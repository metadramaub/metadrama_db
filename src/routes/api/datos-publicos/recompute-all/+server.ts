import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse } from '$lib/server/http';
import { canManagePublicacion } from '$lib/utils/permissions';

type RecomputeAction = 'plan' | 'obra' | 'autor' | 'finalize';
type RecomputePlanItem = { id: string; label: string };
type RecomputePlan = { obras: RecomputePlanItem[]; autores: RecomputePlanItem[] };

const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

function isRecomputeAction(value: unknown): value is RecomputeAction {
	return value === 'plan' || value === 'obra' || value === 'autor' || value === 'finalize';
}

function normalizePlanItem(value: unknown, labelKey: 'titulo' | 'nombre'): RecomputePlanItem | null {
	if (!value || typeof value !== 'object') return null;
	const item = value as Record<string, unknown>;
	if (typeof item.id !== 'string' || !UUID_PATTERN.test(item.id)) return null;
	const label = item[labelKey];
	return { id: item.id, label: typeof label === 'string' && label.trim() ? label : item.id };
}

function normalizePlan(value: unknown): RecomputePlan | null {
	if (!value || typeof value !== 'object') return null;
	const plan = value as Record<string, unknown>;
	if (!Array.isArray(plan.obras) || !Array.isArray(plan.autores)) return null;

	const obras = plan.obras
		.map((item) => normalizePlanItem(item, 'titulo'))
		.filter((item): item is RecomputePlanItem => item !== null);
	const autores = plan.autores
		.map((item) => normalizePlanItem(item, 'nombre'))
		.filter((item): item is RecomputePlanItem => item !== null);

	if (obras.length !== plan.obras.length || autores.length !== plan.autores.length) return null;
	return { obras, autores };
}

async function loadPlan(locals: App.Locals): Promise<RecomputePlan | null> {
	const { data, error } = await locals.supabase.rpc('plan_recompute_datos_publicos');
	if (error) return null;
	return normalizePlan(data);
}

async function isStillPublished(locals: App.Locals, obraId: string) {
	const { data: publicado, error: publishedError } = await locals.supabase
		.from('vocabularios')
		.select('termino_id')
		.eq('categoria', 'estado')
		.eq('termino', 'publicado')
		.maybeSingle();
	if (publishedError || !publicado) return false;

	const { data: obra, error: obraError } = await locals.supabase
		.from('obras')
		.select('obra_id')
		.eq('obra_id', obraId)
		.eq('estado', publicado.termino_id)
		.maybeSingle();
	return !obraError && Boolean(obra);
}

export const POST: RequestHandler = async ({ locals, request }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManagePublicacion(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden recalcular los datos públicos globales.');
	}

	const body = await request.json().catch(() => ({}));
	const action = body?.action;
	if (!isRecomputeAction(action)) {
		return json({ error: 'validation_error', message: 'Acción de recálculo no válida.' }, { status: 422 });
	}

	if (action === 'plan') {
		const plan = await loadPlan(locals);
		if (!plan) {
			return json({ error: 'db_error', message: 'No se pudo preparar el plan de recálculo.' }, { status: 500 });
		}
		return json({ ok: true, ...plan });
	}

	if (action === 'obra') {
		const obraId = body?.obraId;
		if (typeof obraId !== 'string' || !UUID_PATTERN.test(obraId)) {
			return json({ error: 'validation_error', message: 'Obra no válida.' }, { status: 422 });
		}
		if (!(await isStillPublished(locals, obraId))) {
			return json(
				{ error: 'invalid_state', message: 'La obra ya no está publicada y no se ha recalculado.' },
				{ status: 409 }
			);
		}

		const { error } = await locals.supabase.rpc('recompute_obra_resumen', { p_obra_id: obraId });
		if (error) {
			return json({ error: 'db_error', message: `No se pudo recalcular la obra: ${error.message}` }, { status: 500 });
		}
		return json({ ok: true, action, obraId });
	}

	if (action === 'autor') {
		const autorId = body?.autorId;
		if (typeof autorId !== 'string' || !UUID_PATTERN.test(autorId)) {
			return json({ error: 'validation_error', message: 'Autor no válido.' }, { status: 422 });
		}
		const plan = await loadPlan(locals);
		if (!plan?.autores.some((autor) => autor.id === autorId)) {
			return json(
				{ error: 'invalid_state', message: 'El autor ya no tiene unidades métricas y no se ha recalculado.' },
				{ status: 409 }
			);
		}

		const { error } = await locals.supabase.rpc('recompute_autor_resumen', { p_autor_id: autorId });
		if (error) {
			return json({ error: 'db_error', message: `No se pudo recalcular el autor: ${error.message}` }, { status: 500 });
		}
		return json({ ok: true, action, autorId });
	}

	const { data: eliminados, error } = await locals.supabase.rpc('finalizar_recompute_datos_publicos');
	if (error) {
		return json({ error: 'db_error', message: `No se pudo cerrar el recálculo: ${error.message}` }, { status: 500 });
	}
	return json({ ok: true, action, autoresEliminados: eliminados });
};

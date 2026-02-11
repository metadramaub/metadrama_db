import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { canUseCustomAutoriaRanges, getObraContext } from '$lib/server/auth';
import { conflictResponse, validationErrorResponse } from '$lib/server/http';
import { autoriaInputSchema, type AutoriaInputParsed } from '$lib/utils/validators';
import type { Database, Tables } from '$lib/types/database.types';
import type { AutoriaBlockingReason, AutoriaIntegrity } from '$lib/types/obra.types';
import type { SupabaseClient } from '@supabase/supabase-js';

type RangeDraft = {
	v_ini: number;
	v_fin: number;
	autor_ids: string[];
};

type AutoriaMode = AutoriaInputParsed['mode'];
type RangeBounds = Pick<Tables<'rangos'>, 'v_ini' | 'v_fin'>;
type JornadaBounds = Pick<Tables<'jornadas'>, 'v_ini' | 'v_fin'>;

type BlockingState = {
	canUseCustomRanges: boolean;
	requiresReassign: boolean;
	blockingReason: AutoriaBlockingReason;
	defaultReassignMode: 'obra_completa';
};

function sortByRange<T extends { v_ini: number; v_fin: number }>(items: T[]): T[] {
	return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
}

function hasOverlap(ranges: Array<Pick<RangeDraft, 'v_ini' | 'v_fin'>>): boolean {
	const sorted = sortByRange(ranges);
	for (let i = 1; i < sorted.length; i += 1) {
		if (sorted[i].v_ini <= sorted[i - 1].v_fin) {
			return true;
		}
	}
	return false;
}

function matchesJornadasExactly(
	rangos: RangeBounds[],
	jornadas: JornadaBounds[]
): boolean {
	if (jornadas.length === 0 || rangos.length !== jornadas.length) {
		return false;
	}
	const signatures = new Set(rangos.map((range) => `${range.v_ini}:${range.v_fin}`));
	return jornadas.every((jornada) => signatures.has(`${jornada.v_ini}:${jornada.v_fin}`));
}

function hasCoverageGap(rangos: RangeBounds[], totalVersos: number | null): boolean {
	if (rangos.length === 0 || !totalVersos || totalVersos < 1) {
		return false;
	}
	const sorted = sortByRange(rangos);
	if (sorted[0].v_ini > 1) {
		return true;
	}
	for (let i = 1; i < sorted.length; i += 1) {
		if (sorted[i].v_ini > sorted[i - 1].v_fin + 1) {
			return true;
		}
	}
	if (sorted[sorted.length - 1].v_fin < totalVersos) {
		return true;
	}
	if (sorted[sorted.length - 1].v_fin > totalVersos) {
		return true;
	}
	return false;
}

function isLikelyPerJornadaDistribution(
	rangos: RangeBounds[],
	jornadas: JornadaBounds[]
): boolean {
	if (jornadas.length < 2 || rangos.length !== jornadas.length || rangos.length <= 1) {
		return false;
	}
	const sorted = sortByRange(rangos);
	if (hasOverlap(sorted)) {
		return false;
	}
	for (let i = 1; i < sorted.length; i += 1) {
		if (sorted[i].v_ini !== sorted[i - 1].v_fin + 1) {
			return false;
		}
	}
	return true;
}

function inferAutoriaIntegrity(
	rangos: RangeBounds[],
	jornadas: JornadaBounds[],
	effectiveTotalVersos: number | null
): AutoriaIntegrity {
	const sorted = sortByRange(rangos);
	const matchesJornadas = matchesJornadasExactly(sorted, jornadas);
	const hasSingleRange = sorted.length === 1 && sorted[0].v_ini === 1;
	const isSingleFullRange = Boolean(
		hasSingleRange &&
			(effectiveTotalVersos === null || sorted[0].v_fin === effectiveTotalVersos)
	);
	const details: string[] = [];

	if (sorted.length === 0) {
		return {
			effective_total_versos: effectiveTotalVersos,
			status: 'aligned',
			details,
			matches_jornadas_exactly: matchesJornadas,
			is_single_full_range: false,
			requires_reassign: false
		};
	}

	if (hasOverlap(sorted)) {
		details.push('Los rangos de autoria se solapan.');
		return {
			effective_total_versos: effectiveTotalVersos,
			status: 'coverage_overlap',
			details,
			matches_jornadas_exactly: matchesJornadas,
			is_single_full_range: isSingleFullRange,
			requires_reassign: true
		};
	}

	if (hasCoverageGap(sorted, effectiveTotalVersos)) {
		if (effectiveTotalVersos) {
			details.push(
				`La estructura actual llega hasta vv. ${effectiveTotalVersos}, pero la autoria no cubre ese total de forma continua.`
			);
		} else {
			details.push('La autoria tiene huecos o limites incoherentes.');
		}
		return {
			effective_total_versos: effectiveTotalVersos,
			status: 'coverage_gap',
			details,
			matches_jornadas_exactly: matchesJornadas,
			is_single_full_range: isSingleFullRange,
			requires_reassign: true
		};
	}

	if (isLikelyPerJornadaDistribution(sorted, jornadas) && !matchesJornadas) {
		details.push('La autoria parece distribuida por jornadas, pero no coincide con los versos actuales de jornadas.');
		return {
			effective_total_versos: effectiveTotalVersos,
			status: 'jornadas_mismatch',
			details,
			matches_jornadas_exactly: matchesJornadas,
			is_single_full_range: isSingleFullRange,
			requires_reassign: true
		};
	}

	return {
		effective_total_versos: effectiveTotalVersos,
		status: 'aligned',
		details,
		matches_jornadas_exactly: matchesJornadas,
		is_single_full_range: isSingleFullRange,
		requires_reassign: false
	};
}

function inferAutoriaMode(
	rangos: Array<Pick<Tables<'rangos'>, 'v_ini' | 'v_fin'>>,
	jornadas: Array<Pick<Tables<'jornadas'>, 'v_ini' | 'v_fin'>>,
	totalVersos: number | null
): AutoriaMode {
	if (rangos.length === 0) {
		return 'obra_completa';
	}

	if (
		rangos.length === 1 &&
		rangos[0].v_ini === 1 &&
		(totalVersos ? rangos[0].v_fin === totalVersos : true)
	) {
		return 'obra_completa';
	}

	if (matchesJornadasExactly(rangos, jornadas)) {
		return 'por_jornadas';
	}

	return 'rango_personalizado';
}

async function resolveTotalVersos(
	supabase: SupabaseClient<Database>,
	obraId: string,
	declaredTotal: number | null
): Promise<number | null> {
	const [jornadasResp, secuenciasResp] = await Promise.all([
		supabase
			.from('jornadas')
			.select('v_fin')
			.eq('obra_id', obraId)
			.order('v_fin', { ascending: false })
			.limit(1),
		supabase
			.from('secuencias_metricas')
			.select('v_fin')
			.eq('obra_id', obraId)
			.order('v_fin', { ascending: false })
			.limit(1)
	]);

	const fromJornadas = jornadasResp.data?.[0]?.v_fin ?? null;
	const fromSecuencias = secuenciasResp.data?.[0]?.v_fin ?? null;
	const resolved = Math.max(declaredTotal ?? 0, fromJornadas ?? 0, fromSecuencias ?? 0);
	return resolved > 0 ? resolved : null;
}

function normalizeDraftsFromPayload(
	payload: AutoriaInputParsed,
	jornadas: Pick<Tables<'jornadas'>, 'jornada_id' | 'v_ini' | 'v_fin'>[],
	totalVersos: number | null
): { drafts: RangeDraft[]; validationMessage?: string } {
	if (payload.mode === 'obra_completa') {
		if (!totalVersos || totalVersos < 2) {
			return {
				drafts: [],
				validationMessage:
					'No se puede asignar autoria de obra completa sin total_versos (o estructura/secuencias con v_fin).'
			};
		}
		return {
			drafts: [
				{
					v_ini: 1,
					v_fin: totalVersos,
					autor_ids: payload.autor_ids
				}
			]
		};
	}

	if (payload.mode === 'por_jornadas') {
		if (jornadas.length === 0) {
			return { drafts: [], validationMessage: 'La obra no tiene jornadas para usar este modo.' };
		}

		const inputMap = new Map(payload.items.map((item) => [item.jornada_id, item]));

		if (inputMap.size !== jornadas.length || jornadas.some((j) => !inputMap.has(j.jornada_id))) {
			return {
				drafts: [],
				validationMessage: 'Debe asignar autores para todas las jornadas de la obra.'
			};
		}

		const drafts: RangeDraft[] = jornadas.map((jornada) => {
			const entry = inputMap.get(jornada.jornada_id)!;
			return {
				v_ini: jornada.v_ini,
				v_fin: jornada.v_fin,
				autor_ids: entry.autor_ids
			};
		});

		return { drafts };
	}

	const drafts = payload.items.map((item) => ({
		v_ini: item.v_ini,
		v_fin: item.v_fin,
		autor_ids: item.autor_ids
	}));

	return { drafts };
}

async function loadAutoriaData(
	supabase: SupabaseClient<Database>,
	obraId: string,
	declaredTotalVersos: number | null
) {
	const effectiveTotalVersos = await resolveTotalVersos(supabase, obraId, declaredTotalVersos);
	const [rangosResp, jornadasResp, autoresResp] = await Promise.all([
		supabase.from('rangos').select('*').eq('obra_id', obraId).order('v_ini'),
		supabase.from('jornadas').select('jornada_id,jornada_num,v_ini,v_fin').eq('obra_id', obraId).order('jornada_num'),
		supabase.from('autores').select('autor_id,nombre_completo,nombre_normalizado').order('nombre_normalizado')
	]);

	const rangos = (rangosResp.data ?? []) as Tables<'rangos'>[];
	const jornadas =
		(jornadasResp.data ?? []) as Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>[];
	const autores = (autoresResp.data ?? []) as Pick<
		Tables<'autores'>,
		'autor_id' | 'nombre_completo' | 'nombre_normalizado'
	>[];

	const rangoIds = rangos.map((row) => row.rango_id);
	const rangosAutoresResp =
		rangoIds.length > 0
			? await supabase.from('rangos_autores').select('*').in('rango_id', rangoIds)
			: { data: [] };
	const rangosAutores = (rangosAutoresResp.data ?? []) as Tables<'rangos_autores'>[];

	return {
		rangos,
		rangosAutores,
		autores,
		jornadas,
		mode: inferAutoriaMode(rangos, jornadas, effectiveTotalVersos),
		integrity: inferAutoriaIntegrity(rangos, jornadas, effectiveTotalVersos)
	};
}

function resolveBlockingState(
	roleTerm: string,
	mode: AutoriaMode,
	integrity: AutoriaIntegrity
): BlockingState {
	const canUseCustomRanges = canUseCustomAutoriaRanges(roleTerm);
	const customModeRestricted = mode === 'rango_personalizado' && !canUseCustomRanges;
	const requiresReassign = integrity.requires_reassign || customModeRestricted;
	const blockingReason: AutoriaBlockingReason = customModeRestricted
		? 'custom_mode_restricted'
		: integrity.requires_reassign
			? 'structure_changed'
			: null;

	return {
		canUseCustomRanges,
		requiresReassign,
		blockingReason,
		defaultReassignMode: 'obra_completa'
	};
}

export const GET: RequestHandler = async ({ locals, params }) => {
	const { obra, profile } = await getObraContext({ locals }, params.id, { requireEdit: false });
	const data = await loadAutoriaData(locals.supabase, obra.obra_id, obra.total_versos);
	const blocking = resolveBlockingState(profile.roleTerm, data.mode, data.integrity);

	return json({
		loaded_at: new Date().toISOString(),
		obra: {
			obra_id: obra.obra_id,
			total_versos: obra.total_versos,
			autoria: obra.autoria,
			url_informe_autoria: obra.url_informe_autoria
		},
		can_use_custom_ranges: blocking.canUseCustomRanges,
		requires_reassign: blocking.requiresReassign,
		blocking_reason: blocking.blockingReason,
		default_reassign_mode: blocking.defaultReassignMode,
		...data
	});
};

export const PUT: RequestHandler = async ({ locals, params, request }) => {
	const { obra, profile } = await getObraContext({ locals }, params.id, { requireEdit: true });

	const body = await request.json().catch(() => ({}));
	const parsed = autoriaInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const payload = parsed.data;
	const jornadasResp = await locals.supabase
		.from('jornadas')
		.select('jornada_id,v_ini,v_fin')
		.eq('obra_id', obra.obra_id)
		.order('v_ini');
	const jornadas = (jornadasResp.data ?? []) as Pick<Tables<'jornadas'>, 'jornada_id' | 'v_ini' | 'v_fin'>[];

	const totalVersos = await resolveTotalVersos(locals.supabase, obra.obra_id, obra.total_versos);
	const existingResp = await locals.supabase
		.from('rangos')
		.select('rango_id,v_ini,v_fin')
		.eq('obra_id', obra.obra_id)
		.order('v_ini');
	const existingRanges = (existingResp.data ?? []) as Pick<
		Tables<'rangos'>,
		'rango_id' | 'v_ini' | 'v_fin'
	>[];
	const currentMode = inferAutoriaMode(existingRanges, jornadas, totalVersos);
	const currentIntegrity = inferAutoriaIntegrity(existingRanges, jornadas, totalVersos);
	const currentBlocking = resolveBlockingState(profile.roleTerm, currentMode, currentIntegrity);

	if (payload.mode === 'rango_personalizado' && !currentBlocking.canUseCustomRanges) {
		return json(
			{
				error: 'forbidden',
				message: 'Tu rol no puede guardar autoria en rangos personalizados.'
			},
			{ status: 403 }
		);
	}

	if (currentBlocking.requiresReassign && payload.confirm_reassign !== true) {
		return json(
			{
				error: 'conflict',
				message:
					currentBlocking.blockingReason === 'custom_mode_restricted'
						? 'Tu rol no puede editar la autoria actual en rangos personalizados. Reasigna autoria antes de guardar.'
						: 'La autoria actual no coincide con la estructura. Reasigna autoria antes de guardar.',
				integrity: currentIntegrity,
				blocking_reason: currentBlocking.blockingReason,
				requires_reassign: true,
				details: [
					{
						path: 'confirm_reassign',
						message: 'Debes confirmar la reasignacion de autoria para aplicar cambios.'
					}
				]
			},
			{ status: 409 }
		);
	}

	const modeChanged = payload.mode !== currentMode;
	if (modeChanged && payload.confirm_mode_change !== true) {
		return json(
			{
				error: 'conflict',
				message: 'Debes confirmar el cambio de modo antes de guardar.',
				current_mode: currentMode,
				details: [{ path: 'confirm_mode_change', message: 'Falta confirmacion para cambio de modo.' }]
			},
			{ status: 409 }
		);
	}

	if (currentMode !== 'obra_completa' && payload.mode === 'obra_completa' && payload.confirm_mode_change !== true) {
		return json(
			{
				error: 'conflict',
				message: 'Guardar en obra completa reemplaza los rangos actuales. Confirma primero la conversion.',
				current_mode: currentMode,
				details: [
					{
						path: 'confirm_mode_change',
						message: 'Se requiere confirmacion explicita para convertir a obra completa.'
					}
				]
			},
			{ status: 409 }
		);
	}

	const normalized = normalizeDraftsFromPayload(payload, jornadas, totalVersos);
	if (normalized.validationMessage) {
		return json(
			{ error: 'validation_error', details: [{ path: 'mode', message: normalized.validationMessage }] },
			{ status: 422 }
		);
	}

	const drafts = sortByRange(normalized.drafts);
	if (hasOverlap(drafts)) {
		return conflictResponse('Los rangos de autoria se solapan.');
	}

	if (totalVersos && drafts.some((draft) => draft.v_fin > totalVersos)) {
		return json(
			{
				error: 'validation_error',
				details: [
					{ path: 'items', message: `Hay rangos que superan el total de versos de la obra (${totalVersos}).` }
				]
			},
			{ status: 422 }
		);
	}

	const uniqueAuthorIds = [...new Set(drafts.flatMap((draft) => draft.autor_ids))];
	const autoresResp = uniqueAuthorIds.length
		? await locals.supabase
				.from('autores')
				.select('autor_id,nombre_completo')
				.in('autor_id', uniqueAuthorIds)
		: { data: [] };
	const autoresRows = (autoresResp.data ?? []) as Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo'>[];

	if (autoresRows.length !== uniqueAuthorIds.length) {
		return json(
			{
				error: 'validation_error',
				details: [{ path: 'autor_ids', message: 'Uno o varios autores no existen en catalogo.' }]
			},
			{ status: 422 }
		);
	}

	const existingIds = existingRanges.map((row) => row.rango_id);
	if (existingIds.length > 0) {
		const { error: unlinkError } = await locals.supabase
			.from('rangos_autores')
			.delete()
			.in('rango_id', existingIds);
		if (unlinkError) {
			return json(
				{ error: 'db_error', message: unlinkError.message ?? 'No se pudieron limpiar autores por rango.' },
				{ status: 500 }
			);
		}
	}

	const { error: deleteRangesError } = await locals.supabase
		.from('rangos')
		.delete()
		.eq('obra_id', obra.obra_id);
	if (deleteRangesError) {
		return json(
			{ error: 'db_error', message: deleteRangesError.message ?? 'No se pudieron limpiar rangos previos.' },
			{ status: 500 }
		);
	}

	for (const draft of drafts) {
		const { data: rango, error: rangoError } = await locals.supabase
			.from('rangos')
			.insert({
				obra_id: obra.obra_id,
				v_ini: draft.v_ini,
				v_fin: draft.v_fin,
				notas: null
			})
			.select('*')
			.single();

		if (rangoError || !rango) {
			return json(
				{ error: 'db_error', message: rangoError?.message ?? 'No se pudo insertar rango de autoria.' },
				{ status: 500 }
			);
		}

		const linkRows = draft.autor_ids.map((autorId) => ({
			rango_id: rango.rango_id,
			autor_id: autorId
		}));
		const { error: linkError } = await locals.supabase.from('rangos_autores').insert(linkRows);
		if (linkError) {
			return json(
				{ error: 'db_error', message: linkError.message ?? 'No se pudo vincular autores con rango.' },
				{ status: 500 }
			);
		}
	}

	const authorNameMap = new Map(autoresRows.map((row) => [row.autor_id, row.nombre_completo]));
	const autoriaNames = [...new Set(uniqueAuthorIds.map((id) => authorNameMap.get(id)).filter(Boolean) as string[])].sort(
		(a, b) => a.localeCompare(b, 'es')
	);

	const { data: obraUpdated, error: obraUpdateError } = await locals.supabase
		.from('obras')
		.update({
			url_informe_autoria: payload.url_informe_autoria,
			autoria: autoriaNames
		})
		.eq('obra_id', obra.obra_id)
		.select('obra_id,total_versos,autoria,url_informe_autoria')
		.single();
	if (obraUpdateError || !obraUpdated) {
		return json(
			{ error: 'db_error', message: obraUpdateError?.message ?? 'No se pudo actualizar obra.autoria.' },
			{ status: 500 }
		);
	}

	const data = await loadAutoriaData(locals.supabase, obra.obra_id, obraUpdated.total_versos);
	const blocking = resolveBlockingState(profile.roleTerm, data.mode, data.integrity);
	return json({
		loaded_at: new Date().toISOString(),
		obra: obraUpdated,
		can_use_custom_ranges: blocking.canUseCustomRanges,
		requires_reassign: blocking.requiresReassign,
		blocking_reason: blocking.blockingReason,
		default_reassign_mode: blocking.defaultReassignMode,
		...data
	});
};

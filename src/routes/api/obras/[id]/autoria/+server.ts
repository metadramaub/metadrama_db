import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { conflictResponse, validationErrorResponse } from '$lib/server/http';
import { autoriaInputSchema, type AutoriaInputParsed } from '$lib/utils/validators';
import type { Database, Tables } from '$lib/types/database.types';
import type { SupabaseClient } from '@supabase/supabase-js';

type RangeDraft = {
	v_ini: number;
	v_fin: number;
	autor_ids: string[];
};

type AutoriaMode = AutoriaInputParsed['mode'];

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

function inferAutoriaMode(
	rangos: Tables<'rangos'>[],
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

	if (jornadas.length > 0 && rangos.length === jornadas.length) {
		const signatures = new Set(rangos.map((range) => `${range.v_ini}:${range.v_fin}`));
		if (jornadas.every((jornada) => signatures.has(`${jornada.v_ini}:${jornada.v_fin}`))) {
			return 'por_jornadas';
		}
	}

	return 'rango_personalizado';
}

async function resolveTotalVersos(
	supabase: SupabaseClient<Database>,
	obraId: string,
	declaredTotal: number | null
): Promise<number | null> {
	if (declaredTotal && declaredTotal > 0) {
		return declaredTotal;
	}

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
	const resolved = Math.max(fromJornadas ?? 0, fromSecuencias ?? 0);
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
	totalVersos: number | null
) {
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
		mode: inferAutoriaMode(rangos, jornadas, totalVersos)
	};
}

export const GET: RequestHandler = async ({ locals, params }) => {
	const { obra } = await getObraContext({ locals }, params.id, { requireEdit: false });
	const data = await loadAutoriaData(locals.supabase, obra.obra_id, obra.total_versos);

	return json({
		obra: {
			obra_id: obra.obra_id,
			total_versos: obra.total_versos,
			autoria: obra.autoria,
			url_informe_autoria: obra.url_informe_autoria
		},
		...data
	});
};

export const PUT: RequestHandler = async ({ locals, params, request }) => {
	const { obra } = await getObraContext({ locals }, params.id, { requireEdit: true });

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

	const existingResp = await locals.supabase.from('rangos').select('rango_id').eq('obra_id', obra.obra_id);
	const existingIds = (existingResp.data ?? []).map((row) => row.rango_id);
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
	return json({
		obra: obraUpdated,
		...data
	});
};

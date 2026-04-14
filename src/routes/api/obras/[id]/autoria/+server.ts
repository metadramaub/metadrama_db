import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { validationErrorResponse } from '$lib/server/http';
import { autoriaInputSchema, type AutoriaInputParsed } from '$lib/utils/validators';
import type { Database, Tables } from '$lib/types/database.types';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { AutoriaApiPayload, AutoriaAtribucionPayload } from '$lib/types/obra.types';

type AuthorCatalogRow = Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo' | 'nombre_normalizado'>;
type JornadaRow = Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>;
type VocabRow = Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>;
type AtribucionRow = Tables<'atribuciones'>;
type AtribucionAutorRow = Pick<Tables<'atribucion_autores'>, 'atribucion_id' | 'autor_id' | 'orden'>;
type ValidationIssue = { path: string; message: string };

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

async function loadCatalogs(supabase: SupabaseClient<Database>) {
	const [tiposResp, modalidadesResp] = await Promise.all([
		supabase
			.from('vocabularios')
			.select('termino_id,termino')
			.eq('categoria', 'tipo_atribucion')
			.eq('activo', true)
			.order('orden'),
		supabase
			.from('vocabularios')
			.select('termino_id,termino')
			.eq('categoria', 'modalidad_atribucion')
			.eq('activo', true)
			.order('orden')
	]);

	return {
		tipos: (tiposResp.data ?? []) as VocabRow[],
		modalidades: (modalidadesResp.data ?? []) as VocabRow[]
	};
}

function sortAtribuciones(
	atribuciones: AtribucionRow[],
	jornadaById: Map<string, JornadaRow>
): AtribucionRow[] {
	return [...atribuciones].sort((a, b) => {
		const aJornada = a.jornada_id ? jornadaById.get(a.jornada_id) : null;
		const bJornada = b.jornada_id ? jornadaById.get(b.jornada_id) : null;
		const aNum = aJornada?.jornada_num ?? 0;
		const bNum = bJornada?.jornada_num ?? 0;
		return aNum - bNum || a.created_at.localeCompare(b.created_at) || a.atribucion_id.localeCompare(b.atribucion_id);
	});
}

function mapAtribucionesPayload(
	rows: AtribucionRow[],
	links: AtribucionAutorRow[],
	jornadaById: Map<string, JornadaRow>
): AutoriaAtribucionPayload[] {
	const linksByAtribucion = new Map<string, AtribucionAutorRow[]>();
	for (const link of links) {
		const current = linksByAtribucion.get(link.atribucion_id) ?? [];
		current.push(link);
		linksByAtribucion.set(link.atribucion_id, current);
	}

	return sortAtribuciones(rows, jornadaById).map((row) => ({
		atribucion_id: row.atribucion_id,
		obra_id: row.obra_id,
		jornada_id: row.jornada_id,
		tipo_atribucion_id: row.tipo_atribucion_id,
		modalidad_atribucion_id: row.modalidad_atribucion_id,
		fuente_autoria: row.fuente_autoria,
		adoptada: row.adoptada,
		notas: row.notas,
		autores: [...(linksByAtribucion.get(row.atribucion_id) ?? [])]
			.sort((a, b) => (a.orden ?? 99999) - (b.orden ?? 99999) || a.autor_id.localeCompare(b.autor_id))
			.map((link) => ({ autor_id: link.autor_id, orden: link.orden ?? null }))
	}));
}

async function loadAutoriaData(
	supabase: SupabaseClient<Database>,
	obraId: string,
	declaredTotalVersos: number | null
): Promise<Omit<AutoriaApiPayload, 'loaded_at'>> {
	const effectiveTotalVersos = await resolveTotalVersos(supabase, obraId, declaredTotalVersos);

	const [jornadasResp, autoresResp, catalogs] = await Promise.all([
		supabase.from('jornadas').select('jornada_id,jornada_num,v_ini,v_fin').eq('obra_id', obraId).order('jornada_num'),
		supabase.from('autores').select('autor_id,nombre_completo,nombre_normalizado').order('nombre_normalizado'),
		loadCatalogs(supabase)
	]);

	const jornadas = (jornadasResp.data ?? []) as JornadaRow[];
	const autores = (autoresResp.data ?? []) as AuthorCatalogRow[];
	const jornadaIds = jornadas.map((row) => row.jornada_id);

	const [atribucionesObraResp, atribucionesJornadaResp] = await Promise.all([
		supabase.from('atribuciones').select('*').eq('obra_id', obraId),
		jornadaIds.length > 0
			? supabase.from('atribuciones').select('*').in('jornada_id', jornadaIds)
			: Promise.resolve({ data: [] as AtribucionRow[] })
	]);

	const atribucionesRows = [
		...((atribucionesObraResp.data ?? []) as AtribucionRow[]),
		...((atribucionesJornadaResp.data ?? []) as AtribucionRow[])
	];
	const atribucionIds = [...new Set(atribucionesRows.map((row) => row.atribucion_id))];

	const atribucionAutoresResp =
		atribucionIds.length > 0
			? await supabase
					.from('atribucion_autores')
					.select('atribucion_id,autor_id,orden')
					.in('atribucion_id', atribucionIds)
			: { data: [] as AtribucionAutorRow[] };
	const atribucionAutoresRows = (atribucionAutoresResp.data ?? []) as AtribucionAutorRow[];

	const jornadaById = new Map(jornadas.map((row) => [row.jornada_id, row]));

	return {
		obra: {
			obra_id: obraId,
			total_versos: effectiveTotalVersos
		},
		autores,
		jornadas,
		catalogos: {
			tipos: catalogs.tipos,
			modalidades: catalogs.modalidades
		},
		atribuciones: mapAtribucionesPayload(atribucionesRows, atribucionAutoresRows, jornadaById)
	};
}

function pushIssue(issues: ValidationIssue[], path: string, message: string) {
	issues.push({ path, message });
}

function buildValidationResponse(issues: ValidationIssue[]) {
	return json({ error: 'validation_error', details: issues }, { status: 422 });
}

function validateAdoptedRules(atribuciones: AutoriaInputParsed['atribuciones'], issues: ValidationIssue[]) {
	const adoptedObra = atribuciones.filter((item) => !item.jornada_id && item.adoptada).length;
	if (adoptedObra > 1) {
		pushIssue(
			issues,
			'atribuciones',
			'Solo puede haber una atribucion adoptada para el ambito global de obra.'
		);
	}

	const adoptedByJornada = new Map<string, number>();
	for (const item of atribuciones) {
		if (!item.jornada_id || !item.adoptada) continue;
		adoptedByJornada.set(item.jornada_id, (adoptedByJornada.get(item.jornada_id) ?? 0) + 1);
	}
	for (const [jornadaId, count] of adoptedByJornada.entries()) {
		if (count <= 1) continue;
		pushIssue(
			issues,
			'atribuciones',
			`La jornada ${jornadaId} tiene mas de una atribucion adoptada.`
		);
	}
}

function validateModalidadRules(
	atribuciones: AutoriaInputParsed['atribuciones'],
	modalidadTermById: Map<string, string>,
	issues: ValidationIssue[]
) {
	const modalidadesSinAutores = new Set(['desconocida', 'no_atribuida']);

	atribuciones.forEach((item, index) => {
		const modalidadTerm = (modalidadTermById.get(item.modalidad_atribucion_id) ?? '').trim().toLowerCase();
		const authorCount = item.autores.length;

		if (modalidadesSinAutores.has(modalidadTerm) && authorCount !== 0) {
			pushIssue(
				issues,
				`atribuciones.${index}.autores`,
				'La modalidad desconocida exige 0 autores.'
			);
		}

		if (!modalidadesSinAutores.has(modalidadTerm) && authorCount < 1) {
			pushIssue(
				issues,
				`atribuciones.${index}.autores`,
				'Debes seleccionar al menos 1 autor para esta modalidad.'
			);
		}

		if (modalidadTerm === 'unica' && authorCount !== 1) {
			pushIssue(
				issues,
				`atribuciones.${index}.autores`,
				'La modalidad unica exige exactamente 1 autor.'
			);
		}

		if ((modalidadTerm === 'alternativa' || modalidadTerm === 'colaborativa') && authorCount < 2) {
			pushIssue(
				issues,
				`atribuciones.${index}.autores`,
				'Las modalidades alternativa y colaborativa exigen 2 o mas autores.'
			);
		}
	});
}

async function replaceAtribuciones(
	supabase: SupabaseClient<Database>,
	obraId: string,
	jornadaIds: string[],
	atribuciones: AutoriaInputParsed['atribuciones']
): Promise<{ errorMessage: string | null }> {
	const [deleteObraResp, deleteJornadaResp] = await Promise.all([
		supabase.from('atribuciones').delete().eq('obra_id', obraId),
		jornadaIds.length > 0
			? supabase.from('atribuciones').delete().in('jornada_id', jornadaIds)
			: Promise.resolve({ error: null })
	]);

	if (deleteObraResp.error) {
		return { errorMessage: deleteObraResp.error.message };
	}
	if (deleteJornadaResp.error) {
		return { errorMessage: deleteJornadaResp.error.message };
	}

	for (const item of atribuciones) {
		const { data: inserted, error: insertError } = await supabase
			.from('atribuciones')
			.insert({
				obra_id: item.jornada_id ? null : obraId,
				jornada_id: item.jornada_id ?? null,
				tipo_atribucion_id: item.tipo_atribucion_id,
				modalidad_atribucion_id: item.modalidad_atribucion_id,
				fuente_autoria: item.fuente_autoria ?? null,
				adoptada: item.adoptada,
				notas: item.notas ?? null
			})
			.select('atribucion_id')
			.single();

		if (insertError || !inserted) {
			return { errorMessage: insertError?.message ?? 'No se pudo crear una atribucion.' };
		}

		const links = item.autores.map((autor, index) => ({
			atribucion_id: inserted.atribucion_id,
			autor_id: autor.autor_id,
			orden: autor.orden ?? index + 1
		}));

		if (links.length > 0) {
			const linksResp = await supabase.from('atribucion_autores').insert(links);
			if (linksResp.error) {
				return { errorMessage: linksResp.error.message };
			}
		}
	}

	return { errorMessage: null };
}

export const GET: RequestHandler = async ({ locals, params }) => {
	const { obra } = await getObraContext({ locals }, params.id, { requireEdit: false });
	const data = await loadAutoriaData(locals.supabase, obra.obra_id, obra.total_versos);
	return json({
		loaded_at: new Date().toISOString(),
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
		.select('jornada_id')
		.eq('obra_id', obra.obra_id);
	const jornadaIds = [...new Set((jornadasResp.data ?? []).map((row) => row.jornada_id))];
	const jornadaIdSet = new Set(jornadaIds);

	const catalogs = await loadCatalogs(locals.supabase);
	const tipoIdSet = new Set(catalogs.tipos.map((item) => item.termino_id));
	const modalidadTermById = new Map(
		catalogs.modalidades.map((item) => [item.termino_id, item.termino])
	);
	const modalidadIdSet = new Set(catalogs.modalidades.map((item) => item.termino_id));

	const issues: ValidationIssue[] = [];

	payload.atribuciones.forEach((item, index) => {
		if (item.jornada_id && !jornadaIdSet.has(item.jornada_id)) {
			pushIssue(
				issues,
				`atribuciones.${index}.jornada_id`,
				'La jornada indicada no pertenece a la obra.'
			);
		}
		if (!tipoIdSet.has(item.tipo_atribucion_id)) {
			pushIssue(
				issues,
				`atribuciones.${index}.tipo_atribucion_id`,
				'Tipo de atribucion invalido.'
			);
		}
		if (!modalidadIdSet.has(item.modalidad_atribucion_id)) {
			pushIssue(
				issues,
				`atribuciones.${index}.modalidad_atribucion_id`,
				'Modalidad de atribucion invalida.'
			);
		}
	});

	validateModalidadRules(payload.atribuciones, modalidadTermById, issues);
	validateAdoptedRules(payload.atribuciones, issues);

	const authorIds = [
		...new Set(payload.atribuciones.flatMap((item) => item.autores.map((autor) => autor.autor_id)))
	];
	const authorsResp =
		authorIds.length > 0
			? await locals.supabase.from('autores').select('autor_id').in('autor_id', authorIds)
			: { data: [] as Pick<Tables<'autores'>, 'autor_id'>[] };
	const foundAuthorIds = new Set((authorsResp.data ?? []).map((row) => row.autor_id));
	for (const authorId of authorIds) {
		if (!foundAuthorIds.has(authorId)) {
			pushIssue(issues, 'atribuciones', `El autor ${authorId} no existe en catalogo.`);
		}
	}

	if (issues.length > 0) {
		return buildValidationResponse(issues);
	}

	const replaceResult = await replaceAtribuciones(
		locals.supabase,
		obra.obra_id,
		jornadaIds,
		payload.atribuciones
	);
	if (replaceResult.errorMessage) {
		return json({ error: 'db_error', message: replaceResult.errorMessage }, { status: 500 });
	}

	const data = await loadAutoriaData(locals.supabase, obra.obra_id, obra.total_versos);
	return json({
		loaded_at: new Date().toISOString(),
		...data
	});
};

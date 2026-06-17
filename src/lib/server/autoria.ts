import type { SupabaseClient } from '@supabase/supabase-js';
import type { AutoriaInputParsed } from '$lib/utils/validators';
import type { AutoriaApiPayload, AutoriaComposicionTerm } from '$lib/types/obra.types';
import type { Database, Tables } from '$lib/types/database.types';

type AuthorCatalogRow = Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo' | 'nombre_normalizado'>;
type JornadaRow = Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>;
type VocabRow = Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>;
type GrupoRow = Tables<'grupos_atribucion'>;
type AtribucionRow = Tables<'atribuciones'>;
type AtribucionAutorRow = Pick<Tables<'atribucion_autores'>, 'atribucion_id' | 'autor_id' | 'orden'>;
type AtribucionEvidenciaRow = Tables<'atribucion_evidencias'>;

export type AutoriaValidationIssue = { path: string; message: string };

function normalizeTerm(value: string | null | undefined): string {
	return (value ?? '')
		.normalize('NFD')
		.replaceAll(/\p{M}/gu, '')
		.trim()
		.toLowerCase()
		.replaceAll(/[\s-]+/g, '_');
}

function pushIssue(issues: AutoriaValidationIssue[], path: string, message: string) {
	issues.push({ path, message });
}

function sortJornadas(items: JornadaRow[]) {
	return [...items].sort((a, b) => a.jornada_num - b.jornada_num || a.v_ini - b.v_ini);
}

function sortGroups(groups: GrupoRow[], jornadaById: Map<string, JornadaRow>) {
	return [...groups].sort((a, b) => {
		const aJornada = a.jornada_id ? jornadaById.get(a.jornada_id) : null;
		const bJornada = b.jornada_id ? jornadaById.get(b.jornada_id) : null;
		const aScope = a.jornada_id ? 1 : 0;
		const bScope = b.jornada_id ? 1 : 0;
		return (
			aScope - bScope ||
			(aJornada?.jornada_num ?? 0) - (bJornada?.jornada_num ?? 0) ||
			a.created_at.localeCompare(b.created_at) ||
			a.grupo_atribucion_id.localeCompare(b.grupo_atribucion_id)
		);
	});
}

function sortEvidenceRows(items: AtribucionEvidenciaRow[], tipoById: Map<string, string>) {
	return [...items].sort(
		(a, b) =>
			(tipoById.get(a.tipo_atribucion_id) ?? '').localeCompare(tipoById.get(b.tipo_atribucion_id) ?? '') ||
			a.created_at.localeCompare(b.created_at) ||
			a.atribucion_evidencia_id.localeCompare(b.atribucion_evidencia_id)
	);
}

async function resolveTotalVersos(
	supabase: SupabaseClient<Database>,
	obraId: string,
	declaredTotal: number | null
): Promise<number | null> {
	const [jornadasResp, secuenciasResp] = await Promise.all([
		supabase.from('jornadas').select('v_fin').eq('obra_id', obraId).order('v_fin', { ascending: false }).limit(1),
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

export async function loadAutoriaCatalogs(supabase: SupabaseClient<Database>) {
	const [tiposResp, composicionesResp, modalidadesResp] = await Promise.all([
		supabase
			.from('vocabularios')
			.select('termino_id,termino')
			.eq('categoria', 'tipo_atribucion')
			.eq('activo', true)
			.order('orden'),
		supabase
			.from('vocabularios')
			.select('termino_id,termino')
			.eq('categoria', 'composicion_autoria')
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
		composiciones: ((composicionesResp.data ?? []) as VocabRow[]).filter((item) =>
			['individual', 'colaborada', 'desconocida'].includes(normalizeTerm(item.termino))
		),
		modalidades: (modalidadesResp.data ?? []) as VocabRow[]
	};
}

export async function loadAutoriaData(
	supabase: SupabaseClient<Database>,
	obraId: string,
	declaredTotalVersos: number | null,
	options: { includePerfilMetrico?: boolean } = {}
): Promise<Omit<AutoriaApiPayload, 'loaded_at'>> {
	const includePerfilMetrico = options.includePerfilMetrico ?? true;
	const effectiveTotalVersos = await resolveTotalVersos(supabase, obraId, declaredTotalVersos);
	const [jornadasResp, autoresResp, catalogs] = await Promise.all([
		supabase.from('jornadas').select('jornada_id,jornada_num,v_ini,v_fin').eq('obra_id', obraId).order('jornada_num'),
		supabase.from('autores').select('autor_id,nombre_completo,nombre_normalizado').order('nombre_normalizado'),
		loadAutoriaCatalogs(supabase)
	]);

	const jornadas = sortJornadas((jornadasResp.data ?? []) as JornadaRow[]);
	const autores = (autoresResp.data ?? []) as AuthorCatalogRow[];
	const jornadaIds = jornadas.map((row) => row.jornada_id);
	const [globalGroupsResp, jornadaGroupsResp] = await Promise.all([
		supabase.from('grupos_atribucion').select('*').eq('obra_id', obraId),
		jornadaIds.length > 0
			? supabase.from('grupos_atribucion').select('*').in('jornada_id', jornadaIds)
			: Promise.resolve({ data: [] as GrupoRow[] })
	]);

	const grupos = [
		...((globalGroupsResp.data ?? []) as GrupoRow[]),
		...((jornadaGroupsResp.data ?? []) as GrupoRow[])
	];
	const grupoIds = grupos.map((grupo) => grupo.grupo_atribucion_id);
	const atribucionesResp =
		grupoIds.length > 0
			? await supabase.from('atribuciones').select('*').in('grupo_atribucion_id', grupoIds)
			: { data: [] as AtribucionRow[] };
	const atribuciones = (atribucionesResp.data ?? []) as AtribucionRow[];
	const atribucionIds = atribuciones.map((row) => row.atribucion_id);
	const atribucionAutoresResp =
		atribucionIds.length > 0
			? await supabase
					.from('atribucion_autores')
					.select('atribucion_id,autor_id,orden')
					.in('atribucion_id', atribucionIds)
			: { data: [] as AtribucionAutorRow[] };
	const atribucionAutores = (atribucionAutoresResp.data ?? []) as AtribucionAutorRow[];
	const atribucionEvidenciasResp =
		atribucionIds.length > 0
			? await supabase
					.from('atribucion_evidencias')
					.select('*')
					.in('atribucion_id', atribucionIds)
			: { data: [] as AtribucionEvidenciaRow[] };
	const atribucionEvidencias = (atribucionEvidenciasResp.data ?? []) as AtribucionEvidenciaRow[];

	const jornadaById = new Map(jornadas.map((row) => [row.jornada_id, row]));
	const tipoById = new Map(catalogs.tipos.map((item) => [item.termino_id, item.termino]));
	const composicionById = new Map(catalogs.composiciones.map((item) => [item.termino_id, item.termino]));
	const linksByAtribucion = new Map<string, AtribucionAutorRow[]>();
	for (const link of atribucionAutores) {
		const current = linksByAtribucion.get(link.atribucion_id) ?? [];
		current.push(link);
		linksByAtribucion.set(link.atribucion_id, current);
	}
	const evidenciasByAtribucion = new Map<string, AtribucionEvidenciaRow[]>();
	for (const evidencia of atribucionEvidencias) {
		const current = evidenciasByAtribucion.get(evidencia.atribucion_id) ?? [];
		current.push(evidencia);
		evidenciasByAtribucion.set(evidencia.atribucion_id, current);
	}

	const propuestasByGrupo = new Map<string, AtribucionRow[]>();
	for (const atribucion of atribuciones) {
		if (!atribucion.grupo_atribucion_id) continue;
		const current = propuestasByGrupo.get(atribucion.grupo_atribucion_id) ?? [];
		current.push(atribucion);
		propuestasByGrupo.set(atribucion.grupo_atribucion_id, current);
	}

	return {
		obra: {
			obra_id: obraId,
			total_versos: effectiveTotalVersos
		},
		autores,
		jornadas,
		catalogos: {
			tipos: catalogs.tipos,
			composiciones: catalogs.composiciones
		},
		grupos: sortGroups(grupos, jornadaById).map((grupo) => ({
			grupo_atribucion_id: grupo.grupo_atribucion_id,
			obra_id: grupo.obra_id,
			jornada_id: grupo.jornada_id,
			jornada_num: grupo.jornada_id ? (jornadaById.get(grupo.jornada_id)?.jornada_num ?? null) : null,
			propuestas: [...(propuestasByGrupo.get(grupo.grupo_atribucion_id) ?? [])]
				.sort((a, b) => a.created_at.localeCompare(b.created_at) || a.atribucion_id.localeCompare(b.atribucion_id))
				.map((atribucion) => {
					const composicionTerm = normalizeTerm(
						atribucion.composicion_autoria_id
							? composicionById.get(atribucion.composicion_autoria_id)
							: 'individual'
					) as AutoriaComposicionTerm;
					return {
						atribucion_id: atribucion.atribucion_id,
						grupo_atribucion_id: grupo.grupo_atribucion_id,
						composicion_autoria_id: atribucion.composicion_autoria_id ?? '',
						composicion_autoria_term: composicionTerm,
						...(includePerfilMetrico ? { perfil_metrico: atribucion.perfil_metrico } : {}),
						autores: [...(linksByAtribucion.get(atribucion.atribucion_id) ?? [])]
							.sort((a, b) => (a.orden ?? 99999) - (b.orden ?? 99999) || a.autor_id.localeCompare(b.autor_id))
							.map((link) => ({ autor_id: link.autor_id, orden: link.orden ?? null })),
						evidencias: sortEvidenceRows(evidenciasByAtribucion.get(atribucion.atribucion_id) ?? [], tipoById)
							.map((evidencia) => ({
								atribucion_evidencia_id: evidencia.atribucion_evidencia_id,
								tipo_atribucion_id: evidencia.tipo_atribucion_id,
								tipo_atribucion_term: tipoById.get(evidencia.tipo_atribucion_id) ?? null,
								fuente_autoria: evidencia.fuente_autoria
							}))
					};
				})
		}))
	};
}

export function validateAutoriaPayload(
	payload: AutoriaInputParsed,
	options: {
		jornadaIds: Set<string>;
		tipoIds: Set<string>;
		composicionTermById: Map<string, string>;
		authorIds: Set<string>;
	}
): AutoriaValidationIssue[] {
	const issues: AutoriaValidationIssue[] = [];
	const globalGroups = payload.grupos.filter((grupo) => grupo.jornada_id === null);
	if (globalGroups.length > 1) {
		pushIssue(issues, 'grupos', 'Solo puede existir una autoría global para la obra completa.');
	}
	const seenJornadaIds = new Set<string>();
	payload.grupos.forEach((grupo, groupIndex) => {
		if (!grupo.jornada_id) return;
		if (seenJornadaIds.has(grupo.jornada_id)) {
			pushIssue(
				issues,
				`grupos.${groupIndex}.jornada_id`,
				'Solo puede existir un grupo de autoría por jornada.'
			);
			return;
		}
		seenJornadaIds.add(grupo.jornada_id);
	});

	payload.grupos.forEach((grupo, groupIndex) => {
		if (grupo.jornada_id && !options.jornadaIds.has(grupo.jornada_id)) {
			pushIssue(issues, `grupos.${groupIndex}.jornada_id`, 'La jornada indicada no pertenece a la obra.');
		}

		grupo.propuestas.forEach((propuesta, proposalIndex) => {
			const path = `grupos.${groupIndex}.propuestas.${proposalIndex}`;
			if (propuesta.evidencias.length === 0) {
				pushIssue(issues, `${path}.evidencias`, 'Cada propuesta debe tener al menos una evidencia.');
			}
			const evidenceTypeIds = new Set<string>();
			for (const [evidenceIndex, evidencia] of propuesta.evidencias.entries()) {
				const evidencePath = `${path}.evidencias.${evidenceIndex}`;
				if (!options.tipoIds.has(evidencia.tipo_atribucion_id)) {
					pushIssue(issues, `${evidencePath}.tipo_atribucion_id`, 'Tipo de evidencia invalido.');
				}
				if (evidenceTypeIds.has(evidencia.tipo_atribucion_id)) {
					pushIssue(issues, evidencePath, 'No puede repetirse el tipo de evidencia en una propuesta.');
				}
				evidenceTypeIds.add(evidencia.tipo_atribucion_id);
			}

			const composicionTerm = normalizeTerm(options.composicionTermById.get(propuesta.composicion_autoria_id));
			if (!composicionTerm || !['individual', 'colaborada', 'desconocida'].includes(composicionTerm)) {
				pushIssue(issues, `${path}.composicion_autoria_id`, 'Tipologia de autoria invalida.');
			}

			const authorIds = propuesta.autores.map((autor) => autor.autor_id);
			for (const authorId of authorIds) {
				if (!options.authorIds.has(authorId)) {
					pushIssue(issues, `${path}.autores`, `El autor ${authorId} no existe en catalogo.`);
				}
			}

			if (composicionTerm === 'individual' && authorIds.length !== 1) {
				pushIssue(issues, `${path}.autores`, 'La tipologia individual exige exactamente 1 autor.');
			}
			if (composicionTerm === 'colaborada' && authorIds.length < 2) {
				pushIssue(issues, `${path}.autores`, 'La tipologia colaborada exige 2 o mas autores.');
			}
			if (composicionTerm === 'desconocida' && authorIds.length !== 0) {
				pushIssue(issues, `${path}.autores`, 'La tipologia desconocida no permite autores.');
			}
			if (propuesta.perfil_metrico && (composicionTerm !== 'individual' || authorIds.length !== 1)) {
				pushIssue(
					issues,
					`${path}.perfil_metrico`,
					'Solo una propuesta individual con un unico autor puede alimentar perfiles metricos.'
				);
			}
		});

		const proposalKeys = new Set<string>();
		grupo.propuestas.forEach((propuesta, proposalIndex) => {
			const composicionTerm = normalizeTerm(options.composicionTermById.get(propuesta.composicion_autoria_id));
			const authorKey = propuesta.autores
				.map((autor) => autor.autor_id)
				.sort((a, b) => a.localeCompare(b))
				.join(',');
			const key = `${composicionTerm}:${authorKey}`;
			if (proposalKeys.has(key)) {
				pushIssue(
					issues,
					`grupos.${groupIndex}.propuestas.${proposalIndex}`,
					'No puede haber dos propuestas iguales en el mismo grupo; anade evidencias a una sola propuesta.'
				);
			}
			proposalKeys.add(key);
		});
	});

	return issues;
}

export async function replaceAutoriaGroups(
	supabase: SupabaseClient<Database>,
	obraId: string,
	jornadaIds: string[],
	payload: AutoriaInputParsed,
	options: { canManagePerfilMetrico?: boolean } = {}
): Promise<{ errorMessage: string | null }> {
	const canManagePerfilMetrico = Boolean(options.canManagePerfilMetrico);
	const catalogs = await loadAutoriaCatalogs(supabase);
	const composicionTermById = new Map(
		catalogs.composiciones.map((item) => [item.termino_id, normalizeTerm(item.termino)])
	);
	const modalidadByTerm = new Map(catalogs.modalidades.map((item) => [normalizeTerm(item.termino), item.termino_id]));
	const fallbackModalidadId = modalidadByTerm.get('unica') ?? catalogs.modalidades[0]?.termino_id;
	if (!fallbackModalidadId) {
		return { errorMessage: 'No hay modalidades de atribucion de compatibilidad configuradas.' };
	}

	const existingMetricByAtribucionId = new Map<string, boolean>();
	if (!canManagePerfilMetrico) {
		const existingIds = [
			...new Set(
				payload.grupos.flatMap((grupo) =>
					grupo.propuestas
						.map((propuesta) => propuesta.atribucion_id)
						.filter((id): id is string => typeof id === 'string' && id.length > 0)
				)
			)
		];
		if (existingIds.length > 0) {
			const existingResp = await supabase
				.from('atribuciones')
				.select('atribucion_id,perfil_metrico')
				.in('atribucion_id', existingIds);
			if (existingResp.error) return { errorMessage: existingResp.error.message };
			for (const row of existingResp.data ?? []) {
				existingMetricByAtribucionId.set(row.atribucion_id, Boolean(row.perfil_metrico));
			}
		}
	}

	const [deleteGlobalGroupsResp, deleteJornadaGroupsResp, deleteLegacyGlobalResp, deleteLegacyJornadaResp] =
		await Promise.all([
			supabase.from('grupos_atribucion').delete().eq('obra_id', obraId),
			jornadaIds.length > 0
				? supabase.from('grupos_atribucion').delete().in('jornada_id', jornadaIds)
				: Promise.resolve({ error: null }),
			supabase.from('atribuciones').delete().eq('obra_id', obraId).is('grupo_atribucion_id', null),
			jornadaIds.length > 0
				? supabase.from('atribuciones').delete().in('jornada_id', jornadaIds).is('grupo_atribucion_id', null)
				: Promise.resolve({ error: null })
		]);

	const deleteError =
		deleteGlobalGroupsResp.error ??
		deleteJornadaGroupsResp.error ??
		deleteLegacyGlobalResp.error ??
		deleteLegacyJornadaResp.error;
	if (deleteError) return { errorMessage: deleteError.message };

	for (const grupo of payload.grupos) {
		const { data: insertedGroup, error: groupError } = await supabase
			.from('grupos_atribucion')
			.insert({
				obra_id: grupo.jornada_id ? null : obraId,
				jornada_id: grupo.jornada_id ?? null
			})
			.select('grupo_atribucion_id')
			.single();
		if (groupError || !insertedGroup) {
			return { errorMessage: groupError?.message ?? 'No se pudo crear el grupo de atribucion.' };
		}

		for (const propuesta of grupo.propuestas) {
			const composicionTerm = composicionTermById.get(propuesta.composicion_autoria_id) ?? 'individual';
			const modalidadId =
				composicionTerm === 'individual'
					? (modalidadByTerm.get('unica') ?? fallbackModalidadId)
					: composicionTerm === 'desconocida'
						? (modalidadByTerm.get('desconocida') ?? fallbackModalidadId)
						: (modalidadByTerm.get('colaborativa') ?? fallbackModalidadId);
			const firstEvidence = propuesta.evidencias[0];
			if (!firstEvidence) {
				return { errorMessage: 'Cada propuesta debe tener al menos una evidencia.' };
			}

			const { data: insertedAtribucion, error: atribucionError } = await supabase
				.from('atribuciones')
				.insert({
					grupo_atribucion_id: insertedGroup.grupo_atribucion_id,
					obra_id: grupo.jornada_id ? null : obraId,
					jornada_id: grupo.jornada_id ?? null,
					tipo_atribucion_id: firstEvidence.tipo_atribucion_id,
					modalidad_atribucion_id: modalidadId,
					composicion_autoria_id: propuesta.composicion_autoria_id,
					fuente_autoria: firstEvidence.fuente_autoria ?? null,
					perfil_metrico: canManagePerfilMetrico
						? propuesta.perfil_metrico
						: (existingMetricByAtribucionId.get(propuesta.atribucion_id ?? '') ?? false)
				})
				.select('atribucion_id')
				.single();
			if (atribucionError || !insertedAtribucion) {
				return { errorMessage: atribucionError?.message ?? 'No se pudo crear una propuesta de autoria.' };
			}

			const links = propuesta.autores.map((autor, index) => ({
				atribucion_id: insertedAtribucion.atribucion_id,
				autor_id: autor.autor_id,
				orden: autor.orden ?? index + 1
			}));
			if (links.length > 0) {
				const linksResp = await supabase.from('atribucion_autores').insert(links);
				if (linksResp.error) return { errorMessage: linksResp.error.message };
			}

			const evidencias = propuesta.evidencias.map((evidencia) => ({
				atribucion_id: insertedAtribucion.atribucion_id,
				tipo_atribucion_id: evidencia.tipo_atribucion_id,
				fuente_autoria: evidencia.fuente_autoria ?? null
			}));
			const evidenciasResp = await supabase.from('atribucion_evidencias').insert(evidencias);
			if (evidenciasResp.error) return { errorMessage: evidenciasResp.error.message };
		}
	}

	return { errorMessage: null };
}

export async function loadMetricProfileAutoriaGroups(supabase: SupabaseClient<Database>, obraId: string) {
	const data = await loadAutoriaData(supabase, obraId, null);
	return data.grupos
		.map((grupo) => ({
			...grupo,
			propuestas: grupo.propuestas.filter((propuesta) => propuesta.perfil_metrico)
		}))
		.filter((grupo) => grupo.propuestas.length > 0);
}

export async function countUnambiguousAutoriaGroups(
	supabase: SupabaseClient<Database>,
	obraId: string
): Promise<number> {
	const data = await loadAutoriaData(supabase, obraId, null, { includePerfilMetrico: false });
	return data.grupos.filter((grupo) => grupo.propuestas.length === 1).length;
}

import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import type { CatalogTramo } from '$lib/catalogo/catalog-filters';
import { getPublicadoEstadoId, resolvePublicViewerContext } from '$lib/server/public-obras';
import { requireSectionVisible } from '$lib/server/secciones-publicas';
import type { Tables } from '$lib/types/database.types';

type LaboratorioObra = Pick<
	Tables<'obras'>,
	| 'obra_id'
	| 'slug'
	| 'titulo'
	| 'fecha_inicio_trad'
	| 'fecha_fin_trad'
	| 'total_versos'
	| 'visible_publico'
> & {
	autoria_autores: string[];
	perfil_formas: Record<string, number>;
	tramos: CatalogTramo[];
};

type ObraRow = Pick<
	Tables<'obras'>,
	| 'obra_id'
	| 'slug'
	| 'titulo'
	| 'fecha_inicio_trad'
	| 'fecha_fin_trad'
	| 'total_versos'
	| 'visible_publico'
	| 'editor_asignado'
>;

type ResumenRow = Pick<Tables<'obras_resumen'>, 'obra_id' | 'perfil_formas' | 'tramos'>;

export const load: PageServerLoad = async ({ locals }) => {
	await requireSectionVisible(locals, 'laboratorio');

	const [viewer, publicadoId] = await Promise.all([
		resolvePublicViewerContext(locals),
		getPublicadoEstadoId(locals)
	]);

	if (!publicadoId) {
		return { obras: [] as LaboratorioObra[] };
	}

	let query = locals.supabase
		.from('obras')
		.select(
			'obra_id,slug,titulo,fecha_inicio_trad,fecha_fin_trad,total_versos,visible_publico,editor_asignado'
		)
		.eq('estado', publicadoId)
		.order('titulo');

	if (!viewer.canSeeAllPublished) {
		if (viewer.userId) {
			query = query.or(`visible_publico.eq.true,editor_asignado.eq.${viewer.userId}`);
		} else {
			query = query.eq('visible_publico', true);
		}
	}

	const { data, error: dbError } = await query.limit(300);
	if (dbError) {
		throw error(500, `No se pudieron cargar las obras del laboratorio: ${dbError.message}`);
	}

	const obraRows = (data ?? []) as ObraRow[];
	const obraIds = obraRows.map((obra) => obra.obra_id);
	if (obraIds.length === 0) {
		return { obras: [] as LaboratorioObra[] };
	}

	const resumenResp = await locals.supabase
		.from('obras_resumen')
		.select('obra_id,perfil_formas,tramos')
		.in('obra_id', obraIds);
	if (resumenResp.error) {
		throw error(500, `No se pudieron cargar los perfiles métricos: ${resumenResp.error.message}`);
	}
	const resumenByObra = new Map(
		((resumenResp.data ?? []) as ResumenRow[]).map((row) => [row.obra_id, row])
	);

	const gruposResp = await locals.supabase
		.from('grupos_atribucion')
		.select('grupo_atribucion_id,obra_id')
		.in('obra_id', obraIds);
	const grupos = (gruposResp.data ?? []) as Array<
		Pick<Tables<'grupos_atribucion'>, 'grupo_atribucion_id' | 'obra_id'>
	>;
	const grupoIds = grupos.map((grupo) => grupo.grupo_atribucion_id);
	const atribucionesResp =
		grupoIds.length > 0
			? await locals.supabase
					.from('atribuciones')
					.select('atribucion_id,grupo_atribucion_id')
					.in('grupo_atribucion_id', grupoIds)
			: { data: [] as Pick<Tables<'atribuciones'>, 'atribucion_id' | 'grupo_atribucion_id'>[] };
	const atribuciones = (atribucionesResp.data ?? []) as Pick<
		Tables<'atribuciones'>,
		'atribucion_id' | 'grupo_atribucion_id'
	>[];
	const grupoToObra = new Map(grupos.map((grupo) => [grupo.grupo_atribucion_id, grupo.obra_id]));
	const atribucionToObra = new Map<string, string>();
	for (const atribucion of atribuciones) {
		if (!atribucion.grupo_atribucion_id) continue;
		const obraId = grupoToObra.get(atribucion.grupo_atribucion_id);
		if (obraId) atribucionToObra.set(atribucion.atribucion_id, obraId);
	}

	const atribucionIds = [...atribucionToObra.keys()];
	const atribucionAutoresResp =
		atribucionIds.length > 0
			? await locals.supabase
					.from('atribucion_autores')
					.select('atribucion_id,autor_id')
					.in('atribucion_id', atribucionIds)
			: { data: [] as Pick<Tables<'atribucion_autores'>, 'atribucion_id' | 'autor_id'>[] };
	const atribucionAutores = (atribucionAutoresResp.data ?? []) as Pick<
		Tables<'atribucion_autores'>,
		'atribucion_id' | 'autor_id'
	>[];
	const authorIds = [...new Set(atribucionAutores.map((row) => row.autor_id))];
	const autoresResp =
		authorIds.length > 0
			? await locals.supabase.from('autores').select('autor_id,nombre_completo').in('autor_id', authorIds)
			: { data: [] as Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo'>[] };
	const authorNameById = new Map(
		((autoresResp.data ?? []) as Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo'>[]).map((row) => [
			row.autor_id,
			row.nombre_completo
		])
	);
	const autoresByObra = new Map<string, Set<string>>();
	for (const link of atribucionAutores) {
		const obraId = atribucionToObra.get(link.atribucion_id);
		const authorName = authorNameById.get(link.autor_id);
		if (!obraId || !authorName) continue;
		const current = autoresByObra.get(obraId) ?? new Set<string>();
		current.add(authorName);
		autoresByObra.set(obraId, current);
	}

	const obras: LaboratorioObra[] = obraRows
		.map(({ editor_asignado: _editorAsignado, ...obra }) => {
			const resumen = resumenByObra.get(obra.obra_id);
			return {
				...obra,
				autoria_autores: [...(autoresByObra.get(obra.obra_id) ?? new Set<string>())].sort((a, b) =>
					a.localeCompare(b, 'es')
				),
				perfil_formas: (resumen?.perfil_formas as Record<string, number> | null) ?? {},
				tramos: (resumen?.tramos as CatalogTramo[] | null) ?? []
			};
		})
		.filter((obra) => Object.keys(obra.perfil_formas).length > 0 && obra.tramos.length > 0);

	return { obras };
};

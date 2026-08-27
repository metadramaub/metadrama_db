import type { PageServerLoad } from './$types';
import { countAutoriaGroupsWithProposals } from '$lib/server/autoria';
import { getObraContext } from '$lib/server/auth';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import { loadMetricCatalog } from '$lib/server/catalogo-metrico';
import type { Tables } from '$lib/types/database.types';
import type { EditorCuadroRow, EditorJornadaRow, EditorSecuenciaRow } from '$lib/types/editor.types';

const JORNADAS_EDITOR_SELECT = 'jornada_id,jornada_num,obra_id,v_ini,v_fin';
const CUADROS_EDITOR_SELECT = 'cuadro_id,cuadro_num,jornada_id,v_ini,v_fin';
const SECUENCIAS_EDITOR_SELECT =
	'secuencia_id,obra_id,v_ini,v_fin,n_versos,estrofa_tipo_id,inaugura_espacio,versos_partidos,evocacion_metrica,evocacion_metrica_texto,intervencion_personajes_femeninos,intervencion_figuras_donaire,intervencion_personajes_sobrenaturales,sinopsis';

export const load: PageServerLoad = async ({ locals, params, depends }) => {
	depends(`dashboard:obra:${params.id}`);

	const { obra, profile, estadoTerm, assignedReviewer, capabilities } = await getObraContext(
		{ locals },
		params.id,
		{
			requireEdit: false
		}
	);

	const [jornadasResp, secuenciasResp, vocabularios] = await Promise.all([
		locals.supabase
			.from('jornadas')
			.select(JORNADAS_EDITOR_SELECT)
			.eq('obra_id', obra.obra_id)
			.order('v_ini'),
		locals.supabase
			.from('secuencias_metricas')
			.select(SECUENCIAS_EDITOR_SELECT)
			.eq('obra_id', obra.obra_id)
			.order('v_ini'),
		loadInternalVocabulario(locals.supabase, [
			'genero',
			'estado',
			'estrofa_tipo',
			'caracterizacion_rango',
			'personajes_donaire',
			'personajes_sobrenatural'
		])
	]);

	const jornadas = (jornadasResp.data ?? []) as EditorJornadaRow[];
	const jornadaIds = jornadas.map((jornada) => jornada.jornada_id);
	const cuadrosResp =
		jornadaIds.length > 0
			? await locals.supabase
					.from('cuadros')
					.select(CUADROS_EDITOR_SELECT)
					.in('jornada_id', jornadaIds)
					.order('v_ini')
			: { data: [] };
	const cuadros = (cuadrosResp.data ?? []) as EditorCuadroRow[];
	const secuencias = (secuenciasResp.data ?? []) as EditorSecuenciaRow[];
	const autoriaGroupCount = await countAutoriaGroupsWithProposals(
		locals.supabase,
		obra.obra_id,
		jornadaIds
	);

	// Estado de los datos públicos precomputados (Fase 2 del plan de precomputación).
	// Si no hay fila, la obra nunca ha publicado datos (resumenExiste = false).
	const resumenResp = await locals.supabase
		.from('obras_resumen')
		.select('metrica_sucia,actualizado_en')
		.eq('obra_id', obra.obra_id)
		.maybeSingle();
	const resumenRow = resumenResp.data as Pick<
		Tables<'obras_resumen'>,
		'metrica_sucia' | 'actualizado_en'
	> | null;
	const resumenPublico = {
		existe: Boolean(resumenRow),
		metricaSucia: resumenRow?.metrica_sucia ?? false,
		actualizadoEn: resumenRow?.actualizado_en ?? null
	};

	/**
	 * ¿Esta obra se anota con el catálogo nuevo?
	 *
	 * El interruptor es **por obra** para que la ola de editores que entra empiece con el editor V2
	 * sin interrumpir a quien está a mitad de una obra anotada con el vocabulario legado. Mientras
	 * dure la migración conviven los dos.
	 */
	const anotacionNuevaResp = await locals.supabase
		.from('obras_anotacion_nueva')
		.select('obra_id')
		.eq('obra_id', obra.obra_id)
		.maybeSingle();
	const usaAnotacionNueva = Boolean(anotacionNuevaResp.data);

	/**
	 * El catálogo métrico, **solo si esta obra lo necesita**.
	 *
	 * Son unas 2 400 filas que viajan al cliente, y en una obra que todavía se anota con el
	 * vocabulario legado no las mira nadie. Cargarlo sale barato desde que se guarda en memoria del
	 * servidor mientras su revisión no cambia, pero serializarlo no.
	 *
	 * *Se manda solo lo que el editor consume* —formas, arquitecturas, reglas de longitud y el
	 * dominio—, no el laboratorio de pruebas que `loadMetricCatalog` trae además.
	 *
	 * **Hoy esto solo funciona para admin o IP**, porque leer la revisión del catálogo lo exige su
	 * RLS. Abrirlo a los editores es el paso siguiente del camino a develop.
	 */
	const catalogoMetrico = usaAnotacionNueva
		? await loadMetricCatalog(locals.supabase).then((catalogo) =>
				catalogo.migrationPending
					? null
					: {
							forms: catalogo.forms,
							configurations: catalogo.configurations,
							lengthRules: catalogo.lengthRules,
							domain: catalogo.domain
						}
			)
		: null;

	const editorAsignadoResp = obra.editor_asignado
		? await locals.supabase
				.from('editores')
				.select('nombre_completo')
				.eq('user_id', obra.editor_asignado)
				.maybeSingle()
		: { data: null };

	return {
		profile,
		obra,
		estadoTerm,
		assignedReviewer,
		capabilities,
		editorAsignadoNombre: editorAsignadoResp.data?.nombre_completo ?? null,
		jornadas,
		cuadros,
		secuencias,
		autoriaGroupCount,
		resumenPublico,
		vocabularios,
		usaAnotacionNueva,
		catalogoMetrico
	};
};

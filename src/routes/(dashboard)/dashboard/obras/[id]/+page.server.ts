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
	 * El catálogo métrico, que **toda obra necesita**: desde el 27 de agosto de 2026 todas se anotan
	 * con él. Hubo un interruptor por obra mientras la anotación en sombra iba a ser el camino de la
	 * migración; dejó de tener sentido cuando el IP decidió migrar a mano, con el informe delante.
	 *
	 * *Se manda solo lo que el editor consume* —formas, arquitecturas, reglas de longitud y el
	 * dominio—, no el laboratorio de pruebas que `loadMetricCatalog` trae además. Leerlo sale barato
	 * desde que se guarda en memoria del servidor mientras su revisión no cambia; lo que cuesta es
	 * serializarlo, y por eso no viaja entero.
	 *
	 * **Hoy esto solo llega a admin o IP**, porque leer la revisión del catálogo lo exige su RLS. Un
	 * editor recibe `null` y la pestaña le enseña el panel de siempre en vez de una pantalla en
	 * blanco. Abrir la RLS es el paso siguiente del camino a develop.
	 */
	const catalogoMetrico = await loadMetricCatalog(locals.supabase).then((catalogo) =>
		catalogo.migrationPending
			? null
			: {
					forms: catalogo.forms,
					configurations: catalogo.configurations,
					lengthRules: catalogo.lengthRules,
					rhymeTypes: catalogo.options.rhymeTypes,
					domain: catalogo.domain
				}
	);

	/**
	 * Lo que esta obra ya tiene anotado con el catálogo nuevo.
	 *
	 * Sin esto, reabrir una secuencia anotada arrancaría en blanco y guardar intentaría **crear una
	 * segunda anotación** de la misma secuencia. Lo impediría el índice único, pero con un error
	 * crudo en vez de con lo que el editor tenía escrito delante.
	 *
	 * Son tablas pequeñas y se filtran por las secuencias de esta obra, no por todas.
	 */
	const idsDeSecuencias = secuencias.map((fila) => fila.secuencia_id);
	const anotacionesResp = idsDeSecuencias.length
		? await locals.supabase
				.from('anotaciones_metricas')
				.select('*')
				.in('secuencia_id', idsDeSecuencias)
		: { data: [] };
	const idsDeAnotaciones = (anotacionesResp.data ?? []).map(
		(fila: { anotacion_id: string }) => fila.anotacion_id
	);
	const [realizacionesResp, eleccionesResp, desviacionesResp] = idsDeAnotaciones.length
		? await Promise.all([
				locals.supabase
					.from('anotacion_realizaciones')
					.select('*')
					.in('anotacion_id', idsDeAnotaciones)
					.order('orden'),
				locals.supabase.from('anotacion_elecciones_resueltas').select('*').in('anotacion_id', idsDeAnotaciones),
				locals.supabase
					.from('anotacion_desviaciones')
					.select('*')
					.in('anotacion_id', idsDeAnotaciones)
					.order('v_ini')
			])
		: [{ data: [] }, { data: [] }, { data: [] }];

	const anotacionMetrica = {
		secuencias: anotacionesResp.data ?? [],
		unidades: realizacionesResp.data ?? [],
		elecciones: eleccionesResp.data ?? [],
		desviaciones: desviacionesResp.data ?? []
	};

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
		/**
		 * Cada secuencia dice si está anotada con el catálogo nuevo.
		 *
		 * Lo mira la checklist de revisión, que se calcula en el cliente: una secuencia anotada así
		 * deja `estrofa_tipo_id` vacío a propósito, y sin esta marca la daría por incompleta y
		 * ninguna obra podría cerrarse.
		 */
		secuencias: secuencias.map((fila) => ({
			...fila,
			tiene_anotacion_metrica: anotacionMetrica.secuencias.some(
				(anotacion: { secuencia_id: string | null }) =>
					anotacion.secuencia_id === fila.secuencia_id
			)
		})),
		autoriaGroupCount,
		resumenPublico,
		vocabularios,
		catalogoMetrico,
		anotacionMetrica
	};
};

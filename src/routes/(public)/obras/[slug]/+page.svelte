<script lang="ts">
	import { ChevronRight } from 'lucide-svelte';
	import Tabs from '$lib/components/ui/tabs.svelte';
	import Breadcrumb from '$lib/components/ui/Breadcrumb.svelte';
	import CitaDeFicha from '$lib/components/ficha/CitaDeFicha.svelte';
	import MetricBarcode from '$lib/components/metrica/MetricBarcode.svelte';
	import MetricScheme from '$lib/components/metrica/MetricScheme.svelte';
	import MetricFormStrips from '$lib/components/metrica/MetricFormStrips.svelte';
	import MetricSlopeChart from '$lib/components/metrica/MetricSlopeChart.svelte';
	import MetricTraditionSplit from '$lib/components/metrica/MetricTraditionSplit.svelte';
	import MetricWorkSummary from '$lib/components/metrica/MetricWorkSummary.svelte';
	import MetricRunTable from '$lib/components/metrica/MetricRunTable.svelte';
	import MetricEnunciationSummary from '$lib/components/metrica/MetricEnunciationSummary.svelte';
	import MetricDramaticArticulation from '$lib/components/metrica/MetricDramaticArticulation.svelte';
	import MetricTransitions from '$lib/components/metrica/MetricTransitions.svelte';
	import MetricPhenomenaIndex from '$lib/components/metrica/MetricPhenomenaIndex.svelte';
	import MetricEvolution from '$lib/components/metrica/MetricEvolution.svelte';
	import MetricAnalysisHeading from '$lib/components/metrica/MetricAnalysisHeading.svelte';
	import MetricBarcodeFigura, { type FilaDeBarras } from '$lib/components/metrica/MetricBarcodeFigura.svelte';
	import MetricDistributionPieFigura from '$lib/components/metrica/MetricDistributionPieFigura.svelte';
	import { leyendaDeTradiciones } from '$lib/components/metrica/MetricTraditionSplit.svelte';
	import FiguraDescargable from '$lib/components/figuras/FiguraDescargable.svelte';
	import { anioDeFicha } from '$lib/figuras/cita';
	import { TINTA } from '$lib/figuras/tema';
	import type { FiguraDescargable as Figura, ItemLeyenda, ProcedenciaFigura } from '$lib/figuras/tipos';
	import StructureOutline from '$lib/components/metrica/StructureOutline.svelte';
	import MetricDistributionPie from '$lib/components/metrica/MetricDistributionPie.svelte';
	import SequenceDetailModal from '$lib/components/ficha/SequenceDetailModal.svelte';
	import FichaAutoriaBlock from '$lib/components/ficha/FichaAutoriaBlock.svelte';
	import InlineNotePopover from '$lib/components/ui/inline-note-popover.svelte';
	import OrcidIcon from '$lib/components/icons/OrcidIcon.svelte';
	import SequenceSynopsisView from '$lib/components/editor/SequenceSynopsisView.svelte';
	import {
		secuenciasToAnalizables,
		secuenciasToBarSegments,
		secuenciasToSchemeEntries
	} from '$lib/components/ficha/ficha-metric-adapter';
	import {
		SIN_FORMA,
		caracterizacionesDeLaObra,
		cierreDeJornadas,
		cortesDeCuadro,
		evolucionPorJornada,
		fichaTecnica,
		perfilDeFormas,
		perfilPorJornada,
		tradicionesPorJornada,
		secuenciasPorForma,
		transiciones
	} from '$lib/metrica/analisis-ficha';
	import { buildSequenceSynopsisGroups } from '$lib/components/editor/sequence-synopsis';
	import { isSectionVisible, FICHA_SECTION_IDS } from '$lib/secciones-publicas';
	import type {
		SequenceModalPayload,
		PublicFichaComentarioPublico,
		PublicFichaSinopsisMetricaSecuencia,
		PublicFichaDistribucionForma
	} from '$lib/types/public-ficha.types';
	import { renderMarkdown } from '$lib/utils/markdown';
	import { colorForForma } from '$lib/utils/metric-colors';
	import { buildPhenomenaIndex } from '$lib/metrica/phenomena-index';
	import type { MetricDistributionSlice } from '$lib/components/metrica/metric-display.types';
	import {
		resolveSequenceStructures,
		type ResolvedSequenceStructure
	} from '$lib/utils/sequence-structure';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	type TabId =
		| 'estructura'
		| 'esquema'
		| 'analisis'
		| 'sinopsis_metrica'
		| 'observaciones'
		| 'bibliografia';
	type MetricViewMode = 'obra_completa' | 'por_jornadas';
	type PieValueMode = 'percent' | 'absolute';
	type ResolvedPublicSequence = ResolvedSequenceStructure<SequenceModalPayload>;

	let activeTab = $state<TabId>('estructura');
	let estructuraAbierta = $state(false);

	// Se cierra con Escape, como el detalle de secuencia: dos ventanas que se cierran distinto
	// se sienten como dos aplicaciones.
	$effect(() => {
		if (!estructuraAbierta) return;
		const alPulsar = (evento: KeyboardEvent) => {
			if (evento.key === 'Escape') estructuraAbierta = false;
		};
		document.addEventListener('keydown', alPulsar);
		return () => document.removeEventListener('keydown', alPulsar);
	});
	let metricViewMode = $state<MetricViewMode>('obra_completa');
	let pieValueMode = $state<PieValueMode>('percent');
	// Forma resaltada al pasar el ratón por la leyenda del pie. Se aísla por grupo
	// ('obra' o el id de jornada) para que en modo por-jornadas solo ilumine el
	// barcode/pie de esa jornada, no los de las demás.
	let hoveredForma = $state<{ groupId: string; forma: string } | null>(null);

	function formaForGroup(groupId: string): string | null {
		return hoveredForma && hoveredForma.groupId === groupId ? hoveredForma.forma : null;
	}
	let selectedSequenceId = $state<string | null>(null);

	const ficha = $derived(data.ficha);
	const obra = $derived(ficha.obra);
	const estadoTerm = $derived((obra.estado_term ?? '').trim().toLowerCase());
	const isEditorialPreview = $derived(
		estadoTerm === 'vista_previa' || estadoTerm === 'listo_para_publicar'
	);
	const dashboardObraHref = $derived(`/dashboard/obras/${obra.obra_id}?tab=revision`);

	// --- Visibilidad de secciones (resuelve el pendiente B: ocultar, no vaciar) ---
	const show = (id: string) => isSectionVisible(data.sectionVisibility ?? {}, id);
	const showAutoria = $derived(show(FICHA_SECTION_IDS.autoria));
	const showFuentes = $derived(show(FICHA_SECTION_IDS.fuentes));
	const showMetrica = $derived(show(FICHA_SECTION_IDS.metrica));
	const showSinopsisMetrica = $derived(show(FICHA_SECTION_IDS.sinopsisMetrica));
	const showObservaciones = $derived(show(FICHA_SECTION_IDS.observaciones));
	const showBibliografia = $derived(show(FICHA_SECTION_IDS.bibliografia));
	const showComentarios = $derived(show(FICHA_SECTION_IDS.comentarios));

	// --- Estructura métrica ---
	const jornadas = $derived.by(() =>
		[...ficha.estructura.jornadas].sort((a, b) => a.jornada_num - b.jornada_num)
	);
	const cuadros = $derived.by(() =>
		[...ficha.estructura.cuadros].sort((a, b) => a.v_ini - b.v_ini || a.cuadro_num - b.cuadro_num)
	);
	/**
	 * Una secuencia sin forma anotada no se llama como el término interno que la base le pone por
	 * defecto («sin_estrofa»): se dice lo que es, con el mismo nombre que ya le da el análisis.
	 */
	const secuenciasOrdenadas = $derived.by(() =>
		[...ficha.metrica.secuencias]
			.map((secuencia) =>
				secuencia.forma_slug
					? secuencia
					: { ...secuencia, forma_nombre: SIN_FORMA, arquitectura_nombre: SIN_FORMA }
			)
			.sort((a, b) => a.v_ini - b.v_ini)
	);
	const resolvedPublicSequences = $derived.by(() =>
		resolveSequenceStructures({ secuencias: secuenciasOrdenadas, jornadas, cuadros })
	);
	const totalVersos = $derived.by(() => {
		const fromObra = obra.total_versos ?? 0;
		const fromJornadas = jornadas.reduce((max, j) => Math.max(max, j.v_fin), 0);
		const fromSecuencias = secuenciasOrdenadas.reduce((max, s) => Math.max(max, s.v_fin), 0);
		return Math.max(1, fromObra, fromJornadas, fromSecuencias);
	});
	const tabs = $derived.by(() => {
		const items: { id: TabId; label: string }[] = [];
		// **Las pestañas nombran preguntas del lector, no tipos de dato.** «De un vistazo» contesta
		// qué obra es esta; «Esquema métrico», qué hay en cada verso.
		if (showMetrica) items.push({ id: 'estructura', label: 'De un vistazo' });
		if (showMetrica) items.push({ id: 'esquema', label: 'Esquema métrico' });
		if (showMetrica) items.push({ id: 'analisis', label: 'Análisis' });
		if (showSinopsisMetrica) items.push({ id: 'sinopsis_metrica', label: 'Sinopsis' });
		if (showObservaciones) items.push({ id: 'observaciones', label: 'Observaciones' });
		if (showBibliografia) items.push({ id: 'bibliografia', label: 'Bibliografía métrica' });
		return items;
	});

	const datacionLabel = $derived.by(() => {
		const inicio = obra.fecha_inicio_trad;
		const fin = obra.fecha_fin_trad;
		if (inicio !== null && fin !== null && inicio === fin) return `${inicio}`;
		if (inicio !== null && fin !== null) return `${inicio} - ${fin}`;
		if (inicio !== null) return `${inicio}`;
		if (fin !== null) return `${fin}`;
		return '--';
	});
	const fuenteDatacion = $derived((obra.fuente_fecha ?? '').trim());
	const variantesLabel = $derived((obra.variantes_titulo ?? []).join(' | '));
	const editorOrcid = $derived((obra.autor_ficha_orcid_publico ?? '').trim());
	const editorOrcidHref = $derived.by(() => {
		if (!editorOrcid) return '';
		if (/^https?:\/\//i.test(editorOrcid)) return editorOrcid;
		return `https://orcid.org/${editorOrcid}`;
	});
	/**
	 * Un día de la vida de la ficha, sin hora: se guarda, pero al lector no le dice nada. En la hora
	 * de Madrid, que es la del proyecto, y para que el servidor y el navegador escriban el mismo día.
	 */
	function diaDeLaFicha(iso: string | null | undefined): string | null {
		if (!iso) return null;
		const date = new Date(iso);
		if (Number.isNaN(date.valueOf())) return null;
		return new Intl.DateTimeFormat('es-ES', { dateStyle: 'long', timeZone: 'Europe/Madrid' }).format(date);
	}
	/**
	 * La versión que se cita: la del último cambio publicado; si no la hay, la publicación; y en una
	 * vista previa, la última escritura en la obra. De aquí sale el año de la cita.
	 */
	const fechaDeLaVersion = $derived(
		data.datosActualizados ?? obra.fecha_publicacion ?? obra.updated_at
	);
	/** Sin fecha —una vista previa, o un JSON anterior a la columna— no se enseña nada. */
	const publicadaLabel = $derived(diaDeLaFicha(obra.fecha_publicacion));
	/**
	 * La última vez que cambió lo publicado, del artefacto y no de `updated_at`, que no se mueve con
	 * la anotación. Solo se dice si cae en otro día que la publicación.
	 */
	const actualizadaLabel = $derived.by(() => {
		const dia = diaDeLaFicha(data.datosActualizados);
		return dia && dia !== publicadaLabel ? dia : null;
	});

	// Colores por forma (compartidos entre barcode y pie). Clave = slug estable de
	// la forma raíz; color resuelto por slug + gama (tipo_forma).
	const colorByForma = $derived.by(() => {
		const map: Record<string, string> = {};
		for (const item of ficha.metrica.distribucion_formas) {
			const key = item.forma_slug ?? SIN_FORMA;
			if (!map[key]) map[key] = colorForForma({ slug: key, tipoForma: item.forma_tipo_forma });
		}
		for (const secuencia of secuenciasOrdenadas) {
			const key = secuencia.forma_slug ?? secuencia.forma_nombre;
			if (!map[key]) map[key] = colorForForma({ slug: key, tipoForma: secuencia.tipo_forma });
		}
		return map;
	});

	// Slices de la distribución obra-completa con clave de color (slug) explícita.
	const distribucionFormasSlices = $derived.by(() =>
		ficha.metrica.distribucion_formas.map((item: PublicFichaDistribucionForma) => ({
			forma: item.forma_slug ? item.forma : SIN_FORMA,
			colorKey: item.forma_slug ?? SIN_FORMA,
			versos: item.versos,
			porcentaje: item.porcentaje
		}))
	);

	// Adaptación a segmentos genéricos del barcode (incluye subtipos como subsegments).
	const barSegments = $derived.by(() => secuenciasToBarSegments(secuenciasOrdenadas));

	const jornadaMarkers = $derived.by(() =>
		jornadas.map((j) => j.v_fin).filter((m) => m > 0 && m < totalVersos)
	);
	const cuadroMarkers = $derived.by(() =>
		cuadros.map((c) => c.v_fin).filter((m) => m > 0 && m < totalVersos)
	);

	const segmentsByJornada = $derived.by(() => {
		const map = new Map<string, ReturnType<typeof secuenciasToBarSegments>>();
		for (const item of resolvedPublicSequences) {
			if (!item.jornada.jornadaId) continue;
			const current = map.get(item.jornada.jornadaId) ?? [];
			current.push(secuenciasToBarSegments([item.sequence])[0]);
			map.set(item.jornada.jornadaId, current);
		}
		return map;
	});
	const cuadroMarkersByJornada = $derived.by(() => {
		const map = new Map<string, number[]>();
		for (const jornada of jornadas) {
			map.set(
				jornada.jornada_id,
				cuadros.filter((c) => c.jornada_id === jornada.jornada_id).map((c) => c.v_fin)
			);
		}
		return map;
	});
	function buildMetricDistribution(sequences: SequenceModalPayload[]): MetricDistributionSlice[] {
		const total = sequences.reduce((sum, sequence) => sum + (sequence.n_versos ?? 0), 0);
		// Agrupa por forma raíz usando el slug como clave estable; conserva la
		// etiqueta visible y el tipo_forma (gama) para el color.
		const byForma = new Map<string, { forma: string; colorKey: string; tipoForma: string | null; versos: number }>();
		for (const sequence of sequences) {
			const versos = sequence.n_versos ?? 0;
			if (versos <= 0) continue;
			const colorKey = sequence.forma_slug ?? sequence.forma_nombre;
			const current = byForma.get(colorKey);
			if (current) {
				current.versos += versos;
			} else {
				byForma.set(colorKey, {
					forma: sequence.forma_nombre,
					colorKey,
					tipoForma: sequence.tipo_forma,
					versos
				});
			}
		}
		return [...byForma.values()]
			.map((entry) => ({
				forma: entry.forma,
				colorKey: entry.colorKey,
				versos: entry.versos,
				porcentaje: total > 0 ? Math.round((entry.versos / total) * 10000) / 100 : 0
			}))
			.sort((a, b) => b.versos - a.versos || a.forma.localeCompare(b.forma, 'es'));
	}
	const metricProfilesByJornada = $derived.by(() =>
		jornadas.map((jornada) => {
			const sequences = resolvedPublicSequences
				.filter((item) => item.jornada.jornadaId === jornada.jornada_id)
				.map((item) => item.sequence);
			return {
				jornada,
				sequences,
				distribution: buildMetricDistribution(sequences)
			};
		})
	);
	const sinopsisMetricaSequences = $derived.by(
		(): PublicFichaSinopsisMetricaSecuencia[] => ficha.sinopsis_metrica?.secuencias ?? []
	);
	// Las secuencias de sinopsis ya traen forma_slug/tipo_forma
	// desde la RPC, así que el color del borde sale directo (igual que barcode/pie).
	const sinopsisMetricaGroups = $derived.by(() =>
		buildSequenceSynopsisGroups({
			secuencias: sinopsisMetricaSequences,
			jornadas,
			cuadros
		})
	);
	const sinopsisMetricaMissingCount = $derived.by(
		() => sinopsisMetricaSequences.filter((secuencia) => !(secuencia.sinopsis ?? '').trim()).length
	);

	// --- Modal de secuencia ---
	const selectedSequenceIndex = $derived.by(() => {
		if (!selectedSequenceId) return -1;
		return resolvedPublicSequences.findIndex((i) => i.sequence.secuencia_id === selectedSequenceId);
	});
	const selectedSequenceStructure = $derived.by((): ResolvedPublicSequence | null =>
		selectedSequenceIndex < 0 ? null : (resolvedPublicSequences[selectedSequenceIndex] ?? null)
	);
	const selectedSequence = $derived.by(() => selectedSequenceStructure?.sequence ?? null);
	const previousSequenceLabel = $derived.by(() =>
		selectedSequenceIndex > 0
			? (resolvedPublicSequences[selectedSequenceIndex - 1]?.sequence.forma_nombre ?? null)
			: null
	);
	const nextSequenceLabel = $derived.by(() =>
		selectedSequenceIndex >= 0 && selectedSequenceIndex < resolvedPublicSequences.length - 1
			? (resolvedPublicSequences[selectedSequenceIndex + 1]?.sequence.forma_nombre ?? null)
			: null
	);

	const comentariosPublicos = $derived<PublicFichaComentarioPublico[]>(
		ficha.comentarios_publicos ?? []
	);
	const comentariosPorSecuencia = $derived.by(() => {
		const map = new Map<string, PublicFichaComentarioPublico[]>();
		for (const c of comentariosPublicos) {
			if (!c.secuencia_id) continue;
			const cur = map.get(c.secuencia_id) ?? [];
			cur.push(c);
			map.set(c.secuencia_id, cur);
		}
		return map;
	});
	const selectedSequenceComments = $derived.by(() =>
		selectedSequenceId ? (comentariosPorSecuencia.get(selectedSequenceId) ?? []) : []
	);

	function openSequenceModal(id: string) {
		selectedSequenceId = id;
	}
	function closeSequenceModal() {
		selectedSequenceId = null;
	}
	function openPrevSequence() {
		if (selectedSequenceIndex <= 0) return;
		selectedSequenceId = resolvedPublicSequences[selectedSequenceIndex - 1]?.sequence.secuencia_id ?? null;
	}
	function openNextSequence() {
		if (selectedSequenceIndex < 0 || selectedSequenceIndex >= resolvedPublicSequences.length - 1) return;
		selectedSequenceId = resolvedPublicSequences[selectedSequenceIndex + 1]?.sequence.secuencia_id ?? null;
	}

	const schemeEntries = $derived(secuenciasToSchemeEntries(secuenciasOrdenadas));

	/** Los cuadros con su rango, numerados de corrido: la banda no sabe de jornadas. */
	const cuadrosConRango = $derived(
		[...cuadros]
			.sort((a, b) => a.v_ini - b.v_ini)
			.map((cuadro, indice) => ({ numero: indice + 1, v_ini: cuadro.v_ini, v_fin: cuadro.v_fin }))
	);
	/**
	 * Los cortes del código de barras de pantalla, **con lo que empieza en cada uno**: al pasar por
	 * la raya se lee «Jornada 2 · desde el v. 1011», que es como se cita. Los cuadros se numeran de
	 * corrido, como en el resto de la ficha. Un cuadro que acaba donde acaba la jornada no lleva raya
	 * propia: ahí ya está la de la jornada.
	 */
	const rayasDeJornada = $derived(
		jornadas
			.slice(0, -1)
			.map((jornada, indice) => ({
				verse: jornada.v_fin,
				title: `Jornada ${jornadas[indice + 1].jornada_num}`
			}))
			.filter((corte) => corte.verse > 0 && corte.verse < totalVersos)
	);
	const rayasDeCuadro = $derived(
		cuadrosConRango
			.slice(0, -1)
			.map((cuadro) => ({ verse: cuadro.v_fin, title: `Cuadro ${cuadro.numero + 1}` }))
			.filter(
				(corte) =>
					corte.verse > 0 &&
					corte.verse < totalVersos &&
					!rayasDeJornada.some((jornada) => jornada.verse === corte.verse)
			)
	);
	/** Qué cortes enseñan su verso encima de la barra: los de la leyenda por la que se pasa. */
	let cortesALaVista = $state<'jornada' | 'cuadro' | null>(null);

	const analizables = $derived(secuenciasToAnalizables(secuenciasOrdenadas));
	const tecnica = $derived(fichaTecnica(analizables));
	const secuenciasPorFormaDeLaObra = $derived(secuenciasPorForma(analizables));
	const caracterizacionesEnunciativas = $derived(caracterizacionesDeLaObra(analizables));
	const cortesCuadro = $derived(cortesDeCuadro(analizables, cuadros));
	const extremosDeJornadas = $derived(cierreDeJornadas(analizables));
	const transicionesDeLaObra = $derived(transiciones(analizables));
	const phenomenaIndex = $derived(
		buildPhenomenaIndex(secuenciasOrdenadas, {
			sin_figuras_donaire: obra.sin_figuras_donaire ?? false,
			sin_personajes_sobrenaturales: obra.sin_personajes_sobrenaturales ?? false,
			sin_eventos_sobrenaturales: obra.sin_eventos_sobrenaturales ?? false
		})
	);

	/** El orden de apilado es el del reparto de toda la obra, igual en todas las jornadas. */
	const ordenDeFormas = $derived(
		perfilDeFormas(analizables).map((peso) => ({ forma: peso.forma, colorKey: peso.colorKey }))
	);

	// --- Gráficos descargables ---
	// Cada gráfico dice qué es y qué admite; lo que se descarga lo pinta él mismo en modo figura.
	// La cita y la licencia las pone `FiguraDescargable` a partir de esta procedencia.
	const procedenciaFigura = $derived<ProcedenciaFigura>({
		obraTitulo: obra.titulo,
		obraSlug: obra.slug,
		autorFicha: obra.autor_ficha_publico ?? null,
		anio: anioDeFicha(fechaDeLaVersion),
		actualizada: data.datosActualizados
	});
	const leyendaDeFormas = $derived<ItemLeyenda[]>(
		ordenDeFormas.map(({ forma, colorKey }) => ({
			etiqueta: forma,
			color: colorByForma[colorKey] ?? colorForForma({ slug: colorKey, tipoForma: null })
		}))
	);
	const figuraCodigoDeBarras = $derived.by((): Figura => {
		const porJornadas = metricViewMode === 'por_jornadas';
		const cortes: ItemLeyenda[] = [
			...(!porJornadas && jornadaMarkers.length > 0
				? [{ etiqueta: 'Cambio de jornada', color: TINTA.texto, muestra: 'linea' as const }]
				: []),
			...(cuadros.length > 0
				? [{ etiqueta: 'Cambio de cuadro', color: TINTA.tenue, muestra: 'linea-discontinua' as const }]
				: [])
		];
		return {
			titulo: porJornadas ? 'Código de barras métrico por jornadas' : 'Código de barras métrico',
			archivo: porJornadas ? 'codigo-de-barras-por-jornadas' : 'codigo-de-barras',
			admiteGrises: false,
			leyenda: () => [...leyendaDeFormas, ...cortes]
		};
	});
	const filasDeBarras = $derived.by((): FilaDeBarras[] =>
		metricViewMode === 'obra_completa'
			? [
					{
						etiqueta: 'Obra completa',
						desde: 1,
						hasta: totalVersos,
						segmentos: barSegments,
						cortesJornada: jornadaMarkers,
						cortesCuadro: cuadroMarkers,
						jornadas:
							jornadas.length > 1
								? jornadas.map((jornada) => ({
										etiqueta: `Jornada ${jornada.jornada_num}`,
										desde: jornada.v_ini,
										hasta: jornada.v_fin
									}))
								: []
					}
				]
			: jornadas.map((jornada) => ({
					etiqueta: `Jornada ${jornada.jornada_num}`,
					desde: jornada.v_ini,
					hasta: jornada.v_fin,
					segmentos: segmentsByJornada.get(jornada.jornada_id) ?? [],
					cortesCuadro: cuadroMarkersByJornada.get(jornada.jornada_id) ?? []
				}))
	);
	const figuraPerfil = $derived<Figura>(
		metricViewMode === 'por_jornadas'
			? { titulo: 'Perfil métrico por jornadas', archivo: 'perfil-metrico-por-jornadas', admiteGrises: false }
			: { titulo: 'Perfil métrico', archivo: 'perfil-metrico', admiteGrises: false }
	);
	const gruposDelPerfil = $derived(
		metricViewMode === 'por_jornadas'
			? metricProfilesByJornada.map((perfil) => ({
					titulo: `Jornada ${perfil.jornada.jornada_num}`,
					items: perfil.distribution
				}))
			: [{ titulo: null, items: distribucionFormasSlices }]
	);
	const figuraFranjas = $derived<Figura>({
		titulo: 'Dónde cae cada forma',
		archivo: 'donde-cae-cada-forma',
		admiteGrises: true,
		leyenda: () =>
			jornadas.length > 1
				? [{ etiqueta: 'Cambio de jornada', color: TINTA.tenue, muestra: 'linea' }]
				: []
	});
	const figuraPendientes: Figura = {
		titulo: 'El peso de cada forma en cada jornada',
		archivo: 'peso-de-cada-forma-por-jornada',
		admiteGrises: true
	};
	const figuraTradiciones = $derived<Figura>({
		titulo: 'Españolas e italianas por jornada',
		archivo: 'tradiciones-por-jornada',
		admiteGrises: true,
		leyenda: ({ paleta }) =>
			leyendaDeTradiciones(
				paleta,
				tradiciones.some((fila) => fila.sinTradicion.porcentaje > 0)
			)
	});
	const evolucion = $derived(
		perfilPorJornada(analizables).map((jornada) => ({
			etiqueta: `Jornada ${jornada.jornada}`,
			valores: jornada.formas.map((forma) => ({ colorKey: forma.colorKey, versos: forma.versos }))
		}))
	);

	/** Cada forma con sus secuencias, para ver dónde se concentra. */
	const franjas = $derived(
		perfilDeFormas(analizables).map((peso) => ({
			forma: peso.forma,
			colorKey: peso.colorKey,
			porcentaje: peso.porcentaje,
			secuencias: analizables
				.filter((s) => (s.forma_slug ?? SIN_FORMA) === peso.colorKey)
				.map((s) => ({ secuencia_id: s.secuencia_id, v_ini: s.v_ini, v_fin: s.v_fin }))
		}))
	);
	const tradiciones = $derived(tradicionesPorJornada(analizables));

	const momentos = $derived(evolucion.map((serie) => serie.etiqueta));

	/**
	 * Cada forma seguida jornada a jornada, en porcentaje de esa jornada.
	 *
	 * **Un cero es un dato**: quiere decir que la forma no está en esa jornada, y que aparezca en la
	 * siguiente es una de las tres cosas que el gráfico viene a contestar.
	 */
	const pendientes = $derived(
		ordenDeFormas.map(({ forma, colorKey }) => ({
			forma,
			colorKey,
			valores: perfilPorJornada(analizables).map(
				(jornada) => jornada.formas.find((f) => f.colorKey === colorKey)?.porcentaje ?? 0
			)
		}))
	);

	const evolucionDeLaObra = $derived(evolucionPorJornada(analizables));

	/**
	 * Qué contiene esta obra, agrupado por la pregunta que contesta cada cosa.
	 *
	 * **Los grupos son del índice, no del contenido.** No hay encabezados de grupo en la página: los
	 * ocho bloques van seguidos y cada uno lleva su propio título. El grupo sirve para orientarse en
	 * el índice, que es donde hacía falta —ocho enlaces en fila son una lista, cinco grupos con lo
	 * suyo dentro son un mapa—, y evita tener que rehacer la jerarquía de encabezados de cinco
	 * componentes.
	 *
	 * Cada entrada repite la condición con la que su bloque se pinta, y por eso se declara aquí,
	 * junto a los datos: así el índice no puede nombrar algo que no está.
	 */
	const indiceAnalisis = $derived.by(() =>
		[
			{
				grupo: 'El recorrido',
				items: [{ id: 'analisis-donde-cae', label: 'Dónde cae cada forma', hay: franjas.length > 0 }]
			},
			{
				grupo: 'Jornada a jornada',
				items: [
					{
						id: 'analisis-como-cambia',
						label: 'El peso de cada forma',
						hay: momentos.length >= 2
					},
					{
						id: 'analisis-tradiciones',
						label: 'Españolas e italianas',
						hay: tradiciones.length > 0
					},
					{
						id: 'analisis-evolucion',
						label: 'Longitud y variedad',
						hay: evolucionDeLaObra.length > 1
					}
				]
			},
			{
				grupo: 'El repertorio',
				items: [
					{
						id: 'analisis-secuencias',
						label: 'Las secuencias de cada forma',
						hay: secuenciasPorFormaDeLaObra.length > 0
					},
					{
						id: 'analisis-transiciones',
						label: 'Qué forma sigue a cuál',
						hay: transicionesDeLaObra.length > 0
					}
				]
			},
			{
				grupo: 'Otros análisis',
				items: [
					{ id: 'analisis-articulacion', label: 'Jornadas y cuadros', hay: true },
					{
						id: 'analisis-enunciacion',
						label: 'Canto, prosa y evocación',
						hay: caracterizacionesEnunciativas.length > 0
					}
				]
			},
			{
				grupo: 'Ir a',
				items: [
					{ id: 'analisis-localizar', label: 'Localizar en la obra', hay: phenomenaIndex.length > 0 }
				]
			}
		]
			.map((grupo) => ({ ...grupo, items: grupo.items.filter((item) => item.hay) }))
			.filter((grupo) => grupo.items.length > 0)
	);

	const repartoDeTradiciones = $derived(
		tradiciones.map((fila) => ({
			momento: `Jornada ${fila.jornada}`,
			espanola: fila.espanola.porcentaje,
			italiana: fila.italiana.porcentaje,
			sinTradicion: fila.sinTradicion.porcentaje
		}))
	);

	/** Las jornadas con sus cuadros dentro, que es como se lee una comedia. */
	const estructuraJornadas = $derived(
		jornadas.map((jornada) => ({
			numero: jornada.jornada_num,
			v_ini: jornada.v_ini,
			v_fin: jornada.v_fin,
			cuadros: cuadros
				.filter((cuadro) => cuadro.jornada_id === jornada.jornada_id)
				.map((cuadro) => ({ numero: cuadro.cuadro_num, v_ini: cuadro.v_ini, v_fin: cuadro.v_fin }))
				.sort((a, b) => a.numero - b.numero)
		}))
	);

	const hasObservaciones = $derived((obra.observaciones ?? '').trim().length > 0);
	const hasBibliografia = $derived((obra.bibliografia ?? '').trim().length > 0);
	// **La estructura son jornadas y cuadros.** El recuento de secuencias métricas estaba aquí y no
	// pertenece: cómo está partida la obra es un dato de la obra, y en cuántas tiradas está
	// versificada es un dato del verso. Vive en el resumen métrico, con la longitud media y los
	// extremos, que es lo que lo hace legible.
	const estructuraItems = $derived.by(() => [
		{ label: jornadas.length === 1 ? 'jornada' : 'jornadas', value: jornadas.length },
		{ label: cuadros.length === 1 ? 'cuadro' : 'cuadros', value: cuadros.length }
	]);

	$effect(() => {
		if (tabs.some((tab) => tab.id === activeTab)) return;
		activeTab = tabs[0]?.id ?? 'estructura';
	});
</script>

{#if estructuraAbierta}
	<div class="fixed inset-0 z-[120]">
		<button
			type="button"
			class="absolute inset-0 bg-black/40"
			aria-label="Cerrar el desglose de la estructura"
			onclick={() => (estructuraAbierta = false)}
		></button>
		<div
			class="absolute inset-x-4 top-10 bottom-10 overflow-y-auto border border-[color:var(--border)] bg-white p-4 md:inset-x-1/4 md:p-6"
			role="dialog"
			aria-modal="true"
			aria-label="Estructura de la obra"
		>
			<div class="mb-4 flex items-center justify-between gap-3 border-b border-[color:var(--border)] pb-3">
				<h2 class="text-lg font-semibold">Estructura</h2>
				<button
					type="button"
					class="border border-[color:var(--gray-800)] bg-[color:var(--gray-800)] px-2 py-1 text-xs font-semibold text-white"
					onclick={() => (estructuraAbierta = false)}
				>
					Cerrar
				</button>
			</div>
			<StructureOutline jornadas={estructuraJornadas} totalVersos={totalVersos} />
		</div>
	</div>
{/if}

<section class="space-y-6">
	<Breadcrumb
		items={[
			{ label: 'Obras', href: '/obras' },
			{ label: obra.titulo, preserveCase: true }
		]}
	/>

	<header class="card p-4 md:p-5">
		<div class="flex flex-wrap items-start justify-between gap-4 border-b border-[color:var(--border)] pb-4">
			<div class="min-w-0 flex-1">
				<h1 class="font-display text-3xl text-[color:var(--gray-900)] md:text-4xl">{obra.titulo}</h1>
				<!-- Las variantes son parte del título: van pegadas a él y en cursiva, no como una nota. -->
				{#if variantesLabel}
					<p class="mt-1 text-base italic text-[color:var(--gray-700)] md:text-lg">{variantesLabel}</p>
				{/if}
			</div>
		</div>

		{#if data.canSeeAllPublished && isEditorialPreview}
			<div class="mt-4 flex flex-wrap items-center justify-between gap-3 border border-[color:var(--border)] bg-[color:var(--muted)] p-3 text-sm text-[color:var(--muted-foreground)]">
				<span>
					Estás viendo esta obra en vista previa. Para editarla, vuelve al dashboard y cambia el estado a borrador.
				</span>
				<a class="button secondary text-sm" href={dashboardObraHref}>Volver</a>
			</div>
		{:else if data.canSeeAllPublished && !obra.visible_publico}
			<div class="mt-4 border border-[color:var(--border)] bg-[color:var(--muted)] p-3 text-sm text-[color:var(--muted-foreground)]">
				Esta obra está publicada internamente, pero no visible sin login.
			</div>
		{/if}

		<!-- **Contraste en vez de líneas.** Los datos de la obra van un punto más grandes que el resto de
		     la cabecera y el bloque de la ficha, en pequeño y gris: con todo al mismo tamaño la
		     cabecera se leía plana. -->
		<dl class="mt-5 grid gap-x-6 gap-y-5 text-base md:grid-cols-2 lg:grid-cols-[minmax(0,1.3fr)_repeat(3,minmax(0,1fr))]">
			{#if showAutoria}
				<div>
					<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
						Autoría
					</dt>
					<dd class="mt-1">
						<FichaAutoriaBlock autoria={ficha.autoria} showFuentes={showFuentes} />
					</dd>
				</div>
			{/if}
			<div>
				<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Datación
				</dt>
				<dd class="mt-1 font-semibold">
					{datacionLabel}
					{#if fuenteDatacion}
						<span class="mt-1 block font-normal">
							<InlineNotePopover
								text={fuenteDatacion}
								label="Mostrar la fuente de la datación"
								multilinea
								claseBoton="text-left text-xs leading-5 text-[color:var(--muted-foreground)] underline decoration-dotted underline-offset-4 hover:text-[color:var(--foreground)] focus-visible:outline focus-visible:outline-1 focus-visible:outline-offset-2"
							>
								{#snippet disparador()}Fuente de la datación{/snippet}
							</InlineNotePopover>
						</span>
					{/if}
				</dd>
			</div>
			<div>
				<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Género dramático
				</dt>
				<dd class="mt-1 font-semibold">{obra.genero_term ?? '--'}</dd>
			</div>
			<div>
				<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
					Extensión
				</dt>
				<!-- **El total y cómo está partido van juntos**: los dos contestan cuánto mide la obra, y
				     suelto el total de versos ocupaba una columna para un solo número.
				     **El desglose es el botón**, y lo dice su flecha: sin ella el recuento no parecía
				     pulsable. Cómo está partida la obra es un dato de la obra, no del verso, y por eso
				     vive aquí y no en el esquema métrico. -->
				<dd class="mt-1 font-semibold">{totalVersos} vv.</dd>
				<dd class="mt-1">
					{#if estructuraJornadas.length > 0}
						<button
							type="button"
							class="group inline-flex items-center gap-1.5 border-l-2 border-[color:var(--gray-800)] bg-[color:var(--gray-50)] px-2 py-1 text-left hover:bg-[color:var(--gray-100)]"
							title="Ver el desglose en jornadas y cuadros"
							onclick={() => (estructuraAbierta = true)}
						>
							{#each estructuraItems as item, indice (item.label)}
								{#if indice > 0}<span class="text-[color:var(--muted-foreground)]">·</span>{/if}
								<span>
									<span class="font-semibold">{item.value}</span>
									<span class="text-xs text-[color:var(--muted-foreground)]">{item.label}</span>
								</span>
							{/each}
							<ChevronRight
								class="h-3.5 w-3.5 text-[color:var(--muted-foreground)] transition-transform group-hover:translate-x-0.5 group-hover:text-[color:var(--foreground)]"
								aria-hidden="true"
							/>
						</button>
					{:else}
						<span class="inline-flex items-center gap-1.5 border-l-2 border-[color:var(--border)] bg-[color:var(--gray-50)] px-2 py-1">
							{#each estructuraItems as item, indice (item.label)}
								{#if indice > 0}<span class="text-[color:var(--muted-foreground)]">·</span>{/if}
								<span>
									<span class="font-semibold">{item.value}</span>
									<span class="text-xs text-[color:var(--muted-foreground)]">{item.label}</span>
								</span>
							{/each}
						</span>
					{/if}
				</dd>
			</div>
		</dl>

		<!-- **La obra arriba, la ficha abajo.** Lo de encima describe la comedia —quién, cuándo, de
		     qué género, cuánto mide y cómo está partida—; esto, el trabajo sobre ella: quién la anotó,
		     desde cuándo está publicada, sobre qué edición y cómo se cita. Antes el editor y la fecha
		     iban en la misma rejilla que la datación, como si fueran datos de la obra. -->
		<section
			class="mt-8 border-t border-[color:var(--border)] pt-5 text-[color:var(--gray-700)]"
			aria-labelledby="ficha-sobre"
		>
			<h2 id="ficha-sobre" class="text-[10px] font-semibold tracking-[0.18em] text-[color:var(--primary)]">
				LA FICHA
			</h2>
			{#if obra.autor_ficha_publico || publicadaLabel}
				<dl class="mt-2 flex flex-wrap gap-x-8 gap-y-2 text-sm">
					{#if obra.autor_ficha_publico}
						<div>
							<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
								Editor a cargo
							</dt>
							<dd class="mt-0.5 flex items-center gap-2 font-medium">
								<span>{obra.autor_ficha_publico}</span>
								{#if editorOrcidHref}
									<a
										class="inline-flex items-center text-[color:var(--muted-foreground)] transition-colors hover:text-[color:var(--foreground)]"
										href={editorOrcidHref}
										target="_blank"
										rel="noreferrer"
										aria-label={`ORCID de ${obra.autor_ficha_publico}`}
									>
										<OrcidIcon size={15} />
										<span class="sr-only">ORCID</span>
									</a>
								{/if}
							</dd>
						</div>
					{/if}
					{#if publicadaLabel}
						<div>
							<dt class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
								Publicada
							</dt>
							<dd class="mt-0.5 font-medium">{publicadaLabel}</dd>
							{#if actualizadaLabel}
								<dd class="text-xs text-[color:var(--muted-foreground)]">Actualizada el {actualizadaLabel}</dd>
							{/if}
						</div>
					{/if}
				</dl>
			{/if}

			{#if (obra.edicion ?? '').trim().length > 0}
				<div class="mt-3">
					<div class="mb-0.5 text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
						Edición base usada
					</div>
					<div class="space-y-2 text-xs leading-5">{@html renderMarkdown(obra.edicion ?? '')}</div>
				</div>
			{/if}

			<CitaDeFicha
				titulo={obra.titulo}
				autorFicha={obra.autor_ficha_publico}
				updatedAt={fechaDeLaVersion}
				obraSlug={obra.slug}
			/>
		</section>
	</header>

	{#if tabs.length > 0}
		<Tabs tabs={tabs} active={activeTab} onChange={(id) => (activeTab = id as TabId)} />
	{/if}

	{#if activeTab === 'estructura'}
		{#if showMetrica}
			<section class="space-y-6">
				<MetricWorkSummary summary={tecnica} />
				<div class="space-y-3">
					<div class="mb-3 flex flex-wrap items-center justify-between gap-3">
						<div class="flex flex-wrap items-center gap-2">
							<button
								type="button"
								class={`border px-3 py-2 text-xs font-semibold tracking-[0.05em] ${metricViewMode === 'obra_completa' ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white text-[color:var(--gray-800)]'}`}
								onclick={() => (metricViewMode = 'obra_completa')}
							>
								Obra completa
							</button>
							<button
								type="button"
								class={`border px-3 py-2 text-xs font-semibold tracking-[0.05em] ${metricViewMode === 'por_jornadas' ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white text-[color:var(--gray-800)]'}`}
								onclick={() => (metricViewMode = 'por_jornadas')}
							>
								Por jornadas
							</button>
						</div>
						<div class="flex flex-wrap items-center gap-2">
							<span class="text-xs text-[color:var(--muted-foreground)]">Perfil métrico:</span>
							<button
								type="button"
								class={`border px-2 py-1 text-xs font-semibold ${pieValueMode === 'percent' ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white text-[color:var(--gray-800)]'}`}
								onclick={() => (pieValueMode = 'percent')}
							>
								%
							</button>
							<button
								type="button"
								class={`border px-2 py-1 text-xs font-semibold ${pieValueMode === 'absolute' ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white text-[color:var(--gray-800)]'}`}
								onclick={() => (pieValueMode = 'absolute')}
							>
								Nº versos
							</button>
						</div>
					</div>

					{#if secuenciasOrdenadas.length === 0}
						<p class="text-sm text-[color:var(--muted-foreground)]">
							No hay secuencias métricas registradas para esta obra.
						</p>
					{:else}
						<FiguraDescargable figura={figuraCodigoDeBarras} procedencia={procedenciaFigura}>
							{#if metricViewMode === 'obra_completa'}
								<!-- El margen de arriba es el sitio de los versos de los cortes, que salen al pasar por
								     la leyenda: sin él se montaban sobre los controles de la vista. -->
								<div class="mt-10"></div>
								<MetricBarcode
									segments={barSegments}
									totalVerses={totalVersos}
									jornadaMarkers={rayasDeJornada}
									cuadroMarkers={rayasDeCuadro}
									colorByForma={colorByForma}
									onOpenSegment={openSequenceModal}
									highlightedForma={formaForGroup('obra')}
									markerLabels={cortesALaVista}
									showSubsegments
								/>
								<div class="mt-5 flex flex-wrap items-center gap-4 text-xs text-[color:var(--muted-foreground)]">
									<span
										class="inline-flex cursor-default items-center gap-2 hover:text-[color:var(--foreground)]"
										role="presentation"
										onpointerenter={() => (cortesALaVista = 'jornada')}
										onpointerleave={() => (cortesALaVista = null)}
									>
										<span class="inline-block h-3 w-[2px] bg-[color:var(--gray-900)]"></span>
										Corte de jornada
									</span>
									<span
										class="inline-flex cursor-default items-center gap-2 hover:text-[color:var(--foreground)]"
										role="presentation"
										onpointerenter={() => (cortesALaVista = 'cuadro')}
										onpointerleave={() => (cortesALaVista = null)}
									>
										<span class="inline-block h-3 w-3 border-l border-dashed border-[color:var(--gray-500)]"></span>
										Corte de cuadro
									</span>
								</div>
							{:else}
								<div class="space-y-5">
									{#each jornadas as jornada (jornada.jornada_id)}
										<div>
											<h3 class="mb-4 text-sm font-semibold">
												Jornada {jornada.jornada_num} (vv. {jornada.v_ini}-{jornada.v_fin})
											</h3>
											<MetricBarcode
												segments={segmentsByJornada.get(jornada.jornada_id) ?? []}
												totalVerses={totalVersos}
												rangeStart={jornada.v_ini}
												rangeEnd={jornada.v_fin}
												cuadroMarkers={rayasDeCuadro}
												colorByForma={colorByForma}
												onOpenSegment={openSequenceModal}
												highlightedForma={formaForGroup(jornada.jornada_id)}
												showSubsegments
											/>
										</div>
									{/each}
								</div>
							{/if}
							{#snippet grafico()}
								<MetricBarcodeFigura filas={filasDeBarras} colorByForma={colorByForma} />
							{/snippet}
						</FiguraDescargable>
					{/if}
				</div>

				{#snippet perfilEnPantalla()}
					{#if metricViewMode === 'obra_completa'}
						<MetricDistributionPie
							items={distribucionFormasSlices}
							sequences={secuenciasOrdenadas}
							colorByForma={colorByForma}
							arquitecturasPorForma={data.arquitecturasPorForma}
							valueMode={pieValueMode}
							highlightedForma={formaForGroup('obra')}
							onHoverForma={(forma) => (hoveredForma = forma ? { groupId: 'obra', forma } : null)}
						/>
					{:else}
						<div class="space-y-5">
							{#each metricProfilesByJornada as profile (profile.jornada.jornada_id)}
								<MetricDistributionPie
									title={`Perfil métrico · Jornada ${profile.jornada.jornada_num}`}
									items={profile.distribution}
									sequences={profile.sequences}
									colorByForma={colorByForma}
									arquitecturasPorForma={data.arquitecturasPorForma}
									valueMode={pieValueMode}
									highlightedForma={formaForGroup(profile.jornada.jornada_id)}
									onHoverForma={(forma) =>
										(hoveredForma = forma ? { groupId: profile.jornada.jornada_id, forma } : null)}
								/>
							{/each}
						</div>
					{/if}
				{/snippet}
				{#if secuenciasOrdenadas.length > 0}
					<FiguraDescargable figura={figuraPerfil} procedencia={procedenciaFigura}>
						{@render perfilEnPantalla()}
						{#snippet grafico()}
							<MetricDistributionPieFigura
								grupos={gruposDelPerfil}
								colorByForma={colorByForma}
								valueMode={pieValueMode}
							/>
						{/snippet}
					</FiguraDescargable>
				{:else}
					{@render perfilEnPantalla()}
				{/if}
			</section>
		{/if}
	{:else if activeTab === 'esquema'}
		{#if showMetrica}
			<section class="space-y-6">
				<h2 class="text-lg font-semibold">Esquema métrico</h2>

				<!-- «Localizar en la obra» vive en Análisis: es una herramienta de consulta, y aquí
				     sobra. Esta pestaña contesta qué hay en cada verso y no lleva nada más. -->

				{#if schemeEntries.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">
						No hay secuencias métricas registradas para esta obra.
					</p>
				{:else}
					<MetricScheme
						entries={schemeEntries}
						colorByForma={colorByForma}
						cuadros={cuadrosConRango}
						onOpen={openSequenceModal}
					/>
				{/if}
			</section>
		{/if}
	{:else if activeTab === 'analisis'}
		{#if showMetrica}
			<!--
				**El índice es una columna al lado, no otra fila de pastillas.** Con chips debajo de las
				pestañas había dos filas seguidas hablando el mismo idioma, y la segunda parecía un
				segundo juego de pestañas. Como columna se lee por lo que es —un sumario— y se queda a
				la vista mientras se recorre la pestaña, que era el problema de partida.

				Por debajo de `xl` no hay sitio para la columna y se pliega en un desplegable, cerrado,
				que no gasta alto ni imita a nada.
			-->
			<div class="grid gap-8 xl:grid-cols-[13rem_minmax(0,1fr)]">
				{#if indiceAnalisis.length > 0}
					<details class="border-b border-[color:var(--border)] pb-3 xl:hidden">
						<summary class="cursor-pointer text-sm font-semibold">Ir a una sección</summary>
						<div class="mt-3 space-y-3">
							{#each indiceAnalisis as grupo (grupo.grupo)}
								<div>
									<p class="text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)]">
										{grupo.grupo}
									</p>
									<ul class="mt-1 space-y-1">
										{#each grupo.items as item (item.id)}
											<li>
												<a class="text-sm underline-offset-4 hover:underline" href={`#${item.id}`}>
													{item.label}
												</a>
											</li>
										{/each}
									</ul>
								</div>
							{/each}
						</div>
					</details>

					<nav
						class="sticky top-4 hidden self-start border-l border-[color:var(--border)] pl-4 xl:block"
						aria-label="Secciones del análisis"
					>
						{#each indiceAnalisis as grupo (grupo.grupo)}
							<p
								class="mt-4 text-xs font-semibold uppercase tracking-[0.06em] text-[color:var(--muted-foreground)] first:mt-0"
							>
								{grupo.grupo}
							</p>
							<ul class="mt-1.5 space-y-1.5">
								{#each grupo.items as item (item.id)}
									<li>
										<a
											class="block text-sm leading-snug text-[color:var(--gray-700)] underline-offset-4 hover:text-[color:var(--primary)] hover:underline"
											href={`#${item.id}`}
										>
											{item.label}
										</a>
									</li>
								{/each}
							</ul>
						{/each}
					</nav>
				{/if}

			<section class="space-y-10">

				<div id="analisis-donde-cae" class="space-y-3 scroll-mt-4">
					<MetricAnalysisHeading
						title="Dónde cae cada forma"
						description="En qué punto de la obra aparece cada forma. Las líneas verticales son los cambios de jornada."
					/>
					<FiguraDescargable figura={figuraFranjas} procedencia={procedenciaFigura}>
						<MetricFormStrips
							filas={franjas}
							totalVersos={totalVersos}
							colorByForma={colorByForma}
							jornadas={jornadas.map((jornada) => jornada.v_ini)}
							resaltada={hoveredForma?.forma ?? null}
							onOpenSequence={openSequenceModal}
							onHoverForma={(forma) =>
								(hoveredForma = forma ? { groupId: 'analisis', forma } : null)}
						/>
						{#snippet grafico({ paleta })}
							<MetricFormStrips
								filas={franjas}
								totalVersos={totalVersos}
								colorByForma={colorByForma}
								jornadas={jornadas.map((jornada) => jornada.v_ini)}
								modo="figura"
								{paleta}
							/>
						{/snippet}
					</FiguraDescargable>
				</div>

				<!--
					**Un bloque por fila, aunque sobre ancho.** Se probaron dos columnas para aprovechar
					la pantalla y se cortaba justo lo que hay que leer: la tabla de secuencias perdía sus
					últimas columnas tras una barra de desplazamiento, y las transiciones quedaban en
					«Red… → Rom…». El sumario de la izquierda ya recupera el alto que costaba recorrer la
					pestaña; el ancho sobrante no vale lo que cuesta.
				-->
				<div id="analisis-como-cambia" class="space-y-3 scroll-mt-4">
					<MetricAnalysisHeading
						title="El peso de cada forma en cada jornada"
						description="Cuánto ocupa cada forma dentro de cada jornada, para ver si crece, se retira o aparece. Un círculo hueco quiere decir que esa jornada no la usa."
					/>
					{#if momentos.length < 2}
						<p class="text-sm text-[color:var(--muted-foreground)]">
							Hace falta más de una jornada anotada para poder comparar.
						</p>
					{:else}
						<FiguraDescargable figura={figuraPendientes} procedencia={procedenciaFigura}>
							<MetricSlopeChart
								momentos={momentos}
								series={pendientes}
								colorByForma={colorByForma}
								resaltada={hoveredForma?.forma ?? null}
								onHoverForma={(forma) =>
									(hoveredForma = forma ? { groupId: 'analisis', forma } : null)}
							/>
							{#snippet grafico({ paleta })}
								<MetricSlopeChart
									momentos={momentos}
									series={pendientes}
									colorByForma={colorByForma}
									modo="figura"
									{paleta}
								/>
							{/snippet}
						</FiguraDescargable>
					{/if}
				</div>

				{#if tradiciones.length > 0}
					<div id="analisis-tradiciones" class="space-y-3 scroll-mt-4">
						<MetricAnalysisHeading
							title="Españolas e italianas por jornada"
							description="De qué tradición métrica es cada jornada. La línea de puntos marca la mitad."
						/>
						<!-- Sin tabla al lado: el gráfico da la cifra dentro de cada tramo —a dos
						     decimales, como todo porcentaje del proyecto— y repetirla en columnas no
						     añadía nada. -->
						<FiguraDescargable figura={figuraTradiciones} procedencia={procedenciaFigura}>
							<MetricTraditionSplit puntos={repartoDeTradiciones} />
							{#snippet grafico({ paleta })}
								<MetricTraditionSplit puntos={repartoDeTradiciones} modo="figura" {paleta} />
							{/snippet}
						</FiguraDescargable>
					</div>
				{/if}

				{#if evolucionDeLaObra.length > 1}
					<div id="analisis-evolucion" class="scroll-mt-4">
						<MetricEvolution puntos={evolucionDeLaObra} />
					</div>
				{/if}

				{#if secuenciasPorFormaDeLaObra.length > 0}
					<div id="analisis-secuencias" class="scroll-mt-4">
						<MetricRunTable rows={secuenciasPorFormaDeLaObra} colorByForma={colorByForma} />
					</div>
				{/if}

				{#if transicionesDeLaObra.length > 0}
					<div id="analisis-transiciones" class="scroll-mt-4">
						<MetricTransitions rows={transicionesDeLaObra} onOpen={openSequenceModal} colorByForma={colorByForma} />
					</div>
				{/if}

				<div id="analisis-articulacion" class="scroll-mt-4">
					<MetricDramaticArticulation
						cuts={cortesCuadro}
						jornadas={extremosDeJornadas}
						colorByForma={colorByForma}
						onOpen={openSequenceModal}
					/>
				</div>

				{#if caracterizacionesEnunciativas.length > 0}
					<div id="analisis-enunciacion" class="scroll-mt-4">
						<MetricEnunciationSummary rows={caracterizacionesEnunciativas} />
					</div>
				{/if}

				<!-- Cierra la pestaña porque es lo único que no contesta una pregunta sino que
				     lleva a un sitio: se usa después de haber leído, no antes. -->
				{#if phenomenaIndex.length > 0}
					<div id="analisis-localizar" class="scroll-mt-4">
						<MetricPhenomenaIndex
							groups={phenomenaIndex}
							colorByForma={colorByForma}
							onOpen={openSequenceModal}
						/>
					</div>
				{/if}
			</section>
			</div>
		{/if}
	{:else if activeTab === 'sinopsis_metrica'}
		{#if showSinopsisMetrica}
			<section class="space-y-4">
				<div>
					<h2 class="text-lg font-semibold">Sinopsis</h2>
					<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
						{sinopsisMetricaSequences.length} secuencias
						{#if sinopsisMetricaMissingCount > 0}
							· {sinopsisMetricaMissingCount} sin sinopsis
						{/if}
					</p>
				</div>
				<SequenceSynopsisView groups={sinopsisMetricaGroups} colorByForma={colorByForma} />
			</section>
		{/if}
	{:else if activeTab === 'observaciones'}
		{#if showObservaciones}
			<section class="space-y-3 border-t border-[color:var(--border)] pt-4">
				<h2 class="text-lg font-semibold">Observaciones</h2>
				{#if hasObservaciones}
					<div class="space-y-2 text-sm leading-7">{@html renderMarkdown(obra.observaciones ?? '')}</div>
				{:else}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin observaciones publicadas.</p>
				{/if}
			</section>
		{/if}
	{:else if activeTab === 'bibliografia'}
		{#if showBibliografia}
			<section class="space-y-3 border-t border-[color:var(--border)] pt-4">
				<h2 class="text-lg font-semibold">Bibliografía métrica</h2>
				{#if hasBibliografia}
					<div class="space-y-2 text-sm leading-7">{@html renderMarkdown(obra.bibliografia ?? '')}</div>
				{:else}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin bibliografía métrica publicada.</p>
				{/if}
			</section>
		{/if}
	{/if}

	<SequenceDetailModal
		open={selectedSequence !== null}
		secuencia={selectedSequence}
		structure={selectedSequenceStructure}
		comentariosPublicos={showComentarios ? selectedSequenceComments : []}
		index={Math.max(selectedSequenceIndex, 0)}
		total={secuenciasOrdenadas.length}
		canPrev={selectedSequenceIndex > 0}
		canNext={selectedSequenceIndex >= 0 && selectedSequenceIndex < secuenciasOrdenadas.length - 1}
		previousLabel={previousSequenceLabel}
		nextLabel={nextSequenceLabel}
		onClose={closeSequenceModal}
		onPrev={openPrevSequence}
		onNext={openNextSequence}
	/>
</section>

<script lang="ts">
	import { browser } from '$app/environment';
	import { onDestroy, untrack } from 'svelte';
	import ChevronLeft from 'lucide-svelte/icons/chevron-left';
	import ChevronRight from 'lucide-svelte/icons/chevron-right';
	import Eye from 'lucide-svelte/icons/eye';
	import Pencil from 'lucide-svelte/icons/pencil';
	import Trash2 from 'lucide-svelte/icons/trash-2';
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import NullableBooleanChoice from '$lib/components/ui/nullable-boolean-choice.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import RangeConsistencyAlert from '$lib/components/editor/RangeConsistencyAlert.svelte';
	import SequenceSynopsisModal from '$lib/components/editor/SequenceSynopsisModal.svelte';
	import UnsavedChangesModal from '$lib/components/editor/UnsavedChangesModal.svelte';
	import { buildSequenceSynopsisGroups } from '$lib/components/editor/sequence-synopsis';
	import { pushToast } from '$lib/stores/toast';
	import { patchCurrentObra } from '$lib/stores/currentObra';
	import type { EditorCuadroRow, EditorJornadaRow, EditorSecuenciaRow } from '$lib/types/editor.types';
	import { displayTerm } from '$lib/utils/vocabulario';
	import MetricSequenceEditor from '$lib/components/metrica/editor-v2/MetricSequenceEditor.svelte';
	import MetricSequenceModal from '$lib/components/metrica/editor-v2/MetricSequenceModal.svelte';
	import MetricPanelSection from '$lib/components/metrica/editor-v2/MetricPanelSection.svelte';
	import { draftFromRows } from '$lib/components/metrica/editor-v2/sequence-draft';
	import type {
		MetricSequenceDraft,
		MetricSequenceEditorState
	} from '$lib/components/metrica/editor-v2/sequence-draft';
	import type { MetricCatalogDomainRow, MetricCatalogForEditor } from '$lib/metrica/catalogo';
	import CaracterizacionesDeLaSecuencia from './secuencias/CaracterizacionesDeLaSecuencia.svelte';
	import DeDondeVieneLaSecuencia from './secuencias/DeDondeVieneLaSecuencia.svelte';
	import type { PropuestaDeSecuencia } from './secuencias/DeDondeVieneLaSecuencia.svelte';
	import CaracterizacionesPorRango from './secuencias/CaracterizacionesPorRango.svelte';
	import {
		analyzeSequenceRangeConsistency,
		collectRangeConsistencyIds
	} from '$lib/utils/range-consistency';

	const props = $props<{
		obraId: string;
		secuenciasInitial: EditorSecuenciaRow[];
		jornadasInitial: EditorJornadaRow[];
		cuadrosInitial: EditorCuadroRow[];
		estrofaOptions: Array<
			Pick<
				Tables<'vocabularios'>,
				'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id' | 'orden' | 'tipo_forma'
			>
		>;
		caracterizacionRangoOptions: Array<
			Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id' | 'orden'>
		>;
		readOnly?: boolean;
		canComment?: boolean;
		focusSecuenciaId?: string | null;
		focusComentarioId?: string | null;
		commentsReloadKey?: string | number | null;
		onSecuenciasChange?: (items: EditorSecuenciaRow[]) => void;
		/**
		 * Las anotaciones confirmadas en esta visita, antes de que una recarga vuelva a traerlas.
		 *
		 * **Vive en la página y no aquí**: cambiar de pestaña desmonta este componente, y guardado
		 * dentro se perdía al volver —la columna «Forma» decía «Pendiente» hasta recargar—.
		 */
		anotacionesEnSesion: Map<string, MetricSequenceDraft>;
		onAnotacionMetricaGuardada?: (secuenciaId: string, borrador: MetricSequenceDraft) => void;
		onPendingChangesChange?: (pending: boolean) => void;
		// Señala que cambió algún dato que alimenta obras_resumen pero que NO altera
		// la lista de secuencias: hoy, las caracterizaciones por rango.
		onMetricaDirty?: () => void;
		/**
		 * Lo que la obra tiene marcado que no hay. Marcarlo cierra la pregunta en todas sus
		 * secuencias; sin marcar, cada una la responde.
		 */
		loQueNoHay?: {
			donaire: boolean;
			personajesSobrenaturales: boolean;
			eventosSobrenaturales: boolean;
		} | null;
		/** El catálogo métrico. Sin él no hay editor nuevo que montar, y se cae al panel de siempre. */
		catalogoMetrico?: MetricCatalogForEditor | null;
		/** Lo que esta obra ya tiene anotado con el catálogo nuevo, para releerlo al abrir. */
		anotacionMetrica?: {
			secuencias: MetricCatalogDomainRow[];
			unidades: MetricCatalogDomainRow[];
			elecciones: MetricCatalogDomainRow[];
			desviaciones: MetricCatalogDomainRow[];
		} | null;
	}>();

	type IntervencionValue = 'sin_intervencion' | 'exclusiva' | 'compartida';

	/**
	 * Lo que no hay en la obra, y por eso abre esta pestaña: se marca **antes de anotar**.
	 *
	 * Vive aquí y no en los datos de la obra: allí está su identidad —título, género, fechas,
	 * edición— y esto es un hecho de la dramaturgia que **solo usa esta pantalla**. Marcarlo con las
	 * secuencias delante es lo que hace que se entienda.
	 */
	type ClaveDeclaracion =
		| 'sin_figuras_donaire'
		| 'sin_personajes_sobrenaturales'
		| 'sin_eventos_sobrenaturales';

	/**
	 * **La pregunta no es simétrica, y por eso no se responde con sí y no.** Decir que no cierra la
	 * pregunta en todas las secuencias; decir que sí no marcaría un sí en ninguna, solo dejaría de
	 * cerrarla, que es lo que ya pasa mientras nadie diga nada. Con un sí y un no juntos, marcar sí
	 * parece hacer lo contrario de marcar no, y no hace nada. Así que es una casilla: se marca para
	 * dejar de preguntarlo, y se desmarca para volver a preguntarlo.
	 */
	const DECLARACIONES: Array<{
		clave: ClaveDeclaracion;
		etiqueta: string;
		casilla: string;
		ayuda: string;
		loDeclaran: (secuencia: EditorSecuenciaRow) => boolean;
	}> = [
		{
			clave: 'sin_figuras_donaire',
			etiqueta: 'Figuras de donaire',
			casilla: 'No hay en esta obra',
			ayuda:
				'La figura del donaire. Al marcar que no la hay, las secuencias dejan de preguntarlo y quedan en «sin intervención».',
			loDeclaran: (secuencia) =>
				secuencia.intervencion_figuras_donaire === 'exclusiva' ||
				secuencia.intervencion_figuras_donaire === 'compartida'
		},
		{
			clave: 'sin_personajes_sobrenaturales',
			etiqueta: 'Personajes sobrenaturales',
			casilla: 'No hay en esta obra',
			ayuda:
				'Personajes alegóricos, magos, demonios, santos que obran milagros, apariciones. Al marcar que no los hay, las secuencias dejan de preguntarlo.',
			loDeclaran: (secuencia) =>
				secuencia.intervencion_personajes_sobrenaturales === 'exclusiva' ||
				secuencia.intervencion_personajes_sobrenaturales === 'compartida'
		},
		{
			clave: 'sin_eventos_sobrenaturales',
			etiqueta: 'Eventos sobrenaturales',
			casilla: 'No ocurren en esta obra',
			ayuda:
				'Un milagro, una aparición, una transformación. Ocurren aunque no hable ningún personaje sobrenatural, y por eso se preguntan aparte.',
			loDeclaran: (secuencia) => secuencia.evento_sobrenatural === true
		}
	];

	// Viene abierto: es lo primero que hay que mirar al llegar. Una vez marcado, se pliega y no
	// vuelve a ocupar sitio.
	let declaracionesAbiertas = $state(true);

	/** Cuántas secuencias lo declaran: es lo que impide cerrarlo, y conviene decir cuántas son. */
	function cuantasLoDeclaran(declaracion: (typeof DECLARACIONES)[number]) {
		return secuencias.filter((secuencia) => declaracion.loDeclaran(secuencia)).length;
	}

	let guardandoDeclaracion = $state<ClaveDeclaracion | null>(null);

	/**
	 * Al marcarlo, la base responde por las secuencias que callaban. Esto hace lo mismo con las que
	 * la pantalla tiene en memoria, para no releerlas enteras ni dejarlas diciendo «pendiente» encima
	 * de una respuesta que ya está guardada.
	 */
	function responderPorLasSecuencias(clave: ClaveDeclaracion) {
		const next = secuencias.map((secuencia) => {
			if (clave === 'sin_figuras_donaire' && secuencia.intervencion_figuras_donaire === null) {
				return { ...secuencia, intervencion_figuras_donaire: 'sin_intervencion' };
			}
			if (
				clave === 'sin_personajes_sobrenaturales' &&
				secuencia.intervencion_personajes_sobrenaturales === null
			) {
				return { ...secuencia, intervencion_personajes_sobrenaturales: 'sin_intervencion' };
			}
			if (clave === 'sin_eventos_sobrenaturales' && secuencia.evento_sobrenatural === null) {
				return { ...secuencia, evento_sobrenatural: false };
			}
			return secuencia;
		});
		secuencias = next;
		emitSecuenciasChange(next);
	}

	const declaracionesActuales = $derived({
		sin_figuras_donaire: props.loQueNoHay?.donaire ?? false,
		sin_personajes_sobrenaturales: props.loQueNoHay?.personajesSobrenaturales ?? false,
		sin_eventos_sobrenaturales: props.loQueNoHay?.eventosSobrenaturales ?? false
	});

	async function declarar(clave: ClaveDeclaracion, valor: boolean) {
		if (props.readOnly || guardandoDeclaracion) return;
		guardandoDeclaracion = clave;
		const response = await fetch(`/api/obras/${props.obraId}/declaraciones`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ ...declaracionesActuales, [clave]: valor })
		});
		guardandoDeclaracion = null;

		if (!response.ok) {
			// Cuando alguna secuencia declara lo contrario, el mensaje del disparador dice qué quitar
			// antes; se enseña tal cual y no se toca nada en pantalla.
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo guardar lo que la obra no tiene');
			return;
		}

		const payload = await response.json();
		patchCurrentObra(payload.obra);
		if (valor) responderPorLasSecuencias(clave);
		pushToast('success', 'Guardado');
	}

	type FormState = {
		v_ini: number;
		v_fin: number;
		estrofa_tipo_id: string;
		inaugura_espacio: boolean | null;
		versos_partidos: boolean | null;
		intervencion_personajes_femeninos: IntervencionValue | null;
		intervencion_figuras_donaire: IntervencionValue | null;
		intervencion_personajes_sobrenaturales: IntervencionValue | null;
		evento_sobrenatural: boolean | null;
		sinopsis: string;
	};

	type PendingSidebarAction =
		| { kind: 'close' }
		| { kind: 'new' }
		| { kind: 'sequence'; target: EditorSecuenciaRow };

	let secuencias = $state(untrack(() => [...props.secuenciasInitial]));
	let sidebarOpen = $state(false);
	let editingId = $state<string | null>(null);
	let filtroForma = $state('');
	let filtroFormaDraft = $state('');

	function aplicarFiltroForma() {
		filtroForma = filtroFormaDraft;
	}

	function limpiarFiltroForma() {
		filtroFormaDraft = '';
		filtroForma = '';
	}
	let deleteTargetId = $state<string | null>(null);
	let deletingSequence = $state(false);
	let sequenceSynopsisModalOpen = $state(false);
	let pendingSidebarAction = $state<PendingSidebarAction | null>(null);

	let sidebarSaving = $state(false);
	let sidebarDirty = $state(false);
	let sidebarBaselineSnapshot = $state('');
	let lastReportedPending = false;
	/**
	 * El editor conserva su borrador internamente. Cambiar de secuencia tiene que remontarlo, pero
	 * convertir una secuencia nueva en guardada no: durante ese primer guardado el `editingId` pasa de
	 * nulo al id real y los datos de la página aún no incluyen su anotación.
	 */
	let editorSessionKey = $state(0);
	const borradoresMetricosEnSesion = $derived(props.anotacionesEnSesion);
	/** El componente de caracterizaciones, para recargarlo y cerrarlo desde aquí. */
	let caracterizaciones = $state<CaracterizacionesPorRango | null>(null);
	let handledFocusSecuenciaId = $state<string | null>(null);
	function sortEstrofaOptions(options: typeof props.estrofaOptions) {
		return [...options].sort(
			(a, b) => (a.orden ?? Number.MAX_SAFE_INTEGER) - (b.orden ?? Number.MAX_SAFE_INTEGER) ||
				a.termino.localeCompare(b.termino, 'es')
		);
	}

	function normalizeTerm(value: string): string {
		return value
			.normalize('NFD')
			.replaceAll(/\p{M}/gu, '')
			.trim()
			.toLowerCase()
			.replaceAll(/[\s-]+/g, '_');
	}

	const sortedEstrofaOptions = $derived.by(() => sortEstrofaOptions(props.estrofaOptions));
	const estrofaById = $derived.by(
		() =>
			new Map<string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id'>>(
				sortedEstrofaOptions.map(
					(
						option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id'>
					): readonly [string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id'>] => [
						option.termino_id,
						option
					]
				)
			)
	);
	const quintillaRootId = $derived.by(() => {
		const root = sortedEstrofaOptions.find(
			(option) => !option.termino_padre_id && normalizeTerm(option.termino) === 'quintilla'
		);
		return root?.termino_id ?? null;
	});
	const estrofaSelectableOptions = $derived.by(() =>
		sortedEstrofaOptions.filter((option) => {
			if (!quintillaRootId) return true;
			let parentId = option.termino_padre_id;
			while (parentId) {
				if (parentId === quintillaRootId) return false;
				parentId = estrofaById.get(parentId)?.termino_padre_id ?? null;
			}
			return true;
		})
	);
	const estrofaSelectableIds = $derived.by(() => new Set(estrofaSelectableOptions.map((option) => option.termino_id)));
	const formaDropdownItems = $derived.by(() =>
		(props.catalogoMetrico?.forms ?? []).map((forma) => ({
			id: forma.forma_id,
			label: forma.nombre
		}))
	);
	function toSelectableEstrofaId(termId: string | null | undefined): string {
		if (!termId) return '';
		if (estrofaSelectableIds.has(termId)) return termId;

		let cursor = estrofaById.get(termId) ?? null;
		while (cursor?.termino_padre_id) {
			const parentId = cursor.termino_padre_id;
			if (estrofaSelectableIds.has(parentId)) return parentId;
			cursor = estrofaById.get(parentId) ?? null;
		}

		return '';
	}

	function getSuggestedSecuenciaStart(): number {
		const maxVFin = secuencias.reduce((max, item) => Math.max(max, Number(item.v_fin) || 0), 0);
		return maxVFin > 0 ? maxVFin + 1 : 1;
	}

	/**
	 * Lo que la obra declara que no hay es **la respuesta** de la secuencia, no un hueco.
	 *
	 * La pantalla ya lo enseñaba así, pero solo al mirar: el formulario seguía en nulo y la fila se
	 * guardaba sin responder. El disparador de la base responde por las secuencias que existían al
	 * marcar la casilla, y como se marca antes de anotar, toda secuencia nacía después con el hueco:
	 * el raíl contaba «4 de 6» y la revisión de la obra se quedaba bloqueada.
	 */
	function conLoQueLaObraDeclara(valores: FormState): FormState {
		return {
			...valores,
			intervencion_figuras_donaire: props.loQueNoHay?.donaire
				? 'sin_intervencion'
				: valores.intervencion_figuras_donaire,
			intervencion_personajes_sobrenaturales: props.loQueNoHay?.personajesSobrenaturales
				? 'sin_intervencion'
				: valores.intervencion_personajes_sobrenaturales,
			evento_sobrenatural: props.loQueNoHay?.eventosSobrenaturales
				? false
				: valores.evento_sobrenatural
		};
	}

	function initialForm(): FormState {
		const suggestedStart = getSuggestedSecuenciaStart();
		return conLoQueLaObraDeclara({
			v_ini: suggestedStart,
			v_fin: suggestedStart + 1,
			estrofa_tipo_id: '',
			inaugura_espacio: null,
			versos_partidos: null,
			intervencion_personajes_femeninos: null,
			intervencion_figuras_donaire: null,
			intervencion_personajes_sobrenaturales: null,
			evento_sobrenatural: null,
			sinopsis: ''
		});
	}

	let form = $state<FormState>(initialForm());

	/**
	 * La tabla lee solo la anotación V2: `estrofa_tipo_id` queda fuera de esta vista.
	 * Mientras la página no se recarga, la última anotación confirmada vive en el borrador de esta
	 * sesión; después, la misma respuesta llega en `props.anotacionMetrica`.
	 */
	function formaIdDeSecuencia(secuencia: EditorSecuenciaRow): string | null {
		const formaEnSesion = borradoresMetricosEnSesion.get(secuencia.secuencia_id)?.forma_id;
		const anotacionGuardada = (props.anotacionMetrica?.secuencias ?? []).find(
			(fila: MetricCatalogDomainRow) => String(fila.secuencia_id) === secuencia.secuencia_id
		);
		return formaEnSesion ?? (anotacionGuardada?.forma_id ? String(anotacionGuardada.forma_id) : null);
	}

	function formaDeSecuencia(secuencia: EditorSecuenciaRow): string {
		const formaId = formaIdDeSecuencia(secuencia);
		if (formaId) {
			return (
				props.catalogoMetrico?.forms.find((forma) => forma.forma_id === formaId)?.nombre ??
				'Forma registrada'
			);
		}
		return 'Pendiente';
	}

	function sortSecuencias(items: EditorSecuenciaRow[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini);
	}

	function sortJornadas(items: EditorJornadaRow[]) {
		return [...items].sort(
			(a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin || a.jornada_num - b.jornada_num
		);
	}

	function sortCuadros(items: EditorCuadroRow[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin || a.cuadro_num - b.cuadro_num);
	}

	function emitSecuenciasChange(nextItems: EditorSecuenciaRow[] = secuencias) {
		props.onSecuenciasChange?.(sortSecuencias(nextItems));
	}

	const jornadasSorted = $derived.by(() => sortJornadas(props.jornadasInitial));
	const cuadrosSorted = $derived.by(() => sortCuadros(props.cuadrosInitial));

	const filteredSecuencias = $derived.by(() => {
		return secuencias
			.filter((secuencia) => !filtroForma || formaIdDeSecuencia(secuencia) === filtroForma)
			.sort((a, b) => a.v_ini - b.v_ini);
	});
	// Todas las secuencias ordenadas, para numerar y navegar en el panel de edición.
	const orderedSecuencias = $derived.by(() => sortSecuencias(secuencias));
	const sequenceOverlapIssues = $derived.by(() => analyzeSequenceRangeConsistency(secuencias));
	const sequenceOverlapIds = $derived(collectRangeConsistencyIds(sequenceOverlapIssues));
	const editingIndex = $derived.by(() =>
		editingId ? orderedSecuencias.findIndex((item) => item.secuencia_id === editingId) : -1
	);
	const prevSecuencia = $derived.by(() =>
		editingIndex > 0 ? orderedSecuencias[editingIndex - 1] : null
	);
	const nextSecuencia = $derived.by(() =>
		editingIndex >= 0 && editingIndex < orderedSecuencias.length - 1
			? orderedSecuencias[editingIndex + 1]
			: null
	);
	const totalVersosEstructura = $derived.by(() => {
		if (jornadasSorted.length === 0) return null;
		const maxVFin = jornadasSorted.reduce((max, jornada) => Math.max(max, Number(jornada.v_fin) || 0), 0);
		return maxVFin > 0 ? maxVFin : null;
	});
	const totalVersosDeclaradosFiltrados = $derived.by(() =>
		filteredSecuencias.reduce((sum, secuencia) => sum + (Number(secuencia.n_versos) || 0), 0)
	);
	const diferenciaFiltrada = $derived.by(() => {
		if (totalVersosEstructura === null) return null;
		return totalVersosDeclaradosFiltrados - totalVersosEstructura;
	});
	const cuadrosByJornada = $derived.by(() => {
		const grouped = new Map<string, EditorCuadroRow[]>();
		for (const cuadro of cuadrosSorted) {
			const items = grouped.get(cuadro.jornada_id) ?? [];
			items.push(cuadro);
			grouped.set(cuadro.jornada_id, items);
		}
		return grouped;
	});
	const sequenceSynopsisGroups = $derived.by(() =>
		buildSequenceSynopsisGroups({
			secuencias,
			jornadas: jornadasSorted,
			cuadros: cuadrosSorted,
			estrofaOptions: props.estrofaOptions
		})
	);
	const sequenceSynopsisMissingCount = $derived.by(
		() => secuencias.filter((secuencia) => !(secuencia.sinopsis ?? '').trim()).length
	);

	function openSequenceSynopsisModal() {
		sequenceSynopsisModalOpen = true;
	}

	function closeSequenceSynopsisModal() {
		sequenceSynopsisModalOpen = false;
	}

	function sidebarSnapshot(source: FormState = form, sourceEditingId: string | null = editingId): string {
		return JSON.stringify({
			sidebarOpen,
			id: sourceEditingId,
			v_ini: Number(source.v_ini),
			v_fin: Number(source.v_fin),
			estrofa_tipo_id: source.estrofa_tipo_id,
			inaugura_espacio: source.inaugura_espacio,
			versos_partidos: source.versos_partidos,
			intervencion_personajes_femeninos: source.intervencion_personajes_femeninos,
			intervencion_figuras_donaire: source.intervencion_figuras_donaire,
			intervencion_personajes_sobrenaturales: source.intervencion_personajes_sobrenaturales,
			evento_sobrenatural: source.evento_sobrenatural,
			sinopsis: source.sinopsis.trim()
		});
	}

	function reportPendingChanges(pending: boolean) {
		if (pending === lastReportedPending) return;
		lastReportedPending = pending;
		props.onPendingChangesChange?.(pending);
	}

	function setSidebarBaselineFromCurrent() {
		sidebarBaselineSnapshot = sidebarSnapshot();
		sidebarDirty = false;
		reportPendingChanges(false);
	}

	function refreshSidebarDirty() {
		if (!sidebarOpen) {
			sidebarDirty = false;
			return false;
		}
		const current = sidebarSnapshot();
		sidebarDirty = current !== sidebarBaselineSnapshot;
		return sidebarDirty;
	}

	function validateForm(showToast = true) {
		if (!Number.isFinite(Number(form.v_ini)) || !Number.isFinite(Number(form.v_fin)) || Number(form.v_ini) > Number(form.v_fin)) {
			if (showToast) pushToast('error', 'Rango de versos inválido');
			return false;
		}
		return true;
	}

	function openNew() {
		if (props.readOnly) return;
		editingId = null;
		form = initialForm();
		estadoMetrico = null;
		editorSessionKey += 1;
		caracterizaciones?.cerrarModales();
		sidebarOpen = true;
		pendingSidebarAction = null;
		setSidebarBaselineFromCurrent();
	}

	function openEdit(secuencia: EditorSecuenciaRow) {
		if (props.readOnly && !props.canComment) return;
		editingId = secuencia.secuencia_id;
		// Una secuencia guardada antes de este arreglo puede traer el hueco: abrirla lo cierra, y el
		// primer guardado lo escribe.
		form = conLoQueLaObraDeclara({
			v_ini: secuencia.v_ini,
			v_fin: secuencia.v_fin,
			estrofa_tipo_id: toSelectableEstrofaId(secuencia.estrofa_tipo_id),
			inaugura_espacio: secuencia.inaugura_espacio,
			versos_partidos: secuencia.versos_partidos,
			intervencion_personajes_femeninos: secuencia.intervencion_personajes_femeninos as IntervencionValue | null,
			intervencion_figuras_donaire: secuencia.intervencion_figuras_donaire as IntervencionValue | null,
			intervencion_personajes_sobrenaturales:
				secuencia.intervencion_personajes_sobrenaturales as IntervencionValue | null,
			evento_sobrenatural: secuencia.evento_sobrenatural,
			sinopsis: secuencia.sinopsis ?? ''
		});
		estadoMetrico = null;
		editorSessionKey += 1;
		caracterizaciones?.cerrarModales();
		sidebarOpen = true;
		pendingSidebarAction = null;
		setSidebarBaselineFromCurrent();
		// Solo cuesta la consulta si la secuencia venía anotada con el vocabulario viejo.
		if (secuencia.estrofa_tipo_id) void cargarPropuestas();
	}

	function requestOpenNew() {
		if (props.readOnly || sidebarSaving) return;
		if (sidebarOpen && refreshSidebarDirty()) {
			pendingSidebarAction = { kind: 'new' };
			return;
		}
		openNew();
	}

	function requestOpenEdit(secuencia: EditorSecuenciaRow) {
		if (sidebarSaving) return;
		if (sidebarOpen && editingId === secuencia.secuencia_id) return;
		if (!props.readOnly && sidebarOpen && refreshSidebarDirty()) {
			pendingSidebarAction = { kind: 'sequence', target: secuencia };
			return;
		}
		openEdit(secuencia);
	}

	function goToSecuencia(target: EditorSecuenciaRow | null) {
		if (!target || sidebarSaving) return;
		requestOpenEdit(target);
	}

	function performCloseSidebar() {
		sidebarOpen = false;
		editingId = null;
		caracterizaciones?.cerrarModales();
		sidebarDirty = false;
		sidebarBaselineSnapshot = '';
		pendingSidebarAction = null;
		reportPendingChanges(false);
	}

	function requestCloseSidebar() {
		if (props.readOnly) {
			performCloseSidebar();
			return;
		}
		if (!refreshSidebarDirty()) {
			performCloseSidebar();
			return;
		}
		pendingSidebarAction = { kind: 'close' };
	}

	function cancelPendingSidebarAction() {
		pendingSidebarAction = null;
	}

	function executeSidebarAction(action: PendingSidebarAction) {
		if (action.kind === 'close') {
			performCloseSidebar();
			return;
		}
		if (action.kind === 'new') {
			openNew();
			return;
		}
		openEdit(action.target);
	}

	function discardAndContinue() {
		const action = pendingSidebarAction;
		if (!action) return;
		pendingSidebarAction = null;
		executeSidebarAction(action);
	}

	async function saveAndContinue() {
		const action = pendingSidebarAction;
		if (!action) return;
		const saved = await save();
		if (!saved) return;
		pendingSidebarAction = null;
		executeSidebarAction(action);
	}

	async function save(): Promise<boolean> {
		if (!browser) return false;
		if (props.readOnly || sidebarSaving || !sidebarOpen) return false;
		if (!validateForm(true)) return false;

		sidebarSaving = true;
		const currentId = editingId;
		const endpoint = currentId
			? `/api/obras/${props.obraId}/secuencias/${currentId}`
			: `/api/obras/${props.obraId}/secuencias`;
		const method = currentId ? 'PATCH' : 'POST';

		let response: Response;
		try {
			response = await fetch(endpoint, {
				method,
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					...form,
					estrofa_tipo_id: form.estrofa_tipo_id || null
				})
			});
		} catch {
			sidebarSaving = false;
			pushToast('error', 'No se pudo conectar con el servidor. Los cambios siguen sin guardar.');
			return false;
		}

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message = body.message ?? 'No se pudo guardar la secuencia';
			sidebarSaving = false;
			pushToast('error', message);
			return false;
		}

		const payload = await response.json().catch(() => null);
		if (!payload?.secuencia) {
			sidebarSaving = false;
			pushToast('error', 'El servidor devolvió una respuesta incompleta. Los cambios siguen sin guardar.');
			return false;
		}
		const savedSecuencia = payload.secuencia as EditorSecuenciaRow;
		const savedId = currentId ?? savedSecuencia.secuencia_id;
		// **La respuesta es la fila de `secuencias_metricas` a secas**, y ahí no consta si la secuencia
		// tiene anotación en el catálogo nuevo. Reemplazar la fila con ella perdía esa marca, y la
		// checklist de revisión seguía contando pendientes hasta que se recargaba la página.
		const filaGuardada: EditorSecuenciaRow = {
			...savedSecuencia,
			tiene_anotacion_metrica:
				secuencias.find((item) => item.secuencia_id === savedId)?.tiene_anotacion_metrica ?? false
		};

		if (currentId) {
			const next = secuencias.map((item) => (item.secuencia_id === currentId ? filaGuardada : item));
			secuencias = next;
			emitSecuenciasChange(next);
			} else {
			const next = sortSecuencias([...secuencias, filaGuardada]);
			secuencias = next;
			emitSecuenciasChange(next);
			editingId = savedId;
				}

		form = {
			v_ini: savedSecuencia.v_ini,
			v_fin: savedSecuencia.v_fin,
			estrofa_tipo_id: toSelectableEstrofaId(savedSecuencia.estrofa_tipo_id),
			inaugura_espacio: savedSecuencia.inaugura_espacio,
			versos_partidos: savedSecuencia.versos_partidos,
			intervencion_personajes_femeninos:
				savedSecuencia.intervencion_personajes_femeninos as IntervencionValue | null,
			intervencion_figuras_donaire:
				savedSecuencia.intervencion_figuras_donaire as IntervencionValue | null,
			intervencion_personajes_sobrenaturales:
				savedSecuencia.intervencion_personajes_sobrenaturales as IntervencionValue | null,
			evento_sobrenatural: savedSecuencia.evento_sobrenatural,
			sinopsis: savedSecuencia.sinopsis ?? ''
		};

		// ------------------------------------------------------------------ La anotación métrica
		//
		// **Va después de la secuencia y no puede ir antes**: la anotación apunta a una secuencia
		// real, así que necesita que exista. Por eso crear una secuencia la guarda ya como
		// secuencia, y a partir de ahí cada cosa que se cambie se guarda por su lado.
		//
		// *Si esto falla, la secuencia ya está escrita.* No es una pérdida —el rango y las
		// caracterizaciones quedan— pero sí un estado a medias, y el aviso tiene que decirlo con
		// esas palabras para que quien anota sepa que basta con volver a guardar.
		if (usaElEditorNuevo && estadoMetrico) {
			const guardada = await guardarAnotacionMetrica(savedId, estadoMetrico);
			if (!guardada) {
				sidebarSaving = false;
				return false;
			}
			// Ya tiene forma: decírselo a la página evita que la revisión la cuente pendiente.
			const conAnotacion = secuencias.map((item) =>
				item.secuencia_id === savedId ? { ...item, tiene_anotacion_metrica: true } : item
			);
			secuencias = conAnotacion;
			emitSecuenciasChange(conAnotacion);
		}

		setSidebarBaselineFromCurrent();
		pushToast('success', currentId ? 'Secuencia actualizada' : 'Secuencia creada');
		if (!currentId && filtroForma && formaIdDeSecuencia(savedSecuencia) !== filtroForma) {
			pushToast('info', 'Secuencia creada. Está oculta por los filtros actuales.');
		}
		sidebarSaving = false;
		return true;
	}

	/**
	 * El editor V2 es **el único sitio donde se edita el rango** de una secuencia, así que el
	 * formulario tiene que seguirlo.
	 *
	 * No es un adorno: el guardado de la secuencia manda `form`, y la anotación manda el borrador. Si
	 * se separan, mover el rango en el editor no llegaba a `secuencias_metricas` —se guardaba el
	 * viejo— y la anotación quedaba describiendo otro pasaje. Y de paso lo siguen la cobertura, la
	 * validación y el rango que acota las caracterizaciones.
	 */
	function recibirEstadoMetrico(estado: MetricSequenceEditorState) {
		estadoMetrico = estado;
		const { v_ini, v_fin } = estado.draft;
		if (form.v_ini !== v_ini || form.v_fin !== v_fin) {
			form = { ...form, v_ini, v_fin };
		}
	}

	/**
	 * El borrador vivo del editor métrico, que él devuelve en cada cambio.
	 *
	 * La pestaña no lo toca: solo lo guarda cuando se pulsa Guardar. Quien decide qué es válido es
	 * el propio editor, que además dice por qué no lo es.
	 */
	/**
	 * Qué secciones del modal están desplegadas.
	 *
	 * **Solo la métrica de entrada**, que es donde empieza el trabajo: las cuatro abiertas obligan a
	 * recorrer la pantalla entera para llegar a los comentarios. El raíl de la izquierda es su
	 * índice y abre la que se pulsa.
	 */
	let seccionesAbiertas = $state(new Set<string>(['identificacion']));

	function alternarSeccion(id: string) {
		const siguiente = new Set(seccionesAbiertas);
		if (siguiente.has(id)) siguiente.delete(id);
		else siguiente.add(id);
		seccionesAbiertas = siguiente;
	}

	function abrirSeccion(id: string) {
		if (seccionesAbiertas.has(id)) return;
		seccionesAbiertas = new Set(seccionesAbiertas).add(id);
	}

	/**
	 * Cuántos comentarios tiene cada secuencia de la obra.
	 *
	 * Se piden **una vez por obra** y se agrupan aquí: en toda la base hay cincuenta y dos
	 * comentarios de secuencia repartidos en treinta y nueve, así que una consulta trae de sobra lo
	 * de una obra entera y evita una por secuencia abierta. El panel de comentarios sigue cargando
	 * los suyos cuando se despliega; esto es solo el número, para que el raíl lo diga sin abrir nada.
	 */
	let comentariosPorSecuencia = $state<Map<string, number>>(new Map());

	async function contarComentarios(obraId: string) {
		try {
			const response = await fetch(`/api/obras/${obraId}/comentarios?limit=1000`);
			if (!response.ok) return;
			const payload = (await response.json()) as { items?: { secuencia_id: string | null }[] };
			const cuenta = new Map<string, number>();
			for (const comentario of payload.items ?? []) {
				if (!comentario.secuencia_id) continue;
				cuenta.set(comentario.secuencia_id, (cuenta.get(comentario.secuencia_id) ?? 0) + 1);
			}
			comentariosPorSecuencia = cuenta;
		} catch {
			// Sin el número el raíl se lee igual: es un dato de más, no una condición para anotar.
		}
	}

	/**
	 * Las caracterizaciones que cuentan para dar la secuencia por terminada.
	 *
	 * **Las de por rango no están**, y no por olvido: no son obligatorias nunca —lagunas, prosa,
	 * versos cantados, hipometría son lo que se encuentre— y además se guardan por su cuenta, fuera
	 * del `save()` de la secuencia. Contarlas sería pedir que se rellene lo que puede no existir.
	 *
	 * Las siete que sí cuentan admiten nulo en la base, así que «sin responder» se distingue de
	 * «no»; la explicación de la evocación solo cuenta cuando se ha dicho que la hay.
	 */
	const CARACTERIZACIONES_QUE_CUENTAN = 6;
	const caracterizacionesRespondidas = $derived.by(() => {
		let hechas = 0;
		for (const valor of [
			form.intervencion_personajes_femeninos,
			form.intervencion_figuras_donaire,
			form.intervencion_personajes_sobrenaturales
		]) {
			if (valor !== null && valor !== undefined && String(valor).trim() !== '') hechas += 1;
		}
		for (const valor of [form.versos_partidos, form.inaugura_espacio, form.evento_sobrenatural]) {
			if (valor !== null && valor !== undefined) hechas += 1;
		}
		return hechas;
	});

	/**
	 * Las secciones que no pinta el editor métrico, en el orden en que se leen.
	 *
	 * `detalle` es lo que el raíl dice al lado del nombre —«3 de 7», «sin escribir», «2»—: **informa,
	 * no exige**. Ninguna de estas tres impide guardar, y lo normal es anotar por tandas.
	 */
	const seccionesDelModal = $derived([
		{
			id: 'caracterizaciones',
			label: 'Caracterizaciones',
			detalle: `${caracterizacionesRespondidas} de ${CARACTERIZACIONES_QUE_CUENTAN}`,
			pendiente: caracterizacionesRespondidas < CARACTERIZACIONES_QUE_CUENTAN
		},
		{
			id: 'sinopsis',
			label: 'Sinopsis',
			detalle: form.sinopsis?.trim() ? 'escrita' : 'sin escribir',
			pendiente: !form.sinopsis?.trim()
		},
		{
			id: 'comentarios',
			label: 'Comentarios',
			detalle: editingId
				? String(comentariosPorSecuencia.get(editingId) ?? 0)
				: 'al guardar',
			pendiente: false
		}
	]);
	let estadoMetrico = $state<MetricSequenceEditorState | null>(null);

	/**
	 * De dónde viene cada secuencia que ya estaba anotada con el vocabulario legado.
	 *
	 * **Se pide una vez por obra y solo cuando hace falta**: la primera vez que se abre una secuencia
	 * con término legado. La consulta que la responde deriva el catálogo entero, así que pedirla en
	 * cada visita a la pestaña sería repetir el error que hacía caer `/dashboard/metrica`.
	 */
	let propuestas = $state<Map<string, PropuestaDeSecuencia> | null>(null);
	let propuestasCargando = $state(false);

	async function cargarPropuestas() {
		if (!browser || propuestas || propuestasCargando) return;
		propuestasCargando = true;
		try {
			const respuesta = await fetch(`/api/obras/${props.obraId}/secuencias/propuesta`);
			if (!respuesta.ok) return;
			const carga = await respuesta.json().catch(() => ({ items: [] }));
			propuestas = new Map(
				(carga.items ?? []).map((fila: PropuestaDeSecuencia & { secuencia_id: string }) => [
					String(fila.secuencia_id),
					fila
				])
			);
		} catch {
			// Es un mensaje de ayuda: si no llega, el editor sigue sirviendo igual.
		} finally {
			propuestasCargando = false;
		}
	}

	/** La secuencia abierta, si venía anotada con el vocabulario viejo. */
	const propuestaDeLaAbierta = $derived.by(() => {
		if (!editingId) return null;
		const secuencia = secuencias.find((row) => row.secuencia_id === editingId);
		if (!secuencia?.estrofa_tipo_id) return null;
		return propuestas?.get(editingId) ?? null;
	});

	/** Y si hay que ir a buscarla, para enseñar que se está buscando. */
	const buscandoLaPropuesta = $derived.by(() => {
		if (!editingId || propuestas) return false;
		const secuencia = secuencias.find((row) => row.secuencia_id === editingId);
		return Boolean(secuencia?.estrofa_tipo_id) && propuestasCargando;
	});

	/**
	 * Si hay catálogo que darle al editor nuevo.
	 *
	 * **Todas las obras se anotan con él** desde el 27 de agosto de 2026, así que lo único que puede
	 * faltar es el catálogo mismo: `loadMetricCatalog` devuelve vacío cuando faltan migraciones o
	 * cuando quien mira no puede leer su revisión, que hoy exige ser admin o IP. Sin catálogo, el
	 * editor nuevo no puede pintar nada, y es mejor el panel de siempre que una pantalla en blanco.
	 */
	const usaElEditorNuevo = $derived(Boolean(props.catalogoMetrico));

	/**
	 * El borrador que consume el editor V2.
	 *
	 * Si la secuencia ya tiene anotación, se relee entera —forma, arquitectura, realizaciones,
	 * respuestas y desviaciones— para que guardar la **actualice** en vez de intentar crear una
	 * segunda, que el índice único rechazaría. Si no la tiene, se arranca en blanco con el rango
	 * puesto, que es lo que el editor necesita para dividir el pasaje en unidades.
	 *
	 * *El rango manda siempre sobre lo guardado*: si el editor acaba de moverlo, es ese el que vale.
	 */
	function borradorMetrico(): MetricSequenceDraft {
		const vIni = Number(form.v_ini) || 1;
		const vFin = Number(form.v_fin) || 1;
		const borradorEnSesion = editingId ? borradoresMetricosEnSesion.get(editingId) : null;
		if (borradorEnSesion) {
			return {
				...borradorEnSesion,
				secuencia_id: editingId,
				v_ini: vIni,
				v_fin: vFin
			};
		}
		const anotada = editingId
			? (props.anotacionMetrica?.secuencias ?? []).find(
					(fila: MetricCatalogDomainRow) => String(fila.secuencia_id) === editingId
				)
			: null;

		if (anotada) {
			const borrador = draftFromRows(anotada, {
				units: props.anotacionMetrica?.unidades ?? [],
				choices: props.anotacionMetrica?.elecciones ?? [],
				deviations: props.anotacionMetrica?.desviaciones ?? []
			});
			return { ...borrador, v_ini: vIni, v_fin: vFin };
		}

		return {
			anotacion_id: null,
			escenario_id: null,
			secuencia_id: editingId,
			// `orden` es obligatorio y en una secuencia real no ordena nada: solo las anotaciones de
			// escenario compiten por él. Se usa el sitio que ocupa en la obra, que al menos se lee.
			orden: editingIndex >= 0 ? editingIndex + 1 : 1,
			v_ini: vIni,
			v_fin: vFin,
			forma_id: '',
			arquitectura_id: '',
			observaciones: '',
			unidades: [],
			elecciones: [],
			desviaciones: []
		};
	}

	/**
	 * Escribe la identidad métrica de una secuencia en las tablas de la anotación.
	 *
	 * Comparte endpoint con el editor de pruebas: `save_sequence` acepta `secuencia_id` —la real— o
	 * `escenario_id`, y la base resuelve una u otra. No hacía falta inventar un camino nuevo.
	 */
	async function guardarAnotacionMetrica(
		secuenciaId: string,
		estado: MetricSequenceEditorState
	): Promise<boolean> {
		if (estado.error) {
			pushToast('error', estado.error);
			return false;
		}
		const borrador: MetricSequenceDraft = estado.draft;
		const limpiar = (valor: string | null | undefined) => {
			const texto = (valor ?? '').trim();
			return texto.length > 0 ? texto : null;
		};

		let respuesta: Response;
		try {
			respuesta = await fetch('/api/metrica/anotacion', {
				method: 'POST',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({
					action: 'save_sequence',
					...borrador,
					escenario_id: null,
					secuencia_id: secuenciaId,
					arquitectura_id: borrador.arquitectura_id || null,
					observaciones: limpiar(borrador.observaciones),
					unidades: borrador.unidades.map((unidad) => ({
						...unidad,
						etiqueta: limpiar(unidad.etiqueta),
						observaciones: limpiar(unidad.observaciones)
					})),
					/**
					 * **La respuesta viaja diciendo de qué habla**, no a qué pregunta contesta.
					 *
					 * El borrador sigue trabajando con preguntas, que es lo que necesita para pintar
					 * el rótulo, el control y las opciones; lo que cambia es el cable. La dimensión y
					 * la parte tratada se sacan de la pregunta que el editor tenía delante, incluidas
					 * las que una parte toma prestadas de la arquitectura que reutiliza.
					 */
					elecciones: borrador.elecciones.map((eleccion) => {
						const grupo = props.catalogoMetrico?.domain.choiceGroups.find(
							(fila: MetricCatalogDomainRow) =>
								String(fila.grupo_eleccion_id) === eleccion.grupo_eleccion_id
						);
						return {
							realizacion_id: eleccion.realizacion_id,
							dimension: String(grupo?.dimension ?? ''),
							seccion_tratada_id: grupo?.seccion_tratada_id
								? String(grupo.seccion_tratada_id)
								: null,
							opcion_eleccion_id: eleccion.opcion_eleccion_id,
							valor_texto: eleccion.valor_texto ?? null,
							observaciones: eleccion.observaciones
						};
					}),
					desviaciones: borrador.desviaciones.map((desviacion) => ({
						...desviacion,
						observaciones: limpiar(desviacion.observaciones)
					}))
				})
			});
		} catch {
			pushToast(
				'error',
				'La secuencia se guardó, pero no se pudo conectar para guardar su anotación métrica. Vuelve a guardar.'
			);
			return false;
		}

		const cuerpo = (await respuesta.json().catch(() => null)) as {
			anotacion_id?: unknown;
			message?: string;
			details?: { message?: string }[];
		} | null;

		if (!respuesta.ok) {
			pushToast(
				'error',
				`La secuencia se guardó, pero su anotación métrica no: ${
					cuerpo?.details?.[0]?.message ?? cuerpo?.message ?? 'error desconocido'
				}. Vuelve a guardar.`
			);
			return false;
		}

		props.onAnotacionMetricaGuardada?.(secuenciaId, {
			...borrador,
			anotacion_id:
				typeof cuerpo?.anotacion_id === 'string' ? cuerpo.anotacion_id : borrador.anotacion_id,
			secuencia_id: secuenciaId
		});
		return true;
	}

	function openDelete(secuenciaId: string) {
		if (props.readOnly) return;
		deleteTargetId = secuenciaId;
	}

	async function remove(secuenciaId: string) {
		if (!browser) return;
		if (props.readOnly || deletingSequence) return;
		deletingSequence = true;
		try {
			const response = await fetch(`/api/obras/${props.obraId}/secuencias/${secuenciaId}`, {
				method: 'DELETE'
			});
			if (!response.ok) {
				const body = await response.json().catch(() => ({}));
				pushToast('error', body.message ?? 'No se pudo eliminar la secuencia');
				return;
			}
			const next = secuencias.filter((row) => row.secuencia_id !== secuenciaId);
			secuencias = next;
			emitSecuenciasChange(next);
			if (editingId === secuenciaId) {
				performCloseSidebar();
			}
			pushToast('success', 'Secuencia eliminada');
			deleteTargetId = null;
		} catch {
			pushToast('error', 'No se pudo conectar con el servidor para eliminar la secuencia');
		} finally {
			deletingSequence = false;
		}
	}

	function clearFocusSecuenciaQueryParam() {
		if (!browser) return;
		const currentUrl = new URL(window.location.href);
		if (!currentUrl.searchParams.has('focusSecuenciaId')) return;
		currentUrl.searchParams.delete('focusSecuenciaId');
		window.history.replaceState(window.history.state, '', currentUrl.toString());
	}

	$effect(() => {
		const initialSecuencias = props.secuenciasInitial;
		if (secuencias.length === 0 && initialSecuencias.length > 0) {
			secuencias = [...initialSecuencias];
		}
	});

	$effect(() => {
		const focusSecuenciaId = props.focusSecuenciaId?.trim() ?? '';
		if (!focusSecuenciaId) {
			handledFocusSecuenciaId = null;
			return;
		}
		if (focusSecuenciaId === handledFocusSecuenciaId) return;

		const targetSecuencia = secuencias.find((item) => item.secuencia_id === focusSecuenciaId) ?? null;
		if (targetSecuencia) {
			openEdit(targetSecuencia);
		} else {
			pushToast('info', 'La secuencia enlazada no existe o ya no está disponible.');
		}

		handledFocusSecuenciaId = focusSecuenciaId;
		clearFocusSecuenciaQueryParam();
	});

	$effect(() => {
		const open = sidebarOpen;
		const readOnly = props.readOnly;
		const track = `${form.v_ini}|${form.v_fin}|${form.estrofa_tipo_id}|${form.inaugura_espacio}|${form.versos_partidos}|${form.intervencion_personajes_femeninos}|${form.intervencion_figuras_donaire}|${form.intervencion_personajes_sobrenaturales}|${form.evento_sobrenatural}|${form.sinopsis}|${editingId}`;
		void track;

		if (!open || readOnly) {
			sidebarDirty = false;
			reportPendingChanges(false);
			return;
		}

		sidebarDirty = sidebarSnapshot() !== sidebarBaselineSnapshot;
		reportPendingChanges(sidebarDirty);
	});

	onDestroy(() => {
		props.onPendingChangesChange?.(false);
	});

	/**
	 * Se cuenta al abrir la obra y cada vez que se escribe o se borra un comentario, que es cuando el
	 * número deja de ser cierto. Se leen las dos dependencias antes de llamar, para que el efecto no
	 * se suscriba de más a lo que la función toque por dentro.
	 */
	$effect(() => {
		const obraId = props.obraId;
		void props.commentsReloadKey;
		void contarComentarios(obraId);
	});
</script>

<section class="space-y-4">
	<MetricPanelSection
		id="declaraciones-obra"
		titulo="Antes de anotar"
		abierta={declaracionesAbiertas}
		alAlternar={() => (declaracionesAbiertas = !declaracionesAbiertas)}
	>
		<div class="space-y-3 p-4">
			<p class="form-help">
				Marca lo que no hay en la obra y dejará de preguntarse en cada secuencia. Los personajes
				femeninos se preguntan siempre.
			</p>
			<div class="grid gap-3 sm:grid-cols-3">
				{#each DECLARACIONES as declaracion (declaracion.clave)}
					{@const declarantes = cuantasLoDeclaran(declaracion)}
					<div class="form-field min-w-0">
						<span class="form-label">
							<span class="form-label-with-help">
								{declaracion.etiqueta}
								<FieldHelpTooltip
									text={declaracion.ayuda}
									label={`Ayuda sobre ${declaracion.etiqueta.toLocaleLowerCase('es')}`}
								/>
							</span>
						</span>
						<label class="flex items-center gap-2 text-sm">
							<input
								type="checkbox"
								checked={declaracionesActuales[declaracion.clave]}
								disabled={props.readOnly || guardandoDeclaracion !== null || declarantes > 0}
								onchange={(event) => declarar(declaracion.clave, event.currentTarget.checked)}
							/>
							{declaracion.casilla}
						</label>
						{#if declarantes > 0}
							<span class="form-help">
								{declarantes === 1 ? '1 secuencia lo declara' : `${declarantes} secuencias lo declaran`}
							</span>
						{/if}
					</div>
				{/each}
			</div>
		</div>
	</MetricPanelSection>

	<div class="flex flex-wrap items-end justify-between gap-3 pb-3 pt-2">
		<h2 class="text-lg font-semibold">Secuencias métricas</h2>
		<div class="flex flex-wrap items-end gap-2">
			<div class="w-56">
				<CheckDropdown
					multiple={false}
					hierarchical={true}
					collapsibleHierarchy={true}
					disableParentsWithChildren={false}
					closeOnSelect={false}
					showPathInTrigger={true}
					allowSingleClear={true}
					search={true}
					placeholder="Filtrar por forma"
					items={formaDropdownItems}
					selectedIds={filtroFormaDraft ? [filtroFormaDraft] : []}
					onChange={(ids) => {
						filtroFormaDraft = ids[0] ?? '';
					}}
				/>
			</div>
			<Button variant="secondary" onclick={aplicarFiltroForma}>Filtrar</Button>
			<Button
				variant="ghost"
				onclick={limpiarFiltroForma}
				disabled={!filtroForma && !filtroFormaDraft}
			>
				Limpiar
			</Button>
			<Button variant="primary-soft" onclick={requestOpenNew} disabled={props.readOnly}>Nueva secuencia</Button>
		</div>
	</div>

	<RangeConsistencyAlert issues={sequenceOverlapIssues} />

	<div class="lg:grid lg:grid-cols-[15rem_minmax(0,1fr)] lg:gap-4">
		<aside class="secuencias-structure-index hidden lg:sticky lg:top-4 lg:block lg:h-fit lg:self-start">
			<div class="card secuencias-structure-index__head">Índice de estructura</div>
			{#if jornadasSorted.length === 0}
				<p class="card secuencias-structure-index__empty-text">Sin estructura registrada.</p>
			{:else}
				<ul class="card secuencias-structure-list">
					{#each jornadasSorted as jornada (jornada.jornada_id)}
						<li class="secuencias-structure-list__item">
							<p class="secuencias-structure-list__jornada">
								Jornada {jornada.jornada_num}
								<span>(vv. {jornada.v_ini}-{jornada.v_fin})</span>
							</p>
							{#if (cuadrosByJornada.get(jornada.jornada_id)?.length ?? 0) > 0}
								<ul class="secuencias-structure-sublist">
									{#each cuadrosByJornada.get(jornada.jornada_id) ?? [] as cuadro (cuadro.cuadro_id)}
										<li class="secuencias-structure-sublist__item">
											Cuadro {cuadro.cuadro_num} (vv. {cuadro.v_ini}-{cuadro.v_fin})
										</li>
									{/each}
								</ul>
							{/if}
						</li>
					{/each}
				</ul>
			{/if}
			<div class="card mt-4 space-y-2">
				<Button variant="primary" class="w-full" onclick={openSequenceSynopsisModal}>
					Leer sinopsis completa
				</Button>
				{#if sidebarDirty}
					<p class="text-xs text-[color:var(--muted-foreground)]">
						La sinopsis completa refleja la última versión guardada mientras haya cambios pendientes en el panel lateral.
					</p>
				{/if}
			</div>
			<div class="mt-4 space-y-2">
				<Button variant="primary-soft" class="w-full" onclick={requestOpenNew} disabled={props.readOnly}>
					Nueva secuencia
				</Button>
			</div>
		</aside>

		<div class="space-y-2">
			<div class="card overflow-x-auto">
				<table class="min-w-full text-left text-sm">
					<thead class="bg-[color:var(--muted)]">
						<tr>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">#</th>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">V_ini</th>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">V_fin</th>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">N_versos</th>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">Forma</th>
							<th class="sticky top-0 z-10 w-28 bg-[color:var(--muted)] px-3 py-2"><span class="sr-only">Acciones</span></th>
						</tr>
					</thead>
					<tbody>
						{#if filteredSecuencias.length === 0}
							<tr>
								<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={6}>
									Sin secuencias para este filtro.
								</td>
							</tr>
						{:else}
							{#each filteredSecuencias as secuencia, idx}
								<tr
									class={`border-t ${
										sequenceOverlapIds.has(secuencia.secuencia_id)
											? 'border-[color:var(--danger)] bg-red-50'
											: 'border-[color:var(--border)]'
									}`}
								>
									<td class="px-3 py-2">{idx + 1}</td>
									<td class="px-3 py-2">{secuencia.v_ini}</td>
									<td class="px-3 py-2">{secuencia.v_fin}</td>
									<td class="px-3 py-2">{secuencia.n_versos}</td>
									<td class="px-3 py-2">{formaDeSecuencia(secuencia)}</td>
									<td class="px-3 py-2">
										<div class="flex items-center justify-end gap-1">
											<button
												type="button"
												class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--success)] disabled:opacity-40"
												aria-label={props.readOnly ? 'Ver secuencia' : 'Editar secuencia'}
												onclick={() => requestOpenEdit(secuencia)}
												disabled={props.readOnly && !props.canComment}
											>
												{#if props.readOnly}<Eye size={16} />{:else}<Pencil size={16} />{/if}
											</button>
											<button
												type="button"
												class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--danger)] disabled:opacity-40"
												aria-label="Eliminar secuencia"
												onclick={() => openDelete(secuencia.secuencia_id)}
												disabled={props.readOnly}
											>
												<Trash2 size={16} />
											</button>
										</div>
									</td>
								</tr>
							{/each}
						{/if}
					</tbody>
				</table>
			</div>
		</div>
	</div>

	<div class="card grid p-4 sm:grid-cols-3 sm:divide-x sm:divide-[color:var(--border)]">
		<div class="px-3 py-1 sm:first:pl-0">
			<p class="text-xs text-[color:var(--muted-foreground)]">Total estructura</p>
			<p class="text-base font-semibold">
				{#if totalVersosEstructura === null}
					--
				{:else}
					{totalVersosEstructura}
				{/if}
			</p>
		</div>
		<div class="px-3 py-1">
			<p class="text-xs text-[color:var(--muted-foreground)]">Versos declarados (filtrado)</p>
			<p class="text-base font-semibold">{totalVersosDeclaradosFiltrados}</p>
		</div>
		<div class="px-3 py-1">
			<p class="text-xs text-[color:var(--muted-foreground)]">Diferencia</p>
			<p
				class={`text-base font-semibold ${
					diferenciaFiltrada === null
						? 'text-[color:var(--muted-foreground)]'
						: diferenciaFiltrada === 0
							? 'text-[color:var(--foreground)]'
							: 'text-[color:var(--danger)]'
				}`}
			>
				{#if diferenciaFiltrada === null}
					--
				{:else if diferenciaFiltrada > 0}
					+{diferenciaFiltrada}
				{:else}
					{diferenciaFiltrada}
				{/if}
			</p>
		</div>
	</div>
	<p class="text-xs text-[color:var(--muted-foreground)]">
		La suma de versos declarados se calcula solo sobre las secuencias visibles por los filtros activos.
	</p>
	<div class="space-y-2 lg:hidden">
		<div class="flex justify-start">
			<Button variant="primary" onclick={openSequenceSynopsisModal}>Leer sinopsis completa</Button>
		</div>
		{#if sidebarDirty}
			<p class="text-xs text-[color:var(--muted-foreground)]">
				La sinopsis completa refleja la última versión guardada mientras haya cambios pendientes en el panel lateral.
			</p>
		{/if}
	</div>
</section>

<SequenceSynopsisModal
	open={sequenceSynopsisModalOpen}
	groups={sequenceSynopsisGroups}
	totalSequences={secuencias.length}
	missingSynopsisCount={sequenceSynopsisMissingCount}
	showSavedVersionNote={sidebarDirty}
	onClose={closeSequenceSynopsisModal}
/>

{#if sidebarOpen}
	<!--
		**Dos contenedores para el mismo formulario.** El editor V2 no cabe en el panel lateral: es una
		rejilla verso a verso, las preguntas de cada unidad y las desviaciones, y trabajar ahí obliga a
		desplazarse tanto que se pierde de vista el pasaje. Por eso las obras abiertas al catálogo
		nuevo se anotan en el modal ancho, el mismo del editor de pruebas.

		Las demás siguen con el panel de siempre hasta que se migren. Durante ese tiempo hay más
		código, no menos, y es a propósito: no se interrumpe a quien está a mitad de una obra.
	-->
	{#if usaElEditorNuevo}
		<!--
			**Lo que está mal en el rango se dice mientras se anota; lo que falta, al guardar.**

			El editor ya calculaba los dos y el modal ya tenía dónde enseñarlos, pero nadie los
			conectaba: el aviso solo salía como aviso flotante después de pulsar Guardar, mientras la
			pantalla enumeraba «qué se va a registrar» de un guardado que iba a fallar.

			Arriba va **solo el del rango**. Que una pregunta esté sin responder no es un error: es
			trabajo a medias, y decirlo desde que se abre la secuencia es apremiar por no haber
			terminado —y hacerlo además de manera desigual, porque de lo que falta en
			caracterizaciones o en la sinopsis no se dice nada—. El rango no es trabajo a medias: es
			algo que está mal, y cuanto antes se vea, menos trabajo se hace encima de él.
		-->
		<MetricSequenceModal
			titulo={editingId ? (props.readOnly ? 'Ver secuencia' : 'Editar secuencia') : 'Nueva secuencia'}
			rango={{ v_ini: Number(form.v_ini) || 1, v_fin: Number(form.v_fin) || 1 }}
			posicion={editingId && editingIndex >= 0
				? { indice: editingIndex + 1, total: orderedSecuencias.length }
				: null}
			alAnterior={() => void goToSecuencia(prevSecuencia)}
			alSiguiente={() => void goToSecuencia(nextSecuencia)}
			hayAnterior={Boolean(prevSecuencia)}
			haySiguiente={Boolean(nextSecuencia)}
			sucio={sidebarDirty}
			guardando={sidebarSaving}
			error={estadoMetrico?.errorDeRango ?? null}
			alEliminar={editingId && !props.readOnly ? () => openDelete(editingId as string) : null}
			alCerrar={requestCloseSidebar}
			alGuardar={() => void save()}
		>
			{#if propuestaDeLaAbierta || buscandoLaPropuesta}
				<div class="px-5 pt-4">
					<DeDondeVieneLaSecuencia
						propuesta={propuestaDeLaAbierta}
						cargando={buscandoLaPropuesta}
					/>
				</div>
			{/if}
			{#key editorSessionKey}
				<MetricSequenceEditor
					catalog={props.catalogoMetrico as MetricCatalogForEditor}
					initialDraft={borradorMetrico()}
					onStateChange={recibirEstadoMetrico}
					bodyExtra={restoDelFormulario}
					seccionAbierta={seccionesAbiertas.has('identificacion')}
					alAlternarSeccion={() => alternarSeccion('identificacion')}
					extraRailItems={seccionesDelModal.map((seccion) => ({
						...seccion,
						alAbrir: () => abrirSeccion(seccion.id)
					}))}
				/>
			{/key}
		</MetricSequenceModal>
	{:else}
		<!--
			**Sin catálogo no hay editor.** `loadMetricCatalog` devuelve vacío si faltan migraciones,
			así que esto solo se ve con la base a medio migrar. Aquí estuvo el panel lateral con el
			selector del vocabulario legado, retirado el 27 de agosto de 2026: nadie va a anotar ya con
			él, y dejarlo era mantener dos editores para que uno no se usara nunca.
		-->
		<div class="fixed inset-0 z-40 flex items-start justify-center bg-black/50 p-4">
			<div class="card w-full max-w-lg p-5">
				<h3 class="text-base font-semibold">No se puede anotar ahora mismo</h3>
				<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
					El catálogo métrico no ha llegado a cargarse. Suele ser que faltan migraciones por
					aplicar a esta base.
				</p>
				<div class="mt-4 flex justify-end">
					<Button variant="secondary" onclick={requestCloseSidebar}>Cerrar</Button>
				</div>
			</div>
		</div>
	{/if}
	{/if}

	{#if deleteTargetId}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Eliminar secuencia</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta acción no se puede deshacer.</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button
					variant="secondary"
					onclick={() => (deleteTargetId = null)}
					disabled={deletingSequence}
				>
					Cancelar
				</Button>
				<Button
					variant="danger"
					disabled={props.readOnly}
					loading={deletingSequence}
					loadingLabel="Eliminando…"
					onclick={() => {
						if (!deleteTargetId) return;
						void remove(deleteTargetId);
					}}
				>
					Eliminar
				</Button>
			</div>
		</div>
	</div>
{/if}

<UnsavedChangesModal
	open={Boolean(pendingSidebarAction)}
	message={
		pendingSidebarAction?.kind === 'new'
			? 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de crear otra?'
			: pendingSidebarAction?.kind === 'sequence'
				? 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de cambiar de secuencia?'
				: 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de cerrar?'
	}
	discardLabel="Continuar sin guardar"
	saving={sidebarSaving}
	onCancel={cancelPendingSidebarAction}
	onDiscard={discardAndContinue}
	onSave={saveAndContinue}
/>

<!--
	Lo que no es métrico de una secuencia, repartido en las tres secciones que el raíl indexa:
	caracterizaciones, sinopsis y comentarios.

	Va debajo del editor V2, dentro del mismo modal, porque **el editor lo rellena en la misma
	pasada** y separarlo obligaría a abrir dos sitios para anotar una secuencia. Aquí hubo también un
	fragmento con el selector del vocabulario legado; se retiró con el panel que lo pintaba.

	**Los comentarios volvieron el 28 de agosto de 2026.** Estaban al pie del panel lateral y se
	fueron con él sin que nadie lo notara: la anotación perdió el sitio donde se discute, que es
	justo lo que un equipo editorial necesita a mano mientras anota.
-->
{#snippet restoDelFormulario()}
	<MetricPanelSection
		id="caracterizaciones"
		titulo="Caracterizaciones"
		abierta={seccionesAbiertas.has('caracterizaciones')}
		alAlternar={() => alternarSeccion('caracterizaciones')}
	>
		<CaracterizacionesPorRango
			bind:this={caracterizaciones}
			obraId={props.obraId}
			secuenciaId={editingId}
			rango={{ v_ini: Number(form.v_ini) || 1, v_fin: Number(form.v_fin) || 1 }}
			opciones={props.caracterizacionRangoOptions}
			readOnly={props.readOnly}
			onMetricaDirty={props.onMetricaDirty}
		/>

		<CaracterizacionesDeLaSecuencia
			valores={{
				intervencion_personajes_femeninos: form.intervencion_personajes_femeninos,
				intervencion_figuras_donaire: form.intervencion_figuras_donaire,
				intervencion_personajes_sobrenaturales: form.intervencion_personajes_sobrenaturales,
				versos_partidos: form.versos_partidos,
				inaugura_espacio: form.inaugura_espacio,
				evento_sobrenatural: form.evento_sobrenatural
			}}
			loQueNoHay={{
				donaire: declaracionesActuales.sin_figuras_donaire,
				personajesSobrenaturales: declaracionesActuales.sin_personajes_sobrenaturales,
				eventosSobrenaturales: declaracionesActuales.sin_eventos_sobrenaturales
			}}
			readOnly={props.readOnly}
			alCambiar={(cambio) => (form = { ...form, ...cambio })}
		/>
	</MetricPanelSection>

	<MetricPanelSection
		id="sinopsis"
		titulo="Sinopsis"
		abierta={seccionesAbiertas.has('sinopsis')}
		alAlternar={() => alternarSeccion('sinopsis')}
		resumen={form.sinopsis?.trim() ? 'Escrita' : 'Sin escribir'}
	>
		<label class="form-field">
			<span class="sr-only">Sinopsis argumental</span>
			<MarkdownEditorLite
				rows={3}
				class="mt-1"
				minHeightClass="min-h-28"
				value={form.sinopsis}
				disabled={props.readOnly}
				onChange={(nextValue) => {
					form = {
						...form,
						sinopsis: nextValue
					};
				}}
			/>
		</label>
	</MetricPanelSection>

	<MetricPanelSection
		id="comentarios"
		titulo="Comentarios"
		abierta={seccionesAbiertas.has('comentarios')}
		alAlternar={() => alternarSeccion('comentarios')}
		resumen={editingId ? null : 'Al guardar la secuencia'}
	>
		{#if editingId}
			{#key editingId}
				<InternalCommentsPanel
					obraId={props.obraId}
					canComment={Boolean(props.canComment)}
					title=""
					context={{ secuencia_id: editingId }}
					focusComentarioId={props.focusComentarioId}
					reloadKey={props.commentsReloadKey}
				/>
			{/key}
		{:else}
			<p class="text-sm text-[color:var(--muted-foreground)]">
				Guarda la secuencia para poder comentarla.
			</p>
		{/if}
	</MetricPanelSection>
{/snippet}

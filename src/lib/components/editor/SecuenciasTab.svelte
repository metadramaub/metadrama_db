<script lang="ts">
	import { browser } from '$app/environment';
	import { onDestroy } from 'svelte';
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import SequenceSynopsisModal from '$lib/components/editor/SequenceSynopsisModal.svelte';
	import { buildSequenceSynopsisGroups } from '$lib/components/editor/sequence-synopsis';
	import { suggestNextSubtipoRange } from '$lib/components/editor/secuencia-subtipos';
	import { pushToast } from '$lib/stores/toast';
	import { displayTerm } from '$lib/utils/vocabulario';

	const props = $props<{
		obraId: string;
		secuenciasInitial: Tables<'secuencias_metricas'>[];
		jornadasInitial: Array<Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>>;
		cuadrosInitial: Array<Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'>>;
		estrofaOptions: Array<
			Pick<
				Tables<'vocabularios'>,
				'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id' | 'orden' | 'tipo_forma'
			>
		>;
		certezaOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>>;
		caracterizacionRangoOptions: Array<
			Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta' | 'termino_padre_id' | 'orden'>
		>;
		readOnly?: boolean;
		canComment?: boolean;
		focusSecuenciaId?: string | null;
		focusComentarioId?: string | null;
		onSecuenciasChange?: (items: Tables<'secuencias_metricas'>[]) => void;
	}>();

	type FormState = {
		v_ini: number;
		v_fin: number;
		estrofa_tipo_id: string;
		inaugura_espacio: boolean;
		versos_partidos: boolean;
		evocacion_metrica: boolean;
		evocacion_metrica_texto: string;
		intervencion_personajes_femeninos: 'sin_intervencion' | 'exclusiva' | 'compartida';
		intervencion_figuras_donaire: 'sin_intervencion' | 'exclusiva' | 'compartida';
		intervencion_personajes_sobrenaturales: 'sin_intervencion' | 'exclusiva' | 'compartida';
		certeza_editor: string;
		sinopsis: string;
	};

	type CaracterizacionRangoItem = {
		caracterizacion_rango_id: string;
		secuencia_id: string;
		tipo_caracterizacion_rango_id: string;
		tipo_caracterizacion_rango_term: string;
		tipo_caracterizacion_rango_parent_id: string | null;
		v_ini: number;
		v_fin: number;
		observaciones: string | null;
	};

	type CaracterizacionRangoFormState = {
		tipo_caracterizacion_rango_id: string;
		v_ini: number;
		v_fin: number;
		observaciones: string;
	};

	type SubtipoItem = {
		subtipo_secuencia_id: string;
		secuencia_id: string;
		subtipo_estrofa_id: string;
		subtipo_estrofa_term: string;
		subtipo_estrofa_parent_id: string | null;
		v_ini: number;
		v_fin: number;
	};

	type SubtipoFormState = {
		subtipo_estrofa_id: string;
		v_ini: number;
		v_fin: number;
	};

	let secuencias = $state([...props.secuenciasInitial]);
	let sidebarOpen = $state(false);
	let editingId = $state<string | null>(null);
	let filtroEstrofa = $state('');
	let filtroCerteza = $state('');
	let deleteTargetId = $state<string | null>(null);
	let showCloseWithoutSavingModal = $state(false);
	let sequenceSynopsisModalOpen = $state(false);

	let sidebarSaving = $state(false);
	let sidebarDirty = $state(false);
	let sidebarBaselineSnapshot = $state('');
	let autosaveErrorShown = $state(false);
	let lastSidebarSnapshot = $state('');
	let autosaveTimer: ReturnType<typeof setTimeout> | null = null;
	let caracterizacionesRango = $state<CaracterizacionRangoItem[]>([]);
	let caracterizacionesRangoLoading = $state(false);
	let caracterizacionesRangoRequestCounter = $state(0);
	let caracterizacionRangoModalOpen = $state(false);
	let caracterizacionRangoModalSaving = $state(false);
	let caracterizacionRangoEditingId = $state<string | null>(null);
	let caracterizacionRangoDeleteTargetId = $state<string | null>(null);
	let caracterizacionRangoForm = $state<CaracterizacionRangoFormState>({
		tipo_caracterizacion_rango_id: '',
		v_ini: 1,
		v_fin: 1,
		observaciones: ''
	});
	let subtipos = $state<SubtipoItem[]>([]);
	let subtiposLoading = $state(false);
	let subtiposRequestCounter = $state(0);
	let subtipoModalOpen = $state(false);
	let subtipoModalSaving = $state(false);
	let subtipoEditingId = $state<string | null>(null);
	let subtipoDeleteTargetId = $state<string | null>(null);
	let handledFocusSecuenciaId = $state<string | null>(null);
	let subtipoForm = $state<SubtipoFormState>({
		subtipo_estrofa_id: '',
		v_ini: 1,
		v_fin: 1
	});

	function sortEstrofaOptions(options: typeof props.estrofaOptions) {
		return [...options].sort(
			(a, b) => (a.orden ?? Number.MAX_SAFE_INTEGER) - (b.orden ?? Number.MAX_SAFE_INTEGER) ||
				a.termino.localeCompare(b.termino, 'es')
		);
	}

	function sortCaracterizacionRangoOptions(options: typeof props.caracterizacionRangoOptions) {
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

	const defaultCerteza = props.certezaOptions[0]?.termino_id ?? '';
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
	const defaultEstrofa = $derived.by(() => {
		const redondilla = estrofaSelectableOptions.find(
			(option) => normalizeTerm(option.termino) === 'redondilla'
		);
		return redondilla?.termino_id ?? estrofaSelectableOptions[0]?.termino_id ?? '';
	});
	const estrofaDropdownItems = $derived.by(() =>
		estrofaSelectableOptions.map((option) => ({
			id: option.termino_id,
			label: displayTerm(option),
			parentId: option.termino_padre_id ?? null
		}))
	);
	const caracterizacionRangoDropdownItems = $derived.by(() =>
		sortCaracterizacionRangoOptions(props.caracterizacionRangoOptions).map((option) => ({
			id: option.termino_id,
			label: displayTerm(option),
			parentId: option.termino_padre_id ?? null
		}))
	);
	const certezaDropdownItems = $derived(
		props.certezaOptions.map((option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>) => ({
			id: option.termino_id,
			label: displayTerm(option)
		}))
	);
	const intervencionItems = [
		{ id: 'sin_intervencion', label: 'Sin intervención' },
		{ id: 'exclusiva', label: 'Intervención exclusiva' },
		{ id: 'compartida', label: 'Intervención compartida' }
	];
	const INTERVENCION_HELP =
		'Indica si en esta secuencia métrica interviene verbalmente un personaje de este tipo. El dato se refiere al habla dentro de la secuencia, no a la presencia escénica.';
	const caracterizacionRangoById = $derived.by(
		() =>
			new Map<string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>>(
				props.caracterizacionRangoOptions.map(
					(
						option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>
					): readonly [string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>] => [
						option.termino_id,
						option
					]
				)
			)
	);
	const selectedCaracterizacionRangoTerm = $derived.by(() => {
		const term =
			caracterizacionRangoById.get(caracterizacionRangoForm.tipo_caracterizacion_rango_id)?.termino ?? '';
		return normalizeTerm(term);
	});
	const caracterizacionRangoRangeHelperText = $derived.by(() => {
		if (selectedCaracterizacionRangoTerm === 'prosa') {
			return 'Indica entre qué versos aparece la prosa (no numerada). Ej.: v_ini=56, v_fin=57.';
		}
		if (
			selectedCaracterizacionRangoTerm === 'hipometrico' ||
			selectedCaracterizacionRangoTerm === 'hipermetrico'
		) {
			return 'Esta caracterización aplica a un solo verso: usa el mismo número en V. ini y V. fin.';
		}
		if (
			selectedCaracterizacionRangoTerm === 'cantado' ||
			selectedCaracterizacionRangoTerm === 'rima_defectuosa' ||
			selectedCaracterizacionRangoTerm === 'laguna'
		) {
			return 'Puedes marcar un solo verso (V. ini = V. fin) o un rango (V. ini < V. fin).';
		}
		if (
			selectedCaracterizacionRangoTerm === 'mayoria_agudas' ||
			selectedCaracterizacionRangoTerm === 'mayoria_esdrujulas'
		) {
			return 'Marca el tramo donde predominan esos finales acentuales dentro de la secuencia.';
		}
		return '';
	});

	function toSelectableEstrofaId(termId: string | null | undefined): string {
		if (!termId) return defaultEstrofa;
		if (estrofaSelectableIds.has(termId)) return termId;

		let cursor = estrofaById.get(termId) ?? null;
		while (cursor?.termino_padre_id) {
			const parentId = cursor.termino_padre_id;
			if (estrofaSelectableIds.has(parentId)) return parentId;
			cursor = estrofaById.get(parentId) ?? null;
		}

		return defaultEstrofa;
	}

	function getSuggestedSecuenciaStart(): number {
		const maxVFin = secuencias.reduce((max, item) => Math.max(max, Number(item.v_fin) || 0), 0);
		return maxVFin > 0 ? maxVFin + 1 : 1;
	}

	function initialForm(): FormState {
		const suggestedStart = getSuggestedSecuenciaStart();
		return {
			v_ini: suggestedStart,
			v_fin: suggestedStart + 1,
			estrofa_tipo_id: defaultEstrofa,
			inaugura_espacio: false,
			versos_partidos: false,
			evocacion_metrica: false,
			evocacion_metrica_texto: '',
			intervencion_personajes_femeninos: 'sin_intervencion',
			intervencion_figuras_donaire: 'sin_intervencion',
			intervencion_personajes_sobrenaturales: 'sin_intervencion',
			certeza_editor: defaultCerteza,
			sinopsis: ''
		};
	}

	let form = $state<FormState>(initialForm());

	const currentEstrofaTerm = $derived.by(() => estrofaById.get(form.estrofa_tipo_id)?.termino ?? '');
	const isSubtipoEnabledForCurrentEstrofa = $derived.by(
		() => normalizeTerm(currentEstrofaTerm) === 'quintilla'
	);
	const subtipoOptionsForCurrentEstrofa = $derived.by(() =>
		sortEstrofaOptions(props.estrofaOptions).filter(
			(option) => option.termino_padre_id === form.estrofa_tipo_id
		)
	);
	const subtipoDropdownItems = $derived.by(() =>
		subtipoOptionsForCurrentEstrofa.map((option) => ({
			id: option.termino_id,
			label: displayTerm(option),
			parentId: option.termino_padre_id ?? null
		}))
	);
	const subtipoById = $derived.by(
		() =>
			new Map<string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>>(
				subtipoOptionsForCurrentEstrofa.map(
					(
						option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>
					): readonly [string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>] => [
						option.termino_id,
						option
					]
				)
			)
	);

	function getDefaultCaracterizacionRangoId() {
		const firstSelectable = sortCaracterizacionRangoOptions(props.caracterizacionRangoOptions).find(
			(option) => Boolean(option.termino_padre_id)
		);
		return firstSelectable?.termino_id ?? '';
	}

	function initialCaracterizacionRangoForm(): CaracterizacionRangoFormState {
		return {
			tipo_caracterizacion_rango_id: getDefaultCaracterizacionRangoId(),
			v_ini: Number(form.v_ini) || 1,
			v_fin: Number(form.v_ini) || 1,
			observaciones: ''
		};
	}

	function getDefaultSubtipoId() {
		return subtipoOptionsForCurrentEstrofa[0]?.termino_id ?? '';
	}

	function initialSubtipoForm(): SubtipoFormState {
		const suggestedRange = suggestNextSubtipoRange(
			{ v_ini: Number(form.v_ini), v_fin: Number(form.v_fin) },
			subtipos
		);
		return {
			subtipo_estrofa_id: getDefaultSubtipoId(),
			v_ini: suggestedRange.v_ini,
			v_fin: suggestedRange.v_fin
		};
	}

	function termById(
		options: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>>,
		id: string | null
	) {
		if (!id) return '--';
		const option = options.find((opt) => opt.termino_id === id);
		return option ? displayTerm(option) : '--';
	}

	function caracterizacionRangoLabelById(tipoCaracterizacionRangoId: string, fallback = '') {
		const fromVocabulary = displayTerm(caracterizacionRangoById.get(tipoCaracterizacionRangoId));
		return fromVocabulary || fallback || '--';
	}

	function sortCaracterizacionesRango(items: CaracterizacionRangoItem[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	}

	function sortSubtipos(items: SubtipoItem[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	}

	function subtipoLabelById(subtipoEstrofaId: string, fallback = '') {
		const fromVocabulary = displayTerm(subtipoById.get(subtipoEstrofaId));
		return fromVocabulary || fallback || '--';
	}

	function sortSecuencias(items: Tables<'secuencias_metricas'>[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini);
	}

	function sortJornadas(
		items: Array<Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>>
	) {
		return [...items].sort(
			(a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin || a.jornada_num - b.jornada_num
		);
	}

	function sortCuadros(
		items: Array<Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'>>
	) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin || a.cuadro_num - b.cuadro_num);
	}

	function emitSecuenciasChange(nextItems: Tables<'secuencias_metricas'>[] = secuencias) {
		props.onSecuenciasChange?.(sortSecuencias(nextItems));
	}

	const jornadasSorted = $derived.by(() => sortJornadas(props.jornadasInitial));
	const cuadrosSorted = $derived.by(() => sortCuadros(props.cuadrosInitial));

	const filteredSecuencias = $derived.by(() => {
		return secuencias
			.filter((secuencia) => !filtroEstrofa || secuencia.estrofa_tipo_id === filtroEstrofa)
			.filter((secuencia) => !filtroCerteza || secuencia.certeza_editor === filtroCerteza)
			.sort((a, b) => a.v_ini - b.v_ini);
	});
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
		const grouped = new Map<string, Array<Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'>>>();
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

	function clearAutosaveTimer() {
		if (!autosaveTimer) return;
		clearTimeout(autosaveTimer);
		autosaveTimer = null;
	}

	function sidebarSnapshot(): string {
		return JSON.stringify({
			sidebarOpen,
			id: editingId,
			v_ini: Number(form.v_ini),
			v_fin: Number(form.v_fin),
			estrofa_tipo_id: form.estrofa_tipo_id,
			inaugura_espacio: Boolean(form.inaugura_espacio),
			versos_partidos: Boolean(form.versos_partidos),
			evocacion_metrica: Boolean(form.evocacion_metrica),
			evocacion_metrica_texto: form.evocacion_metrica ? form.evocacion_metrica_texto.trim() : '',
			intervencion_personajes_femeninos: form.intervencion_personajes_femeninos,
			intervencion_figuras_donaire: form.intervencion_figuras_donaire,
			intervencion_personajes_sobrenaturales: form.intervencion_personajes_sobrenaturales,
			certeza_editor: form.certeza_editor,
			sinopsis: form.sinopsis.trim()
		});
	}

	function setSidebarBaselineFromCurrent() {
		sidebarBaselineSnapshot = sidebarSnapshot();
		sidebarDirty = false;
		autosaveErrorShown = false;
		lastSidebarSnapshot = sidebarBaselineSnapshot;
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
		if (!Number.isFinite(Number(form.v_ini)) || !Number.isFinite(Number(form.v_fin)) || Number(form.v_ini) >= Number(form.v_fin)) {
			if (showToast) pushToast('error', 'Rango de versos inválido');
			return false;
		}
		if (!form.estrofa_tipo_id) {
			if (showToast) pushToast('error', 'Selecciona estrofa');
			return false;
		}
		if (!form.certeza_editor) {
			if (showToast) pushToast('error', 'Selecciona certeza');
			return false;
		}
		return true;
	}

	function handleAutosaveError(message: string) {
		if (autosaveErrorShown) return;
		autosaveErrorShown = true;
		pushToast('error', message);
	}

	function openNew() {
		if (props.readOnly) return;
		editingId = null;
		form = initialForm();
		caracterizacionesRango = [];
		subtipos = [];
		caracterizacionRangoDeleteTargetId = null;
		caracterizacionRangoModalOpen = false;
		subtipoDeleteTargetId = null;
		subtipoModalOpen = false;
		sidebarOpen = true;
		showCloseWithoutSavingModal = false;
		setSidebarBaselineFromCurrent();
	}

	function openEdit(secuencia: Tables<'secuencias_metricas'>) {
		if (props.readOnly && !props.canComment) return;
		editingId = secuencia.secuencia_id;
		form = {
			v_ini: secuencia.v_ini,
			v_fin: secuencia.v_fin,
			estrofa_tipo_id: toSelectableEstrofaId(secuencia.estrofa_tipo_id),
			inaugura_espacio: Boolean(secuencia.inaugura_espacio),
			versos_partidos: Boolean(secuencia.versos_partidos),
			evocacion_metrica: Boolean(secuencia.evocacion_metrica),
			evocacion_metrica_texto: secuencia.evocacion_metrica_texto ?? '',
			intervencion_personajes_femeninos:
				secuencia.intervencion_personajes_femeninos as FormState['intervencion_personajes_femeninos'],
			intervencion_figuras_donaire:
				secuencia.intervencion_figuras_donaire as FormState['intervencion_figuras_donaire'],
			intervencion_personajes_sobrenaturales:
				secuencia.intervencion_personajes_sobrenaturales as FormState['intervencion_personajes_sobrenaturales'],
			certeza_editor: secuencia.certeza_editor,
			sinopsis: secuencia.sinopsis ?? ''
		};
		caracterizacionesRango = [];
		subtipos = [];
		caracterizacionRangoDeleteTargetId = null;
		caracterizacionRangoModalOpen = false;
		subtipoDeleteTargetId = null;
		subtipoModalOpen = false;
		sidebarOpen = true;
		showCloseWithoutSavingModal = false;
		setSidebarBaselineFromCurrent();
		void loadCaracterizacionesRangoForCurrentSecuencia();
		void loadSubtiposForCurrentSecuencia();
	}

	function performCloseSidebar() {
		clearAutosaveTimer();
		sidebarOpen = false;
		editingId = null;
		caracterizacionesRango = [];
		caracterizacionesRangoLoading = false;
		caracterizacionesRangoRequestCounter += 1;
		subtipos = [];
		subtiposLoading = false;
		subtiposRequestCounter += 1;
		caracterizacionRangoModalOpen = false;
		caracterizacionRangoEditingId = null;
		caracterizacionRangoDeleteTargetId = null;
		subtipoModalOpen = false;
		subtipoEditingId = null;
		subtipoDeleteTargetId = null;
		sidebarDirty = false;
		sidebarBaselineSnapshot = '';
		lastSidebarSnapshot = '';
		autosaveErrorShown = false;
		showCloseWithoutSavingModal = false;
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
		showCloseWithoutSavingModal = true;
	}

	function cancelCloseWithoutSaving() {
		showCloseWithoutSavingModal = false;
	}

	function confirmCloseWithoutSaving() {
		performCloseSidebar();
	}

	async function save(source: 'manual' | 'autosave' = 'manual') {
		if (!browser) return;
		if (props.readOnly || sidebarSaving || !sidebarOpen) return;
		const showToast = source === 'manual';
		if (!validateForm(showToast)) return;

		sidebarSaving = true;
		const currentId = editingId;
		const endpoint = currentId
			? `/api/obras/${props.obraId}/secuencias/${currentId}`
			: `/api/obras/${props.obraId}/secuencias`;
		const method = currentId ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				...form,
				evocacion_metrica_texto: form.evocacion_metrica ? form.evocacion_metrica_texto : null
			})
		});
		sidebarSaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message = body.message ?? 'No se pudo guardar la secuencia';
			if (source === 'manual') {
				pushToast('error', message);
			} else {
				handleAutosaveError(message);
			}
			return;
		}

		const payload = await response.json();
		const savedSecuencia = payload.secuencia as Tables<'secuencias_metricas'>;
		const savedId = currentId ?? savedSecuencia.secuencia_id;

		if (currentId) {
			const next = secuencias.map((item) => (item.secuencia_id === currentId ? savedSecuencia : item));
			secuencias = next;
			emitSecuenciasChange(next);
			void loadSubtiposForCurrentSecuencia();
		} else {
			const next = sortSecuencias([...secuencias, savedSecuencia]);
			secuencias = next;
			emitSecuenciasChange(next);
			editingId = savedId;
			void loadCaracterizacionesRangoForCurrentSecuencia();
			void loadSubtiposForCurrentSecuencia();
		}

		form = {
			v_ini: savedSecuencia.v_ini,
			v_fin: savedSecuencia.v_fin,
			estrofa_tipo_id: toSelectableEstrofaId(savedSecuencia.estrofa_tipo_id),
			inaugura_espacio: Boolean(savedSecuencia.inaugura_espacio),
			versos_partidos: Boolean(savedSecuencia.versos_partidos),
			evocacion_metrica: Boolean(savedSecuencia.evocacion_metrica),
			evocacion_metrica_texto: savedSecuencia.evocacion_metrica_texto ?? '',
			intervencion_personajes_femeninos:
				savedSecuencia.intervencion_personajes_femeninos as FormState['intervencion_personajes_femeninos'],
			intervencion_figuras_donaire:
				savedSecuencia.intervencion_figuras_donaire as FormState['intervencion_figuras_donaire'],
			intervencion_personajes_sobrenaturales:
				savedSecuencia.intervencion_personajes_sobrenaturales as FormState['intervencion_personajes_sobrenaturales'],
			certeza_editor: savedSecuencia.certeza_editor,
			sinopsis: savedSecuencia.sinopsis ?? ''
		};

		setSidebarBaselineFromCurrent();
		autosaveErrorShown = false;
		if (source === 'manual') {
			pushToast('success', currentId ? 'Secuencia actualizada' : 'Secuencia creada');
			if (
				!currentId &&
				(filtroEstrofa || filtroCerteza) &&
				((filtroEstrofa && savedSecuencia.estrofa_tipo_id !== filtroEstrofa) ||
					(filtroCerteza && savedSecuencia.certeza_editor !== filtroCerteza))
			) {
				pushToast('info', 'Secuencia creada. Está oculta por los filtros actuales.');
			}
		}
	}

	function openDelete(secuenciaId: string) {
		if (props.readOnly) return;
		deleteTargetId = secuenciaId;
	}

	async function remove(secuenciaId: string) {
		if (!browser) return;
		if (props.readOnly) return;
		const response = await fetch(`/api/obras/${props.obraId}/secuencias/${secuenciaId}`, {
			method: 'DELETE'
		});
		if (!response.ok) {
			pushToast('error', 'No se pudo eliminar la secuencia');
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
	}

	async function loadCaracterizacionesRangoForCurrentSecuencia() {
		if (!browser) return;
		if (!editingId) {
			caracterizacionesRango = [];
			return;
		}
		caracterizacionesRangoLoading = true;
		const requestId = ++caracterizacionesRangoRequestCounter;

		const response = await fetch(`/api/obras/${props.obraId}/secuencias/${editingId}/caracterizaciones`);
		if (requestId !== caracterizacionesRangoRequestCounter) return;
		caracterizacionesRangoLoading = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudieron cargar las caracterizaciones por rango');
			return;
		}

		const payload = await response.json().catch(() => ({ items: [] }));
		caracterizacionesRango = sortCaracterizacionesRango(
			(payload.items ?? []) as CaracterizacionRangoItem[]
		);
	}

	function validateCaracterizacionRangoForm(showToast = true) {
		if (!editingId) {
			if (showToast) {
				pushToast('error', 'Guarda la secuencia antes de gestionar caracterizaciones por rango');
			}
			return false;
		}
		if (!caracterizacionRangoForm.tipo_caracterizacion_rango_id) {
			if (showToast) pushToast('error', 'Selecciona un tipo de caracterización');
			return false;
		}
		if (!caracterizacionRangoById.has(caracterizacionRangoForm.tipo_caracterizacion_rango_id)) {
			if (showToast) pushToast('error', 'El tipo de caracterización seleccionado no es válido');
			return false;
		}

		const vIni = Number(caracterizacionRangoForm.v_ini);
		const vFin = Number(caracterizacionRangoForm.v_fin);
		if (!Number.isFinite(vIni) || !Number.isFinite(vFin)) {
			if (showToast) pushToast('error', 'Versos de caracterización inválidos');
			return false;
		}
		if (vIni > vFin) {
			if (showToast) pushToast('error', 'El verso inicial no puede ser mayor que el final');
			return false;
		}
		if (vIni < Number(form.v_ini) || vFin > Number(form.v_fin)) {
			if (showToast) {
				pushToast(
					'error',
					`La caracterización debe quedar dentro del rango de la secuencia (${form.v_ini}-${form.v_fin})`
				);
			}
			return false;
		}

		const tipoTerm = selectedCaracterizacionRangoTerm;
		if (tipoTerm === 'prosa' && vIni >= vFin) {
			if (showToast) pushToast('error', 'En prosa, v_ini debe ser menor que v_fin');
			return false;
		}
		if ((tipoTerm === 'hipometrico' || tipoTerm === 'hipermetrico') && vIni !== vFin) {
			if (showToast) pushToast('error', 'Hipométrico e hipermétrico solo admiten un verso');
			return false;
		}

		return true;
	}

	function openCaracterizacionRangoCreateModal() {
		if (props.readOnly || !editingId) return;
		caracterizacionRangoEditingId = null;
		caracterizacionRangoForm = initialCaracterizacionRangoForm();
		caracterizacionRangoModalOpen = true;
	}

	function openCaracterizacionRangoEditModal(caracterizacion: CaracterizacionRangoItem) {
		if (props.readOnly || !editingId) return;
		caracterizacionRangoEditingId = caracterizacion.caracterizacion_rango_id;
		caracterizacionRangoForm = {
			tipo_caracterizacion_rango_id: caracterizacion.tipo_caracterizacion_rango_id,
			v_ini: caracterizacion.v_ini,
			v_fin: caracterizacion.v_fin,
			observaciones: caracterizacion.observaciones ?? ''
		};
		caracterizacionRangoModalOpen = true;
	}

	function closeCaracterizacionRangoModal() {
		if (caracterizacionRangoModalSaving) return;
		caracterizacionRangoModalOpen = false;
		caracterizacionRangoEditingId = null;
		caracterizacionRangoForm = initialCaracterizacionRangoForm();
	}

	async function saveCaracterizacionRango() {
		if (!browser) return;
		if (props.readOnly || caracterizacionRangoModalSaving || !editingId) return;
		if (!validateCaracterizacionRangoForm(true)) return;

		caracterizacionRangoModalSaving = true;
		const isEditing = Boolean(caracterizacionRangoEditingId);
		const endpoint = isEditing
			? `/api/obras/${props.obraId}/secuencias/${editingId}/caracterizaciones/${caracterizacionRangoEditingId}`
			: `/api/obras/${props.obraId}/secuencias/${editingId}/caracterizaciones`;
		const method = isEditing ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				tipo_caracterizacion_rango_id: caracterizacionRangoForm.tipo_caracterizacion_rango_id,
				v_ini: Number(caracterizacionRangoForm.v_ini),
				v_fin: Number(caracterizacionRangoForm.v_fin),
				observaciones: caracterizacionRangoForm.observaciones.trim() || null
			})
		});
		caracterizacionRangoModalSaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message =
				body.details?.[0]?.message ??
				body.message ??
				(isEditing
					? 'No se pudo actualizar la caracterización'
					: 'No se pudo crear la caracterización');
			pushToast('error', message);
			return;
		}

		const payload = await response.json();
		const saved = payload.caracterizacion as CaracterizacionRangoItem;
		if (isEditing && caracterizacionRangoEditingId) {
			caracterizacionesRango = sortCaracterizacionesRango(
				caracterizacionesRango.map((item) =>
					item.caracterizacion_rango_id === caracterizacionRangoEditingId ? saved : item
				)
			);
		} else {
			caracterizacionesRango = sortCaracterizacionesRango([...caracterizacionesRango, saved]);
		}

		closeCaracterizacionRangoModal();
		pushToast('success', isEditing ? 'Caracterización actualizada' : 'Caracterización creada');
	}

	function openCaracterizacionRangoDeleteModal(caracterizacionRangoId: string) {
		if (props.readOnly) return;
		caracterizacionRangoDeleteTargetId = caracterizacionRangoId;
	}

	function closeCaracterizacionRangoDeleteModal() {
		caracterizacionRangoDeleteTargetId = null;
	}

	async function removeCaracterizacionRango(caracterizacionRangoId: string) {
		if (!browser) return;
		if (props.readOnly || !editingId) return;
		const response = await fetch(
			`/api/obras/${props.obraId}/secuencias/${editingId}/caracterizaciones/${caracterizacionRangoId}`,
			{
				method: 'DELETE'
			}
		);
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo eliminar la caracterización');
			return;
		}
		caracterizacionesRango = caracterizacionesRango.filter(
			(row) => row.caracterizacion_rango_id !== caracterizacionRangoId
		);
		caracterizacionRangoDeleteTargetId = null;
		pushToast('success', 'Caracterización eliminada');
	}

	async function loadSubtiposForCurrentSecuencia() {
		if (!browser) return;
		if (!editingId) {
			subtipos = [];
			return;
		}
		subtiposLoading = true;
		const requestId = ++subtiposRequestCounter;

		const response = await fetch(`/api/obras/${props.obraId}/secuencias/${editingId}/subtipos`);
		if (requestId !== subtiposRequestCounter) return;
		subtiposLoading = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudieron cargar los subtipos');
			return;
		}

		const payload = await response.json().catch(() => ({ items: [] }));
		subtipos = sortSubtipos((payload.items ?? []) as SubtipoItem[]);
	}

	function validateSubtipoForm(showToast = true) {
		if (!editingId) {
			if (showToast) pushToast('error', 'Guarda la secuencia antes de gestionar subtipos');
			return false;
		}
		if (!isSubtipoEnabledForCurrentEstrofa) {
			if (showToast) pushToast('error', 'Los subtipos solo están habilitados para secuencias de quintilla');
			return false;
		}
		if (subtipoOptionsForCurrentEstrofa.length === 0) {
			if (showToast) pushToast('error', 'No hay subtipos disponibles para la estrofa seleccionada');
			return false;
		}
		if (!subtipoForm.subtipo_estrofa_id) {
			if (showToast) pushToast('error', 'Selecciona un subtipo');
			return false;
		}
		if (!subtipoById.has(subtipoForm.subtipo_estrofa_id)) {
			if (showToast) pushToast('error', 'El subtipo seleccionado no es válido para esta estrofa');
			return false;
		}

		const vIni = Number(subtipoForm.v_ini);
		const vFin = Number(subtipoForm.v_fin);
		if (!Number.isFinite(vIni) || !Number.isFinite(vFin)) {
			if (showToast) pushToast('error', 'Versos de subtipo inválidos');
			return false;
		}
		if (vIni > vFin) {
			if (showToast) pushToast('error', 'El verso inicial no puede ser mayor que el final');
			return false;
		}
		if (vIni < Number(form.v_ini) || vFin > Number(form.v_fin)) {
			if (showToast) {
				pushToast(
					'error',
					`El subtipo debe quedar dentro del rango de la secuencia (${form.v_ini}-${form.v_fin})`
				);
			}
			return false;
		}

		return true;
	}

	function openSubtipoCreateModal() {
		if (props.readOnly || !editingId || !isSubtipoEnabledForCurrentEstrofa) return;
		const suggestedRange = suggestNextSubtipoRange(
			{ v_ini: Number(form.v_ini), v_fin: Number(form.v_fin) },
			subtipos
		);
		if (!suggestedRange.available) {
			pushToast('error', 'No quedan versos disponibles para añadir otro subtipo.');
			return;
		}
		subtipoEditingId = null;
		subtipoForm = {
			subtipo_estrofa_id: getDefaultSubtipoId(),
			v_ini: suggestedRange.v_ini,
			v_fin: suggestedRange.v_fin
		};
		subtipoModalOpen = true;
	}

	function openSubtipoEditModal(subtipo: SubtipoItem) {
		if (props.readOnly || !editingId || !isSubtipoEnabledForCurrentEstrofa) return;
		subtipoEditingId = subtipo.subtipo_secuencia_id;
		subtipoForm = {
			subtipo_estrofa_id: subtipo.subtipo_estrofa_id,
			v_ini: subtipo.v_ini,
			v_fin: subtipo.v_fin
		};
		subtipoModalOpen = true;
	}

	function closeSubtipoModal() {
		if (subtipoModalSaving) return;
		subtipoModalOpen = false;
		subtipoEditingId = null;
		subtipoForm = initialSubtipoForm();
	}

	async function saveSubtipo() {
		if (!browser) return;
		if (props.readOnly || subtipoModalSaving || !editingId) return;
		if (!validateSubtipoForm(true)) return;

		subtipoModalSaving = true;
		const isEditing = Boolean(subtipoEditingId);
		const endpoint = isEditing
			? `/api/obras/${props.obraId}/secuencias/${editingId}/subtipos/${subtipoEditingId}`
			: `/api/obras/${props.obraId}/secuencias/${editingId}/subtipos`;
		const method = isEditing ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				subtipo_estrofa_id: subtipoForm.subtipo_estrofa_id,
				v_ini: Number(subtipoForm.v_ini),
				v_fin: Number(subtipoForm.v_fin)
			})
		});
		subtipoModalSaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message =
				body.details?.[0]?.message ??
				body.message ??
				(isEditing ? 'No se pudo actualizar el subtipo' : 'No se pudo crear el subtipo');
			pushToast('error', message);
			return;
		}

		const payload = await response.json();
		const saved = payload.subtipo as SubtipoItem;
		if (isEditing && subtipoEditingId) {
			subtipos = sortSubtipos(
				subtipos.map((item) => (item.subtipo_secuencia_id === subtipoEditingId ? saved : item))
			);
		} else {
			subtipos = sortSubtipos([...subtipos, saved]);
		}

		closeSubtipoModal();
		pushToast('success', isEditing ? 'Subtipo actualizado' : 'Subtipo creado');
	}

	function openSubtipoDeleteModal(subtipoSecuenciaId: string) {
		if (props.readOnly) return;
		subtipoDeleteTargetId = subtipoSecuenciaId;
	}

	function closeSubtipoDeleteModal() {
		subtipoDeleteTargetId = null;
	}

	async function removeSubtipo(subtipoSecuenciaId: string) {
		if (!browser) return;
		if (props.readOnly || !editingId) return;
		const response = await fetch(
			`/api/obras/${props.obraId}/secuencias/${editingId}/subtipos/${subtipoSecuenciaId}`,
			{
				method: 'DELETE'
			}
		);
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo eliminar el subtipo');
			return;
		}
		subtipos = subtipos.filter((row) => row.subtipo_secuencia_id !== subtipoSecuenciaId);
		subtipoDeleteTargetId = null;
		pushToast('success', 'Subtipo eliminado');
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
		const saving = sidebarSaving;
		const track = `${form.v_ini}|${form.v_fin}|${form.estrofa_tipo_id}|${form.inaugura_espacio}|${form.versos_partidos}|${form.evocacion_metrica}|${form.evocacion_metrica_texto}|${form.intervencion_personajes_femeninos}|${form.intervencion_figuras_donaire}|${form.intervencion_personajes_sobrenaturales}|${form.certeza_editor}|${form.sinopsis}|${editingId}`;
		void track;

		if (!open || readOnly) {
			sidebarDirty = false;
			clearAutosaveTimer();
			return;
		}

		const currentSnapshot = sidebarSnapshot();
		if (currentSnapshot !== lastSidebarSnapshot) {
			lastSidebarSnapshot = currentSnapshot;
			autosaveErrorShown = false;
		}

		sidebarDirty = currentSnapshot !== sidebarBaselineSnapshot;
		if (!sidebarDirty) {
			clearAutosaveTimer();
			return;
		}

		if (saving) return;

		if (!validateForm(false)) {
			clearAutosaveTimer();
			return;
		}

		clearAutosaveTimer();
		autosaveTimer = setTimeout(() => {
			void save('autosave');
		}, 10_000);
	});

	$effect(() => {
		const enabled = isSubtipoEnabledForCurrentEstrofa;
		const availableIds = subtipoDropdownItems.map((item) => item.id);
		const currentSubtipoId = subtipoForm.subtipo_estrofa_id;
		if (!enabled) {
			const fallbackVerse = Number(form.v_ini) || 1;
			if (subtipoModalOpen) subtipoModalOpen = false;
			if (subtipoEditingId) subtipoEditingId = null;
			if (subtipoDeleteTargetId) subtipoDeleteTargetId = null;
			if (
				currentSubtipoId !== '' ||
				subtipoForm.v_ini !== fallbackVerse ||
				subtipoForm.v_fin !== fallbackVerse
			) {
				subtipoForm = {
					subtipo_estrofa_id: '',
					v_ini: fallbackVerse,
					v_fin: fallbackVerse
				};
			}
			return;
		}

		if (availableIds.length === 0) {
			if (currentSubtipoId !== '') {
				subtipoForm = {
					...subtipoForm,
					subtipo_estrofa_id: ''
				};
			}
			return;
		}

		if (!availableIds.includes(currentSubtipoId)) {
			subtipoForm = {
				...subtipoForm,
				subtipo_estrofa_id: availableIds[0]
			};
		}
	});

	onDestroy(() => {
		clearAutosaveTimer();
	});
</script>

<section class="space-y-4">
	<div
		class="flex items-end justify-between gap-4 border-b border-[color:var(--border)] bg-[color:var(--gray-50)] pb-3 pt-2"
	>
		<div>
			<h2 class="text-xl font-semibold">Secuencias métricas</h2>
		</div>
		<Button variant="primary-soft" onclick={openNew} disabled={props.readOnly}>Nueva secuencia</Button>
	</div>

	<div class="card grid gap-3 p-4 md:grid-cols-2">
		<div class="form-field">
			<span class="form-label">Filtro por estrofa</span>
			<CheckDropdown
				multiple={false}
				hierarchical={true}
				collapsibleHierarchy={true}
				disableParentsWithChildren={true}
				showPathInTrigger={true}
				allowSingleClear={true}
				search={true}
				placeholder="Todas"
				items={estrofaDropdownItems}
				selectedIds={filtroEstrofa ? [filtroEstrofa] : []}
				onChange={(ids) => {
					filtroEstrofa = ids[0] ?? '';
				}}
			/>
		</div>
		<label class="form-field">
			<span class="form-label">Filtro por certeza</span>
			<CheckDropdown
				multiple={false}
				allowSingleClear={true}
				search={certezaDropdownItems.length > 8}
				placeholder="Todas"
				items={certezaDropdownItems}
				selectedIds={filtroCerteza ? [filtroCerteza] : []}
				onChange={(ids) => {
					filtroCerteza = ids[0] ?? '';
				}}
			/>
		</label>
	</div>

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
				<Button variant="primary-soft" class="w-full" onclick={openNew} disabled={props.readOnly}>
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
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">Estrofa</th>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">Certeza</th>
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">
								<div class="ml-auto w-[11.5rem] text-left whitespace-nowrap">Acciones</div>
							</th>
						</tr>
					</thead>
					<tbody>
						{#if filteredSecuencias.length === 0}
							<tr>
								<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={7}>
									Sin secuencias para este filtro.
								</td>
							</tr>
						{:else}
							{#each filteredSecuencias as secuencia, idx}
								<tr class="border-t border-[color:var(--border)]">
									<td class="px-3 py-2">{idx + 1}</td>
									<td class="px-3 py-2">{secuencia.v_ini}</td>
									<td class="px-3 py-2">{secuencia.v_fin}</td>
									<td class="px-3 py-2">{secuencia.n_versos}</td>
									<td class="px-3 py-2">{termById(props.estrofaOptions, secuencia.estrofa_tipo_id)}</td>
									<td class="px-3 py-2">{termById(props.certezaOptions, secuencia.certeza_editor)}</td>
									<td class="px-3 py-2">
										<div class="ml-auto flex w-[11.5rem] items-center gap-2">
											<Button
												variant="ghost"
												onclick={() => openEdit(secuencia)}
												disabled={props.readOnly && !props.canComment}
												>{props.readOnly ? 'Ver' : 'Editar'}</Button
											>
											<Button
												variant="danger"
												onclick={() => openDelete(secuencia.secuencia_id)}
												disabled={props.readOnly}>Eliminar</Button
											>
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

	<div class="card grid gap-3 p-4 sm:grid-cols-3">
		<div class="rounded-md border border-[color:var(--border)] bg-white px-3 py-2">
			<p class="text-xs text-[color:var(--muted-foreground)]">Total estructura</p>
			<p class="text-lg font-semibold">
				{#if totalVersosEstructura === null}
					--
				{:else}
					{totalVersosEstructura}
				{/if}
			</p>
		</div>
		<div class="rounded-md border border-[color:var(--border)] bg-white px-3 py-2">
			<p class="text-xs text-[color:var(--muted-foreground)]">Versos declarados (filtrado)</p>
			<p class="text-lg font-semibold">{totalVersosDeclaradosFiltrados}</p>
		</div>
		<div class="rounded-md border border-[color:var(--border)] bg-white px-3 py-2">
			<p class="text-xs text-[color:var(--muted-foreground)]">Diferencia</p>
			<p
				class={`text-lg font-semibold ${
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
	<aside class="fixed right-0 top-0 z-40 h-screen w-full max-w-xl overflow-y-auto border-l border-[color:var(--border)] bg-[color:var(--gray-50)] px-5 pb-5 pt-0">
		<div class="sticky top-0 z-20 -mx-5 mb-4 flex items-center justify-between gap-3 border-b border-[color:var(--border)] bg-[color:var(--gray-50)] px-5 pb-3 pt-5">
			<h3 class="text-lg font-semibold">
				{#if editingId}
					{props.readOnly ? 'Ver secuencia' : 'Editar secuencia'}
				{:else}
					Nueva secuencia
				{/if}
			</h3>
			<div class="flex items-center gap-2">
				<Button variant="secondary" onclick={requestCloseSidebar}>Cerrar</Button>
				{#if !props.readOnly}
					<Button variant="success" onclick={() => void save('manual')} disabled={sidebarSaving}>
						{sidebarSaving ? 'Guardando...' : 'Guardar'}
					</Button>
				{/if}
			</div>
		</div>

		<div class="grid gap-3">
			<section class="form-section">
				<h4 class="form-section-title">Métrica base</h4>
				<div class="grid gap-3 sm:grid-cols-2">
					<label class="form-field">
						<span class="form-label">Verso inicial</span>
						<input
							type="number"
							bind:value={form.v_ini}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Verso final</span>
						<input
							type="number"
							bind:value={form.v_fin}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
				</div>

				<label class="form-field mt-3">
					<span class="form-label">Estrofa *</span>
					<CheckDropdown
						class="mt-1"
						multiple={false}
						hierarchical={true}
						collapsibleHierarchy={true}
						disableParentsWithChildren={true}
						showPathInTrigger={true}
						allowSingleClear={false}
						search={true}
						placeholder="Seleccionar estrofa"
						items={estrofaDropdownItems}
						selectedIds={form.estrofa_tipo_id ? [form.estrofa_tipo_id] : []}
						disabled={props.readOnly}
						onChange={(ids) => {
							const nextId = ids[0] ?? '';
							if (!nextId) return;
							form = {
								...form,
								estrofa_tipo_id: nextId
							};
						}}
					/>
				</label>
			</section>

			{#if isSubtipoEnabledForCurrentEstrofa}
			<section class="form-section">
				<div class="mb-2 flex flex-wrap items-center justify-between gap-2">
					<h4 class="form-section-title mb-0">Subtipos internos</h4>
					<Button
						variant="secondary"
						onclick={openSubtipoCreateModal}
						disabled={
							props.readOnly ||
							!editingId ||
							subtipoOptionsForCurrentEstrofa.length === 0
						}
					>
						Añadir subtipo
					</Button>
				</div>

				{#if !editingId}
					<p class="form-help">Guarda la secuencia para añadir subtipos internos.</p>
				{:else if subtipoOptionsForCurrentEstrofa.length === 0}
					<p class="form-help">No hay subtipos de vocabulario definidos para esta estrofa.</p>
				{:else if subtiposLoading}
					<p class="form-help">Cargando subtipos...</p>
				{:else if subtipos.length === 0}
					<p class="form-help">Sin subtipos registrados en esta secuencia.</p>
				{:else}
					<div class="card mt-3 overflow-x-auto">
						<table class="min-w-full text-left text-xs">
							<thead class="bg-[color:var(--muted)]">
								<tr>
									<th class="px-2 py-2">Subtipo</th>
									<th class="px-2 py-2">V_ini</th>
									<th class="px-2 py-2">V_fin</th>
									<th class="px-2 py-2">
										<div class="ml-auto w-[11.5rem] text-left whitespace-nowrap">Acciones</div>
									</th>
								</tr>
							</thead>
							<tbody>
								{#each subtipos as subtipo}
									<tr class="border-t border-[color:var(--border)]">
										<td class="px-2 py-2">
											{subtipoLabelById(subtipo.subtipo_estrofa_id, subtipo.subtipo_estrofa_term)}
										</td>
										<td class="px-2 py-2">{subtipo.v_ini}</td>
										<td class="px-2 py-2">{subtipo.v_fin}</td>
										<td class="px-2 py-2">
											<div class="ml-auto flex w-[11.5rem] items-center gap-2">
												<Button
													variant="ghost"
													onclick={() => openSubtipoEditModal(subtipo)}
													disabled={props.readOnly}
												>
													Editar
												</Button>
												<Button
													variant="danger"
													onclick={() => openSubtipoDeleteModal(subtipo.subtipo_secuencia_id)}
													disabled={props.readOnly}
												>
													Eliminar
												</Button>
											</div>
										</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				{/if}
			</section>
			{/if}

			<section class="form-section">
				<div class="mb-2 flex flex-wrap items-center justify-between gap-2">
					<h4 class="form-section-title mb-0">Caracterizaciones por rango</h4>
					<Button
						variant="secondary"
						onclick={openCaracterizacionRangoCreateModal}
						disabled={props.readOnly || !editingId}
					>
						Añadir caracterización
					</Button>
				</div>

				{#if !editingId}
					<p class="form-help">Guarda la secuencia para añadir caracterizaciones por rango.</p>
				{:else if caracterizacionesRangoLoading}
					<p class="form-help">Cargando caracterizaciones por rango...</p>
				{:else if caracterizacionesRango.length === 0}
					<p class="form-help">Sin caracterizaciones por rango registradas en esta secuencia.</p>
				{:else}
					<div class="card mt-3 overflow-x-auto">
						<table class="min-w-full text-left text-xs">
							<thead class="bg-[color:var(--muted)]">
								<tr>
									<th class="px-2 py-2">Tipo</th>
									<th class="px-2 py-2">V_ini</th>
									<th class="px-2 py-2">V_fin</th>
									<th class="px-2 py-2">
										<div class="ml-auto w-[11.5rem] text-left whitespace-nowrap">Acciones</div>
									</th>
								</tr>
							</thead>
							<tbody>
								{#each caracterizacionesRango as caracterizacion}
									<tr class="border-t border-[color:var(--border)]">
										<td class="px-2 py-2">
											{caracterizacionRangoLabelById(
												caracterizacion.tipo_caracterizacion_rango_id,
												caracterizacion.tipo_caracterizacion_rango_term
											)}
										</td>
										<td class="px-2 py-2">{caracterizacion.v_ini}</td>
										<td class="px-2 py-2">{caracterizacion.v_fin}</td>
										<td class="px-2 py-2">
											<div class="ml-auto flex w-[11.5rem] items-center gap-2">
												<Button
													variant="ghost"
													onclick={() => openCaracterizacionRangoEditModal(caracterizacion)}
													disabled={props.readOnly}
												>
													Editar
												</Button>
												<Button
													variant="danger"
													onclick={() =>
														openCaracterizacionRangoDeleteModal(
															caracterizacion.caracterizacion_rango_id
														)}
													disabled={props.readOnly}
												>
													Eliminar
												</Button>
											</div>
										</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				{/if}
			</section>


			<section class="form-section">
				<h4 class="form-section-title">
					<span class="form-label-with-help">
						Intervención de personajes
						<FieldHelpTooltip text={INTERVENCION_HELP} label="Ayuda sobre la intervención de personajes" />
					</span>
				</h4>
				<div class="grid gap-3 sm:grid-cols-2">
					<label class="form-field">
						<span class="form-label">Personajes femeninos</span>
						<CheckDropdown
							multiple={false}
							search={false}
							placeholder="Seleccionar valor"
							items={intervencionItems}
							disabled={props.readOnly}
							selectedIds={[form.intervencion_personajes_femeninos]}
							onChange={(ids) => {
								const nextPersonajeFemenino = ids[0] as FormState['intervencion_personajes_femeninos'] | undefined;
								if (!nextPersonajeFemenino) return;
								form = {
									...form,
									intervencion_personajes_femeninos: nextPersonajeFemenino
								};
							}}
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Figuras de donaire</span>
						<CheckDropdown
							multiple={false}
							search={false}
							placeholder="Seleccionar valor"
							items={intervencionItems}
							disabled={props.readOnly}
							selectedIds={[form.intervencion_figuras_donaire]}
							onChange={(ids) => {
								const nextDonaire = ids[0] as FormState['intervencion_figuras_donaire'] | undefined;
								if (!nextDonaire) return;
								form = {
									...form,
									intervencion_figuras_donaire: nextDonaire
								};
							}}
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Personajes sobrenaturales</span>
						<CheckDropdown
							multiple={false}
							search={false}
							placeholder="Seleccionar valor"
							items={intervencionItems}
							disabled={props.readOnly}
							selectedIds={[form.intervencion_personajes_sobrenaturales]}
							onChange={(ids) => {
								const nextSobrenatural = ids[0] as FormState['intervencion_personajes_sobrenaturales'] | undefined;
								if (!nextSobrenatural) return;
								form = {
									...form,
									intervencion_personajes_sobrenaturales: nextSobrenatural
								};
							}}
						/>
					</label>
				</div>
			</section>

			<section class="form-section">
				<h4 class="form-section-title">Otras caracterizaciones</h4>
				<div class="grid gap-3 sm:grid-cols-2">
					<div class="grid grid-cols-2 gap-3 sm:col-span-2">
						<div class="form-field min-w-0">
						<span class="form-label">
							<span class="form-label-with-help">
								Versos partidos
								<FieldHelpTooltip
									text="Marca 'Sí' si en esta secuencia hay versos repartidos entre intervenciones de distintos personajes."
									label="Ayuda sobre el campo Versos partidos"
								/>
							</span>
						</span>
						<div class="form-inline-toggle">
							<button
								type="button"
								role="switch"
								aria-checked={form.versos_partidos}
								aria-label="Versos partidos"
								class={`form-switch ${props.readOnly ? 'cursor-not-allowed opacity-60' : 'cursor-pointer'}`}
								disabled={props.readOnly}
								onclick={() => {
									form = {
										...form,
										versos_partidos: !form.versos_partidos
									};
								}}
							>
								<span class="form-switch-thumb"></span>
							</button>
							<span class="text-[color:var(--muted-foreground)]">
								{form.versos_partidos ? 'Sí' : 'No'}
							</span>
						</div>
						</div>

						<div class="form-field min-w-0">
						<span class="form-label">
							<span class="form-label-with-help">
								Inaugura espacio
								<FieldHelpTooltip
									text="Marca 'Sí' si coincide (de forma evidente) el inicio de esta secuencia con el cambio de espacio escénico"
									label="Ayuda sobre el campo Inaugura espacio"
								/>
							</span>
						</span>
						<div class="form-inline-toggle">
							<button
								type="button"
								role="switch"
								aria-checked={form.inaugura_espacio}
								aria-label="Inaugura espacio"
								class={`form-switch ${props.readOnly ? 'cursor-not-allowed opacity-60' : 'cursor-pointer'}`}
								disabled={props.readOnly}
								onclick={() => {
									form = {
										...form,
										inaugura_espacio: !form.inaugura_espacio
									};
								}}
							>
								<span class="form-switch-thumb"></span>
							</button>
							<span class="text-[color:var(--muted-foreground)]">
								{form.inaugura_espacio ? 'Sí' : 'No'}
							</span>
						</div>
						</div>
					</div>
					<label class="form-field sm:col-span-2">
						<span class="form-label">
							<span class="form-label-with-help">
								Evocación métrica
								<FieldHelpTooltip
									text="Marca esta opción cuando el cambio de metro se deba a que un personaje adopta, imita o reproduce la voz de otro personaje."
									label="Ayuda sobre el campo Evocación métrica"
								/>
							</span>
						</span>
						<div class="form-inline-toggle">
							<input
								type="checkbox"
								class="h-4 w-4"
								checked={form.evocacion_metrica}
								disabled={props.readOnly}
								onchange={(event) => {
									const checked = event.currentTarget.checked;
									form = {
										...form,
										evocacion_metrica: checked,
										evocacion_metrica_texto: checked ? form.evocacion_metrica_texto : ''
									};
								}}
							/>
							<span class="text-[color:var(--muted-foreground)]">
								{form.evocacion_metrica ? 'Sí' : 'No'}
							</span>
						</div>
					</label>
					{#if form.evocacion_metrica}
						<label class="form-field sm:col-span-2">
							<span class="form-label">Explicación de la evocación métrica</span>
							<MarkdownEditorLite
								rows={3}
								class="mt-1"
								minHeightClass="min-h-24"
								value={form.evocacion_metrica_texto}
								disabled={props.readOnly}
								onChange={(nextValue) => {
									form = {
										...form,
										evocacion_metrica_texto: nextValue
									};
								}}
							/>
						</label>
					{/if}
				</div>
			</section>

			<section class="form-section">
				<h4 class="form-section-title">Sinopsis argumental</h4>
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
			</section>

			<section class="form-section">
				<h4 class="form-section-title">
					<span class="form-label-with-help">
						Certeza
						<FieldHelpTooltip
							text="Indica el grado de seguridad de la información que has registrado sobre esta secuencia para facilitar su revisión posterior"
							label="Ayuda sobre el campo Certeza"
						/>
					</span>
				</h4>
				<label class="form-field">
					<span class="sr-only">Certeza</span>
					<CheckDropdown
						multiple={false}
						search={certezaDropdownItems.length > 8}
						placeholder="Seleccionar certeza"
						items={certezaDropdownItems}
						disabled={props.readOnly}
						selectedIds={form.certeza_editor ? [form.certeza_editor] : []}
						onChange={(ids) => {
							const nextCerteza = ids[0] ?? '';
							if (!nextCerteza) return;
							form = {
								...form,
								certeza_editor: nextCerteza
							};
						}}
					/>
				</label>
			</section>
		</div>

		{#if editingId}
			<div class="mt-4">
				{#key editingId}
					<InternalCommentsPanel
						obraId={props.obraId}
						canComment={Boolean(props.canComment)}
						title="Comentarios internos de secuencia"
						context={{ secuencia_id: editingId }}
						collapsible={true}
						defaultCollapsed={true}
						collapseLabel="Ver"
						focusComentarioId={props.focusComentarioId}
					/>
				{/key}
			</div>
		{/if}
	</aside>
	{/if}

	{#if caracterizacionRangoModalOpen}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
			<div class="card w-full max-w-2xl p-5">
				<h3 class="text-lg font-semibold">
					{caracterizacionRangoEditingId ? 'Editar caracterización' : 'Añadir caracterización'}
				</h3>
				<div class="mt-3 grid gap-3">
					<label class="form-field">
						<span class="form-label">Tipo *</span>
						<CheckDropdown
							multiple={false}
							hierarchical={true}
							collapsibleHierarchy={true}
							showPathInTrigger={true}
							allowSingleClear={false}
							search={caracterizacionRangoDropdownItems.length > 8}
							placeholder="Seleccionar tipo"
							items={caracterizacionRangoDropdownItems}
							disabled={props.readOnly || caracterizacionRangoModalSaving}
							disableParentsWithChildren={true}
							selectedIds={
								caracterizacionRangoForm.tipo_caracterizacion_rango_id
									? [caracterizacionRangoForm.tipo_caracterizacion_rango_id]
									: []
							}
							onChange={(ids) => {
								const nextId = ids[0] ?? '';
								if (!nextId) return;
								caracterizacionRangoForm = {
									...caracterizacionRangoForm,
									tipo_caracterizacion_rango_id: nextId
								};
							}}
						/>
					</label>

					<div class="grid gap-3 sm:grid-cols-2">
						<label class="form-field">
							<span class="form-label">V. ini *</span>
							<input
								type="number"
								bind:value={caracterizacionRangoForm.v_ini}
								disabled={props.readOnly || caracterizacionRangoModalSaving}
								class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
							/>
						</label>
						<label class="form-field">
							<span class="form-label">V. fin *</span>
							<input
								type="number"
								bind:value={caracterizacionRangoForm.v_fin}
								disabled={props.readOnly || caracterizacionRangoModalSaving}
								class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
							/>
						</label>
					</div>

										{#if caracterizacionRangoRangeHelperText}
						<p class="rounded-md border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-xs text-[color:var(--muted-foreground)]">
							{caracterizacionRangoRangeHelperText}
						</p>
					{/if}

					<label class="form-field">
						<span class="form-label">
							<span class="form-label-with-help">
								Observaciones
								<FieldHelpTooltip
									text="Este contenido se publica en la ficha pública de la obra."
									label="Visibilidad pública de observaciones de la caracterización"
								/>
							</span>
						</span>
						<MarkdownEditorLite
							rows={3}
							class="mt-1"
							minHeightClass="min-h-24"
							value={caracterizacionRangoForm.observaciones}
							disabled={props.readOnly || caracterizacionRangoModalSaving}
							onChange={(nextValue) => {
								caracterizacionRangoForm = {
									...caracterizacionRangoForm,
									observaciones: nextValue
								};
							}}
						/>
					</label>
				</div>
				<div class="mt-4 flex justify-end gap-2">
					<Button variant="secondary" onclick={closeCaracterizacionRangoModal}>Cancelar</Button>
					<Button
						variant="success"
						disabled={props.readOnly || caracterizacionRangoModalSaving}
						onclick={() => void saveCaracterizacionRango()}
					>
						{caracterizacionRangoModalSaving ? 'Guardando...' : 'Guardar'}
					</Button>
				</div>
			</div>
		</div>
	{/if}

	{#if subtipoModalOpen}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
			<div class="card w-full max-w-2xl p-5">
				<h3 class="text-lg font-semibold">
					{subtipoEditingId ? 'Editar subtipo' : 'Añadir subtipo'}
				</h3>
				<div class="mt-3 grid gap-3">
					<label class="form-field">
						<span class="form-label">Subtipo *</span>
						<CheckDropdown
							multiple={false}
							search={subtipoDropdownItems.length > 8}
							allowSingleClear={false}
							placeholder="Seleccionar subtipo"
							items={subtipoDropdownItems}
							disabled={props.readOnly || subtipoModalSaving}
							selectedIds={subtipoForm.subtipo_estrofa_id ? [subtipoForm.subtipo_estrofa_id] : []}
							onChange={(ids) => {
								const nextId = ids[0] ?? '';
								if (!nextId) return;
								subtipoForm = {
									...subtipoForm,
									subtipo_estrofa_id: nextId
								};
							}}
						/>
					</label>

					<div class="grid gap-3 sm:grid-cols-2">
						<label class="form-field">
							<span class="form-label">V. ini *</span>
							<input
								type="number"
								bind:value={subtipoForm.v_ini}
								disabled={props.readOnly || subtipoModalSaving}
								class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
							/>
						</label>
						<label class="form-field">
							<span class="form-label">V. fin *</span>
							<input
								type="number"
								bind:value={subtipoForm.v_fin}
								disabled={props.readOnly || subtipoModalSaving}
								class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
							/>
						</label>
					</div>
				</div>
				<div class="mt-4 flex justify-end gap-2">
					<Button variant="secondary" onclick={closeSubtipoModal}>Cancelar</Button>
					<Button
						variant="success"
						disabled={props.readOnly || subtipoModalSaving}
						onclick={() => void saveSubtipo()}
					>
						{subtipoModalSaving ? 'Guardando...' : 'Guardar'}
					</Button>
				</div>
			</div>
		</div>
	{/if}

	{#if caracterizacionRangoDeleteTargetId}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
			<div class="card w-full max-w-md p-5">
				<h3 class="text-lg font-semibold">Eliminar caracterización</h3>
				<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta acción no se puede deshacer.</p>
				<div class="mt-4 flex justify-end gap-2">
					<Button variant="secondary" onclick={closeCaracterizacionRangoDeleteModal}>Cancelar</Button>
					<Button
						variant="danger"
						disabled={props.readOnly}
						onclick={() => {
							if (!caracterizacionRangoDeleteTargetId) return;
							void removeCaracterizacionRango(caracterizacionRangoDeleteTargetId);
						}}
					>
						Eliminar
					</Button>
				</div>
			</div>
		</div>
	{/if}

	{#if subtipoDeleteTargetId}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
			<div class="card w-full max-w-md p-5">
				<h3 class="text-lg font-semibold">Eliminar subtipo</h3>
				<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta acción no se puede deshacer.</p>
				<div class="mt-4 flex justify-end gap-2">
					<Button variant="secondary" onclick={closeSubtipoDeleteModal}>Cancelar</Button>
					<Button
						variant="danger"
						disabled={props.readOnly}
						onclick={() => {
							if (!subtipoDeleteTargetId) return;
							void removeSubtipo(subtipoDeleteTargetId);
						}}
					>
						Eliminar
					</Button>
				</div>
			</div>
		</div>
	{/if}

	{#if deleteTargetId}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Eliminar secuencia</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta acción no se puede deshacer.</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={() => (deleteTargetId = null)}>Cancelar</Button>
				<Button
					variant="danger"
					disabled={props.readOnly}
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

{#if showCloseWithoutSavingModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Cambios sin guardar</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Hay cambios sin guardar en este panel.</p>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">Si continúas, perderás los cambios no guardados.</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={cancelCloseWithoutSaving}>Seguir editando</Button>
				<Button variant="danger" onclick={confirmCloseWithoutSaving}>Cerrar sin guardar</Button>
			</div>
		</div>
	</div>
{/if}




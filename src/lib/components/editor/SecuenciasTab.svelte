<script lang="ts">
	import { browser } from '$app/environment';
	import { onDestroy } from 'svelte';
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import { pushToast } from '$lib/stores/toast';

	const props = $props<{
		obraId: string;
		secuenciasInitial: Tables<'secuencias_metricas'>[];
		jornadasInitial: Array<Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>>;
		cuadrosInitial: Array<Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'>>;
		estrofaOptions: Array<
			Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'termino_padre_id' | 'orden'>
		>;
		certezaOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>;
		tipoVariacionOptions: Array<
			Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'termino_padre_id' | 'orden'>
		>;
		readOnly?: boolean;
		canComment?: boolean;
		onSecuenciasChange?: (items: Tables<'secuencias_metricas'>[]) => void;
	}>();

	type FormState = {
		v_ini: number;
		v_fin: number;
		estrofa_tipo_id: string;
		inaugura_espacio: boolean;
		versos_partidos: boolean;
		personaje_femenino: 'ausente' | 'solo' | 'con_otros';
		personajes_donaire: 'ausente' | 'solo' | 'con_otros';
		personajes_sobrenatural: 'ausente' | 'solo' | 'con_otros';
		certeza_editor: string;
		sinopsis: string;
	};

	type VariacionItem = {
		variacion_id: string;
		secuencia_id: string;
		tipo_variacion_id: string;
		tipo_variacion_term: string;
		tipo_variacion_parent_id: string | null;
		v_ini: number;
		v_fin: number;
		observaciones: string | null;
	};

	type VariacionFormState = {
		tipo_variacion_id: string;
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

	let sidebarSaving = $state(false);
	let sidebarDirty = $state(false);
	let sidebarBaselineSnapshot = $state('');
	let autosaveErrorShown = $state(false);
	let lastSidebarSnapshot = $state('');
	let autosaveTimer: ReturnType<typeof setTimeout> | null = null;
	let variaciones = $state<VariacionItem[]>([]);
	let variacionesLoading = $state(false);
	let variacionesRequestCounter = $state(0);
	let variacionModalOpen = $state(false);
	let variacionModalSaving = $state(false);
	let variacionEditingId = $state<string | null>(null);
	let variacionDeleteTargetId = $state<string | null>(null);
	let variacionForm = $state<VariacionFormState>({
		tipo_variacion_id: '',
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

	function sortTipoVariacionOptions(options: typeof props.tipoVariacionOptions) {
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
			new Map<string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'termino_padre_id'>>(
				sortedEstrofaOptions.map(
					(
						option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'termino_padre_id'>
					): readonly [string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'termino_padre_id'>] => [
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
			label: option.termino,
			parentId: option.termino_padre_id ?? null
		}))
	);
	const tipoVariacionDropdownItems = $derived.by(() =>
		sortTipoVariacionOptions(props.tipoVariacionOptions).map((option) => ({
			id: option.termino_id,
			label: option.termino,
			parentId: option.termino_padre_id ?? null
		}))
	);
	const certezaDropdownItems = $derived(
		props.certezaOptions.map((option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>) => ({
			id: option.termino_id,
			label: option.termino
		}))
	);
	const personajeFemeninoItems = [
		{ id: 'ausente', label: 'ausente' },
		{ id: 'solo', label: 'solo' },
		{ id: 'con_otros', label: 'con_otros' }
	];
	const personajesRolItems = [
		{ id: 'ausente', label: 'ausente' },
		{ id: 'solo', label: 'solo' },
		{ id: 'con_otros', label: 'con_otros' }
	];
	const tipoVariacionById = $derived.by(
		() =>
			new Map<string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>(
				props.tipoVariacionOptions.map(
					(
						option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>
					): readonly [string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>] => [
						option.termino_id,
						option
					]
				)
			)
	);
	const irregularTipoVariacionId = $derived.by(() => {
		const parent = props.tipoVariacionOptions.find(
			(
				option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'termino_padre_id' | 'orden'>
			) => normalizeTerm(option.termino) === 'irregular'
		);
		return parent?.termino_id ?? null;
	});
	const selectedVariacionTipoTerm = $derived.by(() => {
		const term = tipoVariacionById.get(variacionForm.tipo_variacion_id)?.termino ?? '';
		return normalizeTerm(term);
	});
	const variacionRangeHelperText = $derived.by(() => {
		if (selectedVariacionTipoTerm === 'prosa') {
			return 'Indica entre qué versos aparece la prosa (no numerada). Ej: v_ini=56, v_fin=57 -> prosa entre verso 56 y 57.';
		}
		if (selectedVariacionTipoTerm === 'hipometrico' || selectedVariacionTipoTerm === 'hipermetrico') {
			return 'Esta variación aplica a un solo verso: usa el mismo número en V. ini y V. fin.';
		}
		if (
			selectedVariacionTipoTerm === 'cantado' ||
			selectedVariacionTipoTerm === 'rima_defectuosa' ||
			selectedVariacionTipoTerm === 'laguna'
		) {
			return 'Puedes marcar un solo verso (V. ini = V. fin) o un rango (V. ini < V. fin).';
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
			personaje_femenino: 'ausente',
			personajes_donaire: 'ausente',
			personajes_sobrenatural: 'ausente',
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
			label: option.termino,
			parentId: option.termino_padre_id ?? null
		}))
	);
	const subtipoById = $derived.by(
		() =>
			new Map<string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>(
				subtipoOptionsForCurrentEstrofa.map(
					(
						option: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>
					): readonly [string, Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>] => [
						option.termino_id,
						option
					]
				)
			)
	);

	function getDefaultTipoVariacionId() {
		const firstSelectable = sortTipoVariacionOptions(props.tipoVariacionOptions).find(
			(option) => normalizeTerm(option.termino) !== 'irregular'
		);
		return firstSelectable?.termino_id ?? '';
	}

	function initialVariacionForm(): VariacionFormState {
		return {
			tipo_variacion_id: getDefaultTipoVariacionId(),
			v_ini: Number(form.v_ini) || 1,
			v_fin: Number(form.v_ini) || 1,
			observaciones: ''
		};
	}

	function getDefaultSubtipoId() {
		return subtipoOptionsForCurrentEstrofa[0]?.termino_id ?? '';
	}

	function initialSubtipoForm(): SubtipoFormState {
		return {
			subtipo_estrofa_id: getDefaultSubtipoId(),
			v_ini: Number(form.v_ini) || 1,
			v_fin: Number(form.v_ini) || 1
		};
	}

	function termById(options: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>, id: string | null) {
		if (!id) return '--';
		return options.find((option) => option.termino_id === id)?.termino ?? '--';
	}

	function variacionLabelById(tipoVariacionId: string, fallback = '') {
		const fromVocabulary = tipoVariacionById.get(tipoVariacionId)?.termino ?? '';
		return fromVocabulary || fallback || '--';
	}

	function sortVariaciones(items: VariacionItem[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	}

	function sortSubtipos(items: SubtipoItem[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	}

	function subtipoLabelById(subtipoEstrofaId: string, fallback = '') {
		const fromVocabulary = subtipoById.get(subtipoEstrofaId)?.termino ?? '';
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
			personaje_femenino: form.personaje_femenino,
			personajes_donaire: form.personajes_donaire,
			personajes_sobrenatural: form.personajes_sobrenatural,
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
		variaciones = [];
		subtipos = [];
		variacionDeleteTargetId = null;
		variacionModalOpen = false;
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
			personaje_femenino: secuencia.personaje_femenino as FormState['personaje_femenino'],
			personajes_donaire: secuencia.personajes_donaire as FormState['personajes_donaire'],
			personajes_sobrenatural: secuencia.personajes_sobrenatural as FormState['personajes_sobrenatural'],
			certeza_editor: secuencia.certeza_editor,
			sinopsis: secuencia.sinopsis ?? ''
		};
		variaciones = [];
		subtipos = [];
		variacionDeleteTargetId = null;
		variacionModalOpen = false;
		subtipoDeleteTargetId = null;
		subtipoModalOpen = false;
		sidebarOpen = true;
		showCloseWithoutSavingModal = false;
		setSidebarBaselineFromCurrent();
		void loadVariacionesForCurrentSecuencia();
		void loadSubtiposForCurrentSecuencia();
	}

	function performCloseSidebar() {
		clearAutosaveTimer();
		sidebarOpen = false;
		editingId = null;
		variaciones = [];
		variacionesLoading = false;
		variacionesRequestCounter += 1;
		subtipos = [];
		subtiposLoading = false;
		subtiposRequestCounter += 1;
		variacionModalOpen = false;
		variacionEditingId = null;
		variacionDeleteTargetId = null;
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
			body: JSON.stringify(form)
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
			void loadVariacionesForCurrentSecuencia();
			void loadSubtiposForCurrentSecuencia();
		}

		form = {
			v_ini: savedSecuencia.v_ini,
			v_fin: savedSecuencia.v_fin,
			estrofa_tipo_id: toSelectableEstrofaId(savedSecuencia.estrofa_tipo_id),
			inaugura_espacio: Boolean(savedSecuencia.inaugura_espacio),
			versos_partidos: Boolean(savedSecuencia.versos_partidos),
			personaje_femenino: savedSecuencia.personaje_femenino as FormState['personaje_femenino'],
			personajes_donaire: savedSecuencia.personajes_donaire as FormState['personajes_donaire'],
			personajes_sobrenatural: savedSecuencia.personajes_sobrenatural as FormState['personajes_sobrenatural'],
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

	async function loadVariacionesForCurrentSecuencia() {
		if (!browser) return;
		if (!editingId) {
			variaciones = [];
			return;
		}
		variacionesLoading = true;
		const requestId = ++variacionesRequestCounter;

		const response = await fetch(`/api/obras/${props.obraId}/secuencias/${editingId}/variaciones`);
		if (requestId !== variacionesRequestCounter) return;
		variacionesLoading = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudieron cargar las variaciones');
			return;
		}

		const payload = await response.json().catch(() => ({ items: [] }));
		variaciones = sortVariaciones((payload.items ?? []) as VariacionItem[]);
	}

	function validateVariacionForm(showToast = true) {
		if (!editingId) {
			if (showToast) pushToast('error', 'Guarda la secuencia antes de gestionar variaciones');
			return false;
		}
		if (!variacionForm.tipo_variacion_id) {
			if (showToast) pushToast('error', 'Selecciona un tipo de variación');
			return false;
		}
		if (!tipoVariacionById.has(variacionForm.tipo_variacion_id)) {
			if (showToast) pushToast('error', 'El tipo de variación seleccionado no es válido');
			return false;
		}

		const vIni = Number(variacionForm.v_ini);
		const vFin = Number(variacionForm.v_fin);
		if (!Number.isFinite(vIni) || !Number.isFinite(vFin)) {
			if (showToast) pushToast('error', 'Versos de variación inválidos');
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
					`La variación debe quedar dentro del rango de la secuencia (${form.v_ini}-${form.v_fin})`
				);
			}
			return false;
		}

		const tipoTerm = selectedVariacionTipoTerm;
		if (tipoTerm === 'irregular') {
			if (showToast) pushToast('error', 'El tipo irregular es solo agrupador');
			return false;
		}
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

	function openVariacionCreateModal() {
		if (props.readOnly || !editingId) return;
		variacionEditingId = null;
		variacionForm = initialVariacionForm();
		variacionModalOpen = true;
	}

	function openVariacionEditModal(variacion: VariacionItem) {
		if (props.readOnly || !editingId) return;
		variacionEditingId = variacion.variacion_id;
		variacionForm = {
			tipo_variacion_id: variacion.tipo_variacion_id,
			v_ini: variacion.v_ini,
			v_fin: variacion.v_fin,
			observaciones: variacion.observaciones ?? ''
		};
		variacionModalOpen = true;
	}

	function closeVariacionModal() {
		if (variacionModalSaving) return;
		variacionModalOpen = false;
		variacionEditingId = null;
		variacionForm = initialVariacionForm();
	}

	async function saveVariacion() {
		if (!browser) return;
		if (props.readOnly || variacionModalSaving || !editingId) return;
		if (!validateVariacionForm(true)) return;

		variacionModalSaving = true;
		const isEditing = Boolean(variacionEditingId);
		const endpoint = isEditing
			? `/api/obras/${props.obraId}/secuencias/${editingId}/variaciones/${variacionEditingId}`
			: `/api/obras/${props.obraId}/secuencias/${editingId}/variaciones`;
		const method = isEditing ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				tipo_variacion_id: variacionForm.tipo_variacion_id,
				v_ini: Number(variacionForm.v_ini),
				v_fin: Number(variacionForm.v_fin),
				observaciones: variacionForm.observaciones.trim() || null
			})
		});
		variacionModalSaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message =
				body.details?.[0]?.message ??
				body.message ??
				(isEditing ? 'No se pudo actualizar la variación' : 'No se pudo crear la variación');
			pushToast('error', message);
			return;
		}

		const payload = await response.json();
		const saved = payload.variacion as VariacionItem;
		if (isEditing && variacionEditingId) {
			variaciones = sortVariaciones(
				variaciones.map((item) => (item.variacion_id === variacionEditingId ? saved : item))
			);
		} else {
			variaciones = sortVariaciones([...variaciones, saved]);
		}

		closeVariacionModal();
		pushToast('success', isEditing ? 'Variación actualizada' : 'Variación creada');
	}

	function openVariacionDeleteModal(variacionId: string) {
		if (props.readOnly) return;
		variacionDeleteTargetId = variacionId;
	}

	function closeVariacionDeleteModal() {
		variacionDeleteTargetId = null;
	}

	async function removeVariacion(variacionId: string) {
		if (!browser) return;
		if (props.readOnly || !editingId) return;
		const response = await fetch(
			`/api/obras/${props.obraId}/secuencias/${editingId}/variaciones/${variacionId}`,
			{
				method: 'DELETE'
			}
		);
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo eliminar la variación');
			return;
		}
		variaciones = variaciones.filter((row) => row.variacion_id !== variacionId);
		variacionDeleteTargetId = null;
		pushToast('success', 'Variación eliminada');
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
		subtipoEditingId = null;
		subtipoForm = initialSubtipoForm();
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

	$effect(() => {
		const open = sidebarOpen;
		const readOnly = props.readOnly;
		const saving = sidebarSaving;
		const track = `${form.v_ini}|${form.v_fin}|${form.estrofa_tipo_id}|${form.inaugura_espacio}|${form.versos_partidos}|${form.personaje_femenino}|${form.personajes_donaire}|${form.personajes_sobrenatural}|${form.certeza_editor}|${form.sinopsis}|${editingId}`;
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
	<div class="flex items-end justify-between gap-4">
		<div>
			<h2 class="text-xl font-semibold">Secuencias métricas</h2>
			<p class="text-sm text-[color:var(--muted-foreground)]">Ordenadas por verso inicial.</p>
		</div>
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
		<aside class="secuencias-structure-index card hidden lg:sticky lg:top-4 lg:block lg:h-fit lg:self-start">
			<div class="secuencias-structure-index__head">Índice de estructura</div>
			{#if jornadasSorted.length === 0}
				<p class="secuencias-structure-index__empty-text">Sin estructura registrada.</p>
			{:else}
				<ul class="secuencias-structure-list">
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
		</aside>

		<div class="space-y-2">
			<div class="flex justify-start">
				<Button variant="secondary" onclick={openNew} disabled={props.readOnly}>Nueva secuencia</Button>
			</div>
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
</section>

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
					<h4 class="form-section-title mb-0">Variaciones / irregularidades</h4>
					<Button
						variant="secondary"
						onclick={openVariacionCreateModal}
						disabled={props.readOnly || !editingId}
					>
						Añadir variación
					</Button>
				</div>

				{#if !editingId}
					<p class="form-help">Guarda la secuencia para añadir variaciones.</p>
				{:else if variacionesLoading}
					<p class="form-help">Cargando variaciones...</p>
				{:else if variaciones.length === 0}
					<p class="form-help">Sin variaciones registradas en esta secuencia.</p>
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
								{#each variaciones as variacion}
									<tr class="border-t border-[color:var(--border)]">
										<td class="px-2 py-2">
											{variacionLabelById(variacion.tipo_variacion_id, variacion.tipo_variacion_term)}
										</td>
										<td class="px-2 py-2">{variacion.v_ini}</td>
										<td class="px-2 py-2">{variacion.v_fin}</td>
										<td class="px-2 py-2">
											<div class="ml-auto flex w-[11.5rem] items-center gap-2">
												<Button
													variant="ghost"
													onclick={() => openVariacionEditModal(variacion)}
													disabled={props.readOnly}
												>
													Editar
												</Button>
												<Button
													variant="danger"
													onclick={() => openVariacionDeleteModal(variacion.variacion_id)}
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
				<h4 class="form-section-title">Caracterización</h4>
				<div class="grid gap-3 sm:grid-cols-2">
					<label class="form-field">
						<span class="form-label">Personaje femenino</span>
						<CheckDropdown
							multiple={false}
							search={false}
							placeholder="Seleccionar valor"
							items={personajeFemeninoItems}
							disabled={props.readOnly}
							selectedIds={[form.personaje_femenino]}
							onChange={(ids) => {
								const nextPersonajeFemenino = ids[0] as FormState['personaje_femenino'] | undefined;
								if (!nextPersonajeFemenino) return;
								form = {
									...form,
									personaje_femenino: nextPersonajeFemenino
								};
							}}
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Donaire</span>
						<CheckDropdown
							multiple={false}
							search={false}
							placeholder="Seleccionar valor"
							items={personajesRolItems}
							disabled={props.readOnly}
							selectedIds={[form.personajes_donaire]}
							onChange={(ids) => {
								const nextDonaire = ids[0] as FormState['personajes_donaire'] | undefined;
								if (!nextDonaire) return;
								form = {
									...form,
									personajes_donaire: nextDonaire
								};
							}}
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Sobrenatural</span>
						<CheckDropdown
							multiple={false}
							search={false}
							placeholder="Seleccionar valor"
							items={personajesRolItems}
							disabled={props.readOnly}
							selectedIds={[form.personajes_sobrenatural]}
							onChange={(ids) => {
								const nextSobrenatural = ids[0] as FormState['personajes_sobrenatural'] | undefined;
								if (!nextSobrenatural) return;
								form = {
									...form,
									personajes_sobrenatural: nextSobrenatural
								};
							}}
						/>
					</label>

					<div class="grid grid-cols-2 gap-3">
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
						collapseLabel="Ver comentarios"
					/>
				{/key}
			</div>
		{/if}
	</aside>
	{/if}

	{#if variacionModalOpen}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
			<div class="card w-full max-w-2xl p-5">
				<h3 class="text-lg font-semibold">
					{variacionEditingId ? 'Editar variación' : 'Añadir variación'}
				</h3>
				<div class="mt-3 grid gap-3">
					<label class="form-field">
						<span class="form-label">Tipo *</span>
						<CheckDropdown
							multiple={false}
							hierarchical={true}
							showPathInTrigger={true}
							allowSingleClear={false}
							search={tipoVariacionDropdownItems.length > 8}
							placeholder="Seleccionar tipo"
							items={tipoVariacionDropdownItems}
							disabled={props.readOnly || variacionModalSaving}
							disabledIds={irregularTipoVariacionId ? [irregularTipoVariacionId] : []}
							selectedIds={variacionForm.tipo_variacion_id ? [variacionForm.tipo_variacion_id] : []}
							onChange={(ids) => {
								const nextId = ids[0] ?? '';
								if (!nextId) return;
								variacionForm = {
									...variacionForm,
									tipo_variacion_id: nextId
								};
							}}
						/>
					</label>

					<div class="grid gap-3 sm:grid-cols-2">
						<label class="form-field">
							<span class="form-label">V. ini *</span>
							<input
								type="number"
								bind:value={variacionForm.v_ini}
								disabled={props.readOnly || variacionModalSaving}
								class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
							/>
						</label>
						<label class="form-field">
							<span class="form-label">V. fin *</span>
							<input
								type="number"
								bind:value={variacionForm.v_fin}
								disabled={props.readOnly || variacionModalSaving}
								class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
							/>
						</label>
					</div>

										{#if variacionRangeHelperText}
						<p class="rounded-md border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-xs text-[color:var(--muted-foreground)]">
							{variacionRangeHelperText}
						</p>
					{/if}

					<label class="form-field">
						<span class="form-label">
							<span class="form-label-with-help">
								Observaciones
								<FieldHelpTooltip
									text="Este contenido se publica en la ficha pública de la obra."
									label="Visibilidad pública de observaciones de la variación"
								/>
							</span>
						</span>
						<MarkdownEditorLite
							rows={3}
							class="mt-1"
							minHeightClass="min-h-24"
							value={variacionForm.observaciones}
							disabled={props.readOnly || variacionModalSaving}
							onChange={(nextValue) => {
								variacionForm = {
									...variacionForm,
									observaciones: nextValue
								};
							}}
						/>
					</label>
				</div>
				<div class="mt-4 flex justify-end gap-2">
					<Button variant="secondary" onclick={closeVariacionModal}>Cancelar</Button>
					<Button
						variant="success"
						disabled={props.readOnly || variacionModalSaving}
						onclick={() => void saveVariacion()}
					>
						{variacionModalSaving ? 'Guardando...' : 'Guardar'}
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

	{#if variacionDeleteTargetId}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
			<div class="card w-full max-w-md p-5">
				<h3 class="text-lg font-semibold">Eliminar variación</h3>
				<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta acción no se puede deshacer.</p>
				<div class="mt-4 flex justify-end gap-2">
					<Button variant="secondary" onclick={closeVariacionDeleteModal}>Cancelar</Button>
					<Button
						variant="danger"
						disabled={props.readOnly}
						onclick={() => {
							if (!variacionDeleteTargetId) return;
							void removeVariacion(variacionDeleteTargetId);
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




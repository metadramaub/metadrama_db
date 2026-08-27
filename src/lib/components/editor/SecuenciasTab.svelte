<script lang="ts">
	import { browser } from '$app/environment';
	import { onDestroy, onMount, untrack } from 'svelte';
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
	import LocalDraftRecoveryModal from '$lib/components/editor/LocalDraftRecoveryModal.svelte';
	import RangeConsistencyAlert from '$lib/components/editor/RangeConsistencyAlert.svelte';
	import SequenceSynopsisModal from '$lib/components/editor/SequenceSynopsisModal.svelte';
	import UnsavedChangesModal from '$lib/components/editor/UnsavedChangesModal.svelte';
	import { buildSequenceSynopsisGroups } from '$lib/components/editor/sequence-synopsis';
	import { suggestNextSubtipoRange } from '$lib/components/editor/secuencia-subtipos';
	import { pushToast } from '$lib/stores/toast';
	import type { EditorCuadroRow, EditorJornadaRow, EditorSecuenciaRow } from '$lib/types/editor.types';
	import {
		buildLocalDraftKey,
		createLocalDraftWriter,
		readLocalDraft,
		removeLocalDraft,
		type LocalFormDraft
	} from '$lib/utils/local-form-draft';
	import { displayTerm } from '$lib/utils/vocabulario';
	import CaracterizacionesPorRango from './secuencias/CaracterizacionesPorRango.svelte';
	import {
		analyzeSequenceRangeConsistency,
		collectRangeConsistencyIds
	} from '$lib/utils/range-consistency';

	const props = $props<{
		obraId: string;
		draftOwnerId: string;
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
		onPendingChangesChange?: (pending: boolean) => void;
		// Señala que cambió algún dato que alimenta obras_resumen pero que NO altera
		// la lista de secuencias (caracterizaciones de rango, subtipos de estrofa).
		onMetricaDirty?: () => void;
	}>();

	type IntervencionValue = 'sin_intervencion' | 'exclusiva' | 'compartida';

	type FormState = {
		v_ini: number;
		v_fin: number;
		estrofa_tipo_id: string;
		inaugura_espacio: boolean | null;
		versos_partidos: boolean | null;
		evocacion_metrica: boolean | null;
		evocacion_metrica_texto: string;
		intervencion_personajes_femeninos: IntervencionValue | null;
		intervencion_figuras_donaire: IntervencionValue | null;
		intervencion_personajes_sobrenaturales: IntervencionValue | null;
		sinopsis: string;
	};

	type PendingSidebarAction =
		| { kind: 'close' }
		| { kind: 'new' }
		| { kind: 'sequence'; target: EditorSecuenciaRow };

	type DraftRecovery = {
		key: string;
		draft: LocalFormDraft<FormState>;
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

	let secuencias = $state(untrack(() => [...props.secuenciasInitial]));
	let sidebarOpen = $state(false);
	let editingId = $state<string | null>(null);
	let filtroEstrofa = $state('');
	let filtroEstrofaDraft = $state('');

	function aplicarFiltroEstrofa() {
		filtroEstrofa = filtroEstrofaDraft;
	}

	function limpiarFiltroEstrofa() {
		filtroEstrofaDraft = '';
		filtroEstrofa = '';
	}
	let deleteTargetId = $state<string | null>(null);
	let deletingSequence = $state(false);
	let sequenceSynopsisModalOpen = $state(false);
	let pendingSidebarAction = $state<PendingSidebarAction | null>(null);
	let draftRecovery = $state<DraftRecovery | null>(null);

	let sidebarSaving = $state(false);
	let sidebarDirty = $state(false);
	let sidebarBaselineSnapshot = $state('');
	let lastReportedPending = false;
	const localDraftWriter = createLocalDraftWriter();
	/** El componente de caracterizaciones, para recargarlo y cerrarlo desde aquí. */
	let caracterizaciones = $state<CaracterizacionesPorRango | null>(null);
	let subtipos = $state<SubtipoItem[]>([]);
	let subtiposLoading = $state(false);
	let subtiposRequestCounter = $state(0);
	let subtipoModalOpen = $state(false);
	let subtipoModalSaving = $state(false);
	let subtipoEditingId = $state<string | null>(null);
	let subtipoDeleteTargetId = $state<string | null>(null);
	let deletingSubtipo = $state(false);
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
	const estrofaDropdownItems = $derived.by(() =>
		estrofaSelectableOptions.map((option) => ({
			id: option.termino_id,
			label: displayTerm(option),
			parentId: option.termino_padre_id ?? null
		}))
	);
	const intervencionItems = [
		{ id: 'sin_intervencion', label: 'Sin intervención' },
		{ id: 'exclusiva', label: 'Intervención exclusiva' },
		{ id: 'compartida', label: 'Intervención compartida' }
	];
	const INTERVENCION_HELP =
		'Indica si en esta secuencia métrica interviene verbalmente un personaje de este tipo. El dato se refiere al habla dentro de la secuencia, no a la presencia escénica.';
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

	function initialForm(): FormState {
		const suggestedStart = getSuggestedSecuenciaStart();
		return {
			v_ini: suggestedStart,
			v_fin: suggestedStart + 1,
			estrofa_tipo_id: '',
			inaugura_espacio: null,
			versos_partidos: null,
			evocacion_metrica: null,
			evocacion_metrica_texto: '',
			intervencion_personajes_femeninos: null,
			intervencion_figuras_donaire: null,
			intervencion_personajes_sobrenaturales: null,
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
		if (!id) return 'Pendiente';
		const option = options.find((opt) => opt.termino_id === id);
		return option ? displayTerm(option) : 'Pendiente';
	}

	function sortSubtipos(items: SubtipoItem[]) {
		return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	}

	function subtipoLabelById(subtipoEstrofaId: string, fallback = '') {
		const fromVocabulary = displayTerm(subtipoById.get(subtipoEstrofaId));
		return fromVocabulary || fallback || '--';
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
			.filter((secuencia) => !filtroEstrofa || secuencia.estrofa_tipo_id === filtroEstrofa)
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
			evocacion_metrica: source.evocacion_metrica,
			evocacion_metrica_texto: source.evocacion_metrica ? source.evocacion_metrica_texto.trim() : '',
			intervencion_personajes_femeninos: source.intervencion_personajes_femeninos,
			intervencion_figuras_donaire: source.intervencion_figuras_donaire,
			intervencion_personajes_sobrenaturales: source.intervencion_personajes_sobrenaturales,
			sinopsis: source.sinopsis.trim()
		});
	}

	function localDraftKey(sourceEditingId: string | null = editingId): string {
		return buildLocalDraftKey([
			props.draftOwnerId,
			props.obraId,
			'secuencia',
			sourceEditingId ?? 'nueva'
		]);
	}

	function isFormState(value: unknown): value is FormState {
		if (!value || typeof value !== 'object') return false;
		const candidate = value as Partial<FormState>;
		const isIntervencionValue = (intervencion: unknown) =>
			intervencion === null ||
			['sin_intervencion', 'exclusiva', 'compartida'].includes(String(intervencion));
		return (
			Number.isFinite(Number(candidate.v_ini)) &&
			Number.isFinite(Number(candidate.v_fin)) &&
			typeof candidate.estrofa_tipo_id === 'string' &&
			(candidate.inaugura_espacio === null || typeof candidate.inaugura_espacio === 'boolean') &&
			(candidate.versos_partidos === null || typeof candidate.versos_partidos === 'boolean') &&
			(candidate.evocacion_metrica === null || typeof candidate.evocacion_metrica === 'boolean') &&
			typeof candidate.evocacion_metrica_texto === 'string' &&
			isIntervencionValue(candidate.intervencion_personajes_femeninos) &&
			isIntervencionValue(candidate.intervencion_figuras_donaire) &&
			isIntervencionValue(candidate.intervencion_personajes_sobrenaturales) &&
			typeof candidate.sinopsis === 'string'
		);
	}

	function prepareLocalDraftRecovery() {
		draftRecovery = null;
		if (!browser || props.readOnly) return;
		const key = localDraftKey();
		const draft = readLocalDraft<FormState>(key);
		if (!draft) return;
		if (!isFormState(draft.value)) {
			removeLocalDraft(key);
			return;
		}
		if (sidebarSnapshot(draft.value) === sidebarBaselineSnapshot) {
			removeLocalDraft(key);
			return;
		}
		draftRecovery = { key, draft };
	}

	function discardLocalDraft() {
		if (!draftRecovery) return;
		removeLocalDraft(draftRecovery.key);
		draftRecovery = null;
	}

	function restoreLocalDraft() {
		if (!draftRecovery) return;
		form = { ...draftRecovery.draft.value };
		draftRecovery = null;
		pushToast('info', 'Borrador local recuperado. Pulsa Guardar para enviarlo a Supabase.');
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
		subtipos = [];
		caracterizaciones?.cerrarModales();
		subtipoDeleteTargetId = null;
		subtipoModalOpen = false;
		sidebarOpen = true;
		pendingSidebarAction = null;
		setSidebarBaselineFromCurrent();
		prepareLocalDraftRecovery();
	}

	function openEdit(secuencia: EditorSecuenciaRow) {
		if (props.readOnly && !props.canComment) return;
		editingId = secuencia.secuencia_id;
		form = {
			v_ini: secuencia.v_ini,
			v_fin: secuencia.v_fin,
			estrofa_tipo_id: toSelectableEstrofaId(secuencia.estrofa_tipo_id),
			inaugura_espacio: secuencia.inaugura_espacio,
			versos_partidos: secuencia.versos_partidos,
			evocacion_metrica: secuencia.evocacion_metrica,
			evocacion_metrica_texto: secuencia.evocacion_metrica_texto ?? '',
			intervencion_personajes_femeninos: secuencia.intervencion_personajes_femeninos as IntervencionValue | null,
			intervencion_figuras_donaire: secuencia.intervencion_figuras_donaire as IntervencionValue | null,
			intervencion_personajes_sobrenaturales:
				secuencia.intervencion_personajes_sobrenaturales as IntervencionValue | null,
			sinopsis: secuencia.sinopsis ?? ''
		};
		subtipos = [];
		caracterizaciones?.cerrarModales();
		subtipoDeleteTargetId = null;
		subtipoModalOpen = false;
		sidebarOpen = true;
		pendingSidebarAction = null;
		setSidebarBaselineFromCurrent();
		prepareLocalDraftRecovery();
		void caracterizaciones?.recargar();
		void loadSubtiposForCurrentSecuencia();
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
		localDraftWriter.cancel();
		sidebarOpen = false;
		editingId = null;
		caracterizaciones?.cerrarModales();
		subtipos = [];
		subtiposLoading = false;
		subtiposRequestCounter += 1;
		subtipoModalOpen = false;
		subtipoEditingId = null;
		subtipoDeleteTargetId = null;
		sidebarDirty = false;
		sidebarBaselineSnapshot = '';
		pendingSidebarAction = null;
		draftRecovery = null;
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
		localDraftWriter.cancel();
		removeLocalDraft(localDraftKey());
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
		const submittedDraftKey = localDraftKey(currentId);
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
					estrofa_tipo_id: form.estrofa_tipo_id || null,
					evocacion_metrica_texto: form.evocacion_metrica ? form.evocacion_metrica_texto : null
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
			void caracterizaciones?.recargar();
			void loadSubtiposForCurrentSecuencia();
		}

		form = {
			v_ini: savedSecuencia.v_ini,
			v_fin: savedSecuencia.v_fin,
			estrofa_tipo_id: toSelectableEstrofaId(savedSecuencia.estrofa_tipo_id),
			inaugura_espacio: savedSecuencia.inaugura_espacio,
			versos_partidos: savedSecuencia.versos_partidos,
			evocacion_metrica: savedSecuencia.evocacion_metrica,
			evocacion_metrica_texto: savedSecuencia.evocacion_metrica_texto ?? '',
			intervencion_personajes_femeninos:
				savedSecuencia.intervencion_personajes_femeninos as IntervencionValue | null,
			intervencion_figuras_donaire:
				savedSecuencia.intervencion_figuras_donaire as IntervencionValue | null,
			intervencion_personajes_sobrenaturales:
				savedSecuencia.intervencion_personajes_sobrenaturales as IntervencionValue | null,
			sinopsis: savedSecuencia.sinopsis ?? ''
		};

		localDraftWriter.cancel();
		removeLocalDraft(submittedDraftKey);
		setSidebarBaselineFromCurrent();
		pushToast('success', currentId ? 'Secuencia actualizada' : 'Secuencia creada');
		if (
			!currentId &&
			filtroEstrofa &&
			savedSecuencia.estrofa_tipo_id !== filtroEstrofa
		) {
			pushToast('info', 'Secuencia creada. Está oculta por los filtros actuales.');
		}
		sidebarSaving = false;
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
		props.onMetricaDirty?.();
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
		if (props.readOnly || !editingId || deletingSubtipo) return;
		deletingSubtipo = true;
		try {
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
			props.onMetricaDirty?.();
			pushToast('success', 'Subtipo eliminado');
		} catch {
			pushToast('error', 'No se pudo conectar con el servidor para eliminar el subtipo');
		} finally {
			deletingSubtipo = false;
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
		const track = `${form.v_ini}|${form.v_fin}|${form.estrofa_tipo_id}|${form.inaugura_espacio}|${form.versos_partidos}|${form.evocacion_metrica}|${form.evocacion_metrica_texto}|${form.intervencion_personajes_femeninos}|${form.intervencion_figuras_donaire}|${form.intervencion_personajes_sobrenaturales}|${form.sinopsis}|${editingId}`;
		void track;

		if (!open || readOnly) {
			sidebarDirty = false;
			localDraftWriter.cancel();
			reportPendingChanges(false);
			return;
		}

		const currentSnapshot = sidebarSnapshot();
		sidebarDirty = currentSnapshot !== sidebarBaselineSnapshot;
		reportPendingChanges(sidebarDirty);
		if (draftRecovery) {
			localDraftWriter.cancel();
			return;
		}
		if (!sidebarDirty) {
			localDraftWriter.cancel();
			removeLocalDraft(localDraftKey());
			return;
		}
		localDraftWriter.schedule(localDraftKey(), { ...form });
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
		localDraftWriter.flush();
		props.onPendingChangesChange?.(false);
	});

	onMount(() => {
		const flushLocalDraft = () => localDraftWriter.flush();
		window.addEventListener('pagehide', flushLocalDraft);
		return () => window.removeEventListener('pagehide', flushLocalDraft);
	});
</script>

<section class="space-y-4">
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
					placeholder="Filtrar por estrofa"
					items={estrofaDropdownItems}
					selectedIds={filtroEstrofaDraft ? [filtroEstrofaDraft] : []}
					onChange={(ids) => {
						filtroEstrofaDraft = ids[0] ?? '';
					}}
				/>
			</div>
			<Button variant="secondary" onclick={aplicarFiltroEstrofa}>Filtrar</Button>
			<Button
				variant="ghost"
				onclick={limpiarFiltroEstrofa}
				disabled={!filtroEstrofa && !filtroEstrofaDraft}
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
							<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">Estrofa</th>
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
									<td class="px-3 py-2">{termById(props.estrofaOptions, secuencia.estrofa_tipo_id)}</td>
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
	<aside
		class="fixed right-0 top-0 z-40 h-screen w-full max-w-xl overflow-y-auto border-l border-[color:var(--border)] bg-[color:var(--gray-50)] px-5 pb-5 pt-0"
		inert={sidebarSaving}
		aria-busy={sidebarSaving}
	>
		<div class="sticky top-0 z-20 -mx-5 mb-4 flex items-center justify-between gap-3 border-b border-[color:var(--border)] bg-[color:var(--gray-50)] px-5 pb-3 pt-5">
			<div class="flex min-w-0 items-center gap-2">
				<h3 class="text-base font-semibold">
					{#if editingId}
						{props.readOnly ? 'Ver secuencia' : 'Editar secuencia'}
					{:else}
						Nueva secuencia
					{/if}
				</h3>
				{#if editingId && editingIndex >= 0}
					<div class="flex items-center gap-1">
						<button
							type="button"
							class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
							aria-label="Secuencia anterior"
							onclick={() => void goToSecuencia(prevSecuencia)}
							disabled={!prevSecuencia || sidebarSaving}
						>
							<ChevronLeft size={18} />
						</button>
						<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
							{editingIndex + 1} / {orderedSecuencias.length}
						</span>
						<button
							type="button"
							class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
							aria-label="Secuencia siguiente"
							onclick={() => void goToSecuencia(nextSecuencia)}
							disabled={!nextSecuencia || sidebarSaving}
						>
							<ChevronRight size={18} />
						</button>
					</div>
				{/if}
			</div>
			<div class="flex items-center gap-2">
				{#if sidebarDirty}
					<span class="text-xs text-[color:var(--muted-foreground)]">Cambios sin guardar</span>
				{/if}
				<Button variant="secondary" onclick={requestCloseSidebar} disabled={sidebarSaving}>Cerrar</Button>
				{#if !props.readOnly}
					<Button
						variant="success"
						onclick={() => void save()}
						loading={sidebarSaving}
						loadingLabel="Guardando…"
					>
						Guardar
					</Button>
				{/if}
			</div>
		</div>

		<div class="space-y-3">
			<section class="bg-white p-4">
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
					<span class="form-label">Estrofa</span>
					<CheckDropdown
						class="mt-1"
						multiple={false}
						hierarchical={true}
						collapsibleHierarchy={true}
						disableParentsWithChildren={true}
						showPathInTrigger={true}
						allowSingleClear
						search={true}
						placeholder="Pendiente — seleccionar"
						items={estrofaDropdownItems}
						selectedIds={form.estrofa_tipo_id ? [form.estrofa_tipo_id] : []}
						disabled={props.readOnly}
						onChange={(ids) => {
							const nextId = ids[0] ?? '';
							form = {
								...form,
								estrofa_tipo_id: nextId
							};
						}}
					/>
				</label>
			</section>

			{#if isSubtipoEnabledForCurrentEstrofa}
			<section class="bg-white p-4">
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
					<div class="mt-3 overflow-x-auto">
						<table class="min-w-full text-left text-xs">
							<thead class="bg-[color:var(--muted)]">
								<tr>
									<th class="px-2 py-2">Subtipo</th>
									<th class="px-2 py-2">V_ini</th>
									<th class="px-2 py-2">V_fin</th>
									<th class="w-16 px-2 py-2"><span class="sr-only">Acciones</span></th>
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
											<div class="flex items-center justify-end gap-1">
												<button
													type="button"
													class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--success)] disabled:opacity-40"
													aria-label="Editar subtipo"
													onclick={() => openSubtipoEditModal(subtipo)}
													disabled={props.readOnly}
												>
													<Pencil size={15} />
												</button>
												<button
													type="button"
													class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--danger)] disabled:opacity-40"
													aria-label="Eliminar subtipo"
													onclick={() => openSubtipoDeleteModal(subtipo.subtipo_secuencia_id)}
													disabled={props.readOnly}
												>
													<Trash2 size={15} />
												</button>
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

			<CaracterizacionesPorRango
				bind:this={caracterizaciones}
				obraId={props.obraId}
				secuenciaId={editingId}
				rango={{ v_ini: Number(form.v_ini) || 1, v_fin: Number(form.v_fin) || 1 }}
				opciones={props.caracterizacionRangoOptions}
				readOnly={props.readOnly}
				onMetricaDirty={props.onMetricaDirty}
			/>

			<section class="bg-white p-4">
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
							allowSingleClear
							placeholder="Pendiente — seleccionar"
							items={intervencionItems}
							disabled={props.readOnly}
							selectedIds={form.intervencion_personajes_femeninos
								? [form.intervencion_personajes_femeninos]
								: []}
							onChange={(ids) => {
								const nextPersonajeFemenino = ids[0] as IntervencionValue | undefined;
								form = {
									...form,
									intervencion_personajes_femeninos: nextPersonajeFemenino ?? null
								};
							}}
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Figuras de donaire</span>
						<CheckDropdown
							multiple={false}
							search={false}
							allowSingleClear
							placeholder="Pendiente — seleccionar"
							items={intervencionItems}
							disabled={props.readOnly}
							selectedIds={form.intervencion_figuras_donaire
								? [form.intervencion_figuras_donaire]
								: []}
							onChange={(ids) => {
								const nextDonaire = ids[0] as IntervencionValue | undefined;
								form = {
									...form,
									intervencion_figuras_donaire: nextDonaire ?? null
								};
							}}
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Personajes sobrenaturales</span>
						<CheckDropdown
							multiple={false}
							search={false}
							allowSingleClear
							placeholder="Pendiente — seleccionar"
							items={intervencionItems}
							disabled={props.readOnly}
							selectedIds={form.intervencion_personajes_sobrenaturales
								? [form.intervencion_personajes_sobrenaturales]
								: []}
							onChange={(ids) => {
								const nextSobrenatural = ids[0] as IntervencionValue | undefined;
								form = {
									...form,
									intervencion_personajes_sobrenaturales: nextSobrenatural ?? null
								};
							}}
						/>
					</label>
				</div>
			</section>

			<section class="bg-white p-4">
				<h4 class="form-section-title">Otras caracterizaciones</h4>
				<div class="grid gap-3 sm:grid-cols-2">
					<div class="grid grid-cols-2 gap-3 sm:col-span-2">
						<div class="form-field min-w-0">
							<span class="form-label">
								<span class="form-label-with-help">
									Versos partidos
									<FieldHelpTooltip
										text="Selecciona 'Sí' si en esta secuencia hay versos repartidos entre intervenciones de distintos personajes."
										label="Ayuda sobre el campo Versos partidos"
									/>
								</span>
							</span>
							<NullableBooleanChoice
								value={form.versos_partidos}
								ariaLabel="Versos partidos"
								disabled={props.readOnly}
								onChange={(value) => {
									form = {
										...form,
										versos_partidos: value
									};
								}}
							/>
						</div>

						<div class="form-field min-w-0">
							<span class="form-label">
								<span class="form-label-with-help">
									Inaugura espacio
									<FieldHelpTooltip
										text="Selecciona 'Sí' si coincide (de forma evidente) el inicio de esta secuencia con el cambio de espacio escénico."
										label="Ayuda sobre el campo Inaugura espacio"
									/>
								</span>
							</span>
							<NullableBooleanChoice
								value={form.inaugura_espacio}
								ariaLabel="Inaugura espacio"
								disabled={props.readOnly}
								onChange={(value) => {
									form = {
										...form,
										inaugura_espacio: value
									};
								}}
							/>
						</div>
					</div>
					<div class="form-field sm:col-span-2">
						<span class="form-label">
							<span class="form-label-with-help">
								Evocación métrica
								<FieldHelpTooltip
									text="Selecciona 'Sí' cuando el cambio de metro se deba a que un personaje adopta, imita o reproduce la voz de otro personaje."
									label="Ayuda sobre el campo Evocación métrica"
								/>
							</span>
						</span>
						<NullableBooleanChoice
							value={form.evocacion_metrica}
							ariaLabel="Evocación métrica"
							disabled={props.readOnly}
							onChange={(value) => {
								form = {
									...form,
									evocacion_metrica: value,
									evocacion_metrica_texto: value === true ? form.evocacion_metrica_texto : ''
								};
							}}
						/>
					</div>
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

			<section class="bg-white p-4">
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
						reloadKey={props.commentsReloadKey}
					/>
				{/key}
			</div>
		{/if}
	</aside>
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
						disabled={props.readOnly}
						loading={subtipoModalSaving}
						loadingLabel="Guardando…"
						onclick={() => void saveSubtipo()}
					>
						Guardar
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
					<Button variant="secondary" onclick={closeSubtipoDeleteModal} disabled={deletingSubtipo}>
						Cancelar
					</Button>
					<Button
						variant="danger"
						disabled={props.readOnly}
						loading={deletingSubtipo}
						loadingLabel="Eliminando…"
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

<LocalDraftRecoveryModal
	open={Boolean(draftRecovery)}
	savedAt={draftRecovery?.draft.savedAt}
	onDiscard={discardLocalDraft}
	onRestore={restoreLocalDraft}
/>




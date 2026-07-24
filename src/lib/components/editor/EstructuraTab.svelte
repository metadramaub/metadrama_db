<script lang="ts">
	import { browser } from '$app/environment';
	import { onDestroy, onMount, untrack } from 'svelte';
	import { ChevronLeft, ChevronRight, Eye, Pencil, Plus, Trash2 } from 'lucide-svelte';
	import type { EditorCuadroRow, EditorJornadaRow } from '$lib/types/editor.types';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import LocalDraftRecoveryModal from '$lib/components/editor/LocalDraftRecoveryModal.svelte';
	import UnsavedChangesModal from '$lib/components/editor/UnsavedChangesModal.svelte';
	import { pushToast } from '$lib/stores/toast';
	import {
		buildLocalDraftKey,
		createLocalDraftWriter,
		readLocalDraft,
		removeLocalDraft,
		type LocalFormDraft
	} from '$lib/utils/local-form-draft';

	const props = $props<{
		obraId: string;
		draftOwnerId: string;
		jornadasInitial: EditorJornadaRow[];
		cuadrosInitial: EditorCuadroRow[];
		readOnly?: boolean;
		canComment?: boolean;
		focusJornadaId?: string | null;
		focusCuadroId?: string | null;
		focusComentarioId?: string | null;
		commentsReloadKey?: string | number | null;
		onStructureChange?: (payload: {
			jornadas: EditorJornadaRow[];
			cuadros: EditorCuadroRow[];
		}) => void;
		onPendingChangesChange?: (pending: boolean) => void;
	}>();

	let jornadas = $state(untrack(() => [...props.jornadasInitial]));
	let cuadros = $state(untrack(() => [...props.cuadrosInitial]));

	type SidebarMode = 'jornada-new' | 'jornada-edit' | 'cuadro-new' | 'cuadro-edit' | null;
	type ActiveSidebarMode = Exclude<SidebarMode, null>;
	type JornadaFormState = {
		jornada_num: number;
		v_ini: number;
		v_fin: number;
	};
	type CuadroFormState = {
		jornada_id: string;
		cuadro_num: number;
		v_ini: number;
		v_fin: number;
	};
	type StructureDraftValue = {
		mode: ActiveSidebarMode;
		jornadaForm: JornadaFormState;
		cuadroForm: CuadroFormState;
	};
	type DraftRecovery = {
		key: string;
		draft: LocalFormDraft<StructureDraftValue>;
	};
	type PendingSidebarAction =
		| { kind: 'close' }
		| { kind: 'new-jornada' }
		| { kind: 'new-cuadro'; jornada: EditorJornadaRow }
		| { kind: 'jornada'; target: EditorJornadaRow }
		| { kind: 'cuadro'; target: EditorCuadroRow };
	type DeleteTarget = {
		kind: 'jornada' | 'cuadro';
		id: string;
		title: string;
		description: string;
	};

	let sidebarMode = $state<SidebarMode>(null);
	let editingJornadaId = $state<string | null>(null);
	let editingCuadroId = $state<string | null>(null);
	let deleteTarget = $state<DeleteTarget | null>(null);
	let deletingStructure = $state(false);
	let pendingSidebarAction = $state<PendingSidebarAction | null>(null);
	let draftRecovery = $state<DraftRecovery | null>(null);

	let sidebarSaving = $state(false);
	let sidebarDirty = $state(false);
	let sidebarBaselineSnapshot = $state('');
	let lastReportedPending = false;
	const localDraftWriter = createLocalDraftWriter();
	let handledFocusTarget = $state<string | null>(null);

	let jornadaForm = $state<JornadaFormState>({
		jornada_num: untrack(() => props.jornadasInitial.length + 1),
		v_ini: 1,
		v_fin: 2
	});

	let cuadroForm = $state<CuadroFormState>({
		jornada_id: untrack(() => props.jornadasInitial[0]?.jornada_id ?? ''),
		cuadro_num: 1,
		v_ini: untrack(() => props.jornadasInitial[0]?.v_ini ?? 1),
		v_fin: untrack(() => props.jornadasInitial[0]?.v_fin ?? 2)
	});

	function sortByVIni<T extends { v_ini: number }>(items: T[]): T[] {
		return [...items].sort((a, b) => a.v_ini - b.v_ini);
	}
	const orderedJornadas = $derived(sortByVIni(jornadas));
	const orderedCuadros = $derived(sortByVIni(cuadros));
	const editingJornadaIndex = $derived(
		editingJornadaId ? orderedJornadas.findIndex((item) => item.jornada_id === editingJornadaId) : -1
	);
	const editingCuadroIndex = $derived(
		editingCuadroId ? orderedCuadros.findIndex((item) => item.cuadro_id === editingCuadroId) : -1
	);
	const prevJornada = $derived(
		editingJornadaIndex > 0 ? orderedJornadas[editingJornadaIndex - 1] : null
	);
	const nextJornada = $derived(
		editingJornadaIndex >= 0 && editingJornadaIndex < orderedJornadas.length - 1
			? orderedJornadas[editingJornadaIndex + 1]
			: null
	);
	const prevCuadro = $derived(editingCuadroIndex > 0 ? orderedCuadros[editingCuadroIndex - 1] : null);
	const nextCuadro = $derived(
		editingCuadroIndex >= 0 && editingCuadroIndex < orderedCuadros.length - 1
			? orderedCuadros[editingCuadroIndex + 1]
			: null
	);
	const jornadaDropdownItems = $derived(
		sortByVIni(jornadas).map((jornada) => ({
			id: jornada.jornada_id,
			label: `Jornada ${jornada.jornada_num} (vv. ${jornada.v_ini}-${jornada.v_fin})`
		}))
	);
	function getJornadaById(jornadaId: string) {
		return jornadas.find((item) => item.jornada_id === jornadaId) ?? null;
	}

	function getCuadroById(cuadroId: string) {
		return cuadros.find((item) => item.cuadro_id === cuadroId) ?? null;
	}

	function getCuadros(jornadaId: string) {
		return sortByVIni(cuadros.filter((item) => item.jornada_id === jornadaId));
	}

	function getSuggestedJornadaStart(): number {
		const maxVFin = jornadas.reduce((max, item) => Math.max(max, Number(item.v_fin) || 0), 0);
		return maxVFin > 0 ? maxVFin + 1 : 1;
	}

	function getSuggestedCuadroStart(jornadaId: string): number {
		const jornada = getJornadaById(jornadaId);
		if (!jornada) return 1;
		const maxVFin = cuadros
			.filter((item) => item.jornada_id === jornadaId)
			.reduce((max, item) => Math.max(max, Number(item.v_fin) || 0), 0);
		return maxVFin > 0 ? maxVFin + 1 : jornada.v_ini;
	}

	function emitStructureChange() {
		props.onStructureChange?.({
			jornadas: [...jornadas],
			cuadros: [...cuadros]
		});
	}

	function resetJornadaForm() {
		const suggestedStart = getSuggestedJornadaStart();
		jornadaForm = {
			jornada_num: jornadas.length + 1,
			v_ini: suggestedStart,
			v_fin: suggestedStart + 1
		};
	}

	function resetCuadroForm(jornadaId?: string) {
		const selectedJornadaId = jornadaId ?? jornadas[0]?.jornada_id ?? '';
		const suggestedStart = getSuggestedCuadroStart(selectedJornadaId);
		cuadroForm = {
			jornada_id: selectedJornadaId,
			cuadro_num: selectedJornadaId ? getCuadros(selectedJornadaId).length + 1 : 1,
			v_ini: suggestedStart,
			v_fin: suggestedStart + 1
		};
	}

	function onCuadroJornadaChange(nextJornadaId: string) {
		const nextJornada = getJornadaById(nextJornadaId);
		const inCreationMode = sidebarMode === 'cuadro-new';
		const suggestedStart = inCreationMode ? getSuggestedCuadroStart(nextJornadaId) : cuadroForm.v_ini;
		cuadroForm = {
			...cuadroForm,
			jornada_id: nextJornadaId,
			cuadro_num: nextJornadaId ? getCuadros(nextJornadaId).length + 1 : 1,
			v_ini: inCreationMode ? suggestedStart : nextJornada?.v_ini ?? cuadroForm.v_ini,
			v_fin: inCreationMode ? suggestedStart + 1 : nextJornada?.v_fin ?? cuadroForm.v_fin
		};
	}

	function sidebarSnapshot(): string {
		if (sidebarMode === 'jornada-new' || sidebarMode === 'jornada-edit') {
			return JSON.stringify({
				mode: sidebarMode,
				id: editingJornadaId,
				jornada_num: Number(jornadaForm.jornada_num),
				v_ini: Number(jornadaForm.v_ini),
				v_fin: Number(jornadaForm.v_fin)
			});
		}
		if (sidebarMode === 'cuadro-new' || sidebarMode === 'cuadro-edit') {
			return JSON.stringify({
				mode: sidebarMode,
				id: editingCuadroId,
				jornada_id: cuadroForm.jornada_id,
				cuadro_num: Number(cuadroForm.cuadro_num),
				v_ini: Number(cuadroForm.v_ini),
				v_fin: Number(cuadroForm.v_fin)
			});
		}
		return '';
	}

	function localDraftKey(): string {
		let target = 'cerrado';
		if (sidebarMode === 'jornada-new') target = 'jornada:nueva';
		if (sidebarMode === 'jornada-edit') target = `jornada:${editingJornadaId ?? 'desconocida'}`;
		if (sidebarMode === 'cuadro-new') target = 'cuadro:nuevo';
		if (sidebarMode === 'cuadro-edit') target = `cuadro:${editingCuadroId ?? 'desconocido'}`;
		return buildLocalDraftKey([props.draftOwnerId, props.obraId, 'estructura', target]);
	}

	function currentDraftValue(): StructureDraftValue | null {
		if (!sidebarMode) return null;
		return {
			mode: sidebarMode,
			jornadaForm: { ...jornadaForm },
			cuadroForm: { ...cuadroForm }
		};
	}

	function isStructureDraftValue(value: unknown): value is StructureDraftValue {
		if (!value || typeof value !== 'object') return false;
		const candidate = value as Partial<StructureDraftValue>;
		const jornada = candidate.jornadaForm;
		const cuadro = candidate.cuadroForm;
		return (
			['jornada-new', 'jornada-edit', 'cuadro-new', 'cuadro-edit'].includes(candidate.mode ?? '') &&
			Boolean(jornada) &&
			Number.isFinite(Number(jornada?.jornada_num)) &&
			Number.isFinite(Number(jornada?.v_ini)) &&
			Number.isFinite(Number(jornada?.v_fin)) &&
			Boolean(cuadro) &&
			typeof cuadro?.jornada_id === 'string' &&
			Number.isFinite(Number(cuadro?.cuadro_num)) &&
			Number.isFinite(Number(cuadro?.v_ini)) &&
			Number.isFinite(Number(cuadro?.v_fin))
		);
	}

	function prepareLocalDraftRecovery() {
		draftRecovery = null;
		if (!browser || props.readOnly || !sidebarMode) return;
		const key = localDraftKey();
		const draft = readLocalDraft<StructureDraftValue>(key);
		if (!draft) return;
		if (!isStructureDraftValue(draft.value) || draft.value.mode !== sidebarMode) {
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
		jornadaForm = { ...draftRecovery.draft.value.jornadaForm };
		cuadroForm = { ...draftRecovery.draft.value.cuadroForm };
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
		if (!sidebarMode) {
			sidebarDirty = false;
			return false;
		}
		const current = sidebarSnapshot();
		sidebarDirty = current !== sidebarBaselineSnapshot;
		return sidebarDirty;
	}

	function parseJornadaPayload() {
		return {
			jornada_num: Number(jornadaForm.jornada_num),
			v_ini: Number(jornadaForm.v_ini),
			v_fin: Number(jornadaForm.v_fin)
		};
	}

	function parseCuadroPayload() {
		return {
			jornada_id: cuadroForm.jornada_id,
			cuadro_num: Number(cuadroForm.cuadro_num),
			v_ini: Number(cuadroForm.v_ini),
			v_fin: Number(cuadroForm.v_fin)
		};
	}

	function validateJornadaForm(showToast = true) {
		const payload = parseJornadaPayload();
		if (!Number.isFinite(payload.jornada_num) || payload.jornada_num < 1) {
			if (showToast) pushToast('error', 'Jornada inválida');
			return false;
		}
		if (!Number.isFinite(payload.v_ini) || !Number.isFinite(payload.v_fin) || payload.v_ini >= payload.v_fin) {
			if (showToast) pushToast('error', 'Rango de versos inválido');
			return false;
		}
		return true;
	}

	function validateCuadroForm(showToast = true) {
		const payload = parseCuadroPayload();
		if (!payload.jornada_id) {
			if (showToast) pushToast('error', 'Selecciona una jornada');
			return false;
		}
		if (!Number.isFinite(payload.cuadro_num) || payload.cuadro_num < 1) {
			if (showToast) pushToast('error', 'Cuadro inválido');
			return false;
		}
		if (!Number.isFinite(payload.v_ini) || !Number.isFinite(payload.v_fin) || payload.v_ini >= payload.v_fin) {
			if (showToast) pushToast('error', 'Rango de versos inválido');
			return false;
		}
		return true;
	}

	function isSidebarFormValid(showToast = true) {
		if (sidebarMode === 'jornada-new' || sidebarMode === 'jornada-edit') {
			return validateJornadaForm(showToast);
		}
		if (sidebarMode === 'cuadro-new' || sidebarMode === 'cuadro-edit') {
			return validateCuadroForm(showToast);
		}
		return false;
	}

	async function persistJornada() {
		const payload = parseJornadaPayload();
		const wasEditing = Boolean(editingJornadaId);
		const endpoint = editingJornadaId
			? `/api/obras/${props.obraId}/estructura/jornadas/${editingJornadaId}`
			: `/api/obras/${props.obraId}/estructura/jornadas`;
		const method = editingJornadaId ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload)
		});

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message = body.message ?? 'No se pudo guardar la jornada';
			pushToast('error', message);
			return false;
		}

		const result = await response.json();
		const savedJornada = result.jornada as EditorJornadaRow;

		if (wasEditing && editingJornadaId) {
			jornadas = sortByVIni(
				jornadas.map((item) => (item.jornada_id === editingJornadaId ? savedJornada : item))
			);
		} else {
			jornadas = sortByVIni([...jornadas, savedJornada]);
			editingJornadaId = savedJornada.jornada_id;
			sidebarMode = 'jornada-edit';
		}

		jornadaForm = {
			jornada_num: savedJornada.jornada_num,
			v_ini: savedJornada.v_ini,
			v_fin: savedJornada.v_fin
		};

		emitStructureChange();
		pushToast('success', wasEditing ? 'Jornada actualizada' : 'Jornada creada');
		return true;
	}

	async function persistCuadro() {
		const payload = parseCuadroPayload();
		const wasEditing = Boolean(editingCuadroId);
		const endpoint = editingCuadroId
			? `/api/obras/${props.obraId}/estructura/cuadros/${editingCuadroId}`
			: `/api/obras/${props.obraId}/estructura/cuadros`;
		const method = editingCuadroId ? 'PATCH' : 'POST';

		const response = await fetch(endpoint, {
			method,
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload)
		});

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message = body.message ?? 'No se pudo guardar el cuadro';
			pushToast('error', message);
			return false;
		}

		const result = await response.json();
		const savedCuadro = result.cuadro as EditorCuadroRow;

		if (wasEditing && editingCuadroId) {
			cuadros = sortByVIni(
				cuadros.map((item) => (item.cuadro_id === editingCuadroId ? savedCuadro : item))
			);
		} else {
			cuadros = sortByVIni([...cuadros, savedCuadro]);
			editingCuadroId = savedCuadro.cuadro_id;
			sidebarMode = 'cuadro-edit';
		}

		cuadroForm = {
			jornada_id: savedCuadro.jornada_id,
			cuadro_num: savedCuadro.cuadro_num,
			v_ini: savedCuadro.v_ini,
			v_fin: savedCuadro.v_fin
		};

		emitStructureChange();
		pushToast('success', wasEditing ? 'Cuadro actualizado' : 'Cuadro creado');
		return true;
	}

	async function saveSidebar(): Promise<boolean> {
		if (props.readOnly || sidebarSaving || !sidebarMode) return false;
		if (!isSidebarFormValid(true)) return false;

		sidebarSaving = true;
		const submittedDraftKey = localDraftKey();
		let ok = false;
		try {
			ok =
				sidebarMode === 'jornada-new' || sidebarMode === 'jornada-edit'
					? await persistJornada()
					: await persistCuadro();
		} catch {
			pushToast('error', 'No se pudo conectar con el servidor. Los cambios siguen sin guardar.');
			return false;
		} finally {
			sidebarSaving = false;
		}

		if (!ok) return false;
		localDraftWriter.cancel();
		removeLocalDraft(submittedDraftKey);
		setSidebarBaselineFromCurrent();
		return true;
	}

	function openNewJornada() {
		if (props.readOnly) return;
		editingJornadaId = null;
		editingCuadroId = null;
		resetJornadaForm();
		sidebarMode = 'jornada-new';
		setSidebarBaselineFromCurrent();
		pendingSidebarAction = null;
		prepareLocalDraftRecovery();
	}

	function openEditJornada(jornada: EditorJornadaRow) {
		if (props.readOnly && !props.canComment) return;
		editingJornadaId = jornada.jornada_id;
		editingCuadroId = null;
		jornadaForm = {
			jornada_num: jornada.jornada_num,
			v_ini: jornada.v_ini,
			v_fin: jornada.v_fin
		};
		sidebarMode = 'jornada-edit';
		setSidebarBaselineFromCurrent();
		pendingSidebarAction = null;
		prepareLocalDraftRecovery();
	}

	function openNewCuadro(jornada: EditorJornadaRow) {
		if (props.readOnly) return;
		editingJornadaId = null;
		editingCuadroId = null;
		resetCuadroForm(jornada.jornada_id);
		sidebarMode = 'cuadro-new';
		setSidebarBaselineFromCurrent();
		pendingSidebarAction = null;
		prepareLocalDraftRecovery();
	}

	function openEditCuadro(cuadro: EditorCuadroRow) {
		if (props.readOnly && !props.canComment) return;
		editingJornadaId = null;
		editingCuadroId = cuadro.cuadro_id;
		cuadroForm = {
			jornada_id: cuadro.jornada_id,
			cuadro_num: cuadro.cuadro_num,
			v_ini: cuadro.v_ini,
			v_fin: cuadro.v_fin
		};
		sidebarMode = 'cuadro-edit';
		setSidebarBaselineFromCurrent();
		pendingSidebarAction = null;
		prepareLocalDraftRecovery();
	}

	function requestOpenNewJornada() {
		if (props.readOnly || sidebarSaving) return;
		if (sidebarMode && refreshSidebarDirty()) {
			pendingSidebarAction = { kind: 'new-jornada' };
			return;
		}
		openNewJornada();
	}

	function requestOpenNewCuadro(jornada: EditorJornadaRow) {
		if (props.readOnly || sidebarSaving) return;
		if (sidebarMode && refreshSidebarDirty()) {
			pendingSidebarAction = { kind: 'new-cuadro', jornada };
			return;
		}
		openNewCuadro(jornada);
	}

	function requestOpenEditJornada(jornada: EditorJornadaRow) {
		if (sidebarSaving) return;
		if (sidebarMode === 'jornada-edit' && editingJornadaId === jornada.jornada_id) return;
		if (!props.readOnly && sidebarMode && refreshSidebarDirty()) {
			pendingSidebarAction = { kind: 'jornada', target: jornada };
			return;
		}
		openEditJornada(jornada);
	}

	function requestOpenEditCuadro(cuadro: EditorCuadroRow) {
		if (sidebarSaving) return;
		if (sidebarMode === 'cuadro-edit' && editingCuadroId === cuadro.cuadro_id) return;
		if (!props.readOnly && sidebarMode && refreshSidebarDirty()) {
			pendingSidebarAction = { kind: 'cuadro', target: cuadro };
			return;
		}
		openEditCuadro(cuadro);
	}

	function goToJornada(target: EditorJornadaRow | null) {
		if (!target || sidebarSaving) return;
		requestOpenEditJornada(target);
	}

	function goToCuadro(target: EditorCuadroRow | null) {
		if (!target || sidebarSaving) return;
		requestOpenEditCuadro(target);
	}

	function clearFocusStructureQueryParams() {
		if (!browser) return;
		const currentUrl = new URL(window.location.href);
		if (
			!currentUrl.searchParams.has('focusJornadaId') &&
			!currentUrl.searchParams.has('focusCuadroId')
		) {
			return;
		}
		currentUrl.searchParams.delete('focusJornadaId');
		currentUrl.searchParams.delete('focusCuadroId');
		window.history.replaceState(window.history.state, '', currentUrl.toString());
	}

	function performCloseSidebar() {
		localDraftWriter.cancel();
		sidebarMode = null;
		editingJornadaId = null;
		editingCuadroId = null;
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
		if (action.kind === 'new-jornada') {
			openNewJornada();
			return;
		}
		if (action.kind === 'new-cuadro') {
			openNewCuadro(action.jornada);
			return;
		}
		if (action.kind === 'jornada') {
			openEditJornada(action.target);
			return;
		}
		openEditCuadro(action.target);
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
		const saved = await saveSidebar();
		if (!saved) return;
		pendingSidebarAction = null;
		executeSidebarAction(action);
	}

	function openDeleteJornada(jornada: EditorJornadaRow) {
		if (props.readOnly) return;
		deleteTarget = {
			kind: 'jornada',
			id: jornada.jornada_id,
			title: `Eliminar Jornada ${jornada.jornada_num}`,
			description: 'Se eliminarán también los cuadros asociados.'
		};
	}

	function openDeleteCuadro(cuadro: EditorCuadroRow) {
		if (props.readOnly) return;
		deleteTarget = {
			kind: 'cuadro',
			id: cuadro.cuadro_id,
			title: `Eliminar Cuadro ${cuadro.cuadro_num}`,
			description: 'Esta acción no se puede deshacer.'
		};
	}

	async function confirmDelete() {
		if (props.readOnly || !deleteTarget || deletingStructure) return;
		const target = deleteTarget;
		deletingStructure = true;

		try {
			if (target.kind === 'jornada') {
				const response = await fetch(`/api/obras/${props.obraId}/estructura/jornadas/${target.id}`, {
					method: 'DELETE'
				});
				if (!response.ok) {
					const body = await response.json().catch(() => ({}));
					pushToast('error', body.message ?? 'No se pudo eliminar la jornada');
					return;
				}
				jornadas = jornadas.filter((item) => item.jornada_id !== target.id);
				cuadros = cuadros.filter((item) => item.jornada_id !== target.id);
				if (editingJornadaId === target.id) {
					performCloseSidebar();
				}
				pushToast('success', 'Jornada eliminada');
			} else {
				const response = await fetch(`/api/obras/${props.obraId}/estructura/cuadros/${target.id}`, {
					method: 'DELETE'
				});
				if (!response.ok) {
					const body = await response.json().catch(() => ({}));
					pushToast('error', body.message ?? 'No se pudo eliminar el cuadro');
					return;
				}
				cuadros = cuadros.filter((item) => item.cuadro_id !== target.id);
				if (editingCuadroId === target.id) {
					performCloseSidebar();
				}
				pushToast('success', 'Cuadro eliminado');
			}

			deleteTarget = null;
			emitStructureChange();
		} catch {
			pushToast(
				'error',
				target.kind === 'jornada'
					? 'No se pudo conectar con el servidor para eliminar la jornada'
					: 'No se pudo conectar con el servidor para eliminar el cuadro'
			);
		} finally {
			deletingStructure = false;
		}
	}

	$effect(() => {
		const focusCuadroId = props.focusCuadroId?.trim() ?? '';
		const focusJornadaId = props.focusJornadaId?.trim() ?? '';
		const focusKey = focusCuadroId ? `cuadro:${focusCuadroId}` : focusJornadaId ? `jornada:${focusJornadaId}` : '';
		if (!focusKey) {
			handledFocusTarget = null;
			return;
		}
		if (focusKey === handledFocusTarget) return;

		if (focusCuadroId) {
			const targetCuadro = getCuadroById(focusCuadroId);
			if (targetCuadro) {
				openEditCuadro(targetCuadro);
			} else {
				pushToast('info', 'El cuadro enlazado no existe o ya no está disponible.');
			}
		} else if (focusJornadaId) {
			const targetJornada = getJornadaById(focusJornadaId);
			if (targetJornada) {
				openEditJornada(targetJornada);
			} else {
				pushToast('info', 'La jornada enlazada no existe o ya no está disponible.');
			}
		}

		handledFocusTarget = focusKey;
		clearFocusStructureQueryParams();
	});

	$effect(() => {
		const mode = sidebarMode;
		const readOnly = props.readOnly;
		const trackJornada = `${jornadaForm.jornada_num}|${jornadaForm.v_ini}|${jornadaForm.v_fin}`;
		const trackCuadro = `${cuadroForm.jornada_id}|${cuadroForm.cuadro_num}|${cuadroForm.v_ini}|${cuadroForm.v_fin}`;
		void trackJornada;
		void trackCuadro;

		if (!mode || readOnly) {
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
		const draftValue = currentDraftValue();
		if (draftValue) localDraftWriter.schedule(localDraftKey(), draftValue);
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
	<div class="flex flex-wrap items-center justify-between gap-3">
		<h2 class="text-lg font-semibold">Jornadas y cuadros</h2>
	</div>

	{#if jornadas.length === 0}
		<p class="bg-white px-3 py-2 text-sm text-[color:var(--muted-foreground)]">
			No hay jornadas registradas.
		</p>
	{:else}
		<div>
			{#each sortByVIni(jornadas) as jornada}
				<section class="space-y-2 py-3 first:pt-0">
					<div class="flex flex-wrap items-start justify-between gap-3">
						<div class="min-w-0 text-sm">
							<span class="font-semibold">Jornada {jornada.jornada_num}</span>
							<span class="ml-2 text-xs text-[color:var(--muted-foreground)]">
								vv. {jornada.v_ini}-{jornada.v_fin}
							</span>
						</div>
						<div class="flex items-center gap-1">
							<button
								type="button"
								class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--success)] disabled:opacity-40"
								aria-label={props.readOnly ? 'Ver jornada' : 'Editar jornada'}
								onclick={() => requestOpenEditJornada(jornada)}
								disabled={props.readOnly && !props.canComment}
							>
								{#if props.readOnly}<Eye size={16} />{:else}<Pencil size={16} />{/if}
							</button>
							<button
								type="button"
								class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--danger)] disabled:opacity-40"
								aria-label="Eliminar jornada"
								onclick={() => openDeleteJornada(jornada)}
								disabled={props.readOnly}
							>
								<Trash2 size={16} />
							</button>
						</div>
					</div>

					<div class="bg-white">
						{#if getCuadros(jornada.jornada_id).length === 0}
							<p class="px-3 py-2 text-sm text-[color:var(--muted-foreground)]">
								Sin cuadros en esta jornada.
							</p>
						{:else}
							{#each getCuadros(jornada.jornada_id) as cuadro}
								<div
									class="flex items-center justify-between gap-3 border-t border-[color:var(--border)] px-3 py-2 text-sm first:border-t-0"
								>
									<div class="min-w-0">
										<span class="font-medium">Cuadro {cuadro.cuadro_num}</span>
										<span class="ml-2 text-xs text-[color:var(--muted-foreground)]">
											vv. {cuadro.v_ini}-{cuadro.v_fin}
										</span>
									</div>
									<div class="flex items-center gap-1">
										<button
											type="button"
											class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--success)] disabled:opacity-40"
											aria-label={props.readOnly ? 'Ver cuadro' : 'Editar cuadro'}
											onclick={() => requestOpenEditCuadro(cuadro)}
											disabled={props.readOnly && !props.canComment}
										>
											{#if props.readOnly}<Eye size={16} />{:else}<Pencil size={16} />{/if}
										</button>
										<button
											type="button"
											class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--danger)] disabled:opacity-40"
											aria-label="Eliminar cuadro"
											onclick={() => openDeleteCuadro(cuadro)}
											disabled={props.readOnly}
										>
											<Trash2 size={16} />
										</button>
									</div>
								</div>
							{/each}
						{/if}
					</div>

					<Button variant="ghost" onclick={() => requestOpenNewCuadro(jornada)} disabled={props.readOnly}>
						<Plus size={16} />
						Añadir cuadro
					</Button>
				</section>
			{/each}
		</div>
	{/if}

	<div class="flex justify-start">
		<Button variant="primary-soft" onclick={requestOpenNewJornada} disabled={props.readOnly}>
			<Plus size={16} />
			Añadir jornada
		</Button>
	</div>
</section>

{#if sidebarMode}
	<aside
		class="fixed right-0 top-0 z-40 h-screen w-full max-w-xl overflow-y-auto border-l border-[color:var(--border)] bg-[color:var(--gray-50)] p-5"
		inert={sidebarSaving}
		aria-busy={sidebarSaving}
	>
		<div class="sticky top-0 z-10 mb-4 flex items-center justify-between gap-3 bg-[color:var(--gray-50)] pb-3">
			<div class="flex min-w-0 items-center gap-2">
				<h3 class="text-base font-semibold">
					{#if sidebarMode === 'jornada-new'}Nueva jornada{/if}
					{#if sidebarMode === 'jornada-edit'}{props.readOnly ? 'Ver jornada' : 'Editar jornada'}{/if}
					{#if sidebarMode === 'cuadro-new'}Nuevo cuadro{/if}
					{#if sidebarMode === 'cuadro-edit'}{props.readOnly ? 'Ver cuadro' : 'Editar cuadro'}{/if}
				</h3>
				{#if sidebarMode === 'jornada-edit' && editingJornadaIndex >= 0}
					<div class="flex items-center gap-1">
						<button
							type="button"
							class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
							aria-label="Jornada anterior"
							onclick={() => void goToJornada(prevJornada)}
							disabled={!prevJornada || sidebarSaving}
						>
							<ChevronLeft size={18} />
						</button>
						<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
							{editingJornadaIndex + 1} / {orderedJornadas.length}
						</span>
						<button
							type="button"
							class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
							aria-label="Jornada siguiente"
							onclick={() => void goToJornada(nextJornada)}
							disabled={!nextJornada || sidebarSaving}
						>
							<ChevronRight size={18} />
						</button>
					</div>
				{:else if sidebarMode === 'cuadro-edit' && editingCuadroIndex >= 0}
					<div class="flex items-center gap-1">
						<button
							type="button"
							class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
							aria-label="Cuadro anterior"
							onclick={() => void goToCuadro(prevCuadro)}
							disabled={!prevCuadro || sidebarSaving}
						>
							<ChevronLeft size={18} />
						</button>
						<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
							{editingCuadroIndex + 1} / {orderedCuadros.length}
						</span>
						<button
							type="button"
							class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
							aria-label="Cuadro siguiente"
							onclick={() => void goToCuadro(nextCuadro)}
							disabled={!nextCuadro || sidebarSaving}
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
						onclick={() => void saveSidebar()}
						loading={sidebarSaving}
						loadingLabel="Guardando…"
					>
						Guardar
					</Button>
				{/if}
			</div>
		</div>

		<div class="grid gap-3">
			{#if sidebarMode === 'jornada-new' || sidebarMode === 'jornada-edit'}
				<div class="grid gap-3 sm:grid-cols-3">
					<label class="form-field">
						<span class="form-label">Jornada #</span>
						<input
							type="number"
							bind:value={jornadaForm.jornada_num}
							min="1"
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Verso inicial</span>
						<input
							type="number"
							bind:value={jornadaForm.v_ini}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Verso final</span>
						<input
							type="number"
							bind:value={jornadaForm.v_fin}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
				</div>
			{:else}
				<label class="form-field">
					<span class="form-label">Jornada</span>
					<CheckDropdown
						multiple={false}
						search={jornadaDropdownItems.length > 8}
						placeholder="Seleccionar jornada"
						items={jornadaDropdownItems}
						disabled={props.readOnly}
						selectedIds={cuadroForm.jornada_id ? [cuadroForm.jornada_id] : []}
						onChange={(ids) => {
							const nextJornadaId = ids[0] ?? '';
							if (!nextJornadaId) return;
							onCuadroJornadaChange(nextJornadaId);
						}}
					/>
				</label>
				<div class="grid gap-3 sm:grid-cols-3">
					<label class="form-field">
						<span class="form-label">Cuadro #</span>
						<input
							type="number"
							bind:value={cuadroForm.cuadro_num}
							min="1"
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Verso inicial</span>
						<input
							type="number"
							bind:value={cuadroForm.v_ini}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Verso final</span>
						<input
							type="number"
							bind:value={cuadroForm.v_fin}
							disabled={props.readOnly}
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						/>
					</label>
				</div>
			{/if}
		</div>

		{#if sidebarMode === 'jornada-edit' && editingJornadaId}
			<div class="mt-4">
				{#key editingJornadaId}
					<InternalCommentsPanel
						obraId={props.obraId}
						canComment={Boolean(props.canComment)}
						title="Comentarios internos de jornada"
						context={{ jornada_id: editingJornadaId }}
						collapsible={true}
						defaultCollapsed={true}
						collapseLabel="Ver"
						focusComentarioId={props.focusComentarioId}
						reloadKey={props.commentsReloadKey}
					/>
				{/key}
			</div>
		{/if}
		{#if sidebarMode === 'cuadro-edit' && editingCuadroId}
			<div class="mt-4">
				{#key editingCuadroId}
					<InternalCommentsPanel
						obraId={props.obraId}
						canComment={Boolean(props.canComment)}
						title="Comentarios internos de cuadro"
						context={{ cuadro_id: editingCuadroId }}
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

{#if deleteTarget}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">{deleteTarget.title}</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{deleteTarget.description}</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button
					variant="secondary"
					onclick={() => (deleteTarget = null)}
					disabled={deletingStructure}
				>
					Cancelar
				</Button>
				<Button
					variant="danger"
					onclick={confirmDelete}
					disabled={props.readOnly}
					loading={deletingStructure}
					loadingLabel="Eliminando…"
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
		pendingSidebarAction?.kind === 'new-jornada'
			? 'La jornada actual tiene cambios sin guardar. ¿Quieres guardarlos antes de crear otra?'
			: pendingSidebarAction?.kind === 'new-cuadro'
				? 'El cuadro actual tiene cambios sin guardar. ¿Quieres guardarlos antes de crear otro?'
				: pendingSidebarAction?.kind === 'jornada'
					? 'La jornada actual tiene cambios sin guardar. ¿Quieres guardarlos antes de cambiar de jornada?'
					: pendingSidebarAction?.kind === 'cuadro'
						? 'El cuadro actual tiene cambios sin guardar. ¿Quieres guardarlos antes de cambiar de cuadro?'
						: 'Este elemento tiene cambios sin guardar. ¿Quieres guardarlos antes de cerrar?'
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


<script lang="ts">
	import { browser } from '$app/environment';
	import { beforeNavigate, goto } from '$app/navigation';
	import { onDestroy, onMount } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import { getVocabularyFieldConfig } from '$lib/config/vocabulary-fields';
	import VocabularyTree from '$lib/components/vocabularios/VocabularyTree.svelte';
	import VocabularyDetailPanel from '$lib/components/vocabularios/VocabularyDetailPanel.svelte';
	import {
		buildReorderPayload,
		computePath,
		flattenVocabularyTree,
		normalizeTree,
		type VocabularyItem
	} from '$lib/components/vocabularios/useVocabularyTree';
	import { pushToast } from '$lib/stores/toast';
	import type { PageData } from './$types';

	type TipoFormaValue = 'forma_espanola' | 'forma_italiana' | null;

	type TermForm = {
		termino: string;
		termino_padre_id: string | null;
		nivel: number | null;
		activo: boolean;
		definicion: string;
		ejemplo: string;
		bibliografia: string;
		equivalenciasText: string;
		patron_especifico: string;
		tipo_forma: TipoFormaValue;
		metro_ids: string[];
	};

	type CreateTermForm = {
		termino: string;
		termino_padre_id: string | null;
		activo: boolean;
		definicion: string;
		ejemplo: string;
		bibliografia: string;
		equivalenciasText: string;
		patron_especifico: string;
		tipo_forma: TipoFormaValue;
		metro_ids: string[];
	};

	type EstrofaTipoMetro = {
		estrofa_tipo_id: string;
		metro_id: string;
	};

	type TreeSyncStatus = 'idle' | 'saving' | 'queued' | 'error';

	let { data } = $props<{ data: PageData }>();
	let items = $state<VocabularyItem[]>([]);
	let estrofaTipoMetros = $state<EstrofaTipoMetro[]>([]);
	let selectedId = $state<string | null>(null);
	let search = $state('');

	let savingTree = $state(false);
	let savingTerm = $state(false);
	let creating = $state(false);
	let showCreateModal = $state(false);
	let deletingTerm = $state(false);
	let deleteConfirmText = $state('');
	let showDeleteModal = $state(false);
	let queuedSave = $state(false);
	let retryAttempt = $state(0);
	let retryScheduled = $state(false);
	let treeSyncStatus = $state<TreeSyncStatus>('idle');
	let persistedTreeSignature = $state('');

	function emptyCreateForm(): CreateTermForm {
		return {
			termino: '',
			termino_padre_id: null,
			activo: true,
			definicion: '',
			ejemplo: '',
			bibliografia: '',
			equivalenciasText: '',
			patron_especifico: '',
			tipo_forma: null,
			metro_ids: []
		};
	}

	function emptyTermForm(): TermForm {
		return {
			termino: '',
			termino_padre_id: null,
			nivel: null,
			activo: true,
			definicion: '',
			ejemplo: '',
			bibliografia: '',
			equivalenciasText: '',
			patron_especifico: '',
			tipo_forma: null,
			metro_ids: []
		};
	}

	let createForm = $state<CreateTermForm>(emptyCreateForm());
	let termForm = $state<TermForm>(emptyTermForm());
	let lastHydrationKey = $state('');

	let retryTimer: ReturnType<typeof setTimeout> | null = null;
	let termAutosaveTimer: ReturnType<typeof setTimeout> | null = null;
	let hasShownAutoSaveError = false;
	let termAutosaveErrorShown = false;
	let showUnsavedChangesModal = $state(false);
	let pendingSelectionId = $state<string | null>(null);
	let pendingCloseDetail = $state(false);
	let pendingRouteChange = $state<string | null>(null);
	let bypassUnsavedGuard = false;

	const fieldConfig = $derived(getVocabularyFieldConfig(data.categoria));
	const readOnly = $derived(!data.canEdit);
	const deleteConfirmed = $derived(deleteConfirmText.trim() === 'ELIMINAR');
	const selectedItem = $derived(items.find((item) => item.termino_id === selectedId) ?? null);
	const pathLabel = $derived(computePath(items, selectedId).join(' > '));
	const parentOptions = $derived(
		flattenVocabularyTree(items)
			.filter((row) => row.item.termino_id !== selectedId)
			.map((row) => ({
				id: row.item.termino_id,
				label: `${'  '.repeat(Math.max(0, row.depth - 1))}${row.item.termino}`
			}))
	);
	const createParentOptions = $derived(
		flattenVocabularyTree(items)
			.filter((row) => row.depth === 1)
			.map((row) => ({
				id: row.item.termino_id,
				label: row.item.termino
			}))
	);
	const metroDropdownItems = $derived(
		(data.metroOptions ?? []).map((metro: { termino_id: string; termino: string }) => ({
			id: metro.termino_id,
			label: metro.termino
		}))
	);

	const treeSyncLabel = $derived.by(() => {
		if (readOnly) return '';
		if (savingTree && retryAttempt > 0) return 'Reintentando...';
		if (savingTree) return 'Guardando...';
		if (retryScheduled) return 'Reintentando...';
		if (treeSyncStatus === 'queued') return 'Pendiente';
		if (treeSyncStatus === 'error') return 'Pendiente';
		return 'Sincronizado';
	});
	const treeSyncTone = $derived.by(() => {
		if (readOnly) return '';
		if (treeSyncStatus === 'error') return 'text-red-700';
		if (savingTree || retryScheduled || treeSyncStatus === 'queued') {
			return 'text-[color:var(--muted-foreground)]';
		}
		return 'text-emerald-700';
	});

	const termDirty = $derived.by(() => {
		if (!selectedItem) return false;

		if (termForm.termino.trim() !== selectedItem.termino) return true;

		if (fieldConfig.showParent) {
			if ((termForm.termino_padre_id ?? null) !== (selectedItem.termino_padre_id ?? null)) return true;
		}
		if (fieldConfig.showActive) {
			if (termForm.activo !== Boolean(selectedItem.activo ?? true)) return true;
		}
		if (fieldConfig.showDefinition) {
			if (termForm.definicion.trim() !== (selectedItem.definicion ?? '').trim()) return true;
		}
		if (fieldConfig.showExample) {
			if (termForm.ejemplo.trim() !== (selectedItem.ejemplo ?? '').trim()) return true;
		}
		if (fieldConfig.showBibliography) {
			if (termForm.bibliografia.trim() !== (selectedItem.bibliografia ?? '').trim()) return true;
		}
		if (fieldConfig.showEquivalences) {
			const equivalencias = normalizeEquivalencias(termForm.equivalenciasText);
			const currentEquivalencias = normalizeEquivalencias((selectedItem.equivalencias ?? []).join('\n'));
			if (JSON.stringify(equivalencias) !== JSON.stringify(currentEquivalencias)) return true;
		}
		if (fieldConfig.showPattern) {
			if (termForm.patron_especifico.trim() !== (selectedItem.patron_especifico ?? '').trim()) return true;
		}
		if (fieldConfig.showTipoForma) {
			if (termForm.tipo_forma !== normalizeTipoForma(selectedItem.tipo_forma)) return true;
		}
		if (fieldConfig.showMetros) {
			const currentMetroIds = normalizeMetroIds(metroIdsForTerm(selectedItem.termino_id));
			const formMetroIds = normalizeMetroIds(termForm.metro_ids);
			if (JSON.stringify(formMetroIds) !== JSON.stringify(currentMetroIds)) return true;
		}

		return false;
	});

	function normalizeTipoForma(value: string | null | undefined): TipoFormaValue {
		if (value === 'forma_espanola' || value === 'forma_italiana') return value;
		return null;
	}

	function normalizeEquivalencias(text: string): string[] {
		return text
			.split('\n')
			.map((value) => value.trim())
			.filter(Boolean)
			.filter((value, index, self) => self.indexOf(value) === index);
	}

	function normalizeMetroIds(ids: string[]): string[] {
		return [...new Set(ids)].sort((a, b) => a.localeCompare(b));
	}

	function metroIdsForTerm(terminoId: string): string[] {
		return normalizeMetroIds(
			estrofaTipoMetros
				.filter((item) => item.estrofa_tipo_id === terminoId)
				.map((item) => item.metro_id)
		);
	}

	function computeTreeSignature(sourceItems: VocabularyItem[]): string {
		return JSON.stringify(
			buildReorderPayload(sourceItems, data.categoria).sort((a, b) => a.termino_id.localeCompare(b.termino_id))
		);
	}

	function computeHydrationKey(source: PageData): string {
		const vocabKey = (source.vocabularios ?? [])
			.map((item) => `${item.termino_id}:${item.termino_padre_id ?? ''}:${item.orden ?? ''}:${item.activo ?? ''}`)
			.join('|');
		const metrosKey = (source.estrofaTipoMetros ?? [])
			.map((item) => `${item.estrofa_tipo_id}:${item.metro_id}`)
			.sort((a, b) => a.localeCompare(b))
			.join('|');
		return `${source.categoria}|${vocabKey}|${metrosKey}|${source.canEdit ? '1' : '0'}`;
	}

	function clearRetryTimer() {
		if (retryTimer) {
			clearTimeout(retryTimer);
			retryTimer = null;
		}
		retryScheduled = false;
	}

	function clearTermAutosaveTimer() {
		if (termAutosaveTimer) {
			clearTimeout(termAutosaveTimer);
			termAutosaveTimer = null;
		}
	}

	function hasPendingTermChanges() {
		return Boolean(selectedItem && termDirty && !savingTerm);
	}

	function openUnsavedChangesModal({
		selectionId = null,
		closeDetail = false,
		routeChange = null
	}: {
		selectionId?: string | null;
		closeDetail?: boolean;
		routeChange?: string | null;
	}) {
		pendingSelectionId = selectionId;
		pendingCloseDetail = closeDetail;
		pendingRouteChange = routeChange;
		showUnsavedChangesModal = true;
	}

	function cancelUnsavedChangesModal() {
		showUnsavedChangesModal = false;
		pendingSelectionId = null;
		pendingCloseDetail = false;
		pendingRouteChange = null;
	}

	function performSelectItem(terminoId: string) {
		selectedId = terminoId;
		syncFormFromSelection();
	}

	function performCloseSelectedItem() {
		selectedId = null;
		termForm = emptyTermForm();
		showDeleteModal = false;
		deleteConfirmText = '';
		clearTermAutosaveTimer();
		termAutosaveErrorShown = false;
	}

	async function confirmUnsavedChangesModal() {
		const nextSelectionId = pendingSelectionId;
		const shouldCloseDetail = pendingCloseDetail;
		const nextRoute = pendingRouteChange;

		cancelUnsavedChangesModal();

		if (nextSelectionId) {
			performSelectItem(nextSelectionId);
			return;
		}
		if (shouldCloseDetail) {
			performCloseSelectedItem();
			return;
		}
		if (!nextRoute) return;

		bypassUnsavedGuard = true;
		try {
			await goto(nextRoute);
		} finally {
			bypassUnsavedGuard = false;
		}
	}

	function termFormFromItem(item: VocabularyItem): TermForm {
		return {
			termino: item.termino,
			termino_padre_id: item.termino_padre_id,
			nivel: item.nivel,
			activo: Boolean(item.activo ?? true),
			definicion: item.definicion ?? '',
			ejemplo: item.ejemplo ?? '',
			bibliografia: item.bibliografia ?? '',
			equivalenciasText: (item.equivalencias ?? []).join('\n'),
			patron_especifico: item.patron_especifico ?? '',
			tipo_forma: normalizeTipoForma(item.tipo_forma),
			metro_ids: fieldConfig.showMetros ? metroIdsForTerm(item.termino_id) : []
		};
	}

	function syncFormFromSelection() {
		const item = items.find((row) => row.termino_id === selectedId);
		if (!item) {
			termForm = emptyTermForm();
			return;
		}
		termForm = termFormFromItem(item);
	}

	function onSelectItem(terminoId: string) {
		if (terminoId === selectedId) return;
		if (hasPendingTermChanges()) {
			openUnsavedChangesModal({ selectionId: terminoId });
			return;
		}
		performSelectItem(terminoId);
	}

	function closeSelectedItem() {
		if (hasPendingTermChanges()) {
			openUnsavedChangesModal({ closeDetail: true });
			return;
		}
		performCloseSelectedItem();
	}

	function openDeleteModal() {
		if (readOnly || !selectedItem || deletingTerm) return;
		deleteConfirmText = '';
		showDeleteModal = true;
	}

	function closeDeleteModal() {
		if (deletingTerm) return;
		showDeleteModal = false;
		deleteConfirmText = '';
	}

	async function deleteSelectedTerm() {
		if (readOnly || deletingTerm || !selectedItem) return;
		if (!deleteConfirmed) {
			pushToast('error', 'Debes escribir ELIMINAR para confirmar.');
			return;
		}

		const target = selectedItem;
		deletingTerm = true;
		const response = await fetch(`/api/vocabularios/${target.termino_id}`, {
			method: 'DELETE',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ confirmText: deleteConfirmText.trim() })
		});
		deletingTerm = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo eliminar el termino.');
			return;
		}

		showDeleteModal = false;
		deleteConfirmText = '';
		cancelUnsavedChangesModal();
		estrofaTipoMetros = estrofaTipoMetros.filter(
			(item) => item.estrofa_tipo_id !== target.termino_id && item.metro_id !== target.termino_id
		);
		items = normalizeTree(items.filter((item) => item.termino_id !== target.termino_id));

		if (selectedId === target.termino_id) {
			performCloseSelectedItem();
		} else {
			syncFormFromSelection();
		}

		pushToast('success', 'Término eliminado.');
	}

	beforeNavigate((navigation) => {
		if (!browser) return;
		if (bypassUnsavedGuard) return;
		if (!navigation.to) return;
		if (!hasPendingTermChanges()) return;

		const sameDestination =
			navigation.to.url.pathname === window.location.pathname &&
			navigation.to.url.search === window.location.search &&
			navigation.to.url.hash === window.location.hash;
		if (sameDestination) return;

		navigation.cancel();
		const route = `${navigation.to.url.pathname}${navigation.to.url.search}${navigation.to.url.hash}`;
		openUnsavedChangesModal({ routeChange: route });
	});

	function scheduleTreeRetry() {
		if (readOnly || retryScheduled) return;
		const delay = Math.min(8000, 1500 * 2 ** Math.max(0, retryAttempt - 1));
		retryScheduled = true;
		treeSyncStatus = 'queued';
		retryTimer = setTimeout(() => {
			retryTimer = null;
			retryScheduled = false;
			if (readOnly) return;
			if (savingTree) {
				queuedSave = true;
				treeSyncStatus = 'queued';
				return;
			}
			queuedSave = false;
			void saveTreeNow();
		}, delay);
	}

	async function saveTreeNow() {
		if (readOnly || savingTree) return;
		const requestSignature = computeTreeSignature(items);
		if (requestSignature === persistedTreeSignature) {
			queuedSave = false;
			treeSyncStatus = 'idle';
			return;
		}

		clearRetryTimer();
		savingTree = true;
		treeSyncStatus = 'saving';
		const requestPayload = buildReorderPayload(items, data.categoria);
		const response = await fetch('/api/vocabularios/reordenar', {
			method: 'PUT',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				categoria: data.categoria,
				items: requestPayload
			})
		});
		savingTree = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			treeSyncStatus = 'error';
			queuedSave = true;
			retryAttempt = Math.min(retryAttempt + 1, 8);
			if (!hasShownAutoSaveError) {
				pushToast('error', body.message ?? 'No se pudo guardar el orden jerarquico.', 5500, {
					actionLabel: 'Reintentar ahora',
					onAction: () => {
						clearRetryTimer();
						queuedSave = true;
						if (!savingTree) {
							queuedSave = false;
							void saveTreeNow();
						}
					}
				});
				hasShownAutoSaveError = true;
			}
			scheduleTreeRetry();
			return;
		}

		const payload = await response.json();
		const serverItems = normalizeTree(payload.vocabularios as VocabularyItem[]);
		const serverSignature = computeTreeSignature(serverItems);
		persistedTreeSignature = serverSignature;
		retryAttempt = 0;
		hasShownAutoSaveError = false;

		const liveSignature = computeTreeSignature(items);
		let signatureAfterApply = liveSignature;
		if (liveSignature === requestSignature) {
			items = serverItems;
			syncFormFromSelection();
			signatureAfterApply = computeTreeSignature(serverItems);
		}

		if (signatureAfterApply !== persistedTreeSignature) {
			queuedSave = true;
			treeSyncStatus = 'queued';
		} else {
			queuedSave = false;
			treeSyncStatus = 'idle';
		}

		if (queuedSave) {
			queuedSave = false;
			void saveTreeNow();
		}
	}

	function enqueueTreeSave() {
		if (readOnly) return;
		const currentSignature = computeTreeSignature(items);
		if (currentSignature === persistedTreeSignature) {
			queuedSave = false;
			if (!savingTree && !retryScheduled) treeSyncStatus = 'idle';
			return;
		}
		if (savingTree || retryScheduled) {
			queuedSave = true;
			treeSyncStatus = 'queued';
			return;
		}
		void saveTreeNow();
	}

	function onTreeItemsChange(nextItems: VocabularyItem[]) {
		const normalized = normalizeTree(nextItems);
		if (computeTreeSignature(normalized) === computeTreeSignature(items)) {
			return;
		}
		items = normalized;
		syncFormFromSelection();
		enqueueTreeSave();
	}

	function onTermFormChange(patch: Partial<TermForm>) {
		termForm = { ...termForm, ...patch };
	}

	function resetCreateForm() {
		createForm = emptyCreateForm();
	}

	function openCreateModal() {
		if (readOnly) return;
		resetCreateForm();
		showCreateModal = true;
	}

	function closeCreateModal() {
		if (creating) return;
		showCreateModal = false;
	}

	function onCreateFormChange(patch: Partial<CreateTermForm>) {
		createForm = { ...createForm, ...patch };
	}

	function buildPatchPayloadFromForm(form: TermForm): Record<string, unknown> {
		const payload: Record<string, unknown> = {
			termino: form.termino.trim()
		};

		if (fieldConfig.showParent) payload.termino_padre_id = form.termino_padre_id;
		if (fieldConfig.showActive) payload.activo = form.activo;
		if (fieldConfig.showDefinition) payload.definicion = form.definicion.trim() || null;
		if (fieldConfig.showExample) payload.ejemplo = form.ejemplo.trim() || null;
		if (fieldConfig.showBibliography) payload.bibliografia = form.bibliografia.trim() || null;
		if (fieldConfig.showEquivalences) {
			const equivalencias = normalizeEquivalencias(form.equivalenciasText);
			payload.equivalencias = equivalencias.length > 0 ? equivalencias : null;
		}
		if (fieldConfig.showPattern) payload.patron_especifico = form.patron_especifico.trim() || null;
		if (fieldConfig.showTipoForma) payload.tipo_forma = form.tipo_forma;
		if (fieldConfig.showMetros) payload.metro_ids = normalizeMetroIds(form.metro_ids);

		return payload;
	}

	function buildCreatePayloadFromForm(form: CreateTermForm): Record<string, unknown> {
		const payload: Record<string, unknown> = {
			categoria: data.categoria,
			termino: form.termino.trim()
		};

		if (fieldConfig.showParent) payload.termino_padre_id = form.termino_padre_id;
		if (fieldConfig.showActive) payload.activo = form.activo;
		if (fieldConfig.showDefinition) payload.definicion = form.definicion.trim() || null;
		if (fieldConfig.showExample) payload.ejemplo = form.ejemplo.trim() || null;
		if (fieldConfig.showBibliography) payload.bibliografia = form.bibliografia.trim() || null;
		if (fieldConfig.showEquivalences) {
			const equivalencias = normalizeEquivalencias(form.equivalenciasText);
			payload.equivalencias = equivalencias.length > 0 ? equivalencias : null;
		}
		if (fieldConfig.showPattern) payload.patron_especifico = form.patron_especifico.trim() || null;
		if (fieldConfig.showTipoForma) payload.tipo_forma = form.tipo_forma;
		if (fieldConfig.showMetros) payload.metro_ids = normalizeMetroIds(form.metro_ids);

		return payload;
	}

	function applyReturnedMetros(terminoId: string, metroIds: string[]) {
		estrofaTipoMetros = estrofaTipoMetros.filter((item) => item.estrofa_tipo_id !== terminoId);
		estrofaTipoMetros = [
			...estrofaTipoMetros,
			...normalizeMetroIds(metroIds).map((metroId) => ({
				estrofa_tipo_id: terminoId,
				metro_id: metroId
			}))
		];
	}

	function handleTermAutosaveError(message: string) {
		if (termAutosaveErrorShown) return;
		termAutosaveErrorShown = true;
		pushToast('error', message);
	}

	async function saveTerm(source: 'manual' | 'autosave' = 'manual') {
		if (readOnly || deletingTerm || !selectedItem || !termDirty || savingTerm) return;
		savingTerm = true;

		const response = await fetch(`/api/vocabularios/${selectedItem.termino_id}`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(buildPatchPayloadFromForm(termForm))
		});
		savingTerm = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message = body.message ?? 'No se pudo guardar el termino.';
			if (source === 'manual') {
				pushToast('error', message);
			} else {
				handleTermAutosaveError(message);
			}
			return;
		}

		const payload = await response.json();
		const updated = payload.vocabulario as VocabularyItem;
		if (fieldConfig.showMetros) {
			applyReturnedMetros(updated.termino_id, (payload.metro_ids ?? []) as string[]);
		}
		items = normalizeTree(items.map((item) => (item.termino_id === updated.termino_id ? updated : item)));
		syncFormFromSelection();
		termAutosaveErrorShown = false;
		if (source === 'manual') {
			pushToast('success', 'Término actualizado.');
		}
	}

	async function createTerm() {
		if (readOnly || creating) return;
		const term = createForm.termino.trim();
		if (!term) {
			pushToast('error', 'Escribe un termino para crear.');
			return;
		}
		creating = true;
		const response = await fetch('/api/vocabularios', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(buildCreatePayloadFromForm(createForm))
		});
		creating = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo crear el termino.');
			return;
		}

		const payload = await response.json();
		const created = payload.vocabulario as VocabularyItem;
		if (fieldConfig.showMetros) {
			applyReturnedMetros(created.termino_id, (payload.metro_ids ?? []) as string[]);
		}
		items = normalizeTree([...items, created]);
		selectedId = created.termino_id;
		showCreateModal = false;
		resetCreateForm();
		syncFormFromSelection();
		pushToast('success', 'Término creado.');
	}

	$effect(() => {
		const hydrationKey = computeHydrationKey(data);
		if (hydrationKey === lastHydrationKey) return;
		lastHydrationKey = hydrationKey;

		clearRetryTimer();
		clearTermAutosaveTimer();
		const initialItems = normalizeTree(data.vocabularios as VocabularyItem[]);
		items = initialItems;
		estrofaTipoMetros = [...((data.estrofaTipoMetros ?? []) as EstrofaTipoMetro[])];
		persistedTreeSignature = computeTreeSignature(initialItems);
		queuedSave = false;
		retryAttempt = 0;
		treeSyncStatus = 'idle';
		hasShownAutoSaveError = false;
		termAutosaveErrorShown = false;
		cancelUnsavedChangesModal();
		showDeleteModal = false;
		deleteConfirmText = '';
		deletingTerm = false;
		selectedId = null;
		termForm = emptyTermForm();
	});

	$effect(() => {
		const track = `${selectedId ?? ''}|${JSON.stringify(termForm)}`;
		void track;

		if (!selectedId || readOnly || deletingTerm) {
			clearTermAutosaveTimer();
			return;
		}
		if (!termDirty) {
			clearTermAutosaveTimer();
			termAutosaveErrorShown = false;
			return;
		}
		if (savingTerm) return;

		clearTermAutosaveTimer();
		termAutosaveTimer = setTimeout(() => {
			void saveTerm('autosave');
		}, 10_000);
	});

	onMount(() => {
		if (!browser) return;

		const handleBeforeUnload = (event: BeforeUnloadEvent) => {
			if (!hasPendingTermChanges()) return;
			event.preventDefault();
			event.returnValue = '';
		};

		window.addEventListener('beforeunload', handleBeforeUnload);
		return () => {
			window.removeEventListener('beforeunload', handleBeforeUnload);
		};
	});

	onDestroy(() => {
		clearRetryTimer();
		clearTermAutosaveTimer();
	});
</script>

<section class="space-y-4">
	<div class="flex flex-wrap items-center justify-between gap-3">
		<div>
			<div class="text-xs uppercase tracking-[0.08em] text-[color:var(--muted-foreground)]">Dashboard / Vocabularios</div>
			<h1 class="font-display text-3xl">{data.categoria}</h1>
		</div>
		<div class="flex items-center gap-2">
			{#if !readOnly}
				<Button variant="success" onclick={openCreateModal}>Nuevo término</Button>
			{/if}
			<a href="/dashboard/vocabularios">
				<Button variant="secondary">Volver a categorías</Button>
			</a>
			{#if data.isProtected}
				<span class="border border-[color:var(--warning)] bg-[color:var(--muted)] px-2 py-1 text-xs">
					Categoria protegida (solo lectura)
				</span>
			{:else if !data.canEdit}
				<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">
					Modo consulta
				</span>
			{/if}
		</div>
	</div>

	<div class="grid gap-4 lg:grid-cols-[1.25fr_1fr]">
		<div class="space-y-3 lg:max-h-[calc(100dvh-12rem)] lg:overflow-y-auto lg:pr-1">
			<div class="card p-4">
				<label class="text-sm">
					<span class="mb-1 block">Buscar término</span>
					<input
						type="text"
						bind:value={search}
						placeholder="Filtrar por nombre"
						class="w-full border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
			</div>

			<div class="card p-4">
				<div class="mb-3 flex items-center justify-between gap-2">
					<h2 class="text-lg font-semibold">Árbol de términos</h2>
					{#if !readOnly}
						<span class={`text-xs ${treeSyncTone}`}>Orden: {treeSyncLabel}</span>
					{/if}
				</div>
				<VocabularyTree
					items={items}
					selectedId={selectedId}
					readOnly={readOnly}
					search={search}
					collapseKey={lastHydrationKey}
					allowNesting={fieldConfig.showParent}
					onSelect={onSelectItem}
					onChange={onTreeItemsChange}
				/>
			</div>
		</div>

		<div class="lg:max-h-[calc(100dvh-12rem)] lg:overflow-y-auto lg:pr-1">
			<VocabularyDetailPanel
				selectedItem={selectedItem}
				pathLabel={pathLabel}
				readOnly={readOnly}
				termForm={termForm}
				parentOptions={parentOptions}
				metroOptions={data.metroOptions ?? []}
				fieldConfig={fieldConfig}
				termDirty={termDirty}
				savingTerm={savingTerm}
				deletingTerm={deletingTerm}
				onTermFormChange={onTermFormChange}
				onSaveTerm={saveTerm}
				onOpenDeleteModal={openDeleteModal}
				onClose={closeSelectedItem}
			/>
		</div>
	</div>
</section>

{#if showUnsavedChangesModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold">Cambios sin guardar</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Hay cambios sin guardar en este panel.</p>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">Si continuas, perderas los cambios no guardados.</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={cancelUnsavedChangesModal}>Seguir editando</Button>
				<Button variant="danger" onclick={() => void confirmUnsavedChangesModal()}>Cerrar sin guardar</Button>
			</div>
		</div>
	</div>
{/if}

{#if showDeleteModal && selectedItem}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold text-[color:var(--danger)]">Confirmar eliminacion</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				Esta accion es irreversible. Escribe <strong>ELIMINAR</strong> para confirmar.
			</p>
			<label class="mt-3 block text-sm">
				<span class="mb-1 block">Confirmacion</span>
				<input
					type="text"
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					bind:value={deleteConfirmText}
					autocomplete="off"
					spellcheck={false}
				/>
			</label>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={closeDeleteModal} disabled={deletingTerm}>Cancelar</Button>
				<Button
					variant="danger"
					onclick={() => void deleteSelectedTerm()}
					disabled={deletingTerm || !deleteConfirmed}
				>
					{deletingTerm ? 'Eliminando...' : 'Eliminar'}
				</Button>
			</div>
		</div>
	</div>
{/if}

{#if showCreateModal && !readOnly}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card max-h-[85vh] w-full max-w-2xl overflow-y-auto p-5">
			<div class="mb-4 flex items-center justify-between gap-3">
				<h3 class="text-lg font-semibold">Nuevo término</h3>
				<button
					type="button"
					class="border border-[color:var(--border)] px-2 py-1 text-sm"
					onclick={closeCreateModal}
					disabled={creating}
				>
					Cerrar
				</button>
			</div>

			<div class="grid gap-3">
				<label class="text-sm">
					<span class="mb-1 block">Término</span>
					<input
						type="text"
						value={createForm.termino}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						oninput={(event) => onCreateFormChange({ termino: event.currentTarget.value })}
					/>
				</label>

				{#if fieldConfig.showParent}
					<label class="text-sm">
						<span class="mb-1 block">Término padre (opcional)</span>
						<select
							value={createForm.termino_padre_id ?? ''}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							onchange={(event) => onCreateFormChange({ termino_padre_id: event.currentTarget.value || null })}
						>
							<option value="">Sin padre (raíz)</option>
							{#each createParentOptions as option}
								<option value={option.id}>{option.label}</option>
							{/each}
						</select>
					</label>
				{/if}

				{#if fieldConfig.showActive}
					<label class="flex items-center gap-2 text-sm">
						<input
							type="checkbox"
							checked={createForm.activo}
							onchange={(event) => onCreateFormChange({ activo: event.currentTarget.checked })}
						/>
						Activo
					</label>
				{/if}

				{#if fieldConfig.showDefinition}
					<label class="text-sm">
						<span class="mb-1 block">Definición</span>
						<textarea
							rows={4}
							value={createForm.definicion}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							oninput={(event) => onCreateFormChange({ definicion: event.currentTarget.value })}
						></textarea>
					</label>
				{/if}

				{#if fieldConfig.showExample}
					<label class="text-sm">
						<span class="mb-1 block">Ejemplo</span>
						<textarea
							rows={3}
							value={createForm.ejemplo}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							oninput={(event) => onCreateFormChange({ ejemplo: event.currentTarget.value })}
						></textarea>
					</label>
				{/if}

				{#if fieldConfig.showBibliography}
					<label class="text-sm">
						<span class="mb-1 block">Bibliografía</span>
						<textarea
							rows={3}
							value={createForm.bibliografia}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							oninput={(event) => onCreateFormChange({ bibliografia: event.currentTarget.value })}
						></textarea>
					</label>
				{/if}

				{#if fieldConfig.showEquivalences}
					<label class="text-sm">
						<span class="mb-1 block">Equivalencias (una por línea)</span>
						<textarea
							rows={3}
							value={createForm.equivalenciasText}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							oninput={(event) => onCreateFormChange({ equivalenciasText: event.currentTarget.value })}
						></textarea>
					</label>
				{/if}

				{#if fieldConfig.showPattern}
					<label class="text-sm">
						<span class="mb-1 block">Patrón específico</span>
						<input
							type="text"
							value={createForm.patron_especifico}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							oninput={(event) => onCreateFormChange({ patron_especifico: event.currentTarget.value })}
						/>
					</label>
				{/if}

				{#if fieldConfig.showTipoForma}
					<label class="text-sm">
						<span class="mb-1 block">Tipo de forma</span>
						<select
							value={createForm.tipo_forma ?? ''}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							onchange={(event) =>
								onCreateFormChange({
									tipo_forma: (event.currentTarget.value || null) as TipoFormaValue
								})}
						>
							<option value="">Sin especificar</option>
							<option value="forma_espanola">Forma española</option>
							<option value="forma_italiana">Forma italiana</option>
						</select>
					</label>
				{/if}

				{#if fieldConfig.showMetros}
					<div class="text-sm">
						<span class="mb-1 block">Metros asociados</span>
						<CheckDropdown
							items={metroDropdownItems}
							selectedIds={createForm.metro_ids}
							search={true}
							placeholder="Seleccionar metros"
							onChange={(ids) => onCreateFormChange({ metro_ids: ids })}
						/>
					</div>
				{/if}
			</div>

			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={closeCreateModal} disabled={creating}>Cancelar</Button>
				<Button variant="success" onclick={() => void createTerm()} disabled={creating || !createForm.termino.trim()}>
					{creating ? 'Creando...' : 'Crear termino'}
				</Button>
			</div>
		</div>
	</div>
{/if}

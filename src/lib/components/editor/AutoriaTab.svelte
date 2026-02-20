<script lang="ts">
	import { onDestroy, onMount } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import AuthorSelector from '$lib/components/editor/AuthorSelector.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, patchCurrentObra, setDirty, setSaving } from '$lib/stores/currentObra';
	import type { Tables } from '$lib/types/database.types';
	import type { AutoriaApiPayload, AutoriaBlockingReason, AutoriaIntegrity } from '$lib/types/obra.types';

	type Mode = AutoriaApiPayload['mode'];
	type JornadaOption = Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>;
	type AuthorOption = Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo'>;
	type JornadaAssignment = {
		jornada_id: string;
		autor_ids: string[];
	};
	type CustomRange = {
		temp_id: string;
		v_ini: number;
		v_fin: number;
		autor_ids: string[];
	};

	const props = $props<{
		obraId: string;
		obra: Tables<'obras'>;
		roleTerm: string;
		readOnly?: boolean;
	}>();
	// Temporal: restringe UI de autoria avanzada a admin.
	const LOCK_NON_ADMIN_TO_OBRA_COMPLETA = true;

	let loadingAutoria = $state(true);
	let loadingFromServer = $state(false);
	let loadError = $state<string | null>(null);
	let savingNow = $state(false);
	let timer: ReturnType<typeof setTimeout> | null = null;

	let jornadasCurrent = $state<JornadaOption[]>([]);
	let autoresCurrent = $state<AuthorOption[]>([]);
	let rangos = $state<Tables<'rangos'>[]>([]);
	let rangosAutores = $state<Tables<'rangos_autores'>[]>([]);
	let integrity = $state<AutoriaIntegrity | null>(null);

	let canUseCustomRanges = $state(true);
	let requiresReassign = $state(false);
	let blockingReason = $state<AutoriaBlockingReason>(null);
	let defaultReassignMode = $state<Mode>('obra_completa');

	let sourceMode = $state<Mode>('obra_completa');
	let mode = $state<Mode>('obra_completa');
	let modeChangeConfirmed = $state(false);
	let reassignPrepared = $state(false);
	let pendingMode = $state<Mode | null>(null);
	let showModeChangeModal = $state(false);
	let showReassignModal = $state(false);
	let urlInforme = $state('');

	let obraCompleta = $state({ autor_ids: [] as string[] });
	let jornadaAssignments = $state<JornadaAssignment[]>([]);
	let customRanges = $state<CustomRange[]>([]);
	let baselineSnapshot = $state('');

	const isAdmin = $derived(props.roleTerm === 'admin');
	const nonAdminLocked = $derived(LOCK_NON_ADMIN_TO_OBRA_COMPLETA && !isAdmin);
	const legacySplitReadOnly = $derived(nonAdminLocked && sourceMode !== 'obra_completa');
	const effectiveReadOnly = $derived(Boolean(props.readOnly) || legacySplitReadOnly);
	const canShowAllModes = $derived(!LOCK_NON_ADMIN_TO_OBRA_COMPLETA || isAdmin);
	const editingBlocked = $derived(requiresReassign && !reassignPrepared);
	const jornadaMap = $derived(
		new Map(
			jornadasCurrent.map((jornada: JornadaOption) => [
				jornada.jornada_id,
				`Jornada ${jornada.jornada_num} (vv. ${jornada.v_ini}-${jornada.v_fin})`
			])
		)
	);
	const authorOptions = $derived(
		autoresCurrent.map((author) => ({
			autor_id: author.autor_id,
			nombre_completo: author.nombre_completo
		}))
	);
	const modeDropdownItems = $derived.by(() => {
		const items: Array<{ id: Mode; label: string }> = [
			{ id: 'obra_completa', label: 'Obra completa' },
			{ id: 'por_jornadas', label: 'Por jornadas' }
		];
		if (canUseCustomRanges || mode === 'rango_personalizado' || sourceMode === 'rango_personalizado') {
			items.push({ id: 'rango_personalizado', label: 'Rangos personalizados' });
		}
		return items;
	});

	function normalizeAuthorIds(ids: string[]): string[] {
		return [...new Set(ids)].sort((a, b) => a.localeCompare(b));
	}

	function normalizeUrl(url: string): string {
		return url.trim();
	}

	function modeLabel(value: Mode): string {
		if (value === 'obra_completa') return 'Obra completa';
		if (value === 'por_jornadas') return 'Por jornadas';
		return 'Rangos personalizados';
	}

	function blockingTitle(reason: AutoriaBlockingReason): string {
		if (reason === 'custom_mode_restricted') {
			return 'Esta autoría necesita reasignación por permisos';
		}
		return 'La estructura ha cambiado, vuelve a asignar la autoría';
	}

	function blockingText(reason: AutoriaBlockingReason): string {
		if (reason === 'custom_mode_restricted') {
			return 'Tu rol no puede editar rangos personalizados. Reasigna la autoría para continuar.';
		}
		return 'Se detectó un desajuste entre la estructura y los rangos de autoría guardados.';
	}

	function getAuthorIdsByRange(rangosAutoresInput: Tables<'rangos_autores'>[]): Map<string, string[]> {
		const map = new Map<string, string[]>();
		for (const row of rangosAutoresInput) {
			const current = map.get(row.rango_id) ?? [];
			if (!current.includes(row.autor_id)) {
				current.push(row.autor_id);
			}
			map.set(row.rango_id, current);
		}
		return map;
	}

	function initializeForms(
		rangosInput: Tables<'rangos'>[],
		rangosAutoresInput: Tables<'rangos_autores'>[],
		nextMode: Mode
	) {
		const authorIdsByRange = getAuthorIdsByRange(rangosAutoresInput);
		const sortedRanges = [...rangosInput].sort((a, b) => a.v_ini - b.v_ini);
		const firstRange = sortedRanges[0];

		obraCompleta = {
			autor_ids: firstRange ? [...(authorIdsByRange.get(firstRange.rango_id) ?? [])] : []
		};

		jornadaAssignments = jornadasCurrent.map((jornada: JornadaOption) => {
			const match = sortedRanges.find(
				(range) => range.v_ini === jornada.v_ini && range.v_fin === jornada.v_fin
			);
			return {
				jornada_id: jornada.jornada_id,
				autor_ids: match ? [...(authorIdsByRange.get(match.rango_id) ?? [])] : []
			};
		});

		customRanges = sortedRanges.map((range) => ({
			temp_id: range.rango_id,
			v_ini: range.v_ini,
			v_fin: range.v_fin,
			autor_ids: [...(authorIdsByRange.get(range.rango_id) ?? [])]
		}));

		mode = nextMode;
	}

	function resetModeData(nextMode: Mode) {
		if (nextMode === 'obra_completa') {
			obraCompleta = { autor_ids: [] };
			return;
		}
		if (nextMode === 'por_jornadas') {
			jornadaAssignments = jornadasCurrent.map((jornada: JornadaOption) => ({
				jornada_id: jornada.jornada_id,
				autor_ids: []
			}));
			return;
		}
		customRanges = [];
	}

	function modeHasChanged() {
		return mode !== sourceMode;
	}

	function clearQueuedSave() {
		if (timer) {
			clearTimeout(timer);
			timer = null;
		}
	}

	function buildComparableSnapshot(): string {
		const base = {
			mode,
			url_informe_autoria: normalizeUrl(urlInforme)
		};

		if (mode === 'obra_completa') {
			return JSON.stringify({
				...base,
				autor_ids: normalizeAuthorIds(obraCompleta.autor_ids)
			});
		}

		if (mode === 'por_jornadas') {
			const items = [...jornadaAssignments]
				.map((item) => ({
					jornada_id: item.jornada_id,
					autor_ids: normalizeAuthorIds(item.autor_ids)
				}))
				.sort((a, b) => a.jornada_id.localeCompare(b.jornada_id));
			return JSON.stringify({ ...base, items });
		}

		const items = [...customRanges]
			.map((item) => ({
				v_ini: Number(item.v_ini),
				v_fin: Number(item.v_fin),
				autor_ids: normalizeAuthorIds(item.autor_ids)
			}))
			.sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
		return JSON.stringify({ ...base, items });
	}

	function syncDirtyAndAutosave() {
		if (effectiveReadOnly) return;
		clearQueuedSave();
		const dirtyNow = buildComparableSnapshot() !== baselineSnapshot;
		setDirty(dirtyNow, 'autoria');
		if (!dirtyNow) {
			setSaving(false, 'autoria');
			return;
		}
		if (modeHasChanged() && !modeChangeConfirmed) {
			return;
		}
		if (requiresReassign && !reassignPrepared) {
			return;
		}
		timer = setTimeout(() => void save(), 10_000);
	}

	function requestModeChange(nextMode: Mode) {
		if (effectiveReadOnly || loadingAutoria || loadingFromServer || editingBlocked) return;
		if (nextMode === mode) return;
		if (nextMode === 'rango_personalizado' && !canUseCustomRanges) return;
		if (nextMode === sourceMode) {
			mode = sourceMode;
			modeChangeConfirmed = false;
			reassignPrepared = false;
			pendingMode = null;
			showModeChangeModal = false;
			initializeForms(rangos, rangosAutores, sourceMode);
			syncDirtyAndAutosave();
			return;
		}
		pendingMode = nextMode;
		showModeChangeModal = true;
	}

	function cancelModeChange() {
		pendingMode = null;
		showModeChangeModal = false;
	}

	function confirmModeChange() {
		if (effectiveReadOnly || !pendingMode) return;
		mode = pendingMode;
		resetModeData(pendingMode);
		modeChangeConfirmed = true;
		if (requiresReassign) {
			reassignPrepared = true;
		}
		showModeChangeModal = false;
		pendingMode = null;
		syncDirtyAndAutosave();
	}

	function openReassignModal() {
		if (effectiveReadOnly || loadingAutoria || loadingFromServer) return;
		showReassignModal = true;
	}

	function cancelReassign() {
		showReassignModal = false;
	}

	function confirmReassign() {
		if (effectiveReadOnly) return;
		mode = defaultReassignMode;
		resetModeData(defaultReassignMode);
		modeChangeConfirmed = defaultReassignMode !== sourceMode;
		reassignPrepared = true;
		showReassignModal = false;
		syncDirtyAndAutosave();
	}

	function setObraCompletaAuthors(ids: string[]) {
		obraCompleta = {
			...obraCompleta,
			autor_ids: ids
		};
		syncDirtyAndAutosave();
	}

	function setJornadaAuthors(jornadaId: string, ids: string[]) {
		jornadaAssignments = jornadaAssignments.map((item) =>
			item.jornada_id === jornadaId ? { ...item, autor_ids: ids } : item
		);
		syncDirtyAndAutosave();
	}

	function setCustomRangeAuthors(tempId: string, ids: string[]) {
		customRanges = customRanges.map((item) =>
			item.temp_id === tempId ? { ...item, autor_ids: ids } : item
		);
		syncDirtyAndAutosave();
	}

	function updateCustomRange(tempId: string, patch: Partial<CustomRange>) {
		customRanges = customRanges.map((item) =>
			item.temp_id === tempId ? { ...item, ...patch } : item
		);
		syncDirtyAndAutosave();
	}

	function addCustomRange() {
		const sorted = [...customRanges].sort((a, b) => a.v_ini - b.v_ini);
		const nextStart = (sorted.at(-1)?.v_fin ?? 0) + 1;
		customRanges = [
			...customRanges,
			{
				temp_id: `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
				v_ini: nextStart,
				v_fin: nextStart + 10,
				autor_ids: []
			}
		];
		syncDirtyAndAutosave();
	}

	function removeCustomRange(tempId: string) {
		customRanges = customRanges.filter((item) => item.temp_id !== tempId);
		syncDirtyAndAutosave();
	}

	function buildPayload() {
		const normalizedUrl = normalizeUrl(urlInforme) || null;
		const modeChanged = modeHasChanged();
		const confirmModeChangePayload = modeChanged ? modeChangeConfirmed : false;
		const confirmReassignPayload = requiresReassign ? reassignPrepared : false;

		if (mode === 'obra_completa') {
			return {
				mode,
				source_mode: sourceMode,
				confirm_mode_change: confirmModeChangePayload,
				confirm_reassign: confirmReassignPayload,
				url_informe_autoria: normalizedUrl,
				autor_ids: obraCompleta.autor_ids
			};
		}

		if (mode === 'por_jornadas') {
			return {
				mode,
				source_mode: sourceMode,
				confirm_mode_change: confirmModeChangePayload,
				confirm_reassign: confirmReassignPayload,
				url_informe_autoria: normalizedUrl,
				items: jornadaAssignments.map((item) => ({
					jornada_id: item.jornada_id,
					autor_ids: item.autor_ids
				}))
			};
		}

		return {
			mode,
			source_mode: sourceMode,
			confirm_mode_change: confirmModeChangePayload,
			confirm_reassign: confirmReassignPayload,
			url_informe_autoria: normalizedUrl,
			items: customRanges.map((item) => ({
				v_ini: Number(item.v_ini),
				v_fin: Number(item.v_fin),
				autor_ids: item.autor_ids
			}))
		};
	}

	function validateClientPayload() {
		if (requiresReassign && !reassignPrepared) {
			return 'La estructura ha cambiado o el modo actual no es editable para tu rol. Pulsa "Reasignar autoría" antes de guardar.';
		}

		if (modeHasChanged() && !modeChangeConfirmed) {
			return 'Confirma el cambio de opción antes de guardar.';
		}

		if (mode === 'rango_personalizado' && !canUseCustomRanges) {
			return 'Tu rol no puede usar rangos personalizados.';
		}

		if (mode === 'obra_completa') {
			if (obraCompleta.autor_ids.length === 0) {
				return 'Selecciona al menos un autor para la obra completa.';
			}
			return null;
		}

		if (mode === 'por_jornadas') {
			if (jornadaAssignments.length === 0) {
				return 'No hay jornadas disponibles para asignar autoría.';
			}
			for (const jornada of jornadaAssignments) {
				if (jornada.autor_ids.length === 0) {
					return `Faltan autores en ${jornadaMap.get(jornada.jornada_id) ?? 'una jornada'}.`;
				}
			}
			return null;
		}

		if (customRanges.length === 0) {
			return 'Debes definir al menos un rango personalizado.';
		}
		for (const range of customRanges) {
			if (!Number.isFinite(range.v_ini) || !Number.isFinite(range.v_fin) || range.v_ini >= range.v_fin) {
				return 'Hay rangos con versos inválidos.';
			}
			if (range.autor_ids.length === 0) {
				return 'Todos los rangos deben tener al menos un autor.';
			}
		}
		const sorted = [...customRanges].sort((a, b) => a.v_ini - b.v_ini);
		for (let i = 1; i < sorted.length; i += 1) {
			if (sorted[i].v_ini <= sorted[i - 1].v_fin) {
				return 'Hay rangos solapados. Ajusta los versos para continuar.';
			}
		}
		return null;
	}

	function applyServerState(payload: AutoriaApiPayload) {
		jornadasCurrent = [...payload.jornadas];
		autoresCurrent = payload.autores.map((author) => ({
			autor_id: author.autor_id,
			nombre_completo: author.nombre_completo
		}));
		rangos = [...payload.rangos];
		rangosAutores = [...payload.rangosAutores];
		urlInforme = payload.obra.url_informe_autoria ?? '';
		sourceMode = payload.mode;
		mode = payload.mode;
		modeChangeConfirmed = false;
		reassignPrepared = false;
		pendingMode = null;
		showModeChangeModal = false;
		integrity = payload.integrity;
		canUseCustomRanges = payload.can_use_custom_ranges;
		requiresReassign = payload.requires_reassign;
		blockingReason = payload.blocking_reason;
		defaultReassignMode = payload.default_reassign_mode;

		patchCurrentObra({
			total_versos: payload.obra.total_versos ?? null,
			url_informe_autoria: payload.obra.url_informe_autoria,
			autoria: payload.obra.autoria ?? null
		});

		initializeForms(payload.rangos, payload.rangosAutores, payload.mode);
		baselineSnapshot = buildComparableSnapshot();
		setDirty(false, 'autoria');
		setSaving(false, 'autoria');

		if (requiresReassign && !effectiveReadOnly) {
			showReassignModal = true;
		} else {
			showReassignModal = false;
		}
	}

	async function refreshFromServer(silent = false) {
		if (loadingFromServer) return;
		loadingFromServer = true;
		const response = await fetch(`/api/obras/${props.obraId}/autoria`);
		loadingFromServer = false;
		loadingAutoria = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			loadError = body?.message ?? 'No se pudo cargar la autoría actual de la obra.';
			if (!silent) {
				pushToast('error', loadError ?? 'No se pudo cargar la autoría actual de la obra.');
			}
			return;
		}

		loadError = null;
		const payload = (await response.json()) as AutoriaApiPayload;
		applyServerState(payload);
	}

	async function save() {
		if (effectiveReadOnly || loadingAutoria || loadingFromServer || editingBlocked) return;
		if (savingNow) return;
		const clientError = validateClientPayload();
		if (clientError) {
			pushToast('error', clientError);
			setSaving(false, 'autoria');
			return;
		}

		savingNow = true;
		setSaving(true, 'autoria');
		const response = await fetch(`/api/obras/${props.obraId}/autoria`, {
			method: 'PUT',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(buildPayload())
		});
		savingNow = false;

		if (!response.ok) {
			setSaving(false, 'autoria');
			const body = await response.json().catch(() => ({}));
			const detail = Array.isArray(body?.details) ? body.details[0]?.message : null;
			if (body?.integrity) {
				integrity = body.integrity as AutoriaIntegrity;
			}
			if (typeof body?.requires_reassign === 'boolean') {
				requiresReassign = body.requires_reassign;
			}
			if (typeof body?.blocking_reason === 'string' || body?.blocking_reason === null) {
				blockingReason = body.blocking_reason as AutoriaBlockingReason;
			}
			if (response.status === 409) {
				pushToast(
					'error',
					detail ?? body.message ?? 'La autoría cambió en paralelo o requiere confirmación antes de guardar.'
				);
				return;
			}
			pushToast('error', detail ?? body.message ?? 'No se pudo guardar la autoría.');
			return;
		}

		const payload = (await response.json()) as AutoriaApiPayload;
		applyServerState(payload);
		markSaved('autoria');
		pushToast('success', 'Autoría guardada');
	}

	onMount(() => {
		void refreshFromServer(true);
	});

	onDestroy(() => {
		clearQueuedSave();
	});
</script>

<section class="space-y-4">
	<div class="flex justify-end">
		<Button
			variant="success"
			onclick={save}
			disabled={savingNow || effectiveReadOnly || loadingFromServer || loadingAutoria || editingBlocked}
		>
			{savingNow ? 'Guardando...' : 'Guardar'}
		</Button>
	</div>

	{#if loadingAutoria}
		<div class="card p-4">
			<div class="animate-pulse space-y-3">
				<div class="h-5 w-40 border border-[color:var(--border)] bg-[color:var(--muted)]"></div>
				<div class="h-10 border border-[color:var(--border)] bg-[color:var(--muted)]"></div>
				<div class="h-10 border border-[color:var(--border)] bg-[color:var(--muted)]"></div>
			</div>
		</div>
	{:else if loadError}
		<div class="card p-4">
			<p class="text-sm text-[color:var(--danger)]">{loadError}</p>
			<div class="mt-3">
				<Button variant="secondary" onclick={() => void refreshFromServer(false)} disabled={loadingFromServer}>
					Reintentar
				</Button>
			</div>
		</div>
	{:else}
		<div class="card p-4">
			<div class="mb-3 flex flex-wrap items-center justify-between gap-3">
				<div>
					<h2 class="text-xl font-semibold">Autoría</h2>
				</div>
			</div>

			{#if legacySplitReadOnly}
				<div class="mb-3 border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
					Esta obra tiene autoría fragmentada; solo admin puede modificar esta distribución.
				</div>
			{/if}

			{#if editingBlocked}
				<div class="border border-amber-200 bg-amber-50 p-3 text-sm text-amber-900">
					<p class="font-medium">{blockingTitle(blockingReason)}</p>
					<p class="mt-1">{blockingText(blockingReason)}</p>
					<p class="mt-2">
						Distribución detectada en DB: <strong>{modeLabel(sourceMode)}</strong>
					</p>
					{#if integrity && integrity.details.length > 0}
						<ul class="mt-2 list-disc pl-5">
							{#each integrity.details as detail}
								<li>{detail}</li>
							{/each}
						</ul>
					{/if}
					{#if !effectiveReadOnly}
						<div class="mt-3">
							<Button variant="secondary" onclick={openReassignModal} disabled={loadingFromServer}>
								Reasignar autoría
							</Button>
						</div>
					{/if}
				</div>
			{:else}
				{#if canShowAllModes}
					<label class="block text-sm">
					<span class="mb-1 block">Selecciona cómo se distribuye la autoría en la obra</span>
					<CheckDropdown
							multiple={false}
							search={false}
							placeholder="Seleccionar modo"
							items={modeDropdownItems}
							disabled={effectiveReadOnly || loadingFromServer}
							selectedIds={[mode]}
							onChange={(ids) => {
								const nextMode = ids[0] as Mode | undefined;
								if (!nextMode) return;
								requestModeChange(nextMode);
							}}
						/>
					</label>
				{:else}
					<div class="block text-sm">
						<span class="mb-1 block">Modo de autoria</span>
						<div class="w-full rounded-md border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2">
							Obra completa
						</div>
						{#if sourceMode !== 'obra_completa'}
							<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">
								Distribucion detectada en DB: <strong>{modeLabel(sourceMode)}</strong>.
							</p>
						{/if}
					</div>
				{/if}

				<label class="mt-4 block text-sm">
					<span class="mb-1 block">URL informe ETSO</span>
					<input
						type="url"
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						disabled={effectiveReadOnly || loadingFromServer}
						value={urlInforme}
						oninput={(event) => {
							urlInforme = event.currentTarget.value;
							syncDirtyAndAutosave();
						}}
					/>
				</label>
			{/if}
		</div>

		{#if !editingBlocked}
			<div class="card p-4">
				<h3 class="mb-3 text-lg font-semibold">Autores</h3>

				{#if mode === 'obra_completa'}
					<div class="space-y-3">
						<div class="block text-sm">
							<span class="mb-1 block">Autores de la obra</span>
							<AuthorSelector
								authors={authorOptions}
								selectedIds={obraCompleta.autor_ids}
								onChange={setObraCompletaAuthors}
								placeholder="Escribe y selecciona autores"
								disabled={effectiveReadOnly || loadingFromServer}
							/>
						</div>
					</div>
				{:else if mode === 'por_jornadas'}
					<div class="space-y-3">
						{#if jornadaAssignments.length === 0}
							<p class="text-sm text-[color:var(--muted-foreground)]">No hay jornadas definidas.</p>
						{:else}
							{#each jornadaAssignments as assignment}
								<article class="border border-[color:var(--border)] bg-white p-3">
									<div class="mb-2 text-sm font-medium">
										{jornadaMap.get(assignment.jornada_id) ?? assignment.jornada_id}
									</div>
									<div class="block text-sm">
										<span class="mb-1 block">Autores</span>
										<AuthorSelector
											authors={authorOptions}
											selectedIds={assignment.autor_ids}
											onChange={(ids) => setJornadaAuthors(assignment.jornada_id, ids)}
											placeholder="Escribe y selecciona autores"
											disabled={effectiveReadOnly || loadingFromServer}
										/>
									</div>
								</article>
							{/each}
						{/if}
					</div>
				{:else}
					<div class="space-y-3">
						<div class="flex flex-wrap justify-end gap-2">
							<Button variant="secondary" onclick={addCustomRange} disabled={effectiveReadOnly || loadingFromServer}>
								Añadir rango
							</Button>
						</div>
						{#if customRanges.length === 0}
							<p class="text-sm text-[color:var(--muted-foreground)]">No hay rangos definidos.</p>
						{:else}
							{#each customRanges as range}
								<article class="border border-[color:var(--border)] bg-white p-3">
									<div class="mb-3 flex justify-between gap-2">
										<div class="grid w-full grid-cols-2 gap-2 sm:grid-cols-4">
											<label class="text-sm">
												<span class="mb-1 block">V_ini</span>
												<input
													type="number"
													class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
													disabled={effectiveReadOnly || loadingFromServer}
													value={range.v_ini}
													oninput={(event) =>
														updateCustomRange(range.temp_id, { v_ini: Number(event.currentTarget.value) })}
												/>
											</label>
											<label class="text-sm">
												<span class="mb-1 block">V_fin</span>
												<input
													type="number"
													class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
													disabled={effectiveReadOnly || loadingFromServer}
													value={range.v_fin}
													oninput={(event) =>
														updateCustomRange(range.temp_id, { v_fin: Number(event.currentTarget.value) })}
												/>
											</label>
										</div>
										<Button
											variant="danger"
											onclick={() => removeCustomRange(range.temp_id)}
											disabled={effectiveReadOnly || loadingFromServer}
										>
											Eliminar
										</Button>
									</div>

									<div class="grid gap-3 md:grid-cols-2">
										<div class="block text-sm">
											<span class="mb-1 block">Autores</span>
											<AuthorSelector
												authors={authorOptions}
												selectedIds={range.autor_ids}
												onChange={(ids) => setCustomRangeAuthors(range.temp_id, ids)}
												placeholder="Escribe y selecciona autores"
												disabled={effectiveReadOnly || loadingFromServer}
											/>
										</div>
									</div>
								</article>
							{/each}
						{/if}
					</div>
				{/if}
			</div>
		{/if}
	{/if}
</section>

{#if showModeChangeModal && pendingMode}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4">
		<div class="w-full max-w-lg border border-[color:var(--border)] bg-white p-4">
			<h3 class="text-lg font-semibold">Confirmar cambio de opción</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				Cambiar de opción borrará la asignación actual de autores/rangos en el formulario.
			</p>
			<p class="mt-2 text-sm">
				Nueva opción: <strong>{modeLabel(pendingMode)}</strong>
			</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={cancelModeChange}>Cancelar</Button>
				<Button variant="danger" onclick={confirmModeChange}>Confirmar cambio</Button>
			</div>
		</div>
	</div>
{/if}

{#if showReassignModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/45 p-4">
		<div class="w-full max-w-lg border border-[color:var(--border)] bg-white p-4">
			<h3 class="text-lg font-semibold">Reasignar autoría</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{blockingTitle(blockingReason)}</p>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">{blockingText(blockingReason)}</p>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				Se limpiará el borrador local y se abrirá <strong>{modeLabel(defaultReassignMode)}</strong> para volver a asignar.
			</p>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={cancelReassign}>Ahora no</Button>
				<Button variant="danger" onclick={confirmReassign}>Reasignar</Button>
			</div>
		</div>
	</div>
{/if}

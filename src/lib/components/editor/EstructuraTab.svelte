<script lang="ts">
	import { browser } from '$app/environment';
	import { onDestroy, untrack } from 'svelte';
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import { pushToast } from '$lib/stores/toast';

	const props = $props<{
		obraId: string;
		jornadasInitial: Tables<'jornadas'>[];
		cuadrosInitial: Tables<'cuadros'>[];
		readOnly?: boolean;
		canComment?: boolean;
		focusJornadaId?: string | null;
		focusCuadroId?: string | null;
		focusComentarioId?: string | null;
		onStructureChange?: (payload: {
			jornadas: Tables<'jornadas'>[];
			cuadros: Tables<'cuadros'>[];
		}) => void;
	}>();

	let jornadas = $state(untrack(() => [...props.jornadasInitial]));
	let cuadros = $state(untrack(() => [...props.cuadrosInitial]));

	type SidebarMode = 'jornada-new' | 'jornada-edit' | 'cuadro-new' | 'cuadro-edit' | null;
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
	let showCloseWithoutSavingModal = $state(false);

	let sidebarSaving = $state(false);
	let sidebarDirty = $state(false);
	let sidebarBaselineSnapshot = $state('');
	let autosaveErrorShown = $state(false);
	let lastSidebarSnapshot = $state('');
	let autosaveTimer: ReturnType<typeof setTimeout> | null = null;
	let handledFocusTarget = $state<string | null>(null);

	let jornadaForm = $state({
		jornada_num: untrack(() => props.jornadasInitial.length + 1),
		v_ini: 1,
		v_fin: 2
	});

	let cuadroForm = $state({
		jornada_id: untrack(() => props.jornadasInitial[0]?.jornada_id ?? ''),
		cuadro_num: 1,
		v_ini: untrack(() => props.jornadasInitial[0]?.v_ini ?? 1),
		v_fin: untrack(() => props.jornadasInitial[0]?.v_fin ?? 2)
	});

	function sortByVIni<T extends { v_ini: number }>(items: T[]): T[] {
		return [...items].sort((a, b) => a.v_ini - b.v_ini);
	}
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

	function clearAutosaveTimer() {
		if (!autosaveTimer) return;
		clearTimeout(autosaveTimer);
		autosaveTimer = null;
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

	function setSidebarBaselineFromCurrent() {
		sidebarBaselineSnapshot = sidebarSnapshot();
		sidebarDirty = false;
		autosaveErrorShown = false;
		lastSidebarSnapshot = sidebarBaselineSnapshot;
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

	function handleAutosaveError(message: string) {
		if (autosaveErrorShown) return;
		autosaveErrorShown = true;
		pushToast('error', message);
	}

	async function persistJornada(source: 'manual' | 'autosave') {
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
			if (source === 'manual') {
				pushToast('error', message);
			} else {
				handleAutosaveError(message);
			}
			return false;
		}

		const result = await response.json();
		const savedJornada = result.jornada as Tables<'jornadas'>;

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
		setSidebarBaselineFromCurrent();
		if (source === 'manual') {
			pushToast('success', wasEditing ? 'Jornada actualizada' : 'Jornada creada');
		}
		return true;
	}

	async function persistCuadro(source: 'manual' | 'autosave') {
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
			if (source === 'manual') {
				pushToast('error', message);
			} else {
				handleAutosaveError(message);
			}
			return false;
		}

		const result = await response.json();
		const savedCuadro = result.cuadro as Tables<'cuadros'>;

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
		setSidebarBaselineFromCurrent();
		if (source === 'manual') {
			pushToast('success', wasEditing ? 'Cuadro actualizado' : 'Cuadro creado');
		}
		return true;
	}

	async function saveSidebar(source: 'manual' | 'autosave' = 'manual') {
		if (props.readOnly || sidebarSaving || !sidebarMode) return;
		const showToast = source === 'manual';
		if (!isSidebarFormValid(showToast)) return;

		sidebarSaving = true;
		const ok =
			sidebarMode === 'jornada-new' || sidebarMode === 'jornada-edit'
				? await persistJornada(source)
				: await persistCuadro(source);
		sidebarSaving = false;

		if (!ok) return;
		autosaveErrorShown = false;
	}

	function openNewJornada() {
		if (props.readOnly) return;
		editingJornadaId = null;
		editingCuadroId = null;
		resetJornadaForm();
		sidebarMode = 'jornada-new';
		setSidebarBaselineFromCurrent();
		showCloseWithoutSavingModal = false;
	}

	function openEditJornada(jornada: Tables<'jornadas'>) {
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
		showCloseWithoutSavingModal = false;
	}

	function openNewCuadro(jornada: Tables<'jornadas'>) {
		if (props.readOnly) return;
		editingJornadaId = null;
		editingCuadroId = null;
		resetCuadroForm(jornada.jornada_id);
		sidebarMode = 'cuadro-new';
		setSidebarBaselineFromCurrent();
		showCloseWithoutSavingModal = false;
	}

	function openEditCuadro(cuadro: Tables<'cuadros'>) {
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
		showCloseWithoutSavingModal = false;
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
		clearAutosaveTimer();
		sidebarMode = null;
		editingJornadaId = null;
		editingCuadroId = null;
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

	function openDeleteJornada(jornada: Tables<'jornadas'>) {
		if (props.readOnly) return;
		deleteTarget = {
			kind: 'jornada',
			id: jornada.jornada_id,
			title: `Eliminar Jornada ${jornada.jornada_num}`,
			description: 'Se eliminarán también los cuadros asociados.'
		};
	}

	function openDeleteCuadro(cuadro: Tables<'cuadros'>) {
		if (props.readOnly) return;
		deleteTarget = {
			kind: 'cuadro',
			id: cuadro.cuadro_id,
			title: `Eliminar Cuadro ${cuadro.cuadro_num}`,
			description: 'Esta acción no se puede deshacer.'
		};
	}

	async function confirmDelete() {
		if (props.readOnly || !deleteTarget) return;
		const target = deleteTarget;

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
		const saving = sidebarSaving;
		const trackJornada = `${jornadaForm.jornada_num}|${jornadaForm.v_ini}|${jornadaForm.v_fin}`;
		const trackCuadro = `${cuadroForm.jornada_id}|${cuadroForm.cuadro_num}|${cuadroForm.v_ini}|${cuadroForm.v_fin}`;
		void trackJornada;
		void trackCuadro;

		if (!mode || readOnly) {
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

		if (saving) {
			return;
		}

		if (!isSidebarFormValid(false)) {
			clearAutosaveTimer();
			return;
		}

		clearAutosaveTimer();
		autosaveTimer = setTimeout(() => {
			void saveSidebar('autosave');
		}, 10_000);
	});

	onDestroy(() => {
		clearAutosaveTimer();
	});
</script>

<section class="space-y-4">
	<div class="flex items-center justify-between">
		<h2 class="text-xl font-semibold">Jornadas y cuadros</h2>
	</div>

	{#each sortByVIni(jornadas) as jornada}
		<article class="card p-4">
			<div class="mb-3 flex items-center justify-between gap-2">
				<h3 class="text-lg font-semibold">
					Jornada {jornada.jornada_num} (vv. {jornada.v_ini}-{jornada.v_fin})
				</h3>
				<div class="flex gap-2">
					<Button
						variant="ghost"
						onclick={() => openEditJornada(jornada)}
						disabled={props.readOnly && !props.canComment}
						>{props.readOnly ? 'Ver' : 'Editar'}</Button
					>
					<Button variant="danger" onclick={() => openDeleteJornada(jornada)} disabled={props.readOnly}
						>Eliminar</Button
					>
				</div>
			</div>

			<div class="mb-2 text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">Cuadros</div>

			<div class="space-y-2">
				{#if getCuadros(jornada.jornada_id).length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin cuadros en esta jornada.</p>
				{:else}
					{#each getCuadros(jornada.jornada_id) as cuadro}
						<div class="border border-[color:var(--border)] bg-white p-3">
							<div class="flex items-start justify-between gap-2">
								<div>
									<div class="font-medium">
										Cuadro {cuadro.cuadro_num}: vv. {cuadro.v_ini}-{cuadro.v_fin}
									</div>
								</div>
								<div class="flex gap-2">
									<Button
										variant="ghost"
										onclick={() => openEditCuadro(cuadro)}
										disabled={props.readOnly && !props.canComment}
										>{props.readOnly ? 'Ver' : 'Editar'}</Button
									>
									<Button variant="danger" onclick={() => openDeleteCuadro(cuadro)} disabled={props.readOnly}
										>Eliminar</Button
									>
								</div>
							</div>
						</div>
					{/each}
				{/if}
			</div>

			<div class="mt-3">
				<Button variant="primary-soft" onclick={() => openNewCuadro(jornada)} disabled={props.readOnly}
					>Añadir cuadro</Button
				>
			</div>
		</article>
	{/each}

	<div class="flex justify-start">
		<Button variant="primary-soft" onclick={openNewJornada} disabled={props.readOnly}>Añadir jornada</Button>
	</div>
</section>

{#if sidebarMode}
	<aside class="fixed right-0 top-0 z-40 h-screen w-full max-w-xl overflow-y-auto border-l border-[color:var(--border)] bg-[color:var(--gray-50)] p-5">
		<div class="sticky top-0 z-10 mb-4 flex items-center justify-between gap-3 bg-[color:var(--gray-50)] pb-3">
			<h3 class="text-lg font-semibold">
				{#if sidebarMode === 'jornada-new'}Nueva jornada{/if}
				{#if sidebarMode === 'jornada-edit'}{props.readOnly ? 'Ver jornada' : 'Editar jornada'}{/if}
				{#if sidebarMode === 'cuadro-new'}Nuevo cuadro{/if}
				{#if sidebarMode === 'cuadro-edit'}{props.readOnly ? 'Ver cuadro' : 'Editar cuadro'}{/if}
			</h3>
			<div class="flex items-center gap-2">
				<Button variant="secondary" onclick={requestCloseSidebar}>Cerrar</Button>
				{#if !props.readOnly}
					<Button variant="success" onclick={() => void saveSidebar('manual')} disabled={sidebarSaving}>
						{sidebarSaving ? 'Guardando...' : 'Guardar'}
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
				<Button variant="secondary" onclick={() => (deleteTarget = null)}>Cancelar</Button>
				<Button variant="danger" onclick={confirmDelete} disabled={props.readOnly}>Eliminar</Button>
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


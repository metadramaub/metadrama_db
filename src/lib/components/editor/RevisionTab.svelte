<script lang="ts">
	import { goto } from '$app/navigation';
	import { onDestroy, onMount } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { currentObraStore, patchCurrentObra } from '$lib/stores/currentObra';
	import { canTransitionState } from '$lib/utils/permissions';
	import type { Tables } from '$lib/types/database.types';
	import type {
		EditorProfile,
		ObraAccessFlags,
		ObraAssignmentsInput,
		ObraAssignmentsResponse
	} from '$lib/types/obra.types';

	type EstadoOption = Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>;

	const props = $props<{
		obraId: string;
		obra: Tables<'obras'>;
		profile: EditorProfile;
		estadoTerm: string;
		estadoOptions: EstadoOption[];
		jornadas: Tables<'jornadas'>[];
		cuadros: Tables<'cuadros'>[];
		secuencias: Tables<'secuencias_metricas'>[];
		rangos: Tables<'rangos'>[];
		editorAsignadoNombre: string | null;
		assignedReviewer: boolean;
		capabilities: ObraAccessFlags;
		onPendingChangesChange?: (pending: boolean) => void;
	}>();

	const obraLive = $derived(($currentObraStore.obra ?? props.obra) as Tables<'obras'>);

	let currentEstadoId = $state(props.obra.estado);
	let persistedEstadoId = $state(props.obra.estado);
	let estadoComentario = $state('');
	let estadoConfirmComentario = $state('');
	let pendingEstadoId = $state<string | null>(null);
	let showEstadoConfirmModal = $state(false);
	let visiblePublico = $state(Boolean(props.obra.visible_publico));
	let persistedVisiblePublico = $state(Boolean(props.obra.visible_publico));
	let commentsDraftDirty = $state(false);
	let commentsReloadKey = $state(0);

	let stateSaving = $state(false);
	let visibilitySaving = $state(false);
	let reviewersLoading = $state(false);
	let reviewersSaving = $state(false);

	let editorOptions = $state<ObraAssignmentsResponse['editorOptions']>([]);
	let reviewerCandidates = $state<ObraAssignmentsResponse['candidates']>([]);
	let assignedReviewers = $state<ObraAssignmentsResponse['assigned']>([]);
	let assignmentEditorId = $state('');
	let assignmentReviewerIds = $state<string[]>([]);
	let baselineEditorId = $state('');
	let baselineReviewerIds = $state<string[]>([]);
	let showAssignmentsConfirmModal = $state(false);

	let deletingObra = $state(false);
	let deleteConfirmText = $state('');
	let showDeleteModal = $state(false);

	const canToggleVisible = $derived(Boolean(props.capabilities.canToggleVisibility));
	const canManageAssignments = $derived(Boolean(props.capabilities.canManageReviewers));
	const canComment = $derived(Boolean(props.capabilities.canComment));
	const canChangeState = $derived(Boolean(props.capabilities.canChangeState));
	const canDeleteObra = $derived(Boolean(props.capabilities.canDeleteObra));
	const isEditorRole = $derived(props.profile.roleTerm === 'editor');
	const isAssignedEditor = $derived(obraLive.editor_asignado === props.profile.userId);
	const deleteConfirmed = $derived(deleteConfirmText.trim() === 'ELIMINAR');

	const checklist = $derived.by(() => {
		const secuenciasTotales = props.secuencias.length;
		return [
			{
				label: 'Datos básicos completos',
				done: Boolean(obraLive.titulo?.trim() && obraLive.genero_id && obraLive.edicion?.trim()),
				detail: ''
			},
			{
				label: 'Estructura definida',
				done: props.jornadas.length > 0,
				detail: `${props.jornadas.length} jornadas, ${props.cuadros.length} cuadros`
			},
			{
				label: 'Secuencias métricas registradas',
				done: secuenciasTotales > 0,
				detail: `${secuenciasTotales} secuencias`
			},
			{
				label: 'Autoría asignada',
				done: (obraLive.autoria ?? []).length > 0,
				detail: `${(obraLive.autoria ?? []).length} autores`
			},
			{
				label: 'Observaciones de obra',
				done: (obraLive.observaciones ?? '').trim().length > 100,
				detail: `${(obraLive.observaciones ?? '').trim().length} caracteres`
			},
			{
				label: 'Bibliografía añadida',
				done: (obraLive.bibliografia ?? '').trim().length > 0,
				detail: `${(obraLive.bibliografia ?? '').trim().length} caracteres`
			}
		];
	});

	const estadoDropdownItems = $derived(
		props.estadoOptions.map((option: EstadoOption) => ({
			id: option.termino_id,
			label: option.termino,
			description: null
		}))
	);
	const estadoTermById = $derived(
		new Map(
			props.estadoOptions.map((option: EstadoOption) => [
				option.termino_id,
				option.termino.trim().toLowerCase()
			])
		)
	);
	const persistedEstadoTerm = $derived(
		estadoTermById.get(persistedEstadoId) ?? props.estadoTerm.trim().toLowerCase()
	);
	const estadoDisabledIds = $derived.by(() => {
		if (!canChangeState) {
			return props.estadoOptions.map((option: EstadoOption) => option.termino_id);
		}
		return props.estadoOptions
			.filter(
				(option: EstadoOption) =>
					!canTransitionState(props.profile.roleTerm, persistedEstadoTerm, option.termino, {
						assignedEditor: isAssignedEditor,
						assignedReviewer: props.assignedReviewer
					})
			)
			.map((option: EstadoOption) => option.termino_id);
	});

	const selectedEstadoLabel = $derived(
		props.estadoOptions.find((option: EstadoOption) => option.termino_id === currentEstadoId)?.termino ?? '--'
	);

	const persistedEstadoLabel = $derived(
		props.estadoOptions.find((option: EstadoOption) => option.termino_id === persistedEstadoId)?.termino ?? '--'
	);
	const stateDirty = $derived(currentEstadoId.trim() !== persistedEstadoId.trim());
	const visibilityDirty = $derived(visiblePublico !== persistedVisiblePublico);

	function normalizeIds(ids: string[]): string[] {
		return [...new Set(ids)].sort((a, b) => a.localeCompare(b));
	}

	function sanitizeIds(ids: string[]): string[] {
		return normalizeIds(
			ids
				.map((id) => id.trim())
				.filter((id) => id.length > 0)
		);
	}

	function getUserName(userId: string | null): string {
		if (!userId) return 'Sin asignar';
		const directEditor = editorOptions.find((item) => item.user_id === userId);
		if (directEditor) return directEditor.nombre_completo;
		const candidate = reviewerCandidates.find((item) => item.user_id === userId);
		if (candidate) return candidate.nombre_completo;
		return userId;
	}

	const assignmentEditorLabel = $derived(getUserName(assignmentEditorId || null));
	const baselineEditorLabel = $derived(getUserName(baselineEditorId || null));

	const editorDropdownItems = $derived(
		editorOptions.map((item) => ({
			id: item.user_id,
			label: item.nombre_completo,
			description: item.email
		}))
	);

	const reviewerDropdownItems = $derived(
		reviewerCandidates.map((item) => ({
			id: item.user_id,
			label: item.nombre_completo,
			description: item.email
		}))
	);

	const editorDisabledIds = $derived(normalizeIds(assignmentReviewerIds));
	const reviewerDisabledIds = $derived(assignmentEditorId ? [assignmentEditorId] : []);

	const normalizedReviewerIds = $derived(normalizeIds(assignmentReviewerIds));
	const normalizedBaselineReviewerIds = $derived(normalizeIds(baselineReviewerIds));
	const assignmentsDirty = $derived(
		assignmentEditorId !== baselineEditorId ||
			JSON.stringify(normalizedReviewerIds) !== JSON.stringify(normalizedBaselineReviewerIds)
	);
	const revisionPendingChanges = $derived(
		assignmentsDirty || stateDirty || visibilityDirty || commentsDraftDirty
	);

	const addedReviewerIds = $derived(
		normalizedReviewerIds.filter((id) => !normalizedBaselineReviewerIds.includes(id))
	);
	const removedReviewerIds = $derived(
		normalizedBaselineReviewerIds.filter((id) => !normalizedReviewerIds.includes(id))
	);

	const selectedReviewersSummary = $derived(
		normalizedReviewerIds.map((id) => ({ id, name: getUserName(id) }))
	);

	function applyAssignmentsPayload(payload: Partial<ObraAssignmentsResponse> & { editorAsignado?: string | null }) {
		editorOptions = payload.editorOptions ?? [];
		reviewerCandidates = payload.candidates ?? [];
		assignedReviewers = payload.assigned ?? [];

		const nextEditorRaw = payload.editor_asignado ?? payload.editorAsignado ?? '';
		const nextEditor = nextEditorRaw.trim();
		const candidateSelectedIds = (payload.candidates ?? [])
			.filter((item) => item.selected)
			.map((item) => item.user_id);
		const assignedIds = (payload.assigned ?? []).map((item) => item.revisor_id);
		const nextReviewers = sanitizeIds(candidateSelectedIds.length > 0 ? candidateSelectedIds : assignedIds).filter(
			(id) => id !== nextEditor
		);

		assignmentEditorId = nextEditor;
		assignmentReviewerIds = nextReviewers;
		baselineEditorId = nextEditor;
		baselineReviewerIds = nextReviewers;
	}

	async function loadReviewers() {
		reviewersLoading = true;
		const response = await fetch(`/api/obras/${props.obraId}/revisores`);
		reviewersLoading = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudieron cargar las asignaciones editoriales.');
			return;
		}
		const payload = (await response.json()) as ObraAssignmentsResponse & { editorAsignado?: string | null };
		applyAssignmentsPayload(payload);
	}

	function onEditorSelectionChange(ids: string[]) {
		if (!canManageAssignments) return;
		const nextEditorId = ids[0] ?? '';
		assignmentEditorId = nextEditorId;
		if (nextEditorId && assignmentReviewerIds.includes(nextEditorId)) {
			assignmentReviewerIds = assignmentReviewerIds.filter((id) => id !== nextEditorId);
		}
	}

	function onReviewerSelectionChange(ids: string[]) {
		if (!canManageAssignments) return;
		assignmentReviewerIds = sanitizeIds(ids.filter((id) => id !== assignmentEditorId));
	}

	function onEstadoSelectionChange(ids: string[]) {
		if (!canChangeState) return;
		const nextEstadoId = (ids[0] ?? '').trim();
		if (!nextEstadoId) return;
		if (estadoDisabledIds.includes(nextEstadoId)) return;
		currentEstadoId = nextEstadoId;
	}

	function onCommentsDraftDirtyChange(dirty: boolean) {
		commentsDraftDirty = dirty;
	}

	function openAssignmentsConfirmModal() {
		if (!canManageAssignments || reviewersSaving || reviewersLoading) return;
		if (!assignmentsDirty) {
			pushToast('info', 'No hay cambios pendientes en las asignaciones.');
			return;
		}
		if (!assignmentEditorId) {
			pushToast('error', 'Debes seleccionar un editor antes de guardar asignaciones.');
			return;
		}
		showAssignmentsConfirmModal = true;
	}

	function closeAssignmentsConfirmModal() {
		if (reviewersSaving) return;
		showAssignmentsConfirmModal = false;
	}

	async function saveAssignments() {
		if (!canManageAssignments || reviewersSaving) return;
		if (!assignmentEditorId) {
			pushToast('error', 'Debes seleccionar un editor antes de guardar asignaciones.');
			return;
		}
		if (assignmentReviewerIds.includes(assignmentEditorId)) {
			pushToast('error', 'El editor no puede quedar también como revisor en esta obra.');
			return;
		}

		reviewersSaving = true;
		const requestBody: ObraAssignmentsInput = {
			editor_asignado: assignmentEditorId,
			reviewer_ids: sanitizeIds(assignmentReviewerIds)
		};
		const response = await fetch(`/api/obras/${props.obraId}/revisores`, {
			method: 'PUT',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(requestBody)
		});
		reviewersSaving = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const detail = Array.isArray(body?.details) ? body.details[0]?.message : null;
			pushToast('error', detail ?? body.message ?? 'No se pudieron guardar las asignaciones editoriales.');
			return;
		}
		const payload = (await response.json()) as ObraAssignmentsResponse & { editorAsignado?: string | null };
		applyAssignmentsPayload(payload);
		patchCurrentObra({ editor_asignado: payload.editor_asignado ?? payload.editorAsignado ?? null });
		showAssignmentsConfirmModal = false;
		pushToast('success', 'Asignaciones editoriales actualizadas');
	}

	async function saveEstado(targetEstadoId: string, comentario: string) {
		if (stateSaving) return;
		stateSaving = true;
		const response = await fetch(`/api/obras/${props.obraId}/estado`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ estado: targetEstadoId, comentario: comentario.trim() || undefined })
		});
		stateSaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo cambiar el estado.');
			return false;
		}

		const payload = await response.json();
		currentEstadoId = payload.obra.estado;
		persistedEstadoId = payload.obra.estado;
		visiblePublico = Boolean(payload.obra.visible_publico);
		persistedVisiblePublico = Boolean(payload.obra.visible_publico);
		estadoComentario = '';
		estadoConfirmComentario = '';
		pendingEstadoId = null;
		patchCurrentObra({
			estado: payload.obra.estado,
			visible_publico: payload.obra.visible_publico,
			updated_at: payload.obra.updated_at ?? obraLive.updated_at
		});
		pushToast('success', 'Estado actualizado');
		commentsReloadKey += 1;
		return true;
	}

	function openEstadoConfirmModal() {
		if (!canChangeState || stateSaving) return;
		if (!currentEstadoId) {
			pushToast('error', 'Selecciona un estado antes de guardar.');
			return;
		}
		if (!stateDirty) {
			pushToast('info', 'No hay cambios pendientes en el estado.');
			return;
		}
		pendingEstadoId = currentEstadoId;
		const baseComment = estadoComentario.trim();
		if (baseComment.length > 0) {
			estadoConfirmComentario = baseComment;
		} else if (currentEstadoId !== persistedEstadoId) {
			estadoConfirmComentario = `Cambio de estado: ${persistedEstadoLabel} -> ${selectedEstadoLabel}`;
		} else {
			estadoConfirmComentario = '';
		}
		showEstadoConfirmModal = true;
	}

	function cancelEstadoConfirmModal() {
		if (stateSaving) return;
		showEstadoConfirmModal = false;
		pendingEstadoId = null;
	}

	async function confirmEstadoChange() {
		if (!canChangeState || !pendingEstadoId) return;
		const ok = await saveEstado(pendingEstadoId, estadoConfirmComentario);
		if (!ok) return;
		showEstadoConfirmModal = false;
	}

	async function onGuardarVisibilidad() {
		if (visibilitySaving || !canToggleVisible) return;
		if (!visibilityDirty) {
			pushToast('info', 'No hay cambios pendientes en la visibilidad.');
			return;
		}
		visibilitySaving = true;
		const response = await fetch(`/api/obras/${props.obraId}/visibilidad`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ visible_publico: visiblePublico })
		});
		visibilitySaving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo actualizar visibilidad.');
			return;
		}

		const payload = await response.json();
		visiblePublico = Boolean(payload.obra.visible_publico);
		persistedVisiblePublico = Boolean(payload.obra.visible_publico);
		patchCurrentObra({
			visible_publico: payload.obra.visible_publico,
			updated_at: payload.obra.updated_at ?? obraLive.updated_at
		});
		pushToast('success', 'Visibilidad actualizada');
	}

	async function onDeleteObra() {
		if (!canDeleteObra || deletingObra || !deleteConfirmed) return;
		deletingObra = true;
		const response = await fetch(`/api/obras/${props.obraId}`, {
			method: 'DELETE',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ confirmText: deleteConfirmText.trim() })
		});
		deletingObra = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo eliminar la obra.');
			return;
		}

		showDeleteModal = false;
		deleteConfirmText = '';
		if (typeof window !== 'undefined') {
			window.dispatchEvent(new CustomEvent('dashboard-obras-updated'));
		}
		pushToast('success', 'Obra eliminada correctamente.');
		await goto('/dashboard/obras?scope=all', { invalidateAll: true });
	}

	function onOpenDeleteModal() {
		if (!canDeleteObra || deletingObra) return;
		deleteConfirmText = '';
		showDeleteModal = true;
	}

	function onCloseDeleteModal() {
		if (deletingObra) return;
		showDeleteModal = false;
		deleteConfirmText = '';
	}

	onMount(() => {
		if (!isEditorRole) {
			void loadReviewers();
		}
	});

	$effect(() => {
		props.onPendingChangesChange?.(revisionPendingChanges);
	});

	onDestroy(() => {
		props.onPendingChangesChange?.(false);
	});
</script>

<section class="space-y-4">
	<div class="card p-4">
		<h3 class="mb-3 text-lg font-semibold">Checklist</h3>
		<div class="space-y-2 text-sm">
			{#each checklist as item}
				<div class="flex items-start justify-between gap-3 border border-[color:var(--border)] bg-white px-3 py-2">
					<div>
						<span class={item.done ? 'font-medium text-[color:var(--success)]' : 'font-medium text-[color:var(--danger)]'}>
							{item.done ? '[OK]' : '[PEND]'} {item.label}
						</span>
					</div>
					{#if item.detail}
						<span class="text-[color:var(--muted-foreground)]">{item.detail}</span>
					{/if}
				</div>
			{/each}
		</div>
	</div>

	<InternalCommentsPanel
		obraId={props.obraId}
		canComment={canComment}
		title="Comentarios internos"
		reloadKey={commentsReloadKey}
		onDraftDirtyChange={onCommentsDraftDirtyChange}
	/>

	<div class="card p-4">
		<h3 class="mb-3 text-lg font-semibold">Gestión editorial</h3>
		{#if props.assignedReviewer}
			<p class="mb-3 text-sm text-[color:var(--muted-foreground)]">
				Tienes esta obra asignada para revisión.
			</p>
		{/if}

		{#if !isEditorRole}
			<div class="border border-[color:var(--border)] bg-white p-3">
				<h4 class="mb-3 text-sm font-semibold">Asignaciones editoriales</h4>
				{#if reviewersLoading}
					<p class="text-sm text-[color:var(--muted-foreground)]">Cargando asignaciones...</p>
				{:else}
					<div class="grid gap-3 md:grid-cols-2">
						<label class="form-field">
							<span class="form-label">Editor asignado</span>
							<CheckDropdown
								multiple={false}
								items={editorDropdownItems}
								selectedIds={assignmentEditorId ? [assignmentEditorId] : []}
								disabledIds={editorDisabledIds}
								placeholder="Selecciona editor"
								search={true}
								disabled={!canManageAssignments || reviewersSaving}
								onChange={onEditorSelectionChange}
							/>
						</label>

						<label class="form-field">
							<span class="form-label">Revisores asignados</span>
							<CheckDropdown
								multiple={true}
								items={reviewerDropdownItems}
								selectedIds={assignmentReviewerIds}
								disabledIds={reviewerDisabledIds}
								placeholder="Selecciona revisores"
								search={true}
								disabled={!canManageAssignments || reviewersSaving}
								onChange={onReviewerSelectionChange}
							/>
						</label>
					</div>

					{#if canManageAssignments}
						<div class="mt-3 flex justify-end">
							<Button variant="success" onclick={openAssignmentsConfirmModal} disabled={reviewersSaving || !assignmentsDirty}>
								{reviewersSaving ? 'Guardando...' : 'Guardar asignaciones'}
							</Button>
						</div>
					{/if}
				{/if}
			</div>
		{/if}

		<div class="mt-4 border border-[color:var(--border)] bg-white p-3">
			<h4 class="mb-3 text-sm font-semibold">Estado de la obra</h4>
			<div class="flex flex-col gap-3 md:flex-row md:items-end">
				<label class="form-field w-full">
					<span class="form-label">Estado</span>
					<CheckDropdown
						multiple={false}
						items={estadoDropdownItems}
						selectedIds={currentEstadoId ? [currentEstadoId] : []}
						disabledIds={estadoDisabledIds}
						placeholder="Selecciona estado"
						disabled={!canChangeState || stateSaving}
						onChange={onEstadoSelectionChange}
					/>
				</label>
				<Button
					variant="success"
					class="shrink-0"
					onclick={openEstadoConfirmModal}
					disabled={stateSaving || !canChangeState || !stateDirty}
				>
					{stateSaving ? 'Guardando...' : 'Guardar estado'}
				</Button>
			</div>
		</div>

		{#if canToggleVisible}
			<div class="mt-4 border border-[color:var(--border)] bg-white p-3">
				<h4 class="mb-2 text-sm font-semibold">Visibilidad</h4>
				<div class="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
					<label class="form-inline-toggle">
						<input type="checkbox" bind:checked={visiblePublico} />
						Visible sin login (web pública)
					</label>
					<Button
						variant="success"
						onclick={onGuardarVisibilidad}
						disabled={visibilitySaving || !canToggleVisible || !visibilityDirty}
					>
						{visibilitySaving ? 'Guardando...' : 'Guardar visibilidad'}
					</Button>
				</div>
			</div>
		{/if}
	</div>

	{#if canDeleteObra}
		<div>
			<h3 class="mb-2 text-lg font-semibold text-[color:var(--danger)]">Zona de peligro</h3>
			<div class="overflow-hidden border border-[color:var(--danger)] bg-white">
				<div class="flex flex-col gap-3 p-4 sm:flex-row sm:items-center sm:justify-between">
					<div>
						<h4 class="text-sm font-semibold text-[color:var(--danger)]">Eliminar esta obra</h4>
						<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
							Se eliminarán la obra y sus datos relacionados. Esta acción es irreversible.
						</p>
					</div>
					<Button variant="danger" onclick={onOpenDeleteModal} disabled={deletingObra}>Eliminar obra</Button>
				</div>
			</div>
		</div>
	{/if}
</section>

{#if showEstadoConfirmModal && pendingEstadoId}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-lg p-5">
			<h3 class="text-lg font-semibold">Confirmar cambio de estado</h3>
			<div class="mt-3 space-y-2 text-sm">
				<div>
					<strong>Estado actual:</strong> {persistedEstadoLabel}
				</div>
				<div>
					<strong>Nuevo estado:</strong> {selectedEstadoLabel}
				</div>
			</div>
			<label class="form-field mt-3">
				<span class="form-label">Comentario de cambio (opcional)</span>
				<textarea
					rows={4}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					disabled={stateSaving}
					bind:value={estadoConfirmComentario}
				></textarea>
			</label>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={cancelEstadoConfirmModal} disabled={stateSaving}>
					Cancelar
				</Button>
				<Button variant="success" onclick={() => void confirmEstadoChange()} disabled={stateSaving}>
					{stateSaving ? 'Guardando...' : 'Confirmar y guardar'}
				</Button>
			</div>
		</div>
	</div>
{/if}

{#if showAssignmentsConfirmModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-lg p-5">
			<h3 class="text-lg font-semibold">Confirmar cambios de asignación</h3>
			<div class="mt-3 space-y-2 text-sm">
				<div>
					<strong>Editor:</strong> {baselineEditorLabel} -> {assignmentEditorLabel}
				</div>
				<div>
					<strong>Revisores añadidos:</strong>
					{#if addedReviewerIds.length === 0}
						<span class="text-[color:var(--muted-foreground)]"> ninguno</span>
					{:else}
						<span>{addedReviewerIds.map((id) => getUserName(id)).join(', ')}</span>
					{/if}
				</div>
				<div>
					<strong>Revisores quitados:</strong>
					{#if removedReviewerIds.length === 0}
						<span class="text-[color:var(--muted-foreground)]"> ninguno</span>
					{:else}
						<span>{removedReviewerIds.map((id) => getUserName(id)).join(', ')}</span>
					{/if}
				</div>
				<div>
					<strong>Resultado final:</strong>
					{#if selectedReviewersSummary.length === 0}
						<span class="text-[color:var(--muted-foreground)]"> sin revisores asignados</span>
					{:else}
						<span>{selectedReviewersSummary.map((item) => item.name).join(', ')}</span>
					{/if}
				</div>
			</div>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={closeAssignmentsConfirmModal} disabled={reviewersSaving}>
					Cancelar
				</Button>
				<Button variant="success" onclick={() => void saveAssignments()} disabled={reviewersSaving}>
					{reviewersSaving ? 'Guardando...' : 'Confirmar y guardar'}
				</Button>
			</div>
		</div>
	</div>
{/if}

{#if showDeleteModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold text-[color:var(--danger)]">Confirmar eliminación</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				Esta acción es irreversible. Escribe <strong>ELIMINAR</strong> para confirmar.
			</p>
			<label class="form-field mt-3">
				<span class="form-label">Confirmación</span>
				<input
					type="text"
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					bind:value={deleteConfirmText}
					autocomplete="off"
					spellcheck={false}
				/>
			</label>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={onCloseDeleteModal} disabled={deletingObra}>
					Cancelar
				</Button>
				<Button variant="danger" onclick={onDeleteObra} disabled={deletingObra || !deleteConfirmed}>
					{deletingObra ? 'Eliminando...' : 'Eliminar'}
				</Button>
			</div>
		</div>
	</div>
{/if}


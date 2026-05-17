<script lang="ts">
	import { onDestroy, onMount, tick } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import InternalCommentsFeed from '$lib/components/editor/InternalCommentsFeed.svelte';
	import { pushToast } from '$lib/stores/toast';
	import type {
		ComentarioInput,
		ComentarioListItem,
		ComentarioPatchInput,
		ComentarioPublicacionPatchInput,
		ComentarioSeccion
	} from '$lib/types/obra.types';

	type CommentType = 'general' | 'revision' | 'tecnico' | 'nota_propia' | 'observacion_publica';
	type CommentContext = Pick<
		ComentarioInput,
		'secuencia_id' | 'jornada_id' | 'cuadro_id'
	>;

	const props = $props<{
		obraId: string;
		canComment?: boolean;
		title?: string;
		emptyText?: string;
		context?: CommentContext;
		section?: ComentarioSeccion;
		reloadKey?: string | number | null;
		collapsible?: boolean;
		defaultCollapsed?: boolean;
		collapseLabel?: string;
		headerActionLabel?: string;
		headerActionBadgeCount?: number | null;
		headerActionBadgeLoading?: boolean;
		focusComentarioId?: string | null;
		onHeaderAction?: () => void;
		onCommentsMutated?: () => void;
		onDraftDirtyChange?: (dirty: boolean) => void;
	}>();

	function hasStructuredContext(context?: CommentContext): context is CommentContext {
		return Boolean(context?.secuencia_id || context?.jornada_id || context?.cuadro_id);
	}

	let comments = $state<ComentarioListItem[]>([]);
	let commentsLoading = $state(false);
	let postingComment = $state(false);
	let showAllComments = $state(false);
	let collapsed = $state(Boolean(props.defaultCollapsed));
	let newComment = $state('');
	let newCommentType = $state<CommentType>('general');

	let editingCommentId = $state<string | null>(null);
	let editingText = $state('');
	let editingType = $state<CommentType>('general');
	let editingBaselineText = $state('');
	let editingBaselineType = $state<CommentType>('general');
	let savingEdit = $state(false);

	let deleteConfirmId = $state<string | null>(null);
	let deletingComment = $state(false);
	let mounted = false;
	let initialLoadResolved = $state(false);
	let lastReloadKey = $state<string | null>(null);
	let handledFocusComentarioId = $state<string | null>(null);
	let highlightedCommentId = $state<string | null>(null);
	let highlightTimer: ReturnType<typeof setTimeout> | null = null;

	const canComment = $derived(Boolean(props.canComment));
	const canCollapse = $derived(Boolean(props.collapsible));
	const visibleComments = $derived(showAllComments ? comments : comments.slice(0, 5));
	const collapseBadgeLabel = $derived.by(() => {
		if (!initialLoadResolved) return '…';
		return String(comments.length);
	});
	const collapseBadgeClass = $derived.by(() => {
		if (!initialLoadResolved || comments.length === 0) {
			return 'border border-[color:var(--border)] bg-[color:var(--muted)] text-[color:var(--foreground)]';
		}
		return 'border border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--primary-foreground)]';
	});
	const headerActionBadgeLabel = $derived.by(() => {
		if (props.headerActionBadgeLoading) return '…';
		if (props.headerActionBadgeCount === null || props.headerActionBadgeCount === undefined) return null;
		return String(props.headerActionBadgeCount);
	});
	const headerActionBadgeClass = $derived.by(() => {
		if (props.headerActionBadgeLoading || !props.headerActionBadgeCount) {
			return 'border border-[color:var(--border)] bg-[color:var(--muted)] text-[color:var(--foreground)]';
		}
		return 'border border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--primary-foreground)]';
	});
	const newCommentDraftDirty = $derived(newComment.trim().length > 0);
	const editCommentDraftDirty = $derived.by(() => {
		if (!editingCommentId) return false;
		return editingText.trim() !== editingBaselineText.trim() || editingType !== editingBaselineType;
	});
	const draftDirty = $derived(newCommentDraftDirty || editCommentDraftDirty);
	const contextParams = $derived.by(() => {
		const params = new URLSearchParams();
		if (hasStructuredContext(props.context)) {
			if (props.context.secuencia_id) params.set('secuencia_id', props.context.secuencia_id);
			if (props.context.jornada_id) params.set('jornada_id', props.context.jornada_id);
			if (props.context.cuadro_id) params.set('cuadro_id', props.context.cuadro_id);
			return params;
		}
		if (props.section) {
			params.set('seccion', props.section);
		}
		return params;
	});
	const commentTypeItems = [
		{ id: 'general', label: 'general' },
		{ id: 'revision', label: 'revisión' },
		{ id: 'tecnico', label: 'técnico' },
		{ id: 'nota_propia', label: 'nota propia' },
		{ id: 'observacion_publica', label: 'observación pública' }
	];
	const INTERNAL_VISIBILITY_HELP =
		'Este comentario es interno y no se publica en la ficha pública salvo que sea una observación pública marcada como visible.';

	async function loadComments() {
		commentsLoading = true;
		const params = new URLSearchParams(contextParams);
		params.set('limit', '1000');
		const qs = params.toString();
		const endpoint = qs
			? `/api/obras/${props.obraId}/comentarios?${qs}`
			: `/api/obras/${props.obraId}/comentarios?limit=1000`;
		const response = await fetch(endpoint);
		commentsLoading = false;
		initialLoadResolved = true;
		if (!response.ok) {
			pushToast('error', 'No se pudieron cargar los comentarios internos.');
			return;
		}
		const payload = await response.json();
		comments = payload.items ?? [];
	}

	function clearFocusComentarioQueryParam() {
		if (typeof window === 'undefined') return;
		const currentUrl = new URL(window.location.href);
		if (!currentUrl.searchParams.has('focusComentarioId')) return;
		currentUrl.searchParams.delete('focusComentarioId');
		window.history.replaceState(window.history.state, '', currentUrl.toString());
	}

	function commentElementId(commentId: string): string {
		return `comentario-${commentId}`;
	}

	async function applyFocusedComment(commentId: string) {
		if (!mounted) return;
		if (!comments.some((comment) => comment.comentario_id === commentId)) return;

		handledFocusComentarioId = commentId;
		collapsed = false;
		showAllComments = true;

		await tick();

		const element = document.getElementById(commentElementId(commentId));
		element?.scrollIntoView({ block: 'center', behavior: 'smooth' });
		highlightedCommentId = commentId;
		if (highlightTimer) clearTimeout(highlightTimer);
		highlightTimer = setTimeout(() => {
			if (highlightedCommentId === commentId) {
				highlightedCommentId = null;
			}
			highlightTimer = null;
		}, 4500);
		clearFocusComentarioQueryParam();
	}

	function startEdit(comment: ComentarioListItem) {
		editingCommentId = comment.comentario_id;
		editingText = comment.comentario;
		editingBaselineText = comment.comentario;
		if (
			comment.tipo_comentario_term === 'revision' ||
			comment.tipo_comentario_term === 'tecnico' ||
			comment.tipo_comentario_term === 'nota_propia' ||
			comment.tipo_comentario_term === 'observacion_publica'
		) {
			editingType = comment.tipo_comentario_term;
			editingBaselineType = comment.tipo_comentario_term;
			return;
		}
		editingType = 'general';
		editingBaselineType = 'general';
	}

	function cancelEdit() {
		editingCommentId = null;
		editingText = '';
		editingType = 'general';
		editingBaselineText = '';
		editingBaselineType = 'general';
	}

	async function saveEdit(commentId: string) {
		if (savingEdit) return;
		if (!editingText.trim()) {
			pushToast('error', 'Escribe un comentario antes de guardar.');
			return;
		}
		savingEdit = true;
		const payload: ComentarioPatchInput = {
			comentario: editingText.trim(),
			tipo_comentario: editingType
		};
		const response = await fetch(`/api/obras/${props.obraId}/comentarios/${commentId}`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload)
		});
		savingEdit = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo editar el comentario.');
			return;
		}
		pushToast('success', 'Comentario actualizado');
		cancelEdit();
		await loadComments();
		props.onCommentsMutated?.();
	}

	async function publishComment() {
		if (!canComment || postingComment) return;
		if (!newComment.trim()) {
			pushToast('error', 'Escribe un comentario antes de publicar.');
			return;
		}
		postingComment = true;
		const scopedContext = hasStructuredContext(props.context)
			? props.context
			: props.section
				? { seccion: props.section }
				: {};
		const payload: ComentarioInput = {
			comentario: newComment.trim(),
			tipo_comentario: newCommentType,
			...scopedContext
		};
		const response = await fetch(`/api/obras/${props.obraId}/comentarios`, {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload)
		});
		postingComment = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo publicar el comentario.');
			return;
		}
		newComment = '';
		newCommentType = 'general';
		pushToast('success', 'Comentario publicado');
		await loadComments();
		props.onCommentsMutated?.();
	}

	async function confirmDelete(commentId: string) {
		if (deletingComment) return;
		deletingComment = true;
		const response = await fetch(`/api/obras/${props.obraId}/comentarios/${commentId}`, {
			method: 'DELETE'
		});
		deletingComment = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo eliminar el comentario.');
			return;
		}
		deleteConfirmId = null;
		if (editingCommentId === commentId) {
			cancelEdit();
		}
		pushToast('success', 'Comentario eliminado');
		await loadComments();
		props.onCommentsMutated?.();
	}

	async function toggleCommentPublication(comment: ComentarioListItem) {
		if (!comment.can_publish || savingEdit) return;
		const payload: ComentarioPublicacionPatchInput = {
			visible_publico: !comment.visible_publico
		};
		savingEdit = true;
		const response = await fetch(
			`/api/obras/${props.obraId}/comentarios/${comment.comentario_id}/publicacion`,
			{
				method: 'PATCH',
				headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify(payload)
			}
		);
		savingEdit = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo cambiar la visibilidad pública.');
			return;
		}
		pushToast(
			'success',
			payload.visible_publico
				? 'Comentario visible en ficha pública'
				: 'Comentario retirado de la ficha pública'
		);
		await loadComments();
		props.onCommentsMutated?.();
	}

	onMount(() => {
		mounted = true;
		void loadComments();
	});

	$effect(() => {
		if (!props.collapsible) {
			collapsed = false;
			return;
		}
		collapsed = Boolean(props.defaultCollapsed);
	});

	$effect(() => {
		const reloadValue = props.reloadKey;
		if (!mounted) return;
		if (reloadValue === undefined || reloadValue === null) return;
		const normalized = String(reloadValue);
		if (normalized === lastReloadKey) return;
		lastReloadKey = normalized;
		void loadComments();
	});

	$effect(() => {
		props.onDraftDirtyChange?.(draftDirty);
	});

	$effect(() => {
		const focusComentarioId = props.focusComentarioId?.trim() ?? '';
		if (!focusComentarioId) {
			handledFocusComentarioId = null;
			return;
		}
		if (focusComentarioId === handledFocusComentarioId) return;

		collapsed = false;
		showAllComments = true;

		if (!comments.some((comment) => comment.comentario_id === focusComentarioId)) return;
		void applyFocusedComment(focusComentarioId);
	});

	onDestroy(() => {
		if (highlightTimer) {
			clearTimeout(highlightTimer);
			highlightTimer = null;
		}
		props.onDraftDirtyChange?.(false);
	});
</script>

{#snippet panelEditingContent(comment: ComentarioListItem)}
	<label class="form-field">
		<span class="form-label">Tipo</span>
		<CheckDropdown
			multiple={false}
			search={false}
			placeholder="Seleccionar tipo"
			items={commentTypeItems}
			disabled={savingEdit}
			selectedIds={[editingType]}
			onChange={(ids) => {
				const nextType = ids[0] as CommentType | undefined;
				if (!nextType) return;
				editingType = nextType;
			}}
		/>
	</label>
	<label class="form-field mt-2">
		<span class="form-label">
			<span class="form-label-with-help">
				Comentario
				<FieldHelpTooltip
					text={INTERNAL_VISIBILITY_HELP}
					label="Visibilidad interna del comentario en edición"
				/>
			</span>
		</span>
		<textarea
			rows={3}
			class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
			bind:value={editingText}
			disabled={savingEdit}
		></textarea>
	</label>
	<div class="mt-2 flex justify-end gap-2">
		{#if comment.can_edit}
			<Button variant="secondary" onclick={cancelEdit} disabled={savingEdit}>Cancelar</Button>
			<Button variant="success" onclick={() => saveEdit(comment.comentario_id)} disabled={savingEdit}>
				{savingEdit ? 'Guardando...' : 'Guardar'}
			</Button>
		{:else}
			<Button variant="secondary" onclick={cancelEdit} disabled={savingEdit}>Cancelar</Button>
		{/if}
	</div>
{/snippet}

{#snippet panelActions(comment: ComentarioListItem)}
	{#if comment.can_edit || comment.can_delete || comment.can_publish}
		<div class="mt-2 flex flex-wrap items-center justify-end gap-3">
			{#if comment.can_publish}
				<label class="inline-flex items-center gap-2 text-xs text-[color:var(--foreground)]">
					<input
						type="checkbox"
						class="h-4 w-4 accent-[color:var(--primary)]"
						checked={comment.visible_publico}
						disabled={savingEdit || deletingComment}
						onchange={() => toggleCommentPublication(comment)}
					/>
					<span>Visible en ficha pública</span>
				</label>
			{/if}
			{#if comment.can_edit}
				<Button
					variant="ghost"
					onclick={() => startEdit(comment)}
					disabled={savingEdit || deletingComment}
				>
					Editar
				</Button>
			{/if}
			{#if comment.can_delete}
				<Button
					variant="danger"
					onclick={() =>
						(deleteConfirmId =
							deleteConfirmId === comment.comentario_id ? null : comment.comentario_id)}
					disabled={savingEdit || deletingComment}
				>
					Eliminar
				</Button>
			{/if}
		</div>
	{/if}
{/snippet}

{#snippet panelDeleteConfirmContent(comment: ComentarioListItem)}
	<div class="mt-2 border border-[color:var(--danger)] bg-white p-2 text-xs">
		<div class="mb-2">Esta acción eliminará el comentario de forma permanente.</div>
		<div class="flex justify-end gap-2">
			<Button
				variant="secondary"
				onclick={() => (deleteConfirmId = null)}
				disabled={deletingComment}
			>
				Cancelar
			</Button>
			<Button
				variant="danger"
				onclick={() => confirmDelete(comment.comentario_id)}
				disabled={deletingComment}
			>
				{deletingComment ? 'Eliminando...' : 'Confirmar'}
			</Button>
		</div>
	</div>
{/snippet}

<div class="card p-4">
	<div class="mb-3 flex items-center justify-between gap-2">
		<h3 class="text-lg font-semibold">{props.title ?? 'Comentarios internos'}</h3>
		<div class="flex flex-wrap items-center justify-end gap-2">
			{#if props.headerActionLabel && props.onHeaderAction}
				<Button variant="secondary" class="gap-2" onclick={props.onHeaderAction}>
					<span>{props.headerActionLabel}</span>
					{#if headerActionBadgeLabel !== null}
						<span
							class={`inline-flex min-w-6 items-center justify-center rounded-full px-2 py-0.5 text-[10px] font-semibold leading-none ${headerActionBadgeClass}`}
						>
							{headerActionBadgeLabel}
						</span>
					{/if}
				</Button>
			{/if}
			{#if !collapsed && comments.length > 5}
				<Button variant="ghost" onclick={() => (showAllComments = !showAllComments)}>
					{showAllComments ? 'Ver menos' : 'Ver todos'}
				</Button>
			{/if}
			{#if canCollapse}
				<Button variant="secondary" class="gap-2" onclick={() => (collapsed = !collapsed)}>
					<span>{collapsed ? (props.collapseLabel ?? 'Ver') : 'Ocultar'}</span>
					<span
						class={`inline-flex min-w-6 items-center justify-center rounded-full px-2 py-0.5 text-[10px] font-semibold leading-none ${collapseBadgeClass}`}
					>
						{collapseBadgeLabel}
					</span>
				</Button>
			{/if}
		</div>
	</div>

	{#if !collapsed}
		<div class="mb-3">
			<InternalCommentsFeed
				comments={visibleComments}
				loading={commentsLoading}
				emptyText={props.emptyText}
				editingCommentId={editingCommentId}
				deleteConfirmId={deleteConfirmId}
				highlightedCommentId={highlightedCommentId}
			>
				{#snippet editingContent(comment)}
					{@render panelEditingContent(comment)}
				{/snippet}
				{#snippet actions(comment)}
					{@render panelActions(comment)}
				{/snippet}
				{#snippet deleteConfirmContent(comment)}
					{@render panelDeleteConfirmContent(comment)}
				{/snippet}
			</InternalCommentsFeed>
		</div>

		<div class="border border-[color:var(--border)] bg-white p-3">
			<label class="form-field">
				<span class="form-label">Tipo de comentario</span>
				<CheckDropdown
					class="mb-2"
					multiple={false}
					search={false}
					placeholder="Seleccionar tipo"
					items={commentTypeItems}
					disabled={!canComment}
					selectedIds={[newCommentType]}
					onChange={(ids) => {
						const nextType = ids[0] as CommentType | undefined;
						if (!nextType) return;
						newCommentType = nextType;
					}}
				/>
			</label>
			<label class="form-field">
				<span class="form-label">
					<span class="form-label-with-help">
						Nuevo comentario
						<FieldHelpTooltip
							text={INTERNAL_VISIBILITY_HELP}
							label="Visibilidad interna del nuevo comentario"
						/>
					</span>
				</span>
				<textarea
					rows={3}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					disabled={!canComment}
					bind:value={newComment}
				></textarea>
			</label>
			<div class="mt-2 flex justify-end">
				<Button variant="success" onclick={publishComment} disabled={postingComment || !canComment}>
					{postingComment ? 'Publicando...' : 'Publicar'}
				</Button>
			</div>
		</div>
	{/if}
</div>


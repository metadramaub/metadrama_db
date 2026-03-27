<script lang="ts">
	import { onDestroy, onMount } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { formatRelative } from '$lib/utils/formatters';
	import type {
		ComentarioInput,
		ComentarioListItem,
		ComentarioPatchInput,
		ComentarioSeccion
	} from '$lib/types/obra.types';

	type CommentType = 'general' | 'revision' | 'tecnico';
	type CommentContext = Pick<
		ComentarioInput,
		'secuencia_id' | 'jornada_id' | 'cuadro_id' | 'rango_id'
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
		onDraftDirtyChange?: (dirty: boolean) => void;
	}>();

	function hasStructuredContext(context?: CommentContext): context is CommentContext {
		return Boolean(
			context?.secuencia_id || context?.jornada_id || context?.cuadro_id || context?.rango_id
		);
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
	let lastReloadKey = $state<string | null>(null);

	const canComment = $derived(Boolean(props.canComment));
	const canCollapse = $derived(Boolean(props.collapsible));
	const visibleComments = $derived(showAllComments ? comments : comments.slice(0, 5));
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
			if (props.context.rango_id) params.set('rango_id', props.context.rango_id);
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
		{ id: 'tecnico', label: 'técnico' }
	];
	const INTERNAL_VISIBILITY_HELP =
		'Este comentario es interno y no se publica en la ficha pública.';

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
		if (!response.ok) {
			pushToast('error', 'No se pudieron cargar los comentarios internos.');
			return;
		}
		const payload = await response.json();
		comments = payload.items ?? [];
	}

	function startEdit(comment: ComentarioListItem) {
		editingCommentId = comment.comentario_id;
		editingText = comment.comentario;
		editingBaselineText = comment.comentario;
		if (comment.tipo_comentario_term === 'revision' || comment.tipo_comentario_term === 'tecnico') {
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

	onDestroy(() => {
		props.onDraftDirtyChange?.(false);
	});
</script>

<div class="card p-4">
	<div class="mb-3 flex items-center justify-between gap-2">
		<h3 class="text-lg font-semibold">{props.title ?? 'Comentarios internos'}</h3>
		<div class="flex items-center gap-2">
			{#if !collapsed && comments.length > 5}
				<Button variant="ghost" onclick={() => (showAllComments = !showAllComments)}>
					{showAllComments ? 'Ver menos' : 'Ver todos'}
				</Button>
			{/if}
			{#if canCollapse}
				<Button variant="secondary" onclick={() => (collapsed = !collapsed)}>
					{collapsed ? (props.collapseLabel ?? 'Ver comentarios') : 'Ocultar comentarios'}
				</Button>
			{/if}
		</div>
	</div>

	{#if !collapsed}
		{#if commentsLoading}
			<p class="text-sm text-[color:var(--muted-foreground)]">Cargando comentarios...</p>
		{:else if comments.length === 0}
			<p class="text-sm text-[color:var(--muted-foreground)]">{props.emptyText ?? 'No hay comentarios aún.'}</p>
		{:else}
			<div class="mb-3 space-y-2">
				{#each visibleComments as comment}
					<div class="border border-[color:var(--border)] bg-white p-3 text-sm">
						<div class="mb-1 text-xs text-[color:var(--muted-foreground)]">
							{comment.nombre_editor ?? 'Editor'} - {formatRelative(comment.created_at)}
						</div>
						<div class="mb-2 flex flex-wrap gap-2">
							<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-0.5 text-xs">
								{comment.tipo_comentario_term ?? 'general'}
							</span>
							{#if comment.contexto_label}
								<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-0.5 text-xs">
									{comment.contexto_label}
								</span>
							{/if}
							{#if comment.locked}
								<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-0.5 text-xs">
									solo lectura
								</span>
							{/if}
						</div>

						{#if editingCommentId === comment.comentario_id}
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
						{:else}
							<div class="whitespace-pre-wrap">{comment.comentario}</div>
							{#if comment.can_edit || comment.can_delete}
								<div class="mt-2 flex justify-end gap-2">
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
							{#if deleteConfirmId === comment.comentario_id}
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
							{/if}
						{/if}
					</div>
				{/each}
			</div>
		{/if}

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
				<Button onclick={publishComment} disabled={postingComment || !canComment}>
					{postingComment ? 'Publicando...' : 'Publicar comentario'}
				</Button>
			</div>
		</div>
	{/if}
</div>


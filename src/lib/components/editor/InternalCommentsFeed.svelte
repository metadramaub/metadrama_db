<script lang="ts">
	import type { Snippet } from 'svelte';
	import { formatRelative } from '$lib/utils/formatters';
	import type { ComentarioListItem } from '$lib/types/obra.types';

	const props = $props<{
		comments: ComentarioListItem[];
		loading?: boolean;
		emptyText?: string;
		editingCommentId?: string | null;
		deleteConfirmId?: string | null;
		editingContent?: Snippet<[ComentarioListItem]>;
		actions?: Snippet<[ComentarioListItem]>;
		deleteConfirmContent?: Snippet<[ComentarioListItem]>;
	}>();
</script>

{#if props.loading}
	<p class="text-sm text-[color:var(--muted-foreground)]">Cargando comentarios...</p>
{:else if props.comments.length === 0}
	<p class="text-sm text-[color:var(--muted-foreground)]">{props.emptyText ?? 'No hay comentarios aún.'}</p>
{:else}
	<div class="space-y-2">
		{#each props.comments as comment}
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

				{#if props.editingCommentId === comment.comentario_id && props.editingContent}
					{@render props.editingContent(comment)}
				{:else}
					<div class="whitespace-pre-wrap">{comment.comentario}</div>
					{#if props.actions}
						{@render props.actions(comment)}
					{/if}
					{#if props.deleteConfirmId === comment.comentario_id && props.deleteConfirmContent}
						{@render props.deleteConfirmContent(comment)}
					{/if}
				{/if}
			</div>
		{/each}
	</div>
{/if}

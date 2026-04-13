<script lang="ts">
	import { onMount } from 'svelte';
	import type { Snippet } from 'svelte';
	import Badge from '$lib/components/ui/badge.svelte';
	import { formatRelative } from '$lib/utils/formatters';
	import type { ComentarioListItem } from '$lib/types/obra.types';

	const props = $props<{
		comments: ComentarioListItem[];
		loading?: boolean;
		emptyText?: string;
		editingCommentId?: string | null;
		deleteConfirmId?: string | null;
		showSequenceEstrofa?: boolean;
		onSequenceContextClick?: (comment: ComentarioListItem) => void;
		editingContent?: Snippet<[ComentarioListItem]>;
		actions?: Snippet<[ComentarioListItem]>;
		deleteConfirmContent?: Snippet<[ComentarioListItem]>;
	}>();

	type IconComponent = any;

	let LinkBadgeIcon = $state<IconComponent | null>(null);

	onMount(() => {
		let cancelled = false;

		void import('lucide-svelte/icons/external-link')
			.then((iconModule) => {
				if (cancelled) return;
				LinkBadgeIcon = iconModule.default;
			})
			.catch(() => {
				if (cancelled) return;
				LinkBadgeIcon = null;
			});

		return () => {
			cancelled = true;
		};
	});

	function toneForCommentType(
		type: ComentarioListItem['tipo_comentario_term']
	): 'neutral' | 'accent' | 'info' | 'success' | 'warning' {
		if (type === 'revision') return 'accent';
		if (type === 'tecnico') return 'info';
		if (type === 'estado') return 'warning';
		return 'neutral';
	}
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
					<Badge tone={toneForCommentType(comment.tipo_comentario_term)}>
						{comment.tipo_comentario_term ?? 'general'}
					</Badge>
					{#if comment.contexto_label}
						{#if props.onSequenceContextClick && comment.secuencia_id}
							<Badge
								tone="info"
								interactive={true}
								icon={LinkBadgeIcon}
								title={`Abrir ${comment.contexto_label} en Secuencias`}
								ariaLabel={`Abrir ${comment.contexto_label} en Secuencias`}
								onclick={() => props.onSequenceContextClick?.(comment)}
							>
								{comment.contexto_label}
							</Badge>
						{:else}
							<Badge tone="info">
								{comment.contexto_label}
							</Badge>
						{/if}
					{/if}
					{#if props.showSequenceEstrofa && comment.secuencia_estrofa_term}
						<Badge tone="success">
							Estrofa: {comment.secuencia_estrofa_term}
						</Badge>
					{/if}
					{#if comment.locked}
						<Badge tone="warning" class="opacity-90">
							solo lectura
						</Badge>
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

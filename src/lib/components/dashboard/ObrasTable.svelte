<script lang="ts">
	import { createEventDispatcher } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { formatRelative } from '$lib/utils/formatters';

	export interface ObraRow {
		obra_id: string;
		titulo: string;
		estadoTerm: string;
		editorNombre: string;
		updated_at: string | null;
		canEditContent?: boolean;
		canComment?: boolean;
		canReview?: boolean;
		canChangeState?: boolean;
	}

	const props = $props<{ obras: ObraRow[] }>();
	const dispatch = createEventDispatcher<{ open: string }>();
	function actionLabel(obra: ObraRow) {
		if (obra.canEditContent) return 'Editar';
		if (obra.canReview || obra.canComment || obra.canChangeState) return 'Revisar';
		return 'Ver';
	}

	function actionHint(obra: ObraRow) {
		if (obra.canEditContent) return '';
		if (obra.canReview || obra.canComment || obra.canChangeState) return 'Solo revision';
		return 'Solo lectura';
	}
</script>

<div class="card overflow-x-auto">
	<table class="min-w-full text-left text-sm">
		<thead class="bg-[color:var(--muted)]">
			<tr>
				<th class="px-3 py-2">Título</th>
				<th class="px-3 py-2">Estado</th>
				<th class="px-3 py-2">Editor</th>
				<th class="px-3 py-2">Última modificación</th>
				<th class="px-3 py-2">Acciones</th>
			</tr>
		</thead>
		<tbody>
			{#if props.obras.length === 0}
				<tr>
					<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={5}>
						No hay obras para mostrar.
					</td>
				</tr>
			{:else}
				{#each props.obras as obra}
					<tr class="border-t border-[color:var(--border)]">
						<td class="px-3 py-2">{obra.titulo}</td>
						<td class="px-3 py-2">
							<span class="rounded-full bg-[color:var(--muted)] px-2 py-1 text-xs">{obra.estadoTerm}</span>
						</td>
						<td class="px-3 py-2">{obra.editorNombre}</td>
						<td class="px-3 py-2">{formatRelative(obra.updated_at)}</td>
						<td class="px-3 py-2">
							<div class="flex items-center gap-2">
								<Button variant="ghost" onclick={() => dispatch('open', obra.obra_id)}>
									{actionLabel(obra)}
								</Button>
								{#if actionHint(obra)}
									<span class="text-xs text-[color:var(--muted-foreground)]">{actionHint(obra)}</span>
								{/if}
							</div>
						</td>
					</tr>
				{/each}
			{/if}
		</tbody>
	</table>
</div>

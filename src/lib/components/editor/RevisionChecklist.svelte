<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';
	import type {
		RevisionChecklistItem,
		RevisionTargetTab
	} from '$lib/utils/revision-checklist';

	const props = $props<{
		required: RevisionChecklistItem[];
		recommendations: RevisionChecklistItem[];
		onNavigate?: (tab: RevisionTargetTab) => void;
	}>();

	const requiredDoneCount = $derived(
		props.required.filter((item: RevisionChecklistItem) => item.done).length
	);
	// Las opcionales no entran en el total: vacías no son nada que revisar.
	const countedRecommendations = $derived(
		props.recommendations.filter((item: RevisionChecklistItem) => !item.optional)
	);
	const recommendationDoneCount = $derived(
		countedRecommendations.filter((item: RevisionChecklistItem) => item.done).length
	);
</script>

<div class="card p-4">
	<div class="mb-3 flex flex-wrap items-baseline justify-between gap-2">
		<div>
			<h3 class="text-base font-semibold">Comprobaciones necesarias</h3>
			<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
				Deben completarse para avanzar a revisión o publicación.
			</p>
		</div>
		<span class="text-xs text-[color:var(--muted-foreground)]">
			{requiredDoneCount}/{props.required.length} completadas
		</span>
	</div>

	<ul class="text-sm">
		{#each props.required as item}
			<li
				class="flex flex-wrap items-center justify-between gap-3 border-b border-[color:var(--border)] py-2 last:border-b-0"
			>
				<div class="min-w-0">
					<span
						class={item.done
							? 'font-medium text-[color:var(--success)]'
							: 'font-medium text-[color:var(--danger)]'}
					>
						{item.done ? '[OK]' : '[PEND]'} {item.label}
					</span>
					{#if item.detail}
						<p class="mt-0.5 text-xs text-[color:var(--muted-foreground)]">
							{item.detail}
						</p>
					{/if}
				</div>
				{#if !item.done && item.targetTab && props.onNavigate}
					<Button
						variant="ghost"
						class="shrink-0 !px-2 !py-1 text-xs"
						onclick={() => props.onNavigate?.(item.targetTab as RevisionTargetTab)}
					>
						Revisar
					</Button>
				{/if}
			</li>
		{/each}
	</ul>

	<div
		class="mt-5 mb-3 flex flex-wrap items-baseline justify-between gap-2 border-t border-[color:var(--border)] pt-4"
	>
		<h3 class="text-base font-semibold">Recomendaciones editoriales</h3>
		<span class="text-xs text-[color:var(--muted-foreground)]">
			{recommendationDoneCount}/{countedRecommendations.length} completadas
		</span>
	</div>

	<ul class="text-sm">
		{#each props.recommendations as item}
			<li
				class="flex flex-wrap items-center justify-between gap-3 border-b border-[color:var(--border)] py-2 last:border-b-0"
			>
				<div class="min-w-0">
					<span
						class={item.done
							? 'font-medium text-[color:var(--success)]'
							: 'font-medium text-[color:var(--muted-foreground)]'}
					>
						{item.done ? '[OK]' : item.optional ? '[OPCIONAL]' : '[REVISAR]'} {item.label}
					</span>
					{#if item.detail}
						<p class="mt-0.5 text-xs text-[color:var(--muted-foreground)]">
							{item.detail}
						</p>
					{/if}
				</div>
				{#if !item.done && !item.optional && item.targetTab && props.onNavigate}
					<Button
						variant="ghost"
						class="shrink-0 !px-2 !py-1 text-xs"
						onclick={() => props.onNavigate?.(item.targetTab as RevisionTargetTab)}
					>
						Revisar
					</Button>
				{/if}
			</li>
		{/each}
	</ul>
</div>

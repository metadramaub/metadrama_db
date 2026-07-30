<script lang="ts">
	export type MetricPositionSequenceItem = {
		key: string;
		position: number;
		label: string;
		context?: string | null;
		optional?: boolean;
	};

	const props = $props<{
		items: MetricPositionSequenceItem[];
		emptyMessage: string;
	}>();
</script>

{#if props.items.length > 0}
	<div class="flex flex-wrap border-l border-t border-[color:var(--border)]">
		{#each props.items as item (item.key)}
			<div
				class="min-w-24 flex-1 basis-24 border-b border-r border-[color:var(--border)] bg-[color:var(--background)] p-3"
			>
				<p class="text-xs text-[color:var(--muted-foreground)]">Verso {item.position}</p>
				<p class="mt-1 font-mono text-base font-semibold">{item.label}</p>
				{#if item.context || item.optional}
					<p class="mt-1 text-xs leading-4 text-[color:var(--muted-foreground)]">
						{item.context ?? ''}{item.context && item.optional ? ' · ' : ''}{item.optional
							? 'opcional'
							: ''}
					</p>
				{/if}
			</div>
		{/each}
	</div>
{:else}
	<p class="border border-dashed border-[color:var(--border)] p-3 text-sm text-[color:var(--muted-foreground)]">
		{props.emptyMessage}
	</p>
{/if}

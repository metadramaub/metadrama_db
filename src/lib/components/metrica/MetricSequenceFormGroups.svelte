<script lang="ts">
	import ChevronDown from 'lucide-svelte/icons/chevron-down';
	import MetricFormLabel from './MetricFormLabel.svelte';
	import type { MetricSequenceFormGroup } from './metric-display.types';

	const props = $props<{
		groups: MetricSequenceFormGroup[];
		colorByForma: Record<string, string>;
		onOpen: (sequenceId: string) => void;
	}>();

	const textoSecuencias = (n: number) => `${n} ${n === 1 ? 'secuencia' : 'secuencias'}`;
	const columnaIzquierda = $derived(
		props.groups.filter((_: MetricSequenceFormGroup, indice: number) => indice % 2 === 0)
	);
	const columnaDerecha = $derived(
		props.groups.filter((_: MetricSequenceFormGroup, indice: number) => indice % 2 === 1)
	);
</script>

<ul class="space-y-1 sm:hidden">
	{#each props.groups as group (group.colorKey)}
		{@render forma(group)}
	{/each}
</ul>

<div class="hidden gap-x-5 sm:grid sm:grid-cols-2">
	<ul class="min-w-0 space-y-1">
		{#each columnaIzquierda as group (group.colorKey)}
			{@render forma(group)}
		{/each}
	</ul>
	<ul class="min-w-0 space-y-1">
		{#each columnaDerecha as group (group.colorKey)}
			{@render forma(group)}
		{/each}
	</ul>
</div>

{#snippet forma(group: MetricSequenceFormGroup)}
	<li>
		<details class="group/forma">
			<summary class="flex cursor-pointer list-none items-center justify-between gap-3 px-1 py-2 text-sm [&::-webkit-details-marker]:hidden">
				<MetricFormLabel forma={group.forma} colorKey={group.colorKey} colorByForma={props.colorByForma} className="font-medium" />
				<span class="flex shrink-0 items-center gap-2 text-xs tabular-nums text-[color:var(--muted-foreground)]">
					{textoSecuencias(group.items.length)}{#if group.detalle} · {group.detalle}{/if}
					<ChevronDown class="h-3.5 w-3.5 transition-transform group-open/forma:rotate-180" aria-hidden="true" />
				</span>
			</summary>
			<ul class="pb-2 pl-5 pr-1">
				{#each group.items as item (item.id)}
					<li>
						<button
							type="button"
							class="flex w-full items-center justify-between gap-3 rounded px-2 py-1.5 text-left text-sm hover:bg-[color:var(--muted)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)]"
							onclick={() => props.onOpen(item.secuencia_id)}
						>
							<span class="tabular-nums">vv. {item.v_ini}–{item.v_fin}</span>
							{#if item.detalle}
								<span class="text-xs text-[color:var(--muted-foreground)]">{item.detalle}</span>
							{/if}
						</button>
					</li>
				{/each}
			</ul>
		</details>
	</li>
{/snippet}

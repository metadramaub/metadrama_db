<script lang="ts">
	import ChevronDown from 'lucide-svelte/icons/chevron-down';
	import CircleCheck from 'lucide-svelte/icons/circle-check';
	import CircleMinus from 'lucide-svelte/icons/circle-minus';
	import MetricAnalysisHeading from './MetricAnalysisHeading.svelte';
	import MetricSequenceFormGroups from './MetricSequenceFormGroups.svelte';
	import type { PhenomenonForm, PhenomenonGroup } from '$lib/metrica/phenomena-index';

	const props = $props<{
		groups: PhenomenonGroup[];
		colorByForma: Record<string, string>;
		onOpen: (sequenceId: string) => void;
	}>();
	let selectedId = $state<string | null>(null);
	const selected = $derived(props.groups.find((group: PhenomenonGroup) => group.id === selectedId) ?? null);

	const plural = (n: number, singular: string, plural: string) =>
		`${n} ${n === 1 ? singular : plural}`;

	function resumenChip(group: PhenomenonGroup) {
		if (group.ramas.length > 1) return `${group.ramas.length} tipos`;
		const rama = group.ramas[0];
		if (!rama) return '';
		if (rama.declarada) return 'Declarado';
		if (rama.facetas.length === 1 && rama.facetas[0]?.label === '') return String(rama.facetas[0].total);
		const partes = rama.facetas
			.filter((faceta) => faceta.total > 0)
			.map((faceta) => `${faceta.label} ${faceta.total}`);
		return partes.length > 0 ? partes.join(' · ') : 'Sin casos';
	}
</script>

	<section class="rounded-lg border border-[color:var(--border)] bg-white" aria-labelledby="phenomena-index-title">
	<div class="border-b border-[color:var(--border)] px-4 py-4 sm:px-5">
		<MetricAnalysisHeading
			id="phenomena-index-title"
			title="Localizar en la obra"
			description="En qué formas aparece cada fenómeno —y en cuáles no—. Cada forma despliega sus secuencias."
		/>
		<div class="mt-3 flex flex-wrap gap-2">
			{#each props.groups as group (group.id)}
				<button
					type="button"
					class={`rounded-full border px-3 py-1.5 text-xs font-medium transition-colors ${selectedId === group.id ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white hover:bg-[color:var(--muted)]'}`}
					aria-pressed={selectedId === group.id}
					onclick={() => (selectedId = selectedId === group.id ? null : group.id)}
				>
					{group.label}
					<span class="ml-1 tabular-nums opacity-75">{resumenChip(group)}</span>
				</button>
			{/each}
		</div>
	</div>

	{#if selected}
		<div class="px-4 py-4 sm:px-5">
			{#each selected.ramas as rama, indice (rama.id)}
				<section class={indice > 0 ? 'mt-5 border-t border-[color:var(--border)] pt-5' : ''}>
					{#if rama.label}
						<h3 class="text-base font-semibold">{rama.label}</h3>
					{/if}

					{#if rama.declarada}
						<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">{rama.nota}</p>
					{:else}
						<div class="mt-3 space-y-4">
							{#each rama.facetas as faceta (faceta.id)}
								{#if faceta.label === ''}
									{@render formas(faceta.formas)}
								{:else}
									<details class="group/respuesta">
										<summary class="flex cursor-pointer list-none items-center justify-between gap-3 py-1.5 text-sm [&::-webkit-details-marker]:hidden">
											<span class="flex items-center gap-2">
												{#if faceta.positiva}
													<CircleCheck class="h-4 w-4 shrink-0" aria-hidden="true" />
													<span class="sr-only">Respuesta positiva:</span>
												{:else}
													<CircleMinus class="h-4 w-4 shrink-0" aria-hidden="true" />
													<span class="sr-only">Respuesta negativa:</span>
												{/if}
												<span class="font-medium">{faceta.label}</span>
												<span class="text-xs font-normal tabular-nums text-[color:var(--muted-foreground)]">{plural(faceta.total, 'secuencia', 'secuencias')}</span>
											</span>
											<ChevronDown class="h-4 w-4 shrink-0 text-[color:var(--muted-foreground)] transition-transform group-open/respuesta:rotate-180" aria-hidden="true" />
										</summary>
										<div class="pb-2 pl-4 pt-1">
											{#if faceta.formas.length > 0}
												{@render formas(faceta.formas)}
											{:else}
												<p class="text-xs">No hay secuencias con esta respuesta.</p>
											{/if}
										</div>
									</details>
								{/if}
							{/each}
						</div>
					{/if}

					{#if rama.pendientes > 0}
						<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">
							{plural(rama.pendientes, 'secuencia', 'secuencias')} sin anotar.
						</p>
					{/if}
				</section>
			{/each}
		</div>
	{/if}
</section>

{#snippet formas(lista: PhenomenonForm[])}
	<MetricSequenceFormGroups groups={lista} colorByForma={props.colorByForma} onOpen={props.onOpen} />
{/snippet}

<script lang="ts">
	import ChevronDown from 'lucide-svelte/icons/chevron-down';
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
</script>

<section class="rounded-lg border border-[color:var(--border)] bg-white" aria-labelledby="phenomena-index-title">
	<div class="border-b border-[color:var(--border)] px-4 py-4 sm:px-5">
		<h2 id="phenomena-index-title" class="text-base font-semibold">Localizar en la obra</h2>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			En qué formas aparece cada fenómeno —y en cuáles no—. Cada forma despliega sus secuencias.
		</p>
		<div class="mt-3 flex flex-wrap gap-2">
			{#each props.groups as group (group.id)}
				<button
					type="button"
					class={`rounded-full border px-3 py-1.5 text-xs font-medium transition-colors ${selectedId === group.id ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white hover:bg-[color:var(--muted)]'}`}
					aria-pressed={selectedId === group.id}
					onclick={() => (selectedId = selectedId === group.id ? null : group.id)}
				>
					{group.label}
					{#if group.total > 0}
						<span class="ml-1 tabular-nums opacity-75">{group.total}</span>
					{/if}
				</button>
			{/each}
		</div>
	</div>

	{#if selected}
		<div class="space-y-5 px-4 py-4 sm:px-5">
			{#each selected.ramas as rama (rama.id)}
				<div>
					{#if rama.label}
						<h3 class="text-sm font-semibold">{rama.label}</h3>
					{/if}

					{#if rama.declarada}
						<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">{rama.nota}</p>
					{:else}
						<div class="mt-2 space-y-2">
							<!-- La vertiente positiva se abre sola; la negativa se ofrece cerrada porque suele
							     ser la mayoría de la obra y taparía lo que se viene a buscar. -->
							{#each rama.facetas as faceta (faceta.id)}
								{#if faceta.label === ''}
									{@render formas(faceta.formas)}
								{:else}
									<details class="group rounded-md border border-[color:var(--border)]" open={faceta.positiva}>
										<summary class="flex cursor-pointer list-none items-center justify-between gap-3 px-3 py-2 text-sm font-medium [&::-webkit-details-marker]:hidden">
											<span>
												{faceta.label}
												<span class="ml-1 font-normal tabular-nums text-[color:var(--muted-foreground)]">
													{plural(faceta.total, 'secuencia', 'secuencias')}
												</span>
											</span>
											<ChevronDown class="h-4 w-4 shrink-0 text-[color:var(--muted-foreground)] transition-transform group-open:rotate-180" aria-hidden="true" />
										</summary>
										<div class="border-t border-[color:var(--border)] px-3 py-2">
											{@render formas(faceta.formas)}
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
				</div>
			{/each}
		</div>
	{/if}
</section>

{#snippet formas(lista: PhenomenonForm[])}
	<ul class="grid gap-1.5 sm:grid-cols-2">
		{#each lista as forma (forma.colorKey)}
			<li>
				<details class="group/forma rounded-md border border-[color:var(--border)]">
					<summary class="flex cursor-pointer list-none items-center justify-between gap-3 px-3 py-2 text-sm [&::-webkit-details-marker]:hidden">
						<span class="flex min-w-0 items-center gap-2">
							<span class="h-2.5 w-2.5 shrink-0 rounded-full" style={`background-color: ${props.colorByForma[forma.colorKey] ?? 'var(--gray-400)'}`}></span>
							<span class="truncate font-medium">{forma.forma}</span>
						</span>
						<span class="flex shrink-0 items-center gap-2 text-xs tabular-nums text-[color:var(--muted-foreground)]">
							{forma.items.length} · {forma.versos} vv.
							<ChevronDown class="h-3.5 w-3.5 transition-transform group-open/forma:rotate-180" aria-hidden="true" />
						</span>
					</summary>
					<ul class="border-t border-[color:var(--border)] px-2 py-2">
						{#each forma.items as item (item.id)}
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
		{/each}
	</ul>
{/snippet}

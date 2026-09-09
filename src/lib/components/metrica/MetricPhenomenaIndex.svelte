<script lang="ts">
	import type { PhenomenonGroup } from '$lib/metrica/phenomena-index';

	const props = $props<{
		groups: PhenomenonGroup[];
		onOpen: (sequenceId: string) => void;
	}>();
	let selectedId = $state<string | null>(null);
	const selected = $derived(props.groups.find((group) => group.id === selectedId) ?? null);
</script>

<section class="rounded-lg border border-[color:var(--border)] bg-white" aria-labelledby="phenomena-index-title">
	<div class="border-b border-[color:var(--border)] px-4 py-4 sm:px-5">
		<h2 id="phenomena-index-title" class="text-base font-semibold">Localizar en la obra</h2>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			Busca las secuencias donde se ha anotado cada fenómeno.
		</p>
		<div class="mt-3 flex flex-wrap gap-2">
			{#each props.groups as group (group.id)}
				<button
					type="button"
					class={`rounded-full border px-3 py-1.5 text-xs font-medium transition-colors ${selectedId === group.id ? 'border-[color:var(--gray-800)] bg-[color:var(--gray-800)] text-white' : 'border-[color:var(--border)] bg-white hover:bg-[color:var(--muted)]'}`}
					aria-pressed={selectedId === group.id}
					onclick={() => (selectedId = selectedId === group.id ? null : group.id)}
				>
					{group.label} <span class="ml-1 tabular-nums opacity-75">{group.items.length}</span>
				</button>
			{/each}
		</div>
	</div>

	{#if selected}
		<div class="px-4 py-4 sm:px-5">
			<h3 class="text-sm font-semibold">{selected.label}</h3>
			<ul class="mt-2 grid max-h-72 gap-2 overflow-y-auto pr-1 sm:grid-cols-2">
				{#each selected.items as item (item.id)}
					<li>
						<button
							type="button"
							class="flex w-full items-start justify-between gap-3 rounded-md border border-[color:var(--border)] px-3 py-2.5 text-left text-sm hover:bg-[color:var(--muted)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-[color:var(--primary)]"
							onclick={() => props.onOpen(item.secuencia_id)}
						>
							<span>
								<span class="block font-medium">{item.forma}</span>
								{#if item.detalle}<span class="block text-xs text-[color:var(--muted-foreground)]">{item.detalle}</span>{/if}
							</span>
							<span class="shrink-0 text-xs tabular-nums text-[color:var(--muted-foreground)]">vv. {item.v_ini}–{item.v_fin}</span>
						</button>
					</li>
				{/each}
			</ul>
		</div>
	{/if}
</section>

<script lang="ts">
	import X from 'lucide-svelte/icons/x';
	import type { CatalogActiveChip, CatalogActiveChipId } from '$lib/catalogo/catalog-filters';

	const props = $props<{
		chips: CatalogActiveChip[];
		onRemove: (chipId: CatalogActiveChipId) => void;
		onClear: () => void;
	}>();
</script>

{#if props.chips.length > 0}
	<section class="border border-[color:var(--border)] bg-white p-3">
		<div class="flex flex-wrap items-center justify-between gap-3">
			<div class="flex min-w-0 flex-wrap gap-2">
				{#each props.chips as chip (chip.id)}
					<span
						class="inline-flex max-w-full items-center gap-2 border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs"
					>
						<span class="truncate">{chip.label}</span>
						<button
							type="button"
							class="inline-flex h-5 w-5 shrink-0 items-center justify-center border border-[color:var(--border)] bg-white text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)]"
							aria-label={`Quitar filtro ${chip.label}`}
							onclick={() => props.onRemove(chip.id)}
						>
							<X size={12} aria-hidden="true" />
						</button>
					</span>
				{/each}
			</div>

			<button
				type="button"
				class="shrink-0 text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-700)] underline-offset-4 hover:underline"
				onclick={props.onClear}
			>
				Limpiar filtros
			</button>
		</div>
	</section>
{/if}

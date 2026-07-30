<script lang="ts">
	type RepetitionPosition = {
		posicion_id?: unknown;
		bloque?: unknown;
		posicion?: unknown;
		bloque_origen?: unknown;
		posicion_origen?: unknown;
		etiqueta_funcional?: unknown;
	};

	const props = $props<{
		positions: RepetitionPosition[];
		blockLabel?: string;
	}>();

	const blocks = $derived.by(() => {
		const positions = props.positions as RepetitionPosition[];
		return [...new Set<number>(positions.map((row) => Number(row.bloque ?? 1)))]
			.sort((a: number, b: number) => a - b)
			.map((block: number) => ({
				block,
				positions: positions
					.filter((row: RepetitionPosition) => Number(row.bloque ?? 1) === block)
					.sort(
						(a: RepetitionPosition, b: RepetitionPosition) =>
							Number(a.posicion ?? 0) - Number(b.posicion ?? 0)
					)
			}));
	});

	function sourceLabel(row: RepetitionPosition): string {
		const sourcePosition = Number(row.posicion_origen);
		if (Number.isInteger(sourcePosition) && sourcePosition >= 1 && sourcePosition <= 26) {
			return String.fromCharCode(64 + sourcePosition);
		}
		const functionalLabel = String(row.etiqueta_funcional ?? '').trim();
		return functionalLabel || String(row.posicion ?? '?');
	}
</script>

{#if blocks.length === 0}
	<p class="text-sm text-[color:var(--muted-foreground)]">
		Todavía no se ha descompuesto esta regla en posiciones.
	</p>
{:else}
	<div class="space-y-2">
		{#each blocks as block (block.block)}
			<div class="flex flex-wrap items-center gap-2">
				<span class="w-20 shrink-0 text-xs font-medium text-[color:var(--muted-foreground)]">
					{props.blockLabel ?? 'Bloque'} {block.block}
				</span>
				<ol class="flex flex-wrap gap-1" aria-label={`${props.blockLabel ?? 'Bloque'} ${block.block}`}>
					{#each block.positions as position (String(position.posicion_id ?? `${block.block}-${position.posicion}`))}
						<li
							class="flex h-8 min-w-8 items-center justify-center border border-[color:var(--border)] bg-[color:var(--background)] px-2 font-mono text-sm"
							title={String(position.etiqueta_funcional ?? '') || undefined}
						>
							{sourceLabel(position)}
						</li>
					{/each}
				</ol>
			</div>
		{/each}
	</div>
{/if}

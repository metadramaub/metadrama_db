<script lang="ts">
	import type { MetricSummary, MetricSummarySequence } from './metric-display.types';

	const { columns } = $props<{
		columns: { id: string; label: string; range: string; summary: MetricSummary }[];
	}>();

	const numero = (value: number) => value.toLocaleString('es', { maximumFractionDigits: 2 });
	const rows: { label: string; value: (summary: MetricSummary) => string; divider?: boolean }[] = [
		{ label: 'Secuencias', value: (s) => numero(s.secuencias) },
		{ label: 'Formas distintas', value: (s) => numero(s.formasDistintas) },
		{ label: 'Longitud media', value: (s) => `${numero(s.mediaPorSecuencia)} vv.` },
		{ label: 'Diversidad', value: (s) => numero(s.diversidad) },
		{ label: 'Densidad', value: (s) => `${numero(s.densidad)} /100 vv.` },
		{ label: 'Abre con', value: (s) => s.abre ?? '—', divider: true },
		{ label: 'Cierra con', value: (s) => s.cierra ?? '—' }
	];
	const extremes = [
		{ label: 'Más larga', key: 'secuenciaMasLarga' },
		{ label: 'Más corta', key: 'secuenciaMasCorta' }
	] as const;

	const rango = (s: MetricSummarySequence) =>
		`${s.v_ini === s.v_fin ? `v. ${s.v_ini}` : `vv. ${s.v_ini}–${s.v_fin}`} · ${s.n_versos} ${s.n_versos === 1 ? 'v.' : 'vv.'}`;
</script>

<!-- El contenedor recibe foco para desplazar la tabla con el teclado en pantallas estrechas. -->
<!-- svelte-ignore a11y_no_noninteractive_tabindex -->
<div class="overflow-x-auto border border-[color:var(--border)] bg-white focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2" role="region" aria-label="Resumen métrico por jornadas" tabindex="0">
	<table class="w-full border-separate border-spacing-0 text-left text-sm">
		<caption class="sr-only">Resumen métrico por jornadas</caption>
		<thead>
			<tr>
				<td class="sticky left-0 z-10 bg-white"></td>
				{#each columns as column (column.id)}
					<th scope="col" class="min-w-44 px-4 py-3 align-top font-semibold">
						{column.label}
						<span class="mt-0.5 block text-xs font-normal text-[color:var(--muted-foreground)]">{column.range}</span>
					</th>
				{/each}
			</tr>
		</thead>
		<tbody>
			{#each rows as row (row.label)}
				<tr>
					<th scope="row" class={`sticky left-0 z-10 whitespace-nowrap bg-white px-4 py-1.5 text-xs font-normal text-[color:var(--muted-foreground)] ${row.divider ? 'border-t border-[color:var(--border)] pt-3' : ''}`}>
						{row.label}
					</th>
					{#each columns as column (column.id)}
						<td class={`px-4 py-1.5 align-top tabular-nums ${row.divider ? 'border-t border-[color:var(--border)] pt-3' : 'font-semibold'}`}>
							{row.value(column.summary)}
						</td>
					{/each}
				</tr>
			{/each}
			{#each extremes as row (row.key)}
				<tr>
					<th scope="row" class="sticky left-0 z-10 whitespace-nowrap bg-white px-4 py-2 align-top text-xs font-normal text-[color:var(--muted-foreground)]">{row.label}</th>
					{#each columns as column (column.id)}
						{@const sequence = column.summary[row.key]}
						<td class="px-4 py-2 align-top">
							{#if sequence}
								<span>{sequence.forma ?? 'Sin forma anotada'}</span>
								<span class="mt-0.5 block whitespace-nowrap text-xs tabular-nums text-[color:var(--muted-foreground)]">{rango(sequence)}</span>
							{:else}
								—
							{/if}
						</td>
					{/each}
				</tr>
			{/each}
		</tbody>
	</table>
</div>

<script lang="ts">
	import MetricAnalysisHeading from './MetricAnalysisHeading.svelte';
	import type { EnunciationSummary } from '$lib/metrica/analisis-ficha';

	const props = $props<{ rows: EnunciationSummary[] }>();
	const percentFormatter = new Intl.NumberFormat('es-ES', { maximumFractionDigits: 2 });

	function labelFor(tipo: string) {
		if (tipo === 'cantado') return 'Pasajes cantados';
		if (tipo === 'prosa') return 'Pasajes en prosa';
		if (tipo === 'evocacion_metrica') return 'Evocaciones métricas';
		return tipo;
	}
</script>

<section class="space-y-3" aria-labelledby="metric-enunciation-title">
	<MetricAnalysisHeading
		id="metric-enunciation-title"
		title="Canto, prosa y evocación"
		description="Extensión del canto y la evocación, y localización de la prosa."
	/>
	<ul class="divide-y divide-[color:var(--border)] rounded-lg border border-[color:var(--border)] bg-white">
		{#each props.rows as row (row.tipo)}
			<li class="grid gap-2 px-4 py-3 sm:grid-cols-[minmax(0,1fr)_auto_minmax(0,1.4fr)] sm:items-center sm:gap-5">
				<h3 class="font-semibold">{labelFor(row.tipo)}</h3>
				<div>
					{#if row.tipo === 'prosa'}
						<p class="font-semibold">Presente</p>
						{#each row.localizaciones as lugar}
							<p class="text-sm tabular-nums">Entre vv. {lugar.v_anterior} y {lugar.v_posterior}</p>
						{/each}
					{:else}
						<p class="text-lg font-semibold tabular-nums">
							{row.versos} <span class="text-sm font-normal text-[color:var(--muted-foreground)]">vv.</span>
						</p>
						<p class="text-xs text-[color:var(--muted-foreground)]">{percentFormatter.format(row.porcentaje)} %</p>
					{/if}
				</div>
				<p class="text-sm"><span class="text-[color:var(--muted-foreground)]">En</span> {row.formas.join(' · ')}</p>
			</li>
		{/each}
	</ul>
</section>

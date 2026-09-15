<script lang="ts">
	import { formatLaboratoryFraction, formatLaboratoryValue } from '$lib/laboratorio/metricas';
	import type { LaboratoryMetric, LaboratoryMetricReading } from '$lib/laboratorio/metricas';
	import type { CorpusComparisonWork } from '$lib/types/public-artifacts.types';
	import ExternalLink from 'lucide-svelte/icons/external-link';

	const props = $props<{
		work: CorpusComparisonWork;
		metric: LaboratoryMetric;
		reading: LaboratoryMetricReading;
		position: { location: string; rank: string };
		date: string;
	}>();

	const fraction = $derived(formatLaboratoryFraction(props.reading, props.metric));
</script>

<div class="border-b border-[color:var(--border)] bg-[color:var(--gray-50)] px-5 py-4">
	<div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
		<div>
			<p class="text-[10px] font-semibold uppercase tracking-[0.14em] text-[color:var(--muted-foreground)]">
				Obra de referencia
			</p>
			<h3 class="mt-1 font-semibold">{props.work.titulo}</h3>
			<p class="mt-0.5 text-xs text-[color:var(--muted-foreground)]">
				{props.work.autores.join(', ') || 'Autoría sin identificar'} · {props.date}
			</p>
		</div>
		<a
			class="inline-flex shrink-0 items-center gap-1.5 text-sm font-semibold hover:text-[color:var(--primary)]"
			href={`/obras/${props.work.slug}`}
		>
			Abrir ficha <ExternalLink class="h-3.5 w-3.5" aria-hidden="true" />
		</a>
	</div>

	<dl class="mt-4 grid gap-3 border-t border-[color:var(--border)] pt-3 sm:grid-cols-3">
		<div>
			<dt class="text-xs text-[color:var(--muted-foreground)]">Valor en la obra</dt>
			<dd class="mt-0.5 font-semibold tabular-nums">
				{formatLaboratoryValue(props.reading.value, props.metric)}
				{#if fraction}
					<span class="ml-2 text-xs font-normal text-[color:var(--muted-foreground)]">{fraction}</span>
				{/if}
			</dd>
		</div>
		<div>
			<dt class="text-xs text-[color:var(--muted-foreground)]">Posición</dt>
			<dd class="mt-0.5 font-semibold">{props.position.location}</dd>
		</div>
		<div>
			<dt class="text-xs text-[color:var(--muted-foreground)]">Orden de mayor a menor</dt>
			<dd class="mt-0.5 font-semibold tabular-nums">{props.position.rank}</dd>
		</div>
	</dl>
</div>

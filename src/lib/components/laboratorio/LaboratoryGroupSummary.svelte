<script lang="ts">
	import { formatLaboratoryValue } from '$lib/laboratorio/metricas';
	import type {
		LaboratoryMetric,
		LaboratoryValueSummary
	} from '$lib/laboratorio/metricas';

	const props = $props<{
		label: string;
		color: string;
		worksCount: number;
		summary: LaboratoryValueSummary;
		metric: LaboratoryMetric;
	}>();
</script>

<article
	class="border border-[color:var(--border)] border-t-4 bg-white px-4 py-4"
	style:border-top-color={props.color}
>
	<div class="flex items-baseline justify-between gap-3">
		<h3 class="font-semibold">{props.label}</h3>
		<span class="text-xs tabular-nums text-[color:var(--muted-foreground)]">
			{props.worksCount} {props.worksCount === 1 ? 'obra' : 'obras'}
		</span>
	</div>
	<dl class="mt-3 grid grid-cols-2 gap-x-4 gap-y-3">
		<div>
			<dt class="text-xs text-[color:var(--muted-foreground)]">Con dato</dt>
			<dd class="mt-0.5 font-semibold tabular-nums">{props.summary.n} de {props.worksCount}</dd>
		</div>
		<div>
			<dt class="text-xs text-[color:var(--muted-foreground)]">Mediana</dt>
			<dd class="mt-0.5 font-semibold tabular-nums">{formatLaboratoryValue(props.summary.median, props.metric)}</dd>
		</div>
		<div class="col-span-2">
			<dt class="text-xs text-[color:var(--muted-foreground)]">Rango central</dt>
			<dd class="mt-0.5 font-semibold tabular-nums">
				{formatLaboratoryValue(props.summary.q1, props.metric)}–{formatLaboratoryValue(props.summary.q3, props.metric)}
			</dd>
		</div>
	</dl>
</article>

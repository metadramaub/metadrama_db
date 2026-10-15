<script lang="ts">
	import type { MetricSummary, MetricSummarySequence } from './metric-display.types';

	const props = $props<{ summary: MetricSummary; title?: string }>();

	const numero = (valor: number) =>
		valor.toLocaleString('es', { maximumFractionDigits: 2 });

	/** Las cinco cifras, en el orden en que se preguntan. La unidad va pegada al número. */
	const cifras = $derived([
		{ etiqueta: 'Secuencias', valor: String(props.summary.secuencias) },
		{ etiqueta: 'Formas distintas', valor: String(props.summary.formasDistintas) },
		{ etiqueta: 'Longitud media', valor: `${props.summary.mediaPorSecuencia} vv.` },
		{ etiqueta: 'Diversidad', valor: numero(props.summary.diversidad) },
		{ etiqueta: 'Densidad', valor: `${numero(props.summary.densidad)} /100 vv.` }
	]);

	const rango = (s: MetricSummarySequence) =>
		`${s.v_ini === s.v_fin ? `v. ${s.v_ini}` : `vv. ${s.v_ini}–${s.v_fin}`} · ${s.n_versos} ${s.n_versos === 1 ? 'v.' : 'vv.'}`;
</script>

<section
	class="border border-[color:var(--border)] bg-white px-4 py-3 sm:px-5"
	aria-label={props.title ? `Resumen métrico · ${props.title}` : 'Resumen métrico'}
>
	{#if props.title}
		<h3 class="mb-3 text-sm font-semibold">{props.title}</h3>
	{/if}

	<dl class="flex flex-wrap items-baseline gap-x-5 gap-y-1.5 text-sm">
		{#each cifras as cifra (cifra.etiqueta)}
			<div class="flex items-baseline gap-1.5">
				<dt class="text-xs text-[color:var(--muted-foreground)]">{cifra.etiqueta}</dt>
				<dd class="font-semibold tabular-nums">{cifra.valor}</dd>
			</div>
		{/each}
	</dl>

	<p class="mt-2 flex flex-wrap gap-x-5 gap-y-1 border-t border-[color:var(--border)] pt-2 text-xs text-[color:var(--muted-foreground)]">
		<span>Abre con <strong class="text-[color:var(--gray-900)]">{props.summary.abre ?? '—'}</strong> y cierra con <strong class="text-[color:var(--gray-900)]">{props.summary.cierra ?? '—'}</strong></span>
		{#if props.summary.secuenciaMasLarga}
			<span>La más larga, <strong class="text-[color:var(--gray-900)]">{props.summary.secuenciaMasLarga.forma ?? 'sin forma anotada'}</strong> ({rango(props.summary.secuenciaMasLarga)})</span>
		{/if}
		{#if props.summary.secuenciaMasCorta}
			<span>La más corta, <strong class="text-[color:var(--gray-900)]">{props.summary.secuenciaMasCorta.forma ?? 'sin forma anotada'}</strong> ({rango(props.summary.secuenciaMasCorta)})</span>
		{/if}
	</p>
</section>

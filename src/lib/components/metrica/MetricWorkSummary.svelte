<script lang="ts">
	type SecuenciaDestacada = {
		forma: string | null;
		v_ini: number;
		v_fin: number;
		n_versos: number;
	} | null;

	interface TechnicalSummary {
		/** Cuántas secuencias métricas tiene la obra. Vivía en la cabecera, junto a jornadas y
		 *  cuadros, y no es un dato de la estructura de la obra sino de cómo está versificada. */
		secuencias: number;
		formasDistintas: number;
		mediaPorSecuencia: number;
		secuenciaMasLarga: SecuenciaDestacada;
		secuenciaMasCorta: SecuenciaDestacada;
		abre: string | null;
		cierra: string | null;
	}

	const props = $props<{ summary: TechnicalSummary }>();
</script>

{#snippet destacada(secuencia: SecuenciaDestacada)}
	{#if secuencia}
		<dd class="mt-0.5 font-semibold">{secuencia.forma ?? 'Sin forma anotada'}</dd>
		<dd class="text-xs text-[color:var(--muted-foreground)]">
			{secuencia.v_ini === secuencia.v_fin
				? `v. ${secuencia.v_ini}`
				: `vv. ${secuencia.v_ini}–${secuencia.v_fin}`}
			· {secuencia.n_versos}
			{secuencia.n_versos === 1 ? 'v.' : 'vv.'}
		</dd>
	{:else}
		<dd class="mt-0.5 text-[color:var(--muted-foreground)]">Sin datos</dd>
	{/if}
{/snippet}

<section class="rounded-lg border border-[color:var(--border)] bg-white" aria-labelledby="metric-summary-title">
	<div class="flex flex-wrap items-center justify-between gap-2 border-b border-[color:var(--border)] px-4 py-3 sm:px-5">
		<h2 id="metric-summary-title" class="text-base font-semibold">Resumen métrico</h2>
	</div>
	<dl class="grid sm:grid-cols-2 lg:grid-cols-4">
		<div class="px-4 py-3.5 sm:px-5">
			<dt class="text-xs text-[color:var(--muted-foreground)]">Secuencias métricas</dt>
			<dd class="mt-0.5 text-lg font-semibold tabular-nums">{props.summary.secuencias}</dd>
		</div>
		<div class="border-t border-[color:var(--border)] px-4 py-3.5 sm:border-l sm:border-t-0 sm:px-5">
			<dt class="text-xs text-[color:var(--muted-foreground)]">Formas distintas</dt>
			<dd class="mt-0.5 text-lg font-semibold tabular-nums">{props.summary.formasDistintas}</dd>
		</div>
		<div class="border-t border-[color:var(--border)] px-4 py-3.5 sm:border-l sm:border-t-0 sm:px-5 lg:border-l-0">
			<dt class="text-xs text-[color:var(--muted-foreground)]">Longitud media</dt>
			<dd class="mt-0.5 text-lg font-semibold tabular-nums">{props.summary.mediaPorSecuencia} vv.</dd>
		</div>
		<div class="border-t border-[color:var(--border)] px-4 py-3.5 sm:border-l sm:border-t-0 sm:px-5">
			<dt class="text-xs text-[color:var(--muted-foreground)]">Secuencia más larga</dt>
			{@render destacada(props.summary.secuenciaMasLarga)}
		</div>
		<div class="border-t border-[color:var(--border)] px-4 py-3.5 sm:border-l sm:border-t-0 sm:px-5">
			<dt class="text-xs text-[color:var(--muted-foreground)]">Secuencia más corta</dt>
			{@render destacada(props.summary.secuenciaMasCorta)}
		</div>
	</dl>
	<div class="grid gap-2 border-t border-[color:var(--border)] px-4 py-3 text-sm sm:grid-cols-2 sm:px-5">
		<p><span class="text-[color:var(--muted-foreground)]">La obra abre con</span> <strong>{props.summary.abre ?? '—'}</strong></p>
		<p><span class="text-[color:var(--muted-foreground)]">y cierra con</span> <strong>{props.summary.cierra ?? '—'}</strong></p>
	</div>
</section>

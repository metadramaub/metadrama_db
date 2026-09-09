<script lang="ts">
	interface TechnicalSummary {
		formasDistintas: number;
		mediaPorSecuencia: number;
		tiradaMasLarga: {
			forma: string | null;
			v_ini: number;
			v_fin: number;
			n_versos: number;
		} | null;
		abre: string | null;
		cierra: string | null;
	}

	const props = $props<{ summary: TechnicalSummary }>();
</script>

<section class="rounded-lg border border-[color:var(--border)] bg-white" aria-labelledby="metric-summary-title">
	<div class="flex flex-wrap items-center justify-between gap-2 border-b border-[color:var(--border)] px-4 py-3 sm:px-5">
		<h2 id="metric-summary-title" class="text-base font-semibold">Resumen métrico</h2>
		<span class="text-xs text-[color:var(--muted-foreground)]">Calculado a partir de las secuencias</span>
	</div>
	<dl class="grid sm:grid-cols-3">
		<div class="px-4 py-3.5 sm:px-5">
			<dt class="text-xs text-[color:var(--muted-foreground)]">Formas distintas</dt>
			<dd class="mt-0.5 text-lg font-semibold tabular-nums">{props.summary.formasDistintas}</dd>
		</div>
		<div class="border-t border-[color:var(--border)] px-4 py-3.5 sm:border-l sm:border-t-0 sm:px-5">
			<dt class="text-xs text-[color:var(--muted-foreground)]">Longitud media de las tiradas</dt>
			<dd class="mt-0.5 text-lg font-semibold tabular-nums">{props.summary.mediaPorSecuencia} vv.</dd>
		</div>
		<div class="border-t border-[color:var(--border)] px-4 py-3.5 sm:border-l sm:border-t-0 sm:px-5">
			<dt class="text-xs text-[color:var(--muted-foreground)]">Tirada más larga</dt>
			{#if props.summary.tiradaMasLarga}
				<dd class="mt-0.5 font-semibold">
					{props.summary.tiradaMasLarga.forma ?? 'Sin forma anotada'}
				</dd>
				<dd class="text-xs text-[color:var(--muted-foreground)]">
					vv. {props.summary.tiradaMasLarga.v_ini}–{props.summary.tiradaMasLarga.v_fin}
					· {props.summary.tiradaMasLarga.n_versos} vv.
				</dd>
			{:else}
				<dd class="mt-0.5 text-[color:var(--muted-foreground)]">Sin datos</dd>
			{/if}
		</div>
	</dl>
	<div class="grid gap-2 border-t border-[color:var(--border)] px-4 py-3 text-sm sm:grid-cols-2 sm:px-5">
		<p><span class="text-[color:var(--muted-foreground)]">La obra abre con</span> <strong>{props.summary.abre ?? '—'}</strong></p>
		<p><span class="text-[color:var(--muted-foreground)]">y cierra con</span> <strong>{props.summary.cierra ?? '—'}</strong></p>
	</div>
</section>

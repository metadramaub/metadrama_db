<script lang="ts">
	interface CuadroCuts {
		total: number;
		partenSecuencia: number;
		coincidenCambioForma: number;
		entreSecuenciasMismaForma: number;
		sinCobertura: number;
	}

	interface JornadaEnds {
		jornada: number;
		abre: string | null;
		cierra: string | null;
	}

	const props = $props<{ cuts: CuadroCuts; jornadas: JornadaEnds[] }>();
</script>

<section class="space-y-3" aria-labelledby="metric-articulation-title">
	<div>
		<h2 id="metric-articulation-title" class="text-lg font-semibold">Jornadas y cuadros</h2>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			Cómo se relacionan los límites dramáticos con el curso de las formas.
		</p>
	</div>
	<div class="grid overflow-hidden rounded-lg border border-[color:var(--border)] bg-white lg:grid-cols-2">
		<div class="px-4 py-4 sm:px-5">
			<h3 class="font-semibold">Cambios de cuadro</h3>
			<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
				Solo cambios internos de jornada; los cortes de jornada se cuentan aparte.
			</p>
			{#if props.cuts.total > 0}
				<dl class="mt-4 grid grid-cols-3 gap-3 text-sm">
					<div>
						<dt class="text-xs text-[color:var(--muted-foreground)]">Cambian de forma</dt>
						<dd class="mt-1 text-xl font-semibold tabular-nums">{props.cuts.coincidenCambioForma}</dd>
					</div>
					<div>
						<dt class="text-xs text-[color:var(--muted-foreground)]">Cortan una secuencia</dt>
						<dd class="mt-1 text-xl font-semibold tabular-nums">{props.cuts.partenSecuencia}</dd>
					</div>
					<div>
						<dt class="text-xs text-[color:var(--muted-foreground)]">Entre la misma forma</dt>
						<dd class="mt-1 text-xl font-semibold tabular-nums">{props.cuts.entreSecuenciasMismaForma}</dd>
					</div>
				</dl>
				<p class="mt-4 border-t border-[color:var(--border)] pt-3 text-xs text-[color:var(--muted-foreground)]">
					{props.cuts.total} {props.cuts.total === 1 ? 'cambio de cuadro analizado' : 'cambios de cuadro analizados'}
					{#if props.cuts.sinCobertura > 0} · {props.cuts.sinCobertura} sin cobertura métrica{/if}
				</p>
			{:else}
				<p class="mt-4 text-sm text-[color:var(--muted-foreground)]">No hay cambios internos de cuadro anotados.</p>
			{/if}
		</div>

		<div class="border-t border-[color:var(--border)] px-4 py-4 sm:px-5 lg:border-l lg:border-t-0">
			<h3 class="font-semibold">Apertura y cierre de las jornadas</h3>
			{#if props.jornadas.length > 0}
				<table class="mt-3 w-full text-sm">
					<thead>
						<tr class="border-b border-[color:var(--border)] text-left text-xs text-[color:var(--muted-foreground)]">
							<th scope="col" class="py-2 pr-3 font-semibold">Jornada</th>
							<th scope="col" class="px-3 py-2 font-semibold">Abre con</th>
							<th scope="col" class="py-2 pl-3 font-semibold">Cierra con</th>
						</tr>
					</thead>
					<tbody>
						{#each props.jornadas as jornada (jornada.jornada)}
							<tr class="border-b border-[color:var(--border)] last:border-b-0">
								<th scope="row" class="py-2.5 pr-3 text-left font-medium">{jornada.jornada}</th>
								<td class="px-3 py-2.5">{jornada.abre ?? '—'}</td>
								<td class="py-2.5 pl-3">{jornada.cierra ?? '—'}</td>
							</tr>
						{/each}
					</tbody>
				</table>
			{:else}
				<p class="mt-4 text-sm text-[color:var(--muted-foreground)]">No hay jornadas anotadas.</p>
			{/if}
		</div>
	</div>
</section>

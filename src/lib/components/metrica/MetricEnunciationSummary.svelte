<script lang="ts">
	interface EnunciationSummary {
		tipo: string;
		versos: number;
		porcentaje: number;
		formas: string[];
	}

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
	<div>
		<h2 id="metric-enunciation-title" class="text-lg font-semibold">Canto, prosa y evocación</h2>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			Cuánto ocupan estos pasajes y dentro de qué formas aparecen.
		</p>
	</div>
	<ul class="grid gap-3 md:grid-cols-3">
		{#each props.rows as row (row.tipo)}
			<li class="rounded-lg border border-[color:var(--border)] bg-white px-4 py-4">
				<h3 class="font-semibold">{labelFor(row.tipo)}</h3>
				<p class="mt-2 text-xl font-semibold tabular-nums">
					{row.versos} <span class="text-sm font-normal text-[color:var(--muted-foreground)]">vv.</span>
				</p>
				<p class="text-xs text-[color:var(--muted-foreground)]">
					{percentFormatter.format(row.porcentaje)} % de la obra
				</p>
				<p class="mt-3 border-t border-[color:var(--border)] pt-3 text-sm">
					<span class="text-[color:var(--muted-foreground)]">En</span> {row.formas.join(' · ')}
				</p>
			</li>
		{/each}
	</ul>
</section>

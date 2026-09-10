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
		/** Número efectivo de formas y secuencias por cada cien versos: las dos medidas con las que
		 *  se ordena el catálogo de obras, dichas también aquí. */
		diversidad: number;
		densidad: number;
		secuenciaMasLarga: SecuenciaDestacada;
		secuenciaMasCorta: SecuenciaDestacada;
		abre: string | null;
		cierra: string | null;
	}

	const props = $props<{ summary: TechnicalSummary }>();

	const numero = (valor: number) =>
		valor.toLocaleString('es', { maximumFractionDigits: 2 });

	/** Las seis cifras, en el orden en que se preguntan. La unidad va pegada al número. */
	const cifras = $derived([
		{ etiqueta: 'Secuencias', valor: String(props.summary.secuencias) },
		{ etiqueta: 'Formas distintas', valor: String(props.summary.formasDistintas) },
		{ etiqueta: 'Longitud media', valor: `${props.summary.mediaPorSecuencia} vv.` },
		{ etiqueta: 'Diversidad', valor: numero(props.summary.diversidad) },
		{ etiqueta: 'Densidad', valor: `${numero(props.summary.densidad)} /100 vv.` }
	]);

	const rango = (s: NonNullable<SecuenciaDestacada>) =>
		`${s.v_ini === s.v_fin ? `v. ${s.v_ini}` : `vv. ${s.v_ini}–${s.v_fin}`} · ${s.n_versos} ${s.n_versos === 1 ? 'v.' : 'vv.'}`;
</script>

<!--
	**Es un resumen y tiene que ocupar como un resumen.** En rejilla de celdas con borde ocupaba
	media pantalla antes de llegar al primer gráfico, que es lo contrario de lo que hace falta arriba
	de la ficha. Ahora son dos líneas: los números en una y las formas que la enmarcan en otra.
-->
<section
	class="border border-[color:var(--border)] bg-white px-4 py-3 sm:px-5"
	aria-labelledby="metric-summary-title"
>
	<h2 id="metric-summary-title" class="sr-only">Resumen métrico</h2>

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

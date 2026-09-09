<script lang="ts">
	// Cómo cambia cada forma de una jornada a otra. REUTILIZABLE.
	//
	// **Es el gráfico del cambio, no el de la composición.** De qué está hecha cada jornada lo dice
	// el apilado; lo que aquí se ve es si una forma sube, baja o aparece, que en un apilado es
	// justamente lo que peor se lee: el tramo se mueve arriba y abajo porque lo empujan los de
	// debajo, y seguirlo con la vista es imposible.
	//
	// Decisiones:
	//
	// - **Una línea por forma, no un área.** Se cruzan, y así debe ser: los cruces son el dato.
	// - **Escala común de cero al máximo**, no una por forma. Con escalas propias todas las líneas
	//   parecerían igual de importantes.
	// - **Se rotula donde la forma pesa**, en su extremo más alto, y solo si el hueco da para ello.
	//   Con doce formas, rotularlas todas es una maraña.
	// - **Una forma que no está en una jornada vale cero y se dibuja**, porque «aparece en la II» es
	//   una de las tres cosas que este gráfico viene a contestar.
	import { scaleLinear, scalePoint } from 'd3-scale';
	import type { MetricSlopeSeries } from './metric-display.types';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';

	const props = $props<{
		/** Los momentos, en orden: las jornadas. */
		momentos: string[];
		series: MetricSlopeSeries[];
		colorByForma: Record<string, string>;
		onHoverForma?: (colorKey: string | null) => void;
		resaltada?: string | null;
	}>();

	const ANCHO = 760;
	const ALTO_UTIL = 300;
	const MARGEN_SUP = 18;
	const MARGEN_INF = 38;
	const MARGEN_IZQ = 46;
	const MARGEN_DER = 132; // Sitio para los nombres, que van a la derecha.

	const alto = MARGEN_SUP + ALTO_UTIL + MARGEN_INF;

	const maximo = $derived(
		Math.max(
			10,
			...props.series.flatMap((s: MetricSlopeSeries) => s.valores.map((v) => v ?? 0))
		)
	);

	const y = $derived(
		scaleLinear()
			.domain([0, maximo])
			.nice()
			.range([MARGEN_SUP + ALTO_UTIL, MARGEN_SUP])
	);

	const x = $derived(
		scalePoint<string>()
			.domain(props.momentos)
			.range([MARGEN_IZQ, ANCHO - MARGEN_DER])
	);

	const colorDe = (colorKey: string) =>
		props.colorByForma[normalizeFormaKey(colorKey)] ?? 'var(--muted-foreground)';

	const trazo = (valores: (number | null)[]) =>
		props.momentos
			.map((momento: string, i: number) => `${i === 0 ? 'M' : 'L'}${x(momento)},${y(valores[i] ?? 0)}`)
			.join(' ');

	/**
	 * Dónde se rotula cada forma: en su extremo derecho, apartándolas si se solapan.
	 *
	 * Sin esto, cuatro formas del 2 % se escriben una encima de otra y no se lee ninguna. Y con
	 * esto solo, **la pila se sale por abajo**: seis formas pequeñas empujadas hacia abajo acaban
	 * escribiéndose encima del nombre de la jornada. Por eso, después de separarlas, la pila entera
	 * se sube lo que se haya pasado.
	 */
	const etiquetas = $derived.by(() => {
		const ALTO_LINEA = 15;
		const SUELO = MARGEN_SUP + ALTO_UTIL;
		const puestas = props.series
			.map((serie: MetricSlopeSeries) => ({
				serie,
				valor: serie.valores[serie.valores.length - 1] ?? 0,
				y: y(serie.valores[serie.valores.length - 1] ?? 0)
			}))
			.sort((a: { y: number }, b: { y: number }) => a.y - b.y);

		let ultima = -Infinity;
		for (const puesta of puestas) {
			puesta.y = Math.max(puesta.y, ultima + ALTO_LINEA);
			ultima = puesta.y;
		}

		const sobra = ultima - SUELO;
		if (sobra > 0) {
			for (const puesta of puestas) puesta.y -= sobra;
		}
		return puestas;
	});

	const referencias = $derived(y.ticks(4));

	/**
	 * Guías finas cada cinco puntos.
	 *
	 * Casi todas las formas quedan por debajo del veinte por ciento, así que con una línea cada
	 * veinte no hay contra qué leerlas: se ve que están abajo y nada más.
	 */
	const menudas = $derived(
		Array.from({ length: Math.floor(maximo / 5) + 1 }, (_, i) => i * 5).filter(
			(valor) => !referencias.includes(valor)
		)
	);
</script>

<figure class="metric-slope">
	<svg viewBox={`0 0 ${ANCHO} ${alto}`} role="img" aria-label="Cambio de cada forma por jornadas">
		{#each menudas as valor (valor)}
			<line
				class="metric-slope__guia metric-slope__guia--menuda"
				x1={MARGEN_IZQ - 6}
				x2={ANCHO - MARGEN_DER + 6}
				y1={y(valor)}
				y2={y(valor)}
			/>
		{/each}

		{#each referencias as valor (valor)}
			<line
				class="metric-slope__guia"
				x1={MARGEN_IZQ - 6}
				x2={ANCHO - MARGEN_DER + 6}
				y1={y(valor)}
				y2={y(valor)}
			/>
			<text
				class="metric-slope__referencia"
				x={MARGEN_IZQ - 10}
				y={y(valor)}
				text-anchor="end"
				dominant-baseline="middle">{valor}%</text
			>
		{/each}

		{#each props.momentos as momento (momento)}
			<text
				class="metric-slope__momento"
				x={x(momento)}
				y={MARGEN_SUP + ALTO_UTIL + 24}
				text-anchor="middle">{momento}</text
			>
		{/each}

		{#each props.series as serie (serie.colorKey)}
			{@const apagada = props.resaltada && props.resaltada !== serie.colorKey}
			<path
				class="metric-slope__linea"
				d={trazo(serie.valores)}
				stroke={colorDe(serie.colorKey)}
				opacity={apagada ? 0.15 : 1}
				role="presentation"
				onmouseenter={() => props.onHoverForma?.(serie.colorKey)}
				onmouseleave={() => props.onHoverForma?.(null)}
			>
				<title>{serie.forma}</title>
			</path>
			{#each props.momentos as momento, i (momento)}
				{@const valor = serie.valores[i] ?? 0}
				<!-- **El cero va hueco.** «No aparece en esta jornada» no es lo mismo que «aparece
				     poquísimo», y con el mismo punto relleno las dos cosas se leían igual. -->
				<circle
					cx={x(momento)}
					cy={y(valor)}
					r={valor === 0 ? 3.5 : 4}
					fill={valor === 0 ? 'var(--background, #fff)' : colorDe(serie.colorKey)}
					stroke={valor === 0 ? colorDe(serie.colorKey) : 'none'}
					stroke-width={valor === 0 ? 1.5 : 0}
					opacity={apagada ? 0.15 : 1}
				>
					<title>
						{serie.forma}, {momento}: {valor === 0 ? 'no aparece' : `${valor.toFixed(1)} %`}
					</title>
				</circle>
			{/each}
		{/each}

		{#each etiquetas as etiqueta (etiqueta.serie.colorKey)}
			<!-- El nombre también resalta: es lo que la mano busca, más que la línea. -->
			<text
				class="metric-slope__nombre"
				x={ANCHO - MARGEN_DER + 12}
				y={etiqueta.y}
				dominant-baseline="middle"
				fill={colorDe(etiqueta.serie.colorKey)}
				opacity={props.resaltada && props.resaltada !== etiqueta.serie.colorKey ? 0.25 : 1}
				role="presentation"
				onmouseenter={() => props.onHoverForma?.(etiqueta.serie.colorKey)}
				onmouseleave={() => props.onHoverForma?.(null)}
			>
				{etiqueta.serie.forma}
			</text>
		{/each}
	</svg>
</figure>

<style>
	.metric-slope {
		margin: 0;
	}

	.metric-slope svg {
		display: block;
		width: 100%;
		max-width: 44rem;
		height: auto;
	}

	.metric-slope__linea {
		fill: none;
		stroke-width: 2.5;
		stroke-linejoin: round;
	}

	.metric-slope__guia {
		stroke: var(--border);
		stroke-width: 1;
	}

	.metric-slope__guia--menuda {
		opacity: 0.4;
	}

	.metric-slope__nombre,
	.metric-slope__linea {
		cursor: default;
	}

	.metric-slope__referencia {
		font-size: 12px;
		fill: var(--muted-foreground);
	}

	.metric-slope__momento {
		font-size: 13px;
		font-weight: 600;
		fill: var(--muted-foreground);
		text-transform: uppercase;
		letter-spacing: 0.4px;
	}

	.metric-slope__nombre {
		font-size: 12px;
		font-weight: 600;
	}
</style>

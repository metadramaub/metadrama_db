<script lang="ts">
	// Españolas contra italianas, jornada a jornada. REUTILIZABLE.
	//
	// **Las dos partes se dibujan, no se deducen.** Antes era una sola línea con la proporción
	// italiana, y obligaba a rellenar mentalmente que el resto era español; además repetía el
	// lenguaje del gráfico de pendientes, que dice otra cosa, y dos gráficos iguales que significan
	// cosas distintas se confunden.
	//
	// Va en columnas apiladas y no en líneas porque es una composición: de qué está hecha cada
	// jornada. Con dos categorías el apilado se lee perfectamente —lo que no se puede seguir en un
	// apilado es una banda intermedia entre muchas—, y la referencia del cincuenta por ciento dice
	// de qué lado cae cada jornada sin tener que leer un número.
	import { scaleLinear } from 'd3-scale';
	import { colorForForma } from '$lib/utils/metric-colors';

	const props = $props<{
		puntos: { momento: string; espanola: number; italiana: number; sinTradicion: number }[];
	}>();

	const ANCHO_COL = 96;
	const HUECO = 56;
	const ALTO_UTIL = 260;
	const MARGEN_SUP = 14;
	const MARGEN_IZQ = 46;
	const MARGEN_INF = 38;

	const ESPANOLA = colorForForma({ slug: null, tipoForma: 'forma_espanola' });
	const ITALIANA = colorForForma({ slug: null, tipoForma: 'forma_italiana' });
	const SIN = colorForForma({ slug: null, tipoForma: null });

	const ancho = $derived(
		MARGEN_IZQ + props.puntos.length * ANCHO_COL + Math.max(0, props.puntos.length - 1) * HUECO + 8
	);
	const alto = MARGEN_SUP + ALTO_UTIL + MARGEN_INF;

	const y = $derived(
		scaleLinear()
			.domain([0, 100])
			.range([MARGEN_SUP + ALTO_UTIL, MARGEN_SUP])
	);

	const x = (columna: number) => MARGEN_IZQ + columna * (ANCHO_COL + HUECO);

	/** Las tres partes de una columna, de abajo arriba: española, italiana y lo que no es ninguna. */
	const partesDe = (punto: {
		espanola: number;
		italiana: number;
		sinTradicion: number;
	}) => {
		const partes = [
			{ nombre: 'Españolas', valor: punto.espanola, color: ESPANOLA },
			{ nombre: 'Italianas', valor: punto.italiana, color: ITALIANA },
			{ nombre: 'Sin tradición', valor: punto.sinTradicion, color: SIN }
		];
		let acumulado = 0;
		return partes
			.filter((parte) => parte.valor > 0)
			.map((parte) => {
				const desde = acumulado;
				acumulado += parte.valor;
				return { ...parte, desde };
			});
	};
</script>

<figure class="metric-tradition">
	<svg viewBox={`0 0 ${ancho} ${alto}`} role="img" aria-label="Españolas e italianas por jornadas">
		{#each [0, 25, 50, 75, 100] as valor (valor)}
			<line
				class="metric-tradition__guia"
				class:mitad={valor === 50}
				x1={MARGEN_IZQ - 6}
				x2={ancho - 8}
				y1={y(valor)}
				y2={y(valor)}
			/>
			<text
				class="metric-tradition__referencia"
				x={MARGEN_IZQ - 10}
				y={y(valor)}
				text-anchor="end"
				dominant-baseline="middle">{valor}%</text
			>
		{/each}

		{#each props.puntos as punto, indice (punto.momento)}
			{#each partesDe(punto) as parte (parte.nombre)}
				{@const altoParte = Math.max(0, y(parte.desde) - y(parte.desde + parte.valor))}
				<rect
					x={x(indice)}
					y={y(parte.desde + parte.valor)}
					width={ANCHO_COL}
					height={altoParte}
					fill={parte.color}
				>
					<title>{punto.momento}: {parte.nombre}, {parte.valor.toFixed(1)} %</title>
				</rect>
				<!-- El número va dentro de su parte, y solo si cabe: fuera se amontona con el vecino. -->
				{#if altoParte > 22}
					<text
						class="metric-tradition__valor"
						x={x(indice) + ANCHO_COL / 2}
						y={y(parte.desde + parte.valor / 2)}
						text-anchor="middle"
						dominant-baseline="middle">{parte.valor.toFixed(0)}%</text
					>
				{/if}
			{/each}

			<text
				class="metric-tradition__momento"
				x={x(indice) + ANCHO_COL / 2}
				y={MARGEN_SUP + ALTO_UTIL + 24}
				text-anchor="middle">{punto.momento}</text
			>
		{/each}
	</svg>

	<figcaption class="metric-tradition__leyenda">
		<span><span style={`background:${ESPANOLA}`}></span>Españolas</span>
		<span><span style={`background:${ITALIANA}`}></span>Italianas</span>
	</figcaption>
</figure>

<style>
	.metric-tradition {
		margin: 0;
	}

	.metric-tradition svg {
		display: block;
		width: 100%;
		max-width: 30rem;
		height: auto;
	}

	.metric-tradition__guia {
		stroke: var(--border);
		stroke-width: 1;
	}

	/* La mitad se marca más: es la referencia que dice de qué lado cae cada jornada. */
	.metric-tradition__guia.mitad {
		stroke: var(--muted-foreground);
		stroke-dasharray: 4 4;
	}

	.metric-tradition__referencia {
		font-size: 12px;
		fill: var(--muted-foreground);
	}

	.metric-tradition__valor {
		font-size: 13px;
		font-weight: 600;
		fill: #fff;
	}

	.metric-tradition__momento {
		font-size: 13px;
		font-weight: 600;
		fill: var(--muted-foreground);
		text-transform: uppercase;
		letter-spacing: 0.4px;
	}

	.metric-tradition__leyenda {
		display: flex;
		gap: 1rem;
		margin-top: 0.35rem;
		font-size: 0.75rem;
		color: var(--muted-foreground);
	}

	.metric-tradition__leyenda span span {
		display: inline-block;
		width: 0.75rem;
		height: 0.6rem;
		margin-right: 0.3rem;
		vertical-align: -0.05rem;
	}
</style>

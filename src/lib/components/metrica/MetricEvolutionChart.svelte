<script lang="ts">
	// Evolución de las formas por jornadas, REUTILIZABLE (ficha, y mañana el perfil de autor).
	//
	// **El primero del lenguaje gráfico del proyecto**, y por eso está hecho a mano con `d3-scale` y
	// SVG en vez de con una librería de gráficos: lo que se dibuja son proporciones de una obra
	// dramática, con sus colores por tradición y sus nombres de forma, y eso no encaja en los
	// valores por defecto de nadie. Las decisiones que fija:
	//
	// - **En columnas, no en barras horizontales.** Lo horizontal se reserva para lo secuencial: el
	//   código de barras recorre la obra verso a verso, y una barra apilada en horizontal se lee como
	//   si también fuera un recorrido. Aquí no hay orden que seguir —es una acumulación de formas—,
	//   así que va en vertical y no se confunde con nada.
	// - **Apiladas al cien por cien.** Lo que se compara es de qué está hecha cada jornada; sus
	//   totales no son iguales y comparar alturas absolutas engañaría.
	// - **El mismo orden de formas en todas las columnas**, el del reparto global. Si cada jornada
	//   ordenara por su propio peso, los tramos bailarían y no se podría seguir ninguno con la vista.
	// - **Las etiquetas van dentro del SVG**, para que viajen con él al exportarlo a PNG.
	import { scaleLinear } from 'd3-scale';
	import type { MetricEvolutionSeries } from './metric-display.types';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';

	const props = $props<{
		series: MetricEvolutionSeries[];
		colorByForma: Record<string, string>;
		/** El orden en que se apilan las formas: el del reparto de toda la obra. */
		orden: { forma: string; colorKey: string }[];
		onHoverForma?: (colorKey: string | null) => void;
		resaltada?: string | null;
	}>();

	const ANCHO_COL = 110;
	const HUECO = 54;
	const ALTO_UTIL = 420;
	const MARGEN_SUP = 14;
	const MARGEN_IZQ = 46;
	const MARGEN_INF = 40;

	const ancho = $derived(
		MARGEN_IZQ + props.series.length * ANCHO_COL + Math.max(0, props.series.length - 1) * HUECO + 8
	);
	const alto = MARGEN_SUP + ALTO_UTIL + MARGEN_INF;

	/** De porcentaje a coordenada: el cero abajo, que es como se lee una columna. */
	const y = $derived(
		scaleLinear()
			.domain([0, 100])
			.range([MARGEN_SUP + ALTO_UTIL, MARGEN_SUP])
	);

	const x = (columna: number) => MARGEN_IZQ + columna * (ANCHO_COL + HUECO);

	const colorDe = (colorKey: string) =>
		props.colorByForma[normalizeFormaKey(colorKey)] ?? 'var(--muted-foreground)';

	/** Cada columna, ya apilada: qué porción ocupa cada forma dentro de su jornada. */
	const columnas = $derived.by(() =>
		props.series.map((serie: MetricEvolutionSeries, indice: number) => {
			const total = serie.valores.reduce((t, v) => t + v.versos, 0) || 1;
			let acumulado = 0;
			const tramos = props.orden
				.map(({ forma, colorKey }: { forma: string; colorKey: string }) => {
					const versos = serie.valores.find((v) => v.colorKey === colorKey)?.versos ?? 0;
					const desde = (acumulado / total) * 100;
					acumulado += versos;
					return { forma, colorKey, versos, desde, porcentaje: (versos / total) * 100 };
				})
				.filter((tramo: { versos: number }) => tramo.versos > 0);
			return { serie, indice, tramos, total };
		})
	);

	const REFERENCIAS = [0, 25, 50, 75, 100];
</script>

<figure class="metric-evolution">
	<svg viewBox={`0 0 ${ancho} ${alto}`} role="img" aria-label="Evolución de las formas por jornadas">
		<!-- Las guías van detrás y muy tenues: sitúan sin competir con el color de las formas. -->
		{#each REFERENCIAS as valor (valor)}
			<line
				class="metric-evolution__guia"
				x1={MARGEN_IZQ - 6}
				x2={ancho - 8}
				y1={y(valor)}
				y2={y(valor)}
			/>
			<text
				class="metric-evolution__referencia"
				x={MARGEN_IZQ - 10}
				y={y(valor)}
				text-anchor="end"
				dominant-baseline="middle"
			>
				{valor}%
			</text>
		{/each}

		{#each columnas as columna (columna.serie.etiqueta)}
			{#each columna.tramos as tramo (tramo.colorKey)}
				<rect
					x={x(columna.indice)}
					y={y(tramo.desde + tramo.porcentaje)}
					width={ANCHO_COL}
					height={Math.max(0, y(tramo.desde) - y(tramo.desde + tramo.porcentaje))}
					fill={colorDe(tramo.colorKey)}
					opacity={props.resaltada && props.resaltada !== tramo.colorKey ? 0.25 : 1}
					role="presentation"
					onmouseenter={() => props.onHoverForma?.(tramo.colorKey)}
					onmouseleave={() => props.onHoverForma?.(null)}
				>
					<title>
						{columna.serie.etiqueta}: {tramo.forma}, {tramo.versos} versos ({tramo.porcentaje.toFixed(
							1
						)} %)
					</title>
				</rect>
			{/each}

			<text
				class="metric-evolution__etiqueta"
				x={x(columna.indice) + ANCHO_COL / 2}
				y={MARGEN_SUP + ALTO_UTIL + 24}
				text-anchor="middle"
			>
				{columna.serie.etiqueta}
			</text>
		{/each}
	</svg>
</figure>

<style>
	.metric-evolution {
		margin: 0;
	}

	/* Se deja crecer hasta un ancho cómodo y no más: estirado a toda la página, tres columnas
	   quedarían absurdamente anchas y volverían a parecer una línea de tiempo. */
	.metric-evolution svg {
		display: block;
		width: 100%;
		max-width: 32rem;
		height: auto;
	}

	.metric-evolution__guia {
		stroke: var(--border);
		stroke-width: 1;
	}

	.metric-evolution__referencia {
		font-size: 13px;
		fill: var(--muted-foreground);
	}

	.metric-evolution__etiqueta {
		font-size: 15px;
		font-weight: 600;
		fill: var(--muted-foreground);
		text-transform: uppercase;
		letter-spacing: 0.4px;
	}
</style>

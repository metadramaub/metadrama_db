<script lang="ts">
	// Evolución de las formas por jornadas, REUTILIZABLE (ficha, y mañana el perfil de autor).
	//
	// **El primero del lenguaje gráfico del proyecto**, y por eso está hecho a mano con `d3-scale` y
	// SVG en vez de con una librería de gráficos: lo que se dibuja aquí son proporciones de una obra
	// dramática, con sus colores por tradición y sus nombres de forma, y eso no encaja en los
	// valores por defecto de nadie. Las decisiones que fija:
	//
	// - **Barras apiladas y no líneas.** Lo que se compara es de qué está hecha cada jornada, no cómo
	//   sube un número; y el total de cada jornada no es el mismo, así que se apila al 100 %.
	// - **El orden de las formas es el mismo en las tres barras**, y es el del reparto global. Si
	//   cada jornada ordenara por su propio peso, los tramos bailarían y no se podría seguir ninguno.
	// - **Solo se rotula lo que cabe.** Un tramo de dos versos no lleva texto encima; se lee en el
	//   pie o al pasar por encima.
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

	// **Un espacio de coordenadas ancho y escalado uniforme.** Dibujar en porcentaje obligaría a
	// `preserveAspectRatio="none"`, que estira el texto junto con las barras; con mil unidades de
	// ancho el SVG escala entero y las letras salen proporcionadas.
	const ANCHO = 1000;
	const ALTO_BARRA = 42;
	const HUECO = 18;
	const MARGEN_IZQ = 96;
	const MARGEN_DER = 8;

	const escala = $derived(scaleLinear().domain([0, 100]).range([MARGEN_IZQ, ANCHO - MARGEN_DER]));

	const alto = $derived(props.series.length * (ALTO_BARRA + HUECO));

	const colorDe = (colorKey: string) =>
		props.colorByForma[normalizeFormaKey(colorKey)] ?? 'var(--muted-foreground)';

	/** Cada barra, ya apilada: de dónde a dónde va cada forma dentro de su jornada. */
	const barras = $derived.by(() =>
		props.series.map((serie: MetricEvolutionSeries, fila: number) => {
			const total = serie.valores.reduce((t, v) => t + v.versos, 0) || 1;
			let acumulado = 0;
			const tramos = props.orden
				.map(({ forma, colorKey }: { forma: string; colorKey: string }) => {
					const versos = serie.valores.find((v) => v.colorKey === colorKey)?.versos ?? 0;
					const desde = (acumulado / total) * 100;
					acumulado += versos;
					return {
						forma,
						colorKey,
						versos,
						desde,
						ancho: (versos / total) * 100,
						porcentaje: (versos / total) * 100
					};
				})
				.filter((tramo: { versos: number }) => tramo.versos > 0);
			return { serie, fila, tramos, total };
		})
	);

	const y = (fila: number) => fila * (ALTO_BARRA + HUECO);
</script>

<figure class="metric-evolution">
	<svg
		viewBox={`0 0 ${ANCHO} ${alto}`}
		role="img"
		aria-label="Evolución de las formas métricas por jornadas"
	>
		{#each barras as barra (barra.serie.etiqueta)}
			<!-- La etiqueta va dentro del SVG para que viaje con él al exportarlo a PNG. -->
			<text
				class="metric-evolution__etiqueta"
				x={MARGEN_IZQ - 8}
				y={y(barra.fila) + ALTO_BARRA / 2}
				text-anchor="end"
				dominant-baseline="middle"
			>
				{barra.serie.etiqueta}
			</text>

			{#each barra.tramos as tramo (tramo.colorKey)}
				<rect
					x={escala(tramo.desde)}
					y={y(barra.fila)}
					width={Math.max(0, escala(tramo.desde + tramo.ancho) - escala(tramo.desde))}
					height={ALTO_BARRA}
					fill={colorDe(tramo.colorKey)}
					opacity={props.resaltada && props.resaltada !== tramo.colorKey ? 0.25 : 1}
					role="presentation"
					onmouseenter={() => props.onHoverForma?.(tramo.colorKey)}
					onmouseleave={() => props.onHoverForma?.(null)}
				>
					<title>
						{barra.serie.etiqueta}: {tramo.forma}, {tramo.versos} versos ({tramo.porcentaje.toFixed(
							1
						)} %)
					</title>
				</rect>
			{/each}
		{/each}
	</svg>
</figure>

<style>
	.metric-evolution {
		margin: 0;
	}

	.metric-evolution svg {
		display: block;
		width: 100%;
		height: auto;
	}

	.metric-evolution__etiqueta {
		font-size: 15px;
		font-weight: 600;
		fill: var(--muted-foreground);
		text-transform: uppercase;
		letter-spacing: 0.4px;
	}

	.metric-evolution rect {
		cursor: default;
	}
</style>

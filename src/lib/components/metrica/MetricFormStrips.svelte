<script lang="ts">
	// Dónde cae cada forma a lo largo de la obra. REUTILIZABLE y exportable como SVG puro.
	// Cada tirada conserva su posición exacta: no hay ventanas ni interpolación.
	import { scaleLinear } from 'd3-scale';
	import type { MetricStripRow } from './metric-display.types';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';

	const props = $props<{
		filas: MetricStripRow[];
		totalVersos: number;
		colorByForma: Record<string, string>;
		jornadas?: number[];
		onHoverForma?: (colorKey: string | null) => void;
		resaltada?: string | null;
	}>();

	const ANCHO = 1000;
	const MARGEN_IZQ = 205;
	const MARGEN_DER = 70;
	const ALTO_FILA = 25;
	const ALTO_PISTA = 17;
	const MARGEN_SUP = 4;
	const alto = $derived(Math.max(1, props.filas.length) * ALTO_FILA + MARGEN_SUP * 2);
	const escala = $derived(
		scaleLinear()
			.domain([1, Math.max(2, props.totalVersos)])
			.range([MARGEN_IZQ, ANCHO - MARGEN_DER])
	);
	const colorDe = (colorKey: string) =>
		props.colorByForma[normalizeFormaKey(colorKey)] ?? 'var(--muted-foreground)';
	const anchoTirada = (vIni: number, vFin: number) => Math.max(2, escala(vFin + 1) - escala(vIni));
</script>

<figure class="metric-strips">
	<svg viewBox={`0 0 ${ANCHO} ${alto}`} role="img" aria-label="Dónde cae cada forma en la obra">
		{#each props.filas as fila, index (fila.colorKey)}
			{@const y = MARGEN_SUP + index * ALTO_FILA}
			{@const apagada = props.resaltada && props.resaltada !== fila.colorKey}
			<g
				opacity={apagada ? 0.3 : 1}
				onmouseenter={() => props.onHoverForma?.(fila.colorKey)}
				onmouseleave={() => props.onHoverForma?.(null)}
			>
				<text class="metric-strips__nombre" x={MARGEN_IZQ - 12} y={y + ALTO_PISTA / 2}>
					{fila.forma}
				</text>
				<rect
					x={MARGEN_IZQ}
					y={y}
					width={ANCHO - MARGEN_IZQ - MARGEN_DER}
					height={ALTO_PISTA}
					fill="var(--gray-50, #f7f7f7)"
				/>
				{#each props.jornadas ?? [] as corte (corte)}
					<line
						class="metric-strips__jornada"
						x1={escala(corte)} x2={escala(corte)} y1={y - 2} y2={y + ALTO_PISTA + 2}
					/>
				{/each}
				{#each fila.tiradas as tirada (tirada.v_ini)}
					<rect
						x={escala(tirada.v_ini)}
						y={y}
						width={anchoTirada(tirada.v_ini, tirada.v_fin)}
						height={ALTO_PISTA}
						fill={colorDe(fila.colorKey)}
					>
						<title>{fila.forma}, vv. {tirada.v_ini}-{tirada.v_fin}</title>
					</rect>
				{/each}
				<text class="metric-strips__cuantos" x={ANCHO - 4} y={y + ALTO_PISTA / 2}>
					{fila.porcentaje.toFixed(1)}%
				</text>
			</g>
		{/each}
	</svg>
</figure>

<style>
	.metric-strips { margin: 0; }
	.metric-strips svg { display: block; width: 100%; height: auto; }
	.metric-strips__nombre {
		font-size: 13px;
		font-weight: 600;
		text-anchor: end;
		dominant-baseline: middle;
	}
	.metric-strips__jornada { stroke: var(--gray-800); stroke-width: 1; opacity: 0.35; }
	.metric-strips__cuantos {
		font-size: 13px;
		fill: var(--muted-foreground);
		text-anchor: end;
		dominant-baseline: middle;
		font-variant-numeric: tabular-nums;
	}
</style>

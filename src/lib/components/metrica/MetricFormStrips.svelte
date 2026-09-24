<script lang="ts">
	// Dónde cae cada forma a lo largo de la obra. REUTILIZABLE y descargable.
	// Cada secuencia conserva su posición exacta: no hay ventanas ni interpolación.
	//
	// **Los estilos van como atributos y no como clases**, con los valores de `$lib/figuras/tema`:
	// el mismo SVG se descarga, y fuera de la página no hay hoja de estilos que los resuelva.
	//
	// En modo `figura` —lo que baja del modal— no hay interacción y aparecen dos cosas que en
	// pantalla sobran porque el ratón las da: **un eje de versos**, sin el que en un artículo no se
	// sabe dónde cae nada, y el sello, en la columna de nombres a la altura del eje. En blanco y
	// negro todas las franjas van en el mismo gris: cada fila ya dice su forma al lado.
	import { scaleLinear } from 'd3-scale';
	import type { MetricStripRow } from './metric-display.types';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';
	import SelloFigura from '$lib/components/figuras/SelloFigura.svelte';
	import { CUERPO, GRISES, TINTA } from '$lib/figuras/tema';
	import type { Paleta } from '$lib/figuras/tipos';

	const props = $props<{
		filas: MetricStripRow[];
		totalVersos: number;
		colorByForma: Record<string, string>;
		jornadas?: number[];
		onOpenSequence?: (sequenceId: string) => void;
		onHoverForma?: (colorKey: string | null) => void;
		resaltada?: string | null;
		modo?: 'pantalla' | 'figura';
		paleta?: Paleta;
	}>();

	const ANCHO = 1000;
	const MARGEN_IZQ = 205;
	const MARGEN_DER = 70;
	const ALTO_FILA = 25;
	const ALTO_PISTA = 17;
	const MARGEN_SUP = 4;
	/** El eje de versos, solo en la figura: rayita, número y aire. */
	const ALTO_EJE = 30;

	const figura = $derived(props.modo === 'figura');
	const altoFilas = $derived(Math.max(1, props.filas.length) * ALTO_FILA + MARGEN_SUP * 2);
	const alto = $derived(altoFilas + (figura ? ALTO_EJE : 0));
	const escala = $derived(
		scaleLinear()
			.domain([1, Math.max(2, props.totalVersos)])
			.range([MARGEN_IZQ, ANCHO - MARGEN_DER])
	);
	const marcas = $derived(escala.ticks(8).filter((verso) => verso >= 1));
	const numero = (valor: number) => valor.toLocaleString('es-ES');
	const colorDe = (colorKey: string) =>
		props.paleta === 'grises'
			? GRISES[1]
			: (props.colorByForma[normalizeFormaKey(colorKey)] ?? TINTA.neutro);
	const anchoSecuencia = (vIni: number, vFin: number) => Math.max(2, escala(vFin + 1) - escala(vIni));

	function abrir(secuenciaId: string) {
		props.onOpenSequence?.(secuenciaId);
	}
</script>

{#snippet lienzo()}
	<svg
		viewBox={`0 0 ${ANCHO} ${alto}`}
		role="img"
		aria-label="Dónde cae cada forma en la obra"
		data-figura={figura ? '' : undefined}
	>
		{#each props.filas as fila, index (fila.colorKey)}
			{@const y = MARGEN_SUP + index * ALTO_FILA}
			{@const apagada = !figura && props.resaltada && props.resaltada !== fila.colorKey}
			<g
				role="group"
				opacity={apagada ? 0.3 : 1}
				onmouseenter={figura ? undefined : () => props.onHoverForma?.(fila.colorKey)}
				onmouseleave={figura ? undefined : () => props.onHoverForma?.(null)}
			>
				<text
					x={MARGEN_IZQ - 12}
					y={y + ALTO_PISTA / 2}
					font-size={CUERPO.rotulo}
					font-weight="600"
					fill={TINTA.texto}
					text-anchor="end"
					dominant-baseline="middle">{fila.forma}</text
				>
				<rect
					x={MARGEN_IZQ}
					y={y}
					width={ANCHO - MARGEN_IZQ - MARGEN_DER}
					height={ALTO_PISTA}
					fill={TINTA.pista}
				/>
				{#each props.jornadas ?? [] as corte (corte)}
					<line
						x1={escala(corte)}
						x2={escala(corte)}
						y1={y - 2}
						y2={y + ALTO_PISTA + 2}
						stroke={TINTA.corte}
						stroke-width="1"
						opacity="0.35"
					/>
				{/each}
				{#each fila.secuencias as secuencia (secuencia.secuencia_id)}
					{#if figura}
						<rect
							x={escala(secuencia.v_ini)}
							y={y}
							width={anchoSecuencia(secuencia.v_ini, secuencia.v_fin)}
							height={ALTO_PISTA}
							fill={colorDe(fila.colorKey)}
						/>
					{:else}
						<g
							role="button"
							tabindex="0"
							aria-label={`Abrir ${fila.forma}, versos ${secuencia.v_ini}–${secuencia.v_fin}`}
							onclick={() => abrir(secuencia.secuencia_id)}
							onkeydown={(event) => {
								if (event.key === 'Enter' || event.key === ' ') {
									event.preventDefault();
									abrir(secuencia.secuencia_id);
								}
							}}
							class="metric-strips__secuencia-interactiva"
						>
							<rect
								x={escala(secuencia.v_ini)}
								y={y}
								width={anchoSecuencia(secuencia.v_ini, secuencia.v_fin)}
								height={ALTO_PISTA}
								fill={colorDe(fila.colorKey)}
							>
								<title>{fila.forma}, vv. {secuencia.v_ini}-{secuencia.v_fin}</title>
							</rect>
						</g>
					{/if}
				{/each}
				<text
					x={ANCHO - 4}
					y={y + ALTO_PISTA / 2}
					font-size={CUERPO.rotulo}
					fill={TINTA.secundario}
					text-anchor="end"
					dominant-baseline="middle"
					style="font-variant-numeric: tabular-nums">{fila.porcentaje.toFixed(2)}%</text
				>
			</g>
		{/each}

		{#if figura}
			{@const ejeY = altoFilas}
			<line
				x1={MARGEN_IZQ}
				x2={ANCHO - MARGEN_DER}
				y1={ejeY}
				y2={ejeY}
				stroke={TINTA.secundario}
				stroke-width="1"
			/>
			{#each marcas as verso (verso)}
				<line x1={escala(verso)} x2={escala(verso)} y1={ejeY} y2={ejeY + 4} stroke={TINTA.secundario} />
				<text
					x={escala(verso)}
					y={ejeY + 16}
					font-size={CUERPO.menor}
					fill={TINTA.secundario}
					text-anchor="middle">{numero(verso)}</text
				>
			{/each}
			<text
				x={ANCHO - MARGEN_DER + 8}
				y={ejeY + 16}
				font-size={CUERPO.menor}
				fill={TINTA.secundario}>versos</text
			>
			<SelloFigura x={MARGEN_IZQ - 12} y={ejeY + 16} anchor="end" />
		{/if}
	</svg>
{/snippet}

{#if figura}
	{@render lienzo()}
{:else}
	<figure class="metric-strips">
		{@render lienzo()}
	</figure>
{/if}

<style>
	.metric-strips { margin: 0; }
	.metric-strips :global(svg) { display: block; width: 100%; height: auto; }
	.metric-strips__secuencia-interactiva { cursor: pointer; }
	.metric-strips__secuencia-interactiva:focus rect {
		stroke: var(--foreground);
		stroke-width: 2;
	}
</style>

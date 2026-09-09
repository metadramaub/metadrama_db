<script lang="ts">
	// Dónde cae cada forma a lo largo de la obra. REUTILIZABLE.
	//
	// **Es exacto y no interpola nada.** Se llegó aquí descartando un área apilada por ventanas:
	// dentro de una obra no hay ventana buena. Ancha —150 versos, que es lo que hace falta para
	// suavizar una tirada media de cien— esconde un soneto de catorce; estrecha, cada ventana
	// contiene una secuencia y el área converge al código de barras. No es cuestión de afinar el
	// número: el gráfico de ventanas pertenece al corpus por años, donde cada punto es una obra
	// entera y diluir un soneto es justamente lo que se quiere.
	//
	// Aquí, en cambio, cada forma tiene su renglón y sus tiradas se marcan donde caen. Una forma que
	// solo aparece una vez sale como una marca fina, pero **sale**, y en su sitio. De un golpe se ve
	// que el romance se acumula al final, que la sextina es un episodio único y que la redondilla
	// está en todas partes.
	//
	// Usa el eje horizontal, y con razón: es lo secuencial.
	import { scaleLinear } from 'd3-scale';
	import type { MetricStripRow } from './metric-display.types';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';

	const props = $props<{
		filas: MetricStripRow[];
		totalVersos: number;
		colorByForma: Record<string, string>;
		/** Los cortes de jornada, para situarse. */
		jornadas?: number[];
		onHoverForma?: (colorKey: string | null) => void;
		resaltada?: string | null;
	}>();

	const escala = $derived(
		scaleLinear()
			.domain([1, Math.max(2, props.totalVersos)])
			.range([0, 100])
	);

	const colorDe = (colorKey: string) =>
		props.colorByForma[normalizeFormaKey(colorKey)] ?? 'var(--muted-foreground)';

	/** El ancho mínimo para que una tirada de catorce versos siga viéndose en 3.000. */
	const ancho = (v_ini: number, v_fin: number) =>
		Math.max(0.35, escala(v_fin + 1) - escala(v_ini));
</script>

<div class="metric-strips">
	{#each props.filas as fila (fila.colorKey)}
		{@const apagada = props.resaltada && props.resaltada !== fila.colorKey}
		<div
			class="metric-strips__fila"
			style={`opacity:${apagada ? 0.3 : 1}`}
			role="presentation"
			onmouseenter={() => props.onHoverForma?.(fila.colorKey)}
			onmouseleave={() => props.onHoverForma?.(null)}
		>
			<span class="metric-strips__nombre">{fila.forma}</span>
			<span class="metric-strips__pista">
				{#each props.jornadas ?? [] as corte (corte)}
					<span class="metric-strips__jornada" style={`left:${escala(corte)}%`}></span>
				{/each}
				{#each fila.tiradas as tirada (tirada.v_ini)}
					<span
						class="metric-strips__tirada"
						style={`left:${escala(tirada.v_ini)}%;width:${ancho(tirada.v_ini, tirada.v_fin)}%;background:${colorDe(fila.colorKey)}`}
						title={`${fila.forma}, vv. ${tirada.v_ini}-${tirada.v_fin}`}
					></span>
				{/each}
			</span>
			<span class="metric-strips__cuantos">{fila.porcentaje.toFixed(1)}%</span>
		</div>
	{/each}
</div>

<style>
	.metric-strips {
		display: flex;
		flex-direction: column;
		gap: 2px;
		font-size: 0.8125rem;
	}

	.metric-strips__fila {
		display: grid;
		grid-template-columns: 10rem minmax(0, 1fr) 3rem;
		align-items: center;
		gap: 0.75rem;
	}

	.metric-strips__nombre {
		text-align: right;
		font-weight: 600;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
	}

	.metric-strips__pista {
		position: relative;
		display: block;
		height: 1.1rem;
		background: var(--gray-50, rgb(0 0 0 / 3%));
	}

	.metric-strips__tirada {
		position: absolute;
		top: 0;
		bottom: 0;
	}

	/* Los cortes de jornada, por detrás: sitúan sin taparse con las tiradas. */
	.metric-strips__jornada {
		position: absolute;
		top: -2px;
		bottom: -2px;
		width: 1px;
		background: var(--gray-800, currentColor);
		opacity: 0.35;
	}

	.metric-strips__cuantos {
		text-align: right;
		font-variant-numeric: tabular-nums;
		color: var(--muted-foreground);
	}
</style>

<script lang="ts">
	// Cómo cambia cada forma de una jornada a otra. REUTILIZABLE y descargable.
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
	// - **En blanco y negro, gris y trazo.** Cada forma va rotulada al final de su línea, así que el
	//   color no hace falta para saber cuál es cuál; pero donde se cruzan hay que poder seguirlas, y
	//   con tres grises y tres trazos no se repite ninguna hasta la décima.
	// - Los estilos van como atributos, con los valores de `$lib/figuras/tema`: el SVG se descarga
	//   tal cual. En modo `figura` el sello va de canto junto a las referencias de porcentaje.
	// - **Cada nombre va unido a su línea por una guía** y lleva su cifra. Apilados para que no se
	//   monten, los nombres quedaban lejos del final de su línea, y con doce colores parecidos no
	//   había manera de saber cuál era cuál.
	// - **Las formas menores pueden ir en segundo plano** (`destacadas`): en gris fino, sin nombre
	//   al final, y nombradas aparte. Diez líneas entre el 0 y el 20 % no se leen; cinco, sí.
	//   Al pasar por una se enciende con su color, su nombre y su valor en cada jornada.
	import { scaleLinear, scalePoint } from 'd3-scale';
	import type { MetricSlopeSeries } from './metric-display.types';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';
	import SelloFigura from '$lib/components/figuras/SelloFigura.svelte';
	import { CUERPO, TINTA, trazoEnGrises } from '$lib/figuras/tema';
	import type { Paleta } from '$lib/figuras/tipos';

	const props = $props<{
		/** Los momentos, en orden: las jornadas. */
		momentos: string[];
		series: MetricSlopeSeries[];
		colorByForma: Record<string, string>;
		onHoverForma?: (colorKey: string | null) => void;
		resaltada?: string | null;
		modo?: 'pantalla' | 'figura';
		paleta?: Paleta;
		/** Cuántas formas, por orden de peso en la obra, van en color y con nombre. Sin él, todas. */
		destacadas?: number | null;
	}>();

	const ALTO_UTIL = 300;
	const MARGEN_SUP = 18;
	const MARGEN_INF = 38;
	const MARGEN_DER = 230; // Sitio para la guía, el nombre y la cifra, que van a la derecha.
	/** Dónde acaba la guía y empieza el nombre, desde el último momento. */
	const SANGRIA_ETIQUETA = 34;
	const GRIS_MENOR = '#bdbdbd';
	/** Lo que se ensancha la figura por la izquierda para que quepa el sello de canto. */
	const SITIO_SELLO = 18;

	const figura = $derived(props.modo === 'figura');
	const margenIzq = $derived(46 + (figura ? SITIO_SELLO : 0));
	const ancho = $derived(840 + (figura ? SITIO_SELLO : 0));
	const alto = MARGEN_SUP + ALTO_UTIL + MARGEN_INF;
	const resaltada = $derived(figura ? null : (props.resaltada ?? null));

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
			.range([margenIzq, ancho - MARGEN_DER])
	);

	/** Color y trazo de cada serie, según la paleta. */
	const estilos = $derived(
		new Map<string, { color: string; trazo: string }>(
			props.series.map((serie: MetricSlopeSeries, indice: number): [string, { color: string; trazo: string }] => [
				serie.colorKey,
				props.paleta === 'grises'
					? trazoEnGrises(indice)
					: {
							color: props.colorByForma[normalizeFormaKey(serie.colorKey)] ?? TINTA.neutro,
							trazo: ''
						}
			])
		)
	);
	/** Las formas en segundo plano: las que pasan del número de destacadas, por orden de peso. */
	const menores = $derived(
		new Set(
			props.destacadas == null
				? []
				: props.series.slice(props.destacadas).map((serie: MetricSlopeSeries) => serie.colorKey)
		)
	);
	/** Una menor se enciende al pasar por ella: color, grosor, nombre y valores. */
	const enSegundoPlano = (colorKey: string) => menores.has(colorKey) && resaltada !== colorKey;
	const colorDe = (colorKey: string) =>
		enSegundoPlano(colorKey) ? GRIS_MENOR : (estilos.get(colorKey)?.color ?? TINTA.neutro);
	const trazoDe = (colorKey: string) => estilos.get(colorKey)?.trazo || undefined;
	const apagada = (colorKey: string) => resaltada !== null && resaltada !== colorKey;
	/** Se pinta primero lo de fondo y al final lo resaltado, para que quede encima. */
	const ordenDePintado = $derived(
		[...props.series].sort(
			(a: MetricSlopeSeries, b: MetricSlopeSeries) =>
				Number(!menores.has(a.colorKey)) - Number(!menores.has(b.colorKey)) ||
				Number(a.colorKey === resaltada) - Number(b.colorKey === resaltada)
		)
	);
	const ultimo = $derived(props.momentos[props.momentos.length - 1]);
	const valorFinal = (serie: MetricSlopeSeries) => serie.valores[serie.valores.length - 1] ?? 0;
	const cifra = (valor: number) => `${valor.toFixed(2)}%`;

	const trazo = (valores: (number | null)[]) =>
		props.momentos
			.map((momento: string, i: number) => `${i === 0 ? 'M' : 'L'}${x(momento)},${y(valores[i] ?? 0)}`)
			.join(' ');

	/**
	 * Dónde se rotula cada forma: en su extremo derecho, apartándolas si se solapan.
	 *
	 * Sin separarlas, cuatro formas del 2 % se escriben una encima de otra. Separándolas solo hacia
	 * abajo, la pila se sale por el suelo. Y subiendo la pila entera cuando eso pasa, **la de arriba
	 * se sale por el techo**: así desapareció la etiqueta de la redondilla, que es la que más pesa.
	 *
	 * Lo que funciona son dos pasadas: una hacia abajo separando, otra hacia arriba desde la última
	 * empujando lo que se haya salido, y un tope en cada extremo. Es lo mismo que hace cualquier
	 * colocador de etiquetas, y no se descubre hasta que una se pierde.
	 */
	const etiquetas = $derived.by(() => {
		const ALTO_LINEA = 15;
		const TECHO = MARGEN_SUP + 6;
		const SUELO = MARGEN_SUP + ALTO_UTIL;

		const puestas = props.series
			.filter((serie: MetricSlopeSeries) => !enSegundoPlano(serie.colorKey))
			.map((serie: MetricSlopeSeries) => ({
				serie,
				valor: serie.valores[serie.valores.length - 1] ?? 0,
				y: y(serie.valores[serie.valores.length - 1] ?? 0)
			}))
			.sort((a: { y: number }, b: { y: number }) => a.y - b.y);

		for (let i = 0; i < puestas.length; i += 1) {
			const minimo = i === 0 ? TECHO : puestas[i - 1].y + ALTO_LINEA;
			puestas[i].y = Math.max(puestas[i].y, minimo);
		}
		for (let i = puestas.length - 1; i >= 0; i -= 1) {
			const maximo = i === puestas.length - 1 ? SUELO : puestas[i + 1].y - ALTO_LINEA;
			puestas[i].y = Math.min(puestas[i].y, maximo);
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

{#snippet lienzo()}
	<svg
		viewBox={`0 0 ${ancho} ${alto}`}
		role="img"
		aria-label="Cambio de cada forma por jornadas"
		data-figura={figura ? '' : undefined}
	>
		{#each menudas as valor (valor)}
			<line
				x1={margenIzq - 6}
				x2={ancho - MARGEN_DER + 6}
				y1={y(valor)}
				y2={y(valor)}
				stroke={TINTA.guia}
				stroke-width="1"
				opacity="0.4"
			/>
		{/each}

		{#each referencias as valor (valor)}
			<line
				x1={margenIzq - 6}
				x2={ancho - MARGEN_DER + 6}
				y1={y(valor)}
				y2={y(valor)}
				stroke={TINTA.guia}
				stroke-width="1"
			/>
			<text
				x={margenIzq - 10}
				y={y(valor)}
				font-size={CUERPO.referencia}
				fill={TINTA.secundario}
				text-anchor="end"
				dominant-baseline="middle">{valor}%</text
			>
		{/each}

		{#each props.momentos as momento (momento)}
			<text
				x={x(momento)}
				y={MARGEN_SUP + ALTO_UTIL + 24}
				font-size={CUERPO.rotulo}
				font-weight="600"
				fill={TINTA.secundario}
				letter-spacing="0.4"
				text-anchor="middle">{momento.toLocaleUpperCase('es')}</text
			>
		{/each}

		{#each ordenDePintado as serie (serie.colorKey)}
			{@const fondo = enSegundoPlano(serie.colorKey)}
			<path
				class:metric-slope__interactiva={!figura}
				d={trazo(serie.valores)}
				fill="none"
				stroke={colorDe(serie.colorKey)}
				stroke-width={fondo ? 1.25 : 2.5}
				stroke-linejoin="round"
				stroke-dasharray={trazoDe(serie.colorKey)}
				opacity={apagada(serie.colorKey) ? 0.15 : 1}
				role="presentation"
				onmouseenter={figura ? undefined : () => props.onHoverForma?.(serie.colorKey)}
				onmouseleave={figura ? undefined : () => props.onHoverForma?.(null)}
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
					r={fondo ? 2.5 : valor === 0 ? 3.5 : 4}
					fill={valor === 0 ? TINTA.fondo : colorDe(serie.colorKey)}
					stroke={valor === 0 ? colorDe(serie.colorKey) : 'none'}
					stroke-width={valor === 0 ? 1.5 : 0}
					opacity={apagada(serie.colorKey) ? 0.15 : 1}
				>
					<title>
						{serie.forma}, {momento}: {valor === 0 ? 'no aparece' : `${valor.toFixed(2)} %`}
					</title>
				</circle>
			{/each}
		{/each}

		<!-- Al pasar por una forma, su valor en cada jornada, sobre cada punto. -->
		{#if !figura && resaltada}
			{@const serie = props.series.find((s: MetricSlopeSeries) => s.colorKey === resaltada)}
			{#if serie}
				{#each props.momentos as momento, i (momento)}
					<text
						x={x(momento)}
						y={y(serie.valores[i] ?? 0) - 10}
						font-size={CUERPO.menor}
						font-weight="600"
						fill={colorDe(serie.colorKey)}
						stroke={TINTA.fondo}
						stroke-width="3"
						paint-order="stroke"
						text-anchor="middle">{cifra(serie.valores[i] ?? 0)}</text
					>
				{/each}
			{/if}
		{/if}

		{#each etiquetas as etiqueta (etiqueta.serie.colorKey)}
			{@const xFinal = x(ultimo) ?? 0}
			{@const yFinal = y(valorFinal(etiqueta.serie))}
			<!-- La guía: del final de la línea al nombre, en su color. Sale recta unos píxeles y luego
			     sube o baja hasta donde el nombre ha tenido sitio. -->
			<path
				d={`M${xFinal + 6},${yFinal} L${xFinal + 14},${yFinal} L${xFinal + SANGRIA_ETIQUETA - 5},${etiqueta.y}`}
				fill="none"
				stroke={colorDe(etiqueta.serie.colorKey)}
				stroke-width="1"
				opacity={apagada(etiqueta.serie.colorKey) ? 0.15 : 0.7}
			/>
			<!-- El nombre también resalta: es lo que la mano busca, más que la línea. En grises va en
			     negro: un rótulo gris claro no se lee impreso. -->
			<text
				class:metric-slope__interactiva={!figura}
				x={xFinal + SANGRIA_ETIQUETA}
				y={etiqueta.y}
				font-size={CUERPO.referencia}
				dominant-baseline="middle"
				opacity={apagada(etiqueta.serie.colorKey) ? 0.25 : 1}
				role="presentation"
				onmouseenter={figura ? undefined : () => props.onHoverForma?.(etiqueta.serie.colorKey)}
				onmouseleave={figura ? undefined : () => props.onHoverForma?.(null)}
			>
				<tspan
					font-weight="600"
					fill={props.paleta === 'grises' ? TINTA.texto : colorDe(etiqueta.serie.colorKey)}
					>{etiqueta.serie.forma}</tspan
				><tspan fill={TINTA.secundario} dx="6">{cifra(etiqueta.valor)}</tspan>
			</text>
		{/each}

		{#if figura}
			<SelloFigura x={12} y={MARGEN_SUP + ALTO_UTIL} vertical />
		{/if}
	</svg>
{/snippet}

{#if figura}
	{@render lienzo()}
{:else}
	<figure class="metric-slope">
		{@render lienzo()}
	</figure>
{/if}

<style>
	.metric-slope {
		margin: 0;
	}

	.metric-slope :global(svg) {
		display: block;
		width: 100%;
		max-width: 52rem;
		height: auto;
	}

	.metric-slope__interactiva {
		cursor: default;
	}
</style>

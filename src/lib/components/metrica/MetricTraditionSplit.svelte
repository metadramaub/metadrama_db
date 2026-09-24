<script lang="ts" module>
	import { colorForForma } from '$lib/utils/metric-colors';
	import { GRISES, TINTA } from '$lib/figuras/tema';
	import type { ItemLeyenda, Paleta } from '$lib/figuras/tipos';

	type Parte = 'espanola' | 'italiana' | 'sinTradicion';

	/**
	 * El color de cada tradición en cada paleta, y el del número que va encima.
	 *
	 * En grises, **la española oscura y la italiana clara**, con el número en blanco sobre la
	 * oscura y en negro sobre la clara: la mitad de la columna tiene que seguir leyéndose en una
	 * fotocopia.
	 */
	export function coloresDeTradicion(paleta: Paleta): Record<Parte, { fondo: string; cifra: string }> {
		if (paleta === 'grises') {
			return {
				espanola: { fondo: GRISES[1], cifra: TINTA.fondo },
				italiana: { fondo: GRISES[3], cifra: TINTA.texto },
				sinTradicion: { fondo: TINTA.guia, cifra: TINTA.texto }
			};
		}
		return {
			espanola: { fondo: colorForForma({ slug: null, tipoForma: 'forma_espanola' }), cifra: TINTA.fondo },
			italiana: { fondo: colorForForma({ slug: null, tipoForma: 'forma_italiana' }), cifra: TINTA.fondo },
			sinTradicion: { fondo: colorForForma({ slug: null, tipoForma: null }), cifra: TINTA.fondo }
		};
	}

	const NOMBRES: Record<Parte, string> = {
		espanola: 'Españolas',
		italiana: 'Italianas',
		sinTradicion: 'Sin tradición'
	};

	/** La leyenda de la figura descargada: las tres partes, en la paleta elegida. */
	export function leyendaDeTradiciones(paleta: Paleta, conSinTradicion: boolean): ItemLeyenda[] {
		const colores = coloresDeTradicion(paleta);
		return (Object.keys(NOMBRES) as Parte[])
			.filter((parte) => conSinTradicion || parte !== 'sinTradicion')
			.map((parte) => ({ etiqueta: NOMBRES[parte], color: colores[parte].fondo }));
	}
</script>

<script lang="ts">
	// Españolas contra italianas, jornada a jornada. REUTILIZABLE y descargable.
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
	//
	// Los estilos van como atributos: el SVG se descarga tal cual. En modo `figura` la leyenda la
	// pone el pie de la figura y el sello va de canto junto a las referencias de porcentaje.
	import { scaleLinear } from 'd3-scale';
	import SelloFigura from '$lib/components/figuras/SelloFigura.svelte';
	import { CUERPO } from '$lib/figuras/tema';

	const props = $props<{
		puntos: { momento: string; espanola: number; italiana: number; sinTradicion: number }[];
		modo?: 'pantalla' | 'figura';
		paleta?: Paleta;
	}>();

	const ANCHO_COL = 96;
	const HUECO = 56;
	const ALTO_UTIL = 260;
	const MARGEN_SUP = 14;
	const MARGEN_INF = 38;
	const SITIO_SELLO = 18;

	const figura = $derived(props.modo === 'figura');
	const colores = $derived(coloresDeTradicion(props.paleta ?? 'color'));
	const margenIzq = $derived(46 + (figura ? SITIO_SELLO : 0));

	const ancho = $derived(
		margenIzq + props.puntos.length * ANCHO_COL + Math.max(0, props.puntos.length - 1) * HUECO + 8
	);
	const alto = MARGEN_SUP + ALTO_UTIL + MARGEN_INF;

	const y = $derived(
		scaleLinear()
			.domain([0, 100])
			.range([MARGEN_SUP + ALTO_UTIL, MARGEN_SUP])
	);

	const x = (columna: number) => margenIzq + columna * (ANCHO_COL + HUECO);

	/** Las tres partes de una columna, de abajo arriba: española, italiana y lo que no es ninguna. */
	const partesDe = (punto: { espanola: number; italiana: number; sinTradicion: number }) => {
		let acumulado = 0;
		return (['espanola', 'italiana', 'sinTradicion'] as Parte[])
			.map((parte) => ({ parte, nombre: NOMBRES[parte], valor: punto[parte], ...colores[parte] }))
			.filter((parte) => parte.valor > 0)
			.map((parte) => {
				const desde = acumulado;
				acumulado += parte.valor;
				return { ...parte, desde };
			});
	};
</script>

{#snippet lienzo()}
	<svg
		viewBox={`0 0 ${ancho} ${alto}`}
		role="img"
		aria-label="Españolas e italianas por jornadas"
		data-figura={figura ? '' : undefined}
	>
		{#each [0, 25, 50, 75, 100] as valor (valor)}
			<!-- La mitad se marca más: es la referencia que dice de qué lado cae cada jornada. -->
			<line
				x1={margenIzq - 6}
				x2={ancho - 8}
				y1={y(valor)}
				y2={y(valor)}
				stroke={valor === 50 ? TINTA.secundario : TINTA.guia}
				stroke-width="1"
				stroke-dasharray={valor === 50 ? '4 4' : undefined}
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

		{#each props.puntos as punto, indice (punto.momento)}
			{#each partesDe(punto) as parte (parte.nombre)}
				{@const altoParte = Math.max(0, y(parte.desde) - y(parte.desde + parte.valor))}
				<rect
					x={x(indice)}
					y={y(parte.desde + parte.valor)}
					width={ANCHO_COL}
					height={altoParte}
					fill={parte.fondo}
				>
					<title>{punto.momento}: {parte.nombre}, {parte.valor.toFixed(2)} %</title>
				</rect>
				<!-- El número va dentro de su parte, y solo si cabe: fuera se amontona con el vecino.
				     Dos decimales, que es la norma del proyecto para cualquier porcentaje. -->
				{#if altoParte > 22}
					<text
						x={x(indice) + ANCHO_COL / 2}
						y={y(parte.desde + parte.valor / 2)}
						font-size={CUERPO.rotulo}
						font-weight="600"
						fill={parte.cifra}
						text-anchor="middle"
						dominant-baseline="middle">{parte.valor.toFixed(2)}%</text
					>
				{/if}
			{/each}

			<text
				x={x(indice) + ANCHO_COL / 2}
				y={MARGEN_SUP + ALTO_UTIL + 24}
				font-size={CUERPO.rotulo}
				font-weight="600"
				fill={TINTA.secundario}
				letter-spacing="0.4"
				text-anchor="middle">{punto.momento.toLocaleUpperCase('es')}</text
			>
		{/each}

		{#if figura}
			<SelloFigura x={12} y={MARGEN_SUP + ALTO_UTIL} vertical />
		{/if}
	</svg>
{/snippet}

{#if figura}
	{@render lienzo()}
{:else}
	<figure class="metric-tradition">
		{@render lienzo()}

		<figcaption class="metric-tradition__leyenda">
			<span><span style={`background:${colores.espanola.fondo}`}></span>Españolas</span>
			<span><span style={`background:${colores.italiana.fondo}`}></span>Italianas</span>
		</figcaption>
	</figure>
{/if}

<style>
	.metric-tradition {
		margin: 0;
	}

	.metric-tradition :global(svg) {
		display: block;
		width: 100%;
		max-width: 30rem;
		height: auto;
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

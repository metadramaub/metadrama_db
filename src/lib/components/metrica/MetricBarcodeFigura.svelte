<script lang="ts" module>
	import type { MetricBarSegment } from './metric-display.types';

	export type FilaDeBarras = {
		etiqueta: string;
		desde: number;
		hasta: number;
		segmentos: MetricBarSegment[];
		/** Último verso de cada jornada que acaba dentro de la fila. */
		cortesJornada?: number[];
		/** Último verso de cada cuadro que acaba dentro de la fila. */
		cortesCuadro?: number[];
		/** Las jornadas rotuladas encima de la barra, cuando la fila es la obra entera. */
		jornadas?: { etiqueta: string; desde: number; hasta: number }[];
	};
</script>

<script lang="ts">
	// El código de barras métrico como figura para descargar.
	//
	// **Es un componente aparte del de pantalla, y a propósito.** `MetricBarcode` es un control:
	// se estira al ancho que le den —su `viewBox` mide 100 y no guarda proporción—, lleva encima los
	// botones y los avisos de cada secuencia, y lo usan también el buscador y las tarjetas en tamaños
	// de un centímetro. Exportarlo era llevarse todo eso: el exportador anterior lo multiplicaba por
	// doce de alto y apilaba debajo las flechas de los avisos.
	//
	// Aquí todo está en coordenadas reales y lleva lo que en pantalla da el ratón y en un artículo
	// no hay quien dé: **a la izquierda qué fila es y qué versos abarca, debajo un eje de versos, y
	// encima el nombre de cada jornada**. La leyenda de formas y de cortes la pone el pie de la
	// figura. Se dibuja igual que en pantalla —mismos colores, mismas subdivisiones, mismos cortes—
	// para que la figura y lo que se vio sean el mismo gráfico.
	//
	// Sin versión en grises: lo único que distingue una forma de otra aquí es el color.
	import { scaleLinear } from 'd3-scale';
	import SelloFigura from '$lib/components/figuras/SelloFigura.svelte';
	import { CUERPO, TINTA } from '$lib/figuras/tema';
	import { subsegmentosVisibles } from './barcode-subsegmentos';

	const props = $props<{
		filas: FilaDeBarras[];
		colorByForma: Record<string, string>;
	}>();

	const ANCHO = 1000;
	const IZQ = 150;
	const DER = 16;
	const BARRA = 30;
	const SOBRESALE = 5;
	const ROTULOS = 18;
	const EJE = 26;
	const ENTRE_FILAS = 16;

	const altoDeFila = (fila: FilaDeBarras) =>
		(fila.jornadas?.length ? ROTULOS : 0) + SOBRESALE * 2 + BARRA + EJE;

	const colocadas = $derived.by(() => {
		let y = 0;
		return props.filas.map((fila: FilaDeBarras) => {
			const arriba = y;
			y += altoDeFila(fila) + ENTRE_FILAS;
			const barra = arriba + (fila.jornadas?.length ? ROTULOS : 0) + SOBRESALE;
			const escala = scaleLinear()
				.domain([fila.desde, fila.hasta + 1])
				.range([IZQ, ANCHO - DER])
				.clamp(true);
			return { fila, barra, escala, marcas: escala.ticks(8).filter((v) => v >= fila.desde && v <= fila.hasta) };
		});
	});
	const alto = $derived(
		Math.max(
			1,
			props.filas.reduce((suma: number, fila: FilaDeBarras) => suma + altoDeFila(fila), 0) +
				Math.max(0, props.filas.length - 1) * ENTRE_FILAS
		)
	);

	const numero = (valor: number) => valor.toLocaleString('es-ES');
	const colorDe = (segmento: MetricBarSegment) =>
		props.colorByForma[segmento.colorKey ?? segmento.forma] ?? TINTA.neutro;
	const cabe = (texto: string, ancho: number) => texto.length * CUERPO.menor * 0.62 < ancho - 6;
</script>

<svg
	viewBox={`0 0 ${ANCHO} ${alto}`}
	width={ANCHO}
	height={alto}
	role="img"
	aria-label="Código de barras métrico"
	data-figura=""
>
	{#each colocadas as { fila, barra, escala, marcas }, indice (fila.etiqueta)}
		{@const pie = barra + BARRA + SOBRESALE + 3}

		{#each fila.jornadas ?? [] as jornada (jornada.etiqueta)}
			{@const ancho = escala(jornada.hasta + 1) - escala(jornada.desde)}
			{#if cabe(jornada.etiqueta, ancho)}
				<text
					x={escala(jornada.desde) + ancho / 2}
					y={barra - SOBRESALE - 6}
					font-size={CUERPO.menor}
					font-weight="600"
					fill={TINTA.secundario}
					letter-spacing="0.4"
					text-anchor="middle">{jornada.etiqueta.toLocaleUpperCase('es')}</text
				>
			{/if}
		{/each}

		<text
			x={IZQ - 14}
			y={barra + BARRA / 2 - 3}
			font-size={CUERPO.rotulo}
			font-weight="600"
			fill={TINTA.texto}
			text-anchor="end">{fila.etiqueta}</text
		>
		<text
			x={IZQ - 14}
			y={barra + BARRA / 2 + 12}
			font-size={CUERPO.menor}
			fill={TINTA.secundario}
			text-anchor="end">vv. {numero(fila.desde)}–{numero(fila.hasta)}</text
		>

		<rect
			x={IZQ}
			y={barra}
			width={ANCHO - DER - IZQ}
			height={BARRA}
			fill={TINTA.pista}
			stroke={TINTA.guia}
		/>
		{#each fila.segmentos as segmento (segmento.id)}
			{@const x = escala(Math.max(segmento.v_ini, fila.desde))}
			{@const ancho = Math.max(1, escala(Math.min(segmento.v_fin, fila.hasta) + 1) - x)}
			<rect x={x} y={barra} width={ancho} height={BARRA} fill={colorDe(segmento)} />
			{#each subsegmentosVisibles(segmento) as sub (sub.id)}
				<line
					x1={escala(sub.v_ini)}
					x2={escala(sub.v_ini)}
					y1={barra}
					y2={barra + BARRA}
					stroke="#ffffff"
					stroke-opacity="0.65"
					stroke-width="0.75"
				/>
			{/each}
		{/each}

		{#each (fila.cortesCuadro ?? []).filter((v: number) => v > fila.desde && v < fila.hasta) as corte (corte)}
			<line
				x1={escala(corte + 1)}
				x2={escala(corte + 1)}
				y1={barra - SOBRESALE}
				y2={barra + BARRA + SOBRESALE}
				stroke={TINTA.tenue}
				stroke-width="1"
				stroke-dasharray="3 2"
			/>
		{/each}
		{#each (fila.cortesJornada ?? []).filter((v: number) => v > fila.desde && v < fila.hasta) as corte (corte)}
			<line
				x1={escala(corte + 1)}
				x2={escala(corte + 1)}
				y1={barra - SOBRESALE}
				y2={barra + BARRA + SOBRESALE}
				stroke={TINTA.texto}
				stroke-width="2"
			/>
		{/each}

		<line x1={IZQ} x2={ANCHO - DER} y1={pie} y2={pie} stroke={TINTA.secundario} stroke-width="1" />
		{#each marcas as verso (verso)}
			<line x1={escala(verso)} x2={escala(verso)} y1={pie} y2={pie + 4} stroke={TINTA.secundario} />
			<text
				x={escala(verso)}
				y={pie + 16}
				font-size={CUERPO.menor}
				fill={TINTA.secundario}
				text-anchor="middle">{numero(verso)}</text
			>
		{/each}

		{#if indice === colocadas.length - 1}
			<SelloFigura x={IZQ - 14} y={pie + 16} anchor="end" />
		{/if}
	{/each}
</svg>

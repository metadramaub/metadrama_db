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
	// Blanco y negro: grises y tramas, con números opcionales; la longitud de los tramos conserva la escala.
	import { formasDeFilas, numerosDeFila, tramasDeFormas } from './diagrama-exportacion';
	import { svgDeTrama, type TramaFigura } from '$lib/figuras/tramas';
	import type { Paleta } from '$lib/figuras/tipos';
	import { scaleLinear } from 'd3-scale';
	import SelloFigura from '$lib/components/figuras/SelloFigura.svelte';
	import { CORTE_CUADRO, CUERPO, TINTA } from '$lib/figuras/tema';
	import { subsegmentosVisibles } from './barcode-subsegmentos';
	import CantoDiagram from './CantoDiagram.svelte';
	import MusicNote from './MusicNote.svelte';
	import type { CantoMarker } from './barcode-canto';
	import { diagramaDeCanto } from './canto-diagrama';

	const idComponente = $props.id();
	const props: {
		filas: FilaDeBarras[];
		colorByForma: Record<string, string>;
		cantoMarkers?: CantoMarker[];
		paleta?: Paleta;
		rotulos?: 'patrones' | 'numeros';
		estilosGrises?: Record<string, TramaFigura>;
	} = $props();

	const prefijoTramas = idComponente.replace(/[^\w-]/g, '');
	const idTrama = (numero: number) => `${prefijoTramas}-trama-${numero}`;
	const estilos = $derived(props.estilosGrises ?? tramasDeFormas(props.filas));
	const blancoNegro = $derived(props.paleta === 'grises');
	const repertorio = $derived(formasDeFilas(props.filas));
	const ANCHO = 1000;
	const IZQ = 150;
	const DER = 16;
	const BARRA = 30;
	const SOBRESALE = 12;
	const ROTULOS = 18;
	const EJE = 26;
	const ENTRE_FILAS = 16;

	const altoDeFila = (fila: FilaDeBarras) =>
		(fila.jornadas?.length ? ROTULOS : 0) + SOBRESALE * 2 + BARRA + EJE;

	const colocadas = $derived.by(() => {
		let y = 0;
		return props.filas.map((fila: FilaDeBarras) => {
			const arriba = y;
			const cantos = diagramaDeCanto(props.cantoMarkers ?? [], fila.desde, fila.hasta, ANCHO - DER - IZQ);
			const altoCantos = cantos.height;
			const rotulos = blancoNegro && props.rotulos === 'numeros'
				? numerosDeFila(fila, ANCHO - DER - IZQ, repertorio) : { items: [], alto: 0 };
			y += altoDeFila(fila) + altoCantos + (blancoNegro ? rotulos.alto : 0) + ENTRE_FILAS;
			const cantoTop = arriba + (fila.jornadas?.length ? ROTULOS : 0);
			const barra = cantoTop + altoCantos + SOBRESALE;
			const escala = scaleLinear()
				.domain([fila.desde, fila.hasta + 1])
				.range([IZQ, ANCHO - DER])
				.clamp(true);
			return { fila, rotulos, arriba, cantoTop, hayCanto: cantos.items.length > 0, barra, escala, marcas: escala.ticks(8).filter((v) => v >= fila.desde && v <= fila.hasta) };
		});
	});
	const alto = $derived(
		Math.max(
			1,
			(colocadas.at(-1)?.barra ?? 0) + BARRA + SOBRESALE + EJE + (blancoNegro ? colocadas.at(-1)?.rotulos.alto ?? 0 : 0)
		)
	);

	const numeroDeForma = (segmento: MetricBarSegment) => repertorio.find((f) => f.clave === (segmento.colorKey ?? segmento.forma))?.numero ?? 0;
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
	aria-label="Diagrama métrico"
	data-figura=""
>
	{#if blancoNegro}
		<defs>{@html repertorio.map((f) => svgDeTrama(idTrama(f.numero), estilos[f.clave])).join('')}</defs>
	{/if}
	{#each colocadas as { fila, rotulos, arriba, cantoTop, hayCanto, barra, escala, marcas }, indice (fila.etiqueta)}
		{@const pie = barra + BARRA + SOBRESALE + 3 + rotulos.alto}
		{#if hayCanto}
			<MusicNote x={IZQ - 87} y={cantoTop + 5} size={13} />
			<text x={IZQ - 67} y={cantoTop + 16} font-size="11" fill={TINTA.secundario}>Canto</text>
		{/if}
		<CantoDiagram markers={props.cantoMarkers ?? []} desde={fila.desde} hasta={fila.hasta} width={ANCHO - DER - IZQ} x={IZQ} y={cantoTop} figure />

		{#each fila.jornadas ?? [] as jornada (jornada.etiqueta)}
			{@const ancho = escala(jornada.hasta + 1) - escala(jornada.desde)}
			{#if cabe(jornada.etiqueta, ancho)}
				<text
					x={escala(jornada.desde) + ancho / 2}
					y={arriba + ROTULOS - 6}
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
		{#each fila.segmentos.filter((s: MetricBarSegment) => s.v_fin >= fila.desde && s.v_ini <= fila.hasta) as segmento (segmento.id)}
			{@const x = escala(Math.max(segmento.v_ini, fila.desde))}
			{@const ancho = Math.max(1, escala(Math.min(segmento.v_fin, fila.hasta) + 1) - x)}
			<rect x={x} y={barra} width={ancho} height={BARRA} fill={blancoNegro ? `url(#${idTrama(numeroDeForma(segmento))})` : colorDe(segmento)} stroke={blancoNegro ? TINTA.texto : undefined} stroke-width={blancoNegro ? 0.8 : undefined} />
			{#each subsegmentosVisibles(segmento) as sub (sub.id)}
				<line
					x1={escala(sub.v_ini)}
					x2={escala(sub.v_ini)}
					y1={barra}
					y2={barra + BARRA}
					stroke={blancoNegro ? TINTA.secundario : "#ffffff"}
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
				stroke={TINTA.fondo}
				stroke-width={CORTE_CUADRO.halo}
				stroke-dasharray={CORTE_CUADRO.trazos}
			/>
			<line
				x1={escala(corte + 1)}
				x2={escala(corte + 1)}
				y1={barra - SOBRESALE}
				y2={barra + BARRA + SOBRESALE}
				stroke={CORTE_CUADRO.color}
				stroke-width={CORTE_CUADRO.ancho}
				stroke-dasharray={CORTE_CUADRO.trazos}
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

		{#each rotulos.items as item (item.segmento.id)}
			{@const estilo = estilos[item.segmento.colorKey ?? item.segmento.forma]}
			{@const oscuro = parseInt(estilo.fondo.slice(1, 3), 16) < 140}
			{@const y = item.exterior ? barra + BARRA + 13 + item.nivel * 18 : barra + BARRA / 2 + 4}
			{#if item.exterior}
				<path d={`M${IZQ + item.origen},${barra + BARRA} L${IZQ + item.x},${y - 9}`} fill="none" stroke={TINTA.secundario} stroke-width="0.7" />
			{/if}
			<text x={IZQ + item.x} {y} font-size="11" font-weight="600" text-anchor="middle" fill={!item.exterior && oscuro ? '#ffffff' : TINTA.texto} stroke={item.exterior ? '#ffffff' : estilo.fondo} stroke-width="3" paint-order="stroke" stroke-linejoin="round">{item.numero}</text>
		{/each}

		{#if indice === colocadas.length - 1}
			<SelloFigura x={IZQ - 14} y={pie + 16} anchor="end" />
		{/if}
	{/each}
</svg>

<script lang="ts">
	// El perfil métrico como figura para descargar: la rosquilla y, al lado, cada forma con su cifra.
	//
	// **La leyenda va dentro del gráfico y con los números**, no en el pie de la figura: en una
	// rosquilla la cifra es la mitad del dato —el ojo compara mal los ángulos—, y en pantalla la
	// daba una lista que no se descarga. Con varias jornadas va una rosquilla por jornada, cada una
	// con su lista debajo, en filas de tres: las rosquillas se comparan mirándolas juntas.
	//
	// El sello va en el hueco —el nombre y no la dirección, que no cabe—: para quitarlo hay que
	// quitar la rosquilla. La dirección aparece debajo del gráfico.
	//
	// En blanco y negro, cada sector comparte gris y trama con su muestra en la leyenda.
	import { svgDeTrama, TRAMAS_GRISES, type TramaFigura } from '$lib/figuras/tramas';
	import type { Paleta } from '$lib/figuras/tipos';
	import SelloFigura from '$lib/components/figuras/SelloFigura.svelte';
	import { CUERPO, TINTA } from '$lib/figuras/tema';
	import MetricDonut from './MetricDonut.svelte';
	import MusicNote from './MusicNote.svelte';
	import type { MetricCantoSummary, MetricDistributionSlice } from './metric-display.types';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';

	type Grupo = { titulo: string | null; items: MetricDistributionSlice[]; canto?: MetricCantoSummary };

	const idComponente = $props.id();
	const props: {
		grupos: Grupo[];
		colorByForma: Record<string, string>;
		valueMode: 'percent' | 'absolute';
		paleta?: Paleta;
		rotulos?: 'patrones' | 'numeros';
		estilosGrises?: Record<string, TramaFigura>;
	} = $props();

	const blancoNegro = $derived(props.paleta === 'grises');
	const conNumeros = $derived(blancoNegro && props.rotulos === 'numeros');
	const repertorio = $derived.by(() => {
		const totales = new Map<string, number>();
		for (const grupo of props.grupos) for (const item of grupo.items) {
			if (item.versos > 0) totales.set(item.colorKey ?? item.forma, (totales.get(item.colorKey ?? item.forma) ?? 0) + item.versos);
		}
		return [...totales].sort((a,b) => b[1]-a[1] || a[0].localeCompare(b[0], 'es')).map(([clave], i) => ({clave,numero:i+1}));
	});
	const prefijo = idComponente.replace(/[^\w-]/g, '');
	const numeroDe = (item: MetricDistributionSlice) => repertorio.find((f) => f.clave === (item.colorKey ?? item.forma))?.numero ?? 0;
	const idTrama = (numero: number) => `${prefijo}-perfil-trama-${numero}`;
	const estiloDe = (item: MetricDistributionSlice) => props.estilosGrises?.[item.colorKey ?? item.forma] ?? TRAMAS_GRISES[(numeroDe(item)-1) % TRAMAS_GRISES.length];
	const rellenoDe = (item: MetricDistributionSlice) => blancoNegro ? `url(#${idTrama(numeroDe(item))})` : colorDe(item);
	const UNA = { rosquilla: 280, leyenda: 320, ancho: 760, fila: 24 };
	const VARIAS = { columna: 300, hueco: 40, titulo: 24, rosquilla: 200, fila: 20, porFila: 3 };

	const ordenados = (items: MetricDistributionSlice[]) =>
		items
			.filter((item) => item.versos > 0)
			.sort((a, b) => b.versos - a.versos || a.forma.localeCompare(b.forma, 'es'));

	const grupos = $derived(
		props.grupos.map((grupo: Grupo) => ({ ...grupo, items: ordenados(grupo.items) }))
	);
	const sola = $derived(grupos.length === 1);

	const colorDe = (item: MetricDistributionSlice) =>
		props.colorByForma[item.colorKey ?? item.forma] ?? TINTA.neutro;
	const cifra = (item: Pick<MetricDistributionSlice, 'versos' | 'porcentaje'>) =>
		props.valueMode === 'absolute'
			? `${item.versos.toLocaleString('es-ES')} vv.`
			: `${item.porcentaje.toFixed(2)}%`;
	const sectores = (items: MetricDistributionSlice[]) =>
		items.map((item) => ({
			clave: normalizeFormaKey(item.colorKey ?? item.forma),
			valor: item.versos,
			color: rellenoDe(item),
			rotulo: conNumeros ? String(numeroDe(item)) : undefined,
			tintaRotulo: parseInt(estiloDe(item).fondo.slice(1,3),16)<140 ? '#ffffff' : TINTA.texto,
			fondoRotulo: estiloDe(item).fondo
		}));

	const columnas = $derived(Math.min(VARIAS.porFila, Math.max(1, grupos.length)));
	const altoLeyenda = (grupo: Grupo, fila: number) => grupo.items.length * fila + (grupo.canto ? 2 * fila : 0);
	const altoColumna = $derived(
		VARIAS.titulo +
			VARIAS.rosquilla +
			14 +
			Math.max(0, ...grupos.map((g: Grupo) => altoLeyenda(g, VARIAS.fila)))
	);
	const ancho = $derived(
		sola ? UNA.ancho : columnas * VARIAS.columna + (columnas - 1) * VARIAS.hueco
	);
	const alto = $derived(
		sola
			? Math.max(UNA.rosquilla, (grupos[0] ? altoLeyenda(grupos[0], UNA.fila) : 0) + 8)
			: Math.ceil(grupos.length / columnas) * (altoColumna + VARIAS.hueco) - VARIAS.hueco
	);
</script>

{#snippet leyenda(items: MetricDistributionSlice[], x: number, y: number, derecha: number, fila: number, cuerpo: number, canto?: MetricCantoSummary)}
	{#each items as item, indice (item.colorKey ?? item.forma)}
		{@const base = y + indice * fila + cuerpo}
		<rect x={x} y={base - (blancoNegro ? 12 : 10)} width={blancoNegro ? 24 : 11} height={blancoNegro ? 14 : 11} fill={rellenoDe(item)} stroke={blancoNegro ? TINTA.texto : undefined} stroke-width={blancoNegro ? 0.6 : undefined} />
		<text x={x + (blancoNegro ? 32 : 18)} y={base} font-size={cuerpo} fill={TINTA.texto}>{conNumeros ? `${numeroDe(item)}. ` : ''}{item.forma}</text>
		<text
			x={derecha}
			y={base}
			font-size={cuerpo}
			fill={TINTA.secundario}
			text-anchor="end"
			style="font-variant-numeric: tabular-nums">{cifra(item)}</text
		>
	{/each}
	{#if canto}
		{@const base = y + items.length * fila + fila + cuerpo}
		<line x1={x} x2={derecha} y1={base - cuerpo - 7} y2={base - cuerpo - 7} stroke={TINTA.guia} />
		<MusicNote x={x} y={base - 11} size={12} />
		<text x={x + 18} y={base} font-size={cuerpo} fill={TINTA.texto}>Versos cantados</text>
		<text x={derecha} y={base} font-size={cuerpo} fill={TINTA.secundario} text-anchor="end">{cifra(canto)}</text>
	{/if}
{/snippet}

<svg
	viewBox={`0 0 ${ancho} ${alto + 24}`}
	width={ancho}
	height={alto + 24}
	role="img"
	aria-label="Perfil métrico"
	data-figura=""
>
	{#if blancoNegro}
		<defs>{@html repertorio.map((f) => svgDeTrama(idTrama(f.numero), props.estilosGrises?.[f.clave] ?? TRAMAS_GRISES[(f.numero-1) % TRAMAS_GRISES.length])).join('')}</defs>
	{/if}
	{#if sola}
		{@const grupo = grupos[0]}
		<MetricDonut
			sectores={sectores(grupo.items)}
			tamano={UNA.rosquilla}
			x={0}
			y={Math.max(0, (alto - UNA.rosquilla) / 2)}
			centro="Versología"
			anguloMinimo={0}
		/>
		{@render leyenda(grupo.items, UNA.leyenda, Math.max(0, (alto - altoLeyenda(grupo, UNA.fila)) / 2), ancho, UNA.fila, CUERPO.rotulo, grupo.canto)}
	{:else}
		{#each grupos as grupo, indice (grupo.titulo ?? indice)}
			{@const x = (indice % columnas) * (VARIAS.columna + VARIAS.hueco)}
			{@const y = Math.floor(indice / columnas) * (altoColumna + VARIAS.hueco)}
			<text
				x={x + VARIAS.columna / 2}
				y={y + 14}
				font-size={CUERPO.rotulo}
				font-weight="600"
				fill={TINTA.secundario}
				letter-spacing="0.4"
				text-anchor="middle">{(grupo.titulo ?? '').toLocaleUpperCase('es')}</text
			>
			<MetricDonut
				sectores={sectores(grupo.items)}
				tamano={VARIAS.rosquilla}
				x={x + (VARIAS.columna - VARIAS.rosquilla) / 2}
				y={y + VARIAS.titulo}
				centro="Versología"
			anguloMinimo={0}
			/>
			{@render leyenda(grupo.items, x, y + VARIAS.titulo + VARIAS.rosquilla + 14, x + VARIAS.columna, VARIAS.fila, CUERPO.referencia, grupo.canto)}
		{/each}
	{/if}
	<SelloFigura x={ancho / 2} y={alto + 18} anchor="middle" />
</svg>

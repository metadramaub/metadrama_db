<script lang="ts">
	// El perfil métrico como figura para descargar: la rosquilla y, al lado, cada forma con su cifra.
	//
	// **La leyenda va dentro del gráfico y con los números**, no en el pie de la figura: en una
	// rosquilla la cifra es la mitad del dato —el ojo compara mal los ángulos—, y en pantalla la
	// daba una lista que no se descarga. Con varias jornadas va una rosquilla por jornada, cada una
	// con su lista debajo, en filas de tres: las rosquillas se comparan mirándolas juntas.
	//
	// El sello va en el hueco —el nombre y no la dirección, que no cabe—: para quitarlo hay que
	// quitar la rosquilla. La dirección la lleva el pie.
	//
	// Sin versión en grises: lo único que une un sector con su nombre es el color.
	import { CUERPO, TINTA } from '$lib/figuras/tema';
	import MetricDonut from './MetricDonut.svelte';
	import type { MetricDistributionSlice } from './metric-display.types';
	import { normalizeFormaKey } from '$lib/utils/metric-colors';

	type Grupo = { titulo: string | null; items: MetricDistributionSlice[] };

	const props = $props<{
		grupos: Grupo[];
		colorByForma: Record<string, string>;
		valueMode: 'percent' | 'absolute';
	}>();

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
	const cifra = (item: MetricDistributionSlice) =>
		props.valueMode === 'absolute'
			? `${item.versos.toLocaleString('es-ES')} vv.`
			: `${item.porcentaje.toFixed(2)}%`;
	const sectores = (items: MetricDistributionSlice[]) =>
		items.map((item) => ({
			clave: normalizeFormaKey(item.colorKey ?? item.forma),
			valor: item.versos,
			color: colorDe(item)
		}));

	const columnas = $derived(Math.min(VARIAS.porFila, Math.max(1, grupos.length)));
	const altoColumna = $derived(
		VARIAS.titulo +
			VARIAS.rosquilla +
			14 +
			Math.max(0, ...grupos.map((g: { items: MetricDistributionSlice[] }) => g.items.length)) * VARIAS.fila
	);
	const ancho = $derived(
		sola ? UNA.ancho : columnas * VARIAS.columna + (columnas - 1) * VARIAS.hueco
	);
	const alto = $derived(
		sola
			? Math.max(UNA.rosquilla, (grupos[0]?.items.length ?? 0) * UNA.fila + 8)
			: Math.ceil(grupos.length / columnas) * (altoColumna + VARIAS.hueco) - VARIAS.hueco
	);
</script>

{#snippet leyenda(items: MetricDistributionSlice[], x: number, y: number, derecha: number, fila: number, cuerpo: number)}
	{#each items as item, indice (item.colorKey ?? item.forma)}
		{@const base = y + indice * fila + cuerpo}
		<rect x={x} y={base - 10} width="11" height="11" fill={colorDe(item)} />
		<text x={x + 18} y={base} font-size={cuerpo} fill={TINTA.texto}>{item.forma}</text>
		<text
			x={derecha}
			y={base}
			font-size={cuerpo}
			fill={TINTA.secundario}
			text-anchor="end"
			style="font-variant-numeric: tabular-nums">{cifra(item)}</text
		>
	{/each}
{/snippet}

<svg
	viewBox={`0 0 ${ancho} ${alto}`}
	width={ancho}
	height={alto}
	role="img"
	aria-label="Perfil métrico"
	data-figura=""
>
	{#if sola}
		{@const grupo = grupos[0]}
		<MetricDonut
			sectores={sectores(grupo.items)}
			tamano={UNA.rosquilla}
			x={0}
			y={Math.max(0, (alto - UNA.rosquilla) / 2)}
			centro="Versología"
		/>
		{@render leyenda(grupo.items, UNA.leyenda, Math.max(0, (alto - grupo.items.length * UNA.fila) / 2), ancho, UNA.fila, CUERPO.rotulo)}
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
			/>
			{@render leyenda(grupo.items, x, y + VARIAS.titulo + VARIAS.rosquilla + 14, x + VARIAS.columna, VARIAS.fila, CUERPO.referencia)}
		{/each}
	{/if}
</svg>

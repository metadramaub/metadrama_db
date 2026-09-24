<script lang="ts" module>
	export type SectorDeRosquilla = {
		/** Clave estable: la del color de la forma. */
		clave: string;
		valor: number;
		color: string;
		/** Lo que dice el aviso nativo al pasar por encima. */
		titulo?: string;
	};
</script>

<script lang="ts">
	// Una rosquilla en SVG, dibujada con d3-shape. La usan el perfil métrico en pantalla y su figura.
	//
	// **Sustituye a ECharts en la zona pública.** ECharts pintaba bien, pero en su propio sistema
	// —su SVG, sus estilos, su aviso en HTML—, y no había manera de descargar lo que pintaba con el
	// mismo aspecto que el resto. Una rosquilla son unos arcos: d3 calcula la geometría y Svelte los
	// pinta, como en los demás gráficos.
	//
	// Las proporciones son las que tenía (radios del 76 % y el 42 %, filete blanco de un punto, dos
	// grados de mínimo por sector) para que no cambie de aspecto al cambiar de motor. Al resaltar
	// una forma, su sector se asoma cuatro puntos y los demás se apagan: lo que hacía ECharts al
	// pasar el ratón.
	import { arc } from 'd3-shape';
	import { TINTA, CUERPO } from '$lib/figuras/tema';
	import { sectoresDeRosquilla } from './rosquilla';

	const props = $props<{
		sectores: SectorDeRosquilla[];
		/** Lado del cuadrado, en unidades del `viewBox`. */
		tamano?: number;
		resaltada?: string | null;
		/** Al entrar en un sector, al moverse por él y al salir (con `null`). Lleva el evento para
		 *  que quien pinte un aviso sepa dónde ponerlo. */
		onHover?: (clave: string | null, evento?: PointerEvent) => void;
		/** Texto en el hueco. En las figuras, el sello. */
		centro?: string;
		etiqueta?: string;
		class?: string;
		/** Posición y tamaño cuando va dentro de otra figura. */
		x?: number;
		y?: number;
	}>();

	const tamano = $derived(props.tamano ?? 224);
	const radio = $derived(tamano / 2);
	const exterior = $derived(radio * 0.76);
	const interior = $derived(radio * 0.42);
	const APAGADO = 0.35;

	const geometria = $derived(sectoresDeRosquilla(props.sectores.map((s: SectorDeRosquilla) => s.valor)));
	const dibujar = $derived(arc<{ inicio: number; fin: number; exterior: number }>()
		.innerRadius(interior)
		.outerRadius((d) => d.exterior)
		.startAngle((d) => d.inicio)
		.endAngle((d) => d.fin));

	const resaltada = $derived(props.resaltada ?? null);
</script>

<svg
	viewBox={`0 0 ${tamano} ${tamano}`}
	x={props.x}
	y={props.y}
	width={props.x !== undefined ? tamano : undefined}
	height={props.x !== undefined ? tamano : undefined}
	class={props.class}
	role="img"
	aria-label={props.etiqueta ?? 'Distribución de formas métricas'}
>
	<g transform={`translate(${radio} ${radio})`}>
		{#each props.sectores as sector, indice (sector.clave)}
			{@const angulos = geometria[indice]}
			{@const activa = resaltada === sector.clave}
			{#if angulos && angulos.fin > angulos.inicio}
				<path
					d={dibujar({ ...angulos, exterior: activa ? exterior + 4 : exterior })}
					fill={sector.color}
					stroke={TINTA.fondo}
					stroke-width="1"
					stroke-linejoin="round"
					opacity={resaltada !== null && !activa ? APAGADO : 1}
					role="presentation"
					onpointerenter={props.onHover ? (evento) => props.onHover?.(sector.clave, evento) : undefined}
					onpointermove={props.onHover ? (evento) => props.onHover?.(sector.clave, evento) : undefined}
					onpointerleave={props.onHover ? () => props.onHover?.(null) : undefined}
				>
					{#if sector.titulo}<title>{sector.titulo}</title>{/if}
				</path>
			{/if}
		{/each}
		{#if props.centro}
			<text
				y="0"
				font-size={CUERPO.sello}
				fill={TINTA.tenue}
				letter-spacing="0.2"
				text-anchor="middle"
				dominant-baseline="middle">{props.centro}</text
			>
		{/if}
	</g>
</svg>

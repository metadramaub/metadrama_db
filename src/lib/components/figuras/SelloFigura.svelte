<script lang="ts">
	// El sello que lleva dentro todo gráfico descargado.
	//
	// **No va encima del dato ni en un margen suelto**, sino pegado a lo que hace legible el
	// gráfico: junto a las referencias del eje, junto a los momentos o en el hueco de la rosquilla.
	// Recortarlo es recortar la escala, y un gráfico sin escala no sirve para nada: quien quiera
	// quitarlo tiene que estropear lo que se lleva. Cada gráfico decide dónde, porque cada uno sabe
	// dónde tiene ese sitio.
	import { CUERPO, SELLO, TINTA } from '$lib/figuras/tema';

	const props = $props<{
		x: number;
		y: number;
		anchor?: 'start' | 'middle' | 'end';
		/** De abajo arriba, para los que lo llevan junto a un eje vertical. */
		vertical?: boolean;
		texto?: string;
	}>();
</script>

<text
	x={props.x}
	y={props.y}
	text-anchor={props.anchor ?? 'start'}
	transform={props.vertical ? `rotate(-90 ${props.x} ${props.y})` : undefined}
	font-size={CUERPO.sello}
	fill={TINTA.tenue}
	letter-spacing="0.2">{props.texto ?? SELLO}</text
>

import { colocarCantos, type CantoMarker } from './barcode-canto';

export type CantoStyle = 'pista' | 'carriles' | 'hitos';

/** Cada anotación conserva su centro y su extensión en el eje de versos. */
export function diagramaDeCanto(
	markers: CantoMarker[], desde: number, hasta: number, width: number,
	style: CantoStyle, figure = false
) {
	const visible = colocarCantos(markers, desde, hasta, width).items
		.sort((a, b) => a.targetX - b.targetX);
	const items = visible.map((item, index) => {
		const start = (item.v_ini - desde) / Math.max(1, hasta - desde + 1) * width;
		const end = (item.v_fin + 1 - desde) / Math.max(1, hasta - desde + 1) * width;
		// El mínimo hace visible un verso suelto, centrado en su posición, sin moverla.
		const drawWidth = Math.max(3, end - start);
		return { ...item, start, end, drawStart: item.targetX - drawWidth / 2,
			drawWidth, rail: style === 'carriles' ? index % 2 : 0 };
	});
	const positioned = items.map((item) => {
		const siblings = items.filter((other) => other.rail === item.rail);
		const index = siblings.findIndex((other) => other.id === item.id);
		// Las zonas de ratón no se pisan: cada marca mantiene también su propio foco de teclado.
		const previous = siblings[index - 1];
		const next = siblings[index + 1];
		return { ...item,
			hitLeft: Math.max(0, item.drawStart - 4, previous ? (previous.targetX + item.targetX) / 2 : 0),
			hitRight: Math.min(width, item.drawStart + item.drawWidth + 4, next ? (next.targetX + item.targetX) / 2 : width)
		};
	});
	const columns = Math.max(1, Math.floor(width / 180));
	// En el archivo se escriben los versos, sin identificadores ni cantidades sobre las marcas.
	const captions = figure ? items.map((item, index) => ({
		x: index % columns * (width / columns) + 3,
		y: 35 + Math.floor(index / columns) * 15,
		text: item.label
	})) : [];
	const captionHeight = captions.length ? 28 + Math.ceil(captions.length / columns) * 15 : 0;
	const rails = style === 'carriles' ? 2 : 1;
	return { items: positioned, captions, captionHeight, rails,
		height: items.length ? captionHeight + 32 + (rails - 1) * 14 : 0 };
}

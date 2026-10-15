import { versoDeCanto, type CantoMarker } from './barcode-canto';

/** Cada anotación conserva su centro y su extensión en el eje de versos. */
export function diagramaDeCanto(markers: CantoMarker[], desde: number, hasta: number, width: number) {
	const visible = markers
		.filter((m) => m.v_ini <= hasta && m.v_fin >= desde)
		.map((m) => ({ ...m, v_ini: Math.max(m.v_ini, desde), v_fin: Math.min(m.v_fin, hasta) }))
		.sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	const items = visible.map((item) => {
		const start = (item.v_ini - desde) / Math.max(1, hasta - desde + 1) * width;
		const end = (item.v_fin + 1 - desde) / Math.max(1, hasta - desde + 1) * width;
		// El mínimo hace visible un verso suelto, centrado en su posición, sin moverla.
		const drawWidth = Math.max(3, end - start);
		const targetX = (start + end) / 2;
		return { ...item, start, end, targetX, label: versoDeCanto(item), drawStart: targetX - drawWidth / 2, drawWidth };
	});
	const positioned = items.map((item, index) => {
		// Las zonas de ratón no se pisan: cada marca mantiene también su propio foco de teclado.
		const previous = items[index - 1];
		const next = items[index + 1];
		return { ...item,
			hitLeft: Math.max(0, item.drawStart - 4, previous ? (previous.targetX + item.targetX) / 2 : 0),
			hitRight: Math.min(width, item.drawStart + item.drawWidth + 4, next ? (next.targetX + item.targetX) / 2 : width)
		};
	});
	return { items: positioned, height: items.length ? 32 : 0 };
}

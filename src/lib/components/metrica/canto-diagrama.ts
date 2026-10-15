import { colocarCantos, type CantoMarker } from './barcode-canto';

export type CantoStyle = 'abanico' | 'pista' | 'grupos';

/** Agrupa solo para dibujar y pulsar: todos los rangos y sus secuencias siguen disponibles. */
export function diagramaDeCanto(markers: CantoMarker[], desde: number, hasta: number, width: number, style: CantoStyle, figure = false) {
	const items = colocarCantos(markers, desde, hasta, width).items.sort((a, b) => a.targetX - b.targetX);
	const groups: { id: string; x: number; items: typeof items }[] = [];
	for (const item of items) {
		const previous = groups.at(-1);
		if (previous && item.targetX - previous.items.at(-1)!.targetX < 22) {
			previous.items.push(item);
			previous.x = previous.items.reduce((sum, i) => sum + i.targetX, 0) / previous.items.length;
		} else groups.push({ id: item.id, x: item.targetX, items: [item] });
	}
	const columns = Math.max(1, Math.floor(width / 190));
	const columnWidth = width / columns;
	const captions: { x: number; y: number; text: string }[] = [];
	let captionHeight = 0;
	if (figure && groups.length) {
		const bottoms = Array<number>(columns).fill(24);
		groups.forEach((group, index) => {
			const column = bottoms.indexOf(Math.min(...bottoms));
			const words = `${index + 1}: ${group.items.map((i) => i.label).join('; ')}`.split(' ');
			const lines: string[] = [''];
			for (const word of words) {
				const last = lines.length - 1;
				if (lines[last] && (lines[last].length + word.length + 1) * 6 > columnWidth - 12) lines.push(word);
				else lines[last] += `${lines[last] ? ' ' : ''}${word}`;
			}
			for (const line of lines) {
				captions.push({ x: column * columnWidth + 3, y: bottoms[column] + 12, text: line });
				bottoms[column] += 15;
			}
			bottoms[column] += 3;
		});
		captionHeight = Math.max(0, ...bottoms) + (groups.length ? 8 : 0);
	}
	const diagramHeight = groups.length ? (style === 'abanico' ? 72 : 44) : 0;
	return { groups, captions, captionHeight, height: captionHeight + diagramHeight };
}

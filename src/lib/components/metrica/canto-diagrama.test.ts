import { describe, expect, it } from 'vitest';
import { diagramaDeCanto, type CantoStyle } from './canto-diagrama';
import type { CantoMarker } from './barcode-canto';

const marker = (verse: number): CantoMarker => ({ id: String(verse), secuencia_id: `s${verse}`, v_ini: verse, v_fin: verse });
const styles: CantoStyle[] = ['abanico', 'pista', 'grupos'];

describe('diagramas alternativos del canto', () => {
	it('agrupa visualmente sin perder ningún rango ni enlace y mantiene una altura acotada', () => {
		const markers = [marker(10), marker(80), marker(81), marker(82), marker(83)];
		for (const style of styles) {
			const result = diagramaDeCanto(markers, 1, 100, 300, style);
			expect(result.groups.map((g) => g.items.length)).toEqual([1, 4]);
			expect(result.groups.flatMap((g) => g.items.map((i) => i.secuencia_id))).toEqual(markers.map((m) => m.secuencia_id));
			expect(result.height).toBeLessThanOrEqual(72);
		}
	});

	it('recalcula posiciones y agrupaciones al ampliar una jornada', () => {
		const markers = [marker(80), marker(81), marker(200)];
		expect(diagramaDeCanto(markers, 1, 300, 600, 'grupos').groups).toHaveLength(2);
		const jornada = diagramaDeCanto(markers, 71, 90, 600, 'grupos');
		expect(jornada.groups).toHaveLength(2);
		expect(jornada.groups.map((g) => g.items[0].v_ini)).toEqual([80, 81]);
	});

	it('escribe todos los versos en la figura y reserva espacio para leerlos', () => {
		const markers = Array.from({ length: 12 }, (_, i) => marker(80 + i));
		for (const style of styles) {
			const result = diagramaDeCanto(markers, 1, 100, 300, style, true);
			const text = result.captions.map((c) => c.text).join(' ');
			for (const marker of markers) expect(text).toContain(`v. ${marker.v_ini}`);
			expect(result.captionHeight).toBeGreaterThan(24);
			for (const caption of result.captions) expect(caption.y).toBeLessThan(result.captionHeight);
		}
	});

	it('no reserva espacio en ninguna variante cuando el canto está desactivado', () => {
		for (const style of styles) {
			expect(diagramaDeCanto([], 1, 100, 600, style, true)).toMatchObject({ groups: [], captions: [], height: 0 });
		}
	});
});

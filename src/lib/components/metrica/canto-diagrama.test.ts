import { describe, expect, it } from 'vitest';
import { diagramaDeCanto, type CantoStyle } from './canto-diagrama';
import type { CantoMarker } from './barcode-canto';

const marker = (verse: number, end = verse): CantoMarker => ({
	id: String(verse), secuencia_id: `s${verse}`, v_ini: verse, v_fin: end
});
const styles: CantoStyle[] = ['pista', 'carriles', 'hitos'];

describe('pistas alternativas del canto', () => {
	it('conserva cada pasaje y su posición exacta, incluso con marcas a menos de un píxel', () => {
		const markers = [marker(10), marker(80), marker(81), marker(82), marker(83)];
		for (const style of styles) {
			const result = diagramaDeCanto(markers, 1, 1000, 300, style);
			expect(result.items).toHaveLength(markers.length);
			expect(result.items.map((i) => i.secuencia_id)).toEqual(markers.map((m) => m.secuencia_id));
			for (const item of result.items) {
				expect(item.targetX).toBeCloseTo((item.v_ini - 0.5) * 0.3);
				expect(item.drawStart + item.drawWidth / 2).toBeCloseTo(item.targetX);
			}
			expect(result.height).toBeLessThanOrEqual(46);
		}
	});

	it('solo alterna la altura de las marcas en la variante de dos carriles', () => {
		const markers = [marker(80), marker(81), marker(82), marker(83)];
		const double = diagramaDeCanto(markers, 1, 100, 600, 'carriles');
		const single = diagramaDeCanto(markers, 1, 100, 600, 'pista');
		expect(double.items.map((i) => i.rail)).toEqual([0, 1, 0, 1]);
		expect(single.items.map((i) => i.rail)).toEqual([0, 0, 0, 0]);
		expect(double.items.map((i) => i.targetX)).toEqual(single.items.map((i) => i.targetX));
	});

	it('recalcula el eje y filtra los pasajes al ampliar una jornada', () => {
		const markers = [marker(80), marker(81), marker(200)];
		const jornada = diagramaDeCanto(markers, 71, 90, 600, 'carriles');
		expect(jornada.items.map((i) => i.v_ini)).toEqual([80, 81]);
		expect(jornada.items.map((i) => i.targetX)).toEqual([285, 315]);
	});

	it('conserva los límites de los rangos y no solapa las zonas de ratón del mismo carril', () => {
		const result = diagramaDeCanto([marker(1), marker(2), marker(40, 60), marker(100)], 1, 100, 300, 'pista');
		const range = result.items[2];
		expect(range.start).toBe(117);
		expect(range.end).toBe(180);
		for (let index = 1; index < result.items.length; index++) {
			expect(result.items[index].hitLeft).toBeGreaterThanOrEqual(result.items[index - 1].hitRight);
		}
		expect(result.items[0].hitLeft).toBe(0);
		expect(result.items.at(-1)?.hitRight).toBe(300);
	});

	it('escribe los versos de cada pasaje en la figura sin numeraciones de referencia', () => {
		const markers = Array.from({ length: 12 }, (_, i) => marker(80 + i));
		for (const style of styles) {
			const result = diagramaDeCanto(markers, 1, 100, 300, style, true);
			expect(result.captions.map((c) => c.text)).toEqual(markers.map((m) => `v. ${m.v_ini}`));
			for (const caption of result.captions) expect(caption.y).toBeLessThan(result.captionHeight);
		}
	});

	it('no reserva espacio cuando el canto está desactivado', () => {
		for (const style of styles) {
			expect(diagramaDeCanto([], 1, 100, 600, style, true)).toMatchObject({ items: [], captions: [], height: 0 });
		}
	});
});

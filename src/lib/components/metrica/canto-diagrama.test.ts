import { describe, expect, it } from 'vitest';
import { diagramaDeCanto } from './canto-diagrama';
import type { CantoMarker } from './barcode-canto';

const marker = (verse: number, end = verse): CantoMarker => ({
	id: String(verse), secuencia_id: `s${verse}`, v_ini: verse, v_fin: end
});

describe('pista del canto', () => {
	it('dibuja un rango con la extensión exacta de sus versos', () => {
		const [item] = diagramaDeCanto([marker(40, 60)], 1, 100, 300).items;
		expect(item).toMatchObject({ start: 117, end: 180, drawStart: 117, drawWidth: 63 });
	});

	it('centra el ancho mínimo en el verso sin agrupar las marcas cercanas', () => {
		const markers = [marker(10), marker(80), marker(81), marker(82), marker(83)];
		const result = diagramaDeCanto(markers, 1, 1000, 300);
		expect(result.items).toHaveLength(5);
		expect(result.items.map((i) => i.secuencia_id)).toEqual(markers.map((m) => m.secuencia_id));
		for (const item of result.items) {
			expect(item.drawWidth).toBe(3);
			expect(item.targetX).toBeCloseTo((item.v_ini - 0.5) * 0.3);
			expect(item.drawStart + 1.5).toBeCloseTo(item.targetX);
		}
		expect(result.height).toBe(32);
	});

	it('recalcula el eje y excluye los pasajes de otras jornadas', () => {
		const jornada = diagramaDeCanto([marker(80), marker(81), marker(200)], 71, 90, 600);
		expect(jornada.items.map((i) => i.v_ini)).toEqual([80, 81]);
		expect(jornada.items.map((i) => i.targetX)).toEqual([285, 315]);
	});

	it('recorta un pasaje al rango visible y conserva la cita correspondiente', () => {
		const [item] = diagramaDeCanto([marker(90, 110)], 101, 200, 500).items;
		expect(item).toMatchObject({ v_ini: 101, v_fin: 110, label: 'vv. 101–110', start: 0, end: 50, targetX: 25 });
	});

	it('mantiene accesos separados al ratón sin desplazar las marcas', () => {
		const result = diagramaDeCanto([marker(1), marker(2), marker(40, 60), marker(100)], 1, 100, 300);
		for (let index = 1; index < result.items.length; index++) {
			expect(result.items[index].hitLeft).toBeGreaterThanOrEqual(result.items[index - 1].hitRight);
		}
		expect(result.items[0].hitLeft).toBe(0);
		expect(result.items.at(-1)?.hitRight).toBe(300);
	});

	it('no reserva espacio cuando no hay canto visible', () => {
		expect(diagramaDeCanto([], 1, 100, 600)).toEqual({ items: [], height: 0 });
		expect(diagramaDeCanto([marker(200)], 1, 100, 600)).toEqual({ items: [], height: 0 });
	});
});

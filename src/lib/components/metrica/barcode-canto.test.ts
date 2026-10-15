import { describe, expect, it } from 'vitest';
import { colocarCantos, rangosCantados, type CantoMarker } from './barcode-canto';

const marker = (ini: number, fin = ini): CantoMarker => ({
	id: `s:${ini}-${fin}`, secuencia_id: 's', v_ini: ini, v_fin: fin
});

describe('rangosCantados', () => {
	it('conserva versos sueltos, une rangos contiguos y excluye otras caracterizaciones', () => {
		const secuencia = { secuencia_id: 's', v_ini: 1, v_fin: 100, caracterizaciones: [
			{ tipo: 'Cantado', v_ini: 10, v_fin: 10 },
			{ tipo: 'cantado', v_ini: 20, v_fin: 25 },
			{ tipo: 'cantado', v_ini: 24, v_fin: 30 },
			{ tipo: 'cantado', v_ini: 31, v_fin: 32 },
			{ tipo: 'prosa', v_ini: 40, v_fin: 45 }
		] };
		const copia = structuredClone(secuencia);
		expect(rangosCantados([secuencia])).toEqual([marker(10), marker(20, 32)]);
		expect(secuencia).toEqual(copia);
	});

	it('respeta los límites de la secuencia y mantiene enlaces distintos en pasajes consecutivos', () => {
		const datos = [
			{ secuencia_id: 'a', v_ini: 1, v_fin: 10, caracterizaciones: [{ tipo: 'cantado', v_ini: 8, v_fin: 15 }] },
			{ secuencia_id: 'b', v_ini: 11, v_fin: 20, caracterizaciones: [{ tipo: 'cantado', v_ini: 11, v_fin: 12 }] }
		];
		expect(rangosCantados(datos).map(({ secuencia_id, v_ini, v_fin }) => ({ secuencia_id, v_ini, v_fin }))).toEqual([
			{ secuencia_id: 'a', v_ini: 8, v_fin: 10 },
			{ secuencia_id: 'b', v_ini: 11, v_fin: 12 }
		]);
	});
});

describe('colocarCantos', () => {
	it('sitúa versos y rangos en su centro usando el mismo eje que la barra', () => {
		const { items } = colocarCantos([marker(1), marker(40, 60)], 1, 100, 1000);
		expect(items[0].targetX).toBe(5);
		expect(items[0].label).toBe('v. 1');
		expect(items[1].targetX).toBe(495);
		expect(items[1].label).toBe('vv. 40–60');
	});

	it('filtra por jornada y recorta solo la parte visible de un rango', () => {
		const { items } = colocarCantos([marker(1), marker(90, 110), marker(150)], 101, 200, 500);
		expect(items.map((i) => i.label)).toEqual(['vv. 101–110', 'v. 150']);
		expect(items[0].targetX).toBe(25);
	});

	it('reparte marcas cercanas en alturas y mantiene las notas dentro del lienzo', () => {
		const { items, lanes } = colocarCantos([marker(1), marker(2), marker(100)], 1, 100, 300);
		expect(lanes).toBe(2);
		expect(items.map((i) => i.lane)).toEqual([0, 1, 0]);
		for (const item of items) {
			expect(item.left).toBeGreaterThanOrEqual(0);
			expect(item.left + 24).toBeLessThanOrEqual(300);
		}
	});

	it('reserva espacio para los rótulos exportados y no ocupa nada si las marcas están desactivadas', () => {
		const markers = [marker(1), marker(6)];
		expect(colocarCantos(markers, 1, 100, 1000).lanes).toBe(1);
		expect(colocarCantos(markers, 1, 100, 1000, true).lanes).toBe(2);
		expect(colocarCantos([], 1, 100, 1000)).toEqual({ items: [], lanes: 0 });
	});
});

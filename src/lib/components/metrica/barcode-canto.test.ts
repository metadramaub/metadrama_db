import { describe, expect, it } from 'vitest';
import { rangosCantados, type CantoMarker } from './barcode-canto';

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

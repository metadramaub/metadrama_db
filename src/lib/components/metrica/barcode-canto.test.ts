import { describe, expect, it } from 'vitest';
import { rangosCantados, resumenCanto, type CantoMarker } from './barcode-canto';

const marker = (ini: number, fin = ini): CantoMarker => ({
	id: `s:${ini}-${fin}`, secuencia_id: 's', v_ini: ini, v_fin: fin
});

describe('resumenCanto', () => {
	const redondilla = {
		secuencia_id: 'r', v_ini: 1, v_fin: 100, n_versos: 100,
		forma_slug: 'redondilla', forma: 'Redondilla',
		caracterizaciones: [
			{ tipo: 'cantado', v_ini: 10, v_fin: 20 },
			{ tipo: 'cantado', v_ini: 18, v_fin: 25 }
		]
	};
	const romance = {
		secuencia_id: 'm', v_ini: 101, v_fin: 200, n_versos: 100,
		forma_slug: 'romance', forma: 'Romance',
		caracterizaciones: [{ tipo: 'cantado', v_ini: 110, v_fin: 113 }]
	};

	it('cuenta solo los versos cantados, sin duplicar los solapes, e identifica las formas', () => {
		expect(resumenCanto([redondilla, romance])).toEqual({
			versos: 20, porcentaje: 10, formas: ['redondilla', 'romance']
		});
	});

	it('usa como denominador todos los versos del perfil, aunque una forma no contenga canto', () => {
		expect(resumenCanto([redondilla, { ...romance, caracterizaciones: [] }])).toEqual({
			versos: 16, porcentaje: 8, formas: ['redondilla']
		});
	});

	it('recalcula el porcentaje sobre las secuencias de cada jornada', () => {
		expect(resumenCanto([romance])).toEqual({ versos: 4, porcentaje: 4, formas: ['romance'] });
	});

	it('mantiene el canto de pasajes sin forma y admite perfiles sin canto o vacíos', () => {
		expect(resumenCanto([{ ...romance, forma_slug: null, forma: null }]).formas).toEqual(['Sin forma anotada']);
		expect(resumenCanto([{ ...romance, caracterizaciones: [] }])).toEqual({ versos: 0, porcentaje: 0, formas: [] });
		expect(resumenCanto([])).toEqual({ versos: 0, porcentaje: 0, formas: [] });
	});
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

import { describe, expect, it } from 'vitest';
import { buildPhenomenaIndex, type PhenomenonSequence } from './phenomena-index';

const sequence: PhenomenonSequence = {
	secuencia_id: 's1',
	v_ini: 100,
	v_fin: 120,
	forma_nombre: 'Romance',
	caracterizaciones_rango: [
		{
			caracterizacion_rango_id: 'c1',
			tipo_caracterizacion_rango_term: 'Cantado',
			v_ini: 105,
			v_fin: 108
		}
	],
	desviaciones: [{ dimension: 'metro' }],
	versos_partidos: true,
	inaugura_espacio: false,
	intervencion_personajes_femeninos: 'compartida',
	intervencion_figuras_donaire: 'sin_intervencion',
	intervencion_personajes_sobrenaturales: null,
	evento_sobrenatural: false
};

describe('buildPhenomenaIndex', () => {
	it('conserva el rango específico del canto y abre la secuencia que lo contiene', () => {
		const canto = buildPhenomenaIndex([sequence]).find((group) => group.id === 'cantado');
		expect(canto?.items).toEqual([
			{
				id: 'c1',
				secuencia_id: 's1',
				v_ini: 105,
				v_fin: 108,
				forma: 'Romance',
				detalle: null
			}
		]);
	});

	it('solo crea grupos presentes y conserva la clase de intervención', () => {
		const groups = buildPhenomenaIndex([sequence]);
		expect(groups.map((group) => group.id)).toEqual([
			'cantado',
			'desviaciones',
			'versos_partidos',
			'personajes_femeninos'
		]);
		expect(groups.at(-1)?.items[0]?.detalle).toBe('Compartida');
	});
});

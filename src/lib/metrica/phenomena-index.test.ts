import { describe, expect, it } from 'vitest';
import { buildPhenomenaIndex, type PhenomenonSequence } from './phenomena-index';

function secuencia(overrides: Partial<PhenomenonSequence> = {}): PhenomenonSequence {
	return {
		secuencia_id: 's1',
		v_ini: 100,
		v_fin: 120,
		forma_nombre: 'Romance',
		forma_slug: 'romance',
		caracterizaciones_rango: [],
		desviaciones: [],
		versos_partidos: null,
		inaugura_espacio: null,
		intervencion_personajes_femeninos: null,
		intervencion_figuras_donaire: null,
		intervencion_personajes_sobrenaturales: null,
		evento_sobrenatural: null,
		...overrides
	};
}

const cantada = secuencia({
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
	evento_sobrenatural: false
});

describe('buildPhenomenaIndex', () => {
	it('conserva el rango específico del canto y abre la secuencia que lo contiene', () => {
		const canto = buildPhenomenaIndex([cantada]).find((group) => group.id === 'cantado');
		expect(canto?.ramas[0]?.facetas[0]?.formas).toEqual([
			{
				forma: 'Romance',
				colorKey: 'romance',
				versos: 4,
				items: [{ id: 'c1', secuencia_id: 's1', v_ini: 105, v_fin: 108, detalle: null }]
			}
		]);
	});

	it('reúne los tres tipos de personaje en un solo grupo', () => {
		const groups = buildPhenomenaIndex([cantada]);
		expect(groups.map((group) => group.id)).toEqual([
			'cantado',
			'desviaciones',
			'versos_partidos',
			'inaugura_espacio',
			'intervenciones',
			'eventos_sobrenaturales'
		]);

		const intervenciones = groups.find((group) => group.id === 'intervenciones');
		expect(intervenciones?.ramas.map((rama) => rama.id)).toEqual([
			'personajes_femeninos',
			'figuras_donaire'
		]);
		expect(intervenciones?.ramas[0]?.facetas.map((faceta) => faceta.label)).toEqual(['Compartida']);
	});

	it('muestra también dónde no ocurre el fenómeno, agrupado por forma', () => {
		const groups = buildPhenomenaIndex([
			secuencia({ secuencia_id: 'a', versos_partidos: true }),
			secuencia({ secuencia_id: 'b', versos_partidos: false, v_ini: 200, v_fin: 209 }),
			secuencia({
				secuencia_id: 'c',
				versos_partidos: false,
				forma_nombre: 'Redondilla',
				forma_slug: 'redondilla',
				v_ini: 300,
				v_fin: 303
			}),
			secuencia({ secuencia_id: 'd' })
		]);

		const partidos = groups.find((group) => group.id === 'versos_partidos');
		expect(partidos?.total).toBe(1);
		const [si, no] = partidos?.ramas[0]?.facetas ?? [];
		expect(si.label).toBe('Sí');
		expect(si.formas.map((forma) => forma.colorKey)).toEqual(['romance']);
		expect(no.label).toBe('No');
		expect(no.total).toBe(2);
		expect(no.formas.map((forma) => forma.colorKey)).toEqual(['romance', 'redondilla']);
		expect(partidos?.ramas[0]?.pendientes).toBe(1);
	});

	it('cuando la obra lo declara, la rama lo dice una vez y no lista secuencias', () => {
		const groups = buildPhenomenaIndex(
			[secuencia({ intervencion_figuras_donaire: 'sin_intervencion' })],
			{
				sin_figuras_donaire: true,
				sin_personajes_sobrenaturales: false,
				sin_eventos_sobrenaturales: false
			}
		);

		const donaire = groups
			.find((group) => group.id === 'intervenciones')
			?.ramas.find((rama) => rama.id === 'figuras_donaire');
		expect(donaire?.declarada).toBe(true);
		expect(donaire?.facetas).toEqual([]);
		expect(donaire?.pendientes).toBe(0);
		expect(donaire?.nota).toBe('La obra declara que no tiene figuras de donaire.');
	});
});

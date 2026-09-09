import { describe, expect, it } from 'vitest';
import type {
	PublicFichaEsquemaRima,
	PublicFichaMetro,
	PublicFichaRasgo
} from '$lib/types/public-ficha.types';
import { buildDistributionGroups } from './metric-distribution';

const context = {
	realizacion_padre_id: null,
	realizacion_orden: 1,
	realizacion_v_ini: 1,
	realizacion_v_fin: 14,
	realizacion_seccion_id: null,
	realizacion_seccion_nombre: null,
	realizacion_seccion_tipo: null,
	realizacion_seccion_orden: null,
	realizacion_seccion_repeticiones_min: null,
	realizacion_seccion_repeticiones_max: null,
	realizacion_seccion_arquitectura_referenciada_id: null,
	seccion_id: null,
	seccion_nombre: null,
	seccion_orden: null,
	observaciones: null
};

function scheme(
	eleccion_id: string,
	realizacion_id: string,
	seccion_nombre: string,
	seccion_orden: number,
	notacion: string
): PublicFichaEsquemaRima {
	return {
		...context,
		eleccion_id,
		realizacion_id,
		seccion_nombre,
		seccion_orden,
		esquema_rima_id: eleccion_id,
		nombre: notacion,
		notacion,
		posicion_unidad: null
	};
}

describe('buildDistributionGroups', () => {
	it('reconstruye y cuenta el esquema completo de cada realización del soneto', () => {
		const [group] = buildDistributionGroups(
			[{ forma: 'Soneto', versos: 42, porcentaje: 100 }],
			[
				{
					secuencia_id: 's1',
					forma_nombre: 'Soneto',
					arquitectura_nombre: 'Endecasilábica consonante',
					arquitectura_slug: 'endecasilabica-consonante',
					n_versos: 14,
					esquemas_rima: [
						scheme('e1', 'r1', 'Cuartetos', 1, 'ABBA ABBA'),
						scheme('e2', 'r1', 'Tercetos', 2, 'CDC DCD')
					]
				},
				{
					secuencia_id: 's2',
					forma_nombre: 'Soneto',
					arquitectura_nombre: 'Endecasilábica consonante',
					arquitectura_slug: 'endecasilabica-consonante',
					n_versos: 14,
					esquemas_rima: [
						scheme('e3', 'r2', 'Cuartetos', 1, 'ABBA ABBA'),
						scheme('e4', 'r2', 'Tercetos', 2, 'CDE CDE')
					]
				},
				{
					secuencia_id: 's3',
					forma_nombre: 'Soneto',
					arquitectura_nombre: 'Endecasilábica consonante',
					arquitectura_slug: 'endecasilabica-consonante',
					n_versos: 14,
					esquemas_rima: [
						scheme('e5', 'r3', 'Cuartetos', 1, 'ABBA ABBA'),
						scheme('e6', 'r3', 'Tercetos', 2, 'CDC DCD')
					]
				}
			]
		);

		expect(group.arquitecturas).toHaveLength(1);
		expect(group.arquitecturas[0].label).toBe('Endecasilábica consonante');
		expect(group.arquitecturas[0].esquemas).toEqual([
			{ label: 'ABBA ABBA CDC DCD', cantidad: 2, unidad: 'soneto', versos: 0 },
			{ label: 'ABBA ABBA CDE CDE', cantidad: 1, unidad: 'soneto', versos: 0 }
		]);
	});

	it('muestra las vocales de asonancia dentro de la arquitectura del romance', () => {
		const feature = (eleccion_id: string, valor_nombre: string): PublicFichaRasgo => ({
			...context,
			eleccion_id,
			realizacion_id: null,
			rasgo_slug: 'vocales_asonancia',
			rasgo_nombre: 'Vocales de la asonancia',
			valor_slug: valor_nombre,
			valor_nombre
		});
		const [group] = buildDistributionGroups(
			[{ forma: 'Romance', versos: 238, porcentaje: 100 }],
			[
				{
					secuencia_id: 'r1',
					forma_nombre: 'Romance',
					arquitectura_nombre: 'Octosilábica',
					n_versos: 144,
					rasgos: [feature('f1', 'a-e')]
				},
				{
					secuencia_id: 'r2',
					forma_nombre: 'Romance',
					arquitectura_nombre: 'Octosilábica',
					n_versos: 94,
					rasgos: [feature('f2', 'e-o')]
				}
			]
		);

		expect(group.arquitecturas[0].rasgos).toEqual([
			{
				label: 'Vocales de la asonancia',
				values: [
					{ label: 'a-e', cantidad: 1, unidad: 'tirada', versos: 144 },
					{ label: 'e-o', cantidad: 1, unidad: 'tirada', versos: 94 }
				]
			}
		]);
	});

	it('cuenta por separado las estancias repetidas de una canción', () => {
		const estancia = (id: string, start: number): PublicFichaEsquemaRima => ({
			...scheme(id, id, '', 1, 'aabbc'),
			realizacion_padre_id: 'cancion-1',
			realizacion_v_ini: start,
			realizacion_v_fin: start + 4,
			realizacion_seccion_id: 'estancia',
			realizacion_seccion_nombre: 'Estancia',
			realizacion_seccion_tipo: 'estancia',
			realizacion_seccion_repeticiones_min: 3,
			realizacion_seccion_repeticiones_max: null,
			seccion_nombre: null,
			seccion_orden: null
		});
		const [group] = buildDistributionGroups(
			[{ forma: 'Canción petrarquista', versos: 15, porcentaje: 100 }],
			[{
				secuencia_id: 'c1',
				forma_nombre: 'Canción petrarquista',
				arquitectura_nombre: 'Estancias consonantes variables',
				n_versos: 15,
				esquemas_rima: [estancia('e1', 1), estancia('e2', 6), estancia('e3', 11)]
			}]
		);

		expect(group.arquitecturas[0].esquemas).toEqual([
			{ label: 'aabbc', cantidad: 3, unidad: 'estancia', versos: 0 }
		]);
	});

	it('recompone las secciones complementarias de una copla real', () => {
		const parte = (id: string, order: number, notation: string): PublicFichaEsquemaRima => ({
			...scheme(id, id, '', order, notation),
			realizacion_padre_id: 'copla-1',
			realizacion_orden: order,
			realizacion_seccion_id: `q${order}`,
			realizacion_seccion_nombre: order === 1 ? 'Primera quintilla' : 'Segunda quintilla',
			realizacion_seccion_tipo: 'quintilla',
			realizacion_seccion_arquitectura_referenciada_id: 'quintilla',
			seccion_nombre: null,
			seccion_orden: null
		});
		const [group] = buildDistributionGroups(
			[{ forma: 'Copla real', versos: 10, porcentaje: 100 }],
			[{
				secuencia_id: 'cr1',
				forma_nombre: 'Copla real',
				arquitectura_nombre: 'Octosilábica consonante',
				n_versos: 10,
				esquemas_rima: [parte('q1', 1, 'ababa'), parte('q2', 2, 'abbab')]
			}]
		);

		expect(group.arquitecturas[0].esquemas).toEqual([
			{ label: 'ababa abbab', cantidad: 1, unidad: 'copla real', versos: 0 }
		]);
	});

	it('cuenta solo los versos realmente afectados por una respuesta de metro', () => {
		const metre = (id: string, position: number, name: string): PublicFichaMetro => ({
			...context,
			eleccion_id: id,
			realizacion_id: 'r1',
			realizacion_v_ini: 100,
			realizacion_v_fin: 103,
			metro_id: name,
			metro_slug: name.toLocaleLowerCase('es'),
			metro_nombre: name,
			posicion_unidad: position
		});
		const [group] = buildDistributionGroups(
			[{ forma: 'Redondilla', versos: 100, porcentaje: 100 }],
			[{
				secuencia_id: 'r1',
				v_ini: 1,
				v_fin: 100,
				forma_nombre: 'Redondilla',
				arquitectura_nombre: 'Octosilábica',
				n_versos: 100,
				metros: [metre('m1', 2, 'Pentasílabo'), metre('m2', 4, 'Pentasílabo')]
			}]
		);

		expect(group.arquitecturas[0].metros).toEqual([
			{ label: 'Pentasílabo', cantidad: 2, unidad: 'verso', versos: 2 }
		]);
	});
});

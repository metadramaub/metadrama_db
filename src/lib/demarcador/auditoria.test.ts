import { describe, expect, it } from 'vitest';
import {
	construirAuditoriaDemarcador,
	type EstrofaFuenteAuditoria,
	type OpcionFuenteAuditoria
} from './auditoria';

const opciones: OpcionFuenteAuditoria[] = [
	{ termino_id: 'rima-consonante', termino: 'consonante', etiqueta: 'Consonante' },
	{ termino_id: 'cerrada', termino: 'estrofa_cerrada', etiqueta: 'Estrofa cerrada' },
	{ termino_id: 'octosilabo', termino: 'octosilabo', etiqueta: 'Octosílabo', numero_silabas: 8 },
	{
		termino_id: 'endecasilabo',
		termino: 'endecasilabo',
		etiqueta: 'Endecasílabo',
		numero_silabas: 11
	}
];

function estrofa(
	id: string,
	parentId: string | null,
	overrides: Partial<EstrofaFuenteAuditoria> = {}
): EstrofaFuenteAuditoria {
	return {
		termino_id: id,
		termino: id,
		etiqueta: null,
		termino_padre_id: parentId,
		orden: null,
		tipo_forma: null,
		tipo_rima_id: null,
		naturaleza_estrofica_id: null,
		tamanio_unidad_estrofica: null,
		arte_metrico: null,
		patron_especifico: null,
		...overrides
	};
}

describe('construirAuditoriaDemarcador', () => {
	it('hereda la rima y el metro del padre sin duplicarlos en los hijos', () => {
		const result = construirAuditoriaDemarcador({
			estrofas: [
				estrofa('familia', null, { tipo_rima_id: 'rima-consonante' }),
				estrofa('a', 'familia'),
				estrofa('b', 'familia')
			],
			opciones,
			relacionesMetro: [{ estrofa_tipo_id: 'familia', metro_id: 'octosilabo' }]
		});

		const familia = result.familias[0];
		expect(familia.sugerencia).toBe('familia');
		expect(familia.hijos[0].rasgos.find((rasgo) => rasgo.clave === 'rima')).toMatchObject({
			valor: 'Consonante',
			heredado: true
		});
		expect(familia.hijos[0].rasgos.find((rasgo) => rasgo.clave === 'metros')).toMatchObject({
			valor: 'Octosílabo (8)',
			heredado: true
		});
	});

	it('propone distinguir variantes por patrón sin tratar una familia concreta como excepción', () => {
		const result = construirAuditoriaDemarcador({
			estrofas: [
				estrofa('familia', null),
				estrofa('a', 'familia', { patron_especifico: 'abaab' }),
				estrofa('b', 'familia', { patron_especifico: 'ababa' })
			],
			opciones,
			relacionesMetro: []
		});

		expect(result.familias[0].sugerencia).toBe('variantes');
		expect(result.familias[0].rasgosDiferenciadores).toEqual(['patrón específico']);
	});

	it('propone distinguir variantes cuando cambia el metro', () => {
		const result = construirAuditoriaDemarcador({
			estrofas: [estrofa('familia', null), estrofa('a', 'familia'), estrofa('b', 'familia')],
			opciones,
			relacionesMetro: [
				{ estrofa_tipo_id: 'a', metro_id: 'octosilabo' },
				{ estrofa_tipo_id: 'b', metro_id: 'endecasilabo' }
			]
		});

		expect(result.familias[0].sugerencia).toBe('variantes');
		expect(result.familias[0].rasgosDiferenciadores).toContain('metro');
	});

	it('avisa cuando todos los hijos comparten un dato que el padre no declara', () => {
		const result = construirAuditoriaDemarcador({
			estrofas: [
				estrofa('familia', null),
				estrofa('a', 'familia', { naturaleza_estrofica_id: 'cerrada' }),
				estrofa('b', 'familia', { naturaleza_estrofica_id: 'cerrada' })
			],
			opciones,
			relacionesMetro: []
		});

		expect(result.familias[0].avisos).toEqual(
			expect.arrayContaining([
				expect.objectContaining({
					codigo: 'padre_sin_dato_comun',
					mensaje: expect.stringContaining('padre no')
				})
			])
		);
	});

	it('no interpreta tamaño o patrón nulos como valores heredados', () => {
		const result = construirAuditoriaDemarcador({
			estrofas: [
				estrofa('familia', null, {
					tamanio_unidad_estrofica: 5,
					patron_especifico: 'abaab'
				}),
				estrofa('a', 'familia'),
				estrofa('b', 'familia', {
					tamanio_unidad_estrofica: 5,
					patron_especifico: 'abaab'
				})
			],
			opciones,
			relacionesMetro: []
		});

		const rasgosA = result.familias[0].hijos[0].rasgos;
		expect(rasgosA.find((rasgo) => rasgo.clave === 'tamanio')).toMatchObject({
			valor: 'Sin tamaño fijo declarado',
			heredado: false
		});
		expect(rasgosA.find((rasgo) => rasgo.clave === 'patron')).toMatchObject({
			valor: 'Sin patrón fijo declarado',
			heredado: false
		});
	});

	it('mantiene separadas la sugerencia automática y la política revisada', () => {
		const result = construirAuditoriaDemarcador({
			estrofas: [
				estrofa('familia', null),
				estrofa('a', 'familia', { patron_especifico: 'abaab' }),
				estrofa('b', 'familia', { patron_especifico: 'ababa' })
			],
			opciones,
			relacionesMetro: [],
			configuraciones: [
				{ familia_id: 'familia', politica: 'familia', revisado_en: '2026-07-27T10:00:00Z' }
			]
		});

		expect(result.familias[0]).toMatchObject({
			sugerencia: 'variantes',
			politica: 'familia'
		});
	});
});

import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import {
	addSectionInstance,
	ensureRequiredMetricStructure,
	flatRepeatedMetricSection,
	flatVariableRepeatedMetricSection,
	hierarchicalRepeatedMetricSection,
	ensureRequiredFlatMetricStructure,
	isHierarchicalMetricStructure,
	syncFlatRepeatedMetricUnits,
	syncHierarchicalRepeatedMetricUnits,
	syncChoiceMaterializedSections,
	type MetricChoiceDraft
} from './editor-model';

let uuidCounter = 0;

beforeEach(() => {
	uuidCounter = 0;
	vi.stubGlobal('crypto', {
		randomUUID: () => `unit-${++uuidCounter}`
	});
});

const sections: MetricCatalogDomainRow[] = [
	{
		seccion_id: 'head',
		seccion_padre_id: null,
		tipo_seccion: 'cabeza',
		nombre: 'Cabeza',
		orden: 1,
		repeticiones_min: 1,
		repeticiones_max: 1,
		versos_min: 2,
		versos_max: 4
	},
	{
		seccion_id: 'ciclo',
		seccion_padre_id: null,
		tipo_seccion: 'ciclo_copla',
		nombre: 'Copla y posible represa',
		orden: 2,
		repeticiones_min: 1,
		repeticiones_max: null
	},
	{
		seccion_id: 'copla',
		seccion_padre_id: 'ciclo',
		tipo_seccion: 'copla',
		nombre: 'Copla',
		orden: 1,
		repeticiones_min: 1,
		repeticiones_max: 1
	},
	{
		seccion_id: 'mudanza',
		seccion_padre_id: 'copla',
		tipo_seccion: 'mudanza',
		nombre: 'Mudanza',
		orden: 1,
		repeticiones_min: 1,
		repeticiones_max: 1,
		versos_min: 4,
		versos_max: 4
	},
	{
		seccion_id: 'enlace',
		seccion_padre_id: 'copla',
		tipo_seccion: 'enlace_vuelta',
		nombre: 'Enlace o vuelta',
		orden: 2,
		repeticiones_min: 0,
		repeticiones_max: 1,
		versos_min: 1,
		versos_max: null
	},
	{
		seccion_id: 'represa',
		seccion_padre_id: 'ciclo',
		tipo_seccion: 'represa',
		nombre: 'Represa',
		orden: 2,
		repeticiones_min: 0,
		repeticiones_max: 1,
		versos_min: 1,
		versos_max: 4
	}
];

const repetitionOptions: MetricCatalogDomainRow[] = [
	{
		opcion_eleccion_id: 'total',
		grupo_eleccion_id: 'repetition',
		slug: 'total',
		materializa_seccion_id: 'represa',
		extension_desde_seccion_id: 'head',
		activo: true
	},
	{
		opcion_eleccion_id: 'implicit',
		grupo_eleccion_id: 'repetition',
		slug: 'implicita',
		materializa_seccion_id: null,
		extension_desde_seccion_id: null,
		activo: true
	}
];

describe('editor métrico jerárquico', () => {
	it('no crea trabajo adicional en una configuración sin jerarquía', () => {
		const simpleSections = [{ ...sections[0], repeticiones_min: 1 }];
		expect(isHierarchicalMetricStructure(simpleSections)).toBe(false);
		expect(ensureRequiredMetricStructure([], simpleSections, 1)).toEqual([]);
	});

	it('genera unidades repetidas desde un rango compatible', () => {
		const quintilla = [
			{
				seccion_id: 'quintilla',
				seccion_padre_id: null,
				tipo_seccion: 'quintilla',
				nombre: 'Quintilla',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: null,
				versos_min: 5,
				versos_max: 5
			}
		];
		expect(flatRepeatedMetricSection(quintilla)).toEqual(quintilla[0]);
		const synchronized = syncFlatRepeatedMetricUnits([], quintilla, 1, 15);
		expect(synchronized.compatible).toBe(true);
		expect(synchronized.units.map((unit) => [unit.v_ini, unit.v_fin])).toEqual([
			[1, 5],
			[6, 10],
			[11, 15]
		]);
	});

	it('genera novenas jerárquicas completas desde el rango', () => {
		const novena = [
			{
				seccion_id: 'novena',
				seccion_padre_id: null,
				tipo_seccion: 'novena',
				nombre: 'Novena',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: null
			},
			{
				seccion_id: 'redondilla',
				seccion_padre_id: 'novena',
				tipo_seccion: 'redondilla',
				nombre: 'Redondilla',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: 1,
				versos_min: 4,
				versos_max: 4
			},
			{
				seccion_id: 'quintilla',
				seccion_padre_id: 'novena',
				tipo_seccion: 'quintilla',
				nombre: 'Quintilla',
				orden: 2,
				repeticiones_min: 1,
				repeticiones_max: 1,
				versos_min: 5,
				versos_max: 5
			}
		];
		expect(hierarchicalRepeatedMetricSection(novena)).toMatchObject({
			section: novena[0],
			unitLength: 9
		});

		const synchronized = syncHierarchicalRepeatedMetricUnits([], novena, 10, 27);
		expect(synchronized.compatible).toBe(true);
		expect(
			synchronized.units
				.filter((unit) => unit.seccion_id === 'novena')
				.map((unit) => [unit.v_ini, unit.v_fin])
		).toEqual([
			[10, 18],
			[19, 27]
		]);
		expect(
			synchronized.units.map((unit) => [
				unit.seccion_id,
				unit.v_ini,
				unit.v_fin
			])
		).toEqual([
			['novena', 10, 18],
			['redondilla', 10, 13],
			['quintilla', 14, 18],
			['novena', 19, 27],
			['redondilla', 19, 22],
			['quintilla', 23, 27]
		]);
	});

	it('descompone 48 versos en doce redondillas sin convertirlos en una sola estrofa', () => {
		const redondilla = [
			{
				seccion_id: 'redondilla',
				seccion_padre_id: null,
				tipo_seccion: 'redondilla',
				nombre: 'Redondilla',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: null,
				versos_min: 4,
				versos_max: 4
			}
		];
		const synchronized = syncFlatRepeatedMetricUnits([], redondilla, 1, 48);

		expect(synchronized.compatible).toBe(true);
		expect(synchronized.units).toHaveLength(12);
		expect(synchronized.units[0]).toMatchObject({ orden: 1, v_ini: 1, v_fin: 4 });
		expect(synchronized.units[11]).toMatchObject({ orden: 12, v_ini: 45, v_fin: 48 });
	});

	it('descompone 48 versos en seis unidades de redondilla doble', () => {
		const redondillaDoble = [
			{
				seccion_id: 'redondilla-doble',
				seccion_padre_id: null,
				tipo_seccion: 'redondilla_doble',
				nombre: 'Redondilla doble',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: null,
				versos_min: 8,
				versos_max: 8
			}
		];
		const synchronized = syncFlatRepeatedMetricUnits([], redondillaDoble, 1, 48);

		expect(synchronized.compatible).toBe(true);
		expect(synchronized.units).toHaveLength(6);
		expect(synchronized.units[0]).toMatchObject({ orden: 1, v_ini: 1, v_fin: 8 });
		expect(synchronized.units[5]).toMatchObject({ orden: 6, v_ini: 41, v_fin: 48 });
	});

	it('crea la unidad mínima de una estructura plana con longitud variable', () => {
		const variable = [
			{
				seccion_id: 'copla',
				seccion_padre_id: null,
				tipo_seccion: 'copla_pie_quebrado',
				nombre: 'Copla',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: null,
				versos_min: 5,
				versos_max: 12
			}
		];
		expect(flatVariableRepeatedMetricSection(variable)).toEqual(variable[0]);
		expect(ensureRequiredFlatMetricStructure([], variable, 20)).toMatchObject([
			{ v_ini: 20, v_fin: 24, seccion_id: 'copla' }
		]);
	});

	it('conserva la identidad y las respuestas de las quintillas existentes al añadir otra', () => {
		const quintilla = [
			{
				seccion_id: 'quintilla',
				seccion_padre_id: null,
				tipo_seccion: 'quintilla',
				nombre: 'Quintilla',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: null,
				versos_min: 5,
				versos_max: 5
			}
		];
		const initial = syncFlatRepeatedMetricUnits([], quintilla, 1, 10).units;
		const initialIds = initial.map((unit) => unit.realizacion_prueba_id);
		const secondChoice: MetricChoiceDraft = {
			realizacion_prueba_id: initialIds[1],
			grupo_eleccion_id: 'esquema-rima',
			opcion_eleccion_id: 'abbab',
			observaciones: null
		};

		const expanded = syncFlatRepeatedMetricUnits(
			initial,
			quintilla,
			1,
			15,
			[secondChoice]
		).units;

		expect(expanded.slice(0, 2).map((unit) => unit.realizacion_prueba_id)).toEqual(initialIds);
		expect(secondChoice.realizacion_prueba_id).toBe(expanded[1].realizacion_prueba_id);
		expect(secondChoice.realizacion_prueba_id).not.toBe(expanded[2].realizacion_prueba_id);
		expect(expanded[2].realizacion_prueba_id).not.toBe(initialIds[0]);
		expect(expanded[2].realizacion_prueba_id).not.toBe(initialIds[1]);
	});

	it('no inventa unidades para un rango incompatible', () => {
		const quintilla = [
			{
				seccion_id: 'quintilla',
				seccion_padre_id: null,
				tipo_seccion: 'quintilla',
				nombre: 'Quintilla',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: null,
				versos_min: 5,
				versos_max: 5
			}
		];
		const synchronized = syncFlatRepeatedMetricUnits([], quintilla, 1, 48);
		expect(synchronized.compatible).toBe(false);
		expect(synchronized.units).toEqual([]);
	});

	it('crea la cabeza, el ciclo, la copla y su mudanza obligatoria', () => {
		const units = ensureRequiredMetricStructure([], sections, 1);
		expect(units.map((unit) => unit.seccion_id)).toEqual([
			'head',
			'ciclo',
			'copla',
			'mudanza'
		]);
		expect(units.find((unit) => unit.seccion_id === 'mudanza')).toMatchObject({
			realizacion_padre_id: 'unit-3',
			v_ini: 3,
			v_fin: 6
		});
		expect(units.find((unit) => unit.seccion_id === 'copla')).toMatchObject({
			realizacion_padre_id: 'unit-2',
			v_ini: 3,
			v_fin: 6
		});
	});

	it('recalcula rangos al añadir secciones opcionales', () => {
		let units = ensureRequiredMetricStructure([], sections, 1);
		const copla = units.find((unit) => unit.seccion_id === 'copla');
		expect(units.find((unit) => unit.seccion_id === 'head')).toMatchObject({
			v_ini: 1,
			v_fin: 2
		});
		expect(copla).toMatchObject({ v_ini: 3, v_fin: 6 });

		units = addSectionInstance(
			units,
			sections,
			'enlace',
			copla?.realizacion_prueba_id ?? null,
			1
		);
		expect(units.find((unit) => unit.seccion_id === 'enlace')).toMatchObject({
			v_ini: 7,
			v_fin: 7
		});
		expect(units.find((unit) => unit.seccion_id === 'copla')).toMatchObject({
			v_ini: 3,
			v_fin: 7
		});
	});

	it('crea una mudanza independiente dentro de cada ciclo de copla', () => {
		let units = ensureRequiredMetricStructure([], sections, 1);
		units = addSectionInstance(units, sections, 'ciclo', null, 1);
		const coplas = units.filter((unit) => unit.seccion_id === 'copla');
		const mudanzas = units.filter((unit) => unit.seccion_id === 'mudanza');

		expect(coplas).toHaveLength(2);
		expect(mudanzas).toHaveLength(2);
		expect(mudanzas.map((unit) => unit.realizacion_padre_id)).toEqual(
			coplas.map((unit) => unit.realizacion_prueba_id)
		);
		expect(coplas.map((unit) => [unit.v_ini, unit.v_fin])).toEqual([
			[3, 6],
			[7, 10]
		]);
	});

	it('materializa la represa como hermana de la copla y deriva su extensión de la cabeza', () => {
		let units = ensureRequiredMetricStructure([], sections, 1);
		const ciclo = units.find((unit) => unit.seccion_id === 'ciclo');
		const choices: MetricChoiceDraft[] = [
			{
				realizacion_prueba_id: ciclo?.realizacion_prueba_id ?? null,
				grupo_eleccion_id: 'repetition',
				opcion_eleccion_id: 'total',
				observaciones: null
			}
		];

		units = syncChoiceMaterializedSections(
			units,
			sections,
			ciclo?.realizacion_prueba_id ?? null,
			repetitionOptions,
			['total'],
			1,
			choices,
			repetitionOptions
		);

		expect(units.find((unit) => unit.seccion_id === 'represa')).toMatchObject({
			v_ini: 7,
			v_fin: 8
		});

		units = syncChoiceMaterializedSections(
			units,
			sections,
			ciclo?.realizacion_prueba_id ?? null,
			repetitionOptions,
			['implicit'],
			1,
			[
				{
					...choices[0],
					opcion_eleccion_id: 'implicit'
				}
			],
			repetitionOptions
		);
		expect(units.some((unit) => unit.seccion_id === 'represa')).toBe(false);
	});

	it('deriva una represa desde un estribillo anidado después de la primera copla', () => {
		const postposedSections: MetricCatalogDomainRow[] = [
			{
				seccion_id: 'primer-ciclo',
				seccion_padre_id: null,
				tipo_seccion: 'primer_ciclo',
				nombre: 'Primera copla y estribillo',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: 1
			},
			{
				seccion_id: 'primera-copla',
				seccion_padre_id: 'primer-ciclo',
				tipo_seccion: 'copla',
				nombre: 'Primera copla',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: 1,
				versos_min: 4,
				versos_max: 4
			},
			{
				seccion_id: 'estribillo-posterior',
				seccion_padre_id: 'primer-ciclo',
				tipo_seccion: 'estribillo',
				nombre: 'Primera aparición del estribillo',
				orden: 2,
				repeticiones_min: 1,
				repeticiones_max: 1,
				versos_min: 3,
				versos_max: 3
			},
			{
				seccion_id: 'ciclo-posterior',
				seccion_padre_id: null,
				tipo_seccion: 'ciclo_copla',
				nombre: 'Copla y posible represa',
				orden: 2,
				repeticiones_min: 0,
				repeticiones_max: null
			},
			{
				seccion_id: 'copla-posterior',
				seccion_padre_id: 'ciclo-posterior',
				tipo_seccion: 'copla',
				nombre: 'Copla',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: 1,
				versos_min: 4,
				versos_max: 4
			},
			{
				seccion_id: 'represa-posterior',
				seccion_padre_id: 'ciclo-posterior',
				tipo_seccion: 'represa',
				nombre: 'Represa',
				orden: 2,
				repeticiones_min: 0,
				repeticiones_max: 1,
				versos_min: 1,
				versos_max: null
			}
		];
		const totalOption: MetricCatalogDomainRow = {
			opcion_eleccion_id: 'total-posterior',
			grupo_eleccion_id: 'repetition-posterior',
			slug: 'total',
			materializa_seccion_id: 'represa-posterior',
			extension_desde_seccion_id: 'estribillo-posterior',
			activo: true
		};
		let units = ensureRequiredMetricStructure([], postposedSections, 1);
		units = addSectionInstance(units, postposedSections, 'ciclo-posterior', null, 1);
		const cycle = units.find((unit) => unit.seccion_id === 'ciclo-posterior');
		const choices: MetricChoiceDraft[] = [
			{
				realizacion_prueba_id: cycle?.realizacion_prueba_id ?? null,
				grupo_eleccion_id: 'repetition-posterior',
				opcion_eleccion_id: 'total-posterior',
				observaciones: null
			}
		];

		units = syncChoiceMaterializedSections(
			units,
			postposedSections,
			cycle?.realizacion_prueba_id ?? null,
			[totalOption],
			['total-posterior'],
			1,
			choices,
			[totalOption]
		);

		expect(units.find((unit) => unit.seccion_id === 'represa-posterior')).toMatchObject({
			v_ini: 12,
			v_fin: 14
		});
	});

	it('compone el zéjel con mudanza y vuelta fijas y materializa solo la represa elegida', () => {
		const zejelSections: MetricCatalogDomainRow[] = [
			{
				seccion_id: 'cabeza-zejel',
				seccion_padre_id: null,
				tipo_seccion: 'cabeza',
				nombre: 'Cabeza',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: 1,
				versos_min: 2,
				versos_max: 2
			},
			{
				seccion_id: 'ciclo-zejel',
				seccion_padre_id: null,
				tipo_seccion: 'ciclo_copla',
				nombre: 'Copla y posible represa',
				orden: 2,
				repeticiones_min: 1,
				repeticiones_max: null
			},
			{
				seccion_id: 'copla-zejel',
				seccion_padre_id: 'ciclo-zejel',
				tipo_seccion: 'copla',
				nombre: 'Copla',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: 1
			},
			{
				seccion_id: 'mudanza-zejel',
				seccion_padre_id: 'copla-zejel',
				tipo_seccion: 'mudanza',
				nombre: 'Mudanza monorrima',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: 1,
				versos_min: 3,
				versos_max: 3
			},
			{
				seccion_id: 'vuelta-zejel',
				seccion_padre_id: 'copla-zejel',
				tipo_seccion: 'vuelta',
				nombre: 'Verso de vuelta',
				orden: 2,
				repeticiones_min: 1,
				repeticiones_max: 1,
				versos_min: 1,
				versos_max: 1
			},
			{
				seccion_id: 'represa-zejel',
				seccion_padre_id: 'ciclo-zejel',
				tipo_seccion: 'represa',
				nombre: 'Represa',
				orden: 2,
				repeticiones_min: 0,
				repeticiones_max: 1,
				versos_min: 1,
				versos_max: 2
			}
		];
		const totalOption: MetricCatalogDomainRow = {
			opcion_eleccion_id: 'total-zejel',
			grupo_eleccion_id: 'repetition-zejel',
			slug: 'total',
			materializa_seccion_id: 'represa-zejel',
			extension_desde_seccion_id: 'cabeza-zejel',
			activo: true
		};
		let units = ensureRequiredMetricStructure([], zejelSections, 1);
		const cycle = units.find((unit) => unit.seccion_id === 'ciclo-zejel');

		expect(units.map((unit) => unit.seccion_id)).toEqual([
			'cabeza-zejel',
			'ciclo-zejel',
			'copla-zejel',
			'mudanza-zejel',
			'vuelta-zejel'
		]);
		expect(units.find((unit) => unit.seccion_id === 'mudanza-zejel')).toMatchObject({
			v_ini: 3,
			v_fin: 5
		});
		expect(units.find((unit) => unit.seccion_id === 'vuelta-zejel')).toMatchObject({
			v_ini: 6,
			v_fin: 6
		});

		const choices: MetricChoiceDraft[] = [
			{
				realizacion_prueba_id: cycle?.realizacion_prueba_id ?? null,
				grupo_eleccion_id: 'repetition-zejel',
				opcion_eleccion_id: 'total-zejel',
				observaciones: null
			}
		];
		units = syncChoiceMaterializedSections(
			units,
			zejelSections,
			cycle?.realizacion_prueba_id ?? null,
			[totalOption],
			['total-zejel'],
			1,
			choices,
			[totalOption]
		);

		expect(units.find((unit) => unit.seccion_id === 'represa-zejel')).toMatchObject({
			v_ini: 7,
			v_fin: 8
		});
	});
});

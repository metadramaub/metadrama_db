import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import {
	addMetricUnit,
	addSectionInstance,
	ensureRequiredMetricUnits,
	metricUnitExtent,
	metricUnitPlan,
	syncRepeatedMetricUnits,
	syncChoiceMaterializedSections,
	type MetricChoiceDraft,
	type MetricUnitDraft
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
		nombre: 'Represa del estribillo',
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

// La novena no tiene una sección que sea la novena: la unidad la envuelve.
const novenaSections: MetricCatalogDomainRow[] = [
	{
		seccion_id: 'redondilla',
		seccion_padre_id: null,
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
		seccion_padre_id: null,
		tipo_seccion: 'quintilla',
		nombre: 'Quintilla',
		orden: 2,
		repeticiones_min: 1,
		repeticiones_max: 1,
		versos_min: 5,
		versos_max: 5
	}
];

const fixedUnit = (versos: number) => ({
	unidad_versos_min: versos,
	unidad_versos_max: versos
});
const fixedExtent = (versos: number) => metricUnitExtent(fixedUnit(versos));
const sinUnidad = { unidad_versos_min: null, unidad_versos_max: null };

describe('la unidad declarada por la arquitectura', () => {
	it('no se materializa en una serie: la secuencia contiene una sola, de extensión libre', () => {
		expect(metricUnitPlan(sinUnidad, sections, 'serie')).toBeNull();
		expect(metricUnitPlan(fixedUnit(4), [], 'verso')).toBeNull();
	});

	it('no se materializa cuando la arquitectura no declara su unidad ni describe sus partes', () => {
		expect(metricUnitPlan(sinUnidad, [], 'estrofa')).toBeNull();
	});

	it('deriva cuántas unidades hay del rango cuando la extensión es fija', () => {
		expect(metricUnitPlan(fixedUnit(4), [], 'estrofa')).toEqual({
			extent: { minimum: 4, maximum: 4 },
			countFromRange: true
		});
	});

	it('deja el recuento al editor cuando la extensión es variable', () => {
		expect(
			metricUnitPlan({ unidad_versos_min: 5, unidad_versos_max: 12 }, [], 'estrofa')
		).toMatchObject({ countFromRange: false });
	});

	it('materializa la unidad de una composición que solo describe sus partes', () => {
		expect(metricUnitPlan(sinUnidad, sections, 'composicion')).toEqual({
			extent: null,
			countFromRange: false
		});
	});
});

describe('cuántas unidades contiene el pasaje', () => {
	it('descompone 48 versos en doce redondillas sin necesidad de una sección', () => {
		const synchronized = syncRepeatedMetricUnits([], [], fixedExtent(4), 1, 48);

		expect(synchronized.compatible).toBe(true);
		expect(synchronized.units).toHaveLength(12);
		expect(synchronized.units.every((unit) => unit.seccion_id === null)).toBe(true);
		expect(synchronized.units[0]).toMatchObject({ orden: 1, v_ini: 1, v_fin: 4 });
		expect(synchronized.units[11]).toMatchObject({ orden: 12, v_ini: 45, v_fin: 48 });
	});

	it('descompone 48 versos en seis unidades de redondilla doble', () => {
		const synchronized = syncRepeatedMetricUnits([], [], fixedExtent(8), 1, 48);

		expect(synchronized.compatible).toBe(true);
		expect(synchronized.units).toHaveLength(6);
		expect(synchronized.units[5]).toMatchObject({ orden: 6, v_ini: 41, v_fin: 48 });
	});

	it('materializa las unidades de una lira, que no tiene ninguna sección', () => {
		const synchronized = syncRepeatedMetricUnits([], [], fixedExtent(5), 100, 114);

		expect(synchronized.compatible).toBe(true);
		expect(synchronized.units.map((unit) => [unit.v_ini, unit.v_fin])).toEqual([
			[100, 104],
			[105, 109],
			[110, 114]
		]);
	});

	it('genera novenas completas con sus partes internas', () => {
		const synchronized = syncRepeatedMetricUnits([], novenaSections, fixedExtent(9), 10, 27);

		expect(synchronized.compatible).toBe(true);
		expect(
			synchronized.units.map((unit) => [unit.seccion_id, unit.v_ini, unit.v_fin])
		).toEqual([
			[null, 10, 18],
			['redondilla', 10, 13],
			['quintilla', 14, 18],
			[null, 19, 27],
			['redondilla', 19, 22],
			['quintilla', 23, 27]
		]);
	});

	it('no inventa unidades para un rango incompatible', () => {
		const synchronized = syncRepeatedMetricUnits([], [], fixedExtent(5), 1, 48);

		expect(synchronized.compatible).toBe(false);
		expect(synchronized.units).toEqual([]);
	});

	it('no reparte el rango cuando la unidad tiene extensión variable', () => {
		const variable = metricUnitExtent({ unidad_versos_min: 5, unidad_versos_max: 12 });
		expect(syncRepeatedMetricUnits([], [], variable, 20, 30).compatible).toBe(false);
		expect(ensureRequiredMetricUnits([], [], variable, 20)).toMatchObject([
			{ v_ini: 20, v_fin: 24, seccion_id: null }
		]);
	});

	it('conserva la identidad y las respuestas de las unidades existentes al ampliar el rango', () => {
		const initial = syncRepeatedMetricUnits([], [], fixedExtent(5), 1, 10).units;
		const initialIds = initial.map((unit) => unit.realizacion_prueba_id);
		const secondChoice: MetricChoiceDraft = {
			realizacion_prueba_id: initialIds[1],
			grupo_eleccion_id: 'esquema-rima',
			opcion_eleccion_id: 'abbab',
			observaciones: null
		};

		const expanded = syncRepeatedMetricUnits(initial, [], fixedExtent(5), 1, 15, [secondChoice]).units;

		expect(expanded.slice(0, 2).map((unit) => unit.realizacion_prueba_id)).toEqual(initialIds);
		expect(secondChoice.realizacion_prueba_id).toBe(expanded[1].realizacion_prueba_id);
		expect(expanded[2].realizacion_prueba_id).not.toBe(initialIds[0]);
		expect(expanded[2].realizacion_prueba_id).not.toBe(initialIds[1]);
	});

	it('retira las unidades sobrantes al acortar el rango', () => {
		const initial = syncRepeatedMetricUnits([], [], fixedExtent(4), 1, 12).units;
		const reduced = syncRepeatedMetricUnits(initial, [], fixedExtent(4), 1, 8);

		expect(reduced.compatible).toBe(true);
		expect(reduced.units).toHaveLength(2);
		expect(reduced.removedUnitIds).toEqual([initial[2].realizacion_prueba_id]);
	});
});

/** La unidad de una composición que no declara su extensión: una sola, calculada. */
const unidadDe = (secciones: MetricCatalogDomainRow[], inicio = 1) =>
	ensureRequiredMetricUnits([], secciones, null, inicio);

const unidadRaiz = (units: MetricUnitDraft[]) =>
	units.find((unit) => unit.realizacion_padre_id === null && unit.seccion_id === null);

describe('la unidad envuelve a las secciones', () => {
	it('crea la unidad con la cabeza, el ciclo, la copla y su mudanza obligatoria', () => {
		const units = unidadDe(sections);
		expect(units.map((unit) => unit.seccion_id)).toEqual([
			null,
			'head',
			'ciclo',
			'copla',
			'mudanza'
		]);
		// Las secciones raíz cuelgan de la unidad, no de la secuencia.
		const unidad = unidadRaiz(units);
		expect(units.find((unit) => unit.seccion_id === 'head')?.realizacion_padre_id).toBe(
			unidad?.realizacion_prueba_id
		);
		expect(units.find((unit) => unit.seccion_id === 'ciclo')?.realizacion_padre_id).toBe(
			unidad?.realizacion_prueba_id
		);
		expect(unidad).toMatchObject({ v_ini: 1, v_fin: 6 });
		expect(units.find((unit) => unit.seccion_id === 'mudanza')).toMatchObject({
			v_ini: 3,
			v_fin: 6
		});
	});

	it('registra dos composiciones seguidas en la misma secuencia', () => {
		let units = unidadDe(sections);
		units = addMetricUnit(units, sections, null, 1);
		const unidades = units.filter(
			(unit) => unit.realizacion_padre_id === null && unit.seccion_id === null
		);

		expect(unidades).toHaveLength(2);
		expect(unidades.map((unit) => [unit.v_ini, unit.v_fin])).toEqual([
			[1, 6],
			[7, 12]
		]);
		expect(units.filter((unit) => unit.seccion_id === 'mudanza')).toHaveLength(2);
	});

	it('recalcula rangos al añadir secciones opcionales', () => {
		let units = unidadDe(sections);
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
		let units = unidadDe(sections);
		units = addSectionInstance(
			units,
			sections,
			'ciclo',
			unidadRaiz(units)?.realizacion_prueba_id ?? null,
			1
		);
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
		let units = unidadDe(sections);
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
		let units = unidadDe(postposedSections);
		units = addSectionInstance(
			units,
			postposedSections,
			'ciclo-posterior',
			unidadRaiz(units)?.realizacion_prueba_id ?? null,
			1
		);
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
		let units = unidadDe(zejelSections);
		const cycle = units.find((unit) => unit.seccion_id === 'ciclo-zejel');

		expect(units.map((unit) => unit.seccion_id)).toEqual([
			null,
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

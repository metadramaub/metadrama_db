import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import {
	addMetricUnit,
	addSectionInstance,
	ensureRequiredMetricUnits,
	hayUnidadConArquitecturaPropia,
	metricUnitExtent,
	partesDeLaRealizacion,
	metricUnitPlan,
	reflowMetricUnits,
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
		expect(synchronized.units.map((unit) => [unit.seccion_id, unit.v_ini, unit.v_fin])).toEqual([
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
		const initialIds = initial.map((unit) => unit.realizacion_id);
		const secondChoice: MetricChoiceDraft = {
			realizacion_id: initialIds[1],
			grupo_eleccion_id: 'esquema-rima',
			opcion_eleccion_id: 'abbab',
			observaciones: null
		};

		const expanded = syncRepeatedMetricUnits(initial, [], fixedExtent(5), 1, 15, [
			secondChoice
		]).units;

		expect(expanded.slice(0, 2).map((unit) => unit.realizacion_id)).toEqual(initialIds);
		expect(secondChoice.realizacion_id).toBe(expanded[1].realizacion_id);
		expect(expanded[2].realizacion_id).not.toBe(initialIds[0]);
		expect(expanded[2].realizacion_id).not.toBe(initialIds[1]);
	});

	it('retira las unidades sobrantes al acortar el rango', () => {
		const initial = syncRepeatedMetricUnits([], [], fixedExtent(4), 1, 12).units;
		const reduced = syncRepeatedMetricUnits(initial, [], fixedExtent(4), 1, 8);

		expect(reduced.compatible).toBe(true);
		expect(reduced.units).toHaveLength(2);
		expect(reduced.removedUnitIds).toEqual([initial[2].realizacion_id]);
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
			unidad?.realizacion_id
		);
		expect(units.find((unit) => unit.seccion_id === 'ciclo')?.realizacion_padre_id).toBe(
			unidad?.realizacion_id
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

		units = addSectionInstance(units, sections, 'enlace', copla?.realizacion_id ?? null, 1);
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
			unidadRaiz(units)?.realizacion_id ?? null,
			1
		);
		const coplas = units.filter((unit) => unit.seccion_id === 'copla');
		const mudanzas = units.filter((unit) => unit.seccion_id === 'mudanza');

		expect(coplas).toHaveLength(2);
		expect(mudanzas).toHaveLength(2);
		expect(mudanzas.map((unit) => unit.realizacion_padre_id)).toEqual(
			coplas.map((unit) => unit.realizacion_id)
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
				realizacion_id: ciclo?.realizacion_id ?? null,
				grupo_eleccion_id: 'repetition',
				opcion_eleccion_id: 'total',
				observaciones: null
			}
		];

		units = syncChoiceMaterializedSections(
			units,
			sections,
			ciclo?.realizacion_id ?? null,
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
			ciclo?.realizacion_id ?? null,
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
			unidadRaiz(units)?.realizacion_id ?? null,
			1
		);
		const cycle = units.find((unit) => unit.seccion_id === 'ciclo-posterior');
		const choices: MetricChoiceDraft[] = [
			{
				realizacion_id: cycle?.realizacion_id ?? null,
				grupo_eleccion_id: 'repetition-posterior',
				opcion_eleccion_id: 'total-posterior',
				observaciones: null
			}
		];

		units = syncChoiceMaterializedSections(
			units,
			postposedSections,
			cycle?.realizacion_id ?? null,
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

	it('deja que el primer estribillo fije la extensión y la aplica a los posteriores', () => {
		const selfReferencedSections: MetricCatalogDomainRow[] = [
			{
				seccion_id: 'ciclo',
				seccion_padre_id: null,
				tipo_seccion: 'ciclo_copla',
				nombre: 'Ciclo',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: null
			},
			{
				seccion_id: 'estribillo',
				seccion_padre_id: 'ciclo',
				tipo_seccion: 'estribillo',
				nombre: 'Estribillo',
				orden: 1,
				repeticiones_min: 0,
				repeticiones_max: 1,
				versos_min: 1,
				versos_max: 4
			}
		];
		const total: MetricCatalogDomainRow = {
			opcion_eleccion_id: 'total',
			grupo_eleccion_id: 'repeticion',
			slug: 'total',
			materializa_seccion_id: 'estribillo',
			extension_desde_seccion_id: 'estribillo',
			activo: true
		};
		const choices: MetricChoiceDraft[] = ['ciclo-1', 'ciclo-2'].map((cycleId) => ({
			realizacion_id: cycleId,
			grupo_eleccion_id: 'repeticion',
			opcion_eleccion_id: 'total',
			observaciones: null
		}));
		const units: MetricUnitDraft[] = [
			{
				realizacion_id: 'raiz',
				realizacion_padre_id: null,
				seccion_id: null,
				orden: 1,
				v_ini: 1,
				v_fin: 4,
				etiqueta: '',
				observaciones: ''
			},
			{
				realizacion_id: 'ciclo-1',
				realizacion_padre_id: 'raiz',
				seccion_id: 'ciclo',
				orden: 2,
				v_ini: 1,
				v_fin: 3,
				etiqueta: '',
				observaciones: ''
			},
			{
				realizacion_id: 'estribillo-1',
				realizacion_padre_id: 'ciclo-1',
				seccion_id: 'estribillo',
				orden: 3,
				v_ini: 1,
				v_fin: 3,
				etiqueta: '',
				observaciones: ''
			},
			{
				realizacion_id: 'ciclo-2',
				realizacion_padre_id: 'raiz',
				seccion_id: 'ciclo',
				orden: 4,
				v_ini: 4,
				v_fin: 4,
				etiqueta: '',
				observaciones: ''
			},
			{
				realizacion_id: 'estribillo-2',
				realizacion_padre_id: 'ciclo-2',
				seccion_id: 'estribillo',
				orden: 5,
				v_ini: 4,
				v_fin: 4,
				etiqueta: '',
				observaciones: ''
			}
		];

		const flowed = reflowMetricUnits(units, selfReferencedSections, 1, choices, [total]);

		expect(flowed.find((unit) => unit.realizacion_id === 'estribillo-1')).toMatchObject({
			v_ini: 1,
			v_fin: 3
		});
		expect(flowed.find((unit) => unit.realizacion_id === 'estribillo-2')).toMatchObject({
			v_ini: 4,
			v_fin: 6
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
				realizacion_id: cycle?.realizacion_id ?? null,
				grupo_eleccion_id: 'repetition-zejel',
				opcion_eleccion_id: 'total-zejel',
				observaciones: null
			}
		];
		units = syncChoiceMaterializedSections(
			units,
			zejelSections,
			cycle?.realizacion_id ?? null,
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

describe('una unidad con arquitectura propia', () => {
	const unidad = (id: string, arquitectura_id: string | null = null) => ({
		realizacion_id: id,
		realizacion_padre_id: null,
		seccion_id: null,
		orden: 1,
		v_ini: 1,
		v_fin: 10,
		etiqueta: '',
		observaciones: '',
		arquitectura_id
	});

	/**
	 * B5. Con una décima aumentada intercalada, el rango deja de dividirse en unidades iguales:
	 * derivarlas borraría la excepción en cuanto el editor recalculara.
	 */
	it('apaga la derivación de unidades desde el rango', () => {
		expect(metricUnitPlan(fixedUnit(10), [], 'estrofa', [unidad('a')])).toMatchObject({
			countFromRange: true
		});
		expect(
			metricUnitPlan(fixedUnit(10), [], 'estrofa', [unidad('a'), unidad('b', 'aumentada')])
		).toMatchObject({ countFromRange: false });
	});

	it('no la apaga una parte, solo una unidad entera', () => {
		const parte = { ...unidad('c', 'aumentada'), realizacion_padre_id: 'a', seccion_id: 's' };
		expect(metricUnitPlan(fixedUnit(10), [], 'estrofa', [unidad('a'), parte])).toMatchObject({
			countFromRange: true
		});
	});

	it('sin unidades se comporta como antes', () => {
		expect(metricUnitPlan(fixedUnit(10), [], 'estrofa')).toMatchObject({ countFromRange: true });
	});
});

/**
 * La décima aumentada entre décimas normales, en pequeño.
 *
 * La espinela son tres partes —4 + 2 + 4— y la aumentada dos —4 + 8—. Aquí están las dos, cada
 * una con su `arquitectura_id`, porque lo que se prueba es justamente que una unidad pueda
 * dividirse por las de la suya y no por las de la secuencia.
 */
const seccionDe = (
	arquitectura: string,
	seccion: string,
	nombre: string,
	orden: number,
	versos: number
): MetricCatalogDomainRow => ({
	seccion_id: seccion,
	arquitectura_id: arquitectura,
	seccion_padre_id: null,
	tipo_seccion: 'bloque',
	nombre,
	orden,
	repeticiones_min: 1,
	repeticiones_max: 1,
	versos_min: versos,
	versos_max: versos
});

const espinela: MetricCatalogDomainRow[] = [
	seccionDe('espinela', 'primera', 'Primera redondilla', 1, 4),
	seccionDe('espinela', 'enlace', 'Enlace', 2, 2),
	seccionDe('espinela', 'segunda', 'Segunda redondilla', 3, 4)
];
const aumentada: MetricCatalogDomainRow[] = [
	seccionDe('aumentada', 'bloque1', 'Primer bloque', 1, 4),
	seccionDe('aumentada', 'bloque2', 'Segundo bloque', 2, 8)
];

describe('una unidad puede declarar una arquitectura intercalada', () => {
	it('reparte las partes de cada unidad según la arquitectura que declare', () => {
		expect(
			partesDeLaRealizacion(espinela, { seccion_id: null, arquitectura_id: null }, aumentada).map(
				(section) => section.seccion_id
			)
		).toEqual(['primera', 'enlace', 'segunda']);
		expect(
			partesDeLaRealizacion(
				espinela,
				{ seccion_id: null, arquitectura_id: 'aumentada' },
				aumentada
			).map((section) => section.seccion_id)
		).toEqual(['bloque1', 'bloque2']);
	});

	it('cambia las partes de la unidad marcada y deja intactas las demás', () => {
		let units = ensureRequiredMetricUnits([], espinela, null, 1, [], [], aumentada);
		units = addMetricUnit(units, espinela, null, 1);
		const unidades = units.filter(
			(unit) => unit.realizacion_padre_id === null && unit.seccion_id === null
		);
		expect(unidades).toHaveLength(2);

		// La segunda se declara aumentada. La primera no se toca.
		units = units.map((unit) =>
			unit.realizacion_id === unidades[1].realizacion_id
				? { ...unit, arquitectura_id: 'aumentada' }
				: unit
		);
		units = ensureRequiredMetricUnits(units, espinela, null, 1, [], [], aumentada);

		const partesDe = (unidadId: string) =>
			units
				.filter((unit) => unit.realizacion_padre_id === unidadId)
				.map((unit) => unit.seccion_id);
		expect(partesDe(unidades[0].realizacion_id)).toEqual([
			'primera',
			'enlace',
			'segunda'
		]);
		// Las tres de la espinela se van; entran las dos suyas. Un filtro global las habría
		// dejado, porque siguen siendo buenas para la otra unidad.
		expect(partesDe(unidades[1].realizacion_id)).toEqual(['bloque1', 'bloque2']);
	});

	it('mide la unidad excepcional por sus propias secciones', () => {
		let units = ensureRequiredMetricUnits([], espinela, null, 1, [], [], aumentada);
		units = addMetricUnit(units, espinela, null, 1);
		const unidades = units.filter(
			(unit) => unit.realizacion_padre_id === null && unit.seccion_id === null
		);
		units = units.map((unit) =>
			unit.realizacion_id === unidades[1].realizacion_id
				? { ...unit, arquitectura_id: 'aumentada' }
				: unit
		);
		units = ensureRequiredMetricUnits(units, espinela, null, 1, [], [], aumentada);

		const conArquitectura = units.find((unit) => unit.arquitectura_id === 'aumentada');
		// Diez versos la normal, doce la aumentada: el pasaje mide 22, no 20.
		expect(unidades[0].seccion_id).toBeNull();
		expect(conArquitectura).toMatchObject({ v_ini: 11, v_fin: 22 });
		expect(units.find((unit) => unit.seccion_id === 'bloque2')).toMatchObject({
			v_ini: 15,
			v_fin: 22
		});
	});

	it('no cuenta como excepción una unidad sin arquitectura propia', () => {
		expect(hayUnidadConArquitecturaPropia([])).toBe(false);
		const units = ensureRequiredMetricUnits([], espinela, null, 1, [], [], aumentada);
		expect(hayUnidadConArquitecturaPropia(units)).toBe(false);
		expect(
			hayUnidadConArquitecturaPropia(
				units.map((unit) =>
					unit.seccion_id === null ? { ...unit, arquitectura_id: 'aumentada' } : unit
				)
			)
		).toBe(true);
	});
});

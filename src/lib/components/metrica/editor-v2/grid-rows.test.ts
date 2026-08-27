import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import {
	addSectionInstance,
	ensureRequiredMetricUnits,
	syncChoiceMaterializedSections,
	syncRepeatedMetricUnits,
	type MetricChoiceDraft,
	type MetricUnitDraft,
	type MetricUnitPlan
} from './editor-model';
import {
	buildGridRows,
	estadoDeRespuesta,
	preguntasCompartidas,
	seccionesOpcionalesUniformes,
	unitsForGroup,
	usaRespuestasPorPartes,
	type GridRow,
	type GridRowContext
} from './grid-rows';

/**
 * Los cuatro casos con los que se juzga la pantalla, con los datos del catálogo en vivo
 * —secciones, repeticiones, extensiones, preguntas y opciones— a 11 de agosto de 2026.
 *
 * Cada prueba comprueba dos cosas a la vez: qué se ve y qué se guarda. Lo segundo importa
 * tanto como lo primero, porque la rejilla es una capa de simplificación y por debajo cada
 * realización sigue conservando su propia respuesta.
 */

let uuidCounter = 0;

beforeEach(() => {
	uuidCounter = 0;
	vi.stubGlobal('crypto', { randomUUID: () => `r-${++uuidCounter}` });
});

function contexto(partial: Partial<GridRowContext>): GridRowContext {
	return {
		sections: [],
		groups: [],
		options: [],
		schemes: [],
		units: [],
		choices: [],
		unitPlan: null,
		unitLabel: 'Unidad',
		...partial
	};
}

/** Una lectura corta de la rejilla, para poder comparar la pantalla entera de un vistazo. */
function pintar(rows: GridRow[]): string[] {
	return rows.map((row) => {
		const sangria = '  '.repeat(row.depth);
		if (row.kind === 'fijas') {
			const suyas = row.preguntas.map((pregunta) => String(pregunta.group.slug)).join(', ');
			return `${sangria}${row.label} · vv. ${row.v_ini}–${row.v_fin} · ${row.cuantas} de ${row.versos} versos${
				suyas ? ` · ${suyas}` : ''
			}`;
		}
		if (row.kind === 'acciones') {
			return `${sangria}[${row.modo}] ${row.label} · ${row.cuantas}`;
		}
		if (row.kind === 'pregunta') {
			const preguntas = row.preguntas.map((pregunta) => String(pregunta.group.slug)).join(', ');
			return `${sangria}${row.label} · sin versos materializados · ${preguntas}`;
		}
		const preguntas = row.preguntas.map((pregunta) => String(pregunta.group.slug)).join(', ');
		return `${sangria}${row.label} · vv. ${row.unit.v_ini}–${row.unit.v_fin}${
			preguntas ? ` · ${preguntas}` : ''
		}${row.nota ? ` · ${row.nota}` : ''}`;
	});
}

// ───────────────────────────── Quintilla ─────────────────────────────

const QUINTILLA_PLAN: MetricUnitPlan = { extent: { minimum: 5, maximum: 5 }, countFromRange: true };

const quintillaGrupo: MetricCatalogDomainRow = {
	grupo_eleccion_id: 'g-quintilla',
	slug: 'esquema_rima',
	nombre: 'Esquema de rima',
	dimension: 'rima',
	alcance: 'unidad',
	tipo_control: 'opciones',
	permite_aplicar_global: true,
	selecciones_min: 1,
	selecciones_max: 1,
	seccion_id: null,
	orden: 1,
	activo: true
};

const quintillaOpciones: MetricCatalogDomainRow[] = [
	{
		opcion_eleccion_id: 'o-abaab',
		grupo_eleccion_id: 'g-quintilla',
		slug: 'abaab',
		nombre: 'Tipología 3 · abaab',
		orden: 3,
		activo: true
	},
	{
		opcion_eleccion_id: 'o-aabba',
		grupo_eleccion_id: 'g-quintilla',
		slug: 'aabba',
		nombre: 'Tipología 5 · aabba',
		orden: 5,
		activo: true
	}
];

function quintilla(vIni: number, vFin: number) {
	const { units } = syncRepeatedMetricUnits([], [], QUINTILLA_PLAN.extent, vIni, vFin);
	return contexto({
		groups: [quintillaGrupo],
		options: quintillaOpciones,
		units,
		unitPlan: QUINTILLA_PLAN,
		unitLabel: 'Quintilla'
	});
}

describe('quintilla · dos unidades de cinco versos', () => {
	it('pinta una fila por unidad y ninguna tarjeta vacía', () => {
		const ctx = quintilla(116, 125);
		expect(pintar(buildGridRows(ctx))).toEqual([
			'Quintilla 1 · vv. 116–120 · esquema_rima · 5 versos fijos',
			'Quintilla 2 · vv. 121–125 · esquema_rima · 5 versos fijos'
		]);
	});

	it('ofrece arriba la pregunta que responde a las dos de una vez', () => {
		const ctx = quintilla(116, 125);
		const comunes = preguntasCompartidas(ctx);
		expect(comunes).toHaveLength(1);
		expect(comunes[0].label).toBe('Esquema de rima');
		expect(comunes[0].realizaciones).toBe(2);
	});

	it('con una sola unidad no hay atajo: la pregunta vive solo en su fila', () => {
		const ctx = quintilla(116, 120);
		expect(preguntasCompartidas(ctx)).toHaveLength(0);
		expect(buildGridRows(ctx)).toHaveLength(1);
	});

	it('guarda una respuesta por unidad, y la fila divergente se distingue', () => {
		const ctx = quintilla(116, 125);
		const [primera, segunda] = ctx.units;
		ctx.choices = [
			{
				realizacion_id: primera.realizacion_id,
				grupo_eleccion_id: 'g-quintilla',
				opcion_eleccion_id: 'o-abaab',
				valor_texto: null,
				observaciones: null
			},
			{
				realizacion_id: segunda.realizacion_id,
				grupo_eleccion_id: 'g-quintilla',
				opcion_eleccion_id: 'o-abaab',
				valor_texto: null,
				observaciones: null
			}
		];
		expect(estadoDeRespuesta(ctx, quintillaGrupo, primera)).toBe('igual');
		expect(estadoDeRespuesta(ctx, quintillaGrupo, segunda)).toBe('igual');

		// La segunda se cambia: se guardan dos respuestas distintas, una por unidad.
		ctx.choices = [ctx.choices[0], { ...ctx.choices[1], opcion_eleccion_id: 'o-aabba' }];
		expect(estadoDeRespuesta(ctx, quintillaGrupo, primera)).toBe('propia');
		expect(estadoDeRespuesta(ctx, quintillaGrupo, segunda)).toBe('propia');
		expect(ctx.choices.map((choice) => choice.opcion_eleccion_id)).toEqual(['o-abaab', 'o-aabba']);
	});

	it('sin responder no se atenúa: es lo que falta', () => {
		const ctx = quintilla(116, 125);
		expect(estadoDeRespuesta(ctx, quintillaGrupo, ctx.units[0])).toBe('sin_responder');
	});

	it('distingue una respuesta compartida por varias unidades de una excepción individual', () => {
		const ctx = quintilla(116, 130);
		const [primera, segunda, tercera] = ctx.units;
		ctx.choices = [
			...([primera, segunda].map((unit) => ({
				realizacion_id: unit.realizacion_id,
				grupo_eleccion_id: 'g-quintilla',
				opcion_eleccion_id: 'o-abaab',
				valor_texto: null,
				observaciones: null
			}))),
			{
				realizacion_id: tercera.realizacion_id,
				grupo_eleccion_id: 'g-quintilla',
				opcion_eleccion_id: 'o-aabba',
				valor_texto: null,
				observaciones: null
			}
		];
		expect(estadoDeRespuesta(ctx, quintillaGrupo, primera)).toBe('compartida');
		expect(estadoDeRespuesta(ctx, quintillaGrupo, segunda)).toBe('compartida');
		expect(estadoDeRespuesta(ctx, quintillaGrupo, tercera)).toBe('propia');
	});

	it('ocho unidades son ocho filas, que es lo que el IP aceptó', () => {
		const rows = buildGridRows(quintilla(116, 155));
		expect(rows).toHaveLength(8);
		expect(rows.every((row) => row.kind === 'realizacion')).toBe(true);
	});
});

// ───────────────────────────── Pareado ─────────────────────────────

const PAREADO_PLAN: MetricUnitPlan = { extent: { minimum: 2, maximum: 2 }, countFromRange: true };

const pareadoMedida: MetricCatalogDomainRow = {
	grupo_eleccion_id: 'g-medida-pareado',
	slug: 'medida_del_pareado',
	nombre: 'Medida de cada verso',
	dimension: 'metro',
	alcance: 'unidad',
	tipo_control: 'opciones',
	permite_aplicar_global: true,
	selecciones_min: 2,
	selecciones_max: 2,
	seccion_id: null,
	orden: 1,
	activo: true
};

const pareadoRima: MetricCatalogDomainRow = {
	grupo_eleccion_id: 'g-rima-pareado',
	slug: 'tipo_de_rima',
	nombre: 'Esquema de rima',
	dimension: 'rima',
	alcance: 'unidad',
	tipo_control: 'opciones',
	permite_aplicar_global: true,
	selecciones_min: 1,
	selecciones_max: 1,
	seccion_id: null,
	orden: 2,
	activo: true
};

const pareadoOpciones: MetricCatalogDomainRow[] = [
	{
		opcion_eleccion_id: 'p-v1-8',
		grupo_eleccion_id: 'g-medida-pareado',
		slug: 'verso-1-octosilabo',
		nombre: 'Verso 1 · Octosílabo',
		posicion_unidad: 1,
		metro_id: 'm-8',
		orden: 1,
		activo: true
	},
	{
		opcion_eleccion_id: 'p-v1-11',
		grupo_eleccion_id: 'g-medida-pareado',
		slug: 'verso-1-endecasilabo',
		nombre: 'Verso 1 · Endecasílabo',
		posicion_unidad: 1,
		metro_id: 'm-11',
		orden: 2,
		activo: true
	},
	{
		opcion_eleccion_id: 'p-v2-8',
		grupo_eleccion_id: 'g-medida-pareado',
		slug: 'verso-2-octosilabo',
		nombre: 'Verso 2 · Octosílabo',
		posicion_unidad: 2,
		metro_id: 'm-8',
		orden: 3,
		activo: true
	},
	{
		opcion_eleccion_id: 'p-v2-11',
		grupo_eleccion_id: 'g-medida-pareado',
		slug: 'verso-2-endecasilabo',
		nombre: 'Verso 2 · Endecasílabo',
		posicion_unidad: 2,
		metro_id: 'm-11',
		orden: 4,
		activo: true
	},
	{
		opcion_eleccion_id: 'p-aa',
		grupo_eleccion_id: 'g-rima-pareado',
		slug: 'asonante-aa',
		nombre: 'Asonante · aa',
		orden: 1,
		activo: true
	},
	{
		opcion_eleccion_id: 'p-AA',
		grupo_eleccion_id: 'g-rima-pareado',
		slug: 'consonante-aa',
		nombre: 'Consonante · aa',
		orden: 2,
		activo: true
	}
];

function pareado(vIni: number, vFin: number) {
	const { units } = syncRepeatedMetricUnits([], [], PAREADO_PLAN.extent, vIni, vFin);
	return contexto({
		groups: [pareadoMedida, pareadoRima],
		options: pareadoOpciones,
		units,
		unitPlan: PAREADO_PLAN,
		unitLabel: 'Pareado'
	});
}

describe('pareado · dos dísticos', () => {
	it('ofrece arriba tanto la medida posicional como la rima', () => {
		const comunes = preguntasCompartidas(pareado(116, 119));
		expect(comunes.map((pregunta) => pregunta.label)).toEqual([
			'Medida de cada verso',
			'Esquema de rima'
		]);
		expect(comunes.map((pregunta) => pregunta.realizaciones)).toEqual([2, 2]);
	});

	it('con un solo dístico mantiene las dos preguntas únicamente en su fila', () => {
		const ctx = pareado(116, 117);
		expect(preguntasCompartidas(ctx)).toHaveLength(0);
		expect(pintar(buildGridRows(ctx))).toEqual([
			'Pareado · vv. 116–117 · medida_del_pareado, tipo_de_rima · 2 versos fijos'
		]);
	});

	it('la medida sigue siendo dos elecciones guardadas por cada dístico', () => {
		const ctx = pareado(116, 119);
		ctx.choices = ctx.units.flatMap((unit) => [
			{
				realizacion_id: unit.realizacion_id,
				grupo_eleccion_id: 'g-medida-pareado',
				opcion_eleccion_id: 'p-v1-8',
				valor_texto: null,
				observaciones: null
			},
			{
				realizacion_id: unit.realizacion_id,
				grupo_eleccion_id: 'g-medida-pareado',
				opcion_eleccion_id: 'p-v2-8',
				valor_texto: null,
				observaciones: null
			}
		]);
		expect(ctx.choices).toHaveLength(4);
		expect(estadoDeRespuesta(ctx, pareadoMedida, ctx.units[0])).toBe('igual');
		expect(estadoDeRespuesta(ctx, pareadoMedida, ctx.units[1])).toBe('igual');
	});
});

// ───────────────────────────── Soneto ─────────────────────────────

const SONETO_PLAN: MetricUnitPlan = {
	extent: { minimum: 14, maximum: 14 },
	countFromRange: true
};

const sonetoSecciones: MetricCatalogDomainRow[] = [
	{
		seccion_id: 's-cuarteto',
		seccion_padre_id: null,
		slug: 'cuarteto',
		tipo_seccion: 'cuarteto',
		nombre: 'Cuartetos',
		orden: 1,
		repeticiones_min: 2,
		repeticiones_max: 2,
		versos_min: 4,
		versos_max: 4
	},
	{
		seccion_id: 's-terceto',
		seccion_padre_id: null,
		slug: 'terceto',
		tipo_seccion: 'terceto',
		nombre: 'Tercetos',
		orden: 2,
		repeticiones_min: 2,
		repeticiones_max: 2,
		versos_min: 3,
		versos_max: 3
	}
];

// Las dos preguntas cuelgan de la unidad —`seccion_id` nulo—, no de sus secciones.
const sonetoGrupos: MetricCatalogDomainRow[] = [
	{
		grupo_eleccion_id: 'g-cuartetos',
		slug: 'esquema_cuartetos',
		nombre: 'Cuartetos · Esquema de rima',
		dimension: 'rima',
		alcance: 'unidad',
		tipo_control: 'opciones',
		permite_aplicar_global: true,
		selecciones_min: 1,
		selecciones_max: 1,
		seccion_id: null,
		orden: 1,
		activo: true
	},
	{
		grupo_eleccion_id: 'g-tercetos',
		slug: 'esquema_tercetos',
		nombre: 'Tercetos · Esquema de rima',
		dimension: 'rima',
		alcance: 'unidad',
		tipo_control: 'opciones',
		permite_aplicar_global: false,
		selecciones_min: 1,
		selecciones_max: 1,
		seccion_id: null,
		orden: 1,
		activo: true
	}
];

// Las dos preguntas no declaran sección, pero sus esquemas sí: es lo que dice de cuál hablan.
const sonetoEsquemas: MetricCatalogDomainRow[] = [
	{ esquema_rima_id: 'e-c1', seccion_id: 's-cuarteto' },
	{ esquema_rima_id: 'e-c2', seccion_id: 's-cuarteto' },
	{ esquema_rima_id: 'e-t1', seccion_id: 's-terceto' },
	{ esquema_rima_id: 'e-t2', seccion_id: 's-terceto' }
];
const sonetoOpciones: MetricCatalogDomainRow[] = [
	{
		opcion_eleccion_id: 'sc1',
		grupo_eleccion_id: 'g-cuartetos',
		esquema_rima_id: 'e-c1',
		slug: 'abba',
		nombre: 'Cuartetos de rima abrazada · ABBA ABBA',
		orden: 1,
		activo: true
	},
	{
		opcion_eleccion_id: 'sc2',
		grupo_eleccion_id: 'g-cuartetos',
		esquema_rima_id: 'e-c2',
		slug: 'abab',
		nombre: 'Cuartetos de rima cruzada · ABAB ABAB',
		orden: 2,
		activo: true
	},
	{
		opcion_eleccion_id: 'st1',
		grupo_eleccion_id: 'g-tercetos',
		esquema_rima_id: 'e-t1',
		slug: 'cdcdcd',
		nombre: 'Tercetos de rima cruzada · CDC DCD',
		orden: 1,
		activo: true
	},
	{
		opcion_eleccion_id: 'st2',
		grupo_eleccion_id: 'g-tercetos',
		esquema_rima_id: 'e-t2',
		slug: 'cdecde',
		nombre: 'Tercetos de rima paralela · CDE CDE',
		orden: 3,
		activo: true
	}
];

function soneto(vIni: number, vFin: number) {
	const { units } = syncRepeatedMetricUnits([], sonetoSecciones, SONETO_PLAN.extent, vIni, vFin);
	return contexto({
		sections: sonetoSecciones,
		groups: sonetoGrupos,
		options: sonetoOpciones,
		schemes: sonetoEsquemas,
		units,
		unitPlan: SONETO_PLAN,
		unitLabel: 'Soneto'
	});
}

describe('soneto · tres seguidos', () => {
	it('pregunta cada esquema en la fila de la sección de la que habla', () => {
		// La fila del soneto se queda sin preguntas y las secciones dejan de ser un eco: cada
		// una lleva la suya. Antes había tres filas donde la de abajo repetía el nombre de la
		// sección sin dejar tocar nada.
		expect(pintar(buildGridRows(soneto(1, 42)))).toEqual([
			'Soneto 1 · vv. 1–14 · rango calculado desde sus partes',
			'  Cuartetos · vv. 1–8 · 2 de 4 versos · esquema_cuartetos',
			'  Tercetos · vv. 9–14 · 2 de 3 versos · esquema_tercetos',
			'Soneto 2 · vv. 15–28 · rango calculado desde sus partes',
			'  Cuartetos · vv. 15–22 · 2 de 4 versos · esquema_cuartetos',
			'  Tercetos · vv. 23–28 · 2 de 3 versos · esquema_tercetos',
			'Soneto 3 · vv. 29–42 · rango calculado desde sus partes',
			'  Cuartetos · vv. 29–36 · 2 de 4 versos · esquema_cuartetos',
			'  Tercetos · vv. 37–42 · 2 de 3 versos · esquema_tercetos'
		]);
	});

	it('un solo soneto se lee sin fila de soneto: dos secciones y sus dos esquemas', () => {
		expect(pintar(buildGridRows(soneto(116, 129)))).toEqual([
			'Cuartetos · vv. 116–123 · 2 de 4 versos · esquema_cuartetos',
			'Tercetos · vv. 124–129 · 2 de 3 versos · esquema_tercetos'
		]);
	});

	it('la respuesta se sigue guardando en la unidad, no en la sección', () => {
		const ctx = soneto(116, 129);
		const rows = buildGridRows(ctx);
		const unidad = ctx.units.find((unit) => unit.seccion_id === null)!;
		for (const row of rows) {
			if (row.kind !== 'fijas') continue;
			for (const pregunta of row.preguntas) {
				expect(pregunta.owner.realizacion_id).toBe(unidad.realizacion_id);
			}
		}
	});

	it('quita de la etiqueta el nombre de la sección que la fila ya dice', () => {
		const rows = buildGridRows(soneto(116, 129));
		const etiquetas = rows.flatMap((row) =>
			row.kind === 'fijas' ? row.preguntas.map((pregunta) => pregunta.label) : []
		);
		expect(etiquetas).toEqual(['Esquema de rima', 'Esquema de rima']);
	});

	it('respeta el catálogo: los cuartetos admiten atajo y los tercetos no', () => {
		const comunes = preguntasCompartidas(soneto(1, 42));
		expect(comunes.map((pregunta) => pregunta.label)).toEqual(['Cuartetos · Esquema de rima']);
	});

	it('un solo soneto no ofrece atajo: no hay dos de nada que responder a la vez', () => {
		expect(preguntasCompartidas(soneto(1, 14))).toHaveLength(0);
	});
});

// ───────────────────────────── Villancico ─────────────────────────────

const villancicoSecciones: MetricCatalogDomainRow[] = [
	{
		seccion_id: 's-cabeza',
		seccion_padre_id: null,
		slug: 'cabeza',
		tipo_seccion: 'estribillo',
		nombre: 'Cabeza',
		orden: 1,
		repeticiones_min: 1,
		repeticiones_max: 1,
		versos_min: 2,
		versos_max: 4
	},
	{
		seccion_id: 's-ciclo',
		seccion_padre_id: null,
		slug: 'ciclo_copla',
		tipo_seccion: 'ciclo_copla',
		nombre: 'Ciclo de copla y estribillo',
		orden: 2,
		repeticiones_min: 1,
		repeticiones_max: null,
		versos_min: null,
		versos_max: null
	},
	{
		seccion_id: 's-copla',
		seccion_padre_id: 's-ciclo',
		slug: 'copla',
		tipo_seccion: 'copla',
		nombre: 'Copla',
		orden: 1,
		repeticiones_min: 1,
		repeticiones_max: 1,
		versos_min: null,
		versos_max: null
	},
	{
		seccion_id: 's-represa',
		seccion_padre_id: 's-ciclo',
		slug: 'represa',
		tipo_seccion: 'estribillo',
		nombre: 'Repetición del estribillo',
		orden: 2,
		repeticiones_min: 0,
		repeticiones_max: 1,
		versos_min: 1,
		versos_max: 4
	},
	{
		seccion_id: 's-mudanza',
		seccion_padre_id: 's-copla',
		slug: 'mudanza',
		tipo_seccion: 'mudanza',
		nombre: 'Mudanza',
		orden: 1,
		repeticiones_min: 1,
		repeticiones_max: 1,
		versos_min: 4,
		versos_max: 4
	},
	{
		seccion_id: 's-enlace',
		seccion_padre_id: 's-copla',
		slug: 'enlace_vuelta',
		tipo_seccion: 'enlace_vuelta',
		nombre: 'Enlace o vuelta',
		orden: 2,
		repeticiones_min: 0,
		repeticiones_max: 1,
		versos_min: 1,
		versos_max: null
	}
];

const villancicoGrupos: MetricCatalogDomainRow[] = [
	{
		grupo_eleccion_id: 'g-medida-cabeza',
		slug: 'medida_cabeza',
		nombre: 'Cabeza · Medida de los versos',
		dimension: 'metro',
		alcance: 'unidad',
		tipo_control: 'opciones',
		permite_aplicar_global: true,
		selecciones_min: 1,
		selecciones_max: 1,
		seccion_id: 's-cabeza',
		orden: 1,
		activo: true
	},
	{
		grupo_eleccion_id: 'g-medida-mudanza',
		slug: 'medida_mudanza',
		nombre: 'Mudanza · Medida de los versos',
		dimension: 'metro',
		alcance: 'unidad',
		tipo_control: 'opciones',
		permite_aplicar_global: true,
		selecciones_min: 1,
		selecciones_max: 1,
		seccion_id: 's-mudanza',
		orden: 2,
		activo: true
	},
	{
		grupo_eleccion_id: 'g-rima-mudanza',
		slug: 'rima_mudanza',
		nombre: 'Mudanza · Esquema de rima',
		dimension: 'rima',
		alcance: 'unidad',
		tipo_control: 'opciones',
		permite_aplicar_global: true,
		selecciones_min: 1,
		selecciones_max: 1,
		seccion_id: 's-mudanza',
		orden: 2,
		activo: true
	},
	{
		grupo_eleccion_id: 'g-represa',
		slug: 'represa_estribillo',
		nombre: 'Repetición del estribillo',
		dimension: 'repeticion',
		alcance: 'realizacion',
		tipo_control: 'opciones',
		permite_aplicar_global: true,
		selecciones_min: 1,
		selecciones_max: 1,
		seccion_id: 's-ciclo',
		orden: 3,
		activo: true
	},
	{
		grupo_eleccion_id: 'g-medida-enlace',
		slug: 'medida_enlace_vuelta',
		nombre: 'Enlace o vuelta · Medida de los versos',
		dimension: 'metro',
		alcance: 'unidad',
		tipo_control: 'opciones',
		permite_aplicar_global: true,
		selecciones_min: 1,
		selecciones_max: 1,
		seccion_id: 's-enlace',
		orden: 3,
		activo: true
	}
];

const villancicoOpciones: MetricCatalogDomainRow[] = [
	{
		opcion_eleccion_id: 'o-represa-entera',
		grupo_eleccion_id: 'g-represa',
		slug: 'total',
		nombre: 'Se repite entero',
		orden: 1,
		activo: true,
		materializa_seccion_id: 's-represa',
		extension_desde_seccion_id: 's-cabeza'
	},
	{
		opcion_eleccion_id: 'o-represa-parcial',
		grupo_eleccion_id: 'g-represa',
		slug: 'parcial',
		nombre: 'Se repite solo en parte',
		orden: 2,
		activo: true,
		materializa_seccion_id: 's-represa'
	},
	{
		opcion_eleccion_id: 'o-represa-implicita',
		grupo_eleccion_id: 'g-represa',
		slug: 'implicita',
		nombre: 'Se sobreentiende, no está escrito',
		orden: 3,
		activo: true
	}
];

/** Un villancico con `ciclos` ciclos, con enlace y con el estribillo repetido entero. */
function villancico(ciclos: number) {
	let units = ensureRequiredMetricUnits([], villancicoSecciones, null, 1, [], villancicoOpciones);
	const unidad = units.find((unit) => unit.seccion_id === null)!;
	for (let añadido = 1; añadido < ciclos; añadido += 1) {
		units = addSectionInstance(
			units,
			villancicoSecciones,
			's-ciclo',
			unidad.realizacion_id,
			1,
			[],
			villancicoOpciones
		);
	}

	// El editor responde la repetición del estribillo en cada ciclo, y esa respuesta es la
	// que materializa la sección: no se añade a mano.
	let choices: MetricChoiceDraft[] = [];
	for (const ciclo of units.filter((unit) => unit.seccion_id === 's-ciclo')) {
		choices = [
			...choices,
			{
				realizacion_id: ciclo.realizacion_id,
				grupo_eleccion_id: 'g-represa',
				opcion_eleccion_id: 'o-represa-entera',
				valor_texto: null,
				observaciones: null
			}
		];
		units = syncChoiceMaterializedSections(
			units,
			villancicoSecciones,
			ciclo.realizacion_id,
			villancicoOpciones.filter((option) => option.grupo_eleccion_id === 'g-represa'),
			['o-represa-entera'],
			1,
			choices,
			villancicoOpciones
		);
	}

	// Y el enlace o vuelta, que es opcional, se añade en cada copla.
	for (const copla of units.filter((unit) => unit.seccion_id === 's-copla')) {
		units = addSectionInstance(
			units,
			villancicoSecciones,
			's-enlace',
			copla.realizacion_id,
			1,
			choices,
			villancicoOpciones
		);
	}

	return contexto({
		sections: villancicoSecciones,
		groups: villancicoGrupos,
		options: villancicoOpciones,
		units,
		choices,
		unitPlan: { extent: null, countFromRange: false },
		unitLabel: 'Villancico'
	});
}

describe('canción petrarquista · la primera estancia declara el patrón', () => {
	const estancia: MetricCatalogDomainRow = {
		seccion_id: 's-estancia',
		seccion_padre_id: null,
		slug: 'estancia',
		nombre: 'Estancia',
		tipo_seccion: 'estancia',
		orden: 1,
		repeticiones_min: 3,
		repeticiones_max: null,
		versos_min: 5,
		versos_max: 20,
		primera_realizacion_define_patron: true
	};
	const medida: MetricCatalogDomainRow = {
		grupo_eleccion_id: 'g-medida-estancia',
		slug: 'medida_estancia',
		nombre: 'Estancia · Medida de cada verso',
		dimension: 'metro',
		alcance: 'unidad',
		seccion_id: 's-estancia',
		define_norma: true,
		permite_aplicar_global: true,
		selecciones_min: 5,
		selecciones_max: 20,
		activo: true
	};
	const rima: MetricCatalogDomainRow = {
		...medida,
		grupo_eleccion_id: 'g-rima-estancia',
		slug: 'esquema_rima_estancia',
		nombre: 'Estancia · Esquema de rima observado',
		dimension: 'rima',
		tipo_control: 'esquema_rima',
		selecciones_min: 1,
		selecciones_max: 1
	};
	const units: MetricUnitDraft[] = [
		{ realizacion_id: 'cancion', realizacion_padre_id: null, seccion_id: null, orden: 1, v_ini: 1, v_fin: 18, etiqueta: '', observaciones: '' },
		{ realizacion_id: 'e1', realizacion_padre_id: 'cancion', seccion_id: 's-estancia', orden: 1, v_ini: 1, v_fin: 6, etiqueta: '', observaciones: '' },
		{ realizacion_id: 'e2', realizacion_padre_id: 'cancion', seccion_id: 's-estancia', orden: 2, v_ini: 7, v_fin: 12, etiqueta: '', observaciones: '' },
		{ realizacion_id: 'e3', realizacion_padre_id: 'cancion', seccion_id: 's-estancia', orden: 3, v_ini: 13, v_fin: 18, etiqueta: '', observaciones: '' }
	];

	it('distingue la estancia modelo de sus resultados heredados', () => {
		const rows = buildGridRows(
			contexto({
				sections: [estancia],
				groups: [medida, rima],
				units,
				unitPlan: { extent: null, countFromRange: false },
				unitLabel: 'Canción petrarquista'
			})
		);
		expect(pintar(rows).slice(0, 3)).toEqual([
			'Estancia modelo · vv. 1–6 · medida_estancia, esquema_rima_estancia · Declara el patrón que repiten las demás estancias',
			'Estancia 2 · vv. 7–12 · medida_estancia, esquema_rima_estancia · Repite extensión, medidas y rima de la estancia modelo',
			'Estancia 3 · vv. 13–18 · medida_estancia, esquema_rima_estancia · Repite extensión, medidas y rima de la estancia modelo'
		]);
		expect(
			usaRespuestasPorPartes(
				contexto({
					sections: [estancia],
					groups: [medida, rima],
					units,
					unitPlan: { extent: null, countFromRange: false }
				})
			)
		).toBe(true);
	});
});

describe('villancico · estribillo inicial, tres ciclos', () => {
	it('dibuja la composición verso a verso, sin la copla, que no pregunta nada', () => {
		// La cabeza nace con su mínimo —2 versos— y el enlace con el suyo —1—, que es lo que
		// el editor corregirá al leer el texto. La repetición mide lo que mide la cabeza.
		expect(pintar(buildGridRows(villancico(3)))).toEqual([
			'Cabeza · vv. 1–2 · medida_cabeza',
			'Ciclo de copla y estribillo 1 · vv. 3–9 · rango calculado desde sus partes',
			'  Mudanza · vv. 3–6 · medida_mudanza, rima_mudanza · 4 versos fijos',
			'  Enlace o vuelta · vv. 7–7 · medida_enlace_vuelta',
			'  Repetición del estribillo · vv. 8–9 · represa_estribillo · 2 versos, calculados desde «Cabeza»',
			'Ciclo de copla y estribillo 2 · vv. 10–16 · rango calculado desde sus partes',
			'  Mudanza · vv. 10–13 · medida_mudanza, rima_mudanza · 4 versos fijos',
			'  Enlace o vuelta · vv. 14–14 · medida_enlace_vuelta',
			'  Repetición del estribillo · vv. 15–16 · represa_estribillo · 2 versos, calculados desde «Cabeza»',
			'Ciclo de copla y estribillo 3 · vv. 17–23 · rango calculado desde sus partes',
			'  Mudanza · vv. 17–20 · medida_mudanza, rima_mudanza · 4 versos fijos',
			'  Enlace o vuelta · vv. 21–21 · medida_enlace_vuelta',
			'  Repetición del estribillo · vv. 22–23 · represa_estribillo · 2 versos, calculados desde «Cabeza»',
			'[anadir] Ciclo de copla y estribillo · 3'
		]);
	});

	it('la unidad no pinta fila propia cuando solo hay un villancico', () => {
		const rows = buildGridRows(villancico(3));
		expect(rows.some((row) => row.kind === 'realizacion' && row.label === 'Villancico')).toBe(
			false
		);
	});

	it('presenta rima y medida como propiedades de la mudanza sin repetir su nombre', () => {
		const mudanza = buildGridRows(villancico(1)).find(
			(row) => row.kind === 'realizacion' && row.label === 'Mudanza'
		);
		expect(mudanza?.kind).toBe('realizacion');
		if (mudanza?.kind !== 'realizacion') return;
		expect(mudanza.preguntas.map((pregunta) => pregunta.label)).toEqual([
			'Medida de los versos',
			'Esquema de rima'
		]);
	});

	it('ofrece arriba solo las preguntas que apuntan a dos o más realizaciones', () => {
		const comunes = preguntasCompartidas(villancico(3)).map((pregunta) => pregunta.label);
		// La cabeza es única, así que su medida se responde en su fila y no arriba.
		expect(comunes).not.toContain('Cabeza · Medida de los versos');
		expect(comunes.sort()).toEqual([
			'Enlace o vuelta · Medida de los versos',
			'Mudanza · Esquema de rima',
			'Mudanza · Medida de los versos',
			'Repetición del estribillo'
		]);
	});

	it('se responde por partes y no ofrece una segunda composición raíz', () => {
		const ctx = villancico(2);
		expect(usaRespuestasPorPartes(ctx)).toBe(true);
		const acciones = buildGridRows(ctx).filter(
			(row): row is Extract<GridRow, { kind: 'acciones' }> => row.kind === 'acciones'
		);
		expect(acciones.some((row) => row.section === null)).toBe(false);
		expect(acciones.map((row) => row.section?.slug)).toContain('ciclo_copla');
	});

	it('diferencia cada ciclo como contenedor y permite quitarlo si sobra', () => {
		const ciclos = buildGridRows(villancico(2)).filter(
			(row) => row.kind === 'realizacion' && row.section?.slug === 'ciclo_copla'
		);
		expect(ciclos).toHaveLength(2);
		expect(
			ciclos.every((row) => row.kind === 'realizacion' && row.container && row.removable)
		).toBe(true);
	});

	it('mantiene el atajo por sección aunque exista el de toda la composición', () => {
		// Son dos ejes distintos: uno recorre las secciones y otro las tres realizaciones de
		// una. El villancico heterométrico de Navarro Tomás —cuarteta octosilábica con
		// estribillo hexasílabo— necesita los dos, y sin el segundo habría que corregir el
		// estribillo ciclo por ciclo.
		const comunes = preguntasCompartidas(villancico(3)).map((pregunta) => pregunta.label);
		expect(comunes).toContain('Mudanza · Medida de los versos');
		expect(comunes).toContain('Enlace o vuelta · Medida de los versos');
	});

	it('el enlace o vuelta se puede poner o quitar de todas las coplas a la vez', () => {
		const opcionales = seccionesOpcionalesUniformes(villancico(3)).map((section) =>
			String(section.slug)
		);
		// La repetición del estribillo no está: la materializa una respuesta, no una casilla.
		expect(opcionales).toEqual(['enlace_vuelta']);
	});

	it('guarda una respuesta de repetición por ciclo, no una para el villancico', () => {
		const ctx = villancico(3);
		const ciclos = ctx.units.filter((unit) => unit.seccion_id === 's-ciclo');
		expect(ciclos).toHaveLength(3);
		for (const ciclo of ciclos) {
			const suyas = ctx.choices.filter(
				(choice) => choice.realizacion_id === ciclo.realizacion_id
			);
			expect(suyas).toHaveLength(1);
			expect(suyas[0].grupo_eleccion_id).toBe('g-represa');
		}
		// Y cada repetición cuelga de su ciclo, no del villancico.
		const represas = ctx.units.filter((unit) => unit.seccion_id === 's-represa');
		expect(represas).toHaveLength(3);
		expect(
			represas.every((represa) =>
				ciclos.some((ciclo) => ciclo.realizacion_id === represa.realizacion_padre_id)
			)
		).toBe(true);
	});

	it('con un solo ciclo se sigue viendo el ciclo, porque se pueden añadir más', () => {
		const rows = pintar(buildGridRows(villancico(1)));
		expect(rows).toContain(
			'Ciclo de copla y estribillo · vv. 3–9 · rango calculado desde sus partes'
		);
		expect(rows).toContain('[anadir] Ciclo de copla y estribillo · 1');
	});

	it('coloca la pregunta después de la copla aunque el estribillo se sobreentienda', () => {
		const ctx = villancico(1);
		const ciclo = ctx.units.find((unit) => unit.seccion_id === 's-ciclo')!;
		ctx.choices = [
			{
				realizacion_id: ciclo.realizacion_id,
				grupo_eleccion_id: 'g-represa',
				opcion_eleccion_id: 'o-represa-implicita',
				valor_texto: null,
				observaciones: null
			}
		];
		ctx.units = syncChoiceMaterializedSections(
			ctx.units,
			villancicoSecciones,
			ciclo.realizacion_id,
			villancicoOpciones.filter((option) => option.grupo_eleccion_id === 'g-represa'),
			['o-represa-implicita'],
			1,
			ctx.choices,
			villancicoOpciones
		);
		const rows = buildGridRows(ctx);
		const mudanza = rows.findIndex(
			(row) => row.kind === 'realizacion' && row.section?.slug === 'mudanza'
		);
		const enlace = rows.findIndex(
			(row) => row.kind === 'realizacion' && row.section?.slug === 'enlace_vuelta'
		);
		const repeticion = rows.findIndex((row) => row.kind === 'pregunta');
		expect(mudanza).toBeLessThan(enlace);
		expect(enlace).toBeLessThan(repeticion);
		expect(pintar(rows)[repeticion]).toBe(
			'  Repetición del estribillo · sin versos materializados · represa_estribillo'
		);
		const pregunta = rows[repeticion];
		expect(pregunta.kind === 'pregunta' && pregunta.preguntas[0].owner.realizacion_id).toBe(
			ciclo.realizacion_id
		);
	});
});

describe('villancico · estribillo tras la primera copla', () => {
	it('pide la extensión en la primera aparición y la deriva solo en las siguientes', () => {
		const sections: MetricCatalogDomainRow[] = [
			{
				seccion_id: 'ciclo',
				seccion_padre_id: null,
				slug: 'ciclo_copla',
				tipo_seccion: 'ciclo_copla',
				nombre: 'Ciclo de copla y estribillo',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: null
			},
			{
				seccion_id: 'estribillo',
				seccion_padre_id: 'ciclo',
				slug: 'estribillo',
				tipo_seccion: 'estribillo',
				nombre: 'Estribillo',
				orden: 1,
				repeticiones_min: 1,
				repeticiones_max: 1,
				versos_min: 1,
				versos_max: 4
			}
		];
		const groups: MetricCatalogDomainRow[] = [
			{
				grupo_eleccion_id: 'repeticion',
				seccion_id: 'ciclo',
				slug: 'represa_estribillo',
				nombre: 'Repetición del estribillo',
				dimension: 'repeticion',
				alcance: 'realizacion',
				tipo_control: 'opciones',
				permite_aplicar_global: true,
				selecciones_min: 1,
				selecciones_max: 1,
				orden: 1,
				activo: true
			},
			{
				grupo_eleccion_id: 'medida',
				seccion_id: 'estribillo',
				slug: 'medida_estribillo',
				nombre: 'Estribillo · Medida de los versos',
				dimension: 'metro',
				alcance: 'unidad',
				tipo_control: 'opciones',
				permite_aplicar_global: true,
				selecciones_min: 1,
				selecciones_max: 1,
				orden: 2,
				activo: true
			}
		];
		const options: MetricCatalogDomainRow[] = [
			{
				opcion_eleccion_id: 'total',
				grupo_eleccion_id: 'repeticion',
				slug: 'total',
				nombre: 'Se repite entero',
				materializa_seccion_id: 'estribillo',
				extension_desde_seccion_id: 'estribillo',
				orden: 1,
				activo: true
			}
		];
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
				v_fin: 6,
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
				v_fin: 6,
				etiqueta: '',
				observaciones: ''
			},
			{
				realizacion_id: 'estribillo-2',
				realizacion_padre_id: 'ciclo-2',
				seccion_id: 'estribillo',
				orden: 5,
				v_ini: 4,
				v_fin: 6,
				etiqueta: '',
				observaciones: ''
			}
		];
		const rows = buildGridRows(
			contexto({
				sections,
				groups,
				options,
				choices,
				units,
				unitPlan: { extent: null, countFromRange: false },
				unitLabel: 'Villancico'
			})
		).filter(
			(row): row is Extract<GridRow, { kind: 'realizacion' }> =>
				row.kind === 'realizacion' && row.section?.slug === 'estribillo'
		);

		expect(rows).toHaveLength(2);
		expect(rows[0]).toMatchObject({ lengthEditable: true, nota: '' });
		expect(rows[1]).toMatchObject({
			lengthEditable: false,
			nota: '3 versos, calculados desde «Estribillo»'
		});
		const context = contexto({
			sections,
			groups,
			options,
			choices,
			units,
			unitPlan: { extent: null, countFromRange: false },
			unitLabel: 'Villancico'
		});
		expect(unitsForGroup(context, groups[0]).map((unit) => unit.realizacion_id)).toEqual([
			'ciclo-2'
		]);
	});
});

// ───────────────────────────── Romance ─────────────────────────────

describe('romance · el control del experimento', () => {
	it('no tiene estructura que pintar: es una serie sin unidad declarada', () => {
		const ctx = contexto({ unitLabel: 'Romance' });
		expect(buildGridRows(ctx)).toEqual([]);
		expect(preguntasCompartidas(ctx)).toEqual([]);
	});
});

// ────────────────── Lo que no se puede tocar desde la rejilla ──────────────────

describe('lo que la rejilla no deja hacer a mano', () => {
	it('no ofrece añadir unidades cuando el rango las decide', () => {
		const rows = buildGridRows(quintilla(116, 125));
		expect(rows.some((row) => row.kind === 'acciones')).toBe(false);
	});

	it('no ofrece añadir una sección que materializa una respuesta', () => {
		const ctx = villancico(2);
		const acciones = buildGridRows(ctx).filter(
			(row): row is Extract<GridRow, { kind: 'acciones' }> => row.kind === 'acciones'
		);
		expect(acciones.some((row) => String(row.section?.slug) === 'represa')).toBe(false);
	});

	it('tampoco ofrece quitarla: se quita cambiando la respuesta', () => {
		// Quitarla a mano dejaba «se repite entero» apuntando a una repetición inexistente, y
		// nada volvía a crearla hasta tocar la respuesta otra vez.
		const represas = buildGridRows(villancico(2)).filter(
			(row) => row.kind === 'realizacion' && String(row.section?.slug) === 'represa'
		);
		expect(represas).toHaveLength(2);
		expect(represas.every((row) => row.kind === 'realizacion' && !row.removable)).toBe(true);
	});

	it('el enlace o vuelta sí se quita a mano: es opcional, no lo pone una respuesta', () => {
		const enlaces = buildGridRows(villancico(2)).filter(
			(row) => row.kind === 'realizacion' && String(row.section?.slug) === 'enlace_vuelta'
		);
		expect(enlaces.every((row) => row.kind === 'realizacion' && row.removable)).toBe(true);
	});

	it('deja escribir la extensión de las secciones que no la tienen fijada', () => {
		const rows = buildGridRows(villancico(1));
		const editables = rows
			.filter((row) => row.kind === 'realizacion' && row.lengthEditable)
			.map((row) => (row.kind === 'realizacion' ? row.label : ''));
		expect(editables.sort()).toEqual(['Cabeza', 'Enlace o vuelta']);
	});
});

/** Las unidades sueltas no se pierden al construir las filas: se pintan todas. */
describe('ninguna realización se queda sin pintar', () => {
	it('cada realización aparece en una fila o en un resumen', () => {
		for (const ctx of [quintilla(116, 155), soneto(1, 42), villancico(3)]) {
			const rows = buildGridRows(ctx);
			const enFilas = new Set(
				rows.flatMap((row) => (row.kind === 'realizacion' ? [row.unit.realizacion_id] : []))
			);
			const enResumen = rows.flatMap((row) =>
				row.kind === 'fijas'
					? ctx.units
							.filter(
								(unit: MetricUnitDraft) =>
									unit.seccion_id === (row.section ? String(row.section.seccion_id) : null)
							)
							.map((unit: MetricUnitDraft) => unit.realizacion_id)
					: []
			);
			// La copla es el único caso previsto de realización sin fila: no pregunta nada y su
			// rango se lee en el de sus partes.
			const sinPintar = ctx.units.filter(
				(unit) =>
					!enFilas.has(unit.realizacion_id) &&
					!enResumen.includes(unit.realizacion_id)
			);
			expect(
				sinPintar.every((unit) => unit.seccion_id === 's-copla' || unit.seccion_id === null)
			).toBe(true);
		}
	});
});

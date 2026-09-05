import { beforeEach, describe, expect, it, vi } from 'vitest';
import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import { syncRepeatedMetricUnits, type MetricUnitPlan } from './editor-model';
import { buildGridRows, unitsForGroup, type GridRowContext } from './grid-rows';
import { preguntasDelFormulario } from './preguntas-formulario';

/**
 * **Lo que estas pruebas vigilan es el contrato, no la pantalla.**
 *
 * La lista plana sustituye a los dos sitios que dibujaban preguntas, así que lo que hay que
 * demostrar es que **a la base sigue llegando lo mismo**: los mismos pares (grupo, realización)
 * que las filas resolvían, ni uno más ni uno menos. Que se vean apilados o en dos columnas es
 * lo de menos aquí.
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

const QUINTILLA_PLAN: MetricUnitPlan = {
	extent: { minimum: 5, maximum: 5 },
	countFromRange: true
};

const quintillaGrupo = {
	grupo_eleccion_id: 'g-rima',
	arquitectura_id: 'a-quintilla',
	slug: 'esquema_rima',
	nombre: 'Esquema de rima',
	dimension: 'rima',
	alcance: 'unidad',
	seccion_id: null,
	selecciones_min: 1,
	selecciones_max: 1,
	permite_aplicar_global: true,
	tipo_control: 'opciones_y_esquema',
	activo: true,
	orden: 1
} as unknown as MetricCatalogDomainRow;

const quintillaOpciones = ['ababa', 'abbab', 'abaab'].map(
	(slug, indice) =>
		({
			opcion_eleccion_id: `o-${slug}`,
			grupo_eleccion_id: 'g-rima',
			slug,
			nombre: `Tipología ${indice + 1} · ${slug}`,
			activo: true,
			orden: indice + 1
		}) as unknown as MetricCatalogDomainRow
);

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

/** Los pares que acabarían en `anotacion_elecciones`, leídos de las filas de siempre. */
function destinatariasSegunLasFilas(ctx: GridRowContext): string[] {
	const pares: string[] = [];
	for (const row of buildGridRows(ctx)) {
		if (row.kind === 'acciones') continue;
		for (const pregunta of row.preguntas) {
			const par = `${String(pregunta.group.grupo_eleccion_id)}|${pregunta.owner.realizacion_id}`;
			if (!pares.includes(par)) pares.push(par);
		}
	}
	return pares.sort();
}

function destinatariasSegunElFormulario(ctx: GridRowContext): string[] {
	return preguntasDelFormulario(ctx)
		.flatMap((pregunta) =>
			pregunta.destinatarias.map(
				(destinataria) =>
					`${String(destinataria.group.grupo_eleccion_id)}|${destinataria.owner.realizacion_id}`
			)
		)
		.sort();
}

describe('quintilla · varias unidades', () => {
	it('reúne las cinco realizaciones en una sola pregunta de unidad', () => {
		const preguntas = preguntasDelFormulario(quintilla(1, 25));
		expect(preguntas).toHaveLength(1);
		expect(preguntas[0].rotulo).toBe('Esquema de rima');
		expect(preguntas[0].alcance).toBe('unidad');
		expect(preguntas[0].destinatarias).toHaveLength(5);
	});

	it('las destinatarias son las mismas que resolvían las filas', () => {
		const ctx = quintilla(1, 25);
		expect(destinatariasSegunElFormulario(ctx)).toEqual(destinatariasSegunLasFilas(ctx));
	});

	it('y las mismas que `unitsForGroup`, que es quien escribe', () => {
		const ctx = quintilla(1, 25);
		const esperadas = unitsForGroup(ctx, quintillaGrupo)
			.map((unit) => unit.realizacion_id)
			.sort();
		const obtenidas = preguntasDelFormulario(ctx)[0]
			.destinatarias.map((destinataria) => destinataria.owner.realizacion_id)
			.sort();
		expect(obtenidas).toEqual(esperadas);
	});

	it('conserva el orden de verso, que es el de la lista de excepciones', () => {
		const preguntas = preguntasDelFormulario(quintilla(1, 25));
		expect(preguntas[0].destinatarias.map((destinataria) => destinataria.owner.v_ini)).toEqual([
			1, 6, 11, 16, 21
		]);
	});
});

describe('quintilla · una sola unidad', () => {
	/**
	 * **El caso que hacía ver la pantalla vieja.** `preguntasCompartidas` descarta las preguntas
	 * con menos de dos realizaciones, así que con un rango de cinco versos la quintilla caía
	 * entera en el renderizador antiguo. Aquí la pregunta existe igual: es de secuencia, porque
	 * no hay de qué apartarse.
	 */
	it('la pregunta existe y se lee como de secuencia', () => {
		const preguntas = preguntasDelFormulario(quintilla(1, 5));
		expect(preguntas).toHaveLength(1);
		expect(preguntas[0].rotulo).toBe('Esquema de rima');
		expect(preguntas[0].alcance).toBe('secuencia');
		expect(preguntas[0].destinatarias).toHaveLength(1);
	});

	it('y se le escribe a la misma realización que antes', () => {
		const ctx = quintilla(1, 5);
		expect(destinatariasSegunElFormulario(ctx)).toEqual(destinatariasSegunLasFilas(ctx));
	});
});

describe('una forma que no pregunta nada', () => {
	it('no produce ninguna pregunta, y no un hueco', () => {
		const ctx = contexto({
			units: syncRepeatedMetricUnits([], [], { minimum: 4, maximum: 4 }, 1, 40).units,
			unitPlan: { extent: { minimum: 4, maximum: 4 }, countFromRange: true },
			unitLabel: 'Redondilla'
		});
		expect(preguntasDelFormulario(ctx)).toEqual([]);
	});
});

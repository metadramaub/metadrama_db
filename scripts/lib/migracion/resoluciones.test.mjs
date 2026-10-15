import { describe, expect, it } from 'vitest';
import { corregirLaObra, desviacionesDe } from './aplicador.mjs';
import { incorporarRespuestasAdicionales, prepararResoluciones } from './resoluciones.mjs';

const metros = [{ metro_id: 'hepta', nombre: 'Heptasílabo', silabas: 7 }];
const origen = {
	caracterizacion_rango_id: 'nota',
	secuencia_id: 'secuencia',
	termino: 'hipometrico',
	v_ini: 2917,
	v_fin: 2917,
	observaciones: 'Verso heptasílabo'
};
const resolucion = {
	origen,
	excel: { respuesta: 'Es correcto' },
	destino: 'desviacion',
	silabas: 7,
	descripcion: null,
	motivo: 'Metro explícito en la nota original'
};
function resolver(nota = origen, decision = resolucion, respuesta = { respuesta: 'Es correcto' }) {
	const pendientes = [];
	const plan = desviacionesDe(
		[{ caracterizaciones: [nota] }],
		new Map([['D|nota', respuesta]]),
		metros,
		[],
		pendientes,
		decision ? { nota: decision } : {}
	);
	return { ...plan, pendientes };
}

describe('destino revisado de las notas históricas', () => {
	it('usa el selector de metro, sin repetir la nota, y conserva el origen en el rastro', () => {
		const plan = resolver();
		expect(plan.pendientes).toEqual([]);
		expect(plan.desviaciones[0]).toMatchObject({
			metro_observado_id: 'hepta',
			observaciones: null,
			relacion_norma: 'menor_que_norma'
		});
		expect(plan.traslados[0]).toMatchObject({ origen, retirar_caracterizacion: true });
	});

	it('no inventa un destino para una nota aún sin revisar', () => {
		const plan = resolver(origen, null);
		expect(plan.pendientes).toHaveLength(1);
		expect(plan.traslados).toEqual([]);
		expect(plan.desviaciones).toEqual([]);
	});

	it('rechaza la resolución si cambian el texto, el rango o la respuesta recibida', () => {
		expect(() => resolver({ ...origen, observaciones: 'Nota corregida' })).toThrow('Ha cambiado');
		expect(() => resolver({ ...origen, v_ini: 2916 })).toThrow('Ha cambiado');
		expect(() => resolver(origen, resolucion, { respuesta: 'No es así' })).toThrow('Ha cambiado');
	});

	it('retira una anomalía rectificada sin crear desviación ni comentario público', () => {
		const respuesta = { respuesta: 'No es así', comentario: 'Otra edición; el verso rima.' };
		const plan = resolver(
			origen,
			{
				origen,
				destino: 'rectificacion',
				excel: respuesta,
				motivo: respuesta.comentario
			},
			respuesta
		);
		expect(plan.desviaciones).toEqual([]);
		expect(plan.traslados[0].resolucion.excel.comentario).toBe(respuesta.comentario);
		expect(plan.traslados[0].retirar_caracterizacion).toBe(true);
	});

	it('una respuesta negativa sin resolución sigue pendiente', () => {
		const plan = resolver({ ...origen, observaciones: null }, null, { respuesta: 'No es así' });
		expect(plan.pendientes).toHaveLength(1);
		expect(plan.traslados).toEqual([]);
	});

	it('conserva el canto y lleva su dato de rima a una desviación', () => {
		const canto = {
			...origen,
			termino: 'cantado',
			v_ini: 1948,
			v_fin: 1948,
			observaciones: 'El verso acaba en veo, frente a la rima i-o.'
		};
		const plan = resolver(canto, {
			origen: canto,
			excel: resolucion.excel,
			destino: 'desviacion',
			conservar_caracterizacion: true,
			descripcion: canto.observaciones,
			desviacion: { dimension: 'rima', relacion_norma: 'otra' }
		});
		expect(plan.desviaciones[0]).toMatchObject({
			dimension: 'rima',
			observaciones: canto.observaciones
		});
		expect(plan.conservadas).toEqual([canto]);
		expect(plan.traslados[0]).toMatchObject({
			retirar_caracterizacion: false,
			limpiar_observaciones: true
		});
	});

	it('falla si el metro exacto revisado ya no está disponible', () => {
		expect(() => resolver(origen, { ...resolucion, silabas: 11 })).toThrow('No existe el metro');
	});
});

describe('respuestas complementarias del IP', () => {
	const fila = {
		clave: 'Q|secuencia|Organización en pareados',
		respuesta: 'Predominantes',
		origen: 'indicacion_ip',
		motivo: 'Pendiente de revisión por la editora'
	};
	it('conserva su procedencia y no modifica las respuestas del Excel', () => {
		const respuestas = new Map([['C|secuencia', { respuesta: 'Es correcto' }]]);
		incorporarRespuestasAdicionales(respuestas, [fila]);
		expect(respuestas.get(fila.clave)).toEqual(fila);
		expect(respuestas.get('C|secuencia')).toEqual({ respuesta: 'Es correcto' });
	});
	it('rechaza duplicados y complementos sin procedencia', () => {
		expect(() => incorporarRespuestasAdicionales(new Map([[fila.clave, fila]]), [fila])).toThrow(
			'sobrescribiría'
		);
		expect(() => incorporarRespuestasAdicionales(new Map(), [{ ...fila, origen: '' }])).toThrow(
			'origen'
		);
	});
});

describe('correcciones particulares antes de planificar', () => {
	it('corrige arquitectura y respuestas en una copia y conserva lo que escribió la editora', () => {
		const obra = {
			secuencias: [
				{
					secuencia_id: 's',
					v_ini: 1,
					respuestas: [{ grupo_eleccion_id: 'densidad', respuesta: 'Mayoritaria' }]
				}
			]
		};
		const respuestas = new Map([['C|s', { respuesta: 'No es así', comentario: 'Orden libre' }]]);
		const preparada = prepararResoluciones(
			obra,
			respuestas,
			{
				respuestas_revisadas: [
					{
						clave: 'C|s',
						esperado: { respuesta: 'No es así', comentario: 'Orden libre' },
						usar: { respuesta: 'Es correcto' },
						motivo: 'Revisión del IP'
					}
				],
				secuencias: {
					s: {
						origen: { v_ini: 1 },
						arquitectura_id: 'libre',
						arquitectura_nombre: 'Orden libre',
						elecciones: { densidad: 'Total' },
						motivo: 'Rima total confirmada'
					}
				}
			},
			new Map([['libre', {}]])
		);
		expect(obra.secuencias[0].respuestas).toHaveLength(1);
		expect(respuestas.get('C|s').respuesta).toBe('No es así');
		expect(preparada.obra.secuencias[0]).toMatchObject({
			arquitectura_propuesta_id: 'libre',
			respuestas: []
		});
		expect(preparada.respuestas.get('R|s|densidad').respuesta).toBe('Total');
		expect(preparada.respuestas.get('C|s').respuesta).toBe('Es correcto');
	});
	it('rechaza una respuesta que cambió después de revisarse', () => {
		expect(() =>
			prepararResoluciones(
				{ secuencias: [] },
				new Map([['C|s', { respuesta: 'Es correcto' }]]),
				{
					respuestas_revisadas: [
						{ clave: 'C|s', esperado: { respuesta: 'No es así' }, usar: {}, motivo: 'Revisión' }
					]
				},
				new Map()
			)
		).toThrow('Ha cambiado');
	});
	it('inserta los dos huecos al final de la quintilla sin mover los versos anteriores', () => {
		const obra = {
			secuencias: [
				{
					secuencia_id: 's',
					v_ini: 2202,
					v_fin: 2459,
					subtipos: [
						{ subtipo_secuencia_id: 'q', v_ini: 2277, v_fin: 2279 },
						{ subtipo_secuencia_id: 'q2', v_ini: 2280, v_fin: 2284 }
					],
					caracterizaciones: [{ caracterizacion_rango_id: 'laguna', v_ini: 2277, v_fin: 2279 }]
				},
				{ secuencia_id: 'posterior', v_ini: 2460, v_fin: 2761 }
			]
		};
		const corregida = corregirLaObra(obra, [
			{ tipo: 'renumerar', desde: 2280, faltan: 2 },
			{ tipo: 'subtipo', id: 'q', v_ini: 2277, v_fin: 2281 },
			{ tipo: 'caracterizacion', id: 'laguna', v_ini: 2280, v_fin: 2281 }
		]);
		expect(corregida.secuencias[0]).toMatchObject({ v_ini: 2202, v_fin: 2461, n_versos: 260 });
		expect(corregida.secuencias[0].subtipos).toEqual([
			{ subtipo_secuencia_id: 'q', v_ini: 2277, v_fin: 2281 },
			{ subtipo_secuencia_id: 'q2', v_ini: 2282, v_fin: 2286 }
		]);
		expect(corregida.secuencias[0].caracterizaciones[0]).toMatchObject({
			v_ini: 2280,
			v_fin: 2281
		});
		expect(corregida.secuencias[1]).toMatchObject({ v_ini: 2462, v_fin: 2763 });
		expect(obra.secuencias[0].v_fin).toBe(2459);
	});
	it('separa la laguna y la bibliografía, conserva su origen y usa el rango final en el comentario', () => {
		const antiguo = {
			...origen,
			termino: 'laguna',
			v_ini: 2277,
			v_fin: 2279,
			observaciones: 'Wardropper (p. 140) señala dos versos ausentes.'
		};
		const actual = { ...antiguo, v_ini: 2280, v_fin: 2281, origen_original: antiguo };
		const plan = resolver(actual, {
			origen: antiguo,
			excel: { respuesta: 'Es correcto' },
			destino: 'mixta',
			comentario_publico: { texto: antiguo.observaciones, v_ini: 2277, v_fin: 2281 }
		});
		expect(plan.desviaciones[0]).toMatchObject({
			dimension: 'estructura',
			relacion_norma: 'falta',
			v_ini: 2280,
			v_fin: 2281,
			observaciones: null
		});
		expect(plan.traslados[0].comentario.comentario).toBe(
			'**Vv. 2277–2281.**\n\n' + antiguo.observaciones
		);
		expect(plan.traslados[0].origen.origen_original).toEqual(antiguo);
	});
	it('traslada una nota de canto a comentario sin convertir el canto en desviación', () => {
		const nota = { ...origen, termino: 'cantado', v_ini: 2211, v_fin: 2211 };
		const plan = resolver(nota, {
			origen: nota,
			excel: { respuesta: 'Es correcto' },
			destino: 'comentario',
			comentario_publico: { texto: nota.observaciones }
		});
		expect(plan.desviaciones).toEqual([]);
		expect(plan.conservadas).toEqual([nota]);
		expect(plan.traslados[0]).toMatchObject({
			retirar_caracterizacion: false,
			limpiar_observaciones: true
		});
	});
});

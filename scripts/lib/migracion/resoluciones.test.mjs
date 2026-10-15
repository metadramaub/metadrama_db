import { describe, expect, it } from 'vitest';
import { desviacionesDe } from './aplicador.mjs';
import { incorporarRespuestasAdicionales } from './resoluciones.mjs';

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

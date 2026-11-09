import { describe, expect, it } from 'vitest';
import { numeracionPorJornada, aplicarNumeracion } from './numeracion.mjs';

const fila = (id, jornada, v_ini, v_fin) => ({ id, jornada, v_ini, v_fin });

describe('numeración por jornada', () => {
	it('reconoce la edición que vuelve a 1 en cada jornada y suma lo anterior', () => {
		const extraccion = { tramos: [fila('t1', 1, 1, 100), fila('t2', 1, 101, 120), fila('t3', 2, 1, 50), fila('t4', 3, 1, 30)], notas: [] };
		expect(numeracionPorJornada(extraccion)).toEqual([
			{ jornada: 1, desplazamiento: 0 },
			{ jornada: 2, desplazamiento: 120 },
			{ jornada: 3, desplazamiento: 170 }
		]);
	});
	it('no toca la numeración continua ni los casos dudosos', () => {
		expect(numeracionPorJornada({ tramos: [fila('t1', 1, 1, 100), fila('t2', 2, 101, 150)] })).toBeNull();
		expect(numeracionPorJornada({ tramos: [fila('t1', 1, 1, 100), fila('t2', null, 1, 50)] })).toBeNull();
		expect(numeracionPorJornada({ tramos: [fila('t1', 2, 1, 100), fila('t2', 1, 1, 50)] })).toBeNull();
		expect(numeracionPorJornada({ tramos: [fila('t1', 1, 1, 100), fila('t2', 2, 1, 50), fila('t3', 3, 51, 80)] })).toBeNull();
	});
	it('desplaza filas y notas en una copia, sin cambiar el original', () => {
		const extraccion = {
			tramos: [fila('t1', 1, 1, 100), fila('t2', 2, 1, 50), { id: 'p', jornada: 2, v_ini: null, v_fin: null }],
			notas: [{ id: 'n1', tramos_ref: ['t2'], v_ini: 10, v_fin: 12 }, { id: 'n2', tramos_ref: [], v_ini: 5, v_fin: 5 }]
		};
		const antes = JSON.stringify(extraccion);
		const copia = aplicarNumeracion(extraccion, numeracionPorJornada(extraccion));
		expect(copia.tramos.map((t) => [t.v_ini, t.v_fin])).toEqual([[1, 100], [101, 150], [null, null]]);
		expect(copia.notas.map((n) => [n.v_ini, n.v_fin])).toEqual([[110, 112], [5, 5]]);
		expect(JSON.stringify(extraccion)).toBe(antes);
	});
});

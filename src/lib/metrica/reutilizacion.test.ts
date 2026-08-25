import { describe, expect, it } from 'vitest';
import {
	gruposHeredadosPorReutilizacion,
	laParteTieneRimaPropia,
	seccionHeredaLaRima,
	unidadDeclaraSuRima
} from './reutilizacion';

/**
 * Un catálogo mínimo con los cuatro casos que la regla tiene que separar:
 *
 * - **oncena**: su unidad no dice nada y sus partes tampoco → hereda quintilla y sextilla.
 * - **copla castellana**: su unidad declara los ocho versos → no hereda, aunque reutilice.
 * - **copla real**: su unidad calla, pero cada parte tiene ya su pregunta → no hereda.
 * - **septeto compuesto**: su unidad solo tiene un patrón abierto y vacío → hereda.
 */
const secciones = [
	{ seccion_id: 'oncena-quintilla', arquitectura_id: 'oncena', arquitectura_referenciada_id: 'quintilla' },
	{ seccion_id: 'oncena-sextilla', arquitectura_id: 'oncena', arquitectura_referenciada_id: 'sextilla' },
	{ seccion_id: 'castellana-1', arquitectura_id: 'castellana', arquitectura_referenciada_id: 'redondilla' },
	{ seccion_id: 'castellana-2', arquitectura_id: 'castellana', arquitectura_referenciada_id: 'redondilla' },
	{ seccion_id: 'real-1', arquitectura_id: 'copla-real', arquitectura_referenciada_id: 'quintilla' },
	{ seccion_id: 'real-2', arquitectura_id: 'copla-real', arquitectura_referenciada_id: 'quintilla' },
	{ seccion_id: 'septeto-cuarteto', arquitectura_id: 'septeto', arquitectura_referenciada_id: 'cuarteto' },
	// Una parte que no reutiliza nada nunca hereda.
	{ seccion_id: 'suelta', arquitectura_id: 'oncena', arquitectura_referenciada_id: null }
];

const esquemas = [
	{ esquema_rima_id: 'q-ababa', arquitectura_id: 'quintilla', seccion_id: null },
	{ esquema_rima_id: 'q-abbab', arquitectura_id: 'quintilla', seccion_id: null },
	{ esquema_rima_id: 'sx-abcabc', arquitectura_id: 'sextilla', seccion_id: null },
	{ esquema_rima_id: 'r-abba', arquitectura_id: 'redondilla', seccion_id: null },
	{ esquema_rima_id: 'cast-abbacddc', arquitectura_id: 'castellana', seccion_id: null },
	{ esquema_rima_id: 'c-abba', arquitectura_id: 'cuarteto', seccion_id: null },
	// El patrón abierto del septeto: existe, no dice nada, y no debe bloquear el préstamo.
	{ esquema_rima_id: 'septeto-variable', arquitectura_id: 'septeto', seccion_id: null }
];

const posiciones = [
	{ esquema_rima_id: 'q-ababa' },
	{ esquema_rima_id: 'q-abbab' },
	{ esquema_rima_id: 'sx-abcabc' },
	{ esquema_rima_id: 'r-abba' },
	{ esquema_rima_id: 'cast-abbacddc' },
	{ esquema_rima_id: 'c-abba' }
];

const grupos = [
	{ grupo_eleccion_id: 'g-quintilla', arquitectura_id: 'quintilla', dimension: 'rima', seccion_id: null, seccion_tratada_id: null, activo: true, alcance: 'unidad', tipo_control: 'opciones' },
	{ grupo_eleccion_id: 'g-sextilla', arquitectura_id: 'sextilla', dimension: 'rima', seccion_id: null, seccion_tratada_id: null, activo: true, alcance: 'unidad', tipo_control: 'opciones_y_esquema' },
	{ grupo_eleccion_id: 'g-cuarteto', arquitectura_id: 'cuarteto', dimension: 'rima', seccion_id: null, seccion_tratada_id: null, activo: true, alcance: 'unidad', tipo_control: 'opciones' },
	// La copla real ya se copió las suyas a mano, apuntando a cada parte.
	{ grupo_eleccion_id: 'g-real-1', arquitectura_id: 'copla-real', dimension: 'rima', seccion_id: 'real-1', seccion_tratada_id: null, activo: true, alcance: 'unidad', tipo_control: 'opciones' },
	{ grupo_eleccion_id: 'g-real-2', arquitectura_id: 'copla-real', dimension: 'rima', seccion_id: 'real-2', seccion_tratada_id: null, activo: true, alcance: 'unidad', tipo_control: 'opciones' },
	// Una pregunta de medida de la quintilla no se hereda: esta regla es de rima.
	{ grupo_eleccion_id: 'g-quintilla-metro', arquitectura_id: 'quintilla', dimension: 'metro', seccion_id: null, seccion_tratada_id: null, activo: true, alcance: 'unidad', tipo_control: 'opciones' },
	// Ni una desactivada.
	{ grupo_eleccion_id: 'g-sextilla-vieja', arquitectura_id: 'sextilla', dimension: 'rima', seccion_id: null, seccion_tratada_id: null, activo: false, alcance: 'unidad', tipo_control: 'opciones' }
];

const catalogo = { secciones, esquemas, posiciones, grupos };

describe('la rima que una parte hereda de la arquitectura que reutiliza', () => {
	it('sabe cuándo la unidad ya declara su rima entera', () => {
		expect(unidadDeclaraSuRima('castellana', esquemas, posiciones)).toBe(true);
		expect(unidadDeclaraSuRima('copla-real', esquemas, posiciones)).toBe(false);
		// Un patrón abierto y vacío no declara nada, aunque exista.
		expect(unidadDeclaraSuRima('septeto', esquemas, posiciones)).toBe(false);
	});

	it('sabe cuándo la parte tiene ya rima suya', () => {
		expect(laParteTieneRimaPropia(secciones[4], esquemas, grupos)).toBe(true);
		expect(laParteTieneRimaPropia(secciones[0], esquemas, grupos)).toBe(false);
	});

	it('presta donde la unidad calla y la parte no tiene nada', () => {
		expect(seccionHeredaLaRima(secciones[0], catalogo)).toBe(true);
		expect(seccionHeredaLaRima(secciones[1], catalogo)).toBe(true);
		expect(seccionHeredaLaRima(secciones[6], catalogo)).toBe(true);
	});

	it('no presta a la copla castellana, cuya unidad declara los ocho versos', () => {
		expect(seccionHeredaLaRima(secciones[2], catalogo)).toBe(false);
		expect(seccionHeredaLaRima(secciones[3], catalogo)).toBe(false);
	});

	it('no presta a la copla real, cuyas partes ya tienen su pregunta', () => {
		expect(seccionHeredaLaRima(secciones[4], catalogo)).toBe(false);
		expect(seccionHeredaLaRima(secciones[5], catalogo)).toBe(false);
	});

	it('no presta a una parte que no reutiliza nada', () => {
		expect(seccionHeredaLaRima(secciones[7], catalogo)).toBe(false);
	});

	describe('las preguntas que salen de ahí', () => {
		it('trae la de cada parte, apuntada a la parte que la toma prestada', () => {
			const heredados = gruposHeredadosPorReutilizacion('oncena', catalogo);
			expect(heredados).toHaveLength(2);
			expect(heredados.map((grupo) => grupo.seccion_id)).toEqual([
				'oncena-quintilla',
				'oncena-sextilla'
			]);
			// La respuesta se guarda contra el grupo original, que es el que existe en la base.
			expect(heredados.map((grupo) => grupo.grupo_eleccion_id)).toEqual([
				'g-quintilla',
				'g-sextilla'
			]);
			// Y con la misma forma que tienen las copias a mano de la copla real.
			expect(heredados[0]).toMatchObject({
				arquitectura_id: 'oncena',
				alcance: 'unidad',
				tipo_control: 'opciones',
				heredado_de: 'quintilla'
			});
		});

		it('no trae preguntas de otra dimensión ni desactivadas', () => {
			const heredados = gruposHeredadosPorReutilizacion('oncena', catalogo);
			expect(heredados.some((grupo) => grupo.dimension !== 'rima')).toBe(false);
			expect(heredados.some((grupo) => grupo.grupo_eleccion_id === 'g-sextilla-vieja')).toBe(
				false
			);
		});

		it('no trae nada donde no se presta', () => {
			expect(gruposHeredadosPorReutilizacion('castellana', catalogo)).toEqual([]);
			expect(gruposHeredadosPorReutilizacion('copla-real', catalogo)).toEqual([]);
		});
	});
});

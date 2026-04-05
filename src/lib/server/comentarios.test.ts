import { describe, expect, it } from 'vitest';
import {
	buildComentarioContextLabel,
	formatComentarioTipoLabel,
	type ComentarioContextMaps
} from './comentarios';

function createMaps(): ComentarioContextMaps {
	return {
		secuenciaById: new Map(),
		jornadaById: new Map([
			[
				'j1',
				{
					jornada_id: 'j1',
					jornada_num: 2,
					v_ini: 101,
					v_fin: 220
				}
			]
		]),
		cuadroById: new Map([
			[
				'c1',
				{
					cuadro_id: 'c1',
					cuadro_num: 1,
					jornada_id: 'j1',
					v_ini: 121,
					v_fin: 180
				}
			],
			[
				'c2',
				{
					cuadro_id: 'c2',
					cuadro_num: 3,
					jornada_id: 'j-missing',
					v_ini: 221,
					v_fin: 280
				}
			]
		])
	};
}

describe('buildComentarioContextLabel', () => {
	it('formats cuadro comments with jornada and cuadro when both are available', () => {
		expect(
			buildComentarioContextLabel(
				{ seccion: null, secuencia_id: null, jornada_id: null, cuadro_id: 'c1' },
				createMaps()
			)
		).toBe('Jornada 2 · Cuadro 1 (vv. 121-180)');
	});

	it('falls back to cuadro-only label when the jornada cannot be resolved', () => {
		expect(
			buildComentarioContextLabel(
				{ seccion: null, secuencia_id: null, jornada_id: null, cuadro_id: 'c2' },
				createMaps()
			)
		).toBe('Cuadro 3 (vv. 221-280)');
	});
});

describe('formatComentarioTipoLabel', () => {
	it('maps internal comment terms to dashboard-friendly labels', () => {
		expect(formatComentarioTipoLabel('general')).toBe('general');
		expect(formatComentarioTipoLabel('revision')).toBe('solicita revision');
		expect(formatComentarioTipoLabel('tecnico')).toBe('soporte tecnico');
		expect(formatComentarioTipoLabel('estado')).toBe('cambio de estado');
	});
});

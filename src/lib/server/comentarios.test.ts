import { describe, expect, it } from 'vitest';
import {
	buildComentarioContextLabel,
	buildComentarioSecuenciaEstrofaTerm,
	formatComentarioTipoLabel,
	type ComentarioContextMaps
} from './comentarios';

function createMaps(): ComentarioContextMaps {
	return {
		secuenciaById: new Map([
			[
				's1',
				{
					secuencia_id: 's1',
					v_ini: 2028,
					v_fin: 2189,
					estrofa_tipo_id: 'e1'
				}
			]
		]),
		secuenciaEstrofaTermById: new Map([['s1', 'Silva de consonantes regular']]),
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
	it('formats secuencia comments with verse range', () => {
		expect(
			buildComentarioContextLabel(
				{ seccion: null, secuencia_id: 's1', jornada_id: null, cuadro_id: null },
				createMaps()
			)
		).toBe('Secuencia vv. 2028-2189');
	});

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

describe('buildComentarioSecuenciaEstrofaTerm', () => {
	it('returns the estrofa term when the comment is tied to a known sequence', () => {
		expect(buildComentarioSecuenciaEstrofaTerm({ secuencia_id: 's1' }, createMaps())).toBe(
			'Silva de consonantes regular'
		);
	});

	it('returns null when there is no linked sequence', () => {
		expect(buildComentarioSecuenciaEstrofaTerm({ secuencia_id: null }, createMaps())).toBeNull();
		expect(buildComentarioSecuenciaEstrofaTerm({ secuencia_id: 'missing' }, createMaps())).toBeNull();
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

import { describe, expect, it } from 'vitest';
import {
	normalizeTipoVariacionTerm,
	validateSecuenciaVariacionContext
} from './secuencias-variaciones';

const secuencia = { v_ini: 10, v_fin: 40 };

describe('secuencias-variaciones', () => {
	it('normaliza terminos legacy de irregular', () => {
		expect(normalizeTipoVariacionTerm('irregular/hipometrico')).toBe('hipometrico');
		expect(normalizeTipoVariacionTerm('irregular/hipermetrico')).toBe('hipermetrico');
	});

	it('rechaza rango fuera de secuencia', () => {
		const error = validateSecuenciaVariacionContext({
			secuencia,
			tipoTerm: 'cantado',
			payload: { v_ini: 9, v_fin: 11 }
		});
		expect(error).toContain('dentro de la secuencia');
	});

	it('exige intervalo estricto para prosa', () => {
		const error = validateSecuenciaVariacionContext({
			secuencia,
			tipoTerm: 'prosa',
			payload: { v_ini: 20, v_fin: 20 }
		});
		expect(error).toContain('v_ini debe ser menor');
	});

	it('exige verso unico para hipometrico e hipermetrico', () => {
		const hipo = validateSecuenciaVariacionContext({
			secuencia,
			tipoTerm: 'hipometrico',
			payload: { v_ini: 20, v_fin: 21 }
		});
		const hiper = validateSecuenciaVariacionContext({
			secuencia,
			tipoTerm: 'hipermetrico',
			payload: { v_ini: 30, v_fin: 31 }
		});
		expect(hipo).toContain('deben ser iguales');
		expect(hiper).toContain('deben ser iguales');
	});

	it('permite igualdad para cantado, rima_defectuosa y laguna', () => {
		for (const term of ['cantado', 'rima_defectuosa', 'laguna']) {
			const error = validateSecuenciaVariacionContext({
				secuencia,
				tipoTerm: term,
				payload: { v_ini: 25, v_fin: 25 }
			});
			expect(error).toBeNull();
		}
	});

	it('rechaza tipo padre irregular', () => {
		const error = validateSecuenciaVariacionContext({
			secuencia,
			tipoTerm: 'irregular',
			payload: { v_ini: 25, v_fin: 25 }
		});
		expect(error).toContain('solo agrupador');
	});
});

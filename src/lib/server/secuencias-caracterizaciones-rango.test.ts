import { describe, expect, it } from 'vitest';
import {
	normalizeCaracterizacionRangoTerm,
	validateSecuenciaCaracterizacionRangoContext
} from './secuencias-caracterizaciones-rango';

const secuencia = { v_ini: 10, v_fin: 40 };

describe('secuencias-caracterizaciones-rango', () => {
	it('normaliza terminos legacy de irregularidades metricas', () => {
		expect(normalizeCaracterizacionRangoTerm('irregularidades_metricas/hipometrico')).toBe(
			'hipometrico'
		);
		expect(normalizeCaracterizacionRangoTerm('irregularidades_metricas/hipermetrico')).toBe(
			'hipermetrico'
		);
	});

	it('rechaza rango fuera de secuencia', () => {
		const error = validateSecuenciaCaracterizacionRangoContext({
			secuencia,
			tipo: { termino: 'cantado', termino_padre_id: 'parent-1' },
			payload: { v_ini: 9, v_fin: 11 }
		});
		expect(error).toContain('dentro de la secuencia');
	});

	it('exige intervalo estricto para prosa', () => {
		const error = validateSecuenciaCaracterizacionRangoContext({
			secuencia,
			tipo: { termino: 'prosa', termino_padre_id: 'parent-1' },
			payload: { v_ini: 20, v_fin: 20 }
		});
		expect(error).toContain('v_ini debe ser menor');
	});

	it('exige verso unico para hipometrico e hipermetrico', () => {
		const hipo = validateSecuenciaCaracterizacionRangoContext({
			secuencia,
			tipo: { termino: 'hipometrico', termino_padre_id: 'parent-1' },
			payload: { v_ini: 20, v_fin: 21 }
		});
		const hiper = validateSecuenciaCaracterizacionRangoContext({
			secuencia,
			tipo: { termino: 'hipermetrico', termino_padre_id: 'parent-1' },
			payload: { v_ini: 30, v_fin: 31 }
		});
		expect(hipo).toContain('deben ser iguales');
		expect(hiper).toContain('deben ser iguales');
	});

	it('permite igualdad para cantado, rima_defectuosa y laguna', () => {
		for (const term of ['cantado', 'rima_defectuosa', 'laguna', 'mayoria_agudas', 'mayoria_esdrujulas']) {
			const error = validateSecuenciaCaracterizacionRangoContext({
				secuencia,
				tipo: { termino: term, termino_padre_id: 'parent-1' },
				payload: { v_ini: 25, v_fin: 25 }
			});
			expect(error).toBeNull();
		}
	});

	it('rechaza terminos padre', () => {
		const error = validateSecuenciaCaracterizacionRangoContext({
			secuencia,
			tipo: { termino: 'irregularidades_metricas', termino_padre_id: null },
			payload: { v_ini: 25, v_fin: 25 }
		});
		expect(error).toContain('solo agrupador');
	});
});

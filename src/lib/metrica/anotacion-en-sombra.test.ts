import { describe, expect, it } from 'vitest';
import { shadowAgreement, type ShadowSequence } from './anotacion-en-sombra';

function sequence(overrides: Partial<ShadowSequence> = {}): ShadowSequence {
	return {
		secuenciaId: 'sec-1',
		obraId: 'obra-1',
		vIni: 1,
		vFin: 8,
		versos: 8,
		terminoLegado: 'redondilla',
		estrofaTipoId: 'termino-1',
		formaPropuestaId: 'forma-1',
		formaPropuesta: 'Redondilla',
		arquitecturaPropuestaId: 'arq-1',
		arquitecturaPropuesta: 'abba',
		subtipos: 0,
		caracterizaciones: 0,
		pruebaId: null,
		formaAnotadaId: null,
		arquitecturaAnotadaId: null,
		...overrides
	};
}

describe('shadowAgreement', () => {
	it('una secuencia sin anotar con propuesta está pendiente', () => {
		expect(shadowAgreement(sequence())).toBe('pendiente');
	});

	it('coincide cuando el editor confirma la forma propuesta', () => {
		expect(
			shadowAgreement(sequence({ pruebaId: 'prueba-1', formaAnotadaId: 'forma-1' }))
		).toBe('coincide');
	});

	it('difiere cuando el editor elige otra forma', () => {
		expect(
			shadowAgreement(sequence({ pruebaId: 'prueba-1', formaAnotadaId: 'forma-2' }))
		).toBe('difiere');
	});

	/**
	 * Que el término legado no tenga correspondencia no es un desacuerdo entre modelos: es una
	 * pieza que falta en el catálogo. Contarlo como «difiere» inflaría el desacuerdo y haría
	 * que la fase pareciera ir peor de lo que va.
	 */
	it('sin correspondencia no cuenta como desacuerdo, esté anotada o no', () => {
		expect(shadowAgreement(sequence({ formaPropuestaId: null }))).toBe('sin_propuesta');
		expect(
			shadowAgreement(
				sequence({ formaPropuestaId: null, pruebaId: 'prueba-1', formaAnotadaId: 'forma-9' })
			)
		).toBe('sin_propuesta');
	});
});

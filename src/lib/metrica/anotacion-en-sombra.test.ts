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
		via: 'directa',
		detalle: null,
		heredadoDe: null,
		respuestas: [],
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
		expect(shadowAgreement(sequence({ formaPropuestaId: null, via: 'sin_destino' }))).toBe(
			'sin_propuesta'
		);
		expect(
			shadowAgreement(
				sequence({
					formaPropuestaId: null,
					via: 'sin_tipo',
					pruebaId: 'prueba-1',
					formaAnotadaId: 'forma-9'
				})
			)
		).toBe('sin_propuesta');
	});

	/**
	 * Una propuesta heredada acierta la forma pero no las respuestas. Para el recuento sigue
	 * siendo un acuerdo —la forma es la misma—, y lo que avisa de su menor precisión es la vía,
	 * que viaja aparte y se enseña en la tabla.
	 */
	it('una propuesta heredada que se confirma cuenta como coincidencia', () => {
		expect(
			shadowAgreement(
				sequence({ via: 'ascendencia', heredadoDe: 'endecasilabo_suelto', pruebaId: 'p', formaAnotadaId: 'forma-1' })
			)
		).toBe('coincide');
	});
});

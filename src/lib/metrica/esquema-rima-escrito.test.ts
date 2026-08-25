import { describe, expect, it } from 'vitest';
import { leerEsquemaEscrito, type EsquemaCatalogado } from './esquema-rima-escrito';

const catalogo: EsquemaCatalogado[] = [
	{ esquemaRimaId: 'redondilla-abba', notacion: 'abba', regimen: 'consonante' },
	{ esquemaRimaId: 'redondilla-abab', notacion: 'abab', regimen: 'consonante' },
	{ esquemaRimaId: 'castellana-abba-cddc', notacion: 'abba|cddc', regimen: 'consonante' },
	{ esquemaRimaId: 'aguda-consonante', notacion: '---a---a', regimen: 'consonante' },
	{ esquemaRimaId: 'aguda-asonante', notacion: '---a---a', regimen: 'asonante' },
	{ esquemaRimaId: 'romance-pares', notacion: '[-a]…', regimen: 'asonante' }
];

describe('el esquema de rima que el editor escribe', () => {
	it('no dice nada de un campo vacío', () => {
		expect(leerEsquemaEscrito('')).toEqual({ estado: 'vacio' });
		expect(leerEsquemaEscrito('   ')).toEqual({ estado: 'vacio' });
		expect(leerEsquemaEscrito(null)).toEqual({ estado: 'vacio' });
	});

	it('mide la unidad y rechaza lo que no encaja en ella', () => {
		const corto = leerEsquemaEscrito('abba', { versos: 6 });
		expect(corto).toMatchObject({ estado: 'error' });
		expect(corto).toHaveProperty('mensaje', expect.stringContaining('6 versos'));

		expect(leerEsquemaEscrito('aabccb', { versos: 6 })).toMatchObject({
			estado: 'ok',
			posiciones: 6,
			clases: 3
		});
	});

	it('rechaza lo que no es una letra ni un guion', () => {
		expect(leerEsquemaEscrito('ab7a')).toMatchObject({ estado: 'error' });
	});

	/**
	 * Un ciclo describe una serie, que no tiene unidad. Por la regla 1 del § 3.3 esas no preguntan
	 * esquema, así que si aparece aquí es que se ha escrito lo que no se pedía.
	 */
	it('rechaza la notación de un ciclo, que es de una serie y no de una unidad', () => {
		expect(leerEsquemaEscrito('[-a]…', { versos: 2 })).toMatchObject({ estado: 'error' });
	});

	it('ignora los separadores de la articulación, que ya dicen las secciones', () => {
		const conBarra = leerEsquemaEscrito('abba|cddc', { versos: 8 });
		const sinBarra = leerEsquemaEscrito('abbacddc', { versos: 8 });
		expect(conBarra).toMatchObject({ estado: 'ok', canonica: 'abbacddc' });
		expect(sinBarra).toMatchObject({ estado: 'ok', canonica: 'abbacddc' });
	});

	it('renombra las clases en orden de primera aparición', () => {
		// La misma disposición escrita con otras letras no es otra disposición.
		expect(leerEsquemaEscrito('baab', { versos: 4 })).toMatchObject({ canonica: 'abba' });
		expect(leerEsquemaEscrito('cddc', { versos: 4 })).toMatchObject({ canonica: 'abba' });
	});

	/**
	 * La caja marca el arte del verso, no una clase distinta: la lira `aBabB` rima su cuarto verso
	 * con el segundo y el quinto. Si la caja separase clases, esto contaría tres y no dos.
	 */
	it('cuenta las clases sin distinguir caja, y conserva la caja de cada verso', () => {
		const lira = leerEsquemaEscrito('aBabB', { versos: 5 });
		expect(lira).toMatchObject({ estado: 'ok', clases: 2, canonica: 'aBabB' });
	});

	it('cuenta los versos sueltos y admite una unidad entera sin rima', () => {
		expect(leerEsquemaEscrito('a-a', { versos: 3 })).toMatchObject({ clases: 1, sueltos: 1 });
		expect(leerEsquemaEscrito('------', { versos: 6 })).toMatchObject({
			estado: 'ok',
			clases: 0,
			sueltos: 6
		});
	});

	describe('casarlo con el catálogo', () => {
		it('reconoce el esquema catalogado aunque se escriba con otras letras o con separadores', () => {
			expect(
				leerEsquemaEscrito('cddc', { versos: 4, regimen: 'consonante', catalogados: catalogo })
			).toMatchObject({ esquemaCatalogadoId: 'redondilla-abba' });
			expect(
				leerEsquemaEscrito('abba cddc', {
					versos: 8,
					regimen: 'consonante',
					catalogados: catalogo
				})
			).toMatchObject({ esquemaCatalogadoId: 'castellana-abba-cddc' });
		});

		it('no reconoce nada cuando la disposición no está', () => {
			expect(
				leerEsquemaEscrito('aabb', { versos: 4, regimen: 'consonante', catalogados: catalogo })
			).toMatchObject({ estado: 'ok', esquemaCatalogadoId: null });
		});

		/**
		 * Regla 3 bis. La octava aguda tiene dos esquemas con la misma notación `---a---a` que solo
		 * se distinguen en el régimen. Casar por notación sola los colapsaría.
		 */
		it('distingue dos esquemas de la misma notación por su régimen', () => {
			expect(
				leerEsquemaEscrito('---a---a', {
					versos: 8,
					regimen: 'consonante',
					catalogados: catalogo
				})
			).toMatchObject({ esquemaCatalogadoId: 'aguda-consonante' });
			expect(
				leerEsquemaEscrito('---a---a', { versos: 8, regimen: 'asonante', catalogados: catalogo })
			).toMatchObject({ esquemaCatalogadoId: 'aguda-asonante' });
		});

		it('nunca casa con el esquema de un ciclo', () => {
			expect(
				leerEsquemaEscrito('-a', { versos: 2, regimen: 'asonante', catalogados: catalogo })
			).toMatchObject({ esquemaCatalogadoId: null });
		});
	});

	describe('lo que rompe la norma', () => {
		it('avisa sin bloquear, porque una desviación se registra y no se prohíbe', () => {
			const quintilla = leerEsquemaEscrito('abbba', {
				versos: 5,
				restricciones: [
					{ tipo: 'numero_clases', valorNumero: 2, valorTexto: null },
					{ tipo: 'max_consecutivos', valorNumero: 2, valorTexto: null },
					{ tipo: 'versos_sueltos', valorNumero: null, valorTexto: 'ninguno' }
				]
			});
			expect(quintilla).toMatchObject({ estado: 'ok', canonica: 'abbba' });
			expect(quintilla).toHaveProperty(
				'avisos',
				expect.arrayContaining([expect.stringContaining('no admite más de 2 versos seguidos')])
			);
		});

		it('no avisa de lo que la norma sí admite', () => {
			const quintilla = leerEsquemaEscrito('ababa', {
				versos: 5,
				restricciones: [
					{ tipo: 'numero_clases', valorNumero: 2, valorTexto: null },
					{ tipo: 'max_consecutivos', valorNumero: 2, valorTexto: null },
					{ tipo: 'versos_sueltos', valorNumero: null, valorTexto: 'ninguno' }
				]
			});
			expect(quintilla).toMatchObject({ estado: 'ok', avisos: [] });
		});

		it('avisa del verso suelto donde la norma no lo admite', () => {
			const sextilla = leerEsquemaEscrito('-abcbc', {
				versos: 6,
				restricciones: [{ tipo: 'versos_sueltos', valorNumero: null, valorTexto: 'ninguno' }]
			});
			expect(sextilla).toHaveProperty(
				'avisos',
				expect.arrayContaining([expect.stringContaining('no admite versos sueltos')])
			);
		});
	});
});

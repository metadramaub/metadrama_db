import { describe, it, expect } from 'vitest';
import { pareadosEnDenominacion, cierreConExcepciones } from './pareados-declarados.mjs';

describe('pareados declarados sin reconstruir la fuente', () => {
	it.each([
		['endecasílabos sueltos (con pareado en vv. 786-787)', 689, 787, true],
		[
			'endecasílabos sueltos (con pareados en vv. 2150-2151, 2159-2160 y 2182-2183)',
			2053,
			2183,
			true
		],
		['endecasílabos sueltos (con pareado en vv. 2150-2151)', 2053, 2183, false]
	])('localiza %s', (literal, v_ini, v_fin, final) => {
		expect(pareadosEnDenominacion(literal, { v_ini, v_fin })).toMatchObject({
			disticoFinal: final,
			aviso: null
		});
	});
	it.each(['1974-1075', '1073-1075', '1074-1076', '1074-1075 o quizá otros'])(
		'conserva una posición contradictoria %s sin asignar cierre',
		(rango) => {
			const result = pareadosEnDenominacion(`endecasílabos sueltos (con pareado en vv. ${rango})`, {
				v_ini: 1020,
				v_fin: 1075
			});
			expect(result).toMatchObject({ disticoFinal: false, aviso: expect.any(String) });
		}
	);
	it('no aplica el patrón a otra forma ni a una simple mención', () => {
		expect(
			pareadosEnDenominacion('octavas (con pareado en vv. 786-787)', { v_ini: 689, v_fin: 787 })
		).toBeNull();
	});
	const filas = new Map([
		[
			't04',
			{
				id: 't04',
				notas_ref: ['n01'],
				v_ini: 1955,
				v_fin: 2087,
				denominacion_literal: 'endecasílabos sueltos'
			}
		],
		[
			't05',
			{
				id: 't05',
				notas_ref: ['n01'],
				v_ini: 3335,
				v_fin: 3405,
				denominacion_literal: 'endecasílabos sueltos'
			}
		],
		[
			't01',
			{
				id: 't01',
				notas_ref: ['n01'],
				v_ini: 513,
				v_fin: 542,
				denominacion_literal: 'endecasílabos sueltos'
			}
		],
		[
			't02',
			{
				id: 't02',
				notas_ref: ['n01'],
				v_ini: 1004,
				v_fin: 1104,
				denominacion_literal: 'endecasílabos sueltos'
			}
		],
		[
			't03',
			{
				id: 't03',
				notas_ref: ['n01'],
				v_ini: 2944,
				v_fin: 2993,
				denominacion_literal: 'endecasílabos sueltos'
			}
		]
	]);
	const nota = {
		id: 'n01',
		texto_literal:
			'Los dos últimos versos constituyen un pareado, forma con la que remata otras dos de las cinco series de versos sueltos. Aquellas que no adoptan esta conclusión son las de los vv. 513-542 y 2944-2993.',
		tramos_ref: [...filas.keys()]
	};
	it('respeta las excepciones localizadas y no inventa un valor ausente', () => {
		expect(
			[...filas.values()].map((f) =>
				cierreConExcepciones(nota, f, filas, ['endecasílabos sueltos'])
			)
		).toEqual([true, true, false, true, false]);
	});
	it('no propaga el cierre si las excepciones no pueden localizarse en las filas enlazadas', () => {
		expect(
			cierreConExcepciones({ ...nota, tramos_ref: ['t01', 't02'] }, filas.get('t02'), filas, [
				'endecasílabos sueltos'
			])
		).toBeNull();
	});
	it('no interpreta como afirmación una nota recortada', () => {
		expect(
			cierreConExcepciones(
				{ ...nota, texto_literal: nota.texto_literal.replace('2944-2993.', '[ilegible]') },
				filas.get('t02'),
				filas,
				['endecasílabos sueltos']
			)
		).toBeNull();
	});
});

import { describe, expect, it } from 'vitest';
import {
	generarArtefactoDemarcador,
	PoliticasDemarcadorPendientesError,
	type EstrofaFuenteDemarcador,
	type OpcionFuenteDemarcador
} from './generar';
import {
	construirPreguntas,
	crearRespuestaNueva,
	elegirSiguientePreguntaNueva,
	filtrarCandidatosNuevos
} from './motor';
import type { CandidatoDemarcadorNuevo } from './modelo';

const opciones: OpcionFuenteDemarcador[] = [
	{
		termino_id: 'octosilabo',
		termino: 'octosilabo',
		etiqueta: 'Octosílabo',
		numero_silabas: 8
	},
	{
		termino_id: 'endecasilabo',
		termino: 'endecasilabo',
		etiqueta: 'Endecasílabo',
		numero_silabas: 11
	},
	{
		termino_id: 'consonante',
		termino: 'consonante',
		etiqueta: 'Consonante',
		numero_silabas: null
	}
];

function estrofa(
	id: string,
	parentId: string | null,
	overrides: Partial<EstrofaFuenteDemarcador> = {}
): EstrofaFuenteDemarcador {
	return {
		termino_id: id,
		termino: id,
		etiqueta: null,
		definicion: null,
		termino_padre_id: parentId,
		orden: null,
		tipo_rima_id: null,
		naturaleza_estrofica_id: null,
		tamanio_unidad_estrofica: null,
		patron_especifico: null,
		updated_at: '2026-07-28T10:00:00Z',
		...overrides
	};
}

function candidato(
	id: string,
	metros: number[],
	overrides: Partial<CandidatoDemarcadorNuevo['rasgos']> = {}
): CandidatoDemarcadorNuevo {
	return {
		id,
		slug: id,
		etiqueta: id,
		definicion: null,
		familiaId: id,
		familiaSlug: id,
		familiaEtiqueta: id,
		esFamilia: true,
		rasgos: {
			metros: metros.map((metro) => ({ clave: String(metro), etiqueta: `${metro} sílabas` })),
			rima: null,
			naturaleza: null,
			tamanio: null,
			patron: null,
			...overrides
		}
	};
}

describe('generarArtefactoDemarcador', () => {
	it('exige una política para cada familia activa que tiene hijos', () => {
		expect(() =>
			generarArtefactoDemarcador({
				estrofas: [estrofa('familia', null), estrofa('hija', 'familia')],
				opciones,
				relacionesMetro: [],
				politicas: []
			})
		).toThrow(PoliticasDemarcadorPendientesError);
	});

	it('conserva la jerarquía y aplica la política revisada', () => {
		const artefacto = generarArtefactoDemarcador({
			estrofas: [
				estrofa('familia', null, { tipo_rima_id: 'consonante' }),
				estrofa('a', 'familia', { patron_especifico: 'abaab' }),
				estrofa('b', 'familia', { patron_especifico: 'ababa' })
			],
			opciones,
			relacionesMetro: [{ estrofa_tipo_id: 'familia', metro_id: 'octosilabo' }],
			politicas: [
				{
					familia_id: 'familia',
					politica: 'variantes',
					updated_at: '2026-07-28T11:00:00Z'
				}
			],
			generadoEn: '2026-07-28T12:00:00Z'
		});

		expect(artefacto.familias[0]).toMatchObject({
			politica: 'variantes',
			variantes: [
				{ slug: 'a', rasgos: { patron: 'abaab' } },
				{ slug: 'b', rasgos: { patron: 'ababa' } }
			]
		});
		expect(artefacto.familias[0].variantes[0].rasgos).toMatchObject({
			metros: [{ clave: '8', etiqueta: '8 sílabas' }],
			rima: { clave: 'consonante', etiqueta: 'Consonante' }
		});
	});

	it('no hereda tamaño ni patrón desde la familia', () => {
		const artefacto = generarArtefactoDemarcador({
			estrofas: [
				estrofa('familia', null, {
					tamanio_unidad_estrofica: 5,
					patron_especifico: 'abaab'
				}),
				estrofa('hija', 'familia')
			],
			opciones,
			relacionesMetro: [],
			politicas: [
				{
					familia_id: 'familia',
					politica: 'variantes',
					updated_at: '2026-07-28T11:00:00Z'
				}
			]
		});

		expect(artefacto.familias[0].variantes[0].rasgos).toMatchObject({
			tamanio: null,
			patron: null
		});
	});
});

describe('motor nuevo del demarcador', () => {
	it('elige preguntas por utilidad y no pregunta patrones entre familias', () => {
		const candidatos = [
			candidato('octosilaba', [8], { tamanio: 4, patron: 'abba' }),
			candidato('endecasilaba', [11], { tamanio: 4, patron: 'abab' }),
			candidato('mixta', [7, 11], { tamanio: 5, patron: 'aBabB' })
		];

		const preguntas = construirPreguntas(candidatos, 'familias');
		expect(preguntas.length).toBeGreaterThan(0);
		expect(preguntas.every((pregunta) => pregunta.rasgo !== 'patron')).toBe(true);
		expect(elegirSiguientePreguntaNueva(candidatos, 'familias')?.rasgo).toBe('metros');
	});

	it('permite usar el patrón al distinguir variantes', () => {
		const candidatos = [
			candidato('a', [8], { tamanio: 5, patron: 'abaab' }),
			candidato('b', [8], { tamanio: 5, patron: 'ababa' })
		];

		expect(elegirSiguientePreguntaNueva(candidatos, 'variantes')?.rasgo).toBe('patron');
	});

	it('distingue configuraciones por el orden de sus partes antes que por la rima', () => {
		const candidatos = [
			candidato('novena-canonica', [8], {
				tamanio: 9,
				estructura: 'redondilla+quintilla',
				estructuraEtiqueta: 'Redondilla + Quintilla'
			}),
			candidato('novena-invertida', [8], {
				tamanio: 9,
				estructura: 'quintilla+redondilla',
				estructuraEtiqueta: 'Quintilla + Redondilla'
			})
		];

		const pregunta = elegirSiguientePreguntaNueva(candidatos, 'variantes');
		expect(pregunta?.rasgo).toBe('estructura');
		expect(pregunta?.pregunta).toBe('¿Cómo se ordenan las partes de la forma?');
	});

	it('usa una repetición formalizada para distinguir formas sin patrón de rima', () => {
		const sextina = candidato('sextina', [11], {
			tamanio: 39,
			repeticion: 'permutacion-seis-palabras',
			repeticionEtiqueta: 'Seis palabras finales permutadas'
		});
		const otra = candidato('otra-forma', [11], {
			tamanio: 39,
			repeticion: 'sin-repeticion',
			repeticionEtiqueta: 'Sin repetición estructural'
		});

		const pregunta = construirPreguntas([sextina, otra], 'familias').find(
			(item) => item.rasgo === 'repeticion'
		);

		expect(pregunta).toMatchObject({
			rasgo: 'repeticion',
			tipo: 'opciones',
			pregunta: '¿Cómo se organiza la repetición?'
		});
		expect(pregunta?.opciones).toContainEqual({
			valor: 'permutacion-seis-palabras',
			etiqueta: 'Seis palabras finales permutadas'
		});
	});

	it('permite comparar patrones en la prueba compilada desde el catálogo', () => {
		const candidatos = [
			candidato('quintilla-ababa', [8], { tamanio: 5, patron: 'ababa' }),
			candidato('quintilla-abbab', [8], { tamanio: 5, patron: 'abbab' })
		];

		expect(
			elegirSiguientePreguntaNueva(candidatos, 'familias', [], {
				incluirPatronEnFamilias: true
			})?.rasgo
		).toBe('patron');
	});

	it('compara la firma estructural y usa el esquema solo como etiqueta', () => {
		const romance = candidato('romance', [8], {
			patron: '{"comportamiento":"secuencia_repetible","posiciones":["-","a"]}',
			patronEtiqueta: '-a-a-a…'
		});
		const redondilla = candidato('redondilla', [8], {
			patron: '{"comportamiento":"secuencia_fija","posiciones":["a","b","b","a"]}',
			patronEtiqueta: 'abba'
		});
		const pregunta = elegirSiguientePreguntaNueva([romance, redondilla], 'variantes');

		expect(pregunta?.rasgo).toBe('patron');
		expect(pregunta?.opciones).toContainEqual({
			valor: romance.rasgos.patron,
			etiqueta: '-a-a-a…'
		});
	});

	it('distingue las series endecasilábicas con dos preguntas cualitativas', () => {
		const suelto = candidato('endecasilabo-suelto', [11], {
			predominioRima: { clave: 'sueltos', etiqueta: 'Predominan los versos sueltos' },
			organizacionPareados: {
				clave: 'no_sistematica',
				etiqueta: 'Sin organización sistemática en pareados'
			},
			patron: 'suelto'
		});
		const silva = candidato('silva-endecasilabica', [11], {
			predominioRima: { clave: 'rimados', etiqueta: 'Predominan los versos rimados' },
			organizacionPareados: {
				clave: 'no_sistematica',
				etiqueta: 'Sin organización sistemática en pareados'
			},
			patron: 'silva'
		});
		const pareados = candidato('pareados-endecasilabos', [11], {
			predominioRima: { clave: 'rimados', etiqueta: 'Predominan los versos rimados' },
			organizacionPareados: {
				clave: 'sistematica',
				etiqueta: 'Organización sistemática en pareados'
			},
			patron: 'pareados'
		});
		const candidatos = [suelto, silva, pareados];
		const primera = elegirSiguientePreguntaNueva(candidatos, 'familias', [], {
			incluirPatronEnFamilias: true
		});

		expect(primera).toMatchObject({
			rasgo: 'predominioRima',
			tipo: 'si_no',
			pregunta: '¿Predominan los versos rimados?',
			valorObjetivo: 'rimados'
		});
		if (!primera) throw new Error('Falta la primera pregunta cualitativa');

		const respuesta = crearRespuestaNueva(primera, 'si', 'Sí');
		const restantes = filtrarCandidatosNuevos(candidatos, [primera], [respuesta]);
		const segunda = elegirSiguientePreguntaNueva(restantes, 'familias', [respuesta], {
			incluirPatronEnFamilias: true
		});

		expect(restantes.map((item) => item.id)).toEqual([
			'silva-endecasilabica',
			'pareados-endecasilabos'
		]);
		expect(segunda).toMatchObject({
			rasgo: 'organizacionPareados',
			tipo: 'si_no',
			pregunta: '¿La serie está organizada sistemáticamente en pareados?',
			valorObjetivo: 'sistematica'
		});
	});

	it('No sé no elimina candidatas', () => {
		const candidatos = [candidato('a', [8]), candidato('b', [11])];
		const pregunta = elegirSiguientePreguntaNueva(candidatos, 'familias');
		if (!pregunta) throw new Error('Falta pregunta');
		const respuesta = crearRespuestaNueva(pregunta, 'desconocido', 'No sé');

		expect(filtrarCandidatosNuevos(candidatos, [pregunta], [respuesta])).toHaveLength(2);
	});

	it('una respuesta solo descarta contradicciones declaradas', () => {
		const candidatos = [
			candidato('octosilaba', [8]),
			candidato('endecasilaba', [11]),
			candidato('sin-dato', [])
		];
		const pregunta = construirPreguntas(candidatos, 'familias').find(
			(item) => item.rasgo === 'metros'
		);
		if (!pregunta) throw new Error('Falta pregunta de metro');
		const opcionOcho = pregunta.opciones.find((opcion) => opcion.valor === '8') ?? {
			valor: 'si',
			etiqueta: 'Sí'
		};
		const respuesta = crearRespuestaNueva(pregunta, opcionOcho.valor, opcionOcho.etiqueta);
		const result = filtrarCandidatosNuevos(candidatos, [pregunta], [respuesta]);

		expect(result.map((item) => item.id)).toContain('octosilaba');
		expect(result.map((item) => item.id)).toContain('sin-dato');
		expect(result.map((item) => item.id)).not.toContain('endecasilaba');
	});
});

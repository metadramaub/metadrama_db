import { describe, expect, it } from 'vitest';

import estrofasRaw from './data/estrofas.json';
import familiasRaw from './data/familias.json';
import preguntasRaw from './data/preguntas.json';

import {
	crearRespuestaDemarcador,
	elegirSiguientePregunta,
	esPreguntaAplicable,
	filtrarCandidatas,
	normalizarEstrofas,
	normalizarFamilias,
	normalizarPreguntas,
	type EstrofaDemarcador,
	type PreguntaDemarcador
} from './index';

function estrofa(
	slug: string,
	rasgos: Record<string, unknown>,
	familySlug?: string
): EstrofaDemarcador {
	return {
		id: slug,
		slug,
		label: slug,
		familySlug,
		rasgos,
		metrica: {},
		notasRevision: [],
		preguntasSugeridas: []
	};
}

function estrofaMetrica(slug: string, metrica: EstrofaDemarcador['metrica']): EstrofaDemarcador {
	return {
		...estrofa(slug, {}),
		metrica
	};
}

function pregunta(overrides: Partial<PreguntaDemarcador>): PreguntaDemarcador {
	return {
		id: 'pregunta',
		pregunta: 'pregunta',
		tipo: 'si_no_ns',
		rasgo: 'rasgo',
		fase: 'inicial',
		prioridad: 10,
		prioridadEditorial: 10,
		opciones: [],
		valores: [],
		bloqueaGruposSiTrue: [],
		bloqueadoPorGruposSiTrue: [],
		bloqueaPreguntasSiTrue: [],
		admiteDesconocido: true,
		requiereFamilias: [],
		nuncaPrimera: false,
		...overrides
	};
}

describe('filtrarCandidatas', () => {
	it('no descarta candidatas cuando la respuesta es No sé', () => {
		const question = pregunta({ id: 'isometrica', rasgo: 'isometrica' });
		const candidates = [estrofa('a', { isometrica: true }), estrofa('b', { isometrica: false })];

		const result = filtrarCandidatas(candidates, [
			crearRespuestaDemarcador(question, 'desconocido', 'No sé')
		]);

		expect(result.map((candidate) => candidate.slug)).toEqual(['a', 'b']);
	});

	it('conserva candidatas con el rasgo indefinido', () => {
		const question = pregunta({ id: 'isometrica', rasgo: 'isometrica' });
		const candidates = [
			estrofa('definida-compatible', { isometrica: true }),
			estrofa('definida-incompatible', { isometrica: false }),
			estrofa('indefinida', {})
		];

		const result = filtrarCandidatas(candidates, [
			crearRespuestaDemarcador(question, true, 'Sí')
		]);

		expect(result.map((candidate) => candidate.slug)).toEqual([
			'definida-compatible',
			'indefinida'
		]);
	});

	it('descarta solo contradicciones definidas en respuestas Sí/No', () => {
		const question = pregunta({ id: 'rima_en_pares', rasgo: 'rima_en_pares' });
		const candidates = [
			estrofa('si', { rima_en_pares: true }),
			estrofa('no', { rima_en_pares: false }),
			estrofa('sin-dato', {})
		];

		const result = filtrarCandidatas(candidates, [
			crearRespuestaDemarcador(question, false, 'No')
		]);

		expect(result.map((candidate) => candidate.slug)).toEqual(['no', 'sin-dato']);
	});

	it('filtra rasgo_contiene sin descartar indefinidos', () => {
		const question = pregunta({
			id: 'metro_heptasilabo',
			rasgo: '',
			rasgoContiene: 'metros',
			valor: 7
		});
		const candidates = [
			estrofa('octosilaba', { metros: [8] }),
			estrofa('hepta-endecasilaba', { metros: [7, 11] }),
			estrofa('sin-dato', {})
		];

		const result = filtrarCandidatas(candidates, [
			crearRespuestaDemarcador(question, true, 'Sí')
		]);

		expect(result.map((candidate) => candidate.slug)).toEqual(['hepta-endecasilaba', 'sin-dato']);
	});

	it('filtra rasgo_conjunto sin descartar indefinidos', () => {
		const question = pregunta({
			id: 'metro_heptasilabo_endecasilabo',
			rasgo: '',
			rasgoConjunto: 'metros',
			valor: [7, 11]
		});
		const candidates = [
			estrofa('endecasilaba', { metros: [11] }),
			estrofa('hepta-endecasilaba', { metros: [7, 11] }),
			estrofa('sin-dato', {})
		];

		const result = filtrarCandidatas(candidates, [
			crearRespuestaDemarcador(question, true, 'Sí')
		]);

		expect(result.map((candidate) => candidate.slug)).toEqual(['hepta-endecasilaba', 'sin-dato']);
	});

	it('usa valor_si y valor_no para respuestas Sí/No con valores concretos', () => {
		const question = pregunta({
			id: 'pausa_decima_copla',
			rasgo: 'pausa_estructural_tras_verso',
			valorSi: 4,
			valorNo: 5
		});
		const candidates = [
			estrofa('pausa-cuarto', { pausa_estructural_tras_verso: 4 }),
			estrofa('pausa-quinto', { pausa_estructural_tras_verso: 5 }),
			estrofa('sin-dato', {})
		];

		const result = filtrarCandidatas(candidates, [
			crearRespuestaDemarcador(question, false, 'No')
		]);

		expect(result.map((candidate) => candidate.slug)).toEqual(['pausa-quinto', 'sin-dato']);
	});

	it('usa rasgo_valor como rasgo escalar con valor esperado para respuesta afirmativa', () => {
		const question = pregunta({
			id: 'versos_4',
			rasgo: '',
			rasgoValor: 'numero_versos_fijo',
			valor: 4
		});
		const candidates = [
			estrofa('cuatro', { numero_versos_fijo: 4 }),
			estrofa('cinco', { numero_versos_fijo: 5 }),
			estrofa('sin-dato', {})
		];

		const result = filtrarCandidatas(candidates, [
			crearRespuestaDemarcador(question, true, 'Si')
		]);

		expect(result.map((candidate) => candidate.slug)).toEqual(['cuatro', 'sin-dato']);
	});

	it('usa rasgo_valor como contradiccion definida para respuesta negativa', () => {
		const question = pregunta({
			id: 'versos_4',
			rasgo: '',
			rasgoValor: 'numero_versos_fijo',
			valor: 4
		});
		const candidates = [
			estrofa('cuatro', { numero_versos_fijo: 4 }),
			estrofa('cinco', { numero_versos_fijo: 5 }),
			estrofa('sin-dato', {})
		];

		const result = filtrarCandidatas(candidates, [
			crearRespuestaDemarcador(question, false, 'No')
		]);

		expect(result.map((candidate) => candidate.slug)).toEqual(['cinco', 'sin-dato']);
	});

	it('no filtra rasgo_valor con respuesta desconocida', () => {
		const question = pregunta({
			id: 'rima_consonante',
			rasgo: '',
			rasgoValor: 'tipo_rima',
			valor: 'consonante'
		});
		const candidates = [
			estrofa('consonante', { tipo_rima: 'consonante' }),
			estrofa('asonante', { tipo_rima: 'asonante' })
		];

		const result = filtrarCandidatas(candidates, [
			crearRespuestaDemarcador(question, 'desconocido', 'No se')
		]);

		expect(result.map((candidate) => candidate.slug)).toEqual(['consonante', 'asonante']);
	});

	it('usa rasgo_valor para valores no numericos', () => {
		const question = pregunta({
			id: 'rima_consonante',
			rasgo: '',
			rasgoValor: 'tipo_rima',
			valor: 'consonante'
		});
		const candidates = [
			estrofa('consonante', { tipo_rima: 'consonante' }),
			estrofa('asonante', { tipo_rima: 'asonante' }),
			estrofa('sin-dato', {})
		];

		const result = filtrarCandidatas(candidates, [
			crearRespuestaDemarcador(question, true, 'Si')
		]);

		expect(result.map((candidate) => candidate.slug)).toEqual(['consonante', 'sin-dato']);
	});
});

describe('elegirSiguientePregunta', () => {
	it('elige forma_abierta como primera pregunta con preguntas v2', () => {
		const questions = normalizarPreguntas(preguntasRaw);
		const candidates = [
			estrofa('abierta', { forma_abierta: true, esquema_rima: 'abba', asonancia: '-a' }),
			estrofa('cerrada', { forma_abierta: false, esquema_rima: 'abab', asonancia: '-e' })
		];

		const result = elegirSiguientePregunta(candidates, questions, []);

		expect(result?.id).toBe('forma_abierta');
		expect(result?.id).not.toMatch(/^esquema_rima/);
		expect(result?.id).not.toBe('asonancia_pares');
	});

	it('respeta nunca_primera aunque la pregunta divida candidatas', () => {
		const candidates = [
			estrofa('a', { esquema_rima: 'abba', forma_abierta: true }),
			estrofa('b', { esquema_rima: 'abab', forma_abierta: false })
		];
		const questions = [
			pregunta({
				id: 'esquema_rima_basico',
				rasgo: 'esquema_rima',
				tipo: 'opcion',
				nuncaPrimera: true,
				opciones: ['abba', 'abab'],
				prioridadEditorial: 1
			}),
			pregunta({ id: 'forma_abierta', rasgo: 'forma_abierta', prioridadEditorial: 10 })
		];

		const result = elegirSiguientePregunta(candidates, questions, []);

		expect(result?.id).toBe('forma_abierta');
	});

	it('respeta max_candidatas', () => {
		const question = pregunta({
			id: 'estribillo',
			rasgo: 'estribillo',
			maxCandidatas: 2
		});
		const candidates = [
			estrofa('a', { estribillo: true }),
			estrofa('b', { estribillo: false }),
			estrofa('c', { estribillo: true })
		];

		expect(esPreguntaAplicable(question, candidates, [])).toBe(false);
	});

	it('activa requiere_rasgos solo cuando el conjunto actual confirma el requisito', () => {
		const question = pregunta({
			id: 'asonancia_pares',
			rasgo: 'asonancia',
			tipo: 'opcion',
			fase: 'avanzada',
			requiereRasgos: { tipo_rima: 'asonante', rima_en_pares: true },
			requiereFamilias: [],
			opciones: ['-a', '-e']
		});
		const candidates = [
			estrofa('romance-a', { tipo_rima: 'asonante', rima_en_pares: true, asonancia: '-a' }),
			estrofa('romance-e', { tipo_rima: 'asonante', rima_en_pares: true, asonancia: '-e' })
		];
		const mixedCandidates = [
			...candidates,
			estrofa('otra', { tipo_rima: 'consonante', rima_en_pares: false, asonancia: '-i' })
		];

		expect(esPreguntaAplicable(question, candidates, [])).toBe(true);
		expect(esPreguntaAplicable(question, mixedCandidates, [])).toBe(false);
	});

	it('activa requiere_familias con mayoría mínima del 60%', () => {
		const question = pregunta({
			id: 'asonancia_pares',
			rasgo: 'asonancia',
			tipo: 'opcion',
			requiereFamilias: ['romance'],
			opciones: ['-a', '-e']
		});
		const candidates = [
			estrofa('romance-a', { asonancia: '-a' }, 'romance'),
			estrofa('romance-e', { asonancia: '-e' }, 'romance'),
			estrofa('otra', { asonancia: '-i' }, 'otra')
		];
		const insufficientCandidates = [
			estrofa('romance-a', { asonancia: '-a' }, 'romance'),
			estrofa('otra-i', { asonancia: '-i' }, 'otra'),
			estrofa('otra-o', { asonancia: '-o' }, 'otra')
		];

		expect(esPreguntaAplicable(question, candidates, [])).toBe(true);
		expect(esPreguntaAplicable(question, insufficientCandidates, [])).toBe(false);
	});

	it('el orden editorial gana a la división estadística', () => {
		const candidates = [
			estrofa('a', { forma_abierta: true, tipo_rima: 'asonante' }),
			estrofa('b', { forma_abierta: false, tipo_rima: 'consonante' }),
			estrofa('c', { forma_abierta: false, tipo_rima: 'suelta' })
		];
		const questions = [
			pregunta({
				id: 'tipo_rima',
				rasgo: 'tipo_rima',
				tipo: 'opcion',
				prioridadEditorial: 20,
				opciones: ['asonante', 'consonante', 'suelta']
			}),
			pregunta({ id: 'forma_abierta', rasgo: 'forma_abierta', prioridadEditorial: 10 })
		];

		const result = elegirSiguientePregunta(candidates, questions, []);

		expect(result?.id).toBe('forma_abierta');
	});

	it('aplica bloqueos declarativos por grupos tras respuesta afirmativa', () => {
		const candidates = [
			estrofaMetrica('octosilaba', { metroExclusivo: true, metrosPosibles: [8] }),
			estrofaMetrica('endecasilaba', { metroExclusivo: true, metrosPosibles: [11] }),
			estrofaMetrica('silva', { metroExclusivo: false, metrosPosibles: [7, 11] }),
			estrofaMetrica('seguidilla', {
				metroExclusivo: false,
				metrosPosibles: [5, 7],
				patronMetrico: [7, 5, 7, 5]
			})
		];
		const octosilabo = pregunta({
			id: 'metro_unico_octosilabo',
			rasgo: 'metro_unico',
			valor: 8,
			grupoExcluyente: 'metro_unico',
			grupoLogico: 'metro_unico',
			bloqueaGruposSiTrue: [
				'metro_unico',
				'metro_presencia_general',
				'metro_combinacion_general',
				'patron_metrico_base'
			]
		});
		const answers = [crearRespuestaDemarcador(octosilabo, true, 'Si')];

		expect(
			esPreguntaAplicable(
				pregunta({
					id: 'metro_unico_endecasilabo',
					rasgo: 'metro_unico',
					valor: 11,
					grupoExcluyente: 'metro_unico',
					grupoLogico: 'metro_unico'
				}),
				candidates,
				answers
			)
		).toBe(false);
		expect(
			esPreguntaAplicable(
				pregunta({
					id: 'metro_contiene_endecasilabo',
					rasgo: '',
					rasgoContiene: 'metros_posibles',
					valor: 11,
					grupoLogico: 'metro_presencia_general'
				}),
				candidates,
				answers
			)
		).toBe(false);
		expect(
			esPreguntaAplicable(
				pregunta({
					id: 'metro_heptasilabo_endecasilabo',
					rasgo: '',
					rasgoConjunto: 'metros_posibles',
					valores: [7, 11],
					grupoLogico: 'metro_combinacion_general'
				}),
				candidates,
				answers
			)
		).toBe(false);
		expect(
			esPreguntaAplicable(
				pregunta({
					id: 'patron_7_5',
					rasgo: '',
					rasgoPatronContiene: 'patron_metrico',
					valores: [7, 5],
					grupoLogico: 'patron_metrico_base'
				}),
				candidates,
				answers
			)
		).toBe(false);
	});

	it('aplica bloqueado_por_grupos_si_true desde la pregunta candidata', () => {
		const candidates = [
			estrofaMetrica('octosilaba', { metroExclusivo: true, metrosPosibles: [8] }),
			estrofaMetrica('silva', { metroExclusivo: false, metrosPosibles: [7, 11] })
		];
		const octosilabo = pregunta({
			id: 'metro_unico_octosilabo',
			rasgo: 'metro_unico',
			valor: 8,
			grupoExcluyente: 'metro_unico'
		});
		const contieneEndecasilabo = pregunta({
			id: 'metro_contiene_endecasilabo',
			rasgo: '',
			rasgoContiene: 'metros_posibles',
			valor: 11,
			grupoLogico: 'metro_presencia_general',
			bloqueadoPorGruposSiTrue: ['metro_unico']
		});
		const answers = [crearRespuestaDemarcador(octosilabo, true, 'Si')];

		expect(esPreguntaAplicable(contieneEndecasilabo, candidates, answers)).toBe(false);
	});

	it('aplica bloquea_preguntas_si_true antes de la utilidad', () => {
		const candidates = [estrofa('a', { rasgo_destino: true }), estrofa('b', { rasgo_destino: false })];
		const blocker = pregunta({
			id: 'bloqueadora',
			rasgo: 'rasgo_origen',
			bloqueaPreguntasSiTrue: ['destino']
		});
		const target = pregunta({ id: 'destino', rasgo: 'rasgo_destino' });
		const answers = [crearRespuestaDemarcador(blocker, true, 'Si')];

		expect(esPreguntaAplicable(target, candidates, answers)).toBe(false);
		expect(elegirSiguientePregunta(candidates, [target], answers)).toBeNull();
	});

	it('no bloquea otras preguntas metro_unico tras respuesta negativa o desconocida', () => {
		const candidates = [
			estrofaMetrica('octosilaba', { metroExclusivo: true, metrosPosibles: [8] }),
			estrofaMetrica('endecasilaba', { metroExclusivo: true, metrosPosibles: [11] })
		];
		const octosilabo = pregunta({
			id: 'metro_unico_octosilabo',
			rasgo: 'metro_unico',
			valor: 8,
			grupoExcluyente: 'metro_unico',
			grupoLogico: 'metro_unico',
			bloqueaGruposSiTrue: ['metro_unico']
		});
		const endecasilabo = pregunta({
			id: 'metro_unico_endecasilabo',
			rasgo: 'metro_unico',
			valor: 11,
			grupoExcluyente: 'metro_unico',
			grupoLogico: 'metro_unico'
		});

		expect(
			esPreguntaAplicable(endecasilabo, candidates, [
				crearRespuestaDemarcador(octosilabo, false, 'No')
			])
		).toBe(true);
		expect(
			esPreguntaAplicable(endecasilabo, candidates, [
				crearRespuestaDemarcador(octosilabo, 'desconocido', 'No se')
			])
		).toBe(true);
	});
});

describe('filtrado con datos v3 reales', () => {
	const familias = normalizarFamilias(familiasRaw);
	const estrofas = normalizarEstrofas(estrofasRaw, familias);
	const preguntas = normalizarPreguntas(preguntasRaw);

	function getQuestion(questionId: string) {
		const question = preguntas.find((item) => item.id === questionId);
		if (!question) throw new Error(`Pregunta no encontrada: ${questionId}`);
		return question;
	}

	it('no termina prematuramente tras confirmar metro_unico_octosilabo', () => {
		const answers = [
			crearRespuestaDemarcador(getQuestion('forma_abierta'), false, 'No'),
			crearRespuestaDemarcador(getQuestion('numero_fijo_versos'), true, 'Si'),
			crearRespuestaDemarcador(getQuestion('isometrica'), true, 'Si'),
			crearRespuestaDemarcador(getQuestion('metro_unico_octosilabo'), true, 'Si')
		];
		const candidates = filtrarCandidatas(estrofas, answers);
		const result = elegirSiguientePregunta(candidates, preguntas, answers);

		expect(candidates.length).toBeGreaterThan(1);
		expect(result).not.toBeNull();
		expect([
			'rima_asonante',
			'rima_consonante',
			'rima_en_pares',
			'versos_4',
			'versos_5',
			'versos_10'
		]).toContain(result?.id);
		expect(esPreguntaAplicable(getQuestion('metro_unico_endecasilabo'), candidates, answers)).toBe(
			false
		);
		expect(esPreguntaAplicable(getQuestion('metro_contiene_endecasilabo'), candidates, answers)).toBe(
			false
		);
		expect(
			esPreguntaAplicable(getQuestion('metro_heptasilabo_endecasilabo'), candidates, answers)
		).toBe(false);
		expect(esPreguntaAplicable(getQuestion('patron_7_5'), candidates, answers)).toBe(false);
	});

	function aplicarSi(questionId: string) {
		const question = preguntas.find((item) => item.id === questionId);
		if (!question) throw new Error(`Pregunta no encontrada: ${questionId}`);

		return filtrarCandidatas(estrofas, [crearRespuestaDemarcador(question, true, 'Sí')]).map(
			(candidate) => candidate.slug
		);
	}

	it('sí a aparecen endecasílabos descarta seguidilla', () => {
		const result = aplicarSi('metro_contiene_endecasilabo');

		expect(result).not.toContain('seguidilla');
		expect(result).toContain('soneto');
		expect(result).toContain('silva');
	});

	it('sí a todos o casi todos endecasílabos descarta formas heterométricas', () => {
		const result = aplicarSi('metro_unico_endecasilabo');

		expect(result).toContain('soneto');
		expect(result).toContain('octava_real');
		expect(result).toContain('terceto');
		expect(result).toContain('endecasilabo_suelto');
		expect(result).toContain('romance_heroico');
		expect(result).not.toContain('silva');
		expect(result).not.toContain('lira');
		expect(result).not.toContain('sexteto_lira');
		expect(result).not.toContain('seguidilla');
	});

	it('sí a combina heptasílabos y endecasílabos conserva formas 7/11', () => {
		const result = aplicarSi('metro_heptasilabo_endecasilabo');

		expect(result).toContain('silva');
		expect(result).toContain('lira');
		expect(result).toContain('cancion_petrarquista');
		expect(result).toContain('sexteto_lira');
		expect(result).not.toContain('seguidilla');
	});

	it('sí a alterna 7 y 5 conserva seguidilla', () => {
		const result = aplicarSi('patron_7_5');

		expect(result).toContain('seguidilla');
	});

	it('la primera pregunta no es esquema, asonancia ni patrón técnico', () => {
		const result = elegirSiguientePregunta(estrofas, preguntas, []);

		expect(result?.id).toBe('forma_abierta');
		expect(result?.id).not.toMatch(/^esquema_rima/);
		expect(result?.id).not.toBe('asonancia_pares');
		expect(result?.id).not.toBe('patron_7_5');
	});
});

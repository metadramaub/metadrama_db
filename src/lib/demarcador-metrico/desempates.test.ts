import { describe, expect, it } from 'vitest';
import {
	crearRespuesta,
	elegirPregunta,
	encajeDe,
	etiquetaEncaje,
	etiquetaNivel,
	ordenarFormas,
	puntuarHipotesis,
	veredictoDeHipotesis
} from './motor';
import type {
	CatalogoDemarcador,
	EvidenciaNormativa,
	HipotesisMetrica,
	PreguntaDemarcador
} from './modelo';

/**
 * Lo que se corrigió el 25 de septiembre de 2026, cuando el pareado salía con «encaje bajo» en
 * pasajes de dos versos y por detrás del terceto en pasajes pares. Cada prueba fija una de las
 * decisiones; el porqué largo está en el comentario del código que prueba.
 */

function evidencia(
	dimension: string,
	familiaCognitiva: EvidenciaNormativa['familiaCognitiva'],
	claves: string[],
	override: Partial<EvidenciaNormativa> = {}
): EvidenciaNormativa {
	return {
		dimension,
		familiaCognitiva,
		etiqueta: dimension,
		tipo: 'categoria',
		valores: claves.map((clave) => ({ clave, etiqueta: clave })),
		minimo: null,
		maximo: null,
		modulo: null,
		residuo: null,
		desplazamientos: null,
		reglaLongitud: null,
		modalidad: 'definitoria',
		observabilidad: 'directa',
		coste: 0.2,
		orden: 10,
		fuente: 'norma',
		...override
	};
}

function hipotesis(
	formaId: string,
	evidencias: EvidenciaNormativa[],
	override: Partial<HipotesisMetrica> = {}
): HipotesisMetrica {
	return {
		id: `${formaId}:a`,
		formaId,
		formaSlug: formaId,
		formaNombre: formaId,
		formaDefinicion: null,
		nivelEstructural: 'estrofa',
		arquitecturaId: `${formaId}:a`,
		arquitecturaSlug: 'a',
		arquitecturaNombre: 'a',
		arquitecturaDescripcion: null,
		arquitecturaPrincipal: true,
		unidadVersos: null,
		presentacion: {
			rejilla: null,
			metro: { descripcion: null },
			rima: { tipo: null, esquemas: [] },
			estructura: null,
			repeticiones: [],
			rasgos: []
		},
		evidencias,
		...override
	};
}

function catalogoDe(hipotesisLista: HipotesisMetrica[]): CatalogoDemarcador {
	return { formas: [], relaciones: [], textos: {}, advertencias: [], hipotesis: hipotesisLista };
}

function pregunta(
	dimension: string,
	familiaCognitiva: PreguntaDemarcador['familiaCognitiva'],
	tipo: PreguntaDemarcador['tipo'] = 'categoria'
): PreguntaDemarcador {
	return {
		id: dimension,
		dimension,
		familiaCognitiva,
		pregunta: dimension,
		ayuda: '',
		tipo,
		opciones: [],
		observabilidad: 'directa',
		coste: 0,
		utilidad: 1
	};
}

const extension = (modulo: number, minimo = modulo) =>
	evidencia('extension:versos', 'extension', [], {
		tipo: 'numero',
		minimo,
		modulo,
		residuo: 0,
		orden: 8
	});
const agrupacion = (versos: number) =>
	evidencia('estructura:agrupacion', 'estructura', [String(versos)], { orden: 9 });
const arteMenor = evidencia('metro:grupo', 'metro', ['arte_menor'], { orden: 1 });
const consonante = evidencia('rima:tipo', 'rima', ['consonante'], { orden: 15 });

describe('la agrupación se pregunta una vez, por su tamaño', () => {
	const catalogo = catalogoDe([
		hipotesis('pareado', [arteMenor, consonante, extension(2), agrupacion(2)]),
		hipotesis('terceto', [arteMenor, consonante, extension(3), agrupacion(3)]),
		hipotesis('sextilla', [arteMenor, consonante, extension(6), agrupacion(6)]),
		hipotesis('octava', [arteMenor, consonante, extension(8), agrupacion(8)]),
		hipotesis('romance', [arteMenor, evidencia('rima:tipo', 'rima', ['asonante'])], {
			nivelEstructural: 'serie'
		})
	]);
	const respuestas = [
		crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_menor', 'Arte menor'),
		crearRespuesta(pregunta('rima:tipo', 'rima'), 'consonante', 'Consonante'),
		crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 6, '6 versos')
	];

	it('ofrece los tamaños en orden, sin los que no caben en el pasaje, y la salida de no ver grupos', () => {
		const siguiente = elegirPregunta(catalogo, respuestas, 'guiado');
		expect(siguiente?.dimension).toBe('estructura:agrupacion');
		expect(siguiente?.opciones.map((opcion) => opcion.clave)).toEqual(['2', '3', '6', 'ninguno']);
	});

	it('seis versos en pareados dejan detrás al terceto y a la sextilla con una sola respuesta', () => {
		const formas = ordenarFormas(catalogo, [
			...respuestas,
			crearRespuesta(pregunta('estructura:agrupacion', 'estructura'), '2', 'De 2 en 2')
		]);
		expect(formas[0].formaId).toBe('pareado');
		expect(formas[0].nivel).toBe('alto');
	});

	it('no ver grupos contradice a las estrofas y deja en paz a las series', () => {
		const formas = ordenarFormas(catalogo, [
			crearRespuesta(pregunta('estructura:agrupacion', 'estructura'), 'ninguno', 'No se distinguen')
		]);
		const romance = formas.find((forma) => forma.formaId === 'romance');
		const pareado = formas.find((forma) => forma.formaId === 'pareado');
		expect(romance?.arquitecturas[0].contradicciones).toBe(0);
		expect(pareado?.arquitecturas[0].contradicciones).toBe(1);
	});
});

describe('cada valor pesa lo que pesa su esquema', () => {
	it('una rima que la norma solo admite no vale lo mismo que la que prefiere', () => {
		const octavaAguda = hipotesis('octava_aguda', [
			evidencia('rima:tipo', 'rima', ['asonante', 'consonante'], {
				modalidadPorValor: { asonante: 'admitida' }
			})
		]);
		const conAsonante = puntuarHipotesis(octavaAguda, [
			crearRespuesta(pregunta('rima:tipo', 'rima'), 'asonante', 'Asonante')
		]);
		const conConsonante = puntuarHipotesis(octavaAguda, [
			crearRespuesta(pregunta('rima:tipo', 'rima'), 'consonante', 'Consonante')
		]);
		// Las dos coinciden: la variante no contradice, pero vale menos.
		expect(conAsonante.contradicciones).toBe(0);
		expect(conAsonante.puntuacion).toBeLessThan(conConsonante.puntuacion);
	});
});

describe('un mínimo es una condición necesaria, no un indicio', () => {
	const zejel = hipotesis(
		'zejel',
		[
			evidencia('extension:versos', 'extension', [], {
				tipo: 'numero',
				minimo: 5,
				soloContradice: true
			})
		],
		{ nivelEstructural: 'composicion' }
	);

	it('no suma cuando el pasaje llega al mínimo', () => {
		const puntuada = puntuarHipotesis(zejel, [
			crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 30, '30 versos')
		]);
		expect(puntuada.coincidencias).toBe(0);
		expect(puntuada.puntuacion).toBeCloseTo(0.05);
	});

	it('resta cuando el pasaje se queda corto', () => {
		const puntuada = puntuarHipotesis(zejel, [
			crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 2, '2 versos')
		]);
		expect(puntuada.contradicciones).toBe(1);
		expect(puntuada.puntuacion).toBeLessThan(0);
	});
});

describe('una arquitectura excepcional no gana un empate', () => {
	it('la regular pasa delante cuando las dos encajan igual', () => {
		const comun = [arteMenor, consonante, agrupacion(5)];
		const formas = ordenarFormas(
			catalogoDe([
				hipotesis('endecha', comun, {
					arquitecturaPrincipal: false,
					arquitecturaModalidad: 'excepcional'
				}),
				hipotesis('lira', comun, { arquitecturaPrincipal: false })
			]),
			[crearRespuesta(pregunta('rima:tipo', 'rima'), 'consonante', 'Consonante')]
		);
		expect(formas.map((forma) => forma.formaId)).toEqual(['lira', 'endecha']);
	});
});

describe('cuando varias van en cabeza, se pregunta por lo que las separa', () => {
	const distribucion = (notacion: string) =>
		evidencia('rima:distribucion', 'rima', [notacion], {
			observabilidad: 'especializada',
			coste: 0.6,
			orden: 45
		});
	const orden = (etiqueta: string) =>
		evidencia('estructura:orden', 'estructura', [etiqueta], {
			observabilidad: 'especializada',
			coste: 0.64,
			orden: 55
		});
	const repeticion = (clave: string) =>
		evidencia('repeticion:presencia', 'repeticion', [clave], { tipo: 'booleano', orden: 18 });

	it('ofrece la organización interna para desempatar, aunque el recorrido sea guiado', () => {
		const catalogo = catalogoDe([
			hipotesis('decima', [
				arteMenor,
				consonante,
				extension(10),
				orden('Redondilla + Enlace + Redondilla')
			]),
			hipotesis('copla_real', [
				arteMenor,
				consonante,
				extension(10),
				orden('Quintilla + Quintilla')
			]),
			hipotesis('romance', [arteMenor, evidencia('rima:tipo', 'rima', ['asonante'])])
		]);
		const siguiente = elegirPregunta(
			catalogo,
			[
				crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_menor', 'Arte menor'),
				crearRespuesta(pregunta('rima:tipo', 'rima'), 'consonante', 'Consonante'),
				crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 10, '10 versos')
			],
			'guiado'
		);
		expect(siguiente?.dimension).toBe('estructura:orden');
		expect(siguiente?.opciones.map((opcion) => opcion.clave).sort()).toEqual([
			'Quintilla + Quintilla',
			'Redondilla + Enlace + Redondilla'
		]);
	});

	it('elige la pregunta entre las de cabeza, no entre las de detrás', () => {
		// Octava real y octava aguda empatan; el terceto y la silva van detrás y lo que las separaría
		// a ellas —la repetición— no dice nada de las octavas.
		const catalogo = catalogoDe([
			hipotesis('octava_real', [
				consonante,
				extension(8),
				distribucion('ABABABCC'),
				repeticion('no')
			]),
			hipotesis('octava_aguda', [
				consonante,
				extension(8),
				distribucion('---a---a'),
				repeticion('no')
			]),
			hipotesis('terceto', [consonante, extension(3), repeticion('si')]),
			hipotesis('silva', [consonante, repeticion('si')], { nivelEstructural: 'serie' })
		]);
		const siguiente = elegirPregunta(
			catalogo,
			[
				crearRespuesta(pregunta('rima:tipo', 'rima'), 'consonante', 'Consonante'),
				crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 8, '8 versos'),
				crearRespuesta(pregunta('metro:grupo', 'metro'), 'desconocido', 'No sé')
			],
			'guiado'
		);
		expect(siguiente?.dimension).toBe('rima:distribucion');
	});
});

describe('encajar y ser la más probable son dos cosas', () => {
	const catalogo = catalogoDe([
		hipotesis('redondilla', [arteMenor, consonante, extension(4), agrupacion(4)]),
		hipotesis('pareado', [arteMenor, consonante, extension(2)]),
		hipotesis('romance', [arteMenor, evidencia('rima:tipo', 'rima', ['asonante'])])
	]);
	const respuestas = [
		crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_menor', 'Arte menor'),
		crearRespuesta(pregunta('rima:tipo', 'rima'), 'consonante', 'Consonante'),
		crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 4, '4 versos'),
		crearRespuesta(pregunta('estructura:agrupacion', 'estructura'), '4', 'De 4 en 4')
	];

	it('una forma sin contradicciones encaja aunque vaya por detrás', () => {
		const formas = ordenarFormas(catalogo, respuestas);
		const pareado = formas.find((forma) => forma.formaId === 'pareado')!;
		expect(formas[0].formaId).toBe('redondilla');
		expect(pareado.nivel).toBe('bajo');
		expect(pareado.encaje).toBe('pleno');
		expect(etiquetaNivel(pareado.nivel)).toBe('Menos probable');
		expect(etiquetaEncaje(pareado.encaje)).toBe('Encaja');
	});

	it('la extensión desvía, no contradice', () => {
		const puntuada = puntuarHipotesis(catalogo.hipotesis[0], [
			crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 5, '5 versos')
		]);
		expect(encajeDe(puntuada)).toBe('con_desviacion');
	});

	it('romper lo que la norma fija es no encajar', () => {
		const formas = ordenarFormas(catalogo, respuestas);
		expect(formas.find((forma) => forma.formaId === 'romance')?.encaje).toBe('contradice');
	});
});

describe('en el desempate de un contraste se pregunta lo que falta', () => {
	const distribucion = (notacion: string) =>
		evidencia('rima:distribucion', 'rima', [notacion], {
			observabilidad: 'especializada',
			coste: 0.6,
			orden: 45,
			modalidad: 'habitual'
		});
	// Los esquemas de los rivales lejanos llenan la pregunta —juntos pasan de las siete opciones—, y
	// entre ellos hay otra cosa que preguntar, la repetición, que no separa a las dos octavas.
	const muchos = ['abab', 'abba', 'aabb', 'abcabc', 'aabccb', 'ababcc', 'abbacc'];
	const repeticion = (clave: string) =>
		evidencia('repeticion:presencia', 'repeticion', [clave], { tipo: 'booleano', orden: 18 });
	const catalogo = catalogoDe([
		hipotesis('octava_real', [
			consonante,
			extension(8),
			agrupacion(8),
			distribucion('ABABABCC'),
			repeticion('no')
		]),
		hipotesis('octava_aguda', [
			consonante,
			extension(8),
			agrupacion(8),
			distribucion('---a---a'),
			repeticion('no')
		]),
		...muchos.map((notacion, indice) =>
			hipotesis(`otra_${indice}`, [
				consonante,
				extension(4),
				distribucion(notacion),
				repeticion(indice % 2 === 0 ? 'si' : 'no')
			])
		)
	]);
	catalogo.relaciones = muchos.map((_, indice) => ({
		origenId: 'octava_real',
		destinoId: `otra_${indice}`,
		tipo: 'contrasta_con',
		nota: null
	}));
	const respuestas = [
		crearRespuesta(pregunta('rima:tipo', 'rima'), 'consonante', 'Consonante'),
		crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 8, '8 versos'),
		crearRespuesta(pregunta('estructura:agrupacion', 'estructura'), '8', 'De 8 en 8')
	];

	it('pregunta la discrepancia pendiente con las opciones de la hipótesis y su rival', () => {
		const siguiente = elegirPregunta(catalogo, respuestas, 'hipotesis', 'octava_real');
		expect(siguiente?.dimension).toBe('rima:distribucion');
		expect(siguiente?.opciones.map((opcion) => opcion.clave).sort()).toEqual([
			'---a---a',
			'ABABABCC'
		]);
	});

	it('se sostiene cuando lo único que las separaba cae de su lado, aunque sea por poco', () => {
		const veredicto = veredictoDeHipotesis(catalogo, 'octava_real', [
			...respuestas,
			crearRespuesta(pregunta('rima:distribucion', 'rima'), 'ABABABCC', 'ABABABCC')
		]);
		expect(veredicto.rival?.formaId).toBe('octava_aguda');
		expect(veredicto.pendientes).toEqual([]);
		expect(veredicto.estado).toBe('sostenida');
	});

	it('sigue siendo indecidible cuando empatan y ya no queda nada que preguntar', () => {
		const gemelas = catalogoDe([
			hipotesis('una', [consonante, extension(8)]),
			hipotesis('otra', [consonante, extension(8)])
		]);
		const veredicto = veredictoDeHipotesis(gemelas, 'una', [
			crearRespuesta(pregunta('rima:tipo', 'rima'), 'consonante', 'Consonante'),
			crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 8, '8 versos'),
			crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_mayor', 'Arte mayor')
		]);
		expect(veredicto.estado).toBe('indecidible');
	});
});

describe('la medida que se ofrece es la del arte respondido', () => {
	it('con arte mayor, el pareado de las dos artes no trae medidas de arte menor', () => {
		const catalogo = catalogoDe([
			hipotesis('pareado', [
				evidencia('metro:grupo', 'metro', ['arte_menor', 'arte_mayor'], { orden: 1 }),
				evidencia('metro:exacto', 'metro', ['4', '8', '11', '14'], {
					observabilidad: 'especializada',
					orden: 40
				}),
				extension(2)
			]),
			hipotesis('soneto', [
				evidencia('metro:grupo', 'metro', ['arte_mayor'], { orden: 1 }),
				evidencia('metro:exacto', 'metro', ['11'], { observabilidad: 'especializada', orden: 40 }),
				extension(14)
			])
		]);
		const siguiente = elegirPregunta(
			catalogo,
			[crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_mayor', 'Arte mayor')],
			'guiado'
		);
		expect(siguiente?.dimension).toBe('metro:exacto');
		expect(siguiente?.opciones.map((opcion) => opcion.clave)).toEqual(['11', '14']);
	});
});

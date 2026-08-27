import { describe, expect, it } from 'vitest';
import { crearRespuesta, elegirPregunta, ordenarFormas } from './motor';
import type {
	CatalogoDemarcador,
	EvidenciaNormativa,
	HipotesisMetrica,
	PreguntaDemarcador
} from './modelo';

function evidencia(
	dimension: string,
	familiaCognitiva: EvidenciaNormativa['familiaCognitiva'],
	clave: string,
	etiqueta: string,
	override: Partial<EvidenciaNormativa> = {}
): EvidenciaNormativa {
	return {
		dimension,
		familiaCognitiva,
		etiqueta,
		pregunta: `Pregunta sobre ${etiqueta}`,
		ayuda: '',
		tipo: 'categoria',
		valores: [{ clave, etiqueta }],
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
	formaNombre: string,
	arquitecturaNombre: string,
	evidencias: EvidenciaNormativa[],
	override: Partial<HipotesisMetrica> = {}
): HipotesisMetrica {
	return {
		id: `${formaId}:arquitectura`,
		formaId,
		formaSlug: formaId,
		formaNombre,
		formaDefinicion: null,
		nivelEstructural: 'estrofa',
		arquitecturaId: `${formaId}:arquitectura`,
		arquitecturaSlug: 'principal',
		arquitecturaNombre,
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

const catalogo: CatalogoDemarcador = {
	formas: [],
	advertencias: [],
	hipotesis: [
		hipotesis('romance', 'Romance', 'Octosilábica', [
			evidencia('metro:grupo', 'metro', 'arte_menor', 'Arte menor', { orden: 1 }),
			evidencia('rima:tipo', 'rima', 'asonante', 'Asonante'),
			evidencia('extension:versos', 'extension', '', 'Extensión', {
				tipo: 'numero',
				valores: [],
				minimo: 4,
				maximo: null
			}),
			evidencia('estructura:secciones', 'estructura', 'no', 'Sin secciones', {
				tipo: 'booleano'
			})
		]),
		hipotesis('redondilla', 'Redondilla', 'Octosilábica', [
			evidencia('metro:grupo', 'metro', 'arte_menor', 'Arte menor', { orden: 1 }),
			evidencia('rima:tipo', 'rima', 'consonante', 'Consonante'),
			evidencia('extension:versos', 'extension', '', 'Extensión', {
				tipo: 'numero',
				valores: [],
				minimo: 4,
				maximo: 4
			}),
			evidencia('estructura:secciones', 'estructura', 'no', 'Sin secciones', {
				tipo: 'booleano'
			})
		]),
			hipotesis('soneto', 'Soneto', 'Canónica', [
				evidencia('metro:grupo', 'metro', 'arte_mayor', 'Arte mayor', { orden: 1 }),
			evidencia('rima:tipo', 'rima', 'consonante', 'Consonante'),
			evidencia('extension:versos', 'extension', '', 'Extensión', {
				tipo: 'numero',
				valores: [],
				minimo: 14,
				maximo: 14
			}),
			evidencia('estructura:secciones', 'estructura', 'si', 'Con secciones', {
				tipo: 'booleano'
			})
		])
	]
};

describe('motor ontológico del demarcador', () => {
	it('abre el recorrido guiado con una agrupación amplia de la medida', () => {
		const pregunta = elegirPregunta(catalogo, [], 'guiado');
		expect(pregunta).toMatchObject({
			dimension: 'metro:grupo',
			tipo: 'categoria'
		});
		expect(pregunta?.opciones).toEqual([
			{ clave: 'arte_menor', etiqueta: 'Arte menor' },
			{ clave: 'arte_mayor', etiqueta: 'Arte mayor' },
			{ clave: 'mixto', etiqueta: 'Mixto' }
		]);
	});

	it('concreta después la medida dentro del grupo elegido', () => {
		const catalogoMedidas: CatalogoDemarcador = {
			formas: [],
			advertencias: [],
			hipotesis: [
				hipotesis('menor-7', 'Menor de siete', 'Heptasilábica', [
					evidencia('metro:grupo', 'metro', 'arte_menor', 'Arte menor', { orden: 1 }),
					evidencia('metro:exacto', 'metro', '7', '7 sílabas')
				]),
				hipotesis('menor-8', 'Menor de ocho', 'Octosilábica', [
					evidencia('metro:grupo', 'metro', 'arte_menor', 'Arte menor', { orden: 1 }),
					evidencia('metro:exacto', 'metro', '8', '8 sílabas')
				]),
				hipotesis('mayor-11', 'Mayor de once', 'Endecasilábica', [
					evidencia('metro:grupo', 'metro', 'arte_mayor', 'Arte mayor', { orden: 1 }),
					evidencia('metro:exacto', 'metro', '11', '11 sílabas')
				]),
				hipotesis('mayor-14', 'Mayor de catorce', 'Alejandrina', [
					evidencia('metro:grupo', 'metro', 'arte_mayor', 'Arte mayor', { orden: 1 }),
					evidencia('metro:exacto', 'metro', '14', '14 sílabas')
				]),
				hipotesis('mixta-7-11', 'Mixta de siete y once', 'Alirada', [
					evidencia('metro:grupo', 'metro', 'mixto', 'Mixto', { orden: 1 }),
					evidencia('metro:exacto', 'metro', '7+11', '7 sílabas + 11 sílabas')
				]),
				hipotesis('mixta-8-11', 'Mixta de ocho y once', 'Mixta', [
					evidencia('metro:grupo', 'metro', 'mixto', 'Mixto', { orden: 1 }),
					evidencia('metro:exacto', 'metro', '8+11', '8 sílabas + 11 sílabas')
				])
			]
		};
		const inicial = elegirPregunta(catalogoMedidas, [], 'guiado') as PreguntaDemarcador;
		const arteMenor = crearRespuesta(inicial, 'arte_menor', 'Arte menor');
		const siguienteMenor = elegirPregunta(catalogoMedidas, [arteMenor], 'guiado');

		expect(siguienteMenor?.dimension).toBe('metro:exacto');
		expect(siguienteMenor?.opciones.map((opcion) => opcion.clave)).toEqual(['7', '8']);

		const mixto = crearRespuesta(inicial, 'mixto', 'Mixto');
		const siguienteMixto = elegirPregunta(catalogoMedidas, [mixto], 'guiado');
		expect(siguienteMixto).toMatchObject({
			dimension: 'metro:exacto',
			pregunta: '¿Qué medidas se combinan en los versos?'
		});
		expect(siguienteMixto?.opciones.map((opcion) => opcion.clave)).toEqual(['7+11', '8+11']);
	});

	it('rebaja una familia cognitiva después de No sé', () => {
		const inicial = elegirPregunta(catalogo, [], 'guiado') as PreguntaDemarcador;
		const desconocida = crearRespuesta(inicial, 'desconocido', 'No sé');
		const siguiente = elegirPregunta(catalogo, [desconocida], 'guiado');

		expect(siguiente?.familiaCognitiva).not.toBe('metro');
	});

	it('sitúa Romance primero mediante evidencias concordantes sin eliminar alternativas', () => {
		const metro = elegirPregunta(catalogo, [], 'guiado') as PreguntaDemarcador;
		const respuestaMetro = crearRespuesta(metro, 'arte_menor', 'Arte menor');
		const rima = {
			id: 'pregunta:rima:tipo',
			dimension: 'rima:tipo',
			familiaCognitiva: 'rima',
			pregunta: '¿Qué rima presenta?',
			ayuda: '',
			tipo: 'categoria',
			opciones: [],
			observabilidad: 'directa',
			coste: 0.2,
			utilidad: 1
		} satisfies PreguntaDemarcador;
		const respuestaRima = crearRespuesta(rima, 'asonante', 'Asonante');
		const resultados = ordenarFormas(catalogo, [respuestaMetro, respuestaRima]);

		expect(resultados[0].formaNombre).toBe('Romance');
		expect(resultados).toHaveLength(3);
		expect(resultados[0].arquitecturas[0].hipotesis.arquitecturaNombre).toBe('Octosilábica');
	});

	it('ofrece siempre Sí y No en las preguntas booleanas', () => {
		const catalogoBooleano: CatalogoDemarcador = {
			formas: [],
			advertencias: [],
			hipotesis: catalogo.hipotesis.map((item) => ({
				...item,
				evidencias: item.evidencias.filter((evidencia) => evidencia.tipo === 'booleano')
			}))
		};
		const pregunta = elegirPregunta(catalogoBooleano, [], 'hipotesis', 'romance');

		expect(pregunta?.tipo).toBe('booleano');
		expect(pregunta?.opciones.map((opcion) => opcion.clave)).toEqual(['no', 'si']);
	});

	it('calcula las longitudes regulares vecinas sin descartar una forma con desviación', () => {
		const catalogoLongitudes: CatalogoDemarcador = {
			formas: [],
			advertencias: [],
			hipotesis: [
				hipotesis('soneto', 'Soneto', 'Canónica', [
					evidencia('extension:versos', 'extension', '', 'Extensión', {
						tipo: 'numero', valores: [], minimo: 14, maximo: 14,
						modulo: 14, residuo: 0, reglaLongitud: 'estructuras completas de 14 versos'
					})
				], { nivelEstructural: 'composicion', unidadVersos: 14 }),
				hipotesis('terceto-encadenado', 'Terceto encadenado', 'Endecasilábico', [
					evidencia('extension:versos', 'extension', '', 'Extensión', {
						tipo: 'numero', valores: [], minimo: 4, maximo: null,
						modulo: 3, residuo: 1,
						reglaLongitud: 'bloques completos de 3 versos más 1 verso fijo'
					})
				], { nivelEstructural: 'serie' })
			]
		};
		const pregunta = {
			id: 'pregunta:extension:versos', dimension: 'extension:versos',
			familiaCognitiva: 'extension', pregunta: '¿Cuántos versos tiene?', ayuda: '',
			tipo: 'numero', opciones: [], observabilidad: 'directa', coste: 0.2, utilidad: 1
		} satisfies PreguntaDemarcador;
		const resultados = ordenarFormas(
			catalogoLongitudes,
			[crearRespuesta(pregunta, 14, '14 versos')]
		);
		const terceto = resultados.find((forma) => forma.formaId === 'terceto-encadenado');

		expect(resultados[0].formaNombre).toBe('Soneto');
		expect(resultados[0].arquitecturas[0].desviacionLongitud).toBeNull();
		expect(terceto?.arquitecturas[0].desviacionLongitud).toMatchObject({
			observada: 14,
			regularAnterior: 13,
			regularSiguiente: 16,
			diferenciaMinima: 1
		});
	});

	it('interpreta 25 versos como cinco quintillas y como una serie encadenada regular', () => {
		const metro = evidencia('metro:grupo', 'metro', 'arte_menor', 'Arte menor');
		const agrupacion = evidencia('estructura:agrupacion:5', 'estructura', 'si', 'Grupos de 5', {
			tipo: 'booleano', orden: 9, coste: 0.2
		});
		const serie = evidencia('estructura:serie:3:4', 'estructura', 'si', 'Serie con cierre', {
			tipo: 'booleano', orden: 24, coste: 0.42
		});
		const catalogoPasaje: CatalogoDemarcador = {
			formas: [], advertencias: [], hipotesis: [
				hipotesis('quintilla', 'Quintilla', 'Octosilábica consonante', [
					metro,
					evidencia('extension:versos', 'extension', '', 'Extensión del pasaje', {
						tipo: 'numero', valores: [], minimo: 5, maximo: null, modulo: 5, residuo: 0,
						reglaLongitud: 'unidades completas de 5 versos'
					}),
					agrupacion
				], { unidadVersos: 5 }),
				hipotesis('terceto-encadenado', 'Terceto encadenado', 'Octosilábico', [
					metro,
					evidencia('extension:versos', 'extension', '', 'Extensión del pasaje', {
						tipo: 'numero', valores: [], minimo: 7, maximo: null, modulo: 3, residuo: 1,
						reglaLongitud: 'bloques de 3 versos más el cierre'
					}),
					serie
				], { nivelEstructural: 'serie' })
			]
		};
		const preguntaMetro = {
			id: 'pregunta:metro:grupo', dimension: 'metro:grupo', familiaCognitiva: 'metro',
			pregunta: '¿Qué medida predomina?', ayuda: '', tipo: 'categoria', opciones: [],
			observabilidad: 'directa', coste: 0.1, utilidad: 1
		} satisfies PreguntaDemarcador;
		const preguntaExtension = {
			id: 'pregunta:extension:versos', dimension: 'extension:versos', familiaCognitiva: 'extension',
			pregunta: '¿Cuántos versos abarca?', ayuda: '', tipo: 'numero', opciones: [],
			observabilidad: 'directa', coste: 0.2, utilidad: 1
		} satisfies PreguntaDemarcador;
		const respuestas = [
			crearRespuesta(preguntaMetro, 'arte_menor', 'Arte menor'),
			crearRespuesta(preguntaExtension, 25, '25 versos')
		];
		const resultados = ordenarFormas(catalogoPasaje, respuestas);
		const quintilla = resultados.find((forma) => forma.formaId === 'quintilla');
		const terceto = resultados.find((forma) => forma.formaId === 'terceto-encadenado');

		expect(quintilla?.arquitecturas[0].interpretacionLongitud).toMatchObject({
			tipo: 'repeticion', unidades: 5, versosPorUnidad: 5
		});
		expect(terceto?.arquitecturas[0].interpretacionLongitud).toMatchObject({
			tipo: 'serie', observada: 25
		});
		expect(elegirPregunta(catalogoPasaje, respuestas, 'guiado')?.dimension).toBe(
			'estructura:agrupacion:5'
		);
	});
});

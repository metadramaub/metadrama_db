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
	evidencias: EvidenciaNormativa[]
): HipotesisMetrica {
	return {
		id: `${formaId}:arquitectura`,
		formaId,
		formaSlug: formaId,
		formaNombre,
		formaDefinicion: null,
		gradoEspecificacion: 'especifica',
		arquitecturaId: `${formaId}:arquitectura`,
		arquitecturaSlug: 'principal',
		arquitecturaNombre,
		arquitecturaDescripcion: null,
		arquitecturaPrincipal: true,
		evidencias
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
			evidencia('metro:grupo', 'metro', 'endecasilabos', 'Endecasílabos', { orden: 1 }),
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
		expect(elegirPregunta(catalogo, [], 'guiado')).toMatchObject({
			dimension: 'metro:grupo',
			tipo: 'categoria'
		});
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
});

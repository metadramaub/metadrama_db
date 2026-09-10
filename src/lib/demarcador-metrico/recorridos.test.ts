import { describe, expect, it } from 'vitest';
import {
	crearRespuesta,
	discrepanciasEntre,
	elegirPregunta,
	ordenarFormas,
	rivalesDe,
	veredictoDeHipotesis
} from './motor';
import type {
	CatalogoDemarcador,
	EvidenciaNormativa,
	HipotesisMetrica,
	PreguntaDemarcador
} from './modelo';

function evidencia(
	dimension: string,
	familiaCognitiva: EvidenciaNormativa['familiaCognitiva'],
	valores: Array<{ clave: string; etiqueta: string }>,
	override: Partial<EvidenciaNormativa> = {}
): EvidenciaNormativa {
	return {
		dimension,
		familiaCognitiva,
		etiqueta: override.etiqueta ?? dimension,
		pregunta: override.pregunta ?? dimension,
		ayuda: override.ayuda ?? '',
		tipo: override.tipo ?? 'categoria',
		valores,
		minimo: override.minimo ?? null,
		maximo: override.maximo ?? null,
		modulo: override.modulo ?? null,
		residuo: override.residuo ?? null,
		desplazamientos: override.desplazamientos ?? null,
		reglaLongitud: override.reglaLongitud ?? null,
		modalidad: override.modalidad ?? 'definitoria',
		observabilidad: override.observabilidad ?? 'directa',
		coste: override.coste ?? 0.2,
		orden: override.orden ?? 10,
		fuente: override.fuente ?? 'norma'
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
		id: `${formaId}:${arquitecturaNombre}`,
		formaId,
		formaSlug: formaId,
		formaNombre,
		formaDefinicion: null,
		nivelEstructural: 'estrofa',
		arquitecturaId: `${formaId}:${arquitecturaNombre}`,
		arquitecturaSlug: arquitecturaNombre,
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

const arteMenor = evidencia('metro:grupo', 'metro', [
	{ clave: 'arte_menor', etiqueta: 'Arte menor' }
]);
const medidaUniforme = evidencia('metro:uniformidad', 'metro', [
	{ clave: 'misma_medida', etiqueta: 'Sí, predomina una medida' }
]);
const octosilabos = evidencia('metro:exacto', 'metro', [{ clave: '8', etiqueta: '8 sílabas' }], {
	observabilidad: 'especializada',
	coste: 0.55
});
const consonante = evidencia(
	'rima:tipo',
	'rima',
	[{ clave: 'consonante', etiqueta: 'Consonante' }],
	{ observabilidad: 'especializada' }
);

const catalogo: CatalogoDemarcador = {
	formas: [],
	relaciones: [],
	advertencias: [],
	hipotesis: [
		hipotesis(
			'romance',
			'Romance',
			'Octosilábica',
			[
				arteMenor,
				medidaUniforme,
				octosilabos,
				evidencia('extension:versos', 'extension', [], {
					tipo: 'numero',
					minimo: 4,
					maximo: null
				}),
				evidencia('rima:tipo', 'rima', [{ clave: 'asonante', etiqueta: 'Asonante' }], {
					observabilidad: 'especializada'
				})
			],
			{ nivelEstructural: 'serie' }
		),
		hipotesis('redondilla', 'Redondilla', 'Octosilábica', [
			arteMenor,
			medidaUniforme,
			octosilabos,
			evidencia('extension:versos', 'extension', [], {
				tipo: 'numero',
				minimo: 4,
				maximo: 4
			}),
			consonante
		]),
		hipotesis(
			'soneto',
			'Soneto',
			'Canónica',
			[
				evidencia('metro:grupo', 'metro', [{ clave: 'arte_mayor', etiqueta: 'Arte mayor' }]),
				evidencia('extension:versos', 'extension', [], {
					tipo: 'numero',
					minimo: 14,
					maximo: 14
				}),
				consonante
			],
			{ nivelEstructural: 'composicion', unidadVersos: 14 }
		)
	]
};

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

describe('recorridos de referencia del demarcador', () => {
	it('mantiene grados sin cerrar después de una observación general', () => {
		const resultados = ordenarFormas(catalogo, [
			crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_menor', 'Arte menor')
		]);

		expect(resultados[0].nivel).toBe('candidata');
		expect(resultados.every((resultado) => resultado.nivel === 'candidata')).toBe(true);
	});

	it('sitúa el romance con encaje alto a partir de observaciones accesibles', () => {
		const resultados = ordenarFormas(catalogo, [
			crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_menor', 'Arte menor'),
			crearRespuesta(
				pregunta('metro:uniformidad', 'metro'),
				'misma_medida',
				'Sí, predomina una medida'
			),
			crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 20, '20 versos'),
			crearRespuesta(pregunta('rima:tipo', 'rima'), 'asonante', 'Asonante')
		]);

		expect(resultados[0].formaNombre).toBe('Romance');
		expect(resultados[0].nivel).toBe('alto');
	});

	it('una precisión desconocida no perjudica una identificación bien apoyada', () => {
		const resultados = ordenarFormas(catalogo, [
			crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_menor', 'Arte menor'),
			crearRespuesta(
				pregunta('metro:uniformidad', 'metro'),
				'misma_medida',
				'Sí, predomina una medida'
			),
			crearRespuesta(pregunta('metro:exacto', 'metro'), 'desconocido', 'No sé'),
			crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 20, '20 versos'),
			crearRespuesta(pregunta('rima:tipo', 'rima'), 'asonante', 'Asonante')
		]);

		expect(resultados[0].formaNombre).toBe('Romance');
		expect(resultados[0].nivel).toBe('alto');
	});
});

describe('comprobar una hipótesis contrasta contra sus rivales, no contra el catálogo', () => {
	/**
	 * Cuatro formas de arte menor y medida uniforme, montadas para que los dos criterios **elijan
	 * distinto**: la rima parte el catálogo en dos mitades limpias —dos consonantes contra dos
	 * asonantes— y es la mejor pregunta para identificar; pero sextilla y septilla la responden
	 * igual, así que para comprobar una contra la otra no decide nada y lo que separa es la
	 * extensión. Si el recorrido de comprobación eligiera la rima, sería el guiado con otro nombre.
	 */
	const rimaConsonante = evidencia('rima:tipo', 'rima', [
		{ clave: 'consonante', etiqueta: 'Consonante' }
	]);
	const rimaAsonante = evidencia('rima:tipo', 'rima', [
		{ clave: 'asonante', etiqueta: 'Asonante' }
	]);
	const extensionDe = (minimo: number) =>
		evidencia('extension:versos', 'extension', [], {
			tipo: 'numero',
			minimo,
			modulo: minimo,
			residuo: 0,
			etiqueta: 'Extensión del pasaje'
		});

	const conRelaciones = (relaciones: CatalogoDemarcador['relaciones']): CatalogoDemarcador => ({
		formas: [],
		relaciones,
		advertencias: [],
		hipotesis: [
			hipotesis('sextilla', 'Sextilla', 'Octosílaba', [
				arteMenor,
				medidaUniforme,
				rimaConsonante,
				extensionDe(6)
			]),
			hipotesis('septilla', 'Septilla', 'Octosílaba', [
				arteMenor,
				medidaUniforme,
				rimaConsonante,
				extensionDe(7)
			]),
			hipotesis('romance', 'Romance', 'Octosílabo', [arteMenor, medidaUniforme, rimaAsonante]),
			hipotesis('endecha', 'Endecha', 'Heptasílaba', [arteMenor, medidaUniforme, rimaAsonante])
		]
	});

	const contraste = [
		{
			origenId: 'sextilla',
			destinoId: 'septilla',
			tipo: 'contrasta_con',
			nota: 'Se separan por la extensión de la estrofa.'
		}
	];

	it('identificar elige la pregunta que mejor reparte el catálogo', () => {
		expect(elegirPregunta(conRelaciones([]), [], 'guiado')?.dimension).toBe('rima:tipo');
	});

	it('comprobar elige la que separa la hipótesis de su rival, aunque reparta peor', () => {
		expect(elegirPregunta(conRelaciones(contraste), [], 'hipotesis', 'sextilla')?.dimension).toBe(
			'extension:versos'
		);
	});

	it('la hipótesis entra siempre en su propio contraste', () => {
		const rivales = rivalesDe(conRelaciones(contraste), 'sextilla', []);
		expect(rivales.has('sextilla')).toBe(true);
		expect(rivales.has('septilla')).toBe(true);
	});

	it('dice qué separa dos formas y qué queda por preguntar', () => {
		const catalogo = conRelaciones([]);
		const discrepancias = discrepanciasEntre(
			catalogo.hipotesis[0],
			catalogo.hipotesis[2],
			new Set()
		);
		expect(discrepancias.map((d) => d.dimension)).toEqual(['rima:tipo']);
		expect(discrepancias[0].observable).toBe(true);
		expect(discrepancias[0].respondida).toBe(false);
	});

	const preguntaRima: PreguntaDemarcador = {
		id: 'pregunta:rima:tipo',
		dimension: 'rima:tipo',
		familiaCognitiva: 'rima',
		pregunta: 'rima',
		ayuda: '',
		tipo: 'categoria',
		opciones: [],
		observabilidad: 'directa',
		coste: 0.2,
		utilidad: 1
	};

	it('refuta la hipótesis cuando el pasaje contradice lo que su norma fija', () => {
		const veredicto = veredictoDeHipotesis(conRelaciones(contraste), 'sextilla', [
			crearRespuesta(preguntaRima, 'asonante', 'Asonante')
		]);
		expect(veredicto.estado).toBe('refutada');
		expect(veredicto.contradiceDefinitorias.map((d) => d.dimension)).toEqual(['rima:tipo']);
	});

	it('una vez refutada, la hipótesis deja de gobernar el recorrido', () => {
		const catalogo = conRelaciones(contraste);
		const respuestas = [crearRespuesta(preguntaRima, 'asonante', 'Asonante')];
		// La sextilla se ha caído y las asonantes pasan delante: el recorrido sigue, pero ya no trata
		// sobre ella.
		const ordenadas = ordenarFormas(catalogo, respuestas);
		expect(ordenadas[0].formaId).not.toBe('sextilla');
		expect(elegirPregunta(catalogo, respuestas, 'hipotesis', 'sextilla')).not.toBeNull();
	});

	it('trae la nota del catálogo sobre el contraste declarado', () => {
		const veredicto = veredictoDeHipotesis(conRelaciones(contraste), 'sextilla', []);
		expect(veredicto.nota).toBe('Se separan por la extensión de la estrofa.');
	});
});

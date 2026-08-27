import { beforeEach, describe, expect, it } from 'vitest';
import {
	buildIssues,
	loadMetricCatalog,
	olvidarCatalogoMetricoEnMemoria
} from './catalogo-metrico';
import type { MetricCatalogConfiguration, MetricCatalogDomainData } from '$lib/metrica/catalogo';

/**
 * El aviso de un esquema de rima abierto.
 *
 * Dejar la disposición abierta no es un defecto: es lo que hace una forma general, y el catálogo
 * tiene ocho esquemas así. Solo lo es cuando la arquitectura entera no dice nada más de su rima,
 * y tiene tres maneras de decirlo. Hasta el 10 de agosto de 2026 el aviso miraba una sola —las
 * restricciones del propio esquema— y saltaba en los ocho.
 */

const RASGO_DENSIDAD = 'rasgo-densidad';

function arquitectura(id: string): MetricCatalogConfiguration {
	return {
		arquitectura_id: id,
		forma_id: 'forma',
		slug: id,
		nombre: id,
		descripcion: null,
		principal: true,
		demarcable: true,
		modalidad: 'habitual',
		tipo_rima_id: 'consonante',
		unidad_versos_min: 6,
		unidad_versos_max: 6,
		activo: true,
		orden: 1,
		origen_termino_id: null,
		updated_at: null,
		patrones_metro: 1,
		esquemas_rima: 1
	} as unknown as MetricCatalogConfiguration;
}

function dominio(parcial: Partial<MetricCatalogDomainData>): MetricCatalogDomainData {
	return {
		forms: [],
		configurations: [],
		traditions: [],
		formTraditions: [],
		aliases: [],
		formRelations: [],
		verseModels: [],
		verseSegments: [],
		metricPatterns: [],
		metricPositions: [],
		metricOptions: [],
		rhymePatterns: [],
		rhymePositions: [],
		rhymeLinks: [],
		rhymeRestrictions: [],
		patternCombinations: [],
		sections: [],
		repetitionPatterns: [],
		repetitionPositions: [],
		traits: [{ rasgo_id: RASGO_DENSIDAD, slug: 'densidad_de_rima' }],
		traitValues: [],
		configurationTraits: [],
		choiceGroups: [],
		choiceOptions: [],
		sources: [],
		sourceClaims: [],
		...parcial
	} as unknown as MetricCatalogDomainData;
}

const abierto = {
	esquema_rima_id: 'abierto',
	arquitectura_id: 'arq',
	tipo_secuencia: 'abierta'
};

function avisosDeRima(domain: MetricCatalogDomainData) {
	return buildIssues({ forms: [], configurations: [arquitectura('arq')], domain })
		.filter((issue) => issue.code === 'patron_rima_sin_regla')
		.map((issue) => issue.message);
}

describe('el aviso de un esquema de rima abierto', () => {
	it('salta cuando la arquitectura no dice nada más de su rima', () => {
		expect(avisosDeRima(dominio({ rhymePatterns: [abierto] as never }))).toHaveLength(1);
	});

	it('calla cuando el esquema declara restricciones', () => {
		const domain = dominio({
			rhymePatterns: [abierto] as never,
			rhymeRestrictions: [
				{ restriccion_id: 'r', esquema_rima_id: 'abierto', tipo: 'numero_clases' }
			] as never
		});
		expect(avisosDeRima(domain)).toEqual([]);
	});

	it('calla cuando la arquitectura declara su densidad de rima', () => {
		// El caso de las seis sextillas y sextetos de disposición libre: la norma no fija el orden
		// de las rimas, pero sí dice que riman todos los versos.
		const domain = dominio({
			rhymePatterns: [abierto] as never,
			configurationTraits: [
				{ arquitectura_id: 'arq', rasgo_id: RASGO_DENSIDAD, valor_id: 'total' }
			] as never
		});
		expect(avisosDeRima(domain)).toEqual([]);
	});

	it('calla cuando convive con un esquema concreto, del que la rima se calcula', () => {
		const domain = dominio({
			rhymePatterns: [
				abierto,
				{
					esquema_rima_id: 'ababcc',
					arquitectura_id: 'arq',
					tipo_secuencia: 'secuencia'
				}
			] as never,
			rhymePositions: [{ esquema_rima_id: 'ababcc' }] as never
		});
		expect(avisosDeRima(domain)).toEqual([]);
	});

	it('sigue saltando en un esquema ordenado sin posiciones, que es el otro caso del aviso', () => {
		const domain = dominio({
			rhymePatterns: [
				{ esquema_rima_id: 'cerrado', arquitectura_id: 'arq', tipo_secuencia: 'secuencia' }
			] as never
		});
		expect(avisosDeRima(domain)).toHaveLength(1);
	});
});

/**
 * El catálogo se lee de memoria mientras su revisión no cambie.
 *
 * Construirlo son unas treinta consultas, cuatro de ellas vistas derivadas que recorren el catálogo
 * entero: medidas por PostgREST iban entre 750 y 1.500 ms cada una y llegaron a dar un 500 por
 * `statement timeout`. Como solo cambia por migración, basta con preguntar por la revisión.
 *
 * Lo que se fija aquí es justo eso: que con la misma revisión **no se vuelve a preguntar**, que con
 * otra sí, y que el sandbox del editor —que cambia cada vez que alguien guarda— nunca se guarda.
 */
function baseDeMentira(revision: number, llamadas: Map<string, number>) {
	const from = (tabla: string) => {
		llamadas.set(tabla, (llamadas.get(tabla) ?? 0) + 1);
		const constructor: Record<string, unknown> = {
			select: () => constructor,
			order: () => constructor,
			eq: () => constructor,
			not: () => constructor,
			in: () => constructor,
			limit: () => constructor,
			is: () => constructor,
			gt: () => constructor,
			filter: () => constructor,
			maybeSingle: () =>
				Promise.resolve({ data: { revision, modelo_version: 99 }, error: null }),
			then: (resolver: (valor: unknown) => unknown) => resolver({ data: [], error: null })
		};
		return constructor;
	};
	return { from } as unknown as App.Locals['supabase'];
}

describe('el catálogo se guarda en memoria por su revisión', () => {
	beforeEach(() => olvidarCatalogoMetricoEnMemoria());

	it('no vuelve a preguntar por el catálogo si la revisión no ha cambiado', async () => {
		const llamadas = new Map<string, number>();
		await loadMetricCatalog(baseDeMentira(4400, llamadas));
		await loadMetricCatalog(baseDeMentira(4400, llamadas));
		await loadMetricCatalog(baseDeMentira(4400, llamadas));

		// La revisión se pregunta siempre: es lo que mantiene honesta la caché.
		expect(llamadas.get('catalogo_metrico_estado')).toBe(3);
		// El catálogo, una sola vez.
		expect(llamadas.get('formas_metricas')).toBe(1);
		expect(llamadas.get('opciones_eleccion_metrica')).toBe(1);
		expect(llamadas.get('grupos_eleccion_metrica_resueltos')).toBe(1);
		expect(llamadas.get('arquitecturas_reglas_longitud')).toBe(1);
	});

	it('reconstruye cuando la revisión cambia', async () => {
		const llamadas = new Map<string, number>();
		await loadMetricCatalog(baseDeMentira(4400, llamadas));
		await loadMetricCatalog(baseDeMentira(4401, llamadas));

		expect(llamadas.get('formas_metricas')).toBe(2);
		expect(llamadas.get('opciones_eleccion_metrica')).toBe(2);
	});

	it('nunca guarda el sandbox del editor, que cambia cada vez que alguien escribe', async () => {
		const llamadas = new Map<string, number>();
		await loadMetricCatalog(baseDeMentira(4400, llamadas));
		await loadMetricCatalog(baseDeMentira(4400, llamadas));

		expect(llamadas.get('anotaciones_metricas')).toBe(2);
		expect(llamadas.get('anotacion_realizaciones')).toBe(2);
		expect(llamadas.get('anotacion_elecciones_resueltas')).toBe(2);
	});
});

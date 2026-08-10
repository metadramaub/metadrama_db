import { describe, expect, it } from 'vitest';
import { buildIssues } from './catalogo-metrico';
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
		estado_revision: 'revisada',
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

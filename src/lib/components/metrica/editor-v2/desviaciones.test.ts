import { describe, expect, it } from 'vitest';
import {
	contradiceLaRelacion,
	fijarValorObservado,
	medidaDeLaNorma,
	notaDelMetroObservado,
	opcionesObservadas,
	valorObservado
} from './desviaciones';
import type { MetricCatalogDomainData } from '$lib/metrica/catalogo';
import type { MetricDeviationDraft } from './sequence-draft';

/**
 * Lo observado en una desviación se guarda en la columna de su dimensión, y lo que se le enseña
 * al editor —cuántas sílabas se aparta de la norma— se calcula en el momento y no se almacena.
 * Estas eran las reglas que vivían dentro de un componente de mil cuatrocientas líneas.
 */

const OCTOSILABO = 'metro-8';
const HEPTASILABO = 'metro-7';

function dominio(parcial: Partial<MetricCatalogDomainData> = {}): MetricCatalogDomainData {
	return {
		verseModels: [
			{ metro_id: OCTOSILABO, nombre: 'Octosílabo', silabas: 8 },
			{ metro_id: HEPTASILABO, nombre: 'Heptasílabo', silabas: 7 }
		],
		metricPatterns: [{ esquema_metrico_id: 'em', arquitectura_id: 'arq' }],
		metricPositions: [{ esquema_metrico_id: 'em', metro_id: OCTOSILABO }],
		rhymePatterns: [],
		repetitionPatterns: [],
		traitValues: [],
		...parcial
	} as unknown as MetricCatalogDomainData;
}

function desviacion(parcial: Partial<MetricDeviationDraft> = {}): MetricDeviationDraft {
	return {
		dimension: 'metro',
		relacion_norma: null,
		metro_observado_id: null,
		esquema_rima_observado_id: null,
		seccion_observada_id: null,
		repeticion_observada_id: null,
		valor_rasgo_observado_id: null,
		...parcial
	} as unknown as MetricDeviationDraft;
}

describe('la columna de lo observado', () => {
	it('guarda el valor en la que corresponde a su dimensión', () => {
		const d = desviacion({ dimension: 'rima' });
		fijarValorObservado(d, 'esquema-abba');
		expect(d.esquema_rima_observado_id).toBe('esquema-abba');
		expect(valorObservado(d)).toBe('esquema-abba');
	});

	it('limpia las demás al cambiar de dimensión, que es lo que la base exige', () => {
		const d = desviacion({ dimension: 'metro' });
		fijarValorObservado(d, OCTOSILABO);
		d.dimension = 'estructura';
		fijarValorObservado(d, 'seccion-mudanza');
		expect(d.metro_observado_id).toBeNull();
		expect(d.seccion_observada_id).toBe('seccion-mudanza');
	});

	it('vacía la columna cuando se borra el valor', () => {
		const d = desviacion({ dimension: 'metro', metro_observado_id: OCTOSILABO });
		fijarValorObservado(d, '');
		expect(valorObservado(d)).toBe('');
	});
});

describe('la medida que la norma fija', () => {
	it('la da cuando la arquitectura usa un solo metro', () => {
		expect(medidaDeLaNorma(dominio(), 'arq')).toEqual({ silabas: 8, nombre: 'Octosílabo' });
	});

	it('no la da cuando hay más de uno: entonces no hay una cifra que comparar', () => {
		const domain = dominio({
			metricPositions: [
				{ esquema_metrico_id: 'em', metro_id: OCTOSILABO },
				{ esquema_metrico_id: 'em', metro_id: HEPTASILABO }
			]
		} as Partial<MetricCatalogDomainData>);
		expect(medidaDeLaNorma(domain, 'arq')).toBeNull();
	});

	it('no la da sin arquitectura elegida', () => {
		expect(medidaDeLaNorma(dominio(), null)).toBeNull();
	});
});

describe('lo que se le enseña al editor', () => {
	const domain = dominio();
	const norma = medidaDeLaNorma(domain, 'arq');

	it('dice cuántas sílabas se aparta, en singular cuando es una', () => {
		const d = desviacion({ metro_observado_id: HEPTASILABO });
		expect(notaDelMetroObservado(domain, d, norma)).toBe(
			'1 sílaba menos que la norma (Octosílabo)'
		);
	});

	it('avisa cuando el metro observado coincide con la norma', () => {
		const d = desviacion({ metro_observado_id: OCTOSILABO });
		expect(notaDelMetroObservado(domain, d, norma)).toContain('coincide con la norma');
	});

	it('sin norma que comparar dice solo la medida', () => {
		const d = desviacion({ metro_observado_id: HEPTASILABO });
		expect(notaDelMetroObservado(domain, d, null)).toBe('7 sílabas');
	});

	it('calla en las dimensiones que no son el metro', () => {
		const d = desviacion({ dimension: 'rima', esquema_rima_observado_id: 'x' });
		expect(notaDelMetroObservado(domain, d, norma)).toBe('');
	});
});

describe('la contradicción entre lo declarado y lo observado', () => {
	const domain = dominio();
	const norma = medidaDeLaNorma(domain, 'arq');

	it('la detecta cuando se declara «menor» y el verso es más largo', () => {
		const d = desviacion({ metro_observado_id: OCTOSILABO, relacion_norma: 'menor_que_norma' });
		expect(contradiceLaRelacion(domain, d, norma)).toBe(true);
	});

	it('no la ve cuando el verso es de verdad más corto', () => {
		const d = desviacion({ metro_observado_id: HEPTASILABO, relacion_norma: 'menor_que_norma' });
		expect(contradiceLaRelacion(domain, d, norma)).toBe(false);
	});

	it('no juzga sin una norma con la que comparar', () => {
		const d = desviacion({ metro_observado_id: OCTOSILABO, relacion_norma: 'menor_que_norma' });
		expect(contradiceLaRelacion(domain, d, null)).toBe(false);
	});
});

describe('las opciones de lo observado', () => {
	it('vienen ordenadas y sin las inactivas', () => {
		const domain = dominio({
			rhymePatterns: [
				{ esquema_rima_id: 'b', arquitectura_id: 'arq', nombre: 'Cruzada' },
				{ esquema_rima_id: 'a', arquitectura_id: 'arq', nombre: 'Abrazada' },
				{ esquema_rima_id: 'z', arquitectura_id: 'arq', nombre: 'Retirada', activo: false }
			]
		} as Partial<MetricCatalogDomainData>);
		expect(opcionesObservadas(domain, 'rima', 'arq', []).map((o) => o.label)).toEqual([
			'Abrazada',
			'Cruzada'
		]);
	});

	it('deja fuera las de otra arquitectura', () => {
		const domain = dominio({
			rhymePatterns: [{ esquema_rima_id: 'a', arquitectura_id: 'otra', nombre: 'Ajena' }]
		} as Partial<MetricCatalogDomainData>);
		expect(opcionesObservadas(domain, 'rima', 'arq', [])).toEqual([]);
	});
});

import { describe, expect, it } from 'vitest';
import { METRIC_CATALOG_RESOURCES, type MetricCatalogDomainData } from '$lib/metrica/catalogo';
import {
	disposicionesDeQuebrados,
	disposicionCompatible,
	medidasDeLosQuebrados
} from './disposiciones-quebrados';
import { isPartialPositionalSelection } from './positional-options';

function catalogo(versos = 6) {
	const d = Object.fromEntries(
		METRIC_CATALOG_RESOURCES.map((k) => [k, []])
	) as unknown as MetricCatalogDomainData;
	d.forms = [];
	d.configurations = [];
	d.verseModels = [4, 5, 8].map((n) => ({ metro_id: `m${n}`, silabas: n }));
	for (const [indice, posiciones] of (versos === 6
		? [
				[3, 6],
				[2, 5]
			]
		: [[1], [2, 5]]
	).entries()) {
		const id = `esquema${indice}`;
		d.metricPatterns.push({
			arquitectura_id: 'arquitectura',
			esquema_metrico_id: id,
			tipo_secuencia: 'secuencia',
			created_at: `2026-0${indice + 1}-01`
		});
		d.metricOptions.push(
			...[4, 5, 8].map((n) => ({
				esquema_metrico_id: id,
				metro_id: `m${n}`,
				rol: n === 8 ? 'dominante' : 'quebrado'
			}))
		);
		for (let n = 1; n <= versos; n++) {
			const silabas = posiciones.includes(n)
				? versos === 5 && indice === 0
					? [8, 4, 5]
					: [4, 5]
				: [8];
			d.metricPositions.push(
				...silabas.map((m) => ({ esquema_metrico_id: id, posicion: n, metro_id: `m${m}` }))
			);
		}
	}
	return d;
}
const elegida = (posicion: number, silabas: number) => ({
	posicion_unidad: posicion,
	metro_silabas: silabas
});

describe('disposiciones completas de quebrados', () => {
	it('lee las dos sextillas del catálogo sin mezclar sus cuatro posiciones', () => {
		const d = disposicionesDeQuebrados(catalogo(), 'arquitectura');
		expect(d.map((p) => p.posiciones)).toEqual([
			[3, 6],
			[2, 5]
		]);
		expect(disposicionCompatible(d, [3, 6])?.posiciones).toEqual([3, 6]);
		expect(disposicionCompatible(d, [2])?.posiciones).toEqual([2, 5]);
		expect(disposicionCompatible(d, [2, 6])).toBeNull();
	});
	it('conserva las quintillas plenas e iniciales y añade la pareja 2/5', () => {
		const d = disposicionesDeQuebrados(catalogo(5), 'arquitectura');
		expect(d.map((p) => p.posiciones)).toEqual([[], [1], [2, 5]]);
		expect(disposicionCompatible(d, [])?.posiciones).toEqual([]);
		expect(medidasDeLosQuebrados(d, [])).toEqual([8, 8, 8, 8, 8]);
	});
	it('lee las respuestas antiguas y las nuevas sin conservar barras del otro patrón', () => {
		const d = disposicionesDeQuebrados(catalogo(), 'arquitectura');
		expect(medidasDeLosQuebrados(d, [elegida(3, 4), elegida(6, 5)])).toEqual([8, 8, 4, 8, 8, 5]);
		expect(medidasDeLosQuebrados(d, [elegida(2, 4), elegida(5, 5)])).toEqual([8, 4, 8, 8, 5, 8]);
	});
	it('no inventa medidas pendientes y usa la misma pauta inicial que el selector', () => {
		const d = disposicionesDeQuebrados(catalogo(), 'arquitectura');
		expect(medidasDeLosQuebrados(d, [elegida(2, 4)])).toEqual([8, 4, 8, 8, null, 8]);
		expect(medidasDeLosQuebrados(d, [])).toEqual([8, 8, null, 8, 8, null]);
	});
	it('antes de migrar mantiene el control actual de las arquitecturas con un solo esquema', () => {
		const d = catalogo();
		d.metricPatterns = d.metricPatterns.slice(0, 1);
		expect(disposicionesDeQuebrados(d, 'arquitectura')).toEqual([]);
	});
	it('elegir una disposición deja pendientes solo sus quebrados, aun sin medir ninguno', () => {
		const s = disposicionesDeQuebrados(catalogo(), 'arquitectura');
		expect(medidasDeLosQuebrados(s, [], s[0].id)).toEqual([8, 8, null, 8, 8, null]);
		expect(medidasDeLosQuebrados(s, [], s[1].id)).toEqual([8, null, 8, 8, null, 8]);
		const q = disposicionesDeQuebrados(catalogo(5), 'arquitectura');
		expect(medidasDeLosQuebrados(q, [], q[1].id)).toEqual([null, 8, 8, 8, 8]);
		expect(medidasDeLosQuebrados(q, [], q[2].id)).toEqual([8, null, 8, 8, null]);
		expect(medidasDeLosQuebrados(q, [elegida(2, 4)], q[2].id)).toEqual([8, 4, 8, 8, null]);
	});
	it('una licencia no obliga a medir todos los versos aunque todos sean candidatos', () => {
		const opciones = Array.from({ length: 8 }, (_, i) =>
			[4, 5].map((m) => ({ posicion_unidad: i + 1, metro_silabas: m, metro_base_silabas: 8 }))
		).flat();
		expect(
			isPartialPositionalSelection(
				{ define_norma: false, selecciones_min: 0, selecciones_max: 7 },
				opciones,
				8
			)
		).toBe(true);
	});
});

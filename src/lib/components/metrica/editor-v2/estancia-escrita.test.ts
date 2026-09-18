import { describe, expect, it } from 'vitest';
import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import { escribirEstancia, leerEstanciaEscrita, repartoDeLosCortes } from './estancia-escrita';
import type { ParteAsignable } from './reparto-estancia';

function parte(slug: string, contenedora = false, ancestros: string[] = []): ParteAsignable {
	const seccion = { seccion_id: `s-${slug}`, slug, nombre: slug } as MetricCatalogDomainRow;
	return {
		id: `s-${slug}`,
		label: slug,
		seccion,
		contenedora,
		ancestros: ancestros.map((a) => ({ seccion_id: `s-${a}`, slug: a }) as MetricCatalogDomainRow)
	};
}
const partes = [
	parte('fronte', true),
	parte('primer_pie', false, ['fronte']),
	parte('segundo_pie', false, ['fronte']),
	parte('eslabon'),
	parte('sirima')
];

describe('leer la estancia escrita', () => {
	it('abC.abC:c.dD · dos pies, eslabón y sirima', () => {
		const r = leerEstanciaEscrita('abC.abC:c.dD', partes, 9);
		expect(r.error).toBeNull();
		expect(r.letras).toBe('abCabCcdD');
		expect(r.reparto).toEqual([
			's-primer_pie', 's-primer_pie', 's-primer_pie',
			's-segundo_pie', 's-segundo_pie', 's-segundo_pie',
			's-eslabon', 's-sirima', 's-sirima'
		]);
	});

	it('abCabC:cdD · fronte entera, sin pies ni eslabón', () => {
		const r = leerEstanciaEscrita('abCabC:cdD', partes);
		expect(r.error).toBeNull();
		expect(r.reparto.slice(0, 6).every((id) => id === 's-fronte')).toBe(true);
		expect(r.reparto.slice(6).every((id) => id === 's-sirima')).toBe(true);
	});

	it('abCabCcdD · sin dos puntos, sin partes', () => {
		const r = leerEstanciaEscrita('abCabCcdD', partes);
		expect(r.error).toBeNull();
		expect(r.reparto.every((id) => id === null)).toBe(true);
	});

	it('admite espacios y no admite otros signos', () => {
		expect(leerEstanciaEscrita('abC abC : c dD', partes).letras).toBe('abCabCcdD');
		expect(leerEstanciaEscrita('abC|abC', partes).error).toMatch(/Solo letras/);
	});

	it('avisa cuando el número de letras no es el de la estancia', () => {
		expect(leerEstanciaEscrita('abC.abC:c.dD', partes, 13).error).toMatch(/13 versos y has escrito 9/);
	});

	it('el eslabón es un solo verso', () => {
		expect(leerEstanciaEscrita('abC.abC:cc.dD', partes).error).toMatch(/un solo verso/);
	});
});

describe('escribir la estancia', () => {
	it('vuelve a la notación desde el reparto', () => {
		const r = leerEstanciaEscrita('abC.abC:c.dD', partes);
		expect(escribirEstancia(r.letras, r.reparto, partes)).toBe('abC.abC:c.dD');
		const sinPies = leerEstanciaEscrita('abCabC:cdD', partes);
		expect(escribirEstancia(sinPies.letras, sinPies.reparto, partes)).toBe('abCabC:cdD');
	});

	it('sin partes son solo letras; con hueco o desorden no se escribe', () => {
		expect(escribirEstancia('abab', [null, null, null, null], partes)).toBe('abab');
		expect(escribirEstancia('abab', ['s-sirima', 's-sirima', 's-fronte', 's-fronte'], partes)).toBeNull();
		expect(escribirEstancia('abab', ['s-fronte', null, 's-sirima', 's-sirima'], partes)).toBeNull();
	});
});

describe('el reparto que dibujan los cortes', () => {
	const f = 's-fronte', p1 = 's-primer_pie', p2 = 's-segundo_pie', e = 's-eslabon', si = 's-sirima';

	it('ninguno: sin partes', () => {
		expect(repartoDeLosCortes(4, [], partes)).toEqual([null, null, null, null]);
	});

	it('uno: fronte y sirima', () => {
		expect(repartoDeLosCortes(5, [2], partes)).toEqual([f, f, f, si, si]);
	});

	it('dos con un verso en medio: fronte, eslabón y sirima', () => {
		expect(repartoDeLosCortes(6, [2, 3], partes)).toEqual([f, f, f, e, si, si]);
	});

	it('dos con más de un verso en medio: los dos pies y la sirima', () => {
		expect(repartoDeLosCortes(6, [1, 3], partes)).toEqual([p1, p1, p2, p2, si, si]);
	});

	it('tres: pies, eslabón y sirima', () => {
		expect(repartoDeLosCortes(9, [2, 5, 6], partes)).toEqual([p1, p1, p1, p2, p2, p2, e, si, si]);
	});

	it('más de tres no caben', () => {
		expect(repartoDeLosCortes(9, [1, 2, 3, 4], partes).every((id) => id === null)).toBe(true);
	});
});

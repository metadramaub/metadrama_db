import { describe, expect, it } from 'vitest';
import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import type { MetricUnitDraft } from './editor-model';
import { reflowMetricUnits } from './editor-model';
import {
	aplicarReparto,
	avisosDelReparto,
	cuelgaDeUnReparto,
	partesAsignables,
	repartoDeLaUnidad,
	replicarReparto,
	seReparteVersoAVerso,
	tramosDelReparto
} from './reparto-estancia';

/** Las secciones de la estancia de la canción tal como están en el catálogo. */
function seccion(
	id: string,
	padre: string | null,
	orden: number,
	rep: [number, number | null],
	versos: [number, number | null],
	extra: Partial<MetricCatalogDomainRow> = {}
): MetricCatalogDomainRow {
	return {
		seccion_id: id,
		seccion_padre_id: padre,
		slug: id,
		nombre: id[0].toUpperCase() + id.slice(1).replace('_', ' '),
		tipo_seccion: id,
		orden,
		repeticiones_min: rep[0],
		repeticiones_max: rep[1],
		versos_min: versos[0],
		versos_max: versos[1],
		primera_realizacion_define_patron: false,
		...extra
	};
}

const estancia = seccion('estancia', null, 1, [3, null], [9, 15], {
	primera_realizacion_define_patron: true
});
const fronte = seccion('fronte', 'estancia', 1, [0, 1], [4, 14]);
const primerPie = seccion('primer_pie', 'fronte', 1, [0, 1], [2, 9]);
const segundoPie = seccion('segundo_pie', 'fronte', 2, [0, 1], [2, 9]);
const eslabon = seccion('eslabon', 'estancia', 2, [0, 1], [1, 1]);
const sirima = seccion('sirima', 'estancia', 3, [0, 1], [1, 11]);
const remate = seccion('remate', null, 2, [0, 1], [1, 15]);
const sections = [estancia, fronte, primerPie, segundoPie, eslabon, sirima, remate];

function unidad(
	id: string,
	padre: string | null,
	seccion_id: string | null,
	v_ini: number,
	v_fin: number,
	orden = 1
): MetricUnitDraft {
	return { realizacion_id: id, realizacion_padre_id: padre, seccion_id, orden, v_ini, v_fin, etiqueta: '', observaciones: '' };
}

/** Tres estancias de nueve, sin partes todavía. */
const base: MetricUnitDraft[] = [
	unidad('cancion', null, null, 1, 27, 1),
	unidad('e1', 'cancion', 'estancia', 1, 9, 2),
	unidad('e2', 'cancion', 'estancia', 10, 18, 3),
	unidad('e3', 'cancion', 'estancia', 19, 27, 4)
];

const abCabCcdD: (string | null)[] = [
	'primer_pie', 'primer_pie', 'primer_pie',
	'segundo_pie', 'segundo_pie', 'segundo_pie',
	'eslabon',
	'sirima', 'sirima'
];

describe('qué unidades se reparten verso a verso', () => {
	it('la estancia de la canción sí: fija el patrón y tiene partes', () => {
		expect(seReparteVersoAVerso(sections, estancia)).toBe(true);
	});

	it('el remate no: no tiene partes', () => {
		expect(seReparteVersoAVerso(sections, remate)).toBe(false);
	});

	it('la fronte y los piedi cuelgan de un reparto; el remate no', () => {
		expect(cuelgaDeUnReparto(sections, fronte)).toBe(true);
		expect(cuelgaDeUnReparto(sections, primerPie)).toBe(true);
		expect(cuelgaDeUnReparto(sections, remate)).toBe(false);
	});

	it('las partes asignables son todas las del árbol, en el orden del catálogo y con su camino', () => {
		expect(partesAsignables(sections, estancia).map((parte) => [parte.id, parte.label, parte.contenedora])).toEqual([
			['fronte', 'Fronte', true],
			['primer_pie', 'Fronte · Primer pie', false],
			['segundo_pie', 'Fronte · Segundo pie', false],
			['eslabon', 'Eslabon', false],
			['sirima', 'Sirima', false]
		]);
	});
});

describe('la fronte sin pies', () => {
	const soloFronte: (string | null)[] = ['fronte', 'fronte', 'fronte', 'fronte', 'fronte', 'fronte', 'eslabon', 'sirima', 'sirima'];

	it('se guarda como una realización de fronte sin hijas, y se vuelve a leer igual', () => {
		const units = aplicarReparto(base, sections, base[1], soloFronte);
		const frontes = units.filter((u) => u.seccion_id === 'fronte');
		expect(frontes).toHaveLength(1);
		expect([frontes[0].v_ini, frontes[0].v_fin]).toEqual([1, 6]);
		expect(units.some((u) => u.seccion_id === 'primer_pie')).toBe(false);
		expect(repartoDeLaUnidad(units, sections, base[1])).toEqual(soloFronte);
		expect(avisosDelReparto(sections, partesAsignables(sections, estancia), soloFronte)).toEqual([]);
	});

	it('un pie dentro de la fronte cuelga de ella y no la duplica', () => {
		const mixto: (string | null)[] = ['fronte', 'fronte', 'fronte', 'segundo_pie', 'segundo_pie', 'segundo_pie', 'eslabon', 'sirima', 'sirima'];
		const units = aplicarReparto(base, sections, base[1], mixto);
		const frontes = units.filter((u) => u.seccion_id === 'fronte');
		expect(frontes).toHaveLength(1);
		expect([frontes[0].v_ini, frontes[0].v_fin]).toEqual([1, 6]);
		const pie = units.find((u) => u.seccion_id === 'segundo_pie')!;
		expect(pie.realizacion_padre_id).toBe(frontes[0].realizacion_id);
		expect(repartoDeLaUnidad(units, sections, base[1])).toEqual(mixto);
		expect(avisosDelReparto(sections, partesAsignables(sections, estancia), mixto)).toEqual([]);
	});
});

describe('del reparto a las realizaciones y vuelta', () => {
	it('crea la fronte una vez y una realización por tramo, con los versos absolutos', () => {
		const units = aplicarReparto(base, sections, base[1], abCabCcdD);
		const hijas = units.filter((unit) => !base.some((b) => b.realizacion_id === unit.realizacion_id));
		const porSeccion = Object.fromEntries(
			hijas.map((unit) => [unit.seccion_id, [unit.v_ini, unit.v_fin]])
		);
		expect(porSeccion).toEqual({
			fronte: [1, 6],
			primer_pie: [1, 3],
			segundo_pie: [4, 6],
			eslabon: [7, 7],
			sirima: [8, 9]
		});
		const frontePadre = hijas.find((unit) => unit.seccion_id === 'fronte')!;
		expect(hijas.find((unit) => unit.seccion_id === 'primer_pie')!.realizacion_padre_id).toBe(
			frontePadre.realizacion_id
		);
		expect(frontePadre.realizacion_padre_id).toBe('e1');
		expect(hijas.find((unit) => unit.seccion_id === 'sirima')!.realizacion_padre_id).toBe('e1');
	});

	it('leer el reparto de lo aplicado devuelve lo mismo', () => {
		const units = aplicarReparto(base, sections, base[1], abCabCcdD);
		expect(repartoDeLaUnidad(units, sections, units.find((u) => u.realizacion_id === 'e1')!)).toEqual(
			abCabCcdD
		);
	});

	it('aplicar otra vez retira las partes anteriores', () => {
		const conFronte = aplicarReparto(base, sections, base[1], abCabCcdD);
		const sinNada = aplicarReparto(conFronte, sections, base[1], Array(9).fill(null));
		expect(sinNada).toHaveLength(base.length);
	});

	it('replica el reparto de la modelo en las demás estancias, con su desplazamiento', () => {
		const units = replicarReparto(aplicarReparto(base, sections, base[1], abCabCcdD), sections, base[1]);
		const e3 = units.find((u) => u.realizacion_id === 'e3')!;
		expect(repartoDeLaUnidad(units, sections, e3)).toEqual(abCabCcdD);
		const sirimaDeE3 = units.find(
			(u) => u.seccion_id === 'sirima' && u.realizacion_padre_id === 'e3'
		)!;
		expect([sirimaDeE3.v_ini, sirimaDeE3.v_fin]).toEqual([26, 27]);
	});

	it('el reflujo respeta la extensión de la estancia y arrastra sus partes', () => {
		const repartidas = replicarReparto(aplicarReparto(base, sections, base[1], abCabCcdD), sections, base[1]);
		// La segunda estancia empieza en 10; si la modelo creciera a 10 versos, todo se corre uno.
		const crecidas = repartidas.map((u) =>
			u.seccion_id === 'estancia' ? { ...u, v_fin: u.v_ini + 9 } : u
		);
		const reflowed = reflowMetricUnits(crecidas, sections, 1);
		const e2 = reflowed.find((u) => u.realizacion_id === 'e2')!;
		expect([e2.v_ini, e2.v_fin]).toEqual([11, 20]);
		const pie1DeE2 = reflowed.find(
			(u) => u.seccion_id === 'primer_pie' && reflowed.find((p) => p.realizacion_id === u.realizacion_padre_id)?.realizacion_padre_id === 'e2'
		)!;
		expect([pie1DeE2.v_ini, pie1DeE2.v_fin]).toEqual([11, 13]);
	});

	it('los tramos se leen por contigüidad', () => {
		expect(tramosDelReparto(['a', 'a', null, 'a', 'b'])).toEqual([
			{ parteId: 'a', desde: 0, hasta: 1 },
			{ parteId: 'a', desde: 3, hasta: 3 },
			{ parteId: 'b', desde: 4, hasta: 4 }
		]);
	});
});

describe('lo que avisa el reparto', () => {
	const partes = partesAsignables(sections, estancia);

	it('un reparto bien formado no avisa de nada', () => {
		expect(avisosDelReparto(sections, partes, abCabCcdD)).toEqual([]);
	});

	it('ni una estancia sin partes', () => {
		expect(avisosDelReparto(sections, partes, Array(9).fill(null))).toEqual([]);
	});

	it('una fronte con un solo pie', () => {
		const reparto: (string | null)[] = ['primer_pie', 'primer_pie', 'primer_pie', 'sirima', 'sirima', 'sirima', 'sirima', 'sirima', 'sirima'];
		// Los pies son opcionales desde el 18 de septiembre: lo que avisa es la extensión.
		expect(avisosDelReparto(sections, partes, reparto)).toEqual([
			'«Fronte» tiene 3 versos y admite de 4 a 14.'
		]);
	});

	it('una parte partida en dos, y una fuera de orden', () => {
		const reparto: (string | null)[] = ['sirima', 'primer_pie', 'primer_pie', 'segundo_pie', 'segundo_pie', 'sirima', 'sirima', 'sirima', 'sirima'];
		expect(avisosDelReparto(sections, partes, reparto)).toContain('«Sirima» aparece en dos tramos separados.');
		expect(avisosDelReparto(sections, partes, reparto)).toContain('«Fronte · Primer pie» va antes de lo que el catálogo ordena.');
	});

	it('un pie de un verso, y un hueco', () => {
		const reparto: (string | null)[] = ['primer_pie', 'segundo_pie', 'segundo_pie', null, 'sirima', 'sirima', 'sirima', 'sirima', 'sirima'];
		const avisos = avisosDelReparto(sections, partes, reparto);
		expect(avisos).toContain('«Fronte · Primer pie» tiene 1 verso y admite de 2 a 9.');
		expect(avisos).toContain('Hay versos sin parte entre dos partes.');
	});
});

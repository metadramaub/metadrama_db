/**
 * El reparto verso a verso de una unidad cuyas partes son opcionales y de extensión libre.
 *
 * La estancia de la canción es la única unidad del catálogo que **fija el patrón con su primera
 * realización** y que además tiene partes dentro —fronte con dos piedi, eslabón, sirima— que pueden
 * no aparecer y que se reparten los versos como el poeta quiso. El árbol de secciones con que el
 * editor dibuja las demás formas no le sirve: ahí una unidad con partes mide la suma de sus partes,
 * y al decir «sí» a la fronte una estancia de quince versos se encogía a los cuatro del mínimo de
 * dos piedi. Y además obligaba a repartir la extensión parte a parte, lejos de la fila en que se
 * leen la medida y la rima de cada verso.
 *
 * Aquí la estancia manda: mide lo que el editor diga, y cada verso dice a qué parte pertenece. De
 * ese reparto salen las realizaciones de siempre —`fronte`, `primer_pie`, `segundo_pie`, `eslabon`,
 * `sirima`— y se guardan como siempre en `anotacion_realizaciones`: lo que cambia es la pantalla,
 * no el dato. Las demás estancias copian el reparto de la modelo, igual que copian medida y rima.
 */

import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import {
	childrenOfSection,
	sectionId,
	sectionLabel,
	sectionParentId,
	sectionVerseMaximum,
	sectionVerseMinimum,
	type MetricUnitDraft
} from './editor-model';

/**
 * Una parte que se puede asignar a un verso, con su camino.
 *
 * Son las hojas del árbol de secciones **y también sus nodos intermedios**: la fronte se puede
 * marcar entera, sin decir dónde acaba un pie y empieza el otro, porque puede verse clara la
 * fronte y no sus pies. Un verso asignado a la fronte cuelga de ella directamente; uno asignado
 * a un pie cuelga del pie, y el pie de la fronte.
 */
export type ParteAsignable = {
	id: string;
	label: string;
	/** De la raíz hacia abajo, sin la propia parte: la fronte para un pie. */
	ancestros: MetricCatalogDomainRow[];
	seccion: MetricCatalogDomainRow;
	/** Si tiene partes dentro que también se pueden asignar. */
	contenedora: boolean;
};

/** Una parte por verso de la unidad, o nulo si el verso no pertenece a ninguna. */
export type Reparto = (string | null)[];

/** Si una unidad se reparte verso a verso: fija el patrón y tiene partes dentro. */
export function seReparteVersoAVerso(
	sections: MetricCatalogDomainRow[],
	section: MetricCatalogDomainRow | null
): boolean {
	if (!section || section.primera_realizacion_define_patron !== true) return false;
	return childrenOfSection(sections, sectionId(section)).length > 0;
}

/** Si una sección cuelga, a cualquier profundidad, de una que se reparte verso a verso. */
export function cuelgaDeUnReparto(
	sections: MetricCatalogDomainRow[],
	section: MetricCatalogDomainRow
): boolean {
	let parentId = sectionParentId(section);
	while (parentId) {
		const parent = sections.find((candidate) => sectionId(candidate) === parentId);
		if (!parent) return false;
		if (seReparteVersoAVerso(sections, parent)) return true;
		parentId = sectionParentId(parent);
	}
	return false;
}

/** Las partes del árbol de una sección, en el orden del catálogo y con su camino. */
export function partesAsignables(
	sections: MetricCatalogDomainRow[],
	section: MetricCatalogDomainRow
): ParteAsignable[] {
	const out: ParteAsignable[] = [];
	const walk = (parent: MetricCatalogDomainRow, ancestros: MetricCatalogDomainRow[]) => {
		const children = childrenOfSection(sections, sectionId(parent));
		out.push({
			id: sectionId(parent),
			label: etiquetaDeParte(parent, ancestros),
			ancestros,
			seccion: parent,
			contenedora: children.length > 0
		});
		for (const child of children) walk(child, [...ancestros, parent]);
	};
	for (const child of childrenOfSection(sections, sectionId(section))) walk(child, []);
	return out;
}

/** «Primer pie» se lee solo; «Fronte · Primer pie» dice además de dónde cuelga. */
function etiquetaDeParte(section: MetricCatalogDomainRow, ancestros: MetricCatalogDomainRow[]): string {
	const propio = sectionLabel(section);
	return ancestros.length > 0 ? `${sectionLabel(ancestros[ancestros.length - 1])} · ${propio}` : propio;
}

function descendientesDe(units: MetricUnitDraft[], unitId: string): MetricUnitDraft[] {
	const out: MetricUnitDraft[] = [];
	const pending = [unitId];
	while (pending.length > 0) {
		const current = pending.pop()!;
		for (const unit of units) {
			if (unit.realizacion_padre_id === current) {
				out.push(unit);
				pending.push(unit.realizacion_id);
			}
		}
	}
	return out;
}

/**
 * El reparto que ya tiene una unidad, leído de sus realizaciones.
 *
 * Manda la más honda: un verso dentro de un pie es del pie, aunque también esté dentro de la
 * fronte; un verso de la fronte que ningún pie cubre es de la fronte.
 */
export function repartoDeLaUnidad(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	unit: MetricUnitDraft
): Reparto {
	const length = Math.max(1, unit.v_fin - unit.v_ini + 1);
	const reparto: Reparto = Array.from({ length }, () => null);
	const profundidad = (candidate: MetricUnitDraft): number => {
		let depth = 0;
		let parentId = candidate.realizacion_padre_id;
		while (parentId && parentId !== unit.realizacion_id) {
			depth += 1;
			parentId = units.find((u) => u.realizacion_id === parentId)?.realizacion_padre_id ?? null;
		}
		return depth;
	};
	const descendientes = descendientesDe(units, unit.realizacion_id).sort(
		(a, b) => profundidad(a) - profundidad(b)
	);
	for (const child of descendientes) {
		if (!child.seccion_id) continue;
		for (let verso = child.v_ini; verso <= child.v_fin; verso += 1) {
			const index = verso - unit.v_ini;
			if (index >= 0 && index < length) reparto[index] = child.seccion_id;
		}
	}
	return reparto;
}

type Tramo = { parteId: string; desde: number; hasta: number };

/** Los tramos contiguos del reparto, en índices locales (desde 0). */
export function tramosDelReparto(reparto: Reparto): Tramo[] {
	const tramos: Tramo[] = [];
	for (let index = 0; index < reparto.length; index += 1) {
		const parteId = reparto[index];
		if (!parteId) continue;
		const ultimo = tramos[tramos.length - 1];
		if (ultimo && ultimo.parteId === parteId && ultimo.hasta === index - 1) {
			ultimo.hasta = index;
		} else {
			tramos.push({ parteId, desde: index, hasta: index });
		}
	}
	return tramos;
}

/**
 * Sustituye las partes de una unidad por las que dibuja el reparto.
 *
 * Cada tramo del reparto es una realización de su hoja; los ancestros —la fronte— se crean una
 * vez por unidad y abarcan desde el primer verso de su primer descendiente hasta el último del
 * último. Las realizaciones anteriores de la unidad se retiran: el reparto es la única verdad.
 */
export function aplicarReparto(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	unit: MetricUnitDraft,
	reparto: Reparto,
	partes: ParteAsignable[] = partesAsignables(
		sections,
		sections.find((section) => sectionId(section) === unit.seccion_id)!
	)
): MetricUnitDraft[] {
	const retiradas = new Set(descendientesDe(units, unit.realizacion_id).map((u) => u.realizacion_id));
	const conservadas = units.filter((candidate) => !retiradas.has(candidate.realizacion_id));
	const parteDe = new Map(partes.map((parte) => [parte.id, parte]));
	const nuevas: MetricUnitDraft[] = [];
	/** Una realización por ancestro y unidad, creada al primer tramo que la necesita. */
	const ancestrosCreados = new Map<string, MetricUnitDraft>();
	let orden = conservadas.reduce((max, candidate) => Math.max(max, candidate.orden), 0);

	/** La realización de un ancestro, creada al primer tramo que la necesita y estirada después. */
	const realizacionDe = (
		seccion: MetricCatalogDomainRow,
		padreId: string,
		tramo: Tramo
	): MetricUnitDraft => {
		const clave = sectionId(seccion);
		let realizacion = ancestrosCreados.get(clave);
		if (!realizacion) {
			orden += 1;
			realizacion = {
				realizacion_id: crypto.randomUUID(),
				realizacion_padre_id: padreId,
				seccion_id: clave,
				orden,
				v_ini: unit.v_ini + tramo.desde,
				v_fin: unit.v_ini + tramo.hasta,
				etiqueta: '',
				observaciones: ''
			};
			ancestrosCreados.set(clave, realizacion);
			nuevas.push(realizacion);
		} else {
			realizacion.v_ini = Math.min(realizacion.v_ini, unit.v_ini + tramo.desde);
			realizacion.v_fin = Math.max(realizacion.v_fin, unit.v_ini + tramo.hasta);
		}
		return realizacion;
	};

	for (const tramo of tramosDelReparto(reparto)) {
		const parte = parteDe.get(tramo.parteId);
		if (!parte) continue;
		let padreId = unit.realizacion_id;
		for (const ancestro of parte.ancestros) {
			padreId = realizacionDe(ancestro, padreId, tramo).realizacion_id;
		}
		// Una parte contenedora asignada directamente —la fronte sin pies— es una realización única
		// de la unidad, como sus ancestros: si después llega un pie, cuelga de ella y la estira.
		if (parte.contenedora) {
			realizacionDe(parte.seccion, padreId, tramo);
			continue;
		}
		orden += 1;
		nuevas.push({
			realizacion_id: crypto.randomUUID(),
			realizacion_padre_id: padreId,
			seccion_id: parte.id,
			orden,
			v_ini: unit.v_ini + tramo.desde,
			v_fin: unit.v_ini + tramo.hasta,
			etiqueta: '',
			observaciones: ''
		});
	}
	return [...conservadas, ...nuevas];
}

/** Las unidades que repiten el patrón de otra: misma sección, mismo contenedor. */
export function unidadesDelPatron(units: MetricUnitDraft[], modelo: MetricUnitDraft): MetricUnitDraft[] {
	return units
		.filter(
			(unit) =>
				unit.seccion_id === modelo.seccion_id &&
				unit.realizacion_padre_id === modelo.realizacion_padre_id
		)
		.sort((a, b) => a.v_ini - b.v_ini);
}

/**
 * Lleva el reparto de la unidad modelo a todas las que repiten su patrón.
 *
 * Una estancia que mida distinto de la modelo no recibe el reparto tal cual: se recorta o se
 * queda sin las últimas partes. La base no admite estancias de distinta extensión bajo un mismo
 * patrón, así que ese estado es pasajero y el editor lo avisa por otro lado.
 */
export function replicarReparto(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	modelo: MetricUnitDraft
): MetricUnitDraft[] {
	const section = sections.find((candidate) => sectionId(candidate) === modelo.seccion_id);
	if (!section) return units;
	const partes = partesAsignables(sections, section);
	const reparto = repartoDeLaUnidad(units, sections, modelo);
	let next = units;
	for (const unit of unidadesDelPatron(units, modelo)) {
		if (unit.realizacion_id === modelo.realizacion_id) continue;
		const length = unit.v_fin - unit.v_ini + 1;
		next = aplicarReparto(next, sections, unit, reparto.slice(0, length), partes);
	}
	return next;
}

/**
 * Qué le falta al reparto para ser una estancia bien formada, dicho para el editor.
 *
 * No impide guardar: la base comprueba lo suyo y lo demás es materia de quien lee. Pero avisa de
 * lo que la gramática de la forma exige y el desplegable no puede impedir: que una parte no se
 * rompa en dos, que vayan en el orden del catálogo, que la fronte lleve sus dos piedi y que cada
 * parte mida lo que su sección admite.
 */
export function avisosDelReparto(
	sections: MetricCatalogDomainRow[],
	partes: ParteAsignable[],
	reparto: Reparto
): string[] {
	const avisos: string[] = [];
	const tramos = tramosDelReparto(reparto);
	const ordenDe = new Map(partes.map((parte, index) => [parte.id, index]));
	const etiqueta = (id: string) => partes.find((parte) => parte.id === id)?.label ?? id;

	const vistas = new Set<string>();
	let ultimoOrden = -1;
	const parteDe = new Map(partes.map((parte) => [parte.id, parte]));
	const perteneceA = (id: string | null, ancestroId: string) => {
		const parte = id ? parteDe.get(id) : undefined;
		return !!parte && (parte.id === ancestroId || parte.ancestros.some((a) => sectionId(a) === ancestroId));
	};
	for (const tramo of tramos) {
		if (vistas.has(tramo.parteId)) {
			// La fronte marcada entera y partida después por sus pies no son dos frontes: entre
			// sus dos tramos solo hay versos que también son suyos.
			const entreMedias = reparto
				.slice(tramos.find((t) => t.parteId === tramo.parteId)!.desde, tramo.desde)
				.every((id) => perteneceA(id, tramo.parteId));
			if (!entreMedias) avisos.push(`«${etiqueta(tramo.parteId)}» aparece en dos tramos separados.`);
			continue;
		}
		vistas.add(tramo.parteId);
		const orden = ordenDe.get(tramo.parteId) ?? -1;
		if (orden < ultimoOrden) {
			avisos.push(`«${etiqueta(tramo.parteId)}» va antes de lo que el catálogo ordena.`);
		}
		ultimoOrden = Math.max(ultimoOrden, orden);
		const parte = partes.find((candidate) => candidate.id === tramo.parteId);
		if (parte && !parte.contenedora) {
			const versos = tramo.hasta - tramo.desde + 1;
			const minimo = sectionVerseMinimum(parte.seccion);
			const maximo = sectionVerseMaximum(parte.seccion);
			if (versos < minimo || (maximo !== null && versos > maximo)) {
				avisos.push(
					`«${parte.label}» tiene ${versos} ${versos === 1 ? 'verso' : 'versos'} y admite ${
						maximo === null ? `${minimo} o más` : minimo === maximo ? `${minimo}` : `de ${minimo} a ${maximo}`
					}.`
				);
			}
		}
	}

	// Los hermanos obligatorios dentro de un ancestro: si hay fronte, hay dos piedi.
	const ancestrosPresentes = new Map<string, MetricCatalogDomainRow>();
	for (const id of vistas) {
		const parte = partes.find((candidate) => candidate.id === id);
		for (const ancestro of parte?.ancestros ?? []) ancestrosPresentes.set(sectionId(ancestro), ancestro);
		if (parte?.contenedora) ancestrosPresentes.set(parte.id, parte.seccion);
	}
	for (const [ancestroId, ancestro] of ancestrosPresentes) {
		const hijas = childrenOfSection(sections, ancestroId);
		for (const hija of hijas) {
			const minimo = Math.max(0, Number(hija.repeticiones_min ?? 0));
			if (minimo > 0 && !vistas.has(sectionId(hija))) {
				avisos.push(`«${sectionLabel(ancestro)}» necesita «${sectionLabel(hija)}».`);
			}
		}
		const versos = reparto.filter((id) => perteneceA(id, ancestroId)).length;
		const minimo = sectionVerseMinimum(ancestro);
		const maximo = sectionVerseMaximum(ancestro);
		if (versos < minimo || (maximo !== null && versos > maximo)) {
			avisos.push(
				`«${sectionLabel(ancestro)}» tiene ${versos} versos y admite ${
					maximo === null ? `${minimo} o más` : `de ${minimo} a ${maximo}`
				}.`
			);
		}
	}

	// Un hueco entre partes: versos sin parte con partes a los dos lados.
	const primero = reparto.findIndex((id) => id !== null);
	const ultimo = reparto.length - 1 - [...reparto].reverse().findIndex((id) => id !== null);
	if (primero >= 0 && reparto.slice(primero, ultimo + 1).some((id) => id === null)) {
		avisos.push('Hay versos sin parte entre dos partes.');
	}

	return avisos;
}

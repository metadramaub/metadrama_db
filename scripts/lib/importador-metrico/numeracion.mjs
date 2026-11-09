/**
 * Ediciones que vuelven a numerar desde 1 en cada jornada (el Alcalde de Castalia, el Peribáñez de
 * Cátedra). La base guarda numeración continua para toda la obra, así que la importación desplaza
 * cada jornada tras el último verso de la anterior. El original se conserva tal como lo imprime la
 * edición: el desplazamiento se declara en la ficha y la función SQL que guarda lo recalcula.
 */

/**
 * Devuelve los desplazamientos por jornada si la edición reinicia la numeración, o null si no.
 * Solo se reconoce el caso claro: todas las filas numeradas tienen jornada, las jornadas no se
 * mezclan y cada una, salvo la primera, empieza en el v. 1.
 * @param {{tramos: {jornada: number|null, v_ini: number|null, v_fin: number|null}[]}} extraccion
 * @returns {{jornada: number, desplazamiento: number}[] | null}
 */
export function numeracionPorJornada(extraccion) {
	const filas = extraccion.tramos.filter((t) => t.v_ini !== null && t.v_fin !== null);
	if (filas.length < 2 || filas.some((t) => t.jornada === null)) return null;
	for (let i = 1; i < filas.length; i++) if (filas[i].jornada < filas[i - 1].jornada) return null;
	const jornadas = [...new Set(filas.map((t) => t.jornada))];
	if (jornadas.length < 2) return null;
	const desplazamientos = [];
	let acumulado = 0;
	for (const [k, jornada] of jornadas.entries()) {
		const propias = filas.filter((t) => t.jornada === jornada);
		if (k > 0 && propias[0].v_ini !== 1) return null;
		desplazamientos.push({ jornada, desplazamiento: acumulado });
		acumulado += Math.max(...propias.map((t) => t.v_fin));
	}
	return desplazamientos;
}

/**
 * Copia de la extracción con la numeración continua. Las notas que citan versos se desplazan con la
 * jornada de la primera fila a la que remiten; sin fila enlazada, sus versos se dejan como están.
 */
export function aplicarNumeracion(extraccion, desplazamientos) {
	const por = new Map(desplazamientos.map((d) => [d.jornada, d.desplazamiento]));
	const copia = structuredClone(extraccion);
	const jornadaDe = new Map(copia.tramos.map((t) => [t.id, t.jornada]));
	const mover = (valor, jornada) => (valor === null || !por.has(jornada) ? valor : valor + por.get(jornada));
	for (const t of copia.tramos) {
		t.v_ini = mover(t.v_ini, t.jornada);
		t.v_fin = mover(t.v_fin, t.jornada);
	}
	for (const n of copia.notas ?? []) {
		const jornada = jornadaDe.get(n.tramos_ref?.[0]);
		n.v_ini = mover(n.v_ini, jornada);
		n.v_fin = mover(n.v_fin, jornada);
	}
	return copia;
}

/**
 * Las realizaciones de una secuencia anotada: la unidad y, dentro de ella, sus partes.
 *
 * **Puro reparto aritmético sobre el catálogo**, sin nada pactado: la unidad mide lo que declara la
 * arquitectura —o el pasaje entero, si no declara nada—, y las partes se materializan tantas veces
 * como digan sus repeticiones. Por eso lo comparten quien siembra las obras de prueba y quien
 * migra las anotadas de verdad: las dos escriben por `guardar_anotacion_metrica` y las dos tienen
 * que repartir igual, o la misma forma quedaría dibujada de dos maneras.
 */

/**
 * Las realizaciones de una secuencia: la unidad, y dentro de ella sus partes.
 *
 * Es puro reparto aritmético, y por eso no está en el guion: la unidad mide lo que declara la
 * arquitectura —o el pasaje entero, si no declara nada—, y las partes se materializan tantas veces
 * como digan sus repeticiones. La que no tiene tope llena lo que sobra: es la cadena de tercetos
 * del terceto encadenado.
 *
 * **El orden es único en toda la anotación**, no dentro de cada unidad: la tabla lo declara
 * `unique (anotacion_id, orden)`.
 */
export function realizacionesDe(arq, vIni, vFin) {
	const versosUnidad = Number(arq.unidad_versos_min ?? 0);
	const abierta = !versosUnidad;
	const paso = abierta ? vFin - vIni + 1 : versosUnidad;
	const raices = arq.secciones.filter((s) => s.seccion_padre_id === null);

	const vueltas = new Map();
	let ocupado = 0;
	for (const s of raices) {
		if (s.repeticiones_max === null) continue;
		const veces = Number(s.repeticiones_min);
		vueltas.set(s.seccion_id, veces);
		ocupado += veces * Number(s.versos_min || 0);
	}
	const sinTope = raices.filter((s) => s.repeticiones_max === null);
	if (sinTope.length === 1) {
		const resto = paso - ocupado;
		const veces = resto / Number(sinTope[0].versos_min);
		if (resto <= 0 || !Number.isInteger(veces)) {
			return { unidades: [], problema: `no cuadra la parte repetible en ${paso} versos` };
		}
		vueltas.set(sinTope[0].seccion_id, veces);
		ocupado += resto;
	}
	if (raices.length > 0 && ocupado !== paso) {
		return { unidades: [], problema: `las partes ocupan ${ocupado} y la unidad mide ${paso}` };
	}

	const unidades = [];
	let orden = 1;
	for (let inicio = vIni; inicio <= vFin; inicio += paso) {
		const unidad = {
			realizacion_id: crypto.randomUUID(),
			realizacion_padre_id: null,
			seccion_id: null,
			orden: orden++,
			v_ini: inicio,
			v_fin: inicio + paso - 1,
			etiqueta: null,
			observaciones: null
		};
		unidades.push(unidad);
		let cursor = inicio;
		for (const s of raices) {
			const versos = Number(s.versos_min);
			for (let vuelta = 0; vuelta < (vueltas.get(s.seccion_id) ?? 0); vuelta += 1) {
				unidades.push({
					realizacion_id: crypto.randomUUID(),
					realizacion_padre_id: unidad.realizacion_id,
					seccion_id: s.seccion_id,
					orden: orden++,
					v_ini: cursor,
					v_fin: cursor + versos - 1,
					etiqueta: null,
					observaciones: null
				});
				cursor += versos;
			}
		}
	}
	return { unidades, problema: null };
}

/**
 * Las realizaciones de las formas que crecen por ciclos, que el guion dice árbol abajo.
 *
 * Son la canción y el villancico: las únicas del catálogo **cuyas partes tienen partes dentro** —la
 * mudanza cuelga de la copla, no del ciclo; el pie del fronte, no de la estancia—, y ninguna regla
 * dice cuántos ciclos hay ni cuánto mide cada uno. La base lo comprueba: una sección raíz cuelga de
 * la unidad, y una sección interna de la realización de su sección superior.
 */
export function realizacionesPorPartes(arq, vIni, partes) {
	const porSlug = new Map(arq.secciones.map((s) => [s.slug, s]));
	const unidades = [];
	let orden = 1;
	let problema = null;

	const largoDe = (nodo) =>
		nodo.partes ? nodo.partes.reduce((t, hijo) => t + largoDe(hijo), 0) : Number(nodo.versos);
	const total = partes.reduce((t, nodo) => t + largoDe(nodo), 0);

	const unidad = {
		realizacion_id: crypto.randomUUID(),
		realizacion_padre_id: null,
		seccion_id: null,
		orden: orden++,
		v_ini: vIni,
		v_fin: vIni + total - 1,
		etiqueta: null,
		observaciones: null
	};
	unidades.push(unidad);

	const materializar = (nodo, padre, desde) => {
		const seccion = porSlug.get(nodo.seccion);
		if (!seccion) {
			problema = `«${arq.forma}» no tiene parte «${nodo.seccion}»`;
			return desde;
		}
		const largo = largoDe(nodo);
		const suyo = {
			realizacion_id: crypto.randomUUID(),
			realizacion_padre_id: padre,
			seccion_id: seccion.seccion_id,
			orden: orden++,
			v_ini: desde,
			v_fin: desde + largo - 1,
			etiqueta: null,
			observaciones: null
		};
		unidades.push(suyo);
		let cursor = desde;
		for (const hijo of nodo.partes ?? []) cursor = materializar(hijo, suyo.realizacion_id, cursor);
		return desde + largo;
	};

	let cursor = vIni;
	for (const nodo of partes) cursor = materializar(nodo, unidad.realizacion_id, cursor);
	return problema ? { unidades: [], problema } : { unidades, problema: null };
}

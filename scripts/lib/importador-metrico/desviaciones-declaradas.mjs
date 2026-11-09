/**
 * Desviaciones que la edición declara en una nota enlazada a la fila. Solo se proponen las que se
 * leen sin interpretar: listas encabezadas («VERSOS CORTOS: 881, 2046», «Versos que faltan: 816»)
 * y un verso suelto de otra medida («aparece un verso heptasílabo (v. 2172)»). Lo demás se queda
 * en la nota para que lo lea el editor. Todo llega como propuesta y se puede quitar en el editor.
 */

const SILABAS = {
	trisilabo: 3,
	tetrasilabo: 4,
	pentasilabo: 5,
	hexasilabo: 6,
	heptasilabo: 7,
	octosilabo: 8,
	eneasilabo: 9,
	decasilabo: 10,
	endecasilabo: 11,
	dodecasilabo: 12,
	alejandrino: 14
};
// Arquitecturas de una sola medida: dan la norma con la que comparar el verso observado.
const ARQUITECTURA_MEDIDA = {
	tetrasilabica: 4,
	pentasilabica: 5,
	hexasilabica: 6,
	heptasilabica: 7,
	octosilabica: 8,
	octosilabica_consonante: 8,
	decasilabica: 10,
	endecasilabica: 11,
	endecasilabica_consonante: 11,
	endecasilabica_sin_rima: 11,
	dodecasilabica: 12,
	alejandrina: 14
};

const plano = (texto) =>
	String(texto ?? '')
		.normalize('NFD')
		.replace(/\p{M}/gu, '')
		.toLowerCase()
		.replace(/\s+/gu, ' ');

// Encabezados de lista. El texto que sigue a los dos puntos solo puede tener números.
const LISTAS = [
	{ patron: /versos? (?:mas )?cortos?\s*:([^.;]*)/u, dimension: 'metro', relacion_norma: 'menor_que_norma' },
	{ patron: /versos? (?:mas )?largos?\s*:([^.;]*)/u, dimension: 'metro', relacion_norma: 'mayor_que_norma' },
	{ patron: /versos? que faltan\s*:([^.;]*)/u, dimension: 'estructura', relacion_norma: 'falta' },
	{ patron: /versos? que sobran\s*:([^.;]*)/u, dimension: 'estructura', relacion_norma: 'sobra' }
];

/** «816, 930 y 2212», «1060-1061»: rangos en el orden de la nota, o null si hay otra cosa. */
export function rangosDeLista(lista) {
	const limpia = lista.replace(/\bvv?\.\s*/gu, '').trim();
	if (!limpia || !/^[\d\s,\-–—y]+$/u.test(limpia)) return null;
	const rangos = [];
	for (const pieza of limpia.split(/\s*(?:,|\by\b)\s*/u).filter(Boolean)) {
		const m = pieza.match(/^(\d+)(?:\s*[-–—]\s*(\d+))?$/u);
		if (!m) return null;
		const v_ini = Number(m[1]);
		const v_fin = m[2] ? Number(m[2]) : v_ini;
		if (v_fin < v_ini) return null;
		rangos.push({ v_ini, v_fin });
	}
	return rangos;
}

function medidaNorma(row, destino) {
	const porArquitectura = ARQUITECTURA_MEDIDA[destino?.arquitectura_slug ?? ''];
	if (porArquitectura) return porArquitectura;
	// «endecasílabos sueltos», «octosílabos»: el nombre de la fila dice la medida si solo dice una.
	const nombradas = new Set(
		Object.keys(SILABAS).filter((m) => new RegExp(`(?<!\\p{L})${m}s?(?!\\p{L})`, 'u').test(plano(row.denominacion_literal)))
	);
	return nombradas.size === 1 ? SILABAS[[...nombradas][0]] : null;
}

/**
 * @param row fila de la transcripción, ya en numeración continua
 * @param notesById notas por id
 * @param opciones.desplazamiento lo que se sumó a la jornada de la fila (las notas citan la edición)
 * @param opciones.destino forma y arquitectura propuestas, para saber la medida de la norma
 * @param opciones.metros slugs de metro que admite el catálogo
 */
export function desviacionesDeclaradas(row, notesById, { desplazamiento = 0, destino = null, metros = null } = {}) {
	if (row.v_ini === null || row.v_fin === null) return [];
	const dentro = (r) => r.v_ini >= row.v_ini && r.v_fin <= row.v_fin;
	const propuestas = [];
	for (const id of row.notas_ref ?? []) {
		const nota = notesById.get(id);
		if (!nota?.tramos_ref?.includes(row.id)) continue;
		const texto = plano(nota.texto_literal);
		const base = { nota_ref: nota.id, texto_fuente: nota.texto_literal, fundamento: null };
		for (const lista of LISTAS) {
			const m = texto.match(lista.patron);
			const rangos = m && rangosDeLista(m[1]);
			for (const r of rangos ?? []) {
				const rango = { v_ini: r.v_ini + desplazamiento, v_fin: r.v_fin + desplazamiento };
				if (dentro(rango))
					propuestas.push({ ...rango, dimension: lista.dimension, relacion_norma: lista.relacion_norma, ...base });
			}
		}
		// Un verso de otra medida: una sola medida nombrada en singular y versos citados uno a uno.
		const singulares = Object.keys(SILABAS).filter((m) => new RegExp(`(?<!\\p{L})${m}(?![\\p{L}])`, 'u').test(texto));
		const citas = [...texto.matchAll(/(?<!\p{L})vv?\.\s*(\d+)(\s*[-–—]\s*\d+)?/gu)];
		if (singulares.length !== 1 || !citas.length || citas.some((c) => c[1] === undefined || c[2] || c[0].startsWith('vv')))
			continue;
		const observado = singulares[0];
		if (metros && !metros.includes(observado)) continue;
		const norma = medidaNorma(row, destino);
		if (!norma) continue;
		const silabas = SILABAS[observado];
		const desviacion =
			silabas < norma
				? { dimension: 'metro', relacion_norma: 'menor_que_norma', metro_observado_slug: observado }
				: silabas > norma
					? { dimension: 'metro', relacion_norma: 'mayor_que_norma', metro_observado_slug: observado }
					: /(?<!\p{L})suelto(?!\p{L})/u.test(texto)
						? { dimension: 'estructura', relacion_norma: 'sobra' }
						: null;
		if (!desviacion) continue;
		for (const c of citas) {
			const v = Number(c[1]) + desplazamiento;
			if (dentro({ v_ini: v, v_fin: v })) propuestas.push({ v_ini: v, v_fin: v, ...desviacion, ...base });
		}
	}
	return propuestas;
}

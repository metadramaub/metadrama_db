/**
 * Las preguntas que dependen del régimen de la rima que se haya respondido.
 *
 * Doce arquitecturas admiten los dos regímenes, y en ellas las vocales de la asonancia no son una
 * licencia: son el dato de la asonancia. Se responden siempre que la haya y no existen cuando no la
 * hay. El catálogo lo declara desde el 23 de septiembre de 2026 en
 * `grupos_eleccion_metrica.solo_si_tipo_rima_id`, y `guardar_anotacion_metrica` lo exige en los dos
 * sentidos: sin la condición cumplida, la respuesta sobra y se rechaza.
 *
 * Aquí se resuelve lo mismo para la pantalla, **leyendo la misma columna**: el editor no decide nada
 * por su cuenta, solo enseña lo que el catálogo dice que aplica. Se comparan identificadores de
 * término, no etiquetas, así que esto no repite el mapeo que la rejilla usa para nombrar el régimen.
 */

import { separarRegimen } from '$lib/metrica/esquema-rima-escrito';
import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';

type Eleccion = {
	grupo_eleccion_id: string;
	opcion_eleccion_id: string | null;
	valor_texto?: string | null;
};

type TipoDeRima = { id: string | number; slug?: string | null };

/**
 * Los tipos de rima que afirman las respuestas de la secuencia.
 *
 * Se miran **todas** las respuestas de dimensión `rima`, las de la secuencia y las de cada unidad:
 * una tirada de pareados puede tener unos consonantes y otros asonantes, y entonces la asonancia
 * sigue teniendo su dato que declarar.
 *
 * Una respuesta lo dice de dos maneras: eligiendo una disposición del catálogo, que lleva su
 * `tipo_rima_id`, o escribiendo el esquema a mano, que guarda el término detrás del punto medio
 * —`abab · asonante`—.
 */
export function tiposDeRimaAfirmados(datos: {
	elecciones: Eleccion[];
	groups: MetricCatalogDomainRow[];
	options: MetricCatalogDomainRow[];
	rhymePatterns: MetricCatalogDomainRow[];
	rhymeTypes: TipoDeRima[];
}): Set<string> {
	const gruposDeRima = new Set(
		datos.groups
			.filter((group) => String(group.dimension) === 'rima')
			.map((group) => String(group.grupo_eleccion_id))
	);
	const tipoPorEsquema = new Map<string, string>();
	for (const esquema of datos.rhymePatterns) {
		if (!esquema.esquema_rima_id || !esquema.tipo_rima_id) continue;
		tipoPorEsquema.set(String(esquema.esquema_rima_id), String(esquema.tipo_rima_id));
	}
	const tipoPorSlug = new Map<string, string>();
	for (const tipo of datos.rhymeTypes) {
		if (tipo.slug) tipoPorSlug.set(String(tipo.slug), String(tipo.id));
	}

	const afirmados = new Set<string>();
	for (const eleccion of datos.elecciones) {
		if (!gruposDeRima.has(String(eleccion.grupo_eleccion_id))) continue;
		if (eleccion.opcion_eleccion_id) {
			const option = datos.options.find(
				(row) => String(row.opcion_eleccion_id) === eleccion.opcion_eleccion_id
			);
			const tipo = option?.esquema_rima_id
				? tipoPorEsquema.get(String(option.esquema_rima_id))
				: undefined;
			if (tipo) afirmados.add(tipo);
			continue;
		}
		const regimen = separarRegimen(String(eleccion.valor_texto ?? '')).regimen;
		const tipo = regimen ? tipoPorSlug.get(regimen) : undefined;
		if (tipo) afirmados.add(tipo);
	}
	return afirmados;
}

/**
 * Si una pregunta aplica a lo que se lleva respondido.
 *
 * Sin condición, siempre. Con ella, solo cuando alguna respuesta de rima afirma ese régimen: **no
 * saber no es saber que sí**, y mientras la rima esté sin responder la pregunta condicionada no se
 * enseña ni se exige. Como la rima sí es obligatoria, la condición queda resuelta antes de guardar.
 */
export function preguntaAplica(
	group: MetricCatalogDomainRow,
	afirmados: Set<string>
): boolean {
	const condicion = group.solo_si_tipo_rima_id;
	if (!condicion) return true;
	return afirmados.has(String(condicion));
}

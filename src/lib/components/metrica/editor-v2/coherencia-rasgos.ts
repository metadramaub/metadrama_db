/**
 * Lo que dos respuestas de rasgo no pueden decir a la vez.
 *
 * Los rasgos de una secuencia se responden cada uno por su lado, y casi todas las combinaciones
 * valen: un endecasílabo suelto sin rima puede cerrar en dístico —el dístico final no cuenta para
 * la densidad—, llevar esdrújulos o no llevar nada. Lo que no puede es decir que **ningún verso
 * rima** y que **hay pareados intercalados**: los pareados son rima en la serie. Fijado por David el
 * 18 de septiembre de 2026 al revisar *Adonis y Venus*.
 *
 * Se lee por el slug del rasgo y del valor, que es lo que el catálogo fija; la pregunta y su
 * opción se resuelven al vuelo.
 */

import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';

type Eleccion = { realizacion_id: string | null; opcion_eleccion_id: string | null };

/** El slug del valor de rasgo que responde la secuencia entera para un rasgo, o nulo. */
function valorDeRasgo(
	rasgoSlug: string,
	elecciones: Eleccion[],
	options: MetricCatalogDomainRow[],
	traitValues: MetricCatalogDomainRow[],
	traits: MetricCatalogDomainRow[]
): string | null {
	const rasgo = traits.find((row) => String(row.slug) === rasgoSlug);
	if (!rasgo) return null;
	const valores = new Map(
		traitValues
			.filter((row) => String(row.rasgo_id) === String(rasgo.rasgo_id))
			.map((row) => [String(row.valor_id), String(row.slug)])
	);
	for (const eleccion of elecciones) {
		if (eleccion.realizacion_id !== null || !eleccion.opcion_eleccion_id) continue;
		const option = options.find(
			(row) => String(row.opcion_eleccion_id) === eleccion.opcion_eleccion_id
		);
		const slug = option?.valor_rasgo_id ? valores.get(String(option.valor_rasgo_id)) : undefined;
		if (slug) return slug;
	}
	return null;
}

/** El error que impide guardar, o nulo si las respuestas de rasgo se sostienen entre sí. */
export function errorDeCoherenciaDeRasgos(
	elecciones: Eleccion[],
	options: MetricCatalogDomainRow[],
	traitValues: MetricCatalogDomainRow[],
	traits: MetricCatalogDomainRow[]
): string | null {
	const densidad = valorDeRasgo('densidad_de_rima', elecciones, options, traitValues, traits);
	const pareados = valorDeRasgo('organizacion_en_pareados', elecciones, options, traitValues, traits);
	if (densidad === 'ninguna' && pareados !== null && pareados !== 'ninguna') {
		return 'Con densidad de rima «ninguna» no puede haber pareados intercalados: el dístico final no cuenta, pero los pareados sí riman. Revisa una de las dos respuestas.';
	}
	return null;
}

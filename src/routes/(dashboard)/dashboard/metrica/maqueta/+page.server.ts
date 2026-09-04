import { loadMetricCatalog } from '$lib/server/catalogo-metrico';
import type { PageServerLoad } from './$types';

/**
 * Maqueta para decidir cómo se preguntan las cosas, con el catálogo de verdad.
 *
 * No es el editor ni escribe nada: lee el catálogo y dibuja los mismos cuatro casos con tres
 * maquetas distintas, para poder compararlas de un vistazo. Existe porque rehacer el formulario
 * sobre una forma concreta acierta para esa y desajusta las otras noventa, y porque el recorrido
 * forma por forma ya se hizo una vez y no debe repetirse.
 *
 * **Los cuatro casos no son un capricho.** De las 91 arquitecturas activas, 18 no preguntan nada,
 * 51 preguntan una o dos cosas sin partes, y 22 tienen partes o pasan de dos preguntas. Estas
 * cuatro cubren los tres grupos y el caso duro.
 */
const CASOS = [
	{ forma: 'cuarteto', arquitectura: 'endecasilabica', porque: '1 pregunta, sin partes · 18 arquitecturas' },
	{ forma: 'quintilla', arquitectura: 'octosilabica_consonante', porque: '2 preguntas, sin partes · 21 arquitecturas' },
	{ forma: 'romance', arquitectura: 'octosilabica', porque: '1 pregunta, una sola unidad · 12 arquitecturas' },
	{ forma: 'copla_real', arquitectura: 'octosilabica_consonante', porque: '3 preguntas y partes · 6 arquitecturas' }
] as const;

export const load: PageServerLoad = async ({ locals }) => {
	const catalogo = await loadMetricCatalog(locals.supabase);

	return {
		casos: CASOS,
		catalogo: {
			forms: catalogo.forms,
			configurations: catalogo.configurations,
			lengthRules: catalogo.lengthRules,
			rhymeTypes: catalogo.options.rhymeTypes,
			domain: catalogo.domain
		}
	};
};

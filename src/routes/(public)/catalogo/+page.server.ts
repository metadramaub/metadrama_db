import { redirect } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';

/**
 * El buscador de obras se llama `/obras` desde el 7 de septiembre de 2026.
 *
 * Se llamaba «catálogo», y ese nombre pasó a ser ambiguo al publicarse el **catálogo métrico**: uno
 * es el repertorio de obras y el otro el de formas. Ahora la zona pública se lee sola —`/obras` y
 * `/autores`—, y la ficha de una obra ya vivía debajo, en `/obras/<slug>`.
 *
 * La ruta vieja se queda como redirección permanente porque hay enlaces dados.
 */
export const load: PageServerLoad = async ({ url }) => {
	redirect(308, `/obras${url.search}`);
};

/**
 * Con qué control se responde una pregunta del editor.
 *
 * Vive aquí y no en cada componente porque estaba escrito dos veces —una en el campo de una
 * pregunta y otra en el bloque de las que se responden para toda la composición— y las dos
 * copias se separaron: los cuartetos del soneto salían con botones y sus tercetos con
 * desplegable, sin que nada del catálogo lo justificara.
 *
 * La regla mira **cuántas respuestas hay**, no cómo de largas son sus etiquetas. Medir las
 * etiquetas hacía que la misma clase de pregunta se viera distinta según la forma.
 */

/**
 * Por encima de este número las respuestas dejan de leerse de un vistazo y compensa plegarlas
 * en un desplegable. Por debajo se enseñan enteras, en lista, para que quepan la etiqueta y la
 * explicación que el catálogo deriva para cada una.
 */
export const MAX_OPCIONES_A_LA_VISTA = 5;

export type ControlDeRespuestaUnica = 'lista' | 'desplegable';

/** Qué control usa una pregunta de respuesta única con este número de alternativas. */
export function controlDeRespuestaUnica(opciones: number): ControlDeRespuestaUnica {
	return opciones > 0 && opciones <= MAX_OPCIONES_A_LA_VISTA ? 'lista' : 'desplegable';
}

export type ControlDePregunta = 'casilla' | 'lista' | 'desplegable';

/**
 * Con qué control se responde una pregunta, mirando además si admite quedarse sin responder.
 *
 * **Una sola opción que se puede dejar vacía no es una elección: es un sí/no.** El catálogo tiene
 * ocho así —«¿tiene final acentual destacado?»— y pintarlas como una lista de un elemento invita a
 * marcarla por creer que hay que elegir algo. El campo de una pregunta ya lo hacía; el bloque de
 * las que se responden para toda la composición, no, y esa es justo la diferencia que estas dos
 * funciones existen para impedir.
 */
export function controlDePregunta(opciones: number, minimoDeRespuestas: number): ControlDePregunta {
	if (opciones === 1 && minimoDeRespuestas === 0) return 'casilla';
	return controlDeRespuestaUnica(opciones);
}

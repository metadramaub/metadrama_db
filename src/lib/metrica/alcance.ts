/**
 * De qué se responde una pregunta del catálogo.
 *
 * - `secuencia`: una sola vez para todo el pasaje.
 * - `unidad`: una vez por unidad.
 * - `realizacion`: una vez por cada aparición de su sección. Lo usa la repetición del estribillo
 *   del villancico, que puede volver entera tras una copla y en parte tras la siguiente.
 *
 * **`realizacion` está declarado en el modelo y todavía no lo implementa el editor V2.** Hasta que
 * lo haga se responde como si fuera de unidad, de modo que la pregunta sigue apareciendo y se
 * guarda una respuesta para toda la composición, que es lo que se guardaba antes. Cuando el editor
 * pregunte por realización, esta función deja de tratarlos igual y la respuesta pasa a colgar de
 * `elecciones_editor_metrico.realizacion_prueba_id`, que ya existe.
 */
export type AlcanceDePregunta = 'secuencia' | 'unidad' | 'realizacion';

/**
 * Si la pregunta se responde dentro de la unidad y no una sola vez para el pasaje.
 *
 * Es el criterio que reparte las preguntas entre las dos pantallas del editor, y vive aquí para
 * que el reparto esté escrito una vez y no repartido por los componentes.
 */
export function seRespondeDentroDeLaUnidad(alcance: unknown): boolean {
	return alcance === 'unidad' || alcance === 'realizacion';
}

/**
 * Cuántas unidades tiene una secuencia anotada, contadas como las contaría quien la lee.
 *
 * La anotación guarda **un árbol** de realizaciones, no una lista: un villancico de dos coplas son
 * catorce filas —el pasaje entero, la cabeza, cada ciclo con su copla, y dentro de la copla la
 * mudanza, el enlace y la vuelta, y la repetición del estribillo—. Contarlas todas decía «14
 * unidades» donde el editor veía dos coplas, y es lo que hacía la tabla de secuencias.
 *
 * Se cuenta por escalones, y el primero que responde manda:
 *
 * 1. **Las estrofas sueltas**: las realizaciones de raíz sin sección, que es como se anotan las
 *    series estróficas —trece redondillas son trece filas de raíz—. Si hay dos o más, esa es la
 *    cuenta.
 * 2. **La parte que se repite**: cuando el pasaje es una sola realización con secciones dentro,
 *    la unidad es la sección **no anidada y repetible** —el ciclo de copla y estribillo del
 *    villancico, la estancia de la canción, el terceto de la cadena—. Solo si hay exactamente una
 *    sección así entre las anotadas: el soneto tiene dos (cuartetos y tercetos) y sumarlas daría
 *    cuatro unidades para un soneto, que es una.
 * 3. **Lo que quede**: las realizaciones de raíz, que para un soneto o una quintilla sola es una.
 */
export type UnidadContable = {
	realizacion_padre_id: string | null;
	seccion_id: string | null;
};

export type SeccionContable = {
	seccion_id: string;
	seccion_padre_id: string | null;
	repeticiones_max: number | null;
	/** El tipo del catálogo; `remate` es el que interesa aquí. */
	tipo_seccion?: string | null;
};

/**
 * Si entre lo anotado hay un remate: el envío de la canción, el verso final del terceto
 * encadenado cuando se anota por secciones. No es una unidad más y no se cuenta como tal, pero
 * decir «5 unidades» de una canción con envío se queda corto: se añade «+ remate».
 */
export function tieneRemate(
	unidades: readonly UnidadContable[],
	secciones: readonly SeccionContable[]
): boolean {
	const remates = new Set(
		secciones.filter((seccion) => seccion.tipo_seccion === 'remate').map((seccion) => seccion.seccion_id)
	);
	return unidades.some((unidad) => unidad.seccion_id !== null && remates.has(unidad.seccion_id));
}

export function contarUnidades(
	unidades: readonly UnidadContable[],
	secciones: readonly SeccionContable[]
): number {
	const estrofas = unidades.filter(
		(unidad) => unidad.realizacion_padre_id === null && unidad.seccion_id === null
	).length;
	if (estrofas >= 2) return estrofas;

	const seccionPorId = new Map(secciones.map((seccion) => [seccion.seccion_id, seccion]));
	const repetibles = new Set<string>();
	for (const unidad of unidades) {
		if (!unidad.seccion_id) continue;
		const seccion = seccionPorId.get(unidad.seccion_id);
		if (!seccion || seccion.seccion_padre_id !== null) continue;
		if (seccion.repeticiones_max === null || seccion.repeticiones_max > 1) {
			repetibles.add(seccion.seccion_id);
		}
	}
	if (repetibles.size === 1) {
		const [seccionId] = repetibles;
		return unidades.filter((unidad) => unidad.seccion_id === seccionId).length;
	}

	return unidades.filter((unidad) => unidad.realizacion_padre_id === null).length;
}

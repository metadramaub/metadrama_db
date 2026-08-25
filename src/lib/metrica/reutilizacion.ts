/**
 * Cuándo una parte que reutiliza otra arquitectura toma prestado su repertorio de rima.
 *
 * Una sección puede declarar que **es** otra arquitectura —la primera quintilla de la copla real,
 * los dos miembros de la oncena, el cuarteto y el terceto del septeto compuesto—. Cuando lo hace,
 * a veces hereda cómo rima aquella y a veces no, y la diferencia no es de gusto:
 *
 * - **No hereda si la unidad ya declara su rima entera.** La décima espinela dice `abba:accddc` de
 *   sus diez versos; prestarle además el repertorio de la redondilla ofrecería la cruzada, que su
 *   propio esquema no admite. Lo mismo la copla castellana, que no es dos redondillas cualesquiera
 *   sino dos de cuatro rimas distintas, y eso solo lo dice su esquema de ocho posiciones.
 * - **No hereda si la parte ya tiene rima suya**, sea un esquema propio o una pregunta sobre ella:
 *   los cuartetos y los tercetos del soneto, las dos quintillas de la copla real.
 * - **Hereda cuando la unidad calla y la parte no tiene nada**: las dos oncenas, el septeto
 *   compuesto y la estrofa de las tres sextinas.
 *
 * La regla la fijó la ficha pública, que la necesitó antes: está en `formas-publicas.ts` desde que
 * se dibujó la rejilla, con los dos casos que la obligaron a afinarse. Aquí vive **una sola vez**
 * para que el editor V2 y la ficha no puedan separarse, que es lo que el IP pidió el 25 de agosto de
 * 2026: *«hereda las preguntas si la ficha también lo hace»*.
 *
 * Aplicada al catálogo entero presta en nueve secciones de treinta y cuatro que reutilizan algo.
 */

export type FilaSeccion = {
	seccion_id: unknown;
	arquitectura_id: unknown;
	arquitectura_referenciada_id?: unknown;
};

export type FilaEsquemaRima = {
	esquema_rima_id: unknown;
	arquitectura_id: unknown;
	seccion_id?: unknown;
};

export type FilaPosicionRima = {
	esquema_rima_id: unknown;
};

export type FilaGrupo = {
	grupo_eleccion_id: unknown;
	arquitectura_id: unknown;
	dimension: unknown;
	seccion_id?: unknown;
	seccion_tratada_id?: unknown;
	activo?: unknown;
};

function id(valor: unknown): string {
	return valor === null || valor === undefined ? '' : String(valor);
}

/**
 * Si la unidad de una arquitectura declara ya cómo rima, para todos sus versos.
 *
 * Se exige que el esquema **tenga posiciones**, no solo que exista: un patrón abierto y vacío
 * —`distribucion-variable`— no dice nada de la rima y no debe bloquear el préstamo. Es la
 * diferencia que hace que el septeto compuesto herede y la copla castellana no.
 */
export function unidadDeclaraSuRima(
	arquitecturaId: string,
	esquemas: FilaEsquemaRima[],
	posiciones: FilaPosicionRima[]
): boolean {
	const conPosiciones = new Set(posiciones.map((fila) => id(fila.esquema_rima_id)));
	return esquemas.some(
		(esquema) =>
			id(esquema.arquitectura_id) === arquitecturaId &&
			!id(esquema.seccion_id) &&
			conPosiciones.has(id(esquema.esquema_rima_id))
	);
}

/** Si una parte tiene ya rima propia: un esquema suyo, o una pregunta que hable de ella. */
export function laParteTieneRimaPropia(
	seccion: FilaSeccion,
	esquemas: FilaEsquemaRima[],
	grupos: FilaGrupo[]
): boolean {
	const seccionId = id(seccion.seccion_id);
	const arquitecturaId = id(seccion.arquitectura_id);
	const conEsquemaPropio = esquemas.some(
		(esquema) =>
			id(esquema.arquitectura_id) === arquitecturaId && id(esquema.seccion_id) === seccionId
	);
	if (conEsquemaPropio) return true;
	return grupos.some(
		(grupo) =>
			id(grupo.arquitectura_id) === arquitecturaId &&
			grupo.activo !== false &&
			id(grupo.dimension) === 'rima' &&
			(id(grupo.seccion_id) === seccionId || id(grupo.seccion_tratada_id) === seccionId)
	);
}

/** El predicado entero, tal como lo aplica la ficha para prestar el repertorio ajeno. */
export function seccionHeredaLaRima(
	seccion: FilaSeccion,
	catalogo: {
		esquemas: FilaEsquemaRima[];
		posiciones: FilaPosicionRima[];
		grupos: FilaGrupo[];
	}
): boolean {
	if (!id(seccion.arquitectura_referenciada_id)) return false;
	if (unidadDeclaraSuRima(id(seccion.arquitectura_id), catalogo.esquemas, catalogo.posiciones)) {
		return false;
	}
	return !laParteTieneRimaPropia(seccion, catalogo.esquemas, catalogo.grupos);
}

/**
 * Las preguntas de rima que una arquitectura hereda por reutilización, listas para usarse.
 *
 * Cada una es **el grupo de la arquitectura reutilizada**, con su `seccion_id` reescrito a la parte
 * que la toma prestada. Sale con la misma forma que tienen los grupos copiados a mano de la copla
 * real y de la novena —`alcance: 'unidad'`, la sección apuntada, el mismo control y las mismas
 * selecciones—, de modo que todo lo que viene después no distingue una heredada de una propia. Y la
 * respuesta se guarda contra el grupo original, que existe: es exactamente el dato que hoy escribe
 * la copla real, sin la copia.
 *
 * Solo se heredan las preguntas que la arquitectura reutilizada hace **de su unidad**. Una que hable
 * de una parte suya describe un interior que aquí no se materializa, y no se trae.
 */
export function gruposHeredadosPorReutilizacion(
	arquitecturaId: string,
	catalogo: {
		secciones: FilaSeccion[];
		esquemas: FilaEsquemaRima[];
		posiciones: FilaPosicionRima[];
		grupos: FilaGrupo[];
	}
): FilaGrupo[] {
	const heredados: FilaGrupo[] = [];
	for (const seccion of catalogo.secciones) {
		if (id(seccion.arquitectura_id) !== arquitecturaId) continue;
		if (!seccionHeredaLaRima(seccion, catalogo)) continue;
		const referenciada = id(seccion.arquitectura_referenciada_id);
		for (const grupo of catalogo.grupos) {
			if (id(grupo.arquitectura_id) !== referenciada) continue;
			if (grupo.activo === false) continue;
			if (id(grupo.dimension) !== 'rima') continue;
			if (id(grupo.seccion_id) || id(grupo.seccion_tratada_id)) continue;
			heredados.push({
				...grupo,
				arquitectura_id: arquitecturaId,
				seccion_id: seccion.seccion_id,
				alcance: 'unidad',
				heredado_de: referenciada
			} as FilaGrupo);
		}
	}
	return heredados;
}

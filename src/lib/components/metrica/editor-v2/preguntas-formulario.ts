/**
 * Todas las preguntas de una secuencia, en una sola lista plana.
 *
 * **Por qué existe este módulo.** Hasta ahora el editor tenía dos sitios que dibujaban
 * preguntas: `preguntasCompartidas`, para las que apuntan a dos o más realizaciones, y las
 * filas de `buildGridRows` para todo lo demás —las de una sola realización, las de las partes
 * y las de los ciclos—. Con dos sitios, aplicar una manera de preguntar significaba aplicarla
 * dos veces, y el segundo se descubría al abrir una forma que cayera del otro lado: la
 * quintilla de veinticinco versos se veía nueva y la de cinco, vieja.
 *
 * Aquí hay uno solo. Cada pregunta del catálogo aparece una vez, con la lista de
 * realizaciones a las que se le escribe la respuesta, y **quien la pinta no necesita saber de
 * qué forma es**: una serie sin unidades, un soneto con partes y un villancico por ciclos
 * producen la misma clase de objeto.
 *
 * **Lo que se guarda no cambia.** `destinatarias` son exactamente los pares
 * (grupo de elección, realización) que las filas ya resolvían, incluida la sutileza del
 * soneto —los dos esquemas se preguntan en la sección y se escriben en la unidad—, porque se
 * leen de `buildGridRows` en vez de calcularse otra vez. A `anotacion_elecciones` llega lo
 * mismo que llegaba.
 */

import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import { buildGridRows, type GridRow, type GridRowContext, type PreguntaEnFila } from './grid-rows';
import { sectionLabel, type MetricUnitDraft } from './editor-model';

/** A quién se le escribe una respuesta: el par que acaba en `anotacion_elecciones`. */
export type Destinataria = {
	group: MetricCatalogDomainRow;
	owner: MetricUnitDraft;
};

export type PreguntaFormulario = {
	key: string;
	/** «Esquema de rima», y con la parte delante cuando pertenece a una: «Mudanza · Esquema de rima». */
	rotulo: string;
	ayuda: string | null;
	groups: MetricCatalogDomainRow[];
	destinatarias: Destinataria[];
	/**
	 * `secuencia` se responde una vez y no admite excepciones; `unidad` se responde una vez para
	 * todas y se le añaden las que se aparten.
	 *
	 * **No es el `alcance` del catálogo tal cual.** Una pregunta de unidad cuyo pasaje tiene una
	 * sola realización —la quintilla de cinco versos— no tiene de qué apartarse, así que se lee
	 * como una de secuencia. Es el caso que la maqueta no recogió y que en el corpus son 24 de
	 * las 134 secuencias con unidad.
	 */
	alcance: 'secuencia' | 'unidad';
	/** Los dos controles de rima que dejan escribir la respuesta además de elegirla. */
	admiteEscrito: boolean;
	/** Sus opciones son versos que marcar, no una respuesta que elegir: el pie quebrado. */
	esPosicional: boolean;
	/** El rasgo del que cuelga, cuando la pregunta materializa uno que la forma solo admite. */
	rasgoId: string | null;
};

/** Los dos controles de rima que admiten texto escrito. */
function admiteEscrito(group: MetricCatalogDomainRow): boolean {
	const control = String(group.tipo_control);
	return control === 'esquema_rima' || control === 'opciones_y_esquema';
}

/**
 * La familia a la que pertenece una pregunta.
 *
 * Se agrupa por dimensión, enunciado y repertorio, como ya hacía `preguntasCompartidas`: el
 * catálogo puede formular la misma pregunta en dos secciones del mismo nombre y para el editor
 * es una sola. **El repertorio entra en la clave** porque dos preguntas que se llamen igual y
 * ofrezcan cosas distintas no pueden responderse juntas: una se quedaría sin respuesta y nadie
 * lo diría.
 */
function claveDeFamilia(
	group: MetricCatalogDomainRow,
	rotulo: string,
	options: MetricCatalogDomainRow[]
): string {
	const repertorio = options
		.filter(
			(option) =>
				String(option.grupo_eleccion_id) === String(group.grupo_eleccion_id) && option.activo
		)
		.map((option) => String(option.slug))
		.sort()
		.join(',');
	return `${String(group.dimension)}|${rotulo}|${repertorio}`;
}

/**
 * El nombre de la parte, cuando la fila habla de una y no de la unidad entera.
 *
 * La mudanza de un villancico y los cuartetos de un soneto necesitan decirlo —«Mudanza ·
 * Esquema de rima»—; una quintilla no, porque «Quintilla 2 · Esquema de rima» nombraría una
 * realización concreta cuando la pregunta es de todas.
 */
function prefijoDeParte(row: GridRow): string | null {
	if (row.kind === 'acciones') return null;
	if (row.kind === 'realizacion' && !row.section) return null;
	const section = row.kind === 'realizacion' || row.kind === 'fijas' ? row.section : row.section;
	return section ? sectionLabel(section) : null;
}

function esPosicional(group: MetricCatalogDomainRow, options: MetricCatalogDomainRow[]): boolean {
	const propias = options.filter(
		(option) =>
			String(option.grupo_eleccion_id) === String(group.grupo_eleccion_id) && option.activo
	);
	return propias.length > 0 && propias.every((option) => Number(option.posicion_unidad ?? 0) > 0);
}

/**
 * Recorre las filas y devuelve sus preguntas agrupadas por familia.
 *
 * Se lee de las filas y no de `context.groups` a propósito: las filas ya resolvieron a qué
 * realización se le escribe cada respuesta, que es justo lo que no debe cambiar.
 */
export function preguntasDelFormulario(context: GridRowContext): PreguntaFormulario[] {
	const familias = new Map<string, PreguntaFormulario>();
	const vistas = new Set<string>();

	const recoger = (row: GridRow, preguntas: PreguntaEnFila[]) => {
		const prefijo = prefijoDeParte(row);
		for (const pregunta of preguntas) {
			const rotulo = prefijo ? `${prefijo} · ${pregunta.label}` : pregunta.label;
			const groupId = String(pregunta.group.grupo_eleccion_id);
			// Una misma respuesta puede aparecer en dos filas —la pregunta de la sección y la
			// realización que la materializa—: se escribe una vez, así que se cuenta una vez.
			const huella = `${groupId}|${pregunta.owner.realizacion_id}`;
			if (vistas.has(huella)) continue;
			vistas.add(huella);

			const key = claveDeFamilia(pregunta.group, rotulo, context.options);
			const familia = familias.get(key) ?? {
				key,
				rotulo,
				ayuda: pregunta.group.ayuda_editor ? String(pregunta.group.ayuda_editor) : null,
				groups: [],
				destinatarias: [],
				alcance: 'secuencia' as const,
				admiteEscrito: admiteEscrito(pregunta.group),
				esPosicional: esPosicional(pregunta.group, context.options),
				rasgoId: pregunta.group.rasgo_id ? String(pregunta.group.rasgo_id) : null
			};
			if (
				!familia.groups.some(
					(miembro) => String(miembro.grupo_eleccion_id) === groupId
				)
			) {
				familia.groups.push(pregunta.group);
			}
			familia.destinatarias.push({ group: pregunta.group, owner: pregunta.owner });
			familias.set(key, familia);
		}
	};

	for (const row of buildGridRows(context)) {
		if (row.kind === 'acciones') continue;
		recoger(row, row.preguntas);
	}

	return [...familias.values()].map((familia) => ({
		...familia,
		destinatarias: [...familia.destinatarias].sort(
			(primera, segunda) => primera.owner.v_ini - segunda.owner.v_ini
		),
		alcance: familia.destinatarias.length > 1 ? ('unidad' as const) : ('secuencia' as const)
	}));
}

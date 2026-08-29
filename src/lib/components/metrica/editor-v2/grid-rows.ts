/**
 * Qué filas pinta el editor de estructura.
 *
 * La pantalla del editor V2 es una rejilla: a la izquierda la secuencia dibujada verso a
 * verso, a la derecha lo que hay que responder de cada parte. Aquí se decide qué filas
 * existen y en qué orden, aparte del componente, porque es la lógica que se puede probar y
 * porque escribirla dentro de un `{#snippet}` recursivo fue lo que hizo imposible saber qué
 * se estaba viendo.
 *
 * Tres reglas la gobiernan:
 *
 * 1. **Una pregunta vive en su realización.** No hay un segundo sitio donde responderla. La
 *    zona de arriba —`preguntasCompartidas`— no es otro sitio: es un atajo que escribe en
 *    todas, y las filas de abajo siguen enseñando lo que cada una guarda.
 * 2. **Nada se enseña sin contenido.** Un bloque cuyas realizaciones no preguntan nada, no
 *    se pueden alargar ni quitar, se resume en una línea (`fijas`) en vez de repetir
 *    cabeceras vacías.
 * 3. **Una sección que no pregunta nada no pinta contenedor.** La copla del villancico solo
 *    contiene la mudanza; sin esta regla, llegar a su esquema de rima costaba tres niveles
 *    de anidamiento para un desplegable.
 *
 * Lo que se guarda no cambia: cada realización conserva su propia respuesta, como antes.
 */

import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import { seRespondeDentroDeLaUnidad } from '$lib/metrica/alcance';
import {
	childrenOfSection,
	partesDeLaRealizacion,
	extensionSourceUnitFor,
	rootSections,
	sectionHasFixedLength,
	sectionId,
	sectionLabel,
	sectionMaximum,
	sectionMinimum,
	sectionParentId,
	sectionVerseMinimum,
	type MetricChoiceDraft,
	type MetricUnitDraft,
	type MetricUnitPlan
} from './editor-model';

export type GridRowContext = {
	sections: MetricCatalogDomainRow[];
	groups: MetricCatalogDomainRow[];
	options: MetricCatalogDomainRow[];
	/** `esquemas_rima`. Hace falta para saber de qué sección habla una pregunta de la unidad. */
	schemes: MetricCatalogDomainRow[];
	units: MetricUnitDraft[];
	choices: MetricChoiceDraft[];
	unitPlan: MetricUnitPlan | null;
	/** Cómo se llama la unidad que define la forma: su nombre, no «Unidad». */
	unitLabel: string;
	/**
	 * Si la forma tiene alguna arquitectura **intercalable**, de modo que una unidad suelta pueda
	 * declararse excepción —la décima aumentada entre décimas normales—.
	 *
	 * Le importa a la rejilla porque decide si la fila de la unidad se pinta: una unidad sin nada
	 * que decidir se vuelve transparente y deja subir a sus partes, y aquí sí hay algo que decidir.
	 */
	admiteArquitecturaIntercalada?: boolean;
	/**
	 * Las secciones de esas arquitecturas intercalables. La unidad que declara una se dibuja por
	 * ellas y no por las de la secuencia: la aumentada son dos bloques de 4 y 8, no los tres de
	 * la espinela.
	 */
	seccionesIntercaladas?: MetricCatalogDomainRow[];
};

/**
 * Una pregunta tal como se pinta en una fila.
 *
 * `owner` no siempre es la realización de la fila. Los dos esquemas del soneto se guardan en
 * la unidad —describen cómo se entrelazan las rimas de sus dos cuartetos, o de sus dos
 * tercetos, y por eso no cuelgan de ninguno—, pero hablan de una sección y es ahí donde el
 * editor los busca. Se preguntan en la fila de la sección y se escriben en la unidad.
 */
export type PreguntaEnFila = {
	group: MetricCatalogDomainRow;
	owner: MetricUnitDraft;
	/** El enunciado sin el nombre de la sección, cuando la fila ya la nombra. */
	label: string;
};

/** Una realización con lo que se le pregunta y lo que se puede hacer con ella. */
export type GridRealizacionRow = {
	kind: 'realizacion';
	key: string;
	unit: MetricUnitDraft;
	section: MetricCatalogDomainRow | null;
	parentUnitId: string | null;
	depth: number;
	label: string;
	/** Abre un grupo estructural con partes propias, como un ciclo del villancico. */
	container: boolean;
	preguntas: PreguntaEnFila[];
	/** Lo que se dice del rango cuando no se puede tocar. */
	nota: string;
	/** La extensión la escribe el editor: ni la fija la forma ni se calcula de otra sección. */
	lengthEditable: boolean;
	/** Cuántas realizaciones equivalentes hay, contando esta. */
	equivalentes: number;
	removable: boolean;
};

/**
 * Un bloque cuyas realizaciones la norma fija enteras: se resumen en una fila.
 *
 * Puede llevar preguntas. Los dos cuartetos del soneto no se editan por separado —son dos
 * de cuatro versos y no hay nada que decidir de cada uno—, pero su esquema de rima se
 * responde una vez y es de ellos de quien habla: va aquí, y no en una fila aparte que
 * repetiría el nombre de la sección sin dejar tocar nada.
 */
export type GridFijasRow = {
	kind: 'fijas';
	key: string;
	section: MetricCatalogDomainRow | null;
	parentUnitId: string | null;
	depth: number;
	label: string;
	preguntas: PreguntaEnFila[];
	cuantas: number;
	v_ini: number;
	v_fin: number;
	versos: number;
};

/** Una pregunta situada en el lugar estructural del que trata, aunque no materialice versos. */
export type GridPreguntaRow = {
	kind: 'pregunta';
	key: string;
	section: MetricCatalogDomainRow;
	parentUnitId: string;
	depth: number;
	label: string;
	preguntas: PreguntaEnFila[];
};

/** Cuántas hay de una sección repetible, o cómo añadir una más. */
export type GridAccionesRow = {
	kind: 'acciones';
	key: string;
	section: MetricCatalogDomainRow | null;
	parentUnitId: string | null;
	depth: number;
	label: string;
	cuantas: number;
	minimo: number;
	maximo: number | null;
	modo: 'contar' | 'anadir';
};

export type GridRow = GridRealizacionRow | GridFijasRow | GridPreguntaRow | GridAccionesRow;

/** Una pregunta que se responde de una vez para todas las realizaciones a las que apunta. */
export type PreguntaCompartida = {
	key: string;
	label: string;
	help: string | null;
	groups: MetricCatalogDomainRow[];
	/** Cuántas realizaciones responde a la vez. */
	realizaciones: number;
	/**
	 * Si la respuesta se puede escribir, además de o en vez de elegirse.
	 *
	 * Son los dos controles de rima: el abierto puro —ocho grupos, ninguno con opciones— y el que
	 * ofrece un repertorio **y** deja escribir otra cosa, que son 39 grupos más. En los dos casos la
	 * respuesta puede ser texto, y eso cambia dos cosas: el atajo de «en conjunto» tiene que pintar
	 * el campo escrito —si no, la ayuda que invita a escribir otro esquema miente— y la firma con la
	 * que se comparan las unidades no puede separarse por barras, porque una notación como
	 * `abcabc|defdef` lleva una.
	 */
	admiteEscrito: boolean;
};

/**
 * Cómo se lee la respuesta de una realización frente a la de sus equivalentes. Sirve para
 * que se vea de un vistazo cuál diverge, sin esconder ninguna.
 */
export type EstadoDeRespuesta = 'sin_responder' | 'unica' | 'igual' | 'compartida' | 'propia';

/** Las composiciones variables crecen por sus partes; no mezclan atajos globales con ciclos. */
export function usaRespuestasPorPartes(context: GridRowContext): boolean {
	return Boolean(
		context.unitPlan &&
		!context.unitPlan.countFromRange &&
		rootSections(context.sections).length > 0
	);
}

function nodeSectionId(section: MetricCatalogDomainRow | null): string | null {
	return section ? sectionId(section) : null;
}

export function nodeLabel(context: GridRowContext, section: MetricCatalogDomainRow | null): string {
	return section ? sectionLabel(section) : context.unitLabel;
}

function nodeInstanceMinimum(section: MetricCatalogDomainRow | null): number {
	return section ? sectionMinimum(section) : 1;
}

function nodeInstanceMaximum(section: MetricCatalogDomainRow | null): number | null {
	return section ? sectionMaximum(section) : null;
}

function nodeHasFixedLength(
	context: GridRowContext,
	section: MetricCatalogDomainRow | null
): boolean {
	if (section) return sectionHasFixedLength(section);
	const extent = context.unitPlan?.extent ?? null;
	return extent !== null && extent.minimum === extent.maximum;
}

function nodeVerseMinimum(context: GridRowContext, section: MetricCatalogDomainRow | null): number {
	if (section) return sectionVerseMinimum(section);
	return context.unitPlan?.extent?.minimum ?? 1;
}

export function instancesOf(
	units: MetricUnitDraft[],
	targetSectionId: string | null,
	parentUnitId: string | null
): MetricUnitDraft[] {
	return units.filter(
		(unit) => unit.seccion_id === targetSectionId && unit.realizacion_padre_id === parentUnitId
	);
}

/** Las secciones que aparecen o desaparecen al responder una pregunta, no a mano. */
export function controlledSectionIds(options: MetricCatalogDomainRow[]): Set<string> {
	return new Set(
		options
			.map((option) => (option.materializa_seccion_id ? String(option.materializa_seccion_id) : ''))
			.filter(Boolean)
	);
}

/** La única sección que las respuestas de un grupo pueden materializar. */
export function controlledSectionForGroup(
	context: GridRowContext,
	group: MetricCatalogDomainRow
): string | null {
	const sectionIds = new Set(
		context.options
			.filter(
				(option) =>
					option.activo &&
					String(option.grupo_eleccion_id) === String(group.grupo_eleccion_id) &&
					Boolean(option.materializa_seccion_id)
			)
			.map((option) => String(option.materializa_seccion_id))
	);
	return sectionIds.size === 1 ? [...sectionIds][0] : null;
}

/**
 * De qué sección habla una pregunta que se guarda en la unidad.
 *
 * `seccion_id` dice dónde se responde, así que un grupo que la declare se pregunta tantas
 * veces como veces aparezca la sección. Cuando la respuesta es una sola pero describe una
 * sección concreta, el grupo la deja sin declarar y el sujeto lo ponen sus esquemas, con
 * `esquemas_rima.seccion_id`. Son los dos del soneto, y sin leerlo el editor los pintaba en
 * la unidad y dejaba debajo dos filas que repetían el nombre de la sección sin dejar tocar
 * nada.
 *
 * Devuelve nulo salvo que **todos** sus esquemas señalen la misma sección: media respuesta
 * no basta para mover una pregunta de sitio.
 */
export function seccionSujetoDeGrupo(
	context: GridRowContext,
	group: MetricCatalogDomainRow
): string | null {
	if (group.seccion_id) return null;
	const opciones = context.options.filter(
		(option) =>
			String(option.grupo_eleccion_id) === String(group.grupo_eleccion_id) && option.activo
	);
	if (opciones.length === 0) return null;
	const secciones = new Set<string>();
	for (const option of opciones) {
		if (!option.esquema_rima_id) return null;
		const scheme = context.schemes.find(
			(candidate) => String(candidate.esquema_rima_id) === String(option.esquema_rima_id)
		);
		if (!scheme?.seccion_id) return null;
		secciones.add(String(scheme.seccion_id));
	}
	return secciones.size === 1 ? [...secciones][0] : null;
}

/**
 * Las preguntas de una realización. Una pregunta sin sección se refiere a la unidad entera,
 * no a una parte suya, y por eso se dirige a la realización que no cuelga de ninguna otra.
 * Las que hablan de una sección se preguntan allí, no aquí.
 */
export function groupsForUnit(
	context: GridRowContext,
	unit: MetricUnitDraft
): MetricCatalogDomainRow[] {
	return context.groups.filter((group) => {
		if (!seRespondeDentroDeLaUnidad(group.alcance)) return false;
		// Si la respuesta hace aparecer una sección, visualmente pertenece a ese punto de la
		// secuencia. Sigue guardándose en esta realización; solo cambia dónde se pregunta.
		if (controlledSectionForGroup(context, group)) return false;
		if (group.seccion_id) return String(group.seccion_id) === unit.seccion_id;
		if (unit.realizacion_padre_id !== null) return false;
		return seccionSujetoDeGrupo(context, group) === null;
	});
}

/**
 * Una repetición que toma su extensión de la misma sección que materializa empieza después de
 * la primera aparición: esa primera realización es la fuente, no una repetición de sí misma.
 */
export function groupStartsAfterFirstOccurrence(
	group: MetricCatalogDomainRow,
	options: MetricCatalogDomainRow[]
): boolean {
	if (group.dimension !== 'repeticion') return false;
	return options.some(
		(option) =>
			String(option.grupo_eleccion_id) === String(group.grupo_eleccion_id) &&
			Boolean(option.materializa_seccion_id) &&
			String(option.materializa_seccion_id) === String(option.extension_desde_seccion_id ?? '')
	);
}

/** Las realizaciones propietarias de una pregunta, con su ordinal estructural aplicado. */
export function targetUnitsForGroup(
	units: MetricUnitDraft[],
	group: MetricCatalogDomainRow,
	options: MetricCatalogDomainRow[]
): MetricUnitDraft[] {
	const targets = units
		.filter((unit) =>
			group.seccion_id
				? String(group.seccion_id) === unit.seccion_id
				: unit.realizacion_padre_id === null
		)
		.sort(
			(a, b) =>
				a.v_ini - b.v_ini ||
				a.orden - b.orden ||
				a.realizacion_id.localeCompare(b.realizacion_id)
		);
	return groupStartsAfterFirstOccurrence(group, options) ? targets.slice(1) : targets;
}

/** Las realizaciones a las que apunta una pregunta, estén donde estén en el árbol. */
export function unitsForGroup(
	context: GridRowContext,
	group: MetricCatalogDomainRow
): MetricUnitDraft[] {
	return targetUnitsForGroup(context.units, group, context.options);
}

/**
 * La sección de la que una realización toma su extensión, cuando una respuesta lo declara:
 * la repetición total del estribillo mide lo que mide el estribillo.
 */
export function extensionReferenceFor(
	context: GridRowContext,
	unit: MetricUnitDraft
): MetricCatalogDomainRow | null {
	const option = context.options.find(
		(candidate) =>
			String(candidate.materializa_seccion_id ?? '') === unit.seccion_id &&
			Boolean(candidate.extension_desde_seccion_id) &&
			context.choices.some(
				(choice) =>
					choice.opcion_eleccion_id === String(candidate.opcion_eleccion_id) &&
					choice.realizacion_id === unit.realizacion_padre_id
			)
	);
	if (!option?.extension_desde_seccion_id) return null;
	if (!extensionSourceUnitFor(unit, context.units, context.choices, context.options)) return null;
	const referenceSectionId = String(option.extension_desde_seccion_id);
	return context.sections.find((section) => sectionId(section) === referenceSectionId) ?? null;
}

function canAddHere(
	context: GridRowContext,
	section: MetricCatalogDomainRow | null,
	parentUnitId: string | null
): boolean {
	const list = instancesOf(context.units, nodeSectionId(section), parentUnitId);
	// Cuántas unidades contiene el pasaje se deriva del rango: no se añaden a mano.
	if (section === null) {
		if (parentUnitId !== null || context.unitPlan === null) return false;
		// Una composición de extensión variable crece mediante sus ciclos o secciones, no
		// añadiendo otra composición dentro de la misma secuencia.
		if (usaRespuestasPorPartes(context)) return false;
		return !context.unitPlan.countFromRange;
	}
	const maximum = sectionMaximum(section);
	return maximum === null || list.length < maximum;
}

function canRemoveHere(
	context: GridRowContext,
	section: MetricCatalogDomainRow | null,
	parentUnitId: string | null
): boolean {
	const list = instancesOf(context.units, nodeSectionId(section), parentUnitId);
	if (section === null) {
		if (parentUnitId !== null || context.unitPlan === null) return false;
		if (usaRespuestasPorPartes(context)) return false;
		return !context.unitPlan.countFromRange && list.length > 1;
	}
	return list.length > sectionMinimum(section);
}

function lengthEditableFor(
	context: GridRowContext,
	section: MetricCatalogDomainRow | null,
	unit: MetricUnitDraft
): boolean {
	if (childrenOfSection(context.sections, nodeSectionId(section)).length > 0) return false;
	if (extensionReferenceFor(context, unit)) return false;
	// **Una unidad que declara su propia arquitectura mide lo que mida esa**, no lo que fija la de
	// la secuencia: la décima aumentada son doce versos entre décimas de diez. Su extensión la pone
	// el editor y la comprueba la cobertura del rango.
	if (!section && unit.arquitectura_id) return true;
	return !nodeHasFixedLength(context, section);
}

function notaFor(
	context: GridRowContext,
	section: MetricCatalogDomainRow | null,
	unit: MetricUnitDraft
): string {
	if (childrenOfSection(context.sections, nodeSectionId(section)).length > 0) {
		return 'rango calculado desde sus partes';
	}
	const reference = extensionReferenceFor(context, unit);
	if (reference) {
		const versos = unit.v_fin - unit.v_ini + 1;
		return `${versos} ${versos === 1 ? 'verso' : 'versos'}, calculados desde «${sectionLabel(reference)}»`;
	}
	// Lo mismo en la nota: decir «10 versos fijos» sobre una aumentada de doce sería mentir.
	if (!section && unit.arquitectura_id) return 'arquitectura propia de esta unidad';
	if (nodeHasFixedLength(context, section)) {
		const versos = nodeVerseMinimum(context, section);
		return `${versos} ${versos === 1 ? 'verso' : 'versos'} fijos`;
	}
	return '';
}

/**
 * Las filas de la rejilla, en orden de verso.
 *
 * El recorrido es el del árbol de realizaciones, pero el resultado es plano: cada fila sabe
 * su profundidad y la pinta con un filete a la izquierda. Plano se puede leer, contar y
 * probar; anidado en `{#snippet}` recursivos, no.
 */
export function buildGridRows(context: GridRowContext): GridRow[] {
	const out: GridRow[] = [];
	const roots: (MetricCatalogDomainRow | null)[] = context.unitPlan
		? [null]
		: rootSections(context.sections);
	for (const root of roots) walk(context, root, null, 0, out);
	return out;
}

/** La realización que no cuelga de ninguna otra: donde se guardan las preguntas de unidad. */
function unidadDe(context: GridRowContext, unitId: string | null): MetricUnitDraft | null {
	let actual = context.units.find((unit) => unit.realizacion_id === unitId) ?? null;
	while (actual && actual.realizacion_padre_id !== null) {
		actual =
			context.units.find((unit) => unit.realizacion_id === actual!.realizacion_padre_id) ??
			null;
	}
	return actual;
}

/** Sin el nombre de la sección delante, que ya lo dice la fila. */
function sinPrefijoDeSeccion(nombre: string, etiquetaDeSeccion: string): string {
	if (nombre === etiquetaDeSeccion) return 'Modalidad';
	const prefijo = `${etiquetaDeSeccion} · `;
	return nombre.startsWith(prefijo) ? nombre.slice(prefijo.length) : nombre;
}

/**
 * Preguntas que se guardan en el contenedor pero hacen aparecer esta sección.
 *
 * En el villancico la repetición se guarda en el ciclo, pero se lee después de la copla,
 * donde puede materializar el estribillo. Propietario y lugar visual no tienen por qué ser
 * el mismo dato, igual que en los esquemas del soneto.
 */
function materializingQuestions(
	context: GridRowContext,
	section: MetricCatalogDomainRow | null,
	parentUnitId: string | null
): PreguntaEnFila[] {
	if (!section || !parentUnitId) return [];
	const owner = context.units.find((unit) => unit.realizacion_id === parentUnitId);
	if (!owner) return [];
	const targetSectionId = sectionId(section);
	return context.groups
		.filter(
			(group) =>
				seRespondeDentroDeLaUnidad(group.alcance) &&
				unitsForGroup(context, group).some(
					(unit) => unit.realizacion_id === owner.realizacion_id
				) &&
				controlledSectionForGroup(context, group) === targetSectionId
		)
		.map((group) => ({
			group,
			owner,
			label: sinPrefijoDeSeccion(String(group.nombre), sectionLabel(section))
		}));
}

function walk(
	context: GridRowContext,
	section: MetricCatalogDomainRow | null,
	parentUnitId: string | null,
	depth: number,
	out: GridRow[]
): void {
	const targetSectionId = nodeSectionId(section);
	const list = instancesOf(context.units, targetSectionId, parentUnitId);
	const intercaladas = context.seccionesIntercaladas ?? [];
	// Las partes de una realización dependen de **ella**, no solo de su sección: una unidad que
	// declara ser otra arquitectura se divide por las de esa. `children` es el caso general, que
	// vale para todo lo demás y para las decisiones que se toman antes de recorrer la lista.
	const partesDe = (unit: MetricUnitDraft) =>
		partesDeLaRealizacion(context.sections, unit, intercaladas);
	const children = childrenOfSection(
		intercaladas.some((seccion) => sectionId(seccion) === targetSectionId)
			? intercaladas
			: context.sections,
		targetSectionId
	);
	const label = nodeLabel(context, section);
	const blockKey = `${targetSectionId ?? 'unidad'}|${parentUnitId ?? 'raiz'}`;
	const preguntasMaterializadoras = materializingQuestions(context, section, parentUnitId);

	// Las preguntas que se guardan en la unidad pero hablan de esta sección. Se responden una
	// vez para el bloque entero, así que van en su fila y no en la de cada realización.
	const unidad = unidadDe(context, parentUnitId);
	const preguntasDelBloque: PreguntaEnFila[] =
		targetSectionId && unidad
			? context.groups
					.filter(
						(group) =>
							seRespondeDentroDeLaUnidad(group.alcance) &&
							seccionSujetoDeGrupo(context, group) === targetSectionId
					)
					.map((group) => ({
						group,
						owner: unidad,
						label: sinPrefijoDeSeccion(String(group.nombre), label)
					}))
			: [];

	const minimo = nodeInstanceMinimum(section);
	const maximo = nodeInstanceMaximum(section);
	const countable = maximo === null || maximo > 1;
	const puedeAnadir = canAddHere(context, section, parentUnitId);
	const puedeQuitar = canRemoveHere(context, section, parentUnitId);
	const controlada = controlledSectionIds(context.options).has(targetSectionId ?? '');
	// Cuando el número gobierna el bloque, quitar una a mano sobra: se escribe el número.
	//
	// Y una sección que aparece porque una respuesta la materializa tampoco se quita a mano:
	// se quita cambiando la respuesta. Quitarla dejaba «se repite entero» apuntando a una
	// repetición que ya no existe, y nada volvía a crearla hasta tocar la respuesta otra vez.
	// Los contenedores repetibles se gestionan como unidades legibles: «Añadir ciclo» y
	// «Quitar ciclo». Un contador numérico separa la acción de la parte a la que afecta.
	const accionesIndividuales = section !== null && children.length > 0 && !controlada && countable;
	const cuentaVisible =
		!accionesIndividuales && !controlada && countable && (puedeAnadir || puedeQuitar);
	const removable = puedeQuitar && !cuentaVisible && !controlada;

	// Regla 2: un bloque que la norma fija entero y que no pregunta nada es una línea.
	//
	// «La norma las fija enteras» tiene que ser verdad para resumirlas así. No lo es cuando la
	// extensión se calcula desde otra sección —la repetición del estribillo mide lo que mide
	// la cabeza—: ahí la fila tiene algo que decir, y lo dice en su nota.
	const bloqueFijo =
		list.length > 0 &&
		children.length === 0 &&
		!cuentaVisible &&
		!removable &&
		nodeHasFixedLength(context, section) &&
		list.every(
			(unit) => groupsForUnit(context, unit).length === 0 && !extensionReferenceFor(context, unit)
		);

	if (bloqueFijo) {
		const first = list[0];
		const last = list[list.length - 1];
		out.push({
			kind: 'fijas',
			key: `fijas|${blockKey}`,
			section,
			parentUnitId,
			depth,
			label,
			preguntas: [...preguntasDelBloque, ...preguntasMaterializadoras],
			cuantas: list.length,
			v_ini: first.v_ini,
			v_fin: last.v_fin,
			versos: first.v_fin - first.v_ini + 1
		});
	} else {
		const numerada = (maximo === null || maximo > 1) && list.length > 1;
		for (const [index, unit] of list.entries()) {
			const groups = groupsForUnit(context, unit);
			const lengthEditable = lengthEditableFor(context, section, unit);
			// Regla 3: un contenedor que no pregunta nada ni se puede tocar no pinta fila; sus
			// partes suben un nivel. Solo cuando es único, para no perder de vista dónde acaba
			// uno y empieza el siguiente.
			//
			// Un bloque que se puede repetir sí conserva la fila aunque por ahora haya uno: es la
			// frontera que deja claro dónde acabará cada ciclo cuando se añada el siguiente.
			// Y una unidad que puede declararse excepción **nunca** es transparente: ahí vive la
			// única decisión que tiene, y sin fila no habría dónde tomarla.
			const puedeSerExcepcion =
				Boolean(context.admiteArquitecturaIntercalada) &&
				section === null &&
				parentUnitId === null;
			const transparente =
				children.length > 0 &&
				list.length === 1 &&
				groups.length === 0 &&
				!lengthEditable &&
				!removable &&
				!accionesIndividuales &&
				!puedeSerExcepcion &&
				(section === null || !cuentaVisible);

			if (!transparente) {
				out.push({
					kind: 'realizacion',
					key: unit.realizacion_id,
					unit,
					section,
					parentUnitId,
					depth,
					label: section?.primera_realizacion_define_patron
						? index === 0
							? `${label} modelo`
							: `${label} ${index + 1}`
						: numerada
							? `${label} ${index + 1}`
							: label,
					container: children.length > 0,
					preguntas: [
						// Las del bloque solo en la primera: se responden una vez para todas.
						...(index === 0 ? preguntasDelBloque : []),
						...(index === 0 ? preguntasMaterializadoras : []),
						...groups.map((group) => ({
							group,
							owner: unit,
							label: sinPrefijoDeSeccion(String(group.nombre), label)
						}))
					],
					nota: section?.primera_realizacion_define_patron
						? index === 0
							? 'Declara el patrón que repiten las demás estancias'
							: 'Repite extensión, medidas y rima de la estancia modelo'
						: notaFor(context, section, unit),
					lengthEditable,
					equivalentes: context.units.filter(
						(candidate) => candidate.seccion_id === unit.seccion_id
					).length,
					removable
				});
			}

			for (const child of partesDe(unit)) {
				walk(context, child, unit.realizacion_id, transparente ? depth : depth + 1, out);
			}
		}
	}

	// Algunas respuestas no ponen versos —el estribillo puede sobreentenderse—, pero la
	// pregunta conserva su lugar después de la copla. No se inventa una realización ni rango.
	if (list.length === 0 && preguntasMaterializadoras.length > 0 && section) {
		out.push({
			kind: 'pregunta',
			key: `pregunta|${blockKey}`,
			section,
			parentUnitId: parentUnitId!,
			depth,
			label,
			preguntas: preguntasMaterializadoras
		});
	}

	if (cuentaVisible) {
		out.push({
			kind: 'acciones',
			key: `acciones|${blockKey}`,
			section,
			parentUnitId,
			depth,
			label,
			cuantas: list.length,
			minimo,
			maximo,
			modo: 'contar'
		});
	} else if (!controlada && puedeAnadir) {
		out.push({
			kind: 'acciones',
			key: `acciones|${blockKey}`,
			section,
			parentUnitId,
			depth,
			label,
			cuantas: list.length,
			minimo,
			maximo,
			modo: 'anadir'
		});
	}
}

/**
 * Las preguntas que admiten responderse de una vez para todas sus realizaciones.
 *
 * Solo aparecen cuando apuntan a **dos o más**: con una sola, el atajo diría lo mismo que la
 * fila de esa realización y sería el segundo domicilio que la reforma quita. No se mueve
 * nada al aparecer la segunda: la fila de cada realización sigue donde estaba.
 *
 * Se agrupan por dimensión y enunciado porque el catálogo puede formular la misma pregunta
 * en dos secciones distintas del mismo nombre, y para el editor es una sola.
 *
 * **La medida de una sección aparece aquí aunque el contenedor pregunte además por la de
 * toda la composición.** No son la misma pregunta: una recorre las secciones y la otra las
 * realizaciones de una sola. El villancico heterométrico que documenta Navarro Tomás
 * —cuarteta octosilábica con estribillo en cuarteta hexasílaba— necesita las dos: se
 * responde la composición entera y se corrige después el estribillo, en sus tres ciclos, de
 * una vez.
 */
export function preguntasCompartidas(context: GridRowContext): PreguntaCompartida[] {
	const families = new Map<string, PreguntaCompartida>();
	for (const group of context.groups) {
		if (!seRespondeDentroDeLaUnidad(group.alcance)) continue;
		if (!group.permite_aplicar_global) continue;
		const opciones = context.options.filter(
			(option) =>
				String(option.grupo_eleccion_id) === String(group.grupo_eleccion_id) && option.activo
		);
		const esPosicional =
			opciones.length > 0 && opciones.every((option) => Number(option.posicion_unidad ?? 0) > 0);
		/**
		 * **El esquema escrito también se responde en conjunto.**
		 *
		 * El abierto puro estuvo excluido de aquí sin que nada dijera por qué: la razón era técnica
		 * —el control común hablaba en slugs y esto es texto—, no que responder ocho sextillas
		 * iguales una a una tuviera sentido. Y el mixto entraba, pero pintado solo con su
		 * repertorio: en la octava real la ayuda decía «marca ABABABCC si es el que lees, y si no,
		 * escribe el que veas» y en conjunto no había dónde escribir.
		 */
		const admiteEscrito =
			String(group.tipo_control) === 'esquema_rima' ||
			String(group.tipo_control) === 'opciones_y_esquema';
		// Las respuestas múltiples ordinarias no tienen un único valor que copiar. Las
		// posicionales sí: se copia la serie completa, una respuesta por posición. Es el caso
		// del pareado, cuya medida declara por separado sus dos versos.
		if (Number(group.selecciones_max ?? 1) !== 1 && !esPosicional) continue;
		const destinatarias = unitsForGroup(context, group);
		if (destinatarias.length < 2) continue;
		const key = `${String(group.dimension)}|${String(group.nombre)}`;
		const family = families.get(key) ?? {
			key,
			label: String(group.nombre),
			help: group.ayuda_editor ? String(group.ayuda_editor) : null,
			groups: [],
			realizaciones: 0,
			admiteEscrito
		};
		family.groups.push(group);
		family.realizaciones += destinatarias.length;
		families.set(key, family);
	}
	return [...families.values()];
}

/** Las secciones opcionales que están o no en todas las realizaciones de su contenedor. */
export function seccionesOpcionalesUniformes(context: GridRowContext): MetricCatalogDomainRow[] {
	const controladas = controlledSectionIds(context.options);
	return context.sections.filter((section) => {
		if (sectionMinimum(section) !== 0 || sectionMaximum(section) !== 1) return false;
		if (controladas.has(sectionId(section))) return false;
		return parentInstancesOf(context, section).length >= 1;
	});
}

/** Las instancias del contenedor de una sección: las coplas, para el enlace o vuelta. */
export function parentInstancesOf(
	context: GridRowContext,
	section: MetricCatalogDomainRow
): MetricUnitDraft[] {
	const parentId = sectionParentId(section);
	return context.units.filter((unit) => unit.seccion_id === parentId);
}

export function presenciaDeSeccion(context: GridRowContext, section: MetricCatalogDomainRow) {
	const parents = parentInstancesOf(context, section);
	const conSeccion = parents.filter((parent) =>
		context.units.some(
			(unit) =>
				unit.realizacion_padre_id === parent.realizacion_id &&
				unit.seccion_id === sectionId(section)
		)
	);
	return {
		parents,
		present: conSeccion.length,
		everywhere: conSeccion.length === parents.length && parents.length > 0,
		nowhere: conSeccion.length === 0
	};
}

/** Qué contesta una realización a una pregunta, sin sus identificadores. */
export function firmaDeRespuesta(
	choices: MetricChoiceDraft[],
	groupId: string,
	unitId: string
): string {
	return choices
		.filter(
			(choice) => choice.grupo_eleccion_id === groupId && choice.realizacion_id === unitId
		)
		.map((choice) => `${choice.opcion_eleccion_id ?? ''}:${choice.valor_texto ?? ''}`)
		.sort()
		.join(',');
}

/**
 * Si la respuesta de una realización coincide con la de sus equivalentes o se aparta.
 *
 * No esconde nada: las cuatro se pintan y solo cambia el énfasis. `igual` se atenúa porque
 * ya se lee arriba; `propia` se destaca porque es la excepción que el editor ha marcado.
 */
export function estadoDeRespuesta(
	context: GridRowContext,
	group: MetricCatalogDomainRow,
	unit: MetricUnitDraft
): EstadoDeRespuesta {
	const groupId = String(group.grupo_eleccion_id);
	const propia = firmaDeRespuesta(context.choices, groupId, unit.realizacion_id);
	if (!propia) return 'sin_responder';
	const equivalentes = unitsForGroup(context, group);
	if (equivalentes.length < 2) return 'unica';
	const todas = equivalentes.map((candidate) =>
		firmaDeRespuesta(context.choices, groupId, candidate.realizacion_id)
	);
	if (todas.every((firma) => firma === propia)) return 'igual';
	return todas.filter((firma) => firma === propia).length > 1 ? 'compartida' : 'propia';
}

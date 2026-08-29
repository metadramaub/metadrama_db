<script lang="ts">
	import type { Snippet } from 'svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import SegmentedChoice from '$lib/components/ui/segmented-choice.svelte';
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import type { FilaDeRima, Rejilla } from '$lib/metrica/rejilla';
	import { normalizeRhymeSymbol } from './rhyme-notation';
	import MetricChoiceField from './MetricChoiceField.svelte';
	import MetricFamilyControl from './MetricFamilyControl.svelte';
	import MetricGridRow from './MetricGridRow.svelte';
	import MetricVersePatternField from './MetricVersePatternField.svelte';
	import { compactRhymeNotation } from './rhyme-notation';
	import {
		haveAlternativesByPosition,
		isPartialPositionalSelection
	} from './positional-options';
	import {
		addMetricUnit as addMetricUnitBase,
		addSectionInstance as addSectionInstanceBase,
		reflowMetricUnits as reflowMetricUnitsBase,
		removeMetricUnitTree,
		sectionId,
		sectionLabel,
		sectionVerseMaximum,
		sectionVerseMinimum,
		syncChoiceMaterializedSections,
		unitIdsInTree,
		type MetricChoiceDraft,
		type MetricUnitDraft,
		type MetricUnitPlan
	} from './editor-model';
	import {
		buildGridRows,
		estadoDeRespuesta,
		nodeLabel,
		preguntasCompartidas,
		presenciaDeSeccion,
		parentInstancesOf,
		seccionesOpcionalesUniformes,
		unitsForGroup,
		usaRespuestasPorPartes,
		type GridRowContext,
		type GridFijasRow,
		type GridRealizacionRow,
		type GridRow,
		type PreguntaCompartida,
		type PreguntaEnFila
	} from './grid-rows';

	/**
	 * La estructura de la secuencia, como una rejilla: a la izquierda lo que el pasaje es
	 * —unidades, secciones y sus rangos, en orden de verso—, a la derecha lo que hay que
	 * responder de cada parte.
	 *
	 * Las unidades son siempre el domicilio visible de sus respuestas. Cuando una pregunta
	 * apunta a varias realizaciones, el panel de edición conjunta es una operación por lotes:
	 * se abre a petición, declara sus destinatarias y solo escribe al confirmar.
	 *
	 * Qué filas existen se decide en `grid-rows.ts`, que es donde se puede probar.
	 */
	const props = $props<{
		sequenceStart: number;
		sections: MetricCatalogDomainRow[];
		groups: MetricCatalogDomainRow[];
		options: MetricCatalogDomainRow[];
		/** `esquemas_rima`: dice de qué sección habla una pregunta que se guarda en la unidad. */
		schemes: MetricCatalogDomainRow[];
		/** La norma dibujada verso a verso, para anotar también lo que no se pregunta. */
		rejilla?: Rejilla | null;
		units: MetricUnitDraft[];
		choices: MetricChoiceDraft[];
		unitPlan: MetricUnitPlan | null;
		onUnitsChange: (units: MetricUnitDraft[]) => void;
		onChoicesChange: (choices: MetricChoiceDraft[]) => void;
		onUnitsRemoved: (unitIds: string[]) => void;
		/**
		 * Preguntas que el contenedor responde para toda la composición, ya como filas. La
		 * medida es la única por ahora: recorre las secciones, que es un eje que el editor de
		 * estructura no ve, porque él recorre las realizaciones de cada una.
		 */
		globalQuestions?: Snippet;
		/** Cómo se llama la unidad que define la forma: su nombre, no «Unidad». */
		unitLabel?: string;
		/**
		 * Los regímenes de rima entre los que elegir al escribir un esquema, y solo cuando la
		 * arquitectura no declara uno único. Los calcula el contenedor, que ve el catálogo entero.
		 */
		rhymeRegimes?: { slug: string; etiqueta: string }[];
		/**
		 * Las arquitecturas de la forma que el catálogo declara **intercalables**: pueden aparecer
		 * entre realizaciones de otra sin abrir otra secuencia. Hoy solo la décima aumentada. Vacío
		 * en todas las demás formas, y entonces la fila no ofrece nada.
		 */
		interleavedArchitectures?: { arquitectura_id: string; nombre: string; descripcion: string | null }[];
		/** Sus secciones, para dibujar y medir la unidad que declare una de ellas. */
		interleavedSections?: MetricCatalogDomainRow[];
		onUnitArchitectureChange?: (unit: MetricUnitDraft, arquitecturaId: string | null) => void;
	}>();

	// Las funciones del modelo que crean o recolocan realizaciones necesitan conocer las secciones
	// intercaladas. Se envuelven con el mismo nombre —y la misma firma menos ese último
	// argumento— para no repetir el dato en la decena de sitios desde donde se llaman.
	const intercaladasDeLaForma = () => props.interleavedSections ?? [];
	const reflowMetricUnits: typeof reflowMetricUnitsBase = (
		units,
		sections,
		sequenceStart,
		choices = [],
		options = []
	) =>
		reflowMetricUnitsBase(
			units,
			sections,
			sequenceStart,
			choices,
			options,
			intercaladasDeLaForma()
		);
	const addSectionInstance: typeof addSectionInstanceBase = (
		units,
		sections,
		targetSectionId,
		parentUnitId,
		sequenceStart,
		choices = [],
		options = []
	) =>
		addSectionInstanceBase(
			units,
			sections,
			targetSectionId,
			parentUnitId,
			sequenceStart,
			choices,
			options,
			intercaladasDeLaForma()
		);
	const addMetricUnit = addMetricUnitBase;

	/** Por qué el número de versos no se puede tocar cuando la forma lo fija. */
	const EXTENT_HELP =
		'La forma fija esta extensión, así que no se cambia aquí. Si al texto le falta o le sobra un verso, regístralo como desviación.';

	const context = $derived<GridRowContext>({
		sections: props.sections,
		groups: props.groups,
		options: props.options,
		schemes: props.schemes ?? [],
		units: props.units,
		choices: props.choices,
		unitPlan: props.unitPlan,
		unitLabel: props.unitLabel ?? 'Unidad',
		admiteArquitecturaIntercalada: (props.interleavedArchitectures ?? []).length > 0,
		seccionesIntercaladas: props.interleavedSections ?? []
	});

	/**
	 * En una composición que crece por ciclos, responder arriba y por parte mezcla dos escalas
	 * incompatibles. Se responde únicamente en cabeza, mudanza, enlace y estribillo.
	 */
	const respondePorPartes = $derived(usaRespuestasPorPartes(context));
	const rows = $derived(buildGridRows(context));
	/**
	 * Las preguntas comunes, **en el mismo orden en que se leen abajo**.
	 *
	 * Abajo el orden lo manda la estructura: la copla real se pinta antes que sus dos quintillas, así
	 * que sus quebrados salen antes que las rimas. Arriba mandaba el `orden` del catálogo, que pone
	 * las rimas primero, y las dos listas decían lo mismo al revés. Se alinean a la estructura, que
	 * es la que no se puede reordenar. Dentro de cada nivel sigue mandando el catálogo.
	 */
	const comunes = $derived(
		(respondePorPartes ? [] : preguntasCompartidas(context))
			.map((pregunta: PreguntaCompartida, indice: number) => ({ pregunta, indice }))
			.sort((a, b) => {
				const deSeccion = (entrada: { pregunta: PreguntaCompartida }) =>
					entrada.pregunta.groups.every(
						(group: MetricCatalogDomainRow) => group.seccion_id
					)
						? 1
						: 0;
				return deSeccion(a) - deSeccion(b) || a.indice - b.indice;
			})
			.map((entrada) => entrada.pregunta)
	);
	const opcionales = $derived(respondePorPartes ? [] : seccionesOpcionalesUniformes(context));
	/**
	 * **Cómo se está respondiendo, para todas las preguntas a la vez.**
	 *
	 * Hubo un intento con un interruptor por familia de preguntas, y estaba mal: al pedir «una a
	 * una» en la rima, los quebrados —que también varían de unidad en unidad— seguían plegados, y
	 * el botón se repetía en cada pregunta diciendo cosas distintas en cada una. El modo es de la
	 * pantalla, no de cada pregunta.
	 *
	 * Solo hay dos, porque el tercero no era un modo sino una consecuencia: en conjunto, con
	 * unidades que se apartan, es lo mismo que en conjunto. Lo que se elige es **qué unidad se
	 * aparta**, no un modo aparte.
	 */
	let modoDeRespuesta = $state<'conjunto' | 'una_a_una'>('conjunto');


	let unidadesPlegadas = $state(new Set<string>());
	let pendingPositionsByAnswer = $state<Record<string, number[]>>({});
	const unitShortName = $derived(
		String(props.unitLabel ?? 'unidad').split(/\s+/)[0].toLocaleLowerCase('es')
	);
	const hayAjustesDeComposicion = $derived(
		(!respondePorPartes && Boolean(props.globalQuestions)) || opcionales.length > 0
	);
	const hayZonaComun = $derived(hayAjustesDeComposicion || comunes.length > 0);


	function pendingAnswerKey(groupId: string, unitId: string): string {
		return `${groupId}|${unitId}`;
	}

	function pendingPositionsFor(groupId: string, unitId: string): number[] {
		return pendingPositionsByAnswer[pendingAnswerKey(groupId, unitId)] ?? [];
	}

	function setPendingPositionsFor(groupId: string, unitId: string, positions: number[]) {
		const key = pendingAnswerKey(groupId, unitId);
		const next = { ...pendingPositionsByAnswer };
		if (positions.length > 0) next[key] = positions;
		else delete next[key];
		pendingPositionsByAnswer = next;
	}

	function optionsForGroup(groupId: string): MetricCatalogDomainRow[] {
		return props.options
			.filter(
				(option: MetricCatalogDomainRow) =>
					String(option.grupo_eleccion_id) === groupId && option.activo
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.orden ?? 999) - Number(b.orden ?? 999)
			);
	}

	function selectedChoiceIds(groupId: string, unitId: string): string[] {
		return props.choices
			.filter(
				(choice: MetricChoiceDraft) =>
					choice.grupo_eleccion_id === groupId &&
					choice.realizacion_id === unitId &&
					Boolean(choice.opcion_eleccion_id)
			)
			.map((choice: MetricChoiceDraft) => choice.opcion_eleccion_id as string);
	}

	function choiceTextValue(groupId: string, unitId: string): string {
		return (
			props.choices.find(
				(choice: MetricChoiceDraft) =>
					choice.grupo_eleccion_id === groupId &&
					choice.realizacion_id === unitId &&
					Boolean(choice.valor_texto)
			)?.valor_texto ?? ''
		);
	}

	function normalizeRhymeScheme(value: string): string {
		return compactRhymeNotation(value);
	}

	function sectionDefinesPattern(section: MetricCatalogDomainRow | null): boolean {
		return section?.primera_realizacion_define_patron === true;
	}

	function patternUnits(row: GridRealizacionRow): MetricUnitDraft[] {
		return props.units
			.filter(
				(unit: MetricUnitDraft) =>
					unit.seccion_id === row.unit.seccion_id &&
					unit.realizacion_padre_id === row.unit.realizacion_padre_id
			)
			.sort((left: MetricUnitDraft, right: MetricUnitDraft) => left.v_ini - right.v_ini);
	}

	function patternSource(row: GridRealizacionRow): MetricUnitDraft {
		return patternUnits(row)[0] ?? row.unit;
	}

	function patternQuestion(row: GridRealizacionRow, dimension: 'metro' | 'rima') {
		return row.preguntas.find(
			(question: PreguntaEnFila) => String(question.group.dimension) === dimension
		);
	}

	function optionSyllables(optionId: string): string {
		const option = props.options.find(
			(candidate: MetricCatalogDomainRow) =>
				String(candidate.opcion_eleccion_id) === optionId
		);
		const exact = Number(option?.metro_silabas);
		if (Number.isFinite(exact)) return String(exact);
		return String(option?.nombre ?? '').match(/\b(\d+)\b/)?.[1] ?? '?';
	}

	function patternSummary(row: GridRealizacionRow): string {
		const source = patternSource(row);
		const metro = patternQuestion(row, 'metro');
		const rhyme = patternQuestion(row, 'rima');
		const length = source.v_fin - source.v_ini + 1;
		const measures = metro
			? selectedChoiceIds(
					String(metro.group.grupo_eleccion_id),
					source.realizacion_id
				)
					.map((optionId) => ({
						position: Number(
							props.options.find(
								(option: MetricCatalogDomainRow) =>
									String(option.opcion_eleccion_id) === optionId
							)?.posicion_unidad ?? 0
						),
						value: optionSyllables(optionId)
					}))
					.sort((left, right) => left.position - right.position)
					.map((item) => item.value)
					.join('·')
			: '';
		const rhymeValue = rhyme
			? choiceTextValue(String(rhyme.group.grupo_eleccion_id), source.realizacion_id).trim()
			: '';
		return [
			`${length} ${length === 1 ? 'verso' : 'versos'}`,
			measures || null,
			rhymeValue || null
		]
			.filter(Boolean)
			.join(' · ');
	}

	function commitUnits(next: MetricUnitDraft[], previous = props.units) {
		const remainingIds = new Set(
			next.map((unit: MetricUnitDraft) => unit.realizacion_id)
		);
		const removedIds = previous
			.map((unit: MetricUnitDraft) => unit.realizacion_id)
			.filter((unitId: string) => !remainingIds.has(unitId));
		if (removedIds.length > 0) props.onUnitsRemoved(removedIds);
		props.onUnitsChange(next);
	}

	// ------------------------------------------------------------------
	// Responder
	//
	// Todas las respuestas se guardan igual que antes: una fila por realización en
	// `anotacion_elecciones`. Lo único que cambia es desde dónde se escriben.
	// ------------------------------------------------------------------

	function escribirRespuesta(
		choices: MetricChoiceDraft[],
		groupId: string,
		unitId: string,
		optionIds: string[]
	): MetricChoiceDraft[] {
		return [
			...choices.filter(
				(choice: MetricChoiceDraft) =>
					!(
						choice.grupo_eleccion_id === groupId &&
						choice.realizacion_id === unitId
					)
			),
			...optionIds.map((optionId) => ({
				realizacion_id: unitId,
				grupo_eleccion_id: groupId,
				opcion_eleccion_id: optionId,
				valor_texto: null,
				observaciones: null
			}))
		];
	}

	function setChoices(
		group: MetricCatalogDomainRow,
		unit: MetricUnitDraft,
		optionIds: string[]
	) {
		const groupId = String(group.grupo_eleccion_id);
		const nextChoices = escribirRespuesta(
			props.choices,
			groupId,
			unit.realizacion_id,
			optionIds
		);
		props.onChoicesChange(nextChoices);
		commitUnits(
			syncChoiceMaterializedSections(
				props.units,
				props.sections,
				unit.realizacion_id,
				optionsForGroup(groupId),
				optionIds,
				props.sequenceStart,
				nextChoices,
				props.options
			)
		);
	}

	/**
	 * La estancia modelo no ofrece una operación por lotes: escribir en ella actualiza la norma
	 * y materializa la misma respuesta en todas las estancias que la heredan.
	 */
	function setPatternChoices(
		row: GridRealizacionRow,
		group: MetricCatalogDomainRow,
		optionIds: string[]
	) {
		const groupId = String(group.grupo_eleccion_id);
		let nextChoices = [...props.choices];
		for (const unit of patternUnits(row)) {
			nextChoices = escribirRespuesta(
				nextChoices,
				groupId,
				unit.realizacion_id,
				optionIds
			);
		}
		props.onChoicesChange(nextChoices);
	}

	function setChoiceText(
		group: MetricCatalogDomainRow,
		unit: MetricUnitDraft,
		value: string
	) {
		const groupId = String(group.grupo_eleccion_id);
		const normalized = normalizeRhymeScheme(value);
		props.onChoicesChange([
			...props.choices.filter(
				(choice: MetricChoiceDraft) =>
					!(
						choice.grupo_eleccion_id === groupId &&
						choice.realizacion_id === unit.realizacion_id
					)
			),
			...(normalized
				? [
						{
							realizacion_id: unit.realizacion_id,
							grupo_eleccion_id: groupId,
							opcion_eleccion_id: null,
							valor_texto: normalized,
							observaciones: null
						}
					]
				: [])
		]);
	}

	function setPatternRhyme(
		row: GridRealizacionRow,
		group: MetricCatalogDomainRow,
		value: string
	) {
		const groupId = String(group.grupo_eleccion_id);
		// Durante la edición posicional los espacios conservan los huecos aún sin responder.
		const normalized = value.normalize('NFC');
		let nextChoices = [...props.choices];
		for (const unit of patternUnits(row)) {
			nextChoices = [
				...nextChoices.filter(
					(choice: MetricChoiceDraft) =>
						!(
							choice.grupo_eleccion_id === groupId &&
							choice.realizacion_id === unit.realizacion_id
						)
				),
				...(normalized.trim()
					? [
							{
								realizacion_id: unit.realizacion_id,
								grupo_eleccion_id: groupId,
								opcion_eleccion_id: null,
								valor_texto: normalized,
								observaciones: null
							}
						]
					: [])
			];
		}
		props.onChoicesChange(nextChoices);
	}

	/** Copia lo respondido en una realización a todas sus equivalentes. */
	function applyChoiceToEquivalentUnits(
		group: MetricCatalogDomainRow,
		sourceUnit: MetricUnitDraft
	) {
		const groupId = String(group.grupo_eleccion_id);
		const selected = selectedChoiceIds(groupId, sourceUnit.realizacion_id);
		const sourceChoices = props.choices.filter(
			(choice: MetricChoiceDraft) =>
				choice.grupo_eleccion_id === groupId &&
				choice.realizacion_id === sourceUnit.realizacion_id
		);
		let nextChoices = [...props.choices];
		let nextUnits = [...props.units];

		for (const unit of unitsForGroup(context, group)) {
			nextChoices = [
				...nextChoices.filter(
					(choice: MetricChoiceDraft) =>
						!(
							choice.grupo_eleccion_id === groupId &&
							choice.realizacion_id === unit.realizacion_id
						)
				),
				...sourceChoices.map((choice: MetricChoiceDraft) => ({
					...choice,
					realizacion_id: unit.realizacion_id
				}))
			];
			nextUnits = syncChoiceMaterializedSections(
				nextUnits,
				props.sections,
				unit.realizacion_id,
				optionsForGroup(groupId),
				selected,
				props.sequenceStart,
				nextChoices,
				props.options
			);
		}

		props.onChoicesChange(nextChoices);
		commitUnits(nextUnits);
	}

	// ------------------------------------------------------------------
	// Las preguntas que pueden copiarse en una operación conjunta
	// ------------------------------------------------------------------

	function optionSlugOf(optionId: string): string {
		return String(
			props.options.find(
				(option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id) === optionId
			)?.slug ?? ''
		);
	}

	function comunOptions(pregunta: PreguntaCompartida): MetricCatalogDomainRow[] {
		return optionsForGroup(String(pregunta.groups[0]?.grupo_eleccion_id ?? ''));
	}

	/**
	 * Una respuesta común solo puede utilizar posiciones que existan en todas sus unidades.
	 * Así una copla de cinco versos no recibe las doce posiciones máximas del catálogo.
	 */
	function comunPositionLimit(pregunta: PreguntaCompartida): number | undefined {
		const lengths = pregunta.groups.flatMap((group: MetricCatalogDomainRow) =>
			unitsForGroup(context, group).map(
				(unit: MetricUnitDraft) => unit.v_fin - unit.v_ini + 1
			)
		);
		return lengths.length > 0 ? Math.min(...lengths) : undefined;
	}

	/** Qué han contestado las realizaciones a las que apunta: si coinciden y cuántas van. */
	/** Lo que responde una unidad, por slug, para poder comparar entre grupos de la misma familia. */
	function firmaComun(group: MetricCatalogDomainRow, unit: MetricUnitDraft): string {
		const groupId = String(group.grupo_eleccion_id);
		const slugs = selectedChoiceIds(groupId, unit.realizacion_id)
			.map(optionSlugOf)
			.sort()
			.join('|');
		if (!admiteEscrito(group)) return slugs;
		/**
		 * Con esquema escrito la respuesta puede ser una cosa o la otra, así que la firma lleva las
		 * dos. Se codifican **sin separador**: `abcabc|defdef` es una notación corriente y cualquier
		 * carácter que se eligiera para partirlas puede aparecer dentro de una.
		 */
		const texto = choiceTextValue(groupId, unit.realizacion_id).trim();
		if (!slugs && !texto) return '';
		return JSON.stringify([slugs, texto]);
	}

	/** Lo contrario de `firmaComun`: qué eligieron y qué escribieron las unidades que coinciden. */
	function leerFirma(firma: string): [string[], string] {
		if (!firma.startsWith('[')) return [firma.split('|').filter(Boolean), ''];
		const [slugs, texto] = JSON.parse(firma) as [string, string];
		return [slugs.split('|').filter(Boolean), texto];
	}

	/** Los dos controles de rima que dejan escribir: el abierto puro y el de repertorio con salida. */
	function admiteEscrito(group: MetricCatalogDomainRow): boolean {
		const control = String(group.tipo_control);
		return control === 'esquema_rima' || control === 'opciones_y_esquema';
	}

	/**
	 * El estado de una pregunta compartida, leído de las respuestas.
	 *
	 * `mayoritaria` es la firma que más veces se repite —sin contar el vacío—, y `excepciones`,
	 * cuántas unidades se apartan de ella. Con eso se decide qué se pinta abajo: si todas
	 * coinciden, nada; si no, **solo las que se apartan**.
	 */
	function comunState(pregunta: PreguntaCompartida) {
		const cuenta = new Map<string, number>();
		let answered = 0;
		let total = 0;
		for (const group of pregunta.groups) {
			for (const unit of unitsForGroup(context, group)) {
				total += 1;
				const firma = firmaComun(group, unit);
				if (!firma) continue;
				answered += 1;
				cuenta.set(firma, (cuenta.get(firma) ?? 0) + 1);
			}
		}
		let mayoritaria = '';
		let repeticiones = 0;
		for (const [firma, veces] of cuenta) {
			if (veces > repeticiones) {
				mayoritaria = firma;
				repeticiones = veces;
			}
		}
		// La firma de una pregunta con esquema escrito trae la elección y lo escrito, codificados.
		const coinciden = total > 0 && answered === total && cuenta.size === 1;
		const [elegido, escrito] = leerFirma(mayoritaria);
		const uniform = coinciden ? elegido : null;
		const textoUniforme = coinciden ? escrito : null;
		/**
		 * **Una mayoría de verdad, o ninguna.**
		 *
		 * Con seis unidades, cinco respuestas distintas y dos iguales, la «mayoritaria» serían esas
		 * dos y las otras cuatro saldrían marcadas como que se apartan de las demás, que es falso:
		 * ahí no hay «las demás». Solo hay respuesta común si la comparte **más de la mitad**.
		 */
		const hayComun = answered > 0 && repeticiones > total / 2;
		return {
			total,
			answered,
			uniform,
			textoUniforme,
			hayComun,
			mayoritaria: hayComun ? mayoritaria : null,
			// Sin ninguna respuesta no hay excepción: la pregunta está entera por contestar, y esa
			// es la situación de partida de toda secuencia nueva.
			excepciones: hayComun ? total - repeticiones : 0
		};
	}

	/** Cuántas unidades se apartan de lo común, sumando todas las preguntas compartidas. */
	const unidadesQueSeApartan = $derived.by(() => {
		const apartadas = new Set<string>();
		for (const pregunta of comunes) {
			const estado = comunState(pregunta);
			if (!estado.hayComun) continue;
			for (const group of pregunta.groups) {
				for (const unit of unitsForGroup(context, group)) {
					if (firmaComun(group, unit) !== estado.mayoritaria) {
						apartadas.add(unit.realizacion_id);
					}
				}
			}
		}
		return apartadas;
	});

	/** Cuántas unidades hay en total, para rotular el selector. */
	const totalDeUnidades = $derived.by(() =>
		comunes.reduce(
			(maximo: number, pregunta: PreguntaCompartida) =>
				Math.max(maximo, comunState(pregunta).total),
			0
		)
	);

	/**
	 * **«En conjunto» significa todas iguales, sin letra pequeña.**
	 *
	 * Hubo una versión en la que, estando en conjunto, una unidad podía declararse aparte y abrirse
	 * sola. Eran dos caminos para lo mismo —marcar una excepción y responder una a una— y dejaban
	 * un «conjunto» que no lo era. Ahora, si alguna unidad responde algo distinto, **el modo es una
	 * a una**, y el botón de conjunto no se puede pulsar mientras eso siga siendo verdad.
	 */
	/** Si alguna pregunta no tiene ya una sola respuesta para todas. */
	const hayDivergencia = $derived(
		comunes.some((pregunta: PreguntaCompartida) => {
			const estado = comunState(pregunta);
			return estado.answered > 0 && estado.uniform === null;
		})
	);

	const modoEfectivo = $derived(hayDivergencia ? 'una_a_una' : modoDeRespuesta);

	/**
	 * Las unidades de primer nivel, con el rótulo que les toca.
	 *
	 * Se sacan de `units` y no de las filas porque **hay unidades sin fila**: la décima aumentada es
	 * «transparente» y sus dos bloques se dibujan a primer nivel, sin una fila que diga «décima
	 * aumentada». Recorriendo filas, esa forma era la única que no enseñaba su anotación; recorriendo
	 * unidades, todas se leen igual.
	 */
	const unidadesRaiz = $derived.by(() => {
		const raices = props.units
			.filter((unit: MetricUnitDraft) => !unit.realizacion_padre_id && !unit.seccion_id)
			.sort((primera: MetricUnitDraft, segunda: MetricUnitDraft) => primera.v_ini - segunda.v_ini);
		return raices.map((unit: MetricUnitDraft, indice: number) => {
			const fila = rows.find(
				(row: GridRow) =>
					row.kind === 'realizacion' && row.unit.realizacion_id === unit.realizacion_id
			);
			const rotulo =
				fila && fila.kind === 'realizacion'
					? fila.label
					: `${String(props.unitLabel ?? 'Unidad')}${raices.length > 1 ? ` ${indice + 1}` : ''}`;
			return { unit, rotulo };
		});
	});

	/**
	 * **Si todo se responde arriba, abajo sobra la rejilla.**
	 *
	 * Respondido en conjunto, la lista unidad por unidad no dice nada que no se sepa: cuatro coplas
	 * iguales, cada una con sus dos redondillas, ocupando media pantalla para repetir lo mismo. Basta
	 * con saber **qué rango ocupa cada una**.
	 *
	 * Solo cuando de verdad no queda nada que tocar ahí abajo: ninguna fila con pregunta propia,
	 * ninguna extensión editable, ningún patrón que se declare en la unidad y ninguna acción de
	 * añadir o quitar. En cuanto algo de eso aparece, vuelve la rejilla entera.
	 */
	const listaCompacta = $derived(
		modoEfectivo === 'conjunto' &&
			rows.length > 0 &&
			unidadesRaiz.length > 0 &&
			rows.every((row: GridRow) => {
				if (row.kind === 'acciones' || row.kind === 'pregunta') return false;
				if (row.kind === 'fijas') return row.preguntas.length === 0;
				if (row.lengthEditable) return false;
				if (sectionDefinesPattern(row.section)) return false;
				// Las partes que se dibujan dentro de la fila —los dos bloques de la décima aumentada—
				// no impiden compactar si no preguntan nada: son estructura, no trabajo pendiente. Sin
				// esto, la aumentada era la única décima que no enseñaba su anotación.
				if (partesIntegradas(row).some((parte: GridFijasRow) => parte.preguntas.length > 0)) {
					return false;
				}
				if (partesFijasConRima(row).length > 0) return false;
				return row.preguntas.every(
					(pregunta: PreguntaEnFila) => familiaDe(pregunta.group) !== null
				);
			})
	);

	/** Se pide confirmación antes de volver a conjunto, porque borra lo respondido aparte. */
	let confirmarConjunto = $state(false);

	/**
	 * Deja las preguntas comunes sin responder en todas las unidades y vuelve a conjunto.
	 *
	 * Volver a «en conjunto» teniendo respuestas distintas **no puede** conservarlas: conjunto
	 * significa una sola respuesta para todas. Antes esto era imposible —el botón se quedaba
	 * bloqueado para siempre— y había que cerrar la secuencia y empezarla otra vez.
	 */
	function volverAConjunto() {
		let nextChoices = [...props.choices];
		let nextUnits = [...props.units];
		const siguientesPendientes = { ...pendingPositionsByAnswer };
		for (const pregunta of comunes) {
			for (const group of pregunta.groups) {
				const groupId = String(group.grupo_eleccion_id);
				for (const unit of unitsForGroup(context, group)) {
					nextChoices = escribirRespuesta(nextChoices, groupId, unit.realizacion_id, []);
					nextUnits = syncChoiceMaterializedSections(
						nextUnits,
						props.sections,
						unit.realizacion_id,
						optionsForGroup(groupId),
						[],
						props.sequenceStart,
						nextChoices,
						props.options
					);
					delete siguientesPendientes[pendingAnswerKey(groupId, unit.realizacion_id)];
				}
			}
		}
		pendingPositionsByAnswer = siguientesPendientes;
		props.onChoicesChange(nextChoices);
		commitUnits(nextUnits);
		modoDeRespuesta = 'conjunto';
		unidadesPlegadas = new Set();
		confirmarConjunto = false;
	}

	function unidadAbierta(): boolean {
		return modoEfectivo === 'una_a_una';
	}

	/**
	 * Al pasar a una a una se pliegan todas.
	 *
	 * Seis coplas desplegadas con sus dos preguntas cada una no caben en la pantalla, y lo normal
	 * es venir de una respuesta común y querer tocar una o dos.
	 */
	function elegirModo(id: string | null) {
		if (id === 'conjunto' && hayDivergencia) {
			confirmarConjunto = true;
			return;
		}
		confirmarConjunto = false;
		if (id === 'una_a_una') {
			modoDeRespuesta = 'una_a_una';
			// Solo las de primer nivel: plegar también sus partes obligaba a desplegar dos veces —la
			// copla y luego cada quintilla— para llegar a una respuesta.
			unidadesPlegadas = new Set(
				props.units
					.filter(
						(unit: MetricUnitDraft) => !unit.realizacion_padre_id && esUnidadComun(unit)
					)
					.map((unit: MetricUnitDraft) => unit.realizacion_id)
			);
			return;
		}
		modoDeRespuesta = 'conjunto';
		unidadesPlegadas = new Set();
	}

	/**
	 * **La anotación de una unidad, como se escribe siempre: `8a 8b 4c`.**
	 *
	 * Medida y rima van juntas porque así se lee el verso español, y porque separadas obligan a
	 * cruzar dos series a ojo para saber que el quebrado es el que rima en «c». La caja de la letra
	 * la decide la medida —minúscula hasta ocho sílabas, mayúscula por encima—, que es la
	 * convención y ya la sabe `normalizeRhymeSymbol`.
	 *
	 * Devuelve `null` si no se puede armar: sin respuestas, o con una notación que no case verso a
	 * verso con la unidad —los romances, por ejemplo, se anotan con puntos suspensivos—.
	 */
	function notacionDeLaUnidad(unit: MetricUnitDraft): string | null {
		const versos = unit.v_fin - unit.v_ini + 1;
		if (versos <= 0) return null;

		const medidas = new Map<number, number>();
		const letras = new Map<number, string>();
		const cortes = new Set<number>();
		let base: number | null = null;

		// **La copla y sus partes se leen juntas.** En la copla real la medida se responde en la
		// copla y la rima en cada quintilla, que son unidades propias: por separado salían dos
		// renglones —«8 8 8 8 8 8 8 8 8 8» y «a b a b a»— que hay que cruzar a ojo. Se recorre la
		// unidad y todo lo que cuelga de ella, y cada respuesta se coloca en su sitio.
		const rama: MetricUnitDraft[] = [unit];
		for (const candidata of props.units) {
			let padre = candidata.realizacion_padre_id;
			while (padre) {
				if (padre === unit.realizacion_id) {
					rama.push(candidata);
					// Donde empieza una parte se marca un corte, como el `|` de `abab|cddc`.
					if (candidata.v_ini > unit.v_ini) cortes.add(candidata.v_ini - unit.v_ini + 1);
					break;
				}
				padre = props.units.find(
					(otra: MetricUnitDraft) => otra.realizacion_id === padre
				)?.realizacion_padre_id ?? null;
			}
		}

		// **Cada parte estrena letras.** Las quintillas de una copla real riman por separado, y sus
		// esquemas se catalogan con letras propias: puestas una detrás de otra salían «8a 8b 8a 8b 8a
		// | 8a 8b 8b 8a 8a», que se lee como si las dos mitades rimaran igual. Al venir la respuesta
		// de una pregunta **de esa sección**, sus letras son locales y se renombran a las siguientes
		// libres. Las de una pregunta de la unidad entera ya son globales y no se tocan.
		const usadas = new Set<string>();
		const abecedario = 'abcdefghijklmnopqrstuvwxyz';
		function siguienteLibre(): string {
			for (const letra of abecedario) {
				if (!usadas.has(letra)) return letra;
			}
			return '?';
		}

		// Las partes, en el orden en que se leen, para que las letras corran de izquierda a derecha.
		rama.sort((primera, segunda) => primera.v_ini - segunda.v_ini);

		for (const parte of rama) {
			const desplazamiento = parte.v_ini - unit.v_ini;
			const suyos = parte.v_fin - parte.v_ini + 1;
			for (const group of context.groups) {
				const groupId = String(group.grupo_eleccion_id);
				const alcanza = unitsForGroup(context, group).some(
					(candidata: MetricUnitDraft) => candidata.realizacion_id === parte.realizacion_id
				);
				if (!alcanza) continue;
				const elegidas = selectedChoiceIds(groupId, parte.realizacion_id);
				const opciones = optionsForGroup(groupId);

				if (group.dimension === 'metro') {
					for (const opcion of opciones) {
						// `Number(null)` es 0 y `Number.isFinite(0)` es cierto: sin esa condición, una
						// forma sin medida de base —las aliradas abiertas no la tienen— se anotaba
						// «0 0 0 0».
						const posible = Number(opcion.metro_base_silabas);
						if (Number.isFinite(posible) && posible > 0) base = posible;
					}
					for (const opcion of opciones) {
						if (!elegidas.includes(String(opcion.opcion_eleccion_id))) continue;
						const posicion = Number(opcion.posicion_unidad);
						const silabas = Number(opcion.metro_silabas);
						if (Number.isFinite(posicion) && Number.isFinite(silabas)) {
							medidas.set(posicion + desplazamiento, silabas);
						}
					}
					continue;
				}

				if (group.dimension !== 'rima') continue;
				const escrito = choiceTextValue(groupId, parte.realizacion_id).trim();
				const catalogados = normaEsquemaDe(group, parte).catalogados;
				const notacion =
					opciones
						.filter((opcion: MetricCatalogDomainRow) =>
							elegidas.includes(String(opcion.opcion_eleccion_id))
						)
						.map(
							(opcion: MetricCatalogDomainRow) =>
								catalogados.find(
									(candidato) => candidato.esquemaRimaId === String(opcion.opcion_eleccion_id)
								)?.notacion
						)
						.find(Boolean) ?? (escrito || null);
				if (!notacion) continue;
				const seguidas = Array.from(String(notacion).replace(/\|/gu, ''));
				// Una notación que no case verso a verso no se puede repartir por posiciones.
				if (seguidas.length !== suyos) continue;
				// El `|` que el propio esquema trae también corta.
				const renombre = new Map<string, string>();
				const esDeSeccion = Boolean(group.seccion_id);
				let recorrido = 0;
				for (const signo of Array.from(String(notacion))) {
					if (signo === '|') {
						if (recorrido > 0) cortes.add(desplazamiento + recorrido + 1);
						continue;
					}
					recorrido += 1;
					let letra = signo;
					if (letra !== '-') {
						const clave = letra.toLocaleLowerCase('es');
						if (esDeSeccion) {
							if (!renombre.has(clave)) {
								const libre = siguienteLibre();
								usadas.add(libre);
								renombre.set(clave, libre);
							}
							letra = renombre.get(clave) ?? letra;
						} else {
							usadas.add(clave);
						}
					}
					letras.set(desplazamiento + recorrido, letra);
				}
			}
		}

		// **Lo que la norma fija se anota igual.** Una décima espinela no tiene nada que elegir, y
		// su resumen salía en blanco mientras el de una copla castellana traía su serie: dos formas
		// anotadas, dos resúmenes distintos. La rejilla de la norma ya sabe qué mide y en qué clase
		// rima cada verso, así que se usa para rellenar lo que nadie ha respondido. Lo respondido
		// manda siempre: esto solo cubre huecos.
		const rejilla = props.rejilla;
		if (rejilla && !unit.realizacion_padre_id && rejilla.celdas.length === versos) {
			for (const celda of rejilla.celdas) {
				const fijada = celda.medida?.silabas;
				if (fijada && !medidas.has(celda.verso)) {
					const silabas = Number(fijada);
					if (Number.isFinite(silabas) && silabas > 0) medidas.set(celda.verso, silabas);
				}
			}
			// De todas las disposiciones que dibuja la arquitectura, la que da el esqueleto; y si no
			// lo declara, la que la norma fija o la corriente.
			const filas: FilaDeRima[] = rejilla.filasDeRima ?? [];
			const esqueleto =
				filas.find((fila: FilaDeRima) => fila.esquemaRimaId === rejilla.esqueletoDe) ??
				filas.find((fila: FilaDeRima) => fila.modalidad === 'definitoria') ??
				filas.find((fila: FilaDeRima) => fila.modalidad === 'habitual');
			if (esqueleto) {
				esqueleto.clases.forEach((clase: { clase: string | null }, indice: number) => {
					const posicion = esqueleto.desde + indice;
					if (clase.clase && !letras.has(posicion)) letras.set(posicion, clase.clase);
				});
			}
		}

		if (letras.size === 0 && medidas.size === 0 && base === null) return null;

		const piezas: string[] = [];
		for (let posicion = 1; posicion <= versos; posicion += 1) {
			if (cortes.has(posicion) && piezas.length > 0) piezas.push('|');
			const silabas = medidas.get(posicion) ?? base;
			const letra = letras.get(posicion) ?? '';
			const simbolo =
				letra && letra !== '-' && silabas !== null && silabas !== undefined
					? normalizeRhymeSymbol(letra, silabas)
					: letra;
			piezas.push(`${silabas ?? ''}${simbolo}`);
		}
		const escrita = piezas.join(' ').replace(/\s\|\s/gu, ' | ').trim();
		return escrita ? escrita : null;
	}

	/** Si a esta unidad le llega alguna de las preguntas que se responden en común. */
	function esUnidadComun(unit: MetricUnitDraft): boolean {
		return comunes.some((pregunta: PreguntaCompartida) =>
			pregunta.groups.some((group: MetricCatalogDomainRow) =>
				unitsForGroup(context, group).some(
					(candidate: MetricUnitDraft) => candidate.realizacion_id === unit.realizacion_id
				)
			)
		);
	}

	/** La familia a la que pertenece un grupo, si es de las que se responden en conjunto. */
	function familiaDe(group: MetricCatalogDomainRow): PreguntaCompartida | null {
		const groupId = String(group.grupo_eleccion_id);
		return (
			comunes.find((comun: PreguntaCompartida) =>
				comun.groups.some(
					(miembro: MetricCatalogDomainRow) =>
						String(miembro.grupo_eleccion_id) === groupId
				)
			) ?? null
		);
	}

	/** Responde en el acto en todas las unidades. Ya no hay que preparar nada y aplicarlo después. */
	function aplicarComun(pregunta: PreguntaCompartida, slugs: string[]) {
		const resultado = writeComunChoice(pregunta, slugs, [...props.choices], [...props.units]);
		// Un verso marcado como quebrado en una unidad, al que aún le falta la medida, describe una
		// respuesta que el atajo acaba de sobrescribir: se va con ella. Si no, la unidad reclamaba
		// una medida para un quebrado que ya no está.
		const siguientes = { ...pendingPositionsByAnswer };
		for (const group of pregunta.groups) {
			const groupId = String(group.grupo_eleccion_id);
			for (const unit of unitsForGroup(context, group)) {
				delete siguientes[pendingAnswerKey(groupId, unit.realizacion_id)];
			}
		}
		pendingPositionsByAnswer = siguientes;
		props.onChoicesChange(resultado.choices);
		commitUnits(resultado.units);
	}

	/**
	 * Lo mismo, cuando la respuesta se escribe en vez de elegirse.
	 *
	 * Va por separado de `writeComunChoice` porque no hay slug que copiar: se copia la notación,
	 * ya normalizada, exactamente como la escribiría cada unidad por su cuenta.
	 */
	function aplicarComunTexto(pregunta: PreguntaCompartida, value: string) {
		const normalized = normalizeRhymeScheme(value);
		let siguientes = [...props.choices];
		for (const group of pregunta.groups) {
			const groupId = String(group.grupo_eleccion_id);
			for (const unit of unitsForGroup(context, group)) {
				siguientes = siguientes.filter(
					(choice: MetricChoiceDraft) =>
						!(
							choice.grupo_eleccion_id === groupId &&
							choice.realizacion_id === unit.realizacion_id
						)
				);
				if (normalized) {
					siguientes.push({
						realizacion_id: unit.realizacion_id,
						grupo_eleccion_id: groupId,
						opcion_eleccion_id: null,
						valor_texto: normalized,
						observaciones: null
					});
				}
			}
		}
		props.onChoicesChange(siguientes);
	}

	/** El campo de rima habla en identificadores de opción; la respuesta común viaja por slug. */
	function idsComunes(pregunta: PreguntaCompartida, slugs: string[]): string[] {
		const groupId = String(pregunta.groups[0]?.grupo_eleccion_id ?? '');
		return optionsForGroup(groupId)
			.filter((option: MetricCatalogDomainRow) => slugs.includes(String(option.slug)))
			.map((option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id));
	}

	/** Lo que hace falta para leer un esquema escrito: se toma de la primera unidad, que las representa. */
	function normaEsquemaComun(pregunta: PreguntaCompartida) {
		const group = pregunta.groups[0];
		if (!group) return undefined;
		const unit = unitsForGroup(context, group)[0];
		return unit ? normaEsquemaDe(group, unit) : undefined;
	}

	/**
	 * Responde la pregunta en todas las realizaciones a las que se dirige, en todos los
	 * grupos que la formulan. La respuesta viaja por slug porque cada grupo tiene sus propias
	 * opciones apuntando al mismo dato.
	 */
	function writeComunChoice(
		pregunta: PreguntaCompartida,
		slugs: string[],
		baseChoices: MetricChoiceDraft[],
		baseUnits: MetricUnitDraft[]
	): { choices: MetricChoiceDraft[]; units: MetricUnitDraft[] } {
		let nextChoices = [...baseChoices];
		let nextUnits = [...baseUnits];
		for (const group of pregunta.groups) {
			const groupId = String(group.grupo_eleccion_id);
			const optionIds = optionsForGroup(groupId)
				.filter((candidate: MetricCatalogDomainRow) => slugs.includes(String(candidate.slug)))
				.map((option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id));
			if (slugs.length > 0 && optionIds.length === 0) continue;
			for (const unit of unitsForGroup(context, group)) {
				nextChoices = escribirRespuesta(
					nextChoices,
					groupId,
					unit.realizacion_id,
					optionIds
				);
				nextUnits = syncChoiceMaterializedSections(
					nextUnits,
					props.sections,
					unit.realizacion_id,
					optionsForGroup(groupId),
					optionIds,
					props.sequenceStart,
					nextChoices,
					props.options
				);
			}
		}
		return { choices: nextChoices, units: nextUnits };
	}

	function tieneRespuestaComun(group: MetricCatalogDomainRow): boolean {
		return familiaDe(group) !== null;
	}

	/**
	 * Lo que el campo abierto necesita saber de la norma para no aceptar cualquier cosa.
	 *
	 * La extensión sale de la realización en la que se pregunta —la sección, cuando la pregunta es
	 * de una parte—, y las disposiciones catalogadas, de las opciones que el propio grupo ofrece:
	 * si lo escrito resulta ser una de ellas, se marca esa. El identificador que se devuelve es el
	 * de la **opción**, no el del esquema, porque es lo que el editor guarda.
	 */
	function normaEsquemaDe(group: MetricCatalogDomainRow, unit: MetricUnitDraft) {
		const groupId = String(group.grupo_eleccion_id);
		const catalogados = optionsForGroup(groupId)
			.filter((option: MetricCatalogDomainRow) => option.esquema_rima_id)
			.map((option: MetricCatalogDomainRow) => {
				const scheme = (props.schemes ?? []).find(
					(candidate: MetricCatalogDomainRow) =>
						String(candidate.esquema_rima_id) === String(option.esquema_rima_id)
				);
				return {
					esquemaRimaId: String(option.opcion_eleccion_id),
					notacion: scheme?.notacion ? String(scheme.notacion) : null,
					regimen: null
				};
			});
		return {
			versos: unit.v_fin - unit.v_ini + 1,
			regimen: null,
			catalogados,
			regimenes: props.rhymeRegimes ?? []
		};
	}

	function preguntaRespondida(pregunta: PreguntaEnFila): boolean {
		const groupId = String(pregunta.group.grupo_eleccion_id);
		// **Un esquema escrito es una respuesta.** Se miraba solo en el control abierto puro, así
		// que en el híbrido —39 grupos en 21 formas— quien escribía su disposición en vez de
		// elegirla del repertorio seguía viendo la pregunta como pendiente.
		if (
			admiteEscrito(pregunta.group) &&
			choiceTextValue(groupId, pregunta.owner.realizacion_id).trim()
		) {
			return true;
		}
		if (pregunta.group.tipo_control === 'esquema_rima') return false;
		const selected = selectedChoiceIds(groupId, pregunta.owner.realizacion_id);
		const options = optionsForGroup(groupId);
		if (isPartialPositionalSelection(pregunta.group, options)) {
			return selected.length >= Number(pregunta.group.selecciones_min ?? 0);
		}
		return (
			selected.length > 0 &&
			selected.length >= Number(pregunta.group.selecciones_min ?? 0)
		);
	}

	function esFilaPosicionalParcial(row: GridRealizacionRow): boolean {
		return row.preguntas.some((pregunta: PreguntaEnFila) => {
			const groupId = String(pregunta.group.grupo_eleccion_id);
			return isPartialPositionalSelection(pregunta.group, optionsForGroup(groupId));
		});
	}

	function preguntasPosicionalesParciales(row: GridRealizacionRow): PreguntaEnFila[] {
		return row.preguntas.filter((pregunta: PreguntaEnFila) => {
			const groupId = String(pregunta.group.grupo_eleccion_id);
			return isPartialPositionalSelection(pregunta.group, optionsForGroup(groupId));
		});
	}

	function preguntaPosicionalCompleta(row: GridRealizacionRow): PreguntaEnFila | null {
		return (
			row.preguntas.find((pregunta: PreguntaEnFila) => {
				const options = optionsForGroup(String(pregunta.group.grupo_eleccion_id));
				return (
					!isPartialPositionalSelection(pregunta.group, options) &&
					haveAlternativesByPosition(options)
				);
			}) ?? null
		);
	}

	function partesFijasConRima(row: GridRealizacionRow): GridFijasRow[] {
		const parts = rows
			.filter(
				(candidate: GridRow): candidate is GridFijasRow =>
					candidate.kind === 'fijas' &&
					candidate.parentUnitId === row.unit.realizacion_id &&
					Boolean(candidate.section?.esquema_rima_id)
			)
			.sort((left: GridFijasRow, right: GridFijasRow) => left.v_ini - right.v_ini);
		if (parts.length < 2 || parts[0].v_ini !== row.unit.v_ini) return [];
		let expectedStart = row.unit.v_ini;
		for (const part of parts) {
			if (part.v_ini !== expectedStart) return [];
			expectedStart = part.v_fin + 1;
		}
		return expectedStart === row.unit.v_fin + 1 ? parts : [];
	}

	function fixedRhymesFor(row: GridRealizacionRow, parts: GridFijasRow[]): string[] {
		const output = Array.from(
			{ length: row.unit.v_fin - row.unit.v_ini + 1 },
			() => '—'
		);
		for (const part of parts) {
			const scheme = props.schemes.find(
				(candidate: MetricCatalogDomainRow) =>
					String(candidate.esquema_rima_id) === String(part.section?.esquema_rima_id)
			);
			const notation = String(scheme?.notacion ?? '').replace(/[^A-Za-zÑñ-]/g, '');
			for (let verse = part.v_ini; verse <= part.v_fin; verse += 1) {
				const local = verse - row.unit.v_ini;
				output[local] = notation ? (Array.from(notation)[verse - part.v_ini] ?? '—') : '—';
			}
		}
		return output;
	}

	/**
	 * Si una unidad con medidas posicionales se divide en partes fijas que cubren todo su
	 * rango, la medida se pinta dentro de esas partes. Es el caso de la copla real: cada
	 * quintilla reúne su rima y sus cinco versos, aunque la respuesta métrica siga guardándose
	 * una sola vez en la copla.
	 */
	function partesIntegradas(row: GridRealizacionRow): GridFijasRow[] {
		if (preguntasPosicionalesParciales(row).length === 0) return [];
		const parts = rows
			.filter(
				(candidate: GridRow): candidate is GridFijasRow =>
					candidate.kind === 'fijas' &&
					candidate.parentUnitId === row.unit.realizacion_id &&
					candidate.preguntas.length > 0
			)
			.sort((left: GridFijasRow, right: GridFijasRow) => left.v_ini - right.v_ini);
		if (parts.length < 2) return [];
		let expectedStart = row.unit.v_ini;
		for (const part of parts) {
			if (part.v_ini !== expectedStart || part.v_fin < part.v_ini) return [];
			expectedStart = part.v_fin + 1;
		}
		if (expectedStart !== row.unit.v_fin + 1) return [];
		return parts;
	}

	function esParteIntegrada(row: GridRow): boolean {
		if (row.kind !== 'fijas') return false;
		return rows.some(
			(candidate: GridRow) =>
				candidate.kind === 'realizacion' &&
				[
					...partesIntegradas(candidate),
					...partesFijasConRima(candidate)
				].some((part: GridFijasRow) => part.key === row.key)
		);
	}

	function puedePlegarCompuesta(row: GridRealizacionRow, parts: GridFijasRow[]): boolean {
		return (
			row.preguntas.every(preguntaRespondida) &&
			parts.every((part: GridFijasRow) => part.preguntas.every(preguntaRespondida))
		);
	}

	function puedePlegar(row: GridRealizacionRow): boolean {
		return (
			!row.container &&
			row.preguntas.length > 0 &&
			esFilaPosicionalParcial(row) &&
			row.preguntas.every(preguntaRespondida)
		);
	}

	/**
	 * Si una unidad está dentro de otra que se ha plegado.
	 *
	 * Sus partes se pintan como filas hermanas, no anidadas, así que plegar la unidad ocultaba sus
	 * campos pero dejaba las partes sueltas debajo. Al plegar una copla se pliega entera.
	 */
	function filaOculta(row: GridRow): boolean {
		let padre =
			row.kind === 'realizacion' ? row.unit.realizacion_padre_id : row.parentUnitId;
		while (padre) {
			if (unidadesPlegadas.has(padre)) return true;
			padre = props.units.find(
				(candidate: MetricUnitDraft) => candidate.realizacion_id === padre
			)?.realizacion_padre_id ?? null;
		}
		return false;
	}

	function setUnidadPlegada(unitId: string, plegada: boolean) {
		const next = new Set(unidadesPlegadas);
		if (plegada) next.add(unitId);
		else next.delete(unitId);
		unidadesPlegadas = next;
	}

	// ------------------------------------------------------------------
	// Secciones opcionales que aparecen o no en toda la composición
	// ------------------------------------------------------------------

	function setOptionalSectionEverywhere(section: MetricCatalogDomainRow, present: boolean) {
		const targetSectionId = sectionId(section);
		let nextUnits = [...props.units];
		for (const parent of parentInstancesOf(context, section)) {
			const existing = nextUnits.filter(
				(unit: MetricUnitDraft) =>
					unit.realizacion_padre_id === parent.realizacion_id &&
					unit.seccion_id === targetSectionId
			);
			if (present && existing.length === 0) {
				nextUnits = addSectionInstance(
					nextUnits,
					props.sections,
					targetSectionId,
					parent.realizacion_id,
					props.sequenceStart,
					props.choices,
					props.options
				);
			}
			if (!present) {
				for (const unit of existing) {
					nextUnits = removeMetricUnitTree(
						nextUnits,
						unit.realizacion_id,
						props.sections,
						props.sequenceStart,
						props.choices,
						props.options
					);
				}
			}
		}
		commitUnits(nextUnits);
	}

	// ------------------------------------------------------------------
	// Cuántas hay y cuántos versos miden
	// ------------------------------------------------------------------

	function inheritPatternInNewUnits(
		section: MetricCatalogDomainRow,
		parentUnitId: string | null,
		units: MetricUnitDraft[],
		choices: MetricChoiceDraft[]
	): { units: MetricUnitDraft[]; choices: MetricChoiceDraft[] } {
		if (!sectionDefinesPattern(section)) return { units, choices };
		const peers = units
			.filter(
				(unit: MetricUnitDraft) =>
					unit.seccion_id === sectionId(section) &&
					unit.realizacion_padre_id === parentUnitId
			)
			.sort((left: MetricUnitDraft, right: MetricUnitDraft) => left.v_ini - right.v_ini);
		const source = peers[0];
		if (!source) return { units, choices };
		const length = source.v_fin - source.v_ini + 1;
		let nextUnits = units.map((unit: MetricUnitDraft) =>
			peers.some((peer) => peer.realizacion_id === unit.realizacion_id)
				? { ...unit, v_fin: unit.v_ini + length - 1 }
				: unit
		);
		let nextChoices = [...choices];
		const patternGroups = props.groups.filter(
			(group: MetricCatalogDomainRow) =>
				group.define_norma === true && String(group.seccion_id ?? '') === sectionId(section)
		);
		for (const group of patternGroups) {
			const groupId = String(group.grupo_eleccion_id);
			const sourceChoices = choices.filter(
				(choice: MetricChoiceDraft) =>
					choice.grupo_eleccion_id === groupId &&
					choice.realizacion_id === source.realizacion_id
			);
			for (const target of peers.slice(1)) {
				nextChoices = [
					...nextChoices.filter(
						(choice: MetricChoiceDraft) =>
							!(
								choice.grupo_eleccion_id === groupId &&
								choice.realizacion_id === target.realizacion_id
							)
					),
					...sourceChoices.map((choice: MetricChoiceDraft) => ({
						...choice,
						realizacion_id: target.realizacion_id
					}))
				];
			}
		}
		nextUnits = reflowMetricUnits(
			nextUnits,
			props.sections,
			props.sequenceStart,
			nextChoices,
			props.options
		);
		return { units: nextUnits, choices: nextChoices };
	}

	function setInstanceCount(
		section: MetricCatalogDomainRow | null,
		parentUnitId: string | null,
		minimum: number,
		maximum: number | null,
		value: number
	) {
		const current = props.units.filter(
			(unit: MetricUnitDraft) =>
				unit.seccion_id === (section ? sectionId(section) : null) &&
				unit.realizacion_padre_id === parentUnitId
		);
		const target = Math.min(
			maximum ?? Number.MAX_SAFE_INTEGER,
			Math.max(minimum, Number.isFinite(value) ? value : minimum)
		);
		if (target === current.length) return;
		let nextUnits = [...props.units];
		if (target > current.length) {
			for (let added = current.length; added < target; added += 1) {
				nextUnits =
					section === null
						? addMetricUnit(
								nextUnits,
								props.sections,
								props.unitPlan?.extent ?? null,
								props.sequenceStart,
								props.choices,
								props.options
							)
						: addSectionInstance(
								nextUnits,
								props.sections,
								sectionId(section),
								parentUnitId,
								props.sequenceStart,
								props.choices,
								props.options
							);
			}
		} else {
			for (const unit of current.slice(target)) {
				nextUnits = removeMetricUnitTree(
					nextUnits,
					unit.realizacion_id,
					props.sections,
					props.sequenceStart,
					props.choices,
					props.options
				);
			}
		}
		if (section && sectionDefinesPattern(section)) {
			const inherited = inheritPatternInNewUnits(
				section,
				parentUnitId,
				nextUnits,
				props.choices
			);
			props.onChoicesChange(inherited.choices);
			commitUnits(inherited.units);
			return;
		}
		commitUnits(nextUnits);
	}

	function addInstance(targetSectionId: string | null, parentUnitId: string | null) {
		if (targetSectionId === null) {
			if (!props.unitPlan) return;
			commitUnits(
				addMetricUnit(
					props.units,
					props.sections,
					props.unitPlan.extent,
					props.sequenceStart,
					props.choices,
					props.options
				)
			);
			return;
		}
		const section = props.sections.find(
			(candidate: MetricCatalogDomainRow) => sectionId(candidate) === targetSectionId
		);
		const added = addSectionInstance(
				props.units,
				props.sections,
				targetSectionId,
				parentUnitId,
				props.sequenceStart,
				props.choices,
				props.options
			);
		if (section && sectionDefinesPattern(section)) {
			const inherited = inheritPatternInNewUnits(
				section,
				parentUnitId,
				added,
				props.choices
			);
			props.onChoicesChange(inherited.choices);
			commitUnits(inherited.units);
			return;
		}
		commitUnits(added);
	}

	function removeInstance(unit: MetricUnitDraft) {
		const removedIds = [...unitIdsInTree(props.units, unit.realizacion_id)];
		const remaining = removeMetricUnitTree(
			props.units,
			unit.realizacion_id,
			props.sections,
			props.sequenceStart,
			props.choices,
			props.options
		);
		props.onUnitsRemoved(removedIds);
		props.onUnitsChange(remaining);
	}

	function verseMinimum(section: MetricCatalogDomainRow | null): number {
		if (section) return sectionVerseMinimum(section);
		return props.unitPlan?.extent?.minimum ?? 1;
	}

	function verseMaximum(section: MetricCatalogDomainRow | null): number | null {
		if (section) return sectionVerseMaximum(section);
		return props.unitPlan?.extent?.maximum ?? null;
	}

	/** Las respuestas por posición que dejan de caber al acortar una realización. */
	function positionalChoicesBeyond(length: number): Set<string> {
		return new Set(
			props.options
				.filter(
					(option: MetricCatalogDomainRow) => Number(option.posicion_unidad ?? 0) > length
				)
				.map((option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id))
		);
	}

	function setUnitLength(
		unit: MetricUnitDraft,
		section: MetricCatalogDomainRow | null,
		value: number
	) {
		const minimum = verseMinimum(section);
		const maximum = verseMaximum(section);
		const length = Math.max(minimum, maximum === null ? value : Math.min(maximum, value));
		const changed = props.units.map((item: MetricUnitDraft) =>
			item.realizacion_id === unit.realizacion_id
				? { ...item, v_fin: item.v_ini + length - 1 }
				: item
		);
		const sobran = positionalChoicesBeyond(length);
		if (sobran.size > 0) {
			props.onChoicesChange(
				props.choices.filter(
					(choice: MetricChoiceDraft) =>
						choice.realizacion_id !== unit.realizacion_id ||
						!choice.opcion_eleccion_id ||
						!sobran.has(choice.opcion_eleccion_id)
				)
			);
		}
		commitUnits(
			reflowMetricUnits(
				changed,
				props.sections,
				props.sequenceStart,
				props.choices,
				props.options
			)
		);
	}

	function setPatternLength(
		row: GridRealizacionRow,
		section: MetricCatalogDomainRow | null,
		value: number
	) {
		if (!section) return;
		const minimum = verseMinimum(section);
		const maximum = verseMaximum(section);
		const length = Math.max(minimum, maximum === null ? value : Math.min(maximum, value));
		const peerIds = new Set(
			patternUnits(row).map((unit: MetricUnitDraft) => unit.realizacion_id)
		);
		const sobran = positionalChoicesBeyond(length);
		const nextChoices = props.choices.filter(
			(choice: MetricChoiceDraft) =>
				!peerIds.has(choice.realizacion_id ?? '') ||
				!choice.opcion_eleccion_id ||
				!sobran.has(choice.opcion_eleccion_id)
		);
		const changed = props.units.map((unit: MetricUnitDraft) =>
			peerIds.has(unit.realizacion_id)
				? { ...unit, v_fin: unit.v_ini + length - 1 }
				: unit
		);
		if (nextChoices.length !== props.choices.length) props.onChoicesChange(nextChoices);
		commitUnits(
			reflowMetricUnits(
				changed,
				props.sections,
				props.sequenceStart,
				nextChoices,
				props.options
			)
		);
	}

	function applyUnitLengthToEquivalentUnits(sourceUnit: MetricUnitDraft) {
		const length = sourceUnit.v_fin - sourceUnit.v_ini + 1;
		const equivalentUnitIds = new Set(
			props.units
				.filter((unit: MetricUnitDraft) => unit.seccion_id === sourceUnit.seccion_id)
				.map((unit: MetricUnitDraft) => unit.realizacion_id)
		);
		const changed = props.units.map((unit: MetricUnitDraft) =>
			equivalentUnitIds.has(unit.realizacion_id)
				? { ...unit, v_fin: unit.v_ini + length - 1 }
				: unit
		);
		const sobran = positionalChoicesBeyond(length);
		if (sobran.size > 0) {
			props.onChoicesChange(
				props.choices.filter(
					(choice: MetricChoiceDraft) =>
						!equivalentUnitIds.has(choice.realizacion_id ?? '') ||
						!choice.opcion_eleccion_id ||
						!sobran.has(choice.opcion_eleccion_id)
				)
			);
		}
		commitUnits(
			reflowMetricUnits(
				changed,
				props.sections,
				props.sequenceStart,
				props.choices,
				props.options
			)
		);
	}

	/** El atajo solo aporta cuando alguna unidad equivalente tiene otra extensión. */
	function equivalentLengthDiffers(sourceUnit: MetricUnitDraft): boolean {
		const length = sourceUnit.v_fin - sourceUnit.v_ini + 1;
		return props.units.some(
			(unit: MetricUnitDraft) =>
				unit.seccion_id === sourceUnit.seccion_id &&
				unit.realizacion_id !== sourceUnit.realizacion_id &&
				unit.v_fin - unit.v_ini + 1 !== length
		);
	}
</script>

<div class="space-y-3">
	<!-- Veintiuna de las treinta y siete arquitecturas del catálogo no preguntan nada: la forma
	     queda registrada al elegirla. Es el caso más frecuente y hasta ahora se veía como un
	     hueco, que se lee como «falta algo» en vez de como «ya está». -->
	{#if props.groups.length === 0 && !hayZonaComun && rows.length === 0}
		<p class="border border-[color:var(--border)] bg-[color:var(--gray-50)] px-3 py-2 text-sm text-[color:var(--muted-foreground)]">
			La forma no requiere más datos.
		</p>
	{/if}

	<!--
		**Dos bloques separados, no uno corrido.**

		Arriba, lo que se responde una vez y vale para toda la secuencia. Abajo, la secuencia leída
		unidad por unidad. Iban dentro del mismo recuadro y pegados, y eso los hacía parecer una
		lista continua: la respuesta común se leía como si fuera la primera unidad. Separarlos con
		aire es lo que dice de qué va cada cosa.
	-->
	{#if hayZonaComun}
	<div class="border border-[color:var(--border)]">
		{#if hayAjustesDeComposicion}
			<p class="form-grid-title border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2">
				Datos comunes de la composición
			</p>

			{@render props.globalQuestions?.()}

			{#each opcionales as section (sectionId(section))}
				{@const presencia = presenciaDeSeccion(context, section)}
				<MetricGridRow
					label={`¿Aparece «${sectionLabel(section)}»?`}
					rango={presencia.parents.length > 1 ? `en ${presencia.parents.length} unidades` : ''}
					variant="comun"
				>
					<div class="flex flex-wrap items-center gap-3">
						<SegmentedChoice
							items={[
								{ id: 'si', label: presencia.parents.length > 1 ? 'En todas' : 'Sí' },
								{ id: 'no', label: presencia.parents.length > 1 ? 'En ninguna' : 'No' }
							]}
							value={presencia.everywhere ? 'si' : presencia.nowhere ? 'no' : null}
							onChange={(id) => setOptionalSectionEverywhere(section, id === 'si')}
							ariaLabel={`¿Aparece ${sectionLabel(section)}?`}
							size="sm"
						/>
						{#if !presencia.everywhere && !presencia.nowhere}
							<span class="text-xs text-[color:var(--muted-foreground)]">
								Aparece en {presencia.present} de {presencia.parents.length}
							</span>
						{/if}
					</div>
				</MetricGridRow>
			{/each}
		{/if}

		<!--
			**Responder en conjunto es un estado, no una acción.**

			Antes esto era un panel que se abría, en el que se preparaba una respuesta y que al
			aplicarla la **copiaba** en cada unidad y se cerraba. Después no quedaba ningún «en
			conjunto»: quedaban seis respuestas idénticas, cada copla seguía pintando su campo con un
			«Coincide con las demás unidades», y había que avisar de que lo aplicado «solo afecta a
			las unidades que existen ahora», porque era una copia y no una regla.

			Ahora el campo de aquí arriba **es** la respuesta de todas, y lo que se ve abajo depende
			de si alguna se aparta. Nada que preparar, nada que confirmar, ningún aviso sobre el
			futuro: si se añade una unidad, deja de haber uniformidad y la pregunta lo dice sola.
		-->
		{#if comunes.length > 0}
			<div class={hayAjustesDeComposicion ? 'border-t border-[color:var(--border)]' : ''}>
				<!--
					**Un solo selector para toda la pantalla.**

					Estuvo un rato con un interruptor por pregunta y era peor de lo que arreglaba: al
					pedir «una a una» en la rima, los quebrados seguían plegados aunque también varían
					de unidad en unidad, y el botón se repetía diciendo cosas distintas en cada fila.

					Y son dos modos, no tres. «Mixto» no era algo que se eligiera: es lo que pasa
					cuando alguna unidad responde otra cosa. Lo que se elige es **qué unidad se
					aparta**, unidad por unidad, ahí abajo.
				-->
				<div class="flex flex-wrap items-center justify-between gap-3 border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2">
					<p class="form-grid-title">
						{modoEfectivo === 'conjunto'
							? 'Respuestas de todas las unidades'
							: 'Respuestas, unidad por unidad'}
					</p>
					{#if totalDeUnidades > 1}
						<SegmentedChoice
							items={[
								{
									id: 'conjunto',
									label: 'En conjunto',
									title: 'Una respuesta para todas las unidades'
								},
								{ id: 'una_a_una', label: 'Una a una' }
							]}
							value={modoEfectivo}
							onChange={elegirModo}
							ariaLabel="Cómo responder las unidades"
							size="sm"
						/>
					{/if}
				</div>

				<!--
					En «una a una» el campo común sigue aquí, porque partir de lo corriente y matizar
					después ahorra mucho trabajo. Pero se anuncia como lo que es —un atajo— y se
					atenúa, para que no compita con los campos de cada unidad, que son los que mandan.
				-->
				{#if confirmarConjunto}
					<div class="border-b border-amber-300 bg-amber-50 px-3 py-2.5">
						<p class="text-xs text-amber-950">
							En conjunto significa una sola respuesta para todas. Volver borra lo que hayan
							respondido las unidades por su cuenta y empieza de nuevo.
						</p>
						<div class="mt-2 flex flex-wrap gap-3">
							<button
								type="button"
								class="h-8 bg-[color:var(--primary)] px-3 text-xs font-medium text-white"
								onclick={volverAConjunto}
							>
								Borrar y responder en conjunto
							</button>
							<button
								type="button"
								class="link-action text-xs"
								onclick={() => (confirmarConjunto = false)}
							>
								Cancelar
							</button>
						</div>
					</div>
				{:else if modoEfectivo === 'una_a_una' && !hayDivergencia}
					<p class="border-b border-[color:var(--border)] px-3 py-2 text-xs text-[color:var(--muted-foreground)]">
						Atajo: lo que respondas aquí se escribe en las {totalDeUnidades} unidades. Cada una
						puede corregirse después, abajo.
					</p>
				{/if}

				<div class={modoEfectivo === 'una_a_una' ? 'opacity-70' : ''}>
					{#each comunes as pregunta (pregunta.key)}
						{@const state = comunState(pregunta)}
						<MetricGridRow
							label={pregunta.label}
							rango={state.answered === 0
								? `${state.total} unidades`
								: state.excepciones === 0
									? `en las ${state.total} unidades`
									: `en ${state.total - state.excepciones} de ${state.total}`}
							variant="comun"
						>
							{#if state.uniform === null && state.answered > 0}
							<!--
								**Un atajo que ya no puede hablar por todas se retira.**

								Con respuestas distintas, el control se pintaba vacío —como si todos los
								versos fueran de ocho— mientras una nota decía que las unidades conservan
								respuestas distintas. Enseñar un estado falso al lado de la advertencia de
								que es falso no ayuda a nadie: mejor no enseñarlo.
							-->
							<p class="text-sm text-[color:var(--muted-foreground)]">
								{state.hayComun
									? `Las unidades no responden lo mismo: ${state.excepciones} de ${state.total} se apartan.`
									: 'Cada unidad responde una cosa distinta.'}
								Se editan abajo, unidad por unidad.
							</p>
						{:else}
							<div class="flex flex-wrap items-start gap-2">
								<!--
									**`uniform` va en nulo cuando las unidades no coinciden, y punto.**

									El control construye la selección nueva a partir de lo que aquí se le
									pasa, y sabe pintarse «mixto» cuando recibe nulo habiendo respuestas.
									Hubo un momento en que se le pasaba la respuesta mayoritaria para que
									se viera algo, y salió caro: con un quebrado puesto en una sola copla,
									el atajo lo mostraba como si fuera de todas, y al marcar dos más
									partía de aquel y escribía los tres en todas. Cuántas coinciden se
									dice al lado, en el rótulo, que es donde no hace daño.
								-->
								{#if pregunta.admiteEscrito}
									<!--
										**El mismo campo que usa cada unidad, no una copia.**

										Escribir aquí un segundo campo de esquema con su lectura contra la
										norma y su selector de régimen es exactamente lo que ya pasó una vez
										con el control común, y acabaron divergiendo. El rótulo lo pone la
										fila, así que el campo va sin el suyo.

										Vale para los dos controles de rima. En el de repertorio con salida
										abierta hacía falta igual: la octava real invita por escrito a
										escribir otro esquema y en conjunto no había dónde.
									-->
									<div class="min-w-0 flex-1">
										<MetricChoiceField
											group={pregunta.groups[0]}
											variant="celda"
											sinRotulo
											label={pregunta.label}
											options={comunOptions(pregunta)}
											normaEsquema={normaEsquemaComun(pregunta)}
											selectedIds={idsComunes(pregunta, state.uniform ?? [])}
											onChange={(ids) => aplicarComun(pregunta, ids.map(optionSlugOf))}
											textValue={state.textoUniforme ?? ''}
											onTextChange={(value) => aplicarComunTexto(pregunta, value)}
										/>
									</div>
								{:else}
									<MetricFamilyControl
										group={pregunta.groups[0]}
										options={comunOptions(pregunta)}
										uniform={state.uniform}
										answered={state.answered}
										realizaciones={state.total}
										ariaLabel={pregunta.label}
										positionLimit={comunPositionLimit(pregunta)}
										onChoose={(slugs) => aplicarComun(pregunta, slugs)}
									/>
								{/if}
								{#if pregunta.help}
									<FieldHelpTooltip
										text={pregunta.help}
										label={`Ayuda sobre «${pregunta.label}»`}
									/>
								{/if}
							</div>
						{/if}
					</MetricGridRow>
					{/each}
				</div>
			</div>
		{/if}
	</div>
	{/if}

	<!--
		Se llamaba «verso a verso» y no lo es cuando lo que se lista son unidades: en una copla
		castellana de dos coplas, lo que hay debajo son las dos coplas con sus partes, no dieciséis
		versos.
	-->
	<div class={hayZonaComun ? 'mt-6 border border-[color:var(--border)]' : 'border border-[color:var(--border)]'}>
		{#if rows.length > 0}
			<p class="form-grid-title border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2">
				{totalDeUnidades > 1 ? 'La secuencia, unidad por unidad' : 'La secuencia, verso a verso'}
			</p>
		{/if}

		{#if listaCompacta}
			<!-- Una debajo de otra: en fila corrida no se distingue dónde acaba una copla y empieza la siguiente. -->
			<ul class="px-3 py-2.5">
				<!-- Solo las unidades de primer nivel: sus partes ya van dentro de su anotación. -->
				{#each unidadesRaiz as entrada (entrada.unit.realizacion_id)}
					{@const notacion = notacionDeLaUnidad(entrada.unit)}
					<li class="flex flex-wrap items-baseline gap-x-3 text-sm leading-relaxed">
						<span>
							{entrada.rotulo}
							<span class="tabular-nums text-[color:var(--muted-foreground)]">
								vv. {entrada.unit.v_ini}–{entrada.unit.v_fin}
							</span>
						</span>
						<!-- La anotación va al lado y en pequeño: informa sin ocupar otra línea. -->
						{#if notacion}
							<span class="text-xs tabular-nums text-[color:var(--muted-foreground)]">
								{notacion}
							</span>
						{/if}
					</li>
				{/each}
			</ul>
		{:else}
		{#each rows as row (row.key)}
			{#if !esParteIntegrada(row) && !filaOculta(row)}
			{#if row.kind === 'pregunta'}
				<MetricGridRow label={row.label} depth={row.depth}>
					{@render camposDeLaParte(row.preguntas)}
				</MetricGridRow>
			{:else if row.kind === 'fijas'}
				<!--
					«Cuartetos · 2 · vv. 1–8» se lee como «el cuarteto número 2». Cuántas hay va con
					su sustantivo, del lado de la respuesta, y en femenino porque concuerda con
					«realizaciones»: el catálogo no declara el género de los nombres de sección.
				-->
				{@const norma = `${row.cuantas} ${
						row.cuantas === 1 ? 'realización' : 'realizaciones'
					} de ${row.versos} ${row.versos === 1 ? 'verso' : 'versos'}`}
				<MetricGridRow
					label={row.label}
					rango={`vv. ${row.v_ini}–${row.v_fin}`}
					nota={row.preguntas.length > 0 ? `${norma}, fijas por la forma` : undefined}
					notaAyuda={EXTENT_HELP}
					depth={row.depth}
					variant={row.preguntas.length > 0 ? 'normal' : 'resumen'}
				>
					<!--
						Cuando la parte no pregunta nada, no se dice nada. «1 realización de 4 versos · la
						norma las fija enteras», repetido en cada redondilla de cada copla, era media
						pantalla para decir lo que el rótulo de al lado —«Primera redondilla · vv. 1–4»— ya
						deja ver. La extensión sigue explicándose donde importa: en las partes que sí
						preguntan, por su `nota`.
					-->
					{#if row.preguntas.length > 0}
						{@render camposDeLaParte(row.preguntas)}
					{/if}
				</MetricGridRow>
			{:else if row.kind === 'acciones'}
				<MetricGridRow
					label={row.modo === 'contar'
						? `N.º de ${row.label.toLocaleLowerCase('es')}`
						: row.label}
					depth={row.depth}
					variant="resumen"
				>
					{#if row.modo === 'contar'}
						<input
							type="number"
							min={row.minimo}
							max={row.maximo ?? undefined}
							class="h-9 w-24 border border-[color:var(--border)] bg-white px-2"
							value={row.cuantas}
							aria-label={`Número de ${row.label.toLocaleLowerCase('es')}`}
							onchange={(event) =>
								setInstanceCount(
									row.section,
									row.parentUnitId,
									row.minimo,
									row.maximo,
									Number(event.currentTarget.value)
								)}
						/>
					{:else}
						<button
							type="button"
							class="link-action self-start"
							onclick={() =>
								addInstance(
									row.section ? String(row.section.seccion_id) : null,
									row.parentUnitId
								)}
						>
							+ Añadir
						</button>
					{/if}
				</MetricGridRow>
			{:else}
				{@const parts = partesIntegradas(row)}
				{@const fixedRhymeParts = partesFijasConRima(row)}
				{@const completePatternQuestion = preguntaPosicionalCompleta(row)}
				{@const partialQuestions = preguntasPosicionalesParciales(row)}
				{@const otherQuestions = row.preguntas.filter(
					(pregunta: PreguntaEnFila) => !partialQuestions.includes(pregunta)
				)}
				<!--
					**Una unidad abierta se puede plegar aunque no esté respondida.**

					Plegar solo se ofrecía cuando la unidad estaba contestada entera, que es justo
					cuando menos falta hace. Respondiendo una a una, seis coplas desplegadas con sus
					dos preguntas cada una no caben en la pantalla, y hasta contestarlas no había
					manera de recogerlas.
				-->
				{@const abiertaPorModo =
					comunes.length > 0 && esUnidadComun(row.unit) && unidadAbierta()}
				{@const plegable =
					abiertaPorModo || (parts.length > 0 ? puedePlegarCompuesta(row, parts) : puedePlegar(row))}
				{@const plegada = plegable && unidadesPlegadas.has(row.unit.realizacion_id)}
				{@const respondida =
					row.preguntas.every(preguntaRespondida) &&
					parts.every((part: GridFijasRow) => part.preguntas.every(preguntaRespondida))}
				<MetricGridRow
					label={row.label}
					rango={`vv. ${row.unit.v_ini}–${row.unit.v_fin}`}
					nota={row.nota}
					depth={row.depth}
					variant={row.container || parts.length > 0 || fixedRhymeParts.length > 0 ? 'grupo' : 'normal'}
					actionLabel={plegable ? (plegada ? 'Desplegar' : 'Plegar') : undefined}
					onAction={plegable
						? () => setUnidadPlegada(row.unit.realizacion_id, !plegada)
						: undefined}
				>
					{#if sectionDefinesPattern(row.section)}
						{@const source = patternSource(row)}
						{@const metroQuestion = patternQuestion(row, 'metro')}
						{@const rhymeQuestion = patternQuestion(row, 'rima')}
						{#if source.realizacion_id !== row.unit.realizacion_id}
							<div class="border border-[color:var(--border)] bg-[color:var(--gray-50)] px-3 py-2">
								<p class="text-sm font-medium">{patternSummary(row)}</p>
								<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">
									Resultado heredado de la estancia modelo. Si el testimonio no lo cumple,
									registra una desviación.
								</p>
							</div>
						{:else}
							<div class="space-y-3">
								<label class="flex items-center gap-2 text-xs text-[color:var(--muted-foreground)]">
									<span>N.º de versos</span>
									<input
										type="number"
										min={verseMinimum(row.section)}
										max={verseMaximum(row.section) ?? undefined}
										class="h-9 w-24 border border-[color:var(--border)] bg-white px-2 text-sm"
										value={row.unit.v_fin - row.unit.v_ini + 1}
										onchange={(event) =>
											setPatternLength(row, row.section, Number(event.currentTarget.value))}
									/>
									<span>Se aplicará a todas las estancias.</span>
								</label>

								{#if metroQuestion}
									<div>
										<p class="form-label mb-1.5 flex items-center gap-2">
											<span>Patrón de la estancia <span aria-hidden="true">*</span></span>
											{#if rhymeQuestion?.group.ayuda_editor}
												<FieldHelpTooltip
													text={String(rhymeQuestion.group.ayuda_editor)}
													label="Ayuda sobre la notación de la rima"
												/>
											{/if}
										</p>
										<p class="mb-2 text-xs text-[color:var(--muted-foreground)]">
											Elige la medida y la clase de rima de cada verso. Las demás estancias
											repetirán esta disposición.
										</p>
										<MetricVersePatternField
											length={row.unit.v_fin - row.unit.v_ini + 1}
											options={optionsForGroup(String(metroQuestion.group.grupo_eleccion_id))}
											selectedIds={selectedChoiceIds(
												String(metroQuestion.group.grupo_eleccion_id),
												row.unit.realizacion_id
											)}
											onMeasureChange={(ids) =>
												setPatternChoices(row, metroQuestion.group, ids)}
											rhymeValue={rhymeQuestion
												? choiceTextValue(
														String(rhymeQuestion.group.grupo_eleccion_id),
														row.unit.realizacion_id
													)
												: undefined}
											onRhymeChange={rhymeQuestion
												? (value) => setPatternRhyme(row, rhymeQuestion.group, value)
												: undefined}
										/>
									</div>
								{/if}
							</div>
						{/if}

						{#if row.removable}
							<button
								type="button"
								class="link-action link-action--danger self-start"
								onclick={() => removeInstance(row.unit)}
							>
								Quitar {nodeLabel(context, row.section).toLocaleLowerCase('es')}
							</button>
						{/if}
					{:else if completePatternQuestion && fixedRhymeParts.length > 0}
						<div class="space-y-3">
							<p class="text-xs text-[color:var(--muted-foreground)]">
								La medida y la rima se leen juntas. La rima ya está fijada por las partes de
								la estancia; solo hay que indicar si cada verso mide 7 u 11 sílabas.
							</p>
							<MetricVersePatternField
								length={row.unit.v_fin - row.unit.v_ini + 1}
								options={optionsForGroup(
									String(completePatternQuestion.group.grupo_eleccion_id)
								)}
								selectedIds={selectedChoiceIds(
									String(completePatternQuestion.group.grupo_eleccion_id),
									row.unit.realizacion_id
								)}
								onMeasureChange={(ids) =>
									setChoices(completePatternQuestion.group, row.unit, ids)}
								fixedRhymes={fixedRhymesFor(row, fixedRhymeParts)}
							/>
							<div class="flex flex-wrap gap-x-4 gap-y-1 text-xs text-[color:var(--muted-foreground)]">
								{#each fixedRhymeParts as part (part.key)}
									<span>{part.label}: vv. {part.v_ini}–{part.v_fin}</span>
								{/each}
							</div>
						</div>
					{:else if plegada}
						{#if !respondida}
							<span class="text-sm text-[color:var(--muted-foreground)]">
								Sin responder todavía.
							</span>
						{:else if parts.length > 0}
							<span class="text-sm text-[color:var(--muted-foreground)]">
								Respuesta registrada en {parts.length} partes.
							</span>
						{:else}
							{@const notacion = notacionDeLaUnidad(row.unit)}
							{@const restantes = notacion
								? row.preguntas.filter(
										(pregunta: PreguntaEnFila) =>
											pregunta.group.dimension !== 'rima' &&
											pregunta.group.dimension !== 'metro'
									)
								: row.preguntas}
							{#if notacion}
								<p class="text-sm tabular-nums">{notacion}</p>
							{/if}
							{#if restantes.length > 0}
								{@render camposDeLaParte(
									restantes,
									row.equivalentes,
									true,
									() => setUnidadPlegada(row.unit.realizacion_id, false),
									undefined,
									undefined,
									true
								)}
							{/if}
						{/if}
					{:else}
					{#if parts.length > 0}
						{@render camposDeLaParte(otherQuestions, row.equivalentes)}
						<div class="space-y-3">
							{#each parts as part (part.key)}
								<section class="border border-[color:var(--border)] bg-white">
									<div class="border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2">
										<p class="text-sm font-medium">{part.label}</p>
										<p class="text-xs tabular-nums text-[color:var(--muted-foreground)]">
											vv. {part.v_ini}–{part.v_fin} · {part.versos} versos
										</p>
									</div>
									<div class="space-y-4 p-3">
										{@render camposDeLaParte(part.preguntas, row.equivalentes)}
										{#each partialQuestions as pregunta (String(pregunta.group.grupo_eleccion_id))}
											{@render campo(
												pregunta,
												row.equivalentes,
												false,
												undefined,
												part.v_ini - row.unit.v_ini + 1,
												part.v_fin - row.unit.v_ini + 1
											)}
										{/each}
									</div>
								</section>
							{/each}
						</div>
					{:else}
					{#if row.lengthEditable}
						<div class="flex flex-wrap items-center gap-3">
							<label class="flex items-center gap-2 text-xs text-[color:var(--muted-foreground)]">
								<span>N.º de versos</span>
								<input
									type="number"
									min={verseMinimum(row.section)}
									max={verseMaximum(row.section) ?? undefined}
									class="h-9 w-24 border border-[color:var(--border)] bg-white px-2 text-sm"
									value={row.unit.v_fin - row.unit.v_ini + 1}
									onchange={(event) =>
										setUnitLength(row.unit, row.section, Number(event.currentTarget.value))}
								/>
							</label>
							{#if row.equivalentes > 1 && equivalentLengthDiffers(row.unit)}
								<button
									type="button"
									class="link-action"
									onclick={() => applyUnitLengthToEquivalentUnits(row.unit)}
								>
									Aplicar esta extensión a las {row.equivalentes} unidades
								</button>
							{/if}
						</div>
					{/if}

					{@render excepcionDeLaUnidad(row)}

					{#if row.preguntas.length === 0 && !row.lengthEditable}
						<span class="text-sm text-[color:var(--muted-foreground)]">
							{row.unit.v_fin - row.unit.v_ini + 1} versos · patrón fijo por la arquitectura
						</span>
					{:else}
						{@render camposDeLaParte(row.preguntas, row.equivalentes)}
					{/if}

					{#if row.removable}
						<button
							type="button"
							class="link-action link-action--danger self-start"
							onclick={() => removeInstance(row.unit)}
						>
							Quitar {nodeLabel(context, row.section).toLocaleLowerCase('es')}
						</button>
					{/if}
					{/if}
					{/if}
				</MetricGridRow>
			{/if}
			{/if}
		{/each}
		{/if}
	</div>
</div>

{#snippet camposDeLaParte(
	preguntas: PreguntaEnFila[],
	equivalentes = 1,
	forceCompact = false,
	onOpenUnit: (() => void) | undefined = undefined,
	positionStart: number | undefined = undefined,
	positionEnd: number | undefined = undefined,
	comoResumen = false
)}
	<div class={comoResumen ? 'space-y-1' : preguntas.length > 1 ? 'metric-choice-group' : 'contents'}>
		{#each preguntas as pregunta (String(pregunta.group.grupo_eleccion_id))}
			{@render campo(
				pregunta,
				equivalentes,
				forceCompact,
				onOpenUnit,
				positionStart,
				positionEnd,
				comoResumen
			)}
		{/each}
	</div>
{/snippet}

<!--
	Una pregunta dentro de una fila.

	`pregunta.owner` no siempre es la realización de la fila: los dos esquemas del soneto se
	preguntan en la fila de sus cuartetos o de sus tercetos y se guardan en la unidad, porque
	describen cómo se entrelazan las rimas de las dos secciones y no pertenecen a ninguna.

	El enunciado se repite en cada fila a propósito. Se podría deducir de la columna de la
	izquierda y de la pregunta común de arriba, pero deducirlo es trabajo, y lo que se ganaba
	quitándolo no compensa tener que averiguar de qué va un desplegable.
-->
{#snippet campo(
	pregunta: PreguntaEnFila,
	equivalentes = 1,
	forceCompact = false,
	onOpenUnit: (() => void) | undefined = undefined,
	positionStart: number | undefined = undefined,
	positionEnd: number | undefined = undefined,
	comoResumen = false
)}
	{@const group = pregunta.group}
	{@const groupId = String(group.grupo_eleccion_id)}
	{@const unit = pregunta.owner}
	{@const estado = estadoDeRespuesta(context, group, unit)}
	{@const familia = familiaDe(group)}
	{@const abierta = unidadAbierta()}
	{@const seAparta = familia !== null && unidadesQueSeApartan.has(unit.realizacion_id)}
	{@const compacta = forceCompact}
	<!--
		**Lo que ya está respondido arriba no se repite aquí.**

		Una pregunta que se responde en conjunto solo baja a la unidad cuando hay algo que mirar: o
		la unidad se aparta de las demás, o el editor ha pedido responderlas una a una. Si todas
		coinciden, la fila de la unidad se queda en su rótulo —«Copla 2 · vv. 9–16»— y la lista cabe
		de un vistazo.

		Antes bajaban siempre, resumidas con un «Coincide con las demás unidades» repetido tantas
		veces como unidades hubiera, que es exactamente la línea que no aportaba nada.
	-->
	{#if familia === null || abierta}
	<div>
		{#if familia && seAparta}
			<p class="mb-2 text-xs font-medium text-amber-800">
				Esta {unitShortName} es diferente a las demás
			</p>
		{/if}
		<MetricChoiceField
			{group}
			variant="celda"
			label={pregunta.label}
			showDescription={estado !== 'igual'}
			compact={compacta}
			resumen={comoResumen}
			compactNote={forceCompact && !comoResumen ? `Respuesta de esta ${unitShortName}` : undefined}
			changeLabel="Cambiar"
			hideCompactAction={forceCompact}
			onExpand={compacta ? () => onOpenUnit?.() : undefined}
			options={optionsForGroup(groupId)}
			normaEsquema={normaEsquemaDe(group, pregunta.owner)}
			selectedIds={selectedChoiceIds(groupId, unit.realizacion_id)}
			onChange={(ids) => setChoices(group, unit, ids)}
			textValue={choiceTextValue(groupId, unit.realizacion_id)}
			onTextChange={(value) => setChoiceText(group, unit, value)}
			onApplyAll={!respondePorPartes && familia === null && equivalentes > 1
				? () => applyChoiceToEquivalentUnits(group, unit)
				: undefined}
			positionStart={positionStart}
			positionLimit={positionEnd ?? unit.v_fin - unit.v_ini + 1}
			pendingPositions={pendingPositionsFor(groupId, unit.realizacion_id)}
			onPendingPositionsChange={(positions) =>
				setPendingPositionsFor(groupId, unit.realizacion_id, positions)}
		/>
	</div>
	{/if}
{/snippet}

<!--
	La excepción que el catálogo declara: una arquitectura de la misma forma que **aparece
	intercalada** entre realizaciones de otra. Hoy solo la décima aumentada, que alarga su miembro
	final de cuatro versos a seis y que Morley y Bruerton documentan entre décimas normales.

	No es una desviación y no se registra como tal: la norma admite la estrofa larga. Marcarla apaga
	la derivación de unidades desde el rango —una tirada con una aumentada mide `10n + 2`— y deja
	que la cobertura gobierne, que es lo que ya hace en las formas con secciones.

	La fila no ofrece nada donde la forma no declara ninguna intercalable, que son todas menos una.
-->
{#snippet excepcionDeLaUnidad(row: GridRealizacionRow)}
	{#if (props.interleavedArchitectures ?? []).length > 0 && row.depth === 0}
		<label class="mt-2 flex flex-wrap items-center gap-2 text-xs text-[color:var(--muted-foreground)]">
			<span>Esta unidad es</span>
			<select
				class="h-8 border border-[color:var(--border)] bg-white px-2 text-xs"
				value={row.unit.arquitectura_id ?? ''}
				onchange={(event) =>
					props.onUnitArchitectureChange?.(
						row.unit,
						event.currentTarget.value || null
					)}
			>
				<option value="">la arquitectura de la secuencia</option>
				{#each props.interleavedArchitectures ?? [] as arquitectura (arquitectura.arquitectura_id)}
					<option value={arquitectura.arquitectura_id}>{arquitectura.nombre}</option>
				{/each}
			</select>
			{#if row.unit.arquitectura_id}
				<span>Cuenta sus propios versos; el pasaje se comprueba por cobertura.</span>
			{/if}
		</label>
	{/if}
{/snippet}

<script lang="ts">
	import type { Snippet } from 'svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import SegmentedChoice from '$lib/components/ui/segmented-choice.svelte';
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
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
	const comunes = $derived(respondePorPartes ? [] : preguntasCompartidas(context));
	const opcionales = $derived(respondePorPartes ? [] : seccionesOpcionalesUniformes(context));
	let respuestasComunesAbiertas = $state(new Set<string>());
	let unidadesPlegadas = $state(new Set<string>());
	let pendingPositionsByAnswer = $state<Record<string, number[]>>({});
	let batchOpen = $state(false);
	let batchDrafts = $state<Record<string, string[]>>({});
	const unitShortName = $derived(
		String(props.unitLabel ?? 'unidad').split(/\s+/)[0].toLocaleLowerCase('es')
	);
	const hayAjustesDeComposicion = $derived(
		(!respondePorPartes && Boolean(props.globalQuestions)) || opcionales.length > 0
	);
	const hayZonaComun = $derived(hayAjustesDeComposicion || comunes.length > 0);
	const batchUnitCount = $derived.by(() =>
		comunes.reduce(
			(maximum: number, pregunta: PreguntaCompartida) =>
				Math.max(maximum, comunState(pregunta).total),
			0
		)
	);
	const batchChangeCount = $derived(Object.keys(batchDrafts).length);

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
					choice.realizacion_prueba_id === unitId &&
					Boolean(choice.opcion_eleccion_id)
			)
			.map((choice: MetricChoiceDraft) => choice.opcion_eleccion_id as string);
	}

	function choiceTextValue(groupId: string, unitId: string): string {
		return (
			props.choices.find(
				(choice: MetricChoiceDraft) =>
					choice.grupo_eleccion_id === groupId &&
					choice.realizacion_prueba_id === unitId &&
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
					source.realizacion_prueba_id
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
			? choiceTextValue(String(rhyme.group.grupo_eleccion_id), source.realizacion_prueba_id).trim()
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
			next.map((unit: MetricUnitDraft) => unit.realizacion_prueba_id)
		);
		const removedIds = previous
			.map((unit: MetricUnitDraft) => unit.realizacion_prueba_id)
			.filter((unitId: string) => !remainingIds.has(unitId));
		if (removedIds.length > 0) props.onUnitsRemoved(removedIds);
		props.onUnitsChange(next);
	}

	// ------------------------------------------------------------------
	// Responder
	//
	// Todas las respuestas se guardan igual que antes: una fila por realización en
	// `elecciones_editor_metrico`. Lo único que cambia es desde dónde se escriben.
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
						choice.realizacion_prueba_id === unitId
					)
			),
			...optionIds.map((optionId) => ({
				realizacion_prueba_id: unitId,
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
			unit.realizacion_prueba_id,
			optionIds
		);
		props.onChoicesChange(nextChoices);
		commitUnits(
			syncChoiceMaterializedSections(
				props.units,
				props.sections,
				unit.realizacion_prueba_id,
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
				unit.realizacion_prueba_id,
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
						choice.realizacion_prueba_id === unit.realizacion_prueba_id
					)
			),
			...(normalized
				? [
						{
							realizacion_prueba_id: unit.realizacion_prueba_id,
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
							choice.realizacion_prueba_id === unit.realizacion_prueba_id
						)
				),
				...(normalized.trim()
					? [
							{
								realizacion_prueba_id: unit.realizacion_prueba_id,
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
		const selected = selectedChoiceIds(groupId, sourceUnit.realizacion_prueba_id);
		const sourceChoices = props.choices.filter(
			(choice: MetricChoiceDraft) =>
				choice.grupo_eleccion_id === groupId &&
				choice.realizacion_prueba_id === sourceUnit.realizacion_prueba_id
		);
		let nextChoices = [...props.choices];
		let nextUnits = [...props.units];

		for (const unit of unitsForGroup(context, group)) {
			nextChoices = [
				...nextChoices.filter(
					(choice: MetricChoiceDraft) =>
						!(
							choice.grupo_eleccion_id === groupId &&
							choice.realizacion_prueba_id === unit.realizacion_prueba_id
						)
				),
				...sourceChoices.map((choice: MetricChoiceDraft) => ({
					...choice,
					realizacion_prueba_id: unit.realizacion_prueba_id
				}))
			];
			nextUnits = syncChoiceMaterializedSections(
				nextUnits,
				props.sections,
				unit.realizacion_prueba_id,
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
	function comunState(pregunta: PreguntaCompartida) {
		const answers = new Set<string>();
		let answered = 0;
		let total = 0;
		for (const group of pregunta.groups) {
			const groupId = String(group.grupo_eleccion_id);
			for (const unit of unitsForGroup(context, group)) {
				total += 1;
				const selected = selectedChoiceIds(groupId, unit.realizacion_prueba_id);
				if (selected.length === 0) continue;
				answered += 1;
				answers.add(selected.map(optionSlugOf).sort().join('|'));
			}
		}
		const uniform =
			total > 0 && answered === total && answers.size === 1
				? [...answers][0].split('|').filter(Boolean)
				: null;
		return { total, answered, uniform };
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
					unit.realizacion_prueba_id,
					optionIds
				);
				nextUnits = syncChoiceMaterializedSections(
					nextUnits,
					props.sections,
					unit.realizacion_prueba_id,
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

	function stagedComunChoice(
		pregunta: PreguntaCompartida,
		uniform: string[] | null
	): string[] | null {
		return Object.hasOwn(batchDrafts, pregunta.key) ? batchDrafts[pregunta.key] : uniform;
	}

	function stageComunChoice(pregunta: PreguntaCompartida, slugs: string[]) {
		batchDrafts = { ...batchDrafts, [pregunta.key]: slugs };
	}

	function openBatch() {
		batchDrafts = {};
		batchOpen = true;
	}

	function closeBatch() {
		batchDrafts = {};
		batchOpen = false;
	}

	function applyBatch() {
		let nextChoices = [...props.choices];
		let nextUnits = [...props.units];
		for (const pregunta of comunes) {
			if (!Object.hasOwn(batchDrafts, pregunta.key)) continue;
			const result = writeComunChoice(
				pregunta,
				batchDrafts[pregunta.key],
				nextChoices,
				nextUnits
			);
			nextChoices = result.choices;
			nextUnits = result.units;
		}
		props.onChoicesChange(nextChoices);
		commitUnits(nextUnits);
		closeBatch();
	}

	function abrirRespuestaComun(groupId: string, unitId: string) {
		respuestasComunesAbiertas = new Set(respuestasComunesAbiertas).add(`${groupId}|${unitId}`);
	}

	function tieneRespuestaComun(group: MetricCatalogDomainRow): boolean {
		const groupId = String(group.grupo_eleccion_id);
		return comunes.some((comun: PreguntaCompartida) =>
			comun.groups.some(
				(miembro: MetricCatalogDomainRow) =>
					String(miembro.grupo_eleccion_id) === groupId
			)
		);
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
		if (pregunta.group.tipo_control === 'esquema_rima') {
			return Boolean(choiceTextValue(groupId, pregunta.owner.realizacion_prueba_id).trim());
		}
		const selected = selectedChoiceIds(groupId, pregunta.owner.realizacion_prueba_id);
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
					candidate.parentUnitId === row.unit.realizacion_prueba_id &&
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
					candidate.parentUnitId === row.unit.realizacion_prueba_id &&
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
					unit.realizacion_padre_id === parent.realizacion_prueba_id &&
					unit.seccion_id === targetSectionId
			);
			if (present && existing.length === 0) {
				nextUnits = addSectionInstance(
					nextUnits,
					props.sections,
					targetSectionId,
					parent.realizacion_prueba_id,
					props.sequenceStart,
					props.choices,
					props.options
				);
			}
			if (!present) {
				for (const unit of existing) {
					nextUnits = removeMetricUnitTree(
						nextUnits,
						unit.realizacion_prueba_id,
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
			peers.some((peer) => peer.realizacion_prueba_id === unit.realizacion_prueba_id)
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
					choice.realizacion_prueba_id === source.realizacion_prueba_id
			);
			for (const target of peers.slice(1)) {
				nextChoices = [
					...nextChoices.filter(
						(choice: MetricChoiceDraft) =>
							!(
								choice.grupo_eleccion_id === groupId &&
								choice.realizacion_prueba_id === target.realizacion_prueba_id
							)
					),
					...sourceChoices.map((choice: MetricChoiceDraft) => ({
						...choice,
						realizacion_prueba_id: target.realizacion_prueba_id
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
					unit.realizacion_prueba_id,
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
		const removedIds = [...unitIdsInTree(props.units, unit.realizacion_prueba_id)];
		const remaining = removeMetricUnitTree(
			props.units,
			unit.realizacion_prueba_id,
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
			item.realizacion_prueba_id === unit.realizacion_prueba_id
				? { ...item, v_fin: item.v_ini + length - 1 }
				: item
		);
		const sobran = positionalChoicesBeyond(length);
		if (sobran.size > 0) {
			props.onChoicesChange(
				props.choices.filter(
					(choice: MetricChoiceDraft) =>
						choice.realizacion_prueba_id !== unit.realizacion_prueba_id ||
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
			patternUnits(row).map((unit: MetricUnitDraft) => unit.realizacion_prueba_id)
		);
		const sobran = positionalChoicesBeyond(length);
		const nextChoices = props.choices.filter(
			(choice: MetricChoiceDraft) =>
				!peerIds.has(choice.realizacion_prueba_id ?? '') ||
				!choice.opcion_eleccion_id ||
				!sobran.has(choice.opcion_eleccion_id)
		);
		const changed = props.units.map((unit: MetricUnitDraft) =>
			peerIds.has(unit.realizacion_prueba_id)
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
				.map((unit: MetricUnitDraft) => unit.realizacion_prueba_id)
		);
		const changed = props.units.map((unit: MetricUnitDraft) =>
			equivalentUnitIds.has(unit.realizacion_prueba_id)
				? { ...unit, v_fin: unit.v_ini + length - 1 }
				: unit
		);
		const sobran = positionalChoicesBeyond(length);
		if (sobran.size > 0) {
			props.onChoicesChange(
				props.choices.filter(
					(choice: MetricChoiceDraft) =>
						!equivalentUnitIds.has(choice.realizacion_prueba_id ?? '') ||
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
				unit.realizacion_prueba_id !== sourceUnit.realizacion_prueba_id &&
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

		{#if comunes.length > 0}
			<div class={hayAjustesDeComposicion ? 'border-t border-[color:var(--border)]' : ''}>
				<div class="flex flex-wrap items-center justify-between gap-3 bg-[color:var(--muted)] px-3 py-2">
					<div>
						<p class="form-grid-title">Edición de las unidades</p>
						<p class="mt-0.5 text-xs font-normal normal-case tracking-normal text-[color:var(--muted-foreground)]">
							{batchOpen
								? `Preparando una respuesta para ${batchUnitCount} unidades actuales.`
								: 'Las respuestas se editan abajo, unidad por unidad.'}
						</p>
					</div>
					{#if batchOpen}
						<button type="button" class="link-action" onclick={closeBatch}>Cancelar edición conjunta</button>
					{:else}
						<button type="button" class="link-action" onclick={openBatch}>
							Aplicar una respuesta en conjunto
						</button>
					{/if}
				</div>

				{#if batchOpen}
					<div class="border-t border-amber-300 bg-amber-50">
						<p class="border-b border-amber-200 px-3 py-2 text-xs text-amber-950">
							Solo afectará a las {batchUnitCount} unidades que existen ahora. Las que añadas después
							quedarán sin responder hasta que las edites o vuelvas a aplicar una respuesta conjunta.
						</p>
						{#each comunes as pregunta (pregunta.key)}
							{@const state = comunState(pregunta)}
							<MetricGridRow label={pregunta.label} rango={`${state.total} unidades`} variant="comun">
								<div class="flex flex-wrap items-start gap-2">
									<MetricFamilyControl
										group={pregunta.groups[0]}
										options={comunOptions(pregunta)}
										uniform={stagedComunChoice(pregunta, state.uniform)}
										answered={state.answered}
										realizaciones={state.total}
										ariaLabel={pregunta.label}
										positionLimit={comunPositionLimit(pregunta)}
										onChoose={(slugs) => stageComunChoice(pregunta, slugs)}
									/>
									{#if pregunta.help}
										<FieldHelpTooltip
											text={pregunta.help}
											label={`Ayuda sobre «${pregunta.label}»`}
										/>
									{/if}
								</div>
							</MetricGridRow>
						{/each}
						<div class="flex flex-wrap items-center justify-end gap-3 border-t border-amber-200 px-3 py-2.5">
							<span class="text-xs text-amber-900">
								{batchChangeCount === 0
									? 'Elige al menos una respuesta para aplicarla.'
									: `${batchChangeCount} ${batchChangeCount === 1 ? 'respuesta preparada' : 'respuestas preparadas'}`}
							</span>
							<button
								type="button"
								class="h-9 bg-[color:var(--primary)] px-3 text-sm font-medium text-white disabled:cursor-not-allowed disabled:opacity-50"
								disabled={batchChangeCount === 0}
								onclick={applyBatch}
							>
								Aplicar a las {batchUnitCount} unidades actuales
							</button>
						</div>
					</div>
				{/if}
			</div>
		{/if}

		{#if rows.length > 0}
			<p class="form-grid-title border-b border-t border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2">
				La secuencia, verso a verso
			</p>
		{/if}

		{#each rows as row (row.key)}
			{#if !esParteIntegrada(row)}
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
					{#if row.preguntas.length > 0}
						{@render camposDeLaParte(row.preguntas)}
					{:else}
						<span class="text-sm text-[color:var(--muted-foreground)]" title={EXTENT_HELP}>
							{norma} · la norma las fija enteras
						</span>
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
				{@const plegable = parts.length > 0 ? puedePlegarCompuesta(row, parts) : puedePlegar(row)}
				{@const plegada = plegable && unidadesPlegadas.has(row.unit.realizacion_prueba_id)}
				<MetricGridRow
					label={row.label}
					rango={`vv. ${row.unit.v_ini}–${row.unit.v_fin}`}
					nota={row.nota}
					depth={row.depth}
					variant={row.container || parts.length > 0 || fixedRhymeParts.length > 0 ? 'grupo' : 'normal'}
					actionLabel={plegable ? (plegada ? 'Desplegar' : 'Plegar') : undefined}
					onAction={plegable
						? () => setUnidadPlegada(row.unit.realizacion_prueba_id, !plegada)
						: undefined}
				>
					{#if sectionDefinesPattern(row.section)}
						{@const source = patternSource(row)}
						{@const metroQuestion = patternQuestion(row, 'metro')}
						{@const rhymeQuestion = patternQuestion(row, 'rima')}
						{#if source.realizacion_prueba_id !== row.unit.realizacion_prueba_id}
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
												row.unit.realizacion_prueba_id
											)}
											onMeasureChange={(ids) =>
												setPatternChoices(row, metroQuestion.group, ids)}
											rhymeValue={rhymeQuestion
												? choiceTextValue(
														String(rhymeQuestion.group.grupo_eleccion_id),
														row.unit.realizacion_prueba_id
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
									row.unit.realizacion_prueba_id
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
						{#if parts.length > 0}
							<span class="text-sm text-[color:var(--muted-foreground)]">
								Respuesta registrada en {parts.length} partes.
							</span>
						{:else}
							{@render camposDeLaParte(
								row.preguntas,
								row.equivalentes,
								true,
								() => setUnidadPlegada(row.unit.realizacion_prueba_id, false)
							)}
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
	</div>
</div>

{#snippet camposDeLaParte(
	preguntas: PreguntaEnFila[],
	equivalentes = 1,
	forceCompact = false,
	onOpenUnit: (() => void) | undefined = undefined,
	positionStart: number | undefined = undefined,
	positionEnd: number | undefined = undefined
)}
	<div class={preguntas.length > 1 ? 'metric-choice-group' : 'contents'}>
		{#each preguntas as pregunta (String(pregunta.group.grupo_eleccion_id))}
			{@render campo(
				pregunta,
				equivalentes,
				forceCompact,
				onOpenUnit,
				positionStart,
				positionEnd
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
	positionEnd: number | undefined = undefined
)}
	{@const group = pregunta.group}
	{@const groupId = String(group.grupo_eleccion_id)}
	{@const unit = pregunta.owner}
	{@const estado = estadoDeRespuesta(context, group, unit)}
	{@const yaArriba = tieneRespuestaComun(group)}
	{@const claveComun = `${groupId}|${unit.realizacion_prueba_id}`}
	{@const comunAbierta = respuestasComunesAbiertas.has(claveComun)}
	{@const compactaComun =
		yaArriba && estado === 'igual' && !respuestasComunesAbiertas.has(claveComun)}
	{@const compacta = forceCompact || compactaComun}
	<!--
		La respuesta que coincide con todas sus equivalentes se resume para aligerar la lista.
		La que solo coincide con algunas, la individual y la que falta se leen enteras.
	-->
	<div>
		{#if yaArriba && !compactaComun}
			<p class="mb-2 text-xs font-medium text-amber-800">
				{estado === 'compartida'
					? 'Esta respuesta coincide en varias unidades, pero no en todas'
					: estado === 'propia'
					? `Respuesta diferente en esta ${unitShortName}`
					: comunAbierta
						? `Editando solo esta ${unitShortName}`
						: `Esta ${unitShortName} está sin responder`}
			</p>
		{/if}
		<MetricChoiceField
			{group}
			variant="celda"
			label={pregunta.label}
			showDescription={estado !== 'igual'}
			compact={compacta}
			compactNote={compactaComun
				? 'Coincide con las demás unidades'
				: forceCompact
					? `Respuesta de esta ${unitShortName}`
					: undefined}
			changeLabel={compactaComun ? `Editar esta ${unitShortName}` : 'Cambiar'}
			hideCompactAction={forceCompact}
			onExpand={compacta
				? () => {
						onOpenUnit?.();
						if (compactaComun) abrirRespuestaComun(groupId, unit.realizacion_prueba_id);
					}
				: undefined}
			options={optionsForGroup(groupId)}
			normaEsquema={normaEsquemaDe(group, pregunta.owner)}
			selectedIds={selectedChoiceIds(groupId, unit.realizacion_prueba_id)}
			onChange={(ids) => setChoices(group, unit, ids)}
			textValue={choiceTextValue(groupId, unit.realizacion_prueba_id)}
			onTextChange={(value) => setChoiceText(group, unit, value)}
			onApplyAll={!respondePorPartes && !yaArriba && equivalentes > 1
				? () => applyChoiceToEquivalentUnits(group, unit)
				: undefined}
			positionStart={positionStart}
			positionLimit={positionEnd ?? unit.v_fin - unit.v_ini + 1}
			pendingPositions={pendingPositionsFor(groupId, unit.realizacion_prueba_id)}
			onPendingPositionsChange={(positions) =>
				setPendingPositionsFor(groupId, unit.realizacion_prueba_id, positions)}
		/>
	</div>
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

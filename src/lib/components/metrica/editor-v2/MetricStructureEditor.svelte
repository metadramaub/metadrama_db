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
		presenciaDeSeccion,
		parentInstancesOf,
		seccionesOpcionalesUniformes,
		unitsForGroup,
		usaRespuestasPorPartes,
		type GridRowContext,
		type GridFijasRow,
		type GridRealizacionRow,
		type GridRow,
		type PreguntaEnFila
	} from './grid-rows';
	import { preguntasDelFormulario, type PreguntaFormulario } from './preguntas-formulario';

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
		/**
		 * Lo que afirma cada variedad, ya resuelto: su notación de rima y lo que mide cada verso.
		 *
		 * Una variedad reúne un esquema de rima y uno métrico, así que responderla dice las dos
		 * cosas. Sin esto, elegir variedad no cambiaba nada en la anotación de la unidad.
		 */
		varieties?: { variedadId: string; notacion: string | null; medidas: (number | null)[] }[];
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
		/**
		 * Si el pasaje todavía no está repartido: o el número de versos no cabe en la forma, o la
		 * estructura no cubre el rango declarado.
		 *
		 * **Es lo único que invalida la lectura de abajo.** Con una quintilla de doce versos, «qué se
		 * va a registrar» enumeraba una unidad —las únicas cinco materializadas— y callaba los siete
		 * restantes, así que prometía de más y enseñaba de menos.
		 *
		 * Que falte **responder** una pregunta no es lo mismo: la lectura sigue siendo fiel a lo que
		 * hay, solo que incompleta, y esconderla mientras se contesta quita de la vista justamente lo
		 * que sirve para comprobar la respuesta.
		 */
		rangoSinCuadrar?: boolean;
		/**
		 * Las preguntas cuya respuesta no cuelga de ninguna realización —los rasgos del pasaje—, para
		 * pintarlas aquí, delante de las de unidad. Son respuestas como las demás y separarlas en una
		 * sección propia era exponer la fontanería.
		 */
		preguntasDeSecuencia?: Snippet;
		/**
		 * Y las licencias de esas preguntas, para que salgan **en el mismo pie** que las de unidad.
		 *
		 * Puestas con sus campos salían arriba del todo —en el soneto, «+ final acentual» antes que
		 * ninguna pregunta—, y quedaban dos pies diciendo lo mismo en la misma pantalla. El rótulo lo
		 * pone el pie una vez, por eso esto son solo los botones y viene acompañado de cuántos son.
		 */
		licenciasDeSecuencia?: Snippet;
		cuantasLicenciasDeSecuencia?: number;
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
		preguntasDelFormulario(context)
			.map((pregunta: PreguntaFormulario, indice: number) => ({ pregunta, indice }))
			.sort((a, b) => {
				const deSeccion = (entrada: { pregunta: PreguntaFormulario }) =>
					entrada.pregunta.groups.every(
						(group: MetricCatalogDomainRow) => group.seccion_id
					)
						? 1
						: 0;
				return deSeccion(a) - deSeccion(b) || a.indice - b.indice;
			})
			.map((entrada) => entrada.pregunta)
	);
	/**
	 * **Un rasgo opcional sin responder no es una pregunta pendiente.**
	 *
	 * Es la misma regla que ya gobierna los rasgos de la secuencia —el dístico final o el
	 * encadenamiento del endecasílabo suelto—, y no llegaba aquí: aquel chip solo mira las
	 * preguntas cuya respuesta no cuelga de ninguna realización, y **el pie quebrado es de
	 * unidad**. Por eso la quintilla preguntaba siempre por un quiebro que casi nunca hay, en vez
	 * de ofrecerlo al pie.
	 *
	 * El criterio es la opcionalidad y no el rasgo: `posiciones_pie_quebrado` no cuelga de ningún
	 * `rasgo_id` —eso es lo que dice F16— pero declara `selecciones_min = 0`, que es lo que
	 * significa «solo si lo hay». Son diez preguntas de unidad en el catálogo, nueve de ellas el
	 * quiebro.
	 */
	let rasgosPedidos = $state<string[]>([]);
	function esLicenciaSinUsar(pregunta: PreguntaFormulario): boolean {
		if (pregunta.groups.some((group) => Number(group.selecciones_min ?? 0) >= 1)) return false;
		if (!esLicencia(pregunta)) return false;
		if (rasgosPedidos.includes(pregunta.key)) return false;
		return comunState(pregunta).answered === 0;
	}

	/**
	 * **Una licencia es lo que la forma admite, no todo lo que se puede dejar en blanco.**
	 *
	 * El primer predicado era solo la opcionalidad, y con eso el esquema de rima de la copla
	 * manriqueña —que el catálogo declara `0-1`— bajaba al pie como «+ esquema de rima»: la pregunta
	 * principal de la forma, escondida detrás de un botón. Una licencia es un **rasgo** que la forma
	 * admite, y el quiebro, que lo es en todo menos en la columna: cuelga de `metro` porque su rasgo
	 * no tiene valores, que es lo que dice F16.
	 */
	function esLicencia(pregunta: PreguntaFormulario): boolean {
		return (
			Number(pregunta.groups[0]?.selecciones_min ?? 0) === 0 &&
			pregunta.groups.every(
				(group) =>
					String(group.dimension) === 'rasgo' ||
					(String(group.dimension) === 'metro' && pregunta.esPosicional)
			)
		);
	}
	/** Lo que se pregunta arriba: todo menos las licencias que nadie ha dicho que se usen. */
	const preguntasVisibles = $derived(
		comunes.filter((pregunta: PreguntaFormulario) => !esLicenciaSinUsar(pregunta))
	);
	/** Y lo que se ofrece al pie, en una línea, con un botón cada uno. */
	const rasgosQueAdmite = $derived(
		comunes.filter((pregunta: PreguntaFormulario) => esLicenciaSinUsar(pregunta))
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
	/**
	 * Si la lista de unidades está abierta.
	 *
	 * **No es un modo de trabajo, es un detalle que se consulta.** Estuvo siendo lo primero —«en
	 * conjunto» o «una a una»— y obligaba a elegir cómo responder antes de saber si haría falta:
	 * lo corriente, medido sobre el corpus, es que cuarenta unidades respondan dos o tres cosas
	 * con una dominante, así que se responde una vez y se corrige lo que se aparte. La lista sirve
	 * para revisar y para corregir una unidad concreta, y por eso se abre; no para responder.
	 */
	let verUnidades = $state(false);


	let unidadesPlegadas = $state(new Set<string>());
	const unitShortName = $derived(
		String(props.unitLabel ?? 'unidad').split(/\s+/)[0].toLocaleLowerCase('es')
	);
	const hayAjustesDeComposicion = $derived(
		(!respondePorPartes && Boolean(props.globalQuestions)) || opcionales.length > 0
	);
	/**
	 * Si hay zona de respuestas que pintar.
	 *
	 * **Las formas que crecen por ciclos cuentan aunque no tengan preguntas comunes**: su reparto vive
	 * ahora dentro de esta zona, y sin esto la canción regular —que no pregunta nada, porque sus
	 * partes no declaran nada, que es F2— se quedaba sin reparto y sin nada: la zona no se pintaba y
	 * la de abajo ya no le corresponde.
	 */
	const hayZonaComun = $derived(
		hayAjustesDeComposicion || comunes.length > 0 || respondePorPartes
	);


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

	/**
	 * Lo que se guarda de un esquema escrito a mano.
	 *
	 * Quita la separación accidental **y pone cada letra en su caja**, que es minúscula hasta ocho
	 * sílabas y mayúscula por encima. Antes solo quitaba espacios, con el argumento de que la caja
	 * es del verso y hay que conservar la que se escribió; pero eso dejaba guardado `abab` en un
	 * septeto de endecasílabos, donde el resumen enseñaba `ABAB`. **Si sabemos que es arte mayor no
	 * hay nada que respetar**, y dos anotaciones de lo mismo dejan de quedar escritas distinto.
	 *
	 * Donde no se sabe cuánto mide un verso, su letra se queda como se escribió: eso pasa mientras
	 * la medida está sin responder, y en cuanto se responde la caja se recompone al escribir.
	 */
	function normalizeRhymeScheme(value: string, unit?: MetricUnitDraft): string {
		const compacto = compactRhymeNotation(value);
		if (!unit) return compacto;
		const { medidas, base } = medidasDeLaUnidad(unit);
		if (medidas.size === 0 && base === null) return compacto;
		let posicion = 0;
		return Array.from(compacto)
			.map((signo) => {
				if (signo === '|') return signo;
				posicion += 1;
				if (signo === '-') return signo;
				const silabas = medidas.get(posicion) ?? base;
				return silabas === null || silabas === undefined
					? signo
					: normalizeRhymeSymbol(signo, silabas);
			})
			.join('');
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
		// Una serie de medidas se escribe con espacios y con números: normalizarla como una
		// notación de rima le quitaría precisamente lo que la separa en versos.
		const normalized =
			String(group.tipo_control ?? '') === 'serie_medidas'
				? value.replace(/\s+/g, ' ').trimStart()
				: normalizeRhymeScheme(value, unit);
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

	function comunOptions(pregunta: PreguntaFormulario): MetricCatalogDomainRow[] {
		return optionsForGroup(String(pregunta.groups[0]?.grupo_eleccion_id ?? ''));
	}

	/**
	 * Una respuesta común solo puede utilizar posiciones que existan en todas sus unidades.
	 * Así una copla de cinco versos no recibe las doce posiciones máximas del catálogo.
	 */
	function comunPositionLimit(pregunta: PreguntaFormulario): number | undefined {
		const lengths = pregunta.destinatarias.map(
			({ owner }) => owner.v_fin - owner.v_ini + 1
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
	function comunState(pregunta: PreguntaFormulario) {
		const cuenta = new Map<string, number>();
		let answered = 0;
		let total = 0;
		for (const { group, owner: unit } of pregunta.destinatarias) {
			total += 1;
			const firma = firmaComun(group, unit);
			if (!firma) continue;
			answered += 1;
			cuenta.set(firma, (cuenta.get(firma) ?? 0) + 1);
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
		/**
		 * **Lo que responde la mayoría es lo que enseña «en todas», aunque alguna se aparte.**
		 *
		 * `uniform` solo tiene valor cuando coinciden todas, y con eso el control se vaciaba en
		 * cuanto se declaraba la primera excepción: la pantalla decía «salvo 1 de 5 · abbab» encima
		 * de un desplegable sin elegir, que es justo lo contrario de lo que había pasado.
		 *
		 * Enseñar la mayoritaria fue peligroso mientras responder arriba escribía en todas —marcar
		 * un quebrado más partía del de una sola copla y lo extendía a las demás—. Ya no lo es:
		 * responder arriba escribe **solo en las que siguen la norma**, así que lo que se ve es lo
		 * que se va a tocar.
		 */
		const [generalSlugs, generalTexto] = hayComun
			? leerFirma(mayoritaria)
			: [uniform ?? [], textoUniforme ?? ''];
		return {
			total,
			answered,
			uniform,
			textoUniforme,
			generalSlugs,
			generalTexto,
			hayComun,
			mayoritaria: hayComun ? mayoritaria : null,
			// Sin ninguna respuesta no hay excepción: la pregunta está entera por contestar, y esa
			// es la situación de partida de toda secuencia nueva.
			excepciones: hayComun ? total - repeticiones : 0
		};
	}

	/**
	 * Lo que se aparta de la respuesta común, agrupado por lo que responde.
	 *
	 * **Decir «7 de 52 se apartan» no basta para revisar nada.** Lo que hace falta saber es qué
	 * responden esas siete y dónde están, y eso se lee agrupado: con cuarenta unidades y tres
	 * respuestas, la pantalla tiene dos renglones, no cuarenta. Medido sobre el corpus, es siempre
	 * así: el máximo de variedad son cuatro esquemas en 43 unidades, y siempre hay uno dominante.
	 */
	function excepcionesDe(pregunta: PreguntaFormulario, mayoritaria: string | null) {
		if (!mayoritaria) return [];
		const porFirma = new Map<string, MetricUnitDraft[]>();
		for (const { group, owner: unit } of pregunta.destinatarias) {
			const firma = firmaComun(group, unit);
			if (firma === mayoritaria) continue;
			const actuales = porFirma.get(firma) ?? [];
			actuales.push(unit);
			porFirma.set(firma, actuales);
		}
		return [...porFirma.entries()]
			.map(([firma, unidades]) => ({
				firma,
				etiqueta: etiquetaDeFirma(pregunta, firma),
				unidades,
				rangos: rangosDeUnidades(unidades)
			}))
			.sort((a, b) => b.unidades.length - a.unidades.length);
	}

	/** Cómo se llama lo que una firma dice, para poder leerla sin descifrarla. */
	function etiquetaDeFirma(pregunta: PreguntaFormulario, firma: string): string {
		const [slugs, escrito] = leerFirma(firma);
		if (escrito) return escrito;
		if (slugs.length === 0) return 'sin responder';
		const opciones = comunOptions(pregunta);
		const nombres = slugs.map((slug) => {
			const opcion = opciones.find(
				(candidata: MetricCatalogDomainRow) => optionSlugOf(String(candidata.opcion_eleccion_id)) === slug
			);
			return opcion?.nombre ? String(opcion.nombre) : slug;
		});
		return nombres.join(' · ');
	}

	/** «vv. 91-95, 141-150» en vez de una lista de números. */
	function rangosDeUnidades(unidades: MetricUnitDraft[]): string {
		const ordenadas = [...unidades].sort((a, b) => a.v_ini - b.v_ini);
		const tramos: { desde: number; hasta: number }[] = [];
		for (const unidad of ordenadas) {
			const ultimo = tramos.at(-1);
			if (ultimo && unidad.v_ini === ultimo.hasta + 1) {
				ultimo.hasta = unidad.v_fin;
				continue;
			}
			tramos.push({ desde: unidad.v_ini, hasta: unidad.v_fin });
		}
		return 'vv. ' + tramos.map((tramo) => `${tramo.desde}-${tramo.hasta}`).join(', ');
	}

	/** Cuántas unidades se apartan de lo común, sumando todas las preguntas compartidas. */
	const unidadesQueSeApartan = $derived.by(() => {
		const apartadas = new Set<string>();
		for (const pregunta of comunes) {
			const estado = comunState(pregunta);
			if (!estado.hayComun) continue;
			for (const { group, owner: unit } of pregunta.destinatarias) {
				if (firmaComun(group, unit) !== estado.mayoritaria) {
					apartadas.add(unit.realizacion_id);
				}
			}
		}
		return apartadas;
	});

	/** Cuántas unidades hay en total, para rotular el selector. */
	const totalDeUnidades = $derived.by(() =>
		comunes.reduce(
			(maximo: number, pregunta: PreguntaFormulario) =>
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
		comunes.some((pregunta: PreguntaFormulario) => {
			const estado = comunState(pregunta);
			return estado.answered > 0 && estado.uniform === null;
		})
	);

	/** Con algo que se aparta la lista se enseña sola: es donde se corrige. */
	const mostrarUnidades = $derived(verUnidades || hayDivergencia);

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
	 * **Si abajo no queda nada que tocar, lo que va ahí es la lectura de lo que se guarda.**
	 *
	 * Lo que impide compactar es **estructura por decidir**: una extensión editable, un ciclo que se
	 * añade o se quita, un patrón que se declara en la unidad. Eso hay que poder tocarlo, y una
	 * lectura en versos no lo sustituye.
	 *
	 * **Que una parte tenga preguntas ya no cuenta.** Contaba cuando las preguntas se respondían
	 * abajo; ahora se responden todas arriba, en la zona de respuestas, y el soneto era el caso que
	 * lo delataba: sus dos esquemas viven en «Cuartetos» y «Tercetos», así que la lista se negaba a
	 * compactar y enseñaba dos renglones de estructura —«2 realizaciones de 4 versos, fijas por la
	 * forma»— donde lo que hacía falta era leer el soneto entero en notación.
	 */
	const listaCompacta = $derived(
		rows.length > 0 &&
			unidadesRaiz.length > 0 &&
			rows.every((row: GridRow) => {
				if (row.kind === 'acciones' || row.kind === 'pregunta') return false;
				if (row.kind === 'fijas') return true;
				if (row.lengthEditable) return false;
				if (sectionDefinesPattern(row.section)) return false;
				return true;
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
		for (const pregunta of comunes) {
			for (const { group, owner: unit } of pregunta.destinatarias) {
				const groupId = String(group.grupo_eleccion_id);
				{
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
				}
			}
		}
		props.onChoicesChange(nextChoices);
		commitUnits(nextUnits);
		verUnidades = false;
		unidadesPlegadas = new Set();
		confirmarConjunto = false;
	}

	/**
	 * La secuencia entera en notación, cuando no hay ninguna pregunta que hacer.
	 *
	 * **Una composición fija no tenía nada que enseñar aquí**: la sextina decía «Sextina vv. 1–39»,
	 * que es lo que ya pone la cabecera, y el listado no añadía nada. Lo que falta ahí no es una
	 * pregunta sino la lectura que ninguna otra zona da: la norma y las respuestas hablan en
	 * vocabulario del catálogo —«Tipología 3», «base de 8 sílabas»—, y esto habla en versos, que es
	 * lo que el editor tiene delante en el libro. Es además donde se caza una respuesta equivocada.
	 *
	 * Solo cuando no hay preguntas: donde las hay, cada unidad ya escribe la suya.
	 */
	const sinNadaQuePreguntar = $derived(
		comunes.length === 0 &&
			rows.every((row: GridRow) => {
				if (row.kind === 'pregunta' || row.kind === 'acciones') return false;
				if (row.kind === 'fijas' || row.kind === 'realizacion') {
					return row.preguntas.length === 0;
				}
				return true;
			})
	);


	const notacionDeLaSecuencia = $derived.by(() => {
		if (!sinNadaQuePreguntar) return null;
		const raices = props.units
			.filter((unit: MetricUnitDraft) => !unit.realizacion_padre_id)
			.sort((primera: MetricUnitDraft, segunda: MetricUnitDraft) => primera.v_ini - segunda.v_ini);
		const trozos = raices
			.map((unit: MetricUnitDraft) => notacionDeLaUnidad(unit))
			.filter((trozo: string | null): trozo is string => Boolean(trozo));
		return trozos.length > 0 ? trozos.join(' | ') : null;
	});

	/**
	 * Si el listado no tiene nada que añadir a la cabecera.
	 *
	 * La sextina decía «Sextina vv. 1–39», que es exactamente lo que ya pone arriba. Y no es que le
	 * falte la notación: **no la tiene**, porque su rima es la repetición de seis palabras y no un
	 * esquema de letras. Un bloque que solo repite el rango no se pinta.
	 */
	const listadoSinNadaQueDecir = $derived(sinNadaQuePreguntar && !notacionDeLaSecuencia);

	function unidadAbierta(): boolean {
		return mostrarUnidades;
	}

	/**
	 * Al pasar a una a una se pliegan todas.
	 *
	 * Seis coplas desplegadas con sus dos preguntas cada una no caben en la pantalla, y lo normal
	 * es venir de una respuesta común y querer tocar una o dos.
	 */
	function alternarUnidades() {
		confirmarConjunto = false;
		if (!verUnidades) {
			verUnidades = true;
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
		verUnidades = false;
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
	/** Lo que una variedad afirma, tal como baja resuelto del catálogo. */
	type VariedadResuelta = {
		variedadId: string;
		notacion: string | null;
		medidas: (number | null)[];
	};

	/** Las variedades que una realización ha respondido, ya resueltas. */
	function variedadesElegidas(unit: MetricUnitDraft): VariedadResuelta[] {
		const elegidas: VariedadResuelta[] = [];
		for (const group of context.groups) {
			if (String(group.dimension) !== 'combinacion') continue;
			const groupId = String(group.grupo_eleccion_id);
			const ids = selectedChoiceIds(groupId, unit.realizacion_id);
			if (ids.length === 0) continue;
			for (const opcion of optionsForGroup(groupId)) {
				if (!ids.includes(String(opcion.opcion_eleccion_id))) continue;
				const variedad = ((props.varieties ?? []) as VariedadResuelta[]).find(
					(candidata: VariedadResuelta) => candidata.variedadId === String(opcion.variedad_id)
				);
				if (variedad) elegidas.push(variedad);
			}
		}
		return elegidas;
	}

	/** Las realizaciones que cuelgan de una unidad, ella incluida y en el orden en que se leen. */
	function ramaDeLaUnidad(unit: MetricUnitDraft): MetricUnitDraft[] {
		const rama: MetricUnitDraft[] = [unit];
		for (const candidata of props.units) {
			let padre = candidata.realizacion_padre_id;
			while (padre) {
				if (padre === unit.realizacion_id) {
					rama.push(candidata);
					break;
				}
				padre =
					props.units.find((otra: MetricUnitDraft) => otra.realizacion_id === padre)
						?.realizacion_padre_id ?? null;
			}
		}
		return rama.sort((primera, segunda) => primera.v_ini - segunda.v_ini);
	}

	/**
	 * Cuánto mide cada verso de una unidad: lo respondido, y lo que la norma fija donde no se pregunta.
	 *
	 * Vive aparte porque lo usan dos cosas que tienen que decir lo mismo: la anotación que se pinta
	 * —`8a 8b 4c`— y la **caja de las letras al guardar** un esquema escrito a mano, que es
	 * minúscula hasta ocho sílabas y mayúscula por encima. Si se separaran, el editor enseñaría
	 * `ABAB` y la base guardaría `abab`.
	 */
	function medidasDeLaUnidad(unit: MetricUnitDraft): {
		medidas: Map<number, number>;
		base: number | null;
	} {
		const medidas = new Map<number, number>();
		let base: number | null = null;
		for (const parte of ramaDeLaUnidad(unit)) {
			const desplazamiento = parte.v_ini - unit.v_ini;
			for (const group of context.groups) {
				if (group.dimension !== 'metro') continue;
				const alcanza = unitsForGroup(context, group).some(
					(candidata: MetricUnitDraft) => candidata.realizacion_id === parte.realizacion_id
				);
				if (!alcanza) continue;
				const groupId = String(group.grupo_eleccion_id);
				const elegidas = selectedChoiceIds(groupId, parte.realizacion_id);
				for (const opcion of optionsForGroup(groupId)) {
					// `Number(null)` es 0 y `Number.isFinite(0)` es cierto: sin esa condición, una
					// forma sin medida de base —las aliradas abiertas no la tienen— se anotaba
					// «0 0 0 0».
					const posible = Number(opcion.metro_base_silabas);
					if (Number.isFinite(posible) && posible > 0) base = posible;
					if (!elegidas.includes(String(opcion.opcion_eleccion_id))) continue;
					const posicion = Number(opcion.posicion_unidad);
					const silabas = Number(opcion.metro_silabas);
					if (Number.isFinite(posicion) && Number.isFinite(silabas)) {
						medidas.set(posicion + desplazamiento, silabas);
					}
				}
			}
		}
		// **La variedad dice las dos cosas.** Responderla es elegir a la vez una disposición de rima
		// y una serie de medidas; aquí se recoge la segunda.
		for (const parte of ramaDeLaUnidad(unit)) {
			const desplazamiento = parte.v_ini - unit.v_ini;
			for (const variedad of variedadesElegidas(parte)) {
				variedad.medidas.forEach((silabas: number | null, indice: number) => {
					if (silabas === null) return;
					const posicion = desplazamiento + indice + 1;
					if (!medidas.has(posicion)) medidas.set(posicion, silabas);
				});
			}
		}
		// Lo que la norma fija donde nadie responde. Lo respondido manda: esto solo cubre huecos.
		const versos = unit.v_fin - unit.v_ini + 1;
		const rejilla = props.rejilla;
		if (rejilla && !unit.realizacion_padre_id && rejilla.celdas.length === versos) {
			for (const celda of rejilla.celdas) {
				const fijada = Number(celda.medida?.silabas);
				if (!medidas.has(celda.verso) && Number.isFinite(fijada) && fijada > 0) {
					medidas.set(celda.verso, fijada);
				}
			}
		}
		return { medidas, base };
	}

	function notacionDeLaUnidad(unit: MetricUnitDraft): string | null {
		const versos = unit.v_fin - unit.v_ini + 1;
		if (versos <= 0) return null;

		const { medidas, base } = medidasDeLaUnidad(unit);
		const letras = new Map<number, string>();
		const cortes = new Set<number>();

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

				// La medida ya la trae `medidasDeLaUnidad`; aquí solo se reparte la rima.
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
		// **Y la rima que la variedad trae**, antes de caer en la norma: quien elige «A1 · aBaBcC»
		// ya ha dicho cómo rima, y el resumen se quedaba mudo.
		for (const parte of ramaDeLaUnidad(unit)) {
			const desplazamiento = parte.v_ini - unit.v_ini;
			for (const variedad of variedadesElegidas(parte)) {
				const seguidas = Array.from(String(variedad.notacion ?? '').replace(/\|/gu, ''));
				if (seguidas.length !== parte.v_fin - parte.v_ini + 1) continue;
				seguidas.forEach((signo: string, indice: number) => {
					const posicion = desplazamiento + indice + 1;
					if (letras.has(posicion)) return;
					letras.set(posicion, signo);
					if (signo !== '-') usadas.add(signo.toLocaleLowerCase('es'));
				});
			}
		}

		const rejilla = props.rejilla;
		if (rejilla && !unit.realizacion_padre_id && rejilla.celdas.length === versos) {
			// De todas las disposiciones que dibuja la arquitectura, la que da el esqueleto; y si no
			// lo declara, la que la norma fija o la corriente.
			const filas: FilaDeRima[] = rejilla.filasDeRima ?? [];
			const esqueleto =
				filas.find((fila: FilaDeRima) => fila.esquemaRimaId === rejilla.esqueletoDe) ??
				filas.find((fila: FilaDeRima) => fila.modalidad === 'definitoria') ??
				filas.find((fila: FilaDeRima) => fila.modalidad === 'habitual');
			if (esqueleto) {
				/**
				 * **El verso suelto también se anota, con su raya.**
				 *
				 * Se saltaban los que no riman, así que la seguidilla compuesta salía «a a b b» en
				 * vez de «- a - a b - b»: cuatro versos de siete escritos como si no existieran. La
				 * raya es lo que la notación convencional pone ahí, y es lo que trae el catálogo en
				 * `-a-ab-b`; el dato ya lo marca con `suelto`.
				 */
				esqueleto.clases.forEach(
					(clase: { clase: string | null; suelto?: boolean }, indice: number) => {
						const posicion = esqueleto.desde + indice;
						if (letras.has(posicion)) return;
						if (clase.clase) letras.set(posicion, clase.clase);
						else if (clase.suelto) letras.set(posicion, '-');
					}
				);
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

	/**
	 * Lo que la norma fija en cada verso de una unidad, para el campo de medidas.
	 *
	 * Sale de `medidasDeLaUnidad`, que es la misma fuente que la anotación y la caja de las letras.
	 * Se recorta al tramo del que trata la pregunta, porque una pregunta de sección habla de sus
	 * versos y no de los de la unidad entera.
	 */
	function medidasFijasDe(
		unit: MetricUnitDraft,
		desde: number,
		hasta: number
	): (number | null)[] {
		const { medidas, base } = medidasDeLaUnidad(unit);
		const serie: (number | null)[] = [];
		for (let posicion = desde; posicion <= hasta; posicion += 1) {
			serie.push(medidas.get(posicion) ?? base);
		}
		return serie;
	}

	/** Lo mismo para el atajo: en conjunto todas responden igual, así que basta con la primera. */
	function medidasFijasComunes(pregunta: PreguntaFormulario): (number | null)[] {
		const primera = pregunta.destinatarias.at(0)?.owner;
		if (!primera) return [];
		return medidasFijasDe(primera, 1, comunPositionLimit(pregunta) ?? primera.v_fin - primera.v_ini + 1);
	}

	/** Si a esta unidad le llega alguna de las preguntas que se responden en común. */
	function esUnidadComun(unit: MetricUnitDraft): boolean {
		return comunes.some((pregunta: PreguntaFormulario) =>
			pregunta.groups.some((group: MetricCatalogDomainRow) =>
				unitsForGroup(context, group).some(
					(candidate: MetricUnitDraft) => candidate.realizacion_id === unit.realizacion_id
				)
			)
		);
	}

	/** La familia a la que pertenece un grupo, si es de las que se responden en conjunto. */
	function familiaDe(group: MetricCatalogDomainRow): PreguntaFormulario | null {
		const groupId = String(group.grupo_eleccion_id);
		return (
			comunes.find((comun: PreguntaFormulario) =>
				comun.groups.some(
					(miembro: MetricCatalogDomainRow) =>
						String(miembro.grupo_eleccion_id) === groupId
				)
			) ?? null
		);
	}

	/** Responde en el acto en todas las unidades. Ya no hay que preparar nada y aplicarlo después. */
	function aplicarComun(
		pregunta: PreguntaFormulario,
		slugs: string[],
		soloEn: Set<string> | null = null
	) {
		const resultado = writeComunChoice(
			pregunta,
			slugs,
			[...props.choices],
			[...props.units],
			soloEn
		);
		props.onChoicesChange(resultado.choices);
		commitUnits(resultado.units);
	}

	/**
	 * Lo mismo, cuando la respuesta se escribe en vez de elegirse.
	 *
	 * Va por separado de `writeComunChoice` porque no hay slug que copiar: se copia la notación,
	 * ya normalizada, exactamente como la escribiría cada unidad por su cuenta.
	 */
	function aplicarComunTexto(
		pregunta: PreguntaFormulario,
		value: string,
		soloEn: Set<string> | null = null
	) {
		// En conjunto todas las unidades responden lo mismo, así que la caja se decide con la
		// primera: si midieran distinto, la pregunta no sería común.
		const primera = pregunta.destinatarias.at(0)?.owner;
		const esSerie = pregunta.groups.some(
			(group: MetricCatalogDomainRow) => String(group.tipo_control ?? '') === 'serie_medidas'
		);
		const normalized = esSerie
			? value.replace(/\s+/g, ' ').trimStart()
			: normalizeRhymeScheme(value, primera);
		let siguientes = [...props.choices];
		for (const { group, owner: unit } of pregunta.destinatarias) {
			const groupId = String(group.grupo_eleccion_id);
			{
				if (soloEn && !soloEn.has(unit.realizacion_id)) continue;
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

	/**
	 * **Las unidades a las que apunta una pregunta, numeradas y en orden de verso.**
	 *
	 * Una excepción se declara señalando unidades, así que hace falta poder nombrarlas: «3 ·
	 * vv. 11-15». El número es de la pregunta, no de la secuencia: una pregunta que solo alcanza
	 * a las mudanzas numera mudanzas.
	 */
	function unidadesDe(pregunta: PreguntaFormulario) {
		const filas: { unit: MetricUnitDraft; group: MetricCatalogDomainRow; firma: string }[] = [];
		for (const { group, owner: unit } of pregunta.destinatarias) {
			filas.push({ unit, group, firma: firmaComun(group, unit) });
		}
		filas.sort((primera, segunda) => primera.unit.v_ini - segunda.unit.v_ini);
		return filas.map((fila, indice) => ({ ...fila, numero: indice + 1 }));
	}

	/**
	 * **Las unidades que siguen la norma**: todas menos las que ya se apartan.
	 *
	 * Es lo que hace que «en todas» y «salvo» sean un solo mecanismo y no dos que se pisan. Sin
	 * esto, cambiar la respuesta general borraba las excepciones declaradas, que es exactamente lo
	 * que el editor acababa de decir que no eran.
	 */
	function siguenLaNorma(pregunta: PreguntaFormulario): Set<string> | null {
		const state = comunState(pregunta);
		if (!state.mayoritaria) return null;
		const ids = new Set<string>();
		for (const fila of unidadesDe(pregunta)) {
			if (fila.firma === state.mayoritaria || !fila.firma) ids.add(fila.unit.realizacion_id);
		}
		return ids;
	}

	/** Responder arriba escribe en las que siguen la norma, y deja en paz a las que se apartan. */
	function responderEnTodas(pregunta: PreguntaFormulario, slugs: string[]) {
		aplicarComun(pregunta, slugs, siguenLaNorma(pregunta));
	}

	function responderEnTodasTexto(pregunta: PreguntaFormulario, value: string) {
		aplicarComunTexto(pregunta, value, siguenLaNorma(pregunta));
	}

	/**
	 * La excepción que se está declarando: qué responde y en qué unidades.
	 *
	 * Se lleva aparte de las respuestas hasta que se acepta, porque hasta entonces no es una
	 * respuesta de nadie: media excepción escrita en la base son unidades respondiendo cosas que
	 * el editor no ha terminado de decir.
	 */
	let excepcionAbierta = $state<string | null>(null);
	let excepcionSlugs = $state<string[]>([]);
	let excepcionTexto = $state('');
	let excepcionUnidades = $state<string[]>([]);

	function abrirExcepcion(pregunta: PreguntaFormulario) {
		excepcionAbierta = pregunta.key;
		excepcionSlugs = [];
		excepcionTexto = '';
		excepcionUnidades = [];
	}

	function cancelarExcepcion() {
		excepcionAbierta = null;
		excepcionSlugs = [];
		excepcionTexto = '';
		excepcionUnidades = [];
	}

	function alternarUnidadDeExcepcion(realizacionId: string) {
		excepcionUnidades = excepcionUnidades.includes(realizacionId)
			? excepcionUnidades.filter((id) => id !== realizacionId)
			: [...excepcionUnidades, realizacionId];
	}

	/** Una excepción necesita las dos mitades: qué se responde y dónde. */
	const excepcionCompleta = $derived(
		excepcionUnidades.length > 0 && (excepcionSlugs.length > 0 || excepcionTexto.trim().length > 0)
	);

	function guardarExcepcion(pregunta: PreguntaFormulario) {
		const ids = new Set(excepcionUnidades);
		if (excepcionTexto.trim()) aplicarComunTexto(pregunta, excepcionTexto, ids);
		else aplicarComun(pregunta, excepcionSlugs, ids);
		cancelarExcepcion();
	}

	/**
	 * Quitar una excepción es devolver esas unidades a lo que responde la norma, no vaciarlas.
	 *
	 * Vaciarlas dejaría la pregunta sin responder en dos coplas de cincuenta, que no es lo que
	 * significa «quitar» aquí: significa que también responden lo de todas.
	 */
	function quitarExcepcion(pregunta: PreguntaFormulario, unidades: MetricUnitDraft[]) {
		const state = comunState(pregunta);
		if (!state.mayoritaria) return;
		const [slugs, escrito] = leerFirma(state.mayoritaria);
		const ids = new Set(unidades.map((unidad) => unidad.realizacion_id));
		if (escrito) aplicarComunTexto(pregunta, escrito, ids);
		else aplicarComun(pregunta, slugs, ids);
	}

	/**
	 * Si la pregunta se lee como un punto de partida en vez de como una respuesta de todas.
	 *
	 * Una licencia no se responde «en todas»: se parte de que ninguna unidad la lleva y se dice en
	 * cuáles aparece. Es la misma frontera que decide si la pregunta vive al pie o arriba, así que
	 * se pregunta una sola vez —antes esto miraba si el control era posicional, y con eso la medida
	 * de cada verso del pareado, que es obligatoria, se anunciaba como un punto de partida.
	 */
	function esDePartida(pregunta: PreguntaFormulario): boolean {
		return esLicencia(pregunta);
	}

	/**
	 * Las preguntas que hablan de una parte, para pintarlas dentro de ella.
	 *
	 * **Solo en la primera aparición.** En un villancico de tres ciclos la mudanza sale tres veces y
	 * su pregunta es una sola que responde a las tres —«en todas · 3 unidades»—, así que repetir el
	 * control en cada ciclo sería ofrecer tres veces la misma respuesta. Va en la primera y las demás
	 * mudanzas se leen como lo que son: el reparto del pasaje.
	 */
	function preguntasDeLaParte(row: GridRow, indice: number): PreguntaFormulario[] {
		if (!respondePorPartes) return [];
		if (row.kind === 'acciones') return [];
		const seccion = row.section ? String(row.section.seccion_id) : null;
		if (!seccion) return [];
		const primera = rows.findIndex(
			(candidata: GridRow) =>
				candidata.kind !== 'acciones' &&
				candidata.section != null &&
				String(candidata.section.seccion_id) === seccion
		);
		if (primera !== indice) return [];
		return preguntasVisibles.filter(
			(pregunta: PreguntaFormulario) => pregunta.seccionId === seccion
		);
	}

	/**
	 * Las preguntas que la fila pinta por su cuenta.
	 *
	 * **En las formas por ciclos, ninguna de las que ya se leen en su parte.** La fila las pintaba
	 * igual, así que la medida de la cabeza salía dos veces —una dentro de la fila y otra en el
	 * bloque de debajo— y la de la mudanza tres: la del ciclo 1, la del ciclo 2 y el «en todas».
	 *
	 * Se quedan las que el modelo no recoge, que hoy son las de una sección que declara patrón: esas
	 * las pinta el editor de patrón, aquí mismo.
	 */
	function preguntasEnLaFila(preguntas: PreguntaEnFila[]): PreguntaEnFila[] {
		if (!respondePorPartes) return preguntas;
		const subidas = new Set(
			preguntasVisibles.flatMap((pregunta: PreguntaFormulario) =>
				pregunta.groups.map((group: MetricCatalogDomainRow) => String(group.grupo_eleccion_id))
			)
		);
		return preguntas.filter(
			(pregunta: PreguntaEnFila) => !subidas.has(String(pregunta.group.grupo_eleccion_id))
		);
	}

	/** Y las que no hablan de ninguna parte, que siguen yendo en la lista. */
	const preguntasSueltas = $derived(
		respondePorPartes
			? preguntasVisibles.filter(
					(pregunta: PreguntaFormulario) =>
						!rows.some(
							(row: GridRow) =>
								row.kind !== 'acciones' &&
								row.section != null &&
								String(row.section.seccion_id) === pregunta.seccionId
						)
				)
			: preguntasVisibles
	);

	/** El campo de rima habla en identificadores de opción; la respuesta común viaja por slug. */
	function idsComunes(pregunta: PreguntaFormulario, slugs: string[]): string[] {
		const groupId = String(pregunta.groups[0]?.grupo_eleccion_id ?? '');
		return optionsForGroup(groupId)
			.filter((option: MetricCatalogDomainRow) => slugs.includes(String(option.slug)))
			.map((option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id));
	}

	/** Lo que hace falta para leer un esquema escrito: se toma de la primera unidad, que las representa. */
	function normaEsquemaComun(pregunta: PreguntaFormulario) {
		const group = pregunta.groups[0];
		if (!group) return undefined;
		const unit = pregunta.destinatarias[0]?.owner;
		return unit ? normaEsquemaDe(group, unit) : undefined;
	}

	/**
	 * Responde la pregunta en todas las realizaciones a las que se dirige, en todos los
	 * grupos que la formulan. La respuesta viaja por slug porque cada grupo tiene sus propias
	 * opciones apuntando al mismo dato.
	 */
	function writeComunChoice(
		pregunta: PreguntaFormulario,
		slugs: string[],
		baseChoices: MetricChoiceDraft[],
		baseUnits: MetricUnitDraft[],
		soloEn: Set<string> | null = null
	): { choices: MetricChoiceDraft[]; units: MetricUnitDraft[] } {
		let nextChoices = [...baseChoices];
		let nextUnits = [...baseUnits];
		for (const { group, owner: unit } of pregunta.destinatarias) {
			const groupId = String(group.grupo_eleccion_id);
			const optionIds = optionsForGroup(groupId)
				.filter((candidate: MetricCatalogDomainRow) => slugs.includes(String(candidate.slug)))
				.map((option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id));
			// La respuesta viaja por slug porque cada grupo de la familia tiene sus propias
			// opciones apuntando al mismo dato; donde ese slug no existe, no hay nada que escribir.
			if (slugs.length > 0 && optionIds.length === 0) continue;
			{
				if (soloEn && !soloEn.has(unit.realizacion_id)) continue;
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
		{#if comunes.length > 0 || props.preguntasDeSecuencia || respondePorPartes}
			<div class={hayAjustesDeComposicion ? 'border-t border-[color:var(--border)]' : ''}>
				<!--
					**Una sola manera de responder, y ninguna lista que abrir.**

					Aquí hubo un interruptor de dos modos —«en conjunto» y «una a una»—, y después un
					«ver las N unidades» que desplegaba una rejilla editable. Las dos cosas partían de que
					apartarse era trabajar de otra manera. No lo es: medido sobre el corpus, las
					secuencias de más de diez unidades son el 86 % de los versos y **nunca responden todas
					cosas distintas** —el máximo son cuatro respuestas en 43 unidades, siempre con una
					dominante—. Así que se responde una vez y se dice lo que se aparta, ahí mismo.
				-->
				<div
					class="border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2"
				>
					<p class="form-grid-title">Respuestas</p>
				</div>

				<!--
					**Primero cómo se reparte el pasaje, y después qué se responde de cada parte.**

					En el villancico, el zéjel y la canción, el reparto vivía abajo, en una zona aparte, y
					no era estructura contemplada: son decisiones del editor —cuántos versos lleva la
					cabeza, si el ciclo trae enlace y vuelta, cuántos ciclos hay, qué patrón declara la
					estancia modelo—. Y son **las que deciden cuántas preguntas hay arriba**: cuántas
					mudanzas que medir, cuántas repeticiones que calificar. Tomarlas después de
					contestarlas era leer la pantalla al revés.

					Solo en esas tres. El criterio no es una lista de nombres: es que la unidad no se
					deriva del rango y la forma declara secciones raíz, que es lo que significa crecer por
					ciclos.
				-->
				<!--
					**Lo que es del pasaje entero va antes que su reparto.**

					Se pintaba después, y en las formas por ciclos eso lo dejaba al final de la lista de
					partes, detrás del «+ Añadir» del último ciclo: al pulsar «+ vocales de la asonancia»
					la pregunta aparecía ahí abajo, entre la estructura, y desde el pie parecía que el
					botón se hubiera limitado a desaparecer.
				-->
				{#if props.preguntasDeSecuencia}
					<div class="space-y-4 border-b border-[color:var(--border)] px-3 py-3 last:border-b-0">
						{@render props.preguntasDeSecuencia()}
					</div>
				{/if}

				{#if respondePorPartes}
					<div class="border-b border-[color:var(--border)] px-3 py-3">
						<p class="mb-2 text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
							El pasaje se reparte así
						</p>
						{@render repartoOLectura(true)}
					</div>
				{/if}


				{#if confirmarConjunto}
					<div class="border-b border-amber-300 bg-amber-50 px-3 py-2.5">
						<p class="text-xs text-amber-950">
							Igualar todas deja una sola respuesta y borra lo que las unidades hayan respondido
							por su cuenta.
						</p>
						<div class="mt-2 flex flex-wrap gap-3">
							<button
								type="button"
								class="h-8 bg-[color:var(--primary)] px-3 text-xs font-medium text-white"
								onclick={volverAConjunto}
							>
								Borrar e igualar todas
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
				{/if}

				<!--
					**El bloque de la maqueta, no una fila de la rejilla.**

					Esto era una fila de dos columnas —rótulo a la izquierda, control a la derecha—, que
					es la disposición de siempre, y por eso responder no cambiaba la pantalla. La maqueta
					decidió otra cosa: cada pregunta es un bloque apilado que se lee en tres renglones
					—qué responde la secuencia, qué se aparta y en qué unidades— y esos tres renglones
					son el único sitio donde se anota. Se probó así sobre ocho casos medidos, del romance
					sin unidades al villancico por ciclos.
				-->
				<div>
					{#each preguntasSueltas as pregunta (pregunta.key)}
						{@render bloqueDePregunta(pregunta)}
					{/each}
				</div>

				<!--
					**Lo que la forma admite y nadie ha dicho que haya, al pie.**

					Cinco licencias puestas arriba se leen como cinco cosas que resolver y hacen creer
					que el trabajo es mayor de lo que es. Aquí abajo ocupan una línea, y suben con las
					demás en cuanto se dice que las hay: entonces ya no son una licencia sin usar sino
					un dato de esta realización.

					Cada una con su botón, porque un «sí» al final de una lista de tres no dice a cuál
					se le está diciendo que sí.
				-->
				{#if rasgosQueAdmite.length + (props.cuantasLicenciasDeSecuencia ?? 0) > 0}
					{@const cuantas = rasgosQueAdmite.length + (props.cuantasLicenciasDeSecuencia ?? 0)}
					<div
						class="flex flex-wrap items-center gap-2 border-t border-[color:var(--border)] px-3 py-2"
					>
						<span class="text-xs text-[color:var(--muted-foreground)]">
							{cuantas === 1
								? 'Esta forma admite además, si lo hay:'
								: 'Esta forma admite además, si los hay:'}
						</span>
						{@render props.licenciasDeSecuencia?.()}
						{#each rasgosQueAdmite as pregunta (pregunta.key)}
							<button
								type="button"
								class="border border-[color:var(--border)] bg-white px-2 py-1 text-xs hover:border-[color:var(--primary)]"
								onclick={() => (rasgosPedidos = [...rasgosPedidos, pregunta.key])}
							>
								+ {pregunta.rotulo.toLocaleLowerCase('es')}
							</button>
						{/each}
					</div>
				{/if}
			</div>
		{/if}
	</div>
	{/if}

	<!--
		Se llamaba «verso a verso» y no lo es cuando lo que se lista son unidades: en una copla
		castellana de dos coplas, lo que hay debajo son las dos coplas con sus partes, no dieciséis
		versos.
	-->
	<!--
		**Donde la forma crece por ciclos, esto vive dentro de las respuestas.**
		Ver el bloque de arriba: allí se explica por qué.
	-->
	{#if !listadoSinNadaQueDecir && !respondePorPartes}
		{@render repartoOLectura(false)}
	{/if}
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
			medidasFijas={medidasFijasDe(
				unit,
				positionStart ?? 1,
				positionEnd ?? unit.v_fin - unit.v_ini + 1
			)}
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


<!--
	**El reparto del pasaje y la lectura de lo que se guarda comparten sitio.**

	Son la misma zona en dos estados: donde todo se responde arriba, aquí se lee la secuencia en
	versos; donde la forma crece por ciclos, aquí se decide cómo se reparte. Está en un `snippet`
	porque en las formas por ciclos se pinta **dentro** de las respuestas y en las demás debajo, y
	tenerlo escrito dos veces sería garantía de que dejaran de parecerse.
-->
{#snippet repartoOLectura(dentro: boolean)}
<div
	class={dentro
		? ''
		: hayZonaComun
			? 'mt-6 border border-[color:var(--border)]'
			: 'border border-[color:var(--border)]'}
>
	<!-- Dentro de las respuestas el rótulo ya lo pone la zona: aquí sería decirlo dos veces. -->
	{#if rows.length > 0 && !dentro}
		<!--
			**El rótulo dice lo que hay debajo, y debajo no siempre hay lo mismo.**

			Donde la forma se lee entera en versos, esto es lo que va a quedar guardado. Donde crece
			por partes —villancico, zéjel, canción— aquí abajo ya no se responde nada: **las
			preguntas subieron todas a la zona de respuestas** y lo que queda es cómo se reparte el
			pasaje —cuántos versos lleva la cabeza, cuántos ciclos hay, dónde acaba cada estancia—.
			Se llamaba «la secuencia, parte por parte», que era su nombre cuando ahí se anotaba.
		-->
		<p class="form-grid-title border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2">
			{listaCompacta || notacionDeLaSecuencia
				? 'Qué se va a registrar'
				: 'Cómo se reparte el pasaje'}
		</p>
	{/if}

	<!--
		**Y si no se puede guardar, aquí no se enumera nada.**

		«Qué se va a registrar» es una promesa, y con el rango sin cuadrar era falsa dos veces: el
		guardado iba a fallar, y lo que enumeraba eran solo las unidades materializadas —una de
		doce versos en la quintilla— como si fueran la lectura entera.

		**Sin repetir el motivo**, que ya está dicho arriba en la cabecera y no se va de la
		pantalla. Aquí solo hace falta saber por qué está vacío esto.
	-->
	{#if props.rangoSinCuadrar && (listaCompacta || notacionDeLaSecuencia)}
		<p class="px-3 py-2.5 text-sm text-[color:var(--muted-foreground)]">
			Cuando el rango cuadre, aquí se lee lo que va a quedar guardado.
		</p>
	{/if}

	{#if props.rangoSinCuadrar && (listaCompacta || notacionDeLaSecuencia)}
		<!-- Nada: lo que hubiera aquí sería una lectura incompleta presentada como definitiva. -->
	{:else if notacionDeLaSecuencia}
		<p class="px-3 py-2.5 text-sm tabular-nums">{notacionDeLaSecuencia}</p>
	{:else if listaCompacta}
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
	{#each rows as row, indiceDeFila (row.key)}
		{#if !esParteIntegrada(row) && !filaOculta(row)}
		<!--
			**Lo que se pregunta de una parte se lee dentro de la parte.**

			En las formas por ciclos las preguntas iban en una lista aparte, debajo del reparto: la
			medida de la cabeza lejos de la cabeza y las dos de la mudanza lejos de la mudanza. Aquí
			cada una entra bajo la parte de la que habla —y bajo la que **trata**, no la que la aloja:
			la modalidad de la represa cuelga del ciclo y habla de la repetición del estribillo—.
		-->
		{@const suyas = preguntasDeLaParte(row, indiceDeFila)}
		{#if row.kind === 'pregunta'}
			<MetricGridRow label={row.label} depth={row.depth}>
				{@render camposDeLaParte(preguntasEnLaFila(row.preguntas))}
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
					{@render camposDeLaParte(preguntasEnLaFila(row.preguntas))}
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
						{@const restantes = preguntasEnLaFila(
							notacion
								? row.preguntas.filter(
										(pregunta: PreguntaEnFila) =>
											pregunta.group.dimension !== 'rima' &&
											pregunta.group.dimension !== 'metro'
									)
								: row.preguntas
						)}
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
					{@render camposDeLaParte(preguntasEnLaFila(otherQuestions), row.equivalentes)}
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
									{@render camposDeLaParte(preguntasEnLaFila(part.preguntas), row.equivalentes)}
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

				<!--
					«Patrón fijo por la arquitectura» solo cuando la parte **no pregunta nada**. Con la
					pregunta subida a su parte, la fila se quedaba sin controles y decía que la norma la
					fijaba entera, que es falso: la mudanza pregunta medida y rima, solo que se leen unas
					líneas más abajo.
				-->
				{#if row.preguntas.length === 0 && !row.lengthEditable}
					<span class="text-sm text-[color:var(--muted-foreground)]">
						{row.unit.v_fin - row.unit.v_ini + 1} versos · patrón fijo por la arquitectura
					</span>
				{:else if preguntasEnLaFila(row.preguntas).length > 0}
					{@render camposDeLaParte(preguntasEnLaFila(row.preguntas), row.equivalentes)}
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
		{#if suyas.length > 0}
			<div class="border-b border-[color:var(--border)] bg-[color:var(--muted)] pl-3 last:border-b-0">
				{#each suyas as pregunta (pregunta.key)}
					{@render bloqueDePregunta(pregunta, true)}
				{/each}
			</div>
		{/if}
		{/if}
	{/each}
	{/if}
</div>
{/snippet}


<!--
	El bloque de una pregunta. Vive en un `snippet` porque se pinta en dos sitios: en la lista de
	la zona de respuestas y, en las formas por ciclos, dentro de la parte de la que habla.
-->
{#snippet bloqueDePregunta(pregunta: PreguntaFormulario, dentroDeSuParte = false)}
	{@const state = comunState(pregunta)}
	{@const apartadas = state.hayComun ? excepcionesDe(pregunta, state.mayoritaria) : []}
	{@const dePartida = esDePartida(pregunta)}
	{@const porUnidades = pregunta.alcance === 'unidad'}
	<div class="space-y-1.5 border-b border-[color:var(--border)] px-3 py-3 last:border-b-0">
			<!-- Dentro de su parte, el nombre de la parte ya está encima: repetirlo sobra. -->
		<span class="block text-sm font-medium">
			{dentroDeSuParte ? pregunta.rotuloSinParte : pregunta.rotulo}
		</span>

		<!--
			Lo general. El rótulo del alcance va pegado al control para que no se lea como
			una respuesta más de las de abajo: dice de quién habla lo que se está eligiendo.
		-->
		<div class="flex flex-wrap items-center gap-2">
			<!--
				**Con una sola realización no hay «en todas».**

				«En todas» y el raíl de excepciones dicen que la respuesta vale para un
				conjunto del que algo puede apartarse. Una quintilla suelta no tiene conjunto:
				se responde y ya, como el romance. Es el caso que la maqueta no llegó a
				recoger —24 de las 134 secuencias con unidad— y el que hacía ver aquí la
				pantalla vieja.
			-->
			{#if porUnidades}
				<span
					class="shrink-0 text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]"
				>
					{dePartida ? 'De partida' : 'En todas'}
				</span>
			{/if}
			{#if pregunta.admiteEscrito}
				<div class="min-w-0 flex-1">
					<MetricChoiceField
						group={pregunta.groups[0]}
						variant="celda"
						sinRotulo
						label={pregunta.rotulo}
						options={comunOptions(pregunta)}
						normaEsquema={normaEsquemaComun(pregunta)}
						selectedIds={idsComunes(pregunta, state.generalSlugs)}
						onChange={(ids) => responderEnTodas(pregunta, ids.map(optionSlugOf))}
						textValue={state.generalTexto}
						onTextChange={(value) => responderEnTodasTexto(pregunta, value)}
					/>
				</div>
			{:else}
				<MetricFamilyControl
					group={pregunta.groups[0]}
					options={comunOptions(pregunta)}
					uniform={state.hayComun ? state.generalSlugs : state.uniform}
					answered={state.answered}
					realizaciones={state.total}
					ariaLabel={pregunta.rotulo}
					positionLimit={comunPositionLimit(pregunta)}
					medidasFijas={medidasFijasComunes(pregunta)}
					onChoose={(slugs) => responderEnTodas(pregunta, slugs)}
				/>
			{/if}
			{#if porUnidades}
				<span class="shrink-0 text-xs text-[color:var(--muted-foreground)]">
					· {state.total}
					{state.total === 1 ? 'unidad' : 'unidades'}
				</span>
			{/if}
			{#if pregunta.ayuda}
				<FieldHelpTooltip text={pregunta.ayuda} label={`Ayuda sobre «${pregunta.rotulo}»`} />
			{/if}
		</div>

		<!--
			Y lo que se aparta, con la misma forma siempre: cuántas, cuáles y dónde. El raíl
			está aunque no haya ninguna, porque es también donde se declara la primera: sin
			él, apartarse obligaba a bajar a una lista y abrir una unidad.
		-->
		{#if porUnidades}
		<div class="border-l-2 border-[color:var(--primary)] pl-3">
			{#if apartadas.length === 0}
				<p class="text-sm text-[color:var(--muted-foreground)]">
					{#if state.answered > 0 && !state.hayComun}
						Cada unidad responde una cosa distinta.
					{:else}
						Sin excepciones.
					{/if}
					{#if excepcionAbierta !== pregunta.key}
						<button
							type="button"
							class="link-action ml-1"
							onclick={() => abrirExcepcion(pregunta)}
						>
							Añadir una
						</button>
					{/if}
				</p>
			{:else}
				<p class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
					Salvo {state.excepciones} de {state.total}
				</p>
				{#each apartadas as grupo (grupo.firma)}
					<p class="text-sm leading-6">
						<span class="font-medium">{grupo.etiqueta}</span>
						<span class="text-[color:var(--muted-foreground)]">
							· {grupo.unidades.length}
							{grupo.unidades.length === 1 ? 'unidad' : 'unidades'} · {grupo.rangos}</span
						>
						<button
							type="button"
							class="link-action ml-1"
							onclick={() => quitarExcepcion(pregunta, grupo.unidades)}
						>
							quitar
						</button>
					</p>
				{/each}
				{#if excepcionAbierta !== pregunta.key}
					<button
						type="button"
						class="link-action text-sm"
						onclick={() => abrirExcepcion(pregunta)}
					>
						Añadir otra
					</button>
				{/if}
		{/if}
		</div>

		<!--
			**Declarar la excepción es decir dos cosas: qué responde y dónde.**

			Van juntas y no se guarda nada hasta que están las dos: media excepción escrita
			son unidades respondiendo algo que nadie ha terminado de decir.

			**Y va fuera del raíl**, no dentro. Metido ahí, un formulario con su recuadro, su
			control y una lista de casillas quedaba anidado tres niveles bajo la pregunta y
			empujaba las excepciones ya declaradas contra el margen. El raíl es para leer lo
			que se aparta; esto es para declararlo.
		-->
		{#if excepcionAbierta === pregunta.key}
			{@const filas = unidadesDe(pregunta)}
			<div class="border border-[color:var(--border)] bg-[color:var(--muted)] p-2.5">
				<div class="flex flex-wrap items-center gap-2">
					<span
						class="shrink-0 text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]"
					>
						Responden
					</span>
					{#if pregunta.admiteEscrito}
						<div class="min-w-0 flex-1">
							<MetricChoiceField
								group={pregunta.groups[0]}
								variant="celda"
								sinRotulo
								label={`Excepción de «${pregunta.rotulo}»`}
								options={comunOptions(pregunta)}
								normaEsquema={normaEsquemaComun(pregunta)}
								selectedIds={idsComunes(pregunta, excepcionSlugs)}
								onChange={(ids) => (excepcionSlugs = ids.map(optionSlugOf))}
								textValue={excepcionTexto}
								onTextChange={(value) => (excepcionTexto = value)}
							/>
						</div>
					{:else}
						<MetricFamilyControl
							group={pregunta.groups[0]}
							options={comunOptions(pregunta)}
							uniform={excepcionSlugs}
							answered={excepcionSlugs.length}
							realizaciones={1}
							ariaLabel={`Excepción de «${pregunta.rotulo}»`}
							positionLimit={comunPositionLimit(pregunta)}
							medidasFijas={medidasFijasComunes(pregunta)}
							onChoose={(slugs) => (excepcionSlugs = slugs)}
						/>
					{/if}
				</div>

				<!--
					**Las unidades, en fichas.**

					Eran una lista de casillas con su número y su rango, una fila cada una: en la
					quintilla de *El mágico prodigioso* son cincuenta y dos filas dentro de una
					caja con su propio desplazamiento, para señalar siete. En fichas caben en
					dos renglones y se ven de un vistazo las que ya están marcadas. El rango
					sigue estando, en el título de cada ficha, que es donde hace falta: se
					consulta al dudar de una, no al recorrerlas.
				-->
				<div class="mt-2 flex flex-wrap items-center gap-2">
					<span
						class="shrink-0 text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]"
					>
						En
					</span>
					<div class="flex flex-wrap gap-1">
						{#each filas as fila (fila.unit.realizacion_id)}
							{@const marcada = excepcionUnidades.includes(fila.unit.realizacion_id)}
							<button
								type="button"
								class={`min-h-7 min-w-8 border px-1.5 text-xs tabular-nums ${
									marcada
										? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-white'
										: 'border-[color:var(--border)] bg-white hover:border-[color:var(--primary)]'
								}`}
								aria-pressed={marcada}
								title={`Unidad ${fila.numero} · vv. ${fila.unit.v_ini}–${fila.unit.v_fin}`}
								onclick={() => alternarUnidadDeExcepcion(fila.unit.realizacion_id)}
							>
								{fila.numero}
							</button>
						{/each}
					</div>
				</div>

				<div class="mt-2.5 flex flex-wrap items-center gap-3">
					<button
						type="button"
						class="h-8 bg-[color:var(--primary)] px-3 text-xs font-medium text-white disabled:opacity-40"
						disabled={!excepcionCompleta}
						onclick={() => guardarExcepcion(pregunta)}
					>
						Añadir la excepción
					</button>
					<button type="button" class="link-action text-xs" onclick={cancelarExcepcion}>
						Cancelar
					</button>
					{#if excepcionUnidades.length > 0}
						<span class="text-xs text-[color:var(--muted-foreground)]">
							{excepcionUnidades.length}
							{excepcionUnidades.length === 1 ? 'unidad' : 'unidades'} · {rangosDeUnidades(
								filas
									.filter((fila) => excepcionUnidades.includes(fila.unit.realizacion_id))
									.map((fila) => fila.unit)
							)}
						</span>
					{/if}
				</div>
			</div>
		{/if}
		{/if}
	</div>
{/snippet}
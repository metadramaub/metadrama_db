<script lang="ts">
	import { untrack } from 'svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import SegmentedChoice from '$lib/components/ui/segmented-choice.svelte';
	import type {
		MetricCatalogConfiguration,
		MetricCatalogDomainRow,
		MetricCatalogForEditor,
		MetricCatalogForm,
		MetricCatalogOption,
		MetricLengthRule
	} from '$lib/metrica/catalogo';
	import { metricFormLabel } from '$lib/metrica/catalogo';
	import {
		metricLengthCycles,
		metricLengthError,
		metricLengthNoun
	} from '$lib/metrica/metric-length';
	import {
		contradiceLaRelacion,
		fijarValorObservado,
		medidaDeLaNorma,
		medidaDominante,
		notaDelMetroObservado,
		opcionesObservadas,
		valorObservado
	} from './desviaciones';
	import MetricChoiceField from './MetricChoiceField.svelte';
	import MetricGridRow from './MetricGridRow.svelte';
	import MetricNormSummary from './MetricNormSummary.svelte';
	import MetricPanelSection from './MetricPanelSection.svelte';
	import MetricStructureEditor from './MetricStructureEditor.svelte';
	import { metricNormFacts, metricNormGrid } from './norm-summary';
	import { compactRhymeNotation } from './rhyme-notation';
	import { stripMarkdown } from '$lib/utils/markdown';
	import { metricStructureCoverage } from './structure-coverage';
	import {
		childrenOfSection,
		hayUnidadConArquitecturaPropia,
		partesDeLaRealizacion,
		metricUnitPlan,
		reflowMetricUnits,
		sectionId as structuredSectionId,
		sectionLabel as structuredSectionLabel,
		sectionMaximum,
		sectionMinimum,
		sectionVerseMaximum,
		sectionVerseMinimum,
		syncRepeatedMetricUnits,
		type MetricChoiceDraft,
		type MetricUnitDraft
	} from './editor-model';
	import { seRespondeDentroDeLaUnidad } from '$lib/metrica/alcance';
	import { targetUnitsForGroup } from './grid-rows';
	import {
		catalogParts,
		defaultRelationFor,
		emptyDeviation,
		metricDeviationRelations,
		applyProposedUnitAnswers,
		normalizeStructuredUnits,
		seccionesIntercalables,
		unitPlanFor,
		METRIC_DEVIATION_DIMENSIONS,
		type MetricDeviationDimension,
		type MetricDeviationDraft,
		type MetricSequenceDraft,
		type MetricSequenceEditorState
	} from './sequence-draft';

	/**
	 * El formulario de una secuencia métrica. No sabe dónde vive: no conoce escenarios de
	 * prueba, ni la tabla que lo abre, ni la API que lo guarda. Recibe el catálogo y un
	 * borrador, y devuelve hacia arriba su estado —resumen, progreso y el motivo por el que
	 * todavía no se puede guardar— para que lo pinte la cabecera del contenedor.
	 */
	const props = $props<{
		catalog: MetricCatalogForEditor;
		/** Borrador de partida. El editor se queda con él; el contenedor lo recibe de vuelta
		 *  por `onStateChange`. Para editar otra secuencia, remontar con `{#key}`. */
		initialDraft: MetricSequenceDraft;
		onStateChange?: (state: MetricSequenceEditorState) => void;
		/**
		 * El resto del formulario de la secuencia, que no es métrico: caracterizaciones por
		 * rango, intervención de personajes, sinopsis. Se pinta a continuación de lo métrico,
		 * en la misma columna, porque el editor las rellena en la misma pasada.
		 */
		bodyExtra?: import('svelte').Snippet;
		/**
		 * Sus entradas en el mapa, para que el raíl cubra el formulario entero. Cada una es
		 * un destino con su propio título, no un punto de la lista de lo métrico.
		 */
		/**
		 * Las demás secciones del modal, para que el raíl sea el índice de todas y no solo de la
		 * métrica. `alAbrir` las despliega antes de bajar hasta ellas: llevar a una sección plegada
		 * es llevar a un título.
		 */
		extraRailItems?: {
			id: string;
			label: string;
			/** Lo que se dice al lado del nombre: «3 de 6», «sin escribir», «2». */
			detalle?: string;
			pendiente?: boolean;
			alAbrir?: () => void;
		}[];
		/**
		 * Si la sección métrica está desplegada. La gobierna quien monta el modal, porque es una
		 * sección entre varias y solo la primera viene abierta.
		 */
		seccionAbierta?: boolean;
		alAlternarSeccion?: () => void;
		/** Contenido suelto al final del raíl. */
		railExtra?: import('svelte').Snippet;
		/**
		 * Respuestas de ámbito unidad que llegan ya deducidas —el esquema de los tercetos de un
		 * soneto, la tipología de un sexteto-lira—. No pueden venir dentro de `initialDraft`
		 * porque en ese momento las unidades no existen todavía: las materializa este editor al
		 * conocer la arquitectura. Se aplican en cuanto existen.
		 */
		initialUnitAnswers?: { grupo_eleccion_id: string; opcion_eleccion_id: string }[];
	}>();

	// El borrador es del editor, no del contenedor: así ningún componente de fuera muta un
	// estado que no le pertenece y el mismo formulario sirve en cualquier pantalla. Al
	// abrirlo, las realizaciones se ponen al día con lo que declara la arquitectura, de modo
	// que quien lo invoca solo tiene que traer las filas tal como están guardadas.
	let draft = $state<MetricSequenceDraft>(
		untrack(() => {
			const initial = structuredClone(
				$state.snapshot(props.initialDraft)
			) as MetricSequenceDraft;
			if (!initial.arquitectura_id) return initial;
			initial.unidades = normalizeStructuredUnits(
				props.catalog,
				initial.unidades,
				initial.elecciones,
				initial.arquitectura_id,
				initial.v_ini,
				initial.v_fin
			);
			const parts = catalogParts(props.catalog, initial.arquitectura_id);

			// Ya hay unidades: se pueden colgar de ellas las respuestas que llegan deducidas.
			initial.elecciones = applyProposedUnitAnswers(
				initial.unidades,
				initial.elecciones,
				parts.groups,
				props.initialUnitAnswers ?? []
			);

			return initial;
		})
	);

	/** El editor ha vuelto a abrir la identificación ya resuelta para corregirla. */
	let identificationForced = $state(false);
	/** Las desviaciones son una sección secundaria: al añadir una se abre, pero puede plegarse. */
	let desviacionesAbiertas = $state(false);

	const configurationsForDraft = $derived(
		props.catalog.configurations.filter(
			(configuration: MetricCatalogConfiguration) =>
				configuration.forma_id === draft.forma_id && configuration.activo
		)
	);
	const selectedForm = $derived(
		props.catalog.forms.find((form: MetricCatalogForm) => form.forma_id === draft.forma_id) ?? null
	);
	const selectedConfiguration = $derived(
		props.catalog.configurations.find(
			(configuration: MetricCatalogConfiguration) =>
				configuration.arquitectura_id === draft.arquitectura_id
		) ?? null
	);
	const isEditorialOutput = $derived(selectedForm?.tipo_registro === 'sin_forma');
	const isIsolatedVerse = $derived(selectedForm?.slug === 'verso_aislado');
	const selectedLengthRule = $derived(
		props.catalog.lengthRules.find(
			(rule: MetricLengthRule) => rule.arquitectura_id === draft.arquitectura_id
		) ?? null
	);
	const activeForms = $derived(
		props.catalog.forms
			.filter((form: MetricCatalogForm) => form.activo)
			.sort((a: MetricCatalogForm, b: MetricCatalogForm) => a.nombre.localeCompare(b.nombre, 'es'))
	);
	const metricForms = $derived(
		activeForms.filter((form: MetricCatalogForm) => form.tipo_registro === 'forma')
	);
	const editorialOutputs = $derived(
		activeForms.filter((form: MetricCatalogForm) => form.tipo_registro === 'sin_forma')
	);

	const sectionsForDraft = $derived(
		props.catalog.domain.sections
			.filter((row: MetricCatalogDomainRow) => row.arquitectura_id === draft.arquitectura_id)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.orden ?? 999) - Number(b.orden ?? 999)
			)
	);
	/**
	 * Las preguntas de la arquitectura, **heredadas incluidas**.
	 *
	 * Ya no hay que inventarse ninguna: `preguntas_metricas` las trae, y una parte que reutiliza
	 * otra arquitectura recibe su repertorio de rima con el nombre de la parte delante, igual que
	 * si estuviera declarada. La regla vive **una vez**, en el catálogo, así que el editor, la
	 * ficha y el demarcador no pueden volver a separarse.
	 */
	const choiceGroupsForDraft = $derived(
		props.catalog.domain.choiceGroups
			.filter(
				(row: MetricCatalogDomainRow) =>
					row.arquitectura_id === draft.arquitectura_id && row.activo
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.orden ?? 999) - Number(b.orden ?? 999)
			)
	);
	const sequenceChoiceGroups = $derived(
		choiceGroupsForDraft.filter((row: MetricCatalogDomainRow) => row.alcance === 'secuencia')
	);
	const unitChoiceGroups = $derived(
		choiceGroupsForDraft.filter((row: MetricCatalogDomainRow) =>
			seRespondeDentroDeLaUnidad(row.alcance)
		)
	);
	/**
	 * Los regímenes de rima entre los que hay que elegir al escribir un esquema.
	 *
	 * **Solo cuando varían dentro de la arquitectura.** El § 3.3 dice que el régimen se declara
	 * arriba cuando es uno —el soneto es consonante y se acabó— y abajo, en cada disposición, cuando
	 * varía. Donde está arriba se hereda y no se pregunta; donde varía, un esquema escrito no está
	 * completo sin él, porque la octava aguda tiene `---a---a` consonante y `---a---a` asonante y la
	 * notación sola no dice cuál se ha leído.
	 *
	 * Se devuelve vacío también cuando abajo hay uno solo: no hay entre qué elegir.
	 */
	const rhymeRegimes = $derived.by(() => {
		const arquitectura = props.catalog.domain.configurations?.find(
			(row: MetricCatalogDomainRow) =>
				String(row.arquitectura_id) === String(draft.arquitectura_id)
		);
		if (!draft.arquitectura_id || arquitectura?.tipo_rima_id) return [];
		// Leía `domain.vocabularies`, que **no existe**: no está entre los recursos del dominio ni
		// lo rellena nadie. Así que esta lista salía siempre vacía y el régimen de un esquema
		// escrito no se ha podido preguntar nunca, en las doce arquitecturas que admiten más de uno.
		const terminos = new Map<string, string>();
		for (const esquema of props.catalog.domain.rhymePatterns) {
			if (String(esquema.arquitectura_id) !== String(draft.arquitectura_id)) continue;
			if (!esquema.tipo_rima_id) continue;
			const termino = props.catalog.rhymeTypes?.find(
				(row: MetricCatalogOption) => String(row.id) === String(esquema.tipo_rima_id)
			);
			if (!termino) continue;
			if (termino.slug) terminos.set(termino.slug, termino.label || termino.slug);
		}
		return terminos.size > 1
			? [...terminos].map(([slug, etiqueta]) => ({ slug, etiqueta }))
			: [];
	});

	/**
	 * Las arquitecturas de la forma que el catálogo declara **intercalables**.
	 *
	 * Una arquitectura intercalable aparece entre realizaciones de otra de su misma forma sin que el
	 * pasaje deje de ser esa forma: la décima aumentada entre décimas normales, que alarga su miembro
	 * final de cuatro versos a seis y que Morley y Bruerton documentan así. **No es una desviación**,
	 * y por eso no se registra como tal: la norma admite la estrofa larga.
	 *
	 * Se excluye la de la propia secuencia —una unidad no es excepción de sí misma— y sale vacío en
	 * todas las formas menos una, que es donde el editor no ve nada de esto.
	 */
	const interleavedArchitectures = $derived(
		!draft.forma_id
			? []
			: props.catalog.configurations
					.filter(
						(configuration: MetricCatalogConfiguration) =>
							configuration.forma_id === draft.forma_id &&
							configuration.activo &&
							configuration.intercalable &&
							configuration.arquitectura_id !== draft.arquitectura_id
					)
					.map((configuration: MetricCatalogConfiguration) => ({
						arquitectura_id: String(configuration.arquitectura_id),
						nombre: String(configuration.nombre),
						descripcion: configuration.descripcion
					}))
	);

	/** Las secciones de esas arquitecturas, para que la unidad marcada se dibuje por las suyas. */
	const interleavedSections = $derived(
		draft.arquitectura_id ? seccionesIntercalables(props.catalog, draft.arquitectura_id) : []
	);

	/**
	 * Marcar o desmarcar una unidad como la excepción.
	 *
	 * Solo se toca esa unidad. Que el pasaje deje de dividirse en unidades iguales lo deduce el plan
	 * —`metricUnitPlan` apaga `countFromRange` en cuanto hay una excepción—, y la longitud deja de
	 * exigir la congruencia por el mismo motivo.
	 */
	function setUnitArchitecture(unit: MetricUnitDraft, arquitecturaId: string | null) {
		const marcadas = draft.unidades.map((row: MetricUnitDraft) =>
			row.realizacion_id === unit.realizacion_id
				? { ...row, arquitectura_id: arquitecturaId }
				: row
		);
		// **Marcar la excepción rehace la estructura de esa unidad.** La espinela tiene tres
		// secciones y la aumentada dos: las viejas se van y entran las nuevas. Lo hace la misma
		// función que normaliza al elegir arquitectura, para que no haya dos maneras de construir
		// lo mismo. Y de paso apaga la derivación desde el rango, porque una tirada con una
		// aumentada ya no mide un múltiplo de diez.
		draft.unidades = normalizeStructuredUnits(
			props.catalog,
			marcadas,
			draft.elecciones,
			draft.arquitectura_id,
			draft.v_ini,
			draft.v_fin
		);
	}

	const dominantMetreSyllables = $derived.by(() => {
		if (!draft.arquitectura_id) return null;
		const patternIds = new Set(
			props.catalog.domain.metricPatterns
				.filter(
					(pattern: MetricCatalogDomainRow) =>
						pattern.arquitectura_id === draft.arquitectura_id
				)
				.map((pattern: MetricCatalogDomainRow) => String(pattern.esquema_metrico_id))
		);
		const metreIds = new Set(
			props.catalog.domain.metricOptions
				.filter(
					(option: MetricCatalogDomainRow) =>
						patternIds.has(String(option.esquema_metrico_id)) && option.rol === 'dominante'
				)
				.map((option: MetricCatalogDomainRow) => String(option.metro_id))
		);
		const syllables = [
			...new Set(
				props.catalog.domain.verseModels
					.filter((metre: MetricCatalogDomainRow) => metreIds.has(String(metre.metro_id)))
					.map((metre: MetricCatalogDomainRow) => Number(metre.silabas))
					.filter((value: number) => Number.isFinite(value) && value > 0)
			)
		];
		return syllables.length === 1 ? syllables[0] : null;
	});
	const choiceOptionsForDraft = $derived(
		props.catalog.domain.choiceOptions.filter(
			(row: MetricCatalogDomainRow) =>
				row.activo &&
				choiceGroupsForDraft.some(
					(group: MetricCatalogDomainRow) => group.grupo_eleccion_id === row.grupo_eleccion_id
				)
		).map((row: MetricCatalogDomainRow) => {
			const metre = props.catalog.domain.verseModels.find(
				(candidate: MetricCatalogDomainRow) => candidate.metro_id === row.metro_id
			);
			return {
				...row,
				metro_silabas: metre?.silabas ?? null,
				metro_base_silabas: dominantMetreSyllables
			};
		})
	);
	/**
	 * Lo que cada variedad afirma, ya resuelto: su rima y lo que mide cada verso.
	 *
	 * Una variedad **reúne un esquema de rima y uno métrico** —el sexteto-lira tiene ocho, que
	 * combinan tres disposiciones con seis medidas—, y el resumen de la secuencia solo sabía leer
	 * preguntas de metro y de rima: elegir una variedad no cambiaba nada de lo que se veía. Se
	 * resuelve aquí, que es donde vive el catálogo entero, y baja masticado.
	 */
	const varietiesForDraft = $derived.by(() => {
		if (!draft.arquitectura_id) return [];
		return props.catalog.domain.patternCombinations
			.filter(
				(row: MetricCatalogDomainRow) =>
					String(row.arquitectura_id) === String(draft.arquitectura_id)
			)
			.map((row: MetricCatalogDomainRow) => {
				const rima = props.catalog.domain.rhymePatterns.find(
					(candidate: MetricCatalogDomainRow) =>
						String(candidate.esquema_rima_id) === String(row.esquema_rima_id)
				);
				const posiciones = props.catalog.domain.metricPositions
					.filter(
						(candidate: MetricCatalogDomainRow) =>
							String(candidate.esquema_metrico_id) === String(row.esquema_metrico_id)
					)
					.sort(
						(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
							Number(a.posicion ?? 0) - Number(b.posicion ?? 0)
					);
				return {
					variedadId: String(row.variedad_id),
					notacion: rima?.notacion ? String(rima.notacion) : null,
					medidas: posiciones.map((posicion: MetricCatalogDomainRow) => {
						const metre = props.catalog.domain.verseModels.find(
							(candidate: MetricCatalogDomainRow) =>
								String(candidate.metro_id) === String(posicion.metro_id)
						);
						const silabas = Number(metre?.silabas);
						return Number.isFinite(silabas) && silabas > 0 ? silabas : null;
					})
				};
			});
	});
	const unitPlanForDraft = $derived(
		metricUnitPlan(selectedConfiguration, sectionsForDraft, selectedForm?.nivel_estructural)
	);
	const hasDerivedUnitCount = $derived(unitPlanForDraft?.countFromRange ?? false);
	const hasStructuredEditor = $derived(
		Boolean(unitPlanForDraft) &&
			(unitChoiceGroups.length > 0 || sectionsForDraft.length > 0 || !hasDerivedUnitCount)
	);
	const normFacts = $derived(
		draft.arquitectura_id
			? metricNormFacts({
					architectureId: draft.arquitectura_id,
					domain: props.catalog.domain,
					unitPlan: unitPlanForDraft,
					lengthRule: selectedLengthRule,
					rhymeTypes: props.catalog.rhymeTypes
				})
			: []
	);
	const normGrid = $derived(
		draft.arquitectura_id
			? metricNormGrid({
					architectureId: draft.arquitectura_id,
					domain: props.catalog.domain,
					rhymeTypes: props.catalog.rhymeTypes
				})
			: null
	);
	const hasSequenceChoices = $derived(sequenceChoiceGroups.length > 0);

	/**
	 * Los rasgos que la forma admite y que nadie ha dicho que haya.
	 *
	 * **Un rasgo opcional sin responder no es una pregunta pendiente**: es una licencia que casi
	 * nunca se usa. Puestos arriba, cinco de ellos —el endecasílabo suelto tiene cinco— se leen como
	 * cinco cosas que hay que resolver, y hacen creer que el trabajo es mayor de lo que es. Bajan al
	 * pie, en una línea, y suben en cuanto se dice que los hay.
	 *
	 * Lo que se ha dicho que hay se queda arriba, con los demás: ya no es una licencia sin usar sino
	 * un dato de esta realización.
	 */
	let rasgosPedidos = $state<string[]>([]);
	const rasgoSinTocar = (group: MetricCatalogDomainRow) => {
		const groupId = String(group.grupo_eleccion_id);
		if (Number(group.selecciones_min ?? 0) >= 1) return false;
		if (rasgosPedidos.includes(groupId)) return false;
		return (
			selectedChoiceIds(groupId, null).length === 0 && !choiceTextValue(groupId, null).trim()
		);
	};
	const preguntasDeSecuencia = $derived(
		sequenceChoiceGroups.filter((group: MetricCatalogDomainRow) => !rasgoSinTocar(group))
	);
	const rasgosQueAdmite = $derived(
		sequenceChoiceGroups.filter((group: MetricCatalogDomainRow) => rasgoSinTocar(group))
	);
	const materializedUnitCount = $derived(
		unitPlanForDraft
			? draft.unidades.filter(
					(unit: MetricUnitDraft) =>
						unit.realizacion_padre_id === null && unit.seccion_id === null
				).length
			: 0
	);
	/**
	 * Cuántas veces cabe en el pasaje lo que la arquitectura repite.
	 *
	 * Una serie no estrófica no materializa unidades, pero **sí sabemos cuántas veces se repite lo
	 * que la dibuja**: la endecha real pide ciclos completos de cuatro versos, así que en veintiocho
	 * caben siete. El dato ya existía y solo se usaba para el aviso de cuando el rango *no* cuadra;
	 * decirlo también cuando cuadra es la mitad que faltaba.
	 */
	const reparticionDelPasaje = $derived(
		metricLengthCycles(
			selectedLengthRule,
			draft.v_ini,
			draft.v_fin,
			hayUnidadConArquitecturaPropia(draft.unidades)
		)
	);
	/**
	 * Cómo se llama lo contado. Sale del `origen` de la regla, que es donde el catálogo ya lo dice:
	 * la lira cuenta **unidades** y el romance, **ciclos de rima**. Llamarlo «ciclos» a todo hacía
	 * que la cabecera y el cuerpo de la misma pantalla nombraran distinto una misma cosa.
	 */
	/**
	 * De qué son los versos que sobran, cuando la arquitectura declara un cierre opcional.
	 *
	 * El terceto encadenado mide `3n` o `3n+4`, y esos cuatro versos son su serventesio final. Las
	 * dos congruencias son **excluyentes** —`3n ≡ 0` y `3n+4 ≡ 1` en módulo 3—, así que **el rango
	 * ya decide si el cierre está**: en cuarenta versos la única lectura posible lo lleva, y en
	 * treinta y nueve no cabe. Por eso no se pregunta; lo que faltaba era decir su nombre en vez de
	 * «y 4 versos más», que obliga a adivinar qué son.
	 */
	const nombreDeLosSobrantes = $derived.by(() => {
		const sobrantes = reparticionDelPasaje?.sobrantes ?? 0;
		if (sobrantes <= 0) return null;
		const cierre = sectionsForDraft.find(
			(row: MetricCatalogDomainRow) =>
				Number(row.repeticiones_min ?? 1) === 0 &&
				Number(row.repeticiones_max ?? 1) === 1 &&
				Number(row.versos_min) === sobrantes &&
				Number(row.versos_max) === sobrantes
		);
		return cierre?.nombre ? String(cierre.nombre) : null;
	});
	const nombreDeLaReparticion = $derived(
		reparticionDelPasaje ? metricLengthNoun(reparticionDelPasaje.origen) : null
	);

	const structureCoverage = $derived(
		metricStructureCoverage(draft.v_ini, draft.v_fin, draft.unidades)
	);

	// Algunas arquitecturas no cíclicas pueden compartir la medida de varias secciones. Las
	// composiciones variables se excluyen: mezclar composición, sección y ciclo en una zona
	// común confundía más de lo que ahorraba, y se responden directamente por partes.
	const measureGroups = $derived(
		unitChoiceGroups.filter(
			(group: MetricCatalogDomainRow) =>
				group.dimension === 'metro' && Boolean(group.seccion_id)
		)
	);
	const measureMetres = $derived.by(() => {
		const byMetre = new Map<string, string>();
		for (const group of measureGroups) {
			for (const option of optionsForGroup(String(group.grupo_eleccion_id))) {
				if (option.metro_id) byMetre.set(String(option.metro_id), String(option.nombre));
			}
		}
		return [...byMetre].map(([id, label]) => ({ id, label }));
	});
	const measureAnswers = $derived.by(() => {
		const metres = new Set<string>();
		let answered = 0;
		let total = 0;
		for (const group of measureGroups) {
			const groupId = String(group.grupo_eleccion_id);
			const options = optionsForGroup(groupId);
			for (const unit of unitsForGroup(group)) {
				total += 1;
				const selected = selectedChoiceIds(groupId, unit.realizacion_id);
				if (selected.length === 0) continue;
				answered += 1;
				for (const optionId of selected) {
					const option = options.find(
						(candidate: MetricCatalogDomainRow) =>
							String(candidate.opcion_eleccion_id) === optionId
					);
					if (option?.metro_id) metres.add(String(option.metro_id));
				}
			}
		}
		return { total, answered, metres: [...metres] };
	});
	const uniformMetreId = $derived(
		measureAnswers.total > 0 &&
			measureAnswers.answered === measureAnswers.total &&
			measureAnswers.metres.length === 1
			? measureAnswers.metres[0]
			: null
	);
	const hasCompositionMeasure = $derived(
		measureGroups.length >= 2 &&
			!Boolean(
				unitPlanForDraft &&
					!unitPlanForDraft.countFromRange &&
					sectionsForDraft.length > 0
			)
	);

	// Un tramo sin forma también elige arquitectura, así que la identificación se resuelve igual
	// para todo: forma y arquitectura.
	const identificationResolved = $derived(
		Boolean(draft.forma_id) && Boolean(draft.arquitectura_id)
	);
	const identificationOpen = $derived(!identificationResolved || identificationForced);
	/** Sin quien la gobierne desde fuera, la sección métrica está siempre abierta. */
	const seccionMetricaAbierta = $derived(props.seccionAbierta !== false);

	/**
	 * La identificación se lee en dos alturas: la forma, que es el dato que el editor
	 * busca de un vistazo, y el resto —arquitectura y unidades— en segundo plano. El rango
	 * no está aquí: vive en la cabecera, junto al título de la secuencia.
	 */
	const identificationForm = $derived(draft.forma_id ? formLabel(draft.forma_id) : '');
	const identificationDetails = $derived.by(() => {
		const parts: string[] = [];
		if (draft.arquitectura_id && configurationsForDraft.length > 1) {
			parts.push(configurationLabel(draft.arquitectura_id));
		}
		if (materializedUnitCount > 1 && unitPlanForDraft?.extent && hasDerivedUnitCount) {
			parts.push(`${materializedUnitCount} unidades de ${unitPlanForDraft.extent.minimum} versos`);
		} else if (materializedUnitCount > 1) {
			parts.push(`${materializedUnitCount} unidades`);
		}
		return parts.join(' · ');
	});
	const identificationSummary = $derived(
		[identificationForm, identificationDetails].filter(Boolean).join(' · ')
	);

	const summary = $derived.by(() => {
		const parts: string[] = [];
		if (draft.forma_id) parts.push(formLabel(draft.forma_id));
		if (draft.arquitectura_id && configurationsForDraft.length > 1) {
			parts.push(configurationLabel(draft.arquitectura_id));
		}
		const verses = draft.v_fin - draft.v_ini + 1;
		parts.push(`vv. ${draft.v_ini}–${draft.v_fin}`);
		parts.push(`${verses} ${verses === 1 ? 'verso' : 'versos'}`);
		if (materializedUnitCount > 1) parts.push(`${materializedUnitCount} unidades`);
		return parts.join(' · ');
	});

	function formLabel(id: string): string {
		return (
			props.catalog.forms.find((form: MetricCatalogForm) => form.forma_id === id)?.nombre ?? id
		);
	}

	function configurationLabel(id: string): string {
		return (
			props.catalog.configurations.find(
				(configuration: MetricCatalogConfiguration) => configuration.arquitectura_id === id
			)?.nombre ?? id
		);
	}

	function optionsForGroup(groupId: string): MetricCatalogDomainRow[] {
		return props.catalog.domain.choiceOptions
			.filter(
				(row: MetricCatalogDomainRow) =>
					String(row.grupo_eleccion_id) === groupId && row.activo
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.orden ?? 999) - Number(b.orden ?? 999)
			);
	}

	function selectedChoiceIds(groupId: string, unitId: string | null): string[] {
		return draft.elecciones
			.filter(
				(choice: MetricChoiceDraft) =>
					choice.grupo_eleccion_id === groupId &&
					choice.realizacion_id === unitId &&
					Boolean(choice.opcion_eleccion_id)
			)
			.map((choice: MetricChoiceDraft) => choice.opcion_eleccion_id as string);
	}

	function choiceTextValue(groupId: string, unitId: string | null): string {
		return (
			draft.elecciones.find(
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

	function setChoices(groupId: string, unitId: string | null, optionIds: string[]) {
		draft.elecciones = [
			...draft.elecciones.filter(
				(choice: MetricChoiceDraft) =>
					!(choice.grupo_eleccion_id === groupId && choice.realizacion_id === unitId)
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

	function setChoiceText(groupId: string, unitId: string | null, value: string) {
		// Una serie de medidas se escribe con espacios y con números: la normalización de la rima
		// le quitaría precisamente lo que la separa en versos.
		const esSerie = sequenceChoiceGroups.some(
			(group: MetricCatalogDomainRow) =>
				String(group.grupo_eleccion_id) === groupId &&
				String(group.tipo_control ?? '') === 'serie_medidas'
		);
		const normalized = esSerie
			? value.replace(/\s+/g, ' ').trimStart()
			: normalizeRhymeScheme(value);
		draft.elecciones = [
			...draft.elecciones.filter(
				(choice: MetricChoiceDraft) =>
					!(choice.grupo_eleccion_id === groupId && choice.realizacion_id === unitId)
			),
			...(normalized
				? [
						{
							realizacion_id: unitId,
							grupo_eleccion_id: groupId,
							opcion_eleccion_id: null,
							valor_texto: normalized,
							observaciones: null
						}
					]
				: [])
		];
	}

	function choiceCount(groupId: string, unitId: string | null): number {
		return draft.elecciones.filter(
			(choice: MetricChoiceDraft) =>
				choice.grupo_eleccion_id === groupId && choice.realizacion_id === unitId
		).length;
	}

	/** Las realizaciones a las que se dirige una pregunta por unidad. */
	function unitsForGroup(group: MetricCatalogDomainRow): MetricUnitDraft[] {
		return targetUnitsForGroup(draft.unidades, group, choiceOptionsForDraft);
	}

	/** Responde de una vez la medida de todas las secciones con versos. */
	function applyMetreToAllSections(metreId: string) {
		if (!metreId) return;
		let next = [...draft.elecciones];
		for (const group of measureGroups) {
			const groupId = String(group.grupo_eleccion_id);
			const options = optionsForGroup(groupId).filter(
				(option: MetricCatalogDomainRow) => String(option.metro_id) === metreId
			);
			if (options.length === 0) continue;
			const positional = options.every(
				(option: MetricCatalogDomainRow) => Number(option.posicion_unidad ?? 0) > 0
			);
			for (const unit of unitsForGroup(group)) {
				const unitLength = unit.v_fin - unit.v_ini + 1;
				const chosen = positional
					? options.filter(
							(option: MetricCatalogDomainRow) =>
								Number(option.posicion_unidad) <= unitLength
						)
					: options.slice(0, Math.max(1, Number(group.selecciones_max ?? 1)));
				next = [
					...next.filter(
						(choice: MetricChoiceDraft) =>
							!(
								choice.grupo_eleccion_id === groupId &&
								choice.realizacion_id === unit.realizacion_id
							)
					),
					...chosen.map((option: MetricCatalogDomainRow) => ({
						realizacion_id: unit.realizacion_id,
						grupo_eleccion_id: groupId,
						opcion_eleccion_id: String(option.opcion_eleccion_id),
						valor_texto: null,
						observaciones: null
					}))
				];
			}
		}
		draft.elecciones = next;
	}

	/**
	 * Al elegir arquitectura, el rango se estira hasta lo que la estructura ocupa. **F65.**
	 *
	 * Las formas que crecen por ciclos materializan su ciclo mínimo en cuanto se las elige, y el
	 * rango recién creado —dos versos— no les llegaba: el villancico y el zéjel se abrían con un
	 * aviso en rojo, «la estructura ocupa 13 versos y el rango declara 2», antes de que el editor
	 * tocara nada. Un error de partida no dice nada de lo que se está anotando y enseña a no leer
	 * los avisos.
	 *
	 * **Solo al elegir, y solo hacia arriba.** No es sincronizar el rango con la estructura, que es
	 * justo lo que no se hace —«ajusta las unidades o revisa el verso final; el rango no cambiará
	 * automáticamente»—: es que el rango de una secuencia recién abierta todavía no dice nada, y
	 * ponerlo donde la forma lo deja es lo que haría el editor a mano un segundo después.
	 */
	function resetForConfiguration(configurationId: string) {
		draft.arquitectura_id = configurationId;
		draft.unidades = normalizeStructuredUnits(
			props.catalog,
			[],
			[],
			configurationId,
			draft.v_ini,
			draft.v_fin
		);
		const ultimo = draft.unidades.reduce(
			(mayor: number, unit: MetricUnitDraft) => Math.max(mayor, unit.v_fin),
			draft.v_ini - 1
		);
		if (ultimo > draft.v_fin) draft.v_fin = ultimo;
		draft.elecciones = [];
		draft.desviaciones = [];
	}

	function changeForm(formId: string) {
		draft.forma_id = formId;
		identificationForced = true;
		const form = props.catalog.forms.find((item: MetricCatalogForm) => item.forma_id === formId);
		// Un tramo acota su rango —un verso el aislado, dos lo menos el irregular— y a partir de
		// ahí se comporta como cualquier otra entrada: elige arquitectura y responde lo suyo.
		if (form?.tipo_registro === 'sin_forma') {
			if (form.slug === 'verso_aislado') {
				draft.v_fin = draft.v_ini;
			} else if (form.slug === 'irregular' && draft.v_fin === draft.v_ini) {
				draft.v_fin = draft.v_ini + 1;
			}
		}
		const configurations = props.catalog.configurations.filter(
			(configuration: MetricCatalogConfiguration) =>
				configuration.forma_id === formId && configuration.activo
		);
		const principalConfiguration = configurations.find(
			(configuration: MetricCatalogConfiguration) => configuration.principal
		);
		resetForConfiguration(
			principalConfiguration?.arquitectura_id ??
				(configurations.length === 1 ? configurations[0].arquitectura_id : '')
		);
	}

	/**
	 * El rango de una desviación, acotado al de la secuencia y coherente consigo mismo.
	 *
	 * Se corrige mientras se escribe en vez de avisar después: una desviación fuera del pasaje que
	 * describe no es un dato que haya que discutir, es un dedo.
	 */
	function fijarRangoDeDesviacion(
		deviation: MetricDeviationDraft,
		campo: 'v_ini' | 'v_fin',
		valor: number
	) {
		const dentro = Math.min(Math.max(Number.isFinite(valor) ? valor : draft.v_ini, draft.v_ini), draft.v_fin);
		if (campo === 'v_ini') {
			deviation.v_ini = dentro;
			if (deviation.v_fin < dentro) deviation.v_fin = dentro;
			return;
		}
		deviation.v_fin = Math.max(dentro, deviation.v_ini);
	}

	function addDeviation() {
		draft.desviaciones = [...draft.desviaciones, emptyDeviation(draft.v_ini, draft.v_fin)];
		desviacionesAbiertas = true;
	}

	// El valor observado de una desviación vive en `desviaciones.ts`: son funciones puras y
	// merecen prueba. Aquí quedan solo los envoltorios que las atan al borrador vivo.

	const normSyllables = $derived(medidaDeLaNorma(props.catalog.domain, draft.arquitectura_id));

	function observedOptions(dimension: MetricDeviationDimension | '') {
		return opcionesObservadas(
			props.catalog.domain,
			dimension,
			draft.arquitectura_id,
			sectionsForDraft,
			medidaDominante(props.catalog.domain, draft.arquitectura_id)
		);
	}

	const observedValue = valorObservado;

	function setObserved(deviation: MetricDeviationDraft, value: string) {
		fijarValorObservado(deviation, value);
	}

	function observedMetreNote(deviation: MetricDeviationDraft): string {
		return notaDelMetroObservado(props.catalog.domain, deviation, normSyllables);
	}

	function observedContradiction(deviation: MetricDeviationDraft): boolean {
		return contradiceLaRelacion(props.catalog.domain, deviation, normSyllables);
	}

	/**
	 * **Mover el principio mueve el final, siempre.** La secuencia conserva su longitud y se
	 * desplaza entera.
	 *
	 * Antes esto solo pasaba cuando la forma deriva sus unidades del rango; en las demás el final se
	 * quedaba quieto y podía acabar **detrás** del principio. Con un rango imposible la pantalla
	 * seguía calculando: en una forma de trece versos, 116–112 anunciaba que «la estructura rebasa el
	 * rango en 39 versos». El error existía, pero solo al pulsar Guardar, cuando llevaba un rato
	 * mintiendo.
	 */
	function updateSequenceStart(value: number) {
		const previousLength = draft.v_fin - draft.v_ini + 1;
		draft.v_ini = Math.max(1, value);
		if (isIsolatedVerse) {
			draft.v_fin = draft.v_ini;
			return;
		}
		draft.v_fin = draft.v_ini + previousLength - 1;
		if (hasDerivedUnitCount) {
			const { sections, options } = catalogParts(props.catalog, draft.arquitectura_id);
			const synchronized = syncRepeatedMetricUnits(
				draft.unidades,
				sections,
				unitPlanForDraft?.extent ?? null,
				draft.v_ini,
				draft.v_fin,
				draft.elecciones,
				options
			);
			if (synchronized.compatible) {
				removeStructuredReferences(synchronized.removedUnitIds);
				draft.unidades = synchronized.units;
			}
			return;
		}
		if (!hasStructuredEditor) return;
		draft.unidades = reflowMetricUnits(
			draft.unidades,
			sectionsForDraft,
			draft.v_ini,
			draft.elecciones,
			choiceOptionsForDraft
		);
	}

	/**
	 * El final no puede quedar antes que el principio. El navegador ya lo rechaza con `min`, pero un
	 * `input` admite que le escriban cualquier cosa: aquí se acota de verdad.
	 */
	function updateSequenceEnd(value: number) {
		if (isIsolatedVerse) {
			draft.v_fin = draft.v_ini;
			return;
		}
		draft.v_fin = Math.max(draft.v_ini, value);
		if (!hasDerivedUnitCount) return;
		const { sections, options } = catalogParts(props.catalog, draft.arquitectura_id);
		const synchronized = syncRepeatedMetricUnits(
			draft.unidades,
			sections,
			unitPlanForDraft?.extent ?? null,
			draft.v_ini,
			draft.v_fin,
			draft.elecciones,
			options
		);
		if (!synchronized.compatible) return;
		removeStructuredReferences(synchronized.removedUnitIds);
		draft.unidades = synchronized.units;
	}

	function removeStructuredReferences(unitIds: string[]) {
		if (unitIds.length === 0) return;
		const removed = new Set(unitIds);
		draft.elecciones = draft.elecciones.filter(
			(choice: MetricChoiceDraft) =>
				!choice.realizacion_id || !removed.has(choice.realizacion_id)
		);
		draft.desviaciones = draft.desviaciones.map((deviation: MetricDeviationDraft) =>
			deviation.realizacion_id && removed.has(deviation.realizacion_id)
				? { ...deviation, realizacion_id: null }
				: deviation
		);
	}

	/**
	 * Cuántas preguntas obligatorias hay y cuántas están contestadas. Sirve para que la
	 * cabecera diga lo que falta antes de que el editor pulse Guardar y se lleve el aviso.
	 */
	const questionProgress = $derived.by(() => {
		let total = 0;
		let answered = 0;
		if (!draft.arquitectura_id) return { total, answered };
		for (const group of sequenceChoiceGroups) {
			if (Number(group.selecciones_min) < 1) continue;
			total += 1;
			if (choiceCount(String(group.grupo_eleccion_id), null) >= Number(group.selecciones_min)) {
				answered += 1;
			}
		}
		/**
		 * **Se cuentan preguntas, no realizaciones.**
		 *
		 * Contaba un pendiente por cada unidad a la que alcanza la pregunta, y con eso una tirada de
		 * cincuenta y dos quintillas decía «0 de 52» para una sola pregunta que se contesta de una
		 * vez. El número asustaba y además describía una manera de trabajar que ya no existe: se
		 * responde arriba, en todas, y lo que se aparta se declara aparte.
		 *
		 * Una pregunta está hecha cuando **no queda ninguna realización suya sin responder**, así que
		 * las excepciones no añaden pendientes: son otra respuesta, no una respuesta menos.
		 */
		for (const group of unitChoiceGroups) {
			if (Number(group.selecciones_min) < 1) continue;
			const destinatarias = unitsForGroup(group);
			if (destinatarias.length === 0) continue;
			total += 1;
			const todasRespondidas = destinatarias.every(
				(unit: MetricUnitDraft) =>
					choiceCount(String(group.grupo_eleccion_id), unit.realizacion_id) >=
					Number(group.selecciones_min)
			);
			if (todasRespondidas) answered += 1;
		}
		return { total, answered };
	});

	/**
	 * Lo que está mal en el rango, que es lo único que se dice mientras se anota.
	 *
	 * Las dos comprobaciones que miran el par de campos de arriba: si el número de versos cabe en la
	 * forma y si la estructura materializada cubre lo declarado. `validateDraft` las incluye —y
	 * unas cuantas más— para decidir si se puede guardar; esto es solo esa mitad.
	 */
	function errorDeRango(): string | null {
		if (!draft.forma_id || !draft.arquitectura_id) return null;
		if (draft.v_fin < draft.v_ini) return 'El verso final no puede ser anterior al inicial.';
		const lengthError = metricLengthError(
			selectedLengthRule,
			draft.v_ini,
			draft.v_fin,
			selectedConfiguration?.nombre,
			selectedForm?.nombre,
			hayUnidadConArquitecturaPropia(draft.unidades)
		);
		if (lengthError) return lengthError;
		if (hasStructuredEditor && structureCoverage.state !== 'complete') {
			const difference = Math.abs(structureCoverage.difference);
			const ocupa = `La estructura ocupa ${structureCoverage.coveredVerses} ${structureCoverage.coveredVerses === 1 ? 'verso' : 'versos'} y el rango declara ${structureCoverage.declaredVerses}`;
			return structureCoverage.state === 'missing'
				? `${ocupa}: ${difference === 1 ? 'falta 1 verso' : `faltan ${difference} versos`} por asignar.`
				: `${ocupa}: ${difference === 1 ? 'sobra 1' : `sobran ${difference}`}.`;
		}
		return null;
	}

	function validateDraft(): string | null {
		if (!draft.forma_id) {
			return 'Selecciona una forma o una salida editorial.';
		}
		if (!draft.arquitectura_id) {
			return 'Selecciona la arquitectura de la forma.';
		}
		if (selectedForm?.slug === 'irregular' && draft.v_fin - draft.v_ini + 1 < 2) {
			return 'Versificación irregular debe abarcar al menos dos versos.';
		}
		if (isIsolatedVerse && draft.v_fin !== draft.v_ini) {
			return 'Verso aislado debe abarcar exactamente un verso.';
		}
		if (draft.v_fin < draft.v_ini) return 'El verso final no puede ser anterior al inicial.';
		// Con una arquitectura intercalada, el pasaje no se divide en unidades iguales y la
		// congruencia deja de valer: gobierna la cobertura del rango. Ver `metric-length.ts`.
		const lengthError = metricLengthError(
			selectedLengthRule,
			draft.v_ini,
			draft.v_fin,
			selectedConfiguration?.nombre,
			selectedForm?.nombre,
			hayUnidadConArquitecturaPropia(draft.unidades)
		);
		if (lengthError) return lengthError;
		// El mismo recuento que pinta el recuadro de la cobertura, y dicho igual: los dos números con
		// su nombre. Uno solo no basta —«rebasa el rango en 37 versos» no dice cuánto ocupa ni cuánto
		// se declaró— y el editor llega aquí buscando cuál de los dos corregir.
		if (hasStructuredEditor && structureCoverage.state !== 'complete') {
			const difference = Math.abs(structureCoverage.difference);
			const ocupa = `La estructura ocupa ${structureCoverage.coveredVerses} ${structureCoverage.coveredVerses === 1 ? 'verso' : 'versos'} y el rango declara ${structureCoverage.declaredVerses}`;
			return structureCoverage.state === 'missing'
				? `${ocupa}: ${difference === 1 ? 'falta 1 verso' : `faltan ${difference} versos`} por asignar.`
				: `${ocupa}: ${difference === 1 ? 'sobra 1' : `sobran ${difference}`}.`;
		}
		for (const unit of draft.unidades) {
			if (unit.v_fin < unit.v_ini || unit.v_ini < draft.v_ini || unit.v_fin > draft.v_fin) {
				return `La unidad ${unit.orden} queda fuera del rango de la secuencia.`;
			}
			const unitLength = unit.v_fin - unit.v_ini + 1;
			// La sección puede ser de una arquitectura intercalada: los dos bloques de la aumentada
			// tienen extensión propia y hay que comprobarla igual que la de cualquier otra.
			const section = [...sectionsForDraft, ...interleavedSections].find(
				(row: MetricCatalogDomainRow) => structuredSectionId(row) === unit.seccion_id
			);
			if (section) {
				const maximum = sectionVerseMaximum(section);
				if (
					unitLength < sectionVerseMinimum(section) ||
					(maximum !== null && unitLength > maximum)
				) {
					return `Revisa el número de versos de «${structuredSectionLabel(section)}».`;
				}
			} else if (
				unit.seccion_id === null &&
				// **Una unidad que declara su propia arquitectura no mide lo que mide la de la
				// secuencia.** La aumentada son doce versos donde la espinela exige diez, y exigirle
				// los diez impedía guardar lo que la norma admite. Sus partes sí se comprueban, cada
				// una contra la suya, en la rama de arriba.
				!unit.arquitectura_id &&
				unitPlanForDraft?.extent
			) {
				const { minimum, maximum } = unitPlanForDraft.extent;
				if (unitLength < minimum || unitLength > maximum) {
					return `La unidad ${unit.orden} debe tener entre ${minimum} y ${maximum} versos.`;
				}
			}
		}
		// Cada sección se cuenta dentro de la realización que la contiene: las raíces dentro
		// de su unidad, las internas dentro de su sección superior.
		if (hasStructuredEditor) {
			for (const parent of draft.unidades) {
				for (const child of partesDeLaRealizacion(
					sectionsForDraft,
					parent,
					interleavedSections
				)) {
					const childTotal = draft.unidades.filter(
						(unit: MetricUnitDraft) =>
							unit.realizacion_padre_id === parent.realizacion_id &&
							unit.seccion_id === structuredSectionId(child)
					).length;
					const childMaximum = sectionMaximum(child);
					if (
						childTotal < sectionMinimum(child) ||
						(childMaximum !== null && childTotal > childMaximum)
					) {
						const contenedor = parent.seccion_id
							? `«${structuredSectionLabel(
									sectionsForDraft.find(
										(row: MetricCatalogDomainRow) =>
											structuredSectionId(row) === parent.seccion_id
									) as MetricCatalogDomainRow
								)}»`
							: `la unidad ${parent.orden}`;
						return `Revisa «${structuredSectionLabel(child)}» en ${contenedor}.`;
					}
				}
			}
		}
		// Las desviaciones no se miraban en ninguna línea, ni su rango ni que cayera dentro de la
		// secuencia. Lo paraba la base, y el editor se comía un error crudo.
		for (const [indice, deviation] of draft.desviaciones.entries()) {
			/**
			 * **Una desviación que no dice nada no es una desviación.**
			 *
			 * Comprobado contra la base: `dimensión` y `relación` bastan para que la fila entre, así
			 * que se podía pulsar «Registrar una desviación», no tocar nada y guardar una fila que no
			 * registra nada. Por eso hay que decir de qué habla y qué le pasa; la descripción añade
			 * contexto y se recomienda, pero no impide guardar.
			 */
			const numero = draft.desviaciones.length > 1 ? ` ${indice + 1}` : '';
			if (!deviation.dimension) {
				return `Di de qué habla la desviación${numero}: metro, rima, estructura, repetición o rasgo.`;
			}
			if (!deviation.relacion_norma) {
				return `Di qué le pasa a ${METRIC_DEVIATION_DIMENSIONS.find(
					(option) => option.value === deviation.dimension
				)?.label.toLocaleLowerCase('es')} en la desviación${numero}.`;
			}
			if (deviation.v_fin < deviation.v_ini) {
				return 'Una desviación no puede terminar antes de donde empieza.';
			}
			if (deviation.v_ini < draft.v_ini || deviation.v_fin > draft.v_fin) {
				return `Las desviaciones deben quedar dentro del rango de la secuencia (${draft.v_ini}–${draft.v_fin}).`;
			}
		}

		for (const group of sequenceChoiceGroups) {
			const total = choiceCount(String(group.grupo_eleccion_id), null);
			if (total < Number(group.selecciones_min) || total > Number(group.selecciones_max)) {
				return `Revisa la pregunta «${String(group.nombre)}».`;
			}
		}
		for (const group of unitChoiceGroups) {
			// Una pregunta sin sección se refiere a la unidad entera, no a una parte suya.
			const applicableUnits = draft.unidades.filter((unit: MetricUnitDraft) =>
				group.seccion_id
					? String(group.seccion_id) === unit.seccion_id
					: unit.realizacion_padre_id === null
			);
			for (const unit of applicableUnits) {
				const total = choiceCount(
					String(group.grupo_eleccion_id),
					unit.realizacion_id
				);
				if (total < Number(group.selecciones_min) || total > Number(group.selecciones_max)) {
					const unanswered = applicableUnits.every(
						(candidate: MetricUnitDraft) =>
							choiceCount(
								String(group.grupo_eleccion_id),
								candidate.realizacion_id
							) === 0
					);
					if (group.permite_aplicar_global && unanswered) {
						return applicableUnits.length > 1
							? `Responde «${String(group.nombre)}» y aplícala a todas las unidades.`
							: `Revisa la pregunta «${String(group.nombre)}».`;
					}
					return `Revisa la pregunta «${String(group.nombre)}».`;
				}
			}
		}
		return null;
	}

	// La cabecera del contenedor necesita el borrador vivo, el resumen, el progreso y el
	// motivo por el que todavía no se puede guardar.
	$effect(() => {
		props.onStateChange?.({
			draft,
			summary,
			answered: questionProgress.answered,
			total: questionProgress.total,
			error: validateDraft(),
			errorDeRango: errorDeRango()
		});
	});

	/** Lleva la vista a un bloque del cuerpo desde el raíl. */
	function goTo(anchor: string) {
		if (anchor === 'desviaciones') desviacionesAbiertas = true;
		document
			.getElementById(anchor)
			?.scrollIntoView({ behavior: 'smooth', block: 'start' });
	}

	/**
	 * El mapa de la secuencia: los destinos que hay en el cuerpo, con lo que falta en cada uno.
	 *
	 * **Informa, no limita.** Ninguna de estas cosas impide guardar —lo normal es anotar por
	 * tandas— y por eso el estado se dice aquí, en el mapa, y no en el aviso rojo de la cabecera,
	 * que se reserva para lo que de verdad está mal: el rango.
	 *
	 * Los rótulos son los que la pantalla lleva escritos. Antes decía «Datos de esta realización» y
	 * «Estructura», que eran secciones de cuando las preguntas se repartían en dos sitios.
	 */
	const railItems = $derived.by(() => {
		// La clave es el rótulo y no el destino: «Respuestas» y «Qué se va a registrar» llevan a la
		// misma sección, y dos entradas con la misma clave rompen el `{#each}`.
		const items: { id: string; label: string; detalle: string; state: 'done' | 'pending' }[] = [];
		if (hasStructuredEditor || hasSequenceChoices) {
			const total = questionProgress.total;
			items.push({
				id: hasStructuredEditor ? 'estructura' : 'secuencia',
				label: 'Respuestas',
				detalle: total === 0 ? 'nada que responder' : `${questionProgress.answered} de ${total}`,
				state: total > 0 && questionProgress.answered < total ? 'pending' : 'done'
			});
		}
		if (hasStructuredEditor) {
			items.push({
				id: 'estructura',
				label: 'Qué se va a registrar',
				detalle: '',
				state: 'done'
			});
		}
		// Lo que ya está en pantalla entra en el mapa, aunque se haya añadido a mano.
		if (draft.desviaciones.length > 0) {
			items.push({
				id: 'desviaciones',
				label: 'Desviaciones',
				detalle: String(draft.desviaciones.length),
				state: 'done'
			});
		}
		return items;
	});
</script>

<div class="grid min-h-0 lg:grid-cols-[15rem_minmax(0,1fr)]">
	<!--
		Raíl: el mapa de la secuencia. Dice dónde estás y qué falta, no pide datos.

		**La banda llega hasta abajo.** Con `h-fit` y `self-start` el fondo gris terminaba donde
		acababa el texto del menú, a un tercio de la altura, y lo que quedaba debajo era una franja
		blanca del ancho de la columna: no se leía como un lateral sino como un recuadro suelto
		arriba a la izquierda. Ahora la columna se estira y lo que se queda quieto al desplazarse es
		el contenido, dentro.
	-->
	<aside
		class="border-b border-[color:var(--border)] bg-[color:var(--muted)] lg:border-b-0 lg:border-r"
	>
		<div class="p-4 lg:sticky lg:top-0">
		<button
			type="button"
			class="form-section-title mb-2 block w-full text-left hover:text-[color:var(--foreground)]"
			onclick={() => {
				if (props.seccionAbierta === false) props.alAlternarSeccion?.();
				goTo('identificacion');
			}}
		>
			Identificación métrica
		</button>
		<!--
			**La forma va por debajo de su título, no por encima.**

			Se pintaba en `text-base` y el rótulo de la sección en el tamaño pequeño de las cabeceras
			del raíl, así que «Quintilla» era lo más grande de la columna y «Identificación métrica»
			parecía su antetítulo. Es al revés: la sección manda y la forma es lo que hay dentro.

			Y lo que hay dentro va **sangrado y con una guía a la izquierda**, para que se vea de un
			vistazo que «Respuestas» y «Qué se va a registrar» pertenecen a esta sección y no son
			hermanas de «Caracterizaciones».
		-->
		<div class="mt-1 border-l border-[color:var(--border)] pl-3">
			{#if identificationForm}
				<p class="text-sm font-medium leading-snug text-[color:var(--foreground)]">
					{identificationForm}
				</p>
				{#if identificationDetails}
					<p class="mt-0.5 text-xs leading-snug text-[color:var(--muted-foreground)]">
						{identificationDetails}
					</p>
				{/if}
			{:else}
				<p class="text-sm text-[color:var(--muted-foreground)]">Sin forma elegida.</p>
			{/if}

			{#if railItems.length > 0}
			<ul class="mt-2 space-y-1">
				{#each railItems as item (item.label)}
					<li>
						<button
							type="button"
							class="flex w-full items-baseline gap-2 py-0.5 text-left text-sm hover:text-[color:var(--foreground)]"
							onclick={() => goTo(item.id)}
						>
							<span
								class={`mt-1 h-1.5 w-1.5 shrink-0 ${
									item.state === 'pending'
										? 'bg-[color:var(--primary)]'
										: 'bg-[color:var(--muted-foreground)]'
								}`}
								aria-hidden="true"
							></span>
							<span class="min-w-0 flex-1 truncate text-[color:var(--muted-foreground)]">
								{item.label}
							</span>
							{#if item.detalle}
								<span class="shrink-0 text-xs tabular-nums text-[color:var(--muted-foreground)]">
									{item.detalle}
								</span>
							{/if}
						</button>
					</li>
				{/each}
			</ul>
			{/if}
		</div>

		<!-- El resto de la secuencia: cada bloque es un destino con su propio título, al
		     mismo nivel que la métrica, porque son partes distintas del mismo formulario. -->
		{#each props.extraRailItems ?? [] as extra (extra.id)}
			<button
				type="button"
				class="mb-0 mt-5 flex w-full items-baseline gap-2 text-left hover:text-[color:var(--foreground)]"
				onclick={() => {
					extra.alAbrir?.();
					goTo(extra.id);
				}}
			>
				{#if extra.detalle}
					<span
						class={`mt-1 h-1.5 w-1.5 shrink-0 ${
							extra.pendiente
								? 'bg-[color:var(--primary)]'
								: 'bg-[color:var(--muted-foreground)]'
						}`}
						aria-hidden="true"
					></span>
				{/if}
				<span class="form-section-title mb-0 min-w-0 flex-1">{extra.label}</span>
				{#if extra.detalle}
					<span class="shrink-0 text-xs tabular-nums text-[color:var(--muted-foreground)]">
						{extra.detalle}
					</span>
				{/if}
			</button>
		{/each}

			{@render props.railExtra?.()}
		</div>
	</aside>

	<!-- Cuerpo: una cosa cada vez. Lo métrico va junto, bajo un solo título. -->
	<div class="min-w-0 space-y-4 bg-[color:var(--gray-50)] p-5">
		<!-- El bloque métrico es un panel principal, al mismo nivel que caracterizaciones,
		     sinopsis y comentarios. Sus títulos internos son subsecciones, no paneles hermanos. -->
		<!--
			**La métrica es una sección plegable, como las demás.** Su cabecera se llamaba «Versos y
			forma» y llevaba un «Plegar identificación» que solo recogía el primer bloque de campos;
			ahora lleva el nombre con el que la llama el raíl y pliega **la sección entera**, que es
			lo que hace falta cuando se está trabajando en la sinopsis o en los comentarios.
		-->
		<section id="identificacion" class="border border-[color:var(--border)] bg-white">
			<div
				class={`flex flex-wrap items-center justify-between gap-2 bg-[color:var(--muted)] px-4 py-2.5 ${
					seccionMetricaAbierta ? 'border-b border-[color:var(--border)]' : ''
				}`}
			>
				<h3 class="form-panel-title">Identificación métrica</h3>
				<div class="flex items-baseline gap-3">
					{#if !seccionMetricaAbierta && identificationForm}
						<span class="text-xs text-[color:var(--muted-foreground)]">{identificationForm}</span>
					{/if}
					{#if props.alAlternarSeccion}
						<!--
							**Un icono, no un verbo.** «Colapsar» y «Desplegar» son dos palabras largas que
							cambian de una a otra y hay que leer para saber en qué estado está la sección; la
							flecha lo dice apuntando, y no cambia de tamaño al pulsarla.
						-->
						<button
							type="button"
							class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)]"
							aria-expanded={seccionMetricaAbierta}
							aria-label={seccionMetricaAbierta
								? 'Colapsar identificación métrica'
								: 'Desplegar identificación métrica'}
							title={seccionMetricaAbierta ? 'Colapsar' : 'Desplegar'}
							onclick={() => props.alAlternarSeccion?.()}
						>
							<svg
								class={`h-3.5 w-3.5 transition-transform ${seccionMetricaAbierta ? 'rotate-90' : ''}`}
								viewBox="0 0 12 12"
								fill="none"
								aria-hidden="true"
							>
								<path d="M4 2.5 8 6l-4 3.5" stroke="currentColor" stroke-width="1.5" />
							</svg>
						</button>
					{/if}
				</div>
			</div>
			{#if seccionMetricaAbierta}
			<div class="space-y-6 p-4">
			{#if identificationOpen}
				<div class="space-y-3">
				<div class="grid gap-3 sm:grid-cols-2">
					<label class="form-field">
						<span class="form-label">Verso inicial</span>
						<input
							type="number"
							min="1"
							class="h-10 w-full border border-[color:var(--border)] px-3"
							value={draft.v_ini}
							onchange={(event) => updateSequenceStart(Number(event.currentTarget.value))}
						/>
					</label>
					<label class="form-field">
						<span class="form-label">Verso final</span>
						<input
							type="number"
							min={draft.v_ini}
							class="h-10 w-full border border-[color:var(--border)] px-3 disabled:bg-[color:var(--muted)]"
							value={draft.v_fin}
							onchange={(event) => updateSequenceEnd(Number(event.currentTarget.value))}
							disabled={isIsolatedVerse}
						/>
					</label>
				</div>

				<div class="mt-3 space-y-3">
					<!--
						**Un solo aviso del rango, y en la cabecera.**

						Había dos y llegaron a ser tres. Uno aquí, de la regla de longitud; otro
						trescientos píxeles más abajo bajo el rótulo «Estructura», el de la cobertura,
						con distinta redacción y aconsejando «ajusta las unidades», que en una quintilla
						de doce versos no sirve —doce no es múltiplo de cinco y no hay unidades que
						ajustar—; y el tercero, el que de verdad impide guardar, que **no se veía** hasta
						pulsar el botón.

						Son dos comprobaciones distintas —si el número de versos cabe en la forma, y si
						la estructura materializada cubre lo declarado— pero para quien anota es una sola
						pregunta: ¿por qué no puedo guardar esto? Se contesta una vez, **en la cabecera
						del modal**, que es lo único que no se va de la pantalla al desplazarse y está
						pegado a Guardar. Aquí abajo no se repite.
					-->
					<div class="grid gap-3 lg:grid-cols-2">
						<label class="form-field">
							<span class="form-label">Forma métrica *</span>
							<select
								class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
								value={draft.forma_id}
								onchange={(event) => changeForm(event.currentTarget.value)}
							>
								<option value="">Seleccionar</option>
								<optgroup label="Formas métricas">
									{#each metricForms as form (form.forma_id)}
										<option value={form.forma_id}>
											{metricFormLabel(form)}
										</option>
									{/each}
								</optgroup>
								<optgroup label="Solo si no encaja en una forma">
									{#each editorialOutputs as form (form.forma_id)}
										<option value={form.forma_id}>{form.nombre}</option>
									{/each}
								</optgroup>
							</select>
						</label>
						<!-- Sin forma elegida no hay arquitectura que preguntar: el campo no se
						     enseña apagado, sencillamente no existe todavía. -->
						{#if draft.forma_id && configurationsForDraft.length === 1 && selectedConfiguration}
							<div class="form-field">
								<span class="form-label">Arquitectura</span>
								<p class="text-sm leading-10">
									{selectedConfiguration.nombre}
									<span class="text-[color:var(--muted-foreground)]">· única de esta forma</span>
								</p>
							</div>
						{:else if draft.forma_id}
							<!--
								**Siempre desplegable.**

								Había dos controles para lo mismo: fichas cuando las arquitecturas eran tres o
								menos y ninguna pasaba de veintiocho caracteres, y desplegable en los demás
								casos. La quintilla caía justo en la frontera —«Octosilábica consonante» mide
								veintitrés— y sus tres fichas no cabían en la fila, así que la tercera bajaba
								sola; la sextilla, con seis, salía desplegable. La misma pregunta cambiaba de
								forma al cambiar de forma métrica.

								Las fichas se ganan el sitio con dos opciones de una palabra, y estos nombres
								no lo son: «Estribillo tras la primera copla», «Sin rima, con pareado final».
								Y el desplegable lleva además la descripción de cada arquitectura, que las
								fichas no tenían dónde poner.
							-->
							<div class="form-field">
								<span class="form-label">Arquitectura *</span>
								<select
									class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
									value={draft.arquitectura_id}
									onchange={(event) => resetForConfiguration(event.currentTarget.value)}
								>
									<option value="">Seleccionar arquitectura</option>
									{#each configurationsForDraft as configuration (configuration.arquitectura_id)}
										<!--
											La descripción es lo único que dice en qué se diferencian dos
											arquitecturas de la misma forma, y no se veía en ninguna parte. Aquí va
											sin ocupar sitio; **dónde debe leerse de verdad se decide con la norma
											entera** —F61—.
										-->
										<option
											value={configuration.arquitectura_id}
											title={stripMarkdown(String(configuration.descripcion ?? ''))}
										>
											{configuration.nombre}
										</option>
									{/each}
								</select>
							</div>
						{:else if selectedForm}
							<div class="bg-amber-50 p-3 text-sm leading-6 text-amber-950">
								<p class="font-medium">Salida editorial, no forma métrica</p>
							</div>
						{/if}
					</div>
				</div>
				</div>
			{:else}
				<!-- Resuelta, la identificación pesa una línea: el sitio es para las preguntas. -->
				<div
					class="flex flex-wrap items-baseline justify-between gap-3 bg-[color:var(--gray-50)] px-3 py-2.5 text-sm"
				>
					<span>{identificationSummary}</span>
					<button type="button" class="link-action" onclick={() => (identificationForced = true)}>
						Cambiar versos o forma
					</button>
				</div>
			{/if}
			{#if selectedConfiguration && selectedForm}
				<div class="mt-3">
					<MetricNormSummary facts={normFacts} catalogHref={`/recursos/catalogo-metrico/${selectedForm.slug}`} />
				</div>
			{/if}

		{#if draft.arquitectura_id}
			<!--
				**Los rasgos son respuestas, y van con las demás.**

				Vivían en su propia sección, «Datos de esta realización», encima del recuadro de la
				norma, mientras las preguntas de cada unidad quedaban debajo. Lo que las separaba era
				si la respuesta cuelga de la secuencia o de una realización, que es fontanería: para
				quien anota las dos son lo mismo, lo que hay que contestar de este pasaje. Y dejaba
				dos pies de licencias, uno en cada sitio, esperando a una forma que tuviera de los dos.

				Donde hay estructura, estos campos entran en la zona de respuestas, delante de los de
				unidad. Donde no la hay —el romance, el endecasílabo suelto—, son la zona entera.
			-->
			{#if hasSequenceChoices && !hasStructuredEditor}
				<section id="secuencia" class="space-y-4 pt-4">
					<h4 class="form-subsection-title mb-0">Respuestas</h4>
					{@render camposDeLaSecuencia()}
					{#if rasgosQueAdmite.length > 0}
						<div class="flex flex-wrap items-center gap-2">
							<span class="text-xs text-[color:var(--muted-foreground)]">
								{rasgosQueAdmite.length === 1
									? 'Esta forma admite además, si lo hay:'
									: 'Esta forma admite además, si los hay:'}
							</span>
							{@render licenciasDeLaSecuencia()}
						</div>
					{/if}
				</section>
			{/if}

			<!--
				**Las series también dicen cuánto cabe.** No tienen recuadro de cobertura porque no
				materializan unidades, y se quedaban sin decir nada de su extensión salvo cuando el
				rango no cuadraba y saltaba el error. Aquí se dice en positivo.
			-->
			{#if !hasStructuredEditor && reparticionDelPasaje && nombreDeLaReparticion}
				<section class="border-t border-[color:var(--border)] pt-5">
					<div
						class="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1 border border-[color:var(--border)] bg-[color:var(--gray-50)] px-3 py-2.5 text-sm"
					>
						<p class="font-medium">
							{nombreDeLaReparticion.plural.charAt(0).toUpperCase() +
								nombreDeLaReparticion.plural.slice(1)} del pasaje
						</p>
						<p class="text-xs tabular-nums text-[color:var(--muted-foreground)]">
							{reparticionDelPasaje.veces}
							{reparticionDelPasaje.veces === 1
								? nombreDeLaReparticion.singular
								: nombreDeLaReparticion.plural} de {reparticionDelPasaje.modulo}
							{reparticionDelPasaje.modulo === 1 ? 'verso' : 'versos'}{reparticionDelPasaje.sobrantes >
							0
								? nombreDeLosSobrantes
									? ` · y el ${nombreDeLosSobrantes.toLocaleLowerCase('es')}`
									: ` · y ${reparticionDelPasaje.sobrantes} ${reparticionDelPasaje.sobrantes === 1 ? 'verso más' : 'versos más'}`
								: ''}
						</p>
					</div>
				</section>
			{/if}

			{#if hasStructuredEditor}
				<!--
					**Sin rótulo.** «Estructura» encabezaba una sección cuyo único contenido propio era la
					cobertura del rango, que ya no vive aquí. Lo que queda debajo son las respuestas y la
					lectura de lo que va a guardarse, y las dos se nombran solas.
				-->
				<section id="estructura" class="space-y-4 pt-4">

					{#key `${draft.anotacion_id ?? 'nueva'}-${draft.arquitectura_id}`}
						<MetricStructureEditor
							sequenceStart={draft.v_ini}
							sections={sectionsForDraft}
							{rhymeRegimes}
							varieties={varietiesForDraft}
							unitPlan={unitPlanForDraft}
							groups={unitChoiceGroups}
							options={choiceOptionsForDraft}
							schemes={props.catalog.domain.rhymePatterns}
							rejilla={normGrid}
							units={draft.unidades}
							choices={draft.elecciones}
							unitLabel={selectedForm?.nombre}
							globalQuestions={hasCompositionMeasure ? compositionMeasure : undefined}
							{interleavedArchitectures}
							{interleavedSections}
							onUnitArchitectureChange={setUnitArchitecture}
							onUnitsChange={(units) => (draft.unidades = units)}
							onChoicesChange={(choices) => (draft.elecciones = choices)}
							onUnitsRemoved={removeStructuredReferences}
							preguntasDeSecuencia={preguntasDeSecuencia.length > 0 ? camposDeLaSecuencia : undefined}
							licenciasDeSecuencia={rasgosQueAdmite.length > 0 ? licenciasDeLaSecuencia : undefined}
							cuantasLicenciasDeSecuencia={rasgosQueAdmite.length}
							rangoSinCuadrar={structureCoverage.state !== 'complete' ||
								Boolean(
									metricLengthError(
										selectedLengthRule,
										draft.v_ini,
										draft.v_fin,
										selectedConfiguration?.nombre,
										selectedForm?.nombre,
										hayUnidadConArquitecturaPropia(draft.unidades)
									)
								)}
						/>
					{/key}
				</section>
			{/if}

			<!--
				**Declarar una desviación es responder, no navegar.**

				Vivía en el raíl, entre los destinos, y era la única entrada que en vez de llevar a un
				sitio ejecutaba algo. Su lugar es el final de las respuestas: el recuadro de la norma
				termina diciendo «lo que no encaje aquí se registra como desviación», y esto es
				justamente aquí.
			-->
			{#if draft.arquitectura_id && !isEditorialOutput}
				<p class="text-sm text-[color:var(--muted-foreground)]">
					¿Hay algo que no encaja en la norma?
					<button
						type="button"
						class="link-action ml-1"
						onclick={() => {
							addDeviation();
							goTo('desviaciones');
						}}
					>
						Registrar una desviación
					</button>
				</p>
			{/if}


			{#if draft.desviaciones.length > 0}
				<MetricPanelSection
					id="desviaciones"
					titulo="Desviaciones"
					abierta={desviacionesAbiertas}
					alAlternar={() => (desviacionesAbiertas = !desviacionesAbiertas)}
					resumen={`${draft.desviaciones.length}`}
					sinContenedor={true}
				>
					<p class="form-help flex items-center gap-1">
						Solo lo que no encaja en ninguna de las respuestas anteriores.
						<FieldHelpTooltip
							text="Que no haya ninguna desviación significa que la realización cumple la norma, no que falte revisarla."
							label="Ayuda sobre las desviaciones"
						/>
					</p>
					{#each draft.desviaciones as deviation, deviationIndex}
						{@const relaciones = metricDeviationRelations(deviation.dimension)}
						<div class="space-y-3">
							<!--
								**Quitar es del bloque entero, así que va en su cabecera.**

								Estaba en medio de la tarjeta, en rojo y pegado a «V. final», donde parecía que
								quitaba el verso final. Aquí arriba, con el número de la desviación al lado, se
								ve de qué se está deshaciendo uno. Y numeradas, porque los avisos de lo que
								falta hablan de «la desviación 2» y hasta ahora no había ninguna que llevara ese
								número escrito.
							-->
							<div class="flex flex-wrap items-baseline justify-between gap-3">
								<span class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
									Desviación{draft.desviaciones.length > 1 ? ` ${deviationIndex + 1}` : ''}
								</span>
								<button
									type="button"
									class="link-action link-action--danger text-xs"
									onclick={() => {
										draft.desviaciones = draft.desviaciones.filter(
											(_: MetricDeviationDraft, index: number) => index !== deviationIndex
										);
									}}
								>
									Quitar
								</button>
							</div>
							<div class="grid gap-3 sm:grid-cols-2 xl:grid-cols-6">
							<label class="form-field">
								<span class="form-label">Dimensión</span>
								<select
									class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm"
									value={deviation.dimension}
									onchange={(event) => {
										const next = event.currentTarget.value as MetricDeviationDimension;
										deviation.dimension = next;
										// Al cambiar de dimensión, la relación se conserva si sigue
										// aplicando y se vacía si no: elegirla por el editor es lo que
										// hacía que la desviación afirmara algo que nadie ha dicho. Y el
										// valor observado se va, porque pertenecía a la otra dimensión.
										deviation.relacion_norma = defaultRelationFor(
											next,
											deviation.relacion_norma
										);
										setObserved(deviation, '');
									}}
								>
									<option value="">De qué…</option>
									{#each METRIC_DEVIATION_DIMENSIONS as option (option.value)}
										<option value={option.value}>{option.label}</option>
									{/each}
								</select>
							</label>
							<!--
								**Con una sola relación posible no se pregunta: se dice.**

								A la rima solo le queda «otra cosa», porque cualquier esquema distinto ya es una
								respuesta. Un desplegable de un elemento pide una decisión que no existe, así
								que ahí va la frase y el trabajo pasa entero a la descripción.
							-->
							{#if relaciones.length === 1}
								<div class="form-field xl:col-span-2">
									<span class="form-label">Relación con la norma</span>
									<p class="text-sm leading-10 text-[color:var(--muted-foreground)]">
										{relaciones[0].label}
									</p>
								</div>
							{:else}
								<label class="form-field xl:col-span-2">
									<span class="form-label">Relación con la norma</span>
									<select
										class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm"
										value={deviation.relacion_norma}
										onchange={(event) => {
											deviation.relacion_norma = event.currentTarget
												.value as MetricDeviationDraft['relacion_norma'];
											// «Falta» no admite valor observado: no había nada que observar.
											if (deviation.relacion_norma === 'falta') setObserved(deviation, '');
										}}
									>
										<option value="">
											{deviation.dimension ? 'Qué le pasa…' : 'Elige antes la dimensión'}
										</option>
										{#each relaciones as option (option.value)}
											<option value={option.value}>{option.label}</option>
										{/each}
									</select>
								</label>
							{/if}
							<!-- Lo observado: la precisión que hace analizable la desviación. Con
							     «Falta» no hay nada que observar, y la base lo exige vacío. -->
							<!--
								**La rima no ofrece nada que elegir.**

								Ofrecía los esquemas de la propia arquitectura —«Tipología 1», «Tipología 2»…—
								y elegir uno de ellos es decir que el pasaje rima como la norma admite, que es
								una respuesta y no una desviación. Y desde que se puede escribir el esquema
								—las 53 preguntas de rima del catálogo son `opciones_y_esquema` o
								`esquema_rima`, todas— un esquema que el catálogo no tiene **también** es una
								respuesta. No queda ningún caso que elegir aquí: una desviación de rima
								—rima interna, rima donde la norma da versos por sueltos— se escribe.
							-->
							{#if deviation.relacion_norma !== 'falta' && deviation.dimension !== 'rima'}
								{@const opciones = observedOptions(deviation.dimension)}
								{#if opciones.length > 0}
									<label class="form-field sm:col-span-2 xl:col-span-3">
										<span class="form-label">
											{deviation.dimension === 'metro' ? 'Metro observado' : 'Observado'}
										</span>
										<select
											class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm"
											value={observedValue(deviation)}
											onchange={(event) => setObserved(deviation, event.currentTarget.value)}
										>
											<option value="">Sin precisar</option>
											<!--
												**Agrupados por su rasgo.** Los treinta y cuatro valores salían
												mezclados y en una sola lista: «a», «a-a», «Agudo»… Nadie puede saber
												que «a-e» es una vocal de asonancia y «Agudo» un final acentual.
											-->
											{#if opciones.some((option) => option.grupo)}
												{#each [...new Set(opciones.map((option) => option.grupo ?? '—'))] as grupo (grupo)}
													<optgroup label={grupo}>
														{#each opciones.filter((option) => (option.grupo ?? '—') === grupo) as option (option.id)}
															<option value={option.id}>{option.label}</option>
														{/each}
													</optgroup>
												{/each}
											{:else}
												{#each opciones as option (option.id)}
													<option value={option.id}>{option.label}</option>
												{/each}
											{/if}
										</select>
										{#if observedMetreNote(deviation)}
											<span
												class={`form-help ${
													observedContradiction(deviation)
														? 'text-[color:var(--danger)]'
														: ''
												}`}
											>
												{observedMetreNote(deviation)}
												{#if observedContradiction(deviation)}
													· no concuerda con la relación elegida
												{/if}
											</span>
										{/if}
									</label>
								{/if}
							{/if}
							<!--
								**Lo que le falta se dice aquí, no en la cabecera.**

								El aviso de arriba habla solo del rango, que es lo que está mal; esto es trabajo
								a medias y se dice donde se está haciendo. Callado mientras no se haya elegido
								dimensión: una desviación recién abierta está incompleta por definición y
								decírselo al editor en el mismo instante en que pulsa el botón es regañarle por
								no haber escrito todavía.
							-->
							{#if deviation.dimension && !deviation.relacion_norma}
								<p class="text-xs text-[color:var(--primary)] sm:col-span-2 xl:col-span-6">
									Falta decir qué le pasa.
								</p>
							{/if}
							<!--
								Acotados al rango de la secuencia: una desviación es de un pasaje suyo. Iban
								sin `min` siquiera, así que admitían cero y negativos, y nadie los miraba al
								guardar: lo paraba la base, con un error crudo en vez de con un aviso.
							-->
							<label class="form-field">
								<span class="form-label">V. inicial</span>
								<input
									type="number"
									min={draft.v_ini}
									max={draft.v_fin}
									class="h-10 w-full border border-[color:var(--border)] px-2"
									value={deviation.v_ini}
									onchange={(event) =>
										fijarRangoDeDesviacion(deviation, 'v_ini', Number(event.currentTarget.value))}
								/>
							</label>
							<label class="form-field">
								<span class="form-label">V. final</span>
								<input
									type="number"
									min={deviation.v_ini}
									max={draft.v_fin}
									class="h-10 w-full border border-[color:var(--border)] px-2"
									value={deviation.v_fin}
									onchange={(event) =>
										fijarRangoDeDesviacion(deviation, 'v_fin', Number(event.currentTarget.value))}
								/>
							</label>
							<label class="form-field sm:col-span-2 xl:col-span-6">
								<span class="form-label">Descripción de la diferencia (recomendada)</span>
								<textarea
									class="min-h-20 w-full border border-[color:var(--border)] p-2"
									placeholder="Aclara la diferencia si hace falta para leerla después"
									bind:value={deviation.observaciones}
								></textarea>
							</label>
							</div>
						</div>
					{/each}
					<!--
						**Añadir va después de lo que hay, no encima.**

						Estaba arriba, junto al rótulo de la sección, así que se ofrecía añadir una segunda
						antes de haber leído la primera. Se añade cuando se ha terminado con la anterior.
					-->
					<button type="button" class="link-action" onclick={addDeviation}>
						Añadir otra desviación
					</button>
				</MetricPanelSection>
			{/if}

			<!-- Aquí no hay observación libre, tampoco en un tramo sin forma: lo que el editor
			     quiera anotar sobre esta secuencia va a los comentarios internos, que ya se anclan
			     a ella, se tipifican y pueden hacerse públicos. Duplicarlo aquí partiría el mismo
			     trabajo en dos. -->
		{/if}
			</div>
			{/if}
		</section>

		<!-- El resto de la secuencia: no es métrico, pero el editor lo rellena en la misma
		     pasada, así que se ve en el mismo flujo y no en una columna aparte. **Fuera de la
		     sección métrica**, para que plegarla no se lo lleve por delante. -->
		{@render props.bodyExtra?.()}
	</div>
</div>

<!-- La medida común de arquitecturas no cíclicas con varias secciones. -->
{#snippet compositionMeasure()}
	<MetricGridRow
		label="Medida de los versos"
		rango={`las ${measureAnswers.total} secciones con versos`}
		variant="comun"
	>
		<div class="flex flex-wrap items-center gap-3">
			{#if measureMetres.length > 0 && measureMetres.length <= 4}
				<SegmentedChoice
					items={measureMetres}
					value={uniformMetreId}
					onChange={(id) => id && applyMetreToAllSections(id)}
					ariaLabel="Medida de los versos de toda la composición"
					size="sm"
				/>
			{:else}
				<select
					class="h-9 border border-[color:var(--border)] bg-white px-3 text-sm"
					value={uniformMetreId ?? ''}
					aria-label="Medida de los versos de toda la composición"
					onchange={(event) => applyMetreToAllSections(event.currentTarget.value)}
				>
					<option value="">
						{uniformMetreId === null && measureAnswers.answered > 0
							? 'Varían: cada sección conserva la suya'
							: 'Responder todas de una vez'}
					</option>
					{#each measureMetres as metre (metre.id)}
						<option value={metre.id}>{metre.label}</option>
					{/each}
				</select>
			{/if}
			{#if uniformMetreId === null && measureAnswers.answered > 0}
				<span class="text-xs text-[color:var(--muted-foreground)]">
					Varían por sección; cada una conserva la suya
				</span>
			{/if}
		</div>
	</MetricGridRow>
{/snippet}

{#snippet camposDeLaSecuencia()}
				{#each preguntasDeSecuencia as group (String(group.grupo_eleccion_id))}
					<MetricChoiceField
						{group}
						options={optionsForGroup(String(group.grupo_eleccion_id))}
						selectedIds={selectedChoiceIds(String(group.grupo_eleccion_id), null)}
						onChange={(ids) => setChoices(String(group.grupo_eleccion_id), null, ids)}
						textValue={choiceTextValue(String(group.grupo_eleccion_id), null)}
						onTextChange={(value) => setChoiceText(String(group.grupo_eleccion_id), null, value)}
						normaEsquema={String(group.tipo_control ?? '') === 'serie_medidas'
							? {
									versos: draft.v_fin - draft.v_ini + 1,
									regimen: null,
									catalogados: [],
									regimenes: []
								}
							: undefined}
					/>
				{/each}

{/snippet}

{#snippet licenciasDeLaSecuencia()}
	{#each rasgosQueAdmite as group (String(group.grupo_eleccion_id))}
		<button
			type="button"
			class="border border-[color:var(--border)] bg-white px-2 py-1 text-xs hover:border-[color:var(--primary)]"
			onclick={() => (rasgosPedidos = [...rasgosPedidos, String(group.grupo_eleccion_id)])}
		>
			+ {String(group.nombre ?? group.slug ?? '').toLocaleLowerCase('es')}
		</button>
	{/each}
{/snippet}

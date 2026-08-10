<script lang="ts">
	import { untrack } from 'svelte';
	import CollapsibleGroup from '$lib/components/ui/collapsible-group.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import SegmentedChoice from '$lib/components/ui/segmented-choice.svelte';
	import type {
		MetricCatalogConfiguration,
		MetricCatalogDomainRow,
		MetricCatalogForEditor,
		MetricCatalogForm,
		MetricLengthRule
	} from '$lib/metrica/catalogo';
	import { metricFormLabel } from '$lib/metrica/catalogo';
	import { metricLengthError } from '$lib/metrica/metric-length';
	import MetricChoiceField from './MetricChoiceField.svelte';
	import MetricLengthAlert from './MetricLengthAlert.svelte';
	import MetricStructureEditor from './MetricStructureEditor.svelte';
	import {
		childrenOfSection,
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
	import {
		catalogParts,
		defaultRelationFor,
		emptyDeviation,
		metricDeviationRelations,
		applyProposedUnitAnswers,
		normalizeStructuredUnits,
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
		extraRailItems?: { id: string; label: string }[];
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

			const plan = unitPlanFor(props.catalog, initial.arquitectura_id, parts.sections);
			// Con una unidad de extensión variable el rango se calcula desde sus partes.
			if (plan !== null && !plan.countFromRange) {
				initial.v_fin = initial.unidades.reduce(
					(maximum: number, unit: MetricUnitDraft) => Math.max(maximum, unit.v_fin),
					initial.v_ini
				);
			}
			return initial;
		})
	);

	let showMeasuresBySection = $state(false);
	/** El editor ha vuelto a abrir la identificación ya resuelta para corregirla. */
	let identificationForced = $state(false);
	let identificationGroupOpen = $state(true);

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
	const choiceOptionsForDraft = $derived(
		props.catalog.domain.choiceOptions.filter(
			(row: MetricCatalogDomainRow) =>
				row.activo &&
				choiceGroupsForDraft.some(
					(group: MetricCatalogDomainRow) => group.grupo_eleccion_id === row.grupo_eleccion_id
				)
		)
	);
	const unitPlanForDraft = $derived(
		metricUnitPlan(selectedConfiguration, sectionsForDraft, selectedForm?.nivel_estructural)
	);
	const hasDerivedUnitCount = $derived(unitPlanForDraft?.countFromRange ?? false);
	const hasStructuredEditor = $derived(
		Boolean(unitPlanForDraft) &&
			(unitChoiceGroups.length > 0 || sectionsForDraft.length > 0 || !hasDerivedUnitCount)
	);
	const hasCalculatedRange = $derived(Boolean(unitPlanForDraft) && !hasDerivedUnitCount);
	const hasSequenceChoices = $derived(sequenceChoiceGroups.length > 0);
	const materializedUnitCount = $derived(
		unitPlanForDraft
			? draft.unidades.filter(
					(unit: MetricUnitDraft) =>
						unit.realizacion_padre_id === null && unit.seccion_id === null
				).length
			: 0
	);

	// La medida se pregunta en cada sección con versos, así que un villancico isosilábico
	// obliga a responder seis veces lo mismo. La pregunta única las responde todas y las de
	// sección solo se abren cuando alguna difiere: lo que se guarda sigue siendo la medida de
	// cada sección, que es lo que declara el catálogo.
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
				const selected = selectedChoiceIds(groupId, unit.realizacion_prueba_id);
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
	const measuresFoldable = $derived(
		measureGroups.length >= 2 && (uniformMetreId !== null || measureAnswers.answered === 0)
	);
	const measuresFolded = $derived(measuresFoldable && !showMeasuresBySection);
	const structureGroups = $derived(
		measuresFolded
			? unitChoiceGroups.filter(
					(group: MetricCatalogDomainRow) =>
						!measureGroups.some(
							(measure: MetricCatalogDomainRow) =>
								String(measure.grupo_eleccion_id) === String(group.grupo_eleccion_id)
						)
				)
			: unitChoiceGroups
	);

	const identificationResolved = $derived(
		Boolean(draft.forma_id) && (isEditorialOutput || Boolean(draft.arquitectura_id))
	);
	const identificationOpen = $derived(!identificationResolved || identificationForced);

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
					choice.realizacion_prueba_id === unitId &&
					Boolean(choice.opcion_eleccion_id)
			)
			.map((choice: MetricChoiceDraft) => choice.opcion_eleccion_id as string);
	}

	function choiceTextValue(groupId: string, unitId: string | null): string {
		return (
			draft.elecciones.find(
				(choice: MetricChoiceDraft) =>
					choice.grupo_eleccion_id === groupId &&
					choice.realizacion_prueba_id === unitId &&
					Boolean(choice.valor_texto)
			)?.valor_texto ?? ''
		);
	}

	function normalizeRhymeScheme(value: string): string {
		return value.replace(/\s+/g, '').toLocaleUpperCase('es');
	}

	function setChoices(groupId: string, unitId: string | null, optionIds: string[]) {
		draft.elecciones = [
			...draft.elecciones.filter(
				(choice: MetricChoiceDraft) =>
					!(choice.grupo_eleccion_id === groupId && choice.realizacion_prueba_id === unitId)
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

	function setChoiceText(groupId: string, unitId: string | null, value: string) {
		const normalized = normalizeRhymeScheme(value);
		draft.elecciones = [
			...draft.elecciones.filter(
				(choice: MetricChoiceDraft) =>
					!(choice.grupo_eleccion_id === groupId && choice.realizacion_prueba_id === unitId)
			),
			...(normalized
				? [
						{
							realizacion_prueba_id: unitId,
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
				choice.grupo_eleccion_id === groupId && choice.realizacion_prueba_id === unitId
		).length;
	}

	/** Las realizaciones a las que se dirige una pregunta por unidad. */
	function unitsForGroup(group: MetricCatalogDomainRow): MetricUnitDraft[] {
		return draft.unidades.filter((unit: MetricUnitDraft) =>
			group.seccion_id
				? String(group.seccion_id) === unit.seccion_id
				: unit.realizacion_padre_id === null
		);
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
								choice.realizacion_prueba_id === unit.realizacion_prueba_id
							)
					),
					...chosen.map((option: MetricCatalogDomainRow) => ({
						realizacion_prueba_id: unit.realizacion_prueba_id,
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

	function resetForConfiguration(configurationId: string) {
		showMeasuresBySection = false;
		draft.arquitectura_id = configurationId;
		const previousLength = Math.max(1, draft.v_fin - draft.v_ini + 1);
		draft.unidades = normalizeStructuredUnits(
			props.catalog,
			[],
			[],
			configurationId,
			draft.v_ini,
			draft.v_fin
		);
		draft.elecciones = [];
		draft.desviaciones = [];
		const parts = catalogParts(props.catalog, configurationId);
		const plan = unitPlanFor(props.catalog, configurationId, parts.sections);
		if (plan && (!plan.countFromRange || previousLength < (plan.extent?.minimum ?? 1))) {
			draft.v_fin = draft.unidades.reduce(
				(maximum: number, unit: MetricUnitDraft) => Math.max(maximum, unit.v_fin),
				draft.v_ini
			);
		}
	}

	function changeForm(formId: string) {
		draft.forma_id = formId;
		identificationForced = true;
		const form = props.catalog.forms.find((item: MetricCatalogForm) => item.forma_id === formId);
		if (form?.tipo_registro === 'sin_forma') {
			resetForConfiguration('');
			if (form.slug === 'verso_aislado') {
				draft.v_fin = draft.v_ini;
			} else if (form.slug === 'irregular' && draft.v_fin === draft.v_ini) {
				draft.v_fin = draft.v_ini + 1;
			}
			return;
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

	function addDeviation() {
		draft.desviaciones = [...draft.desviaciones, emptyDeviation(draft.v_ini, draft.v_fin)];
	}

	// ------------------------------------------------------------------
	// El valor observado de una desviación
	//
	// Cada dimensión nombra lo observado en su propio vocabulario, y la base exige que la
	// columna corresponda a la dimensión declarada. Aquí vive esa correspondencia una sola
	// vez: qué columna toca, de dónde salen sus opciones y cómo se limpian las demás.
	// ------------------------------------------------------------------

	const OBSERVED_COLUMNS = {
		metro: 'metro_observado_id',
		rima: 'esquema_rima_observado_id',
		estructura: 'seccion_observada_id',
		repeticion: 'repeticion_observada_id',
		rasgo: 'valor_rasgo_observado_id'
	} as const;

	function observedOptions(
		dimension: MetricDeviationDimension
	): { id: string; label: string }[] {
		const domain = props.catalog.domain;
		const rows: MetricCatalogDomainRow[] =
			dimension === 'metro'
				? domain.verseModels
				: dimension === 'rima'
					? domain.rhymePatterns.filter(
							(row: MetricCatalogDomainRow) => row.arquitectura_id === draft.arquitectura_id
						)
					: dimension === 'estructura'
						? sectionsForDraft
						: dimension === 'repeticion'
							? domain.repetitionPatterns.filter(
									(row: MetricCatalogDomainRow) =>
										row.arquitectura_id === draft.arquitectura_id
								)
							: domain.traitValues;
		return rows
			.filter((row: MetricCatalogDomainRow) => row.activo !== false)
			.map((row: MetricCatalogDomainRow) => ({
				id: String(
					row.metro_id ??
						row.esquema_rima_id ??
						row.seccion_id ??
						row.repeticion_id ??
						row.valor_id
				),
				label: String(row.nombre || row.notacion || row.slug || '')
			}))
			.filter((option) => option.id !== 'undefined' && option.label)
			.sort((a, b) => a.label.localeCompare(b.label, 'es'));
	}

	function observedValue(deviation: MetricDeviationDraft): string {
		return String(deviation[OBSERVED_COLUMNS[deviation.dimension]] ?? '');
	}

	/** Deja puesta solo la columna que corresponde a la dimensión, como exige la base. */
	function setObserved(deviation: MetricDeviationDraft, value: string) {
		for (const column of Object.values(OBSERVED_COLUMNS)) {
			deviation[column] = null;
		}
		if (value) deviation[OBSERVED_COLUMNS[deviation.dimension]] = value;
	}

	/**
	 * Las sílabas que la arquitectura fija para sus versos, cuando fija una sola. Sirve para
	 * decirle al editor qué diferencia supone el metro que acaba de elegir, sin guardarlo:
	 * la hipometría se enseña, no se almacena.
	 */
	const normSyllables = $derived.by(() => {
		if (!draft.arquitectura_id) return null;
		const schemeIds = new Set(
			props.catalog.domain.metricPatterns
				.filter((row: MetricCatalogDomainRow) => row.arquitectura_id === draft.arquitectura_id)
				.map((row: MetricCatalogDomainRow) => String(row.esquema_metrico_id))
		);
		if (schemeIds.size === 0) return null;
		const metreIds = new Set(
			props.catalog.domain.metricPositions
				.filter((row: MetricCatalogDomainRow) =>
					schemeIds.has(String(row.esquema_metrico_id))
				)
				.map((row: MetricCatalogDomainRow) => String(row.metro_id))
		);
		// Con más de un metro la norma no es una cifra y no hay diferencia que anunciar.
		if (metreIds.size !== 1) return null;
		const metre = props.catalog.domain.verseModels.find(
			(row: MetricCatalogDomainRow) => String(row.metro_id) === [...metreIds][0]
		);
		return metre ? { silabas: Number(metre.silabas), nombre: String(metre.nombre) } : null;
	});

	/** «Una sílaba menos que la norma (octosílabo)», calculado en el momento. */
	function observedMetreNote(deviation: MetricDeviationDraft): string {
		if (deviation.dimension !== 'metro' || !deviation.metro_observado_id) return '';
		const metre = props.catalog.domain.verseModels.find(
			(row: MetricCatalogDomainRow) => String(row.metro_id) === deviation.metro_observado_id
		);
		if (!metre) return '';
		const silabas = Number(metre.silabas);
		if (!normSyllables) return `${silabas} sílabas`;
		const diferencia = silabas - normSyllables.silabas;
		if (diferencia === 0) {
			return `${silabas} sílabas · coincide con la norma (${normSyllables.nombre})`;
		}
		const cuantas = Math.abs(diferencia);
		return `${cuantas} ${cuantas === 1 ? 'sílaba' : 'sílabas'} ${
			diferencia < 0 ? 'menos' : 'más'
		} que la norma (${normSyllables.nombre})`;
	}

	/** ¿Concuerdan la relación declarada y el metro observado? Invariante 2 del plan. */
	function observedContradiction(deviation: MetricDeviationDraft): boolean {
		if (deviation.dimension !== 'metro' || !deviation.metro_observado_id || !normSyllables) {
			return false;
		}
		const metre = props.catalog.domain.verseModels.find(
			(row: MetricCatalogDomainRow) => String(row.metro_id) === deviation.metro_observado_id
		);
		if (!metre) return false;
		const diferencia = Number(metre.silabas) - normSyllables.silabas;
		if (deviation.relacion_norma === 'menor_que_norma') return diferencia >= 0;
		if (deviation.relacion_norma === 'mayor_que_norma') return diferencia <= 0;
		return false;
	}

	function updateSequenceStart(value: number) {
		const previousLength = draft.v_fin - draft.v_ini + 1;
		draft.v_ini = Math.max(1, value);
		if (isIsolatedVerse) {
			draft.v_fin = draft.v_ini;
			return;
		}
		if (hasDerivedUnitCount) {
			draft.v_fin = draft.v_ini + previousLength - 1;
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
		draft.v_fin = draft.unidades.reduce(
			(maximum: number, unit: MetricUnitDraft) => Math.max(maximum, unit.v_fin),
			draft.v_ini
		);
	}

	function updateSequenceEnd(value: number) {
		if (isIsolatedVerse) {
			draft.v_fin = draft.v_ini;
			return;
		}
		draft.v_fin = Math.max(1, value);
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
				!choice.realizacion_prueba_id || !removed.has(choice.realizacion_prueba_id)
		);
		draft.desviaciones = draft.desviaciones.map((deviation: MetricDeviationDraft) =>
			deviation.realizacion_prueba_id && removed.has(deviation.realizacion_prueba_id)
				? { ...deviation, realizacion_prueba_id: null }
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
		// La medida recogida en la pregunta única cuenta como una sola, que es como se ve.
		if (measuresFolded) {
			total += 1;
			if (uniformMetreId !== null) answered += 1;
		}
		for (const group of structureGroups) {
			if (Number(group.selecciones_min) < 1) continue;
			for (const unit of unitsForGroup(group)) {
				total += 1;
				if (
					choiceCount(String(group.grupo_eleccion_id), unit.realizacion_prueba_id) >=
					Number(group.selecciones_min)
				) {
					answered += 1;
				}
			}
		}
		return { total, answered };
	});

	function validateDraft(): string | null {
		if (!draft.forma_id) {
			return 'Selecciona una forma o una salida editorial.';
		}
		if (!isEditorialOutput && !draft.arquitectura_id) {
			return 'Selecciona la arquitectura de la forma.';
		}
		if (selectedForm?.slug === 'irregular' && draft.v_fin - draft.v_ini + 1 < 2) {
			return 'Versificación irregular debe abarcar al menos dos versos.';
		}
		if (isIsolatedVerse && draft.v_fin !== draft.v_ini) {
			return 'Verso aislado debe abarcar exactamente un verso.';
		}
		if (draft.v_fin < draft.v_ini) return 'El verso final no puede ser anterior al inicial.';
		const lengthError = metricLengthError(
			selectedLengthRule,
			draft.v_ini,
			draft.v_fin,
			selectedConfiguration?.nombre
		);
		if (lengthError) return lengthError;
		for (const unit of draft.unidades) {
			if (unit.v_fin < unit.v_ini || unit.v_ini < draft.v_ini || unit.v_fin > draft.v_fin) {
				return `La unidad ${unit.orden} queda fuera del rango de la secuencia.`;
			}
			const unitLength = unit.v_fin - unit.v_ini + 1;
			const section = sectionsForDraft.find(
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
			} else if (unit.seccion_id === null && unitPlanForDraft?.extent) {
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
				for (const child of childrenOfSection(sectionsForDraft, parent.seccion_id)) {
					const childTotal = draft.unidades.filter(
						(unit: MetricUnitDraft) =>
							unit.realizacion_padre_id === parent.realizacion_prueba_id &&
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
					unit.realizacion_prueba_id
				);
				if (total < Number(group.selecciones_min) || total > Number(group.selecciones_max)) {
					// La pregunta puede estar recogida arriba, en la norma de la composición: el
					// aviso tiene que señalar el campo que el editor está viendo.
					const folded =
						measuresFolded &&
						measureGroups.some(
							(measure: MetricCatalogDomainRow) =>
								String(measure.grupo_eleccion_id) === String(group.grupo_eleccion_id)
						);
					if (folded) return 'Indica la medida de toda la composición.';
					const unanswered = applicableUnits.every(
						(candidate: MetricUnitDraft) =>
							choiceCount(
								String(group.grupo_eleccion_id),
								candidate.realizacion_prueba_id
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
			error: validateDraft()
		});
	});

	/** Lleva la vista a un bloque del cuerpo desde el raíl. */
	function goTo(anchor: string) {
		document
			.getElementById(anchor)
			?.scrollIntoView({ behavior: 'smooth', block: 'start' });
	}

	const railItems = $derived.by(() => {
		const items: { id: string; label: string; state: 'done' | 'pending' | 'none' }[] = [];
		if (hasSequenceChoices) {
			const pending = sequenceChoiceGroups.some(
				(group: MetricCatalogDomainRow) =>
					Number(group.selecciones_min) >= 1 &&
					choiceCount(String(group.grupo_eleccion_id), null) < Number(group.selecciones_min)
			);
			items.push({
				id: 'secuencia',
				label: 'Datos de esta realización',
				state: pending ? 'pending' : 'done'
			});
		}
		if (hasStructuredEditor) {
			items.push({
				id: 'estructura',
				label: materializedUnitCount > 1 ? `Estructura · ${materializedUnitCount} unidades` : 'Estructura',
				state:
					questionProgress.total > 0 && questionProgress.answered < questionProgress.total
						? 'pending'
						: 'done'
			});
		}
		// Lo que ya está en pantalla entra en el mapa, aunque se haya añadido a mano.
		if (draft.desviaciones.length > 0) {
			items.push({
				id: 'desviaciones',
				label: `Desviaciones · ${draft.desviaciones.length}`,
				state: 'done'
			});
		}
		if (isEditorialOutput && !draft.arquitectura_id) {
			items.push({ id: 'observaciones', label: 'Observación', state: 'none' });
		}
		return items;
	});
</script>

<div class="grid min-h-0 lg:grid-cols-[15rem_minmax(0,1fr)]">
	<!-- Raíl: el mapa de la secuencia. Dice dónde estás y qué falta, no pide datos. -->
	<aside
		class="border-b border-[color:var(--border)] bg-[color:var(--muted)] p-4 lg:sticky lg:top-0 lg:h-fit lg:self-start lg:border-b-0 lg:border-r"
	>
		<button
			type="button"
			class="form-section-title mb-2 block w-full text-left hover:text-[color:var(--foreground)]"
			onclick={() => goTo('identificacion')}
		>
			Identificación métrica
		</button>
		{#if identificationForm}
			<p class="text-base font-medium leading-snug text-[color:var(--foreground)]">
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
				{#each railItems as item (item.id)}
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
										: item.state === 'done'
											? 'bg-[color:var(--muted-foreground)]'
											: 'border border-[color:var(--muted-foreground)]'
								}`}
								aria-hidden="true"
							></span>
							<span class="text-[color:var(--muted-foreground)]">{item.label}</span>
						</button>
					</li>
				{/each}
			</ul>
		{/if}

		<!-- La desviación es parte de identificar la secuencia, así que su acción vive aquí
		     y no al final del raíl, suelta debajo del resto de secciones. -->
		{#if draft.arquitectura_id && !isEditorialOutput}
			<button
				type="button"
				class="link-action mt-2 block"
				onclick={() => {
					addDeviation();
					goTo('desviaciones');
				}}
			>
				Registrar una desviación
			</button>
		{/if}

		<!-- El resto de la secuencia: cada bloque es un destino con su propio título, al
		     mismo nivel que la métrica, porque son partes distintas del mismo formulario. -->
		{#each props.extraRailItems ?? [] as extra (extra.id)}
			<button
				type="button"
				class="form-section-title mb-0 mt-5 block w-full text-left hover:text-[color:var(--foreground)]"
				onclick={() => goTo(extra.id)}
			>
				{extra.label}
			</button>
		{/each}

		{@render props.railExtra?.()}
	</aside>

	<!-- Cuerpo: una cosa cada vez. Lo métrico va junto, bajo un solo título. -->
	<div class="min-w-0 space-y-4 bg-[color:var(--gray-50)] p-5">
		<CollapsibleGroup
			id="identificacion"
			title="Identificación métrica"
			summary={identificationResolved ? identificationSummary : 'Sin forma elegida'}
			open={identificationGroupOpen}
			onToggle={(next) => (identificationGroupOpen = next)}
		>
		{#if identificationOpen}
			<section>
				<div class="mb-3 flex flex-wrap items-center justify-between gap-2">
					<h4 class="form-section-title mb-0">Versos y forma</h4>
					{#if identificationResolved && identificationForced}
						<button
							type="button"
							class="link-action"
							onclick={() => (identificationForced = false)}
						>
							Plegar
						</button>
					{/if}
				</div>
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
						<span class="form-label">
							Verso final{hasCalculatedRange ? ' · calculado' : ''}
						</span>
						<input
							type="number"
							min="1"
							class="h-10 w-full border border-[color:var(--border)] px-3 disabled:bg-[color:var(--muted)]"
							value={draft.v_fin}
							onchange={(event) => updateSequenceEnd(Number(event.currentTarget.value))}
							disabled={hasCalculatedRange || isIsolatedVerse}
						/>
					</label>
				</div>

				<div class="mt-3 space-y-3">
					<MetricLengthAlert
						rule={selectedLengthRule}
						start={draft.v_ini}
						end={draft.v_fin}
						configurationName={selectedConfiguration?.nombre}
					/>
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
						{#if draft.forma_id && !isEditorialOutput && configurationsForDraft.length === 1 && selectedConfiguration}
							<div class="form-field">
								<span class="form-label">Arquitectura</span>
								<p class="text-sm leading-10">
									{selectedConfiguration.nombre}
									<span class="text-[color:var(--muted-foreground)]">· única de esta forma</span>
								</p>
							</div>
						{:else if draft.forma_id && !isEditorialOutput}
							<!-- La pregunta la declara la forma; «Arquitectura» es lo que se dice
							     cuando no hay una manera mejor de decirlo. -->
							{@const architectureLabel = `${
								selectedForm?.pregunta_arquitectura?.trim() || 'Arquitectura'
							} *`}
							{@const architectureItems = configurationsForDraft.map(
								(configuration: MetricCatalogConfiguration) => ({
									id: configuration.arquitectura_id,
									label: configuration.nombre
								})
							)}
							<div class="form-field">
								<span class="form-label">{architectureLabel}</span>
								{#if configurationsForDraft.length > 0 && configurationsForDraft.length <= 3 && architectureItems.every((item: { label: string }) => item.label.length <= 28)}
									<SegmentedChoice
										items={architectureItems}
										value={draft.arquitectura_id || null}
										onChange={(id) => resetForConfiguration(id ?? '')}
										ariaLabel={architectureLabel}
									/>
								{:else}
									<select
										class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
										value={draft.arquitectura_id}
										onchange={(event) => resetForConfiguration(event.currentTarget.value)}
									>
										<option value="">Seleccionar arquitectura</option>
										{#each configurationsForDraft as configuration (configuration.arquitectura_id)}
											<option value={configuration.arquitectura_id}>
												{configuration.nombre}
											</option>
										{/each}
									</select>
								{/if}
							</div>
						{:else if selectedForm}
							<div class="bg-amber-50 p-3 text-sm leading-6 text-amber-950">
								<p class="font-medium">Salida editorial, no forma métrica</p>
								<p class="mt-1">{selectedForm.definicion}</p>
							</div>
						{/if}
					</div>
					{#if selectedConfiguration}
						<div class="text-sm leading-6 text-[color:var(--muted-foreground)]">
							{#if selectedConfiguration.descripcion}
								<p>{selectedConfiguration.descripcion}</p>
							{/if}
							{#if unitPlanForDraft && materializedUnitCount > 0}
								<p>
									{#if unitPlanForDraft.extent}
										El rango se guarda como {materializedUnitCount}
										{materializedUnitCount === 1 ? ' unidad' : ' unidades'} de
										{hasDerivedUnitCount
											? `${unitPlanForDraft.extent.minimum} versos`
											: `${unitPlanForDraft.extent.minimum} a ${unitPlanForDraft.extent.maximum} versos`}.
									{:else}
										El pasaje contiene {materializedUnitCount}
										{materializedUnitCount === 1 ? ' unidad' : ' unidades'}; el rango se calcula
										desde sus partes.
									{/if}
								</p>
							{/if}
						</div>
					{/if}
				</div>
			</section>
		{:else}
			<!-- Resuelta, la identificación pesa una línea: el sitio es para las preguntas. -->
			<div
				class="flex flex-wrap items-baseline justify-between gap-3 border border-[color:var(--border)] bg-white px-4 py-2.5 text-sm"
			>
				<span>{identificationSummary}</span>
				<button type="button" class="link-action" onclick={() => (identificationForced = true)}>
					Cambiar versos o forma
				</button>
			</div>
		{/if}

		{#if draft.arquitectura_id}
			{#if hasSequenceChoices}
				<section id="secuencia" class="space-y-4">
					<h4 class="form-section-title mb-0">Datos de esta realización</h4>
					{#each sequenceChoiceGroups as group (String(group.grupo_eleccion_id))}
						<MetricChoiceField
							{group}
							options={optionsForGroup(String(group.grupo_eleccion_id))}
							selectedIds={selectedChoiceIds(String(group.grupo_eleccion_id), null)}
							onChange={(ids) => setChoices(String(group.grupo_eleccion_id), null, ids)}
							textValue={choiceTextValue(String(group.grupo_eleccion_id), null)}
							onTextChange={(value) => setChoiceText(String(group.grupo_eleccion_id), null, value)}
						/>
					{/each}
				</section>
			{/if}

			{#if hasStructuredEditor}
				<section id="estructura" class="space-y-4">
					<h4 class="form-section-title mb-0">Estructura</h4>

					{#key `${draft.secuencia_prueba_id ?? 'nueva'}-${draft.arquitectura_id}`}
						<MetricStructureEditor
							sequenceStart={draft.v_ini}
							sections={sectionsForDraft}
							unitPlan={unitPlanForDraft}
							groups={structureGroups}
							options={choiceOptionsForDraft}
							units={draft.unidades}
							choices={draft.elecciones}
							unitLabel={selectedForm?.nombre}
							globalQuestions={measureGroups.length >= 2 ? compositionMeasure : undefined}
							onUnitsChange={(units) => (draft.unidades = units)}
							onChoicesChange={(choices) => (draft.elecciones = choices)}
							onUnitsRemoved={removeStructuredReferences}
							onRangeChange={(end) => (draft.v_fin = end)}
						/>
					{/key}
				</section>
			{/if}

			{#if draft.desviaciones.length > 0}
				<section
					id="desviaciones"
					class="space-y-4"
				>
					<div class="flex flex-wrap items-center justify-between gap-3">
						<h4 class="form-section-title mb-0">
							<span class="form-label-with-help">
								Desviaciones
								<FieldHelpTooltip
									text="Solo lo que no encaja en ninguna de las respuestas anteriores. Que no haya ninguna significa que la realización cumple la norma, no que falte revisarla."
									label="Ayuda sobre las desviaciones"
								/>
							</span>
						</h4>
						<button type="button" class="link-action" onclick={addDeviation}>Añadir otra</button>
					</div>
					{#each draft.desviaciones as deviation, deviationIndex}
						<div class="grid gap-3 border border-[color:var(--border)] p-4 sm:grid-cols-2 xl:grid-cols-6">
							<label class="form-field">
								<span class="form-label">Dimensión</span>
								<select
									class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm"
									value={deviation.dimension}
									onchange={(event) => {
										const next = event.currentTarget.value as MetricDeviationDimension;
										deviation.dimension = next;
										// Al cambiar de dimensión, la relación elegida puede dejar de
										// aplicar: se sustituye por la primera que sí lo hace. Y el
										// valor observado se vacía, porque pertenecía a la otra.
										deviation.relacion_norma = defaultRelationFor(
											next,
											deviation.relacion_norma
										);
										setObserved(deviation, '');
									}}
								>
									{#each METRIC_DEVIATION_DIMENSIONS as option (option.value)}
										<option value={option.value}>{option.label}</option>
									{/each}
								</select>
							</label>
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
									{#each metricDeviationRelations(deviation.dimension) as option (option.value)}
										<option value={option.value}>{option.label}</option>
									{/each}
								</select>
							</label>
							<!-- Lo observado: la precisión que hace analizable la desviación. Con
							     «Falta» no hay nada que observar, y la base lo exige vacío. -->
							{#if deviation.relacion_norma !== 'falta'}
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
											{#each opciones as option (option.id)}
												<option value={option.id}>{option.label}</option>
											{/each}
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
							<label class="form-field">
								<span class="form-label">V. inicial</span>
								<input
									type="number"
									class="h-10 w-full border border-[color:var(--border)] px-2"
									bind:value={deviation.v_ini}
								/>
							</label>
							<label class="form-field">
								<span class="form-label">V. final</span>
								<input
									type="number"
									class="h-10 w-full border border-[color:var(--border)] px-2"
									bind:value={deviation.v_fin}
								/>
							</label>
							<div class="flex items-end">
								<button
									type="button"
									class="link-action link-action--danger h-10"
									onclick={() => {
										draft.desviaciones = draft.desviaciones.filter(
											(_: MetricDeviationDraft, index: number) => index !== deviationIndex
										);
									}}
								>
									Quitar
								</button>
							</div>
							<label class="form-field sm:col-span-2 xl:col-span-6">
								<span class="form-label">Descripción mínima de la diferencia</span>
								<textarea
									class="min-h-20 w-full border border-[color:var(--border)] p-2"
									bind:value={deviation.observaciones}
								></textarea>
							</label>
						</div>
					{/each}
				</section>
			{/if}

			<!-- Aquí no hay observación libre: lo que el editor quiera anotar sobre esta
			     secuencia va a los comentarios internos, que ya se anclan a ella, se tipifican
			     y pueden hacerse públicos. Duplicarlo aquí partiría el mismo trabajo en dos. -->
		{:else if isEditorialOutput}
			<section id="observaciones">
				<h4 class="form-section-title">Observación opcional</h4>
				<label class="form-field">
					<span class="sr-only">Observación opcional</span>
					<textarea
						class="min-h-24 w-full border border-[color:var(--border)] p-3"
						value={draft.observaciones}
						oninput={(event) => (draft.observaciones = event.currentTarget.value)}
						placeholder={isIsolatedVerse
							? 'Solo si hace falta explicar por qué el verso no se integra en los tramos contiguos.'
							: 'Solo si ayuda a describir por qué no se reconoce una forma del catálogo.'}
					></textarea>
				</label>
			</section>
		{/if}
		</CollapsibleGroup>

		<!-- El resto de la secuencia: no es métrico, pero el editor lo rellena en la misma
		     pasada, así que se ve en el mismo flujo y no en una columna aparte. -->
		{@render props.bodyExtra?.()}
	</div>
</div>

{#snippet compositionMeasure()}
	<div class="form-field">
		<span class="form-label">
			<span class="form-label-with-help">
				Medida de toda la composición
				<FieldHelpTooltip
					text="Lo habitual es que toda la composición use una sola medida. Si alguna sección difiere, ábrelas por sección y corrige solo esa."
					label="Ayuda sobre la medida de toda la composición"
				/>
			</span>
		</span>
		<div class="flex flex-wrap items-center gap-3">
			{#if measureMetres.length > 0 && measureMetres.length <= 4}
				<SegmentedChoice
					items={measureMetres}
					value={uniformMetreId}
					onChange={(id) => id && applyMetreToAllSections(id)}
					ariaLabel="Medida de toda la composición"
				/>
				{#if !measuresFolded && uniformMetreId === null}
					<span class="text-xs text-[color:var(--muted-foreground)]">
						Distintas medidas por sección
					</span>
				{/if}
			{:else}
				<select
					class="h-10 border border-[color:var(--border)] bg-white px-3 text-sm"
					value={uniformMetreId ?? ''}
					onchange={(event) => applyMetreToAllSections(event.currentTarget.value)}
				>
					<option value="">
						{measuresFolded ? 'Seleccionar medida' : 'Distintas medidas por sección'}
					</option>
					{#each measureMetres as metre (metre.id)}
						<option value={metre.id}>{metre.label}</option>
					{/each}
				</select>
			{/if}
			{#if measuresFoldable}
				<button
					type="button"
					class="link-action"
					onclick={() => (showMeasuresBySection = !showMeasuresBySection)}
				>
					{showMeasuresBySection
						? 'Ocultar las medidas por sección'
						: `Ver la medida de cada sección (${measureGroups.length})`}
				</button>
			{/if}
		</div>
	</div>
{/snippet}

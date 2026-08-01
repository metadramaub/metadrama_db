<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { untrack } from 'svelte';
	import ChevronLeft from 'lucide-svelte/icons/chevron-left';
	import ChevronRight from 'lucide-svelte/icons/chevron-right';
	import Pencil from 'lucide-svelte/icons/pencil';
	import Trash2 from 'lucide-svelte/icons/trash-2';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import RangeConsistencyAlert from '$lib/components/editor/RangeConsistencyAlert.svelte';
	import UnsavedChangesModal from '$lib/components/editor/UnsavedChangesModal.svelte';
	import {
		analyzeSequenceRangeConsistency,
		collectRangeConsistencyIds
	} from '$lib/utils/range-consistency';
	import type {
		MetricCatalogConfiguration,
		MetricCatalogDomainRow,
		MetricCatalogForm,
		MetricCatalogPageData,
		MetricLengthRule
	} from '$lib/metrica/catalogo';
	import { metricLengthError } from '$lib/metrica/metric-length';
	import { pushToast } from '$lib/stores/toast';
	import MetricChoiceField from './MetricChoiceField.svelte';
	import MetricLengthAlert from './MetricLengthAlert.svelte';
	import MetricSandboxLegacyFields from './MetricSandboxLegacyFields.svelte';
	import MetricStructureEditor from './MetricStructureEditor.svelte';
	import {
		childrenOfSection,
		ensureRequiredMetricUnits,
		metricUnitPlan,
		reflowMetricUnits,
		sectionId as structuredSectionId,
		sectionLabel as structuredSectionLabel,
		sectionMaximum,
		sectionMinimum,
		sectionVerseMaximum,
		sectionVerseMinimum,
		syncRepeatedMetricUnits,
		syncChoiceMaterializedSections,
		type MetricChoiceDraft,
		type MetricUnitDraft,
		type MetricUnitPlan
	} from './editor-model';

	const props = $props<{ data: MetricCatalogPageData }>();

	type DeviationDraft = {
		realizacion_prueba_id: string | null;
		v_ini: number;
		v_fin: number;
		dimension: 'metro' | 'rima' | 'estructura' | 'repeticion' | 'rasgo' | 'combinacion';
		relacion_norma:
			| 'diferente'
			| 'menor_que_norma'
			| 'mayor_que_norma'
			| 'falta_elemento_esperado'
			| 'aparece_elemento_no_esperado'
			| 'ruptura'
			| 'omision'
			| 'adicion'
			| 'sustitucion'
			| 'otra';
		metro_observado_id: string | null;
		esquema_rima_observado_id: string | null;
		seccion_observada_id: string | null;
		repeticion_observada_id: string | null;
		valor_rasgo_observado_id: string | null;
		observaciones: string;
	};

	type PendingSequenceAction =
		| { kind: 'close' }
		| { kind: 'new' }
		| { kind: 'open'; target: MetricCatalogDomainRow };

	type SequenceDraft = {
		secuencia_prueba_id: string | null;
		escenario_id: string;
		orden: number;
		v_ini: number;
		v_fin: number;
		forma_id: string;
		arquitectura_id: string;
		observaciones: string;
		unidades: MetricUnitDraft[];
		elecciones: MetricChoiceDraft[];
		desviaciones: DeviationDraft[];
	};

	let selectedScenarioId = $state<string | null>(
		untrack(() => String(props.data.editorSandbox.scenarios[0]?.escenario_id ?? '') || null)
	);
	let showNewScenario = $state(false);
	let scenarioName = $state('');
	let scenarioDescription = $state('');
	let scenarioSaving = $state(false);
	let sequenceSaving = $state(false);
	let draft = $state<SequenceDraft | null>(null);
	let errorMessage = $state('');
	// Cómo se abre la secuencia: el panel lateral que ya usa producción o un modal ancho.
	// La prueba consiste justamente en comparar los dos con las mismas preguntas dentro.
	let displayMode = $state<'panel' | 'modal'>('panel');
	let formFilter = $state('');
	let formFilterDraft = $state('');
	let draftBaseline = $state('');
	let pendingAction = $state<PendingSequenceAction | null>(null);
	let showMeasuresBySection = $state(false);
	let observationsOpen = $state(false);

	const scenarios = $derived(props.data.editorSandbox.scenarios);
	const selectedScenario = $derived(
		scenarios.find(
			(row: MetricCatalogDomainRow) => String(row.escenario_id) === selectedScenarioId
		) ?? null
	);
	const scenarioSequences = $derived(
		props.data.editorSandbox.sequences
			.filter(
				(row: MetricCatalogDomainRow) => String(row.escenario_id) === selectedScenarioId
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.orden) - Number(b.orden)
			)
	);
	const activeForms = $derived(
		props.data.forms
			.filter((form: MetricCatalogForm) => form.activo && form.seleccionable)
			.sort((a: MetricCatalogForm, b: MetricCatalogForm) =>
				a.nombre.localeCompare(b.nombre, 'es')
			)
	);
	const metricForms = $derived(
		activeForms.filter((form: MetricCatalogForm) => form.tipo_registro === 'forma')
	);
	const editorialOutputs = $derived(
		activeForms.filter(
			(form: MetricCatalogForm) => form.tipo_registro === 'sin_forma'
		)
	);
	const configurationsForDraft = $derived(
		draft
			? props.data.configurations.filter(
					(configuration: MetricCatalogConfiguration) =>
						configuration.forma_id === draft?.forma_id && configuration.activo
				)
			: []
	);
	const selectedForm = $derived(
		draft
			? props.data.forms.find(
					(form: MetricCatalogForm) => form.forma_id === draft?.forma_id
				) ?? null
			: null
	);
	const selectedConfiguration = $derived(
		draft
			? props.data.configurations.find(
					(configuration: MetricCatalogConfiguration) =>
						configuration.arquitectura_id === draft?.arquitectura_id
				) ?? null
			: null
	);
	const isEditorialOutput = $derived(selectedForm?.tipo_registro === 'sin_forma');
	const isIsolatedVerse = $derived(selectedForm?.slug === 'verso_aislado');
	const selectedLengthRule = $derived(
		draft
			? props.data.lengthRules.find(
					(rule: MetricLengthRule) => rule.arquitectura_id === draft?.arquitectura_id
				) ?? null
			: null
	);
	const sectionsForDraft = $derived(
		draft
			? props.data.domain.sections
					.filter(
						(row: MetricCatalogDomainRow) =>
							row.arquitectura_id === draft?.arquitectura_id
					)
					.sort(
						(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
							Number(a.orden ?? 999) - Number(b.orden ?? 999)
					)
			: []
	);
	const choiceGroupsForDraft = $derived(
		draft
			? props.data.domain.choiceGroups
					.filter(
						(row: MetricCatalogDomainRow) =>
							row.arquitectura_id === draft?.arquitectura_id && row.activo
					)
					.sort(
						(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
							Number(a.orden ?? 999) - Number(b.orden ?? 999)
					)
			: []
	);
	const sequenceChoiceGroups = $derived(
		choiceGroupsForDraft.filter(
			(row: MetricCatalogDomainRow) => row.alcance === 'secuencia'
		)
	);
	const unitChoiceGroups = $derived(
		choiceGroupsForDraft.filter((row: MetricCatalogDomainRow) => row.alcance === 'unidad')
	);
	const choiceOptionsForDraft = $derived(
		props.data.domain.choiceOptions.filter(
			(row: MetricCatalogDomainRow) =>
				row.activo &&
				choiceGroupsForDraft.some(
					(group: MetricCatalogDomainRow) =>
						group.grupo_eleccion_id === row.grupo_eleccion_id
				)
		)
	);
	// La unidad que declara la arquitectura: cuántas contiene el pasaje se deriva del rango,
	// no de ninguna sección que exista para decir que la unidad se repite.
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
		draft && unitPlanForDraft
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
	const draftSummary = $derived.by(() => {
		if (!draft) return '';
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

	const orderedSequences = $derived(
		[...scenarioSequences].sort(
			(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
				Number(a.v_ini) - Number(b.v_ini) || Number(a.v_fin) - Number(b.v_fin)
		)
	);
	const filteredSequences = $derived(
		formFilter
			? orderedSequences.filter(
					(row: MetricCatalogDomainRow) => String(row.forma_id) === formFilter
				)
			: orderedSequences
	);
	const formFilterItems = $derived(
		activeForms.map((form: MetricCatalogForm) => ({
			id: form.forma_id,
			label: form.nombre
		}))
	);
	const sequenceOverlapIssues = $derived(
		analyzeSequenceRangeConsistency(
			orderedSequences.map((row: MetricCatalogDomainRow) => ({
				secuencia_id: String(row.secuencia_prueba_id),
				v_ini: Number(row.v_ini),
				v_fin: Number(row.v_fin)
			}))
		)
	);
	const sequenceOverlapIds = $derived(collectRangeConsistencyIds(sequenceOverlapIssues));
	const scenarioLastVerse = $derived(
		orderedSequences.reduce(
			(maximum: number, row: MetricCatalogDomainRow) => Math.max(maximum, Number(row.v_fin)),
			0
		)
	);
	const declaredVerses = $derived(
		filteredSequences.reduce(
			(total: number, row: MetricCatalogDomainRow) =>
				total + (Number(row.v_fin) - Number(row.v_ini) + 1),
			0
		)
	);
	// Réplica del índice de estructura: el escenario no tiene jornadas ni cuadros, así que se
	// reparte su extensión en tres tramos solo para ocupar el mismo hueco que en producción.
	const mockJornadas = $derived.by(() => {
		if (scenarioLastVerse < 3) return [];
		const size = Math.ceil(scenarioLastVerse / 3);
		return [1, 2, 3]
			.map((numero) => ({
				numero,
				v_ini: (numero - 1) * size + 1,
				v_fin: Math.min(scenarioLastVerse, numero * size)
			}))
			.filter((jornada) => jornada.v_ini <= jornada.v_fin);
	});
	const versesDifference = $derived(
		scenarioLastVerse === 0 ? null : scenarioLastVerse - declaredVerses
	);
	const draftDirty = $derived(draft !== null && JSON.stringify(draft) !== draftBaseline);
	const editingIndex = $derived(
		draft?.secuencia_prueba_id
			? orderedSequences.findIndex(
					(row: MetricCatalogDomainRow) =>
						String(row.secuencia_prueba_id) === draft?.secuencia_prueba_id
				)
			: -1
	);
	const previousSequence = $derived(
		editingIndex > 0 ? orderedSequences[editingIndex - 1] : null
	);
	const nextSequence = $derived(
		editingIndex >= 0 && editingIndex < orderedSequences.length - 1
			? orderedSequences[editingIndex + 1]
			: null
	);

	$effect(() => {
		if (
			selectedScenarioId &&
			scenarios.some(
				(row: MetricCatalogDomainRow) => String(row.escenario_id) === selectedScenarioId
			)
		) {
			return;
		}
		selectedScenarioId = String(scenarios[0]?.escenario_id ?? '') || null;
		draft = null;
	});

	function cleanText(value: string): string | null {
		const cleaned = value.trim();
		return cleaned || null;
	}

	function formLabel(id: string): string {
		return props.data.forms.find((form: MetricCatalogForm) => form.forma_id === id)?.nombre ?? id;
	}

	function configurationLabel(id: string): string {
		return (
			props.data.configurations.find(
				(configuration: MetricCatalogConfiguration) => configuration.arquitectura_id === id
			)?.nombre ?? id
		);
	}

	function sectionLabel(id: string): string {
		const row = props.data.domain.sections.find(
			(section: MetricCatalogDomainRow) => String(section.seccion_id) === id
		);
		return String(row?.nombre || row?.tipo_seccion || id);
	}

	function optionsForGroup(groupId: string): MetricCatalogDomainRow[] {
		return props.data.domain.choiceOptions
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
		if (!draft) return [];
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
		if (!draft) return '';
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
		if (!draft) return;
		draft.elecciones = [
			...draft.elecciones.filter(
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

	function setChoiceText(groupId: string, unitId: string | null, value: string) {
		if (!draft) return;
		const normalized = normalizeRhymeScheme(value);
		draft.elecciones = [
			...draft.elecciones.filter(
				(choice: MetricChoiceDraft) =>
					!(
						choice.grupo_eleccion_id === groupId &&
						choice.realizacion_prueba_id === unitId
					)
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
		if (!draft) return 0;
		return draft.elecciones.filter(
			(choice: MetricChoiceDraft) =>
				choice.grupo_eleccion_id === groupId &&
				choice.realizacion_prueba_id === unitId
		).length;
	}

	/** Las realizaciones a las que se dirige una pregunta por unidad. */
	function unitsForGroup(group: MetricCatalogDomainRow): MetricUnitDraft[] {
		if (!draft) return [];
		return draft.unidades.filter((unit: MetricUnitDraft) =>
			group.seccion_id
				? String(group.seccion_id) === unit.seccion_id
				: unit.realizacion_padre_id === null
		);
	}

	/** Responde de una vez la medida de todas las secciones con versos. */
	function applyMetreToAllSections(metreId: string) {
		if (!draft || !metreId) return;
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

	function catalogParts(configurationId: string) {
		const sections = props.data.domain.sections.filter(
			(row: MetricCatalogDomainRow) => row.arquitectura_id === configurationId
		);
		const groups = props.data.domain.choiceGroups.filter(
			(row: MetricCatalogDomainRow) =>
				row.arquitectura_id === configurationId && row.activo
		);
		const groupIds = new Set(
			groups.map((group: MetricCatalogDomainRow) => String(group.grupo_eleccion_id))
		);
		const options = props.data.domain.choiceOptions.filter(
			(row: MetricCatalogDomainRow) =>
				row.activo && groupIds.has(String(row.grupo_eleccion_id))
		);
		return { sections, groups, options };
	}

	function unitPlanFor(
		configurationId: string,
		sections: MetricCatalogDomainRow[]
	): MetricUnitPlan | null {
		const configuration =
			props.data.configurations.find(
				(row: MetricCatalogConfiguration) => row.arquitectura_id === configurationId
			) ?? null;
		const form = configuration
			? (props.data.forms.find(
					(row: MetricCatalogForm) => row.forma_id === configuration.forma_id
				) ?? null)
			: null;
		return metricUnitPlan(configuration, sections, form?.nivel_estructural);
	}

	/** Materializa las secciones que una respuesta por unidad hace aparecer. */
	function applyMaterializedSections(
		units: MetricUnitDraft[],
		sections: MetricCatalogDomainRow[],
		groups: MetricCatalogDomainRow[],
		options: MetricCatalogDomainRow[],
		choices: MetricChoiceDraft[],
		sequenceStart: number
	): MetricUnitDraft[] {
		let next = units;
		for (const group of groups.filter(
			(row: MetricCatalogDomainRow) => row.alcance === 'unidad'
		)) {
			const groupId = String(group.grupo_eleccion_id);
			const groupOptions = options.filter(
				(option: MetricCatalogDomainRow) => String(option.grupo_eleccion_id) === groupId
			);
			if (!groupOptions.some((option) => option.materializa_seccion_id)) continue;
			for (const unit of [...next]) {
				const applies = group.seccion_id
					? String(group.seccion_id) === unit.seccion_id
					: unit.realizacion_padre_id === null;
				if (!applies) continue;
				const selected = choices
					.filter(
						(choice: MetricChoiceDraft) =>
							choice.grupo_eleccion_id === groupId &&
							choice.realizacion_prueba_id === unit.realizacion_prueba_id &&
							Boolean(choice.opcion_eleccion_id)
					)
					.map((choice: MetricChoiceDraft) => choice.opcion_eleccion_id as string);
				next = syncChoiceMaterializedSections(
					next,
					sections,
					unit.realizacion_prueba_id,
					groupOptions,
					selected,
					sequenceStart,
					choices,
					options
				);
			}
		}
		return next;
	}

	function normalizeStructuredUnits(
		units: MetricUnitDraft[],
		choices: MetricChoiceDraft[],
		configurationId: string,
		sequenceStart: number,
		sequenceEnd: number
	): MetricUnitDraft[] {
		const { sections, groups, options } = catalogParts(configurationId);
		const plan = unitPlanFor(configurationId, sections);
		if (!plan) return units;

		let next: MetricUnitDraft[];
		if (plan.countFromRange) {
			// La unidad es fija: el rango dice cuántas hay.
			const synchronized = syncRepeatedMetricUnits(
				units,
				sections,
				plan.extent,
				sequenceStart,
				sequenceEnd,
				choices,
				options
			);
			if (synchronized.compatible) {
				next = synchronized.units;
			} else if (units.length > 0) {
				next = reflowMetricUnits(units, sections, sequenceStart, choices, options);
			} else {
				next = syncRepeatedMetricUnits(
					units,
					sections,
					plan.extent,
					sequenceStart,
					sequenceStart + (plan.extent?.minimum ?? 1) - 1,
					choices,
					options
				).units;
			}
		} else {
			// La unidad no tiene extensión fija: cuántas hay lo decide el editor.
			next = ensureRequiredMetricUnits(
				units,
				sections,
				plan.extent,
				sequenceStart,
				choices,
				options
			);
		}

		next = applyMaterializedSections(next, sections, groups, options, choices, sequenceStart);
		return reflowMetricUnits(next, sections, sequenceStart, choices, options);
	}

	function resetForConfiguration(configurationId: string) {
		if (!draft) return;
		showMeasuresBySection = false;
		draft.arquitectura_id = configurationId;
		const previousLength = Math.max(1, draft.v_fin - draft.v_ini + 1);
		draft.unidades = normalizeStructuredUnits(
			[],
			[],
			configurationId,
			draft.v_ini,
			draft.v_fin
		);
		draft.elecciones = [];
		draft.desviaciones = [];
		const parts = catalogParts(configurationId);
		const plan = unitPlanFor(configurationId, parts.sections);
		if (
			plan &&
			(!plan.countFromRange || previousLength < (plan.extent?.minimum ?? 1))
		) {
			draft.v_fin = draft.unidades.reduce(
				(maximum: number, unit: MetricUnitDraft) => Math.max(maximum, unit.v_fin),
				draft.v_ini
			);
		}
	}

	function changeForm(formId: string) {
		if (!draft) return;
		draft.forma_id = formId;
		const form = props.data.forms.find(
			(item: MetricCatalogForm) => item.forma_id === formId
		);
		if (form?.tipo_registro === 'sin_forma') {
			resetForConfiguration('');
			if (form.slug === 'verso_aislado') {
				draft.v_fin = draft.v_ini;
			} else if (form.slug === 'irregular' && draft.v_fin === draft.v_ini) {
				draft.v_fin = draft.v_ini + 1;
			}
			return;
		}
		const configurations = props.data.configurations.filter(
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

	function openNewSequence() {
		if (!selectedScenarioId) return;
		const previous = scenarioSequences.at(-1);
		const nextVerse = previous ? Number(previous.v_fin) + 1 : 1;
		draft = {
			secuencia_prueba_id: null,
			escenario_id: selectedScenarioId,
			orden:
				scenarioSequences.reduce(
					(max: number, row: MetricCatalogDomainRow) => Math.max(max, Number(row.orden)),
					0
				) + 1,
			v_ini: nextVerse,
			v_fin: nextVerse,
			forma_id: '',
			arquitectura_id: '',
			observaciones: '',
			unidades: [],
			elecciones: [],
			desviaciones: []
		};
		draftBaseline = JSON.stringify(draft);
		showMeasuresBySection = false;
		observationsOpen = false;
		errorMessage = '';
	}

	function openSequence(row: MetricCatalogDomainRow) {
		const sequenceId = String(row.secuencia_prueba_id);
		draft = {
			secuencia_prueba_id: sequenceId,
			escenario_id: String(row.escenario_id),
			orden: Number(row.orden),
			v_ini: Number(row.v_ini),
			v_fin: Number(row.v_fin),
			forma_id: String(row.forma_id),
			arquitectura_id: row.arquitectura_id ? String(row.arquitectura_id) : '',
			observaciones: String(row.observaciones ?? ''),
			unidades: props.data.editorSandbox.units
				.filter(
					(unit: MetricCatalogDomainRow) =>
						String(unit.secuencia_prueba_id) === sequenceId
				)
				.map((unit: MetricCatalogDomainRow) => ({
					realizacion_prueba_id: String(unit.realizacion_prueba_id),
					realizacion_padre_id: unit.realizacion_padre_id ? String(unit.realizacion_padre_id) : null,
					seccion_id: String(unit.seccion_id),
					orden: Number(unit.orden),
					v_ini: Number(unit.v_ini),
					v_fin: Number(unit.v_fin),
					etiqueta: String(unit.etiqueta ?? ''),
					observaciones: String(unit.observaciones ?? '')
				})),
			elecciones: props.data.editorSandbox.choices
				.filter(
					(choice: MetricCatalogDomainRow) =>
						String(choice.secuencia_prueba_id) === sequenceId
				)
				.map((choice: MetricCatalogDomainRow) => ({
					realizacion_prueba_id: choice.realizacion_prueba_id
						? String(choice.realizacion_prueba_id)
						: null,
					grupo_eleccion_id: String(choice.grupo_eleccion_id),
					opcion_eleccion_id: choice.opcion_eleccion_id
						? String(choice.opcion_eleccion_id)
						: null,
					valor_texto: choice.valor_texto ? String(choice.valor_texto) : null,
					observaciones: choice.observaciones ? String(choice.observaciones) : null
				})),
			desviaciones: props.data.editorSandbox.deviations
				.filter(
					(deviation: MetricCatalogDomainRow) =>
						String(deviation.secuencia_prueba_id) === sequenceId
				)
				.map((deviation: MetricCatalogDomainRow) => ({
					realizacion_prueba_id: deviation.realizacion_prueba_id
						? String(deviation.realizacion_prueba_id)
						: null,
					v_ini: Number(deviation.v_ini),
					v_fin: Number(deviation.v_fin),
					dimension: deviation.dimension as DeviationDraft['dimension'],
					relacion_norma:
						deviation.relacion_norma as DeviationDraft['relacion_norma'],
					metro_observado_id: deviation.metro_observado_id
						? String(deviation.metro_observado_id)
						: null,
					esquema_rima_observado_id: deviation.esquema_rima_observado_id
						? String(deviation.esquema_rima_observado_id)
						: null,
					seccion_observada_id: deviation.seccion_observada_id
						? String(deviation.seccion_observada_id)
						: null,
					repeticion_observada_id:
						deviation.repeticion_observada_id
							? String(deviation.repeticion_observada_id)
							: null,
					valor_rasgo_observado_id: deviation.valor_rasgo_observado_id
						? String(deviation.valor_rasgo_observado_id)
						: null,
					observaciones: String(deviation.observaciones ?? '')
				}))
		};
		draft.unidades = normalizeStructuredUnits(
			draft.unidades,
			draft.elecciones,
			draft.arquitectura_id,
			draft.v_ini,
			draft.v_fin
		);
		const openedSections = catalogParts(draft.arquitectura_id).sections;
		const openedPlan = unitPlanFor(draft.arquitectura_id, openedSections);
		if (openedPlan !== null && !openedPlan.countFromRange) {
			draft.v_fin = draft.unidades.reduce(
				(maximum: number, unit: MetricUnitDraft) => Math.max(maximum, unit.v_fin),
				draft.v_ini
			);
		}
		draftBaseline = JSON.stringify(draft);
		showMeasuresBySection = false;
		observationsOpen = Boolean(draft.observaciones);
		errorMessage = '';
	}

	/**
	 * Salir de una secuencia con cambios pendientes pregunta antes, como en producción: es
	 * parte de lo que se está midiendo, porque el formulario nuevo es mucho más largo.
	 */
	function requestNewSequence() {
		if (draftDirty) {
			pendingAction = { kind: 'new' };
			return;
		}
		openNewSequence();
	}

	function requestOpenSequence(row: MetricCatalogDomainRow) {
		if (String(row.secuencia_prueba_id) === draft?.secuencia_prueba_id) return;
		if (draftDirty) {
			pendingAction = { kind: 'open', target: row };
			return;
		}
		openSequence(row);
	}

	function requestCloseSequence() {
		if (draftDirty) {
			pendingAction = { kind: 'close' };
			return;
		}
		draft = null;
	}

	function runPendingAction() {
		const action = pendingAction;
		pendingAction = null;
		if (!action) return;
		if (action.kind === 'close') draft = null;
		else if (action.kind === 'new') openNewSequence();
		else openSequence(action.target);
	}

	async function savePendingAction() {
		await saveSequence();
		if (errorMessage) return;
		runPendingAction();
	}

	function addDeviation() {
		if (!draft) return;
		draft.desviaciones = [
			...draft.desviaciones,
			{
				realizacion_prueba_id: null,
				v_ini: draft.v_ini,
				v_fin: draft.v_fin,
				dimension: 'metro',
				relacion_norma: 'diferente',
				metro_observado_id: null,
				esquema_rima_observado_id: null,
				seccion_observada_id: null,
				repeticion_observada_id: null,
				valor_rasgo_observado_id: null,
				observaciones: ''
			}
		];
	}

	function updateSequenceStart(value: number) {
		if (!draft) return;
		const previousLength = draft.v_fin - draft.v_ini + 1;
		draft.v_ini = Math.max(1, value);
		if (isIsolatedVerse) {
			draft.v_fin = draft.v_ini;
			return;
		}
		if (hasDerivedUnitCount) {
			draft.v_fin = draft.v_ini + previousLength - 1;
			const { sections, options } = catalogParts(draft.arquitectura_id);
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
		if (!draft) return;
		if (isIsolatedVerse) {
			draft.v_fin = draft.v_ini;
			return;
		}
		draft.v_fin = Math.max(1, value);
		if (!hasDerivedUnitCount) return;
		const { sections, options } = catalogParts(draft.arquitectura_id);
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
		if (!draft || unitIds.length === 0) return;
		const removed = new Set(unitIds);
		draft.elecciones = draft.elecciones.filter(
			(choice: MetricChoiceDraft) =>
				!choice.realizacion_prueba_id || !removed.has(choice.realizacion_prueba_id)
		);
		draft.desviaciones = draft.desviaciones.map((deviation: DeviationDraft) =>
			deviation.realizacion_prueba_id && removed.has(deviation.realizacion_prueba_id)
				? { ...deviation, realizacion_prueba_id: null }
				: deviation
		);
	}

	function validateDraft(): string | null {
		if (!draft) return 'No hay ninguna secuencia abierta.';
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
			if (
				total < Number(group.selecciones_min) ||
				total > Number(group.selecciones_max)
			) {
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
				const selectedIds = selectedChoiceIds(
					String(group.grupo_eleccion_id),
					unit.realizacion_prueba_id
				);
				const total = choiceCount(
					String(group.grupo_eleccion_id),
					unit.realizacion_prueba_id
				);
				if (
					total < Number(group.selecciones_min) ||
					total > Number(group.selecciones_max)
				) {
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
							? `Responde «${String(group.nombre)}»: vale para toda la composición.`
							: `Responde «${String(group.nombre)}».`;
					}
					return `Revisa «${String(group.nombre)}» en la unidad ${unit.orden}.`;
				}
				const selectedPositions = choiceOptionsForDraft
					.filter(
						(option: MetricCatalogDomainRow) =>
							selectedIds.includes(String(option.opcion_eleccion_id)) &&
							Number(option.posicion_unidad ?? 0) > 0
					)
					.map((option: MetricCatalogDomainRow) => Number(option.posicion_unidad));
				const unitLength = unit.v_fin - unit.v_ini + 1;
				const visiblePositionalOptions = choiceOptionsForDraft.filter(
					(option: MetricCatalogDomainRow) =>
						String(option.grupo_eleccion_id) === String(group.grupo_eleccion_id) &&
						Number(option.posicion_unidad ?? 0) > 0 &&
						Number(option.posicion_unidad) <= unitLength
				);
				const hasAlternativesByPosition = visiblePositionalOptions.some(
					(option: MetricCatalogDomainRow, index: number, options: MetricCatalogDomainRow[]) =>
						options.findIndex(
							(candidate: MetricCatalogDomainRow) =>
								Number(candidate.posicion_unidad) === Number(option.posicion_unidad)
						) !== index
				);
				if (selectedPositions.some((position: number) => position > unitLength)) {
					return `Revisa las posiciones de «${String(group.nombre)}» en la unidad ${unit.orden}.`;
				}
				if (
					hasAlternativesByPosition &&
					(new Set(selectedPositions).size !== unitLength ||
						selectedPositions.length !== unitLength)
				) {
					return `Indica la medida de cada verso en «${String(group.nombre)}» para la unidad ${unit.orden}.`;
				}
				if (
					String(group.slug).startsWith('posiciones_pie') &&
					selectedPositions.length >= unitLength
				) {
					return `Debe quedar al menos un octosílabo en la unidad ${unit.orden}.`;
				}
			}
			if (Number(group.selecciones_min) > 0 && applicableUnits.length === 0) {
				return `Añade al menos una unidad «${sectionLabel(String(group.seccion_id))}» para responder «${String(group.nombre)}».`;
			}
		}
		for (const deviation of draft.desviaciones) {
			if (
				deviation.v_fin < deviation.v_ini ||
				deviation.v_ini < draft.v_ini ||
				deviation.v_fin > draft.v_fin
			) {
				return 'Todas las desviaciones deben quedar dentro del rango de la secuencia.';
			}
		}
		return null;
	}

	async function callApi(body: Record<string, unknown>) {
		const response = await fetch('/api/metrica/editor-pruebas', {
			method: 'POST',
			headers: { 'content-type': 'application/json' },
			body: JSON.stringify(body)
		});
		const payload = await response.json().catch(() => ({}));
		if (!response.ok) {
			throw new Error(payload.message ?? 'No se pudo completar la operación.');
		}
		return payload;
	}

	async function createScenario() {
		if (!scenarioName.trim() || scenarioSaving) return;
		scenarioSaving = true;
		errorMessage = '';
		try {
			const payload = await callApi({
				action: 'create_scenario',
				nombre: scenarioName.trim(),
				descripcion: cleanText(scenarioDescription)
			});
			selectedScenarioId = String(payload.scenario.escenario_id);
			scenarioName = '';
			scenarioDescription = '';
			showNewScenario = false;
			pushToast('success', 'Escenario de prueba creado.');
			await invalidateAll();
		} catch (error) {
			errorMessage = error instanceof Error ? error.message : 'No se pudo crear el escenario.';
		} finally {
			scenarioSaving = false;
		}
	}

	async function deleteScenario() {
		if (!selectedScenarioId || !selectedScenario || scenarioSaving) return;
		if (
			!window.confirm(
				`¿Eliminar el escenario «${String(selectedScenario.nombre)}» y todas sus pruebas?`
			)
		) {
			return;
		}
		scenarioSaving = true;
		try {
			await callApi({ action: 'delete_scenario', escenario_id: selectedScenarioId });
			selectedScenarioId = null;
			draft = null;
			pushToast('success', 'Escenario eliminado.');
			await invalidateAll();
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'No se pudo eliminar el escenario.';
		} finally {
			scenarioSaving = false;
		}
	}

	async function saveSequence() {
		const validation = validateDraft();
		if (validation || !draft || sequenceSaving) {
			if (validation) errorMessage = validation;
			return;
		}
		sequenceSaving = true;
		errorMessage = '';
		try {
			const payload = await callApi({
				action: 'save_sequence',
				...draft,
				arquitectura_id: draft.arquitectura_id || null,
				observaciones: cleanText(draft.observaciones),
				unidades: draft.unidades.map((unit: MetricUnitDraft) => ({
					...unit,
					etiqueta: cleanText(unit.etiqueta),
					observaciones: cleanText(unit.observaciones)
				})),
				desviaciones: draft.desviaciones.map((deviation: DeviationDraft) => ({
					...deviation,
					observaciones: cleanText(deviation.observaciones)
				}))
			});
			const savedId = String(payload.secuencia_prueba_id);
			draft.secuencia_prueba_id = savedId;
			draftBaseline = JSON.stringify(draft);
			pushToast('success', 'Secuencia métrica de prueba guardada.');
			await invalidateAll();
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'No se pudo guardar la secuencia.';
		} finally {
			sequenceSaving = false;
		}
	}

	async function deleteSequenceById(sequenceId: string) {
		if (!sequenceId || sequenceSaving) return;
		if (!window.confirm('¿Eliminar esta secuencia métrica de prueba?')) return;
		sequenceSaving = true;
		try {
			await callApi({
				action: 'delete_sequence',
				secuencia_prueba_id: sequenceId
			});
			if (draft?.secuencia_prueba_id === sequenceId) draft = null;
			pushToast('success', 'Secuencia de prueba eliminada.');
			await invalidateAll();
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'No se pudo eliminar la secuencia.';
		} finally {
			sequenceSaving = false;
		}
	}
</script>
<section class="space-y-5">
	<div class="border-l-4 border-sky-500 bg-sky-50 p-5 text-sm leading-6 text-sky-950">
		<h2 class="font-semibold">Laboratorio del editor de secuencias</h2>
		<p class="mt-1 max-w-5xl">
			Estos escenarios no son obras y no aparecen en el dashboard de producción. La pantalla
			imita el editor real —tabla de secuencias, índice de estructura y panel lateral— para
			comprobar cuánto ocupa en él la nueva forma de declarar la métrica. Los bloques marcados
			como «réplica» están solo para ocupar su sitio: no se guardan.
		</p>
	</div>

	<div class="flex flex-col gap-3 border border-[color:var(--border)] bg-[color:var(--card)] p-4 lg:flex-row lg:items-end">
		<label class="min-w-0 flex-1">
			<span class="form-label">Escenario de prueba</span>
			<select
				class="mt-1 h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
				value={selectedScenarioId ?? ''}
				onchange={(event) => {
					selectedScenarioId = event.currentTarget.value || null;
					draft = null;
				}}
			>
				<option value="">Seleccionar escenario</option>
				{#each scenarios as scenario (String(scenario.escenario_id))}
					<option value={String(scenario.escenario_id)}>{String(scenario.nombre)}</option>
				{/each}
			</select>
		</label>
		<div class="form-field">
			<span class="form-label">Dónde se abre la secuencia</span>
			<div class="inline-flex" role="radiogroup" aria-label="Dónde se abre la secuencia">
				{#each [{ id: 'panel', label: 'Panel lateral' }, { id: 'modal', label: 'Modal ancho' }] as option}
					<button
						type="button"
						role="radio"
						aria-checked={displayMode === option.id}
						class={`relative -ml-px border px-3 py-1.5 text-sm font-medium transition-colors first:ml-0 ${
							displayMode === option.id
								? 'z-10 border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--primary-foreground)]'
								: 'border-[color:var(--border)] bg-white text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)]'
						}`}
						onclick={() => (displayMode = option.id as 'panel' | 'modal')}
					>
						{option.label}
					</button>
				{/each}
			</div>
		</div>
		<div class="flex gap-2">
			<Button variant="secondary" onclick={() => (showNewScenario = !showNewScenario)}>
				{showNewScenario ? 'Cancelar' : 'Nuevo escenario'}
			</Button>
			{#if selectedScenario}
				<Button variant="danger" onclick={deleteScenario} disabled={scenarioSaving}>
					Eliminar escenario
				</Button>
			{/if}
		</div>
	</div>

	{#if showNewScenario}
		<div class="grid gap-3 border border-[color:var(--border)] bg-[color:var(--card)] p-4">
			<label class="form-field">
				<span class="form-label">Nombre *</span>
				<input class="h-10 border border-[color:var(--border)] px-3" bind:value={scenarioName} />
			</label>
			<label class="form-field">
				<span class="form-label">Qué quieres comprobar</span>
				<textarea class="min-h-24 border border-[color:var(--border)] p-3" bind:value={scenarioDescription}></textarea>
			</label>
			<div>
				<Button variant="success" onclick={createScenario} disabled={scenarioSaving || !scenarioName.trim()}>
					{scenarioSaving ? 'Creando…' : 'Crear escenario'}
				</Button>
			</div>
		</div>
	{/if}

	{#if errorMessage && !draft}
		<p class="border-l-4 border-red-500 bg-red-50 p-3 text-sm text-red-900">{errorMessage}</p>
	{/if}

	{#if selectedScenario}
		<div class="flex flex-wrap items-end justify-between gap-3 pb-1 pt-2">
			<div>
				<h3 class="text-lg font-semibold">Secuencias métricas</h3>
				<p class="text-xs text-[color:var(--muted-foreground)]">
					{String(selectedScenario.nombre)} · {orderedSequences.length}
					{orderedSequences.length === 1 ? 'secuencia' : 'secuencias'}
				</p>
			</div>
			<div class="flex flex-wrap items-end gap-2">
				<div class="w-56">
					<CheckDropdown
						multiple={false}
						search={true}
						allowSingleClear={true}
						closeOnSelect={false}
						placeholder="Filtrar por forma"
						items={formFilterItems}
						selectedIds={formFilterDraft ? [formFilterDraft] : []}
						onChange={(ids) => {
							formFilterDraft = ids[0] ?? '';
						}}
					/>
				</div>
				<Button variant="secondary" onclick={() => (formFilter = formFilterDraft)}>Filtrar</Button>
				<Button
					variant="ghost"
					onclick={() => {
						formFilterDraft = '';
						formFilter = '';
					}}
					disabled={!formFilter && !formFilterDraft}
				>
					Limpiar
				</Button>
				<Button variant="primary-soft" onclick={requestNewSequence}>Nueva secuencia</Button>
			</div>
		</div>

		<RangeConsistencyAlert issues={sequenceOverlapIssues} />

		<div class="lg:grid lg:grid-cols-[15rem_minmax(0,1fr)] lg:gap-4">
			<aside class="secuencias-structure-index hidden lg:sticky lg:top-4 lg:block lg:h-fit lg:self-start">
				<div class="card secuencias-structure-index__head">Índice de estructura · réplica</div>
				{#if mockJornadas.length === 0}
					<p class="card secuencias-structure-index__empty-text">Sin estructura registrada.</p>
				{:else}
					<ul class="card secuencias-structure-list">
						{#each mockJornadas as jornada (jornada.numero)}
							<li class="secuencias-structure-list__item">
								<p class="secuencias-structure-list__jornada">
									Jornada {jornada.numero}
									<span>(vv. {jornada.v_ini}-{jornada.v_fin})</span>
								</p>
								<ul class="secuencias-structure-sublist">
									<li class="secuencias-structure-sublist__item">
										Cuadro 1 (vv. {jornada.v_ini}-{jornada.v_fin})
									</li>
								</ul>
							</li>
						{/each}
					</ul>
				{/if}
				<div class="card mt-4 space-y-2">
					<Button variant="primary" class="w-full" disabled>Leer sinopsis completa</Button>
					<p class="text-xs text-[color:var(--muted-foreground)]">
						Réplica: en producción abre la sinopsis de toda la obra.
					</p>
				</div>
				<div class="mt-4">
					<Button variant="primary-soft" class="w-full" onclick={requestNewSequence}>
						Nueva secuencia
					</Button>
				</div>
			</aside>

			<div class="space-y-2">
				<div class="card overflow-x-auto">
					<table class="min-w-full text-left text-sm">
						<thead class="bg-[color:var(--muted)]">
							<tr>
								<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">#</th>
								<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">V_ini</th>
								<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">V_fin</th>
								<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">N_versos</th>
								<th class="sticky top-0 z-10 bg-[color:var(--muted)] px-3 py-2">Forma</th>
								<th class="sticky top-0 z-10 w-28 bg-[color:var(--muted)] px-3 py-2">
									<span class="sr-only">Acciones</span>
								</th>
							</tr>
						</thead>
						<tbody>
							{#each filteredSequences as sequence, index (String(sequence.secuencia_prueba_id))}
								<tr
									class={`border-t ${
										sequenceOverlapIds.has(String(sequence.secuencia_prueba_id))
											? 'border-[color:var(--danger)] bg-red-50'
											: 'border-[color:var(--border)]'
									} ${
										draft?.secuencia_prueba_id === String(sequence.secuencia_prueba_id)
											? 'bg-[color:var(--muted)]'
											: ''
									}`}
								>
									<td class="px-3 py-2">{index + 1}</td>
									<td class="px-3 py-2">{Number(sequence.v_ini)}</td>
									<td class="px-3 py-2">{Number(sequence.v_fin)}</td>
									<td class="px-3 py-2">
										{Number(sequence.v_fin) - Number(sequence.v_ini) + 1}
									</td>
									<td class="px-3 py-2">
										<span class="block">{formLabel(String(sequence.forma_id))}</span>
										{#if sequence.arquitectura_id}
											<span class="block text-xs text-[color:var(--muted-foreground)]">
												{configurationLabel(String(sequence.arquitectura_id))}
											</span>
										{/if}
									</td>
									<td class="px-3 py-2">
										<div class="flex items-center justify-end gap-1">
											<button
												type="button"
												class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--success)] disabled:opacity-40"
												aria-label="Editar secuencia"
												onclick={() => requestOpenSequence(sequence)}
												disabled={sequenceSaving}
											>
												<Pencil size={16} />
											</button>
											<button
												type="button"
												class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--danger)] disabled:opacity-40"
												aria-label="Eliminar secuencia"
												onclick={() =>
													void deleteSequenceById(String(sequence.secuencia_prueba_id))}
												disabled={sequenceSaving}
											>
												<Trash2 size={16} />
											</button>
										</div>
									</td>
								</tr>
							{:else}
								<tr>
									<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={6}>
										{orderedSequences.length === 0
											? 'Este escenario todavía no tiene secuencias.'
											: 'Sin secuencias para este filtro.'}
									</td>
								</tr>
							{/each}
						</tbody>
					</table>
				</div>
			</div>
		</div>

		<div class="card grid p-4 sm:grid-cols-3 sm:divide-x sm:divide-[color:var(--border)]">
			<div class="px-3 py-1 sm:first:pl-0">
				<p class="text-xs text-[color:var(--muted-foreground)]">Último verso del escenario</p>
				<p class="text-base font-semibold">
					{scenarioLastVerse === 0 ? '--' : scenarioLastVerse}
				</p>
			</div>
			<div class="px-3 py-1">
				<p class="text-xs text-[color:var(--muted-foreground)]">Versos declarados (filtrado)</p>
				<p class="text-base font-semibold">{declaredVerses}</p>
			</div>
			<div class="px-3 py-1">
				<p class="text-xs text-[color:var(--muted-foreground)]">Diferencia</p>
				<p
					class={`text-base font-semibold ${
						versesDifference === null
							? 'text-[color:var(--muted-foreground)]'
							: versesDifference === 0
								? 'text-[color:var(--foreground)]'
								: 'text-[color:var(--danger)]'
					}`}
				>
					{#if versesDifference === null}
						--
					{:else if versesDifference > 0}
						+{versesDifference}
					{:else}
						{versesDifference}
					{/if}
				</p>
			</div>
		</div>
	{:else if !showNewScenario}
		<div class="border border-dashed border-[color:var(--border)] p-8 text-center">
			<h3 class="font-semibold">Crea el primer escenario de prueba</h3>
		</div>
	{/if}
</section>

{#snippet panelHeader()}
	<div class="sticky top-0 z-20 border-b border-[color:var(--border)] bg-[color:var(--gray-50)] px-5 pb-3 pt-5">
		<div class="flex flex-wrap items-center justify-between gap-3">
		<div class="flex min-w-0 items-center gap-2">
			<h3 class="text-base font-semibold">
				{draft?.secuencia_prueba_id ? 'Editar secuencia' : 'Nueva secuencia'}
			</h3>
			{#if editingIndex >= 0}
				<div class="flex items-center gap-1">
					<button
						type="button"
						class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
						aria-label="Secuencia anterior"
						onclick={() => previousSequence && requestOpenSequence(previousSequence)}
						disabled={!previousSequence || sequenceSaving}
					>
						<ChevronLeft size={18} />
					</button>
					<span class="whitespace-nowrap text-sm text-[color:var(--muted-foreground)]">
						{editingIndex + 1} / {orderedSequences.length}
					</span>
					<button
						type="button"
						class="p-1 text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] disabled:opacity-30"
						aria-label="Secuencia siguiente"
						onclick={() => nextSequence && requestOpenSequence(nextSequence)}
						disabled={!nextSequence || sequenceSaving}
					>
						<ChevronRight size={18} />
					</button>
				</div>
			{/if}
		</div>
		<div class="flex items-center gap-2">
			{#if draftDirty}
				<span class="text-xs text-[color:var(--muted-foreground)]">Cambios sin guardar</span>
			{/if}
			{#if draft?.secuencia_prueba_id}
				<Button
					variant="danger"
					onclick={() => void deleteSequenceById(draft!.secuencia_prueba_id as string)}
					disabled={sequenceSaving}
				>
					Eliminar
				</Button>
			{/if}
			<Button variant="secondary" onclick={requestCloseSequence} disabled={sequenceSaving}>
				Cerrar
			</Button>
			<Button
				variant="success"
				onclick={() => void saveSequence()}
				loading={sequenceSaving}
				loadingLabel="Guardando…"
			>
				Guardar
			</Button>
		</div>
		</div>
		{#if draftSummary}
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">{draftSummary}</p>
		{/if}
	</div>
{/snippet}

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
			{#if measuresFoldable}
				<button
					type="button"
					class="text-xs font-medium text-[color:var(--primary)] hover:underline"
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

{#snippet metricSections()}
	{#if errorMessage}
		<p class="border-l-4 border-red-500 bg-red-50 p-3 text-sm text-red-900">{errorMessage}</p>
	{/if}

	<section class="bg-white p-4">
		<h4 class="form-section-title">Versos y forma</h4>
		<div class="grid gap-3 sm:grid-cols-2">
			<label class="form-field">
				<span class="form-label">Verso inicial</span>
				<input
					type="number"
					min="1"
					class="h-10 w-full border border-[color:var(--border)] px-3"
					value={draft!.v_ini}
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
					value={draft!.v_fin}
					onchange={(event) => updateSequenceEnd(Number(event.currentTarget.value))}
					disabled={hasCalculatedRange || isIsolatedVerse}
				/>
			</label>
		</div>

		<div class="mt-3 space-y-3">
			<MetricLengthAlert
				rule={selectedLengthRule}
				start={draft!.v_ini}
				end={draft!.v_fin}
				configurationName={selectedConfiguration?.nombre}
			/>
			<div class="grid gap-3 lg:grid-cols-2">
				<label class="form-field">
					<span class="form-label">Forma métrica *</span>
					<select
						class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
						value={draft!.forma_id}
						onchange={(event) => changeForm(event.currentTarget.value)}
					>
						<option value="">Seleccionar</option>
						<optgroup label="Formas métricas">
							{#each metricForms as form (form.forma_id)}
								<option value={form.forma_id}>
									{form.nombre}{form.grado_especificacion === 'general' ? ' · general' : ''}
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
				{#if !isEditorialOutput && configurationsForDraft.length === 1 && selectedConfiguration}
					<div class="form-field">
						<span class="form-label">Arquitectura</span>
						<p class="text-sm leading-10">
							{selectedConfiguration.nombre}
							<span class="text-[color:var(--muted-foreground)]">· única de esta forma</span>
						</p>
					</div>
				{:else if !isEditorialOutput}
					<label class="form-field">
						<span class="form-label">
							{selectedForm?.slug === 'villancico'
								? '¿Dónde aparece por primera vez el estribillo? *'
								: selectedForm?.slug === 'copla_real'
									? '¿Aparecen versos de pie quebrado? *'
									: selectedForm?.slug === 'redondilla'
										? '¿Cómo se organizan las redondillas? *'
										: 'Arquitectura *'}
						</span>
						<select
							class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
							value={draft!.arquitectura_id}
							onchange={(event) => resetForConfiguration(event.currentTarget.value)}
							disabled={!draft!.forma_id}
						>
							<option value="">
								{selectedForm?.slug === 'villancico'
									? 'Seleccionar posición'
									: selectedForm?.slug === 'copla_real'
										? 'Seleccionar realización'
										: selectedForm?.slug === 'redondilla'
											? 'Seleccionar organización'
											: 'Seleccionar arquitectura'}
							</option>
							{#each configurationsForDraft as configuration (configuration.arquitectura_id)}
								<option value={configuration.arquitectura_id}>
									{configuration.nombre}
								</option>
							{/each}
						</select>
					</label>
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

	{#if draft!.arquitectura_id}
		{#if hasSequenceChoices}
			<section class="space-y-4 bg-white p-4">
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
			<section class="space-y-4 bg-white p-4">
				<h4 class="form-section-title mb-0">Estructura</h4>

				{#key `${draft!.secuencia_prueba_id ?? 'nueva'}-${draft!.arquitectura_id}`}
					<MetricStructureEditor
						sequenceStart={draft!.v_ini}
						sections={sectionsForDraft}
						unitPlan={unitPlanForDraft}
						groups={structureGroups}
						options={choiceOptionsForDraft}
						units={draft!.unidades}
						choices={draft!.elecciones}
						globalQuestions={measureGroups.length >= 2 ? compositionMeasure : undefined}
						onUnitsChange={(units) => (draft!.unidades = units)}
						onChoicesChange={(choices) => (draft!.elecciones = choices)}
						onUnitsRemoved={removeStructuredReferences}
						onRangeChange={(end) => (draft!.v_fin = end)}
					/>
				{/key}
			</section>
		{/if}

		{#if draft!.desviaciones.length > 0}
		<section class="space-y-4 bg-white p-4">
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
				<Button variant="secondary" onclick={addDeviation}>Añadir otra</Button>
			</div>
			{#each draft!.desviaciones as deviation, deviationIndex}
				<div class="grid gap-3 border border-[color:var(--border)] p-4 sm:grid-cols-2 xl:grid-cols-6">
					<label class="form-field">
						<span class="form-label">Dimensión</span>
						<select
							class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm"
							bind:value={deviation.dimension}
						>
							<option value="metro">Metro</option>
							<option value="rima">Rima</option>
							<option value="estructura">Estructura</option>
							<option value="repeticion">Repetición</option>
							<option value="rasgo">Rasgo</option>
							<option value="combinacion">Variedad</option>
						</select>
					</label>
					<label class="form-field xl:col-span-2">
						<span class="form-label">Relación con la norma</span>
						<select
							class="h-10 w-full border border-[color:var(--border)] bg-white px-2 text-sm"
							bind:value={deviation.relacion_norma}
						>
							<option value="diferente">Diferente</option>
							<option value="menor_que_norma">Menor que la norma</option>
							<option value="mayor_que_norma">Mayor que la norma</option>
							<option value="falta_elemento_esperado">Falta un elemento esperado</option>
							<option value="aparece_elemento_no_esperado">Aparece un elemento no esperado</option>
							<option value="ruptura">Ruptura</option>
							<option value="omision">Omisión</option>
							<option value="adicion">Adición</option>
							<option value="sustitucion">Sustitución</option>
							<option value="otra">Otra</option>
						</select>
					</label>
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
							class="h-10 text-sm text-red-700 hover:underline"
							onclick={() => {
								if (draft) {
									draft.desviaciones = draft.desviaciones.filter(
										(_, index: number) => index !== deviationIndex
									);
								}
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

		{#if observationsOpen}
			<section class="bg-white p-4">
				<h4 class="form-section-title">Observaciones de la prueba</h4>
				<label class="form-field">
					<span class="sr-only">Observaciones de la prueba</span>
					<textarea
						class="min-h-24 w-full border border-[color:var(--border)] p-3"
						value={draft!.observaciones}
						oninput={(event) => (draft!.observaciones = event.currentTarget.value)}
					></textarea>
				</label>
			</section>
		{/if}

		<div class="flex flex-wrap gap-x-5 gap-y-1 px-1">
			{#if draft!.desviaciones.length === 0}
				<button
					type="button"
					class="text-sm font-medium text-[color:var(--primary)] hover:underline"
					onclick={addDeviation}
				>
					+ Registrar una desviación
				</button>
			{/if}
			{#if !observationsOpen}
				<button
					type="button"
					class="text-sm font-medium text-[color:var(--primary)] hover:underline"
					onclick={() => (observationsOpen = true)}
				>
					+ Añadir una observación
				</button>
			{/if}
		</div>
	{:else if isEditorialOutput}
		<section class="bg-white p-4">
			<h4 class="form-section-title">Observación opcional</h4>
			<label class="form-field">
				<span class="sr-only">Observación opcional</span>
				<textarea
					class="min-h-24 w-full border border-[color:var(--border)] p-3"
					value={draft!.observaciones}
					oninput={(event) => (draft!.observaciones = event.currentTarget.value)}
					placeholder={isIsolatedVerse
						? 'Solo si hace falta explicar por qué el verso no se integra en los tramos contiguos.'
						: 'Solo si ayuda a describir por qué no se reconoce una forma del catálogo.'}
				></textarea>
			</label>
		</section>
	{/if}
{/snippet}

{#snippet panelBody(wide: boolean)}
	<div
		class={wide
			? 'grid gap-3 p-5 xl:grid-cols-[minmax(0,1.7fr)_minmax(0,1fr)] xl:items-start'
			: 'space-y-3 px-5 pb-5 pt-4'}
	>
		<div class="min-w-0 space-y-3">
			{@render metricSections()}
		</div>
		<div class="min-w-0 space-y-3">
			<MetricSandboxLegacyFields />
		</div>
	</div>
{/snippet}

{#if draft && displayMode === 'panel'}
	<aside
		class="fixed right-0 top-0 z-40 h-screen w-full max-w-xl overflow-y-auto border-l border-[color:var(--border)] bg-[color:var(--gray-50)]"
		inert={sequenceSaving}
		aria-busy={sequenceSaving}
	>
		{@render panelHeader()}
		{@render panelBody(false)}
	</aside>
{:else if draft}
	<div class="fixed inset-0 z-40 flex items-start justify-center bg-black/50 p-4">
		<div
			class="flex max-h-[92vh] w-full max-w-6xl flex-col overflow-hidden border border-[color:var(--border)] bg-[color:var(--gray-50)]"
			inert={sequenceSaving}
			aria-busy={sequenceSaving}
		>
			{@render panelHeader()}
			<div class="min-h-0 flex-1 overflow-y-auto">
				{@render panelBody(true)}
			</div>
		</div>
	</div>
{/if}

<UnsavedChangesModal
	open={Boolean(pendingAction)}
	message={pendingAction?.kind === 'new'
		? 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de crear otra?'
		: pendingAction?.kind === 'open'
			? 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de cambiar de secuencia?'
			: 'La secuencia actual tiene cambios sin guardar. ¿Quieres guardarlos antes de cerrar?'}
	discardLabel="Continuar sin guardar"
	saving={sequenceSaving}
	onCancel={() => (pendingAction = null)}
	onDiscard={runPendingAction}
	onSave={savePendingAction}
/>

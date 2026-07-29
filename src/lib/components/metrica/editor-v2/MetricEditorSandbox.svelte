<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import { untrack } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
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
	import MetricStructureEditor from './MetricStructureEditor.svelte';
	import {
		childrenOfSection,
		ensureRequiredFlatMetricStructure,
		ensureRequiredMetricStructure,
		flatRepeatedMetricSection,
		flatVariableRepeatedMetricSection,
		isHierarchicalMetricStructure,
		reflowMetricUnits,
		rootSections as structuredRootSections,
		sectionId as structuredSectionId,
		sectionLabel as structuredSectionLabel,
		sectionMaximum,
		sectionMinimum,
		sectionVerseMaximum,
		sectionVerseMinimum,
		syncFlatRepeatedMetricUnits,
		syncChoiceMaterializedSections,
		type MetricChoiceDraft,
		type MetricUnitDraft
	} from './editor-model';

	const props = $props<{ data: MetricCatalogPageData }>();

	type DeviationDraft = {
		unidad_prueba_id: string | null;
		v_ini: number;
		v_fin: number;
		dimension: 'medida' | 'rima' | 'estructura' | 'repeticion' | 'rasgo';
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
		patron_rima_observado_id: string | null;
		seccion_observada_id: string | null;
		patron_repeticion_observado_id: string | null;
		valor_rasgo_observado_id: string | null;
		observaciones: string;
	};

	type SequenceDraft = {
		secuencia_prueba_id: string | null;
		escenario_id: string;
		orden: number;
		v_ini: number;
		v_fin: number;
		forma_id: string;
		configuracion_id: string;
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
						configuration.configuracion_id === draft?.configuracion_id
				) ?? null
			: null
	);
	const selectedLengthRule = $derived(
		draft
			? props.data.lengthRules.find(
					(rule: MetricLengthRule) => rule.configuracion_id === draft?.configuracion_id
				) ?? null
			: null
	);
	const sectionsForDraft = $derived(
		draft
			? props.data.domain.sections
					.filter(
						(row: MetricCatalogDomainRow) =>
							row.configuracion_id === draft?.configuracion_id
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
							row.configuracion_id === draft?.configuracion_id && row.activo
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
	const hasHierarchicalEditor = $derived(isHierarchicalMetricStructure(sectionsForDraft));
	const hasFlatRepeatedEditor = $derived(
		Boolean(flatRepeatedMetricSection(sectionsForDraft)) && unitChoiceGroups.length > 0
	);
	const hasFlatVariableEditor = $derived(
		Boolean(flatVariableRepeatedMetricSection(sectionsForDraft)) && unitChoiceGroups.length > 0
	);
	const hasStructuredEditor = $derived(
		hasHierarchicalEditor || hasFlatRepeatedEditor || hasFlatVariableEditor
	);
	const hasCalculatedRange = $derived(hasHierarchicalEditor || hasFlatVariableEditor);
	const hasSequenceChoices = $derived(sequenceChoiceGroups.length > 0);
	const structureStepNumber = $derived(hasSequenceChoices ? 3 : 2);
	const deviationStepNumber = $derived(
		2 + (hasSequenceChoices ? 1 : 0) + (hasStructuredEditor ? 1 : 0)
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
				(configuration: MetricCatalogConfiguration) => configuration.configuracion_id === id
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
					choice.unidad_prueba_id === unitId
			)
			.map((choice: MetricChoiceDraft) => choice.opcion_eleccion_id);
	}

	function setChoices(groupId: string, unitId: string | null, optionIds: string[]) {
		if (!draft) return;
		draft.elecciones = [
			...draft.elecciones.filter(
				(choice: MetricChoiceDraft) =>
					!(
						choice.grupo_eleccion_id === groupId &&
						choice.unidad_prueba_id === unitId
					)
			),
			...optionIds.map((optionId) => ({
				unidad_prueba_id: unitId,
				grupo_eleccion_id: groupId,
				opcion_eleccion_id: optionId,
				observaciones: null
			}))
		];
	}

	function catalogParts(configurationId: string) {
		const sections = props.data.domain.sections.filter(
			(row: MetricCatalogDomainRow) => row.configuracion_id === configurationId
		);
		const groups = props.data.domain.choiceGroups.filter(
			(row: MetricCatalogDomainRow) =>
				row.configuracion_id === configurationId && row.activo
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

	function normalizeStructuredUnits(
		units: MetricUnitDraft[],
		choices: MetricChoiceDraft[],
		configurationId: string,
		sequenceStart: number,
		sequenceEnd: number
	): MetricUnitDraft[] {
		const { sections, groups, options } = catalogParts(configurationId);
		const hasUnitQuestions = groups.some(
			(row: MetricCatalogDomainRow) => row.alcance === 'unidad'
		);
		const flatSection = hasUnitQuestions ? flatRepeatedMetricSection(sections) : null;
		const variableFlatSection = hasUnitQuestions
			? flatVariableRepeatedMetricSection(sections)
			: null;
		if (!isHierarchicalMetricStructure(sections) && !flatSection && !variableFlatSection) {
			return units;
		}

		if (flatSection) {
			const synchronized = syncFlatRepeatedMetricUnits(
				units,
				sections,
				sequenceStart,
				sequenceEnd,
				choices,
				options
			);
			if (synchronized.compatible) return synchronized.units;
			if (units.length > 0) {
				return reflowMetricUnits(units, sections, sequenceStart, choices, options);
			}
			return syncFlatRepeatedMetricUnits(
				units,
				sections,
				sequenceStart,
				sequenceStart +
					sectionVerseMinimum(flatSection) * sectionMinimum(flatSection) -
					1,
				choices,
				options
			).units;
		}

		if (variableFlatSection) {
			return ensureRequiredFlatMetricStructure(
				units,
				sections,
				sequenceStart,
				choices,
				options
			);
		}

		let next = ensureRequiredMetricStructure(
			units,
			sections,
			sequenceStart,
			choices,
			options
		);
		for (const group of groups.filter(
			(row: MetricCatalogDomainRow) => row.alcance === 'unidad'
		)) {
			const groupId = String(group.grupo_eleccion_id);
			const groupOptions = options.filter(
				(option: MetricCatalogDomainRow) =>
					String(option.grupo_eleccion_id) === groupId
			);
			for (const unit of [...next]) {
				if (
					group.seccion_id &&
					String(group.seccion_id) !== unit.seccion_id
				) {
					continue;
				}
				const selected = choices
					.filter(
						(choice: MetricChoiceDraft) =>
							choice.grupo_eleccion_id === groupId &&
							choice.unidad_prueba_id === unit.unidad_prueba_id
					)
					.map((choice: MetricChoiceDraft) => choice.opcion_eleccion_id);
				next = syncChoiceMaterializedSections(
					next,
					sections,
					unit.unidad_prueba_id,
					groupOptions,
					selected,
					sequenceStart,
					choices,
					options
				);
			}
		}
		return reflowMetricUnits(next, sections, sequenceStart, choices, options);
	}

	function resetForConfiguration(configurationId: string) {
		if (!draft) return;
		draft.configuracion_id = configurationId;
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
		const flatSection = flatRepeatedMetricSection(parts.sections);
		const variableFlatSection = flatVariableRepeatedMetricSection(parts.sections);
		if (
			isHierarchicalMetricStructure(parts.sections) ||
			variableFlatSection ||
			(flatSection &&
				previousLength <
					sectionVerseMinimum(flatSection) * sectionMinimum(flatSection))
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
		const configurations = props.data.configurations.filter(
			(configuration: MetricCatalogConfiguration) =>
				configuration.forma_id === formId && configuration.activo
		);
		resetForConfiguration(
			configurations.length === 1 ? configurations[0].configuracion_id : ''
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
			configuracion_id: '',
			observaciones: '',
			unidades: [],
			elecciones: [],
			desviaciones: []
		};
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
			configuracion_id: String(row.configuracion_id),
			observaciones: String(row.observaciones ?? ''),
			unidades: props.data.editorSandbox.units
				.filter(
					(unit: MetricCatalogDomainRow) =>
						String(unit.secuencia_prueba_id) === sequenceId
				)
				.map((unit: MetricCatalogDomainRow) => ({
					unidad_prueba_id: String(unit.unidad_prueba_id),
					unidad_padre_id: unit.unidad_padre_id ? String(unit.unidad_padre_id) : null,
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
					unidad_prueba_id: choice.unidad_prueba_id
						? String(choice.unidad_prueba_id)
						: null,
					grupo_eleccion_id: String(choice.grupo_eleccion_id),
					opcion_eleccion_id: String(choice.opcion_eleccion_id),
					observaciones: choice.observaciones ? String(choice.observaciones) : null
				})),
			desviaciones: props.data.editorSandbox.deviations
				.filter(
					(deviation: MetricCatalogDomainRow) =>
						String(deviation.secuencia_prueba_id) === sequenceId
				)
				.map((deviation: MetricCatalogDomainRow) => ({
					unidad_prueba_id: deviation.unidad_prueba_id
						? String(deviation.unidad_prueba_id)
						: null,
					v_ini: Number(deviation.v_ini),
					v_fin: Number(deviation.v_fin),
					dimension: deviation.dimension as DeviationDraft['dimension'],
					relacion_norma:
						deviation.relacion_norma as DeviationDraft['relacion_norma'],
					metro_observado_id: deviation.metro_observado_id
						? String(deviation.metro_observado_id)
						: null,
					patron_rima_observado_id: deviation.patron_rima_observado_id
						? String(deviation.patron_rima_observado_id)
						: null,
					seccion_observada_id: deviation.seccion_observada_id
						? String(deviation.seccion_observada_id)
						: null,
					patron_repeticion_observado_id:
						deviation.patron_repeticion_observado_id
							? String(deviation.patron_repeticion_observado_id)
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
			draft.configuracion_id,
			draft.v_ini,
			draft.v_fin
		);
		const openedSections = catalogParts(draft.configuracion_id).sections;
		if (
			isHierarchicalMetricStructure(openedSections) ||
			Boolean(flatVariableRepeatedMetricSection(openedSections))
		) {
			draft.v_fin = draft.unidades.reduce(
				(maximum: number, unit: MetricUnitDraft) => Math.max(maximum, unit.v_fin),
				draft.v_ini
			);
		}
		errorMessage = '';
	}

	function addDeviation() {
		if (!draft) return;
		draft.desviaciones = [
			...draft.desviaciones,
			{
				unidad_prueba_id: null,
				v_ini: draft.v_ini,
				v_fin: draft.v_fin,
				dimension: 'medida',
				relacion_norma: 'diferente',
				metro_observado_id: null,
				patron_rima_observado_id: null,
				seccion_observada_id: null,
				patron_repeticion_observado_id: null,
				valor_rasgo_observado_id: null,
				observaciones: ''
			}
		];
	}

	function updateSequenceStart(value: number) {
		if (!draft) return;
		draft.v_ini = Math.max(1, value);
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
		draft.v_fin = Math.max(1, value);
		if (!hasFlatRepeatedEditor) return;
		const { sections, options } = catalogParts(draft.configuracion_id);
		const synchronized = syncFlatRepeatedMetricUnits(
			draft.unidades,
			sections,
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
				!choice.unidad_prueba_id || !removed.has(choice.unidad_prueba_id)
		);
		draft.desviaciones = draft.desviaciones.map((deviation: DeviationDraft) =>
			deviation.unidad_prueba_id && removed.has(deviation.unidad_prueba_id)
				? { ...deviation, unidad_prueba_id: null }
				: deviation
		);
	}

	function validateDraft(): string | null {
		if (!draft) return 'No hay ninguna secuencia abierta.';
		if (!draft.forma_id || !draft.configuracion_id) {
			return 'Selecciona una forma y su configuración.';
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
			const section = sectionsForDraft.find(
				(row: MetricCatalogDomainRow) => structuredSectionId(row) === unit.seccion_id
			);
			if (section) {
				const unitLength = unit.v_fin - unit.v_ini + 1;
				const maximum = sectionVerseMaximum(section);
				if (
					unitLength < sectionVerseMinimum(section) ||
					(maximum !== null && unitLength > maximum)
				) {
					return `Revisa el número de versos de «${structuredSectionLabel(section)}».`;
				}
			}
		}
		if (hasStructuredEditor) {
			for (const root of structuredRootSections(sectionsForDraft)) {
				const rootUnits = draft.unidades.filter(
					(unit: MetricUnitDraft) =>
						unit.unidad_padre_id === null &&
						unit.seccion_id === structuredSectionId(root)
				);
				const maximum = sectionMaximum(root);
				if (
					rootUnits.length < sectionMinimum(root) ||
					(maximum !== null && rootUnits.length > maximum)
				) {
					return `Revisa el número de unidades «${structuredSectionLabel(root)}».`;
				}
				for (const rootUnit of rootUnits) {
					for (const child of childrenOfSection(
						sectionsForDraft,
						structuredSectionId(root)
					)) {
						const childTotal = draft.unidades.filter(
							(unit: MetricUnitDraft) =>
								unit.unidad_padre_id === rootUnit.unidad_prueba_id &&
								unit.seccion_id === structuredSectionId(child)
						).length;
						const childMaximum = sectionMaximum(child);
						if (
							childTotal < sectionMinimum(child) ||
							(childMaximum !== null && childTotal > childMaximum)
						) {
							return `Revisa «${structuredSectionLabel(child)}» en ${structuredSectionLabel(root)}.`;
						}
					}
				}
			}
		}
		for (const group of sequenceChoiceGroups) {
			const total = selectedChoiceIds(String(group.grupo_eleccion_id), null).length;
			if (
				total < Number(group.selecciones_min) ||
				total > Number(group.selecciones_max)
			) {
				return `Revisa la pregunta «${String(group.nombre)}».`;
			}
		}
		for (const group of unitChoiceGroups) {
			const applicableUnits = draft.unidades.filter(
				(unit: MetricUnitDraft) =>
					!group.seccion_id || String(group.seccion_id) === unit.seccion_id
			);
			for (const unit of applicableUnits) {
				const selectedIds = selectedChoiceIds(
					String(group.grupo_eleccion_id),
					unit.unidad_prueba_id
				);
				const total = selectedIds.length;
				if (
					total < Number(group.selecciones_min) ||
					total > Number(group.selecciones_max)
				) {
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
				if (selectedPositions.some((position: number) => position > unitLength)) {
					return `Revisa las posiciones de «${String(group.nombre)}» en la unidad ${unit.orden}.`;
				}
				if (
					String(group.slug) === 'posiciones_pies_quebrados' &&
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
			pushToast('success', 'Secuencia métrica de prueba guardada.');
			await invalidateAll();
		} catch (error) {
			errorMessage =
				error instanceof Error ? error.message : 'No se pudo guardar la secuencia.';
		} finally {
			sequenceSaving = false;
		}
	}

	async function deleteSequence() {
		if (!draft?.secuencia_prueba_id || sequenceSaving) return;
		if (!window.confirm('¿Eliminar esta secuencia métrica de prueba?')) return;
		sequenceSaving = true;
		try {
			await callApi({
				action: 'delete_sequence',
				secuencia_prueba_id: draft.secuencia_prueba_id
			});
			draft = null;
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
			Estos escenarios no son obras y no aparecen en el dashboard de producción. Sirven para
			comprobar qué preguntas genera el catálogo, cuánto trabajo exige su cumplimentación y qué
			datos analíticos quedan guardados.
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

	{#if errorMessage}
		<p class="border-l-4 border-red-500 bg-red-50 p-3 text-sm text-red-900">{errorMessage}</p>
	{/if}

	{#if selectedScenario}
		<div class="grid min-h-[42rem] border border-[color:var(--border)] bg-[color:var(--card)] lg:grid-cols-[18rem_minmax(0,1fr)]">
			<aside class="border-b border-[color:var(--border)] p-4 lg:border-b-0 lg:border-r">
				<div class="flex items-center justify-between gap-2">
					<div>
						<h3 class="font-semibold">{String(selectedScenario.nombre)}</h3>
						<p class="text-xs text-[color:var(--muted-foreground)]">
							{scenarioSequences.length} secuencias
						</p>
					</div>
					<Button variant="secondary" onclick={openNewSequence}>Añadir</Button>
				</div>
				<nav class="mt-4 space-y-1">
					{#each scenarioSequences as sequence (String(sequence.secuencia_prueba_id))}
						<button
							type="button"
							class={`w-full border-l-2 px-3 py-2 text-left text-sm ${
								draft?.secuencia_prueba_id === String(sequence.secuencia_prueba_id)
									? 'border-[color:var(--primary)] bg-[color:var(--muted)]'
									: 'border-transparent hover:bg-[color:var(--muted)]'
							}`}
							onclick={() => openSequence(sequence)}
						>
							<span class="block font-medium">
								{Number(sequence.orden)}. {formLabel(String(sequence.forma_id))}
							</span>
							<span class="text-xs text-[color:var(--muted-foreground)]">
								vv. {Number(sequence.v_ini)}–{Number(sequence.v_fin)}
							</span>
						</button>
					{:else}
						<p class="text-sm text-[color:var(--muted-foreground)]">
							Este escenario todavía no tiene secuencias.
						</p>
					{/each}
				</nav>
			</aside>

			<div class="min-w-0 p-5">
				{#if draft}
					<div class="space-y-6">
						<header class="flex flex-wrap items-start justify-between gap-3">
							<div>
								<p class="text-xs uppercase tracking-wide text-[color:var(--muted-foreground)]">
									{draft.secuencia_prueba_id ? 'Editar prueba' : 'Nueva prueba'}
								</p>
								<h3 class="mt-1 text-xl font-semibold">Caracterización de la secuencia</h3>
							</div>
							<div class="flex gap-2">
								{#if draft.secuencia_prueba_id}
									<Button variant="danger" onclick={deleteSequence} disabled={sequenceSaving}>
										Eliminar
									</Button>
								{/if}
								<Button variant="success" onclick={saveSequence} disabled={sequenceSaving}>
									{sequenceSaving ? 'Guardando…' : 'Guardar prueba'}
								</Button>
							</div>
						</header>

						<section class="space-y-3">
							<h4 class="font-semibold">1. Rango y forma</h4>
							<div class="grid gap-3 sm:grid-cols-3">
								<label class="form-field">
									<span class="form-label">Orden</span>
									<input type="number" min="1" class="h-10 border border-[color:var(--border)] px-3" bind:value={draft.orden} />
								</label>
								<label class="form-field">
									<span class="form-label">Verso inicial</span>
									<input
										type="number"
										min="1"
										class="h-10 border border-[color:var(--border)] px-3"
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
										class="h-10 border border-[color:var(--border)] px-3 disabled:bg-[color:var(--muted)]"
										value={draft.v_fin}
										onchange={(event) => updateSequenceEnd(Number(event.currentTarget.value))}
										disabled={hasCalculatedRange}
									/>
								</label>
							</div>
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
										class="h-10 border border-[color:var(--border)] bg-white px-3"
										value={draft.forma_id}
										onchange={(event) => changeForm(event.currentTarget.value)}
									>
										<option value="">Seleccionar forma</option>
										{#each activeForms as form (form.forma_id)}
											<option value={form.forma_id}>
												{form.nombre}{form.residual ? ' · residual' : ''}
											</option>
										{/each}
									</select>
								</label>
								<label class="form-field">
									<span class="form-label">
										{selectedForm?.slug === 'villancico'
											? '¿Dónde aparece por primera vez el estribillo? *'
											: selectedForm?.slug === 'copla_real'
												? '¿Aparecen versos de pie quebrado? *'
											: 'Configuración *'}
									</span>
									<select
										class="h-10 border border-[color:var(--border)] bg-white px-3"
										value={draft.configuracion_id}
										onchange={(event) => resetForConfiguration(event.currentTarget.value)}
										disabled={!draft.forma_id}
									>
										<option value="">
											{selectedForm?.slug === 'villancico'
												? 'Seleccionar posición'
												: selectedForm?.slug === 'copla_real'
													? 'Seleccionar realización'
												: 'Seleccionar configuración'}
										</option>
										{#each configurationsForDraft as configuration (configuration.configuracion_id)}
											<option value={configuration.configuracion_id}>
												{configuration.nombre}
											</option>
										{/each}
									</select>
								</label>
							</div>
							{#if selectedConfiguration}
								<div class="bg-[color:var(--muted)] p-3 text-sm leading-6">
									<p class="font-medium">
										Norma seleccionada: {configurationLabel(selectedConfiguration.configuracion_id)}
									</p>
									{#if selectedConfiguration.descripcion}
										<p class="mt-1 text-[color:var(--muted-foreground)]">
											{selectedConfiguration.descripcion}
										</p>
									{/if}
								</div>
							{/if}
						</section>

						{#if draft.configuracion_id}
							{#if hasSequenceChoices}
								<section class="space-y-4">
									<h4 class="font-semibold">2. Datos de esta realización</h4>
									{#each sequenceChoiceGroups as group (String(group.grupo_eleccion_id))}
										<MetricChoiceField
											{group}
											options={optionsForGroup(String(group.grupo_eleccion_id))}
											selectedIds={selectedChoiceIds(String(group.grupo_eleccion_id), null)}
											onChange={(ids) => setChoices(String(group.grupo_eleccion_id), null, ids)}
										/>
									{/each}
								</section>
							{/if}

							{#if hasStructuredEditor}
								<section class="space-y-4">
									<div>
										<h4 class="font-semibold">{structureStepNumber}. Estructura de la forma</h4>
										<p class="mt-1 max-w-3xl text-sm text-[color:var(--muted-foreground)]">
											Completa únicamente las partes que aparecen. Los rangos y las secciones
											obligatorias se calculan automáticamente.
										</p>
									</div>
									<MetricStructureEditor
										sequenceStart={draft.v_ini}
										sections={sectionsForDraft}
										groups={unitChoiceGroups}
										options={choiceOptionsForDraft}
										units={draft.unidades}
										choices={draft.elecciones}
										onUnitsChange={(units) => (draft!.unidades = units)}
										onChoicesChange={(choices) => (draft!.elecciones = choices)}
										onUnitsRemoved={removeStructuredReferences}
										onRangeChange={(end) => (draft!.v_fin = end)}
									/>
								</section>
							{/if}

							<section class="space-y-4">
								<div class="flex flex-wrap items-start justify-between gap-3">
									<div>
										<h4 class="font-semibold">
											{deviationStepNumber}. Desviaciones respecto de lo admitido
										</h4>
										<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
											El bloque queda vacío cuando la realización cumple la norma y las elecciones anteriores.
										</p>
									</div>
									<Button variant="secondary" onclick={addDeviation}>Añadir desviación</Button>
								</div>
								{#each draft.desviaciones as deviation, deviationIndex}
									<div class="grid gap-3 border border-[color:var(--border)] p-4 lg:grid-cols-6">
										<label class="form-field">
											<span class="form-label">Dimensión</span>
											<select class="h-10 border border-[color:var(--border)] bg-white px-2" bind:value={deviation.dimension}>
												<option value="medida">Medida</option>
												<option value="rima">Rima</option>
												<option value="estructura">Estructura</option>
												<option value="repeticion">Repetición</option>
												<option value="rasgo">Rasgo</option>
											</select>
										</label>
										<label class="form-field lg:col-span-2">
											<span class="form-label">Relación con la norma</span>
											<select class="h-10 border border-[color:var(--border)] bg-white px-2" bind:value={deviation.relacion_norma}>
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
											<input type="number" class="h-10 border border-[color:var(--border)] px-2" bind:value={deviation.v_ini} />
										</label>
										<label class="form-field">
											<span class="form-label">V. final</span>
											<input type="number" class="h-10 border border-[color:var(--border)] px-2" bind:value={deviation.v_fin} />
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
										<label class="form-field lg:col-span-6">
											<span class="form-label">Descripción mínima de la diferencia</span>
											<textarea class="min-h-20 border border-[color:var(--border)] p-2" bind:value={deviation.observaciones}></textarea>
										</label>
									</div>
								{/each}
							</section>

							<label class="form-field">
								<span class="form-label">Observaciones generales de la prueba</span>
								<textarea class="min-h-24 border border-[color:var(--border)] p-3" bind:value={draft.observaciones}></textarea>
							</label>
						{/if}
					</div>
				{:else}
					<div class="flex min-h-[28rem] items-center justify-center text-center">
						<div>
							<h3 class="font-semibold">Selecciona o crea una secuencia</h3>
							<p class="mt-2 max-w-md text-sm leading-6 text-[color:var(--muted-foreground)]">
								La prueba mostrará únicamente las preguntas declaradas por la configuración elegida.
							</p>
						</div>
					</div>
				{/if}
			</div>
		</div>
	{:else if !showNewScenario}
		<div class="border border-dashed border-[color:var(--border)] p-8 text-center">
			<h3 class="font-semibold">Crea el primer escenario de prueba</h3>
		</div>
	{/if}
</section>

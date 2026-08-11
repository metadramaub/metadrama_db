<script lang="ts">
	import type { Snippet } from 'svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import SegmentedChoice from '$lib/components/ui/segmented-choice.svelte';
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import { controlDePregunta } from '$lib/metrica/controles-formulario';
	import MetricChoiceField from './MetricChoiceField.svelte';
	import MetricFamilyControl from './MetricFamilyControl.svelte';
	import { seRespondeDentroDeLaUnidad } from '$lib/metrica/alcance';
	import {
		addMetricUnit,
		addSectionInstance,
		childrenOfSection,
		reflowMetricUnits,
		removeMetricUnitTree,
		rootSections,
		sectionHasFixedLength,
		sectionId,
		sectionLabel,
		sectionMaximum,
		sectionMinimum,
		sectionParentId,
		sectionVerseMaximum,
		sectionVerseMinimum,
		syncChoiceMaterializedSections,
		unitIdsInTree,
		type MetricChoiceDraft,
		type MetricUnitDraft,
		type MetricUnitPlan
	} from './editor-model';

	const props = $props<{
		sequenceStart: number;
		sections: MetricCatalogDomainRow[];
		groups: MetricCatalogDomainRow[];
		options: MetricCatalogDomainRow[];
		units: MetricUnitDraft[];
		choices: MetricChoiceDraft[];
		unitPlan: MetricUnitPlan | null;
		onUnitsChange: (units: MetricUnitDraft[]) => void;
		onChoicesChange: (choices: MetricChoiceDraft[]) => void;
		onUnitsRemoved: (unitIds: string[]) => void;
		onRangeChange: (end: number) => void;
		globalQuestions?: Snippet;
		/** Cómo se llama la unidad que define la forma: su nombre, no «Unidad». */
		unitLabel?: string;
	}>();

	/**
	 * El nodo de primer nivel es siempre la unidad, que no realiza ninguna sección. Las
	 * secciones raíz son sus partes y se representan dentro de ella.
	 */
	/** Por qué el número de versos no se puede tocar cuando la forma lo fija. */
	const EXTENT_HELP =
		'La forma fija esta extensión, así que no se cambia aquí. Si al texto le falta o le sobra un verso, regístralo como desviación.';

	const roots = $derived<(MetricCatalogDomainRow | null)[]>(
		props.unitPlan ? [null] : rootSections(props.sections)
	);

	/** La unidad entera, cuando el nodo no realiza ninguna sección. */
	const unitExtent = $derived(props.unitPlan?.extent ?? null);

	function nodeSectionId(section: MetricCatalogDomainRow | null): string | null {
		return section ? sectionId(section) : null;
	}

	/**
	 * La unidad que define la forma no realiza ninguna sección, así que el catálogo no le
	 * pone nombre. Llamarla «Unidad» deja al editor leyendo «+ Añadir unidad» donde debería
	 * leer «+ Añadir villancico»: el nombre se toma de la forma cuando el contenedor lo da.
	 */
	function nodeLabel(section: MetricCatalogDomainRow | null): string {
		return section ? sectionLabel(section) : (props.unitLabel ?? 'Unidad');
	}

	function isUnitNode(section: MetricCatalogDomainRow | null, parentUnitId: string | null): boolean {
		return parentUnitId === null && section === null && props.unitPlan !== null;
	}

	function nodeVerseMinimum(section: MetricCatalogDomainRow | null): number {
		if (section) return sectionVerseMinimum(section);
		return unitExtent?.minimum ?? 1;
	}

	function nodeVerseMaximum(section: MetricCatalogDomainRow | null): number | null {
		if (section) return sectionVerseMaximum(section);
		return unitExtent?.maximum ?? null;
	}

	function nodeHasFixedLength(section: MetricCatalogDomainRow | null): boolean {
		if (section) return sectionHasFixedLength(section);
		return unitExtent !== null && unitExtent.minimum === unitExtent.maximum;
	}
	const controlledSectionIds = $derived(
		new Set(
			props.options
				.map((option: MetricCatalogDomainRow) =>
					option.materializa_seccion_id ? String(option.materializa_seccion_id) : ''
				)
				.filter(Boolean)
		)
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

	function groupsForUnit(unit: MetricUnitDraft): MetricCatalogDomainRow[] {
		return props.groups.filter((group: MetricCatalogDomainRow) => {
			if (!seRespondeDentroDeLaUnidad(group.alcance)) return false;
			// Una pregunta sin sección se refiere a la unidad entera, no a una parte suya.
			return group.seccion_id
				? String(group.seccion_id) === unit.seccion_id
				: unit.realizacion_padre_id === null;
		});
	}

	/** Las que quedan dentro de la unidad: las recogidas arriba no se repiten aquí. */
	function visibleGroupsForUnit(unit: MetricUnitDraft): MetricCatalogDomainRow[] {
		return groupsForUnit(unit).filter((group: MetricCatalogDomainRow) => !isFolded(group));
	}

	// ------------------------------------------------------------------
	// Lo que vale para toda la composición
	//
	// El catálogo marca con `permite_aplicar_global` las preguntas cuya respuesta suele valer
	// para todas las unidades equivalentes: el patrón de la mudanza, cómo reaparece el
	// estribillo. Si se pregunta dentro de cada copla, un villancico de cuatro coplas exige
	// ocho respuestas para decir dos cosas. Se pregunta una vez arriba y las unidades solo se
	// abren cuando alguna difiere. Lo guardado sigue siendo la respuesta de cada unidad.
	// ------------------------------------------------------------------

	let expandedFamilyKeys = $state<Set<string>>(new Set());
	let expandedUnitIds = $state<Set<string>>(new Set());

	function unitsForGroup(group: MetricCatalogDomainRow): MetricUnitDraft[] {
		return props.units.filter((unit: MetricUnitDraft) =>
			group.seccion_id
				? String(group.seccion_id) === unit.seccion_id
				: unit.realizacion_padre_id === null
		);
	}

	type MetricQuestionFamily = {
		key: string;
		label: string;
		help: string | null;
		groups: MetricCatalogDomainRow[];
	};

	/**
	 * La misma pregunta puede estar declarada varias veces en una arquitectura, una por
	 * sección: el villancico que empieza por copla pregunta el patrón de la primera mudanza y
	 * el de las siguientes por separado. Para el editor es una sola pregunta, así que se
	 * agrupan por dimensión y enunciado y se responden juntas. Cada grupo guarda lo suyo.
	 */
	/** Lo que la familia exige responder. Sus grupos formulan la misma pregunta en cada unidad. */
	function familyMinimum(family: MetricQuestionFamily): number {
		return Number(family.groups[0]?.selecciones_min ?? 0);
	}

	function familyKeyOf(group: MetricCatalogDomainRow): string {
		return `${String(group.dimension)}|${String(group.nombre)}`;
	}

	// Basta con que exista una unidad destinataria: la pregunta que vale para toda la
	// composición se hace desde el principio y no aparece a media faena, cuando se añade la
	// segunda copla, cambiando de sitio lo que el editor ya estaba mirando.
	function isGroupFoldable(group: MetricCatalogDomainRow): boolean {
		if (!seRespondeDentroDeLaUnidad(group.alcance)) return false;
		if (!group.permite_aplicar_global) return false;
		if (Number(group.selecciones_max ?? 1) !== 1) return false;
		if (group.tipo_control === 'esquema_rima') return false;
		return unitsForGroup(group).length >= 1;
	}

	const foldableFamilies = $derived.by(() => {
		const families = new Map<string, MetricQuestionFamily>();
		for (const group of props.groups) {
			if (!isGroupFoldable(group)) continue;
			const key = familyKeyOf(group);
			const family = families.get(key) ?? {
				key,
				label: String(group.nombre),
				help: group.ayuda_editor ? String(group.ayuda_editor) : null,
				groups: []
			};
			family.groups.push(group);
			families.set(key, family);
		}
		return [...families.values()];
	});

	function optionSlugOf(optionId: string): string {
		return String(
			props.options.find(
				(option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id) === optionId
			)?.slug ?? ''
		);
	}

	function familyOptions(family: MetricQuestionFamily): MetricCatalogDomainRow[] {
		return optionsForGroup(String(family.groups[0]?.grupo_eleccion_id ?? ''));
	}

	function familyState(family: MetricQuestionFamily) {
		const units: MetricUnitDraft[] = [];
		const answers = new Set<string>();
		let answered = 0;
		for (const group of family.groups) {
			const groupId = String(group.grupo_eleccion_id);
			for (const unit of unitsForGroup(group)) {
				units.push(unit);
				const selected = selectedChoiceIds(groupId, unit.realizacion_prueba_id);
				if (selected.length === 0) continue;
				answered += 1;
				answers.add(selected.map(optionSlugOf).sort().join('|'));
			}
		}
		const uniform =
			units.length > 0 && answered === units.length && answers.size === 1
				? [...answers][0]
				: null;
		return { units, answered, uniform };
	}

	function isFamilyFolded(family: MetricQuestionFamily): boolean {
		if (expandedFamilyKeys.has(family.key)) return false;
		const state = familyState(family);
		return state.answered === 0 || state.uniform !== null;
	}

	function isFolded(group: MetricCatalogDomainRow): boolean {
		const family = foldableFamilies.find(
			(candidate: MetricQuestionFamily) =>
				candidate.key === familyKeyOf(group) &&
				candidate.groups.some(
					(member: MetricCatalogDomainRow) =>
						String(member.grupo_eleccion_id) === String(group.grupo_eleccion_id)
				)
		);
		return family ? isFamilyFolded(family) : false;
	}

	function toggleFamilyFold(family: MetricQuestionFamily) {
		const next = new Set(expandedFamilyKeys);
		if (next.has(family.key)) next.delete(family.key);
		else next.add(family.key);
		expandedFamilyKeys = next;
	}

	/**
	 * Responde la pregunta en todas las unidades a las que se dirige, en todos los grupos que
	 * la formulan. La respuesta viaja por slug porque cada grupo tiene sus propias opciones
	 * apuntando al mismo esquema.
	 */
	function setFamilyChoice(family: MetricQuestionFamily, slug: string) {
		if (!slug) return;
		let nextChoices = [...props.choices];
		let nextUnits = [...props.units];
		for (const group of family.groups) {
			const groupId = String(group.grupo_eleccion_id);
			const option = optionsForGroup(groupId).find(
				(candidate: MetricCatalogDomainRow) => String(candidate.slug) === slug
			);
			if (!option) continue;
			const optionIds = [String(option.opcion_eleccion_id)];
			for (const unit of unitsForGroup(group)) {
				nextChoices = [
					...nextChoices.filter(
						(choice: MetricChoiceDraft) =>
							!(
								choice.grupo_eleccion_id === groupId &&
								choice.realizacion_prueba_id === unit.realizacion_prueba_id
							)
					),
					...optionIds.map((optionId) => ({
						realizacion_prueba_id: unit.realizacion_prueba_id,
						grupo_eleccion_id: groupId,
						opcion_eleccion_id: optionId,
						valor_texto: null,
						observaciones: null
					}))
				];
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
		props.onChoicesChange(nextChoices);
		commitUnits(nextUnits);
	}

	// ------------------------------------------------------------------
	// Secciones opcionales que aparecen o no en toda la composición
	// ------------------------------------------------------------------

	/** Las instancias del contenedor de una sección: las coplas, para el enlace o vuelta. */
	function parentInstancesOf(section: MetricCatalogDomainRow): MetricUnitDraft[] {
		const parentId = sectionParentId(section);
		return props.units.filter((unit: MetricUnitDraft) => unit.seccion_id === parentId);
	}

	const uniformOptionalSections = $derived(
		props.sections.filter((section: MetricCatalogDomainRow) => {
			if (sectionMinimum(section) !== 0 || sectionMaximum(section) !== 1) return false;
			if (controlledSectionIds.has(sectionId(section))) return false;
			return parentInstancesOf(section).length >= 1;
		})
	);

	function optionalPresence(section: MetricCatalogDomainRow) {
		const parents = parentInstancesOf(section);
		const withSection = parents.filter((parent: MetricUnitDraft) =>
			props.units.some(
				(unit: MetricUnitDraft) =>
					unit.realizacion_padre_id === parent.realizacion_prueba_id &&
					unit.seccion_id === sectionId(section)
			)
		);
		return {
			parents,
			present: withSection.length,
			everywhere: withSection.length === parents.length && parents.length > 0,
			nowhere: withSection.length === 0
		};
	}

	function setOptionalSectionEverywhere(section: MetricCatalogDomainRow, present: boolean) {
		const targetSectionId = sectionId(section);
		let nextUnits = [...props.units];
		for (const parent of parentInstancesOf(section)) {
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
	// Cuántas veces se repite una sección, y qué se ve de cada repetición
	// ------------------------------------------------------------------

	function nodeInstanceMinimum(section: MetricCatalogDomainRow | null): number {
		return section ? sectionMinimum(section) : 1;
	}

	function nodeInstanceMaximum(section: MetricCatalogDomainRow | null): number | null {
		return section ? sectionMaximum(section) : null;
	}

	/** Cuántas hay es un dato, no una acción repetida: se escribe en vez de pulsar. */
	function setInstanceCount(
		section: MetricCatalogDomainRow | null,
		parentUnitId: string | null,
		value: number
	) {
		const current = instances(section, parentUnitId);
		const minimum = nodeInstanceMinimum(section);
		const maximum = nodeInstanceMaximum(section);
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
		commitUnits(nextUnits);
	}

	function subtreeUnits(unit: MetricUnitDraft): MetricUnitDraft[] {
		const ids = unitIdsInTree(props.units, unit.realizacion_prueba_id);
		return props.units.filter((candidate: MetricUnitDraft) =>
			ids.has(candidate.realizacion_prueba_id)
		);
	}

	/**
	 * Qué contesta una realización, sin sus identificadores: dos unidades con la misma
	 * firma dicen exactamente lo mismo. Sirve para no pintar doce tarjetas iguales cuando
	 * una tirada de redondillas responde doce veces la misma norma.
	 */
	function unitSignature(unit: MetricUnitDraft): string {
		const parts: string[] = [];
		for (const node of subtreeUnits(unit)) {
			const answers = props.choices
				.filter(
					(choice: MetricChoiceDraft) =>
						choice.realizacion_prueba_id === node.realizacion_prueba_id
				)
				.map(
					(choice: MetricChoiceDraft) =>
						`${choice.grupo_eleccion_id}:${choice.opcion_eleccion_id ?? ''}:${choice.valor_texto ?? ''}`
				)
				.sort();
			parts.push(
				`${node.seccion_id ?? 'unidad'}#${node.v_fin - node.v_ini + 1}[${answers.join(',')}]`
			);
		}
		return parts.sort().join('|');
	}

	/** Las repeticiones desplegadas a mano, por sección y contenedor. */
	let expandedRepeatKeys = $state<Set<string>>(new Set());

	function repeatKey(
		section: MetricCatalogDomainRow | null,
		parentUnitId: string | null
	): string {
		return `${nodeSectionId(section) ?? 'unidad'}|${parentUnitId ?? 'raiz'}`;
	}

	function toggleRepeatFold(key: string) {
		const next = new Set(expandedRepeatKeys);
		if (next.has(key)) next.delete(key);
		else next.add(key);
		expandedRepeatKeys = next;
	}

	/** Todas las repeticiones dicen lo mismo, así que basta con enseñar una. */
	function instancesAreUniform(units: MetricUnitDraft[]): boolean {
		if (units.length < 2) return false;
		const first = unitSignature(units[0]);
		return units.every((unit: MetricUnitDraft) => unitSignature(unit) === first);
	}

	/**
	 * Responde en la realización que se está viendo y repite la respuesta en todas sus
	 * equivalentes. Es lo que hace que editar la tarjeta única de «12 redondillas» no
	 * desparejе en silencio la primera de las once restantes.
	 */
	function setChoicesAcrossEquivalents(
		group: MetricCatalogDomainRow,
		sourceUnit: MetricUnitDraft,
		optionIds: string[],
		siblings: MetricUnitDraft[]
	) {
		const groupId = String(group.grupo_eleccion_id);
		let nextChoices = [...props.choices];
		let nextUnits = [...props.units];
		for (const unit of siblings) {
			nextChoices = [
				...nextChoices.filter(
					(choice: MetricChoiceDraft) =>
						!(
							choice.grupo_eleccion_id === groupId &&
							choice.realizacion_prueba_id === unit.realizacion_prueba_id
						)
				),
				...optionIds.map((optionId) => ({
					realizacion_prueba_id: unit.realizacion_prueba_id,
					grupo_eleccion_id: groupId,
					opcion_eleccion_id: optionId,
					valor_texto: null,
					observaciones: null
				}))
			];
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
		props.onChoicesChange(nextChoices);
		commitUnits(nextUnits);
	}

	function setChoiceTextAcrossEquivalents(
		group: MetricCatalogDomainRow,
		value: string,
		siblings: MetricUnitDraft[]
	) {
		const groupId = String(group.grupo_eleccion_id);
		const normalized = normalizeRhymeScheme(value);
		let nextChoices = [...props.choices];
		for (const unit of siblings) {
			nextChoices = [
				...nextChoices.filter(
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
			];
		}
		props.onChoicesChange(nextChoices);
	}

	/** Una repetición está resuelta cuando no le falta ninguna respuesta obligatoria. */
	function subtreeAnswered(unit: MetricUnitDraft): boolean {
		let asked = 0;
		for (const node of subtreeUnits(unit)) {
			for (const group of groupsForUnit(node)) {
				asked += 1;
				const total = props.choices.filter(
					(choice: MetricChoiceDraft) =>
						choice.grupo_eleccion_id === String(group.grupo_eleccion_id) &&
						choice.realizacion_prueba_id === node.realizacion_prueba_id
				).length;
				if (total < Number(group.selecciones_min ?? 0)) return false;
				if (total === 0) return false;
			}
		}
		return asked > 0;
	}

	function subtreeSummary(unit: MetricUnitDraft): string {
		const parts: string[] = [];
		for (const node of subtreeUnits(unit)) {
			for (const group of groupsForUnit(node)) {
				if (isFolded(group)) continue;
				for (const choice of props.choices) {
					if (
						choice.grupo_eleccion_id !== String(group.grupo_eleccion_id) ||
						choice.realizacion_prueba_id !== node.realizacion_prueba_id
					) {
						continue;
					}
					if (choice.valor_texto) {
						parts.push(choice.valor_texto);
						continue;
					}
					const option = props.options.find(
						(candidate: MetricCatalogDomainRow) =>
							String(candidate.opcion_eleccion_id) === choice.opcion_eleccion_id
					);
					if (option) parts.push(String(option.nombre));
				}
			}
		}
		return [...new Set(parts)].join(' · ');
	}

	function toggleUnitFold(unit: MetricUnitDraft) {
		const next = new Set(expandedUnitIds);
		if (next.has(unit.realizacion_prueba_id)) next.delete(unit.realizacion_prueba_id);
		else next.add(unit.realizacion_prueba_id);
		expandedUnitIds = next;
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
		return value.replace(/\s+/g, '').toLocaleUpperCase('es');
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
		const lastVerse = next.reduce(
			(maximum, unit) => Math.max(maximum, unit.v_fin),
			props.sequenceStart
		);
		props.onRangeChange(lastVerse);
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
		commitUnits(
			addSectionInstance(
				props.units,
				props.sections,
				targetSectionId,
				parentUnitId,
				props.sequenceStart,
				props.choices,
				props.options
			)
		);
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
		props.onRangeChange(
			remaining.reduce(
				(maximum, item) => Math.max(maximum, item.v_fin),
				props.sequenceStart
			)
		);
	}

	function setUnitLength(unit: MetricUnitDraft, value: number) {
		const section =
			props.sections.find(
				(row: MetricCatalogDomainRow) => sectionId(row) === unit.seccion_id
			) ?? null;
		if (!section && !unitExtent) return;
		const minimum = nodeVerseMinimum(section);
		const maximum = nodeVerseMaximum(section);
		const length = Math.max(
			minimum,
			maximum === null ? value : Math.min(maximum, value)
		);
		const changed = props.units.map((item: MetricUnitDraft) =>
			item.realizacion_prueba_id === unit.realizacion_prueba_id
				? { ...item, v_fin: item.v_ini + length - 1 }
				: item
		);
		const hiddenPositionalOptionIds = new Set(
			props.options
				.filter(
					(option: MetricCatalogDomainRow) =>
						Number(option.posicion_unidad ?? 0) > length
				)
				.map((option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id))
		);
		if (hiddenPositionalOptionIds.size > 0) {
			props.onChoicesChange(
				props.choices.filter(
					(choice: MetricChoiceDraft) =>
						choice.realizacion_prueba_id !== unit.realizacion_prueba_id ||
						!choice.opcion_eleccion_id ||
						!hiddenPositionalOptionIds.has(choice.opcion_eleccion_id)
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
		const hiddenPositionalOptionIds = new Set(
			props.options
				.filter(
					(option: MetricCatalogDomainRow) =>
						Number(option.posicion_unidad ?? 0) > length
				)
				.map((option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id))
		);
		if (hiddenPositionalOptionIds.size > 0) {
			props.onChoicesChange(
				props.choices.filter(
					(choice: MetricChoiceDraft) =>
						!equivalentUnitIds.has(choice.realizacion_prueba_id ?? '') ||
						!choice.opcion_eleccion_id ||
						!hiddenPositionalOptionIds.has(choice.opcion_eleccion_id)
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

	function setChoices(
		group: MetricCatalogDomainRow,
		unit: MetricUnitDraft,
		optionIds: string[]
	) {
		const groupId = String(group.grupo_eleccion_id);
		const nextChoices = [
			...props.choices.filter(
				(choice: MetricChoiceDraft) =>
					!(
						choice.grupo_eleccion_id === groupId &&
						choice.realizacion_prueba_id === unit.realizacion_prueba_id
					)
			),
			...optionIds.map((optionId) => ({
				realizacion_prueba_id: unit.realizacion_prueba_id,
				grupo_eleccion_id: groupId,
				opcion_eleccion_id: optionId,
				valor_texto: null,
				observaciones: null
			}))
		];
		props.onChoicesChange(nextChoices);
		const nextUnits = syncChoiceMaterializedSections(
			props.units,
			props.sections,
			unit.realizacion_prueba_id,
			optionsForGroup(groupId),
			optionIds,
			props.sequenceStart,
			nextChoices,
			props.options
		);
		commitUnits(nextUnits);
	}

	/**
	 * Las demás preguntas de medida de la misma arquitectura, cada una colgada de otra
	 * sección. Son las que hacen que un villancico isosilábico obligue a responder seis
	 * veces lo mismo.
	 */
	function siblingMeasureGroups(group: MetricCatalogDomainRow): MetricCatalogDomainRow[] {
		if (group.dimension !== 'metro' || !group.seccion_id) return [];
		return props.groups.filter(
			(candidate: MetricCatalogDomainRow) =>
				candidate.dimension === 'metro' &&
				candidate.seccion_id &&
				String(candidate.grupo_eleccion_id) !== String(group.grupo_eleccion_id)
		);
	}

	/**
	 * Lleva la medida respondida a las demás secciones. Propaga el metro y no la opción,
	 * porque cada sección tiene sus propias opciones apuntando a los mismos metros.
	 */
	function applyMeasureToEverySection(
		group: MetricCatalogDomainRow,
		sourceUnit: MetricUnitDraft
	) {
		const groupId = String(group.grupo_eleccion_id);
		const selected = new Set(selectedChoiceIds(groupId, sourceUnit.realizacion_prueba_id));
		const metros = new Set(
			optionsForGroup(groupId)
				.filter((option: MetricCatalogDomainRow) =>
					selected.has(String(option.opcion_eleccion_id))
				)
				.map((option: MetricCatalogDomainRow) => String(option.metro_id))
		);
		if (metros.size === 0) return;

		let nextChoices = [...props.choices];
		for (const target of siblingMeasureGroups(group)) {
			const targetId = String(target.grupo_eleccion_id);
			const targetOptions = optionsForGroup(targetId).filter(
				(option: MetricCatalogDomainRow) => metros.has(String(option.metro_id))
			);
			if (targetOptions.length === 0) continue;

			const targetUnits = props.units.filter(
				(unit: MetricUnitDraft) => unit.seccion_id === String(target.seccion_id)
			);
			for (const unit of targetUnits) {
				nextChoices = [
					...nextChoices.filter(
						(choice: MetricChoiceDraft) =>
							!(
								choice.grupo_eleccion_id === targetId &&
								choice.realizacion_prueba_id === unit.realizacion_prueba_id
							)
					),
					...targetOptions.map((option: MetricCatalogDomainRow) => ({
						realizacion_prueba_id: unit.realizacion_prueba_id,
						grupo_eleccion_id: targetId,
						opcion_eleccion_id: String(option.opcion_eleccion_id),
						valor_texto: null,
						observaciones: null
					}))
				];
			}
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
		const nextChoices = [
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
		];
		props.onChoicesChange(nextChoices);
	}

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
		const equivalentUnits = props.units.filter(
			(unit: MetricUnitDraft) => unit.seccion_id === sourceUnit.seccion_id
		);

		for (const unit of equivalentUnits) {
			nextChoices = [
				...nextChoices.filter(
					(choice) =>
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

	function instances(section: MetricCatalogDomainRow | null, parentUnitId: string | null) {
		return props.units.filter(
			(unit: MetricUnitDraft) =>
				unit.seccion_id === nodeSectionId(section) &&
				unit.realizacion_padre_id === parentUnitId
		);
	}

	function canAdd(section: MetricCatalogDomainRow | null, parentUnitId: string | null): boolean {
		// Cuántas unidades contiene el pasaje se deriva del rango: no se añaden a mano.
		if (isUnitNode(section, parentUnitId)) return !(props.unitPlan?.countFromRange ?? false);
		if (!section) return false;
		const maximum = sectionMaximum(section);
		return maximum === null || instances(section, parentUnitId).length < maximum;
	}

	function canRemove(
		section: MetricCatalogDomainRow | null,
		parentUnitId: string | null
	): boolean {
		if (isUnitNode(section, parentUnitId)) {
			return !(props.unitPlan?.countFromRange ?? false) && instances(section, parentUnitId).length > 1;
		}
		if (!section) return false;
		return instances(section, parentUnitId).length > sectionMinimum(section);
	}

	function selectedExtensionReference(unit: MetricUnitDraft): MetricCatalogDomainRow | null {
		const option = props.options.find(
			(candidate: MetricCatalogDomainRow) =>
				String(candidate.materializa_seccion_id ?? '') === unit.seccion_id &&
				Boolean(candidate.extension_desde_seccion_id) &&
				props.choices.some(
					(choice: MetricChoiceDraft) =>
						choice.opcion_eleccion_id === String(candidate.opcion_eleccion_id) &&
						choice.realizacion_prueba_id === unit.realizacion_padre_id
				)
		);
		if (!option?.extension_desde_seccion_id) return null;
		const referenceSectionId = String(option.extension_desde_seccion_id);
		if (
			!props.units.some(
				(unit: MetricUnitDraft) => unit.seccion_id === referenceSectionId
			)
		) {
			return null;
		}
		return (
			props.sections.find(
				(section: MetricCatalogDomainRow) =>
					sectionId(section) === referenceSectionId
			) ?? null
		);
	}
</script>

{#snippet renderSection(
	section: MetricCatalogDomainRow | null,
	parentUnitId: string | null,
	depth: number
)}
	{@const sectionInstances = instances(section, parentUnitId)}
	{@const childSections = childrenOfSection(props.sections, nodeSectionId(section))}
	{@const numbered = section
		? sectionMaximum(section) === null || Number(sectionMaximum(section)) > 1
		: true}
	{@const foldKey = repeatKey(section, parentUnitId)}
	{@const uniform = instancesAreUniform(sectionInstances)}
	<!--
		Una repetición solo merece plegarse si dentro hay algo que responder. La estancia
		regular de la canción petrarquista tiene medida y rima fijadas por la norma: ofrecer
		«editar una concreta» prometería una edición que no existe. En ese caso las
		realizaciones se resumen en una línea y se acabó.
	-->
	{@const editableInstances = sectionInstances.some(
		(unit: MetricUnitDraft) =>
			childSections.length > 0 ||
			groupsForUnit(unit).length > 0 ||
			(!selectedExtensionReference(unit) && !nodeHasFixedLength(section))
	)}
	{@const settledRepeat = uniform && !editableInstances}
	<!-- Doce redondillas que dicen lo mismo son una tarjeta y un recuento, no doce tarjetas. -->
	{@const uniformRepeat = uniform && editableInstances && !expandedRepeatKeys.has(foldKey)}
	{@const shownInstances = settledRepeat
		? []
		: uniformRepeat
			? sectionInstances.slice(0, 1)
			: sectionInstances}
	<div
		class={depth === 0
			? 'space-y-3'
			: 'space-y-3 border-l border-[color:var(--border)] pl-3'}
	>
		{#if settledRepeat}
			{@const first = sectionInstances[0]}
			{@const last = sectionInstances[sectionInstances.length - 1]}
			{@const length = first.v_fin - first.v_ini + 1}
			<p class="text-sm text-[color:var(--muted-foreground)]">
				{nodeLabel(section)} · {sectionInstances.length} realizaciones · vv. {first.v_ini}–{last.v_fin}
				· {length} versos cada una · la norma las fija enteras
			</p>
		{:else if uniformRepeat}
			<!-- Decir «4 realizaciones iguales» obliga a abrirlas para saber en qué quedaron.
			     Con lo respondido delante, la línea se lee sola y el botón deja de ser una
			     comprobación obligatoria para ser una corrección voluntaria. -->
			{@const acordado = subtreeSummary(sectionInstances[0])}
			<p class="flex flex-wrap items-baseline justify-between gap-2 text-sm">
				<span class="text-[color:var(--muted-foreground)]">
					{nodeLabel(section)} · las {sectionInstances.length} iguales{acordado
						? ` · ${acordado}`
						: ''}
				</span>
				<button type="button" class="link-action" onclick={() => toggleRepeatFold(foldKey)}>
					Corregir una concreta
				</button>
			</p>
		{:else if sectionInstances.length > 1 && uniform && expandedRepeatKeys.has(foldKey)}
			<p class="flex justify-end">
				<button type="button" class="link-action" onclick={() => toggleRepeatFold(foldKey)}>
					Volver a la vista única
				</button>
			</p>
		{/if}
		{#each shownInstances as unit, unitIndex (unit.realizacion_prueba_id)}
			{@const extensionReference = selectedExtensionReference(unit)}
			{@const heading = uniformRepeat
				? `Cada ${nodeLabel(section).toLocaleLowerCase('es')}`
				: `${nodeLabel(section)}${numbered ? ` ${unitIndex + 1}` : ''}`}
			<!-- Una sección cuya extensión ya está decidida y que no pregunta nada no necesita
			     ni tarjeta ni cabecera: se resume en la línea que dice dónde empieza y acaba. -->
			{@const settled =
				childSections.length === 0 &&
				groupsForUnit(unit).length === 0 &&
				(Boolean(extensionReference) || nodeHasFixedLength(section))}
			{@const folded =
				depth > 0 &&
				!settled &&
				!expandedUnitIds.has(unit.realizacion_prueba_id) &&
				subtreeAnswered(unit)}
			<!-- La extensión, cuando no se puede tocar, se dice en la misma línea del rango. -->
			{@const extentNote =
				childSections.length > 0
					? 'rango calculado desde sus partes'
					: extensionReference
						? `${unit.v_fin - unit.v_ini + 1} versos, calculados desde «${sectionLabel(extensionReference)}»`
						: nodeHasFixedLength(section)
							? `${nodeVerseMinimum(section)} versos fijos`
							: ''}
			{#if depth > 0 && settled}
				<p class="flex flex-wrap items-baseline justify-between gap-2 text-sm text-[color:var(--muted-foreground)]">
					<span title={extentNote ? EXTENT_HELP : undefined}>
						{heading} · vv. {unit.v_ini}–{unit.v_fin}{extentNote ? ` · ${extentNote}` : ''}
					</span>
					{#if canRemove(section, parentUnitId)}
						<button
							type="button"
							class="link-action link-action--danger link-action--sm"
							onclick={() => removeInstance(unit)}
						>
							Quitar
						</button>
					{/if}
				</p>
			{:else if folded}
				{@const summary = subtreeSummary(unit)}
				<p class="flex flex-wrap items-baseline justify-between gap-2 border border-[color:var(--border)] bg-white px-3 py-2 text-sm">
					<span>
						<span class="font-medium">{heading}</span>
						<span class="text-[color:var(--muted-foreground)]">
							· vv. {unit.v_ini}–{unit.v_fin}{summary ? ` · ${summary}` : ''}
						</span>
					</span>
					<span class="flex shrink-0 gap-3">
						<button
							type="button"
							class="link-action link-action--sm"
							onclick={() => toggleUnitFold(unit)}
						>
							Editar
						</button>
						{#if canRemove(section, parentUnitId)}
							<button
								type="button"
								class="link-action link-action--danger link-action--sm"
								onclick={() => removeInstance(unit)}
							>
								Quitar
							</button>
						{/if}
					</span>
				</p>
			{:else}
			<div class={depth === 0 ? 'border border-[color:var(--border)] bg-[color:var(--card)]' : 'space-y-3'}>
				<div
					class={depth === 0
						? 'flex flex-wrap items-center justify-between gap-3 border-b border-[color:var(--border)] bg-[color:var(--muted)] px-4 py-3'
						: 'flex flex-wrap items-baseline justify-between gap-2'}
				>
					{#if depth === 0}
						<div>
							<h5 class="font-medium">{heading}</h5>
							<p
								class="text-xs text-[color:var(--muted-foreground)]"
								title={extentNote ? EXTENT_HELP : undefined}
							>
								vv. {unit.v_ini}–{unit.v_fin}{extentNote ? ` · ${extentNote}` : ''}
							</p>
						</div>
					{:else}
						<div class="flex flex-wrap items-baseline gap-2">
							<span class="form-label mb-0">{heading}</span>
							<span
								class="text-xs text-[color:var(--muted-foreground)]"
								title={extentNote ? EXTENT_HELP : undefined}
							>
								vv. {unit.v_ini}–{unit.v_fin}{extentNote ? ` · ${extentNote}` : ''}
							</span>
						</div>
					{/if}
					<span class="flex shrink-0 gap-3">
						{#if depth > 0 && expandedUnitIds.has(unit.realizacion_prueba_id) && subtreeAnswered(unit)}
							<button
								type="button"
								class="link-action"
								onclick={() => toggleUnitFold(unit)}
							>
								Plegar
							</button>
						{/if}
						{#if canRemove(section, parentUnitId)}
							<button
								type="button"
								class="link-action link-action--danger"
								onclick={() => removeInstance(unit)}
							>
								Quitar
							</button>
						{/if}
					</span>
				</div>

				<div class={depth === 0 ? 'space-y-4 p-4' : 'space-y-4'}>
					{#if childSections.length === 0}
						{#if !extensionReference && !nodeHasFixedLength(section)}
							<div class="flex flex-wrap items-end gap-3">
								<label class="form-field w-36">
									<span class="form-label">N.º de versos</span>
									<input
										type="number"
										min={nodeVerseMinimum(section)}
										max={nodeVerseMaximum(section) ?? undefined}
										class="h-10 border border-[color:var(--border)] px-3"
										value={unit.v_fin - unit.v_ini + 1}
										onchange={(event) =>
											setUnitLength(unit, Number(event.currentTarget.value))}
									/>
								</label>
								{#if props.units.filter(
									(candidate: MetricUnitDraft) =>
										candidate.seccion_id === unit.seccion_id
								).length > 1}
									<button
										type="button"
										class="link-action link-action--sm h-10"
										onclick={() => applyUnitLengthToEquivalentUnits(unit)}
									>
										Aplicar esta extensión a todas las unidades equivalentes
									</button>
								{/if}
							</div>
						{/if}
					{/if}

					{#each childSections as childSection}
						{@render renderSection(childSection, unit.realizacion_prueba_id, depth + 1)}
					{/each}

					{#each visibleGroupsForUnit(unit) as group (String(group.grupo_eleccion_id))}
						<MetricChoiceField
							{group}
							options={optionsForGroup(String(group.grupo_eleccion_id))}
							selectedIds={selectedChoiceIds(
								String(group.grupo_eleccion_id),
								unit.realizacion_prueba_id
							)}
							onChange={(ids) =>
								uniformRepeat
									? setChoicesAcrossEquivalents(group, unit, ids, sectionInstances)
									: setChoices(group, unit, ids)}
							textValue={choiceTextValue(
								String(group.grupo_eleccion_id),
								unit.realizacion_prueba_id
							)}
							onTextChange={(value) =>
								uniformRepeat
									? setChoiceTextAcrossEquivalents(group, value, sectionInstances)
									: setChoiceText(group, unit, value)}
							onApplyAll={uniformRepeat
								? undefined
								: () => applyChoiceToEquivalentUnits(group, unit)}
							onApplyToEverySection={siblingMeasureGroups(group).length > 0
								? () => applyMeasureToEverySection(group, unit)
								: undefined}
							positionLimit={unit.v_fin - unit.v_ini + 1}
						/>
					{/each}
				</div>
			</div>
			{/if}
		{/each}

		{#if !controlledSectionIds.has(nodeSectionId(section) ?? '')}
			{@const countable =
				nodeInstanceMaximum(section) === null || Number(nodeInstanceMaximum(section)) > 1}
			{#if countable && (canAdd(section, parentUnitId) || canRemove(section, parentUnitId))}
				<label class="flex flex-wrap items-baseline gap-2 text-sm">
					<span class="text-[color:var(--muted-foreground)]">
						N.º de {nodeLabel(section).toLocaleLowerCase('es')}
					</span>
					<input
						type="number"
						min={nodeInstanceMinimum(section)}
						max={nodeInstanceMaximum(section) ?? undefined}
						class="h-9 w-20 border border-[color:var(--border)] px-2"
						value={sectionInstances.length}
						onchange={(event) =>
							setInstanceCount(section, parentUnitId, Number(event.currentTarget.value))}
					/>
				</label>
			{:else if canAdd(section, parentUnitId)}
				<button
					type="button"
					class={depth === 0
						? 'w-full border border-dashed border-[color:var(--border)] px-4 py-3 text-sm font-medium text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)]'
						: 'link-action'}
					onclick={() => addInstance(nodeSectionId(section), parentUnitId)}
				>
					+ Añadir {nodeLabel(section).toLocaleLowerCase('es')}
				</button>
			{/if}
		{/if}
	</div>
{/snippet}

<div class="space-y-4">
	<!-- Veintiuna de las treinta y siete arquitecturas del catálogo no preguntan nada: la forma
	     queda registrada al elegirla. Es el caso más frecuente y hasta ahora se veía como un
	     hueco, que se lee como «falta algo» en vez de como «ya está». -->
	{#if props.groups.length === 0}
		<p class="border border-[color:var(--border)] bg-[color:var(--gray-50)] px-3 py-2 text-sm text-[color:var(--muted-foreground)]">
			Esta forma no necesita ninguna respuesta: su arquitectura la fija entera.
		</p>
	{/if}

	{#if props.globalQuestions || foldableFamilies.length > 0 || uniformOptionalSections.length > 0}
		<div class="space-y-3 border-b border-[color:var(--border)] pb-4">
			<p class="form-section-title mb-0">Así es toda la composición</p>

			{@render props.globalQuestions?.()}

			{#each foldableFamilies as family (family.key)}
				{@const state = familyState(family)}
				{@const familyFolded = isFamilyFolded(family)}
				{@const options = familyOptions(family)}
				{@const control = controlDePregunta(options.length, familyMinimum(family))}
				<div class="form-field">
					<span class="form-label">
						<span class="form-label-with-help">
							{family.label}
							{#if family.help}
								<FieldHelpTooltip
									text={family.help}
									label={`Ayuda sobre «${family.label}»`}
								/>
							{/if}
						</span>
					</span>
					<div class="flex flex-wrap items-center gap-3">
						<MetricFamilyControl
							{control}
							{options}
							uniform={state.uniform}
							answered={state.answered}
							name={family.key}
							onChoose={(slug) => setFamilyChoice(family, slug)}
						/>
						{#if state.units.length > 1}
							<button
								type="button"
								class="link-action link-action--sm"
								onclick={() => toggleFamilyFold(family)}
							>
								{familyFolded
									? `Corregir alguna de las ${state.units.length}`
									: 'Volver a una sola respuesta'}
							</button>
						{/if}
					</div>
				</div>
			{/each}

			{#each uniformOptionalSections as section (sectionId(section))}
				{@const presence = optionalPresence(section)}
				<div class="form-field">
					<span class="form-label">¿Aparece «{sectionLabel(section)}»?</span>
					<div class="flex flex-wrap items-center gap-3">
						<SegmentedChoice
							items={[
								{ id: 'si', label: presence.parents.length > 1 ? 'En todas' : 'Sí' },
								{ id: 'no', label: presence.parents.length > 1 ? 'En ninguna' : 'No' }
							]}
							value={presence.everywhere ? 'si' : presence.nowhere ? 'no' : null}
							onChange={(id) => setOptionalSectionEverywhere(section, id === 'si')}
							ariaLabel={`¿Aparece ${sectionLabel(section)}?`}
						/>
						{#if !presence.everywhere && !presence.nowhere}
							<span class="text-xs text-[color:var(--muted-foreground)]">
								Aparece en {presence.present} de {presence.parents.length}; se corrige abajo.
							</span>
						{/if}
					</div>
				</div>
			{/each}
		</div>
	{/if}

	<div class="space-y-5">
		{#each roots as root}
			{@render renderSection(root, null, 0)}
		{/each}
	</div>
</div>

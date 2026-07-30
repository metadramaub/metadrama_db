<script lang="ts">
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import MetricChoiceField from './MetricChoiceField.svelte';
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
		sectionVerseMaximum,
		sectionVerseMinimum,
		syncChoiceMaterializedSections,
		unitIdsInTree,
		type MetricChoiceDraft,
		type MetricUnitAnchor,
		type MetricUnitDraft
	} from './editor-model';

	const props = $props<{
		sequenceStart: number;
		sections: MetricCatalogDomainRow[];
		groups: MetricCatalogDomainRow[];
		options: MetricCatalogDomainRow[];
		units: MetricUnitDraft[];
		choices: MetricChoiceDraft[];
		unitAnchor: MetricUnitAnchor | null;
		unitCountIsDerived: boolean;
		onUnitsChange: (units: MetricUnitDraft[]) => void;
		onChoicesChange: (choices: MetricChoiceDraft[]) => void;
		onUnitsRemoved: (unitIds: string[]) => void;
		onRangeChange: (end: number) => void;
	}>();

	/**
	 * Los nodos de primer nivel son las realizaciones de la unidad. Cuando la unidad no es
	 * ninguna sección —la forma declara su extensión y no describe partes internas— se
	 * representa igual, con la sección nula.
	 */
	const roots = $derived<(MetricCatalogDomainRow | null)[]>(
		props.unitAnchor && props.unitAnchor.sectionId === null ? [null] : rootSections(props.sections)
	);

	/** La unidad entera, cuando el nodo no realiza ninguna sección. */
	const unitExtent = $derived(props.unitAnchor?.extent ?? null);

	function nodeSectionId(section: MetricCatalogDomainRow | null): string | null {
		return section ? sectionId(section) : null;
	}

	function nodeLabel(section: MetricCatalogDomainRow | null): string {
		return section ? sectionLabel(section) : 'Unidad';
	}

	function isUnitNode(section: MetricCatalogDomainRow | null, parentUnitId: string | null): boolean {
		return (
			parentUnitId === null &&
			props.unitAnchor !== null &&
			nodeSectionId(section) === props.unitAnchor.sectionId
		);
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
			if (group.alcance !== 'unidad') return false;
			// Una pregunta sin sección se refiere a la unidad entera, no a una parte suya.
			return group.seccion_id
				? String(group.seccion_id) === unit.seccion_id
				: unit.realizacion_padre_id === null;
		});
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
			if (!props.unitAnchor) return;
			commitUnits(
				addMetricUnit(
					props.units,
					props.sections,
					props.unitAnchor,
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
		if (isUnitNode(section, parentUnitId)) return !props.unitCountIsDerived;
		if (!section) return false;
		const maximum = sectionMaximum(section);
		return maximum === null || instances(section, parentUnitId).length < maximum;
	}

	function canRemove(
		section: MetricCatalogDomainRow | null,
		parentUnitId: string | null
	): boolean {
		if (isUnitNode(section, parentUnitId)) {
			return !props.unitCountIsDerived && instances(section, parentUnitId).length > 1;
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
	<div class={depth === 0 ? 'space-y-3' : 'space-y-3 border-l-2 border-[color:var(--border)] pl-4'}>
		{#each sectionInstances as unit, unitIndex (unit.realizacion_prueba_id)}
			{@const extensionReference = selectedExtensionReference(unit)}
			<div class={depth === 0 ? 'border border-[color:var(--border)] bg-[color:var(--card)]' : 'space-y-3'}>
				<div
					class={depth === 0
						? 'flex flex-wrap items-center justify-between gap-3 border-b border-[color:var(--border)] bg-[color:var(--muted)] px-4 py-3'
						: 'flex flex-wrap items-start justify-between gap-3'}
				>
					<div>
						{#if depth === 0}
							<h5 class="font-medium">
								{nodeLabel(section)}
								{#if numbered}
									{unitIndex + 1}
								{/if}
							</h5>
						{:else}
							<p class="font-medium">
								{nodeLabel(section)}
								{#if numbered}
									{unitIndex + 1}
								{/if}
							</p>
						{/if}
						<p class="text-xs text-[color:var(--muted-foreground)]">
							vv. {unit.v_ini}–{unit.v_fin}
							{#if childSections.length > 0}
								· rango calculado desde sus partes
							{/if}
						</p>
					</div>
					{#if canRemove(section, parentUnitId)}
						<button
							type="button"
							class="text-sm text-red-700 hover:underline"
							onclick={() => removeInstance(unit)}
						>
							Quitar
						</button>
					{/if}
				</div>

				<div class={depth === 0 ? 'space-y-4 p-4' : 'space-y-4'}>
					{#if childSections.length === 0}
						{#if extensionReference}
							<p class="text-sm text-[color:var(--muted-foreground)]">
								Extensión calculada desde «{sectionLabel(extensionReference)}»:
								{unit.v_fin - unit.v_ini + 1} versos.
							</p>
						{:else if nodeHasFixedLength(section)}
							<p class="text-sm text-[color:var(--muted-foreground)]">
								{nodeVerseMinimum(section)}
								{nodeVerseMinimum(section) === 1 ? 'verso' : 'versos'} según la norma.
							</p>
						{:else}
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
										class="h-10 text-xs font-medium text-[color:var(--primary)] hover:underline"
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

					{#each groupsForUnit(unit) as group (String(group.grupo_eleccion_id))}
						<MetricChoiceField
							{group}
							options={optionsForGroup(String(group.grupo_eleccion_id))}
							selectedIds={selectedChoiceIds(
								String(group.grupo_eleccion_id),
								unit.realizacion_prueba_id
							)}
							onChange={(ids) => setChoices(group, unit, ids)}
							textValue={choiceTextValue(
								String(group.grupo_eleccion_id),
								unit.realizacion_prueba_id
							)}
							onTextChange={(value) => setChoiceText(group, unit, value)}
							onApplyAll={() => applyChoiceToEquivalentUnits(group, unit)}
							positionLimit={unit.v_fin - unit.v_ini + 1}
						/>
					{/each}
				</div>
			</div>
		{/each}

		{#if !controlledSectionIds.has(nodeSectionId(section) ?? '') && canAdd(section, parentUnitId)}
			<button
				type="button"
				class={depth === 0
					? 'border border-dashed border-[color:var(--border)] px-4 py-3 text-sm font-medium text-[color:var(--primary)] hover:bg-[color:var(--muted)]'
					: 'text-sm font-medium text-[color:var(--primary)] hover:underline'}
				onclick={() => addInstance(nodeSectionId(section), parentUnitId)}
			>
				+ Añadir {nodeLabel(section).toLocaleLowerCase('es')}
			</button>
		{/if}
	</div>
{/snippet}

<div class="space-y-5">
	{#each roots as root}
		{@render renderSection(root, null, 0)}
	{/each}
</div>

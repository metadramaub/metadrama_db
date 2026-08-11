<script lang="ts">
	import type { Snippet } from 'svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import SegmentedChoice from '$lib/components/ui/segmented-choice.svelte';
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import MetricChoiceField from './MetricChoiceField.svelte';
	import MetricFamilyControl from './MetricFamilyControl.svelte';
	import MetricGridRow from './MetricGridRow.svelte';
	import {
		addMetricUnit,
		addSectionInstance,
		reflowMetricUnits,
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
		type GridRowContext,
		type PreguntaCompartida,
		type PreguntaEnFila
	} from './grid-rows';

	/**
	 * La estructura de la secuencia, como una rejilla: a la izquierda lo que el pasaje es
	 * —unidades, secciones y sus rangos, en orden de verso—, a la derecha lo que hay que
	 * responder de cada parte.
	 *
	 * **No hay nada plegado.** Lo que se ve es lo que hay, y una fila no cambia de sitio ni
	 * aparece al pulsar nada. Arriba, cuando una pregunta apunta a dos o más realizaciones,
	 * hay una línea que las responde de una vez: no es un segundo domicilio de la pregunta,
	 * es un atajo, y las filas de abajo siguen enseñando lo que cada realización guarda.
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
		onRangeChange: (end: number) => void;
		/**
		 * Preguntas que el contenedor responde para toda la composición, ya como filas. La
		 * medida es la única por ahora: recorre las secciones, que es un eje que el editor de
		 * estructura no ve, porque él recorre las realizaciones de cada una.
		 */
		globalQuestions?: Snippet;
		/** Cómo se llama la unidad que define la forma: su nombre, no «Unidad». */
		unitLabel?: string;
	}>();

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
		unitLabel: props.unitLabel ?? 'Unidad'
	});

	const rows = $derived(buildGridRows(context));
	const comunes = $derived(preguntasCompartidas(context));
	const opcionales = $derived(seccionesOpcionalesUniformes(context));
	let respuestasComunesAbiertas = $state(new Set<string>());
	const hayZonaComun = $derived(
		Boolean(props.globalQuestions) || comunes.length > 0 || opcionales.length > 0
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
	// Las preguntas que se responden de una vez
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
	function setComunChoice(pregunta: PreguntaCompartida, slugs: string[]) {
		if (slugs.length === 0) return;
		let nextChoices = [...props.choices];
		let nextUnits = [...props.units];
		for (const group of pregunta.groups) {
			const groupId = String(group.grupo_eleccion_id);
			const optionIds = optionsForGroup(groupId)
				.filter((candidate: MetricCatalogDomainRow) => slugs.includes(String(candidate.slug)))
				.map((option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id));
			if (optionIds.length === 0) continue;
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
		props.onChoicesChange(nextChoices);
		commitUnits(nextUnits);
	}

	function abrirRespuestaComun(groupId: string, unitId: string) {
		respuestasComunesAbiertas = new Set(respuestasComunesAbiertas).add(`${groupId}|${unitId}`);
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
			remaining.reduce((maximum, item) => Math.max(maximum, item.v_fin), props.sequenceStart)
		);
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
</script>

<div class="space-y-3">
	<!-- Veintiuna de las treinta y siete arquitecturas del catálogo no preguntan nada: la forma
	     queda registrada al elegirla. Es el caso más frecuente y hasta ahora se veía como un
	     hueco, que se lee como «falta algo» en vez de como «ya está». -->
	{#if props.groups.length === 0 && !props.globalQuestions}
		<p class="border border-[color:var(--border)] bg-[color:var(--gray-50)] px-3 py-2 text-sm text-[color:var(--muted-foreground)]">
			Esta forma no necesita ninguna respuesta: su arquitectura la fija entera.
		</p>
	{/if}

	<div class="border border-[color:var(--border)]">
		{#if hayZonaComun}
			<!-- Lo que se responde de una vez. No es otro sitio donde vivan estas preguntas: es
			     un atajo que escribe en todas, y abajo cada realización sigue enseñando la suya. -->
			<p class="form-section-title mb-0 border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2">
				Se responde una vez para todas
			</p>

			{@render props.globalQuestions?.()}

			{#each comunes as pregunta (pregunta.key)}
				{@const state = comunState(pregunta)}
				<MetricGridRow label={pregunta.label} rango={`las ${state.total}`} variant="comun">
					<div class="flex flex-wrap items-start gap-2">
						<MetricFamilyControl
							options={comunOptions(pregunta)}
							uniform={state.uniform}
							answered={state.answered}
							realizaciones={state.total}
							ariaLabel={pregunta.label}
							onChoose={(slug) => setComunChoice(pregunta, slug)}
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

			{#each opcionales as section (sectionId(section))}
				{@const presencia = presenciaDeSeccion(context, section)}
				<MetricGridRow
					label={`¿Aparece «${sectionLabel(section)}»?`}
					rango={presencia.parents.length > 1 ? `en las ${presencia.parents.length}` : ''}
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

		{#if rows.length > 0}
			<p class="form-section-title mb-0 border-b border-t border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2">
				La secuencia, verso a verso
			</p>
		{/if}

		{#each rows as row (row.key)}
			{#if row.kind === 'pregunta'}
				<MetricGridRow label={row.label} depth={row.depth}>
					{#each row.preguntas as pregunta (String(pregunta.group.grupo_eleccion_id))}
						{@render campo(pregunta)}
					{/each}
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
						{#each row.preguntas as pregunta (String(pregunta.group.grupo_eleccion_id))}
							{@render campo(pregunta)}
						{/each}
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
						: ''}
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
							+ Añadir {row.label.toLocaleLowerCase('es')}
						</button>
					{/if}
				</MetricGridRow>
			{:else}
				<MetricGridRow
					label={row.label}
					rango={`vv. ${row.unit.v_ini}–${row.unit.v_fin}`}
					nota={row.nota}
					notaAyuda={row.nota ? EXTENT_HELP : undefined}
					depth={row.depth}
				>
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
							{#if row.equivalentes > 1}
								<button
									type="button"
									class="link-action"
									onclick={() => applyUnitLengthToEquivalentUnits(row.unit)}
								>
									Esta extensión en las {row.equivalentes}
								</button>
							{/if}
						</div>
					{/if}

					{#each row.preguntas as pregunta (String(pregunta.group.grupo_eleccion_id))}
						{@render campo(pregunta, row.equivalentes)}
					{/each}

					{#if row.removable}
						<button
							type="button"
							class="link-action link-action--danger self-start"
							onclick={() => removeInstance(row.unit)}
						>
							Quitar {nodeLabel(context, row.section).toLocaleLowerCase('es')}
						</button>
					{/if}
				</MetricGridRow>
			{/if}
		{/each}
	</div>
</div>

<!--
	Una pregunta dentro de una fila.

	`pregunta.owner` no siempre es la realización de la fila: los dos esquemas del soneto se
	preguntan en la fila de sus cuartetos o de sus tercetos y se guardan en la unidad, porque
	describen cómo se entrelazan las rimas de las dos secciones y no pertenecen a ninguna.

	El enunciado se repite en cada fila a propósito. Se podría deducir de la columna de la
	izquierda y de la pregunta común de arriba, pero deducirlo es trabajo, y lo que se ganaba
	quitándolo no compensa tener que averiguar de qué va un desplegable.
-->
{#snippet campo(pregunta: PreguntaEnFila, equivalentes = 1)}
	{@const group = pregunta.group}
	{@const groupId = String(group.grupo_eleccion_id)}
	{@const unit = pregunta.owner}
	{@const estado = estadoDeRespuesta(context, group, unit)}
	{@const yaArriba = comunes.some((comun: PreguntaCompartida) =>
		comun.groups.some(
			(miembro: MetricCatalogDomainRow) => String(miembro.grupo_eleccion_id) === groupId
		)
	)}
	{@const claveComun = `${groupId}|${unit.realizacion_prueba_id}`}
	{@const compacta =
		yaArriba && estado === 'igual' && !respuestasComunesAbiertas.has(claveComun)}
	<!--
		La respuesta que coincide con la de sus equivalentes se atenúa: ya se lee arriba y aquí
		solo confirma. La que diverge y la que falta se leen enteras.
	-->
	<div class={estado === 'igual' ? 'opacity-70' : ''}>
		<MetricChoiceField
			{group}
			variant="celda"
			label={pregunta.label}
			showDescription={estado !== 'igual'}
			compact={compacta}
			onExpand={compacta
				? () => abrirRespuestaComun(groupId, unit.realizacion_prueba_id)
				: undefined}
			options={optionsForGroup(groupId)}
			selectedIds={selectedChoiceIds(groupId, unit.realizacion_prueba_id)}
			onChange={(ids) => setChoices(group, unit, ids)}
			textValue={choiceTextValue(groupId, unit.realizacion_prueba_id)}
			onTextChange={(value) => setChoiceText(group, unit, value)}
			onApplyAll={!yaArriba && equivalentes > 1
				? () => applyChoiceToEquivalentUnits(group, unit)
				: undefined}
			positionLimit={unit.v_fin - unit.v_ini + 1}
		/>
	</div>
{/snippet}

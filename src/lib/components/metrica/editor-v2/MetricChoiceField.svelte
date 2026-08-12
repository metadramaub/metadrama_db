<script lang="ts">
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import { renderInlineMarkdown, stripMarkdown } from '$lib/utils/markdown';
	import { controlDePregunta } from '$lib/metrica/controles-formulario';
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import MetricPartialPositionField from './MetricPartialPositionField.svelte';
	import MetricVersePatternField from './MetricVersePatternField.svelte';
	import {
		arePositionalOptions,
		haveAlternativesByPosition,
		isPartialPositionalSelection
	} from './positional-options';

	const props = $props<{
		group: MetricCatalogDomainRow;
		options: MetricCatalogDomainRow[];
		selectedIds: string[];
		onChange: (ids: string[]) => void;
		textValue?: string;
		onTextChange?: (value: string) => void;
		onApplyAll?: () => void;
		positionStart?: number;
		positionLimit?: number;
		pendingPositions?: number[];
		onPendingPositionsChange?: (positions: number[]) => void;
		/**
		 * `celda` es la variante de la rejilla: una sola línea de alto, para que la fila de
		 * cada realización quepa junto a las demás. Las alternativas se enseñan en un
		 * desplegable aunque sean pocas, porque una lista de tres con sus explicaciones
		 * ocuparía más que la composición entera.
		 */
		variant?: 'campo' | 'celda';
		/**
		 * El enunciado, cuando la fila ya nombra la sección de la que habla y repetirla sobra:
		 * «Esquema de rima» en la fila de los cuartetos, no «Cuartetos · Esquema de rima».
		 */
		label?: string;
		/**
		 * La explicación que el catálogo deriva de la respuesta elegida. Es lo que la rejilla
		 * se dejaría por el camino al comprimir las listas en desplegables, así que se
		 * recupera debajo, y solo donde aporta: en la respuesta común y en la que diverge.
		 */
		showDescription?: boolean;
		/** Resume una respuesta común y deja el control completo para cuando se crea una excepción. */
		compact?: boolean;
		onExpand?: () => void;
		/** Explica si el resumen procede de la respuesta común o de esta unidad. */
		compactNote?: string;
		changeLabel?: string;
		hideCompactAction?: boolean;
	}>();

	const celda = $derived(props.variant === 'celda');

	const minimum = $derived(Number(props.group.selecciones_min ?? 0));
	const maximum = $derived(Number(props.group.selecciones_max ?? 1));
	const optional = $derived(minimum === 0);
	const positional = $derived(arePositionalOptions(props.options));
	const visibleOptions = $derived(
		positional
			? props.options.filter(
					(option: MetricCatalogDomainRow) =>
						(typeof props.positionStart !== 'number' ||
							Number(option.posicion_unidad) >= props.positionStart) &&
						(typeof props.positionLimit !== 'number' ||
							Number(option.posicion_unidad) <= props.positionLimit)
				)
			: props.options
	);
	const positionalAlternatives = $derived(haveAlternativesByPosition(visibleOptions));
	const partialPositionalSelection = $derived(
		isPartialPositionalSelection(props.group, visibleOptions)
	);
	const visiblePositions = $derived(
		Array.from(
			new Set<number>(
				visibleOptions.map((option: MetricCatalogDomainRow) =>
					Number(option.posicion_unidad)
				)
			)
		).sort((a: number, b: number) => a - b)
	);
	const effectiveMaximum = $derived(
		positional && typeof props.positionLimit === 'number'
			? Math.min(maximum, Math.max(1, props.positionLimit))
			: maximum
	);
	const isRhymeScheme = $derived(props.group.tipo_control === 'esquema_rima');

	/** Un rasgo con un solo valor no es una elección entre alternativas: está o no está. */
	const control = $derived(controlDePregunta(visibleOptions.length, minimum));
	const showAsCheckbox = $derived(
		!isRhymeScheme && !positional && maximum === 1 && optional && control === 'casilla'
	);
	const showAsList = $derived(
		!celda &&
			!isRhymeScheme &&
			!positional &&
			!showAsCheckbox &&
			maximum === 1 &&
			control === 'lista'
	);

	/** Lo que dice el catálogo de la respuesta elegida, cuando hay una sola. */
	const descripcionElegida = $derived(
		props.selectedIds.length === 1
			? String(
					visibleOptions.find(
						(option: MetricCatalogDomainRow) =>
							String(option.opcion_eleccion_id) === props.selectedIds[0]
					)?.descripcion ?? ''
				)
			: ''
	);
	function changeSingle(event: Event) {
		const value = (event.currentTarget as HTMLSelectElement).value;
		props.onChange(value ? [value] : []);
	}

	function toggleOption(optionId: string, checked: boolean) {
		const current = new Set(props.selectedIds);
		if (checked) {
			if (current.size >= effectiveMaximum) return;
			current.add(optionId);
		} else {
			current.delete(optionId);
		}
		props.onChange([...current]);
	}

	/** El metro de la primera respuesta, para poder repetirlo en las demás posiciones. */
	const metroRespondido = $derived(
		visibleOptions.find((option: MetricCatalogDomainRow) =>
			props.selectedIds.includes(String(option.opcion_eleccion_id))
		)?.metro_id ?? null
	);
	const puedeRellenarPosiciones = $derived(
		positional &&
			!partialPositionalSelection &&
			Boolean(metroRespondido) &&
			visiblePositions.length > props.selectedIds.length
	);

	/**
	 * Repite la medida ya respondida en todas las posiciones que quedan. Ahorra teclear la
	 * misma sílaba una vez por verso cuando el pasaje es isosilábico.
	 */
	function rellenarPosiciones() {
		if (!metroRespondido) return;
		const siguientes: string[] = [];
		for (const position of visiblePositions) {
			const yaRespondida = visibleOptions.find(
				(option: MetricCatalogDomainRow) =>
					Number(option.posicion_unidad) === position &&
					props.selectedIds.includes(String(option.opcion_eleccion_id))
			);
			const elegida =
				yaRespondida ??
				visibleOptions.find(
					(option: MetricCatalogDomainRow) =>
						Number(option.posicion_unidad) === position &&
						String(option.metro_id) === String(metroRespondido)
				);
			if (elegida) siguientes.push(String(elegida.opcion_eleccion_id));
		}
		props.onChange(siguientes.slice(0, effectiveMaximum));
	}

	/**
	 * Los controles de varias líneas —una fila por verso, una casilla por posición— ocupan
	 * tanto como el resto del formulario junto. Cuando ya están contestados se recogen en su
	 * respuesta: la pregunta contestada debe encoger, no seguir pesando lo mismo.
	 */
	let expanded = $state(false);

	const multiline = $derived(
		positionalAlternatives || positional || (!isRhymeScheme && maximum !== 1)
	);
	const answered = $derived(
		isRhymeScheme
			? Boolean((props.textValue ?? '').trim())
			: positionalAlternatives
				? partialPositionalSelection
					? props.selectedIds.length >= minimum
					: visiblePositions.length > 0 && props.selectedIds.length === visiblePositions.length
				: props.selectedIds.length > 0 && props.selectedIds.length >= minimum
	);
	const collapsed = $derived(
		answered && (props.compact || (!partialPositionalSelection && multiline && !expanded))
	);
	const answerSummary = $derived.by(() => {
		const selectedOptions = visibleOptions
			.filter((option: MetricCatalogDomainRow) =>
				props.selectedIds.includes(String(option.opcion_eleccion_id))
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.posicion_unidad ?? 0) - Number(b.posicion_unidad ?? 0)
			);
		if (partialPositionalSelection) {
			const base = Number(visibleOptions[0]?.metro_base_silabas);
			if (selectedOptions.length === 0) {
				return `Ningún verso quebrado${Number.isFinite(base) ? ` · todos, ${base} síl.` : ''}`;
			}
			const broken = selectedOptions.map((option: MetricCatalogDomainRow) => {
				const position = Number(option.posicion_unidad);
				const syllables = Number(option.metro_silabas);
				return Number.isFinite(syllables)
					? `v. ${position} (${syllables} síl.)`
					: String(option.nombre);
			});
			const remaining = visiblePositions.length - selectedOptions.length;
			return `Quebrados: ${broken.join(', ')}${
				remaining > 0 && Number.isFinite(base)
					? ` · los demás, ${base} síl.`
					: ''
			}`;
		}
		const names = selectedOptions.map((option: MetricCatalogDomainRow) => String(option.nombre));
		const distinct = [...new Set(names)];
		if (names.length > 1 && distinct.length === 1) {
			return `${distinct[0]} · ${names.length} posiciones`;
		}
		return names.join(' · ');
	});

</script>

<fieldset class="form-field">
	<legend class="form-label">
		<span class="form-label-with-help">
			{props.label ?? String(props.group.nombre)}{optional ? '' : ' *'}
			{#if props.group.ayuda_editor}
				<FieldHelpTooltip
					text={String(props.group.ayuda_editor)}
					label={`Ayuda sobre «${String(props.group.nombre)}»`}
				/>
			{/if}
		</span>
	</legend>

	{#if collapsed}
		<div class="border border-[color:var(--border)] bg-white text-sm">
			{#if props.compactNote}
				<p class="border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-1.5 text-xs font-medium text-[color:var(--muted-foreground)]">
					{props.compactNote}
				</p>
			{/if}
			<div class="flex flex-wrap items-baseline justify-between gap-2 px-3 py-2">
				<span>{answerSummary}</span>
				{#if !props.hideCompactAction}
					<button
						type="button"
						class="link-action"
						onclick={() => (props.onExpand ? props.onExpand() : (expanded = true))}
					>
						{props.changeLabel ?? 'Cambiar'}
					</button>
				{/if}
			</div>
		</div>
	{:else if isRhymeScheme}
		<input
			type="text"
			class="h-10 w-full border border-[color:var(--border)] bg-white px-3 font-mono text-sm tracking-wide"
			value={props.textValue ?? ''}
			placeholder="aBaBcC"
			autocomplete="off"
			spellcheck="false"
			oninput={(event) => props.onTextChange?.(event.currentTarget.value)}
		/>
	{:else if showAsCheckbox}
		{@const unica = visibleOptions[0]}
		<label class="flex items-start gap-2 border border-[color:var(--border)] bg-white px-3 py-2 text-sm">
			<input
				type="checkbox"
				class="mt-0.5"
				checked={props.selectedIds.length > 0}
				onchange={(event) =>
					props.onChange(
						event.currentTarget.checked ? [String(unica.opcion_eleccion_id)] : []
					)}
			/>
			<span>
				{String(unica.nombre)}
				{#if unica.descripcion}
					<span class="block text-xs text-[color:var(--muted-foreground)]">
						{@html renderInlineMarkdown(String(unica.descripcion))}
					</span>
				{/if}
			</span>
		</label>
	{:else if showAsList}
		<div class="space-y-1">
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				{@const id = String(option.opcion_eleccion_id)}
				<label
					class={`flex cursor-pointer items-start gap-2 border px-3 py-2 text-sm ${
						props.selectedIds.includes(id)
							? 'border-[color:var(--primary)] bg-[color:var(--muted)]'
							: 'border-[color:var(--border)] bg-white'
					}`}
				>
					<input
						type="radio"
						class="mt-0.5"
						name={String(props.group.grupo_eleccion_id)}
						checked={props.selectedIds.includes(id)}
						onchange={() => props.onChange([id])}
					/>
					<span>
						{String(option.nombre)}
						{#if option.descripcion}
							<span class="block text-xs text-[color:var(--muted-foreground)]">
								{@html renderInlineMarkdown(String(option.descripcion))}
							</span>
						{/if}
					</span>
				</label>
			{/each}
			{#if optional}
				<button
					type="button"
					class="link-action text-xs"
					disabled={props.selectedIds.length === 0}
					onclick={() => props.onChange([])}
				>
					Quitar selección
				</button>
			{/if}
		</div>
	{:else if maximum === 1}
		<select
			class={`w-full border bg-white px-3 text-sm ${
				celda ? 'h-9 max-w-sm' : 'h-10'
			} ${
				props.selectedIds.length === 0 && !optional
					? 'border-[color:var(--primary)]'
					: 'border-[color:var(--border)]'
			}`}
			value={props.selectedIds[0] ?? ''}
			onchange={changeSingle}
		>
			<option value="">
				{optional ? 'Sin seleccionar' : 'Seleccionar una respuesta'}
			</option>
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				<option value={String(option.opcion_eleccion_id)} title={stripMarkdown(String(option.descripcion ?? ''))}>
					{String(option.nombre)}
				</option>
			{/each}
		</select>
	{:else if partialPositionalSelection}
		<MetricPartialPositionField
			options={visibleOptions}
			selectedKeys={props.selectedIds}
			keyField="opcion_eleccion_id"
			minimum={minimum}
			maximum={effectiveMaximum}
			pendingPositions={props.pendingPositions}
			onPendingPositionsChange={props.onPendingPositionsChange}
			ariaLabel={props.label ?? String(props.group.nombre)}
			onChange={props.onChange}
		/>
	{:else if positionalAlternatives}
		<MetricVersePatternField
			length={visiblePositions.length}
			positionStart={visiblePositions[0] ?? 1}
			options={visibleOptions}
			selectedIds={props.selectedIds}
			onMeasureChange={props.onChange}
		/>
	{:else if positional}
		<div class="flex flex-wrap gap-2">
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				<label
					class={`flex min-h-10 min-w-10 cursor-pointer items-center justify-center border px-3 text-sm ${
						props.selectedIds.includes(String(option.opcion_eleccion_id))
							? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-white'
							: 'border-[color:var(--border)] bg-white'
					}`}
					title={String(option.nombre)}
				>
					<input
						type="checkbox"
						class="sr-only"
						checked={props.selectedIds.includes(String(option.opcion_eleccion_id))}
						onchange={(event) =>
							toggleOption(
								String(option.opcion_eleccion_id),
								event.currentTarget.checked
							)}
					/>
					<span>{Number(option.posicion_unidad)}</span>
				</label>
			{/each}
		</div>
		<p class="text-xs text-[color:var(--muted-foreground)]">
			{props.selectedIds.length} de {effectiveMaximum} posiciones seleccionadas
		</p>
	{:else}
		<div class="grid gap-2 sm:grid-cols-2">
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				<label class="flex items-start gap-2 border border-[color:var(--border)] bg-white px-3 py-2 text-sm">
					<input
						type="checkbox"
						class="mt-0.5"
						checked={props.selectedIds.includes(String(option.opcion_eleccion_id))}
						onchange={(event) =>
							toggleOption(
								String(option.opcion_eleccion_id),
								event.currentTarget.checked
							)}
					/>
					<span>{String(option.nombre)}</span>
				</label>
			{/each}
		</div>
	{/if}

	{#if props.showDescription && !collapsed && descripcionElegida}
		<p class="form-help">{@html renderInlineMarkdown(descripcionElegida)}</p>
	{/if}

	<div class={`flex flex-wrap gap-x-4 gap-y-1 ${collapsed ? 'hidden' : 'mt-1'}`}>
		{#if props.onApplyAll && props.group.permite_aplicar_global}
			<button
				type="button"
				class="link-action"
				onclick={props.onApplyAll}
				disabled={isRhymeScheme
					? !(props.textValue ?? '').trim()
					: props.selectedIds.length === 0}
			>
				Aplicar esta respuesta a todas las unidades equivalentes
			</button>
		{/if}

		{#if puedeRellenarPosiciones}
			<button type="button" class="link-action" onclick={rellenarPosiciones}>
				Repetir esta medida en las demás posiciones
			</button>
		{/if}
	</div>
</fieldset>

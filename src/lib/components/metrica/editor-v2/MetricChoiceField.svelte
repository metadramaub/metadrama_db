<script lang="ts">
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import { controlDePregunta } from '$lib/metrica/controles-formulario';
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';

	const props = $props<{
		group: MetricCatalogDomainRow;
		options: MetricCatalogDomainRow[];
		selectedIds: string[];
		onChange: (ids: string[]) => void;
		textValue?: string;
		onTextChange?: (value: string) => void;
		onApplyAll?: () => void;
		onApplyToEverySection?: () => void;
		positionLimit?: number;
	}>();

	const minimum = $derived(Number(props.group.selecciones_min ?? 0));
	const maximum = $derived(Number(props.group.selecciones_max ?? 1));
	const optional = $derived(minimum === 0);
	const positional = $derived(
		props.options.length > 0 &&
			props.options.every(
				(option: MetricCatalogDomainRow) => Number(option.posicion_unidad ?? 0) > 0
			)
	);
	const visibleOptions = $derived(
		positional && typeof props.positionLimit === 'number'
			? props.options.filter(
					(option: MetricCatalogDomainRow) =>
						Number(option.posicion_unidad) <= props.positionLimit!
				)
			: props.options
	);
	const positionalAlternatives = $derived(
		positional &&
			visibleOptions.some(
				(option: MetricCatalogDomainRow, index: number, options: MetricCatalogDomainRow[]) =>
					options.findIndex(
						(candidate: MetricCatalogDomainRow) =>
							Number(candidate.posicion_unidad) === Number(option.posicion_unidad)
					) !== index
			)
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
		!isRhymeScheme && !positional && !showAsCheckbox && maximum === 1 && control === 'lista'
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
		positional && Boolean(metroRespondido) && visiblePositions.length > props.selectedIds.length
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
				? visiblePositions.length > 0 && props.selectedIds.length === visiblePositions.length
				: props.selectedIds.length > 0 && props.selectedIds.length >= minimum
	);
	const collapsed = $derived(multiline && answered && !expanded);
	const answerSummary = $derived.by(() => {
		const names = visibleOptions
			.filter((option: MetricCatalogDomainRow) =>
				props.selectedIds.includes(String(option.opcion_eleccion_id))
			)
			.sort(
				(a: MetricCatalogDomainRow, b: MetricCatalogDomainRow) =>
					Number(a.posicion_unidad ?? 0) - Number(b.posicion_unidad ?? 0)
			)
			.map((option: MetricCatalogDomainRow) => String(option.nombre));
		const distinct = [...new Set(names)];
		if (names.length > 1 && distinct.length === 1) {
			return `${distinct[0]} · ${names.length} posiciones`;
		}
		return names.join(' · ');
	});

	function changePosition(position: number, optionId: string) {
		const positionOptionIds = new Set(
			visibleOptions
				.filter(
					(option: MetricCatalogDomainRow) =>
						Number(option.posicion_unidad) === position
				)
				.map((option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id))
		);
		const next = props.selectedIds.filter((selectedId: string) => !positionOptionIds.has(selectedId));
		if (optionId) next.push(optionId);
		props.onChange(next);
	}
</script>

<fieldset class="form-field">
	<legend class="form-label">
		<span class="form-label-with-help">
			{String(props.group.nombre)}{optional ? '' : ' *'}
			{#if props.group.ayuda_editor}
				<FieldHelpTooltip
					text={String(props.group.ayuda_editor)}
					label={`Ayuda sobre «${String(props.group.nombre)}»`}
				/>
			{/if}
		</span>
	</legend>

	{#if collapsed}
		<div class="flex flex-wrap items-baseline justify-between gap-2 border border-[color:var(--border)] bg-white px-3 py-2 text-sm">
			<span>{answerSummary}</span>
			<button type="button" class="link-action" onclick={() => (expanded = true)}>Cambiar</button>
		</div>
	{:else if isRhymeScheme}
		<input
			type="text"
			class="h-10 w-full border border-[color:var(--border)] bg-white px-3 font-mono text-sm uppercase tracking-wide"
			value={props.textValue ?? ''}
			placeholder="AABCCB"
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
						{String(unica.descripcion)}
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
								{String(option.descripcion)}
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
					No aparece / no se aplica
				</button>
			{/if}
		</div>
	{:else if maximum === 1}
		<select
			class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
			value={props.selectedIds[0] ?? ''}
			onchange={changeSingle}
		>
			<option value="">
				{optional ? 'No aparece / no se aplica' : 'Seleccionar una respuesta'}
			</option>
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				<option value={String(option.opcion_eleccion_id)}>{String(option.nombre)}</option>
			{/each}
		</select>
	{:else if positionalAlternatives}
		<div class="space-y-2">
			{#each visiblePositions as position}
				{@const positionOptions = visibleOptions.filter(
					(option: MetricCatalogDomainRow) =>
						Number(option.posicion_unidad) === position
				)}
				{@const positionOptionIds = new Set(
					positionOptions.map((option: MetricCatalogDomainRow) =>
						String(option.opcion_eleccion_id)
					)
				)}
				<label class="grid items-center gap-2 sm:grid-cols-[5.5rem_1fr]">
					<span class="text-sm text-[color:var(--muted-foreground)]">Verso {position}</span>
					<select
						class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
						value={props.selectedIds.find((selectedId: string) =>
							positionOptionIds.has(selectedId)
						) ?? ''}
						onchange={(event) => changePosition(position, event.currentTarget.value)}
					>
						<option value="">Seleccionar medida</option>
						{#each positionOptions as option (String(option.opcion_eleccion_id))}
							<option value={String(option.opcion_eleccion_id)}>
								{String(option.nombre)}
							</option>
						{/each}
					</select>
				</label>
			{/each}
		</div>
		<p class="text-xs text-[color:var(--muted-foreground)]">
			{props.selectedIds.length} de {visiblePositions.length} versos caracterizados
		</p>
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

		{#if props.onApplyToEverySection}
			<button
				type="button"
				class="link-action"
				onclick={props.onApplyToEverySection}
				disabled={props.selectedIds.length === 0}
			>
				Toda la composición usa esta medida
			</button>
		{/if}

		{#if puedeRellenarPosiciones}
			<button type="button" class="link-action" onclick={rellenarPosiciones}>
				Repetir esta medida en las demás posiciones
			</button>
		{/if}
	</div>
</fieldset>

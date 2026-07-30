<script lang="ts">
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';

	const props = $props<{
		group: MetricCatalogDomainRow;
		options: MetricCatalogDomainRow[];
		selectedIds: string[];
		onChange: (ids: string[]) => void;
		textValue?: string;
		onTextChange?: (value: string) => void;
		onApplyAll?: () => void;
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

<fieldset class="space-y-2 border-l-2 border-[color:var(--border)] pl-3">
	<div class="flex flex-wrap items-start justify-between gap-2">
		<div>
			<legend class="text-sm font-medium">{String(props.group.nombre)}</legend>
			{#if props.group.ayuda_editor}
				<p class="mt-1 text-xs leading-5 text-[color:var(--muted-foreground)]">
					{String(props.group.ayuda_editor)}
				</p>
			{/if}
		</div>
		<span class="text-[0.7rem] uppercase tracking-wide text-[color:var(--muted-foreground)]">
			{optional ? 'Opcional' : 'Obligatoria'}
		</span>
	</div>

	{#if isRhymeScheme}
		<input
			type="text"
			class="h-10 w-full border border-[color:var(--border)] bg-white px-3 font-mono text-sm uppercase tracking-wide"
			value={props.textValue ?? ''}
			placeholder="AABCCB"
			autocomplete="off"
			spellcheck="false"
			oninput={(event) => props.onTextChange?.(event.currentTarget.value)}
		/>
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

	{#if props.onApplyAll && props.group.permite_aplicar_global}
		<button
			type="button"
			class="text-xs font-medium text-[color:var(--primary)] hover:underline disabled:opacity-40"
			onclick={props.onApplyAll}
		disabled={isRhymeScheme ? !(props.textValue ?? '').trim() : props.selectedIds.length === 0}
		>
			Aplicar esta respuesta a todas las unidades equivalentes
		</button>
	{/if}
</fieldset>

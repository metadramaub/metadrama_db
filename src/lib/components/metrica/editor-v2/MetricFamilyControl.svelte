<script lang="ts">
	// El control de una pregunta preparada para copiarse a varias realizaciones.
	//
	// Vive aparte porque su interior es el mismo que el de una pregunta suelta —casilla o
	// desplegable según si admite quedarse vacía— y tenerlo escrito dos veces ya hizo que
	// divergieran: el bloque de arriba pintaba como lista de un elemento el sí/no que el campo
	// suelto pintaba como casilla.
	//
	// En la rejilla ocupa una línea. Las alternativas van siempre en desplegable, aunque sean
	// pocas, porque la fila de al lado tiene que caber al lado y no debajo. Lo que la lista
	// enseñaba —la explicación de cada respuesta— se recupera debajo, para la elegida.
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import { renderInlineMarkdown, stripMarkdown } from '$lib/utils/markdown';
	import MetricPartialPositionField from './MetricPartialPositionField.svelte';
	import MetricVersePatternField from './MetricVersePatternField.svelte';
	import {
		arePositionalOptions,
		haveAlternativesByPosition,
		isPartialPositionalSelection
	} from './positional-options';

	const props: {
		group: MetricCatalogDomainRow;
		options: MetricCatalogDomainRow[];
		/** Los slugs que comparten todas las realizaciones, o nulo si no coinciden. */
		uniform: string[] | null;
		/** Cuántas tienen ya respuesta, para distinguir «vacío» de «varían». */
		answered: number;
		/** Cuántas responde a la vez. */
		realizaciones: number;
		onChoose: (slugs: string[]) => void;
		ariaLabel: string;
		positionLimit?: number;
	} = $props();

	const positional = $derived(arePositionalOptions(props.options));
	const visibleOptions = $derived(
		positional && typeof props.positionLimit === 'number'
			? props.options.filter(
					(option: MetricCatalogDomainRow) =>
						Number(option.posicion_unidad) <= props.positionLimit!
				)
			: props.options
	);
	const first = $derived(visibleOptions[0]);
	const positions = $derived(
		Array.from(
			new Set(
				visibleOptions.map((option: MetricCatalogDomainRow) => Number(option.posicion_unidad))
			)
		).sort((a, b) => a - b)
	);
	const positionalAlternatives = $derived(haveAlternativesByPosition(visibleOptions));
	const partialPositionalSelection = $derived(
		isPartialPositionalSelection(props.group, visibleOptions)
	);
	/** Un rasgo con un solo valor no es una elección entre alternativas: está o no está. */
	const esCasilla = $derived(!positional && visibleOptions.length === 1);
	const descripcion = $derived(
		String(
			props.options.find(
				(option: MetricCatalogDomainRow) => props.uniform?.includes(String(option.slug))
			)?.descripcion ?? ''
		)
	);

	function optionsAt(position: number): MetricCatalogDomainRow[] {
		return visibleOptions.filter(
			(option: MetricCatalogDomainRow) => Number(option.posicion_unidad) === position
		);
	}

	function togglePosition(option: MetricCatalogDomainRow, checked: boolean) {
		const slug = String(option.slug);
		const next = new Set(props.uniform ?? []);
		if (checked) next.add(slug);
		else next.delete(slug);
		props.onChoose([...next]);
	}

	/**
	 * La rejilla que se dibuja: los versos de una unidad, no solo los que preguntan.
	 *
	 * `positionLimit` es la unidad más corta a la que alcanza la respuesta común, y es justo lo que
	 * hay que pintar: en la manriqueña salen los doce versos, con los ocho que la norma fija ya
	 * puestos y los cuatro quebrados esperando medida.
	 */
	const longitudDeLaRejilla = $derived(
		typeof props.positionLimit === 'number' && props.positionLimit > 0
			? props.positionLimit
			: (positions[positions.length - 1] ?? 0)
	);

	/** El campo de versos habla en identificadores de opción; aquí se responde por slug. */
	const idsElegidos = $derived(
		visibleOptions
			.filter((option: MetricCatalogDomainRow) =>
				props.uniform?.includes(String(option.slug))
			)
			.map((option: MetricCatalogDomainRow) => String(option.opcion_eleccion_id))
	);

	function elegirPorId(ids: string[]) {
		const porId = new Map(
			visibleOptions.map((option: MetricCatalogDomainRow) => [
				String(option.opcion_eleccion_id),
				String(option.slug)
			])
		);
		props.onChoose(ids.map((id) => porId.get(id)).filter((slug): slug is string => Boolean(slug)));
	}
</script>

<div class="flex w-full min-w-0 flex-1 flex-col gap-1">
	{#if esCasilla}
		<label class="flex cursor-pointer items-center gap-2 text-sm">
			<input
				type="checkbox"
				checked={props.uniform?.includes(String(first?.slug ?? '')) ?? false}
				onchange={(event) =>
					props.onChoose(event.currentTarget.checked ? [String(first?.slug ?? '')] : [])}
			/>
			<span>{String(first?.nombre ?? '')}</span>
		</label>
	{:else if partialPositionalSelection}
		<MetricPartialPositionField
			options={visibleOptions}
			selectedKeys={props.uniform}
			keyField="slug"
			minimum={Number(props.group.selecciones_min ?? 0)}
			maximum={Number(props.group.selecciones_max ?? positions.length)}
			mixed={props.uniform === null && props.answered > 0}
			ariaLabel={props.ariaLabel}
			onChange={props.onChoose}
		/>
	{:else if positionalAlternatives}
		<!--
			**La misma rejilla de barras que la pregunta suelta.**

			Aquí había un desplegable por verso, y en una novena-lira eran nueve desplegables
			seguidos para elegir entre siete y once: la respuesta de una unidad se veía dibujada y la
			de todas, no. Es la divergencia que este componente existe para evitar.
		-->
		<MetricVersePatternField
			length={longitudDeLaRejilla}
			positionStart={1}
			options={visibleOptions}
			selectedIds={idsElegidos}
			onMeasureChange={elegirPorId}
		/>
	{:else if positional}
		<div class="flex flex-wrap gap-2">
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				<label
					class={`flex min-h-9 min-w-9 cursor-pointer items-center justify-center border px-3 text-sm ${
						props.uniform?.includes(String(option.slug))
							? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-white'
							: 'border-[color:var(--border)] bg-white'
					}`}
					title={String(option.nombre)}
				>
					<input
						type="checkbox"
						class="sr-only"
						checked={props.uniform?.includes(String(option.slug)) ?? false}
						onchange={(event) => togglePosition(option, event.currentTarget.checked)}
					/>
					<span>{Number(option.posicion_unidad)}</span>
				</label>
			{/each}
		</div>
	{:else}
		<select
			class={`h-9 w-full max-w-sm border bg-white px-3 text-sm ${
				props.uniform === null && props.answered === 0
					? 'border-[color:var(--primary)]'
					: 'border-[color:var(--border)]'
			}`}
			value={props.uniform?.[0] ?? ''}
			aria-label={props.ariaLabel}
			onchange={(event) => props.onChoose(event.currentTarget.value ? [event.currentTarget.value] : [])}
		>
			<option value="">
				{props.uniform === null && props.answered > 0
					? 'Varían: cada una conserva la suya'
					: 'Seleccionar una respuesta'}
			</option>
			{#each visibleOptions as option (String(option.opcion_eleccion_id))}
				<option value={String(option.slug)} title={stripMarkdown(String(option.descripcion ?? ''))}>
					{String(option.nombre)}
				</option>
			{/each}
		</select>
	{/if}
	{#if descripcion}
		<p class="form-help mt-0">{@html renderInlineMarkdown(String(descripcion))}</p>
	{/if}
</div>

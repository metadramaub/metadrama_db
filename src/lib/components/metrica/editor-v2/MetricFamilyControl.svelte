<script lang="ts">
	// El control de una pregunta que se responde para todas las realizaciones a la vez.
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

	const props: {
		options: MetricCatalogDomainRow[];
		/** Los slugs que comparten todas las realizaciones, o nulo si no coinciden. */
		uniform: string[] | null;
		/** Cuántas tienen ya respuesta, para distinguir «vacío» de «varían». */
		answered: number;
		/** Cuántas responde a la vez. */
		realizaciones: number;
		onChoose: (slugs: string[]) => void;
		ariaLabel: string;
	} = $props();

	const first = $derived(props.options[0]);
	const positional = $derived(
		props.options.length > 0 &&
			props.options.every(
				(option: MetricCatalogDomainRow) => Number(option.posicion_unidad ?? 0) > 0
			)
	);
	const positions = $derived(
		Array.from(
			new Set(
				props.options.map((option: MetricCatalogDomainRow) => Number(option.posicion_unidad))
			)
		).sort((a, b) => a - b)
	);
	const positionalAlternatives = $derived(
		positional && positions.some((position) => optionsAt(position).length > 1)
	);
	/** Un rasgo con un solo valor no es una elección entre alternativas: está o no está. */
	const esCasilla = $derived(!positional && props.options.length === 1);
	const descripcion = $derived(
		String(
			props.options.find(
				(option: MetricCatalogDomainRow) => props.uniform?.includes(String(option.slug))
			)?.descripcion ?? ''
		)
	);

	function optionsAt(position: number): MetricCatalogDomainRow[] {
		return props.options.filter(
			(option: MetricCatalogDomainRow) => Number(option.posicion_unidad) === position
		);
	}

	function selectedAt(position: number): string {
		return String(
			optionsAt(position).find((option: MetricCatalogDomainRow) =>
				props.uniform?.includes(String(option.slug))
			)?.slug ?? ''
		);
	}

	function changePosition(position: number, slug: string) {
		const slugsAtPosition = new Set(
			optionsAt(position).map((option: MetricCatalogDomainRow) => String(option.slug))
		);
		const next = (props.uniform ?? []).filter((current) => !slugsAtPosition.has(current));
		if (slug) next.push(slug);
		props.onChoose(next);
	}

	function togglePosition(option: MetricCatalogDomainRow, checked: boolean) {
		const slug = String(option.slug);
		const next = new Set(props.uniform ?? []);
		if (checked) next.add(slug);
		else next.delete(slug);
		props.onChoose([...next]);
	}

	function optionLabel(option: MetricCatalogDomainRow, position: number): string {
		const label = String(option.nombre);
		const prefix = `Verso ${position} · `;
		return label.startsWith(prefix) ? label.slice(prefix.length) : label;
	}
</script>

<div class="flex min-w-0 flex-col gap-1">
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
	{:else if positionalAlternatives}
		<div class="grid gap-2 sm:grid-cols-2">
			{#each positions as position}
				<label class="grid min-w-0 items-center gap-2 sm:grid-cols-[4.5rem_1fr]">
					<span class="text-sm text-[color:var(--muted-foreground)]">Verso {position}</span>
					<select
						class="h-9 min-w-0 border border-[color:var(--border)] bg-white px-3 text-sm"
						value={selectedAt(position)}
						aria-label={`${props.ariaLabel}, verso ${position}`}
						onchange={(event) => changePosition(position, event.currentTarget.value)}
					>
						<option value="">Seleccionar medida</option>
						{#each optionsAt(position) as option (String(option.opcion_eleccion_id))}
							<option value={String(option.slug)}>{optionLabel(option, position)}</option>
						{/each}
					</select>
				</label>
			{/each}
		</div>
	{:else if positional}
		<div class="flex flex-wrap gap-2">
			{#each props.options as option (String(option.opcion_eleccion_id))}
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
					: `Responder las ${props.realizaciones} de una vez`}
			</option>
			{#each props.options as option (String(option.opcion_eleccion_id))}
				<option value={String(option.slug)} title={String(option.descripcion ?? '')}>
					{String(option.nombre)}
				</option>
			{/each}
		</select>
	{/if}
	{#if descripcion}
		<p class="form-help mt-0">{descripcion}</p>
	{/if}
</div>

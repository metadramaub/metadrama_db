<script lang="ts">
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import { shortPositionOptionLabel } from './positional-options';

	const props = $props<{
		options: MetricCatalogDomainRow[];
		selectedKeys: string[] | null;
		keyField: 'opcion_eleccion_id' | 'slug';
		minimum: number;
		maximum: number;
		positionLimit?: number;
		mixed?: boolean;
		pendingPositions?: number[];
		onPendingPositionsChange?: (positions: number[]) => void;
		ariaLabel: string;
		onChange: (keys: string[]) => void;
	}>();

	const visibleOptions = $derived(
		typeof props.positionLimit === 'number'
			? props.options.filter(
					(option: MetricCatalogDomainRow) =>
						Number(option.posicion_unidad) <= props.positionLimit!
				)
			: props.options
	);
	const positions = $derived(
		Array.from(
			new Set<number>(
				visibleOptions.map((option: MetricCatalogDomainRow) =>
					Number(option.posicion_unidad)
				)
			)
		).sort((a: number, b: number) => a - b)
	);
	const effectiveMaximum = $derived(Math.min(props.maximum, positions.length));
	const selected = $derived(props.selectedKeys ?? []);
	const baseSyllables = $derived(Number(visibleOptions[0]?.metro_base_silabas) || null);
	let localPendingPositions = $state<number[]>([]);
	const pendingPositions = $derived(props.pendingPositions ?? localPendingPositions);
	const pendingVisibleCount = $derived(
		positions.filter((position: number) => pendingPositions.includes(position)).length
	);
	const selectedVisibleCount = $derived(
		positions.filter((position: number) =>
			optionsAt(position).some((option: MetricCatalogDomainRow) =>
				selected.includes(keyOf(option))
			)
		).length
	);
	const markedCount = $derived(
		positions.filter(
			(position: number) => selectedAt(position) !== null || pendingPositions.includes(position)
		).length
	);
	const occupiedCount = $derived(selected.length + pendingPositions.length);

	function keyOf(option: MetricCatalogDomainRow): string {
		return String(option[props.keyField]);
	}

	function setPendingPositions(positions: number[]) {
		if (props.onPendingPositionsChange) props.onPendingPositionsChange(positions);
		else localPendingPositions = positions;
	}

	function optionsAt(position: number): MetricCatalogDomainRow[] {
		return visibleOptions.filter(
			(option: MetricCatalogDomainRow) => Number(option.posicion_unidad) === position
		);
	}

	function selectedAt(position: number): string | null {
		return (
			optionsAt(position)
				.map(keyOf)
				.find((key: string) => selected.includes(key)) ?? null
		);
	}

	function selectedOptionAt(position: number): MetricCatalogDomainRow | null {
		const selectedKey = selectedAt(position);
		return selectedKey === null
			? null
			: optionsAt(position).find(
					(option: MetricCatalogDomainRow) => keyOf(option) === selectedKey
				) ?? null;
	}

	function markAsBroken(position: number) {
		if (occupiedCount >= effectiveMaximum || pendingPositions.includes(position)) return;
		setPendingPositions([...pendingPositions, position]);
	}

	function restoreBase(position: number) {
		setPendingPositions(pendingPositions.filter((pending: number) => pending !== position));
		const keysAtPosition = new Set(optionsAt(position).map(keyOf));
		props.onChange(selected.filter((selectedKey: string) => !keysAtPosition.has(selectedKey)));
	}

	function choose(position: number, option: MetricCatalogDomainRow) {
		const key = keyOf(option);
		const currentAtPosition = selectedAt(position);
		const keysAtPosition = new Set(optionsAt(position).map(keyOf));
		const next = selected.filter((selectedKey: string) => !keysAtPosition.has(selectedKey));

		if (
			currentAtPosition === null &&
			selected.length >= effectiveMaximum
		)
			return;
		setPendingPositions(pendingPositions.filter((pending: number) => pending !== position));
		props.onChange([...next, key]);
	}

	function displayedSyllables(position: number): number | null {
		const selectedOption = selectedOptionAt(position);
		if (selectedOption) return Number(selectedOption.metro_silabas) || null;
		if (pendingPositions.includes(position)) {
			return Math.min(
				...optionsAt(position)
					.map((option: MetricCatalogDomainRow) => Number(option.metro_silabas))
					.filter((value: number) => Number.isFinite(value) && value > 0)
			);
		}
		return baseSyllables;
	}

	function barWidth(position: number): number {
		const syllables = displayedSyllables(position);
		if (!syllables || !baseSyllables) return 100;
		return Math.max(30, Math.min(100, (syllables / baseSyllables) * 100));
	}
</script>

<div class="space-y-3">
	<p class="text-xs text-[color:var(--muted-foreground)]">
		{#if baseSyllables}
			Todos los versos parten de {baseSyllables} sílabas. Marca solo los que se quiebran.
		{:else}
			Marca los versos quebrados y especifica después su medida.
		{/if}
	</p>

	<div class="space-y-1.5">
		{#each positions as position}
			{@const selectedOption = selectedOptionAt(position)}
			{@const pending = pendingPositions.includes(position)}
			{@const broken = selectedOption !== null || pending}
			<div class="grid min-w-0 items-center gap-2 sm:grid-cols-[4rem_minmax(9rem,1fr)_12rem]">
				<span class="text-xs text-[color:var(--muted-foreground)]">Verso {position}</span>
				<div class="relative h-9 overflow-hidden border border-[color:var(--border)] bg-white">
					<div
						class={`absolute inset-y-0 left-0 ${
							broken ? 'bg-amber-100' : 'bg-[color:var(--muted)]'
						}`}
						style={`width: ${barWidth(position)}%`}
					></div>
					<span class="relative flex h-full items-center px-2 text-xs">
						{#if selectedOption}
							<span class="font-medium tabular-nums">
								{Number(selectedOption.metro_silabas)} sílabas
							</span>
							<span class="ml-1.5 text-[0.65rem] font-medium uppercase tracking-wide text-amber-800">
								Quebrado
							</span>
						{:else if pending}
							<span class="font-medium">Pie quebrado</span>
							<span class="ml-1.5 text-[0.65rem] font-medium uppercase tracking-wide text-amber-800">
								Elige la medida
							</span>
						{:else if baseSyllables}
							<span class="font-medium tabular-nums">{baseSyllables} sílabas</span>
							<span class="ml-1.5 text-[0.65rem] font-medium uppercase tracking-wide text-[color:var(--muted-foreground)]">
								Base
							</span>
						{:else}
							Medida base
						{/if}
					</span>
				</div>

				{#if broken}
					<div class="flex min-w-0 items-center gap-2">
						<div class="flex border border-[color:var(--border)] bg-white">
							{#each optionsAt(position) as option (keyOf(option))}
								{@const key = keyOf(option)}
								{@const active = selected.includes(key)}
								<button
									type="button"
									class={`min-h-8 border-l border-[color:var(--border)] px-2 text-xs first:border-l-0 ${
										active
											? 'bg-[color:var(--primary)] text-white'
											: 'bg-white hover:bg-[color:var(--muted)]'
									}`}
									aria-label={`${props.ariaLabel}, verso ${position}: ${String(option.nombre)}`}
									aria-pressed={active}
									title={String(option.nombre)}
									onclick={() => choose(position, option)}
								>
									{shortPositionOptionLabel(option, position)}
								</button>
							{/each}
						</div>
						<button type="button" class="link-action whitespace-nowrap" onclick={() => restoreBase(position)}>
							{baseSyllables ? `Volver a ${baseSyllables}` : 'Restaurar'}
						</button>
					</div>
				{:else}
					<button
						type="button"
						class="link-action whitespace-nowrap"
						disabled={occupiedCount >= effectiveMaximum}
						onclick={() => markAsBroken(position)}
					>
						Marcar como quebrado
					</button>
				{/if}
			</div>
		{/each}
	</div>

	<p
		class={`text-xs ${
			!props.mixed && selectedVisibleCount < props.minimum
				? 'text-[color:var(--primary)]'
				: 'text-[color:var(--muted-foreground)]'
		}`}
	>
		{#if props.mixed}
			Las unidades conservan respuestas distintas.
		{:else if pendingVisibleCount > 0}
			Falta indicar la medida de {pendingVisibleCount === 1 ? 'un verso quebrado' : `${pendingVisibleCount} versos quebrados`}.
		{:else if selectedVisibleCount < props.minimum}
			Señala {props.minimum === 1 ? 'al menos un verso quebrado' : `al menos ${props.minimum} versos quebrados`}.
		{:else if selectedVisibleCount === 0 && baseSyllables}
			Ningún verso quebrado: todos conservan las {baseSyllables} sílabas de base.
		{:else}
			{selectedVisibleCount} {selectedVisibleCount === 1 ? 'verso quebrado' : 'versos quebrados'}{baseSyllables && selectedVisibleCount < positions.length ? `; los demás conservan ${baseSyllables} sílabas` : ''}.
		{/if}
	</p>

	{#if markedCount === positions.length && positions.length > 1}
		<p class="border-l-2 border-amber-500 bg-amber-50 px-3 py-2 text-xs text-amber-950">
			Has marcado todos los versos como quebrados: no queda ningún verso
			{baseSyllables ? ` de ${baseSyllables} sílabas` : ' de la medida base'}. Revisa que esta siga siendo la forma adecuada.
		</p>
	{/if}
</div>

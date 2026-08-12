<script lang="ts">
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';
	import { normalizeRhymeSymbol } from './rhyme-notation';

	const props = $props<{
		length: number;
		positionStart?: number;
		options: MetricCatalogDomainRow[];
		selectedIds: string[];
		onMeasureChange: (ids: string[]) => void;
		rhymeValue?: string;
		onRhymeChange?: (value: string) => void;
		/** Rima que la arquitectura ya fija: «—» en el cuerpo y «A» en el pareado. */
		fixedRhymes?: string[];
		readOnly?: boolean;
	}>();

	const positions = $derived(
		Array.from({ length: props.length }, (_, index) => (props.positionStart ?? 1) + index)
	);

	function optionsAt(position: number): MetricCatalogDomainRow[] {
		return props.options.filter(
			(option: MetricCatalogDomainRow) => Number(option.posicion_unidad) === position
		);
	}

	function selectedAt(position: number): string | null {
		const ids = new Set(
			optionsAt(position).map((option: MetricCatalogDomainRow) =>
				String(option.opcion_eleccion_id)
			)
		);
		return props.selectedIds.find((id: string) => ids.has(id)) ?? null;
	}

	function syllables(option: MetricCatalogDomainRow): string {
		const exact = Number(option.metro_silabas);
		if (Number.isFinite(exact)) return String(exact);
		const match = String(option.nombre ?? '').match(/\b(\d+)\b/);
		return match?.[1] ?? String(option.nombre ?? '');
	}

	function localIndex(position: number): number {
		return position - (props.positionStart ?? 1);
	}

	function selectedOption(position: number, overrideId?: string): MetricCatalogDomainRow | null {
		const optionId = overrideId ?? selectedAt(position);
		return optionsAt(position).find(
			(option) => String(option.opcion_eleccion_id) === optionId
		) ?? null;
	}

	function selectedSyllables(position: number, overrideId?: string): number | null {
		const value = Number(selectedOption(position, overrideId)?.metro_silabas);
		return Number.isFinite(value) ? value : null;
	}

	function chooseMeasure(position: number, optionId: string) {
		const positionIds = new Set(
			optionsAt(position).map((option) => String(option.opcion_eleccion_id))
		);
		props.onMeasureChange([
			...props.selectedIds.filter((id: string) => !positionIds.has(id)),
			optionId
		]);
		if (props.onRhymeChange) {
			const index = localIndex(position);
			const chars = Array.from(String(props.rhymeValue ?? '')).slice(0, props.length);
			const current = chars[index] ?? '';
			const normalized = normalizeRhymeSymbol(current, selectedSyllables(position, optionId));
			if (current && normalized !== current) {
				chars[index] = normalized;
				props.onRhymeChange(chars.join(''));
			}
		}
	}

	function rhymeAt(position: number): string {
		return Array.from(String(props.rhymeValue ?? ''))[localIndex(position)]?.trim() ?? '';
	}

	function changeRhyme(position: number, raw: string) {
		if (!props.onRhymeChange) return;
		const value = normalizeRhymeSymbol(raw, selectedSyllables(position));
		const chars = Array.from(props.rhymeValue ?? '').slice(0, props.length);
		while (chars.length < props.length) chars.push(' ');
		chars[localIndex(position)] = value || ' ';
		props.onRhymeChange(chars.join(''));
	}

	$effect(() => {
		if (!props.onRhymeChange || !props.rhymeValue) return;
		const chars = Array.from(String(props.rhymeValue)).slice(0, props.length);
		let changed = false;
		for (const position of positions) {
			const index = localIndex(position);
			const normalized = normalizeRhymeSymbol(chars[index] ?? '', selectedSyllables(position));
			if (normalized && normalized !== chars[index]) {
				chars[index] = normalized;
				changed = true;
			}
		}
		if (changed) props.onRhymeChange(chars.join(''));
	});
</script>

<div class="overflow-hidden border border-[color:var(--border)] bg-white">
	<div
		class={`hidden border-b border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-1.5 text-xs font-medium text-[color:var(--muted-foreground)] sm:grid ${
			props.onRhymeChange || props.fixedRhymes
				? 'grid-cols-[4.5rem_minmax(12rem,1fr)_7rem]'
				: 'grid-cols-[4.5rem_minmax(12rem,1fr)]'
		}`}
	>
		<span>Posición</span>
		<span>Medida</span>
		{#if props.onRhymeChange || props.fixedRhymes}<span>Rima</span>{/if}
	</div>

	{#each positions as position}
		{@const choices = optionsAt(position)}
		{@const selected = selectedAt(position)}
		<div
			class={`grid gap-2 border-b border-[color:var(--border)] px-3 py-2 last:border-b-0 sm:items-center ${
				props.onRhymeChange || props.fixedRhymes
					? 'sm:grid-cols-[4.5rem_minmax(12rem,1fr)_7rem]'
					: 'sm:grid-cols-[4.5rem_minmax(12rem,1fr)]'
			}`}
		>
			<span class="text-sm text-[color:var(--muted-foreground)]">Verso {position}</span>
			<div class="flex min-w-0">
				{#each choices as option (String(option.opcion_eleccion_id))}
					{@const optionId = String(option.opcion_eleccion_id)}
					<button
						type="button"
						class={`h-9 min-w-14 border border-r-0 px-4 text-sm font-medium last:border-r ${
							selected === optionId
								? 'border-[color:var(--primary)] bg-[color:var(--primary)] text-white'
								: 'border-[color:var(--border)] bg-white hover:bg-[color:var(--muted)]'
						}`}
						disabled={props.readOnly}
						aria-pressed={selected === optionId}
						onclick={() => chooseMeasure(position, optionId)}
					>
						{syllables(option)}
					</button>
				{/each}
				{#if choices.length === 0}
					<span class="flex h-9 items-center text-sm text-[color:var(--muted-foreground)]">
						Sin medidas disponibles
					</span>
				{/if}
			</div>

			{#if props.onRhymeChange}
				<label class="flex items-center gap-2 sm:block">
					<span class="text-xs text-[color:var(--muted-foreground)] sm:sr-only">Rima</span>
					<input
						type="text"
						maxlength="1"
						class="h-9 w-16 border border-[color:var(--border)] bg-white px-2 text-center font-mono text-sm"
						value={rhymeAt(position)}
						aria-label={`Rima del verso ${position}`}
						autocomplete="off"
						spellcheck="false"
						oninput={(event) => changeRhyme(position, event.currentTarget.value)}
					/>
				</label>
			{:else if props.fixedRhymes}
				<span class="font-mono text-sm font-medium">{props.fixedRhymes[localIndex(position)] ?? '—'}</span>
			{/if}
		</div>
	{/each}
</div>

<p class="text-xs text-[color:var(--muted-foreground)]">
		{props.selectedIds.length} de {props.length} versos con medida
	{#if props.onRhymeChange}
		· {Array.from(String(props.rhymeValue ?? '')).filter((char: string) => char.trim()).length} de {props.length} con rima
	{/if}
</p>

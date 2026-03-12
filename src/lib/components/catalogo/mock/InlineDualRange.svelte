<script lang="ts">
	interface Props {
		label?: string;
		min: number;
		max: number;
		step?: number;
		minGap?: number;
		valueMin: number;
		valueMax: number;
		suffix?: string;
		disabled?: boolean;
		onChange?: (nextMin: number, nextMax: number) => void;
	}

	const props: Props = $props();

	const label = $derived(props.label ?? '');
	const min = $derived(props.min);
	const max = $derived(props.max);
	const step = $derived(props.step ?? 1);
	const minGap = $derived(props.minGap);
	const valueMin = $derived(props.valueMin);
	const valueMax = $derived(props.valueMax);
	const suffix = $derived(props.suffix ?? '');
	const disabled = $derived(props.disabled ?? false);
	const onChange = $derived(props.onChange);

	const minBound = $derived(Math.min(min, max));
	const maxBound = $derived(Math.max(min, max));
	const stepValue = $derived(step);
	const minGapValue = $derived(minGap ?? stepValue);

	const normalizedValues = $derived.by(() => normalizePair(valueMin, valueMax));
	const currentMin = $derived(normalizedValues.min);
	const currentMax = $derived(normalizedValues.max);

	const rangeSpan = $derived(Math.max(maxBound - minBound, 1));
	const leftPercent = $derived(((currentMin - minBound) / rangeSpan) * 100);
	const rightPercent = $derived(((currentMax - minBound) / rangeSpan) * 100);

	function clamp(value: number): number {
		return Math.min(maxBound, Math.max(minBound, value));
	}

	function snap(value: number): number {
		const steps = Math.round((value - minBound) / stepValue);
		return minBound + steps * stepValue;
	}

	function normalizePair(nextMin: number, nextMax: number): { min: number; max: number } {
		let minValue = snap(clamp(nextMin));
		let maxValue = snap(clamp(nextMax));

		if (maxValue - minValue < minGapValue) {
			if (minValue + minGapValue <= maxBound) {
				maxValue = minValue + minGapValue;
			} else {
				minValue = maxValue - minGapValue;
			}
		}

		minValue = snap(clamp(minValue));
		maxValue = snap(clamp(maxValue));

		if (maxValue < minValue) {
			maxValue = minValue;
		}

		return { min: minValue, max: maxValue };
	}

	function emit(nextMin: number, nextMax: number) {
		const next = normalizePair(nextMin, nextMax);
		onChange?.(next.min, next.max);
	}

	function onMinRangeInput(event: Event) {
		const value = Number((event.currentTarget as HTMLInputElement).value);
		emit(value, currentMax);
	}

	function onMaxRangeInput(event: Event) {
		const value = Number((event.currentTarget as HTMLInputElement).value);
		emit(currentMin, value);
	}

	function onMinNumberInput(event: Event) {
		const inputValue = Number((event.currentTarget as HTMLInputElement).value);
		emit(Number.isFinite(inputValue) ? inputValue : currentMin, currentMax);
	}

	function onMaxNumberInput(event: Event) {
		const inputValue = Number((event.currentTarget as HTMLInputElement).value);
		emit(currentMin, Number.isFinite(inputValue) ? inputValue : currentMax);
	}
</script>

<div class="space-y-2">
	{#if label}
		<p class="form-label">{label}</p>
	{/if}

	<div class="grid grid-cols-[4.8rem_minmax(0,1fr)_4.8rem] items-center gap-2">
		<label class="form-field">
			<span class="sr-only">Minimo</span>
			<input
				type="number"
				class="w-full border border-[color:var(--border)] bg-white px-2 py-1.5 text-xs"
				min={minBound}
				max={maxBound}
				step={stepValue}
				value={currentMin}
				disabled={disabled}
				oninput={onMinNumberInput}
			/>
		</label>

		<div class="relative h-8">
			<span class="absolute left-0 right-0 top-1/2 h-[3px] -translate-y-1/2 bg-[color:var(--border)]"></span>
			<span
				class="absolute top-1/2 h-[3px] -translate-y-1/2 bg-[color:var(--primary)]"
				style={`left:${leftPercent}%;width:${Math.max(0, rightPercent - leftPercent)}%;`}
			></span>

			<input
				type="range"
				min={minBound}
				max={maxBound}
				step={stepValue}
				value={currentMin}
				disabled={disabled}
				class="dual-range z-20"
				oninput={onMinRangeInput}
			/>
			<input
				type="range"
				min={minBound}
				max={maxBound}
				step={stepValue}
				value={currentMax}
				disabled={disabled}
				class="dual-range z-30"
				oninput={onMaxRangeInput}
			/>
		</div>

		<label class="form-field">
			<span class="sr-only">Maximo</span>
			<input
				type="number"
				class="w-full border border-[color:var(--border)] bg-white px-2 py-1.5 text-xs"
				min={minBound}
				max={maxBound}
				step={stepValue}
				value={currentMax}
				disabled={disabled}
				oninput={onMaxNumberInput}
			/>
		</label>
	</div>

	{#if suffix}
		<p class="text-[11px] text-[color:var(--muted-foreground)]">Unidad: {suffix}</p>
	{/if}
</div>

<style>
	.dual-range {
		position: absolute;
		inset: 0;
		width: 100%;
		margin: 0;
		background: transparent;
		-webkit-appearance: none;
		appearance: none;
		pointer-events: none;
	}

	.dual-range::-webkit-slider-runnable-track {
		height: 0;
		background: transparent;
	}

	.dual-range::-moz-range-track {
		height: 0;
		background: transparent;
		border: none;
	}

	.dual-range::-webkit-slider-thumb {
		-webkit-appearance: none;
		appearance: none;
		width: 0.8rem;
		height: 0.8rem;
		border: 1px solid var(--gray-900);
		background: white;
		cursor: pointer;
		pointer-events: auto;
	}

	.dual-range::-moz-range-thumb {
		width: 0.8rem;
		height: 0.8rem;
		border: 1px solid var(--gray-900);
		background: white;
		cursor: pointer;
		pointer-events: auto;
	}

	.dual-range:disabled::-webkit-slider-thumb {
		cursor: not-allowed;
		background: var(--gray-200);
	}

	.dual-range:disabled::-moz-range-thumb {
		cursor: not-allowed;
		background: var(--gray-200);
	}
</style>

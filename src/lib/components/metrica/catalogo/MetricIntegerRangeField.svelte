<script lang="ts">
	import { untrack } from 'svelte';
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';

	const props = $props<{
		draft: MetricCatalogDomainRow;
		minKey: string;
		maxKey: string;
		label: string;
		help?: string;
	}>();

	let rangeMode = $state(
		untrack(() => props.draft[props.minKey] !== props.draft[props.maxKey])
	);

	function nullableNonNegativeInteger(value: string): number | null {
		if (!value.trim()) return null;
		const number = Number(value);
		return Number.isInteger(number) && number >= 0 ? number : null;
	}

	function setFixedValue(value: string) {
		const number = nullableNonNegativeInteger(value);
		props.draft[props.minKey] = number;
		props.draft[props.maxKey] = number;
	}

	function setBound(key: string, value: string) {
		props.draft[key] = nullableNonNegativeInteger(value);
	}

	function useFixedValue() {
		const number = props.draft[props.minKey] ?? props.draft[props.maxKey] ?? null;
		props.draft[props.minKey] = number;
		props.draft[props.maxKey] = number;
		rangeMode = false;
	}
</script>

<div class="space-y-2 md:col-span-2">
	<div class="flex flex-wrap items-center justify-between gap-2">
		<span class="text-sm font-medium">{props.label}</span>
		<button
			type="button"
			class="text-xs underline decoration-dotted underline-offset-4"
			onclick={() => (rangeMode ? useFixedValue() : (rangeMode = true))}
		>
			{rangeMode ? 'Usar un número fijo' : 'Usar un intervalo'}
		</button>
	</div>

	{#if rangeMode}
		<div class="grid gap-3 sm:grid-cols-2">
			<label class="space-y-1">
				<span class="text-xs text-[color:var(--muted-foreground)]">Mínimo</span>
				<input
					type="number"
					min="0"
					class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
					value={props.draft[props.minKey] ?? ''}
					oninput={(event) => setBound(props.minKey, event.currentTarget.value)}
				/>
			</label>
			<label class="space-y-1">
				<span class="text-xs text-[color:var(--muted-foreground)]">Máximo</span>
				<input
					type="number"
					min="0"
					class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
					value={props.draft[props.maxKey] ?? ''}
					oninput={(event) => setBound(props.maxKey, event.currentTarget.value)}
				/>
			</label>
		</div>
	{:else}
		<input
			type="number"
			min="0"
			class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
			value={props.draft[props.minKey] ?? ''}
			oninput={(event) => setFixedValue(event.currentTarget.value)}
		/>
	{/if}

	{#if props.help}
		<p class="text-xs leading-5 text-[color:var(--muted-foreground)]">{props.help}</p>
	{/if}
</div>

<script lang="ts">
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import type { CorpusComparisonWork } from '$lib/types/public-artifacts.types';
	import RotateCcw from 'lucide-svelte/icons/rotate-ccw';
	import SlidersHorizontal from 'lucide-svelte/icons/sliders-horizontal';

	const props = $props<{
		works: CorpusComparisonWork[];
		totalWorks: number;
		authorItems: { id: string; label: string; description?: string }[];
		selectedAuthors: string[];
		dateFrom: string;
		dateTo: string;
		metricCoverage?: number;
		onAuthorsChange: (ids: string[]) => void;
		onDateFromChange: (value: string) => void;
		onDateToChange: (value: string) => void;
		onReset: () => void;
	}>();

	const verses = $derived(
		props.works.reduce((sum, work) => sum + (work.metricas.total_versos ?? 0), 0)
	);
	const filtered = $derived(
		props.selectedAuthors.length > 0 || props.dateFrom.length > 0 || props.dateTo.length > 0
	);
</script>

<section class="border-y border-[color:var(--border)] bg-white" aria-labelledby="laboratory-sample-title">
	<div class="flex flex-col gap-4 px-4 py-4 lg:flex-row lg:items-end lg:px-5">
		<div class="min-w-0 lg:w-44 lg:shrink-0">
			<div class="flex items-center gap-2">
				<SlidersHorizontal class="h-4 w-4 text-[color:var(--primary)]" aria-hidden="true" />
				<h2 id="laboratory-sample-title" class="text-sm font-semibold">Muestra</h2>
			</div>
			<p class="mt-1 text-xs leading-5 text-[color:var(--muted-foreground)]">
				{filtered ? 'Subconjunto activo' : 'Corpus completo disponible'}
			</p>
		</div>

		<div class="grid min-w-0 flex-1 gap-3 sm:grid-cols-3">
			<label class="block min-w-0 text-xs font-semibold text-[color:var(--muted-foreground)]">
				<span>Autoría</span>
				<CheckDropdown
					class="mt-1"
					items={props.authorItems}
					selectedIds={props.selectedAuthors}
					placeholder="Todas las autorías"
					search={true}
					portal={true}
					onChange={props.onAuthorsChange}
				/>
			</label>
			<label class="block text-xs font-semibold text-[color:var(--muted-foreground)]">
				<span>Desde</span>
				<input
					type="number"
					value={props.dateFrom}
					placeholder="Año"
					class="mt-1 w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm font-normal text-[color:var(--foreground)]"
					oninput={(event) => props.onDateFromChange(event.currentTarget.value)}
				/>
			</label>
			<label class="block text-xs font-semibold text-[color:var(--muted-foreground)]">
				<span>Hasta</span>
				<input
					type="number"
					value={props.dateTo}
					placeholder="Año"
					class="mt-1 w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm font-normal text-[color:var(--foreground)]"
					oninput={(event) => props.onDateToChange(event.currentTarget.value)}
				/>
			</label>
		</div>

		<div class="flex shrink-0 items-center gap-4 border-t border-[color:var(--border)] pt-3 lg:border-l lg:border-t-0 lg:pl-5 lg:pt-0">
			<dl class="flex gap-4 text-right">
				<div>
					<dt class="text-[10px] uppercase tracking-wide text-[color:var(--muted-foreground)]">Obras</dt>
					<dd class="text-lg font-semibold tabular-nums">{props.works.length}<span class="text-xs font-normal text-[color:var(--muted-foreground)]">/{props.totalWorks}</span></dd>
				</div>
				<div>
					<dt class="text-[10px] uppercase tracking-wide text-[color:var(--muted-foreground)]">Versos</dt>
					<dd class="text-lg font-semibold tabular-nums">{verses.toLocaleString('es')}</dd>
				</div>
				{#if props.metricCoverage !== undefined}
					<div>
						<dt class="text-[10px] uppercase tracking-wide text-[color:var(--muted-foreground)]">Con dato</dt>
						<dd class="text-lg font-semibold tabular-nums">{props.metricCoverage}</dd>
					</div>
				{/if}
			</dl>
			<button
				type="button"
				class="inline-flex h-9 w-9 items-center justify-center rounded-md border border-[color:var(--border)] text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)] disabled:opacity-35"
				disabled={!filtered}
				aria-label="Restablecer muestra"
				title="Restablecer muestra"
				onclick={props.onReset}
			>
				<RotateCcw class="h-4 w-4" aria-hidden="true" />
			</button>
		</div>
	</div>
</section>

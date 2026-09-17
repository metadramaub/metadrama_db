<script lang="ts">
	import LaboratoryReadingKey from '$lib/components/laboratorio/LaboratoryReadingKey.svelte';
	import MetricFormLabel from '$lib/components/metrica/MetricFormLabel.svelte';
	import type {
		LaboratoryFeatureComparisonRow,
		LaboratoryFeatureGroupReading,
		LaboratoryFeatureWork
	} from '$lib/laboratorio/group-features';
	import ArrowRight from 'lucide-svelte/icons/arrow-right';
	import ChevronRight from 'lucide-svelte/icons/chevron-right';

	type ComparisonMode = 'diffusion' | 'typical';
	type FeatureKind = 'formas' | 'transiciones';
	type ValueUnit = 'porcentaje' | 'numero';

	const props = $props<{
		kind: FeatureKind;
		rows: LaboratoryFeatureComparisonRow[];
		mode: ComparisonMode;
		onModeChange: (mode: ComparisonMode) => void;
		typicalLabel: string;
		typicalBase: string;
		typicalUnit: ValueUnit;
		groupAColor: string;
		groupBColor: string;
		colorByForma: Record<string, string>;
		focusedWorkId?: string | null;
	}>();

	let expandedId = $state<string | null>(null);

	const sortedRows = $derived.by(() =>
		[...props.rows].sort((a, b) => {
			const differenceA = differenceMagnitude(a);
			const differenceB = differenceMagnitude(b);
			return differenceB - differenceA || a.label.localeCompare(b.label, 'es');
		})
	);

	function readingValue(reading: LaboratoryFeatureGroupReading): number | null {
		return props.mode === 'diffusion' ? reading.diffusion : reading.typical;
	}

	function difference(row: LaboratoryFeatureComparisonRow): number | null {
		const a = readingValue(row.groupA);
		const b = readingValue(row.groupB);
		return a === null || b === null ? null : a - b;
	}

	function differenceMagnitude(row: LaboratoryFeatureComparisonRow): number {
		const delta = difference(row);
		if (delta !== null) return Math.abs(delta);
		return Math.max(readingValue(row.groupA) ?? 0, readingValue(row.groupB) ?? 0);
	}

	function percent(value: number): string {
		return `${(value * 100).toLocaleString('es', { maximumFractionDigits: 2 })} %`;
	}

	function humanize(value: string): string {
		const normalized = value.replaceAll('_', ' ').replaceAll('-', ' ');
		return normalized.charAt(0).toLocaleUpperCase('es') + normalized.slice(1);
	}

	function number(value: number): string {
		return value.toLocaleString('es', { maximumFractionDigits: 2 });
	}

	function formatValue(value: number | null): string {
		if (value === null) return '—';
		if (props.mode === 'diffusion' || props.typicalUnit === 'porcentaje') return percent(value);
		return number(value);
	}

	function formatDifference(row: LaboratoryFeatureComparisonRow): string {
		const value = difference(row);
		if (value === null) return '—';
		const sign = value > 0 ? '+' : value < 0 ? '−' : '';
		const magnitude = Math.abs(value);
		if (props.mode === 'diffusion' || props.typicalUnit === 'porcentaje') {
			return `${sign}${number(magnitude * 100)} pp`;
		}
		return `${sign}${number(magnitude)}`;
	}

	function secondary(reading: LaboratoryFeatureGroupReading): string {
		if (props.mode === 'diffusion') {
			return `${reading.presentWorks} de ${reading.totalWorks} obras`;
		}
		if (reading.totalWorks === 0) return 'Grupo sin obras';
		if (reading.valueWorks === 0) return 'No aparece';
		return `${reading.valueWorks} ${reading.valueWorks === 1 ? 'obra' : 'obras'} en el cálculo`;
	}

	function formatWorkValue(work: LaboratoryFeatureWork): string {
		if (props.mode === 'diffusion') return 'Presente';
		if (work.value === null) return 'Sin valor';
		if (props.typicalUnit === 'porcentaje') return percent(work.value);
		return `${number(work.value)} ${work.value === 1 ? 'vez' : 'veces'}`;
	}

	function includesFocusedWork(reading: LaboratoryFeatureGroupReading): boolean {
		if (!props.focusedWorkId) return false;
		return reading.works.some(
			(work: LaboratoryFeatureWork) => work.id === props.focusedWorkId
		);
	}

	function toggle(id: string) {
		expandedId = expandedId === id ? null : id;
	}
</script>

<section class="border border-[color:var(--border)] bg-white">
	<header class="border-b border-[color:var(--border)] px-5 py-4">
		<div class="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
			<h2 class="text-xl font-semibold">
				{props.kind === 'formas' ? 'Comparación de formas' : 'Comparación de transiciones'}
			</h2>
			<div class="inline-flex self-start border border-[color:var(--border)] bg-[color:var(--gray-50)] p-0.5" aria-label="Magnitud comparada">
				<button
					type="button"
					class={`px-3 py-1.5 text-xs font-semibold ${props.mode === 'diffusion' ? 'bg-white text-[color:var(--foreground)] shadow-sm' : 'text-[color:var(--muted-foreground)]'}`}
					onclick={() => props.onModeChange('diffusion')}
				>
					Difusión
				</button>
				<button
					type="button"
					class={`px-3 py-1.5 text-xs font-semibold ${props.mode === 'typical' ? 'bg-white text-[color:var(--foreground)] shadow-sm' : 'text-[color:var(--muted-foreground)]'}`}
					onclick={() => props.onModeChange('typical')}
				>
					{props.typicalLabel}
				</button>
			</div>
		</div>
		<LaboratoryReadingKey
			title="Base de comparación"
			items={[
				{
					label: 'Difusión',
					value: `Obras con ${props.kind === 'formas' ? 'la forma' : 'la transición'} ÷ obras del grupo`
				},
				{ label: props.typicalLabel, value: props.typicalBase }
			]}
		/>
	</header>

	{#if sortedRows.length === 0}
		<p class="px-5 py-10 text-center text-sm text-[color:var(--muted-foreground)]">
			No hay {props.kind} en los grupos seleccionados.
		</p>
	{:else}
		<div class="overflow-x-auto">
			<table class="min-w-[52rem] w-full text-sm">
				<thead class="bg-[color:var(--gray-50)] text-left text-xs text-[color:var(--muted-foreground)]">
					<tr>
						<th class="px-5 py-2.5 font-medium">{props.kind === 'formas' ? 'Forma' : 'Transición'}</th>
						<th class="px-4 py-2.5 text-right font-medium">
							<span class="inline-flex items-center gap-1.5"><span class="h-2 w-2" style:background-color={props.groupAColor}></span>Grupo A</span>
						</th>
						<th class="px-4 py-2.5 text-right font-medium">
							<span class="inline-flex items-center gap-1.5"><span class="h-2 w-2" style:background-color={props.groupBColor}></span>Grupo B</span>
						</th>
						<th class="px-5 py-2.5 text-right font-medium">A − B</th>
					</tr>
				</thead>
				<tbody class="divide-y divide-[color:var(--border)]">
					{#each sortedRows as row (row.id)}
						<tr class={expandedId === row.id ? 'bg-[color:var(--gray-50)]' : ''}>
							<td class="px-5 py-3 align-top">
								<button
									type="button"
									class="flex w-full items-start gap-2 text-left"
									onclick={() => toggle(row.id)}
									aria-expanded={expandedId === row.id}
								>
									<ChevronRight class={`mt-0.5 h-4 w-4 shrink-0 text-[color:var(--muted-foreground)] transition-transform ${expandedId === row.id ? 'rotate-90' : ''}`} aria-hidden="true" />
									<span class="min-w-0">
										{#if props.kind === 'formas'}
											<MetricFormLabel forma={row.label} colorKey={row.id} colorByForma={props.colorByForma} className="font-medium" />
										{:else if row.from && row.to}
											<span class="grid grid-cols-[minmax(0,1fr)_1rem_minmax(0,1fr)] items-center gap-2">
												<MetricFormLabel forma={humanize(row.from)} colorKey={row.from} colorByForma={props.colorByForma} className="font-medium" />
												<ArrowRight class="h-4 w-4 text-[color:var(--muted-foreground)]" aria-hidden="true" />
												<MetricFormLabel forma={humanize(row.to)} colorKey={row.to} colorByForma={props.colorByForma} className="font-medium" />
											</span>
										{/if}
										{#if includesFocusedWork(row.groupA) || includesFocusedWork(row.groupB)}
											<span class="mt-1 block text-[11px] text-[color:var(--muted-foreground)]">En la obra de referencia</span>
										{/if}
									</span>
								</button>
							</td>
							{#each [row.groupA, row.groupB] as reading}
								<td class="px-4 py-3 text-right align-top tabular-nums">
									<strong>{formatValue(readingValue(reading))}</strong>
									<span class="mt-0.5 block text-xs text-[color:var(--muted-foreground)]">{secondary(reading)}</span>
								</td>
							{/each}
							<td class="px-5 py-3 text-right align-top font-semibold tabular-nums">{formatDifference(row)}</td>
						</tr>
						{#if expandedId === row.id}
							<tr>
								<td colspan="4" class="border-t border-dashed border-[color:var(--border)] bg-[color:var(--gray-50)] px-5 py-4">
									<div class="grid gap-5 sm:grid-cols-2 sm:divide-x sm:divide-[color:var(--border)]">
										{#each [
											{ label: 'Grupo A', color: props.groupAColor, reading: row.groupA },
											{ label: 'Grupo B', color: props.groupBColor, reading: row.groupB }
										] as group}
											<section class="sm:pl-5 first:pl-0">
												<h3 class="flex items-center gap-1.5 text-xs font-semibold"><span class="h-2 w-2" style:background-color={group.color}></span>{group.label}</h3>
												{#if group.reading.works.length > 0}
													<ul class="mt-2 space-y-1.5">
														{#each group.reading.works as work (work.id)}
															<li class={`flex items-baseline justify-between gap-3 text-xs ${work.id === props.focusedWorkId ? 'font-semibold text-[color:var(--foreground)]' : 'text-[color:var(--muted-foreground)]'}`}>
																<a class="hover:text-[color:var(--foreground)] hover:underline" href={`/obras/${work.slug}`}>{work.title}</a>
																<span class="shrink-0 tabular-nums">{formatWorkValue(work)}</span>
															</li>
														{/each}
													</ul>
												{:else}
													<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">No aparece en este grupo.</p>
												{/if}
											</section>
										{/each}
									</div>
								</td>
							</tr>
						{/if}
					{/each}
				</tbody>
			</table>
		</div>
	{/if}
</section>

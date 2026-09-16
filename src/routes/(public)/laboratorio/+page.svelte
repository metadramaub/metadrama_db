<script lang="ts">
	import LaboratoryDistributionChart from '$lib/components/laboratorio/LaboratoryDistributionChart.svelte';
	import LaboratoryFocusedWorkSummary from '$lib/components/laboratorio/LaboratoryFocusedWorkSummary.svelte';
	import LaboratoryGroupComparisonChart from '$lib/components/laboratorio/LaboratoryGroupComparisonChart.svelte';
	import LaboratoryGroupFilter from '$lib/components/laboratorio/LaboratoryGroupFilter.svelte';
	import LaboratoryGroupSummary from '$lib/components/laboratorio/LaboratoryGroupSummary.svelte';
	import LaboratoryMetricHeader from '$lib/components/laboratorio/LaboratoryMetricHeader.svelte';
	import LaboratoryMetricNav from '$lib/components/laboratorio/LaboratoryMetricNav.svelte';
	import LaboratoryReadingKey from '$lib/components/laboratorio/LaboratoryReadingKey.svelte';
	import LaboratoryRelationMap from '$lib/components/laboratorio/LaboratoryRelationMap.svelte';
	import LaboratorySampleBar from '$lib/components/laboratorio/LaboratorySampleBar.svelte';
	import MetricAnalysisHeading from '$lib/components/metrica/MetricAnalysisHeading.svelte';
	import MetricFormLabel from '$lib/components/metrica/MetricFormLabel.svelte';
	import PublicPageHeader from '$lib/components/public/PublicPageHeader.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import Tabs from '$lib/components/ui/tabs.svelte';
	import {
		formatLaboratoryDifference,
		formatLaboratoryFraction,
		formatLaboratoryValue,
		LABORATORY_METRICS,
		summarizeLaboratoryValues
	} from '$lib/laboratorio/metricas';
	import type { CorpusComparisonWork } from '$lib/types/public-artifacts.types';
	import { colorForForma } from '$lib/utils/metric-colors';
	import ArrowRight from 'lucide-svelte/icons/arrow-right';
	import CircleAlert from 'lucide-svelte/icons/circle-alert';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	type LaboratorySpace = 'explorar' | 'comparar';
	type ExplorationView = 'medidas' | 'formas' | 'transiciones';
	type FormRow = {
		id: string;
		label: string;
		tipo: string | null;
		works: number;
		diffusion: number;
		medianShare: number;
		sequences: number;
	};
	type TransitionRow = {
		id: string;
		from: string;
		to: string;
		works: number;
		diffusion: number;
		occurrences: number;
		meanWhenPresent: number;
	};

	const corpus = $derived(data.corpus);
	const allWorks = $derived<CorpusComparisonWork[]>(corpus?.obras ?? []);
	const GROUP_A_COLOR = '#3f6f78';
	const GROUP_B_COLOR = '#765f7d';

	let activeSpace = $state<LaboratorySpace>('explorar');
	let activeView = $state<ExplorationView>('medidas');
	let selectedMetricId = $state('numero_efectivo_formas');
	let selectedAuthors = $state<string[]>([]);
	let dateFrom = $state('');
	let dateTo = $state('');
	let situatedWorkId = $state('');
	let groupAAuthors = $state<string[]>([]);
	let groupADateFrom = $state('');
	let groupADateTo = $state('');
	let groupBAuthors = $state<string[]>([]);
	let groupBDateFrom = $state('');
	let groupBDateTo = $state('');

	const authorItems = $derived(buildAuthorItems(allWorks));
	const sampleWorks = $derived(filterWorks(allWorks, selectedAuthors, dateFrom, dateTo));
	const sampleAuthorItems = $derived(buildAuthorItems(sampleWorks));
	const groupAWorks = $derived(filterWorks(sampleWorks, groupAAuthors, groupADateFrom, groupADateTo));
	const groupBWorks = $derived(filterWorks(sampleWorks, groupBAuthors, groupBDateFrom, groupBDateTo));

	const selectedMetric = $derived(
		LABORATORY_METRICS.find((metric) => metric.id === selectedMetricId) ?? LABORATORY_METRICS[0]
	);
	const metricRows = $derived.by(() =>
		sampleWorks.map((work) => ({ work, reading: selectedMetric.read(work) }))
	);
	const metricSummary = $derived(
		summarizeLaboratoryValues(metricRows.map((row) => row.reading.value))
	);
	const chartRows = $derived(
		metricRows
			.filter((row) => row.reading.value !== null)
			.map((row) => ({
				id: row.work.obra_id,
				title: row.work.titulo,
				authors: row.work.autores.join(', ') || 'Autoría sin identificar',
				value: row.reading.value as number
			}))
	);
	const orderedMetricRows = $derived(
		[...metricRows].sort(
			(a, b) =>
				(b.reading.value ?? -Infinity) - (a.reading.value ?? -Infinity) ||
				a.work.titulo.localeCompare(b.work.titulo, 'es')
		)
	);
	const groupAMetricRows = $derived.by(() =>
		groupAWorks.map((work) => ({ work, reading: selectedMetric.read(work) }))
	);
	const groupBMetricRows = $derived.by(() =>
		groupBWorks.map((work) => ({ work, reading: selectedMetric.read(work) }))
	);
	const groupASummary = $derived(
		summarizeLaboratoryValues(groupAMetricRows.map((row) => row.reading.value))
	);
	const groupBSummary = $derived(
		summarizeLaboratoryValues(groupBMetricRows.map((row) => row.reading.value))
	);
	const groupAChartRows = $derived(
		groupAMetricRows
			.filter((row) => row.reading.value !== null)
			.map((row) => ({
				id: row.work.obra_id,
				title: row.work.titulo,
				authors: row.work.autores.join(', ') || 'Autoría sin identificar',
				value: row.reading.value as number
			}))
	);
	const groupBChartRows = $derived(
		groupBMetricRows
			.filter((row) => row.reading.value !== null)
			.map((row) => ({
				id: row.work.obra_id,
				title: row.work.titulo,
				authors: row.work.autores.join(', ') || 'Autoría sin identificar',
				value: row.reading.value as number
			}))
	);
	const groupMedianDifference = $derived(
		groupASummary.median !== null && groupBSummary.median !== null
			? groupASummary.median - groupBSummary.median
			: null
	);
	const groupOverlapCount = $derived.by(() => {
		const groupBIds = new Set(groupBWorks.map((work) => work.obra_id));
		return groupAWorks.filter((work) => groupBIds.has(work.obra_id)).length;
	});
	const groupsAreEqual = $derived(
		groupAWorks.length === groupBWorks.length && groupOverlapCount === groupAWorks.length
	);
	const situatedWork = $derived(
		sampleWorks.find((work) => work.obra_id === situatedWorkId) ?? null
	);
	const situatedWorkItems = $derived(
		[...sampleWorks]
			.sort((a, b) => a.titulo.localeCompare(b.titulo, 'es'))
			.map((work) => ({
				id: work.obra_id,
				label: work.titulo,
				description: `${work.autores.join(', ') || 'Autoría sin identificar'} · ${dateLabel(work)}`
			}))
	);
	const situatedReading = $derived(
		situatedWork ? selectedMetric.read(situatedWork) : { value: null }
	);
	const situatedPosition = $derived.by(() => {
		const value = situatedReading.value;
		const values = metricRows
			.map((row) => row.reading.value)
			.filter((entry): entry is number => entry !== null && Number.isFinite(entry));
		if (value === null || !Number.isFinite(value)) {
			return { location: 'Sin dato para esta obra', rank: '—' };
		}
		if (values.length === 0) return { location: 'Sin datos comparables', rank: '—' };

		const higher = values.filter((entry) => entry > value).length;
		const equal = values.filter((entry) => entry === value).length;
		const firstRank = higher + 1;
		const lastRank = higher + equal;
		const rank =
			equal > 1
				? `${firstRank}–${lastRank} de ${values.length} (empate)`
				: `${firstRank} de ${values.length}`;

		if (metricSummary.minimum === metricSummary.maximum) {
			return { location: 'Sin variación en la muestra', rank };
		}
		if (value === metricSummary.maximum) return { location: 'Máximo observado', rank };
		if (value === metricSummary.minimum) return { location: 'Mínimo observado', rank };
		if (metricSummary.q1 !== null && value < metricSummary.q1) {
			return { location: 'Por debajo del rango central', rank };
		}
		if (metricSummary.q3 !== null && value > metricSummary.q3) {
			return { location: 'Por encima del rango central', rank };
		}
		return { location: 'Dentro del rango central', rank };
	});

	const formRows = $derived.by((): FormRow[] => buildFormRows(sampleWorks));
	const colorByForma = $derived(
		Object.fromEntries(
			formRows.map((row) => [row.id, colorForForma({ slug: row.id, tipoForma: row.tipo })])
		)
	);
	const formMapPoints = $derived(
		formRows.map((row) => ({
			id: row.id,
			label: row.label,
			x: row.diffusion * 100,
			y: row.medianShare * 100,
			color: colorByForma[row.id],
			detail: `${row.works} de ${sampleWorks.length} obras · mediana ${formatPercent(row.medianShare)} donde aparece`
		}))
	);

	const transitionRows = $derived.by((): TransitionRow[] => buildTransitionRows(sampleWorks));
	const transitionMapPoints = $derived(
		transitionRows.map((row) => ({
			id: row.id,
			label: `${humanize(row.from)} → ${humanize(row.to)}`,
			x: row.diffusion * 100,
			y: row.meanWhenPresent,
			detail: `${row.works} de ${sampleWorks.length} obras · ${row.occurrences} apariciones en total`
		}))
	);

	const formattedGeneratedAt = $derived(
		data.generatedAt
			? new Intl.DateTimeFormat('es', { dateStyle: 'medium', timeStyle: 'short' }).format(
					new Date(data.generatedAt)
				)
			: null
	);

	function parseYear(value: string): number | null {
		if (!value.trim()) return null;
		const parsed = Number(value);
		return Number.isFinite(parsed) ? parsed : null;
	}

	function resetSample() {
		selectedAuthors = [];
		dateFrom = '';
		dateTo = '';
	}

	function resetGroupA() {
		groupAAuthors = [];
		groupADateFrom = '';
		groupADateTo = '';
	}

	function resetGroupB() {
		groupBAuthors = [];
		groupBDateFrom = '';
		groupBDateTo = '';
	}

	function selectMetric(id: string) {
		selectedMetricId = id;
	}

	function humanize(value: string): string {
		const normalized = value.replaceAll('_', ' ').replaceAll('-', ' ');
		return normalized.charAt(0).toLocaleUpperCase('es') + normalized.slice(1);
	}

	function formatPercent(value: number): string {
		return `${(value * 100).toLocaleString('es', { maximumFractionDigits: 2 })} %`;
	}

	function dateLabel(work: CorpusComparisonWork): string {
		const start = work.fecha_inicio_trad;
		const end = work.fecha_fin_trad;
		if (start === null && end === null) return 's. f.';
		if (start === end || end === null) return String(start);
		if (start === null) return String(end);
		return `${start}–${end}`;
	}

	function buildAuthorItems(works: CorpusComparisonWork[]) {
		return [...new Set(works.flatMap((work) => work.autores))]
			.map((author) => ({
				id: author,
				label: author,
				description: `${works.filter((work) => work.autores.includes(author)).length} obras`
			}))
			.sort((a, b) => a.label.localeCompare(b.label, 'es'));
	}

	function filterWorks(
		works: CorpusComparisonWork[],
		authors: string[],
		fromValue: string,
		toValue: string
	): CorpusComparisonWork[] {
		const from = parseYear(fromValue);
		const to = parseYear(toValue);
		return works.filter((work) => {
			if (authors.length > 0 && !work.autores.some((author) => authors.includes(author))) return false;
			if (from === null && to === null) return true;
			const start = work.fecha_inicio_trad;
			const end = work.fecha_fin_trad ?? start;
			if (start === null && end === null) return false;
			if (from !== null && (end ?? start ?? -Infinity) < from) return false;
			if (to !== null && (start ?? end ?? Infinity) > to) return false;
			return true;
		});
	}

	function buildFormRows(works: CorpusComparisonWork[]): FormRow[] {
		const forms = new Map<
			string,
			{ tipo: string | null; workIds: Set<string>; shares: number[]; sequences: number }
		>();

		for (const work of works) {
			for (const [id, entry] of Object.entries(work.perfil_formas)) {
				if (id === 'sin-forma-anotada' || entry.versos <= 0) continue;
				const current = forms.get(id) ?? {
					tipo: entry.tipo_forma,
					workIds: new Set<string>(),
					shares: [],
					sequences: 0
				};
				current.tipo ??= entry.tipo_forma;
				current.workIds.add(work.obra_id);
				current.shares.push(entry.proporcion_versos ?? 0);
				current.sequences += entry.secuencias;
				forms.set(id, current);
			}
		}

		return [...forms.entries()]
			.map(([id, value]) => {
				const summary = summarizeLaboratoryValues(value.shares);
				return {
					id,
					label: humanize(id),
					tipo: value.tipo,
					works: value.workIds.size,
					diffusion: works.length > 0 ? value.workIds.size / works.length : 0,
					medianShare: summary.median ?? 0,
					sequences: value.sequences
				};
			})
			.sort((a, b) => b.works - a.works || b.medianShare - a.medianShare || a.label.localeCompare(b.label, 'es'));
	}

	function buildTransitionRows(works: CorpusComparisonWork[]): TransitionRow[] {
		const transitions = new Map<
			string,
			{ from: string; to: string; workIds: Set<string>; occurrences: number }
		>();

		for (const work of works) {
			for (const transition of work.transiciones) {
				const id = `${transition.de}→${transition.a}`;
				const current = transitions.get(id) ?? {
					from: transition.de,
					to: transition.a,
					workIds: new Set<string>(),
					occurrences: 0
				};
				current.workIds.add(work.obra_id);
				current.occurrences += transition.veces;
				transitions.set(id, current);
			}
		}

		return [...transitions.entries()]
			.map(([id, value]) => ({
				id,
				from: value.from,
				to: value.to,
				works: value.workIds.size,
				diffusion: works.length > 0 ? value.workIds.size / works.length : 0,
				occurrences: value.occurrences,
				meanWhenPresent:
					value.workIds.size > 0 ? value.occurrences / value.workIds.size : 0
			}))
			.sort(
				(a, b) =>
					b.works - a.works ||
					b.occurrences - a.occurrences ||
					a.id.localeCompare(b.id, 'es')
			);
	}
</script>

<section class="space-y-8">
	<PublicPageHeader
		eyebrow="HERRAMIENTA DE INVESTIGACIÓN"
		title="Laboratorio"
		badge="Corpus de prueba"
		description=""
	/>

	{#if !corpus}
		<div class="border-l-2 border-[color:var(--warning)] bg-white px-5 py-4 text-sm">
			<p class="font-semibold">El banco comparativo todavía no está disponible.</p>
			<p class="mt-1 text-[color:var(--muted-foreground)]">
				Actualiza la precomputación global para materializar el artefacto V2 del laboratorio.
			</p>
		</div>
	{:else}
		<div class="space-y-5">
			<div class="flex flex-wrap items-center justify-between gap-3 text-xs text-[color:var(--muted-foreground)]">
				<p>
					Universo: <strong class="font-semibold text-[color:var(--foreground)]">{data.alcance === 'completo' ? 'todas las obras publicadas' : 'obras publicadas y visibles'}</strong>
				</p>
				<p>
					{#if data.stale}<span class="mr-2 font-semibold text-[color:var(--warning)]">Actualización pendiente</span>{/if}
					{#if formattedGeneratedAt}Generado {formattedGeneratedAt}{/if}
				</p>
			</div>

			<LaboratorySampleBar
				works={sampleWorks}
				totalWorks={allWorks.length}
				{authorItems}
				{selectedAuthors}
				{dateFrom}
				{dateTo}
				metricCoverage={activeSpace === 'comparar' || activeView === 'medidas' ? metricSummary.n : undefined}
				onAuthorsChange={(ids) => (selectedAuthors = ids)}
				onDateFromChange={(value) => (dateFrom = value)}
				onDateToChange={(value) => (dateTo = value)}
				onReset={resetSample}
			/>

			<div class="border-b border-[color:var(--border)]">
				<div class="flex flex-wrap gap-x-7 gap-y-2" aria-label="Espacios del laboratorio">
					<button
						type="button"
						class={`border-b-2 pb-3 text-sm transition-colors ${activeSpace === 'explorar' ? 'border-[color:var(--primary)] font-semibold' : 'border-transparent text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)]'}`}
						onclick={() => (activeSpace = 'explorar')}
					>
						Explorar
					</button>
					<button
						type="button"
						class={`border-b-2 pb-3 text-sm transition-colors ${activeSpace === 'comparar' ? 'border-[color:var(--primary)] font-semibold' : 'border-transparent text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)]'}`}
						onclick={() => (activeSpace = 'comparar')}
					>
						Comparar grupos
					</button>
					<span class="pb-3 text-sm text-[color:var(--muted-foreground)]">Afinidades</span>
				</div>
			</div>

			{#if activeSpace === 'explorar'}
				<div class="space-y-6">
				<div class="space-y-4">
					<MetricAnalysisHeading
						title="Explorar la muestra"
						description="Elige qué observar y, si quieres, señala una obra para situarla dentro de la misma muestra."
					/>
					<div class="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
						<label class="block w-full text-sm sm:max-w-sm">
							<span class="font-medium">Obra de referencia <span class="font-normal text-[color:var(--muted-foreground)]">(opcional)</span></span>
							<CheckDropdown
								class="mt-1"
								multiple={false}
								items={situatedWorkItems}
								selectedIds={situatedWork ? [situatedWork.obra_id] : []}
								placeholder="Ninguna obra destacada"
								search={true}
								portal={true}
								allowSingleClear={true}
								onChange={(ids) => (situatedWorkId = ids[0] ?? '')}
							/>
						</label>
						<div class="sm:max-w-max">
							<Tabs
								tabs={[
									{ id: 'medidas', label: 'Medidas' },
									{ id: 'formas', label: 'Formas' },
									{ id: 'transiciones', label: 'Transiciones' }
								]}
								active={activeView}
								onChange={(id) => (activeView = id as ExplorationView)}
							/>
						</div>
					</div>
				</div>

				{#if sampleWorks.length === 0}
					<div class="border-y border-[color:var(--border)] py-10 text-center text-sm text-[color:var(--muted-foreground)]">
						Ninguna obra coincide con la muestra. Amplía o restablece los filtros.
					</div>
				{:else if activeView === 'medidas'}
					<div class="grid items-start gap-6 lg:grid-cols-[15rem_minmax(0,1fr)]">
						<LaboratoryMetricNav selectedId={selectedMetric.id} onSelect={selectMetric} />

						<section class="min-w-0 border border-[color:var(--border)] bg-white" aria-labelledby="selected-metric-title">
							<LaboratoryMetricHeader metric={selectedMetric} titleId="selected-metric-title" />
							{#if situatedWork}
								<LaboratoryFocusedWorkSummary
									work={situatedWork}
									metric={selectedMetric}
									reading={situatedReading}
									position={situatedPosition}
									date={dateLabel(situatedWork)}
								/>
							{/if}

							<div class="px-5 py-4">
								<dl class="flex flex-wrap gap-x-7 gap-y-2 border-b border-[color:var(--border)] pb-4">
									<div><dt class="text-xs text-[color:var(--muted-foreground)]">Obras con dato</dt><dd class="mt-0.5 font-semibold tabular-nums">{metricSummary.n} de {sampleWorks.length}</dd></div>
									<div><dt class="text-xs text-[color:var(--muted-foreground)]">Mediana</dt><dd class="mt-0.5 font-semibold tabular-nums">{formatLaboratoryValue(metricSummary.median, selectedMetric)}</dd></div>
									<div><dt class="text-xs text-[color:var(--muted-foreground)]">Rango central</dt><dd class="mt-0.5 font-semibold tabular-nums">{formatLaboratoryValue(metricSummary.q1, selectedMetric)}–{formatLaboratoryValue(metricSummary.q3, selectedMetric)}</dd></div>
									<div><dt class="text-xs text-[color:var(--muted-foreground)]">Extremos</dt><dd class="mt-0.5 font-semibold tabular-nums">{formatLaboratoryValue(metricSummary.minimum, selectedMetric)}–{formatLaboratoryValue(metricSummary.maximum, selectedMetric)}</dd></div>
								</dl>

								{#if chartRows.length > 0}
									<LaboratoryDistributionChart
										rows={chartRows}
										metric={selectedMetric}
										q1={metricSummary.q1}
										median={metricSummary.median}
										q3={metricSummary.q3}
										focusedId={situatedWork?.obra_id ?? null}
										formatValue={(value) => formatLaboratoryValue(value, selectedMetric)}
									/>
								{/if}
							</div>

							<div class="overflow-x-auto border-t border-[color:var(--border)]">
								<table class="min-w-full text-sm">
									<thead class="bg-[color:var(--gray-50)] text-left text-xs text-[color:var(--muted-foreground)]">
										<tr>
											<th class="px-5 py-2.5 font-medium">Obra</th>
											<th class="px-3 py-2.5 font-medium">Datación</th>
											<th class="px-5 py-2.5 text-right font-medium">Valor</th>
										</tr>
									</thead>
									<tbody class="divide-y divide-[color:var(--border)]">
									{#each orderedMetricRows as row (row.work.obra_id)}
										{@const fraction = formatLaboratoryFraction(row.reading, selectedMetric)}
										<tr class={situatedWork?.obra_id === row.work.obra_id ? 'bg-[color:var(--muted)]' : ''}>
											<td class="px-5 py-2.5">
												<button type="button" class="text-left" onclick={() => (situatedWorkId = situatedWork?.obra_id === row.work.obra_id ? '' : row.work.obra_id)}>
														<span class="block font-medium">{row.work.titulo}</span>
														<span class="block text-xs text-[color:var(--muted-foreground)]">{row.work.autores.join(', ') || 'Autoría sin identificar'}</span>
													</button>
												</td>
												<td class="whitespace-nowrap px-3 py-2.5 text-xs text-[color:var(--muted-foreground)]">{dateLabel(row.work)}</td>
												<td class="px-5 py-2.5 text-right">
													<span class="font-semibold tabular-nums">{formatLaboratoryValue(row.reading.value, selectedMetric)}</span>
													{#if fraction}
														<span class="ml-2 whitespace-nowrap text-xs tabular-nums text-[color:var(--muted-foreground)]">{fraction}</span>
													{/if}
												</td>
											</tr>
										{/each}
									</tbody>
								</table>
							</div>
						</section>
					</div>
				{:else if activeView === 'formas'}
					<section class="border border-[color:var(--border)] bg-white">
						<header class="border-b border-[color:var(--border)] px-5 py-4">
							<MetricAnalysisHeading
								title="Difusión y peso de las formas"
								description="Sitúa cada forma según cuánto se extiende por el corpus y cuánto pesa dentro de las obras que la usan."
							/>
							<LaboratoryReadingKey
								title="Qué representa cada valor"
								items={[
									{ label: 'Difusión', value: 'Obras de la muestra en que aparece' },
									{ label: 'Peso mediano', value: '% de versos donde aparece' },
									{ label: 'Secuencias', value: 'Apariciones acumuladas en la muestra' }
								]}
							/>
						</header>
						<div class="px-4 py-4 sm:px-5">
							<LaboratoryRelationMap
								points={formMapPoints}
								xLabel="Obras donde aparece"
								yLabel="Peso mediano (%)"
								ariaLabel="Mapa de difusión y peso de las formas métricas"
							/>
						</div>
						<div class="overflow-x-auto border-t border-[color:var(--border)]">
							<table class="min-w-full text-sm">
								<thead class="bg-[color:var(--gray-50)] text-left text-xs text-[color:var(--muted-foreground)]">
									<tr>
										<th class="px-5 py-2.5 font-medium">Forma</th>
										<th class="px-3 py-2.5 text-right font-medium">Difusión</th>
										<th class="px-3 py-2.5 text-right font-medium">Peso mediano</th>
										<th class="px-5 py-2.5 text-right font-medium">Secuencias</th>
										{#if situatedWork}<th class="px-5 py-2.5 text-right font-medium">En la obra</th>{/if}
									</tr>
								</thead>
								<tbody class="divide-y divide-[color:var(--border)]">
									{#each formRows as row (row.id)}
										{@const workForm = situatedWork?.perfil_formas[row.id]}
										<tr class={workForm ? 'bg-[color:var(--gray-50)]' : ''}>
											<td class="px-5 py-2.5"><MetricFormLabel forma={row.label} colorKey={row.id} {colorByForma} className="font-medium" /></td>
											<td class="px-3 py-2.5 text-right tabular-nums"><strong>{row.works}</strong><span class="text-xs text-[color:var(--muted-foreground)]">/{sampleWorks.length}</span></td>
											<td class="px-3 py-2.5 text-right tabular-nums">{formatPercent(row.medianShare)}</td>
											<td class="px-5 py-2.5 text-right tabular-nums">{row.sequences}</td>
											{#if situatedWork}
												<td class="px-5 py-2.5 text-right tabular-nums">
													{#if workForm}
														<strong>{formatPercent(workForm.proporcion_versos ?? 0)}</strong>
														<span class="ml-2 whitespace-nowrap text-xs text-[color:var(--muted-foreground)]">{workForm.secuencias} sec.</span>
													{:else}
														<span class="text-xs text-[color:var(--muted-foreground)]">No aparece</span>
													{/if}
												</td>
											{/if}
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
					</section>
				{:else}
					<section class="border border-[color:var(--border)] bg-white">
						<header class="border-b border-[color:var(--border)] px-5 py-4">
							<MetricAnalysisHeading
								title="Difusión y frecuencia de las transiciones"
								description="Sitúa cada paso métrico según su extensión por el corpus y la frecuencia con que reaparece donde se usa."
							/>
							<LaboratoryReadingKey
								title="Qué representa cada valor"
								items={[
									{ label: 'Difusión', value: 'Obras de la muestra en que aparece' },
									{ label: 'Media donde aparece', value: 'Apariciones por obra que la contiene' },
									{ label: 'Total', value: 'Apariciones acumuladas en la muestra' }
								]}
							/>
						</header>
						<div class="px-4 py-4 sm:px-5">
							<LaboratoryRelationMap
								points={transitionMapPoints}
								xLabel="Obras donde aparece"
								yLabel="Apariciones por obra usuaria"
								ariaLabel="Mapa de difusión y frecuencia de las transiciones métricas"
							/>
						</div>
						<div class="overflow-x-auto border-t border-[color:var(--border)]">
							<table class="min-w-full text-sm">
								<thead class="bg-[color:var(--gray-50)] text-left text-xs text-[color:var(--muted-foreground)]">
									<tr>
										<th class="px-5 py-2.5 font-medium">Transición</th>
										<th class="px-3 py-2.5 text-right font-medium">Difusión</th>
										<th class="px-3 py-2.5 text-right font-medium">Media donde aparece</th>
										<th class="px-5 py-2.5 text-right font-medium">Total</th>
										{#if situatedWork}<th class="px-5 py-2.5 text-right font-medium">En la obra</th>{/if}
									</tr>
								</thead>
								<tbody class="divide-y divide-[color:var(--border)]">
									{#each transitionRows as row (row.id)}
										{@const workTransition = situatedWork?.transiciones.find((transition) => transition.de === row.from && transition.a === row.to)}
										<tr class={workTransition ? 'bg-[color:var(--gray-50)]' : ''}>
											<td class="px-5 py-2.5"><div class="grid grid-cols-[minmax(0,1fr)_1rem_minmax(0,1fr)] items-center gap-2"><MetricFormLabel forma={humanize(row.from)} colorKey={row.from} {colorByForma} className="font-medium" /><ArrowRight class="h-4 w-4 text-[color:var(--muted-foreground)]" aria-hidden="true" /><MetricFormLabel forma={humanize(row.to)} colorKey={row.to} {colorByForma} className="font-medium" /></div></td>
											<td class="px-3 py-2.5 text-right tabular-nums"><strong>{row.works}</strong><span class="text-xs text-[color:var(--muted-foreground)]">/{sampleWorks.length}</span></td>
											<td class="px-3 py-2.5 text-right tabular-nums">{row.meanWhenPresent.toLocaleString('es', { maximumFractionDigits: 2 })}</td>
											<td class="px-5 py-2.5 text-right font-semibold tabular-nums">{row.occurrences}</td>
											{#if situatedWork}
												<td class="px-5 py-2.5 text-right tabular-nums">
													{#if workTransition}
														<strong>{workTransition.veces}</strong> <span class="text-xs text-[color:var(--muted-foreground)]">{workTransition.veces === 1 ? 'vez' : 'veces'}</span>
													{:else}
														<span class="text-xs text-[color:var(--muted-foreground)]">No aparece</span>
													{/if}
												</td>
											{/if}
										</tr>
									{/each}
								</tbody>
							</table>
						</div>
					</section>
				{/if}
				</div>
			{:else}
				<div class="space-y-6">
					<div class="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
						<MetricAnalysisHeading
							title="Comparar grupos"
							description="Define dos subconjuntos dentro de la muestra activa y compara una medida sin ocultar las obras que forman cada distribución."
						/>
						<label class="block w-full text-sm sm:max-w-sm">
							<span class="font-medium">Obra de referencia <span class="font-normal text-[color:var(--muted-foreground)]">(opcional)</span></span>
							<CheckDropdown
								class="mt-1"
								multiple={false}
								items={situatedWorkItems}
								selectedIds={situatedWork ? [situatedWork.obra_id] : []}
								placeholder="Ninguna obra destacada"
								search={true}
								portal={true}
								allowSingleClear={true}
								onChange={(ids) => (situatedWorkId = ids[0] ?? '')}
							/>
						</label>
					</div>

					<div class="grid gap-4 lg:grid-cols-2">
						<LaboratoryGroupFilter
							label="Grupo A"
							color={GROUP_A_COLOR}
							worksCount={groupAWorks.length}
							authorItems={sampleAuthorItems}
							selectedAuthors={groupAAuthors}
							dateFrom={groupADateFrom}
							dateTo={groupADateTo}
							onAuthorsChange={(ids) => (groupAAuthors = ids)}
							onDateFromChange={(value) => (groupADateFrom = value)}
							onDateToChange={(value) => (groupADateTo = value)}
							onReset={resetGroupA}
						/>
						<LaboratoryGroupFilter
							label="Grupo B"
							color={GROUP_B_COLOR}
							worksCount={groupBWorks.length}
							authorItems={sampleAuthorItems}
							selectedAuthors={groupBAuthors}
							dateFrom={groupBDateFrom}
							dateTo={groupBDateTo}
							onAuthorsChange={(ids) => (groupBAuthors = ids)}
							onDateFromChange={(value) => (groupBDateFrom = value)}
							onDateToChange={(value) => (groupBDateTo = value)}
							onReset={resetGroupB}
						/>
					</div>

					{#if sampleWorks.length === 0}
						<div class="border-y border-[color:var(--border)] py-10 text-center text-sm text-[color:var(--muted-foreground)]">
							Ninguna obra coincide con la muestra. Amplía o restablece los filtros generales.
						</div>
					{:else}
						{#if groupsAreEqual}
							<p class="flex items-start gap-2 border-l-2 border-[color:var(--warning)] bg-white px-4 py-3 text-sm leading-6">
								<CircleAlert class="mt-1 h-3.5 w-3.5 shrink-0 text-[color:var(--warning)]" aria-hidden="true" />
								Los dos grupos contienen las mismas obras. Añade algún filtro para producir una comparación distinta.
							</p>
						{:else if groupOverlapCount > 0}
							<p class="flex items-start gap-2 border-l-2 border-[color:var(--primary)] bg-white px-4 py-3 text-sm leading-6">
								<CircleAlert class="mt-1 h-3.5 w-3.5 shrink-0 text-[color:var(--primary)]" aria-hidden="true" />
								{groupOverlapCount} {groupOverlapCount === 1 ? 'obra pertenece' : 'obras pertenecen'} a ambos grupos. Se muestra en las dos distribuciones y los grupos no deben leerse como muestras independientes.
							</p>
						{/if}

						<div class="grid items-start gap-6 lg:grid-cols-[15rem_minmax(0,1fr)]">
							<LaboratoryMetricNav selectedId={selectedMetric.id} onSelect={selectMetric} />

							<section class="min-w-0 border border-[color:var(--border)] bg-white" aria-labelledby="comparison-metric-title">
								<LaboratoryMetricHeader metric={selectedMetric} titleId="comparison-metric-title" />
								<div class="px-5 py-4">
									<div class="grid gap-4 sm:grid-cols-2">
										<LaboratoryGroupSummary
											label="Grupo A"
											color={GROUP_A_COLOR}
											worksCount={groupAWorks.length}
											summary={groupASummary}
											metric={selectedMetric}
										/>
										<LaboratoryGroupSummary
											label="Grupo B"
											color={GROUP_B_COLOR}
											worksCount={groupBWorks.length}
											summary={groupBSummary}
											metric={selectedMetric}
										/>
									</div>

									<div class="mt-4 flex flex-col gap-1 border-y border-[color:var(--border)] py-3 sm:flex-row sm:items-baseline sm:justify-between">
										<div>
											<p class="text-xs text-[color:var(--muted-foreground)]">
												Diferencia de medianas{#if selectedMetric.unit === 'porcentaje'} (puntos porcentuales){/if}
											</p>
											<p class="font-semibold">Grupo A − Grupo B</p>
										</div>
										<p class="text-xl font-semibold tabular-nums">{formatLaboratoryDifference(groupMedianDifference, selectedMetric)}</p>
									</div>

									{#if groupAChartRows.length > 0 || groupBChartRows.length > 0}
										<LaboratoryGroupComparisonChart
											metric={selectedMetric}
											groupA={{ label: 'Grupo A', color: GROUP_A_COLOR, rows: groupAChartRows, summary: groupASummary }}
											groupB={{ label: 'Grupo B', color: GROUP_B_COLOR, rows: groupBChartRows, summary: groupBSummary }}
											focusedId={situatedWork?.obra_id ?? null}
											formatValue={(value) => formatLaboratoryValue(value, selectedMetric)}
										/>
									{:else}
										<p class="py-8 text-center text-sm text-[color:var(--muted-foreground)]">Ninguno de los dos grupos tiene datos para esta medida.</p>
									{/if}

									<p class="mt-4 border-t border-[color:var(--border)] pt-4 text-xs leading-5 text-[color:var(--muted-foreground)]">
										Comparación descriptiva de la muestra activa; no evalúa la significación estadística de la diferencia.
									</p>
								</div>
							</section>
						</div>
					{/if}
				</div>
			{/if}
		</div>
	{/if}
</section>

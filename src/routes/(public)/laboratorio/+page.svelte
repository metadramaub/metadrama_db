<script lang="ts">
	import EChart from '$lib/components/charts/EChart.svelte';
	import {
		distanciaComposicional,
		distanciaSecuencial,
		type PerfilFormas,
		type TramoSecuencial
	} from '$lib/laboratorio/distancias';
	import { colorForMetricKey } from '$lib/utils/metric-colors';
	import type { EChartsOption } from 'echarts';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	type Obra = PageData['obras'][number];
	type DistanceMode = 'composicional' | 'secuencial';
	type FormPointRow = {
		forma: string;
		totalVersos: number;
		values: Array<{
			versos: number;
			proportion: number;
		}>;
	};
	type EvolutionPoint = {
		bin: number;
		label: string;
		totalVersos: number;
		formVerses: Map<string, number>;
	};

	const obras = $derived<Obra[]>(data.obras);
	let selectedIds = $state<string[]>([]);
	let activeMode = $state<DistanceMode>('composicional');
	let focalId = $state('');
	let versosPorSimbolo = $state(25);
	let obraSearch = $state('');
	let authorSelection = $state('');
	let selectedEvolutionForms = $state<string[]>([]);
	let evolutionFormsInitialized = $state(false);

	const selectedObras = $derived.by((): Obra[] =>
		obras.filter((obra: Obra) => selectedIds.includes(obra.obra_id))
	);
	const filteredObras = $derived.by((): Obra[] => {
		const query = normalizeText(obraSearch);
		if (!query) return obras;
		return obras.filter((obra: Obra) => {
			const haystack = normalizeText(`${obra.titulo} ${obra.autoria_autores.join(' ')}`);
			return haystack.includes(query);
		});
	});
	const authorOptions = $derived.by(() =>
		[...new Set(obras.flatMap((obra: Obra) => obra.autoria_autores))]
			.map((name) => ({
				name,
				count: obras.filter((obra: Obra) => obra.autoria_autores.includes(name)).length
			}))
			.sort((a, b) => a.name.localeCompare(b.name, 'es'))
	);

	$effect(() => {
		if (selectedObras.length === 0) {
			focalId = '';
			return;
		}
		if (!selectedObras.some((obra) => obra.obra_id === focalId)) {
			focalId = selectedObras[0]?.obra_id ?? '';
		}
	});

	const matrices = $derived.by(() => buildMatrices(selectedObras, versosPorSimbolo));
	const activeMatrix = $derived(
		activeMode === 'composicional' ? matrices.composicional : matrices.secuencial
	);
	const nearestComposicional = $derived.by(() =>
		nearestFor(focalId, selectedObras, matrices.composicional)
	);
	const nearestSecuencial = $derived.by(() =>
		nearestFor(focalId, selectedObras, matrices.secuencial)
	);
	const formPointRows = $derived.by(() => buildFormPointRows(selectedObras));
	const formPointChartOption = $derived.by(() =>
		buildFormPointChartOption(selectedObras, formPointRows)
	);
	const formPointChartHeight = $derived(
		`${Math.max(18, Math.min(48, formPointRows.length * 2 + 8))}rem`
	);
	const evolutionFormOptions = $derived.by(() =>
		formPointRows.map((row: FormPointRow) => ({
			forma: row.forma,
			label: formLabel(row.forma),
			totalVersos: row.totalVersos
		}))
	);
	const evolutionPoints = $derived.by(() => buildEvolutionPoints(selectedObras));
	const evolutionChartOption = $derived.by(() =>
		buildEvolutionChartOption(evolutionPoints, selectedEvolutionForms)
	);

	$effect(() => {
		const validForms = new Set(evolutionFormOptions.map((option) => option.forma));
		const filtered = selectedEvolutionForms.filter((forma) => validForms.has(forma));
		if (filtered.length !== selectedEvolutionForms.length) {
			selectedEvolutionForms = filtered;
		}
		if (!evolutionFormsInitialized && evolutionFormOptions.length > 0) {
			selectedEvolutionForms = evolutionFormOptions.slice(0, 5).map((option) => option.forma);
			evolutionFormsInitialized = true;
		}
		if (evolutionFormOptions.length === 0) {
			evolutionFormsInitialized = false;
		}
	});

	function buildMatrices(rows: Obra[], step: number) {
		const composicional = rows.map(() => rows.map(() => 0));
		const secuencial = rows.map(() => rows.map(() => 0));

		for (let i = 0; i < rows.length; i += 1) {
			for (let j = i + 1; j < rows.length; j += 1) {
				const comp = distanciaComposicional(
					rows[i].perfil_formas as PerfilFormas,
					rows[j].perfil_formas as PerfilFormas
				);
				const seq = distanciaSecuencial(
					rows[i].tramos as TramoSecuencial[],
					rows[j].tramos as TramoSecuencial[],
					step
				);
				composicional[i][j] = comp;
				composicional[j][i] = comp;
				secuencial[i][j] = seq;
				secuencial[j][i] = seq;
			}
		}

		return { composicional, secuencial };
	}

	function nearestFor(focusId: string, rows: Obra[], matrix: number[][]) {
		const focusIndex = rows.findIndex((obra) => obra.obra_id === focusId);
		if (focusIndex < 0) return [];
		return rows
			.map((obra, index) => ({ obra, distance: matrix[focusIndex]?.[index] ?? 0, index }))
			.filter((item) => item.index !== focusIndex)
			.sort((a, b) => a.distance - b.distance || a.obra.titulo.localeCompare(b.obra.titulo, 'es'));
	}

	function buildFormPointRows(rows: Obra[]): FormPointRow[] {
		const totalsByForma = new Map<string, number>();
		const totalsByObra = rows.map((obra: Obra) => perfilTotal(obra.perfil_formas as PerfilFormas));

		for (const obra of rows) {
			for (const [forma, versos] of Object.entries(obra.perfil_formas as PerfilFormas)) {
				if (!Number.isFinite(versos) || versos <= 0) continue;
				totalsByForma.set(forma, (totalsByForma.get(forma) ?? 0) + versos);
			}
		}

		return [...totalsByForma.entries()]
			.sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0], 'es'))
			.map(([forma, totalVersos]) => ({
				forma,
				totalVersos,
				values: rows.map((obra: Obra, index) => {
					const versos = Number((obra.perfil_formas as PerfilFormas)[forma] ?? 0);
					const total = totalsByObra[index] ?? 0;
					return {
						versos,
						proportion: total > 0 && versos > 0 ? versos / total : 0
					};
				})
			}));
	}

	function buildFormPointChartOption(rows: Obra[], formRows: FormPointRow[]): EChartsOption {
		const xLabels = rows.map((obra: Obra) => shortTitle(obra.titulo));
		const yLabels = formRows.map((row: FormPointRow) => formLabel(row.forma)).reverse();
		const data = formRows.flatMap((row: FormPointRow, rowIndex) =>
			row.values
				.map((point, obraIndex) => ({
					value: [
						obraIndex,
						formRows.length - rowIndex - 1,
						point.versos,
						Number((point.proportion * 100).toFixed(2))
					],
					obra: rows[obraIndex]?.titulo ?? '',
					forma: formLabel(row.forma),
					color: formColor(row.forma),
					versos: point.versos,
					proportion: point.proportion
				}))
				.filter((point) => point.versos > 0)
		);

		return {
			aria: {
				enabled: true
			},
			grid: {
				top: 24,
				right: 28,
				bottom: rows.length > 5 ? 92 : 54,
				left: 128,
				containLabel: true
			},
			tooltip: {
				trigger: 'item',
				confine: true,
				formatter: (params: unknown) => {
					const dataPoint = (params as { data?: (typeof data)[number] }).data;
					if (!dataPoint) return '';
					return [
						`<strong>${dataPoint.forma}</strong>`,
						dataPoint.obra,
						`${dataPoint.versos} versos`,
						`${formatPercent(dataPoint.proportion)}`
					].join('<br />');
				}
			},
			xAxis: {
				type: 'category',
				data: xLabels,
				axisLabel: {
					interval: 0,
					rotate: rows.length > 5 ? 45 : 0,
					color: '#374151',
					fontSize: 11
				},
				axisTick: {
					alignWithLabel: true
				},
				splitLine: {
					show: true,
					lineStyle: {
						color: '#e5e7eb'
					}
				}
			},
			yAxis: {
				type: 'category',
				data: yLabels,
				axisLabel: {
					color: '#374151',
					fontSize: 11,
					width: 112,
					overflow: 'truncate'
				},
				splitLine: {
					show: true,
					lineStyle: {
						color: '#e5e7eb'
					}
				}
			},
			dataZoom:
				rows.length > 10
					? [
							{
								type: 'slider',
								xAxisIndex: 0,
								height: 18,
								bottom: 18,
								start: 0,
								end: Math.min(100, (10 / rows.length) * 100)
							}
						]
					: undefined,
			series: [
				{
					name: 'Peso de la forma',
					type: 'scatter',
					data,
					symbolSize: (value: unknown) => {
						const proportion = Array.isArray(value) ? Number(value[3]) / 100 : 0;
						return 8 + Math.sqrt(Math.max(0, Math.min(1, proportion))) * 34;
					},
					itemStyle: {
						color: (params: unknown) => {
							const dataPoint = (params as { data?: (typeof data)[number] }).data;
							return dataPoint?.color ?? '#8a8a8a';
						},
						opacity: 0.82
					},
					emphasis: {
						scale: true,
						itemStyle: {
							opacity: 1
						}
					}
				}
			]
		};
	}

	function buildEvolutionPoints(rows: Obra[]): EvolutionPoint[] {
		const byBin = new Map<number, { totalVersos: number; formVerses: Map<string, number> }>();

		for (const obra of rows) {
			const year = obra.fecha_inicio_trad ?? obra.fecha_fin_trad;
			if (year === null) continue;
			const bin = Math.floor(year / 5) * 5;
			const perfil = obra.perfil_formas as PerfilFormas;
			const total = perfilTotal(perfil);
			if (total <= 0) continue;

			const current = byBin.get(bin) ?? { totalVersos: 0, formVerses: new Map<string, number>() };
			current.totalVersos += total;
			for (const [forma, versos] of Object.entries(perfil)) {
				if (!Number.isFinite(versos) || versos <= 0) continue;
				current.formVerses.set(forma, (current.formVerses.get(forma) ?? 0) + versos);
			}
			byBin.set(bin, current);
		}

		return [...byBin.entries()]
			.sort((a, b) => a[0] - b[0])
			.map(([bin, value]) => ({
				bin,
				label: `${bin}-${bin + 4}`,
				totalVersos: value.totalVersos,
				formVerses: value.formVerses
			}));
	}

	function buildEvolutionChartOption(points: EvolutionPoint[], forms: string[]): EChartsOption {
		return {
			aria: {
				enabled: true
			},
			grid: {
				top: 28,
				right: 26,
				bottom: 42,
				left: 54,
				containLabel: true
			},
			tooltip: {
				trigger: 'axis',
				confine: true,
				valueFormatter: (value: unknown) => `${Number(value).toFixed(1)}%`
			},
			legend: {
				type: 'scroll',
				top: 0,
				textStyle: {
					fontSize: 11
				}
			},
			xAxis: {
				type: 'category',
				data: points.map((point) => point.label),
				axisLabel: {
					color: '#374151',
					fontSize: 11
				}
			},
			yAxis: {
				type: 'value',
				min: 0,
				max: 100,
				axisLabel: {
					formatter: '{value}%',
					color: '#374151',
					fontSize: 11
				},
				splitLine: {
					lineStyle: {
						color: '#e5e7eb'
					}
				}
			},
			series: forms.map((forma) => ({
				name: formLabel(forma),
				type: 'line',
				smooth: false,
				symbol: 'circle',
				symbolSize: 7,
				lineStyle: {
					color: formColor(forma),
					width: 2
				},
				itemStyle: {
					color: formColor(forma)
				},
				data: points.map((point) => {
					const versos = point.formVerses.get(forma) ?? 0;
					return point.totalVersos > 0 ? Number(((versos / point.totalVersos) * 100).toFixed(2)) : 0;
				})
			}))
		};
	}

	function toggleSelected(id: string) {
		selectedIds = selectedIds.includes(id)
			? selectedIds.filter((selectedId) => selectedId !== id)
			: [...selectedIds, id];
	}

	function selectAuthorProduction(authorName: string) {
		authorSelection = authorName;
		if (!authorName) return;
		selectedIds = obras
			.filter((obra: Obra) => obra.autoria_autores.includes(authorName))
			.map((obra: Obra) => obra.obra_id);
	}

	function clearSelection() {
		selectedIds = [];
		authorSelection = '';
	}

	function toggleEvolutionForm(forma: string) {
		selectedEvolutionForms = selectedEvolutionForms.includes(forma)
			? selectedEvolutionForms.filter((selectedForma) => selectedForma !== forma)
			: [...selectedEvolutionForms, forma];
	}

	function selectTopEvolutionForms(count: number) {
		selectedEvolutionForms = evolutionFormOptions.slice(0, count).map((option) => option.forma);
		evolutionFormsInitialized = true;
	}

	function clearEvolutionForms() {
		selectedEvolutionForms = [];
		evolutionFormsInitialized = true;
	}

	function normalizeText(value: string): string {
		return value
			.normalize('NFD')
			.replace(/\p{Diacritic}/gu, '')
			.toLocaleLowerCase('es');
	}

	function perfilTotal(perfil: PerfilFormas): number {
		return Object.values(perfil).reduce(
			(sum, versos) => sum + (Number.isFinite(versos) && versos > 0 ? versos : 0),
			0
		);
	}

	function shortTitle(title: string): string {
		return title.length > 18 ? `${title.slice(0, 17)}…` : title;
	}

	function formatDistance(value: number): string {
		return value.toFixed(3);
	}

	function formatPercent(value: number): string {
		return `${(value * 100).toFixed(value >= 0.1 ? 0 : 1)}%`;
	}

	function formLabel(slug: string): string {
		return slug.replace(/_/g, ' ');
	}

	function formColor(slug: string): string {
		return colorForMetricKey(slug);
	}

	function cellStyle(value: number): string {
		const clamped = Math.max(0, Math.min(1, value));
		const hue = 142 - clamped * 142;
		const lightness = 94 - clamped * 40;
		const color = clamped > 0.62 ? '#ffffff' : 'var(--gray-900)';
		return `background:hsl(${hue} 55% ${lightness}%);color:${color};`;
	}

	function datacionLabel(obra: Obra): string {
		if (obra.fecha_inicio_trad === null && obra.fecha_fin_trad === null) return 's. f.';
		if (obra.fecha_inicio_trad === obra.fecha_fin_trad || obra.fecha_fin_trad === null) {
			return String(obra.fecha_inicio_trad);
		}
		if (obra.fecha_inicio_trad === null) return String(obra.fecha_fin_trad);
		return `${obra.fecha_inicio_trad}-${obra.fecha_fin_trad}`;
	}
</script>

<section class="space-y-6">
	<header class="flex flex-wrap items-end justify-between gap-4">
		<div>
			<h1 class="font-display text-3xl text-[color:var(--gray-900)]">Laboratorio</h1>
		</div>
		<div class="text-sm text-[color:var(--muted-foreground)]">
			{selectedObras.length} de {obras.length} obras
		</div>
	</header>

	{#if obras.length === 0}
		<div class="card p-6 text-sm text-[color:var(--muted-foreground)]">
			No hay obras con perfil métrico disponible para el laboratorio.
		</div>
	{:else}
		<div class="grid gap-5 lg:grid-cols-[18rem_minmax(0,1fr)]">
			<aside class="card h-fit p-4">
				<div class="flex items-center justify-between gap-2">
					<h2 class="font-display text-lg">Selección</h2>
					<button
						type="button"
						class="text-xs font-semibold text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)]"
						onclick={clearSelection}
					>
						Limpiar
					</button>
				</div>
				<div class="mt-3 space-y-3">
					<label class="block text-xs font-semibold text-[color:var(--muted-foreground)]">
						<span>Buscar obra</span>
						<input
							type="search"
							bind:value={obraSearch}
							placeholder="Título o autor"
							class="mt-1 w-full border border-[color:var(--border)] bg-white px-2 py-1.5 text-sm font-normal text-[color:var(--foreground)]"
						/>
					</label>
					<label class="block text-xs font-semibold text-[color:var(--muted-foreground)]">
						<span>Producción de autor</span>
						<select
							value={authorSelection}
							class="mt-1 w-full border border-[color:var(--border)] bg-white px-2 py-1.5 text-sm font-normal text-[color:var(--foreground)]"
							onchange={(event) => selectAuthorProduction(event.currentTarget.value)}
						>
							<option value="">Seleccionar autor</option>
							{#each authorOptions as author (author.name)}
								<option value={author.name}>{author.name} ({author.count})</option>
							{/each}
						</select>
					</label>
				</div>
				<div class="mt-4 max-h-[32rem] space-y-1 overflow-y-auto pr-1">
					{#each filteredObras as obra (obra.obra_id)}
						<label class="flex cursor-pointer items-start gap-2 border border-transparent px-2 py-1.5 text-sm hover:border-[color:var(--border)]">
							<input
								type="checkbox"
								class="mt-1"
								checked={selectedIds.includes(obra.obra_id)}
								onchange={() => toggleSelected(obra.obra_id)}
							/>
							<span class="min-w-0">
								<span class="block truncate font-medium">{obra.titulo}</span>
								<span class="text-xs text-[color:var(--muted-foreground)]">
									{datacionLabel(obra)}
									{#if obra.autoria_autores.length > 0}
										· {obra.autoria_autores.join(', ')}
									{/if}
								</span>
							</span>
						</label>
					{/each}
					{#if filteredObras.length === 0}
						<p class="px-2 py-3 text-sm text-[color:var(--muted-foreground)]">
							No hay obras que coincidan con la búsqueda.
						</p>
					{/if}
				</div>
			</aside>

			<div class="space-y-6">
				<section class="space-y-4 border border-[color:var(--border)] bg-white/75 p-4">
					<div class="flex flex-wrap items-center justify-between gap-3 border-b border-[color:var(--border)] pb-3">
						<h2 class="font-display text-xl text-[color:var(--gray-900)]">Distancias</h2>
						<div class="flex flex-wrap items-center gap-3">
							<div class="inline-flex border border-[color:var(--border)] bg-white">
								<button
									type="button"
									class={`px-3 py-2 text-sm font-semibold ${activeMode === 'composicional' ? 'bg-[color:var(--gray-900)] text-white' : 'text-[color:var(--gray-800)]'}`}
									onclick={() => (activeMode = 'composicional')}
								>
									Composicional
								</button>
								<button
									type="button"
									class={`border-l border-[color:var(--border)] px-3 py-2 text-sm font-semibold ${activeMode === 'secuencial' ? 'bg-[color:var(--gray-900)] text-white' : 'text-[color:var(--gray-800)]'}`}
									onclick={() => (activeMode = 'secuencial')}
								>
									Secuencial
								</button>
							</div>

							<label class="flex flex-wrap items-center gap-2 text-sm text-[color:var(--muted-foreground)]">
								<span>Resolución secuencial</span>
								<span class="inline-flex items-center gap-2">
									<input
										type="number"
										min="1"
										step="1"
										bind:value={versosPorSimbolo}
										class="w-20 border border-[color:var(--border)] bg-white px-2 py-1 text-right text-[color:var(--foreground)]"
									/>
									<span>versos por bloque</span>
								</span>
							</label>
						</div>
					</div>

					{#if selectedObras.length < 2}
						<p class="mt-4 text-sm text-[color:var(--muted-foreground)]">
							Selecciona al menos dos obras para calcular distancias.
						</p>
					{:else}
						<div class="mt-4 overflow-x-auto">
							<table class="min-w-full border-collapse text-xs">
								<thead>
									<tr>
										<th class="sticky left-0 z-10 border border-[color:var(--border)] bg-white p-2 text-left font-semibold">
											Obra
										</th>
										{#each selectedObras as obra (obra.obra_id)}
											<th
												class="border border-[color:var(--border)] bg-[color:var(--muted)] p-2 text-left font-semibold"
												title={obra.titulo}
											>
												{shortTitle(obra.titulo)}
											</th>
										{/each}
									</tr>
								</thead>
								<tbody>
									{#each selectedObras as row, i (row.obra_id)}
										<tr>
											<th
												class="sticky left-0 z-10 max-w-48 border border-[color:var(--border)] bg-white p-2 text-left font-semibold"
												title={row.titulo}
											>
												{shortTitle(row.titulo)}
											</th>
											{#each selectedObras as col, j (col.obra_id)}
												{@const value = activeMatrix[i]?.[j] ?? 0}
												<td
													class="border border-white p-2 text-center font-mono"
													style={cellStyle(value)}
													title={`${row.titulo} / ${col.titulo}: ${formatDistance(value)}`}
												>
													{formatDistance(value)}
												</td>
											{/each}
										</tr>
									{/each}
								</tbody>
							</table>
						</div>

						<div class="mt-6 border-t border-[color:var(--border)] pt-4">
							<div class="flex flex-wrap items-center justify-between gap-3">
								<h3 class="font-display text-lg">Obras más cercanas</h3>
								<select
									bind:value={focalId}
									class="max-w-full border border-[color:var(--border)] bg-white px-2 py-1.5 text-sm"
									aria-label="Obra de referencia"
								>
									{#each selectedObras as obra (obra.obra_id)}
										<option value={obra.obra_id}>{obra.titulo}</option>
									{/each}
								</select>
							</div>

							<div class="mt-4 grid gap-4 md:grid-cols-2">
								<div>
									<h4 class="text-sm font-semibold">Por composición</h4>
									<ol class="mt-2 divide-y divide-[color:var(--border)] border border-[color:var(--border)]">
										{#each nearestComposicional as item (item.obra.obra_id)}
											<li class="flex items-center justify-between gap-3 px-3 py-2 text-sm">
												<a class="min-w-0 truncate hover:underline" href={`/obras/${item.obra.slug}`}>
													{item.obra.titulo}
												</a>
												<span class="font-mono text-xs text-[color:var(--muted-foreground)]">
													{formatDistance(item.distance)}
												</span>
											</li>
										{/each}
									</ol>
								</div>

								<div>
									<h4 class="text-sm font-semibold">Por secuencia</h4>
									<ol class="mt-2 divide-y divide-[color:var(--border)] border border-[color:var(--border)]">
										{#each nearestSecuencial as item (item.obra.obra_id)}
											<li class="flex items-center justify-between gap-3 px-3 py-2 text-sm">
												<a class="min-w-0 truncate hover:underline" href={`/obras/${item.obra.slug}`}>
													{item.obra.titulo}
												</a>
												<span class="font-mono text-xs text-[color:var(--muted-foreground)]">
													{formatDistance(item.distance)}
												</span>
											</li>
										{/each}
									</ol>
								</div>
							</div>
						</div>
					{/if}
				</section>

				<section class="space-y-6">
					<div>
						<h2 class="font-display text-xl text-[color:var(--gray-900)]">Gráficas</h2>
					</div>

					<div class="space-y-3 border border-[color:var(--border)] bg-white/75 p-4">
						<h3 class="text-base font-semibold">Formas por obra</h3>
						<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
							Cada punto muestra el peso de una forma métrica dentro de una obra seleccionada.
						</p>

						{#if selectedObras.length === 0}
							<p class="text-sm text-[color:var(--muted-foreground)]">
								Selecciona una o más obras para ver sus formas métricas.
							</p>
						{:else if formPointRows.length === 0}
							<p class="text-sm text-[color:var(--muted-foreground)]">
								Las obras seleccionadas no tienen perfil de formas disponible.
							</p>
						{:else}
							<div class="overflow-x-auto">
								<div class="min-w-[44rem]">
									<EChart
										option={formPointChartOption}
										height={formPointChartHeight}
										ariaLabel="Gráfico de puntos de formas métricas por obra"
									/>
								</div>
							</div>
						{/if}
					</div>

					<div class="space-y-3 border border-[color:var(--border)] bg-white/75 p-4">
						<h3 class="text-base font-semibold">Evolución por quinquenios</h3>
						<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
							Porcentaje de versos de cada forma, agrupando las obras seleccionadas en bloques de cinco años.
						</p>

						{#if selectedObras.length === 0}
							<p class="text-sm text-[color:var(--muted-foreground)]">
								Selecciona obras con datación para ver la evolución de sus formas métricas.
							</p>
						{:else if evolutionPoints.length === 0}
							<p class="text-sm text-[color:var(--muted-foreground)]">
								Las obras seleccionadas no tienen datación suficiente para agrupar por quinquenios.
							</p>
						{:else}
							<div class="grid gap-4 xl:grid-cols-[16rem_minmax(0,1fr)]">
								<div>
								<div class="flex items-center justify-between gap-2">
									<h3 class="text-sm font-semibold">Formas</h3>
									<button
										type="button"
										class="text-xs font-semibold text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)]"
										onclick={clearEvolutionForms}
									>
										Limpiar
									</button>
								</div>
								<div class="mt-2 flex flex-wrap gap-2">
									<button
										type="button"
										class="border border-[color:var(--border)] px-2 py-1 text-xs font-semibold"
										onclick={() => selectTopEvolutionForms(5)}
									>
										Top 5
									</button>
									<button
										type="button"
										class="border border-[color:var(--border)] px-2 py-1 text-xs font-semibold"
										onclick={() => selectTopEvolutionForms(10)}
									>
										Top 10
									</button>
								</div>
								<div class="mt-3 max-h-72 space-y-1 overflow-y-auto pr-1">
									{#each evolutionFormOptions as option (option.forma)}
										<label class="flex cursor-pointer items-center gap-2 px-2 py-1 text-sm hover:bg-[color:var(--muted)]">
											<input
												type="checkbox"
												checked={selectedEvolutionForms.includes(option.forma)}
												onchange={() => toggleEvolutionForm(option.forma)}
											/>
											<span
												class="inline-block h-3 w-3 shrink-0 rounded-sm"
												style={`background:${formColor(option.forma)};`}
											></span>
											<span class="min-w-0 flex-1 truncate capitalize">{option.label}</span>
											<span class="font-mono text-xs text-[color:var(--muted-foreground)]">
												{option.totalVersos}
											</span>
										</label>
									{/each}
								</div>
							</div>

								<div class="min-w-0">
									{#if selectedEvolutionForms.length === 0}
										<p class="text-sm text-[color:var(--muted-foreground)]">
											Selecciona una o más formas para dibujar el gráfico.
										</p>
									{:else}
										<EChart
											option={evolutionChartOption}
											height="24rem"
											ariaLabel="Gráfico de líneas de evolución de formas métricas por quinquenio"
										/>
									{/if}
								</div>
							</div>
						{/if}
					</div>
				</section>
			</div>
		</div>
	{/if}
</section>

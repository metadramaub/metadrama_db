<script lang="ts">
	import { onMount } from 'svelte';
	import InlineDualRange from '$lib/components/catalogo/mock/InlineDualRange.svelte';
	import ResultRowVariantC from '$lib/components/catalogo/mock/ResultRowVariantC.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import {
		MOCK_FILTER_OPTIONS,
		MOCK_INITIAL_FILTER_STATE,
		MOCK_METRIC_PALETTE,
		MOCK_SORT_OPTIONS,
		MOCK_WORKS,
		type MockFilterState,
		type MockOption
	} from '$lib/mock/catalogo-mock';

	const SIDEBAR_WIDTH_PX = 300;
	const SIDEBAR_GAP_PX = 24;

	function cloneFilters(source: MockFilterState): MockFilterState {
		return {
			...source,
			selectedAuthorIds: [...source.selectedAuthorIds],
			selectedGenreIds: [...source.selectedGenreIds],
			selectedFormIds: [...source.selectedFormIds],
			selectedMetroIds: [...source.selectedMetroIds],
			selectedVariationIds: [...source.selectedVariationIds],
			selectedJornadas: [...source.selectedJornadas]
		};
	}

	function buildClearedFilters(sortBy: MockFilterState['sortBy']): MockFilterState {
		return {
			...cloneFilters(MOCK_INITIAL_FILTER_STATE),
			textQuery: '',
			selectedAuthorIds: [],
			datationMin: MOCK_FILTER_OPTIONS.datationBounds.min,
			datationMax: MOCK_FILTER_OPTIONS.datationBounds.max,
			selectedGenreIds: [],
			selectedFormIds: [],
			selectedMetroIds: [],
			formType: null,
			withBrokenVerses: null,
			polymetryRatioMin: 0,
			selectedVariationIds: [],
			withSpaceChange: false,
			characterGender: null,
			graciosoPresence: null,
			supernaturalPresence: null,
			versesMin: MOCK_FILTER_OPTIONS.versesBounds.min,
			versesMax: MOCK_FILTER_OPTIONS.versesBounds.max,
			selectedJornadas: [],
			sortBy
		};
	}

	type ActiveFilterChipId =
		| 'textQuery'
		| 'selectedAuthorIds'
		| 'datation'
		| 'selectedGenreIds'
		| 'selectedFormIds'
		| 'polymetryRatioMin';

	interface ActiveFilterChip {
		id: ActiveFilterChipId;
		label: string;
	}

	let filters = $state<MockFilterState>(cloneFilters(MOCK_INITIAL_FILTER_STATE));
	let desktopShellEl = $state<HTMLDivElement | null>(null);

	let sidebarLeftPx = $state(0);
	let sidebarTopPx = $state(8);
	let sidebarHeightPx = $state(640);

	let openTitulo = $state(true);
	let openAutor = $state(true);
	let openDatacion = $state(true);
	let openGenero = $state(true);
	let openMetricas = $state(true);
	let openContexto = $state(true);
	let openExtension = $state(true);

	let selectedRowsC = $state<string[]>([]);
	let resultTextQuery = $state('');
	let legendOpen = $state(false);
	let legendButtonEl = $state<HTMLButtonElement | null>(null);
	let legendPopoverEl = $state<HTMLDivElement | null>(null);

	const previewRows = MOCK_WORKS;
	const normalizedResultTextQuery = $derived(resultTextQuery.trim().toLowerCase());
	const filteredRows = $derived.by(() => {
		if (!normalizedResultTextQuery) return previewRows;
		return previewRows.filter((work) => {
			const title = work.title.toLowerCase();
			const author = work.author.toLowerCase();
			return title.includes(normalizedResultTextQuery) || author.includes(normalizedResultTextQuery);
		});
	});

	const authorDropdownItems = MOCK_FILTER_OPTIONS.authors;
	const genreDropdownItems = MOCK_FILTER_OPTIONS.genres;
	const formDropdownItems = MOCK_FILTER_OPTIONS.forms;
	const metroDropdownItems = MOCK_FILTER_OPTIONS.metros;
	const variationDropdownItems = MOCK_FILTER_OPTIONS.variations;
	const jornadasDropdownItems = MOCK_FILTER_OPTIONS.jornadas;

	const formTypeDropdownItems: MockOption[] = [
		{ id: 'espanola', label: 'Solo españolas' },
		{ id: 'italiana', label: 'Solo italianas' }
	];
	const brokenVersesDropdownItems: MockOption[] = [
		{ id: 'si', label: 'Si' },
		{ id: 'no', label: 'No' }
	];
	const characterGenderDropdownItems: MockOption[] = [
		{ id: 'mixto', label: 'Mixto' },
		{ id: 'solo_masculino', label: 'Solo masculino' },
		{ id: 'solo_femenino', label: 'Solo femenino' }
	];
	const groupedPresenceDropdownItems: MockOption[] = [
		{ id: 'solo', label: 'Solo' },
		{ id: 'ausente', label: 'Ausente' },
		{ id: 'con_otros', label: 'Presente con otros (no solo)' }
	];

	const spanishPalette = MOCK_METRIC_PALETTE.filter((item) => item.origin === 'espanola');
	const italianPalette = MOCK_METRIC_PALETTE.filter((item) => item.origin === 'italiana');

	const activeSubfilters = $derived.by(() => {
		const chips: ActiveFilterChip[] = [];
		if (filters.textQuery.trim().length > 0) {
			chips.push({ id: 'textQuery', label: `Título: "${filters.textQuery.trim()}"` });
		}
		if (filters.selectedAuthorIds.length > 0) {
			const labels = filters.selectedAuthorIds
				.map((id) => optionLabel(authorDropdownItems, id))
				.slice(0, 2);
			chips.push({ id: 'selectedAuthorIds', label: `Autor: ${labels.join(', ')}` });
		}
		const isDatationActive =
			filters.datationMin !== MOCK_FILTER_OPTIONS.datationBounds.min ||
			filters.datationMax !== MOCK_FILTER_OPTIONS.datationBounds.max;
		if (isDatationActive) {
			chips.push({ id: 'datation', label: `Datación: ${filters.datationMin}-${filters.datationMax}` });
		}
		if (filters.selectedGenreIds.length > 0) {
			const labels = filters.selectedGenreIds
				.map((id) => optionLabel(genreDropdownItems, id))
				.slice(0, 2);
			chips.push({ id: 'selectedGenreIds', label: `Género: ${labels.join(', ')}` });
		}
		if (filters.selectedFormIds.length > 0) {
			const labels = filters.selectedFormIds
				.map((id) => optionLabel(formDropdownItems, id))
				.slice(0, 2);
			chips.push({ id: 'selectedFormIds', label: `Formas: ${labels.join(', ')}` });
		}
		if (filters.polymetryRatioMin > 0) {
			chips.push({ id: 'polymetryRatioMin', label: `Polimetría >= ${filters.polymetryRatioMin.toFixed(1)}` });
		}
		return chips;
	});

	function recalcSidebarGeometry() {
		if (!desktopShellEl) return;
		if (typeof window === 'undefined') return;

		const shellRect = desktopShellEl.getBoundingClientRect();
		if (!Number.isFinite(shellRect.height) || shellRect.height <= 0) return;

		const headerEl = document.querySelector('header');
		const headerBottom = headerEl instanceof HTMLElement ? headerEl.getBoundingClientRect().bottom : 0;

		const desiredTop = Math.max(8, Math.max(shellRect.top, headerBottom + 8));
		const desiredHeight = Math.max(240, window.innerHeight - desiredTop - 8);
		const maxBottom = shellRect.bottom - 8;
		const maxTopAllowed = maxBottom - desiredHeight;

		let finalTop = Math.min(desiredTop, maxTopAllowed);
		if (!Number.isFinite(finalTop)) {
			finalTop = desiredTop;
		}

		const nextTop = Math.round(finalTop);
		const nextHeight = Math.round(desiredHeight);
		const nextLeft = Math.round(shellRect.left);

		sidebarTopPx = nextTop;
		sidebarHeightPx = nextHeight;
		sidebarLeftPx = nextLeft;
	}

	function updateFilter<K extends keyof MockFilterState>(key: K, value: MockFilterState[K]) {
		filters = { ...filters, [key]: value } as MockFilterState;
	}

	function updateDatationRange(nextMin: number, nextMax: number) {
		filters = {
			...filters,
			datationMin: nextMin,
			datationMax: nextMax
		};
	}

	function updateVersesRange(nextMin: number, nextMax: number) {
		filters = {
			...filters,
			versesMin: nextMin,
			versesMax: nextMax
		};
	}

	function clearFilters() {
		filters = buildClearedFilters(filters.sortBy);
	}

	function removeFilterChip(chipId: ActiveFilterChipId) {
		if (chipId === 'textQuery') {
			updateFilter('textQuery', '');
			return;
		}
		if (chipId === 'selectedAuthorIds') {
			updateFilter('selectedAuthorIds', []);
			return;
		}
		if (chipId === 'datation') {
			filters = {
				...filters,
				datationMin: MOCK_FILTER_OPTIONS.datationBounds.min,
				datationMax: MOCK_FILTER_OPTIONS.datationBounds.max
			};
			return;
		}
		if (chipId === 'selectedGenreIds') {
			updateFilter('selectedGenreIds', []);
			return;
		}
		if (chipId === 'selectedFormIds') {
			updateFilter('selectedFormIds', []);
			return;
		}
		updateFilter('polymetryRatioMin', 0);
	}

	function toggleSelectedRows(values: string[], workId: string): string[] {
		if (values.includes(workId)) return values.filter((item) => item !== workId);
		return [...values, workId];
	}

	function optionLabel(options: MockOption[], id: string): string {
		return options.find((option) => option.id === id)?.label ?? id;
	}

	function toggleLegendPopover() {
		legendOpen = !legendOpen;
	}

	function closeLegendPopover() {
		legendOpen = false;
	}

	function handleLegendDocumentMouseDown(event: MouseEvent) {
		if (!legendOpen) return;
		const target = event.target;
		if (!(target instanceof Node)) return;
		if (legendButtonEl?.contains(target)) return;
		if (legendPopoverEl?.contains(target)) return;
		closeLegendPopover();
	}

	function handleLegendEscape(event: KeyboardEvent) {
		if (event.key !== 'Escape') return;
		if (!legendOpen) return;
		closeLegendPopover();
	}

	onMount(() => {
		recalcSidebarGeometry();

		const handleViewportChange = () => {
			recalcSidebarGeometry();
		};

		window.addEventListener('resize', handleViewportChange, { passive: true });
		window.addEventListener('scroll', handleViewportChange, { passive: true });
		document.addEventListener('mousedown', handleLegendDocumentMouseDown);
		document.addEventListener('keydown', handleLegendEscape);

		return () => {
			window.removeEventListener('resize', handleViewportChange);
			window.removeEventListener('scroll', handleViewportChange);
			document.removeEventListener('mousedown', handleLegendDocumentMouseDown);
			document.removeEventListener('keydown', handleLegendEscape);
		};
	});

	$effect(() => {
		desktopShellEl;
		if (typeof window === 'undefined') return;
		requestAnimationFrame(() => recalcSidebarGeometry());
	});
</script>

	<section class="space-y-6">
		<div class="card p-4 text-sm text-[color:var(--muted-foreground)] min-[1200px]:hidden">
			Este mockup está definido para escritorio. Abre la ruta con ancho de viewport amplio para evaluar las variantes.
		</div>

	<div bind:this={desktopShellEl} class="hidden min-[1200px]:block">
		<aside
			class="fixed z-40"
			style={`left:${sidebarLeftPx}px;top:${sidebarTopPx}px;width:${SIDEBAR_WIDTH_PX}px;height:${sidebarHeightPx}px;`}
		>
			<div class="card flex h-full flex-col overflow-visible">
				<div class="border-b border-[color:var(--border)] px-4 py-3">
					<h2 class="font-display text-xl text-[color:var(--gray-900)]">FILTROS</h2>
				</div>

				<div class="min-h-0 flex-1 overflow-x-visible overflow-y-auto px-4 py-4">
					<section>
						<button
							type="button"
							class="flex w-full items-center justify-between text-left text-xs font-semibold tracking-[0.08em]"
							onclick={() => (openTitulo = !openTitulo)}
						>
							<span>TÍTULO</span>
							<span>{openTitulo ? '-' : '+'}</span>
						</button>
						{#if openTitulo}
							<div class="mt-4">
								<label class="form-field">
									<span class="form-label">Búsqueda fuzzy por título</span>
									<input
										type="text"
										value={filters.textQuery}
										oninput={(event) =>
											updateFilter('textQuery', (event.currentTarget as HTMLInputElement).value)}
										class="w-full border border-[color:var(--border)] bg-white px-2 py-2 text-sm"
									/>
								</label>
							</div>
						{/if}
					</section>

					<section class="mt-5 border-t border-[color:var(--border)] pt-5">
						<button
							type="button"
							class="flex w-full items-center justify-between text-left text-xs font-semibold tracking-[0.08em]"
							onclick={() => (openAutor = !openAutor)}
						>
							<span>AUTOR</span>
							<span>{openAutor ? '-' : '+'}</span>
						</button>
						{#if openAutor}
							<div class="mt-4">
								<label class="form-field">
									<span class="form-label">Selector múltiple con autocomplete</span>
									<CheckDropdown
										multiple={true}
										search={authorDropdownItems.length > 8}
										placeholder="Seleccionar autores"
										items={authorDropdownItems}
										selectedIds={filters.selectedAuthorIds}
										portal={true}
										portalOffsetPx={6}
										portalViewportPaddingPx={8}
										onChange={(ids) => updateFilter('selectedAuthorIds', ids)}
									/>
								</label>
							</div>
						{/if}
					</section>

					<section class="mt-5 border-t border-[color:var(--border)] pt-5">
						<button
							type="button"
							class="flex w-full items-center justify-between text-left text-xs font-semibold tracking-[0.08em]"
							onclick={() => (openDatacion = !openDatacion)}
						>
							<span>DATACIÓN</span>
							<span>{openDatacion ? '-' : '+'}</span>
						</button>
						{#if openDatacion}
							<div class="mt-4">
								<InlineDualRange
									label="Rango de años"
									min={MOCK_FILTER_OPTIONS.datationBounds.min}
									max={MOCK_FILTER_OPTIONS.datationBounds.max}
									step={1}
									minGap={1}
									valueMin={filters.datationMin}
									valueMax={filters.datationMax}
									onChange={updateDatationRange}
								/>
							</div>
						{/if}
					</section>

					<section class="mt-5 border-t border-[color:var(--border)] pt-5">
						<button
							type="button"
							class="flex w-full items-center justify-between text-left text-xs font-semibold tracking-[0.08em]"
							onclick={() => (openGenero = !openGenero)}
						>
							<span>GÉNERO DRAMÁTICO</span>
							<span>{openGenero ? '-' : '+'}</span>
						</button>
						{#if openGenero}
							<div class="mt-4">
								<CheckDropdown
									multiple={true}
									search={genreDropdownItems.length > 8}
									placeholder="Seleccionar géneros"
									items={genreDropdownItems}
									selectedIds={filters.selectedGenreIds}
									portal={true}
									portalOffsetPx={6}
									portalViewportPaddingPx={8}
									onChange={(ids) => updateFilter('selectedGenreIds', ids)}
								/>
							</div>
						{/if}
					</section>

					<section class="mt-5 border-t border-[color:var(--border)] pt-5">
						<button
							type="button"
							class="flex w-full items-center justify-between text-left text-xs font-semibold tracking-[0.08em]"
							onclick={() => (openMetricas = !openMetricas)}
						>
							<span>CARACTERÍSTICAS MÉTRICAS</span>
							<span>{openMetricas ? '-' : '+'}</span>
						</button>
						{#if openMetricas}
							<div class="mt-4 space-y-4">
								<label class="form-field">
									<span class="form-label">Formas estróficas</span>
									<CheckDropdown
										multiple={true}
										search={formDropdownItems.length > 8}
										placeholder="Seleccionar formas"
										items={formDropdownItems}
										selectedIds={filters.selectedFormIds}
										portal={true}
										portalOffsetPx={6}
										portalViewportPaddingPx={8}
										onChange={(ids) => updateFilter('selectedFormIds', ids)}
									/>
								</label>

								<label class="form-field">
									<span class="form-label">Metros específicos</span>
									<CheckDropdown
										multiple={true}
										search={metroDropdownItems.length > 8}
										placeholder="Seleccionar metros"
										items={metroDropdownItems}
										selectedIds={filters.selectedMetroIds}
										portal={true}
										portalOffsetPx={6}
										portalViewportPaddingPx={8}
										onChange={(ids) => updateFilter('selectedMetroIds', ids)}
									/>
								</label>

								<label class="form-field">
									<span class="form-label">Tipo de forma</span>
									<CheckDropdown
										multiple={false}
										allowSingleClear={true}
										placeholder="Sin filtro (cualquiera)"
										items={formTypeDropdownItems}
										selectedIds={filters.formType ? [filters.formType] : []}
										portal={true}
										portalOffsetPx={6}
										portalViewportPaddingPx={8}
										onChange={(ids) => updateFilter('formType', (ids[0] ?? null) as MockFilterState['formType'])}
									/>
								</label>

								<label class="form-field">
									<span class="form-label">Con versos partidos</span>
									<CheckDropdown
										multiple={false}
										allowSingleClear={true}
										placeholder="Sin filtro (cualquiera)"
										items={brokenVersesDropdownItems}
										selectedIds={filters.withBrokenVerses ? [filters.withBrokenVerses] : []}
										portal={true}
										portalOffsetPx={6}
										portalViewportPaddingPx={8}
										onChange={(ids) =>
											updateFilter('withBrokenVerses', (ids[0] ?? null) as MockFilterState['withBrokenVerses'])}
									/>
								</label>

								<div>
									<p class="form-label">Polimetría (secuencias por 100 versos)</p>
									<div class="text-xs text-[color:var(--muted-foreground)]">
										Mínimo actual: {filters.polymetryRatioMin.toFixed(1)}
									</div>
									<input
										type="range"
										min={0}
										max={10}
										step={0.1}
										value={filters.polymetryRatioMin}
										oninput={(event) =>
											updateFilter('polymetryRatioMin', Number((event.currentTarget as HTMLInputElement).value))}
										class="mt-1 w-full"
									/>
								</div>

								<label class="form-field">
									<span class="form-label">Variaciones/irregularidades</span>
									<CheckDropdown
										multiple={true}
										search={variationDropdownItems.length > 8}
										placeholder="Seleccionar variaciones"
										items={variationDropdownItems}
										selectedIds={filters.selectedVariationIds}
										portal={true}
										portalOffsetPx={6}
										portalViewportPaddingPx={8}
										onChange={(ids) => updateFilter('selectedVariationIds', ids)}
									/>
								</label>
							</div>
						{/if}
					</section>

					<section class="mt-5 border-t border-[color:var(--border)] pt-5">
						<button
							type="button"
							class="flex w-full items-center justify-between text-left text-xs font-semibold tracking-[0.08em]"
							onclick={() => (openContexto = !openContexto)}
						>
							<span>CONTEXTO DRAMATICO</span>
							<span>{openContexto ? '-' : '+'}</span>
						</button>
						{#if openContexto}
							<div class="mt-4 space-y-4">
								<label class="flex items-center gap-2 text-xs">
									<input
										type="checkbox"
										checked={filters.withSpaceChange}
										onchange={(event) =>
											updateFilter('withSpaceChange', (event.currentTarget as HTMLInputElement).checked)}
										class="h-3.5 w-3.5 border border-[color:var(--border)]"
									/>
									<span>Con cambios de espacio</span>
								</label>

								<label class="form-field">
									<span class="form-label">Género de personajes</span>
									<CheckDropdown
										multiple={false}
										allowSingleClear={true}
										placeholder="Sin filtro (cualquiera)"
										items={characterGenderDropdownItems}
										selectedIds={filters.characterGender ? [filters.characterGender] : []}
										portal={true}
										portalOffsetPx={6}
										portalViewportPaddingPx={8}
										onChange={(ids) =>
											updateFilter('characterGender', (ids[0] ?? null) as MockFilterState['characterGender'])}
									/>
								</label>

								<label class="form-field">
									<span class="form-label">Personajes de donaire</span>
									<CheckDropdown
										multiple={false}
										allowSingleClear={true}
										placeholder="Sin filtro (cualquiera)"
										items={groupedPresenceDropdownItems}
										selectedIds={filters.graciosoPresence ? [filters.graciosoPresence] : []}
										portal={true}
										portalOffsetPx={6}
										portalViewportPaddingPx={8}
										onChange={(ids) =>
											updateFilter('graciosoPresence', (ids[0] ?? null) as MockFilterState['graciosoPresence'])}
									/>
								</label>

								<label class="form-field">
									<span class="form-label">Personajes sobrenaturales</span>
									<CheckDropdown
										multiple={false}
										allowSingleClear={true}
										placeholder="Sin filtro (cualquiera)"
										items={groupedPresenceDropdownItems}
										selectedIds={filters.supernaturalPresence ? [filters.supernaturalPresence] : []}
										portal={true}
										portalOffsetPx={6}
										portalViewportPaddingPx={8}
										onChange={(ids) =>
											updateFilter(
												'supernaturalPresence',
												(ids[0] ?? null) as MockFilterState['supernaturalPresence']
											)}
									/>
								</label>
							</div>
						{/if}
					</section>

					<section class="mt-5 border-t border-[color:var(--border)] pt-5">
						<button
							type="button"
							class="flex w-full items-center justify-between text-left text-xs font-semibold tracking-[0.08em]"
							onclick={() => (openExtension = !openExtension)}
						>
							<span>EXTENSIÓN</span>
							<span>{openExtension ? '-' : '+'}</span>
						</button>
						{#if openExtension}
							<div class="mt-4 space-y-4">
								<InlineDualRange
									label="Total de versos"
									min={MOCK_FILTER_OPTIONS.versesBounds.min}
									max={MOCK_FILTER_OPTIONS.versesBounds.max}
									step={10}
									minGap={10}
									valueMin={filters.versesMin}
									valueMax={filters.versesMax}
									suffix="vv."
									onChange={updateVersesRange}
								/>

								<label class="form-field">
									<span class="form-label">Número de jornadas</span>
									<CheckDropdown
										multiple={true}
										placeholder="Seleccionar jornadas"
										items={jornadasDropdownItems}
										selectedIds={filters.selectedJornadas}
										portal={true}
										portalOffsetPx={6}
										portalViewportPaddingPx={8}
										onChange={(ids) => updateFilter('selectedJornadas', ids)}
									/>
								</label>
							</div>
						{/if}
					</section>
				</div>
			</div>
		</aside>

			<div class="space-y-5" style={`margin-left:${SIDEBAR_WIDTH_PX + SIDEBAR_GAP_PX}px;`}>
				{#if previewRows.length > 0}
					<h1 class="font-display text-5xl text-[color:var(--gray-900)]">CATÁLOGO</h1>
					<p class="text-sm text-[color:var(--muted-foreground)]">{filteredRows.length} de {previewRows.length} obras</p>

					<section class="card p-4">
						<div class="space-y-3">
							<div class="flex items-center justify-between gap-3">
								<p class="text-xs font-semibold tracking-[0.08em] text-[color:var(--muted-foreground)]">
									FILTROS APLICADOS
							</p>
							<button
								type="button"
								class="border border-[color:var(--border)] bg-white px-2 py-1 text-xs font-semibold tracking-[0.04em]"
								onclick={clearFilters}
							>
								LIMPIAR FILTROS
							</button>
						</div>
						<div class="flex w-full flex-wrap gap-2">
							{#each activeSubfilters as chip (chip.id)}
								<span class="inline-flex items-center gap-2 border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">
									<span>{chip.label}</span>
									<button
										type="button"
										class="inline-flex h-4 w-4 items-center justify-center border border-[color:var(--border)] bg-white text-[10px] leading-none text-[color:var(--muted-foreground)]"
										aria-label={`Quitar filtro ${chip.label}`}
										onclick={() => removeFilterChip(chip.id)}
									>
										x
									</button>
								</span>
							{/each}
						</div>
					</div>
				</section>

				<section class="card p-4">
					<div class="grid grid-cols-[minmax(0,1fr)_20rem_auto] items-end gap-3">
						<label class="form-field">
							<span class="form-label">Filtrar resultados (título o autor)</span>
							<input
								type="text"
								value={resultTextQuery}
								oninput={(event) => (resultTextQuery = (event.currentTarget as HTMLInputElement).value)}
								class="w-full border border-[color:var(--border)] bg-white px-2 py-2 text-sm"
								placeholder="Buscar en resultados..."
							/>
						</label>

						<label class="form-field w-80">
							<span class="form-label">Ordenar por</span>
							<CheckDropdown
								multiple={false}
								allowSingleClear={false}
								search={false}
								placeholder="Seleccionar criterio"
								items={MOCK_SORT_OPTIONS}
								selectedIds={[filters.sortBy]}
								onChange={(ids) => updateFilter('sortBy', (ids[0] ?? filters.sortBy) as MockFilterState['sortBy'])}
							/>
						</label>

						<div class="relative">
							<button
								bind:this={legendButtonEl}
								type="button"
								class={`h-[38px] px-3 text-xs font-semibold tracking-[0.06em] ${legendOpen ? 'border border-[color:var(--primary)] bg-[color:var(--primary)] text-[color:var(--gray-50)]' : 'border border-[color:var(--border)] bg-white text-[color:var(--gray-900)]'}`}
								onclick={toggleLegendPopover}
							>
								LEYENDA
							</button>

							{#if legendOpen}
								<div
									bind:this={legendPopoverEl}
									class="absolute right-0 top-full z-[90] mt-2 w-[500px] border border-[color:var(--border)] bg-white p-4 shadow-lg"
								>
									<div class="grid gap-4 lg:grid-cols-2">
										<div>
											<p class="mb-2 text-xs font-semibold tracking-[0.08em] text-[color:var(--muted-foreground)]">
												FORMAS ESPAÑOLAS
											</p>
											<div class="grid gap-2 text-xs">
												{#each spanishPalette as item}
													<div class="flex items-center gap-2">
														<span class="h-3 w-8 border border-[color:var(--border)]" style={`background:${item.color};`}></span>
														<span>{item.shortLabel} - {item.label}</span>
													</div>
												{/each}
											</div>
										</div>
										<div>
											<p class="mb-2 text-xs font-semibold tracking-[0.08em] text-[color:var(--muted-foreground)]">
												FORMAS ITALIANAS
											</p>
											<div class="grid gap-2 text-xs">
												{#each italianPalette as item}
													<div class="flex items-center gap-2">
														<span class="h-3 w-8 border border-[color:var(--border)]" style={`background:${item.color};`}></span>
														<span>{item.shortLabel} - {item.label}</span>
													</div>
												{/each}
											</div>
										</div>
									</div>
									<div class="mt-4 flex flex-wrap items-center gap-4 text-xs text-[color:var(--muted-foreground)]">
										<span class="inline-flex items-center gap-2">
											<span class="h-4 w-[2px] bg-[color:var(--gray-900)]"></span>
											Corte de jornada
										</span>
										<span class="inline-flex items-center gap-2">
											<span class="h-4 border-l border-dashed border-[color:var(--gray-600)]"></span>
											Corte de cuadro
										</span>
										<span>Hover sobre cada segmento para ver forma, tipo, rango y variaciones.</span>
									</div>
								</div>
							{/if}
						</div>
					</div>
				</section>
			{:else}
				<section class="card p-4 text-sm text-[color:var(--muted-foreground)]">0 obras</section>
			{/if}

			<section class="space-y-3">
				{#if selectedRowsC.length > 0}
					<div class="flex justify-end">
						<button
							type="button"
							class="border border-[color:var(--primary)] bg-[color:var(--primary)] px-3 py-2 text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-50)]"
						>
							Analizar en el laboratorio ({selectedRowsC.length})
						</button>
					</div>
				{/if}
				<div class="grid gap-2">
					{#each filteredRows as work (work.id)}
						<ResultRowVariantC
							work={work}
							selected={selectedRowsC.includes(work.id)}
							onToggle={(workId) => (selectedRowsC = toggleSelectedRows(selectedRowsC, workId))}
						/>
					{/each}
				</div>
			</section>
		</div>
	</div>
</section>

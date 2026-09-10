<script lang="ts">
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import DualRange from '$lib/components/ui/DualRange.svelte';
	import {
		buildFormaSelectorItems,
		catalogSortOptions,
		isCatalogBasicFiltersVisible,
		isCatalogMetricFiltersVisible,
		isCatalogRangeFiltersVisible,
		splitFormaSelection,
		type CatalogFilterOptions,
		type CatalogFilters,
		type CatalogSortId
	} from '$lib/catalogo/catalog-filters';
	import type { SectionVisibilityMap } from '$lib/secciones-publicas';

	const props = $props<{
		filters: CatalogFilters;
		options: CatalogFilterOptions;
		visibility: SectionVisibilityMap;
		onChange: (next: CatalogFilters) => void;
		onClear: () => void;
		hasActiveFilters: boolean;
	}>();

	const showBasicFilters = $derived(isCatalogBasicFiltersVisible(props.visibility));
	const showRangeFilters = $derived(isCatalogRangeFiltersVisible(props.visibility));
	const canShowDatacion = $derived(showRangeFilters && props.options.bounds.datacion !== null);
	const canShowVersos = $derived(showRangeFilters && props.options.bounds.versos !== null);
	const showMetricFilters = $derived(isCatalogMetricFiltersVisible(props.visibility));
	const canShowDensidad = $derived(showMetricFilters && props.options.bounds.densidad !== null);

	// Selector único de forma estrófica: las formas y, anidados bajo cada una, los esquemas de
	// rima que se han anotado en ella. La selección combinada se divide en las dos facetas reales
	// —`formas_presentes` y `subtipos_presentes`— antes de filtrar.
	const formaSelectorItems = $derived(buildFormaSelectorItems(props.options));
	const formaSelectedIds = $derived([...props.filters.formas, ...props.filters.subtipos]);

	function update(patch: Partial<CatalogFilters>) {
		props.onChange({ ...props.filters, ...patch });
	}

	function updateFormaSelection(ids: string[]) {
		const split = splitFormaSelection(ids, props.options);
		update({ formas: split.formas, subtipos: split.subtipos });
	}
</script>

<div class="bg-white p-4">
	<!-- El título lo pone el cajón; aquí solo queda la salida de emergencia. -->
	<div class="flex items-center justify-end gap-3 pb-1">
		{#if props.hasActiveFilters}
			<button
				type="button"
				class="text-xs font-semibold tracking-[0.06em] text-[color:var(--gray-700)] underline-offset-4 hover:underline"
				onclick={props.onClear}
			>
				Limpiar
			</button>
		{/if}
	</div>

	<div class="space-y-5 pt-4">
		{#if showBasicFilters}
			<section class="space-y-4">
				<!--
					**Buscar no está aquí.** Es el filtro rápido y vive fuera del cajón, junto a los
					resultados: es lo único que se usa sin abrir nada.
				-->
				<label class="form-field">
					<span class="form-label">Ordenar por</span>
					<CheckDropdown
						multiple={false}
						placeholder="Seleccionar criterio"
						items={catalogSortOptions(props.visibility)}
						selectedIds={[props.filters.sortBy]}
						allowSingleClear={false}
						onChange={(ids) => update({ sortBy: (ids[0] ?? props.filters.sortBy) as CatalogSortId })}
					/>
				</label>
			</section>

			{#if props.options.autores.length > 0}
				<section class="border-t border-[color:var(--border)] pt-5">
					<label class="form-field">
						<span class="form-label">Autoría</span>
						<CheckDropdown
							multiple={true}
							search={props.options.autores.length > 8}
							placeholder="Seleccionar autores"
							items={props.options.autores}
							selectedIds={props.filters.autores}
							portal={true}
							onChange={(ids) => update({ autores: ids })}
						/>
					</label>
				</section>
			{/if}

			{#if props.options.generos.length > 0}
				<section class="border-t border-[color:var(--border)] pt-5">
					<label class="form-field">
						<span class="form-label">Género dramático</span>
						<CheckDropdown
							multiple={true}
							search={props.options.generos.length > 8}
							placeholder="Seleccionar géneros"
							items={props.options.generos}
							selectedIds={props.filters.generos}
							portal={true}
							onChange={(ids) => update({ generos: ids })}
						/>
					</label>
				</section>
			{/if}
		{/if}

		{#if canShowDatacion || canShowVersos}
			<section class="space-y-5 border-t border-[color:var(--border)] pt-5">
				{#if canShowDatacion && props.options.bounds.datacion}
					<DualRange
						label="Datación"
						min={props.options.bounds.datacion.min}
						max={props.options.bounds.datacion.max}
						step={1}
						minGap={0}
						valueMin={props.filters.datacionMin ?? props.options.bounds.datacion.min}
						valueMax={props.filters.datacionMax ?? props.options.bounds.datacion.max}
						onChange={(min, max) => update({ datacionMin: min, datacionMax: max })}
					/>
				{/if}

				{#if canShowVersos && props.options.bounds.versos}
					<DualRange
						label="Total de versos"
						min={props.options.bounds.versos.min}
						max={props.options.bounds.versos.max}
						step={10}
						minGap={0}
						valueMin={props.filters.versosMin ?? props.options.bounds.versos.min}
						valueMax={props.filters.versosMax ?? props.options.bounds.versos.max}
						suffix="vv."
						onChange={(min, max) => update({ versosMin: min, versosMax: max })}
					/>
				{/if}
			</section>
		{/if}

		{#if showMetricFilters}
			<section class="space-y-4 border-t border-[color:var(--border)] pt-5">
				<h3 class="form-label">Métrica</h3>

				{#if formaSelectorItems.length > 0}
					<label class="form-field">
						<span class="form-label">Forma estrófica</span>
						<CheckDropdown
							multiple={true}
							hierarchical={true}
							collapsibleHierarchy={true}
							search={formaSelectorItems.length > 8}
							placeholder="Seleccionar formas"
							items={formaSelectorItems}
							selectedIds={formaSelectedIds}
							portal={true}
							onChange={updateFormaSelection}
						/>
					</label>
				{/if}

				{#if props.options.metros.length > 0}
					<label class="form-field">
						<span class="form-label">Metros</span>
						<CheckDropdown
							multiple={true}
							search={props.options.metros.length > 8}
							placeholder="Seleccionar metros"
							items={props.options.metros}
							selectedIds={props.filters.metros}
							portal={true}
							onChange={(ids) => update({ metros: ids })}
						/>
					</label>
				{/if}

				{#if props.options.tiposForma.length > 0}
					<label class="form-field">
						<span class="form-label">Tipo de forma</span>
						<CheckDropdown
							multiple={true}
							placeholder="Española / italiana"
							items={props.options.tiposForma}
							selectedIds={props.filters.tiposForma}
							portal={true}
							onChange={(ids) => update({ tiposForma: ids })}
						/>
					</label>
				{/if}

				{#if props.options.variaciones.length > 0}
					<label class="form-field">
						<span class="form-label">Caracterizaciones</span>
						<CheckDropdown
							multiple={true}
							search={props.options.variaciones.length > 8}
							placeholder="Seleccionar caracterizaciones"
							items={props.options.variaciones}
							selectedIds={props.filters.variaciones}
							portal={true}
							onChange={(ids) => update({ variaciones: ids })}
						/>
					</label>
				{/if}

				<!--
					**Rasgos, todavía sin faceta.** Hay seis dimensiones anotadas —vocales de la
					asonancia, final acentual, densidad de rima, organización en pareados, dístico
					final y encadenamiento interior— y ninguna columna que las lleve a `obras_resumen`.
					Crearla ahora sería deuda: cuando el buscador filtre sobre el JSON ya cargado, el
					rasgo se filtra sin columna ninguna. Se deja a la vista y desactivado —es C26—
					para que se entienda que el dato existe y aún no se puede cruzar.
				-->
				<div class="form-field opacity-60">
					<span class="form-label">Rasgos</span>
					<button
						type="button"
						disabled
						class="w-full cursor-not-allowed border border-dashed border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-left text-sm text-[color:var(--muted-foreground)]"
						title="Asonancia, final acentual, densidad de rima… Anotado, todavía sin filtro."
					>
						Asonancia, final acentual… — en preparación
					</button>
				</div>

				{#if canShowDensidad && props.options.bounds.densidad}
					<DualRange
						label="Densidad de transiciones"
						min={props.options.bounds.densidad.min}
						max={props.options.bounds.densidad.max}
						step={1}
						minGap={0}
						valueMin={props.filters.densidadMin ?? props.options.bounds.densidad.min}
						valueMax={props.filters.densidadMax ?? props.options.bounds.densidad.max}
						onChange={(min, max) => update({ densidadMin: min, densidadMax: max })}
					/>
				{/if}
			</section>
		{/if}
	</div>
</div>

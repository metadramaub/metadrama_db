<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import type { VocabularyFieldConfig } from '$lib/config/vocabulary-fields';
	import type { VocabularyItem } from './useVocabularyTree';

	type ArteMetricoValue = 'arte_menor' | 'arte_mayor' | 'mixto' | null;
	type MetroOption = {
		termino_id: string;
		termino: string;
		numero_silabas: number | null;
	};
	type DropdownItem = {
		id: string;
		label: string;
	};

	type TermForm = {
		termino: string;
		etiqueta: string;
		termino_padre_id: string | null;
		nivel: number | null;
		activo: boolean;
		definicion: string;
		ejemplo: string;
		bibliografia: string;
		equivalenciasText: string;
		patron_especifico: string;
		tipo_forma: 'forma_espanola' | 'forma_italiana' | null;
		tipo_rima_id: string | null;
		naturaleza_estrofica_id: string | null;
		tamanio_unidad_estrofica: number | null;
		arte_metrico: ArteMetricoValue;
		numero_silabas: number | null;
		metro_ids: string[];
	};

	const props = $props<{
		selectedItem: VocabularyItem | null;
		pathLabel: string;
		readOnly?: boolean;
		termForm: TermForm;
		parentOptions: Array<{ id: string; label: string; parentId?: string | null }>;
		metroOptions: MetroOption[];
		tipoRimaOptions?: DropdownItem[];
		tipoRimaDisabledIds?: string[];
		naturalezaEstroficaOptions?: DropdownItem[];
		naturalezaEstroficaDisabledIds?: string[];
		fieldConfig: VocabularyFieldConfig;
		termDirty?: boolean;
		savingTerm?: boolean;
		deletingTerm?: boolean;
		onTermFormChange?: (patch: Partial<TermForm>) => void;
		onSaveTerm?: () => void;
		onOpenDeleteModal?: () => void;
		onClose?: () => void;
	}>();

	const readOnly = $derived(Boolean(props.readOnly));
	const metroDropdownItems = $derived(
		props.metroOptions.map((metro: MetroOption) => ({
			id: metro.termino_id,
			label:
				typeof metro.numero_silabas === 'number'
					? `${metro.termino} (${metro.numero_silabas})`
					: metro.termino
		}))
	);
	const metroById = $derived.by(
		() => new Map<string, MetroOption>(props.metroOptions.map((metro: MetroOption) => [metro.termino_id, metro]))
	);
	const parentDropdownItems = $derived(
		props.parentOptions.map((option: { id: string; label: string; parentId?: string | null }) => ({
			id: option.id,
			label: option.label,
			parentId: option.parentId ?? null
		}))
	);
	const tipoFormaItems = [
		{ id: 'forma_espanola', label: 'Forma española' },
		{ id: 'forma_italiana', label: 'Forma italiana' }
	];
	const tipoRimaItems = $derived(
		props.tipoRimaOptions && props.tipoRimaOptions.length > 0 ? props.tipoRimaOptions : []
	);
	const tipoRimaDisabledIds = $derived(props.tipoRimaDisabledIds ?? []);
	const naturalezaEstroficaItems = $derived(
		props.naturalezaEstroficaOptions && props.naturalezaEstroficaOptions.length > 0
			? props.naturalezaEstroficaOptions
			: []
	);
	const naturalezaEstroficaDisabledIds = $derived(props.naturalezaEstroficaDisabledIds ?? []);
	const arteMetricoLabels: Record<NonNullable<ArteMetricoValue>, string> = {
		arte_menor: 'Arte menor',
		arte_mayor: 'Arte mayor',
		mixto: 'Mixto'
	};
	const ARTE_MENOR_MAX_SYLLABLES = 8;
	const ARTE_MAYOR_MIN_SYLLABLES = 9;
	const arteMetricoPreview = $derived(
		props.fieldConfig.showMetros ? computeArteMetricoFromMetroIds(props.termForm.metro_ids) : props.termForm.arte_metrico
	);

	function updateTerm(patch: Partial<TermForm>) {
		props.onTermFormChange?.(patch);
	}

	function parseNullablePositiveInteger(value: string): number | null {
		const trimmed = value.trim();
		if (!trimmed) return null;
		const parsed = Number(trimmed);
		return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
	}

	function labelArteMetrico(value: ArteMetricoValue): string {
		return value ? arteMetricoLabels[value] : 'Sin calcular';
	}

	function computeArteMetricoFromMetroIds(ids: string[]): ArteMetricoValue {
		const normalizedIds = [...new Set(ids)].sort((a, b) => a.localeCompare(b));
		if (normalizedIds.length === 0) return null;

		const syllables = normalizedIds.map((id) => metroById.get(id)?.numero_silabas ?? null);
		if (syllables.some((value) => typeof value !== 'number')) return null;

		const hasMinor = syllables.some(
			(value) => typeof value === 'number' && value <= ARTE_MENOR_MAX_SYLLABLES
		);
		const hasMajor = syllables.some(
			(value) => typeof value === 'number' && value >= ARTE_MAYOR_MIN_SYLLABLES
		);

		if (hasMinor && hasMajor) return 'mixto';
		if (hasMinor) return 'arte_menor';
		if (hasMajor) return 'arte_mayor';
		return null;
	}

	function closePanel() {
		props.onClose?.();
	}
</script>

<section class="space-y-4">
	<div class="card p-4">
		<div class="mb-3 flex items-center justify-between gap-3">
			<h3 class="text-lg font-semibold">Detalle del término</h3>
			{#if props.selectedItem}
				<span class="text-xs text-[color:var(--muted-foreground)]">ID: {props.selectedItem.termino_id}</span>
			{/if}
		</div>

		{#if !props.selectedItem}
			<p class="text-sm text-[color:var(--muted-foreground)]">Selecciona un término en el Árbol para ver su detalle.</p>
		{:else}
			<p class="mb-3 text-xs text-[color:var(--muted-foreground)]">Término: {props.pathLabel || '-'}</p>
			<div class="grid gap-3">
				{#if props.fieldConfig.showParent}
					<label class="form-field">
						<span class="form-label">Término padre</span>
						<CheckDropdown
							multiple={false}
							hierarchical={true}
							showPathInTrigger={true}
							allowSingleClear={true}
							search={parentDropdownItems.length > 8}
							placeholder="Sin padre (raíz)"
							items={parentDropdownItems}
							disabled={readOnly}
							selectedIds={props.termForm.termino_padre_id ? [props.termForm.termino_padre_id] : []}
							onChange={(ids) => updateTerm({ termino_padre_id: ids[0] ?? null })}
						/>
					</label>
				{/if}

				<label class="form-field">
					<span class="form-label">Término</span>
					<input
						type="text"
						value={props.termForm.termino}
						disabled={readOnly}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						oninput={(event) => updateTerm({ termino: event.currentTarget.value })}
					/>
				</label>

				<label class="form-field">
					<span class="form-label">Etiqueta (nombre legible)</span>
					<input
						type="text"
						value={props.termForm.etiqueta}
						disabled={readOnly}
						placeholder={props.termForm.termino || 'Se usa el término si se deja vacío'}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						oninput={(event) => updateTerm({ etiqueta: event.currentTarget.value })}
					/>
					<span class="mt-1 text-xs text-[color:var(--muted-foreground)]">
						Nombre que se muestra en la web pública y los selectores. Si se deja vacío se usa el término.
					</span>
				</label>

				{#if props.fieldConfig.showEquivalences}
					<label class="form-field">
						<span class="form-label">Equivalencias (una por línea)</span>
						<textarea
							rows={3}
							value={props.termForm.equivalenciasText}
							disabled={readOnly}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							oninput={(event) => updateTerm({ equivalenciasText: event.currentTarget.value })}
						></textarea>
					</label>
				{/if}

				{#if props.fieldConfig.showPattern}
					<label class="form-field">
						<span class="form-label">Patrón específico</span>
						<input
							type="text"
							value={props.termForm.patron_especifico}
							disabled={readOnly}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							oninput={(event) => updateTerm({ patron_especifico: event.currentTarget.value })}
						/>
					</label>
				{/if}

				{#if props.fieldConfig.showTipoForma}
					<label class="form-field">
						<span class="form-label">Tipo de forma</span>
						<CheckDropdown
							multiple={false}
							allowSingleClear={true}
							search={false}
							placeholder="Sin especificar"
							items={tipoFormaItems}
							disabled={readOnly}
							selectedIds={props.termForm.tipo_forma ? [props.termForm.tipo_forma] : []}
							onChange={(ids) =>
								updateTerm({
									tipo_forma: (ids[0] ?? null) as
										| 'forma_espanola'
										| 'forma_italiana'
										| null
								})}
						/>
					</label>
				{/if}

				{#if props.fieldConfig.showNumeroSilabas}
					<label class="form-field">
						<span class="form-label">Número de sílabas</span>
						<input
							type="number"
							min="1"
							step="1"
							value={props.termForm.numero_silabas ?? ''}
							disabled={readOnly}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							oninput={(event) =>
								updateTerm({ numero_silabas: parseNullablePositiveInteger(event.currentTarget.value) })}
						/>
					</label>
				{/if}

				{#if props.fieldConfig.showTipoRima}
					<label class="form-field">
						<span class="form-label">Tipo de rima</span>
						<CheckDropdown
							multiple={false}
							allowSingleClear={true}
							search={false}
							placeholder="Sin especificar"
							items={tipoRimaItems}
							disabledIds={tipoRimaDisabledIds}
							disabled={readOnly}
							selectedIds={props.termForm.tipo_rima_id ? [props.termForm.tipo_rima_id] : []}
							onChange={(ids) => updateTerm({ tipo_rima_id: ids[0] ?? null })}
						/>
					</label>
				{/if}

				{#if props.fieldConfig.showNaturalezaEstrofica}
					<label class="form-field">
						<span class="form-label">Naturaleza estrófica</span>
						<CheckDropdown
							multiple={false}
							allowSingleClear={true}
							search={false}
							placeholder="Sin especificar"
							items={naturalezaEstroficaItems}
							disabledIds={naturalezaEstroficaDisabledIds}
							disabled={readOnly}
							selectedIds={props.termForm.naturaleza_estrofica_id ? [props.termForm.naturaleza_estrofica_id] : []}
							onChange={(ids) => updateTerm({ naturaleza_estrofica_id: ids[0] ?? null })}
						/>
					</label>
				{/if}

				{#if props.fieldConfig.showTamanioUnidadEstrofica}
					<label class="form-field">
						<span class="form-label">Tamaño de la unidad estrófica</span>
						<input
							type="number"
							min="1"
							step="1"
							value={props.termForm.tamanio_unidad_estrofica ?? ''}
							disabled={readOnly}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							oninput={(event) =>
								updateTerm({
									tamanio_unidad_estrofica: parseNullablePositiveInteger(event.currentTarget.value)
								})}
						/>
					</label>
				{/if}

				{#if props.fieldConfig.showArteMetrico}
					<div class="form-field">
						<span class="form-label">Arte métrico</span>
						<div class="border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2 text-sm">
							{labelArteMetrico(arteMetricoPreview)}
						</div>
					</div>
				{/if}

				{#if props.fieldConfig.showMetros}
					<div class="form-field">
						<span class="form-label">Metro(s) predominante(s)</span>
						<CheckDropdown
							items={metroDropdownItems}
							selectedIds={props.termForm.metro_ids}
							search={true}
							disabled={readOnly}
							placeholder="Seleccionar metros"
							onChange={(ids) => updateTerm({ metro_ids: ids })}
						/>
					</div>
				{/if}

				{#if props.fieldConfig.showDefinition}
					<label class="form-field">
						<span class="form-label">Definición</span>
						<MarkdownEditorLite
							rows={4}
							class="mt-1"
							minHeightClass="min-h-28"
							value={props.termForm.definicion}
							disabled={readOnly}
							onChange={(nextValue) => updateTerm({ definicion: nextValue })}
						/>
					</label>
				{/if}

				{#if props.fieldConfig.showExample}
					<label class="form-field">
						<span class="form-label">Ejemplo</span>
						<MarkdownEditorLite
							rows={3}
							class="mt-1"
							minHeightClass="min-h-24"
							value={props.termForm.ejemplo}
							disabled={readOnly}
							onChange={(nextValue) => updateTerm({ ejemplo: nextValue })}
						/>
					</label>
				{/if}

				{#if props.fieldConfig.showBibliography}
					<label class="form-field">
						<span class="form-label">Bibliografía</span>
						<MarkdownEditorLite
							rows={3}
							class="mt-1"
							minHeightClass="min-h-24"
							value={props.termForm.bibliografia}
							disabled={readOnly}
							onChange={(nextValue) => updateTerm({ bibliografia: nextValue })}
						/>
					</label>
				{/if}

				{#if props.fieldConfig.showActive}
					<label class="form-inline-toggle">
						<input
							type="checkbox"
							checked={props.termForm.activo}
							disabled={readOnly}
							onchange={(event) => updateTerm({ activo: event.currentTarget.checked })}
						/>
						Activo
					</label>
				{/if}

				{#if !readOnly}
					<div>
						<Button
							variant="danger"
							onclick={props.onOpenDeleteModal}
							disabled={Boolean(props.deletingTerm)}
						>
							{props.deletingTerm ? 'Eliminando...' : 'Eliminar término'}
						</Button>
					</div>
				{/if}
			</div>

			<div class="mt-4 flex justify-end gap-2">
				<Button variant="secondary" onclick={closePanel}>Cerrar</Button>
				{#if !readOnly}
					<Button variant="success" onclick={props.onSaveTerm} disabled={!props.termDirty || props.savingTerm}>
						{props.savingTerm ? 'Guardando...' : 'Guardar'}
					</Button>
				{/if}
			</div>
		{/if}
	</div>
</section>


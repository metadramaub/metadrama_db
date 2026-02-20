<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import type { VocabularyFieldConfig } from '$lib/config/vocabulary-fields';
	import type { VocabularyItem } from './useVocabularyTree';

	type TermForm = {
		termino: string;
		termino_padre_id: string | null;
		nivel: number | null;
		activo: boolean;
		definicion: string;
		ejemplo: string;
		bibliografia: string;
		equivalenciasText: string;
		patron_especifico: string;
		tipo_forma: 'forma_espanola' | 'forma_italiana' | null;
		metro_ids: string[];
	};

	const props = $props<{
		selectedItem: VocabularyItem | null;
		pathLabel: string;
		readOnly?: boolean;
		termForm: TermForm;
		parentOptions: Array<{ id: string; label: string }>;
		metroOptions: Array<{ termino_id: string; termino: string }>;
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
		props.metroOptions.map((metro: { termino_id: string; termino: string }) => ({
			id: metro.termino_id,
			label: metro.termino
		}))
	);

	function updateTerm(patch: Partial<TermForm>) {
		props.onTermFormChange?.(patch);
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
			<p class="text-sm text-[color:var(--muted-foreground)]">Selecciona un término en el árbol para ver su detalle.</p>
		{:else}
			<p class="mb-3 text-xs text-[color:var(--muted-foreground)]">Término: {props.pathLabel || '-'}</p>
			<div class="grid gap-3">
				{#if props.fieldConfig.showParent}
					<label class="text-sm">
						<span class="mb-1 block">Término padre</span>
						<select
							value={props.termForm.termino_padre_id ?? ''}
							disabled={readOnly}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							onchange={(event) => updateTerm({ termino_padre_id: event.currentTarget.value || null })}
						>
							<option value="">Sin padre (raíz)</option>
							{#each props.parentOptions as option}
								<option value={option.id}>{option.label}</option>
							{/each}
						</select>
					</label>
				{/if}

				<label class="text-sm">
					<span class="mb-1 block">Término</span>
					<input
						type="text"
						value={props.termForm.termino}
						disabled={readOnly}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						oninput={(event) => updateTerm({ termino: event.currentTarget.value })}
					/>
				</label>

				{#if props.fieldConfig.showEquivalences}
					<label class="text-sm">
						<span class="mb-1 block">Equivalencias (una por línea)</span>
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
					<label class="text-sm">
						<span class="mb-1 block">Patrón específico</span>
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
					<label class="text-sm">
						<span class="mb-1 block">Tipo de forma</span>
						<select
							value={props.termForm.tipo_forma ?? ''}
							disabled={readOnly}
							class="w-full border border-[color:var(--border)] px-3 py-2"
							onchange={(event) =>
								updateTerm({
									tipo_forma: (event.currentTarget.value || null) as
										| 'forma_espanola'
										| 'forma_italiana'
										| null
								})}
						>
							<option value="">Sin especificar</option>
							<option value="forma_espanola">Forma española</option>
							<option value="forma_italiana">Forma italiana</option>
						</select>
					</label>
				{/if}

				{#if props.fieldConfig.showMetros}
					<div class="text-sm">
						<span class="mb-1 block">Metros asociados</span>
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
					<label class="text-sm">
						<span class="mb-1 block">Definición</span>
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
					<label class="text-sm">
						<span class="mb-1 block">Ejemplo</span>
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
					<label class="text-sm">
						<span class="mb-1 block">Bibliografía</span>
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
					<label class="flex items-center gap-2 text-sm">
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

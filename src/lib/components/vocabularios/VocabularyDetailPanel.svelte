<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';
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
	};

	const props = $props<{
		selectedItem: VocabularyItem | null;
		pathLabel: string;
		readOnly?: boolean;
		termForm: TermForm;
		parentOptions: Array<{ id: string; label: string }>;
		termDirty?: boolean;
		savingTerm?: boolean;
		onTermFormChange?: (patch: Partial<TermForm>) => void;
		onSaveTerm?: () => void;
	}>();

	const readOnly = $derived(Boolean(props.readOnly));

	function updateTerm(patch: Partial<TermForm>) {
		props.onTermFormChange?.(patch);
	}
</script>

<section class="space-y-4">
	<div class="card p-4">
		<div class="mb-3 flex items-center justify-between gap-3">
			<h3 class="text-lg font-semibold">Detalle del termino</h3>
			{#if props.selectedItem}
				<span class="text-xs text-[color:var(--muted-foreground)]">ID: {props.selectedItem.termino_id}</span>
			{/if}
		</div>

		{#if !props.selectedItem}
			<p class="text-sm text-[color:var(--muted-foreground)]">Selecciona un termino en el arbol para ver su detalle.</p>
		{:else}
			<p class="mb-3 text-xs text-[color:var(--muted-foreground)]">Ruta: {props.pathLabel || '-'}</p>
			<div class="grid gap-3">
				<label class="text-sm">
					<span class="mb-1 block">Termino</span>
					<input
						type="text"
						value={props.termForm.termino}
						disabled={readOnly}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						oninput={(event) => updateTerm({ termino: event.currentTarget.value })}
					/>
				</label>

				<label class="text-sm">
					<span class="mb-1 block">Termino padre</span>
					<select
						value={props.termForm.termino_padre_id ?? ''}
						disabled={readOnly}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						onchange={(event) =>
							updateTerm({ termino_padre_id: event.currentTarget.value || null })}
					>
						<option value="">Sin padre (raiz)</option>
						{#each props.parentOptions as option}
							<option value={option.id}>{option.label}</option>
						{/each}
					</select>
				</label>

				<div class="grid gap-3 sm:grid-cols-2">
					<label class="text-sm">
						<span class="mb-1 block">Nivel</span>
						<input
							type="number"
							value={props.termForm.nivel ?? ''}
							disabled
							class="w-full border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2"
						/>
					</label>
					<label class="flex items-center gap-2 text-sm">
						<input
							type="checkbox"
							checked={props.termForm.activo}
							disabled={readOnly}
							onchange={(event) => updateTerm({ activo: event.currentTarget.checked })}
						/>
						Activo
					</label>
				</div>

				<label class="text-sm">
					<span class="mb-1 block">Definicion</span>
					<textarea
						rows={4}
						value={props.termForm.definicion}
						disabled={readOnly}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						oninput={(event) => updateTerm({ definicion: event.currentTarget.value })}
					></textarea>
				</label>

				<label class="text-sm">
					<span class="mb-1 block">Ejemplo</span>
					<textarea
						rows={3}
						value={props.termForm.ejemplo}
						disabled={readOnly}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						oninput={(event) => updateTerm({ ejemplo: event.currentTarget.value })}
					></textarea>
				</label>

				<label class="text-sm">
					<span class="mb-1 block">Bibliografia</span>
					<textarea
						rows={3}
						value={props.termForm.bibliografia}
						disabled={readOnly}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						oninput={(event) => updateTerm({ bibliografia: event.currentTarget.value })}
					></textarea>
				</label>

				<label class="text-sm">
					<span class="mb-1 block">Equivalencias (una por linea)</span>
					<textarea
						rows={3}
						value={props.termForm.equivalenciasText}
						disabled={readOnly}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						oninput={(event) => updateTerm({ equivalenciasText: event.currentTarget.value })}
					></textarea>
				</label>

				<label class="text-sm">
					<span class="mb-1 block">Patron especifico</span>
					<input
						type="text"
						value={props.termForm.patron_especifico}
						disabled={readOnly}
						class="w-full border border-[color:var(--border)] px-3 py-2"
						oninput={(event) => updateTerm({ patron_especifico: event.currentTarget.value })}
					/>
				</label>
			</div>

			{#if !readOnly}
				<div class="mt-4 flex justify-end">
					<Button variant="success" onclick={props.onSaveTerm} disabled={!props.termDirty || props.savingTerm}>
						{props.savingTerm ? 'Guardando...' : 'Guardar termino'}
					</Button>
				</div>
			{/if}
		{/if}
	</div>
</section>

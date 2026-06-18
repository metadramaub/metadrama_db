<script lang="ts">
	import { onDestroy } from 'svelte';
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import {
		OBRA_EDICION_BASE_HELP,
		OBRA_EDICION_BASE_EJEMPLO_HTML,
		OBRA_FUENTE_FECHA_EJEMPLO_HTML,
		OBRA_REFERENCIAS_MULTIPLES_HELP
	} from '$lib/config/citation-examples';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, patchCurrentObra, setDirty, setSaving } from '$lib/stores/currentObra';
	import { displayTerm } from '$lib/utils/vocabulario';

	const props = $props<{
		obra: Tables<'obras'>;
		generoOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>>;
		saveRequestToken?: number;
		readOnly?: boolean;
		canComment?: boolean;
		focusComentarioId?: string | null;
	}>();
	// Temporal: ocultar en UI hasta reactivar el flujo de fechas METADRAMA.
	const SHOW_METADRAMA_DATES = false;

	type FormState = {
		titulo: string;
		variantes_titulo: string[];
		genero_id: string;
		fecha_inicio_trad: number | null;
		fecha_fin_trad: number | null;
		fuente_fecha: string | null;
		fecha_inicio_metadrama: number | null;
		fecha_fin_metadrama: number | null;
		edicion: string;
	};

	function toFormState(obra: Tables<'obras'>): FormState {
		return {
			titulo: obra.titulo ?? '',
			variantes_titulo: obra.variantes_titulo ?? [],
			genero_id: obra.genero_id ?? '',
			fecha_inicio_trad: obra.fecha_inicio_trad,
			fecha_fin_trad: obra.fecha_fin_trad,
			fuente_fecha: obra.fuente_fecha,
			fecha_inicio_metadrama: obra.fecha_inicio_metadrama,
			fecha_fin_metadrama: obra.fecha_fin_metadrama,
			edicion: obra.edicion ?? ''
		};
	}

	let form = $state<FormState>(toFormState(props.obra));
	let hydratedObraId = $state(props.obra.obra_id);
	let varianteDeleteTargetIndex = $state<number | null>(null);

	let timer: ReturnType<typeof setTimeout> | null = null;
	let savingNow = $state(false);
	let lastHandledSaveRequestToken = $state(props.saveRequestToken ?? 0);
	const generoDropdownItems = $derived(
		props.generoOptions.map((genero: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino' | 'etiqueta'>) => ({
			id: genero.termino_id,
			label: displayTerm(genero)
		}))
	);

	function clearQueuedSave() {
		if (!timer) return;
		clearTimeout(timer);
		timer = null;
	}

	$effect(() => {
		const nextObraId = props.obra.obra_id;
		if (nextObraId === hydratedObraId) return;
		hydratedObraId = nextObraId;
		clearQueuedSave();
		savingNow = false;
		varianteDeleteTargetIndex = null;
		form = toFormState(props.obra);
		setSaving(false, 'datos');
		setDirty(false, 'datos');
	});

	$effect(() => {
		const nextToken = props.saveRequestToken ?? 0;
		if (nextToken <= lastHandledSaveRequestToken) return;
		lastHandledSaveRequestToken = nextToken;
		void save();
	});

	function mutateField<T extends keyof FormState>(key: T, value: FormState[T]) {
		if (props.readOnly) return;
		form = { ...form, [key]: value };
		queueSave();
	}

	function queueSave() {
		if (props.readOnly) return;
		setDirty(true, 'datos');
		clearQueuedSave();
		timer = setTimeout(() => save(), 10_000);
	}

	function addVariante() {
		if (props.readOnly) return;
		form = { ...form, variantes_titulo: [...form.variantes_titulo, ''] };
		queueSave();
	}

	function removeVariante(index: number) {
		if (props.readOnly) return;
		form = {
			...form,
			variantes_titulo: form.variantes_titulo.filter((_, idx) => idx !== index)
		};
		queueSave();
	}

	function requestRemoveVariante(index: number) {
		if (props.readOnly) return;
		varianteDeleteTargetIndex = index;
	}

	function closeVarianteDeleteModal() {
		varianteDeleteTargetIndex = null;
	}

	function confirmRemoveVariante() {
		if (varianteDeleteTargetIndex === null) return;
		removeVariante(varianteDeleteTargetIndex);
		varianteDeleteTargetIndex = null;
	}

	async function save() {
		if (props.readOnly || savingNow) return;
		savingNow = true;
		setSaving(true, 'datos');
		const requestPayload = {
			...form,
			variantes_titulo: form.variantes_titulo.map((item) => item.trim()).filter(Boolean)
		};

		const response = await fetch(`/api/obras/${props.obra.obra_id}/datos`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(requestPayload)
		});
		savingNow = false;

		if (!response.ok) {
			setSaving(false, 'datos');
			const body = await response.json().catch(() => ({}));
			const detail = Array.isArray(body?.details) ? body.details[0]?.message : null;
			pushToast('error', detail ?? body.message ?? 'No se pudieron guardar los datos de la obra');
			return;
		}

		const responsePayload = await response.json();
		patchCurrentObra(responsePayload.obra);
		pushToast('success', 'Guardado');
		markSaved('datos');
	}

	onDestroy(() => {
		clearQueuedSave();
	});
</script>

<section class="space-y-5">
	<div class="card p-4">
		<div class="mb-3">
			<div>
				<h2 class="text-xl font-semibold">Datos de la obra</h2>
			</div>
		</div>
		<div class="grid gap-4 md:grid-cols-2">
			<label class="form-field">
				<span class="form-label">Título principal</span>
				<input
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					disabled={props.readOnly}
					value={form.titulo}
					oninput={(event) => mutateField('titulo', event.currentTarget.value)}
				/>
			</label>

			<label class="form-field">
				<span class="form-label">Género</span>
				<CheckDropdown
					multiple={false}
					allowSingleClear={true}
					search={generoDropdownItems.length > 8}
					placeholder="Selecciona género"
					items={generoDropdownItems}
					disabled={props.readOnly}
					selectedIds={form.genero_id ? [form.genero_id] : []}
					onChange={(ids) => mutateField('genero_id', ids[0] ?? '')}
				/>
			</label>

			<label class="form-field">
				<span class="form-label">Fecha inicio tradicional</span>
				<input
					type="number"
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					disabled={props.readOnly}
					value={form.fecha_inicio_trad ?? ''}
					oninput={(event) =>
						mutateField(
							'fecha_inicio_trad',
							event.currentTarget.value ? Number(event.currentTarget.value) : null
						)}
				/>
			</label>
			<label class="form-field">
				<span class="form-label">Fecha fin tradicional</span>
				<input
					type="number"
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					disabled={props.readOnly}
					value={form.fecha_fin_trad ?? ''}
					oninput={(event) =>
						mutateField('fecha_fin_trad', event.currentTarget.value ? Number(event.currentTarget.value) : null)}
				/>
			</label>
		</div>

		<label class="form-field mt-4">
			<span class="form-label">
				<span class="form-label-with-help">
					Fuente bibliográfica para la fecha
					<FieldHelpTooltip
						text={OBRA_REFERENCIAS_MULTIPLES_HELP}
						label="Ayuda para referencias múltiples en fuente bibliográfica"
					/>
				</span>
			</span>
			<p class="form-help">Ejemplo de cita: {@html OBRA_FUENTE_FECHA_EJEMPLO_HTML}</p>
			<MarkdownEditorLite
				rows={3}
				class="mt-1"
				minHeightClass="min-h-28"
				value={form.fuente_fecha ?? ''}
				disabled={props.readOnly}
				onChange={(nextValue) => mutateField('fuente_fecha', nextValue || null)}
			/>
		</label>

		{#if SHOW_METADRAMA_DATES}
			<div class="mt-4 grid gap-4 md:grid-cols-2">
				<label class="form-field">
					<span class="form-label">Fecha inicio METADRAMA</span>
					<input
						type="number"
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						disabled={props.readOnly}
						value={form.fecha_inicio_metadrama ?? ''}
						oninput={(event) =>
							mutateField(
								'fecha_inicio_metadrama',
								event.currentTarget.value ? Number(event.currentTarget.value) : null
							)}
					/>
				</label>

				<label class="form-field">
					<span class="form-label">Fecha fin METADRAMA</span>
					<input
						type="number"
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
						disabled={props.readOnly}
						value={form.fecha_fin_metadrama ?? ''}
						oninput={(event) =>
							mutateField(
								'fecha_fin_metadrama',
								event.currentTarget.value ? Number(event.currentTarget.value) : null
							)}
					/>
				</label>
			</div>
		{/if}

		<label class="form-field mt-4">
			<span class="form-label">
				<span class="form-label-with-help">
					Edición base utilizada
					<FieldHelpTooltip
						text={OBRA_EDICION_BASE_HELP}
						label="Ayuda para referencias múltiples en edición base"
					/>
				</span>
			</span>
			<p class="form-help">Ejemplo de cita: {@html OBRA_EDICION_BASE_EJEMPLO_HTML}</p>
			<MarkdownEditorLite
				rows={4}
				class="mt-1"
				minHeightClass="min-h-32"
				value={form.edicion}
				disabled={props.readOnly}
				onChange={(nextValue) => mutateField('edicion', nextValue)}
			/>
		</label>

		<div class="mt-5 border-t border-[color:var(--border)] pt-4">
			<div class="mb-3 flex items-center justify-between">
				<h3 class="text-base font-semibold">Variantes de título</h3>
				<Button variant="secondary" onclick={addVariante} disabled={props.readOnly}>Añadir variante</Button>
			</div>
			<div class="space-y-2">
				{#if form.variantes_titulo.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">No hay variantes añadidas.</p>
				{:else}
					{#each form.variantes_titulo as variante, idx}
						<div class="flex gap-2">
							<input
								class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
								disabled={props.readOnly}
								value={variante}
								oninput={(event) => {
									const updated = [...form.variantes_titulo];
									updated[idx] = event.currentTarget.value;
									mutateField('variantes_titulo', updated);
								}}
							/>
							<Button variant="danger" onclick={() => requestRemoveVariante(idx)} disabled={props.readOnly}
								>Eliminar</Button
							>
						</div>
					{/each}
				{/if}
			</div>
		</div>
	</div>

	<InternalCommentsPanel
		obraId={props.obra.obra_id}
		canComment={Boolean(props.canComment)}
		section="datos"
		focusComentarioId={props.focusComentarioId}
		title="Comentarios internos sobre datos de la obra"
		emptyText="No hay comentarios internos sobre esta sección."
	/>

	{#if varianteDeleteTargetIndex !== null}
		<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
			<div class="card w-full max-w-md p-5">
				<h3 class="text-lg font-semibold">Eliminar variante de título</h3>
				<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">Esta acción no se puede deshacer.</p>
				<div class="mt-4 flex justify-end gap-2">
					<Button variant="secondary" onclick={closeVarianteDeleteModal}>Cancelar</Button>
					<Button variant="danger" disabled={props.readOnly} onclick={confirmRemoveVariante}
						>Eliminar</Button
					>
				</div>
			</div>
		</div>
	{/if}
</section>


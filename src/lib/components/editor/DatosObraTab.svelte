<script lang="ts">
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import MarkdownEditorLite from '$lib/components/ui/markdown-editor-lite.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, patchCurrentObra, setDirty, setSaving } from '$lib/stores/currentObra';

	const props = $props<{
		obra: Tables<'obras'>;
		generoOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>;
		readOnly?: boolean;
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

	let form = $state<FormState>({
		titulo: props.obra.titulo ?? '',
		variantes_titulo: props.obra.variantes_titulo ?? [],
		genero_id: props.obra.genero_id ?? '',
		fecha_inicio_trad: props.obra.fecha_inicio_trad,
		fecha_fin_trad: props.obra.fecha_fin_trad,
		fuente_fecha: props.obra.fuente_fecha,
		fecha_inicio_metadrama: props.obra.fecha_inicio_metadrama,
		fecha_fin_metadrama: props.obra.fecha_fin_metadrama,
		edicion: props.obra.edicion ?? ''
	});

	let timer: ReturnType<typeof setTimeout> | null = null;
	let savingNow = $state(false);
	const generoDropdownItems = $derived(
		props.generoOptions.map((genero: Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>) => ({
			id: genero.termino_id,
			label: genero.termino
		}))
	);

	function mutateField<T extends keyof FormState>(key: T, value: FormState[T]) {
		if (props.readOnly) return;
		form = { ...form, [key]: value };
		queueSave();
	}

	function queueSave() {
		if (props.readOnly) return;
		setDirty(true, 'datos');
		if (timer) clearTimeout(timer);
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
</script>

<section class="space-y-5">
	<div class="card p-4">
		<div class="mb-3 flex flex-wrap items-center justify-between gap-3">
			<div>
				<h2 class="text-xl font-semibold">Datos de la obra</h2>
			</div>
			<Button variant="success" onclick={save} disabled={savingNow || props.readOnly}
				>{savingNow ? 'Guardando...' : 'Guardar'}</Button
			>
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
			<span class="form-label">Fuente bibliográfica para la fecha</span>
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
			<span class="form-label">Edición base utilizada</span>
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
							<Button variant="danger" onclick={() => removeVariante(idx)} disabled={props.readOnly}
								>Eliminar</Button
							>
						</div>
					{/each}
				{/if}
			</div>
		</div>
	</div>
</section>


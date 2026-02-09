<script lang="ts">
	import type { Tables } from '$lib/types/database.types';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, setDirty, setSaving } from '$lib/stores/currentObra';

	const props = $props<{
		obra: Tables<'obras'>;
		generoOptions: Array<Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>>;
	}>();

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

	function mutateField<T extends keyof FormState>(key: T, value: FormState[T]) {
		form = { ...form, [key]: value };
		queueSave();
	}

	function queueSave() {
		setDirty(true);
		if (timer) clearTimeout(timer);
		timer = setTimeout(() => save(), 10_000);
	}

	function addVariante() {
		form = { ...form, variantes_titulo: [...form.variantes_titulo, ''] };
		queueSave();
	}

	function removeVariante(index: number) {
		form = {
			...form,
			variantes_titulo: form.variantes_titulo.filter((_, idx) => idx !== index)
		};
		queueSave();
	}

	async function save() {
		if (savingNow) return;
		savingNow = true;
		setSaving(true);
		const payload = {
			...form,
			variantes_titulo: form.variantes_titulo.map((item) => item.trim()).filter(Boolean)
		};

		const response = await fetch(`/api/obras/${props.obra.obra_id}/datos`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(payload)
		});
		savingNow = false;

		if (!response.ok) {
			setSaving(false);
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo guardar los datos de la obra');
			return;
		}

		pushToast('success', 'Guardado');
		markSaved();
	}
</script>

<section class="space-y-5">
	<div class="card p-4">
		<div class="mb-2 text-sm text-[color:var(--muted-foreground)]">
			Guardado automático cada 10 segundos si hay cambios.
		</div>
		<div class="grid gap-4 md:grid-cols-2">
			<label class="text-sm">
				<span class="mb-1 block">Título principal *</span>
				<input
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					value={form.titulo}
					oninput={(event) => mutateField('titulo', event.currentTarget.value)}
				/>
			</label>

			<label class="text-sm">
				<span class="mb-1 block">Género *</span>
				<select
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					value={form.genero_id}
					onchange={(event) => mutateField('genero_id', event.currentTarget.value)}
				>
					<option value="">Selecciona género</option>
					{#each props.generoOptions as genero}
						<option value={genero.termino_id}>{genero.termino}</option>
					{/each}
				</select>
			</label>

			<label class="text-sm">
				<span class="mb-1 block">Fecha inicio tradicional</span>
				<input
					type="number"
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					value={form.fecha_inicio_trad ?? ''}
					oninput={(event) =>
						mutateField(
							'fecha_inicio_trad',
							event.currentTarget.value ? Number(event.currentTarget.value) : null
						)}
				/>
			</label>
			<label class="text-sm">
				<span class="mb-1 block">Fecha fin tradicional</span>
				<input
					type="number"
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					value={form.fecha_fin_trad ?? ''}
					oninput={(event) =>
						mutateField('fecha_fin_trad', event.currentTarget.value ? Number(event.currentTarget.value) : null)}
				/>
			</label>
		</div>

		<label class="mt-4 block text-sm">
			<span class="mb-1 block">Fuente bibliográfica</span>
			<textarea
				class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				rows={3}
				oninput={(event) => mutateField('fuente_fecha', event.currentTarget.value || null)}
			>{form.fuente_fecha ?? ''}</textarea>
		</label>

		<div class="mt-4 grid gap-4 md:grid-cols-2">
			<label class="text-sm">
				<span class="mb-1 block">Fecha inicio METADRAMA</span>
				<input
					type="number"
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					value={form.fecha_inicio_metadrama ?? ''}
					oninput={(event) =>
						mutateField(
							'fecha_inicio_metadrama',
							event.currentTarget.value ? Number(event.currentTarget.value) : null
						)}
				/>
			</label>

			<label class="text-sm">
				<span class="mb-1 block">Fecha fin METADRAMA</span>
				<input
					type="number"
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					value={form.fecha_fin_metadrama ?? ''}
					oninput={(event) =>
						mutateField(
							'fecha_fin_metadrama',
							event.currentTarget.value ? Number(event.currentTarget.value) : null
						)}
				/>
			</label>
		</div>

		<label class="mt-4 block text-sm">
			<span class="mb-1 block">Edición base utilizada *</span>
			<textarea
				class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
				rows={4}
				oninput={(event) => mutateField('edicion', event.currentTarget.value)}
			>{form.edicion}</textarea>
		</label>
	</div>

	<div class="card p-4">
		<div class="mb-3 flex items-center justify-between">
			<h3 class="text-lg font-semibold">Variantes de título</h3>
			<Button variant="secondary" onclick={addVariante}>Añadir variante</Button>
		</div>
		<div class="space-y-2">
			{#if form.variantes_titulo.length === 0}
				<p class="text-sm text-[color:var(--muted-foreground)]">No hay variantes añadidas.</p>
			{:else}
				{#each form.variantes_titulo as variante, idx}
					<div class="flex gap-2">
						<input
							class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
							value={variante}
							oninput={(event) => {
								const updated = [...form.variantes_titulo];
								updated[idx] = event.currentTarget.value;
								mutateField('variantes_titulo', updated);
							}}
						/>
						<Button variant="danger" onclick={() => removeVariante(idx)}>Eliminar</Button>
					</div>
				{/each}
			{/if}
		</div>
	</div>

	<div class="flex justify-end">
		<Button onclick={save} disabled={savingNow}>{savingNow ? 'Guardando...' : 'Guardar ahora'}</Button>
	</div>
</section>

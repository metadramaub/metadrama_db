<script lang="ts">
	import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';

	const props = $props<{
		group: MetricCatalogDomainRow;
		options: MetricCatalogDomainRow[];
		selectedIds: string[];
		onChange: (ids: string[]) => void;
		onApplyAll?: () => void;
	}>();

	const minimum = $derived(Number(props.group.selecciones_min ?? 0));
	const maximum = $derived(Number(props.group.selecciones_max ?? 1));
	const optional = $derived(minimum === 0);

	function changeSingle(event: Event) {
		const value = (event.currentTarget as HTMLSelectElement).value;
		props.onChange(value ? [value] : []);
	}

	function toggleOption(optionId: string, checked: boolean) {
		const current = new Set(props.selectedIds);
		if (checked) {
			if (current.size >= maximum) return;
			current.add(optionId);
		} else {
			current.delete(optionId);
		}
		props.onChange([...current]);
	}
</script>

<fieldset class="space-y-2 border-l-2 border-[color:var(--border)] pl-3">
	<div class="flex flex-wrap items-start justify-between gap-2">
		<div>
			<legend class="text-sm font-medium">{String(props.group.nombre)}</legend>
			{#if props.group.ayuda_editor}
				<p class="mt-1 text-xs leading-5 text-[color:var(--muted-foreground)]">
					{String(props.group.ayuda_editor)}
				</p>
			{/if}
		</div>
		<span class="text-[0.7rem] uppercase tracking-wide text-[color:var(--muted-foreground)]">
			{optional ? 'Opcional' : 'Obligatoria'}
		</span>
	</div>

	{#if maximum === 1}
		<select
			class="h-10 w-full border border-[color:var(--border)] bg-white px-3 text-sm"
			value={props.selectedIds[0] ?? ''}
			onchange={changeSingle}
		>
			<option value="">
				{optional ? 'No aparece / no se aplica' : 'Seleccionar una respuesta'}
			</option>
			{#each props.options as option (String(option.opcion_eleccion_id))}
				<option value={String(option.opcion_eleccion_id)}>{String(option.nombre)}</option>
			{/each}
		</select>
	{:else}
		<div class="grid gap-2 sm:grid-cols-2">
			{#each props.options as option (String(option.opcion_eleccion_id))}
				<label class="flex items-start gap-2 border border-[color:var(--border)] bg-white px-3 py-2 text-sm">
					<input
						type="checkbox"
						class="mt-0.5"
						checked={props.selectedIds.includes(String(option.opcion_eleccion_id))}
						onchange={(event) =>
							toggleOption(
								String(option.opcion_eleccion_id),
								event.currentTarget.checked
							)}
					/>
					<span>{String(option.nombre)}</span>
				</label>
			{/each}
		</div>
	{/if}

	{#if props.onApplyAll && props.group.permite_aplicar_global}
		<button
			type="button"
			class="text-xs font-medium text-[color:var(--primary)] hover:underline disabled:opacity-40"
			onclick={props.onApplyAll}
			disabled={props.selectedIds.length === 0}
		>
			Aplicar esta respuesta a todas las unidades equivalentes
		</button>
	{/if}
</fieldset>

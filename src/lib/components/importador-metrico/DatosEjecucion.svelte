<script lang="ts">
	import type { MetadatosEditables } from '$lib/importador-metrico/types';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	let { metadatos = $bindable(), alCambiar = () => {}, soloLectura = false } = $props<{
		metadatos: MetadatosEditables; alCambiar?: () => void; soloLectura?: boolean;
	}>();
	const campos = [
		['ia_generador', 'Servicio'], ['ia_modelo', 'Modelo'], ['ia_modo', 'Modo'], ['ia_plan', 'Cuenta'],
		['ia_parametros', 'Parámetros conocidos']
	] as const;
</script>

<fieldset class="space-y-3 border-t border-[color:var(--border)] pt-4">
	<legend class="form-label"><span class="form-label-with-help">Extracción con IA <span class="font-normal">(opcional)</span>
		<FieldHelpTooltip label="Datos de la extracción" text="Revisa los datos declarados por la IA. Corrige lo que sepas y deja vacío lo desconocido; no se deduce el modelo a partir del modo." />
	</span></legend>
	<div class="grid gap-4 sm:grid-cols-2">
		{#each campos as [clave, etiqueta]}
			{#if soloLectura}
				<div class={clave === 'ia_parametros' ? 'sm:col-span-2' : ''}><p class="form-label">{etiqueta}</p><p class="whitespace-pre-wrap text-sm">{metadatos[clave] || 'Sin especificar'}</p></div>
			{:else}
				<label class={'form-field' + (clave === 'ia_parametros' ? ' sm:col-span-2' : '')}>
					<span class="form-label">{etiqueta}</span>
					{#if clave === 'ia_parametros'}
						<textarea name={clave} bind:value={metadatos[clave]} oninput={alCambiar} maxlength="2000" rows="2" class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"></textarea>
					{:else}
						<input name={clave} bind:value={metadatos[clave]} oninput={alCambiar} maxlength="2000" class="w-full rounded-md border border-[color:var(--border)] px-3 py-2" />
					{/if}
				</label>
			{/if}
		{/each}
	</div>
</fieldset>

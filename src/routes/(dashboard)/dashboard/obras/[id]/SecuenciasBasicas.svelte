<script lang="ts">
	import type { cargarFichaBasica } from '$lib/server/importador-metrico/ficha-basica';
	import { enhance } from '$app/forms';
	import { pushToast } from '$lib/stores/toast';
	import type { EdicionFila } from '$lib/importador-metrico/edicion';
	import VistaPrevia from '$lib/components/importador-metrico/VistaPrevia.svelte';
	import DatosEjecucion from '$lib/components/importador-metrico/DatosEjecucion.svelte';

	let { data } = $props<{ data: Awaited<ReturnType<typeof cargarFichaBasica>> }>();
	const m = $derived(data.vista.datos!.metadatos);
	let pendiente = $state(false);
	let mensaje = $state('');
	let cambio = '';
	let modificadoEn = '';
	let importacionId = '';
	let formulario: HTMLFormElement;

	function abrirEdicion() {
		mensaje = '';
		modificadoEn = data.modificadoEn ?? '';
		importacionId = data.vista.confirmacion?.importacion_id ?? '';
	}

	function guardar(_tramo: string, edicion: EdicionFila | null) {
		if (!edicion || pendiente) return;
		cambio = JSON.stringify(edicion);
		formulario.requestSubmit();
	}
</script>

<section class="space-y-6">
	<div class="card space-y-2 p-4"><h2 class="font-semibold">Edición base</h2><p class="whitespace-pre-wrap text-sm">{m.edicion_base}</p></div>
	{#if data.vista.datos?.procedencia.ejecucion}<div class="card p-4"><DatosEjecucion metadatos={data.vista.metadatos} soloLectura /></div>{/if}
	<p class="text-sm text-[color:var(--muted-foreground)]">Importada por {data.importadoPor} el {new Date(data.importadoEn).toLocaleString('es-ES', {timeZone:'Europe/Madrid'})}.</p>
	<form hidden method="POST" action="?/guardarMetrica" bind:this={formulario} use:enhance={({ formData }) => {
		formData.set('cambio', cambio);
		formData.set('modificado_en', modificadoEn);
		formData.set('importacion_id', importacionId);
		pendiente = true;
		mensaje = '';
		return async ({ result, update }) => {
			try {
				if (result.type === 'success') {
					await update();
					pushToast('success', 'Corrección guardada.');
				} else {
					mensaje = result.type === 'failure'
						? String(result.data?.mensaje ?? 'No se pudo guardar la corrección.')
						: 'No se pudo guardar la corrección.';
				}
			} finally {
				pendiente = false;
			}
		};
	}}></form>
	{#key data.vista.confirmacion?.importacion_id}
		<VistaPrevia vista={data.vista} editable={data.puedeEditarMetrica} formas={data.formas}
			ocupado={pendiente} restablecer={false} guardarDirecto errorEdicion={mensaje}
			onabrir={abrirEdicion} oneditar={data.puedeEditarMetrica ? guardar : undefined} />
	{/key}
</section>

<script lang="ts">
	import type { PageData } from './$types';
	import { enhance } from '$app/forms';
	import type { EdicionFila } from '$lib/importador-metrico/edicion';
	import VistaPrevia from '$lib/components/importador-metrico/VistaPrevia.svelte';
	import DatosEjecucion from '$lib/components/importador-metrico/DatosEjecucion.svelte';

	let { data } = $props<{ data: PageData }>();
	const m = $derived(data.vista.datos!.metadatos);
	let pendiente = $state(false);
	let mensaje = $state('');
	let guardada = $state(false);
	let cambio = '';
	let modificadoEn = '';
	let importacionId = '';
	let formulario: HTMLFormElement;

	function abrirEdicion() {
		mensaje = '';
		guardada = false;
		modificadoEn = data.modificadoEn ?? '';
		importacionId = data.vista.confirmacion?.importacion_id ?? '';
	}

	function guardar(_tramo: string, edicion: EdicionFila | null) {
		if (!edicion || pendiente) return;
		cambio = JSON.stringify(edicion);
		formulario.requestSubmit();
	}
</script>

<svelte:head><title>{m.titulo} — Ficha básica — Versología</title></svelte:head>
<section class="mx-auto max-w-7xl space-y-6">
	<header class="space-y-2"><a href="/dashboard/importador/fichas" class="text-sm underline">Fichas básicas</a><h1 class="font-display text-3xl">{m.titulo}</h1><p class="text-sm">Ficha básica — {m.autor_nombre} — {m.fecha_inicio}–{m.fecha_fin}</p><p class="text-sm text-[color:var(--muted-foreground)]">Importada por {data.importadoPor} el {new Date(data.importadoEn).toLocaleString('es-ES',{timeZone:'Europe/Madrid'})}.</p></header>
	{#if data.puedeEditarMetadatos}
		<a href={`/dashboard/obras/${data.obraId}/metadatos`} class="inline-block text-sm font-medium underline underline-offset-2">Editar datos de la obra</a>
	{/if}
	<div class="card space-y-2 p-4"><h2 class="font-semibold">Edición base</h2><p class="whitespace-pre-wrap text-sm">{m.edicion_base}</p></div>
	{#if data.vista.datos?.procedencia.ejecucion}<div class="card p-4"><DatosEjecucion metadatos={data.vista.metadatos} soloLectura /></div>{/if}
	<p class="text-sm text-[color:var(--muted-foreground)]">Se conserva el JSON original de la importación.</p>
	{#if guardada}<p role="status" class="text-sm text-[color:var(--success)]">Corrección guardada.</p>{/if}
	<form hidden method="POST" action="?/guardar" bind:this={formulario} use:enhance={({ formData }) => {
		formData.set('cambio', cambio);
		formData.set('modificado_en', modificadoEn);
		formData.set('importacion_id', importacionId);
		pendiente = true;
		mensaje = '';
		return async ({ result, update }) => {
			try {
				if (result.type === 'success') {
					await update();
					guardada = true;
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

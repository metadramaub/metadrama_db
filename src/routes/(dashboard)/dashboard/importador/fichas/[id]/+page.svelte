<script lang="ts">
	import type { PageData } from './$types';
	import { enhance } from '$app/forms';
	import Button from '$lib/components/ui/button.svelte';
	import type { EdicionFila } from '$lib/importador-metrico/edicion';
	import type { ResultadoVistaPrevia } from '$lib/importador-metrico/types';
	import VistaPrevia from '$lib/components/importador-metrico/VistaPrevia.svelte';
	import DatosEjecucion from '$lib/components/importador-metrico/DatosEjecucion.svelte';
	let {data}=$props<{data:PageData}>();
	const m=$derived(data.vista.datos!.metadatos);
	let editando = $state(false);
	let pendiente = $state(false);
	let mensaje = $state('');
	let guardada = $state(false);
	let revision = $state<ResultadoVistaPrevia | null>(null);
	let cambio = $state('');
	let modificadoEn = $state('');
	let importacionId = $state('');
	let formularioRevision: HTMLFormElement;

	function empezar() {
		editando = true;
		mensaje = '';
		guardada = false;
		modificadoEn = data.modificadoEn ?? '';
		importacionId = data.vista.confirmacion?.importacion_id ?? '';
	}

	function revisar(_tramo: string, edicion: EdicionFila | null) {
		if (!edicion || pendiente) return;
		cambio = JSON.stringify(edicion);
		formularioRevision.requestSubmit();
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
	<div class="flex flex-wrap items-center justify-between gap-3">
		<p class="text-sm text-[color:var(--muted-foreground)]">Se conserva el JSON original de la importación.</p>
		{#if data.puedeEditarMetrica && !revision}
			<Button variant={editando ? 'ghost' : 'dark'} disabled={pendiente}
				onclick={() => { if (editando) editando = false; else empezar(); }}>
				{editando ? 'Salir de la edición' : 'Editar métrica'}
			</Button>
		{/if}
	</div>
	{#if mensaje}<p role="alert" class="text-sm text-[color:var(--danger)]">{mensaje}</p>{/if}
	{#if guardada}<p role="status" class="text-sm text-[color:var(--success)]">Corrección guardada.</p>{/if}

	<form hidden method="POST" action="?/revisar" bind:this={formularioRevision} use:enhance={({ formData }) => {
		formData.set('cambio', cambio);
		formData.set('modificado_en', modificadoEn);
		formData.set('importacion_id', importacionId);
		pendiente = true;
		mensaje = '';
		return async ({ result }) => {
			pendiente = false;
			if (result.type === 'success' && result.data?.revision) {
				revision = { ...(result.data.revision as ResultadoVistaPrevia), persistido: false };
			} else {
				mensaje = result.type === 'failure' ? String(result.data?.mensaje ?? 'No se pudo revisar la corrección.') : 'No se pudo revisar la corrección.';
			}
		};
	}}></form>

	{#if revision}
		<form method="POST" action="?/guardar" class="flex flex-wrap items-center gap-3" use:enhance={() => {
			pendiente = true;
			mensaje = '';
			return async ({ result, update }) => {
				try {
					if (result.type === 'success') {
						await update();
						revision = null;
						editando = false;
						guardada = true;
					} else {
						mensaje = result.type === 'failure' ? String(result.data?.mensaje ?? 'No se pudo guardar la corrección.') : 'No se pudo guardar la corrección.';
					}
				} finally { pendiente = false; }
			};
		}}>
			<input type="hidden" name="cambio" value={cambio} />
			<input type="hidden" name="modificado_en" value={modificadoEn} />
			<input type="hidden" name="importacion_id" value={importacionId} />
			<Button type="submit" variant="dark" loading={pendiente}>Guardar corrección</Button>
			<Button variant="ghost" disabled={pendiente} onclick={() => { revision = null; mensaje = ''; }}>Descartar corrección</Button>
		</form>
		<VistaPrevia vista={revision} />
	{:else}
		{#key editando}
			<VistaPrevia vista={data.vista} editable={editando && data.puedeEditarMetrica} formas={data.formas}
				ocupado={pendiente} restablecer={false} oneditar={revisar} />
		{/key}
	{/if}
</section>

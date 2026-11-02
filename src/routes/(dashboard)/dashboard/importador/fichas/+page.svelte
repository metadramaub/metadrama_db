<script lang="ts">
	import { tick } from 'svelte';
	import { enhance } from '$app/forms';
	import { portal } from '$lib/actions/portal';
	import type { ActionData, PageData } from './$types';
	import type { FilaBasica } from '$lib/server/importador-metrico/persistencia';
	import ListaFichasBasicas from '$lib/components/importador-metrico/ListaFichasBasicas.svelte';
	import Button from '$lib/components/ui/button.svelte';
	let { data, form } = $props<{ data: PageData; form: ActionData }>();
	let objetivo = $state<FilaBasica | null>(null);
	let confirmacion = $state('');
	let eliminando = $state(false);
	async function abrirEliminar(fila: FilaBasica) {
		objetivo = fila; confirmacion = '';
		await tick(); document.getElementById('confirmar-eliminar-basica')?.focus();
	}
</script>
<svelte:head><title>Fichas básicas · Versología</title></svelte:head>
<svelte:window onkeydown={(e) => { if (e.key === 'Escape' && !eliminando) objetivo = null; }} />
<section class="mx-auto max-w-7xl space-y-5">
	<header class="flex flex-wrap items-baseline justify-between gap-3"><h1 class="font-display text-3xl">Fichas básicas</h1><a href="/dashboard/importador" class="text-sm underline">Importar obra</a></header>
	<ListaFichasBasicas filas={data.filas} puedeEliminar={data.puedeEliminar} oneliminar={abrirEliminar} />
	<nav class="flex gap-4 text-sm" aria-label="Páginas de fichas básicas">{#if data.pagina>1}<a class="underline" href={'?pagina='+(data.pagina-1)}>Anterior</a>{/if}{#if data.hayMas}<a class="underline" href={'?pagina='+(data.pagina+1)}>Siguiente</a>{/if}</nav>
</section>

{#if objetivo && data.puedeEliminar}
	<div use:portal class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div role="dialog" aria-modal="true" aria-labelledby="eliminar-basica-titulo" tabindex="-1" class="card w-full max-w-md space-y-4 p-5">
			<h2 id="eliminar-basica-titulo" class="text-lg font-semibold">Eliminar ficha básica</h2>
			<p class="text-sm">Se eliminarán <strong>{objetivo.titulo}</strong>, sus jornadas, secuencias e importaciones. Esta acción no se puede deshacer desde la plataforma.</p>
			<form method="POST" action="?/eliminar" use:enhance={() => {
				eliminando = true;
				return async ({ result, update }) => { try { await update(); if (result.type === 'redirect' || result.type === 'success') objetivo = null; } finally { eliminando = false; } };
			}} class="space-y-4">
				<input type="hidden" name="importacion_id" value={objetivo.importacion_id} />
				<label class="form-field" for="confirmar-eliminar-basica"><span class="form-label">Escribe el título para confirmar</span><input id="confirmar-eliminar-basica" name="confirmacion" bind:value={confirmacion} disabled={eliminando} autocomplete="off" required class="w-full rounded-md border border-[color:var(--border)] px-3 py-2" /></label>
				{#if form?.importacion_id === objetivo.importacion_id && form.mensaje}<p role="alert" class="text-sm text-[color:var(--danger)]">{form.mensaje}</p>{/if}
				<div class="flex justify-end gap-2"><Button variant="secondary" disabled={eliminando} onclick={() => objetivo = null}>Cancelar</Button><Button type="submit" variant="danger" loading={eliminando} loadingLabel="Eliminando…" disabled={confirmacion.trim() !== objetivo.titulo.trim()}>Eliminar</Button></div>
			</form>
		</div>
	</div>
{/if}

<script lang="ts">
	import type { PageData } from './$types';
	import VistaPrevia from '$lib/components/importador-metrico/VistaPrevia.svelte';
	import DatosEjecucion from '$lib/components/importador-metrico/DatosEjecucion.svelte';
	let {data}=$props<{data:PageData}>();
	const m=$derived(data.vista.datos!.metadatos);
</script>
<svelte:head><title>{m.titulo} — Ficha básica — Versología</title></svelte:head>
<section class="mx-auto max-w-7xl space-y-6">
	<header class="space-y-2"><a href="/dashboard/importador/fichas" class="text-sm underline">Fichas básicas</a><h1 class="font-display text-3xl">{m.titulo}</h1><p class="text-sm">Ficha básica — {m.autor_nombre} — {m.fecha_inicio}–{m.fecha_fin}</p><p class="text-sm text-[color:var(--muted-foreground)]">Importada por {data.importadoPor} el {new Date(data.importadoEn).toLocaleString('es-ES',{timeZone:'Europe/Madrid'})}.</p></header>
	<div class="card space-y-2 p-4"><h2 class="font-semibold">Edición base</h2><p class="whitespace-pre-wrap text-sm">{m.edicion_base}</p></div>
	{#if data.vista.datos?.procedencia.ejecucion}<div class="card p-4"><DatosEjecucion metadatos={data.vista.metadatos} soloLectura /></div>{/if}
	<p class="text-sm text-[color:var(--muted-foreground)]">Se conserva la copia confirmada de la importación. Su incorporación a los análisis aún está pendiente.</p>
	<VistaPrevia vista={data.vista} />
</section>

<script lang="ts">
	import type { PageData } from './$types';
	let {data}=$props<{data:PageData}>();
</script>
<svelte:head><title>Fichas básicas · Versología</title></svelte:head>
<section class="mx-auto max-w-7xl space-y-5">
	<header class="flex flex-wrap items-baseline justify-between gap-3"><h1 class="font-display text-3xl">Fichas básicas</h1><a href="/dashboard/importador" class="text-sm underline">Importar obra</a></header>
	<div class="overflow-x-auto rounded-lg border border-[color:var(--border)] bg-white">
		<table class="w-full text-sm"><thead class="bg-[color:var(--muted)] text-left"><tr><th class="px-4 py-3">Obra</th><th class="px-4 py-3">Autor</th><th class="px-4 py-3">Importada por</th><th class="px-4 py-3">Fecha</th></tr></thead>
		<tbody class="divide-y divide-[color:var(--border)]">{#each data.filas as f}<tr><td class="px-4 py-3"><a class="underline" href={'/dashboard/importador/fichas/'+f.importacion_id}>{f.titulo}</a></td><td class="px-4 py-3">{f.autor_nombre}</td><td class="px-4 py-3">{f.importado_por}</td><td class="px-4 py-3">{new Date(f.importado_en).toLocaleDateString('es-ES',{timeZone:'Europe/Madrid'})}</td></tr>{:else}<tr><td colspan="4" class="px-4 py-6 text-[color:var(--muted-foreground)]">No hay fichas básicas guardadas en esta página.</td></tr>{/each}</tbody></table>
	</div>
	<nav class="flex gap-4 text-sm" aria-label="Páginas de fichas básicas">{#if data.pagina>1}<a class="underline" href={'?pagina='+(data.pagina-1)}>Anterior</a>{/if}{#if data.hayMas}<a class="underline" href={'?pagina='+(data.pagina+1)}>Siguiente</a>{/if}</nav>
</section>

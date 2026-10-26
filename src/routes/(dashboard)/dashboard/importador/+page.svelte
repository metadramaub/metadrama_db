<script lang="ts">
	import { untrack } from 'svelte';
	import { enhance } from '$app/forms';
	import type { SubmitFunction } from '@sveltejs/kit';
	import type { ActionData, PageData } from './$types';
	import type { MetadatosEditables } from '$lib/importador-metrico/types';
	import VistaPrevia from '$lib/components/importador-metrico/VistaPrevia.svelte';

	let { data, form } = $props<{ data: PageData; form: ActionData }>();
	const respuesta = () => form && 'vista' in form ? form : null;
	let ultimaRespuesta = $state(untrack(respuesta));
	const vacios: MetadatosEditables = { titulo:'',autor_nombre:'',genero:'comedia_o_tragicomedia',edicion_base:'',fecha_inicio:'',fecha_fin:'',fuente_fecha:'',fundamento_autoria:'' };
	let entrada = $state(untrack(() => respuesta()?.entrada ?? ''));
	let metadatos = $state<MetadatosEditables>(untrack(() => ({ ...vacios, ...respuesta()?.vista.metadatos })));
	let autorId = $state(untrack(() => respuesta()?.autorId ?? ''));
	let ejemplo = $state('');
	let pendiente = $state(false);
	let entradaCambiada = $state(false);
	let desactualizada = $state(false);
	let copiado = $state(false);
	let errorCopia = $state(false);
	let respuestaDescartada = $state(false);
	const vista = $derived(ultimaRespuesta?.vista ?? null);
	const coincidencias = $derived(ultimaRespuesta?.coincidencias ?? []);
	$effect(() => {
		const r = respuesta();
		if (r) {
			ultimaRespuesta = r;
			entrada = r.entrada;
			metadatos = { ...r.vista.metadatos };
			autorId = r.autorId;
			entradaCambiada = false;
			desactualizada = false;
		}
	});
	const enviar: SubmitFunction = () => {
		const enviados = JSON.stringify([entrada, metadatos, autorId]);
		respuestaDescartada = false;
		pendiente = true;
		return async ({ update }) => {
			try {
				if (JSON.stringify([entrada, metadatos, autorId]) !== enviados) {
					respuestaDescartada = true;
					desactualizada = true;
					return;
				}
				await update({ reset:false, invalidateAll:false });
			} finally { pendiente = false; }
		};
	};
	function cargarEjemplo() {
		const p = data.pilotos.find((p: { id: string; entrada: string }) => p.id === ejemplo);
		if (p) { entrada = p.entrada; entradaCambiada = true; desactualizada = true; }
	}
	function cambioEntrada() { entradaCambiada = true; desactualizada = true; }
	function cambioMetadatos() { desactualizada = true; }
	function elegirAutor() {
		const autor = data.autores.find((a: { autor_id: string; nombre_completo: string }) => a.autor_id === autorId);
		if (autor) metadatos.autor_nombre = autor.nombre_completo;
		cambioMetadatos();
	}
	async function copiarPrompt() {
		try { await navigator.clipboard.writeText(data.referencia.prompt); copiado = true; errorCopia = false; }
		catch { errorCopia = true; }
	}
</script>

<svelte:head><title>Importador métrico · Versología</title></svelte:head>

<section class="mx-auto max-w-7xl space-y-7">
	<header class="space-y-2"><p class="text-xs uppercase tracking-wider text-[color:var(--muted-foreground)]">Fichas mínimas · ensayo</p><h1 class="font-display text-3xl">Importador métrico</h1><p class="max-w-3xl text-sm text-[color:var(--muted-foreground)]">Comprueba la transcripción de una sinopsis métrica y su correspondencia con nuestro catálogo. Puedes probar las cuatro obras del piloto o pegar una nueva extracción.</p></header>
	<p class="border-l-4 border-[color:var(--primary)] bg-white px-4 py-3 text-sm"><strong>Vista previa de prueba.</strong> Todavía no crea obras ni incorpora datos al corpus. Las reglas utilizan el catálogo de referencia del piloto. El ensayo está disponible para admin/IP; el acceso individual de importadores llegará con la integración del guardado.</p>

	<div class="card p-4 sm:p-6">
		<h2 class="font-display text-xl">1. Preparar la entrada</h2>
		<details class="mt-4 border-b border-[color:var(--border)] pb-4"><summary class="cursor-pointer text-sm font-medium">Prompt para pedir la extracción a una IA</summary><p class="mt-3 text-sm text-[color:var(--muted-foreground)]">Adjunta las fotografías y usa este prompt. Pega aquí el JSON que recibas. La identificación métrica se revisa después; la IA debe conservar las denominaciones literales.</p><button type="button" class="mt-3 border border-[color:var(--border)] px-3 py-2 text-sm hover:bg-[color:var(--muted)]" onclick={copiarPrompt}>{copiado ? 'Prompt copiado' : 'Copiar prompt'}</button>{#if errorCopia}<p role="status" class="mt-2 text-sm">No se pudo copiar automáticamente. Puedes seleccionar el texto siguiente.</p>{/if}<pre class="mt-3 max-h-80 overflow-auto whitespace-pre-wrap border border-[color:var(--border)] bg-[color:var(--muted)] p-4 text-xs">{data.referencia.prompt}</pre></details>
		<div class="mt-5 flex flex-wrap items-end gap-3"><label class="min-w-56 flex-1 text-sm">Obra del piloto<select class="mt-1 w-full border border-[color:var(--border)] bg-white p-2" bind:value={ejemplo}><option value="">Seleccionar ejemplo…</option>{#each data.pilotos as p}<option value={p.id}>{p.titulo}</option>{/each}</select></label><button type="button" class="border border-[color:var(--border)] px-4 py-2 text-sm hover:bg-[color:var(--muted)] disabled:opacity-50" disabled={!ejemplo || pendiente} onclick={cargarEjemplo}>Cargar ejemplo</button></div>
		<form method="POST" action="?/leer" use:enhance={enviar} class="mt-5 space-y-3">
			<label class="block text-sm font-medium" for="entrada-importador">Resultado de la IA (JSON)</label>
			<textarea id="entrada-importador" name="entrada" bind:value={entrada} oninput={cambioEntrada} rows="10" spellcheck="false" class="w-full border border-[color:var(--border)] bg-white p-3 font-mono text-xs" placeholder="Pega el JSON completo de una obra" required></textarea>
			<p class="text-xs text-[color:var(--muted-foreground)]">Se acepta extracción 0.1, ficha mínima 0.1 y vista previa del piloto. También un bloque JSON entre triple acento grave.</p>
			<button class="bg-[color:var(--foreground)] px-5 py-2.5 text-sm font-medium text-white disabled:opacity-50" disabled={pendiente || !entrada.trim()}>{pendiente ? 'Comprobando…' : 'Preparar vista previa'}</button>
		</form>
	</div>
	{#if form && 'mensaje' in form}<p role="alert" class="border border-red-200 bg-red-50 p-4 text-sm">{form.mensaje}</p>{/if}
	{#if respuestaDescartada}<p role="status" class="border border-amber-300 bg-amber-50 p-4 text-sm">Los datos cambiaron durante la comprobación. Conservamos tus cambios; vuelve a comprobarlos.</p>{/if}
	{#if vista && !entradaCambiada}
		<form method="POST" action="?/comprobar" use:enhance={enviar} class="card space-y-5 p-4 sm:p-6">
			<h2 class="font-display text-xl">2. Revisar los datos de la obra</h2>
			<p class="text-sm text-[color:var(--muted-foreground)]">Completa o corrige los metadatos y vuelve a comprobarlos. Las fechas son obligatorias; su fuente y los fundamentos de autoría pueden quedar vacíos.</p>
			<input type="hidden" name="entrada" value={entrada} />
			<div class="grid gap-4 sm:grid-cols-2">
				<label class="text-sm sm:col-span-2">Título<input class="mt-1 w-full border border-[color:var(--border)] p-2" name="titulo" bind:value={metadatos.titulo} oninput={cambioMetadatos} required /></label>
				<label class="text-sm">Autor del catálogo<select name="autor_id" bind:value={autorId} onchange={elegirAutor} class="mt-1 w-full border border-[color:var(--border)] bg-white p-2"><option value="">Pendiente de vincular</option>{#each data.autores as a}<option value={a.autor_id}>{a.nombre_completo}</option>{/each}</select></label>
				<label class="text-sm">Nombre del autor en la entrada<input name="autor_nombre" bind:value={metadatos.autor_nombre} oninput={cambioMetadatos} readonly={!!autorId} class="mt-1 w-full border border-[color:var(--border)] p-2 read-only:bg-[color:var(--muted)]" required /></label>
				<label class="text-sm">Género<select name="genero" bind:value={metadatos.genero} onchange={cambioMetadatos} required class="mt-1 w-full border border-[color:var(--border)] bg-white p-2">{#each data.generos as g}<option value={g.termino}>{g.etiqueta ?? g.termino.replaceAll('_',' ')}</option>{/each}</select></label>
				<div class="grid grid-cols-2 gap-3"><label class="text-sm">Fecha inicial<input name="fecha_inicio" type="number" min="1" step="1" bind:value={metadatos.fecha_inicio} oninput={cambioMetadatos} class="mt-1 w-full border border-[color:var(--border)] p-2" required /></label><label class="text-sm">Fecha final<input name="fecha_fin" type="number" min="1" step="1" bind:value={metadatos.fecha_fin} oninput={cambioMetadatos} class="mt-1 w-full border border-[color:var(--border)] p-2" required /></label></div>
				<label class="text-sm sm:col-span-2">Edición base<textarea name="edicion_base" bind:value={metadatos.edicion_base} oninput={cambioMetadatos} rows="3" class="mt-1 w-full border border-[color:var(--border)] p-2" required></textarea></label>
				<label class="text-sm">Fuente de datación <span class="text-[color:var(--muted-foreground)]">(opcional)</span><textarea name="fuente_fecha" bind:value={metadatos.fuente_fecha} oninput={cambioMetadatos} rows="3" class="mt-1 w-full border border-[color:var(--border)] p-2"></textarea></label>
				<label class="text-sm">Fundamentos de autoría <span class="text-[color:var(--muted-foreground)]">(opcional)</span><textarea name="fundamento_autoria" bind:value={metadatos.fundamento_autoria} oninput={cambioMetadatos} rows="3" class="mt-1 w-full border border-[color:var(--border)] p-2"></textarea></label>
			</div>
			{#if !autorId}<p class="text-sm text-[color:var(--muted-foreground)]">El nombre se conserva como lo has indicado. Antes del guardado habrá que vincularlo a un autor del catálogo; esta vista no lo elige automáticamente.</p>{/if}
			<button class="border border-[color:var(--foreground)] px-5 py-2.5 text-sm font-medium hover:bg-[color:var(--muted)] disabled:opacity-50" disabled={pendiente}>{pendiente ? 'Comprobando…' : 'Comprobar los datos revisados'}</button>
		</form>
	{/if}
	{#if coincidencias.length && !entradaCambiada}<aside class="border border-amber-300 bg-amber-50 p-4 text-sm"><h2 class="font-semibold">Ya hay obras con este título</h2><p class="mt-1">Comprueba si se trata de la misma obra antes de importarla. Esta coincidencia no modifica ninguna ficha.</p><ul class="mt-2 list-disc pl-5">{#each coincidencias as c}<li><a class="underline" href={`/dashboard/obras/${c.obra_id}`}>{c.titulo}</a></li>{/each}</ul></aside>{/if}
	{#if vista}<VistaPrevia {vista} {desactualizada} />{/if}
</section>

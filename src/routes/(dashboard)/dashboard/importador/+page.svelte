<script lang="ts">
	import { tick, untrack } from 'svelte';
	import type { EdicionFila } from '$lib/importador-metrico/edicion';
	import { enhance } from '$app/forms';
	import type { SubmitFunction } from '@sveltejs/kit';
	import type { ActionData, PageData } from './$types';
	import type { MetadatosEditables, ResultadoVistaPrevia, IncidenciaImportador } from '$lib/importador-metrico/types';
	import VistaPrevia from '$lib/components/importador-metrico/VistaPrevia.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import EstadoComprobacion from '$lib/components/importador-metrico/EstadoComprobacion.svelte';
	import DatosEjecucion from '$lib/components/importador-metrico/DatosEjecucion.svelte';

	let { data, form } = $props<{ data: PageData; form: ActionData }>();
	const accion=(nombre:string)=>data.obraDestino?'?obra='+data.obraDestino.obra_id+'&/'+nombre:'?/'+nombre;
	const respuesta = () => form && 'vista' in form ? form : null;
	let ultimaRespuesta = $state(untrack(respuesta));
	const vacios: MetadatosEditables = { titulo:'',autor_nombre:'',genero:'comedia_o_tragicomedia',edicion_base:'',fecha_inicio:'',fecha_fin:'',fuente_fecha:'',fundamento_autoria:'',ia_generador:'',ia_modelo:'',ia_modo:'',ia_plan:'',ia_parametros:'' };
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
	let comprobacionTerminada = $state(untrack(() => {
		const r = respuesta(); return Boolean(r && 'comprobacion_realizada' in r && r.comprobacion_realizada);
	}));
	let ediciones = $state(untrack(() => respuesta()?.ediciones ?? '[]'));
	let edicionesComprobadas = $state(untrack(() => respuesta()?.vista.errores.length ? '[]' : respuesta()?.ediciones ?? '[]'));
	let vistaComprobada = $state<ResultadoVistaPrevia | null>(untrack(() => respuesta()?.vista.errores.length ? null : respuesta()?.vista ?? null));
	let formComprobacion = $state<HTMLFormElement>();
	let peticionId = $state(untrack(()=>data.peticionId));
	let otraObra = $state(false);
	function descartarImportacion() {
		ultimaRespuesta=null; vistaComprobada=null; entrada=''; autorId=''; ediciones='[]';
		metadatos={...vacios}; otraObra=false; entradaCambiada=false; desactualizada=false;
		comprobacionTerminada=false;
		peticionId=crypto.randomUUID();
	}
	const vista = $derived(!entradaCambiada && ultimaRespuesta?.entrada === entrada ? ultimaRespuesta.vista : null);
	const coincidencias = $derived(ultimaRespuesta?.coincidencias ?? []);
	$effect(() => {
		const r = respuesta();
		if (r) {
			comprobacionTerminada = 'comprobacion_realizada' in r && r.comprobacion_realizada === true;
			if(r.huella !== untrack(()=>ultimaRespuesta?.huella)) otraObra=false;
			const anterior = untrack(() => ultimaRespuesta?.entrada === r.entrada ? vistaComprobada : null);
			if (!r.vista.errores.length) {
				vistaComprobada = r.vista;
				edicionesComprobadas = r.ediciones ?? '[]';
			} else if (!anterior) {
				vistaComprobada = null;
				edicionesComprobadas = '[]';
			}
			ultimaRespuesta = r.vista.errores.length && anterior ? {
				...r, vista: { ...r.vista, datos: anterior.datos, filas: anterior.filas, resumen: anterior.resumen }
			} : r;
			ediciones = untrack(() => edicionesComprobadas);
			entrada = r.entrada;
			metadatos = { ...r.vista.metadatos };
			autorId = r.autorId || untrack(() => reconocerAutor(r.vista.metadatos.autor_nombre));
			entradaCambiada = false;
			desactualizada = r.vista.errores.length > 0;
		}
	});
	const enviar: SubmitFunction = () => {
		comprobacionTerminada = false;
		const enviados = JSON.stringify([entrada, metadatos, autorId, ediciones]);
		respuestaDescartada = false;
		pendiente = true;
		return async ({ update }) => {
			try {
				if (JSON.stringify([entrada, metadatos, autorId, ediciones]) !== enviados) {
					respuestaDescartada = true;
					desactualizada = true;
					return;
				}
				await update({ reset:false, invalidateAll:false });
				if (!respuesta()) { ultimaRespuesta = null; vistaComprobada = null; }
				entradaCambiada = false;
			} finally { pendiente = false; }
		};
	};
	function cargarEjemplo() {
		const p = data.pilotos.find((p: { id: string; entrada: string }) => p.id === ejemplo);
		if (p) { entrada = p.entrada; cambioEntrada(); }
	}
	function cambioEntrada() { entradaCambiada = true; desactualizada = false; respuestaDescartada = false; comprobacionTerminada = false; }
	function cambioMetadatos() { desactualizada = true; comprobacionTerminada = false; }
	function cancelarEdicion() {
		comprobacionTerminada = false;
		if (!ultimaRespuesta) return;
		ultimaRespuesta = { ...ultimaRespuesta, vista: { ...ultimaRespuesta.vista,
			errores: ultimaRespuesta.vista.errores.filter((e: IncidenciaImportador) => e.codigo !== 'edicion') } };
		desactualizada = !vistaComprobada || JSON.stringify(metadatos) !== JSON.stringify(vistaComprobada.metadatos) || ultimaRespuesta.vista.errores.length > 0;
	}
	async function editarSecuencias(tramo: string, cambio: EdicionFila | null) {
		if (pendiente || entradaCambiada) return;
		comprobacionTerminada = false;
		let anteriores: EdicionFila[] = [];
		try { anteriores = JSON.parse(ediciones); } catch { /* Se conserva el error del servidor hasta corregirlo. */ }
		ediciones = JSON.stringify([...anteriores.filter((e) => e.tramo_ref !== tramo), ...(cambio ? [cambio] : [])]);
		desactualizada = true;
		await tick();
		formComprobacion?.requestSubmit();
	}
	function reconocerAutor(nombre: string) {
		const normalizar = (texto: string) => texto.normalize('NFD').replace(/\p{M}/gu, '').toLowerCase().trim();
		const candidatos = data.autores.filter((a: { nombre_completo: string }) => normalizar(a.nombre_completo) === normalizar(nombre));
		return candidatos.length === 1 ? candidatos[0].autor_id : '';
	}
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

<section class="mx-auto max-w-7xl space-y-6">
	<header class="flex flex-wrap items-baseline justify-between gap-3">
		<h1 class="font-display text-3xl">Importador métrico</h1>
		{#if data.guardadoDisponible}<a href="/dashboard/importador/fichas" class="text-sm underline">Fichas básicas</a>{/if}
	</header>
	<div class="card space-y-4 p-4 sm:p-6">
		<div class="flex flex-wrap items-center justify-between gap-3">
			<h2 class="text-lg font-semibold">1. Entrada</h2>
			<span class="form-label-with-help">
				{#if data.referencia.prompt_version}<span class="text-xs text-[color:var(--muted-foreground)]">Prompt v{data.referencia.prompt_version}</span>{/if}
				<button type="button" class="rounded-md border border-[color:var(--border)] px-3 py-2 text-sm hover:bg-[color:var(--muted)]" onclick={copiarPrompt}>{copiado ? 'Prompt copiado' : 'Copiar prompt'}</button>
				<FieldHelpTooltip label="Cómo obtener la transcripción" text="Adjunta las fotografías a una IA y utiliza este prompt. Pega aquí el JSON que recibas." />
			</span>
		</div>
		{#if errorCopia}
			<label class="form-field"><span class="form-label">Prompt para copiar</span><textarea readonly rows="5" class="w-full rounded-md border border-[color:var(--border)] p-3 text-xs" value={data.referencia.prompt}></textarea></label>
		{/if}
		<div class="flex flex-wrap items-end gap-3">
			<label class="form-field min-w-56 flex-1">
				<span class="form-label">Ejemplo del piloto</span>
				<select class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2" bind:value={ejemplo}>
					<option value="">Seleccionar ejemplo</option>
					{#each data.pilotos as p}<option value={p.id}>{p.titulo}</option>{/each}
				</select>
			</label>
			<button type="button" class="rounded-md border border-[color:var(--border)] px-4 py-2 text-sm hover:bg-[color:var(--muted)] disabled:opacity-50" disabled={!ejemplo || pendiente} onclick={cargarEjemplo}>Cargar ejemplo</button>
		</div>
		<form method="POST" action={accion('leer')} use:enhance={enviar} class="space-y-3">
			<input type="hidden" name="obra_id" value={data.obraDestino?.obra_id ?? ''} />
			{#if data.obraDestino}<p>Importación para <strong>{data.obraDestino.titulo}</strong>. Se conservarán sus metadatos vigentes y se completarán los vacíos; la edición y los datos de la fuente quedarán en la importación.</p>{/if}
			<label class="form-field" for="entrada-importador"><span class="form-label">Transcripción (JSON) <span class="required" aria-label="obligatorio">*</span></span></label>
			<textarea id="entrada-importador" name="entrada" bind:value={entrada} oninput={cambioEntrada} rows="6" spellcheck="false" class="w-full rounded-md border border-[color:var(--border)] bg-white p-3 font-mono text-xs" placeholder="Pega la transcripción de una obra" required></textarea>
			<button class="rounded-md bg-[color:var(--foreground)] px-5 py-2.5 text-sm font-medium text-white disabled:opacity-50" disabled={pendiente || !entrada.trim()}>{pendiente ? 'Preparando…' : 'Preparar importación'}</button>
		</form>
	</div>
	{#if !entradaCambiada && form && 'mensaje' in form}<p role="alert" class="border border-red-200 bg-red-50 p-3 text-sm">{form.mensaje}</p>{/if}
	{#if respuestaDescartada && !entradaCambiada}<p role="status" class="border-l-2 border-amber-400 bg-amber-50 p-3 text-sm">Datos modificados durante el envío. Vuelve a comprobarlos.</p>{/if}
	{#if vista && !entradaCambiada}
		<form bind:this={formComprobacion} method="POST" action={accion('comprobar')} use:enhance={enviar} novalidate class="card space-y-4 p-4 sm:p-6">
			<input type="hidden" name="obra_id" value={data.obraDestino?.obra_id ?? ''} />
			<h2 class="text-lg font-semibold">2. Datos de la obra</h2>
			<input type="hidden" name="entrada" value={entrada} />
			<input type="hidden" name="ediciones" value={ediciones} />
			<input type="hidden" name="autor_nombre" value={metadatos.autor_nombre} />
			<div class="grid gap-4 sm:grid-cols-2">
				<label class="form-field sm:col-span-2">
					<span class="form-label">Título <span class="required" aria-label="obligatorio">*</span></span>
					<input class="w-full rounded-md border border-[color:var(--border)] px-3 py-2" name="titulo" bind:value={metadatos.titulo} oninput={cambioMetadatos} required />
				</label>
				<label class="form-field">
					<span class="form-label">Autor <span class="required" aria-label="obligatorio">*</span></span>
					<select name="autor_id" bind:value={autorId} onchange={elegirAutor} class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2" required>
						<option value="">{metadatos.autor_nombre ? metadatos.autor_nombre + ' — seleccionar autor' : 'Seleccionar autor'}</option>
						{#each data.autores as a}<option value={a.autor_id}>{a.nombre_completo}</option>{/each}
					</select>
				</label>
				<label class="form-field">
					<span class="form-label">Género <span class="required" aria-label="obligatorio">*</span></span>
					<select name="genero" bind:value={metadatos.genero} onchange={cambioMetadatos} required class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2">
						<option value="">Seleccionar género</option>
						{#each data.generos as g}<option value={g.termino}>{g.etiqueta ?? g.termino.replaceAll('_',' ')}</option>{/each}
					</select>
				</label>
				<label class="form-field">
					<span class="form-label">Fecha inicial <span class="required" aria-label="obligatorio">*</span></span>
					<input name="fecha_inicio" type="number" min="1" step="1" bind:value={metadatos.fecha_inicio} oninput={cambioMetadatos} class="w-full rounded-md border border-[color:var(--border)] px-3 py-2" required />
				</label>
				<label class="form-field">
					<span class="form-label">Fecha final <span class="required" aria-label="obligatorio">*</span></span>
					<input name="fecha_fin" type="number" min="1" step="1" bind:value={metadatos.fecha_fin} oninput={cambioMetadatos} class="w-full rounded-md border border-[color:var(--border)] px-3 py-2" required />
				</label>
				<label class="form-field sm:col-span-2">
					<span class="form-label">Edición base <span class="required" aria-label="obligatorio">*</span></span>
					<textarea name="edicion_base" bind:value={metadatos.edicion_base} oninput={cambioMetadatos} rows="3" class="w-full rounded-md border border-[color:var(--border)] px-3 py-2" required></textarea>
				</label>
				<label class="form-field">
					<span class="form-label">Fuente de datación <span class="font-normal">(opcional)</span></span>
					<textarea name="fuente_fecha" bind:value={metadatos.fuente_fecha} oninput={cambioMetadatos} rows="3" class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"></textarea>
				</label>
				<label class="form-field">
					<span class="form-label">Fundamentos de autoría <span class="font-normal">(opcional)</span></span>
					<textarea name="fundamento_autoria" bind:value={metadatos.fundamento_autoria} oninput={cambioMetadatos} rows="3" class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"></textarea>
				</label>
			</div>
			<DatosEjecucion bind:metadatos alCambiar={cambioMetadatos} />
			<div class="flex flex-wrap items-center gap-3">
				<button class="rounded-md border border-[color:var(--foreground)] px-5 py-2.5 text-sm font-medium hover:bg-[color:var(--muted)] disabled:opacity-50" disabled={pendiente}>{pendiente ? 'Comprobando…' : 'Comprobar cambios'}</button>
				{#if !pendiente && comprobacionTerminada}
					<EstadoComprobacion {vista} />
				{:else if !pendiente && desactualizada && vista.datos}
					<p role="status" class="border-l-2 border-amber-400 bg-amber-50 px-3 py-2 text-sm">Cambios sin comprobar.</p>
				{/if}
			</div>
		</form>
	{/if}
	{#if coincidencias.length && !entradaCambiada}
		<aside class="border-l-2 border-amber-400 bg-amber-50 p-3 text-sm">
			<h2 class="font-semibold">Posibles coincidencias</h2>
			<ul class="mt-1 list-disc pl-5">{#each coincidencias as c}<li>{c.titulo} · {c.autores.join(', ') || 'Autoría no indicada'} · {['minima','basica'].includes(c.tipo_ficha)?'Básica':c.tipo_ficha==='sin_ficha'?'Sin ficha':'Completa'}</li>{/each}</ul>
		</aside>
	{/if}
	{#if vista}<VistaPrevia {vista} {desactualizada} formas={data.referencia.formas} ocupado={pendiente} editable={!entradaCambiada} oneditar={editarSecuencias} oncancelar={cancelarEdicion} />{/if}
	{#if vista?.datos && vista.pendientes_metadatos?.length}
		<p role="status" class="text-sm text-[color:var(--muted-foreground)]">Completa los datos obligatorios de la obra para guardar.</p>
	{/if}
	{#if vista?.datos && !vista.errores.length && !vista.pendientes_metadatos?.length}
		<section class="card space-y-3 p-4 sm:p-6">
			<h2 class="text-lg font-semibold">Confirmar importación</h2>
			{#if !data.guardadoDisponible}
				<p class="text-sm text-[color:var(--muted-foreground)]">El guardado aún no está habilitado en esta base.</p>
			{:else}
				<form method="POST" action={accion('confirmar')} use:enhance={enviar} class="space-y-3">
					<input type="hidden" name="obra_id" value={data.obraDestino?.obra_id ?? ''} />
					<input type="hidden" name="entrada" value={entrada} />
					<input type="hidden" name="autor_id" value={autorId} />
					<input type="hidden" name="ediciones" value={ediciones} />
					<input type="hidden" name="peticion_id" value={peticionId} />
					<input type="hidden" name="huella" value={ultimaRespuesta?.huella ?? ''} />
					{#each Object.entries(metadatos) as [nombre,valor]}<input type="hidden" name={nombre} value={valor} />{/each}
					{#if coincidencias.length && !data.obraDestino}
						<label class="flex items-start gap-2 text-sm"><input type="checkbox" name="decision_coincidencias" value="otra_obra" bind:checked={otraObra} />He revisado las coincidencias: es otra obra.</label>
						<button type="button" onclick={descartarImportacion} class="rounded-md border px-3 py-2 text-sm" disabled={pendiente}>Es la misma obra: descartar importación</button>
					{/if}
					<button class="rounded-md bg-[color:var(--foreground)] px-5 py-2.5 text-sm font-medium text-[color:var(--background)] disabled:opacity-50" disabled={pendiente || desactualizada || entradaCambiada || !ultimaRespuesta?.huella || (coincidencias.length>0 && !otraObra && !data.obraDestino)}>Guardar ficha básica</button>
					{#if !ultimaRespuesta?.huella || desactualizada || entradaCambiada}<p class="text-sm">Comprueba los cambios antes de guardar.</p>{/if}
				</form>
			{/if}
		</section>
	{/if}
</section>

<style>
	.required { color: var(--danger); font-weight: 400; }
</style>

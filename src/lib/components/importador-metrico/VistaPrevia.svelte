<script lang="ts">
	import type { ResultadoVistaPrevia, FilaVistaPrevia } from '$lib/importador-metrico/types';
	let { vista, desactualizada = false } = $props<{ vista: ResultadoVistaPrevia; desactualizada?: boolean }>();
	let filtro = $state('todos');
	const filas = $derived<FilaVistaPrevia[]>(vista.filas.filter((f: FilaVistaPrevia) => filtro === 'todos' || (filtro === 'identificadas' && f.estado === 'revisada') || (filtro === 'pendientes' && f.estado !== 'revisada') || (filtro === 'desviaciones' && f.desviaciones.length > 0)));
	const etiquetas = { revisada: 'Identificación revisada', propuesta: 'Propuesta', candidatas: 'Varias posibilidades', sin_resolver: 'Forma sin resolver' };
	const numero = (n: number) => new Intl.NumberFormat('es-ES').format(n);
	const nombre = (v: unknown) => String(v ?? '').replaceAll('_', ' ');
</script>

<section class="space-y-5" aria-label="Vista previa métrica">
	<header class="flex flex-wrap items-end justify-between gap-3">
		<div><p class="text-xs uppercase tracking-wider text-[color:var(--muted-foreground)]">Revisión de la declaración métrica</p><h2 class="font-display text-2xl">Vista previa</h2></div>
		<span class="border border-[color:var(--border)] bg-white px-3 py-1 text-xs">Sin guardar</span>
	</header>
	{#if desactualizada}<p role="status" class="border border-amber-300 bg-amber-50 p-3 text-sm">Has cambiado los datos. Vuelve a comprobarlos; esta vista corresponde a la comprobación anterior.</p>{/if}
	{#if vista.errores.length}
		<div role="alert" class="border border-red-200 bg-red-50 p-4"><h3 class="font-semibold">Hay datos que corregir</h3><ul class="mt-2 list-disc space-y-1 pl-5 text-sm">{#each vista.errores as e}<li>{e.mensaje}{#if e.ruta}<span class="text-xs text-[color:var(--muted-foreground)]"> · {e.ruta}</span>{/if}</li>{/each}</ul></div>
	{/if}
	{#if vista.resumen && vista.datos}
		<div class:opacity-60={desactualizada} class="grid gap-3 sm:grid-cols-4">
			<div class="card p-4"><p class="text-xs text-[color:var(--muted-foreground)]">Posiciones numeradas</p><p class="mt-1 text-2xl font-semibold">{numero(vista.resumen.extension)}</p></div>
			<div class="card p-4"><p class="text-xs text-[color:var(--muted-foreground)]">Jornadas / bloques</p><p class="mt-1 text-2xl font-semibold">{vista.resumen.jornadas} / {vista.resumen.bloques}</p></div>
			<div class="card p-4"><p class="text-xs text-[color:var(--muted-foreground)]">Con forma identificada</p><p class="mt-1 text-2xl font-semibold">{numero(vista.resumen.forma_identificada)}</p></div>
			<div class="card p-4"><p class="text-xs text-[color:var(--muted-foreground)]">Forma pendiente</p><p class="mt-1 text-2xl font-semibold">{numero(vista.resumen.forma_pendiente)}</p></div>
		</div>
		<p class="text-sm text-[color:var(--muted-foreground)]">Las propuestas y candidatas no cuentan como identificaciones. Las posiciones sin forma resuelta permanecen en el total. {#if !vista.resumen.segmentacion_confirmada}Hay bloques con segmentación provisional: todavía no equivalen a secuencias confirmadas.{/if}</p>
		<div class="card p-4"><h3 class="font-semibold">Jornadas</h3><ul class="mt-3 flex flex-wrap gap-3 text-sm">{#each vista.datos.jornadas as j}<li class="border border-[color:var(--border)] px-3 py-2"><strong>Jornada {j.numero}</strong> · vv. {j.v_ini}–{j.v_fin}</li>{/each}</ul></div>
		<div class="flex flex-wrap items-center justify-between gap-3"><h3 class="font-semibold">Bloques de la edición</h3><label class="flex items-center gap-2 text-sm">Mostrar<select class="border border-[color:var(--border)] bg-white p-2" bind:value={filtro}><option value="todos">Todos ({vista.filas.length})</option><option value="identificadas">Forma identificada</option><option value="pendientes">Forma pendiente</option><option value="desviaciones">Con desviaciones</option></select></label></div>
		<div class="overflow-x-auto border border-[color:var(--border)] bg-white">
			<table class="w-full min-w-[800px] table-fixed break-words text-left text-sm"><caption class="sr-only">Rangos y propuestas métricas de la importación</caption><colgroup><col class="w-[14%]" /><col class="w-[23%]" /><col class="w-[23%]" /><col class="w-[40%]" /></colgroup><thead class="bg-[color:var(--muted)] text-xs"><tr><th class="p-3">Jornada / versos</th><th class="p-3">Declaración de la edición</th><th class="p-3">Correspondencia</th><th class="p-3">Detalle y procedencia</th></tr></thead><tbody>
			{#each filas as fila (fila.ref)}
				<tr class="border-t border-[color:var(--border)] align-top">
					<td class="p-3"><p class="font-medium">Jornada {fila.jornada ?? '—'}</p><p class="mt-1 whitespace-nowrap">{fila.v_ini}–{fila.v_fin}</p><p class="mt-1 text-xs text-[color:var(--muted-foreground)]">{fila.extension} posiciones</p><p class="mt-1 text-xs">{fila.segmentacion === 'confirmada' ? 'Segmentación confirmada' : 'Segmentación provisional'}</p></td>
					<td class="p-3"><p class="font-medium">{fila.origen.denominacion_literal ?? 'Sin denominación'}</p><p class="mt-2 text-xs text-[color:var(--muted-foreground)]">{fila.origen.fuente_id}{#if fila.origen.pagina}{' · p. '}{fila.origen.pagina}{/if}</p></td>
					<td class="p-3"><span class="inline-block border border-[color:var(--border)] px-2 py-1 text-xs">{etiquetas[fila.estado]}</span><p class="mt-2 font-medium">{fila.forma_revisada ?? fila.propuesta_nombre ?? (fila.candidatas_nombres.length ? fila.candidatas_nombres.join(' / ') : 'Pendiente de identificar')}</p>{#if fila.identificacion_revisada}<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">{fila.identificacion_revisada.arquitectura_slug ? nombre(fila.identificacion_revisada.arquitectura_slug) : 'Arquitectura sin determinar'}</p>{/if}{#if fila.exhaustividad}<p class="mt-1 text-xs">Candidatas: {nombre(fila.exhaustividad)}</p>{/if}</td>
					<td class="max-w-md p-3"><details><summary class="cursor-pointer underline underline-offset-2">Ver fuente y criterio{#if fila.desviaciones.length}{' · '}{fila.desviaciones.length} {fila.desviaciones.length === 1 ? 'desviación' : 'desviaciones'}{/if}</summary><p class="mt-3">{fila.fundamento}</p>
{#each fila.notas_fuente ?? [] as nota}
<blockquote class="mt-3 border-l-2 border-[color:var(--border)] pl-3 text-sm"><p class="text-xs font-medium">Nota de la edición · {nota.id}</p><p class="mt-1">{nota.texto_literal}</p></blockquote>
{/each}{#each fila.detalles_fuente as d}<p class="mt-2"><strong>{d.tipo_seccion === 'remate' ? 'Remate' : d.estado === 'interpretacion_revisada' ? 'Detalle revisado' : 'Detalle pendiente'}:</strong> {nombre(d.literal)}{#if d.n_versos}{' · '}{nombre(d.n_versos)} versos{/if}{#if d.posicion}{' · '}{nombre(d.posicion)}{/if}</p>{/each}{#each fila.desviaciones as d}<p class="mt-2 border-l-2 border-amber-400 pl-2"><strong>Desviación {nombre(d.dimension)} · {nombre(d.relacion_norma)}</strong><br />vv. {nombre(d.v_ini)}–{nombre(d.v_fin)}: {nombre(d.texto_fuente)}<br /><span class="text-xs text-[color:var(--muted-foreground)]">{nombre(d.fundamento)}</span></p>{/each}{#if fila.aprobacion}<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">Revisión declarada: {fila.aprobacion.responsable} · {fila.aprobacion.fecha}. {fila.aprobacion.fundamento}</p>{/if}<p class="mt-2 text-xs text-[color:var(--muted-foreground)]">Fila {fila.origen.tramo_ref}{#if fila.origen.notas_ref.length}{' · notas '}{fila.origen.notas_ref.join(', ')}{/if}</p></details></td>
				</tr>
			{/each}
			{#if !filas.length}<tr><td colspan="4" class="p-5 text-[color:var(--muted-foreground)]">No hay bloques con este filtro.</td></tr>{/if}
			</tbody></table>
		</div>
	{/if}
	{#if vista.avisos.length}<details class="card p-4"><summary class="cursor-pointer font-medium">Criterios y advertencias ({vista.avisos.length})</summary><ul class="mt-3 list-disc space-y-2 pl-5 text-sm text-[color:var(--muted-foreground)]">{#each vista.avisos as a}<li>{a.mensaje}</li>{/each}</ul></details>{/if}
</section>

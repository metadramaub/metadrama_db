<script lang="ts">
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import type { ResultadoVistaPrevia, FilaVistaPrevia, FichaMinima } from '$lib/importador-metrico/types';

	let { vista, desactualizada = false } = $props<{ vista: ResultadoVistaPrevia; desactualizada?: boolean }>();
	let filtro = $state('todos');
	const etiquetas = { revisada: 'Revisada', propuesta: 'Propuesta', candidatas: 'Por resolver', sin_resolver: 'Sin identificar' };
	const filas = $derived<FilaVistaPrevia[]>(vista.filas.filter((f: FilaVistaPrevia) =>
		filtro === 'todos' || (filtro === 'revisadas' && f.estado === 'revisada') ||
		(filtro === 'pendientes' && f.estado !== 'revisada') ||
		(filtro === 'desviaciones' && f.desviaciones.length > 0)));
	const jornadas = $derived<Array<FichaMinima['jornadas'][number] & { filas: FilaVistaPrevia[] }>>((vista.datos?.jornadas ?? []).map((j: FichaMinima['jornadas'][number]) => ({
		...j, filas: filas.filter((f: FilaVistaPrevia) => f.jornada === j.numero)
	})));
	const numero = (n: number) => new Intl.NumberFormat('es-ES').format(n);
	const fuente = (id: string | null) => (id ?? '').replace(/^foto-/, 'Foto ');
	function detalle(d: Record<string, unknown>, fila: FilaVistaPrevia) {
		if (d.tipo_seccion === 'remate' && d.n_versos === 1 && fila.identificacion_revisada?.forma_slug === 'terceto_encadenado') return 'Remate final de 1 verso (3+1)';
		if (d.tipo_seccion === 'remate') return 'Remate: ' + String(d.literal) +
			(d.n_versos ? ' · ' + String(d.n_versos) + (d.n_versos === 1 ? ' verso' : ' versos') : '');
		if (d.dimension === 'asonancia') return 'Asonancia: ' + String(d.literal);
		return String(d.literal ?? '');
	}
	function desviacion(d: Record<string, unknown>) {
		const versos = d.v_ini === d.v_fin ? 'v. ' + String(d.v_ini) : 'vv. ' + String(d.v_ini) + '–' + String(d.v_fin);
		if (d.dimension === 'estructura') return versos + ': ' + (d.relacion_norma === 'sobra' ? 'verso añadido' : d.relacion_norma === 'falta' ? 'verso ausente' : 'desviación estructural');
		return versos + ': ' + (d.metro_observado_slug ? String(d.metro_observado_slug).replaceAll('_', ' ') : 'desviación de medida');
	}
</script>

<section class="space-y-4" aria-label="Vista previa métrica">
	<header class="flex flex-wrap items-center justify-between gap-3">
		<h2 class="text-lg font-semibold">Esquema métrico</h2>
		<span class="text-xs text-[color:var(--muted-foreground)]">Vista previa · sin guardar</span>
	</header>
	{#if desactualizada}
		<p role="status" class="border-l-2 border-amber-400 bg-amber-50 px-3 py-2 text-sm">Cambios sin comprobar.</p>
	{/if}
	{#if vista.errores.length}
		<div role="alert" class="border border-red-200 bg-red-50 p-4 text-sm">
			<ul class="list-disc space-y-1 pl-5">
				{#each vista.errores as e}<li>{e.mensaje}</li>{/each}
			</ul>
		</div>
	{/if}
	{#if vista.resumen && vista.datos}
		<div class:opacity-60={desactualizada} class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
			<div class="card p-4">
				<p class="form-label"><span class="form-label-with-help">Versos
					<FieldHelpTooltip label="Cómo se cuentan los versos" text="Total según la numeración de la edición. Incluye las lagunas que ya estén numeradas." />
				</span></p>
				<p class="text-2xl font-semibold">{numero(vista.resumen.extension)}</p>
			</div>
			<div class="card p-4">
				<p class="form-label"><span class="form-label-with-help">Tramos métricos
					<FieldHelpTooltip label="Qué es un tramo métrico" text="Cada rango de versos de la tabla de la edición. Al revisarlo puede cambiar su división en secuencias." />
				</span></p>
				<p class="text-2xl font-semibold">{vista.resumen.bloques}</p>
			</div>
			<div class="card p-4">
				<p class="form-label">Versos con forma revisada</p>
				<p class="text-2xl font-semibold">{numero(vista.resumen.forma_identificada)}</p>
			</div>
			<div class="card p-4">
				<p class="form-label"><span class="form-label-with-help">Versos por revisar
					<FieldHelpTooltip label="Qué versos quedan por revisar" text="Incluye los versos con una propuesta aún no aceptada y aquellos cuya forma sigue sin resolver." />
				</span></p>
				<p class="text-2xl font-semibold">{numero(vista.resumen.forma_pendiente)}</p>
			</div>
		</div>
		<div class="flex justify-end">
			<label class="flex items-center gap-2 text-sm">Mostrar
				<select class="rounded-md border border-[color:var(--border)] bg-white px-3 py-2" bind:value={filtro}>
					<option value="todos">Todos los tramos</option>
					<option value="revisadas">Forma revisada</option>
					<option value="pendientes">Por revisar</option>
					<option value="desviaciones">Con desviaciones</option>
				</select>
			</label>
		</div>
		{#each jornadas as jornada (jornada.numero)}
			{#if jornada.filas.length}
				<section class="space-y-2" aria-label={'Jornada ' + jornada.numero}>
					<header class="flex items-baseline justify-between gap-3">
						<h3 class="font-semibold">Jornada {jornada.numero}</h3>
						<span class="text-xs text-[color:var(--muted-foreground)]">vv. {jornada.v_ini}–{jornada.v_fin}</span>
					</header>
					<div class="overflow-x-auto border border-[color:var(--border)] bg-white">
						<table class="w-full min-w-[780px] table-fixed text-left text-sm">
							<caption class="sr-only">Esquema métrico de la jornada {jornada.numero}</caption>
							<colgroup><col class="w-[11%]" /><col class="w-[8%]" /><col class="w-[22%]" /><col class="w-[24%]" /><col class="w-[25%]" /><col class="w-[10%]" /></colgroup>
							<thead class="bg-[color:var(--muted)] text-xs text-[color:var(--muted-foreground)]">
								<tr><th class="px-3 py-3">Versos</th><th class="px-3 py-3">N.º versos</th><th class="px-3 py-3">En la edición</th><th class="px-3 py-3">Forma en Versología</th><th class="px-3 py-3">Detalles y notas</th><th class="px-3 py-3">Fuente</th></tr>
							</thead>
							<tbody>
								{#each jornada.filas as fila (fila.ref)}
									<tr class="border-t border-[color:var(--border)] align-top">
										<td class="px-3 py-3 tabular-nums">{fila.v_ini}–{fila.v_fin}</td>
										<td class="px-3 py-3 tabular-nums">{fila.extension}</td>
										<td class="break-words px-3 py-3">{fila.origen.denominacion_literal ?? '—'}</td>
										<td class="break-words px-3 py-3">
											<p class="font-medium">{fila.forma_revisada ?? fila.propuesta_nombre ?? (fila.candidatas_nombres.length ? fila.candidatas_nombres.join(' / ') : 'Sin identificar')}</p>
											<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">{etiquetas[fila.estado]}</p>
											{#if fila.identificacion_revisada && !fila.identificacion_revisada.arquitectura_slug}
												<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">Arquitectura sin determinar</p>
											{:else if fila.identificacion_revisada?.arquitectura_slug}
												<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">{fila.identificacion_revisada.arquitectura_slug.replaceAll('_', ' ')}</p>
											{/if}
										</td>
										<td class="break-words px-3 py-3">
											{#each fila.detalles_fuente as d}<p class="mb-1">{detalle(d, fila)}</p>{/each}
											{#each fila.desviaciones as d}<p class="mb-1 font-medium">{desviacion(d)}</p>{/each}
											{#each fila.notas_fuente ?? [] as nota}<p class="mb-1 text-xs text-[color:var(--muted-foreground)]">{nota.texto_literal}</p>{/each}
											{#if !fila.detalles_fuente.length && !fila.desviaciones.length && !fila.notas_fuente?.length}<span class="text-[color:var(--muted-foreground)]">—</span>{/if}
										</td>
										<td class="px-3 py-3 text-xs text-[color:var(--muted-foreground)]">
											{fuente(fila.origen.fuente_id)}
											{#if fila.origen.pagina}<p class="mt-1">p. {fila.origen.pagina}</p>{/if}
										</td>
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				</section>
			{/if}
		{/each}
		{#if !filas.length}<p class="card p-4 text-sm text-[color:var(--muted-foreground)]">No hay tramos con este filtro.</p>{/if}
	{/if}
</section>

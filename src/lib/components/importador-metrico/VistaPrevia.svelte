<script lang="ts">
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import Pencil from 'lucide-svelte/icons/pencil';
	import EditorSecuencia from './EditorSecuencia.svelte';
	import type { EdicionFila, FormaEditable } from '$lib/importador-metrico/edicion';
	import type { ResultadoVistaPrevia, FilaVistaPrevia, FichaMinima } from '$lib/importador-metrico/types';
	import { rasgosImportador } from '$lib/importador-metrico/catalogo';

	let { vista, desactualizada = false, formas = [], ocupado = false, editable = false, oneditar, oncancelar } = $props<{
		vista: ResultadoVistaPrevia; desactualizada?: boolean; formas?: FormaEditable[]; ocupado?: boolean;
		editable?: boolean; oneditar?: (tramo: string, cambio: EdicionFila | null) => void;
		oncancelar?: () => void;
	}>();
	let editando = $state<string | null>(null);
	let enviada = $state<ResultadoVistaPrevia | null>(null);
	$effect(() => {
		if (enviada && vista !== enviada) {
			if (!vista.errores.length) editando = null;
			enviada = null;
		}
	});
	function aplicar(tramo: string, cambio: EdicionFila | null) {
		enviada = vista; oneditar?.(tramo, cambio);
	}
	let filtro = $state('todos');
	const sinEquivalencia = (f: FilaVistaPrevia) => !f.identificacion;
	const filas = $derived<FilaVistaPrevia[]>(vista.filas.filter((f: FilaVistaPrevia) =>
		filtro === 'todos' || (filtro === 'sin_resolver' && sinEquivalencia(f)) ||
		(filtro === 'desviaciones' && f.desviaciones.length > 0)));
	const jornadas = $derived<Array<FichaMinima['jornadas'][number] & { filas: FilaVistaPrevia[] }>>((vista.datos?.jornadas ?? []).map((j: FichaMinima['jornadas'][number]) => ({
		...j, filas: filas.filter((f: FilaVistaPrevia) => f.jornada === j.numero)
	})));
	const numero = (n: number) => new Intl.NumberFormat('es-ES').format(n);
	const fuente = (id: string | null) => (id ?? '').replace(/^foto-/, 'Foto ');
	function detalle(d: Record<string, unknown>, fila: FilaVistaPrevia) {
		if (d.tipo_seccion === 'remate' && d.n_versos === 1 && fila.identificacion?.forma_slug === 'terceto_encadenado') return 'Remate final de 1 verso (3+1)';
		if (d.tipo_seccion === 'remate') return 'Remate: ' + String(d.literal) +
			(d.n_versos ? ' · ' + String(d.n_versos) + (d.n_versos === 1 ? ' verso' : ' versos') : '');
		if (d.dimension === 'asonancia') return 'Asonancia: ' + String(d.literal);
		if (d.rasgo_slug === 'distico_final') return 'Dístico final · 2 versos';
		if (d.rasgo_slug) {
			const rasgo = rasgosImportador.find((r) => r.slug === d.rasgo_slug);
			return (rasgo?.nombre ?? String(d.rasgo_slug)) + ': ' + (rasgo?.valores.find((v) => v.slug === d.valor_slug)?.nombre ?? String(d.valor_slug));
		}
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
		<h2 class="text-lg font-semibold">Secuencias propuestas</h2>
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
		{#if editando && editable}
			{#key editando}
				<EditorSecuencia datos={vista.datos} tramoRef={editando} {formas} {ocupado} notasFuente={vista.filas.filter((f: FilaVistaPrevia) => f.origen.tramo_ref === editando).flatMap((f: FilaVistaPrevia) => f.notas_fuente ?? [])} errores={vista.errores.map((e: { mensaje: string }) => e.mensaje)}
					onaplicar={(cambio) => aplicar(cambio.tramo_ref, cambio)}
					onrestablecer={() => editando && aplicar(editando, null)} oncancelar={() => { editando = null; oncancelar?.(); }} />
			{/key}
		{/if}
		<div class:opacity-60={desactualizada} class="grid gap-3 sm:grid-cols-3">
			<div class="card p-4">
				<p class="form-label"><span class="form-label-with-help">Versos
					<FieldHelpTooltip label="Cómo se cuentan los versos" text="Total según la numeración de la edición. Incluye las lagunas que ya estén numeradas." />
				</span></p>
				<p class="text-2xl font-semibold">{numero(vista.resumen.extension)}</p>
			</div>
			<div class="card p-4">
				<p class="form-label"><span class="form-label-with-help">Secuencias propuestas
					<FieldHelpTooltip label="Cómo se proponen las secuencias" text="Se parte de las filas de la edición. Una fila puede necesitar varias secuencias si cambia de forma en su interior." />
				</span></p>
				<p class="text-2xl font-semibold">{vista.resumen.bloques}</p>
			</div>
			<div class="card p-4">
				<p class="form-label">Jornadas</p>
				<p class="text-2xl font-semibold">{vista.resumen.jornadas}</p>
			</div>
		</div>
		<div class="flex justify-end">
			<label class="flex items-center gap-2 text-sm">Mostrar
				<select class="rounded-md border border-[color:var(--border)] bg-white px-3 py-2" bind:value={filtro}>
					<option value="todos">Todas las secuencias</option>
					<option value="sin_resolver">Forma sin resolver</option>
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
							<colgroup><col class="w-[11%]" /><col class="w-[8%]" /><col class="w-[20%]" /><col class="w-[22%]" /><col class="w-[23%]" /><col class="w-[10%]" />{#if oneditar}<col class="w-[6%]" />{/if}</colgroup>
							<thead class="bg-[color:var(--muted)] text-xs text-[color:var(--muted-foreground)]">
								<tr><th class="px-3 py-3">Versos</th><th class="px-3 py-3">N.º versos</th><th class="px-3 py-3">En la edición</th><th class="px-3 py-3">Forma en Versología</th><th class="px-3 py-3">Detalles y notas</th><th class="px-3 py-3">Fuente</th>{#if oneditar}<th class="px-3 py-3"><span class="sr-only">Acciones</span></th>{/if}</tr>
							</thead>
							<tbody>
								{#each jornada.filas as fila (fila.ref)}
									<tr class="border-t border-[color:var(--border)] align-top">
										<td class="px-3 py-3 tabular-nums">{fila.v_ini}–{fila.v_fin}</td>
										<td class="px-3 py-3 tabular-nums">{fila.extension}</td>
										<td class="break-words px-3 py-3">{fila.origen.denominacion_literal ?? '—'}</td>
										<td class="break-words px-3 py-3">
											<p class="font-medium">{fila.forma_nombre ?? 'Forma sin resolver'}</p>
											{#if sinEquivalencia(fila) && fila.candidatas_nombres.length}
												<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">Posibilidades: {fila.candidatas_nombres.join(' / ')}</p>
											{/if}
										</td>
										<td class="break-words px-3 py-3">
											{#each fila.detalles_fuente as d}<p class="mb-1">{detalle(d, fila)}</p>{/each}
											{#each fila.desviaciones as d}<p class="mb-1 font-medium">{desviacion(d)}</p>{/each}
											{#each fila.notas_fuente ?? [] as nota}<p class="mb-1 text-xs text-[color:var(--muted-foreground)]">{nota.texto_literal}</p>{/each}
											{#if fila.nota}<p class="mb-1 text-xs text-[color:var(--muted-foreground)]">{fila.nota}</p>{/if}
											{#if !fila.detalles_fuente.length && !fila.desviaciones.length && !fila.notas_fuente?.length && !fila.nota}<span class="text-[color:var(--muted-foreground)]">—</span>{/if}
										</td>
										<td class="px-3 py-3 text-xs text-[color:var(--muted-foreground)]">
											{fuente(fila.origen.fuente_id)}
											{#if fila.origen.pagina}<p class="mt-1">p. {fila.origen.pagina}</p>{/if}
										</td>
										{#if oneditar}
											<td class="px-3 py-2">
												<div class="flex items-center justify-end gap-1">
													<button type="button" class="rounded p-1 text-[color:var(--success)] transition-colors hover:bg-[color:var(--success)] hover:text-white disabled:opacity-40 disabled:hover:bg-transparent disabled:hover:text-[color:var(--success)]" disabled={!editable || ocupado} title="Editar secuencia" aria-label={'Editar secuencia ' + fila.v_ini + '–' + fila.v_fin} onclick={() => editando = fila.origen.tramo_ref}><Pencil size={16} /></button>
												</div>
											</td>
										{/if}
									</tr>
								{/each}
							</tbody>
						</table>
					</div>
				</section>
			{/if}
		{/each}
		{#if !filas.length}<p class="card p-4 text-sm text-[color:var(--muted-foreground)]">No hay secuencias con este filtro.</p>{/if}
	{/if}
</section>

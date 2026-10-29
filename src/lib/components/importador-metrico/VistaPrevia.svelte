<script lang="ts">
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	import Pencil from 'lucide-svelte/icons/pencil';
	import EditorSecuencia from './EditorSecuencia.svelte';
	import type { EdicionFila, FormaEditable } from '$lib/importador-metrico/edicion';
	import type { ResultadoVistaPrevia, FilaVistaPrevia, FichaMinima } from '$lib/importador-metrico/types';
	import { formasImportador } from '$lib/importador-metrico/catalogo';
	import { datosMetricos, notasMetricas } from '$lib/importador-metrico/presentacion';
	import FormaSecuencia from '$lib/components/metrica/FormaSecuencia.svelte';
	import InlineNotePopover from '$lib/components/ui/inline-note-popover.svelte';

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
</script>

<section class="space-y-4" aria-label={vista.persistido ? 'Métrica importada' : 'Vista previa métrica'}>
	<header class="flex flex-wrap items-center justify-between gap-3">
		<h2 class="text-lg font-semibold">{vista.persistido?'Secuencias registradas':'Secuencias propuestas'}</h2>
		<span class="text-xs text-[color:var(--muted-foreground)]">{vista.persistido?'Copia de la importación':'Vista previa · sin guardar'}</span>
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
				<p class="form-label"><span class="form-label-with-help">{vista.persistido ? 'Secuencias' : 'Secuencias propuestas'}
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
					<div class="card overflow-x-auto">
						<table class="w-full min-w-[860px] table-fixed text-left text-sm">
							<caption class="sr-only">Esquema métrico de la jornada {jornada.numero}</caption>
							<colgroup><col class="w-[11%]" /><col class="w-[18%]" /><col class="w-[17%]" /><col class="w-[25%]" /><col class="w-[16%]" /><col class="w-[8%]" />{#if oneditar}<col class="w-[5%]" />{/if}</colgroup>
							<thead class="bg-[color:var(--muted)]">
								<tr><th class="px-3 py-2">Versos</th><th class="px-3 py-2">En la edición</th><th class="px-3 py-2">Forma</th><th class="px-3 py-2"><span class="form-label-with-help">Datos métricos<FieldHelpTooltip label="Datos métricos que se guardarán" text="Rasgos y valores, remates y desviaciones incorporados a la ficha mínima. Los campos sin especificar quedan sin dato." /></span></th><th class="px-3 py-2">Notas</th><th class="px-3 py-2">Fuente</th>{#if oneditar}<th class="px-3 py-2"><span class="sr-only">Acciones</span></th>{/if}</tr>
							</thead>
							<tbody>
								{#each jornada.filas as fila (fila.ref)}
									{@const forma = (formas.length ? formas : formasImportador).find((f: FormaEditable) => f.slug === fila.identificacion?.forma_slug)}
									{@const arquitectura = forma?.arquitecturas.find((a: {slug: string; nombre: string}) => a.slug === fila.identificacion?.arquitectura_slug)}
									{@const datos = datosMetricos(fila)}
									{@const notas = notasMetricas(fila)}
									<tr class="border-t border-[color:var(--border)] align-top">
										<td class="px-3 py-2 tabular-nums"><span class="whitespace-nowrap">{fila.v_ini}–{fila.v_fin}</span><span class="block text-xs text-[color:var(--muted-foreground)]">{fila.extension} vv.</span></td>
										<td class="break-words px-3 py-2">{fila.origen.denominacion_literal ?? '—'}</td>
										<td class="break-words px-3 py-2">
											<FormaSecuencia forma={forma?.nombre ?? null} arquitectura={arquitectura?.nombre ?? null} pendiente="Forma sin resolver" />
											{#if sinEquivalencia(fila) && fila.candidatas_nombres.length}
												<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">Posibilidades: {fila.candidatas_nombres.join(' / ')}</p>
											{/if}
										</td>
										<td class="break-words px-3 py-2">
											{#if datos.length}<dl class="space-y-2 text-xs">{#each datos as dato}<div><dt class="font-medium">{dato.etiqueta}</dt><dd>{dato.valor}</dd></div>{/each}</dl>{:else}<span class="text-[color:var(--muted-foreground)]">—</span>{/if}
										</td>
										<td class="break-words px-3 py-2 text-xs text-[color:var(--muted-foreground)]">
											{#if notas.length}<p class="line-clamp-3">{notas[0]}</p><span class="inline-flex items-center">{#if notas.length > 1}{notas.length} notas{/if}<InlineNotePopover text={notas.join('\n\n')} label={'Mostrar notas de la secuencia ' + fila.v_ini + '–' + fila.v_fin} multilinea /></span>{:else}—{/if}
										</td>
										<td class="px-3 py-2 text-xs text-[color:var(--muted-foreground)]">
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

<script lang="ts">
	import type { FilaBasica } from '$lib/server/importador-metrico/persistencia';
	import Trash2 from 'lucide-svelte/icons/trash-2';
	import Eye from 'lucide-svelte/icons/eye';
	import Table from '$lib/components/ui/table.svelte';
	import InlineNotePopover from '$lib/components/ui/inline-note-popover.svelte';
	import FieldHelpTooltip from '$lib/components/ui/field-help-tooltip.svelte';
	let { filas, puedeEliminar = false, oneliminar } = $props<{
		filas: FilaBasica[]; puedeEliminar?: boolean; oneliminar?: (fila: FilaBasica) => void;
	}>();
	const fecha = (s: string) => new Date(s).toLocaleDateString('es-ES', { timeZone: 'Europe/Madrid' });
	const fechaCompleta = (s: string) => new Date(s).toLocaleString('es-ES', { timeZone: 'Europe/Madrid' });
	function formasPendientes(f: FilaBasica) {
		const grupos = new Map<string, string[]>();
		for (const p of f.formas_pendientes) grupos.set(p.denominacion, [...(grupos.get(p.denominacion) ?? []), `${p.v_ini}–${p.v_fin}`]);
		return [...grupos].map(([nombre, rangos]) => `${nombre} — ${rangos.join(', ')}`);
	}
</script>

	<Table>
		<thead><tr>
			<th class="min-w-44 px-4 py-3">Obra</th><th class="px-4 py-3">Autor</th>
			<th class="px-4 py-3">Importada por</th><th class="px-4 py-3">Importada el</th>
			<th class="px-4 py-3"><span class="form-label-with-help">Última modificación<FieldHelpTooltip label="Última modificación" text="Fecha guardada de la copia básica. Las importaciones anteriores a este registro muestran «No consta». Consultar la ficha no cambia esta fecha." /></span></th>
			<th class="px-4 py-3"><span class="form-label-with-help">Por revisar<FieldHelpTooltip label="Pendientes y avisos" text="Formas sin identificar y avisos de longitud conservados al guardar. Las incidencias del JSON original se muestran aparte: pueden haberse corregido durante la importación." /></span></th>
			<th class="px-4 py-3"><span class="sr-only">Acciones</span></th>
		</tr></thead>
		<tbody class="divide-y divide-[color:var(--border)]">
			{#each filas as f (f.importacion_id)}
				<tr class="align-top border-t border-[color:var(--border)]">
					<td class="px-4 py-3">{f.titulo}</td>
					<td class="px-4 py-3">{f.autor_nombre}</td><td class="px-4 py-3">{f.importado_por}</td>
					<td class="whitespace-nowrap px-4 py-3" title={fechaCompleta(f.importado_en)}>{fecha(f.importado_en)}</td>
					<td class="whitespace-nowrap px-4 py-3 text-[color:var(--muted-foreground)]" title={f.modificado_en ? fechaCompleta(f.modificado_en) : undefined}>{f.modificado_en ? fecha(f.modificado_en) : 'No consta'}</td>
					<td class="min-w-64 max-w-sm space-y-2 px-4 py-3 text-xs">
						{#each formasPendientes(f) as pendiente}<p><span class="font-medium">Sin identificar:</span> {pendiente}</p>{/each}
						{#each f.avisos_longitud as aviso}<p class="text-amber-800"><span class="font-medium">Longitud:</span> {aviso.v_ini}–{aviso.v_fin} <InlineNotePopover text={aviso.mensaje} label={'Aviso de longitud de ' + f.titulo + ', versos ' + aviso.v_ini + '–' + aviso.v_fin} /></p>{/each}
						{#if !f.comprobacion_registrada}<p class="text-[color:var(--muted-foreground)]">Longitud: sin registro al importar.</p>{/if}
						{#if f.incidencias_fuente.length}<p>JSON original: {f.incidencias_fuente.length} {f.incidencias_fuente.length === 1 ? 'incidencia' : 'incidencias'} <InlineNotePopover text={f.incidencias_fuente.map((i: { descripcion: string }) => i.descripcion).join('\n\n')} label={'Incidencias originales de ' + f.titulo} multilinea /></p>{/if}
						{#if f.comprobacion_registrada && !f.formas_pendientes.length && !f.avisos_longitud.length && !f.incidencias_fuente.length}<p class="text-[color:var(--muted-foreground)]">Sin pendientes registrados.</p>{/if}
					</td>
					<td class="px-4 py-3">
						<div class="flex items-center justify-end gap-1">
							<a href={'/dashboard/importador/fichas/' + f.importacion_id} title="Ver ficha básica" aria-label={'Ver ' + f.titulo} class="rounded p-1 text-[color:var(--muted-foreground)] transition-colors hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)]"><Eye size={16} aria-hidden="true" /></a>
							{#if puedeEliminar}<button type="button" title="Eliminar ficha básica" aria-label={'Eliminar ' + f.titulo} class="rounded p-1 text-[color:var(--danger)] transition-colors hover:bg-[color:var(--danger)] hover:text-white" onclick={() => oneliminar?.(f)}><Trash2 size={16} /></button>{/if}
						</div>
					</td>
				</tr>
			{:else}<tr><td colspan={7} class="px-4 py-6 text-[color:var(--muted-foreground)]">No hay fichas básicas guardadas en esta página.</td></tr>{/each}
		</tbody>
	</Table>

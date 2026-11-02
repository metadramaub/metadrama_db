<script lang="ts">
	import type { ResultadoVistaPrevia, IncidenciaImportador, FilaVistaPrevia } from '$lib/importador-metrico/types';
	let { vista } = $props<{ vista: ResultadoVistaPrevia }>();
	// Estos tres avisos describen el flujo, no incidencias que deba corregir quien importa.
	const avisos = $derived(vista.avisos.filter((a: IncidenciaImportador) => !['referencia_local', 'cotejo_pendiente', 'segmentacion_provisional'].includes(a.codigo)));
	const pendientes = $derived(vista.pendientes_metadatos?.length ?? 0);
	function mensaje(aviso: IncidenciaImportador) {
		if (aviso.codigo !== 'forma_pendiente') return aviso.mensaje;
		const filas = vista.filas.filter((f: FilaVistaPrevia) => !f.identificacion);
		return filas.length ? 'Formas pendientes de identificar: ' + filas.map((f: FilaVistaPrevia) =>
			`${f.origen.denominacion_literal ? '«' + f.origen.denominacion_literal + '» · ' : ''}vv. ${f.v_ini}–${f.v_fin}`
		).join('; ') + '.' : aviso.mensaje;
	}
</script>

<div class="space-y-2 text-sm">
<p role="status" class={vista.errores.length ? 'text-[color:var(--danger)]' : avisos.length || pendientes ? 'text-[color:var(--muted-foreground)]' : 'text-[color:var(--success)]'}>
	{#if vista.errores.length}
		Comprobación terminada: {vista.errores.length} {vista.errores.length === 1 ? 'error' : 'errores'} para corregir.
	{:else if pendientes || avisos.length}
		{`Cambios comprobados:${avisos.length ? ` ${avisos.length} ${avisos.length === 1 ? 'aviso' : 'avisos'} para revisar.` : ''}${pendientes ? ' Faltan datos obligatorios de la obra.' : ''}`}
	{:else}
		Cambios comprobados: sin incidencias detectadas.
	{/if}
</p>
{#if avisos.length}
	<ul class="list-disc space-y-1 pl-5 text-[color:var(--muted-foreground)]">
		{#each avisos as aviso}<li>{mensaje(aviso)}</li>{/each}
	</ul>
{/if}
</div>

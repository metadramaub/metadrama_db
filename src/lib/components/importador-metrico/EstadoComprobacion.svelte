<script lang="ts">
	import type { ResultadoVistaPrevia, IncidenciaImportador } from '$lib/importador-metrico/types';
	let { vista } = $props<{ vista: ResultadoVistaPrevia }>();
	// Estos tres avisos describen el flujo, no incidencias que deba corregir quien importa.
	const avisos = $derived(vista.avisos.filter((a: IncidenciaImportador) => !['referencia_local', 'cotejo_pendiente', 'segmentacion_provisional'].includes(a.codigo)).length);
	const pendientes = $derived(vista.pendientes_metadatos?.length ?? 0);
</script>

<p role="status" class={'text-sm ' + (vista.errores.length ? 'text-[color:var(--danger)]' : avisos || pendientes ? 'text-[color:var(--muted-foreground)]' : 'text-[color:var(--success)]')}>
	{#if vista.errores.length}
		Comprobación terminada: {vista.errores.length} {vista.errores.length === 1 ? 'error' : 'errores'} para corregir.
	{:else if pendientes || avisos}
		Cambios comprobados:{#if avisos} {avisos} {avisos === 1 ? 'aviso' : 'avisos'} para revisar.{/if}{#if pendientes} Faltan datos obligatorios de la obra.{/if}
	{:else}
		Cambios comprobados: sin incidencias detectadas.
	{/if}
</p>

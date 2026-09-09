<script lang="ts">
	import { Download, LoaderCircle } from 'lucide-svelte';
	import type { DiagramExportMeta } from './diagram-export.types';
	import { exportDiagramPng } from '$lib/utils/export-diagram-png';

	const props = $props<{
		target?: Element | null;
		meta: DiagramExportMeta;
	}>();

	let exporting = $state(false);
	let error = $state('');

	async function download() {
		if (!props.target || exporting) return;
		exporting = true;
		error = '';
		try {
			await exportDiagramPng(props.target, props.meta);
		} catch (caught) {
			error = caught instanceof Error ? caught.message : 'No se pudo exportar el diagrama.';
		} finally {
			exporting = false;
		}
	}
</script>

<div class="flex flex-wrap items-center justify-end gap-2">
	<button
		type="button"
		class="inline-flex items-center gap-1.5 border border-[color:var(--border)] bg-white px-2 py-1 text-xs font-semibold text-[color:var(--gray-800)] hover:bg-[color:var(--gray-50)] disabled:opacity-50"
		disabled={!props.target || exporting}
		onclick={download}
	>
		{#if exporting}<LoaderCircle class="h-3.5 w-3.5 animate-spin" />{:else}<Download class="h-3.5 w-3.5" />{/if}
		Descargar PNG
	</button>
</div>
{#if error}
	<p class="mt-1 text-right text-xs text-red-700" role="alert">{error}</p>
{/if}

<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import type { EditorOption } from '$lib/types/editor-management.types';
	let { editors, defaultEditor = '', fixedEditor = false, oncomplete }: {
		editors: EditorOption[]; defaultEditor?: string; fixedEditor?: boolean; oncomplete?: (works: { obra_id: string; titulo: string }[]) => void;
	} = $props();
	let editorId = $state('');
	let titles = $state('');
	let saving = $state(false);
	let message = $state('');
	const activeEditors = $derived(editors.filter((editor) => editor.activo !== false));
	const assignedEditorId = $derived(fixedEditor ? defaultEditor : editorId);
	const count = $derived(titles.split(/\r?\n/).filter((line) => line.trim()).length);
	$effect(() => { if (!editorId) editorId = defaultEditor || activeEditors[0]?.user_id || ''; });
	async function create(event: SubmitEvent) {
		event.preventDefault();
		if (saving) return;
		saving = true;
		message = '';
		try {
			const response = await fetch('/api/obras/lote', {
				method: 'POST', headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ editor_asignado: assignedEditorId, titles: titles.split(/\r?\n/).map((line) => line.trim()).filter(Boolean) })
			});
			const body = await response.json();
			if (!response.ok) { message = body.message ?? 'No se pudieron crear las obras.'; return; }
			titles = '';
			pushToast('success', `${body.obras.length} obras creadas y asignadas.`);
			window.dispatchEvent(new CustomEvent('dashboard-obras-updated'));
			await invalidateAll();
			oncomplete?.(body.obras);
		} catch { message = 'No se pudo comprobar el resultado. Recarga y comprueba las obras antes de reintentar.'; }
		finally { saving = false; }
	}
</script>

<form class="space-y-3" onsubmit={create}>
	{#if fixedEditor}
		<p class="text-sm">Editor responsable: <strong>{editors.find((editor) => editor.user_id === defaultEditor)?.nombre_completo}</strong></p>
	{:else}
	<label class="form-field"><span class="form-label">Editor responsable</span><select class="w-full border border-[color:var(--border)] bg-white p-2" required bind:value={editorId} disabled={saving}><option value="">Seleccionar editor</option>{#each activeEditors as editor}<option value={editor.user_id}>{editor.nombre_completo}</option>{/each}</select></label>
	{/if}
	<label class="form-field"><span class="form-label">Títulos (uno por línea)</span><textarea class="work-titles w-full border border-[color:var(--border)] bg-white p-2" rows="5" placeholder={'Título de la primera obra\nTítulo de la segunda obra'} required bind:value={titles} disabled={saving}></textarea></label>
	{#if message}<p role="alert" class="text-sm text-[color:var(--danger)]">{message}</p>{/if}
	<Button type="submit" loading={saving} disabled={!assignedEditorId || count < 1 || count > 100}>Crear y asignar {count === 1 ? '1 obra' : `${count} obras`}</Button>
	{#if count > 100}<p role="alert">Puedes crear hasta 100 obras por lote.</p>{/if}
</form>

<style>
	.work-titles::placeholder { white-space: pre-line; }
</style>

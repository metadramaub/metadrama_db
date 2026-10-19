<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { assignmentSnapshot } from '$lib/utils/editor-management';
	import type { AssignmentOperation, AssignmentWork, EditorOption } from '$lib/types/editor-management.types';

	let { works, editors, defaultTarget = '', embedded = false, oncomplete }: {
		works: AssignmentWork[]; editors: EditorOption[]; defaultTarget?: string; embedded?: boolean; oncomplete: () => void;
	} = $props();
	let operation = $state<AssignmentOperation>('editor');
	let target = $state('');
	let preview = $state<{ works: AssignmentWork[]; operation: AssignmentOperation; target: string } | null>(null);
	let saving = $state(false);
	let message = $state('');
	const options = $derived(editors.filter((editor) => operation === 'remove_reviewer' || editor.activo !== false));
	const labels = { editor: 'Cambiar editor responsable', add_reviewer: 'Añadir revisor', remove_reviewer: 'Retirar revisor' };
	const editorName = (id: string | null) => editors.find((editor) => editor.user_id === id)?.nombre_completo ?? 'Sin asignar';
	$effect(() => { if (!target && defaultTarget) target = defaultTarget; });

	function review() {
		message = '';
		if (!target || !works.length || works.length > 500) {
			message = 'Selecciona una persona y entre 1 y 500 obras.';
			return;
		}
		if (operation === 'add_reviewer' && works.some((work) => work.editor_asignado === target)) {
			message = 'La selección contiene obras que ya edita esa persona. No puede revisar sus propias obras.';
			return;
		}
		preview = { works: structuredClone($state.snapshot(works)), operation, target };
	}

	async function apply() {
		if (saving || !preview) return;
		saving = true;
		message = '';
		try {
			const response = await fetch('/api/obras/asignaciones-lote', {
				method: 'POST', headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ operation: preview.operation, target: preview.target, works: assignmentSnapshot(preview.works) })
			});
			const body = await response.json();
			if (!response.ok) {
				message = body.message ?? 'No se pudo guardar el lote.';
				if (response.status === 409) {
					preview = null;
					oncomplete();
					await invalidateAll();
				}
				return;
			}
			preview = null;
			oncomplete();
			pushToast('success', `Asignaciones guardadas: ${body.changed} obras modificadas.`);
			window.dispatchEvent(new CustomEvent('dashboard-obras-updated'));
			await invalidateAll();
		} catch {
			message = 'No se pudo comprobar el resultado. Recarga la página antes de volver a aplicar el lote.';
		} finally { saving = false; }
	}
</script>

<div class={embedded ? 'space-y-3 border-t border-[color:var(--border)] bg-[color:var(--muted)] p-4' : 'card space-y-3 p-4'}>
	<p class="font-medium">Cambiar asignaciones de {works.length} {works.length === 1 ? 'obra seleccionada' : 'obras seleccionadas'}</p>
	{#if preview}
		<p>{labels[preview.operation]}: <strong>{editorName(preview.target)}</strong></p>
		<div class="max-h-64 overflow-auto border border-[color:var(--border)]">
			<table class="w-full text-left text-sm">
				<thead><tr><th class="p-2">Obra</th><th class="p-2">Cambio</th></tr></thead>
				<tbody>{#each preview.works as work}
					<tr class="border-t border-[color:var(--border)]"><td class="p-2">{work.titulo}</td><td class="p-2">
						{#if preview.operation === 'editor'}
							{editorName(work.editor_asignado)} → {editorName(preview.target)}
							{#if work.reviewer_ids.includes(preview.target)}<span class="block text-xs">Dejará de ser revisor de esta obra.</span>{/if}
						{:else if preview.operation === 'add_reviewer'}
							{work.reviewer_ids.includes(preview.target) ? 'Ya es revisor; sin cambios' : `Añadir a ${editorName(preview.target)} como revisor`}
						{:else}
							{work.reviewer_ids.includes(preview.target) ? `Retirar a ${editorName(preview.target)} como revisor` : 'No es revisor; sin cambios'}
						{/if}
					</td></tr>
				{/each}</tbody>
			</table>
		</div>
		<div class="flex gap-2"><Button variant="ghost" disabled={saving} onclick={() => { preview = null; message = ''; }}>Volver</Button><Button loading={saving} onclick={apply}>Aplicar a {preview.works.length} obras</Button></div>
	{:else}
		<div class="flex flex-wrap items-end gap-3">
			<label class="form-field"><span class="form-label">Operación</span><select class="border border-[color:var(--border)] bg-white p-2 text-sm" bind:value={operation}>{#each Object.entries(labels) as [value, label]}<option {value}>{label}</option>{/each}</select></label>
			<label class="form-field"><span class="form-label">{operation === 'editor' ? 'Nuevo editor responsable' : 'Revisor'}</span><select class="border border-[color:var(--border)] bg-white p-2 text-sm" bind:value={target}><option value="">Seleccionar persona</option>{#each options as editor}<option value={editor.user_id}>{editor.nombre_completo}{editor.activo === false ? ' (deshabilitado)' : ''}</option>{/each}</select></label>
			<Button disabled={!works.length || !target} onclick={review}>Revisar cambios</Button>
		</div>
	{/if}
	{#if message}<p role="alert" class="text-sm text-[color:var(--danger)]">{message}</p>{/if}
</div>

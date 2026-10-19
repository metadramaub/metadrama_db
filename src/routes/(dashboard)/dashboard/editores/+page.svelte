<script lang="ts">
	import { goto } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import { invitationLabels } from '$lib/utils/editor-management';
	import type { PageData } from './$types';
	import type { ManagedEditor } from '$lib/types/editor-management.types';
	let { data } = $props<{ data: PageData }>();
	let q = $state('');
	let status = $state('');
	let access = $state('');
	let creating = $state(false);
	let saving = $state(false);
	let message = $state('');
	let nombre = $state('');
	let email = $state('');
	let institucion = $state('');
	let orcid = $state('');
	const visible: ManagedEditor[] = $derived(data.editors.filter((editor: ManagedEditor) =>
		`${editor.nombre_completo} ${editor.email} ${editor.institucion ?? ''}`.toLocaleLowerCase('es').includes(q.toLocaleLowerCase('es')) &&
		(!status || editor.invitationStatus === status) &&
		(!access || (access === 'blocked' ? editor.activo === false : editor.activo !== false))
	));
	async function create(event: SubmitEvent) {
		event.preventDefault();
		if (saving) return;
		saving = true;
		message = '';
		try {
			const response = await fetch('/api/editores', { method: 'POST', headers: { 'Content-Type': 'application/json' },
				body: JSON.stringify({ nombre_completo: nombre, email, institucion, orcid }) });
			const body = await response.json();
			if (!response.ok) { message = body.message ?? 'No se pudo crear el editor.'; return; }
			await goto(`/dashboard/editores/${body.editor.user_id}`);
		} catch { message = 'No se pudo comprobar el alta. Revisa el listado antes de reintentar.'; }
		finally { saving = false; }
	}
</script>

<section class="space-y-5">
	<div class="flex flex-wrap items-end justify-between gap-3"><div><h1 class="font-display text-3xl">EDITORES</h1></div><Button onclick={() => creating = !creating}>{creating ? 'Cerrar alta' : 'Crear editor'}</Button></div>
	{#if creating}
		<form class="card space-y-4 p-5" onsubmit={create}>
			<h2 class="text-lg font-semibold">Nuevo editor</h2><p class="text-sm text-[color:var(--muted-foreground)]">El correo de invitación se envía por separado.</p>
			<div class="grid gap-4 md:grid-cols-2">
				<label class="form-field"><span class="form-label">Nombre completo *</span><input class="border border-[color:var(--border)] p-2" required maxlength="200" bind:value={nombre} disabled={saving} /></label>
				<label class="form-field"><span class="form-label">Correo *</span><input class="border border-[color:var(--border)] p-2" type="email" required maxlength="255" bind:value={email} disabled={saving} /></label>
				<label class="form-field"><span class="form-label">Institución</span><input class="border border-[color:var(--border)] p-2" maxlength="200" bind:value={institucion} disabled={saving} /></label>
				<label class="form-field"><span class="form-label">ORCID</span><input class="border border-[color:var(--border)] p-2" placeholder="0000-0000-0000-0000" maxlength="19" bind:value={orcid} disabled={saving} /></label>
			</div>
			{#if message}<p role="alert" class="text-sm text-[color:var(--danger)]">{message}</p>{/if}
			<Button type="submit" loading={saving}>Crear editor</Button>
		</form>
	{/if}
	<div class="card grid gap-3 p-4 md:grid-cols-[minmax(0,1fr)_12rem_12rem]">
		<label class="form-field"><span class="form-label">Buscar editor</span><input class="border border-[color:var(--border)] p-2" placeholder="Nombre, correo o institución" bind:value={q} /></label>
		<label class="form-field"><span class="form-label">Invitación</span><select class="border border-[color:var(--border)] bg-white p-2" bind:value={status}><option value="">Todos</option>{#each Object.entries(invitationLabels) as [value, label]}<option {value}>{label}</option>{/each}</select></label>
		<label class="form-field"><span class="form-label">Permiso de acceso</span><select class="border border-[color:var(--border)] bg-white p-2" bind:value={access}><option value="">Todos</option><option value="allowed">Permitido</option><option value="blocked">Bloqueado</option></select></label>
	</div>
	<div class="card overflow-x-auto"><table class="w-full text-left text-sm"><thead class="bg-[color:var(--muted)]"><tr><th class="p-3">Editor</th><th class="p-3">Rol</th><th class="p-3">Invitación</th><th class="p-3">Permiso de acceso</th><th class="p-3">Edición</th><th class="p-3">Revisión</th></tr></thead><tbody>
		{#each visible as editor}<tr class="border-t border-[color:var(--border)]"><td class="p-3"><a class="font-medium underline" href={`/dashboard/editores/${editor.user_id}`}>{editor.nombre_completo}</a><p>{editor.email}</p><p class="text-xs text-[color:var(--muted-foreground)]">{editor.institucion ?? ''}</p></td><td class="p-3">{({ admin: 'Administración', ip: 'IP', editor: 'Editor' } as Record<string, string>)[editor.roleTerm] ?? editor.roleTerm}</td><td class="p-3">{invitationLabels[editor.invitationStatus]}</td><td class="p-3">{editor.activo === false ? 'Bloqueado' : 'Permitido'}</td><td class="p-3">{editor.editingCount}</td><td class="p-3">{editor.reviewingCount}</td></tr>
		{:else}<tr><td colspan="6" class="p-4">No hay editores que coincidan con la búsqueda.</td></tr>{/each}
	</tbody></table></div>
</section>

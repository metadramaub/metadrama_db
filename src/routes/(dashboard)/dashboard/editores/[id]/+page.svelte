<script lang="ts">
	import { goto, invalidateAll } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import ObrasTable from '$lib/components/dashboard/ObrasTable.svelte';
	import BulkAssignments from '$lib/components/dashboard/BulkAssignments.svelte';
	import CreateWorksForm from '$lib/components/dashboard/CreateWorksForm.svelte';
	import { invitationLabels, normalizeWorkTitle } from '$lib/utils/editor-management';
	import { pushToast } from '$lib/stores/toast';
	import type { PageData } from './$types';
	import type { ManagedEditor } from '$lib/types/editor-management.types';
	type Work = PageData['works'][number];
	let { data } = $props<{ data: PageData }>();
	let nombre = $state('');
	let institucion = $state('');
	let orcid = $state('');
	let activo = $state(true);
	let profileReady = $state(false);
	const hasChanges = $derived(profileReady && (
		nombre.trim() !== data.editor.nombre_completo.trim() ||
		institucion.trim() !== (data.editor.institucion ?? '').trim() ||
		orcid.trim() !== (data.editor.orcid ?? '').trim() ||
		activo !== (data.editor.activo !== false)
	));
	let busy = $state(false);
	let message = $state('');
	let q = $state('');
	let scope = $state<'editing' | 'reviewing'>('editing');
	let operation = $state<'assign' | 'create' | null>(null);
	let catalogQ = $state('');
	let catalogSelectedIds = $state<string[]>([]);
	let selectedIds = $state<string[]>([]);
	let emailAction = $state<'invite' | 'recovery' | null>(null);
	const editing = $derived(data.works.filter((work: Work) => work.editor_asignado === data.editor.user_id));
	const reviewing = $derived(data.works.filter((work: Work) => work.reviewer_ids.includes(data.editor.user_id)));
	const visible = $derived(data.works.filter((work: Work) =>
		(!q || normalizeWorkTitle(work.titulo).includes(normalizeWorkTitle(q))) &&
		(scope === 'editing' ? work.editor_asignado === data.editor.user_id : work.reviewer_ids.includes(data.editor.user_id))
	));
	const selected = $derived(data.works.filter((work: Work) => selectedIds.includes(work.obra_id)));
	const catalogWorks = $derived(data.works.filter((work: Work) => !catalogQ || normalizeWorkTitle(work.titulo).includes(normalizeWorkTitle(catalogQ))));
	const catalogSelected = $derived(data.works.filter((work: Work) => catalogSelectedIds.includes(work.obra_id)));
	$effect(() => {
		nombre = data.editor.nombre_completo;
		institucion = data.editor.institucion ?? '';
		orcid = data.editor.orcid ?? '';
		activo = data.editor.activo !== false;
		profileReady = true;
		selectedIds = [];
		catalogSelectedIds = [];
		emailAction = null;
	});
	async function save(event: SubmitEvent) {
		event.preventDefault();
		if (busy || !hasChanges) return;
		busy = true; message = '';
		try {
			const response = await fetch(`/api/editores/${data.editor.user_id}`, { method: 'PATCH', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ nombre_completo: nombre, institucion, orcid, activo }) });
			const body = await response.json();
			if (!response.ok) { message = body.message ?? 'No se pudo guardar.'; return; }
			pushToast('success', 'Perfil guardado.');
			await invalidateAll();
		} catch { message = 'No se pudo comprobar el resultado. Recarga el perfil.'; }
		finally { busy = false; }
	}
	async function sendAccessEmail() {
		if (busy || !emailAction) return;
		const recovery = emailAction === 'recovery';
		busy = true; message = '';
		try {
			const response = await fetch('/api/editores/' + data.editor.user_id + (recovery ? '/recuperar' : '/invitar'), { method: 'POST' });
			const body = await response.json();
			if (!response.ok) { message = body.message ?? 'No se pudo enviar el correo.'; return; }
			pushToast('success', recovery ? 'Correo de recuperación enviado.' : 'Invitación enviada.');
			emailAction = null;
			await invalidateAll();
		} catch { message = 'No se pudo comprobar el envío. Recarga y revisa el estado antes de reintentar.'; }
		finally { busy = false; }
	}
	function changeScope(next: 'editing' | 'reviewing') {
		scope = next;
		selectedIds = [];
		q = '';
	}
	function openOperation(next: 'assign' | 'create' | null) {
		operation = next;
		catalogQ = '';
		catalogSelectedIds = [];
	}
	function dateLabel(value: string | null) {
		return value ? new Date(value).toLocaleString('es-ES', { timeZone: 'Europe/Madrid' }) : 'Sin registros';
	}
</script>

<section class="space-y-6">
	<header class="space-y-2">
		<div class="flex flex-wrap items-center gap-3">
			<h1 class="font-display text-3xl">{data.editor.nombre_completo}</h1>
			<span class="border border-[color:var(--border)] px-2 py-1 text-xs">{({ admin: 'Administración', ip: 'IP', editor: 'Editor' } as Record<string, string>)[data.editor.roleTerm] ?? data.editor.roleTerm}</span>
		</div>
		<p class="text-sm text-[color:var(--muted-foreground)]">{data.editor.email}</p>
	</header>
	{#if message}<p role="alert" class="card p-4 text-[color:var(--danger)]">{message}</p>{/if}
	<form class="grid items-stretch gap-4 lg:grid-cols-2" onsubmit={save}>
		<div class="card space-y-4 p-5">
			<h2 class="text-lg font-semibold">Perfil editorial</h2>
			<label class="form-field"><span class="form-label">Nombre completo</span><input class="w-full border border-[color:var(--border)] p-2" required maxlength="200" bind:value={nombre} disabled={busy} /></label>
			<label class="form-field"><span class="form-label">Institución</span><input class="w-full border border-[color:var(--border)] p-2" maxlength="200" bind:value={institucion} disabled={busy} /></label>
			<label class="form-field"><span class="form-label">ORCID</span><input class="w-full border border-[color:var(--border)] p-2" maxlength="19" bind:value={orcid} disabled={busy} /></label>
		</div>
		<div class="card space-y-4 p-5">
			<h2 class="text-lg font-semibold">Acceso</h2>
			<dl class="grid grid-cols-[auto_1fr] gap-x-5 gap-y-3 text-sm">
				<dt class="text-[color:var(--muted-foreground)]">Invitación</dt><dd>{invitationLabels[(data.editor as ManagedEditor).invitationStatus]}</dd>
				<dt class="text-[color:var(--muted-foreground)]">Último envío</dt><dd>{data.editor.invitedAt ? dateLabel(data.editor.invitedAt) : 'No enviada'}</dd>
				<dt class="text-[color:var(--muted-foreground)]">Último acceso</dt><dd>{data.editor.lastSignInAt ? dateLabel(data.editor.lastSignInAt) : 'Todavía no ha accedido'}</dd>
			</dl>
			<div class="space-y-2 border-t border-[color:var(--border)] pt-4">
				<h3 class="text-sm font-medium">Permiso de acceso</h3>
				{#if data.canToggleActive}
					<label class="flex items-center gap-2 text-sm"><input type="checkbox" bind:checked={activo} disabled={busy} />Permitir entrada al dashboard</label>
				{:else}
					<p class="text-sm">{data.editor.activo === false ? 'Bloqueado' : 'Permitido'}</p>
				{/if}
			</div>
			<div class="border-t border-[color:var(--border)] pt-4">
				{#if emailAction}
					<div class="space-y-3">
						<p class="text-sm">{emailAction === 'recovery' ? 'Enviar un enlace para restablecer la contraseña a' : 'Enviar invitación a'} <strong>{data.editor.email}</strong>.</p>
						{#if emailAction === 'invite'}<p class="text-sm">Obras asignadas: {editing.length} de edición y {reviewing.length} de revisión.</p>{/if}
						<div class="flex flex-wrap gap-2"><Button variant="ghost" disabled={busy} onclick={() => emailAction = null}>Cancelar</Button><Button loading={busy} onclick={sendAccessEmail}>Confirmar envío</Button></div>
					</div>
				{:else if data.editor.invitationStatus === 'accepted'}
					<Button variant="secondary" disabled={busy || data.editor.activo === false} onclick={() => emailAction = 'recovery'}>Enviar recuperación de contraseña</Button>
				{:else}
					<Button disabled={busy || data.editor.activo === false} onclick={() => emailAction = 'invite'}>{data.editor.invitationStatus === 'sent' ? 'Reenviar invitación' : 'Enviar invitación'}</Button>
				{/if}
			</div>
		</div>
		<div class="flex justify-end lg:col-span-2"><Button type="submit" loading={busy} disabled={!hasChanges}>Guardar cambios</Button></div>
	</form>
	<section class="card overflow-hidden" aria-labelledby="editor-works-heading">
		<div class="flex flex-wrap items-center gap-3 border-b border-[color:var(--border)] px-4 py-3">
			<h2 id="editor-works-heading" class="mr-auto text-lg font-semibold">{operation === 'create' ? 'Crear obras' : operation === 'assign' ? 'Asignar obras existentes' : 'Obras asignadas'}</h2>
			{#if operation === 'assign'}
				<label class="min-w-0 flex-1 sm:max-w-xs">
					<span class="sr-only">Buscar en el catálogo</span>
					<input type="search" class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm" placeholder="Buscar en el catálogo" bind:value={catalogQ} oninput={() => catalogSelectedIds = []} />
				</label>
				{#if catalogSelectedIds.length}<Button variant="ghost" onclick={() => catalogSelectedIds = []}>Limpiar selección</Button>{/if}
			{/if}
			{#if operation}
				<Button variant="ghost" onclick={() => openOperation(null)}>Volver a obras asignadas</Button>
			{:else}
				<div class="flex flex-wrap gap-2" role="group" aria-label="Operaciones sobre obras">
					<Button variant="secondary" onclick={() => openOperation('assign')}>Asignar obras existentes</Button>
					<Button variant="secondary" onclick={() => openOperation('create')}>Crear obras</Button>
				</div>
			{/if}
		</div>
		{#if operation === 'create'}
			<div class="max-w-2xl p-4">
				{#if data.editor.activo === false}<p class="text-sm">Habilita al editor antes de crear obras para él.</p>
				{:else}<CreateWorksForm editors={data.editorOptions} defaultEditor={data.editor.user_id} fixedEditor oncomplete={() => { openOperation(null); changeScope('editing'); }} />{/if}
			</div>
		{:else if operation === 'assign'}
			<div class="max-h-[32rem] overflow-auto">
				<ObrasTable obras={catalogWorks} embedded selectedIds={catalogSelectedIds} onSelectionChange={(ids) => catalogSelectedIds = ids} on:open={(event) => goto('/dashboard/obras/' + event.detail)} />
			</div>
			{#if catalogSelectedIds.length}
				<BulkAssignments works={catalogSelected} editors={data.editorOptions} defaultTarget={data.editor.user_id} embedded oncomplete={() => openOperation(null)} />
			{/if}
		{:else}
			<div class="flex flex-wrap items-center gap-3 px-4 py-3">
				<div class="flex gap-1" role="group" aria-label="Vistas de obras asignadas">
					<Button variant={scope === 'editing' ? 'primary' : 'ghost'} onclick={() => changeScope('editing')}>Edición ({editing.length})</Button>
					<Button variant={scope === 'reviewing' ? 'primary' : 'ghost'} onclick={() => changeScope('reviewing')}>Revisión ({reviewing.length})</Button>
				</div>
				<label class="min-w-0 flex-1 sm:ml-auto sm:max-w-xs">
					<span class="sr-only">Buscar entre sus obras</span>
					<input type="search" class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm" placeholder="Buscar entre sus obras" bind:value={q} oninput={() => selectedIds = []} />
				</label>
				{#if selectedIds.length}<Button variant="ghost" onclick={() => selectedIds = []}>Limpiar selección</Button>{/if}
			</div>
			<div class="max-h-[32rem] overflow-auto border-t border-[color:var(--border)]">
				<ObrasTable obras={visible} embedded {selectedIds} onSelectionChange={(ids) => selectedIds = ids} on:open={(event) => goto('/dashboard/obras/' + event.detail)} />
			</div>
			{#if selectedIds.length}
				<BulkAssignments works={selected} editors={data.editorOptions} defaultTarget={data.editor.user_id} embedded oncomplete={() => selectedIds = []} />
			{/if}
		{/if}
	</section>
</section>

<script lang="ts">
	import { goto } from '$app/navigation';
	import { ArrowDown, ArrowUp, Pencil, X } from 'lucide-svelte';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import Table from '$lib/components/ui/table.svelte';
	import TableSearch from '$lib/components/ui/table-search.svelte';
	import TableToolbar from '$lib/components/ui/table-toolbar.svelte';
	import { invitationLabels } from '$lib/utils/editor-management';
	import type { PageData } from './$types';
	import type { ManagedEditor } from '$lib/types/editor-management.types';
	let { data } = $props<{ data: PageData }>();
	let q = $state('');
	let statuses = $state<string[]>([]);
	let access = $state<string[]>([]);
	let roles = $state<string[]>([]);
	let sortField = $state<'name' | 'editing' | 'reviewing'>('name');
	let ascending = $state(true);
	let creating = $state(false);
	let saving = $state(false);
	let message = $state('');
	let nombre = $state('');
	let email = $state('');
	let institucion = $state('');
	let orcid = $state('');
	const roleLabels: Record<string, string> = { admin: 'Administración', ip: 'IP', editor: 'Editor' };
	const roleOptions = $derived([...new Set(data.editors.map((editor) => editor.roleTerm))]
		.map((id) => ({ id, label: roleLabels[id] ?? id })));
	const invitationOptions = Object.entries(invitationLabels).map(([id, label]) => ({ id, label }));
	const accessOptions = [{ id: 'allowed', label: 'Permitido' }, { id: 'blocked', label: 'Bloqueado' }];
	const collator = new Intl.Collator('es', { sensitivity: 'base' });
	const iconAction = 'inline-flex size-7 items-center justify-center rounded text-[color:var(--muted-foreground)] transition-colors hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2';
	const hasFilters = $derived(Boolean(q || statuses.length || access.length || roles.length));

	function normalizeSearch(value: string) {
		return value.normalize('NFD').replace(/\p{Diacritic}/gu, '').toLocaleLowerCase('es');
	}

	const visible = $derived.by(() => {
		const query = normalizeSearch(q.trim());
		return data.editors.filter((editor: ManagedEditor) => {
			const text = normalizeSearch(`${editor.nombre_completo} ${editor.email} ${editor.institucion ?? ''}`);
			return text.includes(query)
				&& (!roles.length || roles.includes(editor.roleTerm))
				&& (!statuses.length || statuses.includes(editor.invitationStatus))
				&& (!access.length || access.includes(editor.activo === false ? 'blocked' : 'allowed'));
		}).sort((a, b) => {
			const byName = collator.compare(a.nombre_completo, b.nombre_completo);
			const comparison = sortField === 'editing' ? a.editingCount - b.editingCount
				: sortField === 'reviewing' ? a.reviewingCount - b.reviewingCount : byName;
			return (ascending ? comparison : -comparison) || byName;
		});
	});

	function clearFilters() {
		q = '';
		roles = [];
		statuses = [];
		access = [];
	}
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
	<header class="flex flex-wrap items-center justify-between gap-3">
		<h1 class="font-display text-3xl text-[color:var(--gray-900)]">Editores</h1>
		<Button variant={creating ? 'ghost' : 'dark'} onclick={() => creating = !creating}>
			{creating ? 'Cerrar alta' : 'Crear editor'}
		</Button>
	</header>
	{#if creating}
		<form class="space-y-4 border-b border-[color:var(--border)] pb-5" onsubmit={create}>
			<h2 class="text-lg font-semibold">Nuevo editor</h2><p class="text-sm text-[color:var(--muted-foreground)]">El correo de invitación se envía por separado.</p>
			<div class="grid gap-4 md:grid-cols-2">
				<label class="form-field"><span class="form-label">Nombre completo *</span><input class="border border-[color:var(--border)] p-2" required maxlength="200" bind:value={nombre} disabled={saving} /></label>
				<label class="form-field"><span class="form-label">Correo *</span><input class="border border-[color:var(--border)] p-2" type="email" required maxlength="255" bind:value={email} disabled={saving} /></label>
				<label class="form-field"><span class="form-label">Institución</span><input class="border border-[color:var(--border)] p-2" maxlength="200" bind:value={institucion} disabled={saving} /></label>
				<label class="form-field"><span class="form-label">ORCID</span><input class="border border-[color:var(--border)] p-2" placeholder="0000-0000-0000-0000" maxlength="19" bind:value={orcid} disabled={saving} /></label>
			</div>
			{#if message}<p role="alert" class="text-sm text-[color:var(--danger)]">{message}</p>{/if}
			<Button type="submit" variant="dark" loading={saving}>Crear editor</Button>
		</form>
	{/if}
	<div>
		<div class="mb-3 grid gap-2 sm:grid-cols-3">
			{#each [
				{ label: 'Rol', items: roleOptions, selectedIds: roles, onChange: (ids: string[]) => (roles = ids) },
				{ label: 'Invitación', items: invitationOptions, selectedIds: statuses, onChange: (ids: string[]) => (statuses = ids) },
				{ label: 'Permiso de acceso', items: accessOptions, selectedIds: access, onChange: (ids: string[]) => (access = ids) }
			] as filter (filter.label)}
				<div class="form-field min-w-0">
					<span class="form-label">{filter.label}</span>
					<CheckDropdown {...filter} multiple search portal closeOnSelect={false} placeholder="Todos" />
				</div>
			{/each}
		</div>
		<div class="mb-2 flex flex-wrap items-center gap-2 text-sm text-[color:var(--muted-foreground)]">
			<span>{visible.length} de {data.editors.length} editores</span>
			{#if hasFilters}
				<button type="button" class="inline-flex items-center gap-1 px-1 py-0.5 hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)]" onclick={clearFilters}>
					<X size={14} aria-hidden="true" /> Limpiar filtros
				</button>
			{/if}
		</div>
		<TableToolbar>
			{#snippet search()}
				<TableSearch bind:value={q} label="Buscar editor" />
			{/snippet}
			{#snippet controls()}
				<label class="flex items-center gap-2">
					Ordenar por
					<select class="h-8 border border-[color:var(--border)] bg-white px-2" value={sortField}
						onchange={(event) => {
							sortField = event.currentTarget.value as typeof sortField;
							ascending = sortField === 'name';
						}}>
						<option value="name">Nombre</option>
						<option value="editing">Obras en edición</option>
						<option value="reviewing">Obras en revisión</option>
					</select>
				</label>
				<button type="button" class={iconAction} onclick={() => (ascending = !ascending)}
					aria-label={ascending ? 'Orden ascendente. Cambiar a descendente' : 'Orden descendente. Cambiar a ascendente'}>
					{#if ascending}<ArrowUp size={16} aria-hidden="true" />{:else}<ArrowDown size={16} aria-hidden="true" />{/if}
				</button>
			{/snippet}
		</TableToolbar>
		<Table>
			<thead>
				<tr>
					<th scope="col" class="px-3 py-2">Editor</th>
					<th scope="col" class="px-3 py-2">Rol</th>
					<th scope="col" class="px-3 py-2">Invitación</th>
					<th scope="col" class="px-3 py-2">Permiso de acceso</th>
					<th scope="col" class="px-3 py-2">Obras en edición</th>
					<th scope="col" class="px-3 py-2">Obras en revisión</th>
					<th scope="col" class="px-3 py-2 text-right">Acciones</th>
				</tr>
			</thead>
			<tbody>
				{#each visible as editor (editor.user_id)}
					<tr class="border-t border-[color:var(--border)]">
						<th scope="row" class="px-3 py-2 text-left font-normal">
							<a class="font-medium hover:underline" href={`/dashboard/editores/${editor.user_id}`}>{editor.nombre_completo}</a>
							<p class="text-xs text-[color:var(--muted-foreground)]">{editor.email}</p>
							{#if editor.institucion}<p class="text-xs text-[color:var(--muted-foreground)]">{editor.institucion}</p>{/if}
						</th>
						<td class="px-3 py-2">{roleLabels[editor.roleTerm] ?? editor.roleTerm}</td>
						<td class="px-3 py-2">{invitationLabels[editor.invitationStatus]}</td>
						<td class="px-3 py-2">{editor.activo === false ? 'Bloqueado' : 'Permitido'}</td>
						<td class="px-3 py-2 tabular-nums">{editor.editingCount}</td>
						<td class="px-3 py-2 tabular-nums">{editor.reviewingCount}</td>
						<td class="px-3 py-2 text-right">
							<a class={iconAction} href={`/dashboard/editores/${editor.user_id}`} title="Gestionar editor"
								aria-label={`Gestionar a ${editor.nombre_completo}`}>
								<Pencil size={16} aria-hidden="true" />
							</a>
						</td>
					</tr>
				{:else}
					<tr><td colspan="7" class="px-3 py-4 text-[color:var(--muted-foreground)]">No hay editores que coincidan con los filtros.</td></tr>
				{/each}
			</tbody>
		</Table>
	</div>
</section>

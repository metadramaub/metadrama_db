<script lang="ts">
	import { goto } from '$app/navigation';
	import ObrasTable from '$lib/components/dashboard/ObrasTable.svelte';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { displayTerm } from '$lib/utils/vocabulario';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
	let q = $state('');
	let estado = $state('');
	let editor = $state('');
	let scope = $state<'mine' | 'all'>('mine');

	let createModalOpen = $state(false);
	let creating = $state(false);
	let newObraTitle = $state('');
	let newObraEditor = $state('');

	const canReadAll = $derived(['admin', 'ip'].includes(data.profile.roleTerm));
	const canCreate = $derived(['admin', 'ip'].includes(data.profile.roleTerm));
	const estadoDropdownItems = $derived(
		data.estadoOptions.map((option: { termino_id: string; termino: string; etiqueta?: string | null }) => ({
			id: option.termino_id,
			label: displayTerm(option)
		}))
	);
	const editorDropdownItems = $derived(
		data.editorOptions.map((option: { user_id: string; nombre_completo: string }) => ({
			id: option.user_id,
			label: option.nombre_completo
		}))
	);

	$effect(() => {
		q = data.filters.q;
		estado = data.filters.estado;
		editor = data.filters.editor;
		scope = data.scope;
		if (!newObraEditor && data.editorOptions.length > 0) {
			newObraEditor = data.editorOptions[0].user_id;
		}
	});

	function applyFilters(event: SubmitEvent) {
		event.preventDefault();
		const params = new URLSearchParams();
		params.set('scope', scope);
		if (q.trim()) params.set('q', q.trim());
		if (estado) params.set('estado', estado);
		if (editor) params.set('editor', editor);
		goto(`/dashboard/obras?${params.toString()}`);
	}

	function goScope(nextScope: 'mine' | 'all') {
		const params = new URLSearchParams();
		params.set('scope', nextScope);
		if (q.trim()) params.set('q', q.trim());
		if (estado) params.set('estado', estado);
		if (editor) params.set('editor', editor);
		goto(`/dashboard/obras?${params.toString()}`);
	}

	async function createObra() {
		if (creating) return;
		if (!newObraTitle.trim()) {
			pushToast('error', 'Indica un título para la nueva obra.');
			return;
		}
		if (!newObraEditor) {
			pushToast('error', 'Selecciona editor asignado.');
			return;
		}

		creating = true;
		const response = await fetch('/api/obras', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				titulo: newObraTitle.trim(),
				editor_asignado: newObraEditor
			})
		});
		creating = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo crear la obra.');
			return;
		}

		const payload = await response.json();
		pushToast('success', 'Obra creada');
		createModalOpen = false;
		newObraTitle = '';
		await goto(`/dashboard/obras/${payload.obra.obra_id}`);
	}
</script>

<section>
	<div class="mb-4 flex items-end justify-between gap-4">
		<div>
			<h1 class="font-display text-3xl">OBRAS</h1>
			<p class="text-sm text-[color:var(--muted-foreground)]">Listado de obras disponibles para edición.</p>
		</div>
		{#if canCreate}
			<Button variant="secondary" onclick={() => (createModalOpen = true)}>Crear nueva obra</Button>
		{/if}
	</div>

	<div class="mb-4 flex flex-wrap gap-2">
		<Button
			variant={scope === 'mine' ? 'primary' : 'ghost'}
			onclick={() => goScope('mine')}
		>
			Mis obras
		</Button>
		<Button
			variant={scope === 'all' ? 'primary' : 'ghost'}
			onclick={() => goScope('all')}
		>
			Todas las obras
		</Button>
	</div>

	<form class="card mb-4 grid gap-3 p-4 md:grid-cols-4" onsubmit={applyFilters}>
		<label class="form-field">
			<span class="form-label">Buscar título</span>
			<input
				type="text"
				bind:value={q}
				class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
			/>
		</label>

		<label class="form-field">
			<span class="form-label">Estado</span>
			<CheckDropdown
				multiple={false}
				allowSingleClear={true}
				search={estadoDropdownItems.length > 8}
				placeholder="Todos"
				items={estadoDropdownItems}
				selectedIds={estado ? [estado] : []}
				onChange={(ids) => {
					estado = ids[0] ?? '';
				}}
			/>
		</label>

		<label class="form-field">
			<span class="form-label">Editor asignado</span>
			<CheckDropdown
				multiple={false}
				allowSingleClear={true}
				search={editorDropdownItems.length > 8}
				placeholder="Todos"
				items={editorDropdownItems}
				disabled={!canReadAll}
				selectedIds={editor ? [editor] : []}
				onChange={(ids) => {
					editor = ids[0] ?? '';
				}}
			/>
		</label>

		<div class="flex items-end">
			<Button type="submit" class="w-full">Aplicar filtros</Button>
		</div>
	</form>

	<ObrasTable
		obras={data.obras}
		on:open={(event) => goto(`/dashboard/obras/${event.detail}`)}
	/>
</section>

{#if createModalOpen}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-lg p-5">
			<h3 class="text-lg font-semibold">Crear obra</h3>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Se creará en estado borrador y se abrirá el editor inmediatamente.
			</p>

			<div class="mt-4 space-y-3">
				<label class="form-field">
					<span class="form-label">Título *</span>
					<input
						type="text"
						bind:value={newObraTitle}
						class="w-full border border-[color:var(--border)] px-3 py-2"
					/>
				</label>

				<label class="form-field">
					<span class="form-label">Editor asignado *</span>
					<CheckDropdown
						multiple={false}
						search={editorDropdownItems.length > 8}
						placeholder="Seleccionar editor"
						items={editorDropdownItems}
						selectedIds={newObraEditor ? [newObraEditor] : []}
						onChange={(ids) => {
							const nextEditor = ids[0] ?? '';
							if (!nextEditor) return;
							newObraEditor = nextEditor;
						}}
					/>
				</label>
			</div>

			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={() => (createModalOpen = false)}>Cancelar</Button>
				<Button onclick={createObra} disabled={creating}>
					{creating ? 'Creando...' : 'Crear obra'}
				</Button>
			</div>
		</div>
	</div>
{/if}



<script lang="ts">
	import { invalidateAll } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import type { PageData } from './$types';

	type VocabRow = PageData['vocabularios'][number];

	let { data } = $props<{ data: PageData }>();
	let search = $state('');
	let categoryFilter = $state('');
	let createOpen = $state(false);
	let createSaving = $state(false);
	let editSaving = $state(false);
	let creating = $state({
		categoria: '',
		termino: '',
		orden: ''
	});
	let editingRow = $state<VocabRow | null>(null);
	let editing = $state({
		termino: '',
		orden: '',
		nivel: '',
		patron_especifico: '',
		activo: true
	});

	const categories = $derived(
		[...new Set(data.vocabularios.map((item: VocabRow) => item.categoria))]
			.filter((category): category is string => Boolean(category))
			.sort((a: string, b: string) => a.localeCompare(b, 'es'))
	);
	const filtered = $derived.by(() => {
		const term = search.trim().toLowerCase();
		return data.vocabularios
			.filter((item: VocabRow) => !categoryFilter || item.categoria === categoryFilter)
			.filter(
				(item: VocabRow) =>
					!term ||
					item.termino.toLowerCase().includes(term) ||
					item.categoria.toLowerCase().includes(term)
			);
	});

	function isProtectedCategory(category: string): boolean {
		const normalized = category.trim().toLowerCase();
		return normalized === 'role_editor' || normalized === 'estado' || normalized === 'estado_revision';
	}

	function openEdit(row: VocabRow) {
		editingRow = row;
		editing = {
			termino: row.termino,
			orden: row.orden?.toString() ?? '',
			nivel: row.nivel?.toString() ?? '',
			patron_especifico: row.patron_especifico ?? '',
			activo: row.activo ?? true
		};
	}

	function closeEdit() {
		editingRow = null;
	}

	async function createTerm() {
		if (!data.canManage || createSaving) return;
		if (!creating.categoria.trim() || !creating.termino.trim()) {
			pushToast('error', 'Categoria y termino son obligatorios.');
			return;
		}
		createSaving = true;
		const response = await fetch('/api/vocabularios', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				categoria: creating.categoria.trim(),
				termino: creating.termino.trim(),
				orden: creating.orden.trim() ? Number(creating.orden) : null
			})
		});
		createSaving = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo crear el termino.');
			return;
		}
		pushToast('success', 'Termino creado');
		createOpen = false;
		creating = { categoria: '', termino: '', orden: '' };
		await invalidateAll();
	}

	async function saveEdit() {
		if (!editingRow || editSaving) return;
		editSaving = true;
		const response = await fetch(`/api/vocabularios/${editingRow.termino_id}`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				termino: editing.termino.trim(),
				orden: editing.orden.trim() ? Number(editing.orden) : null,
				nivel: editing.nivel.trim() ? Number(editing.nivel) : null,
				patron_especifico: editing.patron_especifico.trim() || null,
				activo: editing.activo
			})
		});
		editSaving = false;
		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo actualizar el termino.');
			return;
		}
		pushToast('success', 'Termino actualizado');
		closeEdit();
		await invalidateAll();
	}
</script>

<section>
	<div class="mb-4 flex items-end justify-between gap-4">
		<div>
			<h1 class="text-2xl font-semibold">Vocabularios</h1>
			<p class="text-sm text-[color:var(--muted-foreground)]">
				CRUD basico de terminos. Las categorias protegidas son de solo lectura.
			</p>
		</div>
		{#if data.canManage}
			<Button variant="secondary" onclick={() => (createOpen = true)}>Nuevo termino</Button>
		{/if}
	</div>

	<div class="card mb-4 grid gap-3 p-4 md:grid-cols-2">
		<label class="text-sm">
			<span class="mb-1 block">Buscar</span>
			<input
				type="text"
				bind:value={search}
				class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
			/>
		</label>
		<label class="text-sm">
			<span class="mb-1 block">Categoria</span>
			<select
				bind:value={categoryFilter}
				class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
			>
				<option value="">Todas</option>
				{#each categories as category}
					<option value={category}>{category}</option>
				{/each}
			</select>
		</label>
	</div>

	<div class="card overflow-x-auto">
		<table class="min-w-full text-left text-sm">
			<thead class="bg-[color:var(--muted)]">
				<tr>
					<th class="px-3 py-2">Categoria</th>
					<th class="px-3 py-2">Termino</th>
					<th class="px-3 py-2">Orden</th>
					<th class="px-3 py-2">Activo</th>
					<th class="px-3 py-2">Acciones</th>
				</tr>
			</thead>
			<tbody>
				{#if filtered.length === 0}
					<tr>
						<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={5}>
							Sin resultados.
						</td>
					</tr>
				{:else}
					{#each filtered as row}
						<tr class="border-t border-[color:var(--border)]">
							<td class="px-3 py-2">{row.categoria}</td>
							<td class="px-3 py-2">{row.termino}</td>
							<td class="px-3 py-2">{row.orden ?? '-'}</td>
							<td class="px-3 py-2">{row.activo ? 'si' : 'no'}</td>
							<td class="px-3 py-2">
								{#if data.canManage && !isProtectedCategory(row.categoria)}
									<Button variant="ghost" onclick={() => openEdit(row)}>Editar</Button>
								{:else}
									<span class="text-xs text-[color:var(--muted-foreground)]">Solo lectura</span>
								{/if}
							</td>
						</tr>
					{/each}
				{/if}
			</tbody>
		</table>
	</div>
</section>

{#if createOpen}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-lg p-5">
			<h3 class="text-lg font-semibold">Nuevo termino</h3>
			<div class="mt-3 grid gap-3">
				<label class="text-sm">
					<span class="mb-1 block">Categoria</span>
					<input
						type="text"
						bind:value={creating.categoria}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Termino</span>
					<input
						type="text"
						bind:value={creating.termino}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Orden</span>
					<input
						type="number"
						bind:value={creating.orden}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
			</div>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={() => (createOpen = false)}>Cancelar</Button>
				<Button onclick={createTerm} disabled={createSaving}>{createSaving ? 'Guardando...' : 'Crear'}</Button>
			</div>
		</div>
	</div>
{/if}

{#if editingRow}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-lg p-5">
			<h3 class="text-lg font-semibold">Editar termino</h3>
			<div class="mt-3 grid gap-3">
				<label class="text-sm">
					<span class="mb-1 block">Categoria</span>
					<input
						type="text"
						value={editingRow.categoria}
						disabled
						class="w-full rounded-md border border-[color:var(--border)] bg-[color:var(--muted)] px-3 py-2"
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Termino</span>
					<input
						type="text"
						bind:value={editing.termino}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Orden</span>
					<input
						type="number"
						bind:value={editing.orden}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Nivel</span>
					<input
						type="number"
						bind:value={editing.nivel}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
				<label class="text-sm">
					<span class="mb-1 block">Patron especifico</span>
					<textarea
						rows={3}
						bind:value={editing.patron_especifico}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					></textarea>
				</label>
				<label class="flex items-center gap-2 text-sm">
					<input type="checkbox" bind:checked={editing.activo} />
					Activo
				</label>
			</div>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={closeEdit}>Cancelar</Button>
				<Button onclick={saveEdit} disabled={editSaving}>{editSaving ? 'Guardando...' : 'Guardar'}</Button>
			</div>
		</div>
	</div>
{/if}

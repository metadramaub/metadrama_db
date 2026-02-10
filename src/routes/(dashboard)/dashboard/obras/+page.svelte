<script lang="ts">
	import { goto } from '$app/navigation';
	import ObrasTable from '$lib/components/dashboard/ObrasTable.svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
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
			pushToast('error', 'Indica un titulo para la nueva obra.');
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
			<h1 class="text-3xl font-semibold">Obras</h1>
			<p class="text-sm text-[color:var(--muted-foreground)]">Listado de obras disponibles para edicion.</p>
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
		<label class="text-sm">
			<span class="mb-1 block">Buscar titulo</span>
			<input
				type="text"
				bind:value={q}
				class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
			/>
		</label>

		<label class="text-sm">
			<span class="mb-1 block">Estado</span>
			<select
				bind:value={estado}
				class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
			>
				<option value="">Todos</option>
				{#each data.estadoOptions as opt}
					<option value={opt.termino_id}>{opt.termino}</option>
				{/each}
			</select>
		</label>

		<label class="text-sm">
			<span class="mb-1 block">Editor asignado</span>
			<select
				bind:value={editor}
				disabled={!canReadAll}
				class="w-full rounded-md border border-[color:var(--border)] bg-white px-3 py-2 text-sm disabled:bg-[color:var(--muted)]"
			>
				<option value="">Todos</option>
				{#each data.editorOptions as opt}
					<option value={opt.user_id}>{opt.nombre_completo}</option>
				{/each}
			</select>
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
				Se creara en estado borrador y se abrira el editor inmediatamente.
			</p>

			<div class="mt-4 space-y-3">
				<label class="block text-sm">
					<span class="mb-1 block">Titulo *</span>
					<input
						type="text"
						bind:value={newObraTitle}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					/>
				</label>

				<label class="block text-sm">
					<span class="mb-1 block">Editor asignado *</span>
					<select
						bind:value={newObraEditor}
						class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					>
						{#each data.editorOptions as opt}
							<option value={opt.user_id}>{opt.nombre_completo}</option>
						{/each}
					</select>
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

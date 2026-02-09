<script lang="ts">
	import { goto } from '$app/navigation';
	import ObrasTable from '$lib/components/dashboard/ObrasTable.svelte';
	import Button from '$lib/components/ui/button.svelte';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
	let q = $state('');
	let estado = $state('');
	let editor = $state('');

	$effect(() => {
		q = data.filters.q;
		estado = data.filters.estado;
		editor = data.filters.editor;
	});

	function applyFilters(event: SubmitEvent) {
		event.preventDefault();
		const params = new URLSearchParams();
		if (q.trim()) params.set('q', q.trim());
		if (estado) params.set('estado', estado);
		if (editor) params.set('editor', editor);
		goto(`/dashboard/obras?${params.toString()}`);
	}
</script>

<section>
	<div class="mb-4 flex items-end justify-between gap-4">
		<div>
			<h1 class="text-3xl font-semibold">Obras</h1>
			<p class="text-sm text-[color:var(--muted-foreground)]">Listado de obras disponibles para edición.</p>
		</div>
		{#if ['admin', 'ip'].includes(data.profile.roleTerm)}
			<Button variant="secondary" disabled>Crear nueva obra</Button>
		{/if}
	</div>

	<form class="card mb-4 grid gap-3 p-4 md:grid-cols-4" onsubmit={applyFilters}>
		<label class="text-sm">
			<span class="mb-1 block">Buscar título</span>
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
				disabled={!['admin', 'ip', 'revisor'].includes(data.profile.roleTerm)}
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

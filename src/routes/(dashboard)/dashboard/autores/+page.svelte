<script lang="ts">
	import { goto } from '$app/navigation';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { formatRelative } from '$lib/utils/formatters';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
	let q = $state('');

	let createModalOpen = $state(false);
	let creating = $state(false);
	let nombreCompleto = $state('');
	let nombreNormalizado = $state('');
	let variantesText = $state('');
	let bnedatosId = $state('');
	let viafId = $state('');
	let wikidataId = $state('');

	const canManage = $derived(Boolean(data.canManageAuthors));

	$effect(() => {
		q = data.filters.q;
	});

	function applyFilters(event: SubmitEvent) {
		event.preventDefault();
		const params = new URLSearchParams();
		if (q.trim()) params.set('q', q.trim());
		const next = params.toString();
		goto(next ? `/dashboard/autores?${next}` : '/dashboard/autores');
	}

	function actionLabel() {
		return canManage ? 'Editar' : 'Ver';
	}

	function resetCreateForm() {
		nombreCompleto = '';
		nombreNormalizado = '';
		variantesText = '';
		bnedatosId = '';
		viafId = '';
		wikidataId = '';
	}

	function closeCreateModal() {
		if (creating) return;
		createModalOpen = false;
		resetCreateForm();
	}

	function parseVariants(value: string): string[] {
		return value
			.split('\n')
			.map((item) => item.trim())
			.filter(Boolean);
	}

	async function createAuthor() {
		if (creating) return;
		if (!nombreCompleto.trim()) {
			pushToast('error', 'Indica un nombre completo para el autor.');
			return;
		}
		if (!nombreNormalizado.trim()) {
			pushToast('error', 'Indica el nombre normalizado del autor.');
			return;
		}

		creating = true;
		const response = await fetch('/api/autores', {
			method: 'POST',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				nombre_completo: nombreCompleto.trim(),
				nombre_normalizado: nombreNormalizado.trim(),
				variantes_nombre: parseVariants(variantesText),
				bnedatos_id: bnedatosId,
				viaf_id: viafId,
				wikidata_id: wikidataId
			})
		});
		creating = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo crear el autor.');
			return;
		}

		const payload = await response.json();
		pushToast('success', 'Autor creado');
		createModalOpen = false;
		resetCreateForm();
		await goto(`/dashboard/autores/${payload.autor.autor_id}`);
	}
</script>

<section>
	<div class="mb-4 flex items-end justify-between gap-4">
		<div>
			<h1 class="font-display text-3xl">AUTORES</h1>
			<p class="text-sm text-[color:var(--muted-foreground)]">Listado de autores de la base de datos.</p>
		</div>
		{#if canManage}
			<Button variant="secondary" onclick={() => (createModalOpen = true)}>Crear nuevo autor</Button>
		{/if}
	</div>

	<form class="card mb-4 grid gap-3 p-4 md:grid-cols-[1fr_auto]" onsubmit={applyFilters}>
		<label class="form-field">
			<span class="form-label">Buscar autor</span>
			<input
				type="text"
				bind:value={q}
				placeholder="Nombre, variante o forma normalizada"
				class="w-full border border-[color:var(--border)] bg-white px-3 py-2 text-sm"
			/>
		</label>
		<div class="flex items-end">
			<Button type="submit" class="w-full">Aplicar filtros</Button>
		</div>
	</form>

	<div class="card overflow-x-auto">
		<table class="min-w-full text-left text-sm">
			<thead class="bg-[color:var(--muted)]">
				<tr>
					<th class="px-3 py-2">Autor</th>
					<th class="px-3 py-2">Obras</th>
					<th class="px-3 py-2">Última modificación</th>
					<th class="px-3 py-2">Acción</th>
				</tr>
			</thead>
			<tbody>
				{#if data.authors.length === 0}
					<tr>
						<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={4}>
							No hay autores para mostrar.
						</td>
					</tr>
				{:else}
					{#each data.authors as author}
						<tr class="border-t border-[color:var(--border)]">
							<td class="px-3 py-2">
								<div class="font-medium">{author.nombre_completo}</div>
								{#if author.variantes_nombre && author.variantes_nombre.length > 0}
									<div class="mt-1 text-xs text-[color:var(--muted-foreground)]">
										Variantes: {author.variantes_nombre.join(', ')}
									</div>
								{/if}
							</td>
							<td class="px-3 py-2">
								<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">
									{author.works_count}
								</span>
							</td>
							<td class="px-3 py-2">{formatRelative(author.updated_at)}</td>
							<td class="px-3 py-2">
								<Button variant="ghost" onclick={() => goto(`/dashboard/autores/${author.autor_id}`)}>
									{actionLabel()}
								</Button>
							</td>
						</tr>
					{/each}
				{/if}
			</tbody>
		</table>
	</div>
</section>

{#if createModalOpen}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-2xl p-5">
			<h3 class="text-lg font-semibold">Crear autor</h3>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Completa los datos mínimos y se abrirá la ficha del autor.
			</p>

			<div class="mt-4 grid gap-3 md:grid-cols-2">
				<label class="form-field md:col-span-2">
					<span class="form-label">Nombre completo *</span>
					<input
						type="text"
						bind:value={nombreCompleto}
						required
						class="w-full border border-[color:var(--border)] px-3 py-2"
					/>
				</label>

				<label class="form-field md:col-span-2">
					<span class="form-label">Nombre normalizado *</span>
					<input
						type="text"
						bind:value={nombreNormalizado}
						placeholder="Apellidos, Nombre"
						required
						class="w-full border border-[color:var(--border)] px-3 py-2"
					/>
					<span class="form-help">Se refiere a &quot;Apellidos, Nombre&quot;.</span>
				</label>

				<label class="form-field md:col-span-2">
					<span class="form-label">Variantes de nombre (una por línea)</span>
					<textarea
						rows={4}
						bind:value={variantesText}
						class="w-full border border-[color:var(--border)] px-3 py-2"
					></textarea>
				</label>

				<label class="form-field">
					<span class="form-label">BNEdatos ID</span>
					<input type="text" bind:value={bnedatosId} class="w-full border border-[color:var(--border)] px-3 py-2" />
				</label>

				<label class="form-field">
					<span class="form-label">VIAF ID</span>
					<input type="text" bind:value={viafId} class="w-full border border-[color:var(--border)] px-3 py-2" />
				</label>

				<label class="form-field md:col-span-2">
					<span class="form-label">Wikidata ID</span>
					<input
						type="text"
						bind:value={wikidataId}
						class="w-full border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
			</div>

			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={closeCreateModal} disabled={creating}>Cancelar</Button>
				<Button onclick={createAuthor} disabled={creating}>
					{creating ? 'Creando...' : 'Crear autor'}
				</Button>
			</div>
		</div>
	</div>
{/if}


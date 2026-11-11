<script lang="ts">
	import { portal } from '$lib/actions/portal';
	import { goto } from '$app/navigation';
	import { ArrowDown, ArrowUp, ExternalLink, Eye, Pencil } from 'lucide-svelte';
	import Button from '$lib/components/ui/button.svelte';
	import Table from '$lib/components/ui/table.svelte';
	import TableSearch from '$lib/components/ui/table-search.svelte';
	import TableToolbar from '$lib/components/ui/table-toolbar.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { formatRelative } from '$lib/utils/formatters';
	import type { PageData } from './$types';

	type SimilarAuthor = {
		autor_id: string;
		nombre_completo: string;
		nombre_normalizado: string;
		matched_value: string;
		reason: 'exact' | 'contains' | 'tokens' | 'distance';
		score: number;
	};

	let { data } = $props<{ data: PageData }>();
	let q = $state('');
	type SortField = 'nombre_completo' | 'nombre_normalizado' | 'works_count';
	let sortField = $state<SortField>('nombre_normalizado');
	let ascending = $state(true);
	const collator = new Intl.Collator('es', { sensitivity: 'base' });
	const sortedAuthors = $derived([...data.authors].sort((a, b) => {
		const comparison = sortField === 'works_count'
			? a.works_count - b.works_count
			: collator.compare(a[sortField] ?? a.nombre_completo, b[sortField] ?? b.nombre_completo);
		return (ascending ? comparison : -comparison) || collator.compare(a.nombre_completo, b.nombre_completo);
	}));
	const iconAction = 'inline-flex size-7 items-center justify-center rounded text-[color:var(--muted-foreground)] transition-colors hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)] focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2';

	let createModalOpen = $state(false);
	let creating = $state(false);
	let similarAuthors = $state<SimilarAuthor[]>([]);
	let nombreCompleto = $state('');
	let nombreNormalizado = $state('');
	let variantesText = $state('');
	let bnedatosId = $state('');
	let viafId = $state('');
	let wikidataId = $state('');

	const canManage = $derived(Boolean(data.canManageAuthors));
	const canCreate = $derived(Boolean(data.canCreateAuthors));

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

	const actionLabel = $derived(canManage ? 'Editar' : 'Ver');

	function resetCreateForm() {
		nombreCompleto = '';
		nombreNormalizado = '';
		variantesText = '';
		bnedatosId = '';
		viafId = '';
		wikidataId = '';
		similarAuthors = [];
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

	function onCreateFormInput() {
		if (similarAuthors.length > 0) {
			similarAuthors = [];
		}
	}

	function similarityReasonLabel(reason: SimilarAuthor['reason']): string {
		if (reason === 'exact') return 'coincidencia exacta';
		if (reason === 'contains') return 'nombre incluido';
		if (reason === 'tokens') return 'palabras coincidentes';
		return 'nombre muy parecido';
	}

	async function createAuthor(confirmSimilar = false) {
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
				wikidata_id: wikidataId,
				confirm_similar: confirmSimilar
			})
		});
		creating = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			if (response.status === 409 && body.error === 'similar_author') {
				similarAuthors = Array.isArray(body.similarAuthors) ? body.similarAuthors : [];
				pushToast('info', body.message ?? 'Revisa los autores parecidos antes de crear uno nuevo.', 5000);
				return;
			}
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
	<header class="mb-4 flex flex-wrap items-center justify-between gap-3">
		<h1 class="font-display text-3xl text-[color:var(--gray-900)]">Autores</h1>
		{#if canCreate}
			<Button variant="dark" onclick={() => (createModalOpen = true)}>Crear autor</Button>
		{/if}
	</header>

	<TableToolbar>
		{#snippet search()}
			<form class="flex gap-2" onsubmit={applyFilters}>
				<TableSearch bind:value={q} label="Buscar autor" />
				<button type="submit" class="h-8 border border-[color:var(--border)] px-2 hover:bg-[color:var(--muted)]">Buscar</button>
			</form>
		{/snippet}
		{#snippet controls()}
		<label class="flex items-center gap-2">
			Ordenar por
			<select class="h-8 border border-[color:var(--border)] bg-white px-2" value={sortField}
				onchange={(event) => {
					sortField = event.currentTarget.value as SortField;
					ascending = sortField !== 'works_count';
				}}>
				<option value="nombre_completo">Nombre</option>
				<option value="nombre_normalizado">Apellido</option>
				<option value="works_count">Número de obras</option>
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
					<th class="px-3 py-2">Autor</th>
					<th class="px-3 py-2">Obras</th>
					<th class="px-3 py-2">Última modificación</th>
					<th class="px-3 py-2">Wikidata</th>
					<th class="px-3 py-2 text-right">Acciones</th>
				</tr>
			</thead>
			<tbody>
				{#if data.authors.length === 0}
					<tr>
						<td class="px-3 py-4 text-[color:var(--muted-foreground)]" colspan={5}>
							No hay autores para mostrar.
						</td>
					</tr>
				{:else}
					{#each sortedAuthors as author (author.autor_id)}
						{@const nombreVisible = sortField === 'nombre_normalizado'
							? author.nombre_normalizado || author.nombre_completo
							: author.nombre_completo}
						<tr class="border-t border-[color:var(--border)]">
							<td class="px-3 py-2">
								<div class="font-medium">{nombreVisible}</div>
								{#if nombreVisible !== author.nombre_completo}
									<div class="mt-1 text-xs text-[color:var(--muted-foreground)]">{author.nombre_completo}</div>
								{/if}
								{#if author.variantes_nombre && author.variantes_nombre.length > 0}
									<div class="mt-1 text-xs text-[color:var(--muted-foreground)]">
										Variantes: {author.variantes_nombre.join(', ')}
									</div>
								{/if}
							</td>
							<td class="px-3 py-2">
								{author.works_count}
							</td>
							<td class="px-3 py-2">{formatRelative(author.updated_at)}</td>
							<td class="px-3 py-2">
								{#if author.wikidata_id}
									<a class={iconAction} href={`https://www.wikidata.org/wiki/${encodeURIComponent(author.wikidata_id)}`}
										target="_blank" rel="noopener noreferrer" title="Abrir en Wikidata"
										aria-label={`Abrir ${author.nombre_completo} en Wikidata (nueva pestaña)`}>
										<ExternalLink size={16} aria-hidden="true" />
									</a>
								{/if}
							</td>
							<td class="px-3 py-2 text-right">
								<a class={iconAction} href={`/dashboard/autores/${author.autor_id}`} title={actionLabel}
									aria-label={`${actionLabel} a ${author.nombre_completo}`}>
									{#if canManage}<Pencil size={16} aria-hidden="true" />{:else}<Eye size={16} aria-hidden="true" />{/if}
								</a>
							</td>
						</tr>
					{/each}
				{/if}
			</tbody>
	</Table>
</section>

{#if createModalOpen}
	<div use:portal class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
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
						oninput={onCreateFormInput}
						required
						class="w-full border border-[color:var(--border)] px-3 py-2"
					/>
				</label>

				<label class="form-field md:col-span-2">
					<span class="form-label">Nombre normalizado *</span>
					<input
						type="text"
						bind:value={nombreNormalizado}
						oninput={onCreateFormInput}
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
						oninput={onCreateFormInput}
						class="w-full border border-[color:var(--border)] px-3 py-2"
					></textarea>
				</label>

				<label class="form-field">
					<span class="form-label">BNEdatos ID</span>
					<input
						type="text"
						bind:value={bnedatosId}
						oninput={onCreateFormInput}
						class="w-full border border-[color:var(--border)] px-3 py-2"
					/>
				</label>

				<label class="form-field">
					<span class="form-label">VIAF ID</span>
					<input
						type="text"
						bind:value={viafId}
						oninput={onCreateFormInput}
						class="w-full border border-[color:var(--border)] px-3 py-2"
					/>
				</label>

				<label class="form-field md:col-span-2">
					<span class="form-label">Wikidata ID</span>
					<input
						type="text"
						bind:value={wikidataId}
						oninput={onCreateFormInput}
						class="w-full border border-[color:var(--border)] px-3 py-2"
					/>
				</label>
			</div>

			{#if similarAuthors.length > 0}
				<div class="mt-4 border border-[color:var(--warning)] bg-[color:var(--muted)] p-3">
					<h4 class="text-sm font-semibold">Posibles autores duplicados</h4>
					<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
						Revisa estas coincidencias antes de crear una ficha nueva.
					</p>
					<ul class="mt-3 space-y-2 text-sm">
						{#each similarAuthors as author}
							<li class="border border-[color:var(--border)] bg-white p-3">
								<div class="flex flex-wrap items-center justify-between gap-2">
									<div>
										<div class="font-medium">{author.nombre_completo}</div>
										<div class="text-xs text-[color:var(--muted-foreground)]">
											{author.nombre_normalizado}
										</div>
									</div>
									<Button
										variant="ghost"
										class="px-2 py-1 text-xs"
										onclick={() => goto(`/dashboard/autores/${author.autor_id}`)}
									>
										Ver
									</Button>
								</div>
								<div class="mt-2 text-xs text-[color:var(--muted-foreground)]">
									{similarityReasonLabel(author.reason)}: {author.matched_value}
								</div>
							</li>
						{/each}
					</ul>
				</div>
			{/if}

			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={closeCreateModal} disabled={creating}>Cancelar</Button>
				<Button onclick={() => void createAuthor(similarAuthors.length > 0)} disabled={creating}>
					{creating ? 'Creando...' : similarAuthors.length > 0 ? 'Crear de todos modos' : 'Crear autor'}
				</Button>
			</div>
		</div>
	</div>
{/if}

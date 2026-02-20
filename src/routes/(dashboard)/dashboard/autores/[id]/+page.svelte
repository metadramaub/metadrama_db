<script lang="ts">
	import { goto } from '$app/navigation';
	import { onDestroy } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { formatRelative } from '$lib/utils/formatters';
	import { isAuthorFormDirty, splitAuthorVariantsText } from '$lib/utils/author-form';
	import type { Tables } from '$lib/types/database.types';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
	type RelatedWork = PageData['obras'][number];

	function getCurrentAuthorData(): Tables<'autores'> {
		return data.autor as Tables<'autores'>;
	}

	function getCurrentWorksCount(): number {
		return data.worksCount;
	}

	function getCurrentWorks(): PageData['obras'] {
		return data.obras;
	}

	let autor = $state(getCurrentAuthorData());
	let worksCount = $state(getCurrentWorksCount());
	let obras = $state(getCurrentWorks());

	let nombreCompleto = $state(getCurrentAuthorData().nombre_completo ?? '');
	let variantesText = $state((getCurrentAuthorData().variantes_nombre ?? []).join('\n'));
	let bnedatosId = $state(getCurrentAuthorData().bnedatos_id ?? '');
	let viafId = $state(getCurrentAuthorData().viaf_id ?? '');
	let wikidataId = $state(getCurrentAuthorData().wikidata_id ?? '');

	let saving = $state(false);
	let deleting = $state(false);
	let showDeleteModal = $state(false);
	let deleteConfirmText = $state('');
	let autosaveTimer = $state<ReturnType<typeof setTimeout> | null>(null);
	let lastHydrationKey = buildHydrationKey(
		getCurrentAuthorData(),
		getCurrentWorksCount(),
		getCurrentWorks()
	);

	const readOnly = $derived(!data.canManageAuthor);
	const canDelete = $derived(Boolean(data.canDeleteAuthor));
	const deleteBlocked = $derived(worksCount > 0);
	const deleteConfirmed = $derived(deleteConfirmText.trim() === 'ELIMINAR');

	function clearAutosaveTimer() {
		if (autosaveTimer) {
			clearTimeout(autosaveTimer);
			autosaveTimer = null;
		}
	}

	function buildHydrationKey(
		nextAuthor: Tables<'autores'>,
		nextWorksCount: number,
		nextObras: PageData['obras']
	): string {
		const obrasKey = nextObras
			.map((obra: RelatedWork) => `${obra.obra_id}:${obra.updated_at ?? ''}`)
			.join('|');
		return `${nextAuthor.autor_id}:${nextAuthor.updated_at ?? ''}:${nextWorksCount}:${obrasKey}`;
	}

	function syncFormFromAuthor(nextAuthor: Tables<'autores'>) {
		nombreCompleto = nextAuthor.nombre_completo ?? '';
		variantesText = (nextAuthor.variantes_nombre ?? []).join('\n');
		bnedatosId = nextAuthor.bnedatos_id ?? '';
		viafId = nextAuthor.viaf_id ?? '';
		wikidataId = nextAuthor.wikidata_id ?? '';
	}

	$effect(() => {
		const nextAuthor = data.autor as Tables<'autores'>;
		const nextWorksCount = data.worksCount;
		const nextObras = data.obras;
		const nextHydrationKey = buildHydrationKey(nextAuthor, nextWorksCount, nextObras);
		if (nextHydrationKey === lastHydrationKey) return;

		lastHydrationKey = nextHydrationKey;
		autor = nextAuthor;
		worksCount = nextWorksCount;
		obras = nextObras;
		syncFormFromAuthor(nextAuthor);
		clearAutosaveTimer();
	});

	const formDirty = $derived.by(() =>
		isAuthorFormDirty(autor, {
			nombreCompleto,
			variantesText,
			bnedatosId,
			viafId,
			wikidataId
		})
	);

	function queueAutosave() {
		if (readOnly || saving || !formDirty) {
			clearAutosaveTimer();
			return;
		}
		clearAutosaveTimer();
		autosaveTimer = setTimeout(() => {
			void saveAuthor('autosave');
		}, 10_000);
	}

	function onFormInput() {
		queueAutosave();
	}

	async function saveAuthor(source: 'manual' | 'autosave' = 'manual') {
		if (readOnly || saving || !formDirty) return;
		if (!nombreCompleto.trim()) {
			if (source === 'manual') {
				pushToast('error', 'El nombre completo es obligatorio.');
			}
			return;
		}

		clearAutosaveTimer();
		saving = true;
		const response = await fetch(`/api/autores/${autor.autor_id}`, {
			method: 'PATCH',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({
				nombre_completo: nombreCompleto.trim(),
				variantes_nombre: splitAuthorVariantsText(variantesText),
				bnedatos_id: bnedatosId,
				viaf_id: viafId,
				wikidata_id: wikidataId
			})
		});
		saving = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo guardar el autor.');
			return;
		}

		const payload = await response.json();
		autor = payload.autor as Tables<'autores'>;
		worksCount = payload.works_count ?? worksCount;
		obras = payload.obras ?? obras;
		syncFormFromAuthor(autor);
		if (source === 'manual') {
			pushToast('success', 'Autor actualizado');
		}
	}

	function openDeleteModal() {
		if (!canDelete || deleting || deleteBlocked) return;
		deleteConfirmText = '';
		showDeleteModal = true;
	}

	function closeDeleteModal() {
		if (deleting) return;
		showDeleteModal = false;
		deleteConfirmText = '';
	}

	async function deleteAuthor() {
		if (!canDelete || deleting || deleteBlocked || !deleteConfirmed) return;
		clearAutosaveTimer();
		deleting = true;
		const response = await fetch(`/api/autores/${autor.autor_id}`, {
			method: 'DELETE',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify({ confirmText: deleteConfirmText.trim() })
		});
		deleting = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			pushToast('error', body.message ?? 'No se pudo eliminar el autor.');
			return;
		}

		pushToast('success', 'Autor eliminado correctamente.');
		showDeleteModal = false;
		await goto('/dashboard/autores', { invalidateAll: true });
	}

	onDestroy(() => {
		clearAutosaveTimer();
	});
</script>

<section class="space-y-4">
	<div class="mb-2">
		<h1 class="text-3xl font-semibold">{autor.nombre_completo}</h1>
		<div class="mt-2 flex flex-wrap items-center gap-2 text-sm text-[color:var(--muted-foreground)]">
			<span>ID autor: {autor.autor_id}</span>
			<span class="border border-[color:var(--border)] bg-[color:var(--muted)] px-2 py-1 text-xs">
				Aparece en {worksCount} obras
			</span>
		</div>
	</div>

	<div class="card p-4">
		<div class="mb-3 flex items-center justify-between gap-2">
			<h2 class="text-lg font-semibold">Datos del autor</h2>
			{#if readOnly}
				<span class="text-xs text-[color:var(--muted-foreground)]">Modo solo lectura</span>
			{/if}
		</div>

		<div class="grid gap-3 md:grid-cols-2">
			<label class="block text-sm md:col-span-2">
				<span class="mb-1 block">Nombre completo *</span>
				<input
					type="text"
					bind:value={nombreCompleto}
					oninput={onFormInput}
					disabled={readOnly}
					class="w-full border border-[color:var(--border)] px-3 py-2 disabled:bg-[color:var(--muted)]"
				/>
			</label>

			<label class="block text-sm md:col-span-2">
				<span class="mb-1 block">Variantes de nombre (una por línea)</span>
				<textarea
					rows={4}
					bind:value={variantesText}
					oninput={onFormInput}
					disabled={readOnly}
					class="w-full border border-[color:var(--border)] px-3 py-2 disabled:bg-[color:var(--muted)]"
				></textarea>
			</label>

			<label class="block text-sm">
				<span class="mb-1 block">BNEdatos ID</span>
				<input
					type="text"
					bind:value={bnedatosId}
					oninput={onFormInput}
					disabled={readOnly}
					class="w-full border border-[color:var(--border)] px-3 py-2 disabled:bg-[color:var(--muted)]"
				/>
			</label>

			<label class="block text-sm">
				<span class="mb-1 block">VIAF ID</span>
				<input
					type="text"
					bind:value={viafId}
					oninput={onFormInput}
					disabled={readOnly}
					class="w-full border border-[color:var(--border)] px-3 py-2 disabled:bg-[color:var(--muted)]"
				/>
			</label>

			<label class="block text-sm md:col-span-2">
				<span class="mb-1 block">Wikidata ID</span>
				<input
					type="text"
					bind:value={wikidataId}
					oninput={onFormInput}
					disabled={readOnly}
					class="w-full border border-[color:var(--border)] px-3 py-2 disabled:bg-[color:var(--muted)]"
				/>
			</label>
		</div>

		{#if !readOnly}
			<div class="mt-4 flex justify-end">
				<Button variant="success" onclick={() => void saveAuthor('manual')} disabled={saving || !formDirty}>
					{saving ? 'Guardando...' : 'Guardar'}
				</Button>
			</div>
		{/if}
	</div>

	<div class="card p-4">
		<h2 class="mb-3 text-lg font-semibold">Obras relacionadas</h2>
		{#if obras.length === 0}
			<p class="text-sm text-[color:var(--muted-foreground)]">Este autor no aparece en obras accesibles con tu perfil.</p>
		{:else}
			<ul class="space-y-2 text-sm">
				{#each obras as obra}
					<li class="flex flex-wrap items-center justify-between gap-2 border-b border-[color:var(--border)] pb-2 last:border-b-0 last:pb-0">
						<button
							class="underline-offset-2 hover:underline"
							onclick={() => goto(`/dashboard/obras/${obra.obra_id}`)}
						>
							{obra.titulo}
						</button>
						<span class="text-xs text-[color:var(--muted-foreground)]">{formatRelative(obra.updated_at)}</span>
					</li>
				{/each}
			</ul>
		{/if}
	</div>

	{#if canDelete}
		<div>
			<h3 class="mb-2 text-lg font-semibold text-[color:var(--danger)]">Zona de peligro</h3>
			<div class="overflow-hidden border border-[color:var(--danger)] bg-white">
				<div class="flex flex-col gap-3 p-4 sm:flex-row sm:items-center sm:justify-between">
					<div>
						<h4 class="text-sm font-semibold text-[color:var(--danger)]">Eliminar este autor</h4>
						{#if deleteBlocked}
							<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
								No se puede eliminar porque aparece en {worksCount} obras.
							</p>
						{:else}
							<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
								Esta acción es irreversible. Solo disponible si no hay obras asociadas.
							</p>
						{/if}
					</div>
					<Button variant="danger" onclick={openDeleteModal} disabled={deleting || deleteBlocked}>
						Eliminar autor
					</Button>
				</div>
			</div>
		</div>
	{/if}
</section>

{#if showDeleteModal}
	<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 p-4">
		<div class="card w-full max-w-md p-5">
			<h3 class="text-lg font-semibold text-[color:var(--danger)]">Confirmar eliminación</h3>
			<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
				Escribe <strong>ELIMINAR</strong> para confirmar.
			</p>
			<label class="mt-3 block text-sm">
				<span class="mb-1 block">Confirmación</span>
				<input
					type="text"
					class="w-full border border-[color:var(--border)] px-3 py-2"
					bind:value={deleteConfirmText}
					autocomplete="off"
					spellcheck={false}
				/>
			</label>
			<div class="mt-4 flex justify-end gap-2">
				<Button variant="ghost" onclick={closeDeleteModal} disabled={deleting}>Cancelar</Button>
				<Button variant="danger" onclick={deleteAuthor} disabled={deleting || !deleteConfirmed}>
					{deleting ? 'Eliminando...' : 'Eliminar'}
				</Button>
			</div>
		</div>
	</div>
{/if}

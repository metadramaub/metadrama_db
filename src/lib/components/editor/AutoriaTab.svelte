<script lang="ts">
	import { onMount } from 'svelte';
	import Button from '$lib/components/ui/button.svelte';
	import CheckDropdown from '$lib/components/ui/check-dropdown.svelte';
	import AuthorSelector from '$lib/components/editor/AuthorSelector.svelte';
	import InternalCommentsPanel from '$lib/components/editor/InternalCommentsPanel.svelte';
	import { pushToast } from '$lib/stores/toast';
	import { markSaved, patchCurrentObra, setDirty, setSaving } from '$lib/stores/currentObra';
	import type { Tables } from '$lib/types/database.types';
	import type { AutoriaApiPayload } from '$lib/types/obra.types';

	type CatalogItem = {
		termino_id: string;
		termino: string;
	};

	type DraftAttribution = {
		local_id: string;
		jornada_id: string | null;
		tipo_atribucion_id: string;
		modalidad_atribucion_id: string;
		fuente: string;
		url: string;
		adoptada: boolean;
		notas: string;
		autor_ids: string[];
	};

	type ScopeView = 'obra' | 'jornadas';

	const props = $props<{
		obraId: string;
		obra: Tables<'obras'>;
		roleTerm: string;
		readOnly?: boolean;
		canComment?: boolean;
	}>();

	let loading = $state(true);
	let loadingFromServer = $state(false);
	let savingNow = $state(false);
	let loadError = $state<string | null>(null);

	let jornadas = $state<Array<Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>>>([]);
	let autores = $state<Array<Pick<Tables<'autores'>, 'autor_id' | 'nombre_completo' | 'nombre_normalizado'>>>([]);
	let tipos = $state<CatalogItem[]>([]);
	let modalidades = $state<CatalogItem[]>([]);
	let drafts = $state<DraftAttribution[]>([]);
	let baselineSnapshot = $state('');
	let scopeView = $state<ScopeView>('obra');
	let openDraftId = $state<string | null>(null);

	const canComment = $derived(Boolean(props.canComment));
	const effectiveReadOnly = $derived(Boolean(props.readOnly));

	const tipoItems = $derived(
		tipos.map((item) => ({
			id: item.termino_id,
			label: item.termino
		}))
	);

	const modalidadItems = $derived(
		modalidades.map((item) => ({
			id: item.termino_id,
			label: item.termino
		}))
	);

	const authorOptions = $derived(
		autores.map((author) => ({
			autor_id: author.autor_id,
			nombre_completo: author.nombre_completo
		}))
	);

	const authorNameById = $derived(new Map(autores.map((author) => [author.autor_id, author.nombre_completo])));
	const tipoTermById = $derived(new Map(tipos.map((item) => [item.termino_id, item.termino])));
	const modalidadTermById = $derived(
		new Map(modalidades.map((item) => [item.termino_id, item.termino.trim().toLowerCase()]))
	);

	const globalDrafts = $derived(drafts.filter((draft) => !draft.jornada_id));
	const jornadaDraftCount = $derived(drafts.filter((draft) => draft.jornada_id !== null).length);

	const draftsByJornadaId = $derived.by(() => {
		const map = new Map<string, DraftAttribution[]>();
		for (const jornada of jornadas) {
			map.set(jornada.jornada_id, []);
		}
		for (const draft of drafts) {
			if (!draft.jornada_id) continue;
			const current = map.get(draft.jornada_id) ?? [];
			current.push(draft);
			map.set(draft.jornada_id, current);
		}
		return map;
	});

	function uniqueIds(ids: string[]): string[] {
		return [...new Set(ids.map((id) => id.trim()).filter((id) => id.length > 0))];
	}

	function inferDefaultScope(nextDrafts: DraftAttribution[]): ScopeView {
		const hasGlobal = nextDrafts.some((draft) => !draft.jornada_id);
		const hasJornada = nextDrafts.some((draft) => Boolean(draft.jornada_id));
		if (hasJornada && !hasGlobal) return 'jornadas';
		return 'obra';
	}

	function createEmptyDraft(jornadaId: string | null): DraftAttribution {
		return {
			local_id: `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
			jornada_id: jornadaId,
			tipo_atribucion_id: tipos[0]?.termino_id ?? '',
			modalidad_atribucion_id: modalidades[0]?.termino_id ?? '',
			fuente: '',
			url: '',
			adoptada: false,
			notas: '',
			autor_ids: []
		};
	}

	function normalizeSnapshot() {
		const compact = drafts.map((draft) => ({
			jornada_id: draft.jornada_id,
			tipo_atribucion_id: draft.tipo_atribucion_id,
			modalidad_atribucion_id: draft.modalidad_atribucion_id,
			fuente: draft.fuente.trim(),
			url: draft.url.trim(),
			adoptada: draft.adoptada,
			notas: draft.notas.trim(),
			autor_ids: uniqueIds(draft.autor_ids)
		}));
		return JSON.stringify(compact);
	}

	function syncDirty() {
		if (effectiveReadOnly) return;
		const dirty = normalizeSnapshot() !== baselineSnapshot;
		setDirty(dirty, 'autoria');
		if (!dirty) {
			setSaving(false, 'autoria');
		}
	}

	function setScope(next: ScopeView) {
		scopeView = next;
	}

	function toggleDraftEditor(localId: string) {
		openDraftId = openDraftId === localId ? null : localId;
	}

	function getTipoTerm(tipoId: string): string {
		return tipoTermById.get(tipoId) ?? 'Sin tipo';
	}

	function getAuthorSummary(authorIds: string[]): string {
		const names = uniqueIds(authorIds).map((authorId) => authorNameById.get(authorId) ?? authorId);
		if (names.length === 0) return 'Sin autores';
		if (names.length <= 3) return names.join(', ');
		return `${names.slice(0, 3).join(', ')} +${names.length - 3}`;
	}

	function applyServerState(payload: AutoriaApiPayload) {
		const nextJornadas = [...payload.jornadas];
		const nextDrafts = payload.atribuciones.map((item) => ({
			local_id: item.atribucion_id,
			jornada_id: item.jornada_id,
			tipo_atribucion_id: item.tipo_atribucion_id,
			modalidad_atribucion_id: item.modalidad_atribucion_id,
			fuente: item.fuente ?? '',
			url: item.url ?? '',
			adoptada: item.adoptada,
			notas: item.notas ?? '',
			autor_ids: uniqueIds(item.autores.map((autor) => autor.autor_id))
		}));

		jornadas = nextJornadas;
		autores = [...payload.autores];
		tipos = [...payload.catalogos.tipos];
		modalidades = [...payload.catalogos.modalidades];
		drafts = nextDrafts;

		scopeView = inferDefaultScope(nextDrafts);
		if (!nextDrafts.some((draft) => draft.local_id === openDraftId)) {
			openDraftId = null;
		}

		patchCurrentObra({
			total_versos: payload.obra.total_versos ?? null
		});
		baselineSnapshot = normalizeSnapshot();
		setDirty(false, 'autoria');
		setSaving(false, 'autoria');
	}

	async function refreshFromServer(silent = false) {
		if (loadingFromServer) return;
		loadingFromServer = true;
		const response = await fetch(`/api/obras/${props.obraId}/autoria`);
		loadingFromServer = false;
		loading = false;

		if (!response.ok) {
			const body = await response.json().catch(() => ({}));
			const message = body?.message ?? 'No se pudo cargar la autoría de la obra.';
			loadError = message;
			if (!silent) pushToast('error', message);
			return;
		}

		loadError = null;
		const payload = (await response.json()) as AutoriaApiPayload;
		applyServerState(payload);
	}

	function addGlobalDraft() {
		const draft = createEmptyDraft(null);
		drafts = [...drafts, draft];
		scopeView = 'obra';
		openDraftId = draft.local_id;
		syncDirty();
	}

	function addJornadaDraft(jornadaId: string) {
		const draft = createEmptyDraft(jornadaId);
		drafts = [...drafts, draft];
		scopeView = 'jornadas';
		openDraftId = draft.local_id;
		syncDirty();
	}

	function removeDraft(localId: string) {
		drafts = drafts.filter((draft) => draft.local_id !== localId);
		if (openDraftId === localId) {
			openDraftId = null;
		}
		syncDirty();
	}

	function patchDraft(localId: string, patch: Partial<DraftAttribution>) {
		drafts = drafts.map((draft) => (draft.local_id === localId ? { ...draft, ...patch } : draft));
		syncDirty();
	}

	function validateClientPayload(): string | null {
		const jornadaSet = new Set(jornadas.map((jornada) => jornada.jornada_id));
		const adoptedGlobal = drafts.filter((draft) => !draft.jornada_id && draft.adoptada).length;
		if (adoptedGlobal > 1) {
			return 'Solo puede haber una atribución global adoptada.';
		}

		const adoptedByJornada = new Map<string, number>();
		for (const draft of drafts) {
			if (!draft.jornada_id || !draft.adoptada) continue;
			adoptedByJornada.set(draft.jornada_id, (adoptedByJornada.get(draft.jornada_id) ?? 0) + 1);
		}
		for (const [jornadaId, count] of adoptedByJornada.entries()) {
			if (count > 1) {
				return `La jornada ${jornadaId} tiene más de una atribución adoptada.`;
			}
		}

		for (const draft of drafts) {
			if (draft.jornada_id && !jornadaSet.has(draft.jornada_id)) {
				return 'Hay atribuciones asociadas a jornadas inválidas.';
			}
			if (!draft.tipo_atribucion_id || !draft.modalidad_atribucion_id) {
				return 'Todas las atribuciones deben tener tipo y modalidad.';
			}
			if (draft.fuente.trim().length === 0) {
				return 'Todas las atribuciones deben indicar fuente.';
			}
			if (uniqueIds(draft.autor_ids).length === 0) {
				return 'Todas las atribuciones deben tener al menos un autor.';
			}
			const modalidadTerm = modalidadTermById.get(draft.modalidad_atribucion_id) ?? '';
			const authorCount = uniqueIds(draft.autor_ids).length;
			if (modalidadTerm === 'unica' && authorCount !== 1) {
				return 'La modalidad única exige exactamente 1 autor.';
			}
			if ((modalidadTerm === 'alternativa' || modalidadTerm === 'colaborativa') && authorCount < 2) {
				return 'Las modalidades alternativa y colaborativa exigen 2 o más autores.';
			}
		}

		return null;
	}

	function buildPayload() {
		return {
			atribuciones: drafts.map((draft) => ({
				jornada_id: draft.jornada_id,
				tipo_atribucion_id: draft.tipo_atribucion_id,
				modalidad_atribucion_id: draft.modalidad_atribucion_id,
				fuente: draft.fuente.trim(),
				url: draft.url.trim() || null,
				adoptada: draft.adoptada,
				notas: draft.notas.trim() || null,
				autores: uniqueIds(draft.autor_ids).map((autor_id, index) => ({
					autor_id,
					orden: index + 1
				}))
			}))
		};
	}

	async function save() {
		if (effectiveReadOnly || loadingFromServer || loading || savingNow) return;
		const validationError = validateClientPayload();
		if (validationError) {
			pushToast('error', validationError);
			return;
		}

		savingNow = true;
		setSaving(true, 'autoria');
		const response = await fetch(`/api/obras/${props.obraId}/autoria`, {
			method: 'PUT',
			headers: { 'Content-Type': 'application/json' },
			body: JSON.stringify(buildPayload())
		});
		savingNow = false;

		if (!response.ok) {
			setSaving(false, 'autoria');
			const body = await response.json().catch(() => ({}));
			const detail = Array.isArray(body?.details) ? body.details[0]?.message : null;
			pushToast('error', detail ?? body.message ?? 'No se pudo guardar la autoría.');
			return;
		}

		const payload = (await response.json()) as AutoriaApiPayload;
		applyServerState(payload);
		markSaved('autoria');
		pushToast('success', 'Autoría guardada');
	}

	onMount(() => {
		void refreshFromServer(true);
	});
</script>

{#snippet draftEditor(draft: DraftAttribution)}
	<div class="mt-3 border border-[color:var(--border)] bg-[color:var(--muted)] p-3">
		<div class="grid gap-3 md:grid-cols-2">
			<label class="form-field">
				<span class="form-label">Tipo de atribución</span>
				<CheckDropdown
					multiple={false}
					search={false}
					items={tipoItems}
					selectedIds={draft.tipo_atribucion_id ? [draft.tipo_atribucion_id] : []}
					placeholder="Selecciona tipo"
					disabled={effectiveReadOnly || loadingFromServer}
					onChange={(ids) =>
						patchDraft(draft.local_id, {
							tipo_atribucion_id: (ids[0] as string | undefined) ?? ''
						})}
				/>
			</label>
			<label class="form-field">
				<span class="form-label">Modalidad</span>
				<CheckDropdown
					multiple={false}
					search={false}
					items={modalidadItems}
					selectedIds={draft.modalidad_atribucion_id ? [draft.modalidad_atribucion_id] : []}
					placeholder="Selecciona modalidad"
					disabled={effectiveReadOnly || loadingFromServer}
					onChange={(ids) =>
						patchDraft(draft.local_id, {
							modalidad_atribucion_id: (ids[0] as string | undefined) ?? ''
						})}
				/>
			</label>
		</div>

		<div class="mt-3 grid gap-3 md:grid-cols-2">
			<label class="form-field">
				<span class="form-label">Fuente</span>
				<input
					type="text"
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					value={draft.fuente}
					disabled={effectiveReadOnly || loadingFromServer}
					oninput={(event) => patchDraft(draft.local_id, { fuente: event.currentTarget.value })}
				/>
			</label>
			<label class="form-field">
				<span class="form-label">URL</span>
				<input
					type="url"
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					value={draft.url}
					disabled={effectiveReadOnly || loadingFromServer}
					oninput={(event) => patchDraft(draft.local_id, { url: event.currentTarget.value })}
				/>
			</label>
		</div>

		<div class="mt-3">
			<label class="form-field">
				<span class="form-label">Autores</span>
				<AuthorSelector
					authors={authorOptions}
					selectedIds={draft.autor_ids}
					onChange={(ids) => patchDraft(draft.local_id, { autor_ids: ids })}
					placeholder="Escribe y selecciona autores"
					disabled={effectiveReadOnly || loadingFromServer}
				/>
			</label>
		</div>

		<div class="mt-3">
			<label class="form-field">
				<span class="form-label">Notas</span>
				<textarea
					rows={3}
					class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
					value={draft.notas}
					disabled={effectiveReadOnly || loadingFromServer}
					oninput={(event) => patchDraft(draft.local_id, { notas: event.currentTarget.value })}
				></textarea>
			</label>
		</div>

		<div class="mt-3 flex items-center justify-between gap-2">
			<label class="inline-flex items-center gap-2 text-sm">
				<input
					type="checkbox"
					checked={draft.adoptada}
					disabled={effectiveReadOnly || loadingFromServer}
					onchange={(event) => patchDraft(draft.local_id, { adoptada: event.currentTarget.checked })}
				/>
				Adoptada por el proyecto
			</label>

			<div class="flex gap-2">
				<Button
					variant="danger"
					onclick={() => removeDraft(draft.local_id)}
					disabled={effectiveReadOnly || loadingFromServer}
				>
					Eliminar
				</Button>
				<Button variant="secondary" onclick={() => toggleDraftEditor(draft.local_id)}>Cerrar</Button>
			</div>
		</div>
	</div>
{/snippet}

{#snippet draftCard(draft: DraftAttribution)}
	<article class="border border-[color:var(--border)] bg-white p-3">
		<button
			type="button"
			class="flex w-full items-center justify-between gap-3 text-left"
			onclick={() => toggleDraftEditor(draft.local_id)}
		>
			<div class="min-w-0">
				<p class="truncate text-sm font-semibold text-[color:var(--gray-900)]">{getAuthorSummary(draft.autor_ids)}</p>
				<p class="mt-1 text-xs text-[color:var(--muted-foreground)]">Tipo: {getTipoTerm(draft.tipo_atribucion_id)}</p>
			</div>
			<div class="flex shrink-0 items-center gap-2">
				{#if draft.adoptada}
					<span class="rounded-full border border-[color:var(--success)] bg-[color:var(--success-soft)] px-2 py-1 text-xs font-semibold text-[color:var(--success)]">
						Adoptada
					</span>
				{/if}
				<span class="text-xs font-semibold text-[color:var(--gray-800)]">
					{openDraftId === draft.local_id ? 'Ocultar' : 'Editar'}
				</span>
			</div>
		</button>

		{#if openDraftId === draft.local_id}
			{@render draftEditor(draft)}
		{/if}
	</article>
{/snippet}

<section class="space-y-4">
	<div class="flex justify-end">
		<Button
			variant="success"
			onclick={save}
			disabled={savingNow || effectiveReadOnly || loadingFromServer || loading}
		>
			{savingNow ? 'Guardando...' : 'Guardar'}
		</Button>
	</div>

	{#if loading}
		<div class="card p-4">
			<p class="text-sm text-[color:var(--muted-foreground)]">Cargando módulo de autoría...</p>
		</div>
	{:else if loadError}
		<div class="card p-4">
			<p class="text-sm text-[color:var(--danger)]">{loadError}</p>
			<div class="mt-3">
				<Button variant="secondary" onclick={() => void refreshFromServer(false)} disabled={loadingFromServer}>
					Reintentar
				</Button>
			</div>
		</div>
	{:else}
		<div class="card p-4">
			<h2 class="text-xl font-semibold">Ámbito de atribución</h2>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Selecciona cómo quieres trabajar la autoría en esta obra.
			</p>
			<div class="mt-3 inline-flex overflow-hidden rounded-md border border-[color:var(--border)] bg-white">
				<button
					type="button"
					class={`inline-flex items-center gap-2 px-3 py-2 text-sm font-medium ${
						scopeView === 'obra'
							? 'bg-[color:var(--gray-900)] text-white'
							: 'bg-white text-[color:var(--gray-900)]'
					}`}
					onclick={() => setScope('obra')}
				>
					Obra completa
					<span class="rounded-full border border-current px-2 py-0.5 text-xs">{globalDrafts.length}</span>
				</button>
				<button
					type="button"
					class={`inline-flex items-center gap-2 border-l border-[color:var(--border)] px-3 py-2 text-sm font-medium ${
						scopeView === 'jornadas'
							? 'bg-[color:var(--gray-900)] text-white'
							: 'bg-white text-[color:var(--gray-900)]'
					}`}
					onclick={() => setScope('jornadas')}
				>
					Por jornadas
					<span class="rounded-full border border-current px-2 py-0.5 text-xs">{jornadaDraftCount}</span>
				</button>
			</div>
		</div>

		{#if scopeView === 'obra'}
			<div class="card p-4">
				<div class="mb-4 flex items-center justify-between">
					<h2 class="text-xl font-semibold">Atribuciones globales de obra</h2>
					<Button variant="secondary" onclick={addGlobalDraft} disabled={effectiveReadOnly || loadingFromServer}>
						Añadir atribución global
					</Button>
				</div>

				{#if globalDrafts.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">Sin atribuciones globales registradas.</p>
				{:else}
					<div class="space-y-3">
						{#each globalDrafts as draft (draft.local_id)}
							{@render draftCard(draft)}
						{/each}
					</div>
				{/if}
			</div>
		{:else}
			<div class="card p-4">
				<h2 class="mb-4 text-xl font-semibold">Atribuciones por jornada</h2>
				{#if jornadas.length === 0}
					<p class="text-sm text-[color:var(--muted-foreground)]">La obra aún no tiene jornadas definidas.</p>
				{:else}
					<div class="space-y-4">
						{#each jornadas as jornada (jornada.jornada_id)}
							<article class="border border-[color:var(--border)] bg-white p-3">
								<div class="mb-3 flex items-center justify-between">
									<h3 class="font-semibold">
										Jornada {jornada.jornada_num} (vv. {jornada.v_ini}-{jornada.v_fin})
									</h3>
									<Button
										variant="secondary"
										onclick={() => addJornadaDraft(jornada.jornada_id)}
										disabled={effectiveReadOnly || loadingFromServer}
									>
										Añadir atribución
									</Button>
								</div>

								{#if (draftsByJornadaId.get(jornada.jornada_id) ?? []).length === 0}
									<p class="text-sm text-[color:var(--muted-foreground)]">Sin atribuciones para esta jornada.</p>
								{:else}
									<div class="space-y-3">
										{#each draftsByJornadaId.get(jornada.jornada_id) ?? [] as draft (draft.local_id)}
											{@render draftCard(draft)}
										{/each}
									</div>
								{/if}
							</article>
						{/each}
					</div>
				{/if}
			</div>
		{/if}
	{/if}

	{#if !loading}
		<InternalCommentsPanel
			obraId={props.obraId}
			canComment={canComment}
			section="autoria"
			title="Comentarios internos sobre autoría"
			emptyText="No hay comentarios internos sobre esta sección."
		/>
	{/if}
</section>

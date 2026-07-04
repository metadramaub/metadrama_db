<script lang="ts">
	import { pushToast } from '$lib/stores/toast';

	type Author = { autor_id: string; nombre_completo: string; nombre_normalizado?: string | null };

	const props = $props<{
		// Autores ya conocidos (p. ej. los atribuidos a la obra) para poder pintar los chips
		// de los seleccionados sin tener el catálogo completo.
		knownAuthors?: Author[];
		selectedIds: string[];
		onChange: (ids: string[]) => void;
		onAuthorSelected?: (author: Author) => void;
		placeholder?: string;
		disabled?: boolean;
	}>();

	let query = $state('');
	let open = $state(false);
	let suggestions = $state<Author[]>([]);
	let searching = $state(false);
	let searchToken = 0;
	let lastSelectedResolveKey = '';
	let debounceTimer: ReturnType<typeof setTimeout> | null = null;

	// Cache de nombres: se alimenta de knownAuthors, de los resultados de búsqueda y de
	// los autores que se van seleccionando. Permite pintar el chip aunque el autor no
	// esté en la última búsqueda.
	let nameCache = $state<Record<string, string>>({});

	$effect(() => {
		const next = { ...nameCache };
		let changed = false;
		for (const author of (props.knownAuthors ?? []) as Author[]) {
			if (next[author.autor_id] !== author.nombre_completo) {
				next[author.autor_id] = author.nombre_completo;
				changed = true;
			}
		}
		if (changed) nameCache = next;
	});

	const selectedAuthors = $derived(
		(props.selectedIds as string[]).map((id) => ({
			autor_id: id,
			nombre_completo: nameCache[id] ?? id
		}))
	);

	async function resolveSelectedAuthorNames(ids: string[]) {
		const params = new URLSearchParams();
		params.set('ids', ids.join(','));
		try {
			const response = await fetch(`/api/autores/buscar?${params.toString()}`);
			if (!response.ok) return;
			const payload = await response.json().catch(() => ({}));
			const rows = (payload.authors ?? []) as Author[];
			if (rows.length === 0) return;
			const next = { ...nameCache };
			let changed = false;
			for (const author of rows) {
				if (next[author.autor_id] !== author.nombre_completo) {
					next[author.autor_id] = author.nombre_completo;
					changed = true;
				}
			}
			if (changed) nameCache = next;
		} catch {
			// El fallback visual sigue siendo el id si no se puede resolver el nombre.
		}
	}

	$effect(() => {
		const missingIds = [
			...new Set((props.selectedIds as string[]).filter((id) => id.trim().length > 0 && !nameCache[id]))
		].sort((a, b) => a.localeCompare(b));
		const key = missingIds.join(',');
		if (!key || key === lastSelectedResolveKey) return;
		lastSelectedResolveKey = key;
		void resolveSelectedAuthorNames(missingIds);
	});

	async function runSearch(term: string) {
		const token = ++searchToken;
		searching = true;
		try {
			const params = new URLSearchParams();
			if (term) params.set('q', term);
			const response = await fetch(`/api/autores/buscar?${params.toString()}`);
			if (token !== searchToken) return;
			if (!response.ok) {
				suggestions = [];
				return;
			}
			const payload = await response.json();
			const rows = (payload.authors ?? []) as Author[];
			suggestions = rows.filter((author) => !props.selectedIds.includes(author.autor_id));
			if (rows.length > 0) {
				const next = { ...nameCache };
				for (const author of rows) next[author.autor_id] = author.nombre_completo;
				nameCache = next;
			}
		} catch {
			if (token === searchToken) suggestions = [];
		} finally {
			if (token === searchToken) searching = false;
		}
	}

	function scheduleSearch(term: string) {
		if (debounceTimer) clearTimeout(debounceTimer);
		debounceTimer = setTimeout(() => void runSearch(term), 200);
	}

	function openAndSearch() {
		open = true;
		void runSearch(query.trim());
	}

	function addAuthor(author: Author) {
		if (props.disabled) return;
		if (props.selectedIds.includes(author.autor_id)) return;
		nameCache = { ...nameCache, [author.autor_id]: author.nombre_completo };
		props.onAuthorSelected?.(author);
		props.onChange([...props.selectedIds, author.autor_id]);
		query = '';
		suggestions = [];
		open = false;
	}

	function removeAuthor(authorId: string) {
		if (props.disabled) return;
		const removedName = nameCache[authorId] ?? 'desconocido';
		props.onChange(props.selectedIds.filter((id: string) => id !== authorId));
		pushToast('info', `Autor eliminado: ${removedName}`, 5000, {
			actionLabel: 'Deshacer',
			onAction: () => {
				if (props.disabled) return;
				if (props.selectedIds.includes(authorId)) return;
				props.onChange([...props.selectedIds, authorId]);
			}
		});
	}

	function addFirstMatch() {
		if (suggestions.length > 0) {
			addAuthor(suggestions[0]);
		}
	}

	function onInputBlur() {
		setTimeout(() => {
			open = false;
		}, 150);
	}
</script>

<div class="relative">
	<div
		class={`flex flex-wrap items-center gap-1.5 rounded-md border border-[color:var(--border)] px-2 py-1.5 ${
			props.disabled ? 'bg-[color:var(--muted)]' : 'bg-white'
		}`}
	>
		{#each selectedAuthors as author}
			<span class="inline-flex items-center gap-1 rounded border border-[color:var(--border)] bg-[color:var(--gray-50)] py-0.5 pl-2 pr-1 text-sm">
				<span class="pointer-events-none">{author.nombre_completo}</span>
				<button
					type="button"
					class="inline-flex h-4 w-4 items-center justify-center rounded text-xs text-[color:var(--muted-foreground)] hover:bg-[color:var(--muted)] hover:text-[color:var(--foreground)] disabled:cursor-not-allowed disabled:opacity-50"
					disabled={props.disabled}
					onclick={(event) => {
						event.stopPropagation();
						removeAuthor(author.autor_id);
					}}
					title={`Quitar ${author.nombre_completo}`}
					aria-label={`Quitar ${author.nombre_completo}`}
				>
					×
				</button>
			</span>
		{/each}
		<input
			type="text"
			class="min-w-[8rem] flex-1 border-0 bg-transparent px-1 py-0.5 text-sm outline-none disabled:cursor-not-allowed"
			disabled={props.disabled}
			placeholder={selectedAuthors.length > 0 ? 'Añadir otro…' : (props.placeholder ?? 'Escribe para buscar autores')}
			value={query}
			onfocus={openAndSearch}
			onblur={onInputBlur}
			oninput={(event) => {
				query = event.currentTarget.value;
				open = true;
				scheduleSearch(query.trim());
			}}
			onkeydown={(event) => {
				if (event.key === 'Enter') {
					event.preventDefault();
					addFirstMatch();
				}
			}}
		/>
	</div>
	{#if open}
		<div class="absolute z-20 mt-1 max-h-48 w-full overflow-auto border border-[color:var(--border)] bg-white">
			{#if searching}
				<div class="px-3 py-2 text-sm text-[color:var(--muted-foreground)]">Buscando…</div>
			{:else if suggestions.length === 0}
				<div class="px-3 py-2 text-sm text-[color:var(--muted-foreground)]">Sin coincidencias.</div>
			{:else}
				{#each suggestions as suggestion}
					<button
						type="button"
						class="block w-full px-3 py-2 text-left text-sm hover:bg-[color:var(--muted)]"
						onclick={() => addAuthor(suggestion)}
					>
						{suggestion.nombre_completo}
					</button>
				{/each}
			{/if}
		</div>
	{/if}
</div>

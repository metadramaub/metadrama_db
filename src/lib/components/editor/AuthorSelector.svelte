<script lang="ts">
	import { pushToast } from '$lib/stores/toast';

	const props = $props<{
		authors: Array<{ autor_id: string; nombre_completo: string }>;
		selectedIds: string[];
		onChange: (ids: string[]) => void;
		placeholder?: string;
		disabled?: boolean;
	}>();
	type AuthorOption = (typeof props.authors)[number];

	function normalizeText(value: string): string {
		return value
			.normalize('NFD')
			.replaceAll(/\p{M}/gu, '')
			.trim()
			.toLowerCase();
	}

	let query = $state('');
	let open = $state(false);

	const selectedAuthors = $derived.by(() => {
		const map = new Map(props.authors.map((author: AuthorOption) => [author.autor_id, author]));
		return props.selectedIds.map((id: string) => map.get(id)).filter(Boolean) as Array<{
			autor_id: string;
			nombre_completo: string;
		}>;
	});

	const suggestions = $derived.by(() => {
		const term = normalizeText(query);
		return props.authors
			.filter(
				(author: AuthorOption) =>
					(!term || normalizeText(author.nombre_completo).includes(term)) &&
					!props.selectedIds.includes(author.autor_id)
			)
			.slice(0, 10);
	});

	function addAuthor(authorId: string) {
		if (props.disabled) return;
		if (props.selectedIds.includes(authorId)) return;
		props.onChange([...props.selectedIds, authorId]);
		query = '';
		open = false;
	}

	function removeAuthor(authorId: string) {
		if (props.disabled) return;
		const removed = props.authors.find((author: AuthorOption) => author.autor_id === authorId);
		props.onChange(props.selectedIds.filter((id: string) => id !== authorId));
		pushToast('info', `Autor eliminado: ${removed?.nombre_completo ?? 'desconocido'}`, 5000, {
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
			addAuthor(suggestions[0].autor_id);
		}
	}

	function onInputBlur() {
		setTimeout(() => {
			open = false;
		}, 120);
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
			onfocus={() => (open = true)}
			onblur={onInputBlur}
			oninput={(event) => {
				query = event.currentTarget.value;
				open = true;
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
			{#if suggestions.length === 0}
				<div class="px-3 py-2 text-sm text-[color:var(--muted-foreground)]">Sin coincidencias.</div>
			{:else}
				{#each suggestions as suggestion}
					<button
						type="button"
						class="block w-full px-3 py-2 text-left text-sm hover:bg-[color:var(--muted)]"
						onclick={() => addAuthor(suggestion.autor_id)}
					>
						{suggestion.nombre_completo}
					</button>
				{/each}
			{/if}
		</div>
	{/if}
</div>

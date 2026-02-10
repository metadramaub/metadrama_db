<script lang="ts">
	import Button from '$lib/components/ui/button.svelte';

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
		props.onChange(props.selectedIds.filter((id: string) => id !== authorId));
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

<div class="space-y-2">
	<div class="flex flex-wrap gap-2">
		{#if selectedAuthors.length === 0}
			<span class="text-sm text-[color:var(--muted-foreground)]">Sin autores seleccionados.</span>
		{:else}
			{#each selectedAuthors as author}
				<span class="inline-flex items-center gap-2 rounded-full border border-[color:var(--border)] bg-[#fffdf8] px-3 py-1 text-sm">
					{author.nombre_completo}
					<Button
						variant="ghost"
						class="h-6 px-2 py-0"
						disabled={props.disabled}
						onclick={() => removeAuthor(author.autor_id)}
						>Quitar</Button
					>
				</span>
			{/each}
		{/if}
	</div>

	<div class="relative">
		<input
			type="text"
			class="w-full rounded-md border border-[color:var(--border)] px-3 py-2"
			disabled={props.disabled}
			placeholder={props.placeholder ?? 'Escribe para buscar autores'}
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
		{#if open}
			<div class="absolute z-20 mt-1 max-h-48 w-full overflow-auto rounded-md border border-[color:var(--border)] bg-white shadow">
				{#if suggestions.length === 0}
					<div class="px-3 py-2 text-sm text-[color:var(--muted-foreground)]">Sin coincidencias.</div>
				{:else}
					{#each suggestions as suggestion}
						<button
							type="button"
							class="block w-full px-3 py-2 text-left text-sm hover:bg-[#f5ede0]"
							onclick={() => addAuthor(suggestion.autor_id)}
						>
							{suggestion.nombre_completo}
						</button>
					{/each}
				{/if}
			</div>
		{/if}
	</div>
</div>

<script lang="ts">
	import { DASHBOARD_GUIDE_GROUPS } from '$lib/types/dashboard-guide.types';
	import type {
		DashboardGuideChapter,
		DashboardGuideSearchEntry,
		DashboardGuideGroup
	} from '$lib/types/dashboard-guide.types';

	type NavChapter = Pick<DashboardGuideChapter, 'slug' | 'title' | 'group' | 'sections'>;

	let {
		chapters,
		searchIndex,
		currentSlug = null,
		showSearch = true
	} = $props<{
		chapters: NavChapter[];
		searchIndex: DashboardGuideSearchEntry[];
		currentSlug?: string | null;
		showSearch?: boolean;
	}>();

	let searchQuery = $state('');

	function normalizeForSearch(value: string): string {
		return value
			.normalize('NFD')
			.replaceAll(/\p{M}/gu, '')
			.toLowerCase();
	}

	type SearchResult = {
		chapterSlug: string;
		chapterTitle: string;
		sectionId: string;
		sectionTitle: string;
		snippet: string;
	};

	function buildSnippet(text: string, normalizedText: string, normalizedTerm: string): string {
		const matchIndex = normalizedText.indexOf(normalizedTerm);
		if (matchIndex < 0) return text.slice(0, 120);
		const start = Math.max(0, matchIndex - 40);
		const end = Math.min(text.length, matchIndex + normalizedTerm.length + 60);
		const prefix = start > 0 ? '…' : '';
		const suffix = end < text.length ? '…' : '';
		return `${prefix}${text.slice(start, end).trim()}${suffix}`;
	}

	const searchResults = $derived.by<SearchResult[]>(() => {
		const term = normalizeForSearch(searchQuery.trim());
		if (term.length < 2) return [];
		const results: SearchResult[] = [];
		for (const entry of searchIndex) {
			const haystack = normalizeForSearch(`${entry.sectionTitle} ${entry.text}`);
			if (!haystack.includes(term)) continue;
			results.push({
				chapterSlug: entry.chapterSlug,
				chapterTitle: entry.chapterTitle,
				sectionId: entry.sectionId,
				sectionTitle: entry.sectionTitle,
				snippet: buildSnippet(entry.text, normalizeForSearch(entry.text), term)
			});
			if (results.length >= 30) break;
		}
		return results;
	});

	const isSearching = $derived(searchQuery.trim().length >= 2);

	const groupedChapters = $derived.by(() =>
		DASHBOARD_GUIDE_GROUPS.map((group) => ({
			...group,
			chapters: chapters.filter((chapter: NavChapter) => chapter.group === group.id)
		})).filter((group) => group.chapters.length > 0)
	);

	function resultHref(result: SearchResult): string {
		if (!result.sectionId) return `/dashboard/guia/${result.chapterSlug}`;
		if (currentSlug && result.chapterSlug === currentSlug) return `#${result.sectionId}`;
		return `/dashboard/guia/${result.chapterSlug}#${result.sectionId}`;
	}

	function sectionHref(chapterSlug: string, sectionId: string): string {
		if (currentSlug && chapterSlug === currentSlug) return `#${sectionId}`;
		return `/dashboard/guia/${chapterSlug}#${sectionId}`;
	}
</script>

<div class="space-y-4">
	{#if showSearch}
		<input
			type="search"
			bind:value={searchQuery}
			placeholder="Buscar en la guía…"
			aria-label="Buscar en la guía"
			class="w-full border border-[color:var(--border)] bg-[color:var(--background)] px-3 py-2 text-sm outline-none focus:border-[color:var(--primary)]"
		/>
	{/if}

	{#if showSearch && isSearching}
		<div class="flex flex-col gap-2">
			{#if searchResults.length === 0}
				<p class="text-xs text-[color:var(--muted-foreground)]">
					Sin resultados para “{searchQuery.trim()}”.
				</p>
			{:else}
				<p class="text-xs text-[color:var(--muted-foreground)]">
					{searchResults.length} resultado{searchResults.length === 1 ? '' : 's'}
				</p>
				<ul class="flex flex-col gap-1">
					{#each searchResults as result}
						<li>
							<a
								href={resultHref(result)}
								class="block border border-transparent px-2 py-1.5 hover:border-[color:var(--border)] hover:bg-[color:var(--muted)]"
							>
								<span class="block text-sm font-semibold leading-5 text-[color:var(--foreground)]">
									{result.sectionTitle}
								</span>
								<span class="block text-[0.7rem] uppercase tracking-wide text-[color:var(--muted-foreground)]">
									{result.chapterTitle}
								</span>
								{#if result.snippet}
									<span class="mt-0.5 block text-xs text-[color:var(--muted-foreground)]">
										{result.snippet}
									</span>
								{/if}
							</a>
						</li>
					{/each}
				</ul>
			{/if}
		</div>
	{:else}
		<nav class="flex flex-col gap-5">
			{#each groupedChapters as group}
				<div>
					<p class="mb-1.5 text-[0.68rem] font-semibold uppercase tracking-wider text-[color:var(--muted-foreground)]">
						{group.label}
					</p>
					<ul class="flex flex-col">
						{#each group.chapters as chapter}
							{@const isCurrent = chapter.slug === currentSlug}
							<li>
								<a
									href={`/dashboard/guia/${chapter.slug}`}
									aria-current={isCurrent ? 'page' : undefined}
									class={`block border-l-2 py-1 pl-3 text-sm leading-5 ${
										isCurrent
											? 'border-[color:var(--primary)] font-semibold text-[color:var(--foreground)]'
											: 'border-transparent text-[color:var(--muted-foreground)] hover:border-[color:var(--border)] hover:text-[color:var(--foreground)]'
									}`}
								>
									{chapter.title}
								</a>
								{#if isCurrent && chapter.sections.length > 0}
									<ul class="mb-1 mt-0.5 flex flex-col gap-0.5 border-l-2 border-[color:var(--primary)] pl-3">
										{#each chapter.sections as section}
											<li>
												<a
													href={sectionHref(chapter.slug, section.id)}
													class="block py-0.5 pl-2 text-xs text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] hover:underline"
												>
													{section.title}
												</a>
											</li>
										{/each}
									</ul>
								{/if}
							</li>
						{/each}
					</ul>
				</div>
			{/each}
		</nav>
	{/if}
</div>

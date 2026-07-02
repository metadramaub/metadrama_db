<script lang="ts">
	import GuideNav from '$lib/components/dashboard/GuideNav.svelte';
	import type { DashboardGuideSearchEntry } from '$lib/types/dashboard-guide.types';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();

	const firstChapterSlug = $derived(data.chapters[0]?.slug ?? null);
	const hasFaq = $derived(data.chapters.some((chapter: { slug: string }) => chapter.slug === 'faq'));

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
		if (matchIndex < 0) return text.slice(0, 140);
		const start = Math.max(0, matchIndex - 50);
		const end = Math.min(text.length, matchIndex + normalizedTerm.length + 70);
		const prefix = start > 0 ? '…' : '';
		const suffix = end < text.length ? '…' : '';
		return `${prefix}${text.slice(start, end).trim()}${suffix}`;
	}

	const searchResults = $derived.by<SearchResult[]>(() => {
		const term = normalizeForSearch(searchQuery.trim());
		if (term.length < 2) return [];
		const results: SearchResult[] = [];
		for (const entry of data.searchIndex as DashboardGuideSearchEntry[]) {
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

	function resultHref(result: SearchResult): string {
		if (!result.sectionId) return `/dashboard/guia/${result.chapterSlug}`;
		return `/dashboard/guia/${result.chapterSlug}#${result.sectionId}`;
	}
</script>

<section class="space-y-4">
	<header>
		<h1 class="font-display text-3xl">GUÍA EDITORIAL</h1>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			Manual interno para los editores y colaboradores del proyecto.
		</p>
	</header>

	<div class="grid gap-8 lg:grid-cols-[15rem_minmax(0,1fr)] lg:items-start">
		<aside class="lg:sticky lg:top-4 lg:max-h-[calc(100vh-2.5rem)] lg:overflow-y-auto">
			<GuideNav chapters={data.chapters} searchIndex={data.searchIndex} showSearch={false} />
		</aside>

		<div class="min-w-0">
			<div class="mx-auto max-w-2xl py-8 text-center sm:py-16">
				<h2 class="text-2xl font-semibold">¿Qué necesitas hacer?</h2>
				<p class="mt-2 text-sm text-[color:var(--muted-foreground)]">
					Busca cualquier tema o empieza por el principio.
				</p>

				<div class="relative mt-6 text-left">
					<input
						type="search"
						bind:value={searchQuery}
						placeholder="Buscar en la guía…"
						aria-label="Buscar en la guía"
						class="w-full border border-[color:var(--border)] bg-white px-4 py-3 text-base outline-none focus:border-[color:var(--primary)]"
					/>

					{#if isSearching}
						<div class="mt-2 border border-[color:var(--border)] bg-white">
							{#if searchResults.length === 0}
								<p class="px-4 py-3 text-sm text-[color:var(--muted-foreground)]">
									Sin resultados para “{searchQuery.trim()}”.
								</p>
							{:else}
								<ul class="max-h-[22rem] overflow-y-auto">
									{#each searchResults as result}
										<li class="border-b border-[color:var(--border)] last:border-b-0">
											<a
												href={resultHref(result)}
												class="block px-4 py-2 hover:bg-[color:var(--muted)]"
											>
												<span class="block text-sm font-semibold text-[color:var(--foreground)]">
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
					{/if}
				</div>

				<div class="mt-6 flex flex-wrap items-center justify-center gap-3">
					{#if firstChapterSlug}
						<a
							href={`/dashboard/guia/${firstChapterSlug}`}
							class="inline-flex items-center border border-[color:var(--primary)] bg-[color:var(--primary)] px-4 py-2 text-sm font-semibold text-[color:var(--primary-foreground)] hover:opacity-90"
						>
							Empezar por el principio
						</a>
					{/if}
					{#if hasFaq}
						<a
							href="/dashboard/guia/faq"
							class="inline-flex items-center border border-[color:var(--border)] px-4 py-2 text-sm hover:bg-[color:var(--muted)]"
						>
							Preguntas frecuentes
						</a>
					{/if}
				</div>
			</div>
		</div>
	</div>
</section>

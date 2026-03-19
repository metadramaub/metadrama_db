<script lang="ts">
	import { browser } from '$app/environment';
	import { renderMarkdown } from '$lib/utils/markdown';
	import { onMount } from 'svelte';
	import type { PageData } from './$types';

	const OPEN_CHAPTERS_STORAGE_KEY = 'dashboard-guide-open-chapters';

	let { data } = $props<{ data: PageData }>();
	let openChapterSlugs = $state<string[]>([]);
	let lastSeenChapterSlug = $state<string | null>(null);

	function normalizeOpenSlugs(candidateSlugs: string[]): string[] {
		const validSlugs = new Set(data.chapters.map((chapter: { slug: string }) => chapter.slug));
		const seen = new Set<string>();
		const normalized: string[] = [];
		for (const slug of candidateSlugs) {
			if (!validSlugs.has(slug) || seen.has(slug)) continue;
			seen.add(slug);
			normalized.push(slug);
		}
		return normalized;
	}

	function persistOpenChapterSlugs(candidateSlugs: string[]) {
		const normalized = normalizeOpenSlugs(candidateSlugs);
		openChapterSlugs = normalized;
		if (!browser) return;
		window.localStorage.setItem(OPEN_CHAPTERS_STORAGE_KEY, JSON.stringify(normalized));
	}

	function isChapterOpen(slug: string): boolean {
		return openChapterSlugs.includes(slug);
	}

	function toggleChapter(slug: string) {
		if (isChapterOpen(slug)) {
			persistOpenChapterSlugs(openChapterSlugs.filter((currentSlug) => currentSlug !== slug));
			return;
		}
		persistOpenChapterSlugs([...openChapterSlugs, slug]);
	}

	function sectionHref(chapterSlug: string, sectionId: string): string {
		if (chapterSlug === data.currentChapter.slug) {
			return `#${sectionId}`;
		}
		return `/dashboard/guia/${chapterSlug}#${sectionId}`;
	}

	onMount(() => {
		if (!browser) return;
		try {
			const raw = window.localStorage.getItem(OPEN_CHAPTERS_STORAGE_KEY);
			if (!raw) return;
			const parsed = JSON.parse(raw);
			if (!Array.isArray(parsed)) return;
			const stored = normalizeOpenSlugs(parsed.filter((value): value is string => typeof value === 'string'));
			if (stored.length === 0) return;
			const withCurrent = stored.includes(data.currentChapter.slug)
				? stored
				: [...stored, data.currentChapter.slug];
			persistOpenChapterSlugs(withCurrent);
		} catch (error) {
			console.warn('No se pudo restaurar el estado del menú de la guía', error);
		}
	});

	$effect(() => {
		const currentSlug = data.currentChapter.slug;
		if (currentSlug === lastSeenChapterSlug) return;
		lastSeenChapterSlug = currentSlug;
		if (openChapterSlugs.includes(currentSlug)) return;
		persistOpenChapterSlugs([...openChapterSlugs, currentSlug]);
	});
</script>

<section class="space-y-4">
	<header>
		<h1 class="font-display text-3xl">GUÍA EDITORIAL</h1>
		<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
			Manual interno para los editores y colaboradores del proyecto.
		</p>
	</header>

	<div class="grid gap-4 lg:grid-cols-[14rem_minmax(0,1fr)] lg:items-start">
		<aside class="lg:sticky lg:top-4 lg:max-h-[calc(100vh-2.5rem)] lg:overflow-y-auto">
			<nav class="flex flex-col gap-2">
				{#each data.chapters as chapter}
					<section
						class={`transition-colors ${
							chapter.slug === data.currentChapter.slug
								? 'border border-[color:var(--primary)]'
								: 'border border-transparent'
						}`}
					>
						<div class="flex items-start gap-1 px-2 py-1.5">
							<button
								type="button"
								class="shrink-0 px-1 text-xs leading-none text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)]"
								aria-label={isChapterOpen(chapter.slug) ? 'Contraer capítulo' : 'Expandir capítulo'}
								aria-expanded={isChapterOpen(chapter.slug)}
								onclick={() => toggleChapter(chapter.slug)}
							>
								{isChapterOpen(chapter.slug) ? '−' : '+'}
							</button>
							<a
								href={`/dashboard/guia/${chapter.slug}`}
								aria-current={chapter.slug === data.currentChapter.slug ? 'page' : undefined}
								class={`min-w-0 flex-1 text-sm font-semibold leading-5 ${
									chapter.slug === data.currentChapter.slug
										? 'text-[color:var(--foreground)]'
										: 'text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)]'
								}`}
							>
								{chapter.title}
							</a>
						</div>

						{#if isChapterOpen(chapter.slug) && chapter.sections.length > 0}
							<ul class="space-y-1 px-4 pb-2">
								{#each chapter.sections as section}
									<li>
										<a
											href={sectionHref(chapter.slug, section.id)}
											class="block text-xs text-[color:var(--muted-foreground)] hover:text-[color:var(--foreground)] hover:underline"
										>
											{section.title}
										</a>
									</li>
								{/each}
							</ul>
						{/if}
					</section>
				{/each}
			</nav>
		</aside>

		<article class="card p-5 md:p-6">
			<header class="border-b border-[color:var(--border)] pb-3">
				<h2 class="text-2xl font-semibold">{data.currentChapter.title}</h2>
				<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">{data.currentChapter.summary}</p>
			</header>

			<div class="mt-4 space-y-2 text-sm leading-6">
				{@html renderMarkdown(data.currentChapter.markdown, { allowTrustedHtml: true })}
			</div>

			<div class="mt-4 flex flex-wrap items-center justify-between gap-2 border-t border-[color:var(--border)] pt-4">
				<div>
					{#if data.prevChapter}
						<a
							class="inline-flex items-center border border-[color:var(--border)] px-3 py-2 text-sm hover:bg-[color:var(--muted)]"
							href={`/dashboard/guia/${data.prevChapter.slug}`}
						>
							Anterior: {data.prevChapter.title}
						</a>
					{:else}
						<span class="text-xs text-[color:var(--muted-foreground)]">Inicio de la guía</span>
					{/if}
				</div>
				<div>
					{#if data.nextChapter}
						<a
							class="inline-flex items-center border border-[color:var(--border)] px-3 py-2 text-sm hover:bg-[color:var(--muted)]"
							href={`/dashboard/guia/${data.nextChapter.slug}`}
						>
							Siguiente: {data.nextChapter.title}
						</a>
					{:else}
						<span class="text-xs text-[color:var(--muted-foreground)]">Fin de la guía</span>
					{/if}
				</div>
			</div>
		</article>
	</div>
</section>

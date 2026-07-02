<script lang="ts">
	import { renderMarkdown } from '$lib/utils/markdown';
	import GuideNav from '$lib/components/dashboard/GuideNav.svelte';
	import type { PageData } from './$types';

	let { data } = $props<{ data: PageData }>();
</script>

<section class="space-y-4">
	<header class="flex flex-wrap items-baseline justify-between gap-2">
		<div>
			<h1 class="font-display text-3xl">GUÍA EDITORIAL</h1>
			<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">
				Manual interno para los editores y colaboradores del proyecto.
			</p>
		</div>
		<a
			href="/dashboard/guia"
			class="text-sm text-[color:var(--muted-foreground)] underline-offset-2 hover:text-[color:var(--foreground)] hover:underline"
		>
			Inicio
		</a>
	</header>

	<div class="grid gap-8 lg:grid-cols-[15rem_minmax(0,1fr)] lg:items-start">
		<aside class="lg:sticky lg:top-4 lg:max-h-[calc(100vh-2.5rem)] lg:overflow-y-auto">
			<GuideNav
				chapters={data.chapters}
				searchIndex={data.searchIndex}
				currentSlug={data.currentChapter.slug}
			/>
		</aside>

		<article class="min-w-0 max-w-3xl">
			<header class="border-b border-[color:var(--border)] pb-3">
				<h2 class="text-2xl font-semibold">{data.currentChapter.title}</h2>
				<p class="mt-1 text-sm text-[color:var(--muted-foreground)]">{data.currentChapter.summary}</p>
			</header>

			<div class="mt-4 space-y-2 text-[0.95rem] leading-7">
				{@html renderMarkdown(data.currentChapter.markdown, { allowTrustedHtml: true })}
			</div>

			<div class="mt-8 flex flex-wrap items-center justify-between gap-2 border-t border-[color:var(--border)] pt-4">
				<div>
					{#if data.prevChapter}
						<a
							class="inline-flex items-center border border-[color:var(--border)] px-3 py-2 text-sm hover:bg-[color:var(--muted)]"
							href={`/dashboard/guia/${data.prevChapter.slug}`}
						>
							Anterior: {data.prevChapter.title}
						</a>
					{:else}
						<a
							class="text-xs text-[color:var(--muted-foreground)] underline-offset-2 hover:underline"
							href="/dashboard/guia"
						>
							Volver al índice
						</a>
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

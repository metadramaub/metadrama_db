import { DASHBOARD_GUIDE_CHAPTERS } from '$lib/content/dashboard-guide';
import type {
	DashboardGuideChapter,
	DashboardGuideChapterMeta,
	DashboardGuideSection
} from '$lib/types/dashboard-guide.types';
import { createHeadingIdGenerator, extractHeadingText } from '$lib/utils/heading-ids';

const rawChapterModules = import.meta.glob('../content/dashboard-guide/chapters/*.md', {
	eager: true,
	query: '?raw',
	import: 'default'
}) as Record<string, string>;

type DashboardGuidePagePayload = {
	chapters: DashboardGuideChapter[];
	currentChapter: DashboardGuideChapter;
	prevChapter: DashboardGuideChapter | null;
	nextChapter: DashboardGuideChapter | null;
};

function buildMarkdownByFileName(modules: Record<string, string>): Map<string, string> {
	const map = new Map<string, string>();
	for (const [modulePath, markdown] of Object.entries(modules)) {
		const segments = modulePath.split('/');
		const fileName = segments[segments.length - 1] ?? '';
		if (!fileName) continue;
		map.set(fileName, markdown);
	}
	return map;
}

const markdownByFileName = buildMarkdownByFileName(rawChapterModules);

function buildFallbackMarkdown(meta: DashboardGuideChapterMeta): string {
	return `## Contenido pendiente

Este capítulo aún no tiene contenido disponible.

## Qué hacer

1. Verifica el valor de \`file\` en \`src/lib/content/dashboard-guide/index.ts\`.
2. Crea o completa el archivo en \`src/lib/content/dashboard-guide/chapters/\`.
3. Vuelve a cargar la página.
`;
}

function extractMarkdownSections(markdown: string): DashboardGuideSection[] {
	const sections: DashboardGuideSection[] = [];
	const lines = markdown.replaceAll('\r\n', '\n').split('\n');
	const nextHeadingId = createHeadingIdGenerator();

	for (const rawLine of lines) {
		const line = rawLine.trim();
		if (!line) continue;

		if (line.startsWith('# ')) {
			nextHeadingId(line.slice(2));
			continue;
		}

		if (line.startsWith('#### ')) {
			nextHeadingId(line.slice(5));
			continue;
		}

		if (line.startsWith('### ')) {
			nextHeadingId(line.slice(4));
			continue;
		}

		if (line.startsWith('## ')) {
			const headingContent = line.slice(3);
			const id = nextHeadingId(headingContent);
			const title = extractHeadingText(headingContent);
			sections.push({ id, title });
		}
	}

	return sections;
}

function resolveChapter(meta: DashboardGuideChapterMeta): DashboardGuideChapter {
	const markdown = markdownByFileName.get(meta.file);
	if (markdown && markdown.trim().length > 0) {
		return { ...meta, markdown, sections: extractMarkdownSections(markdown) };
	}
	const fallbackMarkdown = buildFallbackMarkdown(meta);
	return { ...meta, markdown: fallbackMarkdown, sections: extractMarkdownSections(fallbackMarkdown) };
}

export function getDashboardGuideChapters(): DashboardGuideChapter[] {
	return DASHBOARD_GUIDE_CHAPTERS.map(resolveChapter);
}

export function getFirstDashboardGuideChapterSlug(): string | null {
	return DASHBOARD_GUIDE_CHAPTERS[0]?.slug ?? null;
}

export function getDashboardGuidePagePayload(slug: string): DashboardGuidePagePayload | null {
	const chapters = getDashboardGuideChapters();
	const currentIndex = chapters.findIndex((chapter) => chapter.slug === slug);
	if (currentIndex < 0) return null;

	return {
		chapters,
		currentChapter: chapters[currentIndex],
		prevChapter: currentIndex > 0 ? chapters[currentIndex - 1] : null,
		nextChapter: currentIndex < chapters.length - 1 ? chapters[currentIndex + 1] : null
	};
}

export type { DashboardGuidePagePayload };

import { DASHBOARD_GUIDE_CHAPTERS } from '$lib/content/dashboard-guide';
import type {
	DashboardGuideChapter,
	DashboardGuideChapterMeta,
	DashboardGuideSearchEntry,
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
	searchIndex: DashboardGuideSearchEntry[];
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

function buildFallbackMarkdown(): string {
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

function stripMarkdownMarks(line: string): string {
	return line
		.replace(/^>\s?/, '')
		.replace(/^[-*]\s+/, '')
		.replace(/^\d+\.\s+/, '')
		.replaceAll(/\[(.*?)\]\((.*?)\)/g, '$1')
		.replaceAll(/`([^`]+)`/g, '$1')
		.replaceAll(/\*\*(.+?)\*\*/g, '$1')
		.replaceAll(/\*(.+?)\*/g, '$1')
		.replaceAll(/\[!([A-Za-z]+)\]/g, '')
		.trim();
}

function buildChapterSearchEntries(chapter: DashboardGuideChapter): DashboardGuideSearchEntry[] {
	const entries: DashboardGuideSearchEntry[] = [];
	const lines = chapter.markdown.replaceAll('\r\n', '\n').split('\n');
	const nextHeadingId = createHeadingIdGenerator();

	// Preámbulo: texto antes del primer "## " se asocia al capítulo (ancla vacía).
	let current: DashboardGuideSearchEntry = {
		chapterSlug: chapter.slug,
		chapterTitle: chapter.title,
		sectionId: '',
		sectionTitle: chapter.title,
		text: ''
	};
	let inCodeFence = false;

	const pushCurrent = () => {
		current.text = current.text.trim();
		if (current.text.length > 0 || current.sectionId) {
			entries.push(current);
		}
	};

	for (const rawLine of lines) {
		const line = rawLine.trim();

		if (line.startsWith('```')) {
			inCodeFence = !inCodeFence;
			continue;
		}
		if (inCodeFence) continue;
		if (!line) continue;

		if (line.startsWith('# ') || line.startsWith('#### ') || line.startsWith('### ')) {
			// Estos headings generan id (para mantener contadores sincronizados) pero no abren sección de búsqueda.
			const headingContent = line.replace(/^#+\s+/, '');
			nextHeadingId(headingContent);
			current.text += ` ${stripMarkdownMarks(headingContent)}`;
			continue;
		}

		if (line.startsWith('## ')) {
			pushCurrent();
			const headingContent = line.slice(3);
			const id = nextHeadingId(headingContent);
			const title = extractHeadingText(headingContent);
			current = {
				chapterSlug: chapter.slug,
				chapterTitle: chapter.title,
				sectionId: id,
				sectionTitle: title,
				text: title
			};
			continue;
		}

		current.text += ` ${stripMarkdownMarks(line)}`;
	}

	pushCurrent();
	return entries;
}

function buildSearchIndex(chapters: DashboardGuideChapter[]): DashboardGuideSearchEntry[] {
	return chapters.flatMap(buildChapterSearchEntries);
}

function resolveChapter(meta: DashboardGuideChapterMeta): DashboardGuideChapter {
	const markdown = markdownByFileName.get(meta.file);
	if (markdown && markdown.trim().length > 0) {
		return { ...meta, markdown, sections: extractMarkdownSections(markdown) };
	}
	const fallbackMarkdown = buildFallbackMarkdown();
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
		nextChapter: currentIndex < chapters.length - 1 ? chapters[currentIndex + 1] : null,
		searchIndex: buildSearchIndex(chapters)
	};
}

type DashboardGuideIndexPayload = {
	chapters: DashboardGuideChapter[];
	searchIndex: DashboardGuideSearchEntry[];
};

export function getDashboardGuideIndexPayload(): DashboardGuideIndexPayload {
	const chapters = getDashboardGuideChapters();
	return {
		chapters,
		searchIndex: buildSearchIndex(chapters)
	};
}

export type { DashboardGuidePagePayload, DashboardGuideIndexPayload };

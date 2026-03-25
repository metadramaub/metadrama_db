import { createHeadingIdGenerator } from '$lib/utils/heading-ids';

type CalloutTone = 'note' | 'tip' | 'warning' | 'important' | 'danger' | 'success';
type RenderMarkdownOptions = {
	allowTrustedHtml?: boolean;
};

export function escapeHtml(input: string): string {
	return input
		.replaceAll('&', '&amp;')
		.replaceAll('<', '&lt;')
		.replaceAll('>', '&gt;')
		.replaceAll('"', '&quot;')
		.replaceAll("'", '&#39;');
}

function sanitizeUrl(url: string): string {
	const trimmed = url.trim();
	if (!trimmed || trimmed.startsWith('//')) {
		return '#';
	}
	if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
		return trimmed;
	}
	if (trimmed.startsWith('/') || trimmed.startsWith('#')) {
		return trimmed;
	}
	return '#';
}

function renderInline(markdown: string): string {
	let output = escapeHtml(markdown);
	const codeTokens: string[] = [];

	output = output.replace(/`(.+?)`/g, (_full, code: string) => {
		const token = `__MD_CODE_${codeTokens.length}__`;
		codeTokens.push(
			`<code class="border border-[color:var(--border)] bg-[color:var(--muted)] px-1 py-0.5 text-sm">${code}</code>`
		);
		return token;
	});

	output = output.replace(/\[(.*?)\]\((.*?)\)/g, (_full, label: string, url: string) => {
		const safeUrl = sanitizeUrl(url);
		const isExternal = safeUrl.startsWith('http://') || safeUrl.startsWith('https://');
		const externalAttributes = isExternal ? ' target="_blank" rel="noreferrer"' : '';
		return `<a href="${safeUrl}"${externalAttributes} class="text-[color:var(--accent)] underline">${escapeHtml(label)}</a>`;
	});
	output = output.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
	output = output.replace(/\*(.+?)\*/g, '<em>$1</em>');
	output = output.replace(/__MD_CODE_(\d+)__/g, (_full, index: string) => codeTokens[Number(index)] ?? '');

	return output;
}

function countDivTagDelta(line: string): number {
	const openCount = (line.match(/<div\b/gi) ?? []).length;
	const closeCount = (line.match(/<\/div>/gi) ?? []).length;
	return openCount - closeCount;
}

function readTrustedHtmlBlock(lines: string[], startIndex: number): { html: string; nextIndex: number } | null {
	const startLine = (lines[startIndex] ?? '').trim();
	if (startLine !== '<div class="markdown-fake-preview">') return null;

	const htmlLines: string[] = [lines[startIndex] ?? ''];
	let depth = countDivTagDelta(lines[startIndex] ?? '');
	let index = startIndex;

	while (index + 1 < lines.length && depth > 0) {
		index += 1;
		const currentLine = lines[index] ?? '';
		htmlLines.push(currentLine);
		depth += countDivTagDelta(currentLine);
	}

	return {
		html: htmlLines.join('\n'),
		nextIndex: index
	};
}

function readFencedCodeBlock(lines: string[], startIndex: number): { html: string; nextIndex: number } | null {
	const startLine = (lines[startIndex] ?? '').trim();
	const fenceMatch = startLine.match(/^```([\w-]+)?\s*$/);
	if (!fenceMatch) return null;

	const language = fenceMatch[1]?.trim() ?? '';
	const codeLines: string[] = [];
	let index = startIndex + 1;

	while (index < lines.length) {
		const currentLine = lines[index] ?? '';
		if (currentLine.trim() === '```') {
			break;
		}
		codeLines.push(currentLine);
		index += 1;
	}

	const escapedCode = escapeHtml(codeLines.join('\n'));
	const languageBadge = language
		? `<div class="markdown-code-block__lang">${escapeHtml(language)}</div>`
		: '';

	return {
		html: `<div class="markdown-code-block">${languageBadge}<pre class="markdown-code-block__pre"><code>${escapedCode}</code></pre></div>`,
		nextIndex: index < lines.length ? index : lines.length - 1
	};
}

function renderSimpleBlocks(lines: string[]): string {
	const blocks: string[] = [];
	let listItems: string[] = [];
	let listType: 'ul' | 'ol' | null = null;

	const flushList = () => {
		if (listItems.length === 0 || !listType) return;
		if (listType === 'ul') {
			blocks.push(`<ul class="mt-2 list-disc space-y-1 pl-6">${listItems.join('')}</ul>`);
		} else {
			blocks.push(`<ol class="mt-2 list-decimal space-y-1 pl-6">${listItems.join('')}</ol>`);
		}
		listItems = [];
		listType = null;
	};

	for (let index = 0; index < lines.length; index += 1) {
		const rawLine = lines[index] ?? '';
		const line = rawLine.trim();
		if (!line) {
			flushList();
			continue;
		}

		const fencedCodeBlock = readFencedCodeBlock(lines, index);
		if (fencedCodeBlock) {
			flushList();
			blocks.push(fencedCodeBlock.html);
			index = fencedCodeBlock.nextIndex;
			continue;
		}

		if (line.startsWith('- ')) {
			if (listType === 'ol') flushList();
			listType = 'ul';
			listItems.push(`<li>${renderInline(line.slice(2))}</li>`);
			continue;
		}

		const orderedMatch = line.match(/^\d+\.\s+(.*)$/);
		if (orderedMatch) {
			if (listType === 'ul') flushList();
			listType = 'ol';
			listItems.push(`<li>${renderInline(orderedMatch[1] ?? '')}</li>`);
			continue;
		}

		if (line.startsWith('#### ')) {
			flushList();
			blocks.push(`<h4 class="mt-3 text-base font-semibold">${renderInline(line.slice(5))}</h4>`);
			continue;
		}

		if (line.startsWith('### ')) {
			flushList();
			blocks.push(`<h3 class="mt-4 text-lg font-semibold">${renderInline(line.slice(4))}</h3>`);
			continue;
		}

		if (line.startsWith('## ')) {
			flushList();
			blocks.push(`<h2 class="mt-5 text-xl font-semibold">${renderInline(line.slice(3))}</h2>`);
			continue;
		}

		if (line.startsWith('# ')) {
			flushList();
			blocks.push(`<h1 class="mt-6 text-2xl font-semibold">${renderInline(line.slice(2))}</h1>`);
			continue;
		}

		flushList();
		blocks.push(`<p>${renderInline(line)}</p>`);
	}

	flushList();
	return blocks.join('');
}

function normalizeCalloutTone(rawTone: string): CalloutTone {
	const tone = rawTone.trim().toLowerCase();
	if (tone === 'tip' || tone === 'hint') return 'tip';
	if (tone === 'warning' || tone === 'caution') return 'warning';
	if (tone === 'important') return 'important';
	if (tone === 'danger' || tone === 'error') return 'danger';
	if (tone === 'success') return 'success';
	return 'note';
}

function defaultCalloutTitle(tone: CalloutTone): string {
	if (tone === 'tip') return 'Consejo';
	if (tone === 'warning') return 'Aviso';
	if (tone === 'important') return 'Importante';
	if (tone === 'danger') return 'Atencion';
	if (tone === 'success') return 'OK';
	return 'Nota';
}

function trimLeadingBlankLines(lines: string[]): string[] {
	let start = 0;
	while (start < lines.length && lines[start]?.trim() === '') {
		start += 1;
	}
	return lines.slice(start);
}

function renderQuoteBlock(quoteLines: string[]): string {
	const contentLines = quoteLines.map((line) => line.replace(/^>\s?/, ''));
	const firstLine = contentLines[0]?.trim() ?? '';
	const calloutMatch = firstLine.match(/^\[!([A-Za-z]+)\](?:\s+(.*))?$/);

	if (calloutMatch) {
		const tone = normalizeCalloutTone(calloutMatch[1] ?? 'note');
		const explicitTitle = (calloutMatch[2] ?? '').trim();
		const title = explicitTitle || defaultCalloutTitle(tone);
		const bodyLines = trimLeadingBlankLines(contentLines.slice(1));
		const bodyHtml = renderSimpleBlocks(bodyLines);
		const bodySection = bodyHtml ? `<div class="markdown-callout__body">${bodyHtml}</div>` : '';
		return `<aside class="markdown-callout markdown-callout--${tone}"><p class="markdown-callout__title">${renderInline(title)}</p>${bodySection}</aside>`;
	}

	const bodyHtml = renderSimpleBlocks(trimLeadingBlankLines(contentLines));
	if (!bodyHtml) {
		return '<blockquote class="markdown-blockquote"></blockquote>';
	}
	return `<blockquote class="markdown-blockquote">${bodyHtml}</blockquote>`;
}

export function renderMarkdown(markdown: string, options: RenderMarkdownOptions = {}): string {
	const lines = markdown.replaceAll('\r\n', '\n').split('\n');
	const blocks: string[] = [];
	let listItems: string[] = [];
	let listType: 'ul' | 'ol' | null = null;
	const nextHeadingId = createHeadingIdGenerator();

	const flushList = () => {
		if (listItems.length === 0 || !listType) return;
		if (listType === 'ul') {
			blocks.push(`<ul class="mt-3 list-disc space-y-1 pl-6">${listItems.join('')}</ul>`);
		} else {
			blocks.push(`<ol class="mt-3 list-decimal space-y-1 pl-6">${listItems.join('')}</ol>`);
		}
		listItems = [];
		listType = null;
	};

	for (let index = 0; index < lines.length; index += 1) {
		const rawLine = lines[index] ?? '';
		const line = rawLine.trim();
		if (!line) {
			flushList();
			continue;
		}

		if (options.allowTrustedHtml) {
			const trustedHtmlBlock = readTrustedHtmlBlock(lines, index);
			if (trustedHtmlBlock) {
				flushList();
				blocks.push(trustedHtmlBlock.html);
				index = trustedHtmlBlock.nextIndex;
				continue;
			}
		}

		const fencedCodeBlock = readFencedCodeBlock(lines, index);
		if (fencedCodeBlock) {
			flushList();
			blocks.push(fencedCodeBlock.html);
			index = fencedCodeBlock.nextIndex;
			continue;
		}

		if (line.startsWith('>')) {
			flushList();
			const quoteLines: string[] = [rawLine];
			while (index + 1 < lines.length && (lines[index + 1] ?? '').trim().startsWith('>')) {
				index += 1;
				quoteLines.push(lines[index] ?? '');
			}
			blocks.push(renderQuoteBlock(quoteLines));
			continue;
		}

		if (line.startsWith('- ')) {
			if (listType === 'ol') {
				flushList();
			}
			listType = 'ul';
			listItems.push(`<li>${renderInline(line.slice(2))}</li>`);
			continue;
		}

		const orderedMatch = line.match(/^\d+\.\s+(.*)$/);
		if (orderedMatch) {
			if (listType === 'ul') {
				flushList();
			}
			listType = 'ol';
			listItems.push(`<li>${renderInline(orderedMatch[1] ?? '')}</li>`);
			continue;
		}

		flushList();
		if (line.startsWith('#### ')) {
			const headingContent = line.slice(5);
			const headingId = nextHeadingId(headingContent);
			blocks.push(
				`<h4 id="${headingId}" class="!mt-4 scroll-mt-24 text-base font-semibold">${renderInline(headingContent)}</h4>`
			);
			continue;
		}
		if (line.startsWith('### ')) {
			const headingContent = line.slice(4);
			const headingId = nextHeadingId(headingContent);
			blocks.push(
				`<h3 id="${headingId}" class="!mt-6 scroll-mt-24 text-lg font-semibold">${renderInline(headingContent)}</h3>`
			);
			continue;
		}
		if (line.startsWith('## ')) {
			const headingContent = line.slice(3);
			const headingId = nextHeadingId(headingContent);
			blocks.push(
				`<h2 id="${headingId}" class="!mt-8 scroll-mt-24 text-xl font-semibold">${renderInline(headingContent)}</h2>`
			);
			continue;
		}
		if (line.startsWith('# ')) {
			const headingContent = line.slice(2);
			const headingId = nextHeadingId(headingContent);
			blocks.push(
				`<h1 id="${headingId}" class="!mt-10 scroll-mt-24 text-2xl font-semibold">${renderInline(headingContent)}</h1>`
			);
			continue;
		}

		blocks.push(`<p>${renderInline(line)}</p>`);
	}

	flushList();

	if (blocks.length === 0) {
		return '<p class="text-[color:var(--muted-foreground)]">Sin contenido.</p>';
	}
	return blocks.join('');
}

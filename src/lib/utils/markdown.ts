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
	if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
		return trimmed;
	}
	return '#';
}

function renderInline(markdown: string): string {
	let output = escapeHtml(markdown);

	output = output.replace(/\[(.*?)\]\((.*?)\)/g, (_full, label: string, url: string) => {
		return `<a href="${sanitizeUrl(url)}" target="_blank" rel="noreferrer" class="text-[color:var(--accent)] underline">${escapeHtml(label)}</a>`;
	});
	output = output.replace(/\*\*(.+?)\*\*/g, '<strong>$1</strong>');
	output = output.replace(/\*(.+?)\*/g, '<em>$1</em>');
	output = output.replace(
		/`(.+?)`/g,
		'<code class="border border-[color:var(--border)] bg-[color:var(--muted)] px-1 py-0.5 text-sm">$1</code>'
	);

	return output;
}

export function renderMarkdown(markdown: string): string {
	const lines = markdown.replaceAll('\r\n', '\n').split('\n');
	const blocks: string[] = [];
	let listItems: string[] = [];
	let listType: 'ul' | 'ol' | null = null;

	const flushList = () => {
		if (listItems.length === 0 || !listType) return;
		if (listType === 'ul') {
			blocks.push(`<ul class="list-disc space-y-1 pl-6">${listItems.join('')}</ul>`);
		} else {
			blocks.push(`<ol class="list-decimal space-y-1 pl-6">${listItems.join('')}</ol>`);
		}
		listItems = [];
		listType = null;
	};

	for (const rawLine of lines) {
		const line = rawLine.trim();
		if (!line) {
			flushList();
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
		if (line.startsWith('## ')) {
			blocks.push(`<h2 class="mt-4 text-xl font-semibold">${renderInline(line.slice(3))}</h2>`);
			continue;
		}
		if (line.startsWith('# ')) {
			blocks.push(`<h1 class="mt-4 text-2xl font-semibold">${renderInline(line.slice(2))}</h1>`);
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

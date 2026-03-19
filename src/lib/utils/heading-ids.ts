export function extractHeadingText(markdownHeading: string): string {
	return markdownHeading
		.replaceAll(/\[(.*?)\]\((.*?)\)/g, '$1')
		.replaceAll(/`(.+?)`/g, '$1')
		.replaceAll(/\*\*(.+?)\*\*/g, '$1')
		.replaceAll(/\*(.+?)\*/g, '$1')
		.trim();
}

export function slugifyHeadingId(markdownHeading: string): string {
	const plainText = extractHeadingText(markdownHeading);
	const normalized = plainText
		.normalize('NFD')
		.replaceAll(/\p{M}/gu, '')
		.toLowerCase()
		.replaceAll(/[^a-z0-9]+/g, '-')
		.replaceAll(/^-+|-+$/g, '');

	return normalized || 'seccion';
}

export function createHeadingIdGenerator() {
	const counters = new Map<string, number>();
	return (markdownHeading: string): string => {
		const base = slugifyHeadingId(markdownHeading);
		const count = (counters.get(base) ?? 0) + 1;
		counters.set(base, count);
		return count === 1 ? base : `${base}-${count}`;
	};
}


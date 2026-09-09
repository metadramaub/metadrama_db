import type {
	DiagramExportMeta,
	DiagramLegendItem
} from '$lib/components/metrica/diagram-export.types';

const SVG_NS = 'http://www.w3.org/2000/svg';
const EXPORT_WIDTH = 1200;
const SCALE = 2;

const STYLE_PROPERTIES = [
	'background', 'background-color', 'border', 'border-bottom', 'border-left', 'border-right',
	'border-top', 'box-sizing', 'color', 'display', 'fill', 'font-family', 'font-size',
	'font-style', 'font-variant-numeric', 'font-weight', 'gap', 'grid-template-columns', 'height',
	'justify-content', 'letter-spacing', 'line-height', 'margin', 'max-width', 'opacity', 'overflow',
	'padding', 'position', 'stroke', 'stroke-dasharray', 'stroke-linecap', 'stroke-linejoin',
	'stroke-width', 'text-align', 'text-anchor', 'text-transform', 'vertical-align', 'white-space', 'width'
] as const;

function svgElement<K extends keyof SVGElementTagNameMap>(name: K): SVGElementTagNameMap[K] {
	return document.createElementNS(SVG_NS, name);
}

/** Las clases y variables CSS no sobreviven a XMLSerializer: se resuelven antes de clonar. */
function inlineStyles(source: Element, clone: Element) {
	const computed = getComputedStyle(source);
	const target = clone as HTMLElement | SVGElement;
	for (const property of STYLE_PROPERTIES) {
		const value = computed.getPropertyValue(property);
		if (value) target.style.setProperty(property, value);
	}
	const sourceChildren = [...source.children];
	const cloneChildren = [...clone.children];
	for (let index = 0; index < sourceChildren.length; index += 1) {
		if (cloneChildren[index]) inlineStyles(sourceChildren[index], cloneChildren[index]);
	}
}

function uniqueLegend(items: DiagramLegendItem[] = []): DiagramLegendItem[] {
	const seen = new Set<string>();
	return items.filter((item) => {
		const key = `${item.label}\u0000${item.color}`;
		if (seen.has(key)) return false;
		seen.add(key);
		return true;
	});
}

function addText(
	parent: SVGElement,
	text: string,
	x: number,
	y: number,
	attrs: Record<string, string> = {}
) {
	const node = svgElement('text');
	node.textContent = text;
	node.setAttribute('x', String(x));
	node.setAttribute('y', String(y));
	node.setAttribute('font-family', 'Arial, Helvetica, sans-serif');
	node.setAttribute('fill', '#111827');
	for (const [name, value] of Object.entries(attrs)) node.setAttribute(name, value);
	parent.append(node);
}

function addLegend(root: SVGSVGElement, items: DiagramLegendItem[], yStart: number, width: number) {
	if (items.length === 0) return 0;
	const group = svgElement('g');
	root.append(group);
	let x = 36;
	let y = yStart + 28;
	for (const item of items) {
		const itemWidth = Math.max(110, Math.min(260, 44 + item.label.length * 7));
		if (x + itemWidth > width - 32) {
			x = 36;
			y += 30;
		}
		const swatch = svgElement('rect');
		swatch.setAttribute('x', String(x));
		swatch.setAttribute('y', String(y - 12));
		swatch.setAttribute('width', '18');
		swatch.setAttribute('height', '12');
		swatch.setAttribute('fill', item.color);
		group.append(swatch);
		addText(group, item.label, x + 26, y - 1, { 'font-size': '14' });
		x += itemWidth;
	}
	return y - yStart + 18;
}

function appendFooter(root: SVGSVGElement, meta: DiagramExportMeta, y: number, width: number) {
	const group = svgElement('g');
	root.append(group);
	const rule = svgElement('line');
	rule.setAttribute('x1', '32');
	rule.setAttribute('x2', String(width - 32));
	rule.setAttribute('y1', String(y));
	rule.setAttribute('y2', String(y));
	rule.setAttribute('stroke', '#9ca3af');
	group.append(rule);
	addText(group, meta.workTitle, 32, y + 30, { 'font-size': '18', 'font-weight': '700' });
	addText(group, meta.title, 32, y + 53, { 'font-size': '14' });
	addText(group, 'Versología · versologia.metadrama.org', 32, y + 83, {
		'font-size': '14', 'font-weight': '700'
	});
	const permalink = new URL(meta.permalink, window.location.origin).href;
	const consulted = new Intl.DateTimeFormat('es-ES', { dateStyle: 'long' }).format(new Date());
	addText(group, `${permalink} · consulta: ${consulted}`, 32, y + 104, { 'font-size': '12' });
	return 124;
}

function prepareSvg(target: Element, width: number): { svg: SVGSVGElement; contentHeight: number } {
	if (target instanceof SVGSVGElement) {
		const clone = target.cloneNode(true) as SVGSVGElement;
		inlineStyles(target, clone);
		const viewBox = target.viewBox.baseVal;
		const sourceWidth = viewBox.width || target.getBoundingClientRect().width || width;
		const sourceHeight = viewBox.height || target.getBoundingClientRect().height || 400;
		const scale = width / sourceWidth;
		const contentHeight = sourceHeight * scale;
		clone.setAttribute('x', '0');
		clone.setAttribute('y', '0');
		clone.setAttribute('width', String(width));
		clone.setAttribute('height', String(contentHeight));
		clone.setAttribute('viewBox', `${viewBox.x} ${viewBox.y} ${sourceWidth} ${sourceHeight}`);
		clone.setAttribute('preserveAspectRatio', 'xMidYMid meet');
		const svg = svgElement('svg');
		svg.append(clone);
		return { svg, contentHeight };
	}

	// Un SVG con `foreignObject` contamina el canvas en Chromium y hace que `toBlob` lance
	// SecurityError. Los contenedores solo sirven para localizar uno o varios SVG reales: se
	// serializan estos directamente y, si hay varios (vista por jornadas), se apilan en SVG puro.
	const descendants = [...target.querySelectorAll('svg')];
	if (descendants.length === 0) {
		throw new Error('Este diagrama todavía no tiene una representación SVG exportable.');
	}
	if (descendants.length === 1) return prepareSvg(descendants[0], width);

	const svg = svgElement('svg');
	let contentHeight = 0;
	for (const descendant of descendants) {
		const prepared = prepareSvg(descendant, width);
		prepared.svg.setAttribute('y', String(contentHeight));
		svg.append(prepared.svg);
		contentHeight += prepared.contentHeight + 24;
	}
	return { svg, contentHeight: Math.max(0, contentHeight - 24) };
}

function safeFilename(value: string): string {
	return value.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase()
		.replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '').slice(0, 90);
}

export async function exportDiagramPng(target: Element, meta: DiagramExportMeta): Promise<void> {
	const { svg, contentHeight } = prepareSvg(target, EXPORT_WIDTH);
	const legendHeight = addLegend(svg, uniqueLegend(meta.legend), contentHeight + 16, EXPORT_WIDTH);
	const footerY = contentHeight + legendHeight + 34;
	const totalHeight = Math.ceil(footerY + appendFooter(svg, meta, footerY, EXPORT_WIDTH) + 24);
	svg.setAttribute('xmlns', SVG_NS);
	svg.setAttribute('width', String(EXPORT_WIDTH));
	svg.setAttribute('height', String(totalHeight));
	svg.setAttribute('viewBox', `0 0 ${EXPORT_WIDTH} ${totalHeight}`);
	const background = svgElement('rect');
	background.setAttribute('width', String(EXPORT_WIDTH));
	background.setAttribute('height', String(totalHeight));
	background.setAttribute('fill', '#fff');
	svg.prepend(background);

	const url = URL.createObjectURL(new Blob(
		[new XMLSerializer().serializeToString(svg)],
		{ type: 'image/svg+xml;charset=utf-8' }
	));
	try {
		const image = new Image();
		image.decoding = 'async';
		await new Promise<void>((resolve, reject) => {
			image.onload = () => resolve();
			image.onerror = () => reject(new Error('No se pudo representar el diagrama para exportarlo.'));
			image.src = url;
		});
		const canvas = document.createElement('canvas');
		canvas.width = EXPORT_WIDTH * SCALE;
		canvas.height = totalHeight * SCALE;
		const context = canvas.getContext('2d');
		if (!context) throw new Error('El navegador no ofrece un lienzo para exportar el diagrama.');
		context.scale(SCALE, SCALE);
		context.fillStyle = '#fff';
		context.fillRect(0, 0, EXPORT_WIDTH, totalHeight);
		context.drawImage(image, 0, 0, EXPORT_WIDTH, totalHeight);
		const link = document.createElement('a');
		link.href = canvas.toDataURL('image/png');
		link.download = `${safeFilename(meta.filename)}.png`;
		link.hidden = true;
		document.body.append(link);
		link.click();
		link.remove();
	} finally {
		URL.revokeObjectURL(url);
	}
}

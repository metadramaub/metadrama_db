/**
 * El informe escrito, en HTML, para enviarlo: el Markdown de la obra con una hoja de estilo
 * dentro, que se abre en cualquier navegador y se imprime a PDF en un clic.
 */

import MarkdownIt from 'markdown-it';

const md = new MarkdownIt({ html: true, linkify: true, typographer: false });

const ESTILO = `
	:root { color-scheme: light; }
	body { font: 15px/1.55 Georgia, 'Times New Roman', serif; color: #1f2937; max-width: 62rem;
		margin: 2rem auto; padding: 0 1.25rem; background: #fff; }
	h1 { font-size: 1.7rem; margin: 0 0 .5rem; }
	h2 { font-size: 1.2rem; margin: 2rem 0 .6rem; border-bottom: 1px solid #d1d5db; padding-bottom: .2rem; }
	p, li { max-width: 46rem; }
	code { font: 13px/1 ui-monospace, Menlo, Consolas, monospace; background: #f3f4f6;
		padding: .05rem .3rem; border-radius: 3px; }
	table { border-collapse: collapse; font-size: 13px; margin: .8rem 0 1.4rem; display: block;
		max-width: 100%; overflow-x: auto; }
	th, td { border: 1px solid #d1d5db; padding: .3rem .5rem; vertical-align: top; text-align: left; }
	th { background: #f3f4f6; }
	td:has(> code:only-child) { white-space: nowrap; }
	strong { color: #111827; }
	a { color: #1d4ed8; }
	@media print { body { margin: 0; max-width: none; font-size: 12px; } h2 { break-after: avoid; } table { break-inside: auto; } tr { break-inside: avoid; } }
`;

export function htmlDeInforme(markdown, titulo) {
	const cuerpo = md.render(markdown);
	return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Migración métrica · ${escapar(titulo)}</title>
<style>${ESTILO}</style>
</head>
<body>
${cuerpo}
</body>
</html>
`;
}

function escapar(texto) {
	return String(texto).replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
}

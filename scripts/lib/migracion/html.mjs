/**
 * El informe escrito de una obra, en HTML, para servirlo dentro del dashboard.
 *
 * No es una página: es el **fragmento** que la ruta `/dashboard/migracion/<obra>` pinta dentro de
 * su marco, con las tablas que el Markdown del proyecto no sabe pintar. Se escribe en
 * `src/lib/content/migracion/` y se carga con `import.meta.glob`, como la guía del dashboard.
 *
 * **Sin HTML de la base.** El informe cita sinopsis y notas escritas por los editores, y aquí se
 * escapan: lo único que puede abrir etiquetas es lo que escribe el generador.
 */

import MarkdownIt from 'markdown-it';

const md = new MarkdownIt({ html: false, linkify: true, typographer: false });

// El informe enumera subtipos y caracterizaciones separándolos con `<br>`, que es la única
// etiqueta que el generador necesita y que un texto de la base no puede colar: con `html: false`
// llega escapada, y se devuelve al salto de línea que era.
function restaurarSaltos(html) {
	return html.replaceAll('&lt;br&gt;', '<br>');
}

/**
 * El fragmento de una obra: el informe sin su encabezado de primer nivel, que lo pone la página.
 */
export function fragmentoDeInforme(markdown) {
	const sinTitulo = markdown.replace(/^#\s+.*\n/, '');
	return restaurarSaltos(md.render(sinTitulo)).trim();
}

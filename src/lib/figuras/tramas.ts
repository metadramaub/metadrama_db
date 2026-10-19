/** Muestras compartidas por la barra y su leyenda, también al rasterizar el SVG. */
export type TramaFigura = {
	fondo: string;
	tinta: string;
	patron: 'liso' | 'diagonal' | 'inversa' | 'puntos' | 'horizontal' | 'vertical' | 'cruz';
};

export const TRAMAS_GRISES: readonly TramaFigura[] = [
	{ fondo: '#202020', tinta: '#ffffff', patron: 'liso' },
	{ fondo: '#ffffff', tinta: '#202020', patron: 'liso' },
	{ fondo: '#777777', tinta: '#ffffff', patron: 'liso' },
	{ fondo: '#cccccc', tinta: '#202020', patron: 'liso' },
	{ fondo: '#ffffff', tinta: '#202020', patron: 'diagonal' },
	{ fondo: '#ffffff', tinta: '#202020', patron: 'inversa' },
	{ fondo: '#ffffff', tinta: '#202020', patron: 'puntos' },
	{ fondo: '#ffffff', tinta: '#202020', patron: 'horizontal' },
	{ fondo: '#ffffff', tinta: '#202020', patron: 'vertical' },
	{ fondo: '#ffffff', tinta: '#202020', patron: 'cruz' },
	{ fondo: '#aaaaaa', tinta: '#202020', patron: 'diagonal' },
	{ fondo: '#aaaaaa', tinta: '#202020', patron: 'puntos' },
	{ fondo: '#444444', tinta: '#ffffff', patron: 'inversa' },
	{ fondo: '#444444', tinta: '#ffffff', patron: 'puntos' },
	{ fondo: '#aaaaaa', tinta: '#202020', patron: 'horizontal' },
	{ fondo: '#aaaaaa', tinta: '#202020', patron: 'cruz' }
];

export function svgDeTrama(id: string, estilo: TramaFigura): string {
	const seguro = (color: string) => /^#[\da-f]{6}$/i.test(color) ? color : '#202020';
	const tinta = seguro(estilo.tinta);
	const trazos: Record<TramaFigura['patron'], string> = {
		liso: '',
		diagonal: '<path d="M-2,2 L2,-2 M0,8 L8,0 M6,10 L10,6"/>',
		inversa: '<path d="M-2,6 L2,10 M0,0 L8,8 M6,-2 L10,2"/>',
		puntos: `<circle cx="4" cy="4" r="1.2" fill="${tinta}" stroke="none"/>`,
		horizontal: '<path d="M0,4 H8"/>',
		vertical: '<path d="M4,0 V8"/>',
		cruz: '<path d="M0,4 H8 M4,0 V8"/>'
	};
	return `<pattern id="${id.replace(/[^\w-]/g, '')}" patternUnits="userSpaceOnUse" width="8" height="8"><rect width="8" height="8" fill="${seguro(estilo.fondo)}"/><g fill="none" stroke="${tinta}" stroke-width="1">${trazos[estilo.patron]}</g></pattern>`;
}

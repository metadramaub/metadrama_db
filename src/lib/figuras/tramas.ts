/** Muestras compartidas por la barra y su leyenda, también al rasterizar el SVG. */
export type TramaFigura = {
	fondo: string;
	tinta: string;
	patron: 'liso' | 'diagonal' | 'inversa' | 'puntos' | 'horizontal' | 'ondas' | 'rombos';
};

export const TRAMAS_GRISES: readonly TramaFigura[] = [
	{ fondo: '#202020', tinta: '#ffffff', patron: 'liso' },
	{ fondo: '#d4d4d4', tinta: '#202020', patron: 'liso' },
	{ fondo: '#777777', tinta: '#ffffff', patron: 'liso' },
	{ fondo: '#aaaaaa', tinta: '#202020', patron: 'liso' },
	{ fondo: '#d0d0d0', tinta: '#202020', patron: 'diagonal' },
	{ fondo: '#999999', tinta: '#ffffff', patron: 'inversa' },
	{ fondo: '#e2e2e2', tinta: '#202020', patron: 'puntos' },
	{ fondo: '#b8b8b8', tinta: '#202020', patron: 'horizontal' },
	{ fondo: '#555555', tinta: '#ffffff', patron: 'ondas' },
	{ fondo: '#c4c4c4', tinta: '#202020', patron: 'rombos' },
	{ fondo: '#555555', tinta: '#ffffff', patron: 'diagonal' },
	{ fondo: '#aaaaaa', tinta: '#202020', patron: 'puntos' },
	{ fondo: '#444444', tinta: '#ffffff', patron: 'inversa' },
	{ fondo: '#444444', tinta: '#ffffff', patron: 'puntos' },
	{ fondo: '#aaaaaa', tinta: '#202020', patron: 'horizontal' },
	{ fondo: '#777777', tinta: '#ffffff', patron: 'rombos' }
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
		ondas: '<path d="M0,4 C2,0 6,8 8,4"/>',
		rombos: '<path d="M4,1 L7,4 L4,7 L1,4 Z"/>'
	};
	return `<pattern id="${id.replace(/[^\w-]/g, '')}" patternUnits="userSpaceOnUse" width="8" height="8"><rect width="8" height="8" fill="${seguro(estilo.fondo)}"/><g fill="none" stroke="${tinta}" stroke-width="1.3">${trazos[estilo.patron]}</g></pattern>`;
}

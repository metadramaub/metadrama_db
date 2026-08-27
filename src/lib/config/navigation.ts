export interface NavItem {
	label: string;
	href: string;
	external?: boolean;
}

export interface NavGroup {
	label: string;
	href?: string;
	items?: NavItem[];
}

export interface FooterSection {
	title: string;
	links: NavItem[];
}

export const PUBLIC_NAV: NavGroup[] = [
	{ label: 'CATÁLOGO', href: '/catalogo' },
	{ label: 'AUTORES', href: '/autores' },
	{ label: 'LABORATORIO', href: '/laboratorio' },
	{ label: 'CÓMO CITARNOS', href: '/como-citarnos' },
	{
		label: 'RECURSOS',
		items: [
			{ label: 'CATÁLOGO MÉTRICO', href: '/recursos/catalogo-metrico' },
			{ label: 'DEMARCADOR', href: '/recursos/demarcador' },
			{ label: 'GUÍA', href: '/recursos/guia' }
		]
	},
	{
		label: 'PROYECTO',
		items: [
			{ label: 'ACERCA DE', href: '/proyecto/about' },
			{ label: 'EQUIPO', href: '/proyecto/equipo' },
			{ label: 'WEB METADRAMA', href: 'https://www.ub.edu/metadrama/', external: true },
			{ label: 'CONTACTO', href: '/proyecto/contacto' }
		]
	}
];

export const LOGIN_LINK: NavItem = { label: 'LOG IN', href: '/login' };

export const FOOTER_SECTIONS: FooterSection[] = [
	{
		title: 'NAVEGACIÓN',
		links: [
			{ label: 'CATÁLOGO', href: '/catalogo' },
			{ label: 'AUTORES', href: '/autores' },
			{ label: 'LABORATORIO', href: '/laboratorio' },
			{ label: 'CATÁLOGO MÉTRICO', href: '/recursos/catalogo-metrico' },
			{ label: 'DEMARCADOR', href: '/recursos/demarcador' },
			{ label: 'GUÍA', href: '/recursos/guia' }
		]
	},
	{
		title: 'PROYECTO',
		links: [
			{ label: 'ACERCA DE', href: '/proyecto/about' },
			{ label: 'EQUIPO', href: '/proyecto/equipo' },
			{ label: 'WEB METADRAMA', href: 'https://www.ub.edu/metadrama/', external: true },
			{ label: 'CONTACTO', href: '/proyecto/contacto' }
		]
	},
	{
		title: 'ACCESO',
		links: [{ label: 'LOG IN', href: '/login' }]
	}
];

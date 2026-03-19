import type { DashboardGuideChapterMeta } from '$lib/types/dashboard-guide.types';

export const DASHBOARD_GUIDE_CHAPTERS = [
	{
		slug: 'bienvenida',
		title: 'Bienvenida y roles',
		summary: 'Contexto del proyecto, roles disponibles y permisos reales por perfil.',
		file: '00-bienvenida.md'
	},
	{
		slug: 'flujo',
		title: 'Flujo de trabajo',
		summary: 'Cómo moverte por el dashboard y trabajar con un orden claro.',
		file: '01-flujo.md'
	},
	{
		slug: 'edicion',
		title: 'Edición de obra',
		summary: 'Trabajo principal del editor: datos, estructura, secuencias y revisión.',
		file: '02-edicion.md'
	},
	{
		slug: 'autores',
		title: 'Consulta de autores',
		summary: 'Uso de autores como módulo de consulta para tomar decisiones de atribución.',
		file: '03-autores.md'
	},
	{
		slug: 'vocabularios',
		title: 'Consulta de vocabularios',
		summary: 'Consulta de términos para mantener consistencia al editar obras.',
		file: '04-vocabularios.md'
	}
] satisfies DashboardGuideChapterMeta[];

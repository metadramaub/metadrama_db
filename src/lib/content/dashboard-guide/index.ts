import type { DashboardGuideChapterMeta } from '$lib/types/dashboard-guide.types';

export const DASHBOARD_GUIDE_CHAPTERS = [
	{
		slug: 'empieza-aqui',
		title: 'Empieza aquí',
		summary: 'Qué es METADRAMA, tu rol y qué puedes o no puedes hacer.',
		file: '00-empieza-aqui.md',
		group: 'intro'
	},
	{
		slug: 'como-moverte',
		title: 'Cómo moverte por el dashboard',
		summary: 'Secciones del dashboard y los flujos de editar y revisar.',
		file: '01-como-moverte.md',
		group: 'intro'
	},
	{
		slug: 'antes-de-empezar',
		title: 'Antes de empezar una obra',
		summary: 'Qué información incorporas, qué es público y orden de trabajo.',
		file: '02-antes-de-empezar.md',
		group: 'intro'
	},
	{
		slug: 'paso-datos',
		title: 'Paso 1 · Datos de la obra',
		summary: 'Identidad y contexto: título, género, datación y edición base.',
		file: '03-paso-datos.md',
		group: 'edicion'
	},
	{
		slug: 'paso-estructura',
		title: 'Paso 2 · Estructura',
		summary: 'Jornadas y cuadros, con sus rangos y reglas de delimitación.',
		file: '04-paso-estructura.md',
		group: 'edicion'
	},
	{
		slug: 'paso-secuencias',
		title: 'Paso 3 · Secuencias',
		summary: 'Análisis métrico: estrofa, caracterización y sinopsis.',
		file: '05-paso-secuencias.md',
		group: 'edicion'
	},
	{
		slug: 'paso-caracterizaciones',
		title: 'Paso 4 · Caracterizaciones por rango',
		summary: 'Fenómenos internos de una secuencia declarados por rango.',
		file: '06-paso-caracterizaciones.md',
		group: 'edicion'
	},
	{
		slug: 'paso-autoria',
		title: 'Paso 5 · Autoría',
		summary: 'Reglas de atribución y creación de autores nuevos.',
		file: '07-paso-autoria.md',
		group: 'edicion'
	},
	{
		slug: 'paso-observaciones',
		title: 'Paso 6 · Observaciones y bibliografía',
		summary: 'Observaciones públicas y bibliografía específica de métrica.',
		file: '08-paso-observaciones.md',
		group: 'edicion'
	},
	{
		slug: 'paso-revision',
		title: 'Paso 7 · Revisión y estados',
		summary: 'Checklist final, comentarios internos y transiciones de estado.',
		file: '09-paso-revision.md',
		group: 'edicion'
	},
	{
		slug: 'ref-markdown',
		title: 'Markdown',
		summary: 'Cómo escribir en Markdown en los campos de texto largo.',
		file: '10-ref-markdown.md',
		group: 'consulta'
	},
	{
		slug: 'ref-tablas',
		title: 'Tablas rápidas',
		summary: 'Estados, público/interno, autoría, caracterizaciones y permisos.',
		file: '11-ref-tablas.md',
		group: 'consulta'
	},
	{
		slug: 'ref-vocabularios',
		title: 'Vocabularios',
		summary: 'Consulta de términos controlados para editar con coherencia.',
		file: '13-ref-vocabularios.md',
		group: 'consulta'
	},
	{
		slug: 'faq',
		title: 'Preguntas frecuentes',
		summary: 'Respuestas rápidas a las dudas más habituales al editar.',
		file: '12-faq.md',
		group: 'faq'
	}
] satisfies DashboardGuideChapterMeta[];

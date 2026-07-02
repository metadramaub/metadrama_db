export type DashboardGuideGroup = 'intro' | 'edicion' | 'consulta' | 'faq';

export interface DashboardGuideChapterMeta {
	slug: string;
	title: string;
	summary: string;
	file: string;
	group: DashboardGuideGroup;
}

export interface DashboardGuideGroupMeta {
	id: DashboardGuideGroup;
	label: string;
}

export const DASHBOARD_GUIDE_GROUPS: DashboardGuideGroupMeta[] = [
	{ id: 'intro', label: 'Primeros pasos' },
	{ id: 'edicion', label: 'Pasos de edición' },
	{ id: 'consulta', label: 'Material de consulta' },
	{ id: 'faq', label: 'Preguntas frecuentes' }
];

export interface DashboardGuideSection {
	id: string;
	title: string;
}

export interface DashboardGuideChapter extends DashboardGuideChapterMeta {
	markdown: string;
	sections: DashboardGuideSection[];
}

export interface DashboardGuideSearchEntry {
	chapterSlug: string;
	chapterTitle: string;
	sectionId: string;
	sectionTitle: string;
	text: string;
}

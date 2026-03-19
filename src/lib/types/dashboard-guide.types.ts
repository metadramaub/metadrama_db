export interface DashboardGuideChapterMeta {
	slug: string;
	title: string;
	summary: string;
	file: string;
}

export interface DashboardGuideSection {
	id: string;
	title: string;
}

export interface DashboardGuideChapter extends DashboardGuideChapterMeta {
	markdown: string;
	sections: DashboardGuideSection[];
}

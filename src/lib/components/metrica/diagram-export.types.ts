export type DiagramLegendItem = {
	label: string;
	color: string;
};

export type DiagramExportMeta = {
	title: string;
	workTitle: string;
	permalink: string;
	filename: string;
	legend?: DiagramLegendItem[];
};

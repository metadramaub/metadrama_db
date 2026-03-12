export type MockFormOrigin = 'espanola' | 'italiana';

export interface MockOption {
	id: string;
	label: string;
}

export interface MockMetricPaletteItem extends MockOption {
	shortLabel: string;
	origin: MockFormOrigin;
	color: string;
}

export interface MockMetricSegment {
	id: string;
	startVerse: number;
	endVerse: number;
	formId: string;
	formLabel: string;
	origin: MockFormOrigin;
	jornada: number;
	cuadro: number;
	variationTags: string[];
}

export interface MockCatalogWork {
	id: string;
	title: string;
	author: string;
	datingLabel: string;
	datingStart: number;
	datingEnd: number;
	genre: string;
	totalVerses: number;
	polymetryRatio: number;
	topMetrics: string[];
	jornadaBreaks: number[];
	cuadroBreaks: number[];
	segments: MockMetricSegment[];
	updatedAtLabel: string;
}

export interface MockFilterState {
	textQuery: string;
	selectedAuthorIds: string[];
	datationMin: number;
	datationMax: number;
	selectedGenreIds: string[];
	selectedFormIds: string[];
	selectedMetroIds: string[];
	formType: 'espanola' | 'italiana' | null;
	withBrokenVerses: 'si' | 'no' | null;
	polymetryRatioMin: number;
	selectedVariationIds: string[];
	withSpaceChange: boolean;
	characterGender: 'mixto' | 'solo_masculino' | 'solo_femenino' | null;
	graciosoPresence: 'ausente' | 'solo' | 'con_otros' | null;
	supernaturalPresence: 'ausente' | 'solo' | 'con_otros' | null;
	versesMin: number;
	versesMax: number;
	selectedJornadas: string[];
	sortBy: string;
}

interface SegmentInput {
	id: string;
	startVerse: number;
	endVerse: number;
	formId: string;
	jornada: number;
	cuadro: number;
	variationTags?: string[];
}

export const MOCK_METRIC_PALETTE: MockMetricPaletteItem[] = [
	{ id: 'redondilla', label: 'Redondilla', shortLabel: 'RDO', origin: 'espanola', color: '#c65f34' },
	{ id: 'romance', label: 'Romance', shortLabel: 'ROM', origin: 'espanola', color: '#da8a42' },
	{ id: 'quintilla', label: 'Quintilla', shortLabel: 'QTA', origin: 'espanola', color: '#b84a2c' },
	{ id: 'seguidilla', label: 'Seguidilla', shortLabel: 'SEG', origin: 'espanola', color: '#e19a5b' },
	{ id: 'decima', label: 'Decima', shortLabel: 'DEC', origin: 'espanola', color: '#a43f25' },
	{ id: 'silva', label: 'Silva', shortLabel: 'SLV', origin: 'italiana', color: '#3a77a9' },
	{ id: 'octava_real', label: 'Octava real', shortLabel: 'OCT', origin: 'italiana', color: '#2d6797' },
	{ id: 'terceto', label: 'Terceto', shortLabel: 'TER', origin: 'italiana', color: '#25537c' },
	{ id: 'soneto', label: 'Soneto', shortLabel: 'SON', origin: 'italiana', color: '#4a8ebd' },
	{
		id: 'endecasilabo_suelto',
		label: 'Endecasilabo suelto',
		shortLabel: 'END',
		origin: 'italiana',
		color: '#5ca2cf'
	}
];

export const MOCK_METRIC_PALETTE_BY_ID = Object.fromEntries(
	MOCK_METRIC_PALETTE.map((item) => [item.id, item])
) as Record<string, MockMetricPaletteItem>;

function makeSegment(input: SegmentInput): MockMetricSegment {
	const palette = MOCK_METRIC_PALETTE_BY_ID[input.formId];
	return {
		id: input.id,
		startVerse: input.startVerse,
		endVerse: input.endVerse,
		formId: input.formId,
		formLabel: palette?.label ?? input.formId,
		origin: palette?.origin ?? 'espanola',
		jornada: input.jornada,
		cuadro: input.cuadro,
		variationTags: input.variationTags ?? []
	};
}

function makeWork(args: {
	id: string;
	title: string;
	author: string;
	datingLabel: string;
	datingStart: number;
	datingEnd: number;
	genre: string;
	totalVerses: number;
	polymetryRatio: number;
	topMetrics: string[];
	jornadaBreaks: number[];
	cuadroBreaks: number[];
	segments: SegmentInput[];
	updatedAtLabel: string;
}): MockCatalogWork {
	return {
		id: args.id,
		title: args.title,
		author: args.author,
		datingLabel: args.datingLabel,
		datingStart: args.datingStart,
		datingEnd: args.datingEnd,
		genre: args.genre,
		totalVerses: args.totalVerses,
		polymetryRatio: args.polymetryRatio,
		topMetrics: args.topMetrics,
		jornadaBreaks: args.jornadaBreaks,
		cuadroBreaks: args.cuadroBreaks,
		segments: args.segments.map((segment) => makeSegment(segment)),
		updatedAtLabel: args.updatedAtLabel
	};
}

function validateWorkSegments(work: MockCatalogWork): void {
	if (work.segments.length === 0) {
		throw new Error(`Mock work ${work.id} has no metric segments.`);
	}

	let cursor = 1;
	for (const segment of work.segments) {
		if (segment.startVerse !== cursor) {
			throw new Error(
				`Mock work ${work.id} has a gap or overlap near ${cursor}-${segment.startVerse}.`
			);
		}
		if (segment.endVerse < segment.startVerse) {
			throw new Error(`Mock work ${work.id} has invalid segment ${segment.id}.`);
		}
		cursor = segment.endVerse + 1;
	}

	if (cursor - 1 !== work.totalVerses) {
		throw new Error(
			`Mock work ${work.id} segments end at ${cursor - 1}, expected ${work.totalVerses}.`
		);
	}
}

export const MOCK_WORKS: MockCatalogWork[] = [
	makeWork({
		id: 'mock-obra-01',
		title: 'Fuenteovejuna',
		author: 'Lope de Vega',
		datingLabel: '1612-1614',
		datingStart: 1612,
		datingEnd: 1614,
		genre: 'Comedia',
		totalVerses: 3080,
		polymetryRatio: 4.8,
		topMetrics: ['Redondilla 27%', 'Romance 24%', 'Silva 16%'],
		jornadaBreaks: [1040, 2080],
		cuadroBreaks: [360, 700, 1040, 1350, 1700, 2080, 2440, 2720],
		updatedAtLabel: 'hace 2 dÃ­as',
		segments: [
			{ id: 'm1-s01', startVerse: 1, endVerse: 180, formId: 'redondilla', jornada: 1, cuadro: 1 },
			{ id: 'm1-s02', startVerse: 181, endVerse: 460, formId: 'romance', jornada: 1, cuadro: 2 },
			{ id: 'm1-s03', startVerse: 461, endVerse: 820, formId: 'silva', jornada: 1, cuadro: 3 },
			{
				id: 'm1-s04',
				startVerse: 821,
				endVerse: 1120,
				formId: 'quintilla',
				jornada: 1,
				cuadro: 3,
				variationTags: ['Versos cantados']
			},
			{ id: 'm1-s05', startVerse: 1121, endVerse: 1380, formId: 'octava_real', jornada: 2, cuadro: 4 },
			{ id: 'm1-s06', startVerse: 1381, endVerse: 1730, formId: 'redondilla', jornada: 2, cuadro: 5 },
			{ id: 'm1-s07', startVerse: 1731, endVerse: 2130, formId: 'romance', jornada: 2, cuadro: 6 },
			{
				id: 'm1-s08',
				startVerse: 2131,
				endVerse: 2460,
				formId: 'terceto',
				jornada: 3,
				cuadro: 7,
				variationTags: ['Rima defectuosa']
			},
			{ id: 'm1-s09', startVerse: 2461, endVerse: 2730, formId: 'silva', jornada: 3, cuadro: 8 },
			{ id: 'm1-s10', startVerse: 2731, endVerse: 3080, formId: 'seguidilla', jornada: 3, cuadro: 9, variationTags: ['Laguna'] }
		]
	}),
	makeWork({
		id: 'mock-obra-02',
		title: 'El perro del hortelano',
		author: 'Lope de Vega',
		datingLabel: '1613-1618',
		datingStart: 1613,
		datingEnd: 1618,
		genre: 'Comedia',
		totalVerses: 2890,
		polymetryRatio: 5.1,
		topMetrics: ['Romance 24%', 'Silva 14%', 'Soneto 1%'],
		jornadaBreaks: [980, 2010],
		cuadroBreaks: [460, 760, 980, 1450, 1740, 2010, 2520, 2710],
		updatedAtLabel: 'hace 9 dÃ­as',
		segments: [
			{ id: 'm2-s01', startVerse: 1, endVerse: 230, formId: 'romance', jornada: 1, cuadro: 1 },
			{ id: 'm2-s02', startVerse: 231, endVerse: 856, formId: 'redondilla', jornada: 1, cuadro: 2 },
			{ id: 'm2-s03', startVerse: 857, endVerse: 870, formId: 'soneto', jornada: 1, cuadro: 3 },
			{ id: 'm2-s04', startVerse: 871, endVerse: 1130, formId: 'silva', jornada: 1, cuadro: 3 },
			{ id: 'm2-s05', startVerse: 1131, endVerse: 1470, formId: 'quintilla', jornada: 2, cuadro: 4 },
			{
				id: 'm2-s06',
				startVerse: 1471,
				endVerse: 1830,
				formId: 'endecasilabo_suelto',
				jornada: 2,
				cuadro: 5,
				variationTags: ['Irregular hipometrico']
			},
			{ id: 'm2-s07', startVerse: 1831, endVerse: 2140, formId: 'romance', jornada: 2, cuadro: 6 },
			{ id: 'm2-s08', startVerse: 2141, endVerse: 2470, formId: 'terceto', jornada: 3, cuadro: 7 },
			{ id: 'm2-s09', startVerse: 2471, endVerse: 2876, formId: 'redondilla', jornada: 3, cuadro: 8 },
			{ id: 'm2-s10', startVerse: 2877, endVerse: 2890, formId: 'soneto', jornada: 3, cuadro: 9, variationTags: ['Rima defectuosa'] }
		]
	}),
	makeWork({
		id: 'mock-obra-03',
		title: 'La dama boba',
		author: 'Lope de Vega',
		datingLabel: '1613-1615',
		datingStart: 1613,
		datingEnd: 1615,
		genre: 'Comedia',
		totalVerses: 3320,
		polymetryRatio: 4.5,
		topMetrics: ['Romance 26%', 'Redondilla 23%', 'Silva 15%'],
		jornadaBreaks: [1100, 2180],
		cuadroBreaks: [560, 820, 1100, 1360, 1640, 2180, 2450, 2710, 3010],
		updatedAtLabel: 'hace 1 mes',
		segments: [
			{ id: 'm3-s01', startVerse: 1, endVerse: 300, formId: 'redondilla', jornada: 1, cuadro: 1 },
			{ id: 'm3-s02', startVerse: 301, endVerse: 680, formId: 'romance', jornada: 1, cuadro: 2 },
			{ id: 'm3-s03', startVerse: 681, endVerse: 970, formId: 'decima', jornada: 1, cuadro: 3 },
			{ id: 'm3-s04', startVerse: 971, endVerse: 1240, formId: 'silva', jornada: 1, cuadro: 3 },
			{ id: 'm3-s05', startVerse: 1241, endVerse: 1580, formId: 'quintilla', jornada: 2, cuadro: 4 },
			{ id: 'm3-s06', startVerse: 1581, endVerse: 1910, formId: 'romance', jornada: 2, cuadro: 5, variationTags: ['Versos cantados'] },
			{ id: 'm3-s07', startVerse: 1911, endVerse: 2250, formId: 'octava_real', jornada: 2, cuadro: 6 },
			{ id: 'm3-s08', startVerse: 2251, endVerse: 2550, formId: 'redondilla', jornada: 3, cuadro: 7 },
			{ id: 'm3-s09', startVerse: 2551, endVerse: 2890, formId: 'terceto', jornada: 3, cuadro: 8 },
			{ id: 'm3-s10', startVerse: 2891, endVerse: 3320, formId: 'endecasilabo_suelto', jornada: 3, cuadro: 9 }
		]
	}),
	makeWork({
		id: 'mock-obra-04',
		title: 'El vergonzoso en palacio',
		author: 'Tirso de Molina',
		datingLabel: '1624',
		datingStart: 1624,
		datingEnd: 1624,
		genre: 'Comedia',
		totalVerses: 2760,
		polymetryRatio: 4.3,
		topMetrics: ['Romance 27%', 'Redondilla 22%', 'Silva 16%'],
		jornadaBreaks: [920, 1850],
		cuadroBreaks: [420, 700, 920, 1240, 1540, 1850, 2210, 2480],
		updatedAtLabel: 'hace 3 meses',
		segments: [
			{ id: 'm4-s01', startVerse: 1, endVerse: 240, formId: 'romance', jornada: 1, cuadro: 1 },
			{ id: 'm4-s02', startVerse: 241, endVerse: 520, formId: 'redondilla', jornada: 1, cuadro: 2 },
			{ id: 'm4-s03', startVerse: 521, endVerse: 860, formId: 'silva', jornada: 1, cuadro: 3 },
			{ id: 'm4-s04', startVerse: 861, endVerse: 1080, formId: 'terceto', jornada: 1, cuadro: 3 },
			{ id: 'm4-s05', startVerse: 1081, endVerse: 1420, formId: 'redondilla', jornada: 2, cuadro: 4 },
			{ id: 'm4-s06', startVerse: 1421, endVerse: 1740, formId: 'octava_real', jornada: 2, cuadro: 5 },
			{ id: 'm4-s07', startVerse: 1741, endVerse: 2010, formId: 'romance', jornada: 2, cuadro: 6 },
			{ id: 'm4-s08', startVerse: 2011, endVerse: 2330, formId: 'quintilla', jornada: 3, cuadro: 7, variationTags: ['Laguna'] },
			{ id: 'm4-s09', startVerse: 2331, endVerse: 2760, formId: 'endecasilabo_suelto', jornada: 3, cuadro: 8 }
		]
	}),
	makeWork({
		id: 'mock-obra-05',
		title: 'Don Gil de las calzas verdes',
		author: 'Tirso de Molina',
		datingLabel: '1614-1616',
		datingStart: 1614,
		datingEnd: 1616,
		genre: 'Comedia',
		totalVerses: 3010,
		polymetryRatio: 5.2,
		topMetrics: ['Romance 25%', 'Redondilla 15%', 'Soneto 1%'],
		jornadaBreaks: [1020, 2050],
		cuadroBreaks: [370, 660, 1020, 1370, 1700, 2050, 2440, 2740],
		updatedAtLabel: 'hace 5 meses',
		segments: [
			{ id: 'm5-s01', startVerse: 1, endVerse: 260, formId: 'redondilla', jornada: 1, cuadro: 1 },
			{ id: 'm5-s02', startVerse: 261, endVerse: 590, formId: 'romance', jornada: 1, cuadro: 2 },
			{ id: 'm5-s03', startVerse: 591, endVerse: 1256, formId: 'quintilla', jornada: 1, cuadro: 3 },
			{ id: 'm5-s04', startVerse: 1257, endVerse: 1270, formId: 'soneto', jornada: 1, cuadro: 3 },
			{ id: 'm5-s05', startVerse: 1271, endVerse: 1610, formId: 'silva', jornada: 2, cuadro: 4 },
			{ id: 'm5-s06', startVerse: 1611, endVerse: 1960, formId: 'romance', jornada: 2, cuadro: 5 },
			{ id: 'm5-s07', startVerse: 1961, endVerse: 2230, formId: 'terceto', jornada: 2, cuadro: 6 },
			{ id: 'm5-s08', startVerse: 2231, endVerse: 2570, formId: 'redondilla', jornada: 3, cuadro: 7, variationTags: ['Prosa'] },
			{ id: 'm5-s09', startVerse: 2571, endVerse: 2810, formId: 'octava_real', jornada: 3, cuadro: 8 },
			{ id: 'm5-s10', startVerse: 2811, endVerse: 3010, formId: 'seguidilla', jornada: 3, cuadro: 9 }
		]
	}),
	makeWork({
		id: 'mock-obra-06',
		title: 'Marta la piadosa',
		author: 'Tirso de Molina',
		datingLabel: '1614-1618',
		datingStart: 1614,
		datingEnd: 1618,
		genre: 'Comedia',
		totalVerses: 2950,
		polymetryRatio: 4.6,
		topMetrics: ['Romance 28%', 'Redondilla 14%', 'Soneto 1%'],
		jornadaBreaks: [980, 1980],
		cuadroBreaks: [310, 620, 980, 1310, 1620, 1980, 2310, 2650],
		updatedAtLabel: 'hace 6 meses',
		segments: [
			{ id: 'm6-s01', startVerse: 1, endVerse: 220, formId: 'romance', jornada: 1, cuadro: 1 },
			{ id: 'm6-s02', startVerse: 221, endVerse: 510, formId: 'redondilla', jornada: 1, cuadro: 2 },
			{ id: 'm6-s03', startVerse: 511, endVerse: 880, formId: 'silva', jornada: 1, cuadro: 3 },
			{ id: 'm6-s04', startVerse: 881, endVerse: 1140, formId: 'quintilla', jornada: 1, cuadro: 3 },
			{ id: 'm6-s05', startVerse: 1141, endVerse: 1846, formId: 'romance', jornada: 2, cuadro: 4 },
			{ id: 'm6-s06', startVerse: 1847, endVerse: 1860, formId: 'soneto', jornada: 2, cuadro: 5 },
			{ id: 'm6-s07', startVerse: 1861, endVerse: 2140, formId: 'terceto', jornada: 2, cuadro: 6, variationTags: ['Rima defectuosa'] },
			{ id: 'm6-s08', startVerse: 2141, endVerse: 2460, formId: 'redondilla', jornada: 3, cuadro: 7 },
			{ id: 'm6-s09', startVerse: 2461, endVerse: 2690, formId: 'octava_real', jornada: 3, cuadro: 8 },
			{ id: 'm6-s10', startVerse: 2691, endVerse: 2950, formId: 'seguidilla', jornada: 3, cuadro: 9, variationTags: ['Versos cantados'] }
		]
	}),
	makeWork({
		id: 'mock-obra-07',
		title: 'La dama duende',
		author: 'Calderón de la Barca',
		datingLabel: '1627-1629',
		datingStart: 1627,
		datingEnd: 1629,
		genre: 'Comedia',
		totalVerses: 3120,
		polymetryRatio: 4.4,
		topMetrics: ['Redondilla 24%', 'Romance 17%', 'Soneto 1%'],
		jornadaBreaks: [1040, 2120],
		cuadroBreaks: [350, 690, 1040, 1360, 1710, 2120, 2460, 2790, 2960],
		updatedAtLabel: 'hace 7 meses',
		segments: [
			{ id: 'm7-s01', startVerse: 1, endVerse: 240, formId: 'redondilla', jornada: 1, cuadro: 1 },
			{ id: 'm7-s02', startVerse: 241, endVerse: 560, formId: 'romance', jornada: 1, cuadro: 2 },
			{ id: 'm7-s03', startVerse: 561, endVerse: 1166, formId: 'silva', jornada: 1, cuadro: 3 },
			{ id: 'm7-s04', startVerse: 1167, endVerse: 1180, formId: 'soneto', jornada: 1, cuadro: 3 },
			{ id: 'm7-s05', startVerse: 1181, endVerse: 1530, formId: 'romance', jornada: 2, cuadro: 4 },
			{ id: 'm7-s06', startVerse: 1531, endVerse: 1890, formId: 'terceto', jornada: 2, cuadro: 5 },
			{ id: 'm7-s07', startVerse: 1891, endVerse: 2260, formId: 'redondilla', jornada: 2, cuadro: 6 },
			{ id: 'm7-s08', startVerse: 2261, endVerse: 2590, formId: 'octava_real', jornada: 3, cuadro: 7 },
			{ id: 'm7-s09', startVerse: 2591, endVerse: 2880, formId: 'endecasilabo_suelto', jornada: 3, cuadro: 8 },
			{ id: 'm7-s10', startVerse: 2881, endVerse: 3120, formId: 'seguidilla', jornada: 3, cuadro: 9 }
		]
	}),
	makeWork({
		id: 'mock-obra-08',
		title: 'Casa con dos puertas mala es de guardar',
		author: 'Calderón de la Barca',
		datingLabel: '1627-1630',
		datingStart: 1627,
		datingEnd: 1630,
		genre: 'Comedia',
		totalVerses: 2840,
		polymetryRatio: 4.9,
		topMetrics: ['Redondilla 24%', 'Romance 23%', 'Soneto 1%'],
		jornadaBreaks: [930, 1910],
		cuadroBreaks: [320, 640, 930, 1260, 1590, 1910, 2240, 2520],
		updatedAtLabel: 'hace 8 meses',
		segments: [
			{ id: 'm8-s01', startVerse: 1, endVerse: 260, formId: 'redondilla', jornada: 1, cuadro: 1 },
			{ id: 'm8-s02', startVerse: 261, endVerse: 600, formId: 'romance', jornada: 1, cuadro: 2 },
			{ id: 'm8-s03', startVerse: 601, endVerse: 980, formId: 'silva', jornada: 1, cuadro: 3 },
			{ id: 'm8-s04', startVerse: 981, endVerse: 1280, formId: 'quintilla', jornada: 2, cuadro: 4 },
			{ id: 'm8-s05', startVerse: 1281, endVerse: 2016, formId: 'romance', jornada: 2, cuadro: 5 },
			{ id: 'm8-s06', startVerse: 2017, endVerse: 2030, formId: 'soneto', jornada: 2, cuadro: 6, variationTags: ['Rima defectuosa'] },
			{ id: 'm8-s07', startVerse: 2031, endVerse: 2360, formId: 'terceto', jornada: 3, cuadro: 7 },
			{ id: 'm8-s08', startVerse: 2361, endVerse: 2600, formId: 'redondilla', jornada: 3, cuadro: 8, variationTags: ['Irregular hipermerico'] },
			{ id: 'm8-s09', startVerse: 2601, endVerse: 2840, formId: 'octava_real', jornada: 3, cuadro: 9 }
		]
	}),
	makeWork({
		id: 'mock-obra-09',
		title: 'La verdad sospechosa',
		author: 'Juan Ruiz de Alarcón',
		datingLabel: '1618-1621',
		datingStart: 1618,
		datingEnd: 1621,
		genre: 'Comedia',
		totalVerses: 3380,
		polymetryRatio: 4.1,
		topMetrics: ['Romance 24%', 'Redondilla 21%', 'Soneto 1%'],
		jornadaBreaks: [1120, 2240],
		cuadroBreaks: [410, 760, 1120, 1450, 1760, 2240, 2580, 2920, 3150],
		updatedAtLabel: 'hace 10 meses',
		segments: [
			{ id: 'm9-s01', startVerse: 1, endVerse: 280, formId: 'romance', jornada: 1, cuadro: 1 },
			{ id: 'm9-s02', startVerse: 281, endVerse: 610, formId: 'redondilla', jornada: 1, cuadro: 2 },
			{ id: 'm9-s03', startVerse: 611, endVerse: 990, formId: 'terceto', jornada: 1, cuadro: 3 },
			{ id: 'm9-s04', startVerse: 991, endVerse: 1290, formId: 'silva', jornada: 1, cuadro: 3 },
			{ id: 'm9-s05', startVerse: 1291, endVerse: 1660, formId: 'romance', jornada: 2, cuadro: 4 },
			{ id: 'm9-s06', startVerse: 1661, endVerse: 2346, formId: 'octava_real', jornada: 2, cuadro: 5 },
			{ id: 'm9-s07', startVerse: 2347, endVerse: 2360, formId: 'soneto', jornada: 2, cuadro: 6 },
			{ id: 'm9-s08', startVerse: 2361, endVerse: 2710, formId: 'redondilla', jornada: 3, cuadro: 7 },
			{ id: 'm9-s09', startVerse: 2711, endVerse: 3040, formId: 'quintilla', jornada: 3, cuadro: 8, variationTags: ['Laguna'] },
			{ id: 'm9-s10', startVerse: 3041, endVerse: 3380, formId: 'endecasilabo_suelto', jornada: 3, cuadro: 9 }
		]
	}),
	makeWork({
		id: 'mock-obra-10',
		title: 'Las paredes oyen',
		author: 'Juan Ruiz de Alarcón',
		datingLabel: '1617-1621',
		datingStart: 1617,
		datingEnd: 1621,
		genre: 'Comedia',
		totalVerses: 2680,
		polymetryRatio: 4.7,
		topMetrics: ['Romance 26%', 'Redondilla 21%', 'Soneto 1%'],
		jornadaBreaks: [890, 1790],
		cuadroBreaks: [300, 600, 890, 1190, 1490, 1790, 2100, 2380, 2520],
		updatedAtLabel: 'hace 11 meses',
		segments: [
			{ id: 'm10-s01', startVerse: 1, endVerse: 220, formId: 'romance', jornada: 1, cuadro: 1 },
			{ id: 'm10-s02', startVerse: 221, endVerse: 540, formId: 'redondilla', jornada: 1, cuadro: 2 },
			{ id: 'm10-s03', startVerse: 541, endVerse: 940, formId: 'silva', jornada: 1, cuadro: 3 },
			{ id: 'm10-s04', startVerse: 941, endVerse: 1260, formId: 'quintilla', jornada: 2, cuadro: 4 },
			{ id: 'm10-s05', startVerse: 1261, endVerse: 1600, formId: 'romance', jornada: 2, cuadro: 5, variationTags: ['Versos cantados'] },
			{ id: 'm10-s06', startVerse: 1601, endVerse: 2206, formId: 'terceto', jornada: 2, cuadro: 6 },
			{ id: 'm10-s07', startVerse: 2207, endVerse: 2220, formId: 'soneto', jornada: 3, cuadro: 7 },
			{ id: 'm10-s08', startVerse: 2221, endVerse: 2460, formId: 'redondilla', jornada: 3, cuadro: 8 },
			{ id: 'm10-s09', startVerse: 2461, endVerse: 2680, formId: 'seguidilla', jornada: 3, cuadro: 9 }
		]
	}),
	makeWork({
		id: 'mock-obra-11',
		title: 'Valor, agravio y mujer',
		author: 'Ana Caro',
		datingLabel: '1633-1637',
		datingStart: 1633,
		datingEnd: 1637,
		genre: 'Comedia',
		totalVerses: 3050,
		polymetryRatio: 4.6,
		topMetrics: ['Romance 24%', 'Redondilla 21%', 'Soneto 1%'],
		jornadaBreaks: [1010, 2030],
		cuadroBreaks: [340, 670, 1010, 1350, 1680, 2030, 2360, 2700, 2870],
		updatedAtLabel: 'hace 1 año',
		segments: [
			{ id: 'm11-s01', startVerse: 1, endVerse: 260, formId: 'redondilla', jornada: 1, cuadro: 1 },
			{ id: 'm11-s02', startVerse: 261, endVerse: 620, formId: 'romance', jornada: 1, cuadro: 2 },
			{ id: 'm11-s03', startVerse: 621, endVerse: 1196, formId: 'decima', jornada: 1, cuadro: 3 },
			{ id: 'm11-s04', startVerse: 1197, endVerse: 1210, formId: 'soneto', jornada: 1, cuadro: 3 },
			{ id: 'm11-s05', startVerse: 1211, endVerse: 1580, formId: 'silva', jornada: 2, cuadro: 4 },
			{ id: 'm11-s06', startVerse: 1581, endVerse: 1940, formId: 'romance', jornada: 2, cuadro: 5 },
			{ id: 'm11-s07', startVerse: 1941, endVerse: 2280, formId: 'terceto', jornada: 2, cuadro: 6, variationTags: ['Irregular hipometrico'] },
			{ id: 'm11-s08', startVerse: 2281, endVerse: 2610, formId: 'redondilla', jornada: 3, cuadro: 7 },
			{ id: 'm11-s09', startVerse: 2611, endVerse: 2860, formId: 'quintilla', jornada: 3, cuadro: 8, variationTags: ['Rima defectuosa'] },
			{ id: 'm11-s10', startVerse: 2861, endVerse: 3050, formId: 'endecasilabo_suelto', jornada: 3, cuadro: 9 }
		]
	}),
	makeWork({
		id: 'mock-obra-12',
		title: 'La traición en la amistad',
		author: 'María de Zayas',
		datingLabel: '1632-1637',
		datingStart: 1632,
		datingEnd: 1637,
		genre: 'Comedia',
		totalVerses: 3220,
		polymetryRatio: 4.9,
		topMetrics: ['Romance 25%', 'Redondilla 20%', 'Soneto 1%'],
		jornadaBreaks: [1080, 2140],
		cuadroBreaks: [360, 700, 1080, 1410, 1760, 2140, 2470, 2810, 3040],
		updatedAtLabel: 'hace 1 aÃ±o',
		segments: [
			{ id: 'm12-s01', startVerse: 1, endVerse: 300, formId: 'romance', jornada: 1, cuadro: 1 },
			{ id: 'm12-s02', startVerse: 301, endVerse: 670, formId: 'redondilla', jornada: 1, cuadro: 2 },
			{ id: 'm12-s03', startVerse: 671, endVerse: 1040, formId: 'quintilla', jornada: 1, cuadro: 3 },
			{ id: 'm12-s04', startVerse: 1041, endVerse: 1686, formId: 'silva', jornada: 1, cuadro: 3 },
			{ id: 'm12-s05', startVerse: 1687, endVerse: 1700, formId: 'soneto', jornada: 2, cuadro: 4 },
			{ id: 'm12-s06', startVerse: 1701, endVerse: 2100, formId: 'romance', jornada: 2, cuadro: 5 },
			{ id: 'm12-s07', startVerse: 2101, endVerse: 2380, formId: 'terceto', jornada: 2, cuadro: 6 },
			{ id: 'm12-s08', startVerse: 2381, endVerse: 2720, formId: 'redondilla', jornada: 3, cuadro: 7, variationTags: ['Prosa'] },
			{ id: 'm12-s09', startVerse: 2721, endVerse: 2970, formId: 'octava_real', jornada: 3, cuadro: 8 },
			{ id: 'm12-s10', startVerse: 2971, endVerse: 3220, formId: 'seguidilla', jornada: 3, cuadro: 9, variationTags: ['Laguna'] }
		]
	})
];

for (const work of MOCK_WORKS) {
	validateWorkSegments(work);
}

export const MOCK_RESULTS_COUNT = 126;

export const MOCK_SORT_OPTIONS: MockOption[] = [
	{ id: 'autor', label: 'Autor' },
	{ id: 'titulo', label: 'Titulo' },
	{ id: 'fecha', label: 'Fecha' },
	{ id: 'total_versos', label: 'N de versos' },
	{ id: 'polimetria', label: 'Polimetria' },
	{ id: 'updated_at', label: 'Ultima actualizacion' }
];

export const MOCK_FILTER_OPTIONS = {
	datationBounds: { min: 1580, max: 1690 },
	versesBounds: { min: 1000, max: 3800 },
	authors: [
		{ id: 'lope', label: 'Lope de Vega' },
		{ id: 'tirso', label: 'Tirso de Molina' },
		{ id: 'calderon', label: 'Calderón de la Barca' },
		{ id: 'alarcon', label: 'Juan Ruiz de Alarcón' },
		{ id: 'ana_caro', label: 'Ana Caro' },
		{ id: 'zayas', label: 'María de Zayas' }
	],
	genres: [
		{ id: 'comedia', label: 'Comedia' },
		{ id: 'tragedia', label: 'Tragedia' }
	],
	forms: MOCK_METRIC_PALETTE.map((item) => ({
		id: item.id,
		label: item.label
	})),
	metros: [
		{ id: 'octosilabo', label: 'Octosilabo' },
		{ id: 'heptasilabo', label: 'Heptasilabo' },
		{ id: 'endecasilabo', label: 'Endecasilabo' },
		{ id: 'alejandrino', label: 'Alejandrino' }
	],
	variations: [
		{ id: 'versos_cantados', label: 'Versos cantados' },
		{ id: 'irregular_hipometrico', label: 'Irregular hipometrico' },
		{ id: 'irregular_hipermerico', label: 'Irregular hipermerico' },
		{ id: 'rima_defectuosa', label: 'Rima defectuosa' },
		{ id: 'laguna', label: 'Laguna' },
		{ id: 'prosa', label: 'Prosa' }
	],
	jornadas: [
		{ id: '1', label: '1' },
		{ id: '2', label: '2' },
		{ id: '3', label: '3' },
		{ id: '4', label: '4' },
		{ id: '5-', label: '5-' }
	]
};

export const MOCK_INITIAL_FILTER_STATE: MockFilterState = {
	textQuery: '',
	selectedAuthorIds: ['lope', 'ana_caro'],
	datationMin: 1600,
	datationMax: 1650,
	selectedGenreIds: [],
	selectedFormIds: ['redondilla', 'silva', 'romance'],
	selectedMetroIds: ['octosilabo', 'endecasilabo'],
	formType: null,
	withBrokenVerses: 'si',
	polymetryRatioMin: 4,
	selectedVariationIds: ['versos_cantados', 'laguna'],
	withSpaceChange: true,
	characterGender: 'mixto',
	graciosoPresence: 'con_otros',
	supernaturalPresence: 'ausente',
	versesMin: 1500,
	versesMax: 3400,
	selectedJornadas: ['3'],
	sortBy: 'fecha'
};

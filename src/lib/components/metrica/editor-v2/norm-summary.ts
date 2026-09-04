import type {
	MetricCatalogDomainData,
	MetricCatalogDomainRow,
	MetricCatalogOption,
	MetricLengthRule
} from '$lib/metrica/catalogo';
import { construirRejilla, type Rejilla } from '$lib/metrica/rejilla';
import type { MetricUnitPlan } from './editor-model';

export type MetricNormFact = {
	label: string;
	value: string;
	/**
	 * En qué estado está esa dimensión para quien anota.
	 *
	 * **Es lo único que necesita saber mientras responde**: de qué no tiene que ocuparse porque la
	 * norma lo fija, qué declara el pasaje que tiene delante, y qué admite la forma sin exigirlo.
	 * Sin el estado, el recuadro enumeraba a la vez lo fijo y lo elegible y el editor tenía que
	 * adivinar cuál era cuál. Se omite en lo fijo, que es la mayoría.
	 */
	estado?: 'fija' | 'pasaje' | 'admite';
};

function id(row: MetricCatalogDomainRow, key: string): string {
	return row[key] ? String(row[key]) : '';
}

function positiveInteger(value: unknown): number | null {
	const parsed = Number(value);
	return Number.isInteger(parsed) && parsed > 0 ? parsed : null;
}

function nonNegativeInteger(value: unknown): number | null {
	if (value === null || value === undefined || value === '') return null;
	const parsed = Number(value);
	return Number.isInteger(parsed) && parsed >= 0 ? parsed : null;
}

function sectionName(sections: MetricCatalogDomainRow[], sectionId: string): string | null {
	const section = sections.find((candidate) => id(candidate, 'seccion_id') === sectionId);
	return section?.nombre ? String(section.nombre) : null;
}

/**
 * Las secciones en orden de árbol: cada madre seguida de sus hijas, y cada nivel por su `orden`.
 *
 * Importa para leer la unidad: en la canción petrarquista la estancia lleva dentro un fronte —y el
 * fronte, dos pies—, un eslabón y una sirima. En orden plano salían mezclados y no se veía qué está
 * dentro de qué.
 */
function sectionsInTreeOrder(sections: MetricCatalogDomainRow[]): MetricCatalogDomainRow[] {
	const ordered: MetricCatalogDomainRow[] = [];
	const byParent = new Map<string, MetricCatalogDomainRow[]>();
	for (const section of sections) {
		const parent = section.seccion_padre_id ? String(section.seccion_padre_id) : '';
		const siblings = byParent.get(parent) ?? [];
		siblings.push(section);
		byParent.set(parent, siblings);
	}
	for (const siblings of byParent.values()) {
		siblings.sort((first, second) => Number(first.orden ?? 0) - Number(second.orden ?? 0));
	}
	const walk = (parent: string) => {
		for (const section of byParent.get(parent) ?? []) {
			ordered.push(section);
			walk(String(section.seccion_id ?? ''));
		}
	};
	walk('');
	// Una hija cuya madre no esté en el lote no se pierde: se añade al final.
	for (const section of sections) {
		if (!ordered.includes(section)) ordered.push(section);
	}
	return ordered;
}

function sectionExtent(section: MetricCatalogDomainRow): string | null {
	const repetitions = positiveInteger(section.repeticiones_min);
	const repetitionsMaximum = positiveInteger(section.repeticiones_max);
	const minimum = positiveInteger(section.versos_min);
	const maximum = positiveInteger(section.versos_max);
	if (minimum === null) return null;
	const times =
		repetitions !== null && repetitions === repetitionsMaximum && repetitions > 1
			? `${repetitions} × `
			: '';
	if (maximum === minimum) {
		return `${times}${minimum} ${minimum === 1 ? 'verso' : 'versos'}`;
	}
	return maximum === null
		? `${times}${minimum} o más versos`
		: `${times}${minimum}–${maximum} versos`;
}

/**
 * **Las partes de la unidad, no la estructura de la secuencia.**
 *
 * Aquí entra todo lo que describe *por dentro* una unidad: las secciones hijas —estén fijadas o
 * no— y las madres que la norma fija enteras. Lo que no entra es lo que se repite a lo largo de la
 * secuencia, que es otra cosa y se cuenta aparte.
 *
 * Antes solo entraban las secciones **completamente fijas**, y las demás caían en
 * `variableSectionFacts`, que las anunciaba como si fueran estructura de la secuencia. En la
 * canción de estancias variables eso daba cinco renglones «Estructura» seguidos —fronte, los dos
 * pies, la sirima y la estancia— y uno de ellos decía «1 Primeros pies; 2–9 versos por primer
 * pie»: plural para una parte que aparece una vez, y a la altura equivocada. La unidad se describe
 * una vez, con sus partes y lo que mide cada una; si el pasaje no encaja, eso es una desviación.
 *
 * Devuelve además si todas las partes están fijadas, porque de eso depende cómo se titula.
 */
function sectionPartsSummary(
	sections: MetricCatalogDomainRow[]
): { value: string; allFixed: boolean } | null {
	const parts: string[] = [];
	let allFixed = true;
	for (const section of sectionsInTreeOrder(sections)) {
		const isChild = Boolean(section.seccion_padre_id);
		const repetitions = nonNegativeInteger(section.repeticiones_min);
		const repetitionsMaximum = nonNegativeInteger(section.repeticiones_max);
		const fixedWhole =
			repetitions !== null &&
			repetitions > 0 &&
			repetitionsMaximum === repetitions &&
			positiveInteger(section.versos_min) !== null &&
			positiveInteger(section.versos_max) === positiveInteger(section.versos_min);
		if (!isChild && !fixedWhole) continue;
		const extent = sectionExtent(section);
		if (!extent) continue;
		if (!fixedWhole) allFixed = false;
		const label = String(section.nombre || section.tipo_seccion || 'Parte');
		// Una parte que puede no estar se dice, porque su ausencia no es una desviación.
		const optional = repetitions === 0 ? ' (opcional)' : '';
		parts.push(`${label}: ${extent}${optional}`);
	}
	if (parts.length === 0) return null;
	return { value: [...new Set(parts)].join(' · '), allFixed };
}

function pluralizeSectionName(value: unknown): string {
	const name = String(value || 'parte').toLocaleLowerCase('es');
	if (/s$/i.test(name)) return name;
	return /[aeiouáéíóú]$/i.test(name) ? `${name}s` : `${name}es`;
}

function verseRange(section: MetricCatalogDomainRow): string | null {
	const minimum = positiveInteger(section.versos_min);
	const maximum = positiveInteger(section.versos_max);
	if (minimum === null) return null;
	if (maximum === null) return `${minimum} o más versos`;
	if (minimum === maximum) return `${minimum} ${minimum === 1 ? 'verso' : 'versos'}`;
	return `${minimum}–${maximum} versos`;
}

/**
 * Partes variables que también forman parte de la norma, aunque no produzcan una serie fija.
 *
 * **Solo las de primer nivel.** Una sección hija describe el interior de la unidad y se cuenta en
 * `sectionPartsSummary`; anunciarla aquí la ponía al mismo nivel que la serie de estancias.
 */
function variableSectionFacts(sections: MetricCatalogDomainRow[]): MetricNormFact[] {
	const facts: MetricNormFact[] = [];
	for (const section of sections.filter((candidate) => !candidate.seccion_padre_id)) {
		const repetitionsMinimum = nonNegativeInteger(section.repeticiones_min);
		const repetitionsMaximum = nonNegativeInteger(section.repeticiones_max);
		const verses = verseRange(section);
		if (repetitionsMinimum === null || !verses) continue;

		const fixed =
			repetitionsMinimum > 0 &&
			repetitionsMaximum === repetitionsMinimum &&
			positiveInteger(section.versos_min) === positiveInteger(section.versos_max);
		if (fixed) continue;

		const name = String(section.nombre || section.tipo_seccion || 'Parte');
		if (repetitionsMinimum === 0 && repetitionsMaximum === 1) {
			facts.push({ label: 'Parte opcional', value: `${name}: ${verses}` });
			continue;
		}
		// Una sección que aparece exactamente una vez no es una serie: es una parte. Decía «1
		// Cabezas; 2–4 versos por cabeza», con el plural de una repetición que no existe.
		if (repetitionsMinimum === 1 && repetitionsMaximum === 1) {
			facts.push({ label: 'Parte', value: `${name}: ${verses}` });
			continue;
		}

		let repetitions = '';
		if (repetitionsMaximum === null) {
			repetitions = `${repetitionsMinimum} o más`;
		} else if (repetitionsMaximum === repetitionsMinimum) {
			repetitions = String(repetitionsMinimum);
		} else {
			repetitions = `${repetitionsMinimum}–${repetitionsMaximum}`;
		}
		const pattern = section.primera_realizacion_define_patron === true
			? '; la primera fija el patrón de las demás'
			: '';
		facts.push({
			label: 'Estructura',
			value: `${repetitions} ${pluralizeSectionName(name)}; ${verses} por ${name.toLocaleLowerCase('es')}${pattern}`
		});
	}
	return facts;
}

function metreSyllables(models: MetricCatalogDomainRow[], metreId: string): string {
	const metre = models.find((candidate) => id(candidate, 'metro_id') === metreId);
	return metre?.silabas ? String(metre.silabas) : String(metre?.nombre ?? '—');
}

function repeatedMeasure(tokens: string[], count: number | null): string {
	if (tokens.length === 1 && count && count > 1) return `${count} × ${tokens[0]}`;
	if (tokens.length <= 16) return tokens.join('·');
	return `${tokens.slice(0, 16).join('·')}·…`;
}

function naturalList(values: string[]): string {
	const unique = [...new Set(values)];
	if (unique.length <= 1) return unique[0] ?? '';
	if (unique.length === 2) return `${unique[0]} y ${unique[1]}`;
	return `${unique.slice(0, -1).join(', ')} y ${unique.at(-1)}`;
}

/**
 * Lo que miden los pies quebrados de una arquitectura, leído de los roles de su esquema métrico.
 *
 * Se dice en el renglón del rasgo, que es donde vive el quiebro desde que se sacó de la medida.
 * Las tres enlazadas no tienen roles —su quiebro está en las posiciones declaradas— y ahí no hay
 * nada que añadir: su renglón dice que es obligatorio, que es lo que hay que saber.
 */
function quebradoMeasures(architectureId: string, domain: MetricCatalogDomainData): string[] {
	const schemes = new Set(
		domain.metricPatterns
			.filter((row) => id(row, 'arquitectura_id') === architectureId)
			.map((row) => id(row, 'esquema_metrico_id'))
	);
	return [
		...new Set(
			domain.metricOptions
				.filter((option) => option.rol === 'quebrado' && schemes.has(id(option, 'esquema_metrico_id')))
				.map((option) => metreSyllables(domain.verseModels, id(option, 'metro_id')))
				.filter(Boolean)
		)
	];
}

/**
 * Algunos esquemas no fijan una secuencia completa, sino una medida dominante y las medidas
 * que pueden quebrarla. Es norma tan exacta como una posición fija y no debe desaparecer del
 * resumen solo porque el editor observa después dónde están las excepciones.
 */
function roleBasedMetreSummary(
	architectureId: string,
	domain: MetricCatalogDomainData,
	/** Se llena con los esquemas ya contados aquí, para que nadie los vuelva a contar. */
	covered?: Set<string>
): string | null {
	const entries: string[] = [];
	for (const pattern of domain.metricPatterns.filter(
		(candidate) => id(candidate, 'arquitectura_id') === architectureId
	)) {
		const options = domain.metricOptions.filter(
			(option) =>
				id(option, 'esquema_metrico_id') === id(pattern, 'esquema_metrico_id')
		);
		const dominant = options
			.filter((option) => option.rol === 'dominante')
			.map((option) => metreSyllables(domain.verseModels, id(option, 'metro_id')));
		const broken = options
			.filter((option) => option.rol === 'quebrado')
			.map((option) => metreSyllables(domain.verseModels, id(option, 'metro_id')));
		if (dominant.length === 0 || broken.length === 0) continue;
		covered?.add(id(pattern, 'esquema_metrico_id'));
		/**
		 * **El quiebro no se dice aquí, sino en su rasgo.**
		 *
		 * Este renglón decía «Base de 8 sílabas; los pies quebrados pueden medir 4 y 5», y ponerlo
		 * bajo «Medida» hacía leer el verso corto como parte de cómo mide la estrofa. En una
		 * redondilla es raro: teóricamente es base de 8 con admitidos de menos, y en la práctica es
		 * de 8 y ya. Lo que la medida fija es la base; que además pueda quebrarse es un rasgo, y
		 * allí se dice con su grado —admitido, habitual, obligatorio— y con sus medidas.
		 */
		entries.push(`Base de ${naturalList(dominant)} sílabas`);
	}
	return entries.length > 0 ? [...new Set(entries)].join(' · ') : null;
}

/**
 * Cómo se dice en la norma lo que `modalidad` mide.
 *
 * **`habitual` faltaba**, y caía al cajón de sastre: el dístico final del endecasílabo suelto se
 * anunciaba «declarado por la arquitectura», que no dice si es obligatorio, corriente o tolerado
 * —o sea, nada—. Le pasaba a cinco arquitecturas.
 *
 * Y el cajón de sastre desaparece: si no hay modalidad, no hay nada que añadir. Rellenar con una
 * frase que no informa es peor que callar.
 */
function traitModality(modality: unknown): string {
	if (modality === 'definitoria') return 'Obligatorio';
	if (modality === 'habitual') return 'Habitual';
	if (modality === 'admitida') return 'Admitido';
	if (modality === 'excluida') return 'No admitido';
	return '';
}

/** Rasgos normativos estructurados: valores, modalidad y límites de posiciones. */
function architectureTraitFacts(
	architectureId: string,
	domain: MetricCatalogDomainData
): MetricNormFact[] {
	return domain.configurationTraits.flatMap((assignment) => {
		if (id(assignment, 'arquitectura_id') !== architectureId) return [];
		const maximum = positiveInteger(assignment.posiciones_max);
		const trait = domain.traits.find(
			(candidate) => id(candidate, 'rasgo_id') === id(assignment, 'rasgo_id')
		);
		if (!trait?.nombre) return [];
		/**
		 * El pie quebrado sube siempre, aunque solo esté admitido y sin límite.
		 *
		 * La regla de abajo vale para los rasgos que el editor observa y responde en su control.
		 * El quiebro no: **cambia la medida de la estrofa**, y desde que seis arquitecturas
		 * declaran dónde cae ni siquiera se pregunta en ellas. Si no subiera, la redondilla no
		 * diría en ninguna parte que admite versos cortos.
		 */
		const esQuiebro = String(trait.slug ?? '') === 'pie_quebrado';
		// Los rasgos meramente admitidos son datos de la realización y ya aparecen en sus
		// controles. Solo suben a la norma cuando acotan la elección con un límite exacto.
		if (assignment.modalidad === 'admitida' && maximum === null && !esQuiebro) return [];
		const value = domain.traitValues.find(
			(candidate) => id(candidate, 'valor_id') === id(assignment, 'valor_id')
		);
		const parts: string[] = [];
		if (value?.nombre) parts.push(String(value.nombre));
		else if (assignment.valor_texto) parts.push(String(assignment.valor_texto));
		else if (assignment.valor_numero !== null && assignment.valor_numero !== undefined) {
			parts.push(String(assignment.valor_numero));
		}
		if (assignment.modalidad === 'admitida' && maximum !== null) {
			parts.push(`admite hasta ${maximum} ${maximum === 1 ? 'posición' : 'posiciones'}`);
		} else {
			const modalidad = traitModality(assignment.modalidad);
			if (modalidad) parts.push(modalidad.toLocaleLowerCase('es'));
			if (maximum !== null) {
				parts.push(`máximo de ${maximum} ${maximum === 1 ? 'posición' : 'posiciones'}`);
			}
		}
		// Y lo que miden, que se leía en la medida y ahora se lee donde se afirma el quiebro.
		if (esQuiebro) {
			const medidas = quebradoMeasures(architectureId, domain);
			if (medidas.length > 0) parts.push(`de ${medidas.join(' o ')} sílabas`);
		}
		// Un renglón sin nada que decir no se pinta.
		if (parts.length === 0) return [];
		// Un rasgo definitorio es norma; los demás son licencias que la forma admite.
		const estado = assignment.modalidad === 'definitoria' ? undefined : ('admite' as const);
		return [{ label: String(trait.nombre), value: parts.join('; '), estado }];
	});
}

/**
 * Una variedad elegible puede reunir un esquema métrico y uno de rima. Si las opciones de un
 * mismo grupo conducen a esquemas distintos, esos esquemas no son norma fija de la arquitectura:
 * pertenecen a la elección y se explican allí.
 */
function variableSchemeIds(domain: MetricCatalogDomainData): {
	metric: Set<string>;
	rhyme: Set<string>;
} {
	const metric = new Set<string>();
	const rhyme = new Set<string>();
	const optionsByGroup = new Map<string, MetricCatalogDomainRow[]>();
	for (const option of domain.choiceOptions) {
		const groupId = id(option, 'grupo_eleccion_id');
		if (!groupId || !option.variedad_id) continue;
		const options = optionsByGroup.get(groupId) ?? [];
		options.push(option);
		optionsByGroup.set(groupId, options);
	}

	for (const options of optionsByGroup.values()) {
		const varieties = options
			.map((option) =>
				domain.patternCombinations.find(
					(candidate) => id(candidate, 'variedad_id') === id(option, 'variedad_id')
				)
			)
			.filter((candidate): candidate is MetricCatalogDomainRow => Boolean(candidate));
		const metricIds = new Set(varieties.map((row) => id(row, 'esquema_metrico_id')));
		const rhymeIds = new Set(varieties.map((row) => id(row, 'esquema_rima_id')));
		if (metricIds.size > 1) {
			for (const schemeId of metricIds) if (schemeId) metric.add(schemeId);
		}
		if (rhymeIds.size > 1) {
			for (const schemeId of rhymeIds) if (schemeId) rhyme.add(schemeId);
		}
	}

	return { metric, rhyme };
}

function metricRepertoire(
	domain: MetricCatalogDomainData,
	patternId: string
): Set<string> {
	const positions = domain.metricPositions.filter(
		(position) => id(position, 'esquema_metrico_id') === patternId
	);
	const rows =
		positions.length > 0
			? positions
			: domain.metricOptions.filter(
					(option) => id(option, 'esquema_metrico_id') === patternId
				);
	return new Set(rows.map((row) => id(row, 'metro_id')).filter(Boolean));
}

function sameSet(left: Set<string>, right: Set<string>): boolean {
	return left.size === right.size && [...left].every((value) => right.has(value));
}

/**
 * Cuando todas las variedades combinan el mismo repertorio de metros, ese repertorio sí es
 * información común de la arquitectura aunque las posiciones cambien. Se muestra la pista, no
 * una secuencia concreta que parecería fija.
 */
function sharedVariableMetreSummary(
	architectureId: string,
	domain: MetricCatalogDomainData,
	variableMetricSchemes: Set<string>
): string | null {
	const schemeIds = domain.metricPatterns
		.filter(
			(pattern) =>
				id(pattern, 'arquitectura_id') === architectureId &&
				variableMetricSchemes.has(id(pattern, 'esquema_metrico_id'))
		)
		.map((pattern) => id(pattern, 'esquema_metrico_id'));
	if (schemeIds.length < 2) return null;

	const repertoires = schemeIds.map((schemeId) => metricRepertoire(domain, schemeId));
	const shared = repertoires[0];
	if (shared.size < 2 || repertoires.some((repertoire) => !sameSet(shared, repertoire))) {
		return null;
	}

	const syllables = [...shared]
		.map((metreId) => metreSyllables(domain.verseModels, metreId))
		.sort((left, right) => Number(left) - Number(right) || left.localeCompare(right, 'es'));
	const list =
		syllables.length === 2
			? `${syllables[0]} y ${syllables[1]}`
			: `${syllables.slice(0, -1).join(', ')} y ${syllables.at(-1)}`;
	return `Combina versos de ${list} sílabas; la distribución depende de la variedad.`;
}

/** Repertorios abiertos: la arquitectura fija las medidas posibles, pero no sus posiciones. */
function openMetreSummary(
	architectureId: string,
	domain: MetricCatalogDomainData,
	sections: MetricCatalogDomainRow[]
): string | null {
	const entries: string[] = [];
	for (const pattern of domain.metricPatterns.filter(
		(candidate) =>
			id(candidate, 'arquitectura_id') === architectureId &&
			String(candidate.tipo_secuencia ?? '') === 'conjunto'
	)) {
		const patternId = id(pattern, 'esquema_metrico_id');
		const repertoire = metricRepertoire(domain, patternId);
		if (repertoire.size < 2) continue;
		const syllables = [...repertoire]
			.map((metreId) => metreSyllables(domain.verseModels, metreId))
			.sort((left, right) => Number(left) - Number(right) || left.localeCompare(right, 'es'));
		const section = sections.find(
			(candidate) =>
				id(candidate, 'seccion_id') === id(pattern, 'seccion_id') ||
				id(candidate, 'esquema_metrico_id') === patternId
		);
		const subject = section?.nombre ? `${String(section.nombre)}: ` : '';
		const inheritance = section?.primera_realizacion_define_patron === true
			? '; la primera fija la distribución de las demás'
			: '';
		entries.push(`${subject}versos de ${naturalList(syllables)} sílabas${inheritance}`);
	}
	return entries.length > 0 ? [...new Set(entries)].join(' · ') : null;
}

function fixedMetreSummary(
	architectureId: string,
	domain: MetricCatalogDomainData,
	sections: MetricCatalogDomainRow[],
	unitPlan: MetricUnitPlan | null,
	variableMetricSchemes: Set<string>
): string | null {
	const entries: string[] = [];
	for (const pattern of domain.metricPatterns.filter(
		(candidate) => id(candidate, 'arquitectura_id') === architectureId
	)) {
		const patternId = id(pattern, 'esquema_metrico_id');
		if (variableMetricSchemes.has(patternId)) continue;
		const positions = domain.metricPositions
			.filter((position) => id(position, 'esquema_metrico_id') === patternId)
			.sort(
				(a, b) =>
					Number(a.alternativa ?? 1) - Number(b.alternativa ?? 1) ||
					Number(a.posicion ?? 0) - Number(b.posicion ?? 0)
			);
		const alternatives = new Set(positions.map((position) => Number(position.alternativa ?? 1)));
		let value: string | null = null;
		if (
			positions.length > 0 &&
			alternatives.size === 1 &&
			positions.every((position) => !position.opcional)
		) {
			value = repeatedMeasure(
				positions.map((position) => metreSyllables(domain.verseModels, id(position, 'metro_id'))),
				null
			);
		} else if (positions.length === 0) {
			const options = domain.metricOptions.filter(
				(option) => id(option, 'esquema_metrico_id') === patternId
			);
			if (options.length === 1) {
				const sectionId = id(pattern, 'seccion_id');
				const section = sections.find((candidate) => id(candidate, 'seccion_id') === sectionId);
				const sectionLength =
					positiveInteger(section?.versos_min) === positiveInteger(section?.versos_max)
						? positiveInteger(section?.versos_min)
						: null;
				const unitLength =
					unitPlan?.extent?.minimum === unitPlan?.extent?.maximum
						? (unitPlan?.extent?.minimum ?? null)
						: null;
				value = repeatedMeasure(
					[metreSyllables(domain.verseModels, id(options[0], 'metro_id'))],
					sectionLength ?? unitLength
				);
			}
		}
		if (!value) continue;
		const subject = sectionName(sections, id(pattern, 'seccion_id'));
		entries.push(subject ? `${subject}: ${value}` : value);
	}
	return entries.length > 0 ? [...new Set(entries)].join(' · ') : null;
}

function fixedRhymeSummary(
	architectureId: string,
	domain: MetricCatalogDomainData,
	sections: MetricCatalogDomainRow[],
	variableRhymeSchemes: Set<string>
): string | null {
	const offered = new Set(
		domain.choiceOptions.map((option) => id(option, 'esquema_rima_id')).filter(Boolean)
	);
	const entries = domain.rhymePatterns.flatMap((scheme) => {
		if (
			id(scheme, 'arquitectura_id') !== architectureId ||
			variableRhymeSchemes.has(id(scheme, 'esquema_rima_id')) ||
			String(scheme.modalidad ?? '') !== 'definitoria' ||
			offered.has(id(scheme, 'esquema_rima_id')) ||
			!scheme.notacion
		) {
			return [];
		}
		const subject = sectionName(sections, id(scheme, 'seccion_id'));
		const notation = String(scheme.notacion);
		return [subject ? `${subject}: ${notation}` : notation];
	});
	return entries.length > 0 ? [...new Set(entries)].join(' · ') : null;
}

function openRhymeSummary(
	architectureId: string,
	domain: MetricCatalogDomainData,
	sections: MetricCatalogDomainRow[],
	variableRhymeSchemes: Set<string>
): string | null {
	const offered = new Set(
		domain.choiceOptions.map((option) => id(option, 'esquema_rima_id')).filter(Boolean)
	);
	const entries = domain.rhymePatterns.flatMap((scheme) => {
		if (
			id(scheme, 'arquitectura_id') !== architectureId ||
			variableRhymeSchemes.has(id(scheme, 'esquema_rima_id')) ||
			String(scheme.modalidad ?? '') !== 'definitoria' ||
			offered.has(id(scheme, 'esquema_rima_id')) ||
			scheme.notacion ||
			String(scheme.tipo_secuencia ?? '') !== 'abierta'
		) {
			return [];
		}
		const subject = sectionName(sections, id(scheme, 'seccion_id'));
		// **Con restricciones declaradas, el nombre basta.** El renglón de restricciones ya dice el
		// criterio en corto —«2 clases de rima · sin versos sueltos · máximo 2 seguidos»—, y repetirlo
		// aquí en prosa metía un párrafo entero del catálogo encima del desplegable que lo resuelve.
		// La prosa larga sigue donde sirve: en la ficha, que está enlazada al pie.
		const hasDetailedRestriction = domain.rhymeRestrictions.some(
			(restriction) => id(restriction, 'esquema_rima_id') === id(scheme, 'esquema_rima_id')
		);
		const description = String(
			(hasDetailedRestriction ? scheme.nombre : scheme.descripcion) || scheme.nombre || ''
		).replace(/[.]$/, '');
		if (!description) return [];
		const fragment = description.charAt(0).toLocaleLowerCase('es') + description.slice(1);
		return [subject ? `${subject}: ${fragment}` : description];
	});
	return entries.length > 0 ? [...new Set(entries)].join(' · ') : null;
}

function rhymeRestrictionValue(restriction: MetricCatalogDomainRow): string | null {
	if (restriction.descripcion) return String(restriction.descripcion).replace(/[.]$/, '');
	const type = String(restriction.tipo ?? '');
	const number = Number(restriction.valor_numero);
	const text = restriction.valor_texto ? String(restriction.valor_texto) : '';
	if (type === 'numero_clases' && Number.isFinite(number)) {
		return `${number} ${number === 1 ? 'clase de rima' : 'clases de rima'}`;
	}
	if (type === 'max_consecutivos' && Number.isFinite(number)) {
		return `máximo de ${number} versos consecutivos con la misma rima`;
	}
	if (type === 'min_alternancias' && Number.isFinite(number)) {
		return `mínimo de ${number} alternancias de rima`;
	}
	if (type === 'prohibe_pareado_final') return 'no admite pareado final';
	if (type === 'regularidad') return 'la disposición debe ser regular';
	if (type === 'versos_sueltos' && text) {
		if (text === 'ninguno') return 'no admite versos sueltos';
		if (text === 'todos') return 'todos los versos son sueltos';
		return `versos sueltos ${text}`;
	}
	return text || null;
}

function rhymeRestrictionSummary(
	architectureId: string,
	domain: MetricCatalogDomainData,
	variableRhymeSchemes: Set<string>
): string | null {
	const offered = new Set(
		domain.choiceOptions.map((option) => id(option, 'esquema_rima_id')).filter(Boolean)
	);
	const normativeSchemeIds = new Set(
		domain.rhymePatterns
			.filter(
				(scheme) =>
					id(scheme, 'arquitectura_id') === architectureId &&
					String(scheme.modalidad ?? '') === 'definitoria' &&
					!variableRhymeSchemes.has(id(scheme, 'esquema_rima_id')) &&
					!offered.has(id(scheme, 'esquema_rima_id'))
			)
			.map((scheme) => id(scheme, 'esquema_rima_id'))
	);
	const values = domain.rhymeRestrictions
		.filter((restriction) => normativeSchemeIds.has(id(restriction, 'esquema_rima_id')))
		.map(rhymeRestrictionValue)
		.filter((value): value is string => Boolean(value));
	return values.length > 0 ? [...new Set(values)].join(' · ') : null;
}

function repetitionSummary(
	architectureId: string,
	domain: MetricCatalogDomainData
): string | null {
	const values = domain.repetitionPatterns
		.filter(
			(pattern) =>
				id(pattern, 'arquitectura_id') === architectureId &&
				String(pattern.modalidad ?? '') === 'definitoria'
		)
		.map((pattern) => String(pattern.descripcion || pattern.nombre || '').replace(/[.]$/, ''))
		.filter(Boolean);
	return values.length > 0 ? [...new Set(values)].join(' · ') : null;
}

/**
 * La arquitectura dibujada verso a verso, con la misma rejilla que la ficha de `/formas` y el
 * demarcador. En el editor sirve para que quien anota vea la estructura que está reconociendo
 * mientras responde, sin salir de la pantalla ni traducir una frase a una figura.
 */
/** Si la arquitectura declara un único régimen de rima para todas sus disposiciones. */
function declaraRegimen(architectureId: string, domain: MetricCatalogDomainData): boolean {
	return (domain.configurations ?? []).some(
		(row: MetricCatalogDomainRow) =>
			id(row, 'arquitectura_id') === architectureId && Boolean(row.tipo_rima_id)
	);
}

/**
 * «consonante», «asonante»: la etiqueta del término.
 *
 * Los regímenes no son una tabla del dominio sino términos del vocabulario, así que llegan aparte,
 * en `MetricCatalogForEditor.rhymeTypes`. Sin ellos no se pinta nada: es preferible callar el
 * régimen a inventarle un nombre.
 */
function nombreDelRegimen(
	tipoRimaId: string,
	rhymeTypes: MetricCatalogOption[]
): string | null {
	if (!tipoRimaId) return null;
	const termino = rhymeTypes.find((row) => String(row.id) === tipoRimaId);
	return termino?.label || termino?.slug || null;
}

export function metricNormGrid(args: {
	architectureId: string;
	domain: MetricCatalogDomainData;
	rhymeTypes?: MetricCatalogOption[];
}): Rejilla | null {
	const { architectureId, domain } = args;
	const rhymeTypes = args.rhymeTypes ?? [];
	const syllables = (metreId: string): string | null => {
		const metre = domain.verseModels.find((row) => id(row, 'metro_id') === metreId);
		return metre?.silabas === null || metre?.silabas === undefined ? null : String(metre.silabas);
	};
	/**
	 * El régimen de cada disposición, **solo cuando la arquitectura no declara uno arriba**.
	 *
	 * Es la misma regla que aplica la ficha pública en `formas-publicas.ts` y la que la función de
	 * opciones aplica a las etiquetas: si lo declara la arquitectura, repetirlo en cada fila es
	 * ruido; si varía, sin él el pareado enseña dos disposiciones llamadas «aa» y no se sabe cuál
	 * es la asonante. `MetricPositionGrid` ya sabe pintarlo; aquí nadie se lo daba.
	 */
	const regimenDe = (pattern: MetricCatalogDomainRow): string | null => {
		if (declaraRegimen(architectureId, domain)) return null;
		return nombreDelRegimen(id(pattern, 'tipo_rima_id'), rhymeTypes);
	};
	const sections = domain.sections.filter(
		(section) => id(section, 'arquitectura_id') === architectureId
	);
	const sectionName = (sectionId: string): string | null =>
		sections.find((section) => id(section, 'seccion_id') === sectionId)?.nombre
			? String(sections.find((section) => id(section, 'seccion_id') === sectionId)?.nombre)
			: null;
	const architecture = domain.configurations.find(
		(row) => id(row, 'arquitectura_id') === architectureId
	);

	return construirRejilla({
		metricos: domain.metricPatterns
			.filter((pattern) => id(pattern, 'arquitectura_id') === architectureId)
			.map((pattern) => ({
				tipoSecuencia: pattern.tipo_secuencia ? String(pattern.tipo_secuencia) : null,
				medidaUniforme:
					pattern.medida_uniforme === null || pattern.medida_uniforme === undefined
						? null
						: pattern.medida_uniforme === true,
				seccion: pattern.seccion_id ? sectionName(id(pattern, 'seccion_id')) : null,
				posiciones: domain.metricPositions
					.filter(
						(position) =>
							id(position, 'esquema_metrico_id') === id(pattern, 'esquema_metrico_id')
					)
					.map((position) => ({
						posicion: Number(position.posicion),
						silabas: syllables(id(position, 'metro_id')),
						alternativa:
							position.alternativa === null || position.alternativa === undefined
								? null
								: Number(position.alternativa),
						opcional: position.opcional === true
					})),
				opciones: domain.metricOptions
					.filter(
						(option) => id(option, 'esquema_metrico_id') === id(pattern, 'esquema_metrico_id')
					)
					.map((option) => ({
						silabas: syllables(id(option, 'metro_id')),
						rol: option.rol ? String(option.rol) : null
					}))
			})),
		rimas: domain.rhymePatterns
			.filter((pattern) => id(pattern, 'arquitectura_id') === architectureId)
			.map((pattern) => ({
				id: id(pattern, 'esquema_rima_id'),
				nombre: pattern.nombre ? String(pattern.nombre) : null,
				notacion: pattern.notacion ? String(pattern.notacion) : null,
				seccion: pattern.seccion_id ? sectionName(id(pattern, 'seccion_id')) : null,
				modalidad: pattern.modalidad ? String(pattern.modalidad) : null,
				tipoRima: regimenDe(pattern),
				posiciones: domain.rhymePositions
					.filter(
						(position) => id(position, 'esquema_rima_id') === id(pattern, 'esquema_rima_id')
					)
					.map((position) => ({
						bloque: Number(position.bloque ?? 1),
						posicion: Number(position.posicion),
						clase: position.clase_rima ? String(position.clase_rima) : null,
						suelto: position.suelto === true,
						seccion: position.seccion ? String(position.seccion) : null
					})),
				enlaces: domain.rhymeLinks
					.filter((link) => id(link, 'esquema_rima_id') === id(pattern, 'esquema_rima_id'))
					.map((link) => ({
						desde: Number(link.posicion_origen),
						hasta: Number(link.posicion_destino),
						desplazamiento: Number(link.desplazamiento_bloque),
						nota: link.nota ? String(link.nota) : null
					}))
			})),
		secciones: sections
			.filter((section) => !section.seccion_padre_id)
			.sort((a, b) => Number(a.orden ?? 0) - Number(b.orden ?? 0))
			.map((section) => ({
				nombre: String(section.nombre),
				versosMin: nonNegativeInteger(section.versos_min),
				versosMax: nonNegativeInteger(section.versos_max),
				repeticionesMin: nonNegativeInteger(section.repeticiones_min),
				repeticionesMax: nonNegativeInteger(section.repeticiones_max),
				reutiliza: null
			})),
		unidadMin: nonNegativeInteger(architecture?.unidad_versos_min),
		unidadMax: nonNegativeInteger(architecture?.unidad_versos_max)
	});
}

/** Cómo se llama en la norma lo que una pregunta resuelve. */
const DIMENSION_EN_LA_NORMA: Record<string, string> = {
	metro: 'Medida',
	rima: 'Rima',
	repeticion: 'Repetición',
	combinacion: 'Variedad'
};

/**
 * Lo que el pasaje declara porque hay una pregunta que lo resuelve.
 *
 * La norma solo describe lo que **ella** fija, así que una dimensión que se elige entre opciones
 * catalogadas no dejaba rastro: la redondilla decía qué mide y en qué rima, y callaba que su
 * disposición se elige, mientras la quintilla sí lo decía por tener además una salida abierta. Dos
 * formas igual de sencillas, dos recuadros distintos, sin ninguna razón que el editor pueda ver.
 *
 * Los rasgos no entran: son licencias y van en su propio renglón.
 */
function dimensionesQueDeclaraElPasaje(
	architectureId: string,
	domain: MetricCatalogDomainData,
	yaDichas: Set<string>
): MetricNormFact[] {
	const vistas = new Set<string>();
	const delArquitectura = domain.choiceGroups.filter(
		(group) =>
			id(group, 'arquitectura_id') === architectureId &&
			group.activo !== false &&
			// Una pregunta que se puede dejar en blanco es una licencia, no una dimensión que el
			// pasaje declare: el quiebro ya tiene su renglón entre lo que la forma admite.
			Number(group.selecciones_min ?? 0) >= 1
	);
	return delArquitectura.flatMap((group) => {
		const label = DIMENSION_EN_LA_NORMA[String(group.dimension ?? '')];
		if (!label || yaDichas.has(label) || vistas.has(label)) return [];
		// Una dimensión puede preguntarse por partes —los cuartetos y los tercetos del soneto—, y
		// lo que se cuenta es todo lo que se ofrece para ella.
		const hermanas = delArquitectura.filter((otra) => otra.dimension === group.dimension);
		const opciones = domain.choiceOptions.filter((option) =>
			hermanas.some((otra) => id(option, 'grupo_eleccion_id') === id(otra, 'grupo_eleccion_id'))
		).length;
		vistas.add(label);
		return [
			{
				label,
				value:
					opciones > 1
						? `${opciones} posibilidades documentadas`
						: 'se declara al anotar el pasaje',
				estado: 'pasaje' as const
			}
		];
	});
}

export function metricNormFacts(args: {
	architectureId: string;
	domain: MetricCatalogDomainData;
	unitPlan: MetricUnitPlan | null;
	lengthRule: MetricLengthRule | null;
	rhymeTypes?: MetricCatalogOption[];
}): MetricNormFact[] {
	const { architectureId, domain, unitPlan, lengthRule } = args;
	const rhymeTypes = args.rhymeTypes ?? [];
	const sections = domain.sections.filter(
		(section) => id(section, 'arquitectura_id') === architectureId
	);
	const facts: MetricNormFact[] = [];
	const variableSchemes = variableSchemeIds(domain);
	if (lengthRule?.explicacion) {
		facts.push({ label: 'Extensión', value: lengthRule.explicacion });
	} else if (unitPlan?.extent) {
		facts.push({
			label: 'Extensión',
			value:
				unitPlan.extent.minimum === unitPlan.extent.maximum
					? `${unitPlan.extent.minimum} ${unitPlan.extent.minimum === 1 ? 'verso' : 'versos'} por unidad`
					: `${unitPlan.extent.minimum}–${unitPlan.extent.maximum} versos por unidad`
		});
	}
	const parts = sectionPartsSummary(sections);
	if (parts) {
		// El título dice la verdad: «fijas» solo cuando la norma las fija todas enteras.
		facts.push({ label: parts.allFixed ? 'Partes fijas' : 'Partes', value: parts.value });
	}
	facts.push(...variableSectionFacts(sections));
	// **Un esquema con quebrados se cuenta una vez.** El de la copla castellana —y el de otras nueve
	// arquitecturas— es uno solo: una posición de ocho sílabas y un repertorio con roles. Leído por
	// roles decía «base de 8; los quebrados pueden medir 4 y 5», y releído por posiciones, «medida
	// fija: 8». Las dos frases son ciertas y juntas se contradicen: lo que la norma fija es la base,
	// no la medida de cada verso.
	const metreCoveredByRole = new Set<string>();
	const roleMetre = roleBasedMetreSummary(architectureId, domain, metreCoveredByRole);
	const openMetre = openMetreSummary(architectureId, domain, sections);
	const metre = fixedMetreSummary(
		architectureId,
		domain,
		sections,
		unitPlan,
		new Set([...variableSchemes.metric, ...metreCoveredByRole])
	);
	if (roleMetre) facts.push({ label: 'Medida', value: roleMetre });
	// Una medida abierta no la fija la forma: la declara el pasaje que se anota.
	if (openMetre) facts.push({ label: 'Medida', value: openMetre, estado: 'pasaje' });
	if (metre) facts.push({ label: 'Medida fija', value: metre });
	const variableMetre = sharedVariableMetreSummary(
		architectureId,
		domain,
		variableSchemes.metric
	);
	if (variableMetre) {
		facts.push({ label: 'Medida', value: variableMetre, estado: 'pasaje' });
	}
	/**
	 * El régimen, dicho una vez, cuando la arquitectura lo declara arriba.
	 *
	 * El pareado alirado rima en consonante y la norma solo decía «Rima fija: aa»: que sea
	 * consonante es la mitad de lo que hay que saber para reconocerlo. Donde el régimen varía no
	 * sube aquí, sino a cada disposición de la rejilla, como en la ficha pública.
	 */
	const regimenDeclarado = declaraRegimen(architectureId, domain)
		? nombreDelRegimen(
				id(
					(domain.configurations ?? []).find(
						(row: MetricCatalogDomainRow) => id(row, 'arquitectura_id') === architectureId
					) ?? {},
					'tipo_rima_id'
				),
				rhymeTypes
			)
		: null;
	if (regimenDeclarado) facts.push({ label: 'Régimen de rima', value: regimenDeclarado });
	const rhyme = fixedRhymeSummary(
		architectureId,
		domain,
		sections,
		variableSchemes.rhyme
	);
	if (rhyme) facts.push({ label: 'Rima fija', value: rhyme });
	const openRhyme = openRhymeSummary(
		architectureId,
		domain,
		sections,
		variableSchemes.rhyme
	);
	if (openRhyme) facts.push({ label: 'Rima', value: openRhyme, estado: 'pasaje' });
	const rhymeRestrictions = rhymeRestrictionSummary(
		architectureId,
		domain,
		variableSchemes.rhyme
	);
	if (rhymeRestrictions) {
		facts.push({ label: 'Restricciones de rima', value: rhymeRestrictions });
	}
	const repetition = repetitionSummary(architectureId, domain);
	if (repetition) facts.push({ label: 'Repetición', value: repetition });
	facts.push(
		...dimensionesQueDeclaraElPasaje(
			architectureId,
			domain,
			new Set(facts.filter((fact) => fact.estado === 'pasaje').map((fact) => fact.label))
		)
	);
	facts.push(...architectureTraitFacts(architectureId, domain));
	return facts;
}

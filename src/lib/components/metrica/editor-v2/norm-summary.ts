import type {
	MetricCatalogDomainData,
	MetricCatalogDomainRow,
	MetricLengthRule
} from '$lib/metrica/catalogo';
import type { MetricUnitPlan } from './editor-model';

export type MetricNormFact = {
	label: string;
	value: string;
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

function fixedSectionSummary(sections: MetricCatalogDomainRow[]): string | null {
	const parts = sections.flatMap((section) => {
		const repetitionsMinimum = positiveInteger(section.repeticiones_min);
		const repetitionsMaximum = positiveInteger(section.repeticiones_max);
		const versesMinimum = positiveInteger(section.versos_min);
		const versesMaximum = positiveInteger(section.versos_max);
		if (
			repetitionsMinimum === null ||
			repetitionsMaximum !== repetitionsMinimum ||
			versesMinimum === null ||
			versesMaximum !== versesMinimum
		) {
			return [];
		}
		const label = String(section.nombre || section.tipo_seccion || 'Parte');
		return [
			`${label}: ${repetitionsMinimum > 1 ? `${repetitionsMinimum} × ` : ''}${versesMinimum} ${
				versesMinimum === 1 ? 'verso' : 'versos'
			}`
		];
	});
	return parts.length > 0 ? [...new Set(parts)].join(' · ') : null;
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

/** Partes variables que también forman parte de la norma, aunque no produzcan una serie fija. */
function variableSectionFacts(sections: MetricCatalogDomainRow[]): MetricNormFact[] {
	const facts: MetricNormFact[] = [];
	for (const section of sections) {
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
 * Algunos esquemas no fijan una secuencia completa, sino una medida dominante y las medidas
 * que pueden quebrarla. Es norma tan exacta como una posición fija y no debe desaparecer del
 * resumen solo porque el editor observa después dónde están las excepciones.
 */
function roleBasedMetreSummary(
	architectureId: string,
	domain: MetricCatalogDomainData
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
		entries.push(
			`Base de ${naturalList(dominant)} sílabas; los pies quebrados pueden medir ${naturalList(broken)}`
		);
	}
	return entries.length > 0 ? [...new Set(entries)].join(' · ') : null;
}

function traitModality(modality: unknown): string {
	if (modality === 'definitoria') return 'Obligatorio';
	if (modality === 'admitida') return 'Admitido';
	if (modality === 'excluida') return 'No admitido';
	return 'Declarado por la arquitectura';
}

/** Rasgos normativos estructurados: valores, modalidad y límites de posiciones. */
function architectureTraitFacts(
	architectureId: string,
	domain: MetricCatalogDomainData
): MetricNormFact[] {
	return domain.configurationTraits.flatMap((assignment) => {
		if (id(assignment, 'arquitectura_id') !== architectureId) return [];
		const maximum = positiveInteger(assignment.posiciones_max);
		// Los rasgos meramente admitidos son datos de la realización y ya aparecen en sus
		// controles. Solo suben a la norma cuando acotan la elección con un límite exacto.
		if (assignment.modalidad === 'admitida' && maximum === null) return [];
		const trait = domain.traits.find(
			(candidate) => id(candidate, 'rasgo_id') === id(assignment, 'rasgo_id')
		);
		if (!trait?.nombre) return [];
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
			parts.push(traitModality(assignment.modalidad).toLocaleLowerCase('es'));
			if (maximum !== null) {
				parts.push(`máximo de ${maximum} ${maximum === 1 ? 'posición' : 'posiciones'}`);
			}
		}
		return [{ label: String(trait.nombre), value: parts.join('; ') }];
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
		const hasDetailedRestriction = domain.rhymeRestrictions.some(
			(restriction) =>
				id(restriction, 'esquema_rima_id') === id(scheme, 'esquema_rima_id') &&
				Boolean(restriction.descripcion)
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

export function metricNormFacts(args: {
	architectureId: string;
	domain: MetricCatalogDomainData;
	unitPlan: MetricUnitPlan | null;
	lengthRule: MetricLengthRule | null;
}): MetricNormFact[] {
	const { architectureId, domain, unitPlan, lengthRule } = args;
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
	const structure = fixedSectionSummary(sections);
	if (structure) facts.push({ label: 'Partes fijas', value: structure });
	facts.push(...variableSectionFacts(sections));
	const roleMetre = roleBasedMetreSummary(architectureId, domain);
	const openMetre = openMetreSummary(architectureId, domain, sections);
	const metre = fixedMetreSummary(
		architectureId,
		domain,
		sections,
		unitPlan,
		variableSchemes.metric
	);
	if (roleMetre) facts.push({ label: 'Medida', value: roleMetre });
	if (openMetre) facts.push({ label: 'Medida', value: openMetre });
	if (metre) facts.push({ label: 'Medida fija', value: metre });
	const variableMetre = sharedVariableMetreSummary(
		architectureId,
		domain,
		variableSchemes.metric
	);
	if (variableMetre) facts.push({ label: 'Medida variable', value: variableMetre });
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
	if (openRhyme) facts.push({ label: 'Rima', value: openRhyme });
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
	facts.push(...architectureTraitFacts(architectureId, domain));
	return facts;
}

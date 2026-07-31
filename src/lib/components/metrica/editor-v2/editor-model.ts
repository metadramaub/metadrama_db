import type { MetricCatalogDomainRow } from '$lib/metrica/catalogo';

export type MetricUnitDraft = {
	realizacion_prueba_id: string;
	realizacion_padre_id: string | null;
	seccion_id: string | null;
	orden: number;
	v_ini: number;
	v_fin: number;
	etiqueta: string;
	observaciones: string;
};

export type MetricChoiceDraft = {
	realizacion_prueba_id: string | null;
	grupo_eleccion_id: string;
	opcion_eleccion_id: string | null;
	valor_texto?: string | null;
	observaciones: string | null;
};

/** Extensión que la arquitectura declara para su unidad. Fija cuando ambos coinciden. */
export type MetricUnitExtent = { minimum: number; maximum: number };

/**
 * Cómo materializa el editor la unidad de una arquitectura.
 *
 * La unidad es siempre la realización que no cuelga de ninguna otra, y no realiza ninguna
 * sección: las secciones describen su interior y se realizan dentro de ella.
 */
export type MetricUnitPlan = {
	/** Extensión declarada por la arquitectura; nula cuando no la declara. */
	extent: MetricUnitExtent | null;
	/** La extensión es fija, así que cuántas unidades hay se deriva del rango. */
	countFromRange: boolean;
};

function numeric(value: unknown, fallback: number): number {
	const parsed = Number(value);
	return Number.isFinite(parsed) ? parsed : fallback;
}

export function sectionId(section: MetricCatalogDomainRow): string {
	return String(section.seccion_id);
}

export function sectionParentId(section: MetricCatalogDomainRow): string | null {
	return section.seccion_padre_id ? String(section.seccion_padre_id) : null;
}

export function sectionLabel(section: MetricCatalogDomainRow): string {
	return String(section.nombre || section.tipo_seccion || 'Sección');
}

export function sectionMinimum(section: MetricCatalogDomainRow): number {
	return Math.max(0, numeric(section.repeticiones_min, 0));
}

export function sectionMaximum(section: MetricCatalogDomainRow): number | null {
	return section.repeticiones_max === null || section.repeticiones_max === undefined
		? null
		: Math.max(0, numeric(section.repeticiones_max, 0));
}

export function sectionVerseMinimum(section: MetricCatalogDomainRow): number {
	return Math.max(1, numeric(section.versos_min, 1));
}

export function sectionVerseMaximum(section: MetricCatalogDomainRow): number | null {
	return section.versos_max === null || section.versos_max === undefined
		? null
		: Math.max(1, numeric(section.versos_max, 1));
}

export function sectionHasFixedLength(section: MetricCatalogDomainRow): boolean {
	const maximum = sectionVerseMaximum(section);
	return maximum !== null && maximum === sectionVerseMinimum(section);
}

/** La extensión declarada por la arquitectura, si la declara. */
export function metricUnitExtent(
	configuration:
		| { unidad_versos_min: number | null; unidad_versos_max: number | null }
		| null
		| undefined
): MetricUnitExtent | null {
	if (!configuration) return null;
	const minimum = configuration.unidad_versos_min;
	const maximum = configuration.unidad_versos_max;
	if (minimum === null || maximum === null) return null;
	const declaredMinimum = Math.max(1, numeric(minimum, 1));
	return { minimum: declaredMinimum, maximum: Math.max(declaredMinimum, numeric(maximum, 1)) };
}

/**
 * Cómo se materializa la unidad de una arquitectura. Es la única detección: cuántas
 * unidades contiene la secuencia se deduce del rango y de la extensión declarada, nunca de
 * una sección que exista para decir que la unidad se repite.
 *
 * Devuelve nulo cuando el editor no materializa unidades: en una serie la secuencia
 * contiene una sola unidad de extensión libre, y una arquitectura que no declara su unidad
 * ni describe sus partes no tiene nada que materializar.
 */
export function metricUnitPlan(
	configuration:
		| { unidad_versos_min: number | null; unidad_versos_max: number | null }
		| null
		| undefined,
	sections: MetricCatalogDomainRow[],
	structuralLevel: string | null | undefined
): MetricUnitPlan | null {
	if (structuralLevel === 'serie' || structuralLevel === 'verso') return null;
	const extent = metricUnitExtent(configuration);
	if (!extent && sections.length === 0) return null;
	return { extent, countFromRange: extent !== null && extent.minimum === extent.maximum };
}

function isMetricUnit(unit: MetricUnitDraft): boolean {
	return unit.realizacion_padre_id === null && unit.seccion_id === null;
}

/**
 * Las partes de una sección. Las partes de la unidad —cuya realización no realiza ninguna
 * sección— son las secciones raíz de la arquitectura.
 */
export function childrenOfSection(
	sections: MetricCatalogDomainRow[],
	parentSectionId: string | null
): MetricCatalogDomainRow[] {
	if (parentSectionId === null) return rootSections(sections);
	return sections
		.filter((section) => sectionParentId(section) === parentSectionId)
		.sort(
			(a, b) =>
				numeric(a.orden, 999) - numeric(b.orden, 999) ||
				sectionLabel(a).localeCompare(sectionLabel(b), 'es')
		);
}

export function rootSections(sections: MetricCatalogDomainRow[]): MetricCatalogDomainRow[] {
	return sections
		.filter((section) => !sectionParentId(section))
		.sort(
			(a, b) =>
				numeric(a.orden, 999) - numeric(b.orden, 999) ||
				sectionLabel(a).localeCompare(sectionLabel(b), 'es')
		);
}

function defaultUnit(
	section: MetricCatalogDomainRow | null,
	parentUnitId: string | null,
	start: number,
	fallbackLength: number
): MetricUnitDraft {
	const length = section ? sectionVerseMinimum(section) : fallbackLength;
	return {
		realizacion_prueba_id: crypto.randomUUID(),
		realizacion_padre_id: parentUnitId,
		seccion_id: section ? sectionId(section) : null,
		orden: 1,
		v_ini: start,
		v_fin: start + length - 1,
		etiqueta: '',
		observaciones: ''
	};
}

function appendRequiredDescendants(
	units: MetricUnitDraft[],
	parentUnit: MetricUnitDraft,
	sections: MetricCatalogDomainRow[],
	start: number
): MetricUnitDraft[] {
	let next = units;
	for (const childSection of childrenOfSection(sections, parentUnit.seccion_id)) {
		for (let index = 0; index < sectionMinimum(childSection); index += 1) {
			const child = defaultUnit(childSection, parentUnit.realizacion_prueba_id, start, 1);
			next = [...next, child];
			next = appendRequiredDescendants(next, child, sections, start);
		}
	}
	return next;
}

function appendUnit(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	section: MetricCatalogDomainRow | null,
	parentUnitId: string | null,
	sequenceStart: number,
	fallbackLength: number,
	choices: MetricChoiceDraft[],
	options: MetricCatalogDomainRow[]
): MetricUnitDraft[] {
	const unit = defaultUnit(section, parentUnitId, sequenceStart, fallbackLength);
	unit.orden =
		units.reduce((maximum, existingUnit) => Math.max(maximum, existingUnit.orden), 0) + 1;
	const withRequiredChildren = appendRequiredDescendants(
		[...units, unit],
		unit,
		sections,
		sequenceStart
	);
	return reflowMetricUnits(withRequiredChildren, sections, sequenceStart, choices, options);
}

export function addSectionInstance(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	targetSectionId: string,
	parentUnitId: string | null,
	sequenceStart: number,
	choices: MetricChoiceDraft[] = [],
	options: MetricCatalogDomainRow[] = []
): MetricUnitDraft[] {
	const section = sections.find((row) => sectionId(row) === targetSectionId);
	if (!section) return units;
	return appendUnit(units, sections, section, parentUnitId, sequenceStart, 1, choices, options);
}

/**
 * Añade una realización de la unidad que define la forma, con las secciones que su
 * interior exige.
 */
export function addMetricUnit(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	extent: MetricUnitExtent | null,
	sequenceStart: number,
	choices: MetricChoiceDraft[] = [],
	options: MetricCatalogDomainRow[] = []
): MetricUnitDraft[] {
	return appendUnit(
		units,
		sections,
		null,
		null,
		sequenceStart,
		extent?.minimum ?? 1,
		choices,
		options
	);
}

/**
 * Reparte el rango en unidades completas. Solo se aplica cuando la unidad es fija: con
 * una unidad de extensión variable el rango no dice cuántas hay y las decide el editor.
 */
export function syncRepeatedMetricUnits(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	extent: MetricUnitExtent | null,
	sequenceStart: number,
	sequenceEnd: number,
	choices: MetricChoiceDraft[] = [],
	options: MetricCatalogDomainRow[] = []
): { units: MetricUnitDraft[]; removedUnitIds: string[]; compatible: boolean } {
	if (!extent || extent.minimum !== extent.maximum) {
		return { units, removedUnitIds: [], compatible: false };
	}

	const unitExtent = extent.minimum;
	const sequenceLength = Math.max(0, sequenceEnd - sequenceStart + 1);
	if (sequenceLength < unitExtent || sequenceLength % unitExtent !== 0) {
		return { units, removedUnitIds: [], compatible: false };
	}

	const desiredCount = sequenceLength / unitExtent;
	const existingUnits = units
		.filter(isMetricUnit)
		.sort(
			(a, b) =>
				a.orden - b.orden ||
				a.v_ini - b.v_ini ||
				a.realizacion_prueba_id.localeCompare(b.realizacion_prueba_id)
		);

	let next = [...units];
	const removedUnitIds = existingUnits
		.slice(desiredCount)
		.flatMap((unit) => [...unitIdsInTree(next, unit.realizacion_prueba_id)]);
	if (removedUnitIds.length > 0) {
		const removed = new Set(removedUnitIds);
		next = next.filter((unit) => !removed.has(unit.realizacion_prueba_id));
	}

	for (let index = existingUnits.length; index < desiredCount; index += 1) {
		next = addMetricUnit(next, sections, extent, sequenceStart, choices, options);
	}

	return {
		units: reflowMetricUnits(next, sections, sequenceStart, choices, options),
		removedUnitIds,
		compatible: true
	};
}

/**
 * Garantiza que exista al menos una realización de la unidad cuando su extensión es
 * variable y el rango, por tanto, no basta para deducir cuántas hay.
 */
export function ensureRequiredMetricUnits(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	extent: MetricUnitExtent | null,
	sequenceStart: number,
	choices: MetricChoiceDraft[] = [],
	options: MetricCatalogDomainRow[] = []
): MetricUnitDraft[] {
	let next = [...units];
	if (!next.some(isMetricUnit)) {
		next = addMetricUnit(next, sections, extent, sequenceStart, choices, options);
	}

	// Cada unidad ya materializada debe contener las secciones que su interior exige.
	for (const parent of [...next]) {
		for (const childSection of childrenOfSection(sections, parent.seccion_id)) {
			const existing = next.filter(
				(unit) =>
					unit.realizacion_padre_id === parent.realizacion_prueba_id &&
					unit.seccion_id === sectionId(childSection)
			).length;
			for (let index = existing; index < sectionMinimum(childSection); index += 1) {
				next = addSectionInstance(
					next,
					sections,
					sectionId(childSection),
					parent.realizacion_prueba_id,
					sequenceStart,
					choices,
					options
				);
			}
		}
	}

	return reflowMetricUnits(next, sections, sequenceStart, choices, options);
}

export function removeMetricUnitTree(
	units: MetricUnitDraft[],
	unitId: string,
	sections: MetricCatalogDomainRow[],
	sequenceStart: number,
	choices: MetricChoiceDraft[] = [],
	options: MetricCatalogDomainRow[] = []
): MetricUnitDraft[] {
	const removed = new Set<string>([unitId]);
	let changed = true;
	while (changed) {
		changed = false;
		for (const unit of units) {
			if (
				unit.realizacion_padre_id &&
				removed.has(unit.realizacion_padre_id) &&
				!removed.has(unit.realizacion_prueba_id)
			) {
				removed.add(unit.realizacion_prueba_id);
				changed = true;
			}
		}
	}
	return reflowMetricUnits(
		units.filter((unit) => !removed.has(unit.realizacion_prueba_id)),
		sections,
		sequenceStart,
		choices,
		options
	);
}

function unitLength(unit: MetricUnitDraft): number {
	return Math.max(1, unit.v_fin - unit.v_ini + 1);
}

function lengthForUnit(
	unit: MetricUnitDraft,
	section: MetricCatalogDomainRow,
	units: MetricUnitDraft[],
	choices: MetricChoiceDraft[],
	options: MetricCatalogDomainRow[]
): number {
	const fixed = sectionHasFixedLength(section) ? sectionVerseMinimum(section) : unitLength(unit);

	const effectOption = options.find(
		(option) =>
			String(option.materializa_seccion_id ?? '') === unit.seccion_id &&
			Boolean(option.extension_desde_seccion_id) &&
			choices.some(
				(choice) =>
					choice.opcion_eleccion_id === String(option.opcion_eleccion_id) &&
					choice.realizacion_prueba_id === unit.realizacion_padre_id
			)
	);
	const referenceId = effectOption?.extension_desde_seccion_id
		? String(effectOption.extension_desde_seccion_id)
		: null;
	const referenceUnit = referenceId
		? units.find((candidate) => candidate.seccion_id === referenceId)
		: null;
	const proposed = referenceUnit ? unitLength(referenceUnit) : fixed;
	const minimum = sectionVerseMinimum(section);
	const maximum = sectionVerseMaximum(section);
	return Math.max(minimum, maximum === null ? proposed : Math.min(proposed, maximum));
}

export function reflowMetricUnits(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	sequenceStart: number,
	choices: MetricChoiceDraft[] = [],
	options: MetricCatalogDomainRow[] = []
): MetricUnitDraft[] {
	const sectionById = new Map(sections.map((section) => [sectionId(section), section]));
	const sectionOf = (unit: MetricUnitDraft) =>
		unit.seccion_id ? sectionById.get(unit.seccion_id) : undefined;
	const originalOrder = new Map(
		units.map((unit, index) => [unit.realizacion_prueba_id, unit.orden || index + 1])
	);
	const updated = new Map(units.map((unit) => [unit.realizacion_prueba_id, { ...unit }]));
	const visited = new Set<string>();
	let nextOrder = 1;

	const sortInstances = (items: MetricUnitDraft[]) =>
		[...items].sort(
			(a, b) =>
				numeric(sectionOf(a)?.orden, 999) - numeric(sectionOf(b)?.orden, 999) ||
				numeric(originalOrder.get(a.realizacion_prueba_id), 999) -
					numeric(originalOrder.get(b.realizacion_prueba_id), 999)
		);

	const flowUnit = (unitId: string, start: number): number => {
		const unit = updated.get(unitId);
		if (!unit) return start;
		const section = sectionOf(unit);
		const children = sortInstances(
			[...updated.values()].filter(
				(candidate) => candidate.realizacion_padre_id === unit.realizacion_prueba_id
			)
		);
		visited.add(unit.realizacion_prueba_id);
		unit.orden = nextOrder;
		nextOrder += 1;

		if (children.length > 0) {
			let cursor = start;
			for (const child of children) cursor = flowUnit(child.realizacion_prueba_id, cursor);
			unit.v_ini = start;
			unit.v_fin = Math.max(start, cursor - 1);
			return unit.v_fin + 1;
		}

		const length = section
			? lengthForUnit(unit, section, [...updated.values()], choices, options)
			: unitLength(unit);
		unit.v_ini = start;
		unit.v_fin = start + length - 1;
		return unit.v_fin + 1;
	};

	let cursor = Math.max(1, sequenceStart);
	const roots = sortInstances(
		[...updated.values()].filter((unit) => unit.realizacion_padre_id === null)
	);
	for (const root of roots) cursor = flowUnit(root.realizacion_prueba_id, cursor);

	for (const orphan of sortInstances(
		[...updated.values()].filter((unit) => !visited.has(unit.realizacion_prueba_id))
	)) {
		orphan.realizacion_padre_id = null;
		cursor = flowUnit(orphan.realizacion_prueba_id, cursor);
	}

	return [...updated.values()].sort((a, b) => a.orden - b.orden);
}

export function syncChoiceMaterializedSections(
	units: MetricUnitDraft[],
	sections: MetricCatalogDomainRow[],
	parentUnitId: string | null,
	groupOptions: MetricCatalogDomainRow[],
	selectedOptionIds: string[],
	sequenceStart: number,
	choices: MetricChoiceDraft[],
	allOptions: MetricCatalogDomainRow[]
): MetricUnitDraft[] {
	const managedSectionIds = new Set(
		groupOptions
			.map((option) => (option.materializa_seccion_id ? String(option.materializa_seccion_id) : ''))
			.filter(Boolean)
	);
	const desiredSectionIds = new Set(
		groupOptions
			.filter((option) => selectedOptionIds.includes(String(option.opcion_eleccion_id)))
			.map((option) => (option.materializa_seccion_id ? String(option.materializa_seccion_id) : ''))
			.filter(Boolean)
	);

	let next = units.filter(
		(unit) =>
			!(
				unit.realizacion_padre_id === parentUnitId &&
				unit.seccion_id !== null &&
				managedSectionIds.has(unit.seccion_id) &&
				!desiredSectionIds.has(unit.seccion_id)
			)
	);

	for (const targetSectionId of desiredSectionIds) {
		if (
			!next.some(
				(unit) =>
					unit.realizacion_padre_id === parentUnitId && unit.seccion_id === targetSectionId
			)
		) {
			next = addSectionInstance(
				next,
				sections,
				targetSectionId,
				parentUnitId,
				sequenceStart,
				choices,
				allOptions
			);
		}
	}

	return reflowMetricUnits(next, sections, sequenceStart, choices, allOptions);
}

export function unitIdsInTree(units: MetricUnitDraft[], rootUnitId: string): Set<string> {
	const ids = new Set<string>([rootUnitId]);
	let changed = true;
	while (changed) {
		changed = false;
		for (const unit of units) {
			if (
				unit.realizacion_padre_id &&
				ids.has(unit.realizacion_padre_id) &&
				!ids.has(unit.realizacion_prueba_id)
			) {
				ids.add(unit.realizacion_prueba_id);
				changed = true;
			}
		}
	}
	return ids;
}

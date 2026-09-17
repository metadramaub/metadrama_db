import type { CorpusComparisonWork } from '$lib/types/public-artifacts.types';
import { summarizeLaboratoryValues } from './metricas';

export type LaboratoryFeatureWork = {
	id: string;
	slug: string;
	title: string;
	value: number | null;
};

export type LaboratoryFeatureGroupReading = {
	totalWorks: number;
	presentWorks: number;
	valueWorks: number;
	diffusion: number | null;
	typical: number | null;
	works: LaboratoryFeatureWork[];
};

export type LaboratoryFeatureComparisonRow = {
	id: string;
	label: string;
	from?: string;
	to?: string;
	tipoForma: string | null;
	groupA: LaboratoryFeatureGroupReading;
	groupB: LaboratoryFeatureGroupReading;
};

type FeatureAccumulator = {
	label: string;
	from?: string;
	to?: string;
	tipoForma: string | null;
	presentWorks: number;
	values: number[];
	works: LaboratoryFeatureWork[];
};

function emptyReading(totalWorks: number): LaboratoryFeatureGroupReading {
	return {
		totalWorks,
		presentWorks: 0,
		valueWorks: 0,
		diffusion: totalWorks > 0 ? 0 : null,
		typical: null,
		works: []
	};
}

function toReading(
	entry: FeatureAccumulator | undefined,
	totalWorks: number
): LaboratoryFeatureGroupReading {
	if (!entry) return emptyReading(totalWorks);
	return {
		totalWorks,
		presentWorks: entry.presentWorks,
		valueWorks: entry.values.length,
		diffusion: totalWorks > 0 ? entry.presentWorks / totalWorks : null,
		typical: summarizeLaboratoryValues(entry.values).median,
		works: [...entry.works].sort((a, b) => a.title.localeCompare(b.title, 'es'))
	};
}

function humanize(value: string): string {
	const normalized = value.replaceAll('_', ' ').replaceAll('-', ' ');
	return normalized.charAt(0).toLocaleUpperCase('es') + normalized.slice(1);
}

function buildFormMap(works: CorpusComparisonWork[]): Map<string, FeatureAccumulator> {
	const result = new Map<string, FeatureAccumulator>();
	for (const work of works) {
		for (const [id, profile] of Object.entries(work.perfil_formas)) {
			if (id === 'sin-forma-anotada' || profile.versos <= 0) continue;
			const entry = result.get(id) ?? {
				label: humanize(id),
				tipoForma: profile.tipo_forma,
				presentWorks: 0,
				values: [],
				works: []
			};
			entry.tipoForma ??= profile.tipo_forma;
			entry.presentWorks += 1;
			entry.works.push({
				id: work.obra_id,
				slug: work.slug,
				title: work.titulo,
				value: profile.proporcion_versos
			});
			if (profile.proporcion_versos !== null) {
				entry.values.push(profile.proporcion_versos);
			}
			result.set(id, entry);
		}
	}
	return result;
}

function buildTransitionMap(works: CorpusComparisonWork[]): Map<string, FeatureAccumulator> {
	const result = new Map<string, FeatureAccumulator>();
	for (const work of works) {
		const workTransitions = new Map<string, { from: string; to: string; occurrences: number }>();
		for (const transition of work.transiciones) {
			if (transition.veces <= 0) continue;
			const id = `${transition.de}→${transition.a}`;
			const current = workTransitions.get(id) ?? {
				from: transition.de,
				to: transition.a,
				occurrences: 0
			};
			current.occurrences += transition.veces;
			workTransitions.set(id, current);
		}

		for (const [id, transition] of workTransitions) {
			const entry = result.get(id) ?? {
				label: `${humanize(transition.from)} → ${humanize(transition.to)}`,
				from: transition.from,
				to: transition.to,
				tipoForma: null,
				presentWorks: 0,
				values: [],
				works: []
			};
			entry.presentWorks += 1;
			entry.values.push(transition.occurrences);
			entry.works.push({
				id: work.obra_id,
				slug: work.slug,
				title: work.titulo,
				value: transition.occurrences
			});
			result.set(id, entry);
		}
	}
	return result;
}

function combineMaps(
	groupA: Map<string, FeatureAccumulator>,
	groupB: Map<string, FeatureAccumulator>,
	totalA: number,
	totalB: number
): LaboratoryFeatureComparisonRow[] {
	const ids = new Set([...groupA.keys(), ...groupB.keys()]);
	return [...ids]
		.map((id) => {
			const entryA = groupA.get(id);
			const entryB = groupB.get(id);
			const identity = entryA ?? entryB;
			if (!identity) throw new Error(`Rasgo comparativo sin identidad: ${id}`);
			return {
				id,
				label: identity.label,
				from: identity.from,
				to: identity.to,
				tipoForma: entryA?.tipoForma ?? entryB?.tipoForma ?? null,
				groupA: toReading(entryA, totalA),
				groupB: toReading(entryB, totalB)
			};
		})
		.sort((a, b) => a.label.localeCompare(b.label, 'es'));
}

export function buildFormGroupComparisons(
	groupA: CorpusComparisonWork[],
	groupB: CorpusComparisonWork[]
): LaboratoryFeatureComparisonRow[] {
	return combineMaps(buildFormMap(groupA), buildFormMap(groupB), groupA.length, groupB.length);
}

export function buildTransitionGroupComparisons(
	groupA: CorpusComparisonWork[],
	groupB: CorpusComparisonWork[]
): LaboratoryFeatureComparisonRow[] {
	return combineMaps(
		buildTransitionMap(groupA),
		buildTransitionMap(groupB),
		groupA.length,
		groupB.length
	);
}

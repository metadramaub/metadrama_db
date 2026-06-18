export type SubtipoRangeInput = {
	v_ini: number;
	v_fin: number;
};

export type SuggestedSubtipoRange =
	| {
			available: true;
			v_ini: number;
			v_fin: number;
	  }
	| {
			available: false;
			v_ini: number;
			v_fin: number;
	  };

const DEFAULT_SUBTIPO_LENGTH = 5;

function finitePositiveOrFallback(value: number, fallback: number): number {
	return Number.isFinite(value) && value > 0 ? value : fallback;
}

export function suggestNextSubtipoRange(
	sequence: SubtipoRangeInput,
	subtipos: SubtipoRangeInput[]
): SuggestedSubtipoRange {
	const sequenceStart = finitePositiveOrFallback(Number(sequence.v_ini), 1);
	const sequenceEnd = finitePositiveOrFallback(Number(sequence.v_fin), sequenceStart);
	const maxExistingEnd = subtipos.reduce((max, subtipo) => {
		const subtipoEnd = Number(subtipo.v_fin);
		return Number.isFinite(subtipoEnd) ? Math.max(max, subtipoEnd) : max;
	}, sequenceStart - 1);
	const nextStart = Math.max(sequenceStart, maxExistingEnd + 1);

	if (nextStart > sequenceEnd) {
		return {
			available: false,
			v_ini: nextStart,
			v_fin: sequenceEnd
		};
	}

	return {
		available: true,
		v_ini: nextStart,
		v_fin: Math.min(nextStart + DEFAULT_SUBTIPO_LENGTH - 1, sequenceEnd)
	};
}

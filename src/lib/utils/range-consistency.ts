export type RangeConsistencyScope = 'jornadas' | 'cuadros' | 'secuencias';

export type RangeConsistencyIssue = {
	kind: 'overlap' | 'out_of_bounds';
	scope: RangeConsistencyScope;
	leftId: string;
	rightId: string;
	message: string;
};

type RangeLike = {
	id: string;
	label: string;
	v_ini: number;
	v_fin: number;
};

type JornadaLike = {
	jornada_id: string;
	jornada_num: number;
	v_ini: number;
	v_fin: number;
};

type CuadroLike = {
	cuadro_id: string;
	cuadro_num: number;
	jornada_id: string;
	v_ini: number;
	v_fin: number;
};

type SecuenciaLike = {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
};

function findRangeOverlaps(
	items: RangeLike[],
	scope: RangeConsistencyScope,
	contextLabel = ''
): RangeConsistencyIssue[] {
	const sorted = [...items].sort(
		(a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin || a.id.localeCompare(b.id)
	);
	const issues: RangeConsistencyIssue[] = [];

	for (let leftIndex = 0; leftIndex < sorted.length; leftIndex += 1) {
		const left = sorted[leftIndex];
		for (let rightIndex = leftIndex + 1; rightIndex < sorted.length; rightIndex += 1) {
			const right = sorted[rightIndex];
			if (right.v_ini > left.v_fin) break;
			issues.push({
				kind: 'overlap',
				scope,
				leftId: left.id,
				rightId: right.id,
				message: `${left.label} (vv. ${left.v_ini}-${left.v_fin}) y ${right.label} (vv. ${right.v_ini}-${right.v_fin}) se solapan${contextLabel}.`
			});
		}
	}

	return issues;
}

export function analyzeStructureRangeConsistency(
	jornadas: JornadaLike[],
	cuadros: CuadroLike[]
): RangeConsistencyIssue[] {
	const jornadaIssues = findRangeOverlaps(
		jornadas.map((jornada) => ({
			id: jornada.jornada_id,
			label: `Jornada ${jornada.jornada_num}`,
			v_ini: jornada.v_ini,
			v_fin: jornada.v_fin
		})),
		'jornadas'
	);
	const jornadaById = new Map(jornadas.map((jornada) => [jornada.jornada_id, jornada]));
	const cuadrosByJornada = new Map<string, CuadroLike[]>();

	for (const cuadro of cuadros) {
		const current = cuadrosByJornada.get(cuadro.jornada_id) ?? [];
		current.push(cuadro);
		cuadrosByJornada.set(cuadro.jornada_id, current);
	}

	const cuadroIssues = [...cuadrosByJornada.entries()].flatMap(([jornadaId, items]) => {
		const jornada = jornadaById.get(jornadaId);
		const contextLabel = jornada ? ` dentro de la Jornada ${jornada.jornada_num}` : '';
		return findRangeOverlaps(
			items.map((cuadro) => ({
				id: cuadro.cuadro_id,
				label: `Cuadro ${cuadro.cuadro_num}`,
				v_ini: cuadro.v_ini,
				v_fin: cuadro.v_fin
			})),
			'cuadros',
			contextLabel
		);
	});
	const cuadroContainmentIssues = cuadros.flatMap((cuadro): RangeConsistencyIssue[] => {
		const jornada = jornadaById.get(cuadro.jornada_id);
		if (
			!jornada ||
			(cuadro.v_ini >= jornada.v_ini && cuadro.v_fin <= jornada.v_fin)
		) {
			return [];
		}
		return [
			{
				kind: 'out_of_bounds',
				scope: 'cuadros',
				leftId: jornada.jornada_id,
				rightId: cuadro.cuadro_id,
				message: `Cuadro ${cuadro.cuadro_num} (vv. ${cuadro.v_ini}-${cuadro.v_fin}) queda fuera del rango de la Jornada ${jornada.jornada_num} (vv. ${jornada.v_ini}-${jornada.v_fin}).`
			}
		];
	});

	return [...jornadaIssues, ...cuadroIssues, ...cuadroContainmentIssues];
}

export function analyzeSequenceRangeConsistency(
	secuencias: SecuenciaLike[]
): RangeConsistencyIssue[] {
	const sorted = [...secuencias].sort(
		(a, b) =>
			a.v_ini - b.v_ini || a.v_fin - b.v_fin || a.secuencia_id.localeCompare(b.secuencia_id)
	);
	return findRangeOverlaps(
		sorted.map((secuencia, index) => ({
			id: secuencia.secuencia_id,
			label: `Secuencia ${index + 1}`,
			v_ini: secuencia.v_ini,
			v_fin: secuencia.v_fin
		})),
		'secuencias'
	);
}

export function collectRangeConsistencyIds(issues: RangeConsistencyIssue[]): Set<string> {
	return new Set(issues.flatMap((issue) => [issue.leftId, issue.rightId]));
}

export function stateRequiresCompletedReview(stateTerm: string): boolean {
	return ['vista_previa', 'listo_para_publicar', 'publicado'].includes(
		stateTerm.trim().toLowerCase()
	);
}

export function stateAllowsRangeEditing(stateTerm: string): boolean {
	return stateTerm.trim().toLowerCase() === 'borrador';
}

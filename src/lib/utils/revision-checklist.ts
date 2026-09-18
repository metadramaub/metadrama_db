import {
	analyzeSequenceRangeConsistency,
	analyzeStructureRangeConsistency,
	type RangeConsistencyIssue
} from '$lib/utils/range-consistency';

export type RevisionTargetTab =
	| 'datos'
	| 'estructura'
	| 'secuencias'
	| 'autoria'
	| 'observaciones';

export type RevisionChecklistItem = {
	id: string;
	label: string;
	done: boolean;
	detail: string;
	targetTab?: RevisionTargetTab;
};

type ObraChecklistData = {
	titulo: string | null;
	genero_id: string | null;
	edicion: string | null;
	observaciones: string | null;
	bibliografia: string | null;
	editor_asignado: string | null;
	/** La fecha tradicional y de dónde sale. Se recomiendan, no se exigen: no toda obra la tiene. */
	fecha_inicio_trad?: number | null;
	fecha_fin_trad?: number | null;
	fuente_fecha?: string | null;
};

type JornadaChecklistData = {
	jornada_id: string;
	jornada_num: number;
	v_ini: number;
	v_fin: number;
};

type CuadroChecklistData = {
	cuadro_id: string;
	cuadro_num: number;
	jornada_id: string;
	v_ini: number;
	v_fin: number;
};

type SecuenciaChecklistData = {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	/**
	 * Si la secuencia tiene forma, que es estar anotada con el catálogo: su forma vive en
	 * `anotaciones_metricas`. `estrofa_tipo_id` ya no cuenta, ni para bien ni para mal: desde el 7 de
	 * septiembre de 2026 el vocabulario legado no nombra nada y una obra con él sigue sin forma.
	 */
	tiene_anotacion_metrica?: boolean;
	inaugura_espacio: boolean | null;
	versos_partidos: boolean | null;
	intervencion_personajes_femeninos: string | null;
	intervencion_figuras_donaire: string | null;
	intervencion_personajes_sobrenaturales: string | null;
	evento_sobrenatural: boolean | null;
	sinopsis: string | null;
};

export type RevisionChecklistInput = {
	obra: ObraChecklistData;
	jornadas: JornadaChecklistData[];
	cuadros: CuadroChecklistData[];
	secuencias: SecuenciaChecklistData[];
	autoriaGroupCount: number;
};

export type RevisionChecklistSummary = {
	required: RevisionChecklistItem[];
	recommendations: RevisionChecklistItem[];
	rangeIssues: RangeConsistencyIssue[];
	pendingSequenceCount: number;
};

function pluralize(count: number, singular: string, plural: string): string {
	return `${count} ${count === 1 ? singular : plural}`;
}

function duplicateValues(values: number[]): number[] {
	const counts = new Map<number, number>();
	for (const value of values) {
		counts.set(value, (counts.get(value) ?? 0) + 1);
	}
	return [...counts.entries()]
		.filter(([, count]) => count > 1)
		.map(([value]) => value)
		.sort((a, b) => a - b);
}

function hasPendingSequenceFields(secuencia: SecuenciaChecklistData): boolean {
	return (
		!secuencia.tiene_anotacion_metrica ||
		secuencia.inaugura_espacio === null ||
		secuencia.versos_partidos === null ||
		secuencia.intervencion_personajes_femeninos === null ||
		secuencia.intervencion_figuras_donaire === null ||
		secuencia.intervencion_personajes_sobrenaturales === null ||
		secuencia.evento_sobrenatural === null
	);
}

function rangeLabel(v_ini: number, v_fin: number): string {
	return v_ini === v_fin ? `v. ${v_ini}` : `vv. ${v_ini}-${v_fin}`;
}

/**
 * **La que abre la obra inaugura espacio siempre**, y si ninguna lo hace es que nadie se ha fijado.
 *
 * Esta caracterización es la que más se olvida, porque el editor la responde secuencia a secuencia
 * y en cada una lo natural es que no cambie nada. Por eso se comprueba lo que no admite discusión:
 * la primera secuencia de la obra abre un espacio por fuerza, y una obra entera sin un solo cambio
 * de espacio no existe. Si falla cualquiera de las dos, lo que hay que revisar no es esa secuencia
 * sino la caracterización en todas.
 */
function analyzeSpaceInauguration(secuencias: SecuenciaChecklistData[]): {
	done: boolean;
	detail: string;
} {
	if (secuencias.length === 0) return { done: false, detail: 'No hay secuencias' };
	const ordered = [...secuencias].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	const first = ordered[0];
	const inauguran = secuencias.filter((secuencia) => secuencia.inaugura_espacio === true).length;

	if (inauguran === 0) {
		return {
			done: false,
			detail:
				'Ninguna secuencia inaugura espacio, y la que abre la obra lo hace siempre: revisa esta caracterización en todas'
		};
	}
	if (first.inaugura_espacio !== true) {
		return {
			done: false,
			detail: `La primera secuencia (${rangeLabel(first.v_ini, first.v_fin)}) no inaugura espacio, y la que abre la obra lo hace siempre`
		};
	}
	return { done: true, detail: pluralize(inauguran, 'secuencia lo inaugura', 'secuencias lo inauguran') };
}

/**
 * **Los versos que ninguna secuencia cubre.** Que dos secuencias no se pisen lo mira la coherencia
 * de rangos; que entre las dos no quede un hueco, o que la anotación termine antes que la obra, no
 * lo miraba nadie, y una obra publicada con versos sin anotar tiene el perfil mal. Se compara con
 * la estructura, que es quien dice del verso uno al último, y se devuelven los tramos que faltan.
 */
function findUncoveredRanges(
	jornadas: JornadaChecklistData[],
	secuencias: SecuenciaChecklistData[]
): { v_ini: number; v_fin: number }[] {
	if (jornadas.length === 0 || secuencias.length === 0) return [];
	const start = Math.min(...jornadas.map((jornada) => jornada.v_ini));
	const end = Math.max(...jornadas.map((jornada) => jornada.v_fin));
	const ordered = [...secuencias].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
	const gaps: { v_ini: number; v_fin: number }[] = [];
	let cursor = start;
	for (const secuencia of ordered) {
		if (secuencia.v_ini > cursor) gaps.push({ v_ini: cursor, v_fin: secuencia.v_ini - 1 });
		cursor = Math.max(cursor, secuencia.v_fin + 1);
	}
	if (cursor <= end) gaps.push({ v_ini: cursor, v_fin: end });
	return gaps.filter((gap) => gap.v_fin >= gap.v_ini && gap.v_fin >= start && gap.v_ini <= end);
}

export function buildRevisionChecklist(
	input: RevisionChecklistInput
): RevisionChecklistSummary {
	const missingBasicFields = [
		!input.obra.titulo?.trim() ? 'título' : null,
		!input.obra.genero_id ? 'género' : null,
		!input.obra.edicion?.trim() ? 'edición base' : null
	].filter((value): value is string => Boolean(value));

	const cuadrosByJornada = new Map<string, CuadroChecklistData[]>();
	for (const cuadro of input.cuadros) {
		const current = cuadrosByJornada.get(cuadro.jornada_id) ?? [];
		current.push(cuadro);
		cuadrosByJornada.set(cuadro.jornada_id, current);
	}

	const jornadasWithoutCuadros = input.jornadas.filter(
		(jornada) => (cuadrosByJornada.get(jornada.jornada_id) ?? []).length === 0
	);
	const duplicateJornadaNumbers = duplicateValues(
		input.jornadas.map((jornada) => jornada.jornada_num)
	);
	const jornadasWithDuplicateCuadros = input.jornadas.filter(
		(jornada) =>
			duplicateValues(
				(cuadrosByJornada.get(jornada.jornada_id) ?? []).map(
					(cuadro) => cuadro.cuadro_num
				)
			).length > 0
	);
	const numberingIssueCount =
		duplicateJornadaNumbers.length + jornadasWithDuplicateCuadros.length;
	const numberingIssueDetails = [
		duplicateJornadaNumbers.length > 0
			? `Jornadas repetidas: ${duplicateJornadaNumbers.join(', ')}`
			: null,
		jornadasWithDuplicateCuadros.length > 0
			? `Cuadros repetidos en ${jornadasWithDuplicateCuadros
					.map((jornada) => `jornada ${jornada.jornada_num}`)
					.join(', ')}`
			: null
	].filter((value): value is string => Boolean(value));

	const pendingSequenceCount = input.secuencias.filter(hasPendingSequenceFields).length;
	const missingSynopsisCount = input.secuencias.filter(
		(secuencia) => !(secuencia.sinopsis ?? '').trim()
	).length;
	const rangeIssues = [
		...analyzeStructureRangeConsistency(input.jornadas, input.cuadros),
		...analyzeSequenceRangeConsistency(input.secuencias)
	];
	const rangeTargetTab: RevisionTargetTab =
		rangeIssues.some((issue) => issue.scope !== 'secuencias')
			? 'estructura'
			: 'secuencias';
	const spaceInauguration = analyzeSpaceInauguration(input.secuencias);
	const uncovered = findUncoveredRanges(input.jornadas, input.secuencias);
	const uncoveredVerses = uncovered.reduce((sum, gap) => sum + (gap.v_fin - gap.v_ini + 1), 0);
	const tieneFecha = input.obra.fecha_inicio_trad != null || input.obra.fecha_fin_trad != null;
	const tieneFuenteFecha = Boolean((input.obra.fuente_fecha ?? '').trim());
	const observacionesLength = (input.obra.observaciones ?? '').trim().length;
	const bibliografiaLength = (input.obra.bibliografia ?? '').trim().length;

	return {
		required: [
			{
				id: 'basic-data',
				label: 'Datos básicos completos',
				done: missingBasicFields.length === 0,
				detail:
					missingBasicFields.length === 0
						? ''
						: `Faltan: ${missingBasicFields.join(', ')}`,
				targetTab: 'datos'
			},
			{
				id: 'structure',
				label: 'Estructura definida',
				done: input.jornadas.length > 0 && jornadasWithoutCuadros.length === 0,
				detail:
					input.jornadas.length === 0
						? 'No hay jornadas'
						: jornadasWithoutCuadros.length > 0
							? `${pluralize(jornadasWithoutCuadros.length, 'jornada sin cuadros', 'jornadas sin cuadros')}`
							: `${pluralize(input.jornadas.length, 'jornada', 'jornadas')}, ${pluralize(input.cuadros.length, 'cuadro', 'cuadros')}`,
				targetTab: 'estructura'
			},
			{
				id: 'structure-numbering',
				label: 'Numeración de la estructura sin duplicados',
				done: numberingIssueCount === 0,
				detail:
					numberingIssueCount === 0
						? ''
						: numberingIssueDetails.join('. '),
				targetTab: 'estructura'
			},
			{
				id: 'sequences',
				label: 'Secuencias métricas registradas',
				done: input.secuencias.length > 0,
				detail: pluralize(input.secuencias.length, 'secuencia', 'secuencias'),
				targetTab: 'secuencias'
			},
			{
				id: 'sequence-fields',
				label: 'Campos de secuencia revisados',
				done: input.secuencias.length > 0 && pendingSequenceCount === 0,
				detail:
					input.secuencias.length === 0
						? 'No hay secuencias'
						: pendingSequenceCount === 0
							? ''
							: `${pluralize(pendingSequenceCount, 'secuencia pendiente', 'secuencias pendientes')}`,
				targetTab: 'secuencias'
			},
			{
				id: 'ranges',
				label: 'Rangos coherentes',
				done: rangeIssues.length === 0,
				detail:
					rangeIssues.length === 0
						? ''
						: `${pluralize(rangeIssues.length, 'incoherencia', 'incoherencias')}`,
				targetTab: rangeTargetTab
			},
			{
				id: 'sequence-coverage',
				label: 'Las secuencias cubren toda la obra',
				done: input.jornadas.length > 0 && input.secuencias.length > 0 && uncovered.length === 0,
				detail:
					input.jornadas.length === 0
						? 'No hay estructura con la que comparar'
						: input.secuencias.length === 0
							? 'No hay secuencias'
							: uncovered.length === 0
								? ''
								: `Sin anotar ${pluralize(uncoveredVerses, 'verso', 'versos')}: ${uncovered
										.slice(0, 4)
										.map((gap) => rangeLabel(gap.v_ini, gap.v_fin))
										.join(', ')}${uncovered.length > 4 ? ` y ${uncovered.length - 4} tramos más` : ''}`,
				targetTab: 'secuencias'
			},
			{
				id: 'space-inauguration',
				label: 'Inauguración de espacio revisada',
				done: spaceInauguration.done,
				detail: spaceInauguration.detail,
				targetTab: 'secuencias'
			},
			{
				id: 'authorship',
				label: 'Autoría registrada',
				done: input.autoriaGroupCount > 0,
				detail:
					input.autoriaGroupCount > 0
						? pluralize(input.autoriaGroupCount, 'grupo de autoría', 'grupos de autoría')
						: 'No hay propuestas de autoría',
				targetTab: 'autoria'
			}
		],
		recommendations: [
			{
				id: 'sequence-synopses',
				label: 'Sinopsis de las secuencias completadas',
				done: input.secuencias.length > 0 && missingSynopsisCount === 0,
				detail:
					input.secuencias.length === 0
						? 'No hay secuencias'
						: missingSynopsisCount === 0
							? ''
							: `${pluralize(missingSynopsisCount, 'sinopsis pendiente', 'sinopsis pendientes')}`,
				targetTab: 'secuencias'
			},
			{
				id: 'dating',
				label: 'Fecha tradicional y su fuente',
				done: tieneFecha && tieneFuenteFecha,
				detail: !tieneFecha
					? tieneFuenteFecha
						? 'Hay fuente pero no fecha'
						: 'Sin fecha'
					: tieneFuenteFecha
						? ''
						: 'Hay fecha pero no dice de dónde sale',
				targetTab: 'datos'
			},
			{
				id: 'observations',
				label: 'Observaciones de obra desarrolladas',
				done: observacionesLength > 100,
				detail: `${pluralize(observacionesLength, 'carácter', 'caracteres')}`,
				targetTab: 'observaciones'
			},
			{
				id: 'bibliography',
				label: 'Bibliografía métrica añadida',
				done: bibliografiaLength > 0,
				detail: `${pluralize(bibliografiaLength, 'carácter', 'caracteres')}`,
				targetTab: 'observaciones'
			},
			{
				id: 'editor',
				label: 'Responsable de edición asignado',
				done: Boolean(input.obra.editor_asignado),
				detail: input.obra.editor_asignado ? '' : 'Sin asignar'
			}
		],
		rangeIssues,
		pendingSequenceCount
	};
}

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
	estrofa_tipo_id: string | null;
	inaugura_espacio: boolean | null;
	versos_partidos: boolean | null;
	evocacion_metrica: boolean | null;
	evocacion_metrica_texto: string | null;
	intervencion_personajes_femeninos: string | null;
	intervencion_figuras_donaire: string | null;
	intervencion_personajes_sobrenaturales: string | null;
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
		secuencia.estrofa_tipo_id === null ||
		secuencia.inaugura_espacio === null ||
		secuencia.versos_partidos === null ||
		secuencia.evocacion_metrica === null ||
		secuencia.intervencion_personajes_femeninos === null ||
		secuencia.intervencion_figuras_donaire === null ||
		secuencia.intervencion_personajes_sobrenaturales === null ||
		(secuencia.evocacion_metrica === true &&
			!(secuencia.evocacion_metrica_texto ?? '').trim())
	);
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

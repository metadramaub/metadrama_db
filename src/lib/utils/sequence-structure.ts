export type SequenceStructureSequenceLike = {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
};

export type SequenceStructureJornadaLike = {
	jornada_id: string;
	jornada_num: number;
	v_ini: number;
	v_fin: number;
};

export type SequenceStructureCuadroLike = {
	cuadro_id: string;
	cuadro_num: number;
	jornada_id: string;
	v_ini: number;
	v_fin: number;
};

export type SequenceStructureJornadaRef = {
	key: string;
	jornadaId: string | null;
	jornadaNum: number | null;
	vIni: number | null;
	vFin: number | null;
	label: string;
	rangeLabel: string | null;
};

export type SequenceStructureCuadroRef = {
	key: string;
	cuadroId: string | null;
	cuadroNum: number | null;
	vIni: number | null;
	vFin: number | null;
	label: string;
	rangeLabel: string | null;
};

export type SequenceStructureTramo = {
	cuadroId: string | null;
	cuadroNum: number | null;
	label: string;
	vIni: number;
	vFin: number;
};

export type ResolvedSequenceStructure<TSequence extends SequenceStructureSequenceLike> = {
	sequence: TSequence;
	index: number;
	vIni: number;
	vFin: number;
	jornada: SequenceStructureJornadaRef;
	startingCuadro: SequenceStructureCuadroRef;
	endingCuadro: SequenceStructureCuadroRef;
	spansMultipleCuadros: boolean;
	tramos: SequenceStructureTramo[];
};

type ResolveSequenceStructuresArgs<
	TSequence extends SequenceStructureSequenceLike,
	TJornada extends SequenceStructureJornadaLike,
	TCuadro extends SequenceStructureCuadroLike
> = {
	secuencias: TSequence[];
	jornadas: TJornada[];
	cuadros: TCuadro[];
};

function sortSecuencias<TSequence extends SequenceStructureSequenceLike>(items: TSequence[]) {
	return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
}

function sortJornadas<TJornada extends SequenceStructureJornadaLike>(items: TJornada[]) {
	return [...items].sort(
		(a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin || a.jornada_num - b.jornada_num
	);
}

function sortCuadros<TCuadro extends SequenceStructureCuadroLike>(items: TCuadro[]) {
	return [...items].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin || a.cuadro_num - b.cuadro_num);
}

function overlaps(vIni: number, vFin: number, otherIni: number, otherFin: number) {
	return Math.max(vIni, otherIni) <= Math.min(vFin, otherFin);
}

function formatRangeLabel(vIni: number | null, vFin: number | null) {
	if (vIni === null || vFin === null) return null;
	return `vv. ${vIni}-${vFin}`;
}

function buildJornadaRef<TJornada extends SequenceStructureJornadaLike>(
	jornada: TJornada | null
): SequenceStructureJornadaRef {
	if (!jornada) {
		return {
			key: 'sin-jornada',
			jornadaId: null,
			jornadaNum: null,
			vIni: null,
			vFin: null,
			label: 'Sin jornada',
			rangeLabel: null
		};
	}

	return {
		key: jornada.jornada_id,
		jornadaId: jornada.jornada_id,
		jornadaNum: jornada.jornada_num,
		vIni: jornada.v_ini,
		vFin: jornada.v_fin,
		label: `Jornada ${jornada.jornada_num}`,
		rangeLabel: formatRangeLabel(jornada.v_ini, jornada.v_fin)
	};
}

function buildCuadroRef<TCuadro extends SequenceStructureCuadroLike>(
	cuadro: TCuadro | null
): SequenceStructureCuadroRef {
	if (!cuadro) {
		return {
			key: 'sin-cuadro',
			cuadroId: null,
			cuadroNum: null,
			vIni: null,
			vFin: null,
			label: 'Sin cuadro',
			rangeLabel: null
		};
	}

	return {
		key: cuadro.cuadro_id,
		cuadroId: cuadro.cuadro_id,
		cuadroNum: cuadro.cuadro_num,
		vIni: cuadro.v_ini,
		vFin: cuadro.v_fin,
		label: `Cuadro ${cuadro.cuadro_num}`,
		rangeLabel: formatRangeLabel(cuadro.v_ini, cuadro.v_fin)
	};
}

export function resolveSequenceStructures<
	TSequence extends SequenceStructureSequenceLike,
	TJornada extends SequenceStructureJornadaLike,
	TCuadro extends SequenceStructureCuadroLike
>(
	args: ResolveSequenceStructuresArgs<TSequence, TJornada, TCuadro>
): ResolvedSequenceStructure<TSequence>[] {
	const secuencias = sortSecuencias(args.secuencias);
	const jornadas = sortJornadas(args.jornadas);
	const cuadros = sortCuadros(args.cuadros);

	return secuencias.map((sequence, index) => {
		const jornada =
			jornadas.find((item) => sequence.v_ini >= item.v_ini && sequence.v_fin <= item.v_fin) ?? null;
		const cuadrosSolapados = jornada
			? cuadros.filter(
					(cuadro) =>
						cuadro.jornada_id === jornada.jornada_id &&
						overlaps(sequence.v_ini, sequence.v_fin, cuadro.v_ini, cuadro.v_fin)
				)
			: [];

		const tramos = cuadrosSolapados
			.map((cuadro) => {
				const vIni = Math.max(sequence.v_ini, cuadro.v_ini);
				const vFin = Math.min(sequence.v_fin, cuadro.v_fin);
				return {
					cuadroId: cuadro.cuadro_id,
					cuadroNum: cuadro.cuadro_num,
					label: `Cuadro ${cuadro.cuadro_num} · vv. ${vIni}-${vFin}`,
					vIni,
					vFin
				} satisfies SequenceStructureTramo;
			})
			.filter((tramo) => tramo.vIni <= tramo.vFin);

		return {
			sequence,
			index: index + 1,
			vIni: sequence.v_ini,
			vFin: sequence.v_fin,
			jornada: buildJornadaRef(jornada),
			startingCuadro: buildCuadroRef(cuadrosSolapados[0] ?? null),
			endingCuadro: buildCuadroRef(cuadrosSolapados.at(-1) ?? null),
			spansMultipleCuadros: tramos.length > 1,
			tramos
		} satisfies ResolvedSequenceStructure<TSequence>;
	});
}

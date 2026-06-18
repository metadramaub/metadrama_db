import {
	resolveSequenceStructures,
	type ResolvedSequenceStructure,
	type SequenceStructureCuadroRef,
	type SequenceStructureTramo
} from '$lib/utils/sequence-structure';
import type { Tables } from '$lib/types/database.types';

type JornadaRow = Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>;
type CuadroRow = Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'>;
type EstrofaOption = Pick<Tables<'vocabularios'>, 'termino_id' | 'termino'>;

export type SequenceSynopsisSequenceLike = {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	n_versos?: number | null;
	estrofa_tipo_id?: string | null;
	estrofa_tipo_term?: string | null;
	sinopsis: string | null;
};

export type SequenceSynopsisCuadroRef = SequenceStructureCuadroRef;
export type SequenceSynopsisTramo = SequenceStructureTramo;

export type SequenceSynopsisCard = {
	secuenciaId: string;
	index: number;
	vIni: number;
	vFin: number;
	nVersos: number | null;
	estrofaLabel: string;
	sinopsis: string | null;
	hasSynopsis: boolean;
	startingCuadro: SequenceSynopsisCuadroRef;
	endingCuadro: SequenceSynopsisCuadroRef;
	spansMultipleCuadros: boolean;
	tramos: SequenceSynopsisTramo[];
};

export type SequenceSynopsisGroupItem =
	| {
			type: 'cuadro_divider';
			key: string;
			cuadro: SequenceSynopsisCuadroRef;
	  }
	| {
			type: 'cuadro_carryover';
			key: string;
			cuadro: SequenceSynopsisCuadroRef;
	  }
	| {
			type: 'card';
			key: string;
			card: SequenceSynopsisCard;
	  };

export type SequenceSynopsisJornadaGroup = {
	jornadaId: string | null;
	jornadaNum: number | null;
	label: string;
	rangeLabel: string | null;
	cards: SequenceSynopsisCard[];
	items: SequenceSynopsisGroupItem[];
};

type BuildSequenceSynopsisGroupsArgs = {
	secuencias: SequenceSynopsisSequenceLike[];
	jornadas: JornadaRow[];
	cuadros: CuadroRow[];
	estrofaOptions?: EstrofaOption[];
};

function buildItems(cards: SequenceSynopsisCard[], groupKey: string): SequenceSynopsisGroupItem[] {
	const items: SequenceSynopsisGroupItem[] = [];
	let activeCuadroKey: string | null = null;
	let previousCardEndedInDifferentCuadro = false;

	for (const card of cards) {
		if (previousCardEndedInDifferentCuadro && card.startingCuadro.key === activeCuadroKey) {
			items.push({
				type: 'cuadro_carryover',
				key: `${groupKey}-cuadro_carryover-${card.secuenciaId}`,
				cuadro: card.startingCuadro
			});
		} else if (card.startingCuadro.key !== activeCuadroKey) {
			const type =
				previousCardEndedInDifferentCuadro && card.startingCuadro.key !== 'sin-cuadro'
					? 'cuadro_carryover'
					: 'cuadro_divider';
			items.push({
				type,
				key: `${groupKey}-${type}-${card.secuenciaId}`,
				cuadro: card.startingCuadro
			});
		}

		items.push({
			type: 'card',
			key: `${groupKey}-card-${card.secuenciaId}`,
			card
		});

		activeCuadroKey = card.endingCuadro.key;
		previousCardEndedInDifferentCuadro = card.spansMultipleCuadros;
	}

	return items;
}

export function buildSequenceSynopsisGroups(args: BuildSequenceSynopsisGroupsArgs): SequenceSynopsisJornadaGroup[] {
	const resolved = resolveSequenceStructures({
		secuencias: args.secuencias,
		jornadas: args.jornadas,
		cuadros: args.cuadros
	});
	const estrofaById = new Map((args.estrofaOptions ?? []).map((option) => [option.termino_id, option.termino]));
	const groups = new Map<string, SequenceSynopsisJornadaGroup>();
	const fallbackCards: SequenceSynopsisCard[] = [];

	for (const item of resolved) {
		const card = mapResolvedSequenceToCard(item, estrofaById);
		if (!item.jornada.jornadaId) {
			fallbackCards.push(card);
			continue;
		}

		const existingGroup = groups.get(item.jornada.jornadaId);
		if (existingGroup) {
			existingGroup.cards.push(card);
			continue;
		}

		groups.set(item.jornada.jornadaId, {
			jornadaId: item.jornada.jornadaId,
			jornadaNum: item.jornada.jornadaNum,
			label: item.jornada.label,
			rangeLabel: item.jornada.rangeLabel,
			cards: [card],
			items: []
		});
	}

	const orderedGroups = resolved
		.map((item) => item.jornada.jornadaId)
		.filter((id, index, allIds): id is string => Boolean(id) && allIds.indexOf(id) === index)
		.map((jornadaId) => groups.get(jornadaId))
		.filter((group): group is SequenceSynopsisJornadaGroup => Boolean(group))
		.map((group) => {
			const cards = [...group.cards].sort((a, b) => a.vIni - b.vIni || a.vFin - b.vFin);
			return {
				...group,
				cards,
				items: buildItems(cards, group.jornadaId ?? 'sin-jornada')
			};
		});

	if (fallbackCards.length > 0) {
		const cards = [...fallbackCards].sort((a, b) => a.vIni - b.vIni || a.vFin - b.vFin);
		orderedGroups.push({
			jornadaId: null,
			jornadaNum: null,
			label: 'Sin jornada',
			rangeLabel: null,
			cards,
			items: buildItems(cards, 'sin-jornada')
		});
	}

	return orderedGroups;
}

function mapResolvedSequenceToCard(
	item: ResolvedSequenceStructure<SequenceSynopsisSequenceLike>,
	estrofaById: Map<string, string>
): SequenceSynopsisCard {
	const estrofaLabel =
		item.sequence.estrofa_tipo_term ??
		estrofaById.get(item.sequence.estrofa_tipo_id ?? '') ??
		'Sin estrofa';

	return {
		secuenciaId: item.sequence.secuencia_id,
		index: item.index,
		vIni: item.vIni,
		vFin: item.vFin,
		nVersos: item.sequence.n_versos ?? null,
		estrofaLabel,
		sinopsis: item.sequence.sinopsis,
		hasSynopsis: Boolean(item.sequence.sinopsis?.trim()),
		startingCuadro: item.startingCuadro,
		endingCuadro: item.endingCuadro,
		spansMultipleCuadros: item.spansMultipleCuadros,
		tramos: item.tramos
	};
}

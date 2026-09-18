import {
	resolveSequenceStructures,
	type ResolvedSequenceStructure,
	type SequenceStructureCuadroRef,
	type SequenceStructureTramo
} from '$lib/utils/sequence-structure';
import type { Tables } from '$lib/types/database.types';
import { bandaDeCuadros, type TramoDeBanda } from '$lib/metrica/banda-de-cuadros';

type JornadaRow = Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>;
type CuadroRow = Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'>;

/**
 * Lo que la sinopsis necesita saber de una secuencia. **Solo habla el catálogo nuevo**: la ficha
 * pública lo trae ya resuelto en su artefacto y el dashboard lo resuelve desde la anotación V2
 * antes de llamar aquí. El vocabulario legado —`estrofa_tipo_id`, sus términos— dejó de nombrar
 * pasajes el 7 de septiembre de 2026 y ya no se mira.
 */
export type SequenceSynopsisSequenceLike = {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	n_versos?: number | null;
	forma_nombre?: string | null;
	/** Slug de la forma (clave estable de color, la misma que barcode y pie). */
	forma_slug?: string | null;
	/** 'forma_espanola' | 'forma_italiana': la gama para el color de reserva. */
	tipo_forma?: string | null;
	arquitectura_id?: string | null;
	arquitectura_nombre?: string | null;
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
	/** La forma, que es lo que nombra el pasaje; «Sin forma» si no está anotada. */
	formaLabel: string;
	/**
	 * La arquitectura, cuando se conoce y dice algo más que la forma. Una quintilla «ababa» y una
	 * «abaab» son la misma forma y no la misma arquitectura, y solo con la forma el encabezado se
	 * quedaba corto. Nula si coincide con la forma, para no repetir la palabra.
	 */
	arquitecturaLabel: string | null;
	/** Slug de la forma para colorear (clave de colorByForma). */
	formaColorKey: string | null;
	/** tipo_forma de la forma (gama, para el fallback de color). */
	formaTipoForma: string | null;
	sinopsis: string | null;
	hasSynopsis: boolean;
	/** Dónde cae cada cambio de cuadro dentro de esta tarjeta, en proporción de su altura. */
	banda: TramoDeBanda[];
	startingCuadro: SequenceSynopsisCuadroRef;
	endingCuadro: SequenceSynopsisCuadroRef;
	spansMultipleCuadros: boolean;
	tramos: SequenceSynopsisTramo[];
};

/**
 * Las tarjetas, y nada más.
 *
 * Antes había además dos clases de aviso —«inicia» y «sigue»— para decir dónde cambiaba el cuadro,
 * y se elegía una u otra según dónde hubiera acabado la tarjeta anterior. Fallaba, y sobre todo
 * mentía: **el corte no cae entre dos tarjetas**, cae dentro de una. Ahora lo dice la banda de la
 * izquierda, que lo pinta a su altura real; el tipo se conserva para no romper a quien lo consuma.
 */
export type SequenceSynopsisGroupItem = {
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
};

function buildItems(cards: SequenceSynopsisCard[], groupKey: string): SequenceSynopsisGroupItem[] {
	return cards.map((card) => ({
		type: 'card' as const,
		key: `${groupKey}-card-${card.secuenciaId}`,
		card
	}));
}

export function buildSequenceSynopsisGroups(args: BuildSequenceSynopsisGroupsArgs): SequenceSynopsisJornadaGroup[] {
	const resolved = resolveSequenceStructures({
		secuencias: args.secuencias,
		jornadas: args.jornadas,
		cuadros: args.cuadros
	});
	// Los cuadros con su rango, numerados de corrido: la banda no sabe de jornadas.
	const rangosDeCuadro = [...(args.cuadros ?? [])]
		.filter((cuadro) => cuadro.v_ini !== null && cuadro.v_fin !== null)
		.sort((a, b) => (a.v_ini ?? 0) - (b.v_ini ?? 0))
		.map((cuadro, indice) => ({
			numero: cuadro.cuadro_num ?? indice + 1,
			v_ini: cuadro.v_ini as number,
			v_fin: cuadro.v_fin as number
		}));

	const groups = new Map<string, SequenceSynopsisJornadaGroup>();
	const fallbackCards: SequenceSynopsisCard[] = [];

	for (const item of resolved) {
		const card = mapResolvedSequenceToCard(item, rangosDeCuadro);
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
	rangosDeCuadro: { numero: number; v_ini: number; v_fin: number }[]
): SequenceSynopsisCard {
	// **La forma nombra el pasaje; la arquitectura es el detalle.** Decía «Octosilábica consonante»
	// donde tenía que decir «Quintilla», que es el mismo fallo que tenía el código de barras. Ahora
	// van las dos, y la arquitectura solo si añade algo a la forma.
	const formaLabel = item.sequence.forma_nombre?.trim() || 'Sin forma';
	const arquitectura = item.sequence.arquitectura_nombre?.trim() || null;
	const arquitecturaLabel =
		arquitectura && arquitectura.toLocaleLowerCase('es') !== formaLabel.toLocaleLowerCase('es')
			? arquitectura
			: null;

	return {
		secuenciaId: item.sequence.secuencia_id,
		index: item.index,
		vIni: item.vIni,
		vFin: item.vFin,
		nVersos: item.sequence.n_versos ?? null,
		formaLabel,
		arquitecturaLabel,
		formaColorKey: item.sequence.forma_slug ?? null,
		formaTipoForma: item.sequence.tipo_forma ?? null,
		sinopsis: item.sequence.sinopsis,
		hasSynopsis: Boolean(item.sequence.sinopsis?.trim()),
		banda: bandaDeCuadros(item.vIni, item.vFin, rangosDeCuadro),
		startingCuadro: item.startingCuadro,
		endingCuadro: item.endingCuadro,
		spansMultipleCuadros: item.spansMultipleCuadros,
		tramos: item.tramos
	};
}

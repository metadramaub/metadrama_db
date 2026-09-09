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
type EstrofaOption = Pick<
	Tables<'vocabularios'>,
	'termino_id' | 'termino' | 'termino_padre_id' | 'tipo_forma'
>;

export type SequenceSynopsisSequenceLike = {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	n_versos?: number | null;
	/** Contrato público actual. */
	arquitectura_id?: string | null;
	arquitectura_nombre?: string | null;
	forma_nombre?: string | null;
	forma_slug?: string | null;
	tipo_forma?: string | null;
	/** Contrato del editor y del corpus legado. */
	estrofa_tipo_id?: string | null;
	estrofa_tipo_term?: string | null;
	/** Etiqueta de la forma raíz, que es la que nombra el pasaje. */
	estrofa_forma_term?: string | null;
	/** Slug de la forma raíz (clave estable de color). */
	estrofa_forma_slug?: string | null;
	/** tipo_forma de la forma raíz (gama cálida/fría para el fallback de color). */
	estrofa_tipo_forma?: string | null;
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
	/** Slug de la forma raíz para colorear (clave de colorByForma). */
	formaColorKey: string | null;
	/** tipo_forma de la forma raíz (gama, para el fallback de color). */
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
	estrofaOptions?: EstrofaOption[];
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
	const estrofaById = new Map((args.estrofaOptions ?? []).map((option) => [option.termino_id, option.termino]));
	const estrofaOptionById = new Map((args.estrofaOptions ?? []).map((option) => [option.termino_id, option]));
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
		const card = mapResolvedSequenceToCard(item, estrofaById, estrofaOptionById, rangosDeCuadro);
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
	estrofaById: Map<string, string>,
	estrofaOptionById: Map<string, EstrofaOption>,
	rangosDeCuadro: { numero: number; v_ini: number; v_fin: number }[]
): SequenceSynopsisCard {
	// **La forma nombra el pasaje; la arquitectura es el detalle.** Decía «Octosilábica consonante»
	// donde tenía que decir «Quintilla», que es el mismo fallo que tenía el código de barras. El
	// encadenado conserva los dos escalones de antes porque en el dashboard las secuencias no
	// siempre traen la forma resuelta.
	const estrofaLabel =
		item.sequence.forma_nombre ??
		item.sequence.estrofa_forma_term ??
		item.sequence.arquitectura_nombre ??
		item.sequence.estrofa_tipo_term ??
		estrofaById.get(item.sequence.estrofa_tipo_id ?? '') ??
		'Sin estrofa';

	// Forma raíz: si la secuencia ya trae el slug/gama (p.ej. payload público), se
	// usa; si no, se deriva del estrofa_tipo_id subiendo al término padre (la raíz)
	// con el catálogo de estrofas.
	const forma = resolveFormaRaiz(item.sequence, estrofaOptionById);

	return {
		secuenciaId: item.sequence.secuencia_id,
		index: item.index,
		vIni: item.vIni,
		vFin: item.vFin,
		nVersos: item.sequence.n_versos ?? null,
		estrofaLabel,
		formaColorKey: forma.slug,
		formaTipoForma: forma.tipoForma,
		sinopsis: item.sequence.sinopsis,
		hasSynopsis: Boolean(item.sequence.sinopsis?.trim()),
		banda: bandaDeCuadros(item.vIni, item.vFin, rangosDeCuadro),
		startingCuadro: item.startingCuadro,
		endingCuadro: item.endingCuadro,
		spansMultipleCuadros: item.spansMultipleCuadros,
		tramos: item.tramos
	};
}

/**
 * Forma raíz (slug + tipo_forma) de una secuencia. Prefiere los valores que ya
 * trae la secuencia; si faltan, sube del estrofa_tipo_id a su término padre (la
 * forma raíz) usando el catálogo de estrofas.
 */
function resolveFormaRaiz(
	sequence: SequenceSynopsisSequenceLike,
	estrofaOptionById: Map<string, EstrofaOption>
): { slug: string | null; tipoForma: string | null } {
	if (sequence.forma_slug) {
		return { slug: sequence.forma_slug, tipoForma: sequence.tipo_forma ?? null };
	}
	if (sequence.estrofa_forma_slug) {
		return {
			slug: sequence.estrofa_forma_slug,
			tipoForma: sequence.estrofa_tipo_forma ?? null
		};
	}

	const tipo = sequence.estrofa_tipo_id ? estrofaOptionById.get(sequence.estrofa_tipo_id) : undefined;
	if (!tipo) return { slug: null, tipoForma: sequence.estrofa_tipo_forma ?? null };

	const raiz = tipo.termino_padre_id ? (estrofaOptionById.get(tipo.termino_padre_id) ?? tipo) : tipo;
	return { slug: raiz.termino, tipoForma: raiz.tipo_forma ?? null };
}

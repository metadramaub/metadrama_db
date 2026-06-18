// Construye la jerarquía forma → tipos de estrofa para la leyenda desplegable
// del perfil métrico, a partir de las secuencias (que ya traen forma + tipo).
import type { MetricDistributionSlice } from './metric-display.types';

export interface MetricDistributionChild {
	/** Tipo de estrofa (p.ej. "quintilla"). */
	label: string;
	versos: number;
	porcentaje: number;
}

export interface MetricDistributionGroup extends MetricDistributionSlice {
	/** Tipos de estrofa que componen esta forma (vacío si no hay desglose). */
	children: MetricDistributionChild[];
}

interface SequenceLike {
	estrofa_forma_term: string;
	estrofa_tipo_term: string;
	n_versos: number;
}

/**
 * Agrupa: por cada forma (slice del pie) calcula los tipos de estrofa que la
 * componen y sus versos, ordenados de mayor a menor. Solo añade children cuando
 * aportan desglose (más de un tipo, o un tipo con nombre distinto a la forma).
 */
export function buildDistributionGroups(
	slices: MetricDistributionSlice[],
	sequences: SequenceLike[]
): MetricDistributionGroup[] {
	// Versos por (forma -> tipo).
	const byForma = new Map<string, Map<string, number>>();
	for (const seq of sequences) {
		const tipos = byForma.get(seq.estrofa_forma_term) ?? new Map<string, number>();
		tipos.set(seq.estrofa_tipo_term, (tipos.get(seq.estrofa_tipo_term) ?? 0) + (seq.n_versos ?? 0));
		byForma.set(seq.estrofa_forma_term, tipos);
	}

	return slices.map((slice): MetricDistributionGroup => {
		const tipos = byForma.get(slice.forma);
		const total = slice.versos || 0;
		let children: MetricDistributionChild[] = [];
		if (tipos) {
			children = [...tipos.entries()]
				.map(([label, versos]) => ({
					label,
					versos,
					porcentaje: total > 0 ? Math.round((versos / total) * 10000) / 100 : 0
				}))
				.sort((a, b) => b.versos - a.versos || a.label.localeCompare(b.label, 'es'));
		}
		// Sin desglose útil si solo hay un tipo que coincide con la forma.
		const meaningful =
			children.length > 1 || (children.length === 1 && children[0].label !== slice.forma);
		return { ...slice, children: meaningful ? children : [] };
	});
}

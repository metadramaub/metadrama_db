// Construye la jerarquía forma → tipos/subtipos de estrofa para la leyenda
// desplegable del perfil métrico.
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
	v_ini?: number;
	v_fin?: number;
	estrofa_forma_term: string;
	estrofa_tipo_term: string;
	n_versos: number;
	subtipos_estrofa?: {
		subtipo_estrofa_term: string;
		v_ini: number;
		v_fin: number;
	}[];
}

/**
 * Agrupa: por cada forma (slice del pie) calcula los subtipos de estrofa si
 * existen; si no, usa los tipos. Solo oculta children cuando no aportan desglose.
 */
export function buildDistributionGroups(
	slices: MetricDistributionSlice[],
	sequences: SequenceLike[]
): MetricDistributionGroup[] {
	// Versos por (forma -> subtipo/tipo).
	const byForma = new Map<string, Map<string, number>>();
	const hasSubtypesByForma = new Set<string>();
	for (const seq of sequences) {
		const tipos = byForma.get(seq.estrofa_forma_term) ?? new Map<string, number>();
		const subtypes = seq.subtipos_estrofa ?? [];
		if (subtypes.length > 0) {
			let subtypeVerses = 0;
			for (const subtype of subtypes) {
				const sequenceStart = seq.v_ini ?? subtype.v_ini;
				const sequenceEnd = seq.v_fin ?? subtype.v_fin;
				const vIni = Math.max(subtype.v_ini, sequenceStart);
				const vFin = Math.min(Math.max(subtype.v_fin, vIni), sequenceEnd);
				const versos = Math.max(0, vFin - vIni + 1);
				if (versos <= 0) continue;
				tipos.set(subtype.subtipo_estrofa_term, (tipos.get(subtype.subtipo_estrofa_term) ?? 0) + versos);
				subtypeVerses += versos;
			}
			const remainder = Math.max(0, (seq.n_versos ?? 0) - subtypeVerses);
			if (remainder > 0) {
				tipos.set(seq.estrofa_tipo_term, (tipos.get(seq.estrofa_tipo_term) ?? 0) + remainder);
			}
			hasSubtypesByForma.add(seq.estrofa_forma_term);
		} else {
			tipos.set(seq.estrofa_tipo_term, (tipos.get(seq.estrofa_tipo_term) ?? 0) + (seq.n_versos ?? 0));
		}
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
		// Sin desglose útil si solo hay un tipo que coincide con la forma. Si la
		// forma tiene subtipos declarados, sí interesa mostrar incluso un hijo único.
		const meaningful =
			hasSubtypesByForma.has(slice.forma) ||
			children.length > 1 ||
			(children.length === 1 && children[0].label !== slice.forma);
		return { ...slice, children: meaningful ? children : [] };
	});
}

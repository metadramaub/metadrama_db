// Construye la jerarquía real de la ficha: forma → arquitectura → respuestas observadas.
// Cada dimensión se cuenta en su escala métrica: tiradas, versos o realizaciones concretas.
import type { MetricDistributionSlice } from './metric-display.types';
import type {
	PublicFichaEsquemaRima,
	PublicFichaMetro,
	PublicFichaRasgo,
	PublicFichaRespuestaMetricaContexto,
	PublicFichaVariedad
} from '$lib/types/public-ficha.types';

export interface MetricDistributionValue {
	label: string;
	cantidad: number;
	/** Nombre singular de lo contado: tirada, soneto, estancia, verso... */
	unidad: string;
	/** Versos cubiertos; se usa además del número de tiradas en los rasgos. */
	versos: number;
}

export interface MetricDistributionDimension {
	label: string;
	values: MetricDistributionValue[];
}

export interface MetricDistributionArchitecture {
	label: string;
	slug: string | null;
	versos: number;
	porcentaje: number;
	esquemas: MetricDistributionValue[];
	rasgos: MetricDistributionDimension[];
	metros: MetricDistributionValue[];
	variedades: MetricDistributionValue[];
}

export interface MetricDistributionGroup extends MetricDistributionSlice {
	arquitecturas: MetricDistributionArchitecture[];
}

export interface MetricDistributionSequence {
	secuencia_id?: string;
	v_ini?: number;
	v_fin?: number;
	forma_nombre: string;
	arquitectura_nombre: string;
	arquitectura_slug?: string | null;
	nivel_estructural?: string | null;
	n_versos: number;
	esquemas_rima?: PublicFichaEsquemaRima[];
	rasgos?: PublicFichaRasgo[];
	metros?: PublicFichaMetro[];
	variedades?: PublicFichaVariedad[];
}

interface ResponseScope {
	key: string;
	unit: string;
}

const porcentaje = (parte: number, total: number) =>
	total > 0 ? Math.round((parte / total) * 10000) / 100 : 0;

function pluralizeWord(word: string): string {
	if (['de', 'del', 'la', 'el', 'y'].includes(word)) return word;
	if (word.endsWith('ción')) return `${word.slice(0, -4)}ciones`;
	if (word.endsWith('z')) return `${word.slice(0, -1)}ces`;
	if (/[aeiouáéíóú]$/i.test(word)) return `${word}s`;
	if (word.endsWith('s') || word.endsWith('x')) return word;
	return `${word}es`;
}

export function pluralizeMetricUnit(unit: string, quantity: number): string {
	return quantity === 1 ? unit : unit.split(' ').map(pluralizeWord).join(' ');
}

export function formatMetricCount(value: Pick<MetricDistributionValue, 'cantidad' | 'unidad'>) {
	return `${value.cantidad} ${pluralizeMetricUnit(value.unidad, value.cantidad)}`;
}

const sequenceKey = (sequence: MetricDistributionSequence) =>
	sequence.secuencia_id ?? `${sequence.forma_nombre}:${sequence.v_ini ?? ''}:${sequence.v_fin ?? ''}`;

function responseScope(
	sequence: MetricDistributionSequence,
	row: PublicFichaRespuestaMetricaContexto
): ResponseScope {
	const sequenceId = sequenceKey(sequence);
	if (!row.realizacion_id) return { key: `tirada:${sequenceId}`, unit: 'tirada' };

	// Las secciones que reutilizan otra arquitectura son partes complementarias de la unidad raíz
	// (por ejemplo, las dos quintillas de una copla real): se reconstruyen con su padre.
	if (row.realizacion_seccion_arquitectura_referenciada_id) {
		return {
			key: `raiz:${row.realizacion_padre_id ?? row.realizacion_id}`,
			unit: sequence.forma_nombre.toLocaleLowerCase('es')
		};
	}

	// Una realización de sección no referenciada es el alcance que se repite y se cuenta: estancia,
	// mudanza, estribillo... No se eleva automáticamente a toda la composición.
	if (row.realizacion_seccion_id) {
		return {
			key: `seccion:${row.realizacion_id}`,
			unit: (row.realizacion_seccion_nombre ?? 'realización').toLocaleLowerCase('es')
		};
	}

	return {
		key: `raiz:${row.realizacion_id}`,
		unit: sequence.forma_nombre.toLocaleLowerCase('es')
	};
}

function orderedSchemeRows(rows: PublicFichaEsquemaRima[]) {
	return [...rows].sort(
		(a, b) =>
			(a.seccion_orden ?? a.realizacion_seccion_orden ?? a.realizacion_orden ?? Number.MAX_SAFE_INTEGER) -
			(b.seccion_orden ?? b.realizacion_seccion_orden ?? b.realizacion_orden ?? Number.MAX_SAFE_INTEGER)
	);
}

/** Esquemas observados en una secuencia, ya recompuestos en el alcance que define el catálogo. */
export function buildSequenceRhymeSchemeOccurrences(
	sequence: MetricDistributionSequence
): MetricDistributionValue[] {
	const byOccurrence = new Map<string, { rows: PublicFichaEsquemaRima[]; unit: string }>();
	for (const row of sequence.esquemas_rima ?? []) {
		const scope = responseScope(sequence, row);
		const current = byOccurrence.get(scope.key) ?? { rows: [], unit: scope.unit };
		current.rows.push(row);
		byOccurrence.set(scope.key, current);
	}

	const signatures = new Map<string, MetricDistributionValue>();
	for (const occurrence of byOccurrence.values()) {
		const rows = orderedSchemeRows(occurrence.rows);
		const label = rows
			.map((row) => row.notacion ?? row.nombre ?? 'Esquema observado')
			.join(' ');
		const key = `${occurrence.unit}\t${label}`;
		const current = signatures.get(key) ?? {
			label,
			cantidad: 0,
			unidad: occurrence.unit,
			versos: 0
		};
		current.cantidad += 1;
		signatures.set(key, current);
	}

	return [...signatures.values()].sort(
		(a, b) => b.cantidad - a.cantidad || a.label.localeCompare(b.label, 'es')
	);
}

function rhymeSchemes(sequences: MetricDistributionSequence[]): MetricDistributionValue[] {
	const signatures = new Map<string, MetricDistributionValue>();
	for (const sequence of sequences) {
		for (const scheme of buildSequenceRhymeSchemeOccurrences(sequence)) {
			const key = `${scheme.unidad}\t${scheme.label}`;
			const current = signatures.get(key) ?? { ...scheme, cantidad: 0 };
			current.cantidad += scheme.cantidad;
			signatures.set(key, current);
		}
	}
	return [...signatures.values()].sort(
		(a, b) => b.cantidad - a.cantidad || a.label.localeCompare(b.label, 'es')
	);
}

function featureDimensions(sequences: MetricDistributionSequence[]): MetricDistributionDimension[] {
	const featureNames = new Set(
		sequences.flatMap((sequence) => (sequence.rasgos ?? []).map((row) => row.rasgo_nombre))
	);

	return [...featureNames]
		.map((feature): MetricDistributionDimension => {
			const byValue = new Map<string, Map<string, number>>();
			for (const sequence of sequences) {
				for (const row of (sequence.rasgos ?? []).filter((item) => item.rasgo_nombre === feature)) {
					const sequencesWithValue = byValue.get(row.valor_nombre) ?? new Map<string, number>();
					sequencesWithValue.set(sequenceKey(sequence), sequence.n_versos);
					byValue.set(row.valor_nombre, sequencesWithValue);
				}
			}
			const values = [...byValue.entries()]
				.map(([label, matchingSequences]): MetricDistributionValue => ({
					label,
					cantidad: matchingSequences.size,
					unidad: 'tirada',
					versos: [...matchingSequences.values()].reduce((total, value) => total + value, 0)
				}))
				.sort(
					(a, b) => b.versos - a.versos || b.cantidad - a.cantidad || a.label.localeCompare(b.label, 'es')
				);
			return { label: feature, values };
		})
		.sort((a, b) => a.label.localeCompare(b.label, 'es'));
}

function coveredVerseKeys(
	sequence: MetricDistributionSequence,
	row: PublicFichaRespuestaMetricaContexto & { posicion_unidad?: number | null }
): string[] {
	const prefix = sequenceKey(sequence);
	if (row.posicion_unidad !== null && row.posicion_unidad !== undefined) {
		const verse =
			row.realizacion_v_ini !== null
				? row.realizacion_v_ini + row.posicion_unidad - 1
				: `pos:${row.realizacion_id ?? row.eleccion_id}:${row.posicion_unidad}`;
		return [`${prefix}:${verse}`];
	}
	if (row.realizacion_v_ini !== null && row.realizacion_v_fin !== null) {
		return Array.from(
			{ length: Math.max(0, row.realizacion_v_fin - row.realizacion_v_ini + 1) },
			(_, index) => `${prefix}:${row.realizacion_v_ini! + index}`
		);
	}
	if (sequence.v_ini !== undefined && sequence.v_fin !== undefined) {
		return Array.from(
			{ length: Math.max(0, sequence.v_fin - sequence.v_ini + 1) },
			(_, index) => `${prefix}:${sequence.v_ini! + index}`
		);
	}
	return Array.from({ length: sequence.n_versos }, (_, index) => `${prefix}:fallback:${index}`);
}

function metres(sequences: MetricDistributionSequence[]): MetricDistributionValue[] {
	const byMetre = new Map<string, Set<string>>();
	for (const sequence of sequences) {
		for (const row of sequence.metros ?? []) {
			const verses = byMetre.get(row.metro_nombre) ?? new Set<string>();
			for (const key of coveredVerseKeys(sequence, row)) verses.add(key);
			byMetre.set(row.metro_nombre, verses);
		}
	}
	return [...byMetre.entries()]
		.map(([label, verses]): MetricDistributionValue => ({
			label,
			cantidad: verses.size,
			unidad: 'verso',
			versos: verses.size
		}))
		.sort((a, b) => b.cantidad - a.cantidad || a.label.localeCompare(b.label, 'es'));
}

/** Cobertura real de cada metro dentro de una única secuencia. */
export function buildSequenceMetreCoverage(
	sequence: MetricDistributionSequence
): MetricDistributionValue[] {
	return metres([sequence]);
}

function varieties(sequences: MetricDistributionSequence[]): MetricDistributionValue[] {
	const byVariety = new Map<string, Map<string, ResponseScope>>();
	for (const sequence of sequences) {
		for (const row of sequence.variedades ?? []) {
			const occurrences = byVariety.get(row.variedad_nombre) ?? new Map<string, ResponseScope>();
			const scope = responseScope(sequence, row);
			occurrences.set(scope.key, scope);
			byVariety.set(row.variedad_nombre, occurrences);
		}
	}
	return [...byVariety.entries()]
		.map(([label, occurrences]): MetricDistributionValue => {
			const scopes = [...occurrences.values()];
			return {
				label,
				cantidad: scopes.length,
				unidad: scopes[0]?.unit ?? 'realización',
				versos: 0
			};
		})
		.sort((a, b) => b.cantidad - a.cantidad || a.label.localeCompare(b.label, 'es'));
}

export function buildDistributionGroups(
	slices: MetricDistributionSlice[],
	sequences: MetricDistributionSequence[]
): MetricDistributionGroup[] {
	return slices.map((slice): MetricDistributionGroup => {
		const matching = sequences.filter((sequence) => sequence.forma_nombre === slice.forma);
		const byArchitecture = new Map<string, MetricDistributionSequence[]>();
		for (const sequence of matching) {
			const key = sequence.arquitectura_slug ?? sequence.arquitectura_nombre;
			const current = byArchitecture.get(key) ?? [];
			current.push(sequence);
			byArchitecture.set(key, current);
		}

		const arquitecturas = [...byArchitecture.values()]
			.map((architectureSequences): MetricDistributionArchitecture => {
				const first = architectureSequences[0];
				const versos = architectureSequences.reduce((total, sequence) => total + sequence.n_versos, 0);
				return {
					label: first.arquitectura_nombre,
					slug: first.arquitectura_slug ?? null,
					versos,
					porcentaje: porcentaje(versos, slice.versos),
					esquemas: rhymeSchemes(architectureSequences),
					rasgos: featureDimensions(architectureSequences),
					metros: metres(architectureSequences),
					variedades: varieties(architectureSequences)
				};
			})
			.sort((a, b) => b.versos - a.versos || a.label.localeCompare(b.label, 'es'));

		return { ...slice, arquitecturas };
	});
}

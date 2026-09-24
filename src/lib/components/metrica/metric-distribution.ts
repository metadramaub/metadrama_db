// Construye la jerarquía real de la ficha: forma → arquitectura → respuestas observadas.
// Cada dimensión se cuenta en su escala métrica: secuencias, versos o realizaciones concretas.
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
	/** Nombre singular de lo contado: secuencia, soneto, estancia, verso... */
	unidad: string;
	/** Versos cubiertos; se usa además del número de secuencias en los rasgos. */
	versos: number;
}

export interface MetricDistributionDimension {
	label: string;
	/**
	 * En qué se cuenta el rasgo. `verso`: el valor caracteriza los versos que cubre, y se pueden
	 * sumar y repartir en porcentaje. `secuencia`: es un juicio sobre la secuencia entera —«la
	 * mayoría de sus versos riman», «acaba en esdrújulos»— y sumar sus versos sería afirmar de cada
	 * verso lo que solo se dijo del conjunto.
	 */
	escala: 'verso' | 'secuencia';
	values: MetricDistributionValue[];
}

export interface MetricDistributionArchitecture {
	label: string;
	slug: string | null;
	versos: number;
	porcentaje: number;
	/** Secuencias de la arquitectura: el total contra el que se cuentan los rasgos de secuencia. */
	secuencias: number;
	esquemas: MetricDistributionValue[];
	/** Los rasgos que se cuentan en versos —la asonancia—, cada uno con sus valores. */
	rasgos: MetricDistributionDimension[];
	/** Los rasgos de construcción de la secuencia, agrupados por la combinación de cada una. */
	combinaciones: MetricDistributionCombination[];
	/** Los rasgos de secuencia que son una capa —el final acentual—, contados aparte. */
	capas: MetricDistributionDimension[];
	metros: MetricDistributionValue[];
	variedades: MetricDistributionValue[];
}

/**
 * Un tipo de secuencia: la combinación de rasgos de secuencia que tiene, y cuántas la tienen.
 * `rasgos` vacío son las secuencias sin ninguno marcado.
 */
export interface MetricDistributionCombination {
	rasgos: { rasgo: string; valor: string | null }[];
	secuencias: number;
	/**
	 * Versos de esas secuencias: **su extensión, no los versos que tienen el rasgo**. «Rima
	 * esporádica» no dice qué versos riman, pero sí cuánto ocupan las secuencias que la tienen, y
	 * dos secuencias no pesan lo mismo si una es el doble de larga.
	 */
	versos: number;
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
	if (!row.realizacion_id) return { key: `secuencia:${sequenceId}`, unit: 'secuencia' };

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

const escalaDe = (row: PublicFichaRasgo): 'verso' | 'secuencia' =>
	row.rasgo_escala === 'verso' ? 'verso' : 'secuencia';

/** Un rasgo de secuencia que no dice cómo está hecha, sino algo que se le añade. */
const esCapa = (row: PublicFichaRasgo) =>
	escalaDe(row) === 'secuencia' && row.rasgo_naturaleza === 'capa';

/**
 * Los rasgos de secuencia, **agrupados por combinación** y no rasgo a rasgo.
 *
 * Cada secuencia tiene un valor de cada rasgo, y listarlos por separado desmontaba qué va con qué:
 * en los endecasílabos sueltos de una obra con dos secuencias todo salía «1 de 2 · 50 %», y no se
 * sabía si el final esdrújulo iba con la rima esporádica o con la otra. Agrupados, cada línea es un
 * tipo de secuencia de la obra y las líneas suman las secuencias de la forma. Por eso cuentan
 * también las que no tienen ningún rasgo marcado, siempre que alguna de la arquitectura lo tenga.
 *
 * Un rasgo de presencia —el dístico final, el encadenamiento— se nombra solo: «Dístico final»
 * dice lo mismo que «Dístico final: presente».
 *
 * **Solo entran los de construcción.** El final esdrújulo es una capa: un suelto con él no es otra
 * clase de suelto, y va aparte en `featureLayers`.
 */
function featureCombinations(sequences: MetricDistributionSequence[]): MetricDistributionCombination[] {
	const porSecuencia = new Map<
		string,
		{ rasgos: { rasgo: string; valor: string | null }[]; versos: number }
	>();
	for (const sequence of sequences) {
		const rasgos = (sequence.rasgos ?? [])
			.filter((row) => escalaDe(row) === 'secuencia' && !esCapa(row))
			.map((row) => ({
				rasgo: row.rasgo_nombre,
				valor: row.valor_slug === 'presente' ? null : row.valor_nombre
			}));
		const unicos = new Map(rasgos.map((item) => [`${item.rasgo}\t${item.valor ?? ''}`, item]));
		porSecuencia.set(sequenceKey(sequence), {
			rasgos: [...unicos.values()].sort((a, b) => a.rasgo.localeCompare(b.rasgo, 'es')),
			versos: sequence.n_versos
		});
	}
	if (![...porSecuencia.values()].some(({ rasgos }) => rasgos.length > 0)) return [];

	const combinaciones = new Map<string, MetricDistributionCombination>();
	for (const { rasgos, versos } of porSecuencia.values()) {
		const clave = rasgos.map((item) => `${item.rasgo}\t${item.valor ?? ''}`).join('\n');
		const actual = combinaciones.get(clave) ?? { rasgos, secuencias: 0, versos: 0 };
		actual.secuencias += 1;
		actual.versos += versos;
		combinaciones.set(clave, actual);
	}
	return [...combinaciones.values()].sort(
		(a, b) =>
			// Las secuencias sin rasgos, siempre al final: son el resto, no un tipo.
			Number(a.rasgos.length === 0) - Number(b.rasgos.length === 0) ||
			b.secuencias - a.secuencias ||
			a.rasgos.length - b.rasgos.length
	);
}

/**
 * Las capas —el final acentual—: cuántas secuencias de la arquitectura llevan cada valor, y su
 * extensión en `versos`: los de esas secuencias, como en las combinaciones.
 */
function featureLayers(sequences: MetricDistributionSequence[]): MetricDistributionDimension[] {
	const porRasgo = new Map<string, Map<string, Map<string, number>>>();
	for (const sequence of sequences) {
		for (const row of (sequence.rasgos ?? []).filter(esCapa)) {
			const valores = porRasgo.get(row.rasgo_nombre) ?? new Map<string, Map<string, number>>();
			const secuencias = valores.get(row.valor_nombre) ?? new Map<string, number>();
			secuencias.set(sequenceKey(sequence), sequence.n_versos);
			valores.set(row.valor_nombre, secuencias);
			porRasgo.set(row.rasgo_nombre, valores);
		}
	}
	return [...porRasgo.entries()]
		.map(([label, valores]): MetricDistributionDimension => ({
			label,
			escala: 'secuencia',
			values: [...valores.entries()]
				.map(([valor, secuencias]) => ({
					label: valor,
					cantidad: secuencias.size,
					unidad: 'secuencia',
					versos: [...secuencias.values()].reduce((total, versos) => total + versos, 0)
				}))
				.sort((a, b) => b.cantidad - a.cantidad || a.label.localeCompare(b.label, 'es'))
		}))
		.sort((a, b) => a.label.localeCompare(b.label, 'es'));
}

function featureDimensions(sequences: MetricDistributionSequence[]): MetricDistributionDimension[] {
	// **La escala la dice el catálogo**, en cada respuesta (`rasgo_escala`). Sin ella —un JSON
	// guardado antes de que existiera— se cuenta en secuencias, que es lo que nunca falsea.
	// Solo los de verso: los de secuencia van en `featureCombinations`.
	const features = new Map<string, { nombre: string; escala: 'verso' | 'secuencia' }>();
	for (const sequence of sequences) {
		for (const row of sequence.rasgos ?? []) {
			if (escalaDe(row) !== 'verso') continue;
			features.set(row.rasgo_slug, { nombre: row.rasgo_nombre, escala: 'verso' });
		}
	}

	return [...features.entries()]
		.map(([slug, { nombre: feature, escala }]): MetricDistributionDimension => {
			const byValue = new Map<string, Map<string, number>>();
			for (const sequence of sequences) {
				for (const row of (sequence.rasgos ?? []).filter((item) => item.rasgo_slug === slug)) {
					const matching = byValue.get(row.valor_nombre) ?? new Map<string, number>();
					matching.set(sequenceKey(sequence), sequence.n_versos);
					byValue.set(row.valor_nombre, matching);
				}
			}
			const values = [...byValue.entries()]
				.map(([label, matching]): MetricDistributionValue => ({
					label,
					cantidad: matching.size,
					unidad: 'secuencia',
					versos:
						escala === 'verso' ? [...matching.values()].reduce((total, versos) => total + versos, 0) : 0
				}))
				.sort(
					(a, b) => b.versos - a.versos || b.cantidad - a.cantidad || a.label.localeCompare(b.label, 'es')
				);
			return { label: feature, escala, values };
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
					secuencias: new Set(architectureSequences.map(sequenceKey)).size,
					esquemas: rhymeSchemes(architectureSequences),
					rasgos: featureDimensions(architectureSequences),
					combinaciones: featureCombinations(architectureSequences),
					capas: featureLayers(architectureSequences),
					metros: metres(architectureSequences),
					variedades: varieties(architectureSequences)
				};
			})
			.sort((a, b) => b.versos - a.versos || a.label.localeCompare(b.label, 'es'));

		return { ...slice, arquitecturas };
	});
}

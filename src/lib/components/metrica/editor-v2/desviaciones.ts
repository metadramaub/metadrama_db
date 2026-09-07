/**
 * El valor observado de una desviación.
 *
 * Cada dimensión nombra lo observado en su propio vocabulario, y la base exige que la columna
 * corresponda a la dimensión declarada. Aquí vive esa correspondencia una sola vez: qué columna
 * toca, de dónde salen sus opciones y cómo se limpian las demás.
 *
 * Vive fuera del componente porque son funciones puras que merecen prueba. La nota que le dice al
 * editor cuántas sílabas se aparta del metro de la norma, y la comprobación de que la relación
 * declarada y el metro observado no se contradigan, se razonan mejor con casos delante que
 * leyendo un formulario de mil cuatrocientas líneas.
 */
import type { MetricCatalogDomainData, MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import type { MetricDeviationDimension, MetricDeviationDraft } from './sequence-draft';

/** Qué columna guarda lo observado en cada dimensión. */
export const COLUMNAS_OBSERVADAS = {
	metro: 'metro_observado_id',
	rima: 'esquema_rima_observado_id',
	estructura: 'seccion_observada_id',
	repeticion: 'repeticion_observada_id',
	rasgo: 'valor_rasgo_observado_id'
} as const;

/** La columna en que cada dimensión guarda lo observado. */
export type ColumnaObservada = (typeof COLUMNAS_OBSERVADAS)[MetricDeviationDimension];

export type OpcionObservada = {
	id: string;
	label: string;
	/** De qué rasgo es el valor, para agruparlos: «a-e» y «Agudo» no son de lo mismo. */
	grupo?: string;
};

/** La medida que la arquitectura fija para sus versos, cuando fija una sola. */
export type MedidaDeLaNorma = { silabas: number; nombre: string };

/** Lo que se puede haber observado en esa dimensión, ordenado para leerlo. */
export function opcionesObservadas(
	domain: MetricCatalogDomainData,
	dimension: MetricDeviationDimension | '',
	arquitecturaId: string | null,
	secciones: MetricCatalogDomainRow[],
	/** Cuántas sílabas mide el verso que la norma fija, cuando fija una sola. */
	medidaDeLaNorma: number | null = null
): OpcionObservada[] {
	if (!dimension) return [];
	const deLaArquitectura = (filas: MetricCatalogDomainRow[]) =>
		filas.filter((row: MetricCatalogDomainRow) => row.arquitectura_id === arquitecturaId);
	const rows: MetricCatalogDomainRow[] =
		dimension === 'metro'
			? domain.verseModels
			: dimension === 'rima'
				? deLaArquitectura(domain.rhymePatterns)
				: dimension === 'estructura'
					? secciones
					: dimension === 'repeticion'
						? deLaArquitectura(domain.repetitionPatterns)
						: domain.traitValues;
	// Solo hace falta para agrupar los valores de rasgo; quien no los pida puede no traer los rasgos.
	const nombreDelRasgo = new Map(
		(domain.traits ?? []).map((rasgo: MetricCatalogDomainRow) => [
			String(rasgo.rasgo_id),
			String(rasgo.nombre ?? '')
		])
	);
	const opciones = rows
		.filter((row: MetricCatalogDomainRow) => row.activo !== false)
		.map((row: MetricCatalogDomainRow) => ({
			id: String(
				row.metro_id ?? row.esquema_rima_id ?? row.seccion_id ?? row.repeticion_id ?? row.valor_id
			),
			label: String(row.nombre || row.notacion || row.slug || ''),
			grupo:
				dimension === 'rasgo' ? (nombreDelRasgo.get(String(row.rasgo_id)) ?? undefined) : undefined,
			silabas: Number(row.silabas) || null
		}))
		.filter((option) => option.id !== 'undefined' && option.label);

	/**
	 * **Los metros, por cercanía a la medida de la norma.**
	 *
	 * En orden alfabético, una quintilla octosílaba ofrecía «Alejandrino» lo primero y el
	 * heptasílabo —el vecino de verdad— en mitad de la lista. Una desviación de metro es siempre un
	 * metro que la norma no admite, así que filtrar no vale: lo que se puede hacer es poner cerca lo
	 * que está cerca.
	 */
	if (dimension === 'metro' && medidaDeLaNorma) {
		return opciones
			.slice()
			.sort((a, b) => {
				const da = a.silabas === null ? Number.POSITIVE_INFINITY : Math.abs(a.silabas - medidaDeLaNorma);
				const db = b.silabas === null ? Number.POSITIVE_INFINITY : Math.abs(b.silabas - medidaDeLaNorma);
				return da - db || a.label.localeCompare(b.label, 'es');
			})
			.map(({ id, label, grupo }) => ({ id, label, grupo }));
	}

	/** Los valores de rasgo se agrupan por su rasgo, y dentro se leen alfabéticamente. */
	return opciones
		.slice()
		.sort(
			(a, b) =>
				(a.grupo ?? '').localeCompare(b.grupo ?? '', 'es') ||
				a.label.localeCompare(b.label, 'es')
		)
		.map(({ id, label, grupo }) => ({ id, label, grupo }));
}

export function columnaDe(dimension: MetricDeviationDimension): ColumnaObservada {
	return COLUMNAS_OBSERVADAS[dimension];
}

/** Sin dimensión elegida no hay columna donde mirar: la desviación aún no habla de nada. */
export function valorObservado(deviation: MetricDeviationDraft): string {
	if (!deviation.dimension) return '';
	return String(deviation[columnaDe(deviation.dimension)] ?? '');
}

/** Deja puesta solo la columna que corresponde a la dimensión, como exige la base. */
export function fijarValorObservado(deviation: MetricDeviationDraft, value: string): void {
	for (const column of Object.values(COLUMNAS_OBSERVADAS)) {
		deviation[column] = null;
	}
	if (value && deviation.dimension) deviation[columnaDe(deviation.dimension)] = value;
}

/**
 * Las sílabas que la arquitectura fija para sus versos, cuando fija una sola.
 *
 * Sirve para decirle al editor qué diferencia supone el metro que acaba de elegir, sin guardarlo:
 * la hipometría se enseña, no se almacena. Con más de un metro la norma no es una cifra y no hay
 * diferencia que anunciar.
 */
export function medidaDeLaNorma(
	domain: MetricCatalogDomainData,
	arquitecturaId: string | null
): MedidaDeLaNorma | null {
	if (!arquitecturaId) return null;
	const schemeIds = new Set(
		domain.metricPatterns
			.filter((row: MetricCatalogDomainRow) => row.arquitectura_id === arquitecturaId)
			.map((row: MetricCatalogDomainRow) => String(row.esquema_metrico_id))
	);
	if (schemeIds.size === 0) return null;
	const metreIds = new Set(
		domain.metricPositions
			.filter((row: MetricCatalogDomainRow) => schemeIds.has(String(row.esquema_metrico_id)))
			.map((row: MetricCatalogDomainRow) => String(row.metro_id))
	);
	if (metreIds.size !== 1) return null;
	const metre = domain.verseModels.find(
		(row: MetricCatalogDomainRow) => String(row.metro_id) === [...metreIds][0]
	);
	return metre ? { silabas: Number(metre.silabas), nombre: String(metre.nombre) } : null;
}

/**
 * La medida **dominante** de la arquitectura, aunque admita otras.
 *
 * `medidaDeLaNorma` calla en cuanto hay más de un metro, y con razón: sirve para decir «se aparta
 * tres sílabas», y eso no se puede afirmar si la norma admite varias. Para ordenar sí vale saber
 * cuál manda: la quintilla admite ocho, cinco y cuatro, y la que manda es la de ocho.
 *
 * Se toma del rol `dominante` que declara el esquema métrico, y si no lo declara, del metro que más
 * posiciones ocupa.
 */
export function medidaDominante(
	domain: MetricCatalogDomainData,
	arquitecturaId: string | null
): number | null {
	if (!arquitecturaId) return null;
	const schemeIds = new Set(
		domain.metricPatterns
			.filter((row: MetricCatalogDomainRow) => row.arquitectura_id === arquitecturaId)
			.map((row: MetricCatalogDomainRow) => String(row.esquema_metrico_id))
	);
	if (schemeIds.size === 0) return null;
	const silabasDe = (metroId: string) => {
		const metre = domain.verseModels.find(
			(row: MetricCatalogDomainRow) => String(row.metro_id) === metroId
		);
		const silabas = Number(metre?.silabas);
		return Number.isFinite(silabas) && silabas > 0 ? silabas : null;
	};
	const dominante = (domain.metricOptions ?? []).find(
		(row: MetricCatalogDomainRow) =>
			schemeIds.has(String(row.esquema_metrico_id)) && row.rol === 'dominante'
	);
	if (dominante) return silabasDe(String(dominante.metro_id));
	const veces = new Map<string, number>();
	for (const row of domain.metricPositions) {
		if (!schemeIds.has(String(row.esquema_metrico_id))) continue;
		const metroId = String(row.metro_id);
		veces.set(metroId, (veces.get(metroId) ?? 0) + 1);
	}
	let mayor: string | null = null;
	for (const [metroId, cuantas] of veces) {
		if (mayor === null || cuantas > (veces.get(mayor) ?? 0)) mayor = metroId;
	}
	return mayor ? silabasDe(mayor) : null;
}

function metroObservado(
	domain: MetricCatalogDomainData,
	deviation: MetricDeviationDraft
): MetricCatalogDomainRow | undefined {
	if (deviation.dimension !== 'metro' || !deviation.metro_observado_id) return undefined;
	return domain.verseModels.find(
		(row: MetricCatalogDomainRow) => String(row.metro_id) === deviation.metro_observado_id
	);
}

/** «Una sílaba menos que la norma (octosílabo)», calculado en el momento. */
export function notaDelMetroObservado(
	domain: MetricCatalogDomainData,
	deviation: MetricDeviationDraft,
	norma: MedidaDeLaNorma | null
): string {
	const metre = metroObservado(domain, deviation);
	if (!metre) return '';
	const silabas = Number(metre.silabas);
	if (!norma) return `${silabas} sílabas`;
	const diferencia = silabas - norma.silabas;
	if (diferencia === 0) return `${silabas} sílabas · coincide con la norma (${norma.nombre})`;
	const cuantas = Math.abs(diferencia);
	return `${cuantas} ${cuantas === 1 ? 'sílaba' : 'sílabas'} ${
		diferencia < 0 ? 'menos' : 'más'
	} que la norma (${norma.nombre})`;
}

/** ¿Se contradicen la relación declarada y el metro observado? Invariante 2 del plan. */
export function contradiceLaRelacion(
	domain: MetricCatalogDomainData,
	deviation: MetricDeviationDraft,
	norma: MedidaDeLaNorma | null
): boolean {
	const metre = metroObservado(domain, deviation);
	if (!metre || !norma) return false;
	const diferencia = Number(metre.silabas) - norma.silabas;
	if (deviation.relacion_norma === 'menor_que_norma') return diferencia >= 0;
	if (deviation.relacion_norma === 'mayor_que_norma') return diferencia <= 0;
	return false;
}

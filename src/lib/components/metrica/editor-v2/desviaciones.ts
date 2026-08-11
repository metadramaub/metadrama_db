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

export type OpcionObservada = { id: string; label: string };

/** La medida que la arquitectura fija para sus versos, cuando fija una sola. */
export type MedidaDeLaNorma = { silabas: number; nombre: string };

/** Lo que se puede haber observado en esa dimensión, ordenado para leerlo. */
export function opcionesObservadas(
	domain: MetricCatalogDomainData,
	dimension: MetricDeviationDimension,
	arquitecturaId: string | null,
	secciones: MetricCatalogDomainRow[]
): OpcionObservada[] {
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
	return rows
		.filter((row: MetricCatalogDomainRow) => row.activo !== false)
		.map((row: MetricCatalogDomainRow) => ({
			id: String(
				row.metro_id ?? row.esquema_rima_id ?? row.seccion_id ?? row.repeticion_id ?? row.valor_id
			),
			label: String(row.nombre || row.notacion || row.slug || '')
		}))
		.filter((option) => option.id !== 'undefined' && option.label)
		.sort((a, b) => a.label.localeCompare(b.label, 'es'));
}

export function columnaDe(dimension: MetricDeviationDimension): ColumnaObservada {
	return COLUMNAS_OBSERVADAS[dimension];
}

export function valorObservado(deviation: MetricDeviationDraft): string {
	return String(deviation[columnaDe(deviation.dimension)] ?? '');
}

/** Deja puesta solo la columna que corresponde a la dimensión, como exige la base. */
export function fijarValorObservado(deviation: MetricDeviationDraft, value: string): void {
	for (const column of Object.values(COLUMNAS_OBSERVADAS)) {
		deviation[column] = null;
	}
	if (value) deviation[columnaDe(deviation.dimension)] = value;
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

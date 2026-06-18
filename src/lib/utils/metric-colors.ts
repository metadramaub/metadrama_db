// Colores de las formas métricas para el perfil métrico (pie + barcode).
//
// Diseño: cada FORMA RAÍZ (= familia) tiene un color fijo; sus tipos/subtipos
// heredan el de la raíz. Gama CÁLIDA para formas españolas, FRÍA para italianas,
// gris para irregulares/mixtas. El mapa se mantiene por slug (legible); el
// coloreado en runtime es estable porque se indexa por el id de la forma raíz.
//
// Fallback: si una forma no está en el mapa pero conocemos su gama (tipo_forma),
// usa el tono base cálido/frío de esa gama; si la gama es desconocida, gris.

const NEUTRAL = '#8a8a8a';
const WARM_BASE = '#d98b4a'; // ámbar medio: cálido para ESP sin mapear
const COOL_BASE = '#3e6e9e'; // azul medio: frío para ITA sin mapear

// Paleta curada por FRECUENCIA: las formas frecuentes (alto) reciben los matices
// más separados y saturados dentro de su gama (máximo contraste entre ellas); las
// medio/bajo rellenan con tonos más apagados u oscuros, distinguibles pero
// secundarios. Cálidos confinados al arco rojo→ámbar (sin magentas ni amarillos
// verdosos); fríos al arco cian→índigo (sin verdes ni violetas-rosados).
const FORMA_COLOR_BY_SLUG: Record<string, string> = {
	// --- Españolas (cálidos: rojo → naranja → ámbar) ---
	// Frecuentes (alto): alternan matiz Y claridad (oscuro/claro/medio) para que
	// dos contiguas nunca coincidan en luminosidad a la vez.
	quintilla: '#b71c1c', // alto (rojo profundo, oscuro)
	romance: '#ff9d3c', // alto (naranja claro)
	redondilla: '#e07016', // alto (ámbar-naranja medio-oscuro)
	// Medio: tonos intermedios más apagados, separados de las frecuentes.
	decima: '#9c4a1a', // medio (terracota oscura)
	villancico: '#cf9544', // medio (mostaza)
	romancillo: '#d8b86a', // medio (ocre claro)
	seguidilla: '#7a3014', // medio (caoba)
	// Bajo: oscuros, como fondo.
	copla_real: '#d23b2a', // bajo (rojo teja, separado de quintilla)
	romance_heroico: '#5e1810', // bajo (granate)
	copla_de_pie_quebrado: '#b08a5e', // bajo (canela apagado)
	pareado_de_arte_menor: '#4a2a14', // bajo (marrón oscuro)
	// Sin frecuencia en la tabla original: tonos cálidos libres del arco.
	zejel: '#9c3415',
	terceto_octosilabo: '#a86a2e',
	irregular_arte_menor: '#7a5230',
	// --- Italianas (fríos: cian → azul → índigo) ---
	// Frecuentes (alto): alternan matiz Y claridad para que terceto/silva/soneto
	// (azules contiguos) no se fundan. Cian claro / azul oscuro / índigo medio...
	octava_real: '#22c9de', // alto (cian claro)
	endecasilabo_suelto: '#1773a6', // alto (cian-azul oscuro)
	terceto: '#5a8fe6', // alto (azul claro)
	soneto: '#13427a', // alto (azul muy oscuro)
	silva: '#5a4fd4', // alto (índigo medio)
	// Medio: tonos intermedios, separados de las frecuentes.
	cancion_petrarquista: '#8fc4e0', // medio (cian claro pálido)
	sexteto_lira: '#2a2e7a', // medio (índigo oscuro)
	pareado_endecasilabo: '#3a7d92', // medio (azul-teal grisáceo)
	// Bajo: profundos o muy claros, como fondo.
	sextina: '#1733a0', // bajo (azul profundo)
	lira: '#b0a8e8', // bajo (lavanda pálido)
	// --- Mixtas / irregulares (neutro) ---
	irregular: NEUTRAL,
	irregular_mixto: NEUTRAL
};

/** Normaliza una etiqueta o slug a la clave canónica del mapa. */
export function normalizeFormaKey(value: string): string {
	return value
		.normalize('NFD')
		.replaceAll(/\p{M}/gu, '')
		.trim()
		.toLowerCase()
		.replaceAll(/[\s-]+/g, '_');
}

export interface FormaColorInput {
	/** Slug o etiqueta de la forma raíz (se normaliza). */
	slug?: string | null;
	/** tipo_forma de la forma raíz: 'forma_espanola' | 'forma_italiana'. */
	tipoForma?: string | null;
}

/**
 * Color de una forma métrica. Resuelve por el mapa curado (normalizando el
 * slug); si no está, cae al tono base de su gama (tipo_forma); gris si la gama
 * es desconocida.
 */
export function colorForForma({ slug, tipoForma }: FormaColorInput): string {
	if (slug) {
		const mapped = FORMA_COLOR_BY_SLUG[normalizeFormaKey(slug)];
		if (mapped) return mapped;
	}
	if (tipoForma === 'forma_espanola') return WARM_BASE;
	if (tipoForma === 'forma_italiana') return COOL_BASE;
	return NEUTRAL;
}

/**
 * Compatibilidad: color a partir de un único nombre/slug de forma, sin gama.
 * Equivale a colorForForma resolviendo solo por el mapa (gris si no está).
 */
export function colorForMetricKey(key: string): string {
	if (!key) return NEUTRAL;
	return colorForForma({ slug: key });
}

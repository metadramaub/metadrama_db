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

// Paleta curada por FRECUENCIA: las formas frecuentes reciben los matices más separados y
// saturados dentro de su gama (máximo contraste entre ellas); las demás rellenan con tonos más
// apagados u oscuros, distinguibles pero secundarios. Cálidos confinados al arco rojo→ámbar (sin
// magentas ni amarillos verdosos); fríos al arco cian→índigo (sin verdes ni violetas-rosados).
//
// **Están las 41 formas del catálogo y los dos tramos sin forma, y nada más.** Hasta el 7 de
// septiembre de 2026 el mapa hablaba en slugs del vocabulario legado —`romancillo`,
// `copla_de_pie_quebrado`, `pareado_endecasilabo`—, que ya no nombran ninguna forma; y las que
// entraron al catálogo en agosto no tenían color, así que salían en el tono base de su gama y
// todas iguales.
const FORMA_COLOR_BY_SLUG: Record<string, string> = {
	// --- Españolas (cálidos: rojo → naranja → ámbar) ---
	// Las tres frecuentes se llevan los matices más separados y saturados, que son las que
	// dominan cualquier barcode: alternan matiz Y claridad para no fundirse entre sí.
	quintilla: '#b71c1c', // rojo profundo
	romance: '#ff9d3c', // naranja claro
	redondilla: '#e07016', // ámbar-naranja medio
	// Medias.
	decima: '#9c4a1a', // terracota oscura
	seguidilla: '#7a3014', // caoba
	villancico: '#cf9544', // mostaza
	zejel: '#9c3415', // ladrillo
	copla_real: '#d23b2a', // rojo teja
	// Las coplas, en un tramo contiguo del arco para que se lean como familia.
	copla_castellana: '#c25a2e',
	copla_de_arte_mayor: '#8c2f12',
	copla_de_arte_menor: '#b5613a',
	copla_manriquena: '#d4762a',
	// Las estróficas menos frecuentes.
	novena: '#a33a20',
	oncena: '#8a4726',
	septilla: '#d2452a',
	sextilla: '#a85c14',
	pareado: '#6b2a10',
	endecha_real: '#e0a86a',
	// Las enlazadas, en tonos claros: son series, y en el barcode ocupan tiradas largas.
	redondilla_enlazada: '#f0b070',
	septilla_enlazada: '#c98a55',
	sextilla_enlazada: '#e8c090',
	// --- Italianas (fríos: cian → azul → índigo) ---
	// Frecuentes.
	octava_real: '#22c9de', // cian claro
	endecasilabo_suelto: '#1773a6', // cian-azul oscuro
	terceto: '#5a8fe6', // azul claro
	soneto: '#13427a', // azul muy oscuro
	silva: '#5a4fd4', // índigo medio
	terceto_encadenado: '#7aa8f0', // azul claro, hermano del terceto
	// Medias.
	cancion_petrarquista: '#8fc4e0',
	octava_aguda: '#1a9ec4',
	cuarteto: '#4aa8c9',
	sexteto: '#0e5f8a',
	septeto: '#2f8fbf',
	// La serie alirada, en un tramo índigo contiguo: se reconoce como familia.
	lira: '#b0a8e8',
	cuarteto_lira: '#7fb7d9',
	sexteto_lira: '#2a2e7a',
	septeto_lira: '#5566a8',
	octava_lira: '#3f5fb0',
	novena_lira: '#6c74c4',
	decima_lira: '#9aa8e0',
	// Las sextinas, azul profundo.
	sextina: '#1733a0',
	sextina_estrofa: '#2a49b8',
	// --- Tramos sin forma (neutro) ---
	// **No llevan color de gama a propósito**: no pertenecen a ninguna tradición, y en el barcode
	// tienen que leerse como lo que son, un pasaje del que no se afirma forma.
	irregular: NEUTRAL,
	verso_aislado: NEUTRAL
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

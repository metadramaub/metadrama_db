export type WikidataImage = {
	url: string;
	commonsFile: string;
	sourceUrl: string;
};

export type WikidataAuthorData = {
	image: WikidataImage | null;
	birthDateLabel: string | null;
	deathDateLabel: string | null;
};

type CacheEntry = {
	value: WikidataAuthorData | null;
	expiresAt: number;
};

const CACHE_TTL_MS = 24 * 60 * 60 * 1000;
// Un fallo no es una respuesta: si Wikidata no contesta —o nos limita, que es lo habitual desde
// las IP de Vercel— no sabemos si el autor tiene retrato. Se recuerda solo unos minutos, para no
// insistir en cada carga, pero lo bastante poco como para que la foto vuelva sola.
const FAILURE_CACHE_TTL_MS = 5 * 60 * 1000;
const REQUEST_TIMEOUT_MS = 8000;
// Wikimedia exige identificarse: sin User-Agent responde 403, y con uno genérico limita antes.
const USER_AGENT = 'Versologia/1.0 (https://versologia.metadrama.org)';

const cache = new Map<string, CacheEntry>();
const pending = new Map<string, Promise<WikidataAuthorData | null>>();

function normalizeWikidataId(id: string | null | undefined): string | null {
	const normalized = id?.trim().toUpperCase();
	return normalized && /^Q\d+$/.test(normalized) ? normalized : null;
}

function commonsFileUrl(filename: string): string {
	return `https://commons.wikimedia.org/wiki/Special:FilePath/${encodeURIComponent(filename)}?width=480`;
}

function getClaims(payload: unknown, wikidataId: string): Record<string, unknown[]> {
	const entity = (payload as { entities?: Record<string, unknown> }).entities?.[wikidataId] as
		| { claims?: Record<string, unknown[]> }
		| undefined;
	return entity?.claims ?? {};
}

function extractCommonsFile(claims: Record<string, unknown[]>): string | null {
	const imageClaim = claims.P18?.[0] as
		| { mainsnak?: { datavalue?: { value?: unknown } } }
		| undefined;
	const value = imageClaim?.mainsnak?.datavalue?.value;
	return typeof value === 'string' && value.trim() ? value.trim() : null;
}

function extractWikidataTime(claims: Record<string, unknown[]>, property: 'P569' | 'P570'): string | null {
	const claim = claims[property]?.[0] as
		| {
				mainsnak?: {
					datavalue?: {
						value?: { time?: unknown; precision?: unknown };
					};
				};
		  }
		| undefined;
	const value = claim?.mainsnak?.datavalue?.value;
	if (!value || typeof value.time !== 'string') return null;
	return formatWikidataDate(value.time, typeof value.precision === 'number' ? value.precision : null);
}

function formatWikidataDate(time: string, precision: number | null): string | null {
	const match = time.match(/^([+-])(\d+)-(\d{2})-(\d{2})T/);
	if (!match) return null;

	const sign = match[1];
	const year = Number(match[2]);
	const month = Number(match[3]);
	const day = Number(match[4]);
	if (!Number.isFinite(year)) return null;

	const yearLabel = `${year}${sign === '-' ? ' a. C.' : ''}`;
	if (precision === 11 && month >= 1 && month <= 12 && day >= 1 && day <= 31 && sign !== '-') {
		return new Intl.DateTimeFormat('es-ES', {
			day: 'numeric',
			month: 'long',
			year: 'numeric'
		}).format(new Date(Date.UTC(year, month - 1, day)));
	}
	if (precision === 10 && month >= 1 && month <= 12 && sign !== '-') {
		return new Intl.DateTimeFormat('es-ES', {
			month: 'long',
			year: 'numeric'
		}).format(new Date(Date.UTC(year, month - 1, 1)));
	}
	return yearLabel;
}

async function fetchWikidataAuthorData(
	wikidataId: string,
	fetchFn: typeof fetch
): Promise<WikidataAuthorData | null> {
	const response = await fetchFn(
		`https://www.wikidata.org/wiki/Special:EntityData/${wikidataId}.json`,
		{
			headers: { 'User-Agent': USER_AGENT, Accept: 'application/json' },
			signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS)
		}
	);
	// Se lanza en vez de devolver null para que quien cachea distinga «no tiene imagen» de
	// «no he podido preguntar».
	if (!response.ok) throw new Error(`Wikidata respondio ${response.status} para ${wikidataId}`);

	const claims = getClaims(await response.json(), wikidataId);
	const commonsFile = extractCommonsFile(claims);

	return {
		image: commonsFile
			? {
					url: commonsFileUrl(commonsFile),
					commonsFile,
					sourceUrl: `https://www.wikidata.org/wiki/${wikidataId}`
				}
			: null,
		birthDateLabel: extractWikidataTime(claims, 'P569'),
		deathDateLabel: extractWikidataTime(claims, 'P570')
	};
}

export async function getWikidataAuthorData(
	wikidataId: string | null | undefined,
	fetchFn: typeof fetch
): Promise<WikidataAuthorData | null> {
	const normalized = normalizeWikidataId(wikidataId);
	if (!normalized) return null;

	const now = Date.now();
	const cached = cache.get(normalized);
	if (cached && cached.expiresAt > now) return cached.value;

	const existing = pending.get(normalized);
	if (existing) return existing;

	const promise = fetchWikidataAuthorData(normalized, fetchFn)
		.then((value) => ({ value, ttl: CACHE_TTL_MS }))
		.catch(() => ({ value: null, ttl: FAILURE_CACHE_TTL_MS }))
		.then(({ value, ttl }) => {
			cache.set(normalized, { value, expiresAt: Date.now() + ttl });
			pending.delete(normalized);
			return value;
		});

	pending.set(normalized, promise);
	return promise;
}

export async function getWikidataImage(
	wikidataId: string | null | undefined,
	fetchFn: typeof fetch
): Promise<WikidataImage | null> {
	return (await getWikidataAuthorData(wikidataId, fetchFn))?.image ?? null;
}

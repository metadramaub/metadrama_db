export interface AuthorFormDraft {
	nombreCompleto: string;
	nombreNormalizado: string;
	variantesText: string;
	bnedatosId: string;
	viafId: string;
	wikidataId: string;
}

export interface AuthorFormSnapshot {
	nombreCompleto: string;
	nombreNormalizado: string;
	variantesNombre: string[];
	bnedatosId: string;
	viafId: string;
	wikidataId: string;
}

type PersistedAuthorFormSource = {
	nombre_completo?: string | null;
	nombre_normalizado?: string | null;
	variantes_nombre?: ReadonlyArray<unknown> | null;
	bnedatos_id?: string | null;
	viaf_id?: string | null;
	wikidata_id?: string | null;
};

function normalizeVariantTerm(value: string): string {
	return value.normalize('NFD').replaceAll(/\p{M}/gu, '').trim().toLowerCase();
}

function normalizeOptionalText(value: unknown): string {
	if (typeof value !== 'string') return '';
	return value.trim();
}

function normalizeVariants(values: ReadonlyArray<unknown>): string[] {
	const deduped = new Map<string, string>();
	for (const rawValue of values) {
		if (typeof rawValue !== 'string') continue;
		const trimmed = rawValue.trim();
		if (!trimmed) continue;
		const normalized = normalizeVariantTerm(trimmed);
		if (!normalized || deduped.has(normalized)) continue;
		deduped.set(normalized, trimmed);
	}
	return [...deduped.values()];
}

export function splitAuthorVariantsText(text: string): string[] {
	return text
		.split('\n')
		.map((item) => item.trim())
		.filter(Boolean);
}

export function buildAuthorPersistedSnapshot(
	source: PersistedAuthorFormSource
): AuthorFormSnapshot {
	return {
		nombreCompleto: normalizeOptionalText(source.nombre_completo),
		nombreNormalizado: normalizeOptionalText(source.nombre_normalizado),
		variantesNombre: normalizeVariants(source.variantes_nombre ?? []),
		bnedatosId: normalizeOptionalText(source.bnedatos_id),
		viafId: normalizeOptionalText(source.viaf_id),
		wikidataId: normalizeOptionalText(source.wikidata_id)
	};
}

export function buildAuthorDraftSnapshot(draft: AuthorFormDraft): AuthorFormSnapshot {
	return {
		nombreCompleto: normalizeOptionalText(draft.nombreCompleto),
		nombreNormalizado: normalizeOptionalText(draft.nombreNormalizado),
		variantesNombre: normalizeVariants(splitAuthorVariantsText(draft.variantesText)),
		bnedatosId: normalizeOptionalText(draft.bnedatosId),
		viafId: normalizeOptionalText(draft.viafId),
		wikidataId: normalizeOptionalText(draft.wikidataId)
	};
}

export function areAuthorSnapshotsEqual(
	left: AuthorFormSnapshot,
	right: AuthorFormSnapshot
): boolean {
	return (
		left.nombreCompleto === right.nombreCompleto &&
		left.nombreNormalizado === right.nombreNormalizado &&
		left.bnedatosId === right.bnedatosId &&
		left.viafId === right.viafId &&
		left.wikidataId === right.wikidataId &&
		left.variantesNombre.length === right.variantesNombre.length &&
		left.variantesNombre.every((item, idx) => item === right.variantesNombre[idx])
	);
}

export function isAuthorFormDirty(
	source: PersistedAuthorFormSource,
	draft: AuthorFormDraft
): boolean {
	const baseSnapshot = buildAuthorPersistedSnapshot(source);
	const draftSnapshot = buildAuthorDraftSnapshot(draft);
	return !areAuthorSnapshotsEqual(baseSnapshot, draftSnapshot);
}

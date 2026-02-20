import { describe, expect, it } from 'vitest';
import {
	areAuthorSnapshotsEqual,
	buildAuthorDraftSnapshot,
	buildAuthorPersistedSnapshot,
	isAuthorFormDirty,
	splitAuthorVariantsText,
	type AuthorFormDraft
} from './author-form';

const baseAuthor = {
	nombre_completo: 'Lope de Vega',
	variantes_nombre: ['Fenix de los Ingenios'],
	bnedatos_id: 'BNE-1',
	viaf_id: 'VIAF-1',
	wikidata_id: 'Q1'
};

function createDraft(overrides: Partial<AuthorFormDraft> = {}): AuthorFormDraft {
	return {
		nombreCompleto: 'Lope de Vega',
		variantesText: 'Fenix de los Ingenios',
		bnedatosId: 'BNE-1',
		viafId: 'VIAF-1',
		wikidataId: 'Q1',
		...overrides
	};
}

describe('author-form', () => {
	it('splits variants text by line and trims blanks', () => {
		expect(splitAuthorVariantsText('Lope\n\n Calderon \n')).toEqual(['Lope', 'Calderon']);
	});

	it('keeps form clean when snapshots are equivalent', () => {
		const dirty = isAuthorFormDirty(baseAuthor, createDraft());
		expect(dirty).toBe(false);
	});

	it('marks form as dirty for content changes in any field', () => {
		expect(isAuthorFormDirty(baseAuthor, createDraft({ nombreCompleto: 'Lope Felix de Vega' }))).toBe(
			true
		);
		expect(isAuthorFormDirty(baseAuthor, createDraft({ bnedatosId: 'BNE-2' }))).toBe(true);
		expect(isAuthorFormDirty(baseAuthor, createDraft({ viafId: 'VIAF-2' }))).toBe(true);
		expect(isAuthorFormDirty(baseAuthor, createDraft({ wikidataId: 'Q2' }))).toBe(true);
		expect(
			isAuthorFormDirty(baseAuthor, createDraft({ variantesText: 'Fenix de los Ingenios\nAlias extra' }))
		).toBe(true);
	});

	it('dedupes variants by normalized key preserving first visible value', () => {
		const snapshot = buildAuthorDraftSnapshot(
			createDraft({
				variantesText: 'Lópe\nope\nLOPE\n  \nLópe  '
			})
		);
		expect(snapshot.variantesNombre).toEqual(['Lópe', 'ope']);
	});

	it('ignores non-string persisted variants without throwing', () => {
		const snapshot = buildAuthorPersistedSnapshot({
			...baseAuthor,
			variantes_nombre: ['Lope', null, 123, 'LOPE'] as unknown[]
		});
		expect(snapshot.variantesNombre).toEqual(['Lope']);
		expect(
			isAuthorFormDirty(
				{
					...baseAuthor,
					variantes_nombre: ['Lope', null, 123, 'LOPE'] as unknown[]
				},
				createDraft({ variantesText: 'Lope' })
			)
		).toBe(false);
	});

	it('compares snapshots with deterministic equality', () => {
		const left = buildAuthorPersistedSnapshot(baseAuthor);
		const right = buildAuthorDraftSnapshot(createDraft());
		expect(areAuthorSnapshotsEqual(left, right)).toBe(true);
	});
});

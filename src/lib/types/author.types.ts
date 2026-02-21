import type { Tables } from '$lib/types/database.types';

export interface AuthorBaseInput {
	nombre_completo: string;
	nombre_normalizado: string;
	variantes_nombre?: string[] | null;
	bnedatos_id?: string | null;
	viaf_id?: string | null;
	wikidata_id?: string | null;
}

export interface AuthorCreateInput extends AuthorBaseInput {}

export interface AuthorPatchInput {
	nombre_completo?: string;
	nombre_normalizado?: string;
	variantes_nombre?: string[] | null;
	bnedatos_id?: string | null;
	viaf_id?: string | null;
	wikidata_id?: string | null;
}

export interface AuthorDeleteInput {
	confirmText: string;
}

export interface AuthorWorkSummary {
	obra_id: string;
	titulo: string;
	updated_at: string | null;
}

export interface AuthorListItem extends Tables<'autores'> {
	works_count: number;
}

export interface AuthorDetailResponse {
	autor: Tables<'autores'>;
	works_count: number;
	obras: AuthorWorkSummary[];
}

import type { SecuenciaVariacionInput } from '$lib/types/obra.types';
import type { Tables } from '$lib/types/database.types';

const ALLOWED_TIPO_VARIACION_TERMS = new Set([
	'cantado',
	'irregular',
	'hipometrico',
	'hipermetrico',
	'rima_defectuosa',
	'laguna',
	'prosa'
]);

const SINGLE_VERSE_TERMS = new Set(['hipometrico', 'hipermetrico']);

function sanitizeToken(value: string): string {
	return value
		.normalize('NFD')
		.replaceAll(/\p{M}/gu, '')
		.toLowerCase()
		.trim()
		.replaceAll(/[\s-]+/g, '_');
}

export function normalizeTipoVariacionTerm(term: string): string {
	const normalized = sanitizeToken(term);

	if (normalized === 'irregular/hipometrico') return 'hipometrico';
	if (normalized === 'irregular/hipermetrico') return 'hipermetrico';

	return normalized;
}

export function validateSecuenciaVariacionContext(args: {
	secuencia: Pick<Tables<'secuencias_metricas'>, 'v_ini' | 'v_fin'>;
	tipoTerm: string;
	payload: Pick<SecuenciaVariacionInput, 'v_ini' | 'v_fin'>;
}): string | null {
	const { secuencia, tipoTerm, payload } = args;

	if (payload.v_ini > payload.v_fin) {
		return 'El verso inicial no puede ser mayor que el final.';
	}

	if (payload.v_ini < secuencia.v_ini || payload.v_fin > secuencia.v_fin) {
		return `El rango de la variacion debe quedar dentro de la secuencia (${secuencia.v_ini}-${secuencia.v_fin}).`;
	}

	const normalizedTerm = normalizeTipoVariacionTerm(tipoTerm);
	if (!ALLOWED_TIPO_VARIACION_TERMS.has(normalizedTerm)) {
		return 'Tipo de variacion no permitido.';
	}

	if (normalizedTerm === 'irregular') {
		return 'El tipo "irregular" es solo agrupador y no se puede guardar como variacion.';
	}

	if (normalizedTerm === 'prosa' && payload.v_ini >= payload.v_fin) {
		return 'Para "prosa", v_ini debe ser menor que v_fin.';
	}

	if (SINGLE_VERSE_TERMS.has(normalizedTerm) && payload.v_ini !== payload.v_fin) {
		return `Para "${normalizedTerm}", v_ini y v_fin deben ser iguales.`;
	}

	return null;
}

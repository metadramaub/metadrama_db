import type { SecuenciaCaracterizacionRangoInput } from '$lib/types/obra.types';
import type { Tables } from '$lib/types/database.types';

const SINGLE_VERSE_TERMS = new Set(['hipometrico', 'hipermetrico']);

function sanitizeToken(value: string): string {
	return value
		.normalize('NFD')
		.replaceAll(/\p{M}/gu, '')
		.toLowerCase()
		.trim()
		.replaceAll(/[\s-]+/g, '_');
}

export function normalizeCaracterizacionRangoTerm(term: string): string {
	const normalized = sanitizeToken(term);

	if (normalized === 'irregularidades_metricas/hipometrico') return 'hipometrico';
	if (normalized === 'irregularidades_metricas/hipermetrico') return 'hipermetrico';

	return normalized;
}

export function validateSecuenciaCaracterizacionRangoContext(args: {
	secuencia: Pick<Tables<'secuencias_metricas'>, 'v_ini' | 'v_fin'>;
	tipo: Pick<Tables<'vocabularios'>, 'termino' | 'termino_padre_id'>;
	payload: Pick<SecuenciaCaracterizacionRangoInput, 'v_ini' | 'v_fin'>;
}): string | null {
	const { secuencia, tipo, payload } = args;

	if (payload.v_ini > payload.v_fin) {
		return 'El verso inicial no puede ser mayor que el final.';
	}

	if (payload.v_ini < secuencia.v_ini || payload.v_fin > secuencia.v_fin) {
		return `El rango de la caracterizacion debe quedar dentro de la secuencia (${secuencia.v_ini}-${secuencia.v_fin}).`;
	}

	if (!tipo.termino_padre_id) {
		return 'Este termino es solo agrupador y no se puede guardar como caracterizacion.';
	}

	const normalizedTerm = normalizeCaracterizacionRangoTerm(tipo.termino);
	if (normalizedTerm === 'prosa' && payload.v_ini >= payload.v_fin) {
		return 'Para "prosa", v_ini debe ser menor que v_fin.';
	}

	if (SINGLE_VERSE_TERMS.has(normalizedTerm) && payload.v_ini !== payload.v_fin) {
		return `Para "${normalizedTerm}", v_ini y v_fin deben ser iguales.`;
	}

	return null;
}

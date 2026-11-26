export type EnunciationType = 'cantado' | 'prosa' | 'evocacion_metrica';

/** Referencias entre las que se inserta prosa; no expresan su longitud. */
export type ProseLocation = { v_anterior: number; v_posterior: number };

type Rango = { v_ini: number; v_fin: number };

/** El lado se lee con respecto a la secuencia a la que pertenece la marca. */
export function ladoDeProsa(rango: Rango, marca: Rango): 'antes' | 'despues' | null {
	if (marca.v_fin !== marca.v_ini + 1) return null;
	if (marca.v_fin === rango.v_ini) return 'antes';
	if (marca.v_ini === rango.v_fin) return 'despues';
	return null;
}

export function enunciationType(value: string): EnunciationType | null {
	const normalized = value
		.normalize('NFD')
		.replace(/[\u0300-\u036f]/g, '')
		.replaceAll(' ', '_')
		.toLocaleLowerCase('es');
	return ['cantado', 'prosa', 'evocacion_metrica'].includes(normalized)
		? (normalized as EnunciationType)
		: null;
}

export function enunciationPassageLabel(value: string) {
	switch (enunciationType(value)) {
		case 'cantado':
			return 'Pasaje cantado';
		case 'prosa':
			return 'Pasaje en prosa';
		case 'evocacion_metrica':
			return 'Evocación métrica';
		default:
			return value;
	}
}

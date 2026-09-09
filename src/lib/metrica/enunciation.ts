export type EnunciationType = 'cantado' | 'prosa' | 'evocacion_metrica';

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

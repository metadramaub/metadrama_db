import { enunciationType, type EnunciationType } from './enunciation';

export interface PhenomenonSequence {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	forma_nombre: string;
	caracterizaciones_rango: {
		caracterizacion_rango_id: string;
		tipo_caracterizacion_rango_term: string;
		v_ini: number;
		v_fin: number;
	}[];
	desviaciones: unknown[];
	versos_partidos: boolean | null;
	inaugura_espacio: boolean | null;
	intervencion_personajes_femeninos: string | null;
	intervencion_figuras_donaire: string | null;
	intervencion_personajes_sobrenaturales: string | null;
	evento_sobrenatural: boolean | null;
}

export interface PhenomenonItem {
	id: string;
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	forma: string;
	detalle: string | null;
}

export interface PhenomenonGroup {
	id: string;
	label: string;
	items: PhenomenonItem[];
}

const GROUPS: { id: string; label: string }[] = [
	{ id: 'cantado', label: 'Canto' },
	{ id: 'prosa', label: 'Prosa' },
	{ id: 'evocacion_metrica', label: 'Evocación métrica' },
	{ id: 'desviaciones', label: 'Desviaciones' },
	{ id: 'versos_partidos', label: 'Versos repartidos' },
	{ id: 'inaugura_espacio', label: 'Cambios de espacio' },
	{ id: 'personajes_femeninos', label: 'Intervenciones femeninas' },
	{ id: 'figuras_donaire', label: 'Figuras de donaire' },
	{ id: 'personajes_sobrenaturales', label: 'Personajes sobrenaturales' },
	{ id: 'eventos_sobrenaturales', label: 'Eventos sobrenaturales' }
];

function interventionLabel(value: string | null) {
	if (value === 'exclusiva') return 'Exclusiva';
	if (value === 'compartida') return 'Compartida';
	return null;
}

export function buildPhenomenaIndex(sequences: PhenomenonSequence[]): PhenomenonGroup[] {
	const items = new Map<string, PhenomenonItem[]>();
	const add = (groupId: string, item: PhenomenonItem) =>
		items.set(groupId, [...(items.get(groupId) ?? []), item]);

	for (const sequence of sequences) {
		const base = {
			secuencia_id: sequence.secuencia_id,
			v_ini: sequence.v_ini,
			v_fin: sequence.v_fin,
			forma: sequence.forma_nombre,
			detalle: null
		};

		for (const range of sequence.caracterizaciones_rango ?? []) {
			const type: EnunciationType | null = enunciationType(
				range.tipo_caracterizacion_rango_term
			);
			if (!type) continue;
			add(type, {
				...base,
				id: range.caracterizacion_rango_id,
				v_ini: range.v_ini,
				v_fin: range.v_fin
			});
		}

		if ((sequence.desviaciones ?? []).length > 0) {
			add('desviaciones', {
				...base,
				id: `${sequence.secuencia_id}:desviaciones`,
				detalle: `${sequence.desviaciones.length} ${sequence.desviaciones.length === 1 ? 'desviación' : 'desviaciones'}`
			});
		}
		if (sequence.versos_partidos) add('versos_partidos', { ...base, id: `${sequence.secuencia_id}:versos_partidos` });
		if (sequence.inaugura_espacio) add('inaugura_espacio', { ...base, id: `${sequence.secuencia_id}:inaugura_espacio` });

		const femeninos = interventionLabel(sequence.intervencion_personajes_femeninos);
		if (femeninos) add('personajes_femeninos', { ...base, id: `${sequence.secuencia_id}:femeninos`, detalle: femeninos });
		const donaire = interventionLabel(sequence.intervencion_figuras_donaire);
		if (donaire) add('figuras_donaire', { ...base, id: `${sequence.secuencia_id}:donaire`, detalle: donaire });
		const sobrenaturales = interventionLabel(sequence.intervencion_personajes_sobrenaturales);
		if (sobrenaturales) add('personajes_sobrenaturales', { ...base, id: `${sequence.secuencia_id}:sobrenaturales`, detalle: sobrenaturales });
		if (sequence.evento_sobrenatural) add('eventos_sobrenaturales', { ...base, id: `${sequence.secuencia_id}:evento_sobrenatural` });
	}

	return GROUPS.map((group) => ({ ...group, items: items.get(group.id) ?? [] })).filter(
		(group) => group.items.length > 0
	);
}

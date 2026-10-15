import { enunciationType } from '$lib/metrica/enunciation';

export interface CantoMarker {
	id: string;
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
}

/** Une anotaciones solapadas o contiguas dentro de cada secuencia, sin perder su enlace. */
export function rangosCantados(secuencias: {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	caracterizaciones: { tipo: string; v_ini: number; v_fin: number }[];
}[]): CantoMarker[] {
	return secuencias.flatMap((s) => {
		const rangos = s.caracterizaciones
			.filter((c) => enunciationType(c.tipo) === 'cantado')
			.map((c) => ({ v_ini: Math.max(s.v_ini, c.v_ini), v_fin: Math.min(s.v_fin, c.v_fin) }))
			.filter((c) => c.v_ini <= c.v_fin)
			.sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
		const unidos: { v_ini: number; v_fin: number }[] = [];
		for (const rango of rangos) {
			const anterior = unidos.at(-1);
			if (anterior && rango.v_ini <= anterior.v_fin + 1) anterior.v_fin = Math.max(anterior.v_fin, rango.v_fin);
			else unidos.push({ ...rango });
		}
		return unidos.map((r) => ({ ...r, secuencia_id: s.secuencia_id, id: `${s.secuencia_id}:${r.v_ini}-${r.v_fin}` }));
	});
}

export function versoDeCanto(marker: Pick<CantoMarker, 'v_ini' | 'v_fin'>) {
	return marker.v_ini === marker.v_fin ? `v. ${marker.v_ini}` : `vv. ${marker.v_ini}–${marker.v_fin}`;
}

/** Posiciones en píxeles: la flecha apunta al rango real y la nota permanece dentro del lienzo. */
export function colocarCantos(markers: CantoMarker[], desde: number, hasta: number, ancho: number, rotulos = false) {
	const finales: number[] = [];
	const items = markers
		.filter((m) => m.v_ini <= hasta && m.v_fin >= desde)
		.map((m) => ({ ...m, v_ini: Math.max(m.v_ini, desde), v_fin: Math.min(m.v_fin, hasta) }))
		.sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin)
		.map((marker) => {
			const label = versoDeCanto(marker);
			const targetX = ((marker.v_ini + marker.v_fin + 1) / 2 - desde) / Math.max(1, hasta - desde + 1) * ancho;
			const width = Math.min(ancho, rotulos ? 28 + label.length * 6.5 : 24);
			const left = Math.max(0, Math.min(ancho - width, targetX - (rotulos ? 8 : 12)));
			let lane = finales.findIndex((fin) => fin + 6 <= left);
			if (lane === -1) lane = finales.length;
			finales[lane] = left + width;
			return { ...marker, label, targetX, left, x: left + (rotulos ? 8 : 12), lane };
		});
	return { items, lanes: finales.length };
}

import { TRAMAS_GRISES, type TramaFigura } from '$lib/figuras/tramas';
import type { MetricBarSegment } from './metric-display.types';
import type { FilaDeBarras } from './MetricBarcodeFigura.svelte';

const clave = (segmento: MetricBarSegment) => segmento.colorKey ?? segmento.forma;

/** Repertorio de lo visible, en orden de primera aparición, compartido por rótulos y leyenda. */
export function formasDeFilas(filas: FilaDeBarras[]) {
	const formas = new Map<string, { clave: string; forma: string; numero: number }>();
	for (const fila of filas) {
		for (const segmento of [...fila.segmentos].sort((a, b) => a.v_ini - b.v_ini)) {
			if (segmento.v_fin < fila.desde || segmento.v_ini > fila.hasta) continue;
			const id = clave(segmento);
			if (!formas.has(id)) formas.set(id, { clave: id, forma: segmento.forma, numero: formas.size + 1 });
		}
	}
	return [...formas.values()];
}


/** Las formas con tramos más cortos reciben antes los contrastes lisos, legibles sin textura. */
export function tramasDeFormas(filas: FilaDeBarras[]): Record<string, TramaFigura> {
	const minimos = new Map<string, number>();
	for (const fila of filas) for (const s of fila.segmentos) {
		if (s.v_fin < fila.desde || s.v_ini > fila.hasta) continue;
		const longitud = Math.min(s.v_fin, fila.hasta) - Math.max(s.v_ini, fila.desde) + 1;
		minimos.set(clave(s), Math.min(minimos.get(clave(s)) ?? Infinity, longitud));
	}
	return Object.fromEntries([...minimos].sort((a, b) => a[1] - b[1]).map(([id], i) => [id, TRAMAS_GRISES[i % TRAMAS_GRISES.length]]));
}

/** Solo los números que no caben salen fuera; el resto permanece centrado dentro del tramo. */
export function numerosDeFila(fila: FilaDeBarras, ancho: number, repertorio = formasDeFilas([fila])) {
	const visibles = [...fila.segmentos].filter((s) => s.v_fin >= fila.desde && s.v_ini <= fila.hasta).sort((a, b) => a.v_ini - b.v_ini);
	const numeros = new Map(repertorio.map((f) => [f.clave, f.numero]));
	const finales: number[] = [];
	const items = visibles.map((segmento) => {
		const izquierda = (Math.max(segmento.v_ini, fila.desde) - fila.desde) / (fila.hasta + 1 - fila.desde) * ancho;
		const derecha = (Math.min(segmento.v_fin, fila.hasta) + 1 - fila.desde) / (fila.hasta + 1 - fila.desde) * ancho;
		const numero = numeros.get(clave(segmento)) ?? 0;
		const origen = (izquierda + derecha) / 2;
		const exterior = derecha - izquierda < String(numero).length * 6.5 + 8;
		let nivel = 0;
		let x = origen;
		if (exterior) {
			while (true) {
				x = Math.max(8, Math.min(ancho - 8, origen), (finales[nivel] ?? -12) + 20);
				if (x <= ancho - 8 && Math.abs(x - origen) <= 12) break;
				nivel++;
			}
			finales[nivel] = x;
		}
		return { segmento, numero, origen, x, exterior, nivel };
	});
	return { items, alto: finales.length ? finales.length * 18 + 5 : 0 };
}

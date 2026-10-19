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

/** Separa los rótulos; las guías conservan siempre el centro exacto del tramo de origen. */
export function rotulosDeFila(fila: FilaDeBarras, ancho: number, numeros: boolean) {
	const visibles = [...fila.segmentos]
		.filter((s) => s.v_fin >= fila.desde && s.v_ini <= fila.hasta)
		.sort((a, b) => a.v_ini - b.v_ini);
	if (!visibles.length) return { items: [], alto: 0 };
	const largo = numeros ? 0 : Math.max(...visibles.map((s) => s.forma.length * 6));
	const proyeccion = largo / Math.sqrt(2);
	const util = Math.max(20, ancho - proyeccion - 8);
	const separacion = numeros ? 22 : 20;
	const capacidad = Math.max(1, Math.floor(util / separacion));
	const niveles = Math.ceil(visibles.length / capacidad);
	const pasoY = numeros ? 34 : proyeccion + 34;
	const items = visibles.map((segmento, i) => {
		const centro = (Math.max(segmento.v_ini, fila.desde) + Math.min(segmento.v_fin, fila.hasta) + 1) / 2;
		return { segmento, origen: (centro - fila.desde) / (fila.hasta + 1 - fila.desde) * ancho,
			x: 0, y: 18 + (i % niveles) * pasoY };
	});
	for (let nivel = 0; nivel < niveles; nivel++) {
		const grupo = items.filter((_, i) => i % niveles === nivel);
		let anterior = -separacion;
		for (const item of grupo) {
			item.x = Math.max(anterior + separacion, Math.min(util, item.origen));
			anterior = item.x;
		}
		let siguiente = util + separacion;
		for (const item of [...grupo].reverse()) {
			item.x = Math.min(item.x, siguiente - separacion);
			siguiente = item.x;
		}
	}
	return { items, alto: niveles * pasoY + 8 };
}

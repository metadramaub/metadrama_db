import { metrosImportador, rasgosImportador } from './catalogo';
import type { FilaVistaPrevia } from './types';

export type DatoMetricoVisible = { etiqueta: string; valor: string };

/** Solo datos estructurados del documento mínimo; un literal por sí solo no es un rasgo anotado. */
export function datosMetricos(fila: FilaVistaPrevia): DatoMetricoVisible[] {
	const datos: DatoMetricoVisible[] = [];
	for (const d of fila.detalles_fuente) {
		if (d.rasgo_slug) {
			const rasgo = rasgosImportador.find((r) => r.slug === d.rasgo_slug);
			datos.push({
				etiqueta: rasgo?.nombre ?? String(d.rasgo_slug),
				valor: rasgo?.valores.find((v) => v.slug === d.valor_slug)?.nombre ?? String(d.valor_slug)
			});
		} else if (d.tipo_seccion === 'remate') {
			datos.push({etiqueta: 'Remate final', valor: `${d.n_versos} ${d.n_versos === 1 ? 'verso' : 'versos'}${fila.identificacion?.forma_slug === 'terceto_encadenado' && d.n_versos === 1 ? ' (3+1)' : ''}`});
		}
	}
	for (const d of fila.desviaciones) {
		const rango = d.v_ini === d.v_fin ? `v. ${d.v_ini}` : `vv. ${d.v_ini}–${d.v_fin}`;
		const relaciones: Record<string, string> = {
			sobra: 'Sobra', falta: 'Falta', menor_que_norma: 'Mide menos que la norma',
			mayor_que_norma: 'Mide más que la norma', otra: 'Otra desviación'
		};
		const metro = metrosImportador.find((m) => m.slug === d.metro_observado_slug)?.nombre ?? d.metro_observado_slug;
		datos.push({
			etiqueta: d.dimension === 'metro' ? 'Desviación de metro' : 'Desviación estructural',
			valor: `${rango}: ${relaciones[String(d.relacion_norma)] ?? String(d.relacion_norma)}${metro ? ' · ' + String(metro) : ''}`
		});
	}
	return datos;
}

/** Las notas de fuente y de revisión siguen siendo texto, aunque acompañen a un dato métrico. */
export function notasMetricas(fila: FilaVistaPrevia): string[] {
	return [...new Set([
		...fila.detalles_fuente.filter((d) => !d.rasgo_slug && d.tipo_seccion !== 'remate')
			.map((d) => (d.dimension === 'asonancia' ? 'Asonancia en la fuente: ' : '') + String(d.literal)),
		...(fila.notas_fuente ?? []).map((n) => n.texto_literal),
		...fila.desviaciones.flatMap((d) => [d.texto_fuente, d.nota]),
		fila.nota
	].filter((n): n is string => typeof n === 'string' && Boolean(n.trim())))];
}

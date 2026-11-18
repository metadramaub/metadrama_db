import { z } from 'zod';
import { correccionFuenteSchema } from '../../../../scripts/lib/importador-metrico/ficha-minima.mjs';
import type { BorradorFichaMinima, FilaRevisionFuente } from '$lib/importador-metrico/types';

const enteroOpcional = z.number().int().nullable();
const filaSchema = z.object({
	id: z.string().min(1),
	denominacion_literal: z.string().nullable(),
	pagina: enteroOpcional,
	v_ini: enteroOpcional,
	v_fin: enteroOpcional,
	n_versos_fuente: enteroOpcional
});
const revisionSchema = z.object({
	correcciones: z.array(correccionFuenteSchema),
	finales: z.string().max(2000).trim()
}).strict();

export const revisionVacia = { correcciones: [], finales: '' };

export function filasDeRevision(tramos: unknown): FilaRevisionFuente[] {
	if (!Array.isArray(tramos)) return [];
	return tramos.flatMap(tramo => {
		const fila = filaSchema.safeParse(tramo);
		return fila.success ? [fila.data] : [];
	});
}

export function revisarFuente(fuente: Record<string, unknown>, cambios: unknown, filas: FilaRevisionFuente[]) {
	const revision = revisionSchema.safeParse(cambios);
	if (!revision.success)
		throw new Error('Cada corrección necesita extremos válidos y un motivo de hasta 2000 caracteres.');
	const { correcciones, finales } = revision.data;
	const porRef = new Map(correcciones.map(c => [c.tramo_ref, c]));
	const originales = new Map(filas.map(fila => [fila.id, fila]));
	if (porRef.size !== correcciones.length) throw new Error('Cada fila admite una sola corrección.');
	for (const c of correcciones) {
		const original = originales.get(c.tramo_ref);
		if (!original) throw new Error('La fila que intentas corregir no figura en la transcripción.');
		if (c.v_fin < c.v_ini || (c.n_versos_fuente !== null && c.n_versos_fuente !== c.v_fin - c.v_ini + 1))
			throw new Error('El recuento de la corrección de ' + c.tramo_ref + ' debe coincidir con su rango inclusivo.');
		if (c.v_ini === original.v_ini && c.v_fin === original.v_fin && c.n_versos_fuente === original.n_versos_fuente)
			throw new Error('La corrección de ' + c.tramo_ref + ' repite las cifras originales.');
	}
	if (!porRef.size || !Array.isArray(fuente.tramos)) return { fuente, porRef, finales };
	const tramos = fuente.tramos.map((t: Record<string, unknown> | null) => {
		const cambio = typeof t?.id === 'string' ? porRef.get(t.id) : null;
		if (!cambio) return t;
		const { v_ini, v_fin, n_versos_fuente } = cambio;
		return { ...t, v_ini, v_fin, n_versos_fuente };
	});
	return { fuente: { ...fuente, tramos }, porRef, finales };
}

/** Cada jornada cubre filas enteras. Una fila que cruce el límite se divide primero en la vista previa. */
export function jornadasRevisadas(ficha: BorradorFichaMinima, texto: string): BorradorFichaMinima['jornadas'] {
	if (!/^[1-9]\d*(?:[,\s]+[1-9]\d*)*$/u.test(texto))
		throw new Error('Introduce los versos finales de las jornadas, separados por comas o espacios.');
	const finales = texto.split(/[,\s]+/u).map(Number);
	const filas = ficha.segmentos;
	if (finales.at(-1) !== filas.at(-1)?.v_fin)
		throw new Error('La última jornada debe terminar en el último verso de la tabla.');
	const cortes = new Set(filas.map(fila => fila.v_fin));
	let inicio = filas[0].v_ini;
	return finales.map((v_fin, i) => {
		if (v_fin < inicio) throw new Error('Los versos finales de jornada deben ir en orden ascendente.');
		if (!cortes.has(v_fin))
			throw new Error('Divide primero en la vista previa la fila que cruza el final de jornada en v. ' + v_fin + '.');
		const jornada = { numero: i + 1, v_ini: inicio, v_fin, rotulo_literal: null };
		inicio = v_fin + 1;
		return jornada;
	});
}

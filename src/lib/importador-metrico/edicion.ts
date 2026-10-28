import { z } from 'zod';
import type { FichaMinima, SegmentoMinimo } from './types';

const texto = z.string().trim().min(1).max(4000);
const entero = z.number().int().positive().max(2147483647);
const destino = z.object({ forma_slug: texto, arquitectura_slug: texto.nullable() }).strict();
export const edicionesSchema = z
	.array(
		z
			.object({
				tramo_ref: texto,
				partes: z
					.array(
						z
							.object({
								v_ini: entero,
								v_fin: entero,
								identificacion: destino.nullable(),
								nota: texto.nullable(),
								remate: z.object({ n_versos: entero }).strict().nullable()
							})
							.strict()
					)
					.min(1)
					.max(1000)
			})
			.strict()
	)
	.max(5000);
export type EdicionFila = z.infer<typeof edicionesSchema>[number];
export type FormaEditable = {
	slug: string;
	nombre: string;
	arquitecturas: { slug: string; nombre: string }[];
	secciones?: {
		tipo_seccion: string;
		arquitectura: string;
		versos_min?: number | null;
		versos_max?: number | null;
	}[];
};

/** Solo modifica la interpretación. El origen y el ámbito se reconstruyen desde la entrada. */
export function aplicarEdiciones(datos: FichaMinima, entrada: unknown): FichaMinima {
	const parsed = edicionesSchema.safeParse(entrada);
	if (!parsed.success) throw new Error('Los cambios de secuencias tienen un formato inválido.');
	const copia = structuredClone(datos);
	const vistas = new Set<string>();
	const referencias = new Set(datos.segmentos.map((s) => s.ref));
	for (const cambio of parsed.data) {
		if (vistas.has(cambio.tramo_ref)) throw new Error('Una fila original tiene cambios repetidos.');
		vistas.add(cambio.tramo_ref);
		const originales = datos.segmentos.filter((s) => s.origen.tramo_ref === cambio.tramo_ref);
		if (!originales.length) throw new Error('La fila original de los cambios no existe.');
		const primero = datos.segmentos.indexOf(originales[0]);
		if (originales.some((s, i) => datos.segmentos[primero + i] !== s))
			throw new Error('Las partes de la fila original deben ser consecutivas.');
		const inicio = originales[0].v_ini,
			fin = originales.at(-1)!.v_fin;
		if (
			cambio.partes[0].v_ini !== inicio ||
			cambio.partes.at(-1)!.v_fin !== fin ||
			cambio.partes.some(
				(p, i) => p.v_fin < p.v_ini || (i && p.v_ini !== cambio.partes[i - 1].v_fin + 1)
			)
		)
			throw new Error('Las partes deben cubrir la fila original sin huecos ni solapamientos.');
		const desviaciones = [
			...new Map(
				originales.flatMap((s) => s.desviaciones).map((d) => [JSON.stringify(d), d])
			).values()
		];
		for (const d of desviaciones) {
			if (!cambio.partes.some((p) => Number(d.v_ini) >= p.v_ini && Number(d.v_fin) <= p.v_fin))
				throw new Error(
					'El corte atraviesa una desviación. Ajusta el límite para conservarla entera.'
				);
		}
		const detalles = [
			...new Map(
				originales.flatMap((s) => s.detalles_fuente).map((d) => [JSON.stringify(d), d])
			).values()
		];
		const candidatas = [
			...new Map(
				originales.flatMap((s) => s.candidatas).map((d) => [JSON.stringify(d), d])
			).values()
		];
		const nuevas = cambio.partes.map((p, i): SegmentoMinimo => {
			let ref = originales[0].ref;
			if (cambio.partes.length > 1) {
				ref = `${originales[0].ref}-parte-${i + 1}`;
				while (referencias.has(ref)) ref += '-n';
			}
			referencias.add(ref);
			const mismoDestino = originales.every(
				(s) =>
					s.identificacion?.forma_slug === p.identificacion?.forma_slug &&
					s.identificacion?.arquitectura_slug === p.identificacion?.arquitectura_slug
			);
			return {
				...structuredClone(originales[0]),
				ref,
				v_ini: p.v_ini,
				v_fin: p.v_fin,
				segmentacion: 'provisional',
				identificacion: structuredClone(p.identificacion),
				candidatas: p.identificacion?.arquitectura_slug
					? []
					: structuredClone(
							candidatas.filter(
								(c) =>
									!p.identificacion ||
									(c.forma_slug === p.identificacion.forma_slug && c.arquitectura_slug)
							)
						),
				regla_id: mismoDestino ? originales[0].regla_id : null,
				nota: p.nota,
				detalles_fuente: [
					...structuredClone(detalles.filter((d) => d.tipo_seccion !== 'remate')),
					...(p.remate
						? [
								{
									...structuredClone(
										originales
											.find((s) => s.v_fin === p.v_fin)
											?.detalles_fuente.find(
												(d) => d.tipo_seccion === 'remate' && d.n_versos === p.remate!.n_versos
											) ?? {
											literal: 'remate final',
											dimension: 'estructura',
											tipo_seccion: 'remate',
											nombre: 'Remate',
											posicion: 'final'
										}
									),
									n_versos: p.remate.n_versos
								}
							]
						: [])
				],
				desviaciones: structuredClone(
					desviaciones.filter((d) => Number(d.v_ini) >= p.v_ini && Number(d.v_fin) <= p.v_fin)
				)
			};
		});
		const indice = copia.segmentos.findIndex((s) => s.origen.tramo_ref === cambio.tramo_ref);
		copia.segmentos.splice(indice, originales.length, ...nuevas);
	}
	return copia;
}

import { createHash } from 'node:crypto';
import { completarExtraccion } from './completar-extraccion';
import { z } from 'zod';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/types/database-client.types';
import type { BorradorFichaMinima } from '$lib/importador-metrico/types';
import {
	fichaMinimaSchema,
	serializarCanonico
} from '../../../../scripts/lib/importador-metrico/ficha-minima.mjs';

type Rpc =
	| 'capacidades_importador_metrico'
	| 'coincidencias_importacion_metrica'
	| 'guardar_ficha_basica'
	| 'listar_fichas_basicas'
	| 'eliminar_ficha_basica'
	| 'localizar_importacion_metrica'
	| 'consultar_importacion_metrica';
type DbError = { code?: string; message?: string };
type RespuestaRpc = { data: unknown; error: DbError | null };
/** Frontera limitada a RPC del borrador: no se inventan tipos globales de tablas futuras. */
export function clienteImportador(client: SupabaseClient<Database>) {
	return {
		rpc: (name: Rpc, args: Record<string, unknown> = {}) =>
			client.rpc(name as never, args as never) as unknown as PromiseLike<RespuestaRpc>
	};
}
export type ClienteImportador = ReturnType<typeof clienteImportador>;
export class ErrorImportacion extends Error {
	constructor(
		public status: number,
		message: string
	) {
		super(message);
	}
}
const uuid = z.string().uuid();
const coincidenciaSchema = z.object({
	obra_id: uuid,
	titulo: z.string(),
	tipo_ficha: z.enum(['minima', 'basica', 'completa', 'sin_ficha']),
	autores: z.array(z.string())
});
export type CoincidenciaImportacion = z.infer<typeof coincidenciaSchema>;
const capacidadesSchema = z.object({
	puede_importar: z.boolean(),
	guardado_disponible: z.boolean()
});
export async function capacidadesImportador(db: ClienteImportador) {
	const r = await db.rpc('capacidades_importador_metrico');
	if (r.error && ['PGRST202', '42883'].includes(r.error.code ?? '')) return null;
	if (r.error)
		throw new ErrorImportacion(503, 'No se pudo comprobar la disponibilidad del importador.');
	return capacidadesSchema.parse(r.data);
}
export async function buscarCoincidencias(db: ClienteImportador, titulo: string) {
	const r = await db.rpc('coincidencias_importacion_metrica', { p_titulo: titulo });
	if (r.error) throw new ErrorImportacion(503, 'No se pudieron comprobar las obras coincidentes.');
	return z.array(coincidenciaSchema).parse(r.data);
}
export function huellaConfirmacion(
	datos: BorradorFichaMinima,
	autorId: string,
	coincidencias: CoincidenciaImportacion[],
	obraId?: string | null
) {
	return createHash('sha256')
		.update(
			serializarCanonico({
				datos,
				autorId,
				coincidencias: [...coincidencias].sort((a, b) => a.obra_id.localeCompare(b.obra_id))
				,...(obraId ? {obraId} : {})
			})
		)
		.digest('hex');
}
export function extraccionOriginal(texto: string): Record<string, unknown> {
	const raw = JSON.parse(texto.trim().replace(/^```(?:json)?\s*\n([\s\S]*?)\n```$/i, '$1'));
	if (!raw || raw.esquema !== 'versologia-extraccion/0.1')
		throw new ErrorImportacion(
			400,
			'Para guardar se necesita la extracción original 0.1, no solo una ficha preparada.'
		);
	return completarExtraccion(raw);
}
export async function guardarImportacion(
	db: ClienteImportador,
	p: {
		datos: BorradorFichaMinima;
		autorId: string;
		entrada: string;
		peticionId: string;
		coincidencias: CoincidenciaImportacion[];
		huella: string;
		otraObra: boolean;
		obraId?: string | null;
	}
) {
	if (!uuid.safeParse(p.autorId).success || !uuid.safeParse(p.peticionId).success)
		throw new ErrorImportacion(400, 'Autor o identificador de petición inválidos.');
	const completa = fichaMinimaSchema.safeParse(p.datos);
	if (!completa.success)
		throw new ErrorImportacion(400, 'Completa los datos obligatorios de la obra antes de guardar.');
	if (p.obraId && !uuid.safeParse(p.obraId).success)
		throw new ErrorImportacion(400, 'Obra de destino inválida.');
	if (p.huella !== huellaConfirmacion(p.datos, p.autorId, p.coincidencias, p.obraId))
		throw new ErrorImportacion(
			409,
			'Los datos o las coincidencias han cambiado. Revisa la importación antes de guardar.'
		);
	if (p.coincidencias.length && !p.otraObra && !p.obraId)
		throw new ErrorImportacion(
			409,
			'Revisa si las coincidencias corresponden a otra obra antes de continuar.'
		);
	// Guardar confirma la segmentación revisada, no identifica las formas pendientes.
	const datos = structuredClone(completa.data);
	for (const s of datos.segmentos) s.segmentacion = 'confirmada';
	const r = await db.rpc('guardar_ficha_basica', {
		p_peticion: p.peticionId,
		p_autor: p.autorId,
		p_datos: datos,
		p_entrada_original: extraccionOriginal(p.entrada),
		p_coincidencias_revisadas: p.coincidencias.map((c) => c.obra_id),
		p_obra: p.obraId ?? null
	});
	if (r.error) {
		if (r.error.code === '23505')
			throw new ErrorImportacion(
				409,
				'Han cambiado las coincidencias o la petición ya se usó con otros datos. Vuelve a comprobar.'
			);
		if (r.error.code === '42501')
			throw new ErrorImportacion(403, 'Tu sesión ya no tiene permiso para importar.');
		if (['22023', '23514'].includes(r.error.code ?? ''))
			throw new ErrorImportacion(400, r.error.message ?? 'Revisa los datos de la importación.');
		throw new ErrorImportacion(
			503,
			'No se pudo guardar la importación. Puedes reintentar sin cambiar los datos.'
		);
	}
	return z.object({ obra_id: uuid, importacion_id: uuid, repetida: z.boolean() }).parse(r.data);
}
const filaGuardadaSchema = z.object({
	importacion_id: uuid,
	obra_id: uuid,
	titulo: z.string(),
	autor_nombre: z.string(),
	importado_por: z.string(),
	importado_en: z.string(),
	modificado_en: z.string().nullable().default(null),
	formas_pendientes: z.array(z.object({ denominacion: z.string(), v_ini: z.number().int(), v_fin: z.number().int() })).default([]),
	comprobacion_registrada: z.boolean().default(false),
	avisos_longitud: z.array(z.object({ segmento_ref: z.string(), v_ini: z.number().int(), v_fin: z.number().int(), mensaje: z.string() })).default([]),
	incidencias_fuente: z.array(z.object({ descripcion: z.string() })).default([])
});
export type FilaBasica = z.infer<typeof filaGuardadaSchema>;
export async function listarBasicas(db: ClienteImportador, desde: number) {
	const r = await db.rpc('listar_fichas_basicas', { p_desde: desde });
	if (r.error) throw new ErrorImportacion(503, 'No se pudieron cargar las fichas básicas.');
	const filas = z.array(filaGuardadaSchema).parse(r.data);
	return { filas: filas.slice(0, 50), hayMas: filas.length > 50 };
}
export async function eliminarBasica(db: ClienteImportador, importacionId: string, confirmacion: string) {
	if (!uuid.safeParse(importacionId).success || !confirmacion.trim() || confirmacion.length > 2000)
		throw new ErrorImportacion(400, 'Revisa la ficha y escribe su título para confirmar.');
	const r = await db.rpc('eliminar_ficha_basica', { p_importacion: importacionId, p_confirmacion: confirmacion.trim() });
	if (r.error) {
		const status = r.error.code === '42501' ? 403 : r.error.code === 'P0002' ? 404 : ['23514','22023','23503'].includes(r.error.code ?? '') ? 409 : 503;
		throw new ErrorImportacion(status, status === 503 ? 'No se pudo eliminar la ficha.' : r.error.message ?? 'La ficha no se puede eliminar.');
	}
	return z.object({ eliminada: z.literal(true), obra_id: uuid }).parse(r.data);
}
export async function consultarImportacion(db: ClienteImportador, id: string) {
	if (!uuid.safeParse(id).success) throw new ErrorImportacion(404, 'Importación no disponible.');
	const r = await db.rpc('consultar_importacion_metrica', { p_importacion: id });
	if (r.error) throw new ErrorImportacion(503, 'No se pudo cargar la importación.');
	if (!r.data) throw new ErrorImportacion(404, 'Importación no disponible.');
	return z
		.object({
			importacion_id: uuid,
			obra_id: uuid,
			importado_por: z.string(),
			importado_en: z.string(),
			datos_confirmados: fichaMinimaSchema,
			entrada_original: z.record(z.string(), z.unknown())
		})
		.parse(r.data);
}

export async function localizarImportacion(db: ClienteImportador, obraId: string) {
	const r = await db.rpc('localizar_importacion_metrica', { p_obra: obraId });
	if (r.error) throw new ErrorImportacion(503, 'No se pudo localizar la ficha básica.');
	return uuid.nullable().parse(r.data);
}

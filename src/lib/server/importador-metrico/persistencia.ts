import { createHash } from 'node:crypto';
import { z } from 'zod';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { Database } from '$lib/types/database.types';
import type { FichaMinima } from '$lib/importador-metrico/types';
import {
	fichaMinimaSchema,
	serializarCanonico
} from '../../../../scripts/lib/importador-metrico/ficha-minima.mjs';

type Rpc =
	| 'capacidades_importador_metrico'
	| 'coincidencias_importacion_metrica'
	| 'guardar_ficha_minima'
	| 'listar_fichas_basicas'
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
	tipo_ficha: z.enum(['minima', 'completa']),
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
	datos: FichaMinima,
	autorId: string,
	coincidencias: CoincidenciaImportacion[]
) {
	return createHash('sha256')
		.update(
			serializarCanonico({
				datos,
				autorId,
				coincidencias: [...coincidencias].sort((a, b) => a.obra_id.localeCompare(b.obra_id))
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
	return raw;
}
export async function guardarImportacion(
	db: ClienteImportador,
	p: {
		datos: FichaMinima;
		autorId: string;
		entrada: string;
		peticionId: string;
		coincidencias: CoincidenciaImportacion[];
		huella: string;
		otraObra: boolean;
	}
) {
	if (!uuid.safeParse(p.autorId).success || !uuid.safeParse(p.peticionId).success)
		throw new ErrorImportacion(400, 'Autor o identificador de petición inválidos.');
	if (p.huella !== huellaConfirmacion(p.datos, p.autorId, p.coincidencias))
		throw new ErrorImportacion(
			409,
			'Los datos o las coincidencias han cambiado. Revisa la vista previa antes de guardar.'
		);
	if (p.coincidencias.length && !p.otraObra)
		throw new ErrorImportacion(
			409,
			'Revisa si las coincidencias corresponden a otra obra antes de continuar.'
		);
	const r = await db.rpc('guardar_ficha_minima', {
		p_peticion: p.peticionId,
		p_autor: p.autorId,
		p_datos: p.datos,
		p_entrada_original: extraccionOriginal(p.entrada),
		p_coincidencias_revisadas: p.coincidencias.map((c) => c.obra_id)
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
	importado_en: z.string()
});
export async function listarBasicas(db: ClienteImportador, desde: number) {
	const r = await db.rpc('listar_fichas_basicas', { p_desde: desde });
	if (r.error) throw new ErrorImportacion(503, 'No se pudieron cargar las fichas básicas.');
	const filas = z.array(filaGuardadaSchema).parse(r.data);
	return { filas: filas.slice(0, 50), hayMas: filas.length > 50 };
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

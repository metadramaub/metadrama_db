import { error, json } from '@sveltejs/kit';
import { z } from 'zod';
import type { RequestHandler } from './$types';
import { estadoImportador } from '$lib/server/importador-metrico/acceso';
import { formasImportador } from '$lib/importador-metrico/catalogo';

/** Registra que un término que llegó sin identificar es esta forma (y arquitectura, si se da). */
const texto = z.string().trim().min(1).max(400);
const cuerpoSchema = z
	.object({
		literal: texto,
		forma: texto,
		arquitectura: texto.nullable(),
		procedencia: z
			.object({
				edicion: z.string().trim().max(4000).nullable(),
				obra: texto,
				fila: texto,
				foto: texto.nullable(),
				pagina: z.number().int().positive().nullable()
			})
			.strict()
	})
	.strict();
const TAMANO_MAXIMO = 25_000;

export const POST: RequestHandler = async (event) => {
	await estadoImportador(event);
	const cuerpo = await event.request.text();
	if (cuerpo.length > TAMANO_MAXIMO) throw error(413, 'La correspondencia es demasiado extensa.');
	let entrada: unknown;
	try {
		entrada = JSON.parse(cuerpo);
	} catch {
		throw error(400, 'La correspondencia debe ser JSON válido.');
	}
	const parsed = cuerpoSchema.safeParse(entrada);
	if (!parsed.success) throw error(400, 'Falta la denominación, la forma o la procedencia.');
	const d = parsed.data;
	const forma = formasImportador.find((f) => f.slug === d.forma);
	if (!forma || (d.arquitectura && !forma.arquitecturas.some((a) => a.slug === d.arquitectura)))
		throw error(400, 'La identificación no pertenece al catálogo.');
	const session = await event.locals.safeGetSession();
	if (!session.user) throw error(401, 'La sesión ha caducado.');

	const literal = d.literal.normalize('NFC').replace(/\s+/gu, ' ');
	const r = await event.locals.supabase
		.from('correspondencias_importador')
		.insert({ ...d, literal, creado_por: session.user.id });
	if (r.error?.code === '23505') throw error(409, 'Esta correspondencia ya estaba registrada.');
	if (r.error) throw error(503, 'No se pudo registrar la correspondencia.');
	return json({ guardada: true }, { status: 201 });
};

import { error, fail, redirect, type RequestEvent } from '@sveltejs/kit';
import { z } from 'zod';
import { formasImportador } from '$lib/importador-metrico/catalogo';
import { requireEditorProfile } from '$lib/server/auth';
import { canManageImportCorrespondences } from '$lib/utils/permissions';
import type { Actions, PageServerLoad } from './$types';

const TAMANO_PAGINA = 50;
const idSchema = z.string().uuid();

async function requireRevisor(event: Pick<RequestEvent, 'locals'>) {
	const profile = await requireEditorProfile(event);
	if (!canManageImportCorrespondences(profile.roleTerm))
		throw error(403, 'Solo administración e IP pueden revisar correspondencias.');
	return profile;
}

export const load = (async (event) => {
	await requireRevisor(event);
	const pagina = Number(event.url.searchParams.get('pagina') ?? '1');
	const inicio = (pagina - 1) * TAMANO_PAGINA;
	if (!Number.isSafeInteger(pagina) || pagina < 1 || !Number.isSafeInteger(inicio + TAMANO_PAGINA))
		throw error(400, 'Página inválida.');
	const cliente = event.locals.supabase;
	const { data, error: fallo } = await cliente
		.from('correspondencias_importador')
		.select('id,literal,forma,arquitectura,procedencia,creado_por,creado_en,revisado_por,revisado_en')
		.order('revisado_en', { ascending: false, nullsFirst: true })
		.order('creado_en', { ascending: false })
		.order('id')
		.range(inicio, inicio + TAMANO_PAGINA);
	if (fallo) throw error(503, 'No se pudo cargar el registro de correspondencias.');
	if (!data.length && pagina > 1) throw redirect(303, '/dashboard/importador/correspondencias');

	const filas = data.slice(0, TAMANO_PAGINA);
	const ids = [...new Set(filas.flatMap((fila) =>
		fila.revisado_por ? [fila.creado_por, fila.revisado_por] : [fila.creado_por]
	))];
	const nombres = new Map<string, string>();
	if (ids.length) {
		const editores = await cliente.from('editores').select('user_id,nombre_completo').in('user_id', ids);
		if (editores.error) throw error(503, 'No se pudieron cargar los nombres de los editores.');
		for (const editor of editores.data) nombres.set(editor.user_id, editor.nombre_completo);
	}
	return {
		pagina,
		haySiguiente: data.length > TAMANO_PAGINA,
		correspondencias: filas.map((fila) => {
			const forma = formasImportador.find((item) => item.slug === fila.forma);
			const arquitectura = forma?.arquitecturas.find((item) => item.slug === fila.arquitectura);
			const origen = fila.procedencia;
			const fuente = origen && typeof origen === 'object' && !Array.isArray(origen) ? origen : {};
			return {
				id: fila.id,
				literal: fila.literal,
				forma: forma?.nombre ?? fila.forma,
				arquitectura: arquitectura?.nombre ?? fila.arquitectura,
				autor: nombres.get(fila.creado_por) ?? fila.creado_por,
				creadoEn: fila.creado_en,
				revisor: fila.revisado_por ? nombres.get(fila.revisado_por) ?? fila.revisado_por : null,
				revisadoEn: fila.revisado_en,
				obra: typeof fuente.obra === 'string' ? fuente.obra : null,
				edicion: typeof fuente.edicion === 'string' ? fuente.edicion : null,
				fila: typeof fuente.fila === 'string' ? fuente.fila : null,
				foto: typeof fuente.foto === 'string' ? fuente.foto : null,
				paginaFuente: typeof fuente.pagina === 'number' ? fuente.pagina : null
			};
		})
	};
}) satisfies PageServerLoad;

export const actions: Actions = {
	revisar: async (event) => {
		const profile = await requireRevisor(event);
		const id = idSchema.safeParse((await event.request.formData()).get('id'));
		if (!id.success) return fail(400, { mensaje: 'Correspondencia inválida.' });
		const r = await event.locals.supabase.from('correspondencias_importador')
			.update({ revisado_por: profile.userId, revisado_en: new Date().toISOString() })
			.eq('id', id.data).is('revisado_en', null).select('id').maybeSingle();
		if (r.error) return fail(503, { mensaje: 'No se pudo marcar la correspondencia como revisada.' });
		if (!r.data) return fail(409, { mensaje: 'La correspondencia ya se revisó o se retiró. Actualiza el listado.' });
		return { exito: 'Correspondencia revisada.' };
	},
	retirar: async (event) => {
		await requireRevisor(event);
		const id = idSchema.safeParse((await event.request.formData()).get('id'));
		if (!id.success) return fail(400, { mensaje: 'Correspondencia inválida.' });
		const r = await event.locals.supabase.from('correspondencias_importador')
			.delete().eq('id', id.data).select('id').maybeSingle();
		if (r.error) return fail(503, { mensaje: 'No se pudo retirar la correspondencia.' });
		if (!r.data) return fail(409, { mensaje: 'La correspondencia ya se retiró. Actualiza el listado.' });
		return { exito: 'Correspondencia retirada.' };
	}
};

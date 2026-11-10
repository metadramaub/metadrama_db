import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { modeloEditorialActivo } from '$lib/server/modelo-obras';
import { z } from 'zod';

export const POST: RequestHandler = async ({ locals, params }) => {
	await requireEditorProfile({ locals });
	if (!modeloEditorialActivo()) throw error(503, 'El nuevo modelo editorial aún no está activado.');
	if (!z.string().uuid().safeParse(params.id).success) throw error(400, 'Obra inválida.');
	const r = await locals.supabase.rpc(
		'iniciar_ficha_completa' as never,
		{ p_obra: params.id, p_iniciar: true } as never
	);
	if (r.error)
		throw error(
			r.error.code === '42501' ? 403 : r.error.code === '23514' ? 409 : 500,
			r.error.message
		);
	return json({ ok: true });
};

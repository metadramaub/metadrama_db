import { json, error } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorManager } from '$lib/server/editor-management';
import { modeloEditorialActivo } from '$lib/server/modelo-obras';
import { z } from 'zod';
const entrada = z.object({
	operacion: z.enum(['crear', 'renombrar', 'anadir', 'retirar']),
	codigo: z.string().trim().min(1).max(40),
	nombre: z.string().trim().min(1).max(200).optional(),
	obras: z.array(z.string().uuid()).max(500).default([])
});
export const POST: RequestHandler = async ({ locals, request }) => {
	await requireEditorManager(locals);
	if (!modeloEditorialActivo()) throw error(503, 'El nuevo control aún no está activado.');
	const p = entrada.safeParse(await request.json().catch(() => null));
	if (!p.success) throw error(400, 'Revisa la operación, el corpus y las obras seleccionadas.');
	const r = await locals.supabase.rpc(
		'gestionar_corpus' as never,
		{
			p_operacion: p.data.operacion,
			p_codigo: p.data.codigo,
			p_nombre: p.data.nombre ?? null,
			p_obras: p.data.obras
		} as never
	);
	if (r.error)
		throw error(
			r.error.code === '23505' ? 409 : r.error.code === '22023' ? 400 : 500,
			r.error.message
		);
	return json({ ok: true });
};

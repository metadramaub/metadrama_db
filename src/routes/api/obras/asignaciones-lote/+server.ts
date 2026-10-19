import { error, json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorManager } from '$lib/server/editor-management';
import { bulkAssignmentsSchema } from '$lib/utils/editor-management';
import { validationErrorResponse } from '$lib/server/http';
import type { Json } from '$lib/types/database.types';

export const POST: RequestHandler = async ({ locals, request }) => {
	await requireEditorManager(locals);
	const parsed = bulkAssignmentsSchema.safeParse(await request.json().catch(() => null));
	if (!parsed.success) return validationErrorResponse(parsed.error);
	const result = await locals.supabase.rpc('gestionar_asignaciones_lote', {
		p_operacion: parsed.data.operation,
		p_destino: parsed.data.target,
		p_obras: parsed.data.works as Json
	});
	if (result.error) {
		const status = ['PT409', '40001'].includes(result.error.code)
			? 409
			: result.error.code === '42501'
				? 403
				: result.error.code === '22023'
					? 422
					: 500;
		throw error(
			status,
			status === 500
				? 'No se pudo guardar el lote. No se ha aplicado ningún cambio.'
				: result.error.message
		);
	}
	return json({ changed: result.data });
};

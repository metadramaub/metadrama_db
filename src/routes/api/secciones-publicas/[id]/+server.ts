import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { forbiddenResponse, validationErrorResponse } from '$lib/server/http';
import { canManagePublicacion } from '$lib/utils/permissions';
import { seccionPublicaPatchSchema } from '$lib/utils/validators';
import { invalidatePublicSectionsCache } from '$lib/server/secciones-publicas';

const seccionSelect = 'seccion_id,label,descripcion,activa,scope_minimo,orden';

export const PATCH: RequestHandler = async ({ locals, request, params }) => {
	const profile = await requireEditorProfile({ locals });
	if (!canManagePublicacion(profile.roleTerm)) {
		return forbiddenResponse('Solo admin o IP pueden gestionar la publicación.');
	}

	const body = await request.json().catch(() => ({}));
	const parsed = seccionPublicaPatchSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { data, error } = await locals.supabase
		.from('secciones_publicas')
		.update(parsed.data)
		.eq('seccion_id', params.id)
		.select(seccionSelect)
		.maybeSingle();

	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}
	if (!data) {
		return json({ error: 'not_found', message: 'Sección no encontrada.' }, { status: 404 });
	}

	// El cambio debe reflejarse al instante en la zona pública, sin esperar al TTL.
	invalidatePublicSectionsCache();

	return json({ seccion: data });
};

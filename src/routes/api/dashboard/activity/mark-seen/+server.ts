import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';
import { markDashboardActivitySeen } from '$lib/server/dashboard';

export const POST: RequestHandler = async ({ locals }) => {
	const profile = await requireEditorProfile({ locals });
	const result = await markDashboardActivitySeen(locals, profile);
	if (!result.lastSeenAt) {
		return json(
			{
				error: 'db_error',
				message: `No se pudo actualizar el estado de actividad vista. ${result.errorMessage ?? ''}`.trim()
			},
			{ status: 500 }
		);
	}
	return json({ ok: true, lastSeenAt: result.lastSeenAt });
};

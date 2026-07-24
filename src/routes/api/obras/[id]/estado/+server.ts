import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { canTransitionState } from '$lib/utils/permissions';
import { estadoInputSchema } from '$lib/utils/validators';
import { validationErrorResponse } from '$lib/server/http';
import { getObraContext, requireAuthenticated } from '$lib/server/auth';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import { getEstadoTerm } from '$lib/server/obras';
import { loadObraRangeConsistency } from '$lib/server/range-consistency';
import { stateRequiresConsistentRanges } from '$lib/utils/range-consistency';

export const PATCH: RequestHandler = async ({ locals, params, request }) => {
	const user = await requireAuthenticated({ locals });
	const { obra, profile, estadoTerm, assignedEditor, assignedReviewer } = await getObraContext(
		{ locals },
		params.id,
		{
		requireChangeState: true
		}
	);
	const body = await request.json().catch(() => ({}));
	const parsed = estadoInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const { estado, comentario } = parsed.data;
	const targetTerm = await getEstadoTerm(locals.supabase, estado);
	const allowed = canTransitionState(profile.roleTerm, estadoTerm, targetTerm, {
		assignedEditor,
		assignedReviewer
	});

	if (!allowed) {
		return json(
			{
				error: 'forbidden',
				message: `Transición no permitida para rol ${profile.roleTerm}: ${estadoTerm} -> ${targetTerm}`
			},
			{ status: 403 }
		);
	}

	if (stateRequiresConsistentRanges(targetTerm)) {
		const consistency = await loadObraRangeConsistency(locals.supabase, obra.obra_id);
		if (consistency.errorMessage) {
			return json(
				{
					error: 'db_error',
					message: `No se pudo comprobar la coherencia de los rangos: ${consistency.errorMessage}`
				},
				{ status: 500 }
			);
		}
		if (consistency.issues.length > 0) {
			return json(
				{
					error: 'range_consistency_error',
					message:
						'La obra tiene incoherencias de rango. Corrígelas antes de enviarla a revisión o publicarla.',
					issues: consistency.issues
				},
				{ status: 409 }
			);
		}
	}

	const { data, error } = await locals.supabase
		.from('obras')
		.update({
			estado,
			fecha_cambio_estado: new Date().toISOString()
		})
		.eq('obra_id', obra.obra_id)
		.select('*')
		.single();

	if (error || !data) {
		return json(
			{ error: 'db_error', message: error?.message ?? 'No se pudo cambiar estado' },
			{ status: 500 }
		);
	}

	const tiposComentario = await loadInternalVocabulario(locals.supabase, ['tipo_comentario']);
	const tipoComentarioId = tiposComentario.find((item) => item.termino === 'estado')?.termino_id;
	if (tipoComentarioId) {
		const extra = comentario?.trim() ? ` ${comentario.trim()}` : '';
		await locals.supabase.from('comentarios_internos').insert({
			obra_id: obra.obra_id,
			user_id: user.id,
			comentario: `[Cambio de estado ${estadoTerm} -> ${targetTerm}]${extra}`,
			tipo_comentario_id: tipoComentarioId
		});
	}

	return json({ obra: data, estadoTerm: targetTerm });
};

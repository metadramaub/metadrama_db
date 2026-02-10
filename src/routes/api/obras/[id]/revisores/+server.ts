import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { getObraContext } from '$lib/server/auth';
import { canManageReviewAssignments } from '$lib/utils/permissions';
import { validationErrorResponse } from '$lib/server/http';
import { obraReviewersInputSchema } from '$lib/utils/validators';

async function loadReviewerData(locals: App.Locals, obraId: string, editorAsignado: string | null) {
	const [assignedResp, candidatesResp] = await Promise.all([
		locals.supabase.from('obras_revisores').select('*').eq('obra_id', obraId),
		locals.supabase
			.from('editores')
			.select('user_id,nombre_completo,email,activo')
			.eq('activo', true)
			.order('nombre_completo')
	]);

	const assignedRows = assignedResp.data ?? [];
	const assignedIds = assignedRows.map((row) => row.revisor_id);
	const allEditorRows = candidatesResp.data ?? [];
	const editorMap = new Map(allEditorRows.map((row) => [row.user_id, row]));

	const assigned = assignedRows
		.map((row) => {
			const editor = editorMap.get(row.revisor_id);
			return {
				revisor_id: row.revisor_id,
				nombre_completo: editor?.nombre_completo ?? 'Sin nombre',
				email: editor?.email ?? null,
				created_at: row.created_at
			};
		})
		.sort((a, b) => a.nombre_completo.localeCompare(b.nombre_completo, 'es'));

	const candidates = allEditorRows
		.filter((row) => row.user_id !== editorAsignado)
		.map((row) => ({
			user_id: row.user_id,
			nombre_completo: row.nombre_completo,
			email: row.email,
			selected: assignedIds.includes(row.user_id)
		}));

	return { assigned, candidates };
}

export const GET: RequestHandler = async ({ locals, params }) => {
	const { profile, obra } = await getObraContext({ locals }, params.id, { requireEdit: false });
	const { assigned, candidates } = await loadReviewerData(locals, obra.obra_id, obra.editor_asignado);

	return json({
		canManage: canManageReviewAssignments(profile.roleTerm),
		editorAsignado: obra.editor_asignado,
		assigned,
		candidates
	});
};

export const PUT: RequestHandler = async ({ locals, params, request }) => {
	const { profile, obra } = await getObraContext({ locals }, params.id, {
		requireManageReviewers: true
	});

	const body = await request.json().catch(() => ({}));
	const parsed = obraReviewersInputSchema.safeParse(body);
	if (!parsed.success) {
		return validationErrorResponse(parsed.error);
	}

	const reviewerIds = parsed.data.reviewer_ids;
	if (obra.editor_asignado && reviewerIds.includes(obra.editor_asignado)) {
		return json(
			{
				error: 'validation_error',
				details: [
					{
						path: 'reviewer_ids',
						message: 'No se puede asignar como revisor al editor propietario de la obra.'
					}
				]
			},
			{ status: 422 }
		);
	}

	if (reviewerIds.length > 0) {
		const { data: foundEditors } = await locals.supabase
			.from('editores')
			.select('user_id')
			.eq('activo', true)
			.in('user_id', reviewerIds);
		if ((foundEditors ?? []).length !== reviewerIds.length) {
			return json(
				{
					error: 'validation_error',
					details: [{ path: 'reviewer_ids', message: 'Uno o varios revisores no existen o estan inactivos.' }]
				},
				{ status: 422 }
			);
		}
	}

	const { error: deleteError } = await locals.supabase
		.from('obras_revisores')
		.delete()
		.eq('obra_id', obra.obra_id);
	if (deleteError) {
		return json(
			{ error: 'db_error', message: deleteError.message ?? 'No se pudieron limpiar revisores anteriores.' },
			{ status: 500 }
		);
	}

	if (reviewerIds.length > 0) {
		const rows = reviewerIds.map((reviewerId) => ({
			obra_id: obra.obra_id,
			revisor_id: reviewerId,
			asignado_por: profile.userId
		}));
		const { error: insertError } = await locals.supabase.from('obras_revisores').insert(rows);
		if (insertError) {
			return json(
				{ error: 'db_error', message: insertError.message ?? 'No se pudieron guardar revisores.' },
				{ status: 500 }
			);
		}
	}

	const { assigned, candidates } = await loadReviewerData(locals, obra.obra_id, obra.editor_asignado);
	return json({
		canManage: true,
		editorAsignado: obra.editor_asignado,
		assigned,
		candidates
	});
};

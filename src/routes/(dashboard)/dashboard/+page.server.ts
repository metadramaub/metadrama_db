import type { PageServerLoad } from './$types';
import { canReadAllObras } from '$lib/utils/permissions';
import { computeObraProgress } from '$lib/server/obras';
import type { Tables } from '$lib/types/database.types';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;

	const { data: assignedObras } = await locals.supabase
		.from('obras')
		.select('*')
		.eq('editor_asignado', profile.userId)
		.order('updated_at', { ascending: false })
		.limit(20);
	const assigned = (assignedObras ?? []) as Tables<'obras'>[];

	const allEstadoIds = [...new Set(assigned.map((obra) => obra.estado))];
	const { data: estadoTerms } =
		allEstadoIds.length > 0
			? await locals.supabase
					.from('vocabularios')
					.select('termino_id,termino')
					.in('termino_id', allEstadoIds)
					.eq('categoria', 'estado')
			: { data: [] };
	const termMap = new Map((estadoTerms ?? []).map((item) => [item.termino_id, item.termino]));

	const cards = await Promise.all(
		assigned.map(async (obra) => ({
			obraId: obra.obra_id,
			titulo: obra.titulo,
			estadoTerm: termMap.get(obra.estado) ?? 'borrador',
			updatedAt: obra.updated_at,
			progreso: await computeObraProgress(locals.supabase, obra)
		}))
	);

	let allObrasSummary: {
		obra_id: string;
		titulo: string;
		updated_at: string | null;
		editor_asignado: string | null;
		estado: string;
	}[] = [];

	if (canReadAllObras(profile.roleTerm)) {
		const { data } = await locals.supabase
			.from('obras')
			.select('obra_id,titulo,updated_at,editor_asignado,estado')
			.order('updated_at', { ascending: false })
			.limit(50);
		allObrasSummary = (data ?? []) as typeof allObrasSummary;
	}

	return {
		profile,
		cards,
		allObrasSummary
	};
};

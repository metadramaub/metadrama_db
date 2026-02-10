import type { PageServerLoad } from './$types';
import { canReadAllObras } from '$lib/utils/permissions';
import { computeObraProgress } from '$lib/server/obras';
import type { Tables } from '$lib/types/database.types';
import { error } from '@sveltejs/kit';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const parentData = await parent();
	const profile = parentData.profile;
	const canReadAll = canReadAllObras(profile.roleTerm);

	const cardsQuery = canReadAll
		? locals.supabase.from('obras').select('*').order('updated_at', { ascending: false }).limit(20)
		: locals.supabase
				.from('obras')
				.select('*')
				.eq('editor_asignado', profile.userId)
				.order('updated_at', { ascending: false })
				.limit(20);
	const { data: cardsRows, error: cardsError } = await cardsQuery;
	if (cardsError) {
		throw error(500, `No se pudieron cargar las obras del dashboard: ${cardsError.message}`);
	}
	const cardsSource = (cardsRows ?? []) as Tables<'obras'>[];

	const allEstadoIds = [...new Set(cardsSource.map((obra) => obra.estado))];
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
		cardsSource.map(async (obra) => ({
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
		estadoTerm: string;
	}[] = [];
	let alerts: {
		recentComments: Array<{ obra_id: string; titulo: string; total: number }>;
		lowOrMediumCertainty: Array<{ obra_id: string; titulo: string; total: number }>;
		recentStateChanges: Array<{ obra_id: string; titulo: string; estadoTerm: string; fecha: string | null }>;
	} = { recentComments: [], lowOrMediumCertainty: [], recentStateChanges: [] };

	if (canReadAll) {
		const { data } = await locals.supabase
			.from('obras')
			.select('obra_id,titulo,updated_at,editor_asignado,estado')
			.order('updated_at', { ascending: false })
			.limit(50);
		const allRows = (data ?? []) as Array<{
			obra_id: string;
			titulo: string;
			updated_at: string | null;
			editor_asignado: string | null;
			estado: string;
		}>;
		const allEstadoIds = [...new Set(allRows.map((row) => row.estado))];
		const { data: allEstadoTerms } =
			allEstadoIds.length > 0
				? await locals.supabase
						.from('vocabularios')
						.select('termino_id,termino')
						.in('termino_id', allEstadoIds)
				: { data: [] };
		const allEstadoMap = new Map(
			(allEstadoTerms ?? []).map((item) => [item.termino_id, item.termino])
		);
		allObrasSummary = allRows.map((row) => ({
			...row,
			estadoTerm: allEstadoMap.get(row.estado) ?? row.estado
		}));

		const now = new Date();
		const since72h = new Date(now.getTime() - 72 * 60 * 60 * 1000).toISOString();
		const since7d = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000).toISOString();

		const [recentCommentsResp, certezaResp, secuenciasResp, stateChangesResp] = await Promise.all([
			locals.supabase
				.from('comentarios_internos')
				.select('obra_id,created_at')
				.gte('created_at', since72h)
				.order('created_at', { ascending: false })
				.limit(500),
			locals.supabase
				.from('vocabularios')
				.select('termino_id,termino')
				.eq('categoria', 'certeza_editor')
				.in('termino', ['baja', 'media']),
			locals.supabase.from('secuencias_metricas').select('obra_id,certeza_editor').limit(5000),
			locals.supabase
				.from('obras')
				.select('obra_id,titulo,estado,fecha_cambio_estado')
				.gte('fecha_cambio_estado', since7d)
				.order('fecha_cambio_estado', { ascending: false })
				.limit(100)
		]);

		const titleByObra = new Map(allRows.map((row) => [row.obra_id, row.titulo]));
		const countByObra = new Map<string, number>();
		for (const row of recentCommentsResp.data ?? []) {
			countByObra.set(row.obra_id, (countByObra.get(row.obra_id) ?? 0) + 1);
		}
		alerts.recentComments = [...countByObra.entries()]
			.map(([obraId, total]) => ({
				obra_id: obraId,
				titulo: titleByObra.get(obraId) ?? 'Obra',
				total
			}))
			.sort((a, b) => b.total - a.total)
			.slice(0, 8);

		const certezaIds = new Set((certezaResp.data ?? []).map((row) => row.termino_id));
		const lowMedCountByObra = new Map<string, number>();
		for (const row of secuenciasResp.data ?? []) {
			if (certezaIds.has(row.certeza_editor)) {
				lowMedCountByObra.set(row.obra_id, (lowMedCountByObra.get(row.obra_id) ?? 0) + 1);
			}
		}
		alerts.lowOrMediumCertainty = [...lowMedCountByObra.entries()]
			.map(([obraId, total]) => ({
				obra_id: obraId,
				titulo: titleByObra.get(obraId) ?? 'Obra',
				total
			}))
			.sort((a, b) => b.total - a.total)
			.slice(0, 8);

		const changeRows = (stateChangesResp.data ?? []) as Array<{
			obra_id: string;
			titulo: string;
			estado: string;
			fecha_cambio_estado: string | null;
		}>;
		const changeEstadoIds = [...new Set(changeRows.map((row) => row.estado))];
		const { data: changeEstadoTerms } =
			changeEstadoIds.length > 0
				? await locals.supabase
						.from('vocabularios')
						.select('termino_id,termino')
						.in('termino_id', changeEstadoIds)
				: { data: [] };
		const changeEstadoMap = new Map(
			(changeEstadoTerms ?? []).map((item) => [item.termino_id, item.termino])
		);
		alerts.recentStateChanges = changeRows.slice(0, 8).map((row) => ({
			obra_id: row.obra_id,
			titulo: row.titulo,
			estadoTerm: changeEstadoMap.get(row.estado) ?? row.estado,
			fecha: row.fecha_cambio_estado
		}));
	}

	return {
		profile,
		cardsScope: canReadAll ? 'all' : 'mine',
		cards,
		allObrasSummary,
		alerts
	};
};

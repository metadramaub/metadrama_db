import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { getAssignedEditorObras, getNotifications, getPublishedAssignedSummary } from '$lib/server/dashboard';
import { getInformesVisibles } from '$lib/server/migracion-informes';
import { relacionObras } from '$lib/server/modelo-obras';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';
import { getSupabaseAdmin } from '$lib/server/supabase-admin';

export const load: PageServerLoad = async ({ locals, parent, depends }) => {
	depends('dashboard:home');

	const { profile, importador } = await parent();
	const isAdminOrIp = ['admin', 'ip'].includes(profile.roleTerm);

	async function loadOverview() {
		const estados = await loadInternalVocabulario(locals.supabase, ['estado']);
		const listo = estados.find(({ termino }) => termino === 'listo_para_publicar')?.termino_id;
		const contar = () => locals.supabase.from(relacionObras()).select('obra_id', { count: 'exact', head: true });
		const [sinFicha, basicas, completas, sinAsignar, listas] = await Promise.all([
			contar().eq('tipo_ficha', 'sin_ficha'),
			contar().eq('tipo_ficha', 'basica'),
			contar().eq('tipo_ficha', 'completa'),
			contar().is('editor_asignado', null),
			listo ? contar().eq('tipo_ficha', 'completa').eq('estado', listo) : null
		]);
		if ([sinFicha, basicas, completas, sinAsignar, listas].some((result) => result?.error)) {
			throw error(500, 'No se pudo cargar el resumen de obras.');
		}
		return {
			sinFicha: sinFicha.count ?? 0,
			basicas: basicas.count ?? 0,
			completas: completas.count ?? 0,
			sinAsignar: sinAsignar.count ?? 0,
			listas: listas?.count ?? 0,
			estadoListo: listo
		};
	}

	async function loadProjectProgress() {
		try {
			// La consulta privilegiada devuelve solo recuentos. Las obras conservan su acceso habitual.
			const admin = getSupabaseAdmin();
			const estados = await loadInternalVocabulario(locals.supabase, ['estado']);
			const publicado = estados.find(({ termino }) => termino === 'publicado')?.termino_id;
			if (!publicado) return null;
			const contar = () => admin.from(relacionObras()).select('obra_id', { count: 'exact', head: true });
			const [total, enProceso, publicadas, importadas] = await Promise.all([
				contar(),
				contar().eq('tipo_ficha', 'completa').neq('estado', publicado),
				contar().eq('tipo_ficha', 'completa').eq('estado', publicado),
				contar().eq('tipo_ficha', 'basica')
			]);
			if (total.error || enProceso.error || publicadas.error || importadas.error) return null;
			return {
				total: total.count ?? 0,
				enProceso: enProceso.count ?? 0,
				publicadas: publicadas.count ?? 0,
				importadas: importadas.count ?? 0
			};
		} catch {
			return null;
		}
	}

	const [overview, recentActivity, assignedEditorObras, publishedAssignedSummary, informesMigracion, projectProgress] = await Promise.all([
		isAdminOrIp ? loadOverview() : null,
		isAdminOrIp ? getNotifications(locals, profile, 7, 3, importador != null) : [],
		getAssignedEditorObras(locals, profile, true),
		getPublishedAssignedSummary(locals, profile),
		getInformesVisibles(locals.supabase, profile),
		isAdminOrIp ? null : loadProjectProgress()
	]);

	return { profile, overview, recentActivity, assignedEditorObras, publishedAssignedSummary, projectProgress, informesMigracion: informesMigracion.length };
};

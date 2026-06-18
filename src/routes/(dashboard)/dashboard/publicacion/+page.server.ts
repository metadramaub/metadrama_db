import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { canManagePublicacion } from '$lib/utils/permissions';
import type { PublicSection, SectionScope } from '$lib/secciones-publicas';

export const load: PageServerLoad = async ({ locals, parent }) => {
	const { profile } = await parent();
	const canManage = canManagePublicacion(profile.roleTerm);
	if (!canManage) {
		throw error(403, 'Solo admin o IP pueden gestionar la publicación.');
	}

	// Dato fresco (no el caché público): el panel debe ver el estado real.
	const { data, error: dbError } = await locals.supabase
		.from('secciones_publicas')
		.select('seccion_id,label,descripcion,activa,scope_minimo,orden')
		.order('orden');

	if (dbError) {
		throw error(500, `No se pudieron cargar las secciones públicas: ${dbError.message}`);
	}

	const secciones: PublicSection[] = (data ?? []).map((row) => ({
		seccion_id: row.seccion_id,
		label: row.label,
		descripcion: row.descripcion,
		activa: row.activa,
		scope_minimo: row.scope_minimo as SectionScope,
		orden: row.orden
	}));

	// Páginas vs sub-secciones de ficha, por el prefijo del slug.
	const paginas = secciones.filter((s) => !s.seccion_id.startsWith('ficha.'));
	const ficha = secciones.filter((s) => s.seccion_id.startsWith('ficha.'));

	return { profile, canManage, paginas, ficha };
};

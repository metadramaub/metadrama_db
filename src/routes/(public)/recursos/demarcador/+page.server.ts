import { error } from '@sveltejs/kit';
import type { PageServerLoad } from './$types';
import { obtenerCatalogoDemarcador } from '$lib/server/demarcador-metrico';
import { resolvePublicViewerContext } from '$lib/server/public-obras';
import { requireSectionVisible } from '$lib/server/secciones-publicas';

const CATALOGO_VACIO = { formas: [], hipotesis: [], relaciones: [], advertencias: [] };

export const load: PageServerLoad = async ({ locals }) => {
	await requireSectionVisible(locals, 'demarcador');

	/**
	 * **La puerta se comprueba aquí, antes de pedir nada.**
	 *
	 * Durante la fase de pruebas el catálogo del demarcador solo se sirve a admin e IP, y hasta
	 * ahora eso lo resolvía `obtener_catalogo_demarcador()` devolviendo vacío: cualquier editor
	 * autenticado hacía el viaje entero para no traerse nada. Comprobar el alcance primero ahorra
	 * ese viaje y, sobre todo, **permite guardar el catálogo en memoria**, porque ya no hay dos
	 * respuestas distintas según quién pregunte. La función SQL sigue siendo la puerta de atrás.
	 */
	const viewer = await resolvePublicViewerContext(locals);
	if (viewer.scope !== 'admin_ip') {
		return { catalogo: CATALOGO_VACIO, accesoRestringido: true };
	}

	try {
		const catalogo = await obtenerCatalogoDemarcador(locals.supabase);
		return {
			catalogo,
			accesoRestringido: catalogo.hipotesis.length === 0
		};
	} catch (cause) {
		throw error(
			500,
			cause instanceof Error
				? `No se pudo preparar el demarcador: ${cause.message}`
				: 'No se pudo preparar el demarcador.'
		);
	}
};

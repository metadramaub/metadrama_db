import type { LayoutServerLoad } from './$types';
import { resolvePublicViewerContext } from '$lib/server/public-obras';
import { loadPublicSections } from '$lib/server/secciones-publicas';
import { buildSectionVisibilityMap } from '$lib/secciones-publicas';

// Carga única por request: resuelve el scope del visitante y el mapa de
// secciones visibles, disponible para toda la zona pública vía $page.data.
export const load: LayoutServerLoad = async ({ locals }) => {
	const viewer = await resolvePublicViewerContext(locals);
	const sections = await loadPublicSections(locals);

	return {
		viewerScope: viewer.scope,
		sectionVisibility: buildSectionVisibilityMap(sections, viewer.scope)
	};
};

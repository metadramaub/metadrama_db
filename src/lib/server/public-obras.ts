import { canReadAllObras, normalizeRole } from '$lib/utils/permissions';

export type PublicViewerScope = 'anon' | 'authenticated' | 'admin_ip';

export type PublicViewerContext = {
	scope: PublicViewerScope;
	userId: string | null;
	roleTerm: string | null;
	canSeeAllPublished: boolean;
};

/**
 * Datos mínimos de una obra necesarios para resolver su visibilidad pública.
 * El muro `estado = publicado` se aplica fuera (en la query o en la RPC), pero
 * `editor_asignado` y `visible_publico` deciden la atenuación por obra.
 */
export type PublicObraVisibility = {
	editor_asignado: string | null;
	visible_publico: boolean | null;
};

/**
 * Scope EFECTIVO para el par (visitante, obra). A diferencia del scope global del
 * visitante, esto contempla que el editor asignado a ESTA obra la ve como admin/IP.
 *
 * No decide acceso por sí solo: el muro `estado = publicado` es innegociable y se
 * aplica aparte. Aquí solo se resuelve si el visitante puede ver una obra publicada
 * que aún no es `visible_publico`.
 */
export function resolveObraScope(
	viewer: PublicViewerContext,
	obra: PublicObraVisibility
): PublicViewerScope {
	if (viewer.scope === 'admin_ip') {
		return 'admin_ip';
	}
	if (viewer.userId && obra.editor_asignado === viewer.userId) {
		// Editor asignado a su propia obra: la ve como admin/IP (para revisar su trabajo).
		return 'admin_ip';
	}
	return viewer.scope;
}

/**
 * ¿Puede este visitante ver el contenido público de una obra YA PUBLICADA?
 * Presupone que el muro `estado = publicado` ya se cumplió. Una obra publicada
 * pero no visible solo la ven admin/IP y el editor asignado (scope efectivo
 * `admin_ip`).
 */
export function canViewPublishedObra(
	viewer: PublicViewerContext,
	obra: PublicObraVisibility
): boolean {
	if (obra.visible_publico) {
		return true;
	}
	return resolveObraScope(viewer, obra) === 'admin_ip';
}

// Cache por request: el cliente supabase de locals es único por request
// (se crea en hooks.server.ts), así que sirve de clave. Evita recalcular el
// scope (hasta 3 queries) cuando layout + página lo piden en el mismo request.
const viewerContextCache = new WeakMap<object, Promise<PublicViewerContext>>();

export function resolvePublicViewerContext(locals: App.Locals): Promise<PublicViewerContext> {
	const key = locals.supabase as unknown as object;
	const cached = viewerContextCache.get(key);
	if (cached) {
		return cached;
	}
	const pending = computePublicViewerContext(locals);
	viewerContextCache.set(key, pending);
	return pending;
}

async function computePublicViewerContext(locals: App.Locals): Promise<PublicViewerContext> {
	const { user } = await locals.safeGetSession();
	if (!user) {
		return {
			scope: 'anon',
			userId: null,
			roleTerm: null,
			canSeeAllPublished: false
		};
	}

	const editorResp = await locals.supabase
		.from('editores')
		.select('role,activo')
		.eq('user_id', user.id)
		.maybeSingle();

	if (editorResp.error || !editorResp.data || editorResp.data.activo === false) {
		return {
			scope: 'authenticated',
			userId: user.id,
			roleTerm: null,
			canSeeAllPublished: false
		};
	}

	const roleResp = await locals.supabase
		.from('vocabularios')
		.select('termino')
		.eq('termino_id', editorResp.data.role)
		.maybeSingle();

	const roleTerm = roleResp.data?.termino ? normalizeRole(roleResp.data.termino) : null;
	// Misma regla "admin o IP" que el resto del sistema (permissions.ts), no reimplementada.
	const canSeeAllPublished = roleTerm ? canReadAllObras(roleTerm) : false;

	return {
		scope: canSeeAllPublished ? 'admin_ip' : 'authenticated',
		userId: user.id,
		roleTerm,
		canSeeAllPublished
	};
}

export async function getPublicadoEstadoId(locals: App.Locals): Promise<string | null> {
	const { data } = await locals.supabase
		.from('vocabularios')
		.select('termino_id')
		.eq('categoria', 'estado')
		.ilike('termino', 'publicado')
		.maybeSingle();

	return data?.termino_id ?? null;
}

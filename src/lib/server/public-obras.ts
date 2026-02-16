export type PublicViewerScope = 'anon' | 'authenticated' | 'admin_ip';

export type PublicViewerContext = {
	scope: PublicViewerScope;
	userId: string | null;
	roleTerm: string | null;
	canSeeAllPublished: boolean;
};

export async function resolvePublicViewerContext(locals: App.Locals): Promise<PublicViewerContext> {
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

	const roleTerm = roleResp.data?.termino?.trim().toLowerCase() ?? null;
	const canSeeAllPublished = roleTerm === 'admin' || roleTerm === 'ip';

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

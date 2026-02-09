import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';

export const GET: RequestHandler = async ({ locals, url }) => {
	await requireEditorProfile({ locals });
	const categoriasParam = url.searchParams.get('categorias');
	const categorias = categoriasParam
		? categoriasParam
				.split(',')
				.map((item) => item.trim())
				.filter(Boolean)
		: null;

	let query = locals.supabase
		.from('vocabularios')
		.select('termino_id,categoria,termino,termino_padre_id,nivel,orden,patron_especifico,activo')
		.eq('activo', true)
		.order('categoria')
		.order('orden', { ascending: true });

	if (categorias && categorias.length > 0) {
		query = query.in('categoria', categorias);
	}

	const { data, error } = await query;
	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}

	return json({ vocabularios: data ?? [] });
};

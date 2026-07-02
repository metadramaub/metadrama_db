import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';

// Búsqueda ligera de autores para selectores (p. ej. AuthorSelector en Autoría).
// Filtra en la BD con ilike + limit en vez de traer todo el catálogo.
export const GET: RequestHandler = async ({ locals, url }) => {
	await requireEditorProfile({ locals });

	const q = (url.searchParams.get('q') ?? '').trim();
	const limit = Math.min(Math.max(Number(url.searchParams.get('limit')) || 20, 1), 50);

	let query = locals.supabase
		.from('autores')
		.select('autor_id,nombre_completo,nombre_normalizado')
		.order('nombre_normalizado', { ascending: true })
		.limit(limit);

	if (q.length > 0) {
		const pattern = `%${q}%`;
		query = query.or(
			`nombre_completo.ilike.${pattern},nombre_normalizado.ilike.${pattern}`
		);
	}

	const { data, error } = await query;
	if (error) {
		return json({ error: 'db_error', message: error.message }, { status: 500 });
	}

	return json({ authors: data ?? [] });
};

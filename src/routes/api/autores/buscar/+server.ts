import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorProfile } from '$lib/server/auth';

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

// Búsqueda ligera de autores para selectores (p. ej. AuthorSelector en Autoría).
// Filtra en la BD con ilike + limit en vez de traer todo el catálogo.
export const GET: RequestHandler = async ({ locals, url }) => {
	await requireEditorProfile({ locals });

	const q = (url.searchParams.get('q') ?? '').trim();
	const rawIds = url.searchParams.get('ids');
	const ids = [
		...new Set(
			(rawIds ?? '')
				.split(',')
				.map((id) => id.trim())
				.filter((id) => UUID_RE.test(id))
		)
	].slice(0, 100);
	const limit = Math.min(Math.max(Number(url.searchParams.get('limit')) || 20, 1), 50);

	if (rawIds !== null && ids.length === 0) {
		return json({ authors: [] });
	}

	let query = locals.supabase
		.from('autores')
		.select('autor_id,nombre_completo,nombre_normalizado')
		.order('nombre_normalizado', { ascending: true });

	if (ids.length > 0) {
		query = query.in('autor_id', ids);
	} else {
		query = query.limit(limit);
	}

	if (ids.length === 0 && q.length > 0) {
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

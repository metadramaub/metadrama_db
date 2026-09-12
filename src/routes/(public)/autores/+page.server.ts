import type { PageServerLoad } from './$types';
import { getWikidataImage } from '$lib/server/wikidata-images';
import { requireSectionVisible } from '$lib/server/secciones-publicas';
import { resolvePublicViewerContext } from '$lib/server/public-obras';
import { loadPublicArtifact, publicArtifactKeys } from '$lib/server/public-artifacts';
import type { AutorListadoItem } from '$lib/autores/perfil-autor';
import type { AutoresIndexArtifactPayload } from '$lib/types/public-artifacts.types';

async function mapWithConcurrency<T, U>(
	items: T[],
	limit: number,
	mapper: (item: T) => Promise<U>
): Promise<U[]> {
	const results = new Array<U>(items.length);
	let nextIndex = 0;

	async function worker() {
		while (nextIndex < items.length) {
			const index = nextIndex;
			nextIndex += 1;
			results[index] = await mapper(items[index]);
		}
	}

	await Promise.all(Array.from({ length: Math.min(limit, items.length) }, worker));
	return results;
}

export const load: PageServerLoad = async ({ fetch, locals }) => {
	await requireSectionVisible(locals, 'autores');

	const viewer = await resolvePublicViewerContext(locals);
	const alcance = viewer.canSeeAllPublished ? 'completo' : 'publico';
	const artifact = await loadPublicArtifact<AutoresIndexArtifactPayload>(
		locals.supabase,
		publicArtifactKeys.autoresIndice(alcance)
	);

	// Compatibilidad durante el primer despliegue, antes de que finalice la primera cola global.
	let rows: AutorListadoItem[] | null = artifact?.payload.autores ?? null;
	if (!rows) {
		const { data, error: rpcError } = await locals.supabase.rpc('get_autores_listado_publico');
		rows = ((rpcError ? null : (data as AutorListadoItem[] | null)) ?? []) as AutorListadoItem[];
	}
	const autores = await mapWithConcurrency(rows ?? [], 6, async (autor) => ({
		...autor,
		top_obras: autor.top_obras ?? [],
		imagen_wikidata: await getWikidataImage(autor.wikidata_id, fetch)
	}));

	// El perfil guarda slugs del catálogo métrico; el nombre visible se resuelve aquí, igual que en
	// la ficha del autor, para que las dos pantallas llamen a cada forma de la misma manera.
	const { data: formasData } = await locals.supabase.from('formas_metricas').select('slug,nombre');
	const formaLabels = Object.fromEntries(
		((formasData ?? []) as Array<{ slug: string; nombre: string }>).map((forma) => [
			forma.slug,
			forma.nombre
		])
	);

	return { autores, formaLabels };
};

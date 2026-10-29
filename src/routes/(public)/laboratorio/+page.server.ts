import type { PageServerLoad } from './$types';
import { loadPublicArtifact, publicArtifactKeys } from '$lib/server/public-artifacts';
import { resolvePublicViewerContext } from '$lib/server/public-obras';
import { requireSectionVisible } from '$lib/server/secciones-publicas';
import { corpusCompatible, type ReadableCorpus } from '$lib/laboratorio/corpus-compat';

export const load: PageServerLoad = async ({ locals }) => {
	await requireSectionVisible(locals, 'laboratorio');

	const viewer = await resolvePublicViewerContext(locals);
	const alcance = viewer.canSeeAllPublished ? 'completo' : 'publico';
	const artifact = await loadPublicArtifact<ReadableCorpus>(
		locals.supabase,
		publicArtifactKeys.corpusComparativas(alcance)
	);

	const corpus =
		artifact && [2, 3].includes(artifact.version) ? corpusCompatible(artifact.payload) : null;
	if (!artifact || !corpus) {
		return { corpus: null, alcance, generatedAt: null, stale: false };
	}

	return {
		corpus,
		alcance,
		generatedAt: artifact.generatedAt,
		stale: artifact.stale
	};
};

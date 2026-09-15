import type { PageServerLoad } from './$types';
import { loadPublicArtifact, publicArtifactKeys } from '$lib/server/public-artifacts';
import { resolvePublicViewerContext } from '$lib/server/public-obras';
import { requireSectionVisible } from '$lib/server/secciones-publicas';
import type { CorpusComparisonsArtifactPayload } from '$lib/types/public-artifacts.types';

export const load: PageServerLoad = async ({ locals }) => {
	await requireSectionVisible(locals, 'laboratorio');

	const viewer = await resolvePublicViewerContext(locals);
	const alcance = viewer.canSeeAllPublished ? 'completo' : 'publico';
	const artifact = await loadPublicArtifact<CorpusComparisonsArtifactPayload>(
		locals.supabase,
		publicArtifactKeys.corpusComparativas(alcance)
	);

	if (!artifact || artifact.version < 2 || artifact.payload.schema_version !== 2) {
		return { corpus: null, alcance, generatedAt: null, stale: false };
	}

	return {
		corpus: artifact.payload,
		alcance,
		generatedAt: artifact.generatedAt,
		stale: artifact.stale
	};
};

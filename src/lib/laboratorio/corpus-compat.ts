import type {
	CorpusComparisonsArtifactPayload,
	CorpusComparisonWork,
	CorpusEnunciationComparison,
	ObraEnunciationEntry
} from '$lib/types/public-artifacts.types';

/** V2 solo difiere en prosa, que se trataba incorrectamente como extensión. */
type LegacyCorpus = Omit<
	CorpusComparisonsArtifactPayload,
	'schema_version' | 'obras' | 'enunciacion'
> & {
	schema_version: 2;
	obras: Array<
		Omit<CorpusComparisonWork, 'enunciacion'> & {
			enunciacion: Record<string, ObraEnunciationEntry>;
		}
	>;
	enunciacion: Record<string, CorpusEnunciationComparison>;
};

export type ReadableCorpus = LegacyCorpus | CorpusComparisonsArtifactPayload;

/** Adaptación de JSON precomputado; no calcula métricas ni consulta anotaciones. */
export function corpusCompatible(payload: ReadableCorpus): CorpusComparisonsArtifactPayload | null {
	if (payload.schema_version === 3) return payload;
	if (payload.schema_version !== 2) return null;
	const sinProsa = <T>(entrada: Record<string, T>) => ({
		...(entrada.cantado ? { cantado: entrada.cantado } : {}),
		...(entrada.evocacion_metrica ? { evocacion_metrica: entrada.evocacion_metrica } : {})
	});
	// Se omite el dato inválido de V2: no equivale a afirmar ausencia de prosa.
	return {
		...payload,
		schema_version: 3,
		enunciacion: sinProsa(payload.enunciacion),
		obras: payload.obras.map((obra) => ({ ...obra, enunciacion: sinProsa(obra.enunciacion) }))
	};
}

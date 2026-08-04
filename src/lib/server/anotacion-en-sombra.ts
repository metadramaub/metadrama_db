/**
 * Anotación en sombra: fase 0 de la migración de anotaciones.
 *
 * Lee las obras abiertas al editor V2, sus secuencias reales y lo que el catálogo nuevo
 * propone para cada una. No escribe nunca en `secuencias_metricas`: aquí solo se lee lo que
 * dice el modelo viejo para poder contrastarlo con lo que dice el nuevo.
 *
 * Ver docs/dominio-metrico/plan-migracion-anotaciones.md §6.
 */

import type {
	ShadowAnswer,
	ShadowAnnotationData,
	ShadowCandidateWork,
	ShadowSequence,
	ShadowWork
} from '$lib/metrica/anotacion-en-sombra';

type UntypedSupabaseClient = {
	from: (table: string) => any;
};

type QueryError = { code?: string; message: string };

function throwQueryError(context: string, error: QueryError | null): void {
	if (!error) return;
	throw new Error(`${context}: ${error.message}`);
}

const EMPTY: ShadowAnnotationData = { works: [], sequences: [], candidates: [] };

/**
 * Carga el estado de la anotación en sombra. Devuelve vacío —y no revienta la página del
 * catálogo— si la fase todavía no se ha abierto en esta base.
 */
export async function loadShadowAnnotation(
	client: unknown
): Promise<ShadowAnnotationData> {
	const db = client as UntypedSupabaseClient;

	const worksResponse = await db
		.from('obras_editor_metrico_v2')
		.select('obra_id,nota,obras(titulo)')
		.order('created_at', { ascending: true });

	// La tabla no existe todavía o el rol no la ve: la fase no está abierta aquí.
	if (worksResponse.error) {
		if (
			worksResponse.error.code === '42P01' ||
			worksResponse.error.code === 'PGRST205' ||
			worksResponse.error.code === '42501'
		) {
			return EMPTY;
		}
		throwQueryError('No se pudieron cargar las obras abiertas al editor V2', worksResponse.error);
	}

	const workRows = worksResponse.data ?? [];
	const openedIds = new Set(workRows.map((row: any) => String(row.obra_id)));

	// La vista entera son ~260 filas: cabe de sobra, y con ella se calculan a la vez las
	// secuencias de las obras abiertas y las candidatas del selector.
	const [
		proposalResponse,
		shadowResponse,
		subtypeResponse,
		characterizationResponse,
		obrasResponse,
		answersResponse
	] =
		await Promise.all([
			db
				.from('propuesta_metrica_secuencia')
				.select(
					'secuencia_id,obra_id,v_ini,v_fin,estrofa_tipo_id,termino_legado,forma_propuesta_id,forma_propuesta,arquitectura_propuesta_id,arquitectura_propuesta,via,detalle,heredado_de'
				)
				.order('v_ini', { ascending: true }),
			db
				.from('secuencias_editor_metrico')
				.select('secuencia_prueba_id,secuencia_id,forma_id,arquitectura_id')
				.not('secuencia_id', 'is', null),
			db.from('secuencias_subtipos_estrofa').select('secuencia_id'),
			db.from('secuencias_caracterizaciones_rango').select('secuencia_id'),
			db.from('obras').select('obra_id,titulo'),
			db
				.from('propuesta_elecciones_secuencia')
				.select('secuencia_id,grupo_eleccion_id,pregunta,opcion_eleccion_id,respuesta,alcance')
		]);

	throwQueryError('No se pudo cargar la propuesta métrica', proposalResponse.error);
	throwQueryError('No se pudieron cargar las obras', obrasResponse.error);
	throwQueryError('No se pudieron cargar las respuestas propuestas', answersResponse.error);
	throwQueryError('No se pudieron cargar las anotaciones en sombra', shadowResponse.error);
	throwQueryError('No se pudieron cargar los subtipos estróficos', subtypeResponse.error);
	throwQueryError(
		'No se pudieron cargar las caracterizaciones por rango',
		characterizationResponse.error
	);

	const shadowBySequence = new Map<string, any>();
	for (const row of shadowResponse.data ?? []) {
		shadowBySequence.set(String(row.secuencia_id), row);
	}

	const countBy = (rows: any[] | null): Map<string, number> => {
		const counts = new Map<string, number>();
		for (const row of rows ?? []) {
			const key = String(row.secuencia_id);
			counts.set(key, (counts.get(key) ?? 0) + 1);
		}
		return counts;
	};
	const answersBySequence = new Map<string, ShadowAnswer[]>();
	for (const row of answersResponse.data ?? []) {
		const key = String(row.secuencia_id);
		const list = answersBySequence.get(key) ?? [];
		list.push({
			grupoEleccionId: String(row.grupo_eleccion_id),
			pregunta: String(row.pregunta),
			opcionEleccionId: String(row.opcion_eleccion_id),
			respuesta: String(row.respuesta),
			alcance: row.alcance === 'unidad' ? 'unidad' : 'secuencia'
		});
		answersBySequence.set(key, list);
	}

	const subtypeCounts = countBy(subtypeResponse.data);
	const characterizationCounts = countBy(characterizationResponse.data);

	const allSequences: ShadowSequence[] = (proposalResponse.data ?? []).map((row: any) => {
		const secuenciaId = String(row.secuencia_id);
		const shadow = shadowBySequence.get(secuenciaId) ?? null;
		return {
			secuenciaId,
			obraId: String(row.obra_id),
			vIni: Number(row.v_ini),
			vFin: Number(row.v_fin),
			versos: Number(row.v_fin) - Number(row.v_ini) + 1,
			terminoLegado: row.termino_legado ?? null,
			estrofaTipoId: row.estrofa_tipo_id ? String(row.estrofa_tipo_id) : null,
			formaPropuestaId: row.forma_propuesta_id ? String(row.forma_propuesta_id) : null,
			formaPropuesta: row.forma_propuesta ?? null,
			arquitecturaPropuestaId: row.arquitectura_propuesta_id
				? String(row.arquitectura_propuesta_id)
				: null,
			arquitecturaPropuesta: row.arquitectura_propuesta ?? null,
			via: (row.via ?? 'sin_tipo') as ShadowSequence['via'],
			detalle: row.detalle ?? null,
			heredadoDe: row.heredado_de ?? null,
			respuestas: answersBySequence.get(secuenciaId) ?? [],
			subtipos: subtypeCounts.get(secuenciaId) ?? 0,
			caracterizaciones: characterizationCounts.get(secuenciaId) ?? 0,
			pruebaId: shadow ? String(shadow.secuencia_prueba_id) : null,
			formaAnotadaId: shadow?.forma_id ? String(shadow.forma_id) : null,
			arquitecturaAnotadaId: shadow?.arquitectura_id ? String(shadow.arquitectura_id) : null
		};
	});

	// Solo viajan al cliente las secuencias de las obras abiertas. Las demás se resumen.
	const sequences = allSequences.filter((sequence) => openedIds.has(sequence.obraId));

	type Aggregate = {
		secuencias: number;
		anotadas: number;
		sinCorrespondencia: number;
		terminos: Map<string, number>;
	};
	const totals = new Map<string, Aggregate>();
	for (const sequence of allSequences) {
		const entry = totals.get(sequence.obraId) ?? {
			secuencias: 0,
			anotadas: 0,
			sinCorrespondencia: 0,
			terminos: new Map<string, number>()
		};
		entry.secuencias += 1;
		if (sequence.pruebaId) entry.anotadas += 1;
		if (!sequence.formaPropuestaId) entry.sinCorrespondencia += 1;
		const termino = sequence.terminoLegado ?? '(sin término)';
		entry.terminos.set(termino, (entry.terminos.get(termino) ?? 0) + 1);
		totals.set(sequence.obraId, entry);
	}

	const emptyAggregate = (): Aggregate => ({
		secuencias: 0,
		anotadas: 0,
		sinCorrespondencia: 0,
		terminos: new Map<string, number>()
	});

	const works: ShadowWork[] = workRows.map((row: any) => {
		const obraId = String(row.obra_id);
		const entry = totals.get(obraId) ?? emptyAggregate();
		return {
			obraId,
			titulo: row.obras?.titulo ?? '(obra sin título)',
			nota: row.nota ?? null,
			secuencias: entry.secuencias,
			anotadas: entry.anotadas
		};
	});

	const candidates: ShadowCandidateWork[] = (obrasResponse.data ?? [])
		.map((row: any) => {
			const obraId = String(row.obra_id);
			const entry = totals.get(obraId) ?? emptyAggregate();
			return {
				obraId,
				titulo: String(row.titulo),
				secuencias: entry.secuencias,
				formas: [...entry.terminos.entries()]
					.sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0], 'es'))
					.map(([termino]) => termino),
				sinCorrespondencia: entry.sinCorrespondencia,
				abierta: openedIds.has(obraId)
			};
		})
		// Una obra sin secuencias métricas no se puede anotar en sombra.
		.filter((work: ShadowCandidateWork) => work.secuencias > 0)
		.sort(
			(a: ShadowCandidateWork, b: ShadowCandidateWork) =>
				b.secuencias - a.secuencias || a.titulo.localeCompare(b.titulo, 'es')
		);

	return { works, sequences, candidates };
}

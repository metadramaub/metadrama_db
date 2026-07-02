import type { Tables } from '$lib/types/database.types';
import { loadInternalVocabulario } from '$lib/server/catalogos-internos';

export type ComentarioContextRow = Pick<
	Tables<'comentarios_internos'>,
	'seccion' | 'secuencia_id' | 'jornada_id' | 'cuadro_id'
>;

export type ComentarioTipoTerm =
	| 'general'
	| 'revision'
	| 'tecnico'
	| 'estado'
	| 'nota_propia'
	| 'observacion_publica';

export type ComentarioContextMaps = {
	secuenciaById: Map<
		string,
		Pick<Tables<'secuencias_metricas'>, 'secuencia_id' | 'v_ini' | 'v_fin' | 'estrofa_tipo_id'>
	>;
	secuenciaEstrofaTermById: Map<string, string>;
	jornadaById: Map<
		string,
		Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>
	>;
	cuadroById: Map<
		string,
		Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'>
	>;
};

export async function loadComentarioContextMaps(
	locals: App.Locals,
	commentsRows: ComentarioContextRow[]
): Promise<ComentarioContextMaps> {
	const secuenciaIds = [
		...new Set(commentsRows.map((comment) => comment.secuencia_id).filter(Boolean) as string[])
	];
	const directJornadaIds = [
		...new Set(commentsRows.map((comment) => comment.jornada_id).filter(Boolean) as string[])
	];
	const cuadroIds = [...new Set(commentsRows.map((comment) => comment.cuadro_id).filter(Boolean) as string[])];

	const [secuenciasResp, cuadrosResp] = await Promise.all([
		secuenciaIds.length > 0
			? locals.supabase
					.from('secuencias_metricas')
					.select('secuencia_id,v_ini,v_fin,estrofa_tipo_id')
					.in('secuencia_id', secuenciaIds)
			: Promise.resolve({
					data: [] as Pick<
						Tables<'secuencias_metricas'>,
						'secuencia_id' | 'v_ini' | 'v_fin' | 'estrofa_tipo_id'
					>[]
				}),
		cuadroIds.length > 0
			? locals.supabase
					.from('cuadros')
					.select('cuadro_id,cuadro_num,jornada_id,v_ini,v_fin')
					.in('cuadro_id', cuadroIds)
			: Promise.resolve({
					data: [] as Pick<Tables<'cuadros'>, 'cuadro_id' | 'cuadro_num' | 'jornada_id' | 'v_ini' | 'v_fin'>[]
				})
	]);

	const secuenciaRows = secuenciasResp.data ?? [];
	const cuadroRows = cuadrosResp.data ?? [];
	const jornadaIds = [
		...new Set([
			...directJornadaIds,
			...cuadroRows.map((row) => row.jornada_id).filter(Boolean)
		] as string[])
	];
	const estrofaTipoIds = [
		...new Set(secuenciaRows.map((row) => row.estrofa_tipo_id).filter(Boolean) as string[])
	];

	const [jornadasResp, estrofas] = await Promise.all([
		jornadaIds.length > 0
			? locals.supabase
					.from('jornadas')
					.select('jornada_id,jornada_num,v_ini,v_fin')
					.in('jornada_id', jornadaIds)
			: Promise.resolve({
					data: [] as Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>[]
				}),
		estrofaTipoIds.length > 0
			? loadInternalVocabulario(locals.supabase, ['estrofa_tipo'])
			: Promise.resolve([])
	]);

	const estrofaTipoIdSet = new Set(estrofaTipoIds);
	const estrofaTermById = new Map(
		estrofas
			.filter((row) => estrofaTipoIdSet.has(row.termino_id))
			.map((row) => [row.termino_id, row.termino])
	);
	const secuenciaEstrofaTermById = new Map<string, string>();
	for (const secuencia of secuenciaRows) {
		const estrofaTerminoId = secuencia.estrofa_tipo_id;
		if (!estrofaTerminoId) continue;
		const estrofaTerm = estrofaTermById.get(estrofaTerminoId);
		if (estrofaTerm) {
			secuenciaEstrofaTermById.set(secuencia.secuencia_id, estrofaTerm);
		}
	}

	return {
		secuenciaById: new Map(secuenciaRows.map((row) => [row.secuencia_id, row])),
		secuenciaEstrofaTermById,
		jornadaById: new Map((jornadasResp.data ?? []).map((row) => [row.jornada_id, row])),
		cuadroById: new Map(cuadroRows.map((row) => [row.cuadro_id, row]))
	};
}

export function formatComentarioTipoLabel(tipo: ComentarioTipoTerm | string | null | undefined): string {
	switch ((tipo ?? 'general').trim().toLowerCase()) {
		case 'revision':
			return 'solicita revision';
		case 'tecnico':
			return 'soporte tecnico';
		case 'estado':
			return 'cambio de estado';
		case 'nota_propia':
			return 'nota propia';
		case 'observacion_publica':
			return 'observacion publica';
		default:
			return 'general';
	}
}

export function buildComentarioContextLabel(
	comment: ComentarioContextRow,
	maps: ComentarioContextMaps
): string | null {
	if (comment.seccion === 'datos') return 'Datos de la obra';
	if (comment.seccion === 'estructura') return 'Estructura';
	if (comment.seccion === 'secuencias') return 'Secuencias';
	if (comment.seccion === 'autoria') return 'Autoria';
	if (comment.seccion === 'observaciones') return 'Observaciones';
	if (comment.seccion === 'revision') return 'Revision final';

	if (comment.secuencia_id) {
		const secuencia = maps.secuenciaById.get(comment.secuencia_id);
		return secuencia ? `Secuencia vv. ${secuencia.v_ini}-${secuencia.v_fin}` : 'Secuencia';
	}

	if (comment.cuadro_id) {
		const cuadro = maps.cuadroById.get(comment.cuadro_id);
		if (!cuadro) return 'Cuadro';
		const jornada = cuadro.jornada_id ? maps.jornadaById.get(cuadro.jornada_id) : null;
		if (jornada) {
			return `Jornada ${jornada.jornada_num} · Cuadro ${cuadro.cuadro_num} (vv. ${cuadro.v_ini}-${cuadro.v_fin})`;
		}
		return `Cuadro ${cuadro.cuadro_num} (vv. ${cuadro.v_ini}-${cuadro.v_fin})`;
	}

	if (comment.jornada_id) {
		const jornada = maps.jornadaById.get(comment.jornada_id);
		return jornada ? `Jornada ${jornada.jornada_num} (vv. ${jornada.v_ini}-${jornada.v_fin})` : 'Jornada';
	}

	return null;
}

export function buildComentarioSecuenciaEstrofaTerm(
	comment: Pick<ComentarioContextRow, 'secuencia_id'>,
	maps: ComentarioContextMaps
): string | null {
	if (!comment.secuencia_id) return null;
	return maps.secuenciaEstrofaTermById.get(comment.secuencia_id) ?? null;
}

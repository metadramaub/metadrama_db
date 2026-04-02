import type { Tables } from '$lib/types/database.types';

export type ComentarioContextRow = Pick<
	Tables<'comentarios_internos'>,
	'seccion' | 'secuencia_id' | 'jornada_id' | 'cuadro_id' | 'rango_id'
>;

export type ComentarioTipoTerm = 'general' | 'revision' | 'tecnico' | 'estado';

export type ComentarioContextMaps = {
	secuenciaById: Map<
		string,
		Pick<Tables<'secuencias_metricas'>, 'secuencia_id' | 'v_ini' | 'v_fin'>
	>;
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
					.select('secuencia_id,v_ini,v_fin')
					.in('secuencia_id', secuenciaIds)
			: Promise.resolve({
					data: [] as Pick<Tables<'secuencias_metricas'>, 'secuencia_id' | 'v_ini' | 'v_fin'>[]
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

	const cuadroRows = cuadrosResp.data ?? [];
	const jornadaIds = [
		...new Set([
			...directJornadaIds,
			...cuadroRows.map((row) => row.jornada_id).filter(Boolean)
		] as string[])
	];

	const jornadasResp =
		jornadaIds.length > 0
			? await locals.supabase
					.from('jornadas')
					.select('jornada_id,jornada_num,v_ini,v_fin')
					.in('jornada_id', jornadaIds)
			: {
					data: [] as Pick<Tables<'jornadas'>, 'jornada_id' | 'jornada_num' | 'v_ini' | 'v_fin'>[]
				};

	return {
		secuenciaById: new Map((secuenciasResp.data ?? []).map((row) => [row.secuencia_id, row])),
		jornadaById: new Map((jornadasResp.data ?? []).map((row) => [row.jornada_id, row])),
		cuadroById: new Map(cuadroRows.map((row) => [row.cuadro_id, row]))
	};
}

export function formatComentarioTipoLabel(tipo: ComentarioTipoTerm | string | null | undefined): string {
	switch ((tipo ?? 'general').trim().toLowerCase()) {
		case 'revision':
			return 'solicita revisión';
		case 'tecnico':
			return 'soporte técnico';
		case 'estado':
			return 'cambio de estado';
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
	if (comment.seccion === 'autoria') return 'Autoría';
	if (comment.seccion === 'observaciones') return 'Observaciones';
	if (comment.seccion === 'revision') return 'Revisión final';

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

	if (comment.rango_id) return 'Rango de autoría';
	return null;
}

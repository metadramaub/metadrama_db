import type { PublicFichaComentarioPublico } from '$lib/types/public-ficha.types';

export interface SecuenciaDeAclaracion {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	forma_nombre: string;
}

export function agruparAclaracionesPublicas(
	comentarios: PublicFichaComentarioPublico[],
	secuencias: SecuenciaDeAclaracion[]
) {
	const porId = new Map(secuencias.map((s) => [s.secuencia_id, s]));
	const grupos = new Map<
		string,
		{
			secuenciaId: string | null;
			secuencia: SecuenciaDeAclaracion | null;
			comentarios: PublicFichaComentarioPublico[];
		}
	>();
	for (const comentario of comentarios) {
		const clave = comentario.secuencia_id ?? 'obra';
		let grupo = grupos.get(clave);
		if (!grupo) {
			grupo = {
				secuenciaId: comentario.secuencia_id,
				secuencia: porId.get(clave) ?? null,
				comentarios: []
			};
			grupos.set(clave, grupo);
		}
		grupo.comentarios.push(comentario);
	}
	return [...grupos.values()].sort((a, b) => {
		if (!a.secuenciaId) return b.secuenciaId ? -1 : 0;
		if (!b.secuenciaId) return 1;
		return (a.secuencia?.v_ini ?? Infinity) - (b.secuencia?.v_ini ?? Infinity);
	});
}

type Registro = Record<string, unknown>;
const objeto = (v: unknown): Registro =>
	v !== null && typeof v === 'object' && !Array.isArray(v) ? (v as Registro) : {};

/** Completa el envoltorio de la extracción en una copia, conservando el original. */
export function completarExtraccion(entrada: Registro): Registro {
	const notas = entrada.notas === undefined ? [] : entrada.notas;
	const metadatos = objeto(entrada.metadatos);
	const procedencia = objeto(entrada.procedencia);
	const notasPorTramo = new Map<string, string[]>();
	if (Array.isArray(notas)) {
		for (const nota of notas.map(objeto)) {
			if (typeof nota.id !== 'string' || !Array.isArray(nota.tramos_ref)) continue;
			for (const ref of nota.tramos_ref) {
				if (typeof ref !== 'string') continue;
				const ids = notasPorTramo.get(ref) ?? [];
				ids.push(nota.id);
				notasPorTramo.set(ref, ids);
			}
		}
	}
	return {
		estado_revision: 'borrador_ia',
		revision_humana: { responsable: null, fecha: null, resultado: 'pendiente' },
		resumen_fuente: [],
		incidencias: [],
		...entrada,
		obra_ref: entrada.obra_ref ?? 'obra-importada',
		metadatos: entrada.metadatos === undefined ? null : entrada.metadatos === metadatos ? {
			titulo: null, autoria: null, genero_literal: null, fecha_inicio: null, fecha_fin: null,
			fuente_fecha: null, edicion_base: null, observaciones: [], fuente_id: null,
			...metadatos
		} : entrada.metadatos,
		procedencia: entrada.procedencia === undefined || entrada.procedencia === procedencia ? {
			fecha: null,
			procedimiento: 'ejecucion_prompt',
			generador: null,
			modelo: null,
			prompt_version: 'sin-version',
			ensayo_controlado: false,
			...procedencia
		} : entrada.procedencia,
		notas,
		tramos: Array.isArray(entrada.tramos) ? entrada.tramos.map((tramo) => {
			const fila = objeto(tramo);
			if (typeof fila.id !== 'string' || fila.notas_ref !== undefined) return tramo;
			return { ...fila, notas_ref: notasPorTramo.get(fila.id) ?? [] };
		}) : entrada.tramos
	};
}

/**
 * Orden de lectura de las modalidades métricas.
 *
 * `definitoria` solo aparece en realizaciones internas de una arquitectura; las arquitecturas
 * empiezan en `habitual`. Los valores desconocidos quedan al final y el nombre resuelve los
 * empates para que el resultado no dependa del orden de llegada desde la base.
 */
export const ORDEN_DE_MODALIDAD = ['definitoria', 'habitual', 'admitida', 'excepcional'] as const;

export function rangoDeModalidad(modalidad: string | null | undefined): number {
	const indice = ORDEN_DE_MODALIDAD.indexOf(
		String(modalidad ?? '') as (typeof ORDEN_DE_MODALIDAD)[number]
	);
	return indice < 0 ? ORDEN_DE_MODALIDAD.length : indice;
}

export function compararPorModalidadYNombre(
	a: { modalidad?: string | null; nombre?: string | null; notacion?: string | null },
	b: { modalidad?: string | null; nombre?: string | null; notacion?: string | null }
): number {
	return (
		rangoDeModalidad(a.modalidad) - rangoDeModalidad(b.modalidad) ||
		String(a.nombre ?? a.notacion ?? '').localeCompare(String(b.nombre ?? b.notacion ?? ''), 'es', {
			sensitivity: 'base',
			numeric: true
		})
	);
}

/** Las dos propuestas son independientes. Los consumidores usan referencia salvo elección explícita. */
export type ClaseDatacion = 'referencia' | 'metrica';
export type Datacion = {
	clase: ClaseDatacion;
	inicio: number | null;
	fin: number | null;
	inicio_inclusivo: boolean;
	fin_inclusivo: boolean;
	aproximada: boolean;
	fuente: string | null;
};
export type ObraConDataciones = {
	dataciones?: unknown;
	fecha_inicio_trad?: number | null;
	fecha_fin_trad?: number | null;
	fecha_inicio_metadrama?: number | null;
	fecha_fin_metadrama?: number | null;
	fuente_fecha?: string | null;
};
export function datacionVacia(clase: ClaseDatacion): Datacion {
	return { clase, inicio: null, fin: null, inicio_inclusivo: true, fin_inclusivo: true, aproximada: false, fuente: null };
}
export function datacionDeObra(obra: ObraConDataciones, clase: ClaseDatacion = 'referencia'): Datacion {
	// La presencia del contrato nuevo (incluso []) prevalece sobre columnas históricas congeladas.
	if (Array.isArray(obra.dataciones)) {
		const d = obra.dataciones.find((item) => item?.clase === clase);
		return d ? { ...datacionVacia(clase), ...d } : datacionVacia(clase);
	}
	const inicio = (clase === 'referencia' ? obra.fecha_inicio_trad : obra.fecha_inicio_metadrama) ?? null;
	const fin = (clase === 'referencia' ? obra.fecha_fin_trad : obra.fecha_fin_metadrama) ?? null;
	// Los artefactos anteriores no distinguían un año de un límite: mantener su presentación
	// mientras se sirve la última copia coherente. Solo el contrato nuevo acredita límites abiertos.
	return { ...datacionVacia(clase),
		inicio: inicio ?? fin,
		fin: fin ?? inicio,
		fuente: clase === 'referencia' ? obra.fuente_fecha ?? null : null };
}
/** Años enteros admisibles; un límite abierto nunca se transforma en una fecha exacta. */
export function limitesDatacion(d: Datacion) {
	return { inicio: d.inicio === null ? null : d.inicio + (d.inicio_inclusivo ? 0 : 1),
		fin: d.fin === null ? null : d.fin - (d.fin_inclusivo ? 0 : 1) };
}
export function mediaDatacion(d: Datacion): number | null {
	const { inicio, fin } = limitesDatacion(d);
	return inicio === null || fin === null ? null : (inicio + fin) / 2;
}
export function coincideDatacion(d: Datacion, inicio: number | null, fin: number | null): boolean {
	const limites = limitesDatacion(d);
	if (limites.inicio === null && limites.fin === null) return inicio === null && fin === null;
	return (fin === null || limites.inicio === null || limites.inicio <= fin)
		&& (inicio === null || limites.fin === null || limites.fin >= inicio);
}
export function formatoDatacion(d: Datacion): string {
	const { inicio, fin } = d;
	if (inicio === null && fin === null) return 'Sin fecha';
	let texto: string;
	if (inicio === null) texto = `${d.fin_inclusivo ? '≤' : '<'}${fin}`;
	else if (fin === null) texto = `${d.inicio_inclusivo ? '≥' : '>'}${inicio}`;
	else if (inicio === fin && d.inicio_inclusivo && d.fin_inclusivo) texto = String(inicio);
	else texto = `${d.inicio_inclusivo ? '' : '>'}${inicio}–${d.fin_inclusivo ? '' : '<'}${fin}`;
	return `${d.aproximada ? 'c. ' : ''}${texto}`;
}

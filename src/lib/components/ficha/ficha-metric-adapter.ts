// Adapta los datos de la ficha pública (PublicFichaSecuencia) a los tipos de
// presentación genéricos de los componentes métricos reutilizables.
import type { PublicFichaSecuencia } from '$lib/types/public-ficha.types';
import type {
	MetricBarSegment,
	MetricSchemeEntry
} from '$lib/components/metrica/metric-display.types';
import type { SecuenciaAnalizable } from '$lib/metrica/analisis-ficha';
import {
	buildSequenceRhymeSchemeOccurrences,
	formatMetricCount
} from '$lib/components/metrica/metric-distribution';

/**
 * De la secuencia de la ficha a lo que el análisis necesita.
 *
 * El análisis no conoce `PublicFichaSecuencia` a propósito: así el mismo módulo servirá al perfil
 * de autor, que tendrá su propio adaptador y no la ficha entera.
 */
export function secuenciaToAnalizable(secuencia: PublicFichaSecuencia): SecuenciaAnalizable {
	return {
		secuencia_id: secuencia.secuencia_id,
		v_ini: secuencia.v_ini,
		v_fin: secuencia.v_fin,
		n_versos: secuencia.n_versos,
		forma_slug: secuencia.forma_slug,
		forma: secuencia.forma_nombre ?? null,
		arquitectura: secuencia.arquitectura_nombre ?? null,
		tradicion: secuencia.tipo_forma,
		jornada_num: secuencia.jornada_num,
		cuadro_num: secuencia.cuadro_num,
		cuadro_continua: secuencia.cuadro_continua,
		esquemas: (secuencia.esquemas_rima ?? []).map((s) => ({
			nombre: s.notacion ?? s.nombre ?? 'Esquema observado',
			unidades: 1
		})),
		rasgos: (secuencia.rasgos ?? []).map((r) => ({
			rasgo: r.rasgo_nombre,
			valor: r.valor_nombre
		})),
		caracterizaciones: (secuencia.caracterizaciones_rango ?? []).map((c) => ({
			tipo: c.tipo_caracterizacion_rango_term,
			v_ini: c.v_ini,
			v_fin: c.v_fin
		})),
		desviaciones: (secuencia.desviaciones ?? []).map((d) => ({
			dimension: d.dimension,
			relacion_norma: d.relacion_norma
		})),
		versos_partidos: secuencia.versos_partidos,
		inaugura_espacio: secuencia.inaugura_espacio
	};
}

export const secuenciasToAnalizables = (secuencias: PublicFichaSecuencia[]) =>
	secuencias.map(secuenciaToAnalizable);

/**
 * Lo que distingue una secuencia de otra de la misma forma, dicho en una línea.
 *
 * Es lo que hace útil el esquema métrico: dos romances seguidos no son lo mismo si uno asuena en
 * `é-o` y el otro en `á-a`, y una tirada de redondillas se describe por su reparto de esquemas.
 * **Primero lo observado y luego lo elegido**, porque el rasgo es lo que identifica el pasaje.
 */
export function detalleDeSecuencia(secuencia: PublicFichaSecuencia): string | null {
	const partes: string[] = [];

	for (const rasgo of secuencia.rasgos ?? []) partes.push(rasgo.valor_nombre);

	const esquemas = buildSequenceRhymeSchemeOccurrences(secuencia);
	if (esquemas.length > 0) {
		partes.push(
			esquemas
				.map((esquema) =>
					esquema.cantidad > 1
						? `${esquema.label} · ${formatMetricCount(esquema)}`
						: esquema.label
				)
				.join(' · ')
		);
	}

	// Las desviaciones se nombran, no se detallan: el detalle está al abrir la secuencia.
	const desviaciones = secuencia.desviaciones ?? [];
	if (desviaciones.length > 0) {
		partes.push(
			desviaciones.length === 1 ? '1 desviación' : `${desviaciones.length} desviaciones`
		);
	}

	return partes.length > 0 ? partes.join(' · ') : null;
}

/** Una secuencia como línea del esquema métrico. */
export function secuenciaToSchemeEntry(secuencia: PublicFichaSecuencia): MetricSchemeEntry {
	return {
		id: secuencia.secuencia_id,
		v_ini: secuencia.v_ini,
		v_fin: secuencia.v_fin,
		n_versos: secuencia.n_versos,
		forma: secuencia.forma_nombre,
		colorKey: secuencia.forma_slug ?? secuencia.forma_nombre,
		arquitectura: secuencia.arquitectura_nombre,
		detalle: detalleDeSecuencia(secuencia),
		jornada: secuencia.jornada_num,
		cuadro: secuencia.cuadro_num,
		cuadroContinua: secuencia.cuadro_continua
	};
}

export const secuenciasToSchemeEntries = (secuencias: PublicFichaSecuencia[]) =>
	secuencias.map(secuenciaToSchemeEntry);

/**
 * Una secuencia es **un tramo de un color y con el nombre de su forma**.
 *
 * Rotulaba la arquitectura —«Octosilábica consonante» donde debía decir «Quintilla»—, que es el
 * detalle y no la identidad; la arquitectura se lee dentro, al abrir la secuencia. Y dibujaba una
 * raya por estrofa, porque el esquema de rima se responde una vez por unidad y llegaban setenta y
 * ocho entradas en una tirada de redondillas: el reparto de esquemas es un dato de la secuencia, no
 * una subdivisión que pintar encima.
 */
export function secuenciaToBarSegment(secuencia: PublicFichaSecuencia): MetricBarSegment {
	return {
		id: secuencia.secuencia_id,
		v_ini: secuencia.v_ini,
		v_fin: secuencia.v_fin,
		forma: secuencia.forma_nombre,
		colorKey: secuencia.forma_slug ?? secuencia.forma_nombre,
		label: secuencia.forma_nombre,
		n_versos: secuencia.n_versos,
		subsegments: []
	};
}

export function secuenciasToBarSegments(
	secuencias: PublicFichaSecuencia[]
): MetricBarSegment[] {
	return secuencias.map(secuenciaToBarSegment);
}

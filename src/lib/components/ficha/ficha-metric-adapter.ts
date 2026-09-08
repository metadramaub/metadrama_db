// Adapta los datos de la ficha pública (PublicFichaSecuencia) a los tipos de
// presentación genéricos de los componentes métricos reutilizables.
import type { PublicFichaSecuencia } from '$lib/types/public-ficha.types';
import type {
	MetricBarSegment,
	MetricSchemeEntry
} from '$lib/components/metrica/metric-display.types';
import type { SecuenciaAnalizable } from '$lib/metrica/analisis-ficha';

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
		forma_slug: secuencia.estrofa_forma_slug,
		forma: secuencia.estrofa_forma_term ?? null,
		arquitectura: secuencia.estrofa_tipo_term ?? null,
		tradicion: secuencia.estrofa_tipo_forma,
		jornada_num: secuencia.jornada_num,
		cuadro_num: secuencia.cuadro_num,
		cuadro_continua: secuencia.cuadro_continua,
		esquemas: (secuencia.subtipos_estrofa ?? []).map((s) => ({
			nombre: s.subtipo_estrofa_term,
			unidades: s.unidades
		})),
		rasgos: (secuencia.rasgos ?? []).map((r) => ({ rasgo: r.rasgo_term, valor: r.valor_term })),
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
 * Lo que distingue una tirada de otra de la misma forma, dicho en una línea.
 *
 * Es lo que hace útil el esquema métrico: dos romances seguidos no son lo mismo si uno asuena en
 * `é-o` y el otro en `á-a`, y una tirada de redondillas se describe por su reparto de esquemas.
 * **Primero lo observado y luego lo elegido**, porque el rasgo es lo que identifica el pasaje.
 */
export function detalleDeSecuencia(secuencia: PublicFichaSecuencia): string | null {
	const partes: string[] = [];

	for (const rasgo of secuencia.rasgos ?? []) partes.push(rasgo.valor_term);

	const esquemas = secuencia.subtipos_estrofa ?? [];
	if (esquemas.length === 1) {
		partes.push(esquemas[0].subtipo_estrofa_term);
	} else if (esquemas.length > 1) {
		// Con el signo delante —«Tipología 5 5» se lee como un número partido en dos—, y **sin
		// contar lo que solo pasa una vez**: los dos cuartetos de un soneto son uno, y «×1» sobra.
		partes.push(
			esquemas
				.map((e) => (e.unidades > 1 ? `${e.subtipo_estrofa_term} ×${e.unidades}` : e.subtipo_estrofa_term))
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
		forma: secuencia.estrofa_forma_term,
		colorKey: secuencia.estrofa_forma_slug ?? secuencia.estrofa_forma_term,
		arquitectura: secuencia.estrofa_tipo_term,
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
 * ocho entradas en una tirada de redondillas: el reparto de esquemas es un dato de la tirada, no
 * una subdivisión que pintar encima.
 */
export function secuenciaToBarSegment(secuencia: PublicFichaSecuencia): MetricBarSegment {
	return {
		id: secuencia.secuencia_id,
		v_ini: secuencia.v_ini,
		v_fin: secuencia.v_fin,
		forma: secuencia.estrofa_forma_term,
		colorKey: secuencia.estrofa_forma_slug ?? secuencia.estrofa_forma_term,
		label: secuencia.estrofa_forma_term,
		n_versos: secuencia.n_versos,
		subsegments: []
	};
}

export function secuenciasToBarSegments(
	secuencias: PublicFichaSecuencia[]
): MetricBarSegment[] {
	return secuencias.map(secuenciaToBarSegment);
}

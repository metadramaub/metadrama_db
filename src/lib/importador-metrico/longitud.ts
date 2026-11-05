import referencia from '../../../data/importador-metrico/reglas-longitud.json';
import { formasImportador } from './catalogo';
import { isMetricLengthCompatible } from '$lib/metrica/metric-length';
import { structuralAdditionCount, structuralAdditionRanges } from '$lib/metrica/structural-additions';
import type { MetricLengthRule } from '$lib/metrica/catalogo';
import type { SegmentoMinimo } from './types';

export type ComprobacionLongitud = {
	estado: 'compatible' | 'revisar' | 'sin_regla' | 'sin_identificar';
	mensaje: string | null;
};
type Entrada = Pick<SegmentoMinimo, 'v_ini' | 'v_fin' | 'identificacion' | 'detalles_fuente' | 'desviaciones'>;

/** Aviso de compatibilidad, no identificación ni corrección de la fuente. */
export function comprobarLongitud(secuencia: Entrada): ComprobacionLongitud {
	const { identificacion: destino, v_ini: inicio, v_fin: fin } = secuencia;
	if (!destino) return { estado: 'sin_identificar', mensaje: null };
	if (!Number.isSafeInteger(inicio) || !Number.isSafeInteger(fin) || fin < inicio)
		return { estado: 'sin_regla', mensaje: null }; // La validación del rango informa del error.
	const forma = formasImportador.find((f) => f.slug === destino.forma_slug);
	const arquitecturas = forma?.arquitecturas.filter((a) => !destino.arquitectura_slug || a.slug === destino.arquitectura_slug) ?? [];
	const reglas = arquitecturas.map((a) => referencia.reglas.find((r) => r.arquitectura_id === a.arquitectura_id));
	// Una arquitectura todavía posible sin regla fija impide afirmar incompatibilidad.
	if (!reglas.length || reglas.some((r) => !r)) return { estado: 'sin_regla', mensaje: null };
	const remates = secuencia.detalles_fuente.filter((d) => d.tipo_seccion === 'remate');
	const remate = remates.reduce((n, d) => n + Number(d.n_versos), 0);
	if (!Number.isSafeInteger(remate) || remate < 0 || remate > fin - inicio + 1)
		return { estado: 'revisar', mensaje: 'Revisa la extensión declarada del remate.' };
	const desviaciones = secuencia.desviaciones.map((d) => ({
		v_ini: Number(d.v_ini), v_fin: Number(d.v_fin), dimension: String(d.dimension), relacion_norma: String(d.relacion_norma)
	}));
	if (remate && structuralAdditionRanges(inicio, fin, desviaciones).some((r) => r.v_fin > fin - remate))
		return { estado: 'revisar', mensaje: 'Una adición estructural coincide con el remate. Revisa ambos datos para no descontar el mismo verso dos veces.' };
	const conocidas = reglas.filter((r): r is NonNullable<typeof r> => Boolean(r));
	const compatible = conocidas.some((r) => isMetricLengthCompatible(
		{ ...r, ...(remates.length ? { desplazamientos: [remate] } : {}) } as MetricLengthRule,
		inicio, fin, false, desviaciones
	));
	if (compatible) return { estado: 'compatible', mensaje: null };
	const total = fin - inicio + 1;
	const adiciones = structuralAdditionCount(inicio, fin, desviaciones);
	const ajustes = [
		...(adiciones ? [`${adiciones} ${adiciones === 1 ? 'verso añadido declarado' : 'versos añadidos declarados'}`] : []),
		...(remate ? [`${remate} ${remate === 1 ? 'verso de remate' : 'versos de remate'}`] : [])
	];
	const explicaciones = [...new Set(conocidas.map((r) => r.explicacion))].join(' o ');
	return { estado: 'revisar', mensaje:
		`${total} versos${ajustes.length ? `; descontando ${ajustes.join(' y ')}, quedan ${total - adiciones - remate} para el cuerpo` : ''}. ` +
		`${forma?.nombre ?? destino.forma_slug} requiere ${explicaciones}. Revisa la secuencia.` };
}

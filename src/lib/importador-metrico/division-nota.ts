import type { NotaFuenteImportador, SegmentoMinimo } from './types';
import { comprobarLongitud } from './longitud';

/** Reconoce una declaración localizada y su reanudación, sin interpretar notas ambiguas. */
export function proponerDivisionDesdeNota(
	secuencia: Pick<SegmentoMinimo, 'v_ini' | 'v_fin' | 'identificacion' | 'origen'>,
	nota: NotaFuenteImportador
) {
	if (secuencia.identificacion?.forma_slug !== 'copla_real' ||
		!secuencia.origen.notas_ref.includes(nota.id) ||
		!nota.tramos_ref?.includes(secuencia.origen.tramo_ref)) return null;
	const texto = nota.texto_literal.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase().replace(/\s+/g, ' ');
	const inserciones = [...texto.matchAll(/(?:^|[.!?]\s+)en los (?:vv\.?|versos)\s*(\d+)\s*[-–—]\s*(\d+)\s+hay una quintilla (?:aislada|suelta|independiente)\b/g)];
	const continuaciones = [...texto.matchAll(/a partir del (?:v\.?|verso)\s*(\d+)\s+continua el patron regular de coplas reales\b/g)];
	if (inserciones.length !== 1 || continuaciones.length !== 1) return null;
	const inicio = Number(inserciones[0][1]), fin = Number(inserciones[0][2]);
	if (!Number.isSafeInteger(inicio) || !Number.isSafeInteger(fin) ||
		inicio !== nota.v_ini || fin !== nota.v_fin || fin - inicio + 1 !== 5 ||
		inicio <= secuencia.v_ini || fin >= secuencia.v_fin || Number(continuaciones[0][1]) !== fin + 1) return null;
	const partes = [
		{ v_ini: secuencia.v_ini, v_fin: inicio - 1, identificacion: { ...secuencia.identificacion } },
		{ v_ini: inicio, v_fin: fin, identificacion: { forma_slug: 'quintilla', arquitectura_slug: null } },
		{ v_ini: fin + 1, v_fin: secuencia.v_fin, identificacion: { ...secuencia.identificacion } }
	];
	return { partes, avisos: partes.map((p) => ({ ...p, longitud: comprobarLongitud({ ...p, detalles_fuente: [], desviaciones: [] }) })) };
}

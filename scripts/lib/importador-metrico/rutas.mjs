/** Ubicaciones del piloto: reglas de aplicación separadas de las referencias de evaluación. */
import { fileURLToPath } from 'node:url';
const reglas = new Set([
	'catalogo-referencia.json',
	'reglas-longitud.json',
	'equivalencias.propuestas.json',
	'bibliografia-contraste.json',
	'segmentacion.propuestas.json',
	'auditoria-flujo-2026-10-26.json',
	'auditoria-campos-2026-10-22.json'
]);
export function rutaPiloto(nombre) {
	const base = reglas.has(nombre)
		? '../../../data/importador-metrico/'
		: nombre === 'seguimiento-lote.md'
			? '../../../docs/importador-metrico/evaluacion/informes/'
			: nombre === 'revision-equivalencias.md'
				? '../../../docs/importador-metrico/equivalencias/'
				: '../../../docs/importador-metrico/evaluacion/referencias/';
	return fileURLToPath(new URL(base + nombre, import.meta.url));
}

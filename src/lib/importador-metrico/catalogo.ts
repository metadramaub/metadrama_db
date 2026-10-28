/** Referencia de solo lectura usada por el ensayo; no sustituye la comprobación al guardar. */
import referencia from '../../../docs/importador-metrico/piloto/catalogo-referencia.json';
export const rasgosImportador = referencia.rasgos;
export const metrosImportador = referencia.metros;
export function rasgosAdmitidos(forma: string, arquitectura: string) {
	return rasgosImportador.map((r) => {
		const contextos = r.contextos.filter((c) => c.forma === forma && (!arquitectura || c.arquitectura === arquitectura));
		return {...r, contextos, valores: r.valores.filter((v) => contextos.some((c) => !c.valor_slug || c.valor_slug === v.slug))};
	}).filter((r) => r.valores.length);
}

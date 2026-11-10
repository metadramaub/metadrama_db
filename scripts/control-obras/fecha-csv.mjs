/** Solo interpreta expresiones explícitas de composición; no usa la columna de ordenación. */
export function fechaCsv(literal) {
	const base = { inicio: null, fin: null, inicio_inclusivo: true, fin_inclusivo: true, aproximada: /\bc\s*\./iu.test(literal) };
	const limite = literal.match(/^\s*([≤<>≥])\s*(\d{4})/u);
	if (limite) return { ...base, [/[≤<]/u.test(limite[1]) ? 'fin' : 'inicio']: Number(limite[2]),
		inicio_inclusivo: limite[1] !== '>', fin_inclusivo: limite[1] !== '<' };
	// El año de edición es un límite inclusivo; no demuestra una composición en ese año.
	if (/composici[oó]n anterior no precisada/iu.test(literal)) {
		const edicion = literal.match(/\b\d{4}\b/u);
		if (!edicion) throw Error('Datación de edición sin año reconocible');
		return { ...base, fin: Number(edicion[0]) };
	}
	const intervalo = literal.match(/(\d{4})\s*[–—-]\s*(\d{4})/u);
	if (intervalo) return { ...base, inicio: Number(intervalo[1]), fin: Number(intervalo[2]) };
	const año = literal.match(/\b\d{4}\b/u);
	if (!año && literal.trim()) throw Error('Datación CSV no reconocida: ' + literal);
	return { ...base, inicio: año ? Number(año[0]) : null, fin: año ? Number(año[0]) : null };
}

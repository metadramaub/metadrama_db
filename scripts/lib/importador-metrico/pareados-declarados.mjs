/** Lee únicamente localizaciones y excepciones explícitas; no reconstruye la edición. */
function rangosListados(texto) {
	const patron = /(\d+)\s*[-–—]\s*(\d+)/gu;
	const rangos = [...texto.matchAll(patron)].map((m) => ({ ini: Number(m[1]), fin: Number(m[2]) }));
	if (!rangos.length || texto.replace(patron, '').replace(/[\s,y]/gu, '')) return null;
	return rangos.every(
		(r) => Number.isSafeInteger(r.ini) && Number.isSafeInteger(r.fin) && r.ini > 0 && r.fin >= r.ini
	)
		? rangos
		: null;
}

export function pareadosEnDenominacion(literal, fila) {
	const match =
		/^endecasílabos sueltos\s*\(\s*con pareados? en (?:los )?vv\.\s*([^()]+)\s*\)$/iu.exec(
			literal ?? ''
		);
	if (!match) return null;
	const rangos = rangosListados(match[1]);
	const validos =
		rangos &&
		fila.v_ini !== null &&
		fila.v_fin !== null &&
		rangos.every((r) => r.fin - r.ini === 1 && r.ini >= fila.v_ini && r.fin <= fila.v_fin);
	return {
		literal: match[0],
		disticoFinal: Boolean(validos && rangos.some((r) => r.fin === fila.v_fin)),
		aviso: validos
			? null
			: 'Revisa la localización del pareado indicada por la edición; se conserva sin corregir.'
	};
}

export function cierreConExcepciones(nota, fila, filasPorId, literales) {
	const texto = nota.texto_literal?.replace(/\s+/gu, ' ').trim().toLowerCase();
	if (
		!texto?.includes('los dos últimos versos constituyen un pareado') ||
		!texto.includes('forma con la que remata otras dos de las cinco series de versos sueltos')
	)
		return null;
	const match = /aquellas que no adoptan esta conclusión son las de los vv\.\s*([^.]+)\./u.exec(
		texto
	);
	const excepciones = match && rangosListados(match[1]);
	const filas = nota.tramos_ref.map((id) => filasPorId.get(id));
	// Una nota de alcance incompleto o con otras formas no autoriza a repartir el rasgo.
	if (
		!excepciones ||
		filas.length !== 5 ||
		new Set(nota.tramos_ref).size !== 5 ||
		excepciones.length !== 2 ||
		new Set(excepciones.map((e) => `${e.ini}-${e.fin}`)).size !== 2 ||
		filas.some(
			(r) =>
				!r ||
				!r.notas_ref?.includes(nota.id) ||
				!literales.includes(r.denominacion_literal?.replace(/\s+/gu, ' ').trim().toLowerCase())
		) ||
		excepciones.some((e) => !filas.some((r) => r.v_ini === e.ini && r.v_fin === e.fin))
	)
		return null;
	return !excepciones.some((e) => fila.v_ini === e.ini && fila.v_fin === e.fin);
}

/** Complementos aprobados fuera del Excel: nunca se escriben sobre el documento del editor. */
export function incorporarRespuestasAdicionales(respuestas, adicionales) {
	for (const fila of adicionales) {
		if (!fila.clave || !fila.respuesta || !fila.origen || !fila.motivo) {
			throw new Error('La respuesta adicional necesita clave, respuesta, origen y motivo.');
		}
		if (respuestas.has(fila.clave)) {
			throw new Error(`La respuesta adicional ${fila.clave} sobrescribiría una fila ya recibida.`);
		}
		respuestas.set(fila.clave, { ...fila });
	}
}

/** Prepara una copia para el plan; conserva el Excel y la obra originales para el rastro y las guardas. */
export function prepararResoluciones(obra, respuestas, resoluciones, catalogo) {
	const preparada = structuredClone(obra);
	const efectivas = new Map([...respuestas].map(([k, v]) => [k, { ...v }]));
	for (const cambio of resoluciones?.respuestas_revisadas ?? []) {
		const original = respuestas.get(cambio.clave);
		if (
			!cambio.motivo ||
			!original ||
			Object.entries(cambio.esperado).some(([k, v]) => original[k] !== v)
		) {
			throw new Error(`Ha cambiado la respuesta revisada ${cambio.clave}.`);
		}
		efectivas.set(cambio.clave, { ...original, ...cambio.usar });
	}
	for (const [id, cambio] of Object.entries(resoluciones?.secuencias ?? {})) {
		const s = preparada.secuencias.find((s) => s.secuencia_id === id);
		if (!s) continue; // Una pasada posterior omite lo que ya está migrado.
		if (Object.entries(cambio.origen).some(([k, v]) => s[k] !== v)) {
			throw new Error(`Ha cambiado la secuencia revisada ${id}.`);
		}
		if (cambio.arquitectura_id) {
			if (!catalogo.has(cambio.arquitectura_id))
				throw new Error('La arquitectura revisada ya no está activa.');
			s.arquitectura_propuesta_id = cambio.arquitectura_id;
			s.arquitectura_propuesta = cambio.arquitectura_nombre;
		}
		const grupos = Object.keys(cambio.elecciones ?? {});
		s.respuestas = s.respuestas.filter((r) => !grupos.includes(r.grupo_eleccion_id));
		for (const [grupo, respuesta] of Object.entries(cambio.elecciones ?? {})) {
			efectivas.set(`R|${id}|${grupo}`, {
				clave: `R|${id}|${grupo}`,
				respuesta,
				origen: 'resolucion_aprobada',
				motivo: cambio.motivo
			});
		}
	}
	return { obra: preparada, respuestas: efectivas };
}

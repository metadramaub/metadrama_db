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

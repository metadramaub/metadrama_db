/** La prosa no numerada localiza un fenómeno; no crea versos ni una secuencia métrica. */
export function integrarProsa(segmentos) {
	const resultado = [];
	const esProsa = (s) => /^(?:carta en |pasaje en )?prosa$/iu.test(s.fuente.denominacion_literal?.trim() ?? '');
	const destino = (s) => s.identificacion_revisada ?? s.propuesta;
	for (let i = 0; i < segmentos.length; i++) {
		const fila = structuredClone(segmentos[i]);
		if (!esProsa(fila)) { resultado.push(fila); continue; }
		if (fila.v_ini !== null || fila.v_fin !== null || fila.fuente.n_versos_fuente !== null)
			throw new Error(`Prosa ${fila.id}: debe estar sin numeración ni extensión; revisa la asociación de columnas en la foto.`);
		const anterior = resultado.at(-1), siguiente = segmentos[i + 1];
		if (!anterior || !siguiente || esProsa(siguiente) || !destino(anterior) || !destino(siguiente) ||
			destino(anterior).forma_slug !== destino(siguiente).forma_slug ||
			fila.jornada === null || anterior.jornada !== fila.jornada || siguiente.jornada !== fila.jornada ||
			!Number.isInteger(anterior.v_fin) || siguiente.v_ini !== anterior.v_fin + 1)
			throw new Error(`Prosa ${fila.id}: revisa su localización; debe quedar entre tramos consecutivos de la misma forma identificada y jornada.`);
		// Un cierre intermedio o rasgos diferentes no se convierten en datos de toda la secuencia.
		if (anterior.detalles_fuente.some((d) => d.tipo_seccion === 'remate' || d.rasgo_slug === 'distico_final') ||
			JSON.stringify(anterior.detalles_fuente) !== JSON.stringify(siguiente.detalles_fuente))
			throw new Error(`Prosa ${fila.id}: revisa los rasgos o cierres diferentes antes de unir los tramos.`);
		const nueva = structuredClone(siguiente);
		const identificacion = {forma_slug: destino(anterior).forma_slug,
			arquitectura_slug: destino(anterior).arquitectura_slug === destino(siguiente).arquitectura_slug
				? destino(anterior).arquitectura_slug : null};
		anterior.caracterizaciones = [...(anterior.caracterizaciones ?? []), {
			termino: 'prosa', v_ini: anterior.v_fin, v_fin: siguiente.v_ini,
			tramo_ref: fila.fuente.id, literal: fila.fuente.denominacion_literal
		}, ...(nueva.caracterizaciones ?? [])];
		anterior.tramos_ref = [...(anterior.tramos_ref ?? [anterior.fuente.id]), ...(nueva.tramos_ref ?? [nueva.fuente.id])];
		anterior.fuente.notas_ref = [...new Set([...anterior.fuente.notas_ref, ...nueva.fuente.notas_ref])];
		anterior.v_fin = nueva.v_fin;
		anterior.identificacion_revisada = null; anterior.propuesta = identificacion;
		anterior.candidatas = []; anterior.regla_id = null;
		anterior.desviaciones.push(...nueva.desviaciones);
		anterior.nota = [anterior.nota, nueva.nota].filter(Boolean).join('\n') || null;
		i++;
	}
	return resultado;
}

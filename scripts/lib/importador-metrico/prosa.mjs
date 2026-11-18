export function intervaloProsaDeclarado(literal) {
	const limpio = (literal ?? '').trim().replace(/^\[(.*)\]$/u, '$1').trim();
	const m = /^(?:carta en |pasaje en )?prosa entre (?:los )?vv?\.?\s*(\d+)\s*[-–—]\s*(\d+)$/iu.exec(limpio);
	return m ? { v_ini: Number(m[1]), v_fin: Number(m[2]) } : null;
}

const prosaSimple = (literal) => /^(?:carta en |pasaje en )?prosa$/iu.test(literal?.trim() ?? '');

export function esProsaSinRango(fila) {
	return fila.v_ini === null && fila.v_fin === null && fila.n_versos_fuente === null &&
		(prosaSimple(fila.denominacion_literal) || intervaloProsaDeclarado(fila.denominacion_literal) !== null);
}

/** La prosa no numerada localiza un fenómeno; no crea versos ni una secuencia métrica. */
export function integrarProsa(segmentos, desplazamientos = []) {
	const resultado = [];
	const porJornada = new Map(desplazamientos.map(d => [d.jornada, d.desplazamiento]));
	const anclas = new Map();
	const esProsa = (s) => prosaSimple(s.fuente.denominacion_literal);
	const destino = (s) => s.identificacion_revisada ?? s.propuesta;
	const registrar = (s, fila, v_ini, v_fin) => {
		s.caracterizaciones = [...(s.caracterizaciones ?? []), {
			termino: 'prosa', v_ini, v_fin, tramo_ref: fila.fuente.id, literal: fila.fuente.denominacion_literal
		}];
	};
	const numerados = segmentos.filter(s => Number.isInteger(s.v_ini) && Number.isInteger(s.v_fin));
	for (const fila of segmentos) {
		const intervalo = intervaloProsaDeclarado(fila.fuente.denominacion_literal);
		if (!intervalo) continue;
		const d = porJornada.get(fila.jornada) ?? 0;
		const v_ini = intervalo.v_ini + d, v_fin = intervalo.v_fin + d;
		const posibles = numerados.filter(s => s.jornada === fila.jornada && s.v_ini <= v_ini && s.v_fin >= v_fin);
		if (!esProsaSinRango(fila.fuente) || !Number.isSafeInteger(v_ini) || !Number.isSafeInteger(v_fin) ||
			v_ini < 1 || v_fin !== v_ini + 1 || posibles.length !== 1)
			throw new Error('Prosa ' + fila.id + ': el localizador literal debe señalar dos versos consecutivos dentro de una única fila de la misma jornada.');
		const id = posibles[0].id;
		anclas.set(id, [...(anclas.get(id) ?? []), { fila, v_ini, v_fin }]);
	}
	const copiar = (s) => {
		const copia = structuredClone(s);
		for (const p of anclas.get(s.id) ?? []) registrar(copia, p.fila, p.v_ini, p.v_fin);
		return copia;
	};
	for (let i = 0; i < segmentos.length; i++) {
		if (intervaloProsaDeclarado(segmentos[i].fuente.denominacion_literal)) continue;
		const fila = copiar(segmentos[i]);
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
		const nueva = copiar(siguiente);
		const identificacion = {forma_slug: destino(anterior).forma_slug,
			arquitectura_slug: destino(anterior).arquitectura_slug === destino(siguiente).arquitectura_slug
				? destino(anterior).arquitectura_slug : null};
		registrar(anterior, fila, anterior.v_fin, siguiente.v_ini);
		anterior.caracterizaciones.push(...(nueva.caracterizaciones ?? []));
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

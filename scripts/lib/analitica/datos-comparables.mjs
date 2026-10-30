/** Traducción de evidencia adicional. No infiere respuestas desde la norma o los literales. */
const copia = (v) => structuredClone(v);
const dimensiones = [
	'rasgo',
	'remate',
	'metro',
	'rima',
	'esquema_metrico',
	'repeticion',
	'variedad',
	'desviacion'
];
const unicos = (xs) => [...new Map(xs.map((x) => [JSON.stringify(x), x])).values()];

export function normalizarDatosComparables(aportacion, referencias = {}) {
	const incidencias = [];
	const resolver = (tabla, id) => {
		if (!id) return null;
		const r = referencias[tabla]?.[id];
		if (!r) throw Error(`referencia_no_resuelta:${tabla}`);
		return r;
	};
	const realizaciones = aportacion.evidencia_adicional?.realizaciones ?? [];
	const secuencias = aportacion.secuencias.map((s) => {
		const hechos = [],
			notas = [],
			arquitecturas = [];
		const ambitoBase = {
			tipo: 'secuencia',
			v_ini: s.v_ini,
			v_fin: s.v_fin,
			seccion: null,
			posicion_unidad: null
		};
		const agregar = (dimension, propiedad, valor, ambito = ambitoBase, extra = {}) => {
			if (valor === null || valor === undefined) throw Error('valor_sin_resolver');
			hechos.push({
				dimension,
				propiedad,
				valor,
				ambito: copia(ambito),
				forma_slug: s.forma_slug,
				arquitectura_slug: s.arquitectura_slug,
				...extra
			});
		};
		for (const d of s.detalles ?? []) {
			try {
				if (aportacion.tipo === 'basica') {
					if (d.rasgo_slug)
						agregar('rasgo', d.rasgo_slug, d.valor_slug, ambitoBase, {
							escala_recuento:
								Object.values(referencias.rasgos ?? {}).find((r) => r.slug === d.rasgo_slug)
									?.escala_recuento ?? null
						});
					else if (d.tipo_seccion === 'remate') {
						if (
							!Number.isInteger(d.n_versos) ||
							d.n_versos <= 0 ||
							d.n_versos > s.v_fin - s.v_ini + 1
						)
							throw Error('remate_fuera_de_secuencia');
						agregar(
							'remate',
							'seccion',
							'remate',
							{
								tipo: 'realizacion',
								v_ini: s.v_fin - d.n_versos + 1,
								v_fin: s.v_fin,
								seccion: 'remate',
								posicion_unidad: null
							},
							{ posicion: 'final' }
						);
					} else notas.push(copia(d)); // Un texto, incluso una asonancia literal, no es un valor anotado.
					continue;
				}
				const r = d.realizacion_id
					? realizaciones.find((r) => r.realizacion_id === d.realizacion_id)
					: null;
				if (d.realizacion_id && !r) throw Error('realizacion_no_resuelta');
				const seccion = resolver('secciones', d.seccion_tratada_id ?? r?.seccion_id);
				const ambito = {
					tipo: d.posicion_unidad
						? 'posicion'
						: d.seccion_tratada_id
							? 'seccion'
							: r
								? 'realizacion'
								: 'secuencia',
					v_ini: d.posicion_unidad || d.seccion_tratada_id ? null : (r?.v_ini ?? s.v_ini),
					v_fin: d.posicion_unidad || d.seccion_tratada_id ? null : (r?.v_fin ?? s.v_fin),
					seccion: seccion?.slug ?? null,
					posicion_unidad: d.posicion_unidad ?? null
				};
				const arquitectura =
					resolver('arquitecturas', r?.arquitectura_id)?.slug ?? s.arquitectura_slug;
				const extra = { arquitectura_slug: arquitectura };
				if (d.dimension === 'rasgo') {
					const valor = resolver('valores', d.valor_rasgo_id);
					const pregunta = valor ? null : resolver('preguntas', d.grupo_eleccion_id);
					const rasgo = resolver('rasgos', valor?.rasgo_id ?? pregunta?.rasgo_id);
					if (!rasgo) throw Error('rasgo_no_resuelto');
					let respuesta = valor?.slug ?? d.valor_texto;
					if (!valor && rasgo.tipo_valor === 'numero') {
						if (
							respuesta === null ||
							respuesta === undefined ||
							String(respuesta).trim() === '' ||
							!Number.isFinite(Number(respuesta))
						)
							throw Error('numero_no_valido');
						respuesta = Number(respuesta);
					}
					if (!valor && rasgo.tipo_valor === 'booleano') {
						if (![true, false, 'true', 'false'].includes(respuesta))
							throw Error('booleano_no_valido');
						respuesta = respuesta === true || respuesta === 'true';
					}
					agregar('rasgo', rasgo.slug, respuesta, ambito, {
						...extra,
						escala_recuento: rasgo.escala_recuento ?? null
					});
				} else if (d.metro_id)
					agregar('metro', 'metro', resolver('metros', d.metro_id).slug, ambito, extra);
				else if (d.esquema_rima_id) {
					const esquema = resolver('rimas', d.esquema_rima_id);
					const arq = resolver('arquitecturas', esquema.arquitectura_id);
					if (esquema.seccion_id && !ambito.seccion)
						Object.assign(ambito, {
							tipo: 'seccion',
							seccion: resolver('secciones', esquema.seccion_id).slug,
							v_ini: null,
							v_fin: null
						});
					agregar('rima', 'esquema', esquema.slug, ambito, {
						...extra,
						arquitectura_slug: arq.slug,
						notacion: esquema.notacion
					});
				} else if (d.esquema_metrico_id) {
					const esquema = resolver('esquemas_metricos', d.esquema_metrico_id);
					if (esquema.seccion_id && !ambito.seccion)
						Object.assign(ambito, {
							tipo: 'seccion',
							seccion: resolver('secciones', esquema.seccion_id).slug,
							v_ini: null,
							v_fin: null
						});
					agregar('esquema_metrico', 'esquema', esquema.slug, ambito, {
						...extra,
						arquitectura_slug: resolver('arquitecturas', esquema.arquitectura_id).slug
					});
				} else if (d.repeticion_id)
					agregar(
						'repeticion',
						'patron',
						resolver('repeticiones', d.repeticion_id).slug,
						ambito,
						extra
					);
				else if (d.variedad_id)
					agregar(
						'variedad',
						'combinacion',
						resolver('variedades', d.variedad_id).slug,
						ambito,
						extra
					);
				else if (d.seccion_id)
					agregar(
						d.dimension === 'rima' ? 'rima' : d.dimension === 'metro' ? 'metro' : 'repeticion',
						'seccion',
						resolver('secciones', d.seccion_id).slug,
						ambito,
						extra
					);
				else if (
					d.valor_texto !== null &&
					d.valor_texto !== undefined &&
					['metro', 'rima', 'repeticion', 'combinacion'].includes(d.dimension)
				)
					agregar(
						d.dimension === 'combinacion' ? 'variedad' : d.dimension,
						'disposicion_anotada',
						d.valor_texto,
						ambito,
						{ ...extra, tipo_valor: 'texto_anotado' }
					);
				else throw Error('eleccion_sin_destino');
			} catch (e) {
				incidencias.push({ secuencia: s.ref, codigo: e.message });
			}
		}
		if (aportacion.tipo === 'detallada') {
			for (const r of realizaciones.filter((r) => r.secuencia_id === s.ref && r.arquitectura_id)) {
				try {
					if (r.v_ini < s.v_ini || r.v_fin > s.v_fin || r.v_fin < r.v_ini)
						throw Error('arquitectura_realizada_fuera_de_secuencia');
					const arq = resolver('arquitecturas', r.arquitectura_id);
					if (arq.forma_id && resolver('formas', arq.forma_id)?.slug !== s.forma_slug)
						throw Error('arquitectura_realizada_de_otra_forma');
					arquitecturas.push({
						v_ini: r.v_ini,
						v_fin: r.v_fin,
						arquitectura_slug: arq.slug
					});
				} catch (e) {
					incidencias.push({ secuencia: s.ref, codigo: e.message });
				}
			}
			for (const r of realizaciones.filter((r) => r.secuencia_id === s.ref && r.seccion_id)) {
				try {
					const seccion = resolver('secciones', r.seccion_id);
					if (seccion.tipo_seccion === 'remate') {
						if (r.v_ini < s.v_ini || r.v_fin > s.v_fin || r.v_fin < r.v_ini)
							throw Error('remate_fuera_de_secuencia');
						agregar(
							'remate',
							'seccion',
							'remate',
							{
								tipo: 'realizacion',
								v_ini: r.v_ini,
								v_fin: r.v_fin,
								seccion: 'remate',
								posicion_unidad: null
							},
							{ posicion: r.v_fin === s.v_fin ? 'final' : 'interior' }
						);
					}
				} catch (e) {
					incidencias.push({ secuencia: s.ref, codigo: e.message });
				}
			}
		}
		for (const d of s.desviaciones ?? []) {
			try {
				if (
					!Number.isInteger(d.v_ini) ||
					!Number.isInteger(d.v_fin) ||
					d.v_ini < s.v_ini ||
					d.v_fin > s.v_fin ||
					d.v_fin < d.v_ini
				)
					throw Error('desviacion_fuera_de_secuencia');
				const metro =
					d.metro_observado_slug ?? resolver('metros', d.metro_observado_id)?.slug ?? null;
				const rima = resolver('rimas', d.esquema_rima_observado_id),
					seccion = resolver('secciones', d.seccion_observada_id),
					repeticion = resolver('repeticiones', d.repeticion_observada_id),
					valor = resolver('valores', d.valor_rasgo_observado_id);
				agregar(
					'desviacion',
					d.dimension,
					d.relacion_norma,
					{ tipo: 'rango', v_ini: d.v_ini, v_fin: d.v_fin, seccion: null, posicion_unidad: null },
					{
						metro_observado: metro,
						rima_observada: rima?.slug ?? null,
						seccion_observada: seccion?.slug ?? null,
						repeticion_observada: repeticion?.slug ?? null,
						valor_rasgo_observado: valor?.slug ?? null,
						contexto_observado: {
							arquitectura_rima: resolver('arquitecturas', rima?.arquitectura_id)?.slug ?? null,
							arquitectura_seccion:
								resolver('arquitecturas', seccion?.arquitectura_id)?.slug ?? null,
							arquitectura_repeticion:
								resolver('arquitecturas', repeticion?.arquitectura_id)?.slug ?? null,
							rasgo: resolver('rasgos', valor?.rasgo_id)?.slug ?? null
						}
					}
				);
			} catch (e) {
				incidencias.push({ secuencia: s.ref, codigo: e.message });
			}
		}
		return {
			...copia(s),
			tipo_fuente: aportacion.tipo,
			datos_comparables: unicos(hechos),
			arquitecturas_realizadas: unicos(arquitecturas),
			notas_no_estructuradas: notas
		};
	});
	return { ...aportacion, secuencias, incidencias_datos_comparables: incidencias };
}

function extensionUnion(rangos) {
	let n = 0,
		fin = -1;
	for (const r of [...rangos].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin)) {
		n += Math.max(0, r.v_fin - Math.max(fin + 1, r.v_ini) + 1);
		fin = Math.max(fin, r.v_fin);
	}
	return n;
}

function resumirPosiciones(evidencias, respondidas) {
	const contar = (filas) =>
		[...new Set(filas.map((e) => e.secuencia))].reduce(
			(n, ref) => n + extensionUnion(filas.filter((e) => e.secuencia === ref)),
			0
		);
	const rangos = evidencias.filter((e) => Number.isInteger(e.v_ini) && Number.isInteger(e.v_fin));
	const numerador = contar(rangos),
		denominador = contar(respondidas);
	return {
		numerador,
		denominador,
		proporcion: denominador ? numerador / denominador : null,
		motivo: denominador ? null : 'sin_rango_cuantificable',
		unidad: 'posiciones_del_ambito_anotado'
	};
}

export function precomputarDatosComparables(a) {
	const preparada = a.secuencias.every((s) => Array.isArray(s.datos_comparables))
		? a
		: normalizarDatosComparables(a);
	const total = new Set(preparada.secuencias.map((s) => s.ref)).size;
	const grupos = new Map(),
		respondidas = new Map(),
		rangosRespondidos = new Map();
	const claveContexto = (h) =>
		JSON.stringify([
			h.dimension,
			h.propiedad,
			h.forma_slug,
			h.arquitectura_slug,
			h.ambito.tipo,
			h.ambito.seccion,
			h.ambito.posicion_unidad
		]);
	for (const s of preparada.secuencias)
		for (const h of s.datos_comparables) {
			const contexto = claveContexto(h);
			if (!respondidas.has(contexto)) respondidas.set(contexto, new Set());
			respondidas.get(contexto).add(s.ref);
			if (!rangosRespondidos.has(contexto)) rangosRespondidos.set(contexto, []);
			if (Number.isInteger(h.ambito.v_ini) && Number.isInteger(h.ambito.v_fin))
				rangosRespondidos.get(contexto).push({ secuencia: s.ref, ...h.ambito });
			const key = JSON.stringify([
				contexto,
				h.valor,
				h.metro_observado ?? null,
				h.rima_observada ?? null,
				h.seccion_observada ?? null,
				h.repeticion_observada ?? null,
				h.valor_rasgo_observado ?? null,
				h.contexto_observado ?? null,
				h.posicion ?? null
			]);
			if (!grupos.has(key))
				grupos.set(key, {
					contexto,
					dimension: h.dimension,
					propiedad: h.propiedad,
					escala_recuento: h.escala_recuento ?? null,
					valor: h.valor,
					forma_slug: h.forma_slug,
					arquitectura_slug: h.arquitectura_slug,
					tipo_ambito: h.ambito.tipo,
					seccion: h.ambito.seccion,
					posicion_unidad: h.ambito.posicion_unidad,
					metro_observado: h.metro_observado ?? null,
					rima_observada: h.rima_observada ?? null,
					seccion_observada: h.seccion_observada ?? null,
					repeticion_observada: h.repeticion_observada ?? null,
					valor_rasgo_observado: h.valor_rasgo_observado ?? null,
					contexto_observado: h.contexto_observado ?? null,
					notacion: h.notacion ?? null,
					tipo_valor: h.tipo_valor ?? 'catalogo',
					posicion: h.posicion ?? null,
					secuencias: new Set(),
					evidencias: []
				});
			const g = grupos.get(key);
			g.secuencias.add(s.ref);
			g.evidencias.push({ secuencia: s.ref, ...h.ambito });
		}
	return {
		incidencias: preparada.incidencias_datos_comparables ?? [],
		cobertura: dimensiones.map((dimension) => {
			const conDatos = new Set(
				preparada.secuencias
					.filter((s) => s.datos_comparables.some((h) => h.dimension === dimension))
					.map((s) => s.ref)
			);
			const conDato = conDatos.size;
			// La ausencia de desviaciones en una detallada anotada/publicada es un cero analizado.
			// No se extiende ese criterio al silencio de una edición ni a preguntas sin respuesta.
			const ausencias =
				dimension === 'desviacion'
					? new Set(
							preparada.secuencias
								.filter(
									(s) =>
										(s.tipo_fuente ?? a.tipo) === 'detallada' &&
										s.n_anotaciones === 1 &&
										!(s.desviaciones ?? []).length &&
										!conDatos.has(s.ref)
								)
								.map((s) => s.ref)
						).size
					: 0;
			return {
				dimension,
				secuencias_con_dato: conDato,
				ausencias_comprobadas: ausencias,
				sin_dato: total - conDato - ausencias,
				denominador_secuencias: total
			};
		}),
		valores: [...grupos.values()]
			.map(({ secuencias, evidencias, contexto, ...g }) => ({
				...g,
				secuencias_con_evidencia: secuencias.size,
				denominador_con_dato: respondidas.get(contexto).size,
				secuencias_de_la_forma: new Set(
					preparada.secuencias.filter((s) => s.forma_slug === g.forma_slug).map((s) => s.ref)
				).size,
				proporcion_en_secuencias_con_dato:
					g.escala_recuento === 'verso' ? null : secuencias.size / respondidas.get(contexto).size,
				posiciones_del_ambito_anotado:
					g.escala_recuento === 'verso'
						? resumirPosiciones(evidencias, rangosRespondidos.get(contexto))
						: null,
				// Son incidencias documentadas entre respuestas; no prevalencia en toda la obra.
				prevalencia_total: null,
				extension_documentada: ['remate', 'desviacion'].includes(g.dimension)
					? [...secuencias].reduce(
							(n, ref) => n + extensionUnion(evidencias.filter((e) => e.secuencia === ref)),
							0
						)
					: null,
				evidencias
			}))
			.sort((a, b) =>
				JSON.stringify([
					a.dimension,
					a.propiedad,
					a.forma_slug,
					a.arquitectura_slug,
					a.valor
				]).localeCompare(
					JSON.stringify([b.dimension, b.propiedad, b.forma_slug, b.arquitectura_slug, b.valor])
				)
			)
	};
}

/** Las realizaciones reemplazan la arquitectura de cabecera sin duplicar posiciones. */
export function rangosArquitectura(s) {
	const realizados = s.arquitecturas_realizadas ?? [];
	const cortes = [
		...new Set([s.v_ini, s.v_fin + 1, ...realizados.flatMap((r) => [r.v_ini, r.v_fin + 1])])
	].sort((a, b) => a - b);
	return cortes.slice(0, -1).map((ini, i) => {
		const fin = cortes[i + 1] - 1;
		const arqs = [
			...new Set(
				realizados.filter((r) => r.v_ini <= ini && r.v_fin >= fin).map((r) => r.arquitectura_slug)
			)
		];
		return {
			v_ini: ini,
			v_fin: fin,
			arquitectura_slug: arqs.length > 1 ? null : (arqs[0] ?? s.arquitectura_slug),
			conflicto: arqs.length > 1
		};
	});
}

/** Conserva solo datos cuyo ámbito completo pertenece a la unidad de autoría seleccionada. */
export function recortarSecuenciaComparable(s, rango, obraId, tipo) {
	const v_ini = Math.max(s.v_ini, rango.v_ini),
		v_fin = Math.min(s.v_fin, rango.v_fin);
	const completa = v_ini === s.v_ini && v_fin === s.v_fin;
	return {
		...s,
		ref: `${obraId}/${s.ref}`,
		v_ini,
		v_fin,
		tipo_fuente: tipo,
		datos_comparables: (s.datos_comparables ?? []).filter(
			(h) =>
				completa ||
				(h.ambito.v_ini !== null &&
					h.ambito.v_fin !== null &&
					h.ambito.v_ini >= v_ini &&
					h.ambito.v_fin <= v_fin)
		),
		arquitecturas_realizadas: (s.arquitecturas_realizadas ?? [])
			.map((r) => ({ ...r, v_ini: Math.max(v_ini, r.v_ini), v_fin: Math.min(v_fin, r.v_fin) }))
			.filter((r) => r.v_ini <= r.v_fin)
	};
}

export function precomputarArquitecturas(secuencias, catalogo) {
	const grupos = new Map();
	for (const s of secuencias) {
		if (!s.forma_slug) continue;
		if (!grupos.has(s.forma_slug))
			grupos.set(s.forma_slug, {
				forma_slug: s.forma_slug,
				extension: 0,
				con_arquitectura: 0,
				valores: new Map()
			});
		const g = grupos.get(s.forma_slug);
		g.extension += s.v_fin - s.v_ini + 1;
		for (const r of rangosArquitectura(s))
			if (r.arquitectura_slug) {
				const n = r.v_fin - r.v_ini + 1;
				g.con_arquitectura += n;
				g.valores.set(r.arquitectura_slug, (g.valores.get(r.arquitectura_slug) ?? 0) + n);
			}
	}
	return [...grupos.values()]
		.map(({ valores, ...g }) => ({
			...g,
			pendiente: catalogo.find((f) => f.slug === g.forma_slug)?.arquitecturas.length
				? g.extension - g.con_arquitectura
				: 0,
			no_aplica: catalogo.find((f) => f.slug === g.forma_slug)?.arquitecturas.length
				? 0
				: g.extension - g.con_arquitectura,
			valores: [...valores]
				.sort(([a], [b]) => a.localeCompare(b))
				.map(([arquitectura_slug, versos]) => ({
					arquitectura_slug,
					versos,
					denominador_forma: g.extension,
					proporcion_confirmada: versos / g.extension,
					proporcion_total:
						g.extension === g.con_arquitectura
							? { valor: versos / g.extension, motivo: null }
							: { valor: null, motivo: 'arquitectura_pendiente' }
				}))
		}))
		.sort((a, b) => a.forma_slug.localeCompare(b.forma_slug));
}

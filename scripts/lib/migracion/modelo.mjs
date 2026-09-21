/**
 * El modelo de la migración de una obra: lo que se sabe de cada secuencia legada, lo que falta y
 * lo que hay que preguntar. **Puro**: no consulta nada; recibe filas y devuelve estructuras.
 *
 * Lo consumen los tres escritores —Markdown, HTML y Excel— y lo consumirá el aplicador, que lee
 * las respuestas del Excel por las mismas claves que aquí se generan. Por eso las reglas que
 * traducen el vocabulario viejo viven aquí y no en un escritor: la tabla de caracterizaciones,
 * el umbral de filas por unidad, el formato de las claves.
 */

// ---------------------------------------------------------------------------
// Constantes compartidas con el aplicador
// ---------------------------------------------------------------------------

/**
 * A partir de cuántas unidades una pregunta por estrofa se contesta **una vez para todas, con
 * excepciones**, en vez de una fila por estrofa.
 *
 * Solo llegan aquí las preguntas con más de dos opciones, que son las que no tienen una respuesta
 * dominante: la tipología de una quintilla cambia de estrofa en estrofa y contestarla «todas
 * aabba, salvo estas» sería pedirle al editor que resuma lo que precisamente hay que mirar una a
 * una. El tope está donde el Excel se hace inmanejable, no donde la pregunta cambia de naturaleza:
 * las series de quintillas más largas del corpus son de 35 estrofas.
 *
 * El esquema de una redondilla no pasa por aquí —abba o abab son dos opciones— y se contesta
 * siempre de una vez, con sus excepciones.
 */
export const UMBRAL_FILAS_POR_UNIDAD = 40;

/**
 * Qué se hace con cada caracterización por rango del vocabulario viejo. Es la tabla de §2bis del
 * plan, con lo que se comprobó en la base el 19 de septiembre de 2026: los nueve tipos en uso.
 *
 * `pide` dice qué se le pregunta al editor en la pestaña de desviaciones: `silabas`, la medida
 * observada si la tiene a mano; `confirmar`, que la traducción propuesta le valga; nada, si solo
 * se le enseña.
 */
export const DESTINO_CARACTERIZACION = {
	hipermetrico: {
		destino: 'Pasa a ser una desviación de medida: el verso tiene más sílabas de las que le tocan',
		pide: 'silabas',
		desviacion: { dimension: 'metro', relacion_norma: 'mayor_que_norma' }
	},
	hipometrico: {
		destino:
			'Pasa a ser una desviación de medida: el verso tiene menos sílabas de las que le tocan',
		pide: 'silabas',
		desviacion: { dimension: 'metro', relacion_norma: 'menor_que_norma' }
	},
	rima_defectuosa: {
		destino: 'Pasa a ser una desviación de rima, y se conserva tu nota',
		pide: null,
		desviacion: { dimension: 'rima', relacion_norma: 'otra' }
	},
	laguna: {
		destino: 'Pasa a ser una desviación de estructura por versos que faltan',
		pide: null,
		desviacion: { dimension: 'estructura', relacion_norma: 'falta' }
	},
	patron_alternativo: {
		destino: 'Pasa a ser una desviación de rima, y se conserva tu nota',
		pide: 'confirmar',
		desviacion: { dimension: 'rima', relacion_norma: 'otra' }
	},
	mayoria_agudas: {
		destino:
			'En un romance con asonancia en «a» el final agudo ya va implícito, así que no se registra aparte',
		pide: 'confirmar',
		desviacion: null
	},
	mayoria_esdrujulas: {
		destino: 'Pasa al rasgo «Final acentual», con el valor esdrújulo',
		pide: 'confirmar',
		desviacion: null,
		rasgo: 'Esdrújulo'
	},
	cantado: { destino: 'Se mantiene como está: describe el pasaje, no su métrica', pide: null },
	prosa: { destino: 'Se mantiene como está: describe el pasaje, no su métrica', pide: null },
	evocacion_metrica: {
		destino: 'Se mantiene como está: describe el pasaje, no su métrica',
		pide: null
	},
	fenomenos_enunciativos: {
		destino: 'Se mantiene como está: describe el pasaje, no su métrica',
		pide: null
	}
};

/** Las opciones cerradas de una decisión sobre un rango que no cuadra. */
export const OPCIONES_DECISION = [
	'Hay una laguna que no se contó (indico dónde y cuántos versos faltan)',
	'El rango está mal (indico el correcto)',
	'Es otra forma (indico cuál)',
	'Es otra cosa (lo explico al lado)'
];

export const OPCIONES_CONFIRMACION = ['Es correcto', 'No es así (lo corrijo al lado)'];

/**
 * Qué preguntas opcionales se hacen además de las obligatorias, según el término legado. El
 * catálogo no obliga a decir dónde cae el quebrado, pero si el término viejo decía «de pie
 * quebrado» hay que preguntarlo.
 */
export const PREGUNTAS_EXTRA_POR_TERMINO = {
	copla_real_de_pie_quebrado: ['Pie quebrado']
};

// ---------------------------------------------------------------------------
// Claves
//
// Cada fila del Excel lleva una clave que el aplicador entiende sin mirar el texto. Se escribe y
// se lee aquí, en un solo sitio.
// ---------------------------------------------------------------------------

export function claveDecision(secuenciaId) {
	return `L|${secuenciaId}`;
}
export function claveFusion(primeraId, ultimaId) {
	return `F|${primeraId}|${ultimaId}`;
}
export function claveSinopsis(primeraId) {
	return `S|${primeraId}`;
}
export function claveRespuesta(secuenciaId, grupoId) {
	return `R|${secuenciaId}|${grupoId}`;
}
export function claveRespuestaUnidad(secuenciaId, grupoId, unidadVIni) {
	return `U|${secuenciaId}|${grupoId}|${unidadVIni}`;
}
export function claveConfirmacion(secuenciaId) {
	return `C|${secuenciaId}`;
}
export function claveArquitectura(secuenciaId) {
	return `A|${secuenciaId}`;
}
/** Una pregunta nombrada y no identificada: cuando aún no se sabe la arquitectura. */
export function claveRespuestaPorNombre(secuenciaId, nombre) {
	return `Q|${secuenciaId}|${nombre}`;
}
export function claveCierre(secuenciaId) {
	return `X|${secuenciaId}`;
}
export function claveDesviacion(caracterizacionId) {
	return `D|${caracterizacionId}`;
}

export function leerClave(clave) {
	const [tipo, ...resto] = String(clave ?? '').split('|');
	return { tipo, partes: resto };
}

// ---------------------------------------------------------------------------
// Longitud
// ---------------------------------------------------------------------------

/** La misma lógica que `isMetricLengthCompatible` y que `longitud_encaja_en_regla` en SQL. */
export function longitudEncaja(regla, versos) {
	if (!regla) return true;
	const desplazamientos = regla.desplazamientos?.length ? regla.desplazamientos : [0];
	return desplazamientos.some((d) => {
		const resto = versos - d;
		if (resto < regla.minimo_versos) return false;
		const modulo = Number(regla.modulo_versos);
		if (!(modulo > 0)) return false;
		return (((resto - regla.residuo_versos) % modulo) + modulo) % modulo === 0;
	});
}

/** Con qué desplazamiento encaja, para poder decir «20 tercetos y un verso de cierre». */
export function desplazamientoQueEncaja(regla, versos) {
	if (!regla) return null;
	const desplazamientos = regla.desplazamientos?.length ? regla.desplazamientos : [0];
	for (const d of desplazamientos) {
		if (longitudEncaja({ ...regla, desplazamientos: [d] }, versos)) return d;
	}
	return null;
}

/** Cuántos versos habría que sumar (o restar) para que la longitud cuadre. */
function ajusteQueCuadra(regla, versos) {
	const modulo = Number(regla?.modulo_versos ?? 0);
	if (!(modulo > 0)) return { mas: null, menos: null };
	let mas = null;
	let menos = null;
	for (let k = 1; k <= modulo; k += 1) {
		if (mas === null && longitudEncaja(regla, versos + k)) mas = k;
		if (menos === null && versos - k > 0 && longitudEncaja(regla, versos - k)) menos = k;
	}
	return { mas, menos };
}

// ---------------------------------------------------------------------------
// Unidades
// ---------------------------------------------------------------------------

/**
 * Las unidades de una secuencia: **de los subtipos si los hay**, y si no, dividiendo el rango.
 *
 * Los subtipos son lo que alguien miró estrofa a estrofa, y sus rangos dicen más que la división
 * mecánica: dónde una unidad mide menos de lo que debe, dónde quedan versos sin cubrir. Una
 * arquitectura sin extensión de unidad —romance, silva, terceto encadenado— no tiene unidades que
 * enumerar: la secuencia es la unidad.
 */
export function unidadesDe(secuencia) {
	const subtipos = [...(secuencia.subtipos ?? [])].sort((a, b) => a.v_ini - b.v_ini);
	if (subtipos.length > 0) {
		return subtipos.map((s) => ({
			v_ini: Number(s.v_ini),
			v_fin: Number(s.v_fin),
			origen: 'subtipo',
			termino: s.termino ?? null
		}));
	}
	const unidad = Number(secuencia.unidad_versos_min ?? 0);
	if (!(unidad > 0)) return [];
	const unidades = [];
	const total = Math.floor(secuencia.n_versos / unidad);
	for (let i = 0; i < total; i += 1) {
		const v_ini = secuencia.v_ini + i * unidad;
		unidades.push({ v_ini, v_fin: v_ini + unidad - 1, origen: 'division', termino: null });
	}
	return unidades;
}

// ---------------------------------------------------------------------------
// Diagnóstico
// ---------------------------------------------------------------------------

/**
 * La forma con su arquitectura, en minúscula, para nombrarla en una frase: «redondilla
 * octosílaba», «seguidilla simple». Una arquitectura sola no dice nada.
 */
export function nombreDeForma(secuencia) {
	return [secuencia.forma_propuesta, secuencia.arquitectura_propuesta]
		.filter(Boolean)
		.map((n) => String(n).toLowerCase())
		.join(' ');
}

/** «una redondilla», «un soneto», «una canción»: el género se lee del nombre de la forma. */
export function conArticulo(secuencia) {
	const forma = String(secuencia.forma_propuesta ?? '').toLowerCase();
	const femenino = /(a|ción)$/.test(forma.split(/[\s-]/)[0] ?? '') || /ción/.test(forma);
	return `${femenino ? 'una' : 'un'} ${nombreDeForma(secuencia)}`;
}

const rango = (desde, hasta) => (desde === hasta ? `${desde}` : `${desde}–${hasta}`);
const plural = (n, singular, plural_) => `${n} ${n === 1 ? singular : plural_}`;

const solapa = (a, b) => Number(a.v_ini) <= Number(b.v_fin) && Number(a.v_fin) >= Number(b.v_ini);

/**
 * Qué le pasa a una secuencia cuyo rango no cuadra, dicho de la manera más concreta que los datos
 * permiten.
 *
 * Una laguna se registra **contando sus versos**: la estrofa a la que le faltan dos sigue ocupando
 * cinco números. Así que si el rango solo cuadra sumando la laguna, lo que pasa es que no se
 * contó, y la consecuencia es renumerar la obra desde ahí. Un romance impar no admite otra
 * explicación que un verso perdido: se pide localizarlo.
 */
export function diagnosticar(secuencia) {
	const unidades = secuencia.unidades ?? [];
	const unidad = Number(secuencia.unidad_versos_min ?? 0);
	const lagunas = (secuencia.caracterizaciones ?? []).filter((c) => c.termino === 'laguna');
	const regla = secuencia.regla ?? null;
	const n = Number(secuencia.n_versos);

	// --- Con subtipos: el problema se localiza estrofa a estrofa.
	if (unidades.some((u) => u.origen === 'subtipo') && unidad > 0) {
		const problemas = [];
		for (const u of unidades) {
			const mide = u.v_fin - u.v_ini + 1;
			if (mide === unidad) continue;
			const laguna = lagunas.find((l) => solapa(l, u));
			let texto = `El subtipo ${u.v_ini}–${u.v_fin} tiene ${mide} versos, cuando una estrofa de esta forma tiene ${unidad}.`;
			if (laguna) {
				const faltan = unidad - mide;
				texto +=
					` En ese punto hay anotada una laguna (${laguna.v_ini}–${laguna.v_fin}). Si los ${faltan}` +
					` versos que faltan no se contaron en la numeración, la estrofa iría de ${u.v_ini} a` +
					` ${u.v_ini + unidad - 1} y todo lo que viene después se desplazaría ${faltan}` +
					` verso${faltan === 1 ? '' : 's'}.`;
			}
			problemas.push(texto);
		}
		// Versos de la secuencia que ningún subtipo cubre.
		let cursor = secuencia.v_ini;
		const huecos = [];
		for (const u of unidades) {
			if (u.v_ini > cursor) huecos.push(rango(cursor, u.v_ini - 1));
			cursor = Math.max(cursor, u.v_fin + 1);
		}
		if (cursor <= secuencia.v_fin) huecos.push(rango(cursor, secuencia.v_fin));
		if (huecos.length > 0) {
			problemas.push(`Hay versos sin subtipo: ${huecos.join(', ')}.`);
		}
		if (problemas.length === 0) return null;
		return {
			tipo: 'unidades',
			texto: problemas.join(' '),
			opciones: OPCIONES_DECISION
		};
	}

	// --- Sin subtipos: solo se sabe que el total no cuadra.
	if (secuencia.longitud_compatible !== false) return null;

	if (regla && n < Number(regla.minimo_versos)) {
		return {
			tipo: 'minimo',
			texto:
				`Solo tiene ${n} versos, y ${conArticulo(secuencia)} necesita al menos` +
				` ${regla.minimo_versos}. Puede que el rango esté mal o que se trate de otra forma.`,
			opciones: OPCIONES_DECISION.slice(1)
		};
	}

	const { mas, menos } = ajusteQueCuadra(regla, n);
	const esRomance = regla && Number(regla.modulo_versos) === 2 && regla.origen === 'ciclo_rima';
	if (esRomance) {
		return {
			tipo: 'impar',
			texto:
				`Tiene ${n} versos, y ${conArticulo(secuencia)} no puede tener un número` +
				` impar: en algún punto falta o sobra un verso. Hay que localizarlo y decir si se trata de` +
				` una laguna, en cuyo caso renumeraré la obra a partir de ahí, o de un error en el rango,` +
				` en cuyo caso hace falta el rango correcto.`,
			opciones: OPCIONES_DECISION.slice(0, 2)
		};
	}

	const lagunaDentro = lagunas[0] ?? null;
	let texto =
		`Sus ${n} versos no encajan en ${conArticulo(secuencia)}` +
		(regla?.explicacion ? `, que se compone de ${regla.explicacion}` : '') +
		'.';
	const ajustes = [];
	if (mas) ajustes.push(`${mas} verso${mas === 1 ? '' : 's'} más (${n + mas})`);
	if (menos) ajustes.push(`${menos} verso${menos === 1 ? '' : 's'} menos (${n - menos})`);
	if (ajustes.length > 0) texto += ` Encajaría con ${ajustes.join(' o con ')}.`;
	if (lagunaDentro) {
		texto +=
			` Hay una laguna anotada en ${lagunaDentro.v_ini}–${lagunaDentro.v_fin}; lo más probable es` +
			` que sus versos no se contaran en la numeración, y en ese caso todo lo que viene después se` +
			` desplaza.`;
	}
	return { tipo: 'longitud', texto, opciones: OPCIONES_DECISION, mas, menos };
}

/**
 * Cuando el rango cuadra solo gracias a un cierre —los tercetos encadenados de 3n+1—, no es un
 * problema pero conviene decirlo, por si el verso de más es un error de rango y no un cierre.
 */
export function cierreQueExplica(secuencia) {
	const regla = secuencia.regla;
	if (!regla || secuencia.longitud_compatible === false) return null;
	const d = desplazamientoQueEncaja(regla, Number(secuencia.n_versos));
	if (!d) return null;
	const bloques = (Number(secuencia.n_versos) - d) / Number(regla.modulo_versos);
	return {
		cierre: d,
		bloques,
		texto:
			`Los ${secuencia.n_versos} versos se reparten en ${bloques} bloques de ${regla.modulo_versos}` +
			` más un cierre de ${d} verso${d === 1 ? '' : 's'}. Comprueba que ese cierre existe y que no` +
			` es un error en el rango.`
	};
}

// ---------------------------------------------------------------------------
// Tramos que se funden
// ---------------------------------------------------------------------------

/**
 * Tramos que el modelo viejo obligó a partir y el nuevo recoge como una sola secuencia.
 *
 * El criterio lo da la propia arquitectura: si declara la extensión de su unidad, el pasaje se
 * compone de unidades repetidas y lo que varía entre ellas es una respuesta por unidad. Si no la
 * declara —romance, silva—, la secuencia *es* la unidad y no se toca.
 *
 * Se respetan las fronteras de jornada **y de cuadro**: partir ahí es una decisión editorial,
 * no un artefacto del vocabulario.
 */
export function tramosFundibles(secuencias, cortes) {
	const fronteras = new Set(cortes.map((c) => Number(c)));
	const tramos = [];
	let actual = [];

	const cerrar = () => {
		if (actual.length > 1) tramos.push(actual);
		actual = [];
	};

	for (const fila of secuencias) {
		const unidadAcotada = fila.unidad_versos_min != null && fila.unidad_versos_max != null;
		if (!unidadAcotada) {
			cerrar();
			continue;
		}
		if (actual.length === 0) {
			actual = [fila];
			continue;
		}
		const anterior = actual[actual.length - 1];
		const contigua = Number(fila.v_ini) === Number(anterior.v_fin) + 1;
		const mismaArquitectura = anterior.arquitectura_propuesta_id === fila.arquitectura_propuesta_id;
		const cruzaFrontera = fronteras.has(Number(anterior.v_fin));

		if (contigua && mismaArquitectura && !cruzaFrontera) actual.push(fila);
		else {
			cerrar();
			actual = [fila];
		}
	}
	cerrar();
	return tramos;
}

/**
 * Cómo quedan los indicadores de escena al fundir: los booleanos por suma, las intervenciones por
 * coincidencia y, si no coinciden, «compartida».
 */
export function fundirIndicadores(partes) {
	const alguno = (campo) => partes.some((p) => p[campo] === true);
	const coincidencia = (campo) => {
		const valores = new Set(partes.map((p) => p[campo] ?? 'sin_intervencion'));
		return valores.size === 1 ? [...valores][0] : 'compartida';
	};
	return {
		inaugura_espacio: alguno('inaugura_espacio'),
		versos_partidos: alguno('versos_partidos'),
		evento_sobrenatural: alguno('evento_sobrenatural'),
		intervencion_personajes_femeninos: coincidencia('intervencion_personajes_femeninos'),
		intervencion_figuras_donaire: coincidencia('intervencion_figuras_donaire'),
		intervencion_personajes_sobrenaturales: coincidencia('intervencion_personajes_sobrenaturales')
	};
}

// ---------------------------------------------------------------------------
// Preguntas
// ---------------------------------------------------------------------------

/** Cómo se contesta una pregunta en el Excel: con desplegable o con texto de un formato dado. */
export function formatoDeRespuesta(pregunta) {
	const opciones = pregunta.opciones ?? [];
	const porPosicion = opciones.some((o) => o.posicion_unidad != null);
	const varias = Number(pregunta.selecciones_max ?? 1) > 1;
	// **Se pregunta lo que el catálogo sabe guardar.** Una medida se escribe en cifras cuando las
	// opciones van por posición —cada verso de la lira tiene la suya— o cuando no hay repertorio;
	// si el repertorio es una lista de metros sin posición, como en el pareado, escribir «11 11» no
	// resolvería a ninguna opción y la respuesta se perdería: se eligen por nombre.
	if (pregunta.dimension === 'metro' && (porPosicion || opciones.length === 0)) {
		return Number(pregunta.selecciones_min) >= 1
			? {
					modo: 'medidas',
					ayuda:
						'Escribe el número de sílabas de cada verso, en orden y separados por espacios («7 11 7 7 11»)'
				}
			: {
					modo: 'posiciones',
					ayuda:
						'Indica en qué versos cae el quebrado y cuántas sílabas tiene cada uno («3: 4, 8: 5»)'
				};
	}
	if (opciones.length === 0 && pregunta.dimension === 'rima') {
		return {
			modo: 'esquema',
			ayuda:
				'Escribe una letra por verso, en mayúscula si es de arte mayor y un guion si el verso queda suelto («aBab-B»)'
		};
	}
	if (opciones.length === 0) return { modo: 'texto', ayuda: 'Escríbelo en texto libre' };
	if (varias) {
		// Cuántas hacen falta, que es lo primero que uno se pregunta al ver una lista larga.
		const min = Number(pregunta.selecciones_min ?? 0);
		const max = Number(pregunta.selecciones_max ?? 1);
		const cuantas =
			min === max ? `Indica ${min}, en orden y separadas` : `Indica hasta ${max}, separadas`;
		return {
			modo: 'varias',
			ayuda: `${cuantas} por punto y coma, eligiendo entre: ${opciones.map((o) => o.nombre).join(' · ')}`
		};
	}
	return { modo: 'lista', ayuda: 'Elige en el desplegable', lista: opciones.map((o) => o.nombre) };
}

/**
 * Las filas del cuestionario de una secuencia, ya calculadas sus unidades, sus respuestas y su
 * diagnóstico. Devuelve tres listas —responder, confirmar, desviaciones— con filas del mismo
 * formato.
 */
export function filasDeSecuencia(secuencia) {
	const responder = [];
	const confirmar = [];
	const desviaciones = [];
	const versos = `${secuencia.v_ini}–${secuencia.v_fin}`;
	const forma = [secuencia.forma_propuesta, secuencia.arquitectura_propuesta]
		.filter(Boolean)
		.join(' · ');
	const base = { secuencia_id: secuencia.secuencia_id, versos, forma };

	// --- Decisiones: el rango o las unidades no cuadran.
	//
	// **Lo que no cuadra se decide antes de preguntar nada más.** Las estrofas de una secuencia
	// salen de repartir su rango, así que si el rango está en duda el reparto también: preguntar
	// «la medida de la estrofa 7» sobre un reparto que sabemos falso es pedir un trabajo que luego
	// hay que tirar. Y si además la forma puede ser otra —tiene menos versos que su mínimo—, no se
	// le pregunta nada de esa forma.
	const rangoEnDuda = Boolean(secuencia.diagnostico) || Boolean(secuencia.reparto_problema);
	const formaEnDuda = secuencia.diagnostico?.tipo === 'minimo';
	// Un pasaje que no se reparte en las partes de su forma se pregunta igual que un rango que no
	// cuadra: **puede ser el rango, puede ser otra forma, y puede ser que el catálogo no admita algo
	// que existe.** Lo que no puede es anotarse sin saberlo.
	if (!secuencia.diagnostico && secuencia.reparto_problema) {
		responder.push({
			...base,
			clave: claveDecision(secuencia.secuencia_id),
			tipo: 'decidir',
			asunto:
				`Sus ${secuencia.n_versos} versos no se reparten en las partes que declara ` +
				`${conArticulo(secuencia)}. Puede que el rango esté mal, que se trate de otra forma o ` +
				'que el catálogo no esté admitiendo algo que existe: dime lo que veas y lo consulto.',
			propuesta: '',
			formato: {
				modo: 'lista',
				lista: OPCIONES_DECISION,
				ayuda: 'Elige en el desplegable y explícalo al lado'
			}
		});
	}
	if (secuencia.diagnostico) {
		responder.push({
			...base,
			clave: claveDecision(secuencia.secuencia_id),
			tipo: 'decidir',
			asunto:
				secuencia.diagnostico.texto +
				(formaEnDuda
					? ' Hasta saber esto no te pregunto nada más de este pasaje.'
					: ' Las preguntas que dependen de cómo se reparta en estrofas te las haré cuando esto esté claro.'),
			propuesta: '',
			formato: {
				modo: 'lista',
				lista: secuencia.diagnostico.opciones,
				ayuda: 'Elige en el desplegable y explícalo al lado'
			}
		});
	}

	// --- Un cierre que explica el rango: se confirma.
	const cierre = cierreQueExplica(secuencia);
	if (cierre) {
		confirmar.push({
			...base,
			clave: claveCierre(secuencia.secuencia_id),
			tipo: 'confirmar',
			asunto: 'El cierre de la serie',
			propuesta: cierre.texto,
			formato: { modo: 'lista', lista: OPCIONES_CONFIRMACION, ayuda: '' }
		});
	}

	// --- Sin arquitectura: se pregunta cuál, y lo que todas preguntan por igual.
	if (!secuencia.arquitectura_propuesta_id && secuencia.arquitecturas_de_forma?.length) {
		responder.push({
			...base,
			clave: claveArquitectura(secuencia.secuencia_id),
			tipo: 'responder',
			asunto: `El término «${secuencia.termino_legado}» no dice qué arquitectura de «${secuencia.forma_propuesta}» es. Indica cuál.`,
			propuesta: '',
			formato: {
				modo: 'lista',
				lista: secuencia.arquitecturas_de_forma.map((a) => a.nombre),
				ayuda: 'Elige en el desplegable'
			},
			pregunta: 'Arquitectura'
		});
		for (const pregunta of secuencia.preguntas_comunes ?? []) {
			responder.push({
				...base,
				clave: claveRespuestaPorNombre(secuencia.secuencia_id, pregunta.nombre),
				tipo: 'responder',
				asunto: pregunta.nombre,
				propuesta: '',
				formato: formatoDeRespuesta(pregunta),
				pregunta: pregunta.nombre
			});
		}
	}

	// --- Lo que falta por responder, y lo que se pregunta además por el término legado.
	const respondidas = new Set((secuencia.respuestas ?? []).map((r) => r.grupo_eleccion_id));
	const extra = new Set(PREGUNTAS_EXTRA_POR_TERMINO[secuencia.termino_legado] ?? []);
	const pendientes = (secuencia.preguntas ?? []).filter(
		(p) =>
			!respondidas.has(p.grupo_eleccion_id) &&
			(Number(p.selecciones_min) >= 1 || extra.has(p.nombre))
	);
	const unidades = secuencia.unidades ?? [];
	for (const pregunta of pendientes) {
		if (formaEnDuda) continue;
		if (rangoEnDuda && pregunta.alcance === 'unidad') continue;
		const formato = formatoDeRespuesta(pregunta);
		// Una fila por estrofa solo cuando son pocas **y la respuesta varía de verdad**: ocho
		// tipologías de quintilla se eligen una a una; abba o abab en dieciséis redondillas se
		// contesta «todas abba» y las excepciones.
		const porUnidad =
			pregunta.alcance === 'unidad' &&
			unidades.length > 0 &&
			unidades.length <= UMBRAL_FILAS_POR_UNIDAD &&
			(pregunta.opciones ?? []).length > 2;
		if (porUnidad) {
			// Una pregunta que señala una sección —«Primera quintilla»— se responde una vez por
			// unidad, y la unidad es la estrofa entera: decir «estrofa 3» de una copla real que mide
			// diez versos haría pensar que la quintilla son esos diez.
			const nombreUnidad = pregunta.seccion_id
				? String(secuencia.forma_propuesta ?? 'unidad').toLowerCase()
				: 'estrofa';
			unidades.forEach((u, i) => {
				responder.push({
					...base,
					clave: claveRespuestaUnidad(secuencia.secuencia_id, pregunta.grupo_eleccion_id, u.v_ini),
					tipo: 'responder',
					asunto: `${pregunta.nombre} · ${nombreUnidad} ${i + 1} (vv. ${u.v_ini}–${u.v_fin})`,
					propuesta: '',
					formato,
					pregunta: pregunta.nombre,
					unidad: u
				});
			});
		} else {
			const cuantas =
				pregunta.alcance === 'unidad' && unidades.length > 0
					? ` · ${plural(unidades.length, 'estrofa', 'estrofas')}`
					: '';
			// Escribir la medida o el esquema de una secuencia entera es contar sus versos uno a
			// uno: decir cuántos son evita que el editor se encuentre con la sorpresa a media celda.
			const cuantosVersos =
				(formato.modo === 'medidas' || formato.modo === 'esquema') &&
				pregunta.alcance === 'secuencia'
					? ` (son ${secuencia.n_versos} versos)`
					: '';
			// Una pregunta sobre una parte que puede no estar —el remate de una canción— solo se
			// contesta si el pasaje la lleva: en blanco no es una respuesta que falte.
			const siLaLleva =
				pregunta.seccion_id && Number(pregunta.seccion_repeticiones_min) === 0
					? `. Solo si este pasaje lleva ${String(pregunta.seccion_nombre ?? 'esa parte').toLowerCase()}; si no, déjalo en blanco`
					: '';
			responder.push({
				...base,
				clave: claveRespuesta(secuencia.secuencia_id, pregunta.grupo_eleccion_id),
				tipo: 'responder',
				asunto: `${pregunta.nombre}${cuantas}`,
				propuesta: '',
				formato: {
					...formato,
					ayuda:
						formato.ayuda +
						cuantosVersos +
						siLaLleva +
						(pregunta.alcance === 'unidad' && unidades.length > 1
							? '. La respuesta vale para todas las estrofas; las que sean distintas, en «Excepciones» (versos: respuesta)'
							: '')
				},
				pregunta: pregunta.nombre
			});
		}
	}

	// --- Lo derivado del término legado: se enseña para confirmar. Lo anotado no se pregunta.
	const derivadas = new Map();
	for (const r of secuencia.respuestas ?? []) {
		if (r.origen !== 'derivada') continue;
		const entrada = derivadas.get(r.grupo_eleccion_id) ?? {
			pregunta: r.pregunta,
			alcance: r.alcance,
			respuestas: new Map()
		};
		entrada.respuestas.set(r.respuesta, (entrada.respuestas.get(r.respuesta) ?? 0) + 1);
		derivadas.set(r.grupo_eleccion_id, entrada);
	}
	// Una sola fila por secuencia con todo lo derivado: un endecasílabo suelto trae tres
	// respuestas y confirmarlas de una vez es lo natural. Si algo no es así, la corrección dice cuál.
	if (derivadas.size > 0) {
		// En orden fijo, y «Dístico final: sí» en vez de repetir el nombre de la pregunta.
		const partes = [...derivadas.values()]
			.sort((a, b) => a.pregunta.localeCompare(b.pregunta, 'es'))
			.map((d) => {
				const valores = [...d.respuestas].map(([respuesta, n]) => {
					const valor = respuesta === d.pregunta ? 'sí' : respuesta;
					return d.alcance === 'unidad' && n > 1 ? `${valor} en las ${n} estrofas` : valor;
				});
				return `${d.pregunta}: ${valores.join(', ')}`;
			});
		confirmar.push({
			...base,
			clave: claveConfirmacion(secuencia.secuencia_id),
			tipo: 'confirmar',
			asunto: derivadas.size === 1 ? [...derivadas.values()][0].pregunta : 'Varias respuestas',
			propuesta:
				derivadas.size === 1 ? partes[0].slice(partes[0].indexOf(': ') + 2) : partes.join('; '),
			origen: secuencia.termino_legado,
			formato: { modo: 'lista', lista: OPCIONES_CONFIRMACION, ayuda: '' }
		});
	}

	// --- Las caracterizaciones por rango, una a una.
	for (const c of secuencia.caracterizaciones ?? []) {
		const destino = DESTINO_CARACTERIZACION[c.termino] ?? {
			destino: `No hay traducción prevista para «${c.termino}»; lo revisaré a mano`,
			pide: 'confirmar'
		};
		// La tabla promete conservar la nota; donde no hay nota, no se promete.
		const comoQueda = (c.observaciones ?? '').trim()
			? destino.destino
			: destino.destino.replace(', y se conserva tu nota', '');
		desviaciones.push({
			...base,
			clave: claveDesviacion(c.caracterizacion_rango_id),
			tipo:
				destino.pide === 'silabas'
					? 'silabas'
					: destino.pide === 'confirmar'
						? 'confirmar'
						: 'informar',
			versos: rango(Number(c.v_ini), Number(c.v_fin)),
			secuenciaVersos: versos,
			termino: c.termino,
			asunto: comoQueda,
			observacion: c.observaciones ?? '',
			formato:
				destino.pide === 'silabas'
					? { modo: 'texto', ayuda: 'El número de sílabas del verso, si lo tienes a mano' }
					: destino.pide === 'confirmar'
						? { modo: 'lista', lista: OPCIONES_CONFIRMACION, ayuda: '' }
						: null
		});
	}

	return { responder, confirmar, desviaciones };
}

/**
 * Las filas de un tramo que se funde: la fusión, que se confirma, y la sinopsis nueva, que se
 * escribe.
 *
 * **Fundir no es una decisión del editor, es la regla**: secuencias contiguas de la misma
 * arquitectura, con unidad de extensión fija y sin cruzar jornada ni cuadro, son un solo pasaje que
 * el vocabulario anterior obligaba a partir. Por eso se enseña resuelta, como lo derivado de un
 * término, y lo que se le pide al editor es que diga si en su obra no era así.
 */
export function filasDeFusion(tramo) {
	const primera = tramo[0];
	const ultima = tramo[tramo.length - 1];
	const desde = Number(primera.v_ini);
	const hasta = Number(ultima.v_fin);
	const unidad = Number(primera.unidad_versos_min);
	const versos = hasta - desde + 1;
	const unidades = versos / unidad;
	const forma = [primera.forma_propuesta, primera.arquitectura_propuesta]
		.filter(Boolean)
		.join(' · ');
	const abreEspacioFuera = tramo.slice(1).filter((p) => p.inaugura_espacio === true);
	let propuesta =
		`En tu obra este pasaje está dividido en ${tramo.length} secuencias (${tramo.map((p) => `${p.v_ini}–${p.v_fin}`).join(', ')}),` +
		` y pasa a ser una sola con ${Number.isInteger(unidades) ? unidades : `¿${versos} / ${unidad}?`}` +
		` estrofas de ${unidad} versos: lo que distinguía a cada parte se conserva en sus estrofas.`;
	if (abreEspacioFuera.length > 0) {
		propuesta += ` Ten en cuenta que ${abreEspacioFuera.map((p) => `${p.v_ini}–${p.v_fin}`).join(' y ')} está marcada como inicio de un espacio nuevo.`;
	}
	// Cada sinopsis en su párrafo: pegadas con un espacio parecían menos de las que son.
	const sinopsis = tramo
		.map((p) => (p.sinopsis ?? '').trim())
		.filter(Boolean)
		.join('\n\n');
	const cuantas = tramo.map((p) => (p.sinopsis ?? '').trim()).filter(Boolean).length;
	return {
		confirmar: [
			{
				secuencia_id: primera.secuencia_id,
				clave: claveFusion(primera.secuencia_id, ultima.secuencia_id),
				tipo: 'confirmar',
				versos: `${desde}–${hasta}`,
				forma,
				asunto: 'Un solo pasaje',
				propuesta,
				origen: [...new Set(tramo.map((p) => p.termino_legado).filter(Boolean))].join(', '),
				formato: { modo: 'lista', lista: OPCIONES_CONFIRMACION, ayuda: '' }
			}
		],
		responder: [
			{
				secuencia_id: primera.secuencia_id,
				clave: claveSinopsis(primera.secuencia_id),
				tipo: 'responder',
				versos: `${desde}–${hasta}`,
				forma,
				asunto: 'Escribe la sinopsis de la secuencia completa',
				propuesta: sinopsis,
				formato: {
					modo: 'texto',
					ayuda:
						cuantas === 1
							? 'En «Propuesta» tienes la sinopsis actual del tramo, para partir de ella'
							: `En «Propuesta» tienes las ${cuantas} sinopsis actuales del tramo, en párrafos separados, para partir de ellas`
				}
			}
		]
	};
}

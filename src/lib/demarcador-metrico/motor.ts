import type {
	CatalogoDemarcador,
	DesviacionLongitud,
	EvidenciaNormativa,
	FormaPuntuada,
	HipotesisMetrica,
	HipotesisPuntuada,
	InterpretacionLongitud,
	Discrepancia,
	DetalleCompatibilidad,
	EncajeForma,
	ModoDemarcador,
	ModalidadEvidencia,
	ObservabilidadEvidencia,
	PreguntaDemarcador,
	RespuestaDemarcador,
	TextoDimension,
	ValorEvidencia,
	VeredictoHipotesis
} from './modelo';

const PESO_MODALIDAD: Record<ModalidadEvidencia, { coincide: number; contradice: number }> = {
	definitoria: { coincide: 1, contradice: 1.25 },
	habitual: { coincide: 0.62, contradice: 0.45 },
	admitida: { coincide: 0.28, contradice: 0.1 },
	excepcional: { coincide: 0.12, contradice: 0 }
};

const FIABILIDAD: Record<ObservabilidadEvidencia, number> = {
	directa: 1,
	especializada: 0.65,
	derivada: 0
};

/**
 * La ventaja que separa a la primera de las demás: con ella el recorrido se detiene, la primera
 * destaca y las que quedan a menos se consideran empatadas con ella.
 */
export const VENTAJA_SUFICIENTE = 0.75;

/**
 * Por debajo de esto, dos puntuaciones empatan: es el orden de los desempates que no son evidencia,
 * como el de la arquitectura principal.
 */
const MARGEN_EMPATE = 0.1;

const MAX_OPCIONES = 7;
const MAX_OPCIONES_METRO_EXACTO = 12;
const MAX_OPCIONES_AGRUPACION = 12;

/**
 * La respuesta de quien no ve grupos regulares. No la declara ninguna forma —las series no tienen
 * unidad que agrupar—, así que contradice a todas las estrofas y deja intactas las series, que es
 * lo que hacía el «no» de las antiguas preguntas de sí o no por cada tamaño.
 */
const SIN_AGRUPACION: ValorEvidencia = {
	clave: 'ninguno',
	etiqueta: 'No se distinguen grupos regulares'
};

const OPCIONES_GRUPO_METRO: ValorEvidencia[] = [
	{ clave: 'arte_menor', etiqueta: 'Arte menor' },
	{ clave: 'arte_mayor', etiqueta: 'Arte mayor' },
	{ clave: 'mixto', etiqueta: 'Mixto' }
];

const OPCIONES_UNIFORMIDAD_METRO: ValorEvidencia[] = [
	{ clave: 'misma_medida', etiqueta: 'Sí, predomina una medida' },
	{ clave: 'varias_medidas', etiqueta: 'No, aparecen varias medidas' }
];

function evidenciaDe(hipotesis: HipotesisMetrica, dimension: string): EvidenciaNormativa | null {
	return hipotesis.evidencias.find((evidencia) => evidencia.dimension === dimension) ?? null;
}

function restoNormalizado(valor: number, modulo: number): number {
	return ((valor % modulo) + modulo) % modulo;
}

/** Los totales que las partes opcionales pueden añadir. Sin ellas, solo el cero. */
function desplazamientosDe(evidencia: EvidenciaNormativa): number[] {
	return evidencia.desplazamientos?.length ? evidencia.desplazamientos : [0];
}

function longitudValida(evidencia: EvidenciaNormativa, valor: number): boolean {
	if (evidencia.maximo !== null && valor > evidencia.maximo) return false;
	if (evidencia.modulo === null || evidencia.residuo === null) {
		return evidencia.minimo === null || valor >= evidencia.minimo;
	}
	// El mínimo se comprueba **dentro** de cada desplazamiento, no antes: una cadena de dos tercetos
	// y su remate mide siete versos, y lo que tiene que llegar al mínimo de seis es la cadena, no
	// el total.
	const modulo = evidencia.modulo;
	const residuo = evidencia.residuo;
	return desplazamientosDe(evidencia).some((desplazamiento) => {
		const resto = valor - desplazamiento;
		if (evidencia.minimo !== null && resto < evidencia.minimo) return false;
		return restoNormalizado(resto - residuo, modulo) === 0;
	});
}

function desviacionDeLongitud(
	evidencia: EvidenciaNormativa,
	observada: number
): DesviacionLongitud | null {
	if (evidencia.familiaCognitiva !== 'extension') return null;
	const minimo = evidencia.minimo ?? 1;
	const maximo = evidencia.maximo ?? Number.POSITIVE_INFINITY;
	const modulo = evidencia.modulo;
	const residuo = evidencia.residuo;

	// Con varios desplazamientos hay una longitud regular candidata por cada uno, y la que vale es
	// la más cercana: la anterior más alta y la siguiente más baja.
	const offsets = desplazamientosDe(evidencia);

	const limiteAnterior = Math.min(observada - 1, maximo);
	let regularAnterior: number | null = null;
	if (limiteAnterior >= minimo) {
		for (const desplazamiento of offsets) {
			const base = limiteAnterior - desplazamiento;
			const candidata =
				modulo !== null && residuo !== null
					? base - restoNormalizado(base - residuo, modulo) + desplazamiento
					: limiteAnterior;
			if (candidata < minimo || !longitudValida(evidencia, candidata)) continue;
			if (regularAnterior === null || candidata > regularAnterior) regularAnterior = candidata;
		}
	}

	const limiteSiguiente = Math.max(observada + 1, minimo);
	let regularSiguiente: number | null = null;
	if (limiteSiguiente <= maximo) {
		for (const desplazamiento of offsets) {
			const base = Math.max(limiteSiguiente - desplazamiento, minimo);
			const candidata =
				modulo !== null && residuo !== null
					? base + restoNormalizado(residuo - base, modulo) + desplazamiento
					: limiteSiguiente;
			if (candidata > maximo || !longitudValida(evidencia, candidata)) continue;
			if (regularSiguiente === null || candidata < regularSiguiente) regularSiguiente = candidata;
		}
	}

	const diferencias = [regularAnterior, regularSiguiente]
		.filter((valor): valor is number => valor !== null)
		.map((valor) => Math.abs(observada - valor));
	if (diferencias.length === 0) return null;
	return {
		observada,
		regularAnterior,
		regularSiguiente,
		diferenciaMinima: Math.min(...diferencias),
		regla: evidencia.reglaLongitud
	};
}

function interpretarLongitud(
	hipotesis: HipotesisMetrica,
	evidencia: EvidenciaNormativa,
	observada: number
): InterpretacionLongitud | null {
	if (evidencia.familiaCognitiva !== 'extension') return null;
	if (hipotesis.nivelEstructural === 'serie') {
		return {
			observada,
			tipo: 'serie',
			unidades: null,
			versosPorUnidad: null,
			regla: evidencia.reglaLongitud
		};
	}
	const unidad = hipotesis.unidadVersos;
	if (unidad !== null && observada % unidad === 0) {
		const unidades = observada / unidad;
		return {
			observada,
			tipo: unidades === 1 ? 'unidad' : 'repeticion',
			unidades,
			versosPorUnidad: unidad,
			regla: evidencia.reglaLongitud
		};
	}
	return {
		observada,
		tipo: 'pasaje',
		unidades: null,
		versosPorUnidad: null,
		regla: evidencia.reglaLongitud
	};
}

function coincide(evidencia: EvidenciaNormativa, valor: string | number): boolean {
	if (evidencia.tipo === 'numero') {
		if (typeof valor !== 'number') return false;
		return longitudValida(evidencia, valor);
	}
	return typeof valor === 'string' && evidencia.valores.some((item) => item.clave === valor);
}

export function puntuarHipotesis(
	hipotesis: HipotesisMetrica,
	respuestas: RespuestaDemarcador[]
): HipotesisPuntuada {
	// Un desempate, no una probabilidad previa: a favor de la arquitectura principal y en contra de
	// la que el catálogo llama excepcional, que no debe ganarle un empate a la regular. La endecha
	// real de cinco versos empataba con la lira en todo lo que se pregunta.
	let puntuacion =
		(hipotesis.arquitecturaPrincipal ? 0.05 : 0) -
		(hipotesis.arquitecturaModalidad === 'excepcional' ? 0.05 : 0);
	let coincidencias = 0;
	let contradicciones = 0;
	let interpretacionLongitud: InterpretacionLongitud | null = null;
	let desviacionLongitud: DesviacionLongitud | null = null;
	const detalles: HipotesisPuntuada['detalles'] = [];

	for (const respuesta of respuestas) {
		if (respuesta.valor === 'desconocido') continue;
		const evidencia = evidenciaDe(hipotesis, respuesta.dimension);
		if (!evidencia) {
			detalles.push({
				dimension: respuesta.dimension,
				etiqueta: respuesta.pregunta,
				estado: 'sin_datos',
				peso: 0
			});
			continue;
		}
		const pesos = PESO_MODALIDAD[evidencia.modalidad];
		const fiabilidad = FIABILIDAD[evidencia.observabilidad];
		if (coincide(evidencia, respuesta.valor) && evidencia.soloContradice) {
			detalles.push({
				dimension: respuesta.dimension,
				etiqueta: evidencia.etiqueta,
				estado: 'sin_datos',
				peso: 0
			});
			continue;
		}
		if (coincide(evidencia, respuesta.valor)) {
			const modalidadValor =
				typeof respuesta.valor === 'string'
					? evidencia.modalidadPorValor?.[respuesta.valor]
					: undefined;
			const peso =
				(modalidadValor ? PESO_MODALIDAD[modalidadValor].coincide : pesos.coincide) * fiabilidad;
			puntuacion += peso;
			coincidencias += 1;
			if (typeof respuesta.valor === 'number') {
				interpretacionLongitud = interpretarLongitud(hipotesis, evidencia, respuesta.valor);
			}
			detalles.push({
				dimension: respuesta.dimension,
				etiqueta: evidencia.etiqueta,
				estado: 'coincide',
				peso
			});
		} else {
			const peso = pesos.contradice * fiabilidad;
			puntuacion -= peso;
			contradicciones += 1;
			if (typeof respuesta.valor === 'number') {
				desviacionLongitud = desviacionDeLongitud(evidencia, respuesta.valor);
			}
			detalles.push({
				dimension: respuesta.dimension,
				etiqueta: evidencia.etiqueta,
				estado: 'contradice',
				peso: -peso
			});
		}
	}

	return {
		hipotesis,
		puntuacion: Math.round(puntuacion * 1000) / 1000,
		coincidencias,
		contradicciones,
		interpretacionLongitud,
		desviacionLongitud,
		detalles
	};
}

/**
 * El encaje de una arquitectura con lo respondido, sin mirar a las demás formas.
 *
 * La extensión no cuenta como contradicción de la norma sino como desviación: el demarcador ya
 * explica las longitudes regulares vecinas, y una laguna o un verso de más no hacen de un soneto
 * otra cosa.
 */
export function encajeDe(puntuada: HipotesisPuntuada): EncajeForma {
	const contradicciones = puntuada.detalles.filter((detalle) => detalle.estado === 'contradice');
	if (contradicciones.length === 0) return 'pleno';
	const rompeNorma = contradicciones.some((detalle) => {
		if (detalle.dimension === 'extension:versos') return false;
		return evidenciaDe(puntuada.hipotesis, detalle.dimension)?.modalidad === 'definitoria';
	});
	return rompeNorma ? 'contradice' : 'con_desviacion';
}

export function ordenarFormas(
	catalogo: CatalogoDemarcador,
	respuestas: RespuestaDemarcador[]
): FormaPuntuada[] {
	const porForma = new Map<string, HipotesisPuntuada[]>();
	for (const hipotesis of catalogo.hipotesis) {
		const puntuada = puntuarHipotesis(hipotesis, respuestas);
		porForma.set(hipotesis.formaId, [...(porForma.get(hipotesis.formaId) ?? []), puntuada]);
	}
	const formas = [...porForma.entries()]
		.map(([formaId, arquitecturas]) => {
			const ordenadas = [...arquitecturas].sort(
				(a, b) =>
					b.puntuacion - a.puntuacion ||
					a.hipotesis.arquitecturaNombre.localeCompare(b.hipotesis.arquitecturaNombre, 'es')
			);
			const mejor = ordenadas[0];
			return {
				formaId,
				formaSlug: mejor.hipotesis.formaSlug,
				formaNombre: mejor.hipotesis.formaNombre,
				formaDefinicion: mejor.hipotesis.formaDefinicion,
				puntuacion: mejor.puntuacion,
				nivel: 'posible' as FormaPuntuada['nivel'],
				encaje: encajeDe(mejor),
				arquitecturas: ordenadas
			};
		})
		.sort(
			(a, b) => b.puntuacion - a.puntuacion || a.formaNombre.localeCompare(b.formaNombre, 'es')
		);

	const maxima = formas[0]?.puntuacion ?? 0;
	const respuestasConcluyentes = respuestas.filter(
		(respuesta) => respuesta.valor !== 'desconocido'
	).length;
	const ventajaPrincipal =
		formas.length > 1 ? formas[0].puntuacion - formas[1].puntuacion : Number.POSITIVE_INFINITY;
	return formas.map((forma, index) => {
		const distancia = maxima - forma.puntuacion;
		const nivel: FormaPuntuada['nivel'] =
			respuestasConcluyentes < 3
				? 'candidata'
				: index === 0 && forma.arquitecturas[0].coincidencias >= 2 && ventajaPrincipal >= VENTAJA_SUFICIENTE
					? 'alto'
					: distancia < VENTAJA_SUFICIENTE
						? 'medio'
						: 'bajo';
		return { ...forma, nivel };
	});
}

function entropia(pesos: number[]): number {
	const total = pesos.reduce((suma, peso) => suma + peso, 0);
	if (total <= 0) return 0;
	return pesos.reduce((resultado, peso) => {
		if (peso <= 0) return resultado;
		const probabilidad = peso / total;
		return resultado - probabilidad * Math.log2(probabilidad);
	}, 0);
}

function clavePredicha(evidencia: EvidenciaNormativa): string {
	if (evidencia.tipo === 'numero') {
		return `${evidencia.minimo ?? ''}:${evidencia.maximo ?? ''}:${evidencia.modulo ?? ''}:${evidencia.residuo ?? ''}`;
	}
	return evidencia.valores
		.map((valor) => valor.clave)
		.sort()
		.join('|');
}

function preguntasPosibles(
	hipotesis: HipotesisMetrica[],
	respuestas: RespuestaDemarcador[],
	modo: ModoDemarcador,
	formaObjetivoId: string | null,
	/** Enunciado de cada dimensión: vive una vez en el catálogo, no en cada evidencia. */
	textos: Record<string, TextoDimension> = {},
	/**
	 * De dónde salen las **opciones**, si no es del mismo campo que decide la pregunta.
	 *
	 * La pregunta se elige por lo que separa a las que van en cabeza, pero lo que se ofrece para
	 * responder tiene que alcanzar a más: si la forma verdadera se ha quedado un momento detrás y su
	 * respuesta no está en la lista, ya no hay manera de devolverla arriba. Seis pareados con la
	 * sextilla y el terceto en cabeza preguntaban «¿en grupos de cuántos?» sin ofrecer «de 2 en 2».
	 */
	hipotesisOpciones: HipotesisMetrica[] = hipotesis,
	/** Si el campo son las pocas formas que empatan en cabeza. */
	desempate = false
): PreguntaDemarcador[] {
	const respondidas = new Set(respuestas.map((respuesta) => respuesta.dimension));
	const familiasDesconocidas = new Set(
		respuestas
			.filter((respuesta) => respuesta.valor === 'desconocido')
			.map((respuesta) => respuesta.familiaCognitiva)
	);
	const definiciones = new Map<string, EvidenciaNormativa[]>();
	const grupoMetroRespondido = respuestas.find(
		(respuesta) => respuesta.dimension === 'metro:grupo' && respuesta.valor !== 'desconocido'
	)?.valor;
	const uniformidadMetroRespondida = respuestas.find(
		(respuesta) => respuesta.dimension === 'metro:uniformidad' && respuesta.valor !== 'desconocido'
	)?.valor;
	const extensionRespondida = (() => {
		const valor = respuestas.find((respuesta) => respuesta.dimension === 'extension:versos')?.valor;
		return typeof valor === 'number' ? valor : null;
	})();
	const uniformidadMetroOmitida = respuestas.some(
		(respuesta) => respuesta.dimension === 'metro:uniformidad' && respuesta.valor === 'desconocido'
	);
	/**
	 * **Quien puede contestar la organización interna ya sabe la forma.**
	 *
	 * `estructura:orden` ofrece una etiqueta por arquitectura —«Primera quintilla + Segunda
	 * quintilla», «Cadena de tercetos + Serventesio final»—, así que sus opciones *son* la respuesta:
	 * nombran la unidad completa. Y como cada arquitectura aporta una etiqueta distinta, su
	 * separación es máxima y ganaba el primer puesto por delante del tipo de rima, que es lo que de
	 * verdad distingue un romance de una sextilla. La pregunta que nadie puede contestar desplazaba
	 * a la que resuelve.
	 *
	 * Se queda para el modo hipótesis, donde quien la usa ya trae una forma en la cabeza y confirmar
	 * su orden interno sí añade algo, **y para el desempate**: cuando solo quedan dos o tres formas
	 * en cabeza, sus opciones ya no nombran el catálogo sino esas pocas —«dos quintillas» o
	 * «redondilla, enlace y redondilla»—, y elegir entre ellas es mirar dónde se parte la estrofa. Sin
	 * eso, la décima y la copla real se quedaban empatadas hasta agotar el recorrido.
	 */
	const ordenInternoFueraDeLugar = (dimension: string) =>
		dimension === 'estructura:orden' && modo === 'guiado' && !desempate;

	/**
	 * Y en cualquier modo: si ya se ha dicho que **no hay secciones internas**, preguntar cuál se
	 * reconoce es una contradicción. Pasaba de verdad en un recorrido de romance.
	 */
	const sinSeccionesDeclaradas = respuestas.some(
		(respuesta) => respuesta.dimension === 'estructura:secciones' && respuesta.valor === 'no'
	);
	const evidenciaParaPregunta = (
		candidata: HipotesisMetrica,
		dimension: string
	): EvidenciaNormativa | null => {
		const evidencia = evidenciaDe(candidata, dimension);
		if (!evidencia || dimension !== 'metro:exacto') return evidencia;
		const buscaVarias =
			typeof uniformidadMetroRespondida === 'string'
				? uniformidadMetroRespondida === 'varias_medidas'
				: null;
		/**
		 * **Las medidas se filtran por el arte respondido, no solo las formas.** Filtrar las formas
		 * bastaba mientras cada una era de un solo arte. El pareado isométrico admite las dos —del
		 * tetrasílabo al alejandrino—, así que entra con «arte mayor» y traía consigo el 4, el 5, el 6,
		 * el 7 y el 8.
		 */
		const encajaConElArte = (clave: string) => {
			if (typeof grupoMetroRespondido !== 'string') return true;
			const medidas = clave.split('+').map(Number);
			const menor = medidas.some((medida) => medida <= 8);
			const mayor = medidas.some((medida) => medida > 8);
			if (grupoMetroRespondido === 'arte_menor') return menor && !mayor;
			if (grupoMetroRespondido === 'arte_mayor') return mayor && !menor;
			return menor && mayor;
		};
		const valores = evidencia.valores.filter(
			(valor) =>
				(buscaVarias === null || valor.clave.includes('+') === buscaVarias) &&
				encajaConElArte(valor.clave)
		);
		if (valores.length === evidencia.valores.length) return evidencia;
		return valores.length > 0 ? { ...evidencia, valores } : null;
	};
	for (const candidata of hipotesis) {
		for (const evidencia of candidata.evidencias) {
			if (evidencia.observabilidad === 'derivada' || respondidas.has(evidencia.dimension)) continue;
			definiciones.set(evidencia.dimension, [
				...(definiciones.get(evidencia.dimension) ?? []),
				evidencia
			]);
		}
	}

	/**
	 * Lo que predice la hipótesis en cada dimensión, resuelto una vez.
	 *
	 * Cuando declara varias arquitecturas se toma la primera que cubre la dimensión: basta con que
	 * una realización encaje para que la forma se sostenga, y por eso no se puede exigir que todas
	 * predigan lo mismo.
	 */
	const clavesDelObjetivo = (() => {
		if (modo !== 'hipotesis' || !formaObjetivoId) return null;
		const suyas = hipotesis.filter((candidata) => candidata.formaId === formaObjetivoId);
		if (suyas.length === 0) return null;
		const claves = new Map<string, string>();
		for (const candidata of suyas) {
			for (const evidencia of candidata.evidencias) {
				if (!claves.has(evidencia.dimension)) claves.set(evidencia.dimension, clavePredicha(evidencia));
			}
		}
		return claves;
	})();

	const resultado: PreguntaDemarcador[] = [];
	for (const [dimension] of definiciones) {
		if (dimension === 'metro:exacto' && uniformidadMetroOmitida) continue;
		if (dimension === 'estructura:orden' && (ordenInternoFueraDeLugar(dimension) || sinSeccionesDeclaradas))
			continue;
		const admiteCandidata = (candidata: HipotesisMetrica) => {
			const dependeDelGrupo = dimension === 'metro:uniformidad' || dimension === 'metro:exacto';
			if (!dependeDelGrupo) return true;
			if (
				typeof grupoMetroRespondido === 'string' &&
				!evidenciaDe(candidata, 'metro:grupo')?.valores.some(
					(valor) => valor.clave === grupoMetroRespondido
				)
			) {
				return false;
			}
			if (dimension !== 'metro:exacto') return true;
			if (
				typeof uniformidadMetroRespondida === 'string' &&
				!evidenciaDe(candidata, 'metro:uniformidad')?.valores.some(
					(valor) => valor.clave === uniformidadMetroRespondida
				)
			) {
				return false;
			}
			return evidenciaParaPregunta(candidata, dimension) !== null;
		};
		const candidatasDimension = hipotesis.filter(admiteCandidata);
		const evidenciasDimension = candidatasDimension
			.map((candidata) => evidenciaParaPregunta(candidata, dimension))
			.filter((evidencia): evidencia is EvidenciaNormativa => evidencia !== null);
		if (evidenciasDimension.length === 0) continue;
		const evidenciasAmplias =
			hipotesisOpciones === hipotesis
				? evidenciasDimension
				: [...new Set([...hipotesis, ...hipotesisOpciones])]
						.filter(admiteCandidata)
						.map((candidata) => evidenciaParaPregunta(candidata, dimension))
						.filter((evidencia): evidencia is EvidenciaNormativa => evidencia !== null);
		// Si abrirlas las hace ilegibles —más de las que caben—, se ofrecen las del campo que decide:
		// vale más una lista corta que ninguna pregunta.
		const clavesAmplias = new Set(
			evidenciasAmplias.flatMap((evidencia) => evidencia.valores.map((valor) => valor.clave))
		);
		const evidenciasOpciones =
			dimension === 'estructura:orden' ||
			(dimension !== 'metro:exacto' &&
			dimension !== 'estructura:agrupacion' &&
				clavesAmplias.size > MAX_OPCIONES)
				? evidenciasDimension
				: evidenciasAmplias;
		const modelo = [...evidenciasDimension].sort((a, b) => a.orden - b.orden)[0];
		const grupos = new Map<string, number>();
		const arquitecturasPorForma = new Map<string, number>();
		for (const candidata of candidatasDimension) {
			arquitecturasPorForma.set(
				candidata.formaId,
				(arquitecturasPorForma.get(candidata.formaId) ?? 0) + 1
			);
		}
		let cobertura = 0;
		for (const candidata of candidatasDimension) {
			const pesoForma = 1 / (arquitecturasPorForma.get(candidata.formaId) ?? 1);
			const evidencia = evidenciaParaPregunta(candidata, dimension);
			if (!evidencia) {
				grupos.set('__sin_datos__', (grupos.get('__sin_datos__') ?? 0) + pesoForma);
				continue;
			}
			cobertura += pesoForma;
			const clave = clavePredicha(evidencia);
			grupos.set(clave, (grupos.get(clave) ?? 0) + pesoForma);
		}
		if (grupos.size < 2) continue;

		const opcionesPorClave = new Map<string, ValorEvidencia>();
		for (const evidencia of evidenciasOpciones) {
			for (const valor of evidencia.valores) opcionesPorClave.set(valor.clave, valor);
		}
		const opciones =
			dimension === 'metro:grupo'
				? OPCIONES_GRUPO_METRO
				: dimension === 'metro:uniformidad'
					? OPCIONES_UNIFORMIDAD_METRO
					: dimension === 'estructura:agrupacion'
						? [
								// Un grupo más largo que el pasaje no se puede ver en él.
								...[...opcionesPorClave.values()]
									.filter((valor) => extensionRespondida === null || Number(valor.clave) <= extensionRespondida)
									.sort((a, b) => Number(a.clave) - Number(b.clave)),
								SIN_AGRUPACION
							]
						: modelo.tipo === 'booleano'
							? [
									{ clave: 'si', etiqueta: 'Sí' },
									{ clave: 'no', etiqueta: 'No' }
								]
							: [...opcionesPorClave.values()];
		const maximoOpciones =
			dimension === 'metro:exacto'
				? MAX_OPCIONES_METRO_EXACTO
				: dimension === 'estructura:agrupacion'
					? MAX_OPCIONES_AGRUPACION + 1
					: MAX_OPCIONES;
		if (modelo.tipo !== 'numero' && (opciones.length < 2 || opciones.length > maximoOpciones))
			continue;

		/**
		 * **Separar el catálogo y separar dos formas no son lo mismo.**
		 *
		 * La entropía mide reparto de población: premia la pregunta que parte las candidatas por la
		 * mitad. Eso es lo que hace falta para identificar, y es inútil para comprobar: una pregunta
		 * que parte el catálogo pero en la que la hipótesis y su rival responden igual no decide
		 * nada, y era justo la que salía primera.
		 *
		 * Al comprobar se mide **cuánta masa rival queda al otro lado de la hipótesis**: la
		 * proporción de candidatas que predicen algo distinto de lo que predice ella. Uno es la
		 * pregunta que la separa de todas; cero, la que no la separa de ninguna.
		 *
		 * Si la hipótesis no declara esta dimensión no hay nada que contrastar y se cae a la
		 * entropía, que al menos ordena el resto.
		 */
		const clavePropia = clavesDelObjetivo?.get(dimension) ?? null;
		const separacion =
			clavePropia === null
				? entropia([...grupos.values()])
				: (() => {
						let contraria = 0;
						let total = 0;
						for (const [clave, peso] of grupos) {
							if (clave === '__sin_datos__') continue;
							total += peso;
							if (clave !== clavePropia) contraria += peso;
						}
						return total > 0 ? contraria / total : 0;
					})();
		const proporcionCobertura = cobertura / Math.max(1, arquitecturasPorForma.size);
		const respondibilidad = FIABILIDAD[modelo.observabilidad];
		const penalizacionDesconocida = familiasDesconocidas.has(modelo.familiaCognitiva) ? 0.22 : 1;
		const penalizacionRepeticion =
			respuestas.at(-1)?.familiaCognitiva === modelo.familiaCognitiva ? 0.45 : 1;
		// El impulso del 1,35 a las definitorias de la hipótesis se retira: premiaba lo que la
		// *define* y no lo que la *distingue* —el endecasílabo es definitorio del soneto y de otras
		// cuatro formas—, y la discriminación ya lo recoge donde de verdad importa. Además se lo
		// comía cualquier entropía alta, que es la razón de que este recorrido no se distinguiera
		// del guiado.
		const impulsoObjetivo = 1;
		const utilidad =
			separacion *
			proporcionCobertura *
			respondibilidad *
			(1 - modelo.coste) *
			penalizacionDesconocida *
			penalizacionRepeticion *
			impulsoObjetivo;
		resultado.push({
			id: `pregunta:${dimension}`,
			dimension,
			familiaCognitiva: modelo.familiaCognitiva,
			pregunta:
				dimension === 'metro:exacto' &&
				(uniformidadMetroRespondida === 'varias_medidas' || grupoMetroRespondido === 'mixto')
					? '¿Qué medidas aparecen en el pasaje?'
					: dimension === 'metro:exacto'
						? '¿Cuántas sílabas tiene normalmente cada verso?'
						: (textos[dimension]?.pregunta ?? dimension),
			ayuda:
				dimension === 'metro:exacto' &&
				(uniformidadMetroRespondida === 'varias_medidas' || grupoMetroRespondido === 'mixto')
					? 'Elige las medidas que has contado; no necesitas decidir por qué se combinan ni qué nombre recibe esa combinación.'
					: (textos[dimension]?.ayuda ?? ''),
			tipo: modelo.tipo,
			opciones:
				dimension === 'metro:grupo' ||
				dimension === 'metro:uniformidad' ||
				dimension === 'estructura:agrupacion'
					? opciones
					: opciones.sort((a, b) => a.etiqueta.localeCompare(b.etiqueta, 'es', { numeric: true })),
			observabilidad: modelo.observabilidad,
			coste: modelo.coste,
			utilidad: Math.round(utilidad * 10000) / 10000
		});
	}
	return resultado.sort(
		(a, b) => b.utilidad - a.utilidad || a.pregunta.localeCompare(b.pregunta, 'es')
	);
}

/**
 * **Contra quién hay que contrastar una hipótesis.**
 *
 * Comprobar una forma no es clasificar un pasaje entre trescientas: es decidir entre esa forma y
 * las pocas con las que se confunde. Mientras las preguntas se calculaban sobre las doce mejores
 * del catálogo entero, el recorrido de comprobación era el guiado con otro nombre, porque la forma
 * propuesta no entraba en el cálculo por ningún sitio.
 *
 * Los rivales salen de tres fuentes que se suman, y ninguna basta sola:
 *
 * 1. **Los declarados.** `forma_relaciones` tiene escrito el mapa de confusiones del proyecto
 *    —«septeto y septeto-lira se separan por la medida»—, y eso vale desde la primera pregunta,
 *    cuando todavía no hay respuestas que ordenen nada.
 * 2. **Los que van bien ahora.** Lo que las respuestas hayan puesto arriba, aunque nadie lo
 *    hubiera declarado pariente: una confusión real no siempre está prevista.
 * 3. **Los estructuralmente próximos**, medidos sobre el propio catálogo: las formas que predicen
 *    lo mismo que la hipótesis en más dimensiones. Cubre los huecos del mapa declarado, que
 *    alcanza a 30 de las 43 formas activas.
 *
 * La hipótesis **siempre entra**, aunque las respuestas la hayan hundido. Antes, si caía del
 * puesto doce, el recorrido dejaba de tratar sobre ella en silencio: abandonaba la hipótesis justo
 * cuando estaba en apuros, que es cuando hay que ponerla a prueba.
 */
const RIVALES_MAXIMOS = 6;

/** Cuántas dimensiones predicen lo mismo dos hipótesis, sobre las que ambas declaran. */
function afinidadEstructural(a: HipotesisMetrica, b: HipotesisMetrica): number {
	let comunes = 0;
	let acuerdos = 0;
	for (const evidencia of a.evidencias) {
		const otra = evidenciaDe(b, evidencia.dimension);
		if (!otra) continue;
		comunes += 1;
		if (evidencia.tipo === 'numero') {
			if (clavePredicha(evidencia) === clavePredicha(otra)) acuerdos += 1;
			continue;
		}
		const clavesA = new Set(evidencia.valores.map((valor) => valor.clave));
		if (otra.valores.some((valor) => clavesA.has(valor.clave))) acuerdos += 1;
	}
	return comunes > 0 ? acuerdos / comunes : 0;
}

export function rivalesDe(
	catalogo: CatalogoDemarcador,
	formaObjetivoId: string,
	respuestas: RespuestaDemarcador[]
): Set<string> {
	const rivales = new Set<string>([formaObjetivoId]);

	let declarados = 0;
	for (const relacion of catalogo.relaciones) {
		if (relacion.origenId === formaObjetivoId) {
			rivales.add(relacion.destinoId);
			declarados += 1;
		} else if (relacion.destinoId === formaObjetivoId) {
			rivales.add(relacion.origenId);
			declarados += 1;
		}
	}

	const ordenadas = ordenarFormas(catalogo, respuestas);
	if (respuestas.length > 0) {
		for (const forma of ordenadas.slice(0, 4)) rivales.add(forma.formaId);
	}

	// **La afinidad estructural es el suplente, no un titular.** Solo entra cuando el catálogo no
	// declara ningún contraste para esta forma —trece de las cuarenta y tres—, porque si no, ensancha
	// el campo con parientes lejanos y devuelve el recorrido a donde estaba: comparando contra medio
	// catálogo en vez de contra quien de verdad se confunde.
	if (declarados === 0) {
		const objetivo = catalogo.hipotesis.filter((item) => item.formaId === formaObjetivoId);
		if (objetivo.length > 0) {
			const afinidadPorForma = new Map<string, number>();
			for (const candidata of catalogo.hipotesis) {
				if (rivales.has(candidata.formaId)) continue;
				const afinidad = Math.max(
					...objetivo.map((propia) => afinidadEstructural(propia, candidata))
				);
				afinidadPorForma.set(
					candidata.formaId,
					Math.max(afinidadPorForma.get(candidata.formaId) ?? 0, afinidad)
				);
			}
			const proximas = [...afinidadPorForma.entries()]
				.filter(([, afinidad]) => afinidad >= 0.6)
				.sort((a, b) => b[1] - a[1])
				.slice(0, RIVALES_MAXIMOS - rivales.size + 1);
			for (const [formaId] of proximas) rivales.add(formaId);
		}
	}

	return rivales;
}

/**
 * **Dónde discrepan dos normas**, que es lo único capaz de separarlas.
 *
 * Para una dimensión categórica hay discrepancia cuando los conjuntos de valores previstos no se
 * tocan: si el soneto predice «consonante» y el rival también, preguntar la rima no decide nada por
 * mucho que sea definitoria de las dos. Para la extensión se comparan las congruencias, que es lo
 * que `clavePredicha` resume.
 *
 * **Y cuando solo una de las dos declara la dimensión, también la hay.** La sextina se agrupa de seis
 * en seis y el endecasílabo suelto no dice nada de grupos: «no se distinguen grupos regulares»
 * contradice a una y deja intacta a la otra, así que las separa. Contando solo lo que declaraban las
 * dos, el contraste se daba por indecidible con esa pregunta sin hacer.
 *
 * Se devuelven también las **no observables** y las **ya respondidas**, porque sirven para explicar:
 * «lo que las separaría es X, y X no se puede ver en este pasaje» es un resultado, no un silencio.
 */
export function discrepanciasEntre(
	a: HipotesisMetrica,
	b: HipotesisMetrica,
	respondidas: Set<string>
): Discrepancia[] {
	const discrepancias: Discrepancia[] = [];
	const soloDeUna = (evidencia: EvidenciaNormativa) =>
		discrepancias.push({
			dimension: evidencia.dimension,
			etiqueta: evidencia.etiqueta,
			familiaCognitiva: evidencia.familiaCognitiva,
			observable: evidencia.observabilidad !== 'derivada',
			respondida: respondidas.has(evidencia.dimension)
		});
	for (const evidencia of b.evidencias) {
		if (!evidenciaDe(a, evidencia.dimension)) soloDeUna(evidencia);
	}
	for (const evidencia of a.evidencias) {
		const otra = evidenciaDe(b, evidencia.dimension);
		if (!otra) {
			soloDeUna(evidencia);
			continue;
		}
		const separa =
			evidencia.tipo === 'numero' || otra.tipo === 'numero'
				? clavePredicha(evidencia) !== clavePredicha(otra)
				: !evidencia.valores.some((valor) =>
						otra.valores.some((suyo) => suyo.clave === valor.clave)
					);
		if (!separa) continue;
		discrepancias.push({
			dimension: evidencia.dimension,
			etiqueta: evidencia.etiqueta,
			familiaCognitiva: evidencia.familiaCognitiva,
			observable:
				evidencia.observabilidad !== 'derivada' && otra.observabilidad !== 'derivada',
			respondida: respondidas.has(evidencia.dimension)
		});
	}
	return discrepancias;
}

/**
 * En qué queda la hipótesis: se sostiene, se cae, o no hay manera de decidirlo mirando el pasaje.
 *
 * **Refutada** exige que *todas* sus arquitecturas contradigan algo que su norma fija, porque una
 * forma se sostiene si alguna de sus realizaciones encaja —es la misma regla que
 * `S(forma) = max S(arquitectura)`—.
 *
 * **Indecidible** es el final que faltaba: la hipótesis y su rival empatan y no queda ninguna
 * discrepancia observable que preguntar. Decirlo vale más que seguir pidiendo precisiones que no
 * van a decidir nada.
 */
export function veredictoDeHipotesis(
	catalogo: CatalogoDemarcador,
	formaObjetivoId: string,
	respuestas: RespuestaDemarcador[]
): VeredictoHipotesis {
	const ordenadas = ordenarFormas(catalogo, respuestas);
	const objetivo = ordenadas.find((forma) => forma.formaId === formaObjetivoId) ?? null;
	// **El rival se busca dentro del contraste, no en la cabeza del catálogo.** El veredicto tiene
	// que hablar de las mismas formas contra las que se está preguntando; si no, con cero respuestas
	// nombraría a la primera por orden alfabético, que no es rival de nada.
	const enContraste = rivalesDe(catalogo, formaObjetivoId, respuestas);
	const rival =
		ordenadas.find(
			(forma) => forma.formaId !== formaObjetivoId && enContraste.has(forma.formaId)
		) ??
		ordenadas.find((forma) => forma.formaId !== formaObjetivoId) ??
		null;
	const respondidas = new Set(
		respuestas.filter((respuesta) => respuesta.valor !== 'desconocido').map((r) => r.dimension)
	);
	const nota =
		catalogo.relaciones.find(
			(relacion) =>
				rival !== null &&
				((relacion.origenId === formaObjetivoId && relacion.destinoId === rival.formaId) ||
					(relacion.destinoId === formaObjetivoId && relacion.origenId === rival.formaId))
		)?.nota ?? null;

	const base = { rival, nota, pendientes: [] as Discrepancia[], contradiceDefinitorias: [] as DetalleCompatibilidad[] };
	if (!objetivo) return { ...base, estado: 'en_curso' };

	const definitoriasRotas = (puntuada: (typeof objetivo)['arquitecturas'][number]) =>
		puntuada.detalles.filter((detalle) => {
			if (detalle.estado !== 'contradice') return false;
			const evidencia = evidenciaDe(puntuada.hipotesis, detalle.dimension);
			return evidencia?.modalidad === 'definitoria';
		});
	const rotasPorArquitectura = objetivo.arquitecturas.map(definitoriasRotas);
	if (rotasPorArquitectura.length > 0 && rotasPorArquitectura.every((rotas) => rotas.length > 0)) {
		return { ...base, estado: 'refutada', contradiceDefinitorias: rotasPorArquitectura[0] };
	}

	if (!rival) return { ...base, estado: 'en_curso' };

	const pendientes = discrepanciasEntre(
		objetivo.arquitecturas[0].hipotesis,
		rival.arquitecturas[0].hipotesis,
		respondidas
	).filter((discrepancia) => discrepancia.observable && !discrepancia.respondida);

	const concluyentes = respuestas.filter((respuesta) => respuesta.valor !== 'desconocido').length;
	const ventaja = objetivo.puntuacion - rival.puntuacion;

	/**
	 * **Las discrepancias pendientes deciden los empates, no bloquean las victorias.**
	 *
	 * Exigir que no quedara ninguna para dar por sostenida una hipótesis dejaba el recorrido sin
	 * final: dos formas casi siempre difieren en varias dimensiones —soneto y septeto, en media
	 * docena—, y no hace falta preguntarlas todas cuando una ya va claramente delante. Lo que sí
	 * necesita agotarlas es el empate: decir «no se pueden distinguir» solo es honesto cuando no
	 * queda ninguna pregunta que las separase.
	 */
	if (concluyentes >= 3 && ventaja >= VENTAJA_SUFICIENTE) return { ...base, pendientes, estado: 'sostenida' };
	/**
	 * **Y cuando ya no queda nada que las separe, gana la que va delante.** Si lo único que distinguía
	 * a la octava real de la aguda —cómo se distribuye la rima— cae del lado de la hipótesis, llamarlo
	 * «indecidible» porque la ventaja no llega a la de un recorrido abierto es negar lo que se acaba de
	 * responder: se ha decidido, por poco. Indecidible es el empate de verdad.
	 */
	if (concluyentes >= 3 && pendientes.length === 0) {
		return {
			...base,
			pendientes,
			estado: ventaja > MARGEN_EMPATE ? 'sostenida' : 'indecidible'
		};
	}
	return { ...base, pendientes, estado: 'en_curso' };
}

export function elegirPregunta(
	catalogo: CatalogoDemarcador,
	respuestas: RespuestaDemarcador[],
	modo: ModoDemarcador,
	formaObjetivoId: string | null = null
): PreguntaDemarcador | null {
	const formasOrdenadas = ordenarFormas(catalogo, respuestas);

	// **Comprobar restringe el campo; identificar lo abre.** Con una hipótesis sobre la mesa, las
	// preguntas se calculan entre ella y sus rivales, y no entre las doce mejores del catálogo. El
	// efecto llega más lejos que el orden: las opciones de cada pregunta se juntan de las candidatas
	// que la declaran, así que estrechar el campo estrecha también las respuestas ofrecidas —«¿qué
	// organización interna reconoces?» deja de listar siete organizaciones de formas ajenas.
	/**
	 * **Cuando varias van en cabeza, se pregunta por lo que las separa a ellas.**
	 *
	 * Las doce primeras seguían mandando aunque solo dos estuvieran empatadas arriba, y entonces la
	 * pregunta la elegían las diez de detrás: una décima empatada con la copla real se iba a «¿grupos
	 * sucesivos de tres versos y un serventesio?», que es del terceto encadenado, y el recorrido se
	 * agotaba sin separarlas. Peor aún, la pregunta que las separa —cómo se distribuye la rima— no
	 * llegaba a hacerse, porque con doce formas juntaba más opciones de las que caben en pantalla.
	 *
	 * Van en cabeza las que están a menos de la ventaja que el recorrido exige para detenerse. Si
	 * solo hay una, el campo sigue siendo el de las doce: lo que falta entonces es confirmar que
	 * aventaja a las demás, no desempatar.
	 */
	const enCabeza =
		respuestas.length === 0 || formasOrdenadas.length === 0
			? []
			: formasOrdenadas.filter(
					(forma) => formasOrdenadas[0].puntuacion - forma.puntuacion < VENTAJA_SUFICIENTE
				);
	const hipotesisDe = (formas: FormaPuntuada[]) =>
		formas.flatMap((forma) => forma.arquitecturas.map((item) => item.hipotesis));
	const campoAmplio =
		respuestas.length === 0 ? catalogo.hipotesis : hipotesisDe(formasOrdenadas.slice(0, 12));
	const campoAbierto =
		enCabeza.length >= 2 && enCabeza.length <= 12 ? hipotesisDe(enCabeza) : campoAmplio;
	const desempate = enCabeza.length >= 2 && enCabeza.length <= 3;
	/**
	 * **Una hipótesis refutada deja de gobernar el recorrido.**
	 *
	 * Si el pasaje ya contradice algo que la norma de la forma propuesta fija, seguir preguntando
	 * por lo que la separa de sus rivales es perseguir a un muerto: la pregunta ha vuelto a ser
	 * «¿cuál es, entonces?», que es clasificación abierta. Se pasa al campo y al criterio del
	 * recorrido guiado, sin decírselo al motor dos veces.
	 */
	const veredicto =
		modo === 'hipotesis' && formaObjetivoId
			? veredictoDeHipotesis(catalogo, formaObjetivoId, respuestas)
			: null;
	const refutada = veredicto?.estado === 'refutada';
	const modoEfectivo: ModoDemarcador = refutada ? 'guiado' : modo;
	const objetivoEfectivo = refutada ? null : formaObjetivoId;

	const rivales =
		modoEfectivo === 'hipotesis' && objetivoEfectivo
			? rivalesDe(catalogo, objetivoEfectivo, respuestas)
			: null;
	const candidatas =
		rivales && rivales.size > 1
			? catalogo.hipotesis.filter((item) => rivales.has(item.formaId))
			: campoAbierto;

	// **Si el campo estrecho no da preguntas, se abre.** Una forma puede quedarse sin rivales —trece
	// de las cuarenta y tres no tienen ninguna relación declarada, y la afinidad estructural puede no
	// alcanzar a ninguna—, y entonces no hay nada que separar y el recorrido se quedaría mudo. Vale
	// más una pregunta general que ninguna.
	let preguntas = preguntasPosibles(
		candidatas,
		respuestas,
		modoEfectivo,
		objetivoEfectivo,
		catalogo.textos ?? {},
		candidatas === campoAbierto ? campoAmplio : candidatas,
		candidatas === campoAbierto && desempate
	);
	if (preguntas.length === 0 && candidatas !== campoAbierto) {
		preguntas = preguntasPosibles(
			campoAbierto,
			respuestas,
			modoEfectivo,
			objetivoEfectivo,
			catalogo.textos,
			campoAmplio,
			desempate
		);
	}
	// Y lo mismo con las que van en cabeza: si nada las separa, se pregunta por lo que las separa
	// de las de detrás, que es lo que queda por confirmar.
	if (preguntas.length === 0 && campoAbierto !== campoAmplio) {
		preguntas = preguntasPosibles(
			campoAmplio,
			respuestas,
			modoEfectivo,
			objetivoEfectivo,
			catalogo.textos
		);
	}
	/**
	 * **En el desempate de un contraste, se pregunta lo que falta.**
	 *
	 * El veredicto sabe qué discrepancia queda entre la hipótesis y su rival —entre la octava real y
	 * la aguda, cómo se distribuye la rima—, pero la pregunta no llegaba a hacerse: calculada contra
	 * todos los rivales juntaba más esquemas de los que caben y se descartaba, y el recorrido gastaba
	 * las preguntas que le quedaban en rasgos que no separaban a nadie. Con tres respuestas
	 * concluyentes, que es cuando el veredicto empieza a poder decidir, se pregunta la discrepancia
	 * pendiente con las opciones de las dos formas en juego.
	 */
	if (
		modoEfectivo === 'hipotesis' &&
		objetivoEfectivo &&
		veredicto?.estado === 'en_curso' &&
		veredicto.rival &&
		veredicto.pendientes.length > 0 &&
		respuestas.filter((respuesta) => respuesta.valor !== 'desconocido').length >= 3
	) {
		const faltan = new Set(veredicto.pendientes.map((discrepancia) => discrepancia.dimension));
		const rivalId = veredicto.rival.formaId;
		const pendiente =
			preguntas.find((pregunta) => faltan.has(pregunta.dimension)) ??
			preguntasPosibles(
				catalogo.hipotesis.filter(
					(item) => item.formaId === objetivoEfectivo || item.formaId === rivalId
				),
				respuestas,
				modoEfectivo,
				objetivoEfectivo,
				catalogo.textos ?? {}
			).find((pregunta) => faltan.has(pregunta.dimension));
		if (pendiente) return pendiente;
	}
	if (respuestas.length === 0 && modoEfectivo === 'guiado') {
		return (
			preguntas.find((pregunta) => pregunta.dimension === 'metro:grupo') ?? preguntas[0] ?? null
		);
	}
	const grupoMetroRespondido = respuestas.some(
		(respuesta) => respuesta.dimension === 'metro:grupo' && respuesta.valor !== 'desconocido'
	);
	if (grupoMetroRespondido) {
		const uniformidadRespondida = respuestas.find(
			(respuesta) => respuesta.dimension === 'metro:uniformidad'
		);
		if (!uniformidadRespondida) {
			const uniformidad = preguntas.find((pregunta) => pregunta.dimension === 'metro:uniformidad');
			if (uniformidad) return uniformidad;
			const medidaExacta = preguntas.find((pregunta) => pregunta.dimension === 'metro:exacto');
			if (medidaExacta) return medidaExacta;
		}

		/**
		 * **Y en tercer lugar, la rima**, con la misma regla cableada que ya ordena el metro y por el
		 * mismo motivo: es definitoria y la utilidad no la colocaba donde toca.
		 *
		 * Medida y rima son las dos cosas que cualquiera ve en un pasaje, y juntas separan casi todo
		 * el catálogo. Dejada al cálculo quedaba la última —detrás de «cuántas sílabas» y «pie
		 * quebrado», que la superan en separación aunque confirmen decenas de formas a la vez—, así
		 * que un romance costaba siete preguntas cuando la rima lo resuelve en una: es lo único que lo
		 * distingue de una sextilla octosílaba.
		 */
		const rimaRespondida = respuestas.some((respuesta) => respuesta.dimension === 'rima:tipo');
		if (!rimaRespondida) {
			const rima = preguntas.find((pregunta) => pregunta.dimension === 'rima:tipo');
			if (rima) return rima;
		}
	}
	return preguntas[0] ?? null;
}

export function crearRespuesta(
	pregunta: PreguntaDemarcador,
	valor: string | number | 'desconocido',
	etiqueta: string
): RespuestaDemarcador {
	return {
		preguntaId: pregunta.id,
		dimension: pregunta.dimension,
		familiaCognitiva: pregunta.familiaCognitiva,
		pregunta: pregunta.pregunta,
		valor,
		etiqueta
	};
}

/**
 * La posición frente a las demás, dicha como probabilidad relativa.
 *
 * No es un porcentaje: el demarcador ordena por compatibilidad y dice si la primera destaca, si
 * comparte cabeza o si va por detrás. Lo que antes se llamaba «encaje alto, medio o bajo» es esto;
 * el encaje de verdad, el de la forma con su propia norma, lo dice `etiquetaEncaje`.
 */
export function etiquetaNivel(nivel: FormaPuntuada['nivel']): string {
	if (nivel === 'candidata') return 'Candidata';
	if (nivel === 'alto') return 'La más probable';
	if (nivel === 'medio') return 'Empatada en cabeza';
	return 'Menos probable';
}

export function etiquetaEncaje(encaje: EncajeForma): string {
	if (encaje === 'pleno') return 'Encaja';
	if (encaje === 'con_desviacion') return 'Encaja con desviación';
	return 'No encaja';
}

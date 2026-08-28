import type {
	CatalogoDemarcador,
	DesviacionLongitud,
	EvidenciaNormativa,
	FormaPuntuada,
	HipotesisMetrica,
	HipotesisPuntuada,
	InterpretacionLongitud,
	ModoDemarcador,
	ModalidadEvidencia,
	ObservabilidadEvidencia,
	PreguntaDemarcador,
	RespuestaDemarcador,
	ValorEvidencia
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

const MAX_OPCIONES = 7;
const MAX_OPCIONES_METRO_EXACTO = 12;

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
	// El mínimo se comprueba **dentro** de cada desplazamiento, no antes: una cadena de un solo
	// terceto y su serventesio mide siete versos, y lo que tiene que llegar al mínimo de tres es
	// el ciclo, no el total.
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
	let puntuacion = hipotesis.arquitecturaPrincipal ? 0.05 : 0;
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
		if (coincide(evidencia, respuesta.valor)) {
			const peso = pesos.coincide * fiabilidad;
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
				arquitecturas: ordenadas
			};
		})
		.sort(
			(a, b) => b.puntuacion - a.puntuacion || a.formaNombre.localeCompare(b.formaNombre, 'es')
		);

	const maxima = formas[0]?.puntuacion ?? 0;
	return formas.map((forma, index) => {
		const distancia = maxima - forma.puntuacion;
		const nivel: FormaPuntuada['nivel'] =
			index === 0 && forma.arquitecturas[0].coincidencias >= 2 && distancia === 0
				? 'muy_compatible'
				: distancia <= 0.45
					? 'compatible'
					: distancia <= 1.25
						? 'posible'
						: 'poco_compatible';
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
	formaObjetivoId: string | null
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
	const uniformidadMetroOmitida = respuestas.some(
		(respuesta) => respuesta.dimension === 'metro:uniformidad' && respuesta.valor === 'desconocido'
	);
	const evidenciaParaPregunta = (
		candidata: HipotesisMetrica,
		dimension: string
	): EvidenciaNormativa | null => {
		const evidencia = evidenciaDe(candidata, dimension);
		if (
			!evidencia ||
			dimension !== 'metro:exacto' ||
			typeof uniformidadMetroRespondida !== 'string'
		) {
			return evidencia;
		}
		const buscaVarias = uniformidadMetroRespondida === 'varias_medidas';
		const valores = evidencia.valores.filter((valor) => valor.clave.includes('+') === buscaVarias);
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

	const resultado: PreguntaDemarcador[] = [];
	for (const [dimension] of definiciones) {
		if (dimension === 'metro:exacto' && uniformidadMetroOmitida) continue;
		const candidatasDimension = hipotesis.filter((candidata) => {
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
		});
		const evidenciasDimension = candidatasDimension
			.map((candidata) => evidenciaParaPregunta(candidata, dimension))
			.filter((evidencia): evidencia is EvidenciaNormativa => evidencia !== null);
		if (evidenciasDimension.length === 0) continue;
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
		for (const evidencia of evidenciasDimension) {
			for (const valor of evidencia.valores) opcionesPorClave.set(valor.clave, valor);
		}
		const opciones =
			dimension === 'metro:grupo'
				? OPCIONES_GRUPO_METRO
				: dimension === 'metro:uniformidad'
					? OPCIONES_UNIFORMIDAD_METRO
					: modelo.tipo === 'booleano'
						? [
								{ clave: 'si', etiqueta: 'Sí' },
								{ clave: 'no', etiqueta: 'No' }
							]
						: [...opcionesPorClave.values()];
		const maximoOpciones = dimension === 'metro:exacto' ? MAX_OPCIONES_METRO_EXACTO : MAX_OPCIONES;
		if (modelo.tipo !== 'numero' && (opciones.length < 2 || opciones.length > maximoOpciones))
			continue;

		const separacion = entropia([...grupos.values()]);
		const proporcionCobertura = cobertura / Math.max(1, arquitecturasPorForma.size);
		const respondibilidad = FIABILIDAD[modelo.observabilidad];
		const penalizacionDesconocida = familiasDesconocidas.has(modelo.familiaCognitiva) ? 0.22 : 1;
		const impulsoObjetivo =
			modo === 'hipotesis' &&
			formaObjetivoId &&
			hipotesis.some(
				(candidata) =>
					candidata.formaId === formaObjetivoId &&
					evidenciaDe(candidata, dimension)?.modalidad === 'definitoria'
			)
				? 1.35
				: 1;
		const utilidad =
			separacion *
			proporcionCobertura *
			respondibilidad *
			(1 - modelo.coste) *
			penalizacionDesconocida *
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
						: modelo.pregunta,
			ayuda:
				dimension === 'metro:exacto' &&
				(uniformidadMetroRespondida === 'varias_medidas' || grupoMetroRespondido === 'mixto')
					? 'Elige las medidas que has contado; no necesitas decidir por qué se combinan ni qué nombre recibe esa combinación.'
					: modelo.ayuda,
			tipo: modelo.tipo,
			opciones:
				dimension === 'metro:grupo' || dimension === 'metro:uniformidad'
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

export function elegirPregunta(
	catalogo: CatalogoDemarcador,
	respuestas: RespuestaDemarcador[],
	modo: ModoDemarcador,
	formaObjetivoId: string | null = null
): PreguntaDemarcador | null {
	const formasOrdenadas = ordenarFormas(catalogo, respuestas);
	const candidatas =
		respuestas.length === 0
			? catalogo.hipotesis
			: formasOrdenadas
					.filter((forma, index) => index < 12 || forma.nivel !== 'poco_compatible')
					.flatMap((forma) => forma.arquitecturas.map((item) => item.hipotesis));
	const preguntas = preguntasPosibles(candidatas, respuestas, modo, formaObjetivoId);
	if (respuestas.length === 0 && modo === 'guiado') {
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
		} else if (uniformidadRespondida.valor !== 'desconocido') {
			const medidaExacta = preguntas.find((pregunta) => pregunta.dimension === 'metro:exacto');
			if (medidaExacta) return medidaExacta;
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

export function etiquetaNivel(nivel: FormaPuntuada['nivel']): string {
	if (nivel === 'muy_compatible') return 'Muy compatible';
	if (nivel === 'compatible') return 'Compatible';
	if (nivel === 'posible') return 'Posible';
	return 'Poco compatible';
}

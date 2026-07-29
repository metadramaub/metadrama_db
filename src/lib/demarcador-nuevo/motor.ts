import type {
	CandidatoDemarcadorNuevo,
	ClaveRasgoDemarcador,
	EtapaDemarcador,
	PreguntaDemarcadorNueva,
	RespuestaDemarcadorNueva
} from './modelo';

type ValorRasgo = {
	conocido: boolean;
	clave: string;
	etiqueta: string;
	miembros: string[];
};

const MAX_OPCIONES = 7;
const PESO_RESPONDIBILIDAD: Record<ClaveRasgoDemarcador, number> = {
	metros: 1,
	tamanio: 0.94,
	rima: 0.84,
	predominioRima: 0.92,
	organizacionPareados: 0.9,
	naturaleza: 0.72,
	estructura: 0.86,
	patron: 0.48
};

const ORDEN_RASGOS: ClaveRasgoDemarcador[] = [
	'metros',
	'tamanio',
	'rima',
	'predominioRima',
	'organizacionPareados',
	'naturaleza',
	'estructura',
	'patron'
];

function valorDe(candidato: CandidatoDemarcadorNuevo, rasgo: ClaveRasgoDemarcador): ValorRasgo {
	switch (rasgo) {
		case 'metros': {
			const metros = candidato.rasgos.metros;
			return {
				conocido: metros.length > 0,
				clave: metros.map((metro) => metro.clave).join('+'),
				etiqueta: metros.map((metro) => metro.etiqueta).join(' + '),
				miembros: metros.map((metro) => metro.clave)
			};
		}
		case 'rima':
			return {
				conocido: Boolean(candidato.rasgos.rima),
				clave: candidato.rasgos.rima?.clave ?? '',
				etiqueta: candidato.rasgos.rima?.etiqueta ?? '',
				miembros: []
			};
		case 'predominioRima':
			return {
				conocido: Boolean(candidato.rasgos.predominioRima),
				clave: candidato.rasgos.predominioRima?.clave ?? '',
				etiqueta: candidato.rasgos.predominioRima?.etiqueta ?? '',
				miembros: []
			};
		case 'organizacionPareados':
			return {
				conocido: Boolean(candidato.rasgos.organizacionPareados),
				clave: candidato.rasgos.organizacionPareados?.clave ?? '',
				etiqueta: candidato.rasgos.organizacionPareados?.etiqueta ?? '',
				miembros: []
			};
		case 'naturaleza':
			return {
				conocido: Boolean(candidato.rasgos.naturaleza),
				clave: candidato.rasgos.naturaleza?.clave ?? '',
				etiqueta: candidato.rasgos.naturaleza?.etiqueta ?? '',
				miembros: []
			};
		case 'tamanio':
			return {
				conocido: typeof candidato.rasgos.tamanio === 'number',
				clave: typeof candidato.rasgos.tamanio === 'number' ? String(candidato.rasgos.tamanio) : '',
				etiqueta:
					typeof candidato.rasgos.tamanio === 'number' ? `${candidato.rasgos.tamanio} versos` : '',
				miembros: []
			};
		case 'estructura':
			return {
				conocido: Boolean(candidato.rasgos.estructura),
				clave: candidato.rasgos.estructura ?? '',
				etiqueta:
					candidato.rasgos.estructuraEtiqueta ??
					candidato.rasgos.estructura ??
					'',
				miembros: []
			};
		case 'patron':
			return {
				conocido: Boolean(candidato.rasgos.patron),
				clave: candidato.rasgos.patron ?? '',
				etiqueta: candidato.rasgos.patronEtiqueta ?? candidato.rasgos.patron ?? '',
				miembros: []
			};
	}
}

function entropia(grupos: number[]): number {
	const total = grupos.reduce((sum, value) => sum + value, 0);
	if (total === 0) return 0;
	return grupos.reduce((sum, value) => {
		if (value === 0) return sum;
		const probability = value / total;
		return sum - probability * Math.log2(probability);
	}, 0);
}

function puntuar(
	rasgo: ClaveRasgoDemarcador,
	grupos: number[],
	conocidos: number,
	total: number,
	numeroOpciones: number
): { puntuacion: number; cobertura: number } {
	const cobertura = total > 0 ? conocidos / total : 0;
	const penalizacionOpciones = Math.max(0.72, 1 - Math.max(0, numeroOpciones - 4) * 0.05);
	const puntuacion =
		entropia(grupos) * cobertura * PESO_RESPONDIBILIDAD[rasgo] * penalizacionOpciones;
	return {
		puntuacion: Math.round(puntuacion * 10000) / 10000,
		cobertura: Math.round(cobertura * 10000) / 10000
	};
}

function textosPregunta(
	rasgo: ClaveRasgoDemarcador,
	tipo: 'opciones' | 'si_no',
	etiquetaObjetivo = ''
): { pregunta: string; ayuda: string } {
	if (tipo === 'si_no') {
		switch (rasgo) {
			case 'metros':
				return {
					pregunta: `¿Aparecen versos de ${etiquetaObjetivo}?`,
					ayuda: 'Cuenta las sílabas métricas del verso, no únicamente sus sílabas gramaticales.'
				};
			case 'tamanio':
				return {
					pregunta: `¿La unidad estrófica tiene ${etiquetaObjetivo}?`,
					ayuda: 'Cuenta los versos de una unidad completa, no los de todo el poema.'
				};
			case 'rima':
				return {
					pregunta: `¿La rima es ${etiquetaObjetivo.toLocaleLowerCase('es')}?`,
					ayuda: 'Si no puedes determinarla con seguridad, responde «No sé».'
				};
			case 'predominioRima':
				return {
					pregunta: '¿Predominan los versos rimados?',
					ayuda:
						'Valora qué caracteriza el conjunto de la serie; no hace falta calcular un porcentaje.'
				};
			case 'organizacionPareados':
				return {
					pregunta: '¿La serie está organizada sistemáticamente en pareados?',
					ayuda:
						'Responde «Sí» solo si los dísticos organizan de forma regular o prácticamente completa la serie.'
				};
			case 'naturaleza':
				return {
					pregunta: `¿Se organiza como ${etiquetaObjetivo.toLocaleLowerCase('es')}?`,
					ayuda: 'Esta pregunta describe la arquitectura general de la forma.'
				};
			case 'estructura':
				return {
					pregunta: `¿Las partes siguen el orden ${etiquetaObjetivo}?`,
					ayuda: 'Observa el orden de las unidades internas, no el esquema completo de sus rimas.'
				};
			case 'patron':
				return {
					pregunta: `¿Coincide con el patrón ${etiquetaObjetivo}?`,
					ayuda: 'Compara el orden de las rimas; las letras iguales representan rimas iguales.'
				};
		}
	}

	switch (rasgo) {
		case 'metros':
			return {
				pregunta: '¿Qué medida tienen los versos?',
				ayuda: 'Elige la combinación de medidas que aparece de forma característica.'
			};
		case 'tamanio':
			return {
				pregunta: '¿Cuántos versos tiene la unidad estrófica?',
				ayuda: 'Si no hay una unidad de tamaño fijo, responde «No sé».'
			};
		case 'rima':
			return {
				pregunta: '¿Qué tipo de rima presenta?',
				ayuda: 'Si conviven varios tipos o no puedes determinarlo, responde «No sé».'
			};
		case 'predominioRima':
			return {
				pregunta: '¿Qué predomina en la serie?',
				ayuda: 'Distingue si predominan los versos rimados o los versos sueltos.'
			};
		case 'organizacionPareados':
			return {
				pregunta: '¿Cómo se organizan los pareados?',
				ayuda: 'Distingue una organización sistemática de una presencia ocasional o habitual.'
			};
		case 'naturaleza':
			return {
				pregunta: '¿Cómo se organiza la forma estrófica?',
				ayuda: 'Elige la arquitectura general que mejor describa la forma.'
			};
		case 'estructura':
			return {
				pregunta: '¿Cómo se ordenan las partes de la forma?',
				ayuda: 'Elige el orden de las unidades internas, por ejemplo redondilla + quintilla.'
			};
		case 'patron':
			return {
				pregunta: '¿Qué patrón de rima tiene?',
				ayuda: 'Esta precisión se pregunta solo al distinguir variantes de una misma familia.'
			};
	}
}

function preguntaDeOpciones(
	candidatos: CandidatoDemarcadorNuevo[],
	etapa: EtapaDemarcador,
	rasgo: ClaveRasgoDemarcador
): PreguntaDemarcadorNueva | null {
	// Estos dos rasgos cualitativos se expresan mejor mediante preguntas binarias
	// que mediante opciones terminológicas.
	if (rasgo === 'predominioRima' || rasgo === 'organizacionPareados') return null;

	const values = candidatos.map((candidato) => valorDe(candidato, rasgo));
	const conocidos = values.filter((value) => value.conocido);
	const grupos = new Map<string, { etiqueta: string; total: number }>();
	for (const value of conocidos) {
		const current = grupos.get(value.clave);
		grupos.set(value.clave, {
			etiqueta: value.etiqueta,
			total: (current?.total ?? 0) + 1
		});
	}
	if (grupos.size < 2 || grupos.size > MAX_OPCIONES) return null;

	const opciones = [...grupos.entries()]
		.map(([valor, group]) => ({ valor, etiqueta: group.etiqueta, total: group.total }))
		.sort((a, b) => b.total - a.total || a.etiqueta.localeCompare(b.etiqueta, 'es'));
	const score = puntuar(
		rasgo,
		opciones.map((option) => option.total),
		conocidos.length,
		candidatos.length,
		opciones.length
	);
	const textos = textosPregunta(rasgo, 'opciones');

	return {
		id: `${etapa}:${rasgo}:opciones`,
		etapa,
		rasgo,
		tipo: 'opciones',
		operador: 'igual',
		pregunta: textos.pregunta,
		ayuda: textos.ayuda,
		opciones: opciones.map(({ valor, etiqueta }) => ({ valor, etiqueta })),
		valorObjetivo: null,
		...score
	};
}

function preguntasBinarias(
	candidatos: CandidatoDemarcadorNuevo[],
	etapa: EtapaDemarcador,
	rasgo: ClaveRasgoDemarcador
): PreguntaDemarcadorNueva[] {
	const values = candidatos.map((candidato) => valorDe(candidato, rasgo));
	const conocidos = values.filter((value) => value.conocido);
	const objetivos = new Map<string, string>();

	for (const value of conocidos) {
		if (rasgo === 'metros') {
			for (const member of value.miembros) {
				const metro = candidatos
					.flatMap((candidato) => candidato.rasgos.metros)
					.find((item) => item.clave === member);
				objetivos.set(member, metro?.etiqueta ?? member);
			}
		} else {
			objetivos.set(value.clave, value.etiqueta);
		}
	}

	const preguntas: PreguntaDemarcadorNueva[] = [];
	const objetivosBinarios =
		rasgo === 'predominioRima'
			? [...objetivos].filter(([objetivo]) => objetivo === 'rimados')
			: rasgo === 'organizacionPareados'
				? [...objetivos].filter(([objetivo]) => objetivo === 'sistematica')
				: [...objetivos];

	for (const [objetivo, etiqueta] of objetivosBinarios) {
		let yes = 0;
		let no = 0;
		for (const value of conocidos) {
			const matches =
				rasgo === 'metros' ? value.miembros.includes(objetivo) : value.clave === objetivo;
			if (matches) yes += 1;
			else no += 1;
		}
		if (yes === 0 || no === 0) continue;
		const textos = textosPregunta(rasgo, 'si_no', etiqueta);
		preguntas.push({
			id: `${etapa}:${rasgo}:${rasgo === 'metros' ? 'contiene' : 'igual'}:${objetivo}`,
			etapa,
			rasgo,
			tipo: 'si_no',
			operador: rasgo === 'metros' ? 'contiene' : 'igual',
			pregunta: textos.pregunta,
			ayuda: textos.ayuda,
			opciones: [],
			valorObjetivo: objetivo,
			...puntuar(rasgo, [yes, no], conocidos.length, candidatos.length, 2)
		});
	}
	return preguntas;
}

export function construirPreguntas(
	candidatos: CandidatoDemarcadorNuevo[],
	etapa: EtapaDemarcador,
	respuestas: RespuestaDemarcadorNueva[] = [],
	options: { incluirPatronEnFamilias?: boolean } = {}
): PreguntaDemarcadorNueva[] {
	if (candidatos.length < 2) return [];
	const respondidas = new Set(respuestas.map((respuesta) => respuesta.preguntaId));
	const rasgos =
		etapa === 'familias' && !options.incluirPatronEnFamilias
			? ORDEN_RASGOS.filter((rasgo) => rasgo !== 'patron')
			: ORDEN_RASGOS;
	const preguntas: PreguntaDemarcadorNueva[] = [];

	for (const rasgo of rasgos) {
		const opciones = preguntaDeOpciones(candidatos, etapa, rasgo);
		if (opciones) preguntas.push(opciones);
		else preguntas.push(...preguntasBinarias(candidatos, etapa, rasgo));
	}

	return preguntas
		.filter((pregunta) => !respondidas.has(pregunta.id))
		.sort((a, b) => {
			if (b.puntuacion !== a.puntuacion) return b.puntuacion - a.puntuacion;
			if (b.cobertura !== a.cobertura) return b.cobertura - a.cobertura;
			return ORDEN_RASGOS.indexOf(a.rasgo) - ORDEN_RASGOS.indexOf(b.rasgo);
		});
}

export function elegirSiguientePreguntaNueva(
	candidatos: CandidatoDemarcadorNuevo[],
	etapa: EtapaDemarcador,
	respuestas: RespuestaDemarcadorNueva[] = [],
	options: { incluirPatronEnFamilias?: boolean } = {}
): PreguntaDemarcadorNueva | null {
	return construirPreguntas(candidatos, etapa, respuestas, options)[0] ?? null;
}

function candidatoCoincide(
	candidato: CandidatoDemarcadorNuevo,
	pregunta: PreguntaDemarcadorNueva,
	respuesta: RespuestaDemarcadorNueva
): boolean {
	if (respuesta.valor === 'desconocido') return true;
	const value = valorDe(candidato, pregunta.rasgo);
	if (!value.conocido) return true;

	if (pregunta.tipo === 'opciones') {
		return value.clave === respuesta.valor;
	}

	const matches =
		pregunta.operador === 'contiene'
			? value.miembros.includes(pregunta.valorObjetivo ?? '')
			: value.clave === pregunta.valorObjetivo;
	return respuesta.valor === 'si' ? matches : !matches;
}

export function filtrarCandidatosNuevos(
	candidatos: CandidatoDemarcadorNuevo[],
	preguntas: PreguntaDemarcadorNueva[],
	respuestas: RespuestaDemarcadorNueva[]
): CandidatoDemarcadorNuevo[] {
	const preguntasPorId = new Map(preguntas.map((pregunta) => [pregunta.id, pregunta]));
	return candidatos.filter((candidato) =>
		respuestas.every((respuesta) => {
			const pregunta = preguntasPorId.get(respuesta.preguntaId);
			return pregunta ? candidatoCoincide(candidato, pregunta, respuesta) : true;
		})
	);
}

export function crearRespuestaNueva(
	pregunta: PreguntaDemarcadorNueva,
	valor: string | 'desconocido',
	etiqueta: string
): RespuestaDemarcadorNueva {
	return {
		preguntaId: pregunta.id,
		pregunta: pregunta.pregunta,
		etapa: pregunta.etapa,
		valor,
		etiqueta
	};
}

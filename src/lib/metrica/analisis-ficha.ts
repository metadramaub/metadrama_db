import { enunciationType } from './enunciation';

/**
 * Lo que se puede decir de una obra **sin volver a preguntar a la base**.
 *
 * Todo lo que hay aquí se calcula sobre la ficha que la página ya tiene cargada: el perfil por
 * jornadas, el reparto entre tradiciones, el desglose de cada forma en sus arquitecturas y sus
 * esquemas, las transiciones de una forma a otra y los cortes de cuadro. Ni una consulta más, que
 * es la razón de que esté en el navegador y no en el servidor.
 *
 * **Es puro y se prueba solo**, como `rejilla.ts`: los componentes solo pintan lo que sale de aquí.
 * Y consume un tipo mínimo propio, no `PublicFichaSecuencia`, para poder servir también al perfil
 * de autor cuando llegue.
 */

/** Lo que hace falta saber de una secuencia para analizarla. */
export interface SecuenciaAnalizable {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	n_versos: number;
	/** Slug de la forma; `null` en un tramo del que no se afirma forma. */
	forma_slug: string | null;
	/** Etiqueta legible de la forma. */
	forma: string | null;
	/** Etiqueta de la arquitectura, que es el detalle dentro de la forma. */
	arquitectura: string | null;
	/** `forma_espanola` | `forma_italiana` | `null` en los tramos sin forma. */
	tradicion: string | null;
	jornada_num: number | null;
	cuadro_num: number | null;
	/** La secuencia continúa después del cambio de cuadro. */
	cuadro_continua: boolean | null;
	esquemas: { nombre: string; unidades: number }[];
	rasgos: { rasgo: string; valor: string }[];
	caracterizaciones: { tipo: string; v_ini: number; v_fin: number }[];
	desviaciones: { dimension: string; relacion_norma: string }[];
	versos_partidos: boolean | null;
	inaugura_espacio: boolean | null;
}

export interface CuadroAnalizable {
	jornada_id: string;
	cuadro_num: number;
	v_ini: number;
	v_fin: number;
}

export interface ReferenciaSecuenciaEnCorte {
	secuencia_id: string;
	v_ini: number;
	v_fin: number;
	forma: string;
	colorKey: string;
}

export interface CambioDeSecuenciaEnCuadro {
	limite: number;
	anterior: ReferenciaSecuenciaEnCorte;
	siguiente: ReferenciaSecuenciaEnCorte;
	/** Matiz para el detalle: no divide el agregado principal. */
	cambiaForma: boolean;
}

export interface SecuenciaPorCortesDeCuadro extends ReferenciaSecuenciaEnCorte {
	cortes: number;
}

/** Una forma con su peso. */
export interface PesoDeForma {
	forma: string;
	colorKey: string;
	versos: number;
	porcentaje: number;
}

/**
 * El nombre que se le da a lo que no tiene forma.
 *
 * **No se descarta**: un pasaje del que no se afirma forma es un dato, y dejarlo fuera del reparto
 * hace que los porcentajes no sumen cien sin que nadie sepa por qué.
 */
export const SIN_FORMA = 'Sin forma anotada';

const porcentaje = (parte: number, total: number) =>
	total > 0 ? Math.round((parte / total) * 10000) / 100 : 0;

const claveDe = (s: SecuenciaAnalizable) => s.forma_slug ?? SIN_FORMA;
const nombreDe = (s: SecuenciaAnalizable) => s.forma ?? SIN_FORMA;
const referenciaDe = (secuencia: SecuenciaAnalizable): ReferenciaSecuenciaEnCorte => ({
	secuencia_id: secuencia.secuencia_id,
	v_ini: secuencia.v_ini,
	v_fin: secuencia.v_fin,
	forma: nombreDe(secuencia),
	colorKey: claveDe(secuencia)
});

/** Suma de versos de una lista de secuencias. */
export const versosDe = (secuencias: SecuenciaAnalizable[]) =>
	secuencias.reduce((total, s) => total + s.n_versos, 0);

/**
 * **Número efectivo de formas**, `exp(H)` con `H = −Σ p·ln p` sobre los versos de cada forma.
 *
 * Es la definición que usa la precomputación —`recompute_obra_resumen_metricas`— y con la que
 * `/obras` ordena el corpus, replicada aquí para poder decirla también dentro de una obra sin una
 * consulta más. Los pasajes **sin forma anotada quedan fuera del cálculo**, igual que allí: no son
 * una forma, y contarlos como una inventaría diversidad donde solo hay hueco.
 *
 * Se lee como «cuántas formas equivaldrían a este reparto si todas pesaran lo mismo».
 */
export function numeroEfectivoDeFormas(secuencias: SecuenciaAnalizable[]): number {
	const conForma = perfilDeFormas(secuencias).filter((f) => f.colorKey !== SIN_FORMA);
	const total = conForma.reduce((suma, f) => suma + f.versos, 0);
	if (total === 0) return 0;
	const entropia = conForma.reduce((suma, f) => {
		const p = f.versos / total;
		return p > 0 ? suma - p * Math.log(p) : suma;
	}, 0);
	return Math.exp(entropia);
}

/**
 * **Densidad de transiciones**: cuántas secuencias hay por cada cien versos.
 *
 * También como la precomputación, que la define `n_secuencias / total_versos * 100`. Dice si la
 * obra cambia de forma a menudo o se queda en tiradas largas, y es lo mismo que el resumen enseña
 * al revés como longitud media: se conservan las dos porque `/obras` filtra y ordena por esta.
 */
export function densidadDeTransiciones(secuencias: SecuenciaAnalizable[]): number {
	const versos = versosDe(secuencias);
	return versos > 0 ? (secuencias.length / versos) * 100 : 0;
}

/** Reparto de formas, de la que más pesa a la que menos. */
export function perfilDeFormas(secuencias: SecuenciaAnalizable[]): PesoDeForma[] {
	const total = versosDe(secuencias);
	const acumulado = new Map<string, { forma: string; versos: number }>();
	for (const s of secuencias) {
		const clave = claveDe(s);
		const entrada = acumulado.get(clave) ?? { forma: nombreDe(s), versos: 0 };
		entrada.versos += s.n_versos;
		acumulado.set(clave, entrada);
	}
	return [...acumulado.entries()]
		.map(([colorKey, { forma, versos }]) => ({
			forma,
			colorKey,
			versos,
			porcentaje: porcentaje(versos, total)
		}))
		.sort((a, b) => b.versos - a.versos || a.forma.localeCompare(b.forma, 'es'));
}

/** El mismo reparto, jornada por jornada. */
export function perfilPorJornada(secuencias: SecuenciaAnalizable[]) {
	const jornadas = [
		...new Set(secuencias.map((s) => s.jornada_num).filter((n): n is number => n !== null))
	].sort((a, b) => a - b);
	return jornadas.map((jornada) => {
		const suyas = secuencias.filter((s) => s.jornada_num === jornada);
		return { jornada, versos: versosDe(suyas), formas: perfilDeFormas(suyas) };
	});
}

/** Españolas contra italianas, y lo que no es ni una cosa ni otra. */
export function perfilDeTradiciones(secuencias: SecuenciaAnalizable[]) {
	const total = versosDe(secuencias);
	const cuenta = (tradicion: string | null) =>
		versosDe(secuencias.filter((s) => (s.tradicion ?? null) === tradicion));
	const espanola = cuenta('forma_espanola');
	const italiana = cuenta('forma_italiana');
	const sinTradicion = total - espanola - italiana;
	return {
		total,
		espanola: { versos: espanola, porcentaje: porcentaje(espanola, total) },
		italiana: { versos: italiana, porcentaje: porcentaje(italiana, total) },
		sinTradicion: { versos: sinTradicion, porcentaje: porcentaje(sinTradicion, total) }
	};
}

/** Cómo se mueve el reparto entre tradiciones a lo largo de la obra. */
export function tradicionesPorJornada(secuencias: SecuenciaAnalizable[]) {
	return perfilPorJornada(secuencias).map(({ jornada }) => ({
		jornada,
		...perfilDeTradiciones(secuencias.filter((s) => s.jornada_num === jornada))
	}));
}

/**
 * Una forma abierta por dentro: sus arquitecturas y sus esquemas de rima.
 *
 * Es lo que contesta a «12 % de quintillas, y de ellas la mitad en `ababa`». Las arquitecturas se
 * pesan **en versos**, porque ocupan pasaje; los esquemas **en estrofas**, porque se responden una
 * vez por estrofa y contarlos en versos daría el mismo número multiplicado.
 */
export function desgloseDeFormas(secuencias: SecuenciaAnalizable[]) {
	return perfilDeFormas(secuencias).map((peso) => {
		const suyas = secuencias.filter((s) => claveDe(s) === peso.colorKey);

		const porArquitectura = new Map<string, number>();
		for (const s of suyas) {
			const nombre = s.arquitectura ?? '—';
			porArquitectura.set(nombre, (porArquitectura.get(nombre) ?? 0) + s.n_versos);
		}

		const porEsquema = new Map<string, number>();
		for (const s of suyas) {
			for (const e of s.esquemas) {
				porEsquema.set(e.nombre, (porEsquema.get(e.nombre) ?? 0) + e.unidades);
			}
		}
		const estrofas = [...porEsquema.values()].reduce((a, b) => a + b, 0);

		return {
			...peso,
			secuencias: suyas.length,
			arquitecturas: [...porArquitectura.entries()]
				.map(([nombre, versos]) => ({
					nombre,
					versos,
					porcentaje: porcentaje(versos, peso.versos)
				}))
				.sort((a, b) => b.versos - a.versos),
			esquemas: [...porEsquema.entries()]
				.map(([nombre, unidades]) => ({
					nombre,
					unidades,
					porcentaje: porcentaje(unidades, estrofas)
				}))
				.sort((a, b) => b.unidades - a.unidades)
		};
	});
}

/**
 * Qué forma sigue a cuál, y cuántas veces.
 *
 * Se cuenta sobre la serie tal como suena, **sin saltar los cortes de jornada**: que un acto acabe
 * en romance y el siguiente abra en redondilla es una transición como cualquier otra, y de hecho es
 * de las que interesan.
 */
export function transiciones(secuencias: SecuenciaAnalizable[]) {
	const orden = [...secuencias].sort((a, b) => a.v_ini - b.v_ini);
	const cuenta = new Map<
		string,
		{
			de: string;
			deColorKey: string;
			a: string;
			aColorKey: string;
			veces: number;
			ocurrencias: {
				anterior: ReferenciaSecuenciaEnCorte;
				siguiente: ReferenciaSecuenciaEnCorte;
			}[];
		}
	>();
	for (let i = 1; i < orden.length; i += 1) {
		const anterior = orden[i - 1];
		const siguiente = orden[i];
		const de = nombreDe(anterior);
		const deColorKey = claveDe(anterior);
		const a = nombreDe(siguiente);
		const aColorKey = claveDe(siguiente);
		const clave = `${de}\u0000${a}`;
		const entrada = cuenta.get(clave) ?? { de, deColorKey, a, aColorKey, veces: 0, ocurrencias: [] };
		entrada.veces += 1;
		entrada.ocurrencias.push({ anterior: referenciaDe(anterior), siguiente: referenciaDe(siguiente) });
		cuenta.set(clave, entrada);
	}
	return [...cuenta.values()].sort(
		(x, y) => y.veces - x.veces || x.de.localeCompare(y.de, 'es') || x.a.localeCompare(y.a, 'es')
	);
}

/** Cómo son las secuencias de cada forma: cuántas, cuánto miden y cuáles son sus extremos. */
export function secuenciasPorForma(secuencias: SecuenciaAnalizable[]) {
	return perfilDeFormas(secuencias).map((peso) => {
		const largos = secuencias
			.filter((s) => claveDe(s) === peso.colorKey)
			.map((s) => s.n_versos)
			.sort((a, b) => a - b);
		return {
			forma: peso.forma,
			colorKey: peso.colorKey,
			secuencias: largos.length,
			versos: peso.versos,
			media: largos.length > 0 ? Math.round(peso.versos / largos.length) : 0,
			minima: largos[0] ?? 0,
			maxima: largos[largos.length - 1] ?? 0
		};
	});
}

/**
 * Cómo se relacionan los cambios de cuadro con los límites de las secuencias.
 *
 * El tablado se vacía muchas veces en mitad de un romance, y eso es una decisión dramática que se
 * puede medir: en las comedias de Lope que se leyeron a mano, siete de cada diez cambios de cuadro
 * coinciden con un cambio de forma y tres no.
 */
export function cortesDeCuadro(
	secuencias: SecuenciaAnalizable[],
	cuadros: CuadroAnalizable[]
) {
	const limites = [...new Set(
		[...new Set(cuadros.map((cuadro) => cuadro.jornada_id))].flatMap((jornadaId) =>
			cuadros
				.filter((cuadro) => cuadro.jornada_id === jornadaId)
				.sort((a, b) => a.v_ini - b.v_ini || a.cuadro_num - b.cuadro_num)
				.slice(1)
				.map((cuadro) => cuadro.v_ini)
		)
	)].sort((a, b) => a - b);
	const orden = [...secuencias].sort((a, b) => a.v_ini - b.v_ini);
	let partenSecuencia = 0;
	let cambiosSecuencia = 0;
	let sinCobertura = 0;
	const cambiosDeSecuencia: CambioDeSecuenciaEnCuadro[] = [];
	const cortesPorSecuencia = new Map<string, number>();
	for (const limite of limites) {
		const anterior = orden.find((s) => s.v_ini <= limite - 1 && s.v_fin >= limite - 1);
		const siguiente = orden.find((s) => s.v_ini <= limite && s.v_fin >= limite);
		if (!anterior || !siguiente) {
			sinCobertura += 1;
		} else if (anterior.secuencia_id === siguiente.secuencia_id) {
			partenSecuencia += 1;
			cortesPorSecuencia.set(anterior.secuencia_id, (cortesPorSecuencia.get(anterior.secuencia_id) ?? 0) + 1);
		} else {
			cambiosSecuencia += 1;
			cambiosDeSecuencia.push({
				limite,
				anterior: referenciaDe(anterior),
				siguiente: referenciaDe(siguiente),
				cambiaForma: claveDe(anterior) !== claveDe(siguiente)
			});
		}
	}

	const secuenciasPorCortes: SecuenciaPorCortesDeCuadro[] = orden
		.map((secuencia) => ({
			...referenciaDe(secuencia),
			cortes: cortesPorSecuencia.get(secuencia.secuencia_id) ?? 0
		}))
		.sort((a, b) => b.cortes - a.cortes || a.v_ini - b.v_ini);

	return {
		total: limites.length,
		partenSecuencia,
		cambiosSecuencia,
		sinCobertura,
		cambiosDeSecuencia,
		secuenciasPorCortes
	};
}

/** Qué se canta y qué va en prosa: cuántos versos y en qué formas. */
export function caracterizacionesDeLaObra(secuencias: SecuenciaAnalizable[]) {
	const total = versosDe(secuencias);
	const porTipo = new Map<
		string,
		{ rangos: { v_ini: number; v_fin: number }[]; formas: Set<string> }
	>();
	for (const s of secuencias) {
		for (const c of s.caracterizaciones) {
			const tipo = enunciationType(c.tipo);
			if (!tipo) continue;
			const entrada = porTipo.get(tipo) ?? { rangos: [], formas: new Set<string>() };
			entrada.rangos.push({ v_ini: c.v_ini, v_fin: c.v_fin });
			entrada.formas.add(nombreDe(s));
			porTipo.set(tipo, entrada);
		}
	}
	return [...porTipo.entries()]
		.map(([tipo, { rangos, formas }]) => {
			const ordenados = [...rangos].sort((a, b) => a.v_ini - b.v_ini || a.v_fin - b.v_fin);
			const unidos: { v_ini: number; v_fin: number }[] = [];
			for (const rango of ordenados) {
				const anterior = unidos.at(-1);
				if (anterior && rango.v_ini <= anterior.v_fin + 1) {
					anterior.v_fin = Math.max(anterior.v_fin, rango.v_fin);
				} else {
					unidos.push({ ...rango });
				}
			}
			const versos = unidos.reduce((suma, rango) => suma + rango.v_fin - rango.v_ini + 1, 0);
			return {
				tipo,
				versos,
				porcentaje: porcentaje(versos, total),
				formas: [...formas].sort((a, b) => a.localeCompare(b, 'es'))
			};
		})
		.sort((a, b) => b.versos - a.versos);
}

/**
 * Los números de la obra, dichos de una vez.
 *
 * Incluye la forma que la abre y la que la cierra, que es de lo que más se comenta en la
 * bibliografía y hasta ahora había que ir a buscar al código de barras.
 */
export function fichaTecnica(secuencias: SecuenciaAnalizable[]) {
	const orden = [...secuencias].sort((a, b) => a.v_ini - b.v_ini);
	const perfil = perfilDeFormas(secuencias);
	const total = versosDe(secuencias);
	const jornadas = new Set(orden.map((s) => s.jornada_num).filter((n) => n !== null)).size;
	return {
		versos: total,
		secuencias: orden.length,
		jornadas,
		formasDistintas: perfil.filter((p) => p.colorKey !== SIN_FORMA).length,
		mediaPorSecuencia: orden.length > 0 ? Math.round(total / orden.length) : 0,
		secuenciaMasLarga: orden.reduce<SecuenciaAnalizable | null>(
			(mayor, s) => (!mayor || s.n_versos > mayor.n_versos ? s : mayor),
			null
		),
		// La más corta dice tanto como la más larga: un soneto suelto entre tiradas de cien versos
		// es justo lo que no se ve en la media.
		secuenciaMasCorta: orden.reduce<SecuenciaAnalizable | null>(
			(menor, s) => (!menor || s.n_versos < menor.n_versos ? s : menor),
			null
		),
		// Las dos medidas con las que `/obras` ordena el corpus, dichas también aquí. Hoy solo dan el
		// dato; comparar la obra con el corpus es la capa que viene cuando haya corpus publicado.
		diversidad: numeroEfectivoDeFormas(orden),
		densidad: densidadDeTransiciones(orden),
		abre: orden[0] ? nombreDe(orden[0]) : null,
		cierra: orden.length > 0 ? nombreDe(orden[orden.length - 1]) : null,
		conVersosPartidos: orden.filter((s) => s.versos_partidos).length,
		inauguranEspacio: orden.filter((s) => s.inaugura_espacio).length,
		conDesviaciones: orden.filter((s) => s.desviaciones.length > 0).length
	};
}

/**
 * Cómo cambia la obra de una jornada a otra: longitud de las secuencias y diversidad de formas.
 *
 * **La diversidad es el mismo número efectivo que usa el buscador**, `exp(H)` con
 * `H = −Σ p·ln p` sobre el reparto de versos por forma. Se reutiliza a propósito en vez de
 * inventar otra medida: si `/obras` ordena por ella, dentro de una obra tiene que significar lo
 * mismo —cuántas formas *equivalen* al reparto que hay, si todas pesaran igual—. Una jornada con
 * 2,0 se comporta como si tuviera dos formas repartidas a medias, aunque nombre cinco.
 *
 * **Es exploratorio.** Con tres jornadas hay tres puntos, y de tres puntos no sale una tendencia
 * que sostener: sirve para ver la obra, no para afirmar nada de ella. Lo que diga esta pantalla
 * sobre un corpus está por decidir.
 */
export function evolucionPorJornada(secuencias: SecuenciaAnalizable[]) {
	return perfilPorJornada(secuencias).map(({ jornada, versos, formas }) => {
		const suyas = secuencias.filter((s) => s.jornada_num === jornada);
		return {
			jornada,
			secuencias: suyas.length,
			versos,
			longitudMedia: suyas.length > 0 ? Math.round(versos / suyas.length) : 0,
			formasDistintas: formas.filter((f) => f.colorKey !== SIN_FORMA).length,
			numeroEfectivo: Math.round(numeroEfectivoDeFormas(suyas) * 100) / 100
		};
	});
}

/** Con qué cierra cada jornada, que es donde se ve si la obra tiene una fórmula. */
export function cierreDeJornadas(secuencias: SecuenciaAnalizable[]) {
	return perfilPorJornada(secuencias).map(({ jornada }) => {
		const suyas = secuencias
			.filter((s) => s.jornada_num === jornada)
			.sort((a, b) => a.v_ini - b.v_ini);
		return {
			jornada,
			abre: suyas[0] ? nombreDe(suyas[0]) : null,
			abreColorKey: suyas[0] ? claveDe(suyas[0]) : null,
			cierra: suyas.length > 0 ? nombreDe(suyas[suyas.length - 1]) : null,
			cierraColorKey: suyas.length > 0 ? claveDe(suyas[suyas.length - 1]) : null
		};
	});
}

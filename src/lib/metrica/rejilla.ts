import { compararPorModalidadYNombre } from '$lib/metrica/modalidad';

/**
 * La rejilla de posiciones: una arquitectura dibujada verso a verso.
 *
 * Una columna por verso, una fila para la medida y otra para la clase de rima, y debajo las
 * bandas de las partes. Es lo que ninguna de las tres superficies enseñaba —la ficha pública
 * describía la estructura en prosa, el demarcador solo la medida y el editor ni eso— y es lo que
 * permite reconocer una forma en una secuencia real.
 *
 * **Aquí no hay reglas filológicas.** Todo sale del catálogo: las posiciones, sus alternativas,
 * las secciones y su extensión. Si una forma se dibuja mal, o el catálogo no dice lo que hace
 * falta o lo dice en otro nivel; ese es justamente el uso que se le espera a esta rejilla.
 *
 * La entrada se parece a propósito a las filas de la base, para que las tres superficies
 * —`formas-publicas.ts`, `demarcador-metrico.ts` y el editor V2— la construyan con un `map` y no
 * con tres interpretaciones distintas del mismo dato.
 */

/** Cuántas columnas se dibujan como mucho. Más no cabe en pantalla ni se lee de un vistazo. */
const MAXIMO_DE_COLUMNAS = 24;

export type PosicionMetricaEntrada = {
	posicion: number;
	/** Sílabas del metro, ya resueltas: la rejilla no conoce identificadores. */
	silabas: string | null;
	/** Dos filas con la misma posición y distinta alternativa son opciones de esa posición. */
	alternativa: number | null;
	opcional: boolean;
};

export type EsquemaMetricoEntrada = {
	/** `ciclo`, `secuencia` o `conjunto`. */
	tipoSecuencia: string | null;
	/** En un repertorio abierto, si la medida elegida vale para todo el pasaje. */
	medidaUniforme: boolean | null;
	/** Nombre de la sección a la que se aplica, cuando no es de la unidad entera. */
	seccion: string | null;
	posiciones: PosicionMetricaEntrada[];
	/** Repertorio de un esquema sin posiciones: la realización decide dónde va cada medida. */
	opciones: { silabas: string | null; rol: string | null }[];
};

export type PosicionRimaEntrada = {
	bloque: number;
	posicion: number;
	clase: string | null;
	suelto: boolean;
	/** Parte con nombre dentro del esquema: la fronte de la estancia, la vuelta del zéjel. */
	seccion: string | null;
	/** Precisión sobre ese verso concreto, cuando la figura no puede decirla. */
	nota?: string | null;
};

export type EnlaceEntrada = {
	desde: number;
	hasta: number;
	desplazamiento: number;
	nota: string | null;
};

export type EsquemaRimaEntrada = {
	id: string;
	nombre: string | null;
	notacion: string | null;
	/** Nombre de la sección cuya rima describe, cuando no es la de la unidad entera. */
	seccion: string | null;
	modalidad: string | null;
	posiciones: PosicionRimaEntrada[];
	enlaces: EnlaceEntrada[];
};

export type SeccionEntrada = {
	nombre: string;
	versosMin: number | null;
	versosMax: number | null;
	repeticionesMin: number | null;
	repeticionesMax: number | null;
	/** La forma cuyo repertorio de rima reutiliza, para poder enlazarla desde la banda. */
	reutiliza: { nombre: string; slug: string | null } | null;
};

export type EntradaRejilla = {
	metricos: EsquemaMetricoEntrada[];
	rimas: EsquemaRimaEntrada[];
	/** Solo las secciones raíz: las hijas describen el interior de una parte, no el esqueleto. */
	secciones: SeccionEntrada[];
	unidadMin: number | null;
	unidadMax: number | null;
};

export type MedidaDeCelda = {
	/** Sílabas cuando la norma fija una sola en esta posición. */
	silabas: string | null;
	/** Las que admite cuando no fija una: la realización elige entre ellas. */
	alternativas: string[];
	opcional: boolean;
};

export type RimaDeCelda = {
	clase: string | null;
	suelto: boolean;
	/**
	 * Lo que hay que saber de **ese** verso y la figura no dibuja: que el séptimo de la estancia
	 * rima con la fronte pero pertenece ya a la sirima. Vivía en el catálogo sin llegar nunca a
	 * la pantalla, y su sitio es la celda, no un párrafo aparte.
	 */
	nota?: string | null;
};

export type CeldaRejilla = {
	/** Orden de lectura dentro de lo dibujado, desde 1. */
	verso: number;
	medida: MedidaDeCelda | null;
};

/**
 * Una disposición de rima, dibujada sobre las columnas que ocupa.
 *
 * **Todas las que admite la arquitectura se dibujan, alineadas bajo la misma medida.** Dibujar
 * una y dejar las demás en una lista aparte descompensaba la ficha —la elegida salía arriba y las
 * otras abajo, con distinto tratamiento— y obligaba a comparar de memoria lo que se compara
 * mirando. Las de una parte ocupan solo sus columnas: las de los cuartetos del soneto van del 1 al
 * 8 y las de sus tercetos del 9 al 14.
 */
export type FilaDeRima = {
	esquemaRimaId: string;
	nombre: string | null;
	notacion: string | null;
	modalidad: string | null;
	/** Solo se imprime por fila cuando dentro de la arquitectura varía el régimen. */
	tipoRima?: string | null;
	/** La parte de la que es la disposición, cuando no es de la unidad entera. */
	parte: string | null;
	desde: number;
	hasta: number;
	/** Una entrada por columna, de `desde` a `hasta`. */
	clases: RimaDeCelda[];
};

export type BandaRejilla = {
	nombre: string;
	desde: number;
	hasta: number;
	/** Cuántas veces se repite la parte que la banda dibuja una sola vez: «×6», «×3 o más». */
	repeticiones: string | null;
	/** Cuántas apariciones seguidas de la parte abarca la banda: los dos cuartetos del soneto. */
	apariciones?: number;
	reutiliza: { nombre: string; slug: string | null } | null;
};

export type EnlaceRejilla = {
	desde: number;
	hasta: number;
	/** Hacia la repetición siguiente, la anterior o dentro de la misma. */
	sentido: 'adelante' | 'atras' | 'interior';
	nota: string | null;
};

export type Rejilla = {
	celdas: CeldaRejilla[];
	/** Todas las disposiciones que admite la arquitectura, alineadas bajo la medida. */
	filasDeRima: FilaDeRima[];
	bandas: BandaRejilla[];
	enlaces: EnlaceRejilla[];
	/** Lo dibujado se repite hasta el final de la serie. */
	cicla: boolean;
	/** Se dibujaron menos columnas de las que tiene la unidad. */
	recortada: boolean;
	tieneMedida: boolean;
	tieneRima: boolean;
	/** La parte que la rejilla dibuja, cuando no dibuja la unidad entera: «Estancia regular». */
	parte: string | null;
	/** Cuántas veces se repite esa parte: «×3 o más». */
	repeticionesDeLaParte: string | null;
};

/** Las posiciones en orden de lectura: primero el bloque, luego la posición dentro del bloque. */
function posicionesOrdenadas(esquema: EsquemaRimaEntrada): PosicionRimaEntrada[] {
	return [...esquema.posiciones].sort((a, b) => a.bloque - b.bloque || a.posicion - b.posicion);
}

/**
 * Cuál de las disposiciones se dibuja.
 *
 * Manda tener posiciones: un esquema abierto declara que **no** hay una disposición que enseñar,
 * y aunque sea el definitorio de la forma no puede ocupar la fila. Entre los que las tienen manda
 * la modalidad, que es lo que dice cuál esperar, y el desempate es el orden de la notación para
 * que la misma forma se dibuje siempre igual.
 */
export function ordenarDisposiciones(esquemas: EsquemaRimaEntrada[]): EsquemaRimaEntrada[] {
	return esquemas
		.filter((esquema) => esquema.posiciones.length > 0)
		.sort(compararPorModalidadYNombre);
}

export function esquemaRimaPrincipal(esquemas: EsquemaRimaEntrada[]): EsquemaRimaEntrada | null {
	return ordenarDisposiciones(esquemas)[0] ?? null;
}

/** Un esquema cíclico arrastra rima de una repetición a la siguiente, o lo dice su notación. */
function esCiclico(esquema: EsquemaRimaEntrada | null): boolean {
	if (!esquema) return false;
	if (String(esquema.notacion ?? '').includes(']…')) return true;
	return esquema.enlaces.some((enlace) => enlace.desplazamiento !== 0);
}

function enteroPositivo(valor: number | null | undefined): number | null {
	return typeof valor === 'number' && Number.isInteger(valor) && valor > 0 ? valor : null;
}

/** «×6», «×3 o más», «×de 0 a 1». Nulo cuando la parte aparece una sola vez. */
function etiquetaDeRepeticiones(seccion: SeccionEntrada): string | null {
	const min = seccion.repeticionesMin;
	const max = seccion.repeticionesMax;
	if (min === null && max === null) return null;
	if (min === 1 && max === 1) return null;
	if (max === null) return `×${min ?? 0} o más`;
	if (min === max) return `×${min}`;
	return `×de ${min ?? 0} a ${max}`;
}

type Segmento = {
	seccion: SeccionEntrada;
	versos: number;
	/** Repeticiones que el segmento representa sin dibujarlas. */
	repeticiones: string | null;
};

/**
 * El esqueleto de columnas que dibujan las partes.
 *
 * Una parte de extensión fija que se repite se dibuja **una vez** y se rotula con su número de
 * repeticiones, salvo que un esquema de rima abarque varias: los dos cuartetos del soneto riman
 * `ABBA ABBA` y separarlos partiría en dos lo que es una sola disposición. Las partes de
 * extensión variable —el remate de la canción, la copla del villancico— no entran: no se pueden
 * dibujar y decir de ellas un número inventado sería peor que callarlas.
 */
function esqueletoDeSecciones(entrada: EntradaRejilla): Segmento[] {
	const dibujables = entrada.secciones.filter((seccion) => {
		const versos = enteroPositivo(seccion.versosMin);
		if (versos === null || versos !== enteroPositivo(seccion.versosMax)) return false;
		return seccion.repeticionesMin !== null && seccion.repeticionesMin !== 0;
	});

	/** Cuántas apariciones de una parte hay que dibujar para que su rima se lea entera. */
	const exigidasPorLaRima = (seccion: SeccionEntrada, versos: number) => {
		const principal = esquemaRimaPrincipal(
			entrada.rimas.filter((rima) => rima.seccion === seccion.nombre)
		);
		const abarca = principal ? Math.floor(principal.posiciones.length / versos) : 1;
		return abarca > 1 && seccion.repeticionesMax === seccion.repeticionesMin
			? Math.min(abarca, seccion.repeticionesMin ?? 1)
			: 1;
	};

	// Una parte que se repite un número fijo de veces se dibuja **entera si cabe**. Colapsarla
	// siempre dejaba la chamberga en seis columnas cuando su cabecera anuncia diez versos, y su
	// esquema métrico declara las diez. Solo se colapsa cuando expandirlas no cabría en pantalla,
	// como en la sextina, que sumaría treinta y nueve.
	const completo = dibujables.reduce((total, seccion) => {
		const versos = enteroPositivo(seccion.versosMin) ?? 0;
		const fijas =
			seccion.repeticionesMax === seccion.repeticionesMin ? (seccion.repeticionesMin ?? 1) : 1;
		return total + versos * fijas;
	}, 0);
	const expandirTodo = completo > 0 && completo <= MAXIMO_DE_COLUMNAS;

	const segmentos: Segmento[] = [];
	for (const seccion of dibujables) {
		const versos = enteroPositivo(seccion.versosMin) as number;
		const fijas =
			seccion.repeticionesMax === seccion.repeticionesMin ? (seccion.repeticionesMin ?? 1) : 1;
		const vueltas = expandirTodo ? fijas : exigidasPorLaRima(seccion, versos);

		for (let vuelta = 0; vuelta < vueltas; vuelta += 1) {
			segmentos.push({
				seccion,
				versos,
				repeticiones: vueltas > 1 ? null : etiquetaDeRepeticiones(seccion)
			});
		}
	}
	return segmentos;
}

/** Cuántas posiciones distintas declara un esquema métrico. */
function columnasDelMetrico(esquema: EsquemaMetricoEntrada | null): number {
	if (!esquema) return 0;
	return new Set(esquema.posiciones.map((posicion) => posicion.posicion)).size;
}

/**
 * La medida que ocupa una columna.
 *
 * Un esquema en ciclo repite sus posiciones; uno en secuencia las agota; uno en conjunto no fija
 * ninguna, y lo que declara es el repertorio del que la realización elegirá. Varias filas con la
 * misma posición son **alternativas de esa posición**: la seguidilla gitana mide 6-6-(10/11/12)-6
 * y son cuatro versos, no doce.
 */
function medidaDeColumna(
	esquema: EsquemaMetricoEntrada | null,
	indice: number
): MedidaDeCelda | null {
	if (!esquema) return null;
	if (esquema.posiciones.length === 0) {
		const alternativas = [
			...new Set(
				esquema.opciones
					.map((opcion) => opcion.silabas)
					.filter((valor): valor is string => Boolean(valor))
			)
		];
		if (alternativas.length === 0) return null;
		return { silabas: null, alternativas, opcional: false };
	}
	const distintas = [...new Set(esquema.posiciones.map((posicion) => posicion.posicion))].sort(
		(a, b) => a - b
	);
	const buscada = distintas[indice % distintas.length];
	const enLaPosicion = esquema.posiciones.filter((posicion) => posicion.posicion === buscada);
	const alternativas = [
		...new Set(
			enLaPosicion
				.map((posicion) => posicion.silabas)
				.filter((valor): valor is string => Boolean(valor))
		)
	];
	if (alternativas.length === 0) return null;
	return {
		silabas: alternativas.length === 1 ? alternativas[0] : null,
		alternativas: alternativas.length === 1 ? [] : alternativas,
		opcional: enLaPosicion.every((posicion) => posicion.opcional)
	};
}

/**
 * Dos apariciones seguidas de la misma parte son una banda con su cuenta, no dos bandas.
 *
 * El soneto se dibujaba con cuatro rótulos —«Cuartetos», «Cuartetos», «Tercetos», «Tercetos»— y
 * cuatro veces «rima como Cuarteto», que es decir cuatro veces lo mismo. La división entre las dos
 * apariciones sigue viéndose: la marca la disposición, que cambia de letras.
 */
function agruparBandasContiguas(bandas: BandaRejilla[]): BandaRejilla[] {
	const agrupadas: BandaRejilla[] = [];
	for (const banda of bandas) {
		const ultima = agrupadas.at(-1);
		if (ultima && ultima.nombre === banda.nombre && ultima.hasta + 1 === banda.desde) {
			ultima.hasta = banda.hasta;
			ultima.apariciones = (ultima.apariciones ?? 1) + 1;
			continue;
		}
		agrupadas.push({ ...banda, apariciones: 1 });
	}
	return agrupadas;
}

/** Las partes con nombre que el propio esquema de rima declara en sus posiciones. */
function bandasDelEsquema(
	esquema: EsquemaRimaEntrada | null,
	columnas: number
): BandaRejilla[] {
	if (!esquema) return [];
	const posiciones = posicionesOrdenadas(esquema);
	const bandas: BandaRejilla[] = [];
	let inicio = 0;
	for (let indice = 1; indice <= posiciones.length; indice += 1) {
		const actual = indice < posiciones.length ? posiciones[indice].seccion : null;
		const anterior = posiciones[inicio].seccion;
		if (indice === posiciones.length || actual !== anterior) {
			if (anterior && inicio < columnas) {
				bandas.push({
					nombre: String(anterior).replaceAll('_', ' '),
					desde: inicio + 1,
					hasta: Math.min(indice, columnas),
					repeticiones: null,
					reutiliza: null
				});
			}
			inicio = indice;
		}
	}
	return bandas;
}

/**
 * Dibuja una arquitectura. Devuelve `null` cuando no hay nada que dibujar, que es una respuesta
 * legítima y no un fallo: la silva no declara posiciones y fingirle una rejilla sería mentir.
 */
export function construirRejilla(entrada: EntradaRejilla): Rejilla | null {
	const metricoUnidad = entrada.metricos.find((esquema) => !esquema.seccion) ?? null;
	const metricoPorSeccion = new Map(
		entrada.metricos
			.filter((esquema) => esquema.seccion)
			.map((esquema) => [String(esquema.seccion), esquema])
	);
	const rimasDeLaUnidad = entrada.rimas.filter((rima) => !rima.seccion);
	// La primera de la unidad decide el esqueleto —si cicla, si sus posiciones marcan las
	// columnas—, pero se dibujan todas.
	const elegido = esquemaRimaPrincipal(rimasDeLaUnidad);

	// Un esquema cíclico de la unidad manda sobre las partes: el terceto encadenado se entiende
	// por su ciclo `[ABA]…`, no por la suma de la cadena y el serventesio final.
	const esqueleto = esCiclico(elegido) ? [] : esqueletoDeSecciones(entrada);
	const unidadFija =
		entrada.unidadMin !== null && entrada.unidadMin === entrada.unidadMax
			? entrada.unidadMin
			: null;

	let columnas = 0;
	let cicla = false;
	if (esqueleto.length > 0) {
		columnas = esqueleto.reduce((total, segmento) => total + segmento.versos, 0);
		// Una parte final que se repite sin tope convierte el dibujo en un ciclo.
		cicla = esqueleto.some((segmento) => segmento.seccion.repeticionesMax === null);
	} else if (unidadFija !== null) {
		columnas = unidadFija;
	} else if (elegido && elegido.posiciones.length > 0) {
		columnas = elegido.posiciones.length;
		cicla = true;
	} else if (metricoUnidad?.tipoSecuencia === 'secuencia' && columnasDelMetrico(metricoUnidad) > 0) {
		columnas = columnasDelMetrico(metricoUnidad);
	} else if (metricoUnidad?.tipoSecuencia === 'ciclo' && columnasDelMetrico(metricoUnidad) > 1) {
		columnas = columnasDelMetrico(metricoUnidad);
		cicla = true;
	}
	if (columnas <= 0) return null;

	const recortada = columnas > MAXIMO_DE_COLUMNAS;
	const dibujadas = recortada ? MAXIMO_DE_COLUMNAS : columnas;

	// Qué parte ocupa cada columna, para elegir su medida y colocar su rima.
	const bandasDeSeccion: BandaRejilla[] = [];
	const seccionDeColumna: (SeccionEntrada | null)[] = [];
	const indiceEnLaParte: number[] = [];
	if (esqueleto.length > 0 && !recortada) {
		let cursor = 1;
		for (const segmento of esqueleto) {
			for (let posicion = 0; posicion < segmento.versos; posicion += 1) {
				seccionDeColumna.push(segmento.seccion);
				indiceEnLaParte.push(posicion);
			}
			bandasDeSeccion.push({
				nombre: segmento.seccion.nombre,
				desde: cursor,
				hasta: cursor + segmento.versos - 1,
				repeticiones: segmento.repeticiones,
				reutiliza: segmento.seccion.reutiliza
			});
			cursor += segmento.versos;
		}
	} else {
		for (let indice = 0; indice < dibujadas; indice += 1) {
			seccionDeColumna.push(null);
			indiceEnLaParte.push(indice);
		}
	}

	const celdas: CeldaRejilla[] = [];
	for (let indice = 0; indice < dibujadas; indice += 1) {
		const seccion = seccionDeColumna[indice] ?? null;
		const deLaParte = seccion ? metricoPorSeccion.get(seccion.nombre) : undefined;
		const esquemaMetrico = deLaParte ?? metricoUnidad;
		// Un esquema de la parte se cuenta desde el principio de la parte; uno de la unidad, desde
		// el principio de la unidad. Contar siempre desde la parte daba a los pareados de la
		// chamberga las medidas de la cuarteta que los precede.
		const posicion = deLaParte ? (indiceEnLaParte[indice] ?? indice) : indice;
		celdas.push({
			verso: indice + 1,
			medida: medidaDeColumna(esquemaMetrico, posicion)
		});
	}

	/** Una disposición extendida sobre las columnas que le tocan, repitiéndose si es un ciclo. */
	const filaDe = (
		esquema: EsquemaRimaEntrada,
		desde: number,
		hasta: number,
		parte: string | null
	): FilaDeRima | null => {
		const posiciones = posicionesOrdenadas(esquema);
		if (posiciones.length === 0) return null;
		const clases: RimaDeCelda[] = [];
		for (let columna = desde; columna <= hasta; columna += 1) {
			const posicion = posiciones[(columna - desde) % posiciones.length];
			clases.push({
				clase: posicion.clase,
				suelto: posicion.suelto,
				nota: posicion.nota ?? null
			});
		}
		return {
			esquemaRimaId: esquema.id,
			nombre: esquema.nombre,
			notacion: esquema.notacion,
			modalidad: esquema.modalidad,
			parte,
			desde,
			hasta,
			clases
		};
	};

	// Todas las disposiciones, no una. Las de una parte ocupan sus columnas; las de la unidad, la
	// unidad entera y de principio a fin —contarlas desde la primera columna libre daba al
	// estribillo de la seguidilla compuesta las posiciones que le tocan a su cuerpo—.
	const filasDeRima: FilaDeRima[] = [];
	for (const nombre of new Set(bandasDeSeccion.map((banda) => banda.nombre))) {
		const iguales = bandasDeSeccion.filter((banda) => banda.nombre === nombre);
		const desde = iguales[0].desde;
		const hasta = iguales[iguales.length - 1].hasta;
		for (const esquema of ordenarDisposiciones(
			entrada.rimas.filter((rima) => rima.seccion === nombre)
		)) {
			const fila = filaDe(esquema, desde, hasta, nombre);
			if (fila) filasDeRima.push(fila);
		}
	}
	for (const esquema of ordenarDisposiciones(rimasDeLaUnidad)) {
		const fila = filaDe(esquema, 1, dibujadas, null);
		if (fila) filasDeRima.push(fila);
	}

	// Cuando las partes no subdividen lo dibujado, mandan las del propio esquema: la fronte, el
	// eslabón y la sirima no son secciones del catálogo, son partes de la estancia.
	const interiores = bandasDelEsquema(
		elegido ??
			esquemaRimaPrincipal(
				entrada.rimas.filter((rima) => rima.seccion === bandasDeSeccion[0]?.nombre)
			),
		dibujadas
	);
	const bandas =
		bandasDeSeccion.length > 1 ? agruparBandasContiguas(bandasDeSeccion) : interiores;
	const unica = bandasDeSeccion.length === 1 ? bandasDeSeccion[0] : null;

	const enlaces: EnlaceRejilla[] = (elegido?.enlaces ?? []).map((enlace) => ({
		desde: enlace.desde,
		hasta: enlace.hasta,
		sentido:
			enlace.desplazamiento > 0 ? 'adelante' : enlace.desplazamiento < 0 ? 'atras' : 'interior',
		nota: enlace.nota
	}));

	const tieneMedida = celdas.some((celda) => celda.medida !== null);
	const tieneRima = filasDeRima.length > 0;
	if (!tieneMedida && !tieneRima) return null;

	return {
		celdas,
		filasDeRima,
		bandas,
		enlaces,
		cicla,
		recortada,
		tieneMedida,
		tieneRima,
		parte: unica ? unica.nombre : null,
		repeticionesDeLaParte: unica ? unica.repeticiones : null
	};
}

/**
 * Los siete perfiles de ficha.
 *
 * No se escriben en el catálogo: se derivan, igual que el editor V2 deriva sus filas. Un cambio
 * en el modelo cambia el perfil sin tocar esta lista.
 */
export const PERFILES_DE_ARQUITECTURA = [
	'estrofa_elegible',
	'serie_ciclica',
	'estrofa_compuesta',
	'estancias_declaradas',
	'composicion_con_estribillo',
	'serie_abierta',
	'combinatoria'
] as const;

export type PerfilDeArquitectura = (typeof PERFILES_DE_ARQUITECTURA)[number];

export type EntradaPerfil = EntradaRejilla & {
	/** La arquitectura ofrece variedades que emparejan una medida con una rima. */
	variedades: number;
	/** Declara una repetición de estribillo: la composición se lee por ciclos. */
	tieneCicloDeEstribillo: boolean;
};

export function perfilDeArquitectura(entrada: EntradaPerfil): PerfilDeArquitectura {
	if (entrada.variedades > 0) return 'combinatoria';
	if (entrada.tieneCicloDeEstribillo) return 'composicion_con_estribillo';
	// Una parte que se repite tres veces o más sin tope es una estancia: la primera declara y las
	// demás repiten. Es lo que separa la canción de una estrofa que se repite sin más.
	const estancias = entrada.secciones.some(
		(seccion) => (seccion.repeticionesMin ?? 0) >= 2 && seccion.repeticionesMax === null
	);
	if (estancias) return 'estancias_declaradas';
	const rejilla = construirRejilla(entrada);
	if (!rejilla) return 'serie_abierta';
	if (rejilla.cicla) return 'serie_ciclica';
	if (rejilla.bandas.some((banda) => banda.reutiliza !== null) || entrada.secciones.length > 1) {
		return 'estrofa_compuesta';
	}
	return 'estrofa_elegible';
}

export function etiquetaDePerfil(perfil: PerfilDeArquitectura): string {
	if (perfil === 'estrofa_elegible') return 'Estrofa de disposición elegible';
	if (perfil === 'serie_ciclica') return 'Serie con ciclo';
	if (perfil === 'estrofa_compuesta') return 'Estrofa compuesta de partes';
	if (perfil === 'estancias_declaradas') return 'Estancias que se declaran';
	if (perfil === 'composicion_con_estribillo') return 'Composición con ciclo de estribillo';
	if (perfil === 'serie_abierta') return 'Serie de medida o rima abiertas';
	return 'Combinatoria de variedades';
}

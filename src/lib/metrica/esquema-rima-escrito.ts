/**
 * El esquema de rima que el editor escribe cuando el catálogo no lo tiene.
 *
 * Donde la norma deja la disposición abierta o acotada, el editor tiene que poder **declarar el
 * esquema que ha visto**, y no solo elegir entre los catalogados. Este módulo es lo que hace que esa
 * respuesta sirva para algo más que para leerla: la valida, la normaliza y, si resulta ser una que
 * el catálogo ya tenía, dice cuál —para que se guarde como esa y no como texto suelto—.
 *
 * Es la regla 3 de [criterios de nivel § 3.3](../../../docs/dominio-metrico/criterios-de-nivel.md),
 * y no es un detalle de interfaz. Sin ella cada esquema tecleado es un dato huérfano y «cuántas
 * disposiciones distintas usa este autor» significa una cosa donde el editor eligió de una lista y
 * otra donde escribió. Hasta el 25 de agosto de 2026 el único control abierto del catálogo era un
 * campo de texto de 240 caracteres sin ninguna validación, de modo que `ABBACC` escrito y `abbacc`
 * elegido eran dos observaciones distintas del mismo hecho.
 *
 * **Dos cosas que el catálogo obliga a respetar y que no son obvias.**
 *
 * La primera: la caja marca el arte del verso, **no una clase distinta**. `C` y `c` son la misma
 * rima sobre un endecasílabo y sobre un heptasílabo, y así rima la lira `aBabB`, cuyo cuarto verso
 * comparte clase con el segundo y el quinto. De ahí que la identidad de clase se calcule sin
 * distinguir caja y que la caja se conserve posición a posición.
 *
 * La segunda: dos esquemas pueden compartir notación y ser distintos. La octava aguda tiene
 * `---a---a` consonante y `---a---a` asonante, y al terceto le pasa igual con su `aaa` monorrimo.
 * Por eso se casa por **notación y régimen**, nunca por notación sola (regla 3 bis).
 */

/** Un esquema del catálogo, tal como se ofrece para casarlo con lo escrito. */
export type EsquemaCatalogado = {
	esquemaRimaId: string;
	notacion: string | null;
	/** El régimen del esquema, o el de su arquitectura cuando el esquema no lo declara. */
	regimen: string | null;
};

/** Una restricción declarada por el patrón abierto de la arquitectura. */
export type RestriccionRima = {
	tipo: string;
	valorNumero: number | null;
	valorTexto: string | null;
};

export type LecturaEsquemaEscrito =
	| { estado: 'vacio' }
	| { estado: 'error'; mensaje: string }
	| {
			estado: 'ok';
			/** La notación normalizada: clases en orden de primera aparición, caja conservada. */
			canonica: string;
			/** El régimen con el que se ha leído, venga de lo escrito o de la arquitectura. */
			regimen: string | null;
			posiciones: number;
			clases: number;
			sueltos: number;
			/** El esquema del catálogo que resulta ser, si lo es. */
			esquemaCatalogadoId: string | null;
			/** Lo que rompe la norma declarada. No impide guardar: para eso están las desviaciones. */
			avisos: string[];
	  };

/**
 * Los separadores que la notación del catálogo usa para marcar la articulación —`abab|cdcd`,
 * `ABBA:ACAC`, `ABBA ABBA`—. Se admiten al escribir porque un editor los usa sin pensarlo, y se
 * quitan para comparar: la articulación ya la dicen las secciones.
 */
const SEPARADORES = /[\s:|]/g;

/** Un ciclo se escribe `[…]…` y describe una serie, que no tiene unidad y no se pregunta así. */
function esCiclo(notacion: string): boolean {
	return notacion.includes('[') || notacion.includes('…');
}

/**
 * Cómo se guarda un esquema escrito cuando el catálogo no lo tiene: `abcabc · asonante`.
 *
 * **Un esquema escrito no está completo sin su régimen** (regla 3 bis del § 3.3), y la respuesta
 * viaja en un solo campo de texto. El punto medio sirve de separador porque **no pertenece al
 * alfabeto de la notación** —que admite letras, guion, y los separadores `:`, `|`, espacio y
 * corchetes—, de modo que nunca puede confundirse con parte del esquema.
 *
 * Donde el régimen no varía dentro de la arquitectura no se pregunta ni se guarda: se hereda, y
 * añadirlo sería repetir lo que la ficha ya dice.
 */
export const SEPARADOR_REGIMEN = ' · ';

export function separarRegimen(texto: string): { notacion: string; regimen: string | null } {
	const corte = texto.indexOf('·');
	if (corte < 0) return { notacion: texto.trim(), regimen: null };
	const regimen = texto.slice(corte + 1).trim();
	return { notacion: texto.slice(0, corte).trim(), regimen: regimen || null };
}

export function componerEsquemaEscrito(notacion: string, regimen: string | null): string {
	const limpio = notacion.trim();
	if (!limpio || !regimen) return limpio;
	return `${limpio}${SEPARADOR_REGIMEN}${regimen}`;
}

function limpiar(texto: string): string {
	return texto.replace(SEPARADORES, '');
}

/**
 * La forma canónica: mismas posiciones, clases renombradas en orden de primera aparición.
 *
 * `BABA` y `ABAB` son la misma disposición escrita con otras letras, y sin esto contarían como dos.
 */
function canonizar(limpio: string): string {
	const nombres = new Map<string, string>();
	let siguiente = 0;
	let salida = '';
	for (const caracter of limpio) {
		if (caracter === '-') {
			salida += '-';
			continue;
		}
		const clave = caracter.toLowerCase();
		let nombre = nombres.get(clave);
		if (!nombre) {
			nombre = String.fromCharCode(97 + siguiente);
			nombres.set(clave, nombre);
			siguiente += 1;
		}
		// La caja es del verso, no de la clase: se conserva la que se escribió.
		salida += caracter === clave ? nombre : nombre.toUpperCase();
	}
	return salida;
}

/** Una posición de un esquema, venga de una notación escrita o de las filas del catálogo. */
export type PosicionMedible = {
	/** La clase de rima. Vacía o nula si el verso va suelto. */
	clase: string | null;
	suelto?: boolean;
};

export type MedidaDisposicion = {
	clases: number;
	sueltos: number;
	/** La racha más larga de versos seguidos con la misma rima. */
	maxConsecutivos: number;
	alternancias: number;
};

/**
 * Lo que se puede contar de una disposición, y que las restricciones del catálogo contrastan.
 *
 * Vive aquí y no en el auditor porque **son la misma cuenta**: la que valida lo que un editor
 * escribe y la que comprueba que un esquema catalogado cumple el criterio de su patrón abierto. Con
 * dos implementaciones, un día dirían cosas distintas del mismo verso.
 *
 * Dos reglas que no son obvias y que las dos usan. **La clase no distingue caja**, porque `C` y `c`
 * son la misma rima sobre un endecasílabo y sobre un heptasílabo. Y **un verso suelto corta la
 * racha** en vez de continuarla: no pertenece a ninguna clase, así que dos sueltos seguidos no son
 * dos versos que rimen entre sí.
 */
export function medirDisposicion(posiciones: PosicionMedible[]): MedidaDisposicion {
	const clases = new Set<string>();
	let sueltos = 0;
	let maxConsecutivos = 0;
	let corrida = 0;
	let anterior = '';
	let alternancias = 0;
	for (const posicion of posiciones) {
		const clave = posicion.suelto ? '' : (posicion.clase ?? '').toLowerCase();
		if (!clave) {
			sueltos += 1;
			corrida = 0;
			anterior = '';
			continue;
		}
		clases.add(clave);
		if (clave === anterior) {
			corrida += 1;
		} else {
			if (anterior !== '') alternancias += 1;
			corrida = 1;
		}
		anterior = clave;
		if (corrida > maxConsecutivos) maxConsecutivos = corrida;
	}
	return { clases: clases.size, sueltos, maxConsecutivos, alternancias };
}

function medir(limpio: string): MedidaDisposicion {
	return medirDisposicion(
		[...limpio].map((caracter) => ({ clase: caracter === '-' ? null : caracter }))
	);
}

/** Lo que la norma declara y lo escrito no cumple. Se avisa, no se bloquea. */
function comprobarRestricciones(
	restricciones: RestriccionRima[],
	medida: ReturnType<typeof medir>
): string[] {
	const avisos: string[] = [];
	for (const restriccion of restricciones) {
		if (restriccion.tipo === 'numero_clases' && restriccion.valorNumero !== null) {
			if (medida.clases !== restriccion.valorNumero) {
				avisos.push(
					`La norma declara ${restriccion.valorNumero} clases de rima y se han escrito ${medida.clases}.`
				);
			}
		}
		if (restriccion.tipo === 'max_consecutivos' && restriccion.valorNumero !== null) {
			if (medida.maxConsecutivos > restriccion.valorNumero) {
				avisos.push(
					`La norma no admite más de ${restriccion.valorNumero} versos seguidos con la misma rima, y se han escrito ${medida.maxConsecutivos}.`
				);
			}
		}
		if (restriccion.tipo === 'min_alternancias' && restriccion.valorNumero !== null) {
			if (medida.alternancias < restriccion.valorNumero) {
				avisos.push(
					`La norma pide al menos ${restriccion.valorNumero} alternancias de rima y se han escrito ${medida.alternancias}.`
				);
			}
		}
		if (restriccion.tipo === 'versos_sueltos' && restriccion.valorTexto === 'ninguno') {
			if (medida.sueltos > 0) {
				avisos.push('La norma no admite versos sueltos, y se ha escrito alguno.');
			}
		}
	}
	return avisos;
}

export type OpcionesLectura = {
	/** La extensión de la unidad, cuando se conoce. Lo escrito tiene que medir exactamente eso. */
	versos?: number | null;
	/** El régimen que se declara junto a la notación, o el de la arquitectura si es único. */
	regimen?: string | null;
	/** Los esquemas que el catálogo ya tiene para esta arquitectura o sección. */
	catalogados?: EsquemaCatalogado[];
	/** Las restricciones del patrón abierto de la arquitectura. */
	restricciones?: RestriccionRima[];
};

export function leerEsquemaEscrito(
	texto: string | null | undefined,
	opciones: OpcionesLectura = {}
): LecturaEsquemaEscrito {
	const crudo = (texto ?? '').trim();
	if (!crudo) return { estado: 'vacio' };

	// Lo escrito puede traer ya su régimen —`abcabc · asonante`—, y entonces manda sobre el que
	// llegue por opciones: es el que el editor ha marcado junto a la notación.
	const separado = separarRegimen(crudo);
	const bruto = separado.notacion;
	if (!bruto) {
		return { estado: 'error', mensaje: 'Falta la disposición: se ha escrito solo el régimen.' };
	}

	if (esCiclo(bruto)) {
		return {
			estado: 'error',
			mensaje:
				'Un esquema entre corchetes describe un ciclo, que es de una serie y no de una unidad. Escribe la rima de una sola unidad.'
		};
	}

	const limpio = limpiar(bruto);
	if (!limpio) {
		return { estado: 'error', mensaje: 'No se ha escrito ninguna posición.' };
	}
	const invalido = [...limpio].find((caracter) => !/[A-Za-z-]/.test(caracter));
	if (invalido) {
		return {
			estado: 'error',
			mensaje: `«${invalido}» no vale. Escribe una letra por verso para cada rima y un guion para el verso suelto.`
		};
	}

	const versos = opciones.versos ?? null;
	if (typeof versos === 'number' && versos > 0 && limpio.length !== versos) {
		return {
			estado: 'error',
			mensaje: `La unidad tiene ${versos} ${versos === 1 ? 'verso' : 'versos'} y se han escrito ${limpio.length}.`
		};
	}

	const canonica = canonizar(limpio);
	const medida = medir(limpio);
	const regimen = separado.regimen ?? opciones.regimen ?? null;

	// Notación **y** régimen: la octava aguda tiene dos esquemas con la misma notación.
	const mismaNotacion = (opciones.catalogados ?? []).filter((candidato) => {
		if (!candidato.notacion || esCiclo(candidato.notacion)) return false;
		return canonizar(limpiar(candidato.notacion)) === canonica;
	});
	const candidatos = regimen
		? mismaNotacion.filter((candidato) => !candidato.regimen || candidato.regimen === regimen)
		: mismaNotacion;

	const avisos = comprobarRestricciones(opciones.restricciones ?? [], medida);

	// Dos disposiciones catalogadas con la misma notación solo se separan por el régimen. Sin
	// saberlo, **no se elige ninguna**: adivinar guardaría la mitad de las veces la que no es, y
	// el editor tiene la lista delante para decirlo él.
	if (candidatos.length > 1) {
		avisos.push(
			'El catálogo tiene más de una disposición con esta notación, y se distinguen por el régimen de rima. Elígela en la lista.'
		);
	}

	return {
		estado: 'ok',
		canonica,
		regimen,
		posiciones: limpio.length,
		clases: medida.clases,
		sueltos: medida.sueltos,
		esquemaCatalogadoId: candidatos.length === 1 ? candidatos[0].esquemaRimaId : null,
		avisos
	};
}

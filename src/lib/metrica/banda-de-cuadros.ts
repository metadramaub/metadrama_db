/**
 * Dónde cae cada cambio de cuadro dentro de una fila, y en qué proporción de ella.
 *
 * **El corte no cae en el límite de una fila.** El tablado se vacía muchas veces en mitad de una
 * tirada —en las comedias de Lope que se leyeron a mano pasa en tres de cada diez cambios de
 * cuadro—, y hasta ahora las dos superficies que lo enseñan lo contaban como si cayera entre dos
 * filas: la sinopsis distinguía «divisor» de «arrastre» según dónde acabara la tarjeta anterior, y
 * el esquema métrico ponía la etiqueta sobre la fila siguiente con un aviso. Las dos mentían.
 *
 * Lo que se devuelve aquí es la **banda de una sola fila**, partida en tramos con su proporción.
 * Fuera de la fila partida no hay escala de versos y no debe haberla: una lista no es un gráfico, y
 * una fila con sinopsis larga mide el triple que una vacía. La proporción solo se usa **dentro de
 * la fila que el corte parte**, que es la única donde significa algo, y se pinta como porcentaje de
 * la altura de esa fila: lo resuelve el navegador sin medir nada.
 */

/** Un cuadro con el rango de versos que ocupa. */
export interface CuadroRango {
	numero: number;
	v_ini: number;
	v_fin: number;
}

/** Un tramo de la banda de una fila. */
export interface TramoDeBanda {
	/** El cuadro de este tramo, o `null` si el pasaje no cae en ninguno. */
	numero: number | null;
	/** Dónde empieza dentro de la fila, de 0 a 1. */
	desde: number;
	/** Cuánto ocupa de la fila, de 0 a 1. */
	alto: number;
	/** Si el cuadro **empieza aquí**, y por tanto es donde va su número. */
	abre: boolean;
	/** El verso en que abre, para poder decirlo con palabras. */
	verso: number | null;
}

/**
 * La banda de una fila que va del verso `v_ini` al `v_fin`.
 *
 * Devuelve siempre al menos un tramo. Cuando ningún cuadro empieza dentro, es uno solo que ocupa
 * la fila entera; cuando alguno empieza dentro, tantos como cortes haya más uno.
 */
export function bandaDeCuadros(
	v_ini: number,
	v_fin: number,
	cuadros: CuadroRango[]
): TramoDeBanda[] {
	const versos = v_fin - v_ini + 1;
	if (versos <= 0) return [];

	const ordenados = [...cuadros].sort((a, b) => a.v_ini - b.v_ini);
	const alEmpezar = ordenados.find((c) => v_ini >= c.v_ini && v_ini <= c.v_fin) ?? null;

	// Los que abren **dentro** de la fila: en su primer verso no, que eso es un arranque limpio.
	const dentro = ordenados.filter((c) => c.v_ini > v_ini && c.v_ini <= v_fin);

	const tramos: TramoDeBanda[] = [
		{
			numero: alEmpezar?.numero ?? null,
			desde: 0,
			alto: 1,
			// Abre aquí si la fila empieza justo donde empieza el cuadro.
			abre: alEmpezar ? alEmpezar.v_ini === v_ini : false,
			verso: alEmpezar?.v_ini ?? null
		}
	];

	for (const cuadro of dentro) {
		const desde = (cuadro.v_ini - v_ini) / versos;
		const anterior = tramos[tramos.length - 1];
		anterior.alto = desde - anterior.desde;
		tramos.push({ numero: cuadro.numero, desde, alto: 1 - desde, abre: true, verso: cuadro.v_ini });
	}

	return tramos;
}

/**
 * Si el cuadro en que arranca esta fila venía ya de la fila anterior.
 *
 * Sirve para no repetir el número en cada fila de un cuadro largo: se escribe una vez, donde abre.
 */
export const vieneDeAntes = (tramos: TramoDeBanda[]) => tramos.length > 0 && !tramos[0].abre;

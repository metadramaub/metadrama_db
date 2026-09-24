/**
 * El sistema visual de los gráficos, en valores literales.
 *
 * **Literales y no variables CSS** porque un gráfico se descarga. Fuera de la página no hay
 * `var(--gray-600)` que resolver, y el exportador anterior se pasaba la vida copiando estilos
 * calculados de una lista de propiedades que nunca estaba completa. Aquí los colores y cuerpos
 * de letra van como atributos del SVG, y el mismo SVG sirve en pantalla y en el archivo.
 *
 * Los grises son los de `app.css`, con el nombre de su función y no el de su escala: un gráfico
 * pide «el color de una guía», no «el gris 200».
 */

export const TINTA = {
	/** --gray-900: rótulos y cifras que hay que leer. */
	texto: '#1a1a1a',
	/** --gray-600 (--muted-foreground): referencias de eje, momentos, cifras secundarias. */
	secundario: '#535353',
	/** --gray-500: el sello y lo que acompaña sin pedir atención. */
	tenue: '#808080',
	/** --gray-200 (--border): guías de fondo. */
	guia: '#e6e6e6',
	/** --gray-100: el fondo de una pista vacía. */
	pista: '#f5f5f5',
	/** --gray-800: cortes de jornada. */
	corte: '#272727',
	/** El papel. */
	fondo: '#ffffff',
	/** Sin forma conocida. */
	neutro: '#9ca3af'
} as const;

/** Cuerpos de letra, en unidades del `viewBox`. */
export const CUERPO = {
	rotulo: 13,
	referencia: 12,
	menor: 11,
	sello: 10
} as const;

/** Nombre con el que la figura descargada declara la Inter que lleva dentro. */
export const FAMILIA_FIGURA = 'Inter Figura';

/** Lo que pide la figura descargada: la suya primero, y lo que haya si un programa no la lee. */
export const FAMILIA_TEXTO = `'${FAMILIA_FIGURA}', Inter, 'Helvetica Neue', Helvetica, Arial, sans-serif`;

/** Lo que dice el sello que llevan dentro todos los gráficos descargados. */
export const SELLO = 'versologia.metadrama.org';

/**
 * Escala de grises para imprimir en blanco y negro, de oscuro a claro.
 *
 * Cinco pasos y no más: en papel, dos grises más cercanos que esto ya no se distinguen.
 */
export const GRISES = ['#1a1a1a', '#535353', '#808080', '#a3a3a3', '#d3d3d3'] as const;

/**
 * Trazos que acompañan al gris cuando las líneas son más que cinco. Con el gris solo, la sexta
 * línea repetiría la primera; con gris y trazo hay quince combinaciones distintas.
 */
export const TRAZOS = ['', '7 4', '2 3'] as const;

/** Gris y trazo de la serie `indice` en un gráfico de líneas en blanco y negro. */
export function trazoEnGrises(indice: number): { color: string; trazo: string } {
	const tonos = GRISES.slice(0, 3);
	return {
		color: tonos[indice % tonos.length],
		trazo: TRAZOS[Math.floor(indice / tonos.length) % TRAZOS.length]
	};
}

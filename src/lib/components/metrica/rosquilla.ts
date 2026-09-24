/**
 * Los ángulos de una rosquilla, con un mínimo por sector.
 *
 * **Un sector nunca baja de dos grados.** Una forma de cinco versos en una obra de tres mil ocupa
 * medio grado, y con el filete blanco entre sectores desaparece: el gráfico diría que no está.
 * Es lo que hacía ECharts con `minAngle`, y se conserva al pasar a d3. Lo que se da a los pequeños
 * sale de los demás en proporción, así que el gráfico miente un poco en los pequeños y nada en el
 * orden: por eso la cifra exacta va siempre al lado, en la leyenda.
 *
 * Los ángulos van en radianes desde las doce y en el sentido del reloj, que es como los espera
 * `d3-shape`.
 */
export type Sector = { inicio: number; fin: number };

const VUELTA = Math.PI * 2;
export const ANGULO_MINIMO = (2 * Math.PI) / 180;

export function sectoresDeRosquilla(valores: number[], minimo = ANGULO_MINIMO): Sector[] {
	const positivos = valores.map((valor) => Math.max(0, valor));
	const total = positivos.reduce((suma, valor) => suma + valor, 0);
	if (total <= 0) return valores.map(() => ({ inicio: 0, fin: 0 }));

	// Si no caben todos al mínimo, el mínimo no se puede cumplir: se reparte en proporción.
	const conValor = positivos.filter((valor) => valor > 0).length;
	const minimoPosible = conValor * minimo <= VUELTA ? minimo : 0;

	// Subir uno al mínimo encoge a los demás, y alguno puede quedar por debajo: se repite hasta
	// que el conjunto de los subidos no cambia. Converge porque ese conjunto solo crece.
	const subidos = new Set<number>();
	for (let vuelta = 0; vuelta < positivos.length; vuelta += 1) {
		const reservado = subidos.size * minimoPosible;
		const resto = positivos.reduce((suma, valor, i) => (subidos.has(i) ? suma : suma + valor), 0);
		let cambia = false;
		positivos.forEach((valor, i) => {
			if (valor <= 0 || subidos.has(i)) return;
			if ((valor / resto) * (VUELTA - reservado) < minimoPosible) {
				subidos.add(i);
				cambia = true;
			}
		});
		if (!cambia) break;
	}

	const reservado = subidos.size * minimoPosible;
	const resto = positivos.reduce((suma, valor, i) => (subidos.has(i) ? suma : suma + valor), 0);
	let angulo = 0;
	return positivos.map((valor, i) => {
		const amplitud =
			valor <= 0 ? 0 : subidos.has(i) ? minimoPosible : (valor / resto) * (VUELTA - reservado);
		const sector = { inicio: angulo, fin: angulo + amplitud };
		angulo += amplitud;
		return sector;
	});
}

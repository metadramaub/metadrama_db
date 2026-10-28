import {
	structuralAdditionCount,
	type MetricDeviationRange
} from '$lib/metrica/structural-additions';

/** El número escrito es el primer verso de la nueva secuencia, no la longitud ni el último anterior. */
export function proponerDivision(
	inicio: number,
	fin: number,
	desde: number,
	desviaciones: MetricDeviationRange[] = [],
	remate = 0
) {
	if (!Number.isInteger(desde) || desde <= inicio || desde > fin)
		throw new Error(`La nueva secuencia debe empezar entre los versos ${inicio + 1} y ${fin}.`);
	if (desviaciones.some((d) => d.v_ini < desde && d.v_fin >= desde))
		throw new Error('El corte atraviesa una desviación. Elige otro verso de inicio.');
	if (remate > fin - desde + 1)
		throw new Error('El corte atraviesa el remate. La nueva secuencia debe conservarlo entero.');
	if (remate > 0 && remate === fin - desde + 1)
		throw new Error(
			'El remate pertenece al cuerpo de la secuencia: no se separa como otra secuencia. Revisa primero el dato de remate si esos versos pertenecen a otra forma.'
		);
	return { anterior: { v_ini: inicio, v_fin: desde - 1 }, nueva: { v_ini: desde, v_fin: fin } };
}

export function resumenCuerpo(
	inicio: number,
	fin: number,
	remate: number,
	desviaciones: MetricDeviationRange[] = []
) {
	const total = fin - inicio + 1;
	const adicionales = structuralAdditionCount(inicio, fin, desviaciones);
	return { total, remate, adicionales, cuerpo: total - remate - adicionales };
}

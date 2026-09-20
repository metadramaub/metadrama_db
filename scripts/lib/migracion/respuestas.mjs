/**
 * El Excel que el editor devuelve, leído por sus claves.
 *
 * **La clave manda y el texto no se mira.** Cada fila que se rellena lleva en su última columna la
 * clave que escribió el generador (`scripts/lib/migracion/modelo.mjs`), y es por ahí por donde el
 * aplicador sabe de qué secuencia y de qué pregunta habla. Las demás columnas son para la persona;
 * de ellas solo se leen las tres de fondo amarillo, que son las que se rellenan.
 *
 * Lo que aquí se hace es leer, no interpretar: se devuelve el texto tal cual, con los espacios
 * quitados. Quién sabe qué significa «Sí, es un mismo pasaje» es el aplicador.
 */

import ExcelJS from 'exceljs';

/** Las columnas que se rellenan en cada pestaña, y con qué nombre las conoce el aplicador. */
const COLUMNAS = {
	Responder: {
		Respuesta: 'respuesta',
		'Excepciones / detalle': 'detalle',
		Comentario: 'comentario'
	},
	Confirmar: { '¿Correcto?': 'respuesta', Corrección: 'detalle', Comentario: 'comentario' },
	Desviaciones: { Sílabas: 'silabas', '¿Correcto?': 'respuesta', Comentario: 'comentario' }
};

/** El texto de una celda, venga como venga: ExcelJS devuelve objetos para fórmulas y texto rico. */
function texto(celda) {
	const valor = celda?.value;
	if (valor === null || valor === undefined) return '';
	if (typeof valor === 'object') {
		if (Array.isArray(valor.richText))
			return valor.richText
				.map((t) => t.text)
				.join('')
				.trim();
		if ('text' in valor) return String(valor.text).trim();
		if ('result' in valor) return String(valor.result ?? '').trim();
		return '';
	}
	return String(valor).trim();
}

/**
 * Las respuestas de un Excel devuelto, por clave.
 *
 * Devuelve un mapa `clave -> { hoja, fila, respuesta, detalle, comentario, silabas }`. Una fila sin
 * clave se ignora —es una que el editor añadió— y una clave repetida se avisa: dos respuestas a la
 * misma pregunta no se resuelven adivinando.
 */
export async function leerRespuestas(ruta) {
	const libro = new ExcelJS.Workbook();
	await libro.xlsx.readFile(ruta);

	const porClave = new Map();
	const avisos = [];

	for (const [nombreHoja, columnas] of Object.entries(COLUMNAS)) {
		const hoja = libro.getWorksheet(nombreHoja);
		if (!hoja) {
			avisos.push(`El Excel no tiene la pestaña «${nombreHoja}».`);
			continue;
		}
		const cabecera = hoja.getRow(1);
		const indices = new Map();
		let columnaClave = null;
		cabecera.eachCell((celda, indice) => {
			const titulo = texto(celda);
			if (titulo === 'Clave') columnaClave = indice;
			if (columnas[titulo]) indices.set(columnas[titulo], indice);
		});
		if (!columnaClave) {
			avisos.push(`La pestaña «${nombreHoja}» no tiene columna «Clave»: no se puede leer.`);
			continue;
		}

		hoja.eachRow((fila, numero) => {
			if (numero === 1) return;
			const clave = texto(fila.getCell(columnaClave));
			if (!clave) return;
			const leida = { hoja: nombreHoja, fila: numero, clave };
			for (const [nombre, indice] of indices) leida[nombre] = texto(fila.getCell(indice));
			if (porClave.has(clave)) {
				avisos.push(
					`La clave ${clave} aparece dos veces (${nombreHoja}, filas ` +
						`${porClave.get(clave).fila} y ${numero}): se queda la primera.`
				);
				return;
			}
			porClave.set(clave, leida);
		});
	}

	return { respuestas: porClave, avisos };
}

/** Si una fila está en blanco: ni respuesta, ni detalle, ni sílabas. */
export function estaEnBlanco(fila) {
	if (!fila) return true;
	return !fila.respuesta && !fila.detalle && !fila.silabas;
}

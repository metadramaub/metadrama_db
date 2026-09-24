/**
 * Metadatos dentro de un PNG: la cita, la licencia y la resolución de impresión.
 *
 * El canvas no deja escribir nada de esto, así que se hace a mano sobre los bytes que devuelve:
 * un PNG es una firma y una serie de trozos (`chunks`), y basta con meter los nuestros detrás de
 * la cabecera. Van como `iTXt`, que es el trozo de texto que admite UTF-8 —en `tEXt`, «Versología»
 * perdería la tilde—, y el XMP con la clave que leen los gestores de imágenes.
 */

const FIRMA = [137, 80, 78, 71, 13, 10, 26, 10];

const TABLA_CRC = (() => {
	const tabla = new Uint32Array(256);
	for (let n = 0; n < 256; n += 1) {
		let c = n;
		for (let k = 0; k < 8; k += 1) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
		tabla[n] = c >>> 0;
	}
	return tabla;
})();

export function crc32(bytes: Uint8Array): number {
	let c = 0xffffffff;
	for (const byte of bytes) c = TABLA_CRC[(c ^ byte) & 0xff] ^ (c >>> 8);
	return (c ^ 0xffffffff) >>> 0;
}

const latin1 = (texto: string) => Uint8Array.from(texto, (caracter) => caracter.charCodeAt(0));

function trozo(tipo: string, datos: Uint8Array): Uint8Array {
	const salida = new Uint8Array(12 + datos.length);
	const vista = new DataView(salida.buffer);
	vista.setUint32(0, datos.length);
	salida.set(latin1(tipo), 4);
	salida.set(datos, 8);
	vista.setUint32(8 + datos.length, crc32(salida.subarray(4, 8 + datos.length)));
	return salida;
}

/** Un `iTXt` sin comprimir: clave, dos ceros de compresión, idioma y clave traducida vacíos. */
function trozoDeTexto(clave: string, texto: string): Uint8Array {
	const cuerpo = new TextEncoder().encode(texto);
	const cabecera = latin1(clave);
	const datos = new Uint8Array(cabecera.length + 5 + cuerpo.length);
	datos.set(cabecera, 0);
	// Tras la clave: su cero, bandera de compresión, método, idioma vacío y clave traducida vacía.
	datos.set(cuerpo, cabecera.length + 5);
	return trozo('iTXt', datos);
}

/** Resolución en píxeles por metro, que es como la guarda el PNG. */
function trozoDeResolucion(ppp: number): Uint8Array {
	const porMetro = Math.round(ppp / 0.0254);
	const datos = new Uint8Array(9);
	const vista = new DataView(datos.buffer);
	vista.setUint32(0, porMetro);
	vista.setUint32(4, porMetro);
	datos[8] = 1;
	return trozo('pHYs', datos);
}

export type TrozoPng = { tipo: string; datos: Uint8Array };

/** Los trozos de un PNG, en orden. Lanza si no es un PNG. */
export function leerTrozos(png: Uint8Array): TrozoPng[] {
	if (!FIRMA.every((byte, indice) => png[indice] === byte)) {
		throw new Error('No es un PNG.');
	}
	const vista = new DataView(png.buffer, png.byteOffset, png.byteLength);
	const trozos: TrozoPng[] = [];
	let posicion = FIRMA.length;
	while (posicion < png.length) {
		const largo = vista.getUint32(posicion);
		const tipo = String.fromCharCode(...png.subarray(posicion + 4, posicion + 8));
		trozos.push({ tipo, datos: png.subarray(posicion + 8, posicion + 8 + largo) });
		posicion += 12 + largo;
	}
	return trozos;
}

/** Lee los `iTXt` sin comprimir de un PNG. Para las pruebas y para quien quiera comprobarlo. */
export function leerTextos(png: Uint8Array): Record<string, string> {
	const textos: Record<string, string> = {};
	for (const { tipo, datos } of leerTrozos(png)) {
		if (tipo !== 'iTXt') continue;
		const finClave = datos.indexOf(0);
		const clave = String.fromCharCode(...datos.subarray(0, finClave));
		let posicion = finClave + 3;
		posicion = datos.indexOf(0, posicion) + 1; // idioma
		posicion = datos.indexOf(0, posicion) + 1; // clave traducida
		textos[clave] = new TextDecoder().decode(datos.subarray(posicion));
	}
	return textos;
}

/**
 * Devuelve el PNG con los textos y la resolución dentro.
 *
 * Se sustituye el `pHYs` que traiga el canvas, si trae alguno: un PNG con dos resoluciones es
 * inválido y cada programa elegiría una.
 */
export function conMetadatos(
	png: Uint8Array,
	{ textos, ppp }: { textos: Record<string, string>; ppp: number }
): Uint8Array<ArrayBuffer> {
	const trozos = leerTrozos(png);
	const [cabecera, ...resto] = trozos;
	if (cabecera?.tipo !== 'IHDR') throw new Error('El PNG no empieza por su cabecera.');

	const nuevos = [
		trozoDeResolucion(ppp),
		...Object.entries(textos)
			.filter(([, texto]) => texto.trim() !== '')
			.map(([clave, texto]) => trozoDeTexto(clave, texto))
	];
	const conservados = resto.filter((t) => t.tipo !== 'pHYs').map((t) => trozo(t.tipo, t.datos));
	const partes = [Uint8Array.from(FIRMA), trozo('IHDR', cabecera.datos), ...nuevos, ...conservados];

	const salida = new Uint8Array(partes.reduce((suma, parte) => suma + parte.length, 0));
	let posicion = 0;
	for (const parte of partes) {
		salida.set(parte, posicion);
		posicion += parte.length;
	}
	return salida;
}

/** La resolución guardada, en puntos por pulgada, o null si no hay. */
export function leerPpp(png: Uint8Array): number | null {
	const fisico = leerTrozos(png).find((t) => t.tipo === 'pHYs');
	if (!fisico) return null;
	const vista = new DataView(fisico.datos.buffer, fisico.datos.byteOffset, fisico.datos.byteLength);
	return Math.round(vista.getUint32(0) * 0.0254);
}

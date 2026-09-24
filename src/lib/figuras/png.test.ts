import { describe, expect, it } from 'vitest';
import { conMetadatos, crc32, leerPpp, leerTextos, leerTrozos } from './png';

// Un PNG de un píxel, tal como lo escribe cualquier programa.
const PIXEL = Uint8Array.from(
	atob(
		'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg=='
	),
	(caracter) => caracter.charCodeAt(0)
);

/** Comprueba el CRC de cada trozo, que es lo primero que mira un lector de PNG. */
function crcsCorrectos(png: Uint8Array): boolean {
	const vista = new DataView(png.buffer, png.byteOffset, png.byteLength);
	let posicion = 8;
	while (posicion < png.length) {
		const largo = vista.getUint32(posicion);
		const guardado = vista.getUint32(posicion + 8 + largo);
		if (crc32(png.subarray(posicion + 4, posicion + 8 + largo)) !== guardado) return false;
		posicion += 12 + largo;
	}
	return true;
}

describe('metadatos en PNG', () => {
	it('calcula el CRC como el estándar', () => {
		expect(crcsCorrectos(PIXEL)).toBe(true);
	});

	it('mete los textos con tildes y comillas sin perder nada', () => {
		const textos = {
			Title: 'Dónde cae cada forma. El mágico prodigioso',
			Copyright: 'CC BY-NC-SA 4.0. Versología',
			Description: '«Análisis y estudio versológico de El mágico prodigioso»'
		};
		const salida = conMetadatos(PIXEL, { textos, ppp: 300 });
		expect(leerTextos(salida)).toEqual(textos);
		expect(crcsCorrectos(salida)).toBe(true);
	});

	it('guarda la resolución de impresión y deja una sola', () => {
		const una = conMetadatos(PIXEL, { textos: {}, ppp: 300 });
		const dos = conMetadatos(una, { textos: {}, ppp: 600 });
		expect(leerPpp(dos)).toBe(600);
		expect(leerTrozos(dos).filter((t) => t.tipo === 'pHYs')).toHaveLength(1);
	});

	it('conserva la cabecera delante y la imagen intacta', () => {
		const salida = conMetadatos(PIXEL, { textos: { Title: 'x' }, ppp: 300 });
		const tipos = leerTrozos(salida).map((t) => t.tipo);
		expect(tipos[0]).toBe('IHDR');
		expect(tipos.at(-1)).toBe('IEND');
		const datosDe = (png: Uint8Array) => leerTrozos(png).find((t) => t.tipo === 'IDAT')?.datos;
		expect(datosDe(salida)).toEqual(datosDe(PIXEL));
	});

	it('se niega con lo que no es un PNG', () => {
		expect(() => conMetadatos(new Uint8Array([1, 2, 3]), { textos: {}, ppp: 300 })).toThrow();
	});
});

import { describe, expect, it } from 'vitest';
import { compactRhymeNotation, normalizeRhymeSymbol, repartirNotacion } from './rhyme-notation';

describe('una notación se coloca sobre los versos que describe', () => {
	it('los tercetos escritos del soneto caen en los versos 9 a 14, con su corte, y con sus letras', () => {
		const tercetos = [9, 10, 11, 12, 13, 14];
		expect(repartirNotacion('CDEECD', tercetos)).toEqual({
			letras: [
				[9, 'C'],
				[10, 'D'],
				[11, 'E'],
				[12, 'E'],
				[13, 'C'],
				[14, 'D']
			],
			cortes: []
		});
		expect(repartirNotacion('CDE ECD', tercetos)?.cortes).toEqual([12]);
	});

	it('los cuartetos del catálogo, con espacio, caen en los versos 1 a 8', () => {
		const reparto = repartirNotacion('ABAB ABAB', [1, 2, 3, 4, 5, 6, 7, 8]);
		expect(reparto?.letras.map(([, letra]) => letra).join('')).toBe('ABABABAB');
		expect(reparto?.cortes).toEqual([5]);
	});

	it('no reparte una notación que no casa verso a verso', () => {
		expect(repartirNotacion('CDEEC', [9, 10, 11, 12, 13, 14])).toBeNull();
		// Medida contra el soneto entero, que es lo que hacía el resumen y lo que la descartaba.
		expect(repartirNotacion('ABBA ABBA', Array.from({ length: 14 }, (_, i) => i + 1))).toBeNull();
	});

	it('sigue leyendo las notaciones con barra y con dos puntos', () => {
		expect(repartirNotacion('abba|cddc', [1, 2, 3, 4, 5, 6, 7, 8])?.cortes).toEqual([5]);
		expect(repartirNotacion('abCabC:cdeeDfF', Array.from({ length: 13 }, (_, i) => i + 1))?.cortes).toEqual([7]);
	});
});

describe('notación de rima', () => {
	it('conserva la caja al limpiar un esquema abierto', () => {
		expect(compactRhymeNotation(' a B b A b ')).toBe('aBbAb');
	});

	it('usa minúscula en arte menor y mayúscula en arte mayor', () => {
		expect(normalizeRhymeSymbol('A', 7)).toBe('a');
		expect(normalizeRhymeSymbol('b', 11)).toBe('B');
		expect(normalizeRhymeSymbol('-', 7)).toBe('-');
	});
});

import { describe, expect, it } from 'vitest';
import { compactRhymeNotation, normalizeRhymeSymbol } from './rhyme-notation';

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

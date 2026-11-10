import { describe, expect, it } from 'vitest';
import { fechaCsv } from './fecha-csv.mjs';
describe('fechas explícitas del CSV', () => {
	it('distingue límites inclusivos y estrictos en ambos sentidos', () => {
		expect(fechaCsv('≤1672')).toMatchObject({ inicio: null, fin: 1672, fin_inclusivo: true });
		expect(fechaCsv('<1600')).toMatchObject({ inicio: null, fin: 1600, fin_inclusivo: false });
		expect(fechaCsv('>1600')).toMatchObject({ inicio: 1600, fin: null, inicio_inclusivo: false });
		expect(fechaCsv('≥1600')).toMatchObject({ inicio: 1600, fin: null, inicio_inclusivo: true });
	});
	it('conserva aproximación e intervalos y no convierte una edición en composición exacta', () => {
		expect(fechaCsv('c. 1590')).toMatchObject({ inicio: 1590, fin: 1590, aproximada: true });
		expect(fechaCsv('1580–1590')).toMatchObject({ inicio: 1580, fin: 1590 });
		expect(fechaCsv('1733 (edición; composición anterior no precisada)')).toMatchObject({ inicio: null, fin: 1733 });
		expect(() => fechaCsv('datación sin resolver')).toThrow();
	});
});

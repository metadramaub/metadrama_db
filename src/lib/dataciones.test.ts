import { describe, expect, it } from 'vitest';
import { coincideDatacion, datacionDeObra, datacionVacia, formatoDatacion, limitesDatacion, mediaDatacion } from './dataciones';
describe('dataciones', () => {
	it('distingue antes de y hasta el año, sin fabricar una media', () => {
		const d = { ...datacionVacia('referencia'), fin: 1600, fin_inclusivo: false };
		expect(formatoDatacion(d)).toBe('<1600');
		expect(limitesDatacion(d)).toEqual({ inicio: null, fin: 1599 });
		expect(mediaDatacion(d)).toBeNull();
		expect(coincideDatacion(d, 1600, 1600)).toBe(false);
		expect(coincideDatacion({ ...d, fin_inclusivo: true }, 1600, 1600)).toBe(true);
		expect(coincideDatacion(d, 1500, 1500)).toBe(true);
	});
	it('representa límites posteriores, aproximación e intervalos finitos', () => {
		const d = { ...datacionVacia('referencia'), inicio: 1600, inicio_inclusivo: false };
		expect(formatoDatacion(d)).toBe('>1600');
		expect(coincideDatacion(d, 1600, 1600)).toBe(false);
		expect(mediaDatacion({ ...d, fin: 1603 })).toBe(1602);
		expect(formatoDatacion({ ...d, inicio_inclusivo: true, fin: 1600, aproximada: true })).toBe('c. 1600');
	});
	it('la métrica no sustituye la referencia y el contrato vacío borra la fecha anterior', () => {
		expect(datacionDeObra({ dataciones: [{ ...datacionVacia('metrica'), inicio: 1590, fin: 1600 }], fecha_inicio_trad: 1500 }).inicio).toBeNull();
		expect(datacionDeObra({ dataciones: [], fecha_inicio_trad: 1500 }).inicio).toBeNull();
		expect(datacionDeObra({ fecha_inicio_trad: 1590, fecha_fin_trad: 1600 }).inicio).toBe(1590);
	});
	it('un artefacto anterior conserva su presentación hasta regenerarse con límites explícitos', () => {
		expect(formatoDatacion(datacionDeObra({ fecha_inicio_trad: 1612 }))).toBe('1612');
		expect(formatoDatacion(datacionDeObra({ dataciones: [{ ...datacionVacia('referencia'), fin: 1612 }] }))).toBe('≤1612');
	});
});

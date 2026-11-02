import { describe, expect, it } from 'vitest';
import { comprobarLongitud } from './longitud';
import type { SegmentoMinimo } from './types';

function secuencia(forma: string | null, n: number, arquitectura: string | null = null) {
	return {
		v_ini: 100, v_fin: 99 + n,
		identificacion: forma ? {forma_slug: forma, arquitectura_slug: arquitectura} : null,
		detalles_fuente: [], desviaciones: []
	} as Pick<SegmentoMinimo, 'v_ini' | 'v_fin' | 'identificacion' | 'detalles_fuente' | 'desviaciones'>;
}

describe('longitud normativa del importador', () => {
	it.each([
		['redondilla', 52, 53], ['quintilla', 260, 258], ['octava_real', 104, 103],
		['soneto', 14, 17], ['sexteto_lira', 78, 77], ['romance', 76, 75]
	])('comprueba %s sin exigir elegir una arquitectura cuando todas comparten la regla', (forma, valido, invalido) => {
		expect(comprobarLongitud(secuencia(forma, valido)).estado).toBe('compatible');
		const aviso = comprobarLongitud(secuencia(forma, invalido));
		expect(aviso.estado).toBe('revisar');
		expect(aviso.mensaje).toContain(`${invalido} versos`);
	});
	it('descuenta solo las adiciones declaradas y no las cuenta dos veces por solapamiento', () => {
		const s = secuencia('redondilla', 53);
		const extra = {v_ini: 105,v_fin:105,dimension:'estructura',relacion_norma:'sobra'};
		s.desviaciones = [extra, {...extra}];
		const antes=structuredClone(s);
		expect(comprobarLongitud(s).estado).toBe('compatible');
		expect(s).toEqual(antes);
		s.desviaciones=[{...extra,dimension:'metro',relacion_norma:'menor_que_norma'}];
		expect(comprobarLongitud(s).estado).toBe('revisar');
	});
	it('la laguna ocupa posiciones ya incluidas: no suma ni descuenta otra vez', () => {
		const s=secuencia('redondilla',52);
		s.desviaciones=[{v_ini:105,v_fin:105,dimension:'estructura',relacion_norma:'falta'}];
		expect(comprobarLongitud(s).estado).toBe('compatible');
		s.v_fin-=1;
		expect(comprobarLongitud(s).estado).toBe('revisar');
	});
	it('obliga a respetar un remate declarado y no lo confunde con una adición', () => {
		const s=secuencia('terceto_encadenado',43);
		s.detalles_fuente=[{tipo_seccion:'remate',n_versos:1}];
		expect(comprobarLongitud(s).estado).toBe('compatible');
		s.v_fin-=1;
		expect(comprobarLongitud(s).estado).toBe('revisar'); // 42 no es 3n+1 con cierre declarado.
		s.v_fin+=2;
		s.desviaciones=[{v_ini:105,v_fin:105,dimension:'estructura',relacion_norma:'sobra'}];
		expect(comprobarLongitud(s).estado).toBe('compatible'); // 44 - adición - remate = 42.
		s.desviaciones[0].v_ini=s.v_fin;s.desviaciones[0].v_fin=s.v_fin;
		expect(comprobarLongitud(s).mensaje).toContain('coincide con el remate');
	});
	it('no declara comprobadas formas abiertas ni inventa una forma desde el módulo', () => {
		expect(comprobarLongitud(secuencia(null,43)).estado).toBe('sin_identificar');
		expect(comprobarLongitud(secuencia('endecasilabo_suelto',43)).estado).toBe('sin_regla');
		expect(comprobarLongitud(secuencia('cancion',43)).estado).toBe('sin_regla');
		expect(comprobarLongitud(secuencia('silva',43)).estado).toBe('sin_regla');
		expect(comprobarLongitud(secuencia('redondilla',52,'hexasilabica')).estado).toBe('compatible');
	});
	it('respeta el mínimo de una cadena de al menos dos tercetos', () => {
		const s=secuencia('terceto_encadenado',4);
		s.detalles_fuente=[{tipo_seccion:'remate',n_versos:1}];
		expect(comprobarLongitud(s).estado).toBe('revisar');
		s.v_fin=106;
		expect(comprobarLongitud(s).estado).toBe('compatible');
	});
});

import { describe, expect, it } from 'vitest';
import { indicadorIntervencionFemenina } from './generos-intervinientes';

describe('indicador femenino de la lista de secuencias', () => {
	it.each([
		{ generos: ['femenino'], estado: 'si', texto: 'exclusiva' },
		{ generos: ['masculino', 'femenino'], estado: 'si', texto: 'compartida' },
		{ generos: ['femenino', 'indeterminado'], estado: 'si', texto: 'compartida' },
		{ generos: ['masculino', 'femenino', 'indeterminado'], estado: 'si', texto: 'compartida' },
		{ generos: ['masculino'], estado: 'no', texto: 'Sin intervención femenina' },
		{ generos: ['indeterminado'], estado: 'pendiente', texto: 'sin determinar' },
		{ generos: ['masculino', 'indeterminado'], estado: 'pendiente', texto: 'sin determinar' },
		{ generos: null, estado: 'pendiente', texto: 'sin responder' }
	])('$generos → $estado', ({ generos, estado, texto }) => {
		const indicador = indicadorIntervencionFemenina(generos);
		expect(indicador.estado).toBe(estado);
		expect(indicador.titulo).toContain(texto);
	});
});

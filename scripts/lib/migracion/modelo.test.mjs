import { describe, expect, it } from 'vitest';
import { fundirIndicadores } from './modelo.mjs';

describe('géneros al fundir secuencias', () => {
	it('reúne las selecciones sin perder indeterminado ni repetir géneros', () => {
		expect(
			fundirIndicadores([
				{ generos_intervinientes: ['femenino', 'indeterminado'] },
				{ generos_intervinientes: ['masculino', 'femenino'] }
			]).generos_intervinientes
		).toEqual(['masculino', 'femenino', 'indeterminado']);
	});

	it('conserva el pendiente si falta por responder alguna parte', () => {
		expect(
			fundirIndicadores([
				{ generos_intervinientes: ['indeterminado'] },
				{ generos_intervinientes: null }
			]).generos_intervinientes
		).toBeNull();
	});
});

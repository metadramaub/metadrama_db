import { describe, expect, it } from 'vitest';
import { aplicarCorrespondencias, type Correspondencia } from './correspondencias';
import type { BorradorFichaMinima, IncidenciaImportador } from '$lib/importador-metrico/types';

function datos(literal = 'término de prueba') {
	return {
		segmentos: [
			{ ref: 't01', origen: { denominacion_literal: literal }, identificacion: null, candidatas: [], regla_id: null, nota: null }
		]
	} as unknown as BorradorFichaMinima;
}
const registro: Correspondencia = {
	id: '00000000-0000-4000-8000-000000000001',
	literal: 'término de prueba',
	forma: 'quintilla',
	arquitectura: null
};

describe('correspondencias registradas', () => {
	it('identifica el término pendiente en otra importación', () => {
		const d = datos();
		aplicarCorrespondencias(d, [registro], []);
		expect(d.segmentos[0].identificacion).toEqual({ forma_slug: 'quintilla', arquitectura_slug: null });
		expect(d.segmentos[0].regla_id).toBe('registro:' + registro.id);
	});
	it('no distingue mayúsculas ni espacios', () => {
		const d = datos('  Término   de prueba ');
		aplicarCorrespondencias(d, [registro], []);
		expect(d.segmentos[0].identificacion?.forma_slug).toBe('quintilla');
	});
	it('admite forma y arquitectura', () => {
		const d = datos();
		aplicarCorrespondencias(d, [{ ...registro, forma: 'soneto', arquitectura: 'endecasilabica_consonante' }], []);
		expect(d.segmentos[0].identificacion?.arquitectura_slug).toBe('endecasilabica_consonante');
	});
	it('no pisa una identificación que ya trae una regla', () => {
		const d = datos();
		d.segmentos[0].identificacion = { forma_slug: 'redondilla', arquitectura_slug: null };
		aplicarCorrespondencias(d, [registro], []);
		expect(d.segmentos[0].identificacion.forma_slug).toBe('redondilla');
	});
	it('no elige entre registros que se contradicen', () => {
		const d = datos();
		const avisos: IncidenciaImportador[] = [];
		aplicarCorrespondencias(d, [registro, { ...registro, id: 'b', forma: 'redondilla' }], avisos);
		expect(d.segmentos[0].identificacion).toBeNull();
		expect(avisos[0].codigo).toBe('correspondencias_conflicto');
	});
	it('ignora destinos que ya no están en el catálogo', () => {
		const d = datos();
		aplicarCorrespondencias(d, [{ ...registro, arquitectura: 'inventada' }], []);
		expect(d.segmentos[0].identificacion).toBeNull();
		expect(d.segmentos[0].origen.denominacion_literal).toBe(registro.literal);
	});
});

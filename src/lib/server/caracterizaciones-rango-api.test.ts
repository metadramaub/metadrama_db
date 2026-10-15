import { describe, expect, it, vi } from 'vitest';
import { PATCH } from '../../routes/api/obras/[id]/secuencias/[secuenciaId]/caracterizaciones/[caracterizacionId]/+server';

vi.mock('$lib/server/auth', () => ({ getObraContext: vi.fn().mockResolvedValue({}) }));
vi.mock('$lib/server/catalogos-internos', () => ({
	loadInternalVocabulario: vi.fn().mockResolvedValue([
		{
			termino_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			termino: 'cantado',
			termino_padre_id: 'padre'
		}
	]),
	loadInternalVocabularioTermById: vi.fn()
}));

describe('edición de caracterizaciones históricas', () => {
	it('cambiar el rango conserva la observación original en la base', async () => {
		const nota = 'Nota histórica pendiente de traslado';
		const update = vi.fn().mockReturnThis();
		const query = {
			select: vi.fn().mockReturnThis(),
			eq: vi.fn().mockReturnThis(),
			update,
			maybeSingle: vi
				.fn()
				.mockResolvedValueOnce({ data: { v_ini: 1, v_fin: 100 } })
				.mockResolvedValueOnce({
					data: {
						caracterizacion_rango_id: 'caracterizacion',
						tipo_caracterizacion_rango_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad'
					}
				}),
			single: vi.fn().mockResolvedValue({
				data: {
					caracterizacion_rango_id: 'caracterizacion',
					secuencia_id: 'secuencia',
					tipo_caracterizacion_rango_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
					v_ini: 10,
					v_fin: 15,
					observaciones: nota,
					tipo_caracterizacion_rango: { termino: 'cantado', termino_padre_id: 'padre' }
				}
			})
		};
		const response = await PATCH({
			locals: { supabase: { from: vi.fn().mockReturnValue(query) } },
			params: { id: 'obra', secuenciaId: 'secuencia', caracterizacionId: 'caracterizacion' },
			request: new Request('http://localhost', {
				method: 'PATCH',
				body: JSON.stringify({
					tipo_caracterizacion_rango_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
					v_ini: 10,
					v_fin: 15
				})
			})
		} as unknown as Parameters<typeof PATCH>[0]);
		expect(response.status).toBe(200);
		expect(update).toHaveBeenCalledWith({
			tipo_caracterizacion_rango_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			v_ini: 10,
			v_fin: 15
		});
		expect((await response.json()).caracterizacion.observaciones).toBe(nota);
	});
});

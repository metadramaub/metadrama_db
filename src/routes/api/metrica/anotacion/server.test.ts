import { describe, expect, it, vi } from 'vitest';
vi.mock('$lib/server/auth', () => ({ requireEditorProfile: vi.fn().mockResolvedValue({}) }));
import { POST } from './+server';

const uuid = (n: number) => `00000000-0000-4000-8000-${String(n).padStart(12, '0')}`;
const deviation = {
	realizacion_id: null,
	v_ini: 2666,
	v_fin: 2666,
	dimension: 'estructura',
	relacion_norma: 'sobra',
	metro_observado_id: null,
	esquema_rima_observado_id: null,
	seccion_observada_id: null,
	repeticion_observada_id: null,
	valor_rasgo_observado_id: null,
	observaciones: null
};

async function save(desviaciones: (typeof deviation)[], realSequence = false, end = 2754) {
	const rpc = vi.fn().mockResolvedValue({ data: uuid(5), error: null });
	const input = {
		action: 'save_sequence',
		anotacion_id: null,
		escenario_id: realSequence ? null : uuid(1),
		secuencia_id: realSequence ? uuid(2) : null,
		orden: 1,
		v_ini: 2622,
		v_fin: realSequence ? 2753 : end,
		forma_id: uuid(3),
		arquitectura_id: uuid(4),
		observaciones: null,
		unidades: [],
		elecciones: [],
		desviaciones
	};
	const supabase = {
		rpc,
		from(table: string) {
			const data =
				table === 'secuencias_metricas'
					? { v_ini: 2622, v_fin: 2754 }
					: table === 'anotaciones_metricas'
						? null
						: {
								modulo_versos: 4,
								residuo_versos: 0,
								minimo_versos: 4,
								desplazamientos: [0],
								origen: 'unidad',
								explicacion: 'unidades completas de 4 versos'
							};
			const query = {
				select: () => query,
				eq: () => query,
				maybeSingle: async () => ({ data, error: null })
			};
			return query;
		}
	};
	const response = await POST({
		locals: { supabase },
		request: new Request('http://localhost/api/metrica/anotacion', {
			method: 'POST',
			body: JSON.stringify(input)
		})
	} as unknown as Parameters<typeof POST>[0]);
	return { response, rpc };
}

describe('guardado con adiciones estructurales', () => {
	it('acepta una laguna incluida entre las 132 posiciones de la norma', async () => {
		const missing = { ...deviation, relacion_norma: 'falta' };
		const { response, rpc } = await save([missing], false, 2753);
		expect(response.status).toBe(200);
		expect(rpc.mock.calls[0][1].p_datos.v_fin).toBe(2753);
		const incompatible = await save([missing]);
		expect(incompatible.response.status).toBe(422);
		expect(incompatible.rpc).not.toHaveBeenCalled();
	});
	it('deja pasar 133 versos con una adición declarada y conserva su numeración', async () => {
		const { response, rpc } = await save([deviation]);
		expect(response.status).toBe(200);
		expect(rpc).toHaveBeenCalledWith('guardar_anotacion_metrica', {
			p_datos: expect.objectContaining({ v_ini: 2622, v_fin: 2754, desviaciones: [deviation] })
		});
	});
	it('rechaza los mismos 133 versos sin declaración, o con una desviación de otra dimensión', async () => {
		for (const deviations of [
			[],
			[{ ...deviation, dimension: 'metro', relacion_norma: 'menor_que_norma' }]
		]) {
			const { response, rpc } = await save(deviations);
			expect(response.status).toBe(422);
			expect(rpc).not.toHaveBeenCalled();
		}
	});
	it('comprueba el rango de la secuencia real leído de la base', async () => {
		const { response, rpc } = await save([deviation], true);
		expect(response.status).toBe(200);
		expect(rpc.mock.calls[0][1].p_datos.v_fin).toBe(2754);
	});
	it('rechaza adiciones fuera del rango real', async () => {
		const { response, rpc } = await save([{ ...deviation, v_ini: 2755, v_fin: 2755 }]);
		expect(response.status).toBe(422);
		expect(rpc).not.toHaveBeenCalled();
	});
});

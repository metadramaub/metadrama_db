import { describe, expect, it } from 'vitest';
import { conservarSubtipos } from './conservar-subtipos.mjs';

describe('conservación de los subtipos legados', () => {
	const origen = {
		subtipo_secuencia_id: 'q',
		secuencia_id: 's',
		subtipo_estrofa_id: 'quintilla',
		v_ini: 2277,
		v_fin: 2279,
		created_at: '2026-05-07',
		updated_at: '2026-05-07'
	};
	const secuencias = [{ secuencia_id: 's', subtipos: [{ ...origen, origen_original: origen }] }];
	it('conserva la fila histórica y repone el rango corregido después del borrado del disparador', () => {
		const sql = conservarSubtipos(secuencias, [{ ...origen, secuencia_id: 'fusion', v_fin: 2281 }]);
		expect(sql.antes.join('\n')).toContain(JSON.stringify(origen));
		expect(sql.antes.join('\n')).toContain(
			JSON.stringify({ ...origen, secuencia_id: 'fusion', v_fin: 2281 })
		);
		expect(sql.despues.join('\n')).toContain('insert into public.secuencias_subtipos_estrofa');
		expect(sql.despues.join('\n')).toContain('No se han conservado los subtipos');
		expect(origen.v_fin).toBe(2279);
	});
	it('rechaza pérdidas, duplicados y filas sin un origen completo', () => {
		expect(() => conservarSubtipos(secuencias, [])).toThrow('todos los subtipos');
		expect(() =>
			conservarSubtipos(secuencias, [{ ...origen, subtipo_secuencia_id: 'otro' }])
		).toThrow('sin origen');
		expect(() => conservarSubtipos([{ secuencia_id: 's', subtipos: [origen] }], [origen])).toThrow(
			'original completa'
		);
	});
});

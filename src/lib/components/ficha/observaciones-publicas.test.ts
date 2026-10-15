import { describe, expect, it } from 'vitest';
import type { PublicFichaComentarioPublico } from '$lib/types/public-ficha.types';
import { agruparAclaracionesPublicas } from './observaciones-publicas';

function comentario(id: string, secuenciaId: string | null): PublicFichaComentarioPublico {
	return {
		comentario_id: id,
		comentario: `Nota ${id}`,
		secuencia_id: secuenciaId,
		created_at: null,
		seccion: null,
		jornada_id: null,
		cuadro_id: null,
		nombre_editor: 'Editora'
	};
}

describe('aclaraciones de la pestaña Observaciones', () => {
	it('reúne todas las notas de cada secuencia en orden de versos, sin modificar los datos', () => {
		const comentarios = [comentario('b', 's2'), comentario('a', 's1'), comentario('c', 's2')];
		const grupos = agruparAclaracionesPublicas(comentarios, [
			{ secuencia_id: 's2', v_ini: 100, v_fin: 150, forma_nombre: 'Romance' },
			{ secuencia_id: 's1', v_ini: 1, v_fin: 40, forma_nombre: 'Redondilla' }
		]);
		expect(grupos.map((g) => g.secuenciaId)).toEqual(['s1', 's2']);
		expect(grupos[1].comentarios.map((c) => c.comentario_id)).toEqual(['b', 'c']);
		expect(grupos[0].secuencia).toMatchObject({ v_ini: 1, v_fin: 40, forma_nombre: 'Redondilla' });
		expect(comentarios.map((c) => c.comentario_id)).toEqual(['b', 'a', 'c']);
	});
	it('conserva las notas generales y las que no tienen metadatos de secuencia visibles', () => {
		const grupos = agruparAclaracionesPublicas(
			[comentario('sin-metadatos', 'oculta'), comentario('general', null)],
			[]
		);
		expect(grupos.map((g) => g.secuenciaId)).toEqual([null, 'oculta']);
		expect(grupos[1].secuencia).toBeNull();
		expect(grupos.flatMap((g) => g.comentarios)).toHaveLength(2);
	});
	it('no genera grupos vacíos para secuencias sin aclaraciones', () => {
		expect(
			agruparAclaracionesPublicas(
				[],
				[{ secuencia_id: 's1', v_ini: 1, v_fin: 4, forma_nombre: 'Redondilla' }]
			)
		).toEqual([]);
	});
});

import { describe, expect, it } from 'vitest';
import {
	obraDatosPatchSchema,
	jornadaInputSchema,
	secuenciaInputSchema,
	comentarioInputSchema,
	autoriaInputSchema,
	analisisInputSchema,
	visibilidadInputSchema
} from './validators';

describe('validators', () => {
	it('requires title, genre and edition in obra data', () => {
		const result = obraDatosPatchSchema.safeParse({
			titulo: '',
			variantes_titulo: [],
			genero_id: 'not-a-uuid',
			edicion: ''
		});
		expect(result.success).toBe(false);
	});

	it('accepts valid obra payload', () => {
		const result = obraDatosPatchSchema.safeParse({
			titulo: 'La dama boba',
			variantes_titulo: ['Dama boba'],
			genero_id: 'e7212f8c-8d4d-4a9f-9e5d-d22959e761f4',
			fecha_inicio_trad: 1613,
			fecha_fin_trad: 1617,
			fuente_fecha: 'Morley & Bruerton',
			fecha_inicio_metadrama: null,
			fecha_fin_metadrama: null,
			edicion: 'Edicion de referencia'
		});
		expect(result.success).toBe(true);
	});

	it('rejects invalid range for jornadas', () => {
		const result = jornadaInputSchema.safeParse({ jornada_num: 1, v_ini: 500, v_fin: 120 });
		expect(result.success).toBe(false);
	});

	it('requires at least one metro in secuencia', () => {
		const result = secuenciaInputSchema.safeParse({
			v_ini: 1,
			v_fin: 120,
			estrofa_tipo_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			inaugura_espacio: false,
			personajes_genero: 'mixto',
			personajes_donaire: 'ausente',
			personajes_sobrenatural: 'ausente',
			estado_revision: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7',
			certeza_editor: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
			observaciones: null,
			notas_internas: null,
			metro_ids: []
		});
		expect(result.success).toBe(false);
	});

	it('rejects blank internal comment', () => {
		const result = comentarioInputSchema.safeParse({ comentario: '' });
		expect(result.success).toBe(false);
	});

	it('accepts autoria obra completa payload', () => {
		const result = autoriaInputSchema.safeParse({
			mode: 'obra_completa',
			url_informe_autoria: 'https://example.com/informe',
			autor_ids: ['4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7'],
			notas: 'Colaboracion no determinada'
		});
		expect(result.success).toBe(true);
	});

	it('rejects autoria custom range with invalid verse order', () => {
		const result = autoriaInputSchema.safeParse({
			mode: 'rango_personalizado',
			url_informe_autoria: null,
			items: [
				{
					v_ini: 100,
					v_fin: 90,
					autor_ids: ['4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7'],
					notas: null
				}
			]
		});
		expect(result.success).toBe(false);
	});

	it('normalizes empty analysis text to null', () => {
		const result = analisisInputSchema.parse({ analisis_editor: '   ', bibliografia: '' });
		expect(result.analisis_editor).toBeNull();
		expect(result.bibliografia).toBeNull();
	});

	it('accepts visibility toggle payload', () => {
		const result = visibilidadInputSchema.safeParse({ visible_publico: true });
		expect(result.success).toBe(true);
	});
});

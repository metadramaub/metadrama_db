import { describe, expect, it } from 'vitest';
import {
	obraDatosPatchSchema,
	jornadaInputSchema,
	secuenciaInputSchema,
	secuenciaVariacionInputSchema,
	comentarioInputSchema,
	comentarioPatchSchema,
	comentarioListQuerySchema,
	autoriaInputSchema,
	analisisInputSchema,
	visibilidadInputSchema,
	obraCreateSchema,
	autorCreateSchema,
	autorPatchSchema,
	autorDeleteSchema,
	obraAssignmentsInputSchema,
	obraReviewersInputSchema,
	vocabularioCreateSchema,
	vocabularioPatchSchema,
	vocabularioReorderSchema
} from './validators';

describe('validators', () => {
	it('allows draft obra data with optional fields', () => {
		const result = obraDatosPatchSchema.safeParse({
			titulo: '',
			variantes_titulo: [],
			genero_id: '',
			edicion: ''
		});
		expect(result.success).toBe(true);
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

	it('accepts secuencia payload without metros', () => {
		const result = secuenciaInputSchema.safeParse({
			v_ini: 1,
			v_fin: 120,
			estrofa_tipo_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			inaugura_espacio: false,
			personajes_genero: 'mixto',
			personajes_donaire: 'ausente',
			personajes_sobrenatural: 'ausente',
			certeza_editor: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
			observaciones: null
		});
		expect(result.success).toBe(true);
	});

	it('accepts secuencia variacion payload with same verse range', () => {
		const result = secuenciaVariacionInputSchema.safeParse({
			tipo_variacion_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			v_ini: 56,
			v_fin: 56,
			observaciones: 'irregularidad puntual'
		});
		expect(result.success).toBe(true);
	});

	it('rejects secuencia variacion payload when v_ini is greater than v_fin', () => {
		const result = secuenciaVariacionInputSchema.safeParse({
			tipo_variacion_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			v_ini: 57,
			v_fin: 56
		});
		expect(result.success).toBe(false);
	});

	it('rejects blank internal comment', () => {
		const result = comentarioInputSchema.safeParse({ comentario: '' });
		expect(result.success).toBe(false);
	});

	it('rejects comments with more than one context reference', () => {
		const result = comentarioInputSchema.safeParse({
			comentario: 'Comentario interno',
			secuencia_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
			jornada_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7'
		});
		expect(result.success).toBe(false);
	});

	it('rejects patching internal comment type estado', () => {
		const result = comentarioPatchSchema.safeParse({
			comentario: 'Actualizado',
			tipo_comentario: 'estado'
		});
		expect(result.success).toBe(false);
	});

	it('applies defaults for comment list query pagination', () => {
		const parsed = comentarioListQuerySchema.parse({});
		expect(parsed.limit).toBe(1000);
		expect(parsed.offset).toBe(0);
	});

	it('rejects comment list query with more than one context reference', () => {
		const result = comentarioListQuerySchema.safeParse({
			secuencia_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
			jornada_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7'
		});
		expect(result.success).toBe(false);
	});

	it('accepts autoria obra completa payload', () => {
		const result = autoriaInputSchema.safeParse({
			mode: 'obra_completa',
			source_mode: 'obra_completa',
			url_informe_autoria: 'https://example.com/informe',
			autor_ids: ['4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7']
		});
		expect(result.success).toBe(true);
	});

	it('rejects autoria custom range with invalid verse order', () => {
		const result = autoriaInputSchema.safeParse({
			mode: 'rango_personalizado',
			source_mode: 'rango_personalizado',
			url_informe_autoria: null,
			items: [
				{
					v_ini: 100,
					v_fin: 90,
					autor_ids: ['4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7']
				}
			]
		});
		expect(result.success).toBe(false);
	});

	it('defaults confirm_mode_change to false in autoria payload', () => {
		const result = autoriaInputSchema.parse({
			mode: 'por_jornadas',
			source_mode: 'por_jornadas',
			url_informe_autoria: null,
			items: [
				{
					jornada_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
					autor_ids: ['ef18f734-8cf5-4586-b5ca-0df411a8f4d7']
				}
			]
		});
		expect(result.confirm_mode_change).toBe(false);
		expect(result.confirm_reassign).toBe(false);
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

	it('requires title and assigned editor on obra creation', () => {
		const invalid = obraCreateSchema.safeParse({
			titulo: '',
			editor_asignado: 'not-uuid'
		});
		expect(invalid.success).toBe(false);

		const valid = obraCreateSchema.safeParse({
			titulo: 'Nueva obra',
			editor_asignado: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7'
		});
		expect(valid.success).toBe(true);
	});

	it('validates author create payload', () => {
		const result = autorCreateSchema.safeParse({
			nombre_completo: '  Lope de Vega  ',
			variantes_nombre: ['Lope Felix', '  ', 'LOPE FELIX'],
			bnedatos_id: ' BNE123 ',
			viaf_id: '',
			wikidata_id: null
		});
		expect(result.success).toBe(true);
		if (!result.success) return;
		expect(result.data.nombre_completo).toBe('Lope de Vega');
		expect(result.data.variantes_nombre).toEqual(['Lope Felix']);
		expect(result.data.bnedatos_id).toBe('BNE123');
		expect(result.data.viaf_id).toBeNull();
	});

	it('requires at least one field in author patch payload', () => {
		const empty = autorPatchSchema.safeParse({});
		expect(empty.success).toBe(false);

		const valid = autorPatchSchema.safeParse({
			variantes_nombre: ['Alias A', 'alias a'],
			viaf_id: ' VIAF-1 '
		});
		expect(valid.success).toBe(true);
		if (!valid.success) return;
		expect(valid.data.variantes_nombre).toEqual(['Alias A']);
		expect(valid.data.viaf_id).toBe('VIAF-1');
	});

	it('requires ELIMINAR in author delete confirmation', () => {
		const invalid = autorDeleteSchema.safeParse({ confirmText: 'eliminar' });
		expect(invalid.success).toBe(false);
		const valid = autorDeleteSchema.safeParse({ confirmText: 'ELIMINAR' });
		expect(valid.success).toBe(true);
	});

	it('deduplicates reviewer ids', () => {
		const result = obraReviewersInputSchema.parse({
			reviewer_ids: [
				'4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
				'4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7'
			]
		});
		expect(result.reviewer_ids).toHaveLength(1);
	});

	it('accepts combined editor and reviewers assignments payload', () => {
		const result = obraAssignmentsInputSchema.parse({
			editor_asignado: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
			reviewer_ids: [
				'4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
				'ef18f734-8cf5-4586-b5ca-0df411a8f4d7',
				'ef18f734-8cf5-4586-b5ca-0df411a8f4d7'
			]
		});
		expect(result.editor_asignado).toBe('4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7');
		expect(result.reviewer_ids).toEqual([
			'4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
			'ef18f734-8cf5-4586-b5ca-0df411a8f4d7'
		]);
	});

	it('normalizes blank combined assignments fields', () => {
		const result = obraAssignmentsInputSchema.parse({
			editor_asignado: '  ',
			reviewer_ids: ['', '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7', '  ']
		});
		expect(result.editor_asignado).toBeUndefined();
		expect(result.reviewer_ids).toEqual(['4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7']);
	});

	it('accepts non uuid identifiers in combined assignments payload', () => {
		const result = obraAssignmentsInputSchema.parse({
			editor_asignado: 'editor-externo-123',
			reviewer_ids: ['revisor-01', 'revisor-01']
		});
		expect(result.editor_asignado).toBe('editor-externo-123');
		expect(result.reviewer_ids).toEqual(['revisor-01']);
	});

	it('validates vocabulario create and patch payloads', () => {
		const createResult = vocabularioCreateSchema.safeParse({
			categoria: 'genero',
			termino: 'comedia',
			definicion: 'Descripcion base',
			equivalencias: ['drama', 'pieza']
		});
		expect(createResult.success).toBe(true);

		const estrofaCreate = vocabularioCreateSchema.safeParse({
			categoria: 'estrofa_tipo',
			termino: 'silva',
			tipo_forma: 'forma_italiana',
			metro_ids: ['72fbe06d-9f46-4690-9df8-a4d9f0611d0d']
		});
		expect(estrofaCreate.success).toBe(true);

		const emptyPatch = vocabularioPatchSchema.safeParse({});
		expect(emptyPatch.success).toBe(false);

		const patchResult = vocabularioPatchSchema.safeParse({ activo: false, bibliografia: 'Ref.' });
		expect(patchResult.success).toBe(true);

		const estrofaPatch = vocabularioPatchSchema.safeParse({
			tipo_forma: 'forma_espanola',
			metro_ids: ['81567f6d-5e8b-419f-b2c0-f9e9ed7f1017']
		});
		expect(estrofaPatch.success).toBe(true);
	});

	it('validates vocabulario reorder payloads', () => {
		const valid = vocabularioReorderSchema.safeParse({
			categoria: 'estrofa_tipo',
			items: [
				{
					termino_id: 'b0d246e7-fe7c-4c8f-8b5d-57a3a95e2af7',
					termino_padre_id: null,
					orden: 10,
					nivel: 1
				},
				{
					termino_id: 'e4f15fc1-87a1-4d5e-bf55-2aa9536f4f6e',
					termino_padre_id: 'b0d246e7-fe7c-4c8f-8b5d-57a3a95e2af7',
					orden: 10,
					nivel: 2
				}
			]
		});
		expect(valid.success).toBe(true);

		const duplicate = vocabularioReorderSchema.safeParse({
			categoria: 'estrofa_tipo',
			items: [
				{
					termino_id: 'b0d246e7-fe7c-4c8f-8b5d-57a3a95e2af7',
					termino_padre_id: null,
					orden: 10,
					nivel: 1
				},
				{
					termino_id: 'b0d246e7-fe7c-4c8f-8b5d-57a3a95e2af7',
					termino_padre_id: null,
					orden: 20,
					nivel: 1
				}
			]
		});
		expect(duplicate.success).toBe(false);
	});
});

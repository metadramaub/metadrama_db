import { describe, expect, it } from 'vitest';
import {
	obraDatosPatchSchema,
	jornadaInputSchema,
	secuenciaInputSchema,
	secuenciaCaracterizacionRangoInputSchema,
	secuenciaSubtipoEstrofaInputSchema,
	comentarioInputSchema,
	comentarioPatchSchema,
	comentarioListQuerySchema,
	autoriaInputSchema,
	observacionesInputSchema,
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
			versos_partidos: true,
			evocacion_metrica: true,
			evocacion_metrica_texto: 'Imita la voz métrica de otro personaje',
			intervencion_personajes_femeninos: 'sin_intervencion',
			intervencion_figuras_donaire: 'sin_intervencion',
			intervencion_personajes_sobrenaturales: 'sin_intervencion',
			sinopsis: null
		});
		expect(result.success).toBe(true);
	});

	it('defaults versos_partidos when omitted in secuencia payload', () => {
		const parsed = secuenciaInputSchema.parse({
			v_ini: 1,
			v_fin: 120,
			estrofa_tipo_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			inaugura_espacio: false,
			intervencion_personajes_femeninos: 'sin_intervencion',
			intervencion_figuras_donaire: 'sin_intervencion',
			intervencion_personajes_sobrenaturales: 'sin_intervencion',
			sinopsis: null
		});
		expect(parsed.versos_partidos).toBe(false);
		expect(parsed.evocacion_metrica).toBe(false);
		expect(parsed.evocacion_metrica_texto).toBe(null);
	});

	it('rejects old intervention values in secuencia payload', () => {
		const result = secuenciaInputSchema.safeParse({
			v_ini: 1,
			v_fin: 120,
			estrofa_tipo_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			inaugura_espacio: false,
			intervencion_personajes_femeninos: 'ausente',
			intervencion_figuras_donaire: 'solo',
			intervencion_personajes_sobrenaturales: 'con_otros',
			sinopsis: null
		});
		expect(result.success).toBe(false);
	});

	it('accepts secuencia caracterizacion por rango payload with same verse range', () => {
		const result = secuenciaCaracterizacionRangoInputSchema.safeParse({
			tipo_caracterizacion_rango_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			v_ini: 56,
			v_fin: 56,
			observaciones: 'irregularidad puntual'
		});
		expect(result.success).toBe(true);
	});

	it('rejects secuencia caracterizacion por rango payload when v_ini is greater than v_fin', () => {
		const result = secuenciaCaracterizacionRangoInputSchema.safeParse({
			tipo_caracterizacion_rango_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			v_ini: 57,
			v_fin: 56
		});
		expect(result.success).toBe(false);
	});

	it('accepts secuencia subtipo payload with valid range', () => {
		const result = secuenciaSubtipoEstrofaInputSchema.safeParse({
			subtipo_estrofa_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			v_ini: 10,
			v_fin: 25
		});
		expect(result.success).toBe(true);
	});

	it('rejects secuencia subtipo payload when v_ini is greater than v_fin', () => {
		const result = secuenciaSubtipoEstrofaInputSchema.safeParse({
			subtipo_estrofa_id: '574a7be6-3b2f-4c4a-b6f2-0a8efc3184ad',
			v_ini: 25,
			v_fin: 10
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

	it('accepts comments scoped by section', () => {
		const result = comentarioInputSchema.safeParse({
			comentario: 'Comentario interno',
			seccion: 'datos'
		});
		expect(result.success).toBe(true);
	});

	it('accepts nota propia and public observation comment types', () => {
		expect(
			comentarioInputSchema.safeParse({
				comentario: 'Revisar criterio mas adelante',
				tipo_comentario: 'nota_propia'
			}).success
		).toBe(true);
		expect(
			comentarioInputSchema.safeParse({
				comentario: 'Aclaracion publicable',
				tipo_comentario: 'observacion_publica'
			}).success
		).toBe(true);
	});

	it('rejects comments mixing section and specific context', () => {
		const result = comentarioInputSchema.safeParse({
			comentario: 'Comentario interno',
			seccion: 'autoria',
			cuadro_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7'
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

	it('accepts patching editable public comment types', () => {
		expect(
			comentarioPatchSchema.safeParse({
				comentario: 'Actualizado',
				tipo_comentario: 'nota_propia'
			}).success
		).toBe(true);
		expect(
			comentarioPatchSchema.safeParse({
				comentario: 'Actualizado',
				tipo_comentario: 'observacion_publica'
			}).success
		).toBe(true);
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

	it('accepts comment list query by section', () => {
		const result = comentarioListQuerySchema.safeParse({
			seccion: 'observaciones'
		});
		expect(result.success).toBe(true);
	});

	it('rejects comment list query mixing section and specific context', () => {
		const result = comentarioListQuerySchema.safeParse({
			seccion: 'revision',
			secuencia_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7'
		});
		expect(result.success).toBe(false);
	});

	it('accepts autoria payload with one global group and proposal', () => {
		const result = autoriaInputSchema.safeParse({
			grupos: [
				{
					jornada_id: null,
					propuestas: [
						{
							composicion_autoria_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7',
							perfil_metrico: true,
							evidencias: [
								{
									tipo_atribucion_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
									fuente_autoria: 'Catena tradicional'
								}
							],
							autores: [{ autor_id: '81567f6d-5e8b-419f-b2c0-f9e9ed7f1017', orden: 1 }]
						}
					]
				}
			]
		});
		expect(result.success).toBe(true);
	});

	it('accepts autoria payload with jornada group', () => {
		const result = autoriaInputSchema.safeParse({
			grupos: [
				{
					jornada_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
					propuestas: [
						{
							composicion_autoria_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7',
							evidencias: [{ tipo_atribucion_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7' }],
							autores: [
								{ autor_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7' },
								{ autor_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7', orden: 2 }
							]
						}
					]
				}
			]
		});
		expect(result.success).toBe(true);
	});

	it('deduplicates autores in autoria payload', () => {
		const result = autoriaInputSchema.parse({
			grupos: [
				{
					jornada_id: null,
					propuestas: [
						{
							composicion_autoria_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7',
							evidencias: [
								{
									tipo_atribucion_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
									fuente_autoria: 'Tradicion'
								}
							],
							autores: [
								{ autor_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7', orden: 1 },
								{ autor_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7', orden: 2 }
							]
						}
					]
				}
			]
		});
		expect(result.grupos[0].propuestas[0].autores).toHaveLength(1);
		expect(result.grupos[0].propuestas[0].autores[0].orden).toBe(1);
	});

	it('accepts autoria payload with evidencia without fuente_autoria', () => {
		const result = autoriaInputSchema.safeParse({
			grupos: [
				{
					jornada_id: null,
					propuestas: [
						{
							composicion_autoria_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7',
							evidencias: [{ tipo_atribucion_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7' }],
							autores: [{ autor_id: '81567f6d-5e8b-419f-b2c0-f9e9ed7f1017' }]
						}
					]
				}
			]
		});
		expect(result.success).toBe(true);
	});

	it('normalizes empty fuente_autoria in evidencias to null', () => {
		const result = autoriaInputSchema.parse({
			grupos: [
				{
					jornada_id: null,
					propuestas: [
						{
							composicion_autoria_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7',
							evidencias: [
								{
									tipo_atribucion_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7',
									fuente_autoria: '   '
								}
							],
							autores: [{ autor_id: '81567f6d-5e8b-419f-b2c0-f9e9ed7f1017' }]
						}
					]
				}
			]
		});
		expect(result.grupos[0].propuestas[0].evidencias[0].fuente_autoria).toBeNull();
	});

	it('accepts autoria payload with empty autores array', () => {
		const result = autoriaInputSchema.safeParse({
			grupos: [
				{
					jornada_id: null,
					propuestas: [
						{
							composicion_autoria_id: 'ef18f734-8cf5-4586-b5ca-0df411a8f4d7',
							evidencias: [{ tipo_atribucion_id: '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7' }],
							autores: []
						}
					]
				}
			]
		});
		expect(result.success).toBe(true);
	});

	it('normalizes empty observaciones text to null', () => {
		const result = observacionesInputSchema.parse({ observaciones: '   ', bibliografia: '' });
		expect(result.observaciones).toBeNull();
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
			nombre_normalizado: '  Vega Carpio, Lope de  ',
			variantes_nombre: ['Lope Félix', '  ', 'LOPE FELIX'],
			bnedatos_id: ' BNE123 ',
			viaf_id: '',
			wikidata_id: null
		});
		expect(result.success).toBe(true);
		if (!result.success) return;
		expect(result.data.nombre_completo).toBe('Lope de Vega');
		expect(result.data.nombre_normalizado).toBe('Vega Carpio, Lope de');
		expect(result.data.variantes_nombre).toEqual(['Lope Félix']);
		expect(result.data.bnedatos_id).toBe('BNE123');
		expect(result.data.viaf_id).toBeNull();
	});

	it('requires normalized name in author create payload', () => {
		const result = autorCreateSchema.safeParse({
			nombre_completo: 'Lope de Vega',
			variantes_nombre: [],
			bnedatos_id: null,
			viaf_id: null,
			wikidata_id: null
		});
		expect(result.success).toBe(false);
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

	it('accepts and trims normalized name in author patch payload', () => {
		const result = autorPatchSchema.safeParse({
			nombre_normalizado: '  Vélez de Guevara, Luis  '
		});
		expect(result.success).toBe(true);
		if (!result.success) return;
		expect(result.data.nombre_normalizado).toBe('Vélez de Guevara, Luis');
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
			tipo_rima: 'mixta',
			naturaleza_estrofica: 'tirada_continua',
			tamanio_unidad_estrofica: null,
			metro_ids: ['72fbe06d-9f46-4690-9df8-a4d9f0611d0d']
		});
		expect(estrofaCreate.success).toBe(true);

		const metroCreate = vocabularioCreateSchema.safeParse({
			categoria: 'metro',
			termino: 'octosilabo',
			numero_silabas: 8
		});
		expect(metroCreate.success).toBe(true);

		const emptyPatch = vocabularioPatchSchema.safeParse({});
		expect(emptyPatch.success).toBe(false);

		const patchResult = vocabularioPatchSchema.safeParse({ activo: false, bibliografia: 'Ref.' });
		expect(patchResult.success).toBe(true);

		const estrofaPatch = vocabularioPatchSchema.safeParse({
			tipo_forma: 'forma_espanola',
			tipo_rima: 'asonante',
			naturaleza_estrofica: 'estrofa_cerrada',
			tamanio_unidad_estrofica: 4,
			metro_ids: ['81567f6d-5e8b-419f-b2c0-f9e9ed7f1017']
		});
		expect(estrofaPatch.success).toBe(true);

		expect(vocabularioPatchSchema.safeParse({ tipo_rima: 'parcial' }).success).toBe(false);
		expect(vocabularioPatchSchema.safeParse({ tamanio_unidad_estrofica: 0 }).success).toBe(false);
		expect(vocabularioPatchSchema.safeParse({ numero_silabas: -8 }).success).toBe(false);
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

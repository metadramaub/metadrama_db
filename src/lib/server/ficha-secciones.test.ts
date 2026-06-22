import { describe, expect, it } from 'vitest';
import { applyFichaSectionVisibility, FICHA_SECTION_IDS } from './ficha-secciones';
import type { PublicObraFichaPayload } from '$lib/types/public-ficha.types';
import type { SectionVisibilityMap } from '$lib/secciones-publicas';

function fullFicha(): PublicObraFichaPayload {
	return {
		obra: {
			obra_id: 'o1',
			slug: 'obra',
			titulo: 'Obra',
			variantes_titulo: [],
			fecha_inicio_trad: null,
			fecha_fin_trad: null,
			fuente_fecha: null,
			genero_term: null,
			total_versos: 100,
			edicion: null,
			observaciones: 'OBSERVACIONES',
			bibliografia: 'BIBLIOGRAFIA',
			updated_at: null,
			autor_ficha_publico: null,
			autor_ficha_email_publico: null,
			autor_ficha_orcid_publico: null,
			visible_publico: true
		},
		autoria: {
			autores: [{ autor_id: 'a1', slug: 'autor', nombre_completo: 'Autor' }],
			grupos: [
				{
					grupo_atribucion_id: 'g1',
					scope: 'obra',
					obra_id: 'o1',
					jornada_id: null,
					jornada_num: null,
					nombre: null,
					notas: null,
					propuestas: [
						{
							atribucion_id: 'at1',
							composicion_autoria_id: 'c1',
							composicion_autoria_term: 'individual',
							autores: [{ autor_id: 'a1', slug: 'autor', nombre_completo: 'Autor' }],
							evidencias: [
								{
									atribucion_evidencia_id: 'e1',
									tipo_atribucion_id: 't1',
									tipo_atribucion_term: 'tradicional',
									fuente_autoria: 'FUENTE'
								}
							]
						}
					]
				}
			]
		},
		estructura: {
			jornadas: [{ jornada_id: 'j1', jornada_num: 1, v_ini: 1, v_fin: 100 }],
			cuadros: []
		},
		metrica: {
			secuencias: [
				{
					secuencia_id: 's1',
					v_ini: 1,
					v_fin: 100,
					n_versos: 100,
					estrofa_tipo_id: 'e1',
					estrofa_tipo_term: 'romance',
					estrofa_forma_term: 'romance',
					estrofa_forma_slug: 'romance',
					estrofa_tipo_forma: null,
					inaugura_espacio: false,
					versos_partidos: false,
					evocacion_metrica: false,
					evocacion_metrica_texto: null,
					intervencion_personajes_femeninos: 'sin_intervencion',
					intervencion_figuras_donaire: 'sin_intervencion',
					intervencion_personajes_sobrenaturales: 'sin_intervencion',
					sinopsis: 'SINOPSIS',
					jornada_id: 'j1',
					jornada_num: 1,
					cuadro_id: null,
					cuadro_num: null,
					caracterizaciones_rango: [],
					subtipos_estrofa: []
				}
			],
			distribucion_formas: [
				{ forma: 'romance', forma_slug: 'romance', forma_tipo_forma: null, versos: 100, porcentaje: 100 }
			]
		},
		sinopsis_metrica: {
			secuencias: [
				{
					secuencia_id: 's1',
					v_ini: 1,
					v_fin: 100,
					n_versos: 100,
					estrofa_tipo_id: 'e1',
					estrofa_tipo_term: 'romance',
					estrofa_forma_slug: 'romance',
					estrofa_tipo_forma: null,
					sinopsis: 'SINOPSIS'
				}
			]
		},
		comentarios_publicos: [
			{
				comentario_id: 'cm1',
				comentario: 'hola',
				created_at: null,
				seccion: null,
				secuencia_id: null,
				jornada_id: null,
				cuadro_id: null,
				nombre_editor: null
			}
		]
	};
}

function allVisible(): SectionVisibilityMap {
	return {
		[FICHA_SECTION_IDS.autoria]: true,
		[FICHA_SECTION_IDS.fuentes]: true,
		[FICHA_SECTION_IDS.metrica]: true,
		[FICHA_SECTION_IDS.sinopsisMetrica]: true,
		[FICHA_SECTION_IDS.observaciones]: true,
		[FICHA_SECTION_IDS.bibliografia]: true,
		[FICHA_SECTION_IDS.comentarios]: true
	};
}

describe('applyFichaSectionVisibility', () => {
	it('con todo visible no recorta nada', () => {
		const ficha = fullFicha();
		const out = applyFichaSectionVisibility(ficha, allVisible());
		expect(out.autoria.autores).toHaveLength(1);
		expect(out.autoria.grupos[0].propuestas[0].evidencias).toHaveLength(1);
		expect(out.metrica.distribucion_formas).toHaveLength(1);
		expect(out.sinopsis_metrica.secuencias).toHaveLength(1);
		expect(out.obra.observaciones).toBe('OBSERVACIONES');
		expect(out.obra.bibliografia).toBe('BIBLIOGRAFIA');
		expect(out.comentarios_publicos).toHaveLength(1);
	});

	it('no muta el payload original', () => {
		const ficha = fullFicha();
		applyFichaSectionVisibility(ficha, {});
		expect(ficha.autoria.autores).toHaveLength(1);
		expect(ficha.obra.observaciones).toBe('OBSERVACIONES');
	});

	it('autoría apagada vacía autores y grupos', () => {
		const v = { ...allVisible(), [FICHA_SECTION_IDS.autoria]: false };
		const out = applyFichaSectionVisibility(fullFicha(), v);
		expect(out.autoria.autores).toHaveLength(0);
		expect(out.autoria.grupos).toHaveLength(0);
	});

	it('fuentes apagadas conservan la autoría pero quitan las evidencias', () => {
		const v = { ...allVisible(), [FICHA_SECTION_IDS.fuentes]: false };
		const out = applyFichaSectionVisibility(fullFicha(), v);
		expect(out.autoria.autores).toHaveLength(1);
		expect(out.autoria.grupos).toHaveLength(1);
		expect(out.autoria.grupos[0].propuestas[0].evidencias).toHaveLength(0);
	});

	it('métrica apagada vacía secuencias y distribución', () => {
		const v = { ...allVisible(), [FICHA_SECTION_IDS.metrica]: false };
		const out = applyFichaSectionVisibility(fullFicha(), v);
		expect(out.metrica.secuencias).toHaveLength(0);
		expect(out.metrica.distribucion_formas).toHaveLength(0);
	});

	it('sinopsis visible se conserva aunque la métrica esté apagada', () => {
		const v = { ...allVisible(), [FICHA_SECTION_IDS.metrica]: false };
		const out = applyFichaSectionVisibility(fullFicha(), v);
		expect(out.metrica.secuencias).toHaveLength(0);
		expect(out.sinopsis_metrica.secuencias).toHaveLength(1);
		expect(out.sinopsis_metrica.secuencias[0]?.sinopsis).toBe('SINOPSIS');
	});

	it('sinopsis apagada se vacía y elimina sinopsis del bloque métrico', () => {
		const v = { ...allVisible(), [FICHA_SECTION_IDS.sinopsisMetrica]: false };
		const out = applyFichaSectionVisibility(fullFicha(), v);
		expect(out.sinopsis_metrica.secuencias).toHaveLength(0);
		expect(out.metrica.secuencias).toHaveLength(1);
		expect(out.metrica.secuencias[0]?.sinopsis).toBeNull();
		expect(out.metrica.distribucion_formas).toHaveLength(1);
	});

	it('observaciones/bibliografía apagadas se vacían sin afectar al resto', () => {
		const v = {
			...allVisible(),
			[FICHA_SECTION_IDS.observaciones]: false,
			[FICHA_SECTION_IDS.bibliografia]: false
		};
		const out = applyFichaSectionVisibility(fullFicha(), v);
		expect(out.obra.observaciones).toBeNull();
		expect(out.obra.bibliografia).toBeNull();
		expect(out.obra.titulo).toBe('Obra'); // resto intacto
		expect(out.sinopsis_metrica.secuencias).toHaveLength(1);
	});

	it('comentarios apagados se vacían', () => {
		const v = { ...allVisible(), [FICHA_SECTION_IDS.comentarios]: false };
		const out = applyFichaSectionVisibility(fullFicha(), v);
		expect(out.comentarios_publicos).toHaveLength(0);
	});

	it('mapa vacío = todo oculto (default seguro)', () => {
		const out = applyFichaSectionVisibility(fullFicha(), {});
		expect(out.autoria.autores).toHaveLength(0);
		expect(out.metrica.distribucion_formas).toHaveLength(0);
		expect(out.sinopsis_metrica.secuencias).toHaveLength(0);
		expect(out.obra.observaciones).toBeNull();
		expect(out.comentarios_publicos).toHaveLength(0);
	});
});

import { describe, expect, it } from 'vitest';
import { buildCommentTargetUrl } from './comment-links';

describe('buildCommentTargetUrl', () => {
	it('links sequence comments to the sequence tab and focused sequence', () => {
		expect(
			buildCommentTargetUrl('obra-1', {
				comentario_id: 'comentario-1',
				secuencia_id: 'secuencia-1'
			})
		).toBe(
			'/dashboard/obras/obra-1?tab=secuencias&focusSecuenciaId=secuencia-1&focusComentarioId=comentario-1'
		);
	});

	it('links jornada comments to the structure tab and focused jornada', () => {
		expect(
			buildCommentTargetUrl('obra-1', {
				comentario_id: 'comentario-2',
				jornada_id: 'jornada-1'
			})
		).toBe(
			'/dashboard/obras/obra-1?tab=estructura&focusJornadaId=jornada-1&focusComentarioId=comentario-2'
		);
	});

	it('links cuadro comments to the structure tab and focused cuadro', () => {
		expect(
			buildCommentTargetUrl('obra-1', {
				comentario_id: 'comentario-3',
				cuadro_id: 'cuadro-1'
			})
		).toBe(
			'/dashboard/obras/obra-1?tab=estructura&focusCuadroId=cuadro-1&focusComentarioId=comentario-3'
		);
	});

	it('links section comments to their equivalent tab', () => {
		expect(
			buildCommentTargetUrl('obra-1', {
				comentario_id: 'comentario-4',
				seccion: 'observaciones'
			})
		).toBe('/dashboard/obras/obra-1?tab=observaciones&focusComentarioId=comentario-4');
	});

	it('falls back to revision without context', () => {
		expect(
			buildCommentTargetUrl('obra-1', {
				comentario_id: 'comentario-5'
			})
		).toBe('/dashboard/obras/obra-1?tab=revision&focusComentarioId=comentario-5');
	});
});

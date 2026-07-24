import { describe, expect, it } from 'vitest';
import { buildRevisionChecklist, type RevisionChecklistInput } from './revision-checklist';

function completeInput(): RevisionChecklistInput {
	return {
		obra: {
			titulo: 'La obra',
			genero_id: 'genero',
			edicion: 'Edición base',
			observaciones: 'a'.repeat(101),
			bibliografia: 'Referencia',
			editor_asignado: 'editor'
		},
		jornadas: [{ jornada_id: 'j1', jornada_num: 1, v_ini: 1, v_fin: 100 }],
		cuadros: [
			{
				cuadro_id: 'c1',
				cuadro_num: 1,
				jornada_id: 'j1',
				v_ini: 1,
				v_fin: 100
			}
		],
		secuencias: [
			{
				secuencia_id: 's1',
				v_ini: 1,
				v_fin: 100,
				estrofa_tipo_id: 'estrofa',
				inaugura_espacio: false,
				versos_partidos: false,
				evocacion_metrica: false,
				evocacion_metrica_texto: null,
				intervencion_personajes_femeninos: 'sin_intervencion',
				intervencion_figuras_donaire: 'sin_intervencion',
				intervencion_personajes_sobrenaturales: 'sin_intervencion',
				sinopsis: 'Sinopsis'
			}
		],
		autoriaGroupCount: 1
	};
}

describe('revision checklist', () => {
	it('marks a complete work as ready', () => {
		const summary = buildRevisionChecklist(completeInput());

		expect(summary.required.every((item) => item.done)).toBe(true);
		expect(summary.recommendations.every((item) => item.done)).toBe(true);
	});

	it('counts sequences with any pending editorial field', () => {
		const input = completeInput();
		input.secuencias[0].versos_partidos = null;
		input.secuencias.push({
			...input.secuencias[0],
			secuencia_id: 's2',
			v_ini: 101,
			v_fin: 120,
			versos_partidos: false,
			evocacion_metrica: true,
			evocacion_metrica_texto: ''
		});

		const summary = buildRevisionChecklist(input);
		const item = summary.required.find((candidate) => candidate.id === 'sequence-fields');

		expect(summary.pendingSequenceCount).toBe(2);
		expect(item).toMatchObject({ done: false, detail: '2 secuencias pendientes' });
	});

	it('detects jornadas without cuadros and duplicated numbering', () => {
		const input = completeInput();
		input.jornadas.push({ jornada_id: 'j2', jornada_num: 1, v_ini: 101, v_fin: 200 });

		const summary = buildRevisionChecklist(input);

		expect(summary.required.find((item) => item.id === 'structure')).toMatchObject({
			done: false,
			detail: '1 jornada sin cuadros'
		});
		expect(summary.required.find((item) => item.id === 'structure-numbering')?.done).toBe(
			false
		);
	});

	it('accepts a documented authorship group regardless of ambiguity', () => {
		const input = completeInput();
		input.autoriaGroupCount = 2;

		expect(
			buildRevisionChecklist(input).required.find((item) => item.id === 'authorship')
		).toMatchObject({ done: true, detail: '2 grupos de autoría' });
	});
});

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
				tiene_anotacion_metrica: true,
				inaugura_espacio: true,
				versos_partidos: false,
				intervencion_personajes_femeninos: 'sin_intervencion',
				intervencion_figuras_donaire: 'sin_intervencion',
				intervencion_personajes_sobrenaturales: 'sin_intervencion',
				evento_sobrenatural: false,
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
			intervencion_figuras_donaire: null
		});

		const summary = buildRevisionChecklist(input);
		const item = summary.required.find((candidate) => candidate.id === 'sequence-fields');

		expect(summary.pendingSequenceCount).toBe(2);
		expect(item).toMatchObject({ done: false, detail: '2 secuencias pendientes' });
	});

	it('cuenta pendiente la secuencia que no dice si hay evento sobrenatural', () => {
		const input = completeInput();
		input.secuencias[0].evento_sobrenatural = null;

		const summary = buildRevisionChecklist(input);

		expect(summary.pendingSequenceCount).toBe(1);
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

/**
 * La forma solo puede venir del catálogo nuevo: `estrofa_tipo_id` dejó de contar el 7 de septiembre
 * de 2026, y una secuencia que solo lo tenga sigue sin forma.
 */
describe('la forma viene del catálogo nuevo', () => {
	it('da por completa la secuencia anotada', () => {
		const input = completeInput();
		input.secuencias[0].tiene_anotacion_metrica = true;

		const summary = buildRevisionChecklist(input);
		expect(summary.pendingSequenceCount).toBe(0);
	});

	it('reclama la forma cuando no está anotada', () => {
		const input = completeInput();
		input.secuencias[0].tiene_anotacion_metrica = false;

		const summary = buildRevisionChecklist(input);
		expect(summary.pendingSequenceCount).toBe(1);
	});
});

describe('inauguración de espacio', () => {
	function item(input: RevisionChecklistInput, id: string) {
		return [...buildRevisionChecklist(input).required, ...buildRevisionChecklist(input).recommendations].find(
			(candidate) => candidate.id === id
		);
	}

	it('exige que alguna secuencia inaugure espacio', () => {
		const input = completeInput();
		input.secuencias[0].inaugura_espacio = false;

		expect(item(input, 'space-inauguration')).toMatchObject({ done: false });
		expect(item(input, 'space-inauguration')?.detail).toMatch(/Ninguna secuencia/);
	});

	it('exige que la primera secuencia de la obra lo haga aunque otras lo hagan', () => {
		const input = completeInput();
		input.jornadas[0].v_fin = 200;
		input.cuadros[0].v_fin = 200;
		input.secuencias[0].inaugura_espacio = false;
		input.secuencias.push({ ...input.secuencias[0], secuencia_id: 's2', v_ini: 101, v_fin: 200, inaugura_espacio: true });

		expect(item(input, 'space-inauguration')).toMatchObject({ done: false });
		expect(item(input, 'space-inauguration')?.detail).toMatch(/primera secuencia \(vv\. 1-100\)/);
	});

	it('no reclama nada cuando la primera lo inaugura y da por bueno el resto', () => {
		const input = completeInput();
		input.secuencias[0].inaugura_espacio = null;
		// Sin responder cuenta como campo pendiente, no como inauguración fallida.
		expect(item(input, 'space-inauguration')).toMatchObject({ done: false });
		input.secuencias[0].inaugura_espacio = true;
		expect(item(input, 'space-inauguration')).toMatchObject({ done: true });
	});

	it('recomienda mirar la primera secuencia de cada jornada que no inaugura espacio', () => {
		const input = completeInput();
		input.jornadas.push({ jornada_id: 'j2', jornada_num: 2, v_ini: 101, v_fin: 200 });
		input.cuadros.push({ cuadro_id: 'c2', cuadro_num: 1, jornada_id: 'j2', v_ini: 101, v_fin: 200 });
		input.secuencias.push({ ...input.secuencias[0], secuencia_id: 's2', v_ini: 101, v_fin: 200, inaugura_espacio: false });

		expect(item(input, 'jornada-openings')).toMatchObject({
			done: false,
			detail: 'Revisar la primera secuencia de la jornada 2'
		});
	});
});

describe('cobertura de las secuencias', () => {
	function coverage(input: RevisionChecklistInput) {
		return buildRevisionChecklist(input).required.find((candidate) => candidate.id === 'sequence-coverage');
	}

	it('está completa cuando las secuencias van del primer verso al último', () => {
		expect(coverage(completeInput())).toMatchObject({ done: true });
	});

	it('señala los huecos entre secuencias y el final sin anotar', () => {
		const input = completeInput();
		input.jornadas[0].v_fin = 300;
		input.cuadros[0].v_fin = 300;
		input.secuencias[0].v_fin = 80;
		input.secuencias.push({ ...input.secuencias[0], secuencia_id: 's2', v_ini: 101, v_fin: 250 });

		expect(coverage(input)).toMatchObject({
			done: false,
			detail: 'Sin anotar 70 versos: vv. 81-100, vv. 251-300'
		});
	});

	it('señala el arranque sin anotar', () => {
		const input = completeInput();
		input.secuencias[0].v_ini = 5;

		expect(coverage(input)?.detail).toBe('Sin anotar 4 versos: vv. 1-4');
	});
});

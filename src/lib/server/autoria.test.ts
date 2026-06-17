import { describe, expect, it } from 'vitest';
import { validateAutoriaPayload } from './autoria';

const tipoId = '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7';
const individualId = '11111111-1111-4111-8111-111111111111';
const colaboradaId = '22222222-2222-4222-8222-222222222222';
const desconocidaId = '33333333-3333-4333-8333-333333333333';
const autorA = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const autorB = 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';

function evidencia() {
	return {
		atribucion_evidencia_id: null,
		tipo_atribucion_id: tipoId,
		fuente_autoria: null
	};
}

function options() {
	return {
		jornadaIds: new Set<string>(),
		tipoIds: new Set([tipoId]),
		composicionTermById: new Map([
			[individualId, 'individual'],
			[colaboradaId, 'colaborada'],
			[desconocidaId, 'desconocida']
		]),
		authorIds: new Set([autorA, autorB])
	};
}

describe('validateAutoriaPayload', () => {
	it('accepts an individual proposal with one author and metric profile flag', () => {
		const issues = validateAutoriaPayload(
			{
				grupos: [
					{
						grupo_atribucion_id: null,
						jornada_id: null,
						propuestas: [
							{
								atribucion_id: null,
								composicion_autoria_id: individualId,
								perfil_metrico: true,
								autores: [{ autor_id: autorA, orden: 1 }],
								evidencias: [evidencia()]
							}
						]
					}
				]
			},
			options()
		);

		expect(issues).toHaveLength(0);
	});

	it('rejects invalid author counts by composition', () => {
		const issues = validateAutoriaPayload(
			{
				grupos: [
					{
						grupo_atribucion_id: null,
						jornada_id: null,
						propuestas: [
							{
								atribucion_id: null,
								composicion_autoria_id: individualId,
								perfil_metrico: false,
								autores: [
									{ autor_id: autorA, orden: 1 },
									{ autor_id: autorB, orden: 2 }
								],
								evidencias: [evidencia()]
							},
							{
								atribucion_id: null,
								composicion_autoria_id: colaboradaId,
								perfil_metrico: false,
								autores: [{ autor_id: autorA, orden: 1 }],
								evidencias: [evidencia()]
							}
						]
					}
				]
			},
			options()
		);

		expect(issues.map((issue) => issue.message)).toEqual([
			'La tipologia individual exige exactamente 1 autor.',
			'La tipologia colaborada exige 2 o mas autores.'
		]);
	});

	it('accepts unknown authorship with evidences and no authors', () => {
		const issues = validateAutoriaPayload(
			{
				grupos: [
					{
						grupo_atribucion_id: null,
						jornada_id: null,
						propuestas: [
							{
								atribucion_id: null,
								composicion_autoria_id: desconocidaId,
								perfil_metrico: false,
								autores: [],
								evidencias: [evidencia()]
							}
						]
					}
				]
			},
			options()
		);

		expect(issues).toHaveLength(0);
	});

	it('rejects unknown authorship with selected authors', () => {
		const issues = validateAutoriaPayload(
			{
				grupos: [
					{
						grupo_atribucion_id: null,
						jornada_id: null,
						propuestas: [
							{
								atribucion_id: null,
								composicion_autoria_id: desconocidaId,
								perfil_metrico: false,
								autores: [{ autor_id: autorA, orden: 1 }],
								evidencias: [evidencia()]
							}
						]
					}
				]
			},
			options()
		);

		expect(issues.map((issue) => issue.message)).toContain(
			'La tipologia desconocida no permite autores.'
		);
	});

	it('rejects metric profile flag for non-individual proposals', () => {
		const issues = validateAutoriaPayload(
			{
				grupos: [
					{
						grupo_atribucion_id: null,
						jornada_id: null,
						propuestas: [
							{
								atribucion_id: null,
								composicion_autoria_id: colaboradaId,
								perfil_metrico: true,
								autores: [
									{ autor_id: autorA, orden: 1 },
									{ autor_id: autorB, orden: 2 }
								],
								evidencias: [evidencia()]
							}
						]
					}
				]
			},
			options()
		);

		expect(issues.map((issue) => issue.message)).toContain(
			'Solo una propuesta individual con un unico autor puede alimentar perfiles metricos.'
		);
	});

	it('rejects proposals without evidences', () => {
		const issues = validateAutoriaPayload(
			{
				grupos: [
					{
						grupo_atribucion_id: null,
						jornada_id: null,
						propuestas: [
							{
								atribucion_id: null,
								composicion_autoria_id: individualId,
								perfil_metrico: false,
								autores: [{ autor_id: autorA, orden: 1 }],
								evidencias: []
							}
						]
					}
				]
			},
			options()
		);

		expect(issues.map((issue) => issue.message)).toContain('Cada propuesta debe tener al menos una evidencia.');
	});

	it('rejects repeated evidence type in one proposal', () => {
		const issues = validateAutoriaPayload(
			{
				grupos: [
					{
						grupo_atribucion_id: null,
						jornada_id: null,
						propuestas: [
							{
								atribucion_id: null,
								composicion_autoria_id: individualId,
								perfil_metrico: false,
								autores: [{ autor_id: autorA, orden: 1 }],
								evidencias: [evidencia(), evidencia()]
							}
						]
					}
				]
			},
			options()
		);

		expect(issues.map((issue) => issue.message)).toContain('No puede repetirse el tipo de evidencia en una propuesta.');
	});

	it('rejects duplicate proposals in the same group', () => {
		const proposal = {
			atribucion_id: null,
			composicion_autoria_id: individualId,
			perfil_metrico: false,
			autores: [{ autor_id: autorA, orden: 1 }],
			evidencias: [evidencia()]
		};
		const issues = validateAutoriaPayload(
			{
				grupos: [
					{
						grupo_atribucion_id: null,
						jornada_id: null,
						propuestas: [proposal, proposal]
					}
				]
			},
			options()
		);

		expect(issues.map((issue) => issue.message)).toContain(
			'No puede haber dos propuestas iguales en el mismo grupo; anade evidencias a una sola propuesta.'
		);
	});

	it('rejects more than one global group', () => {
		const proposal = {
			atribucion_id: null,
			composicion_autoria_id: individualId,
			perfil_metrico: false,
			autores: [{ autor_id: autorA, orden: 1 }],
			evidencias: [evidencia()]
		};
		const issues = validateAutoriaPayload(
			{
				grupos: [
					{
						grupo_atribucion_id: null,
						jornada_id: null,
						propuestas: [proposal]
					},
					{
						grupo_atribucion_id: null,
						jornada_id: null,
						propuestas: [proposal]
					}
				]
			},
			options()
		);

		expect(issues.map((issue) => issue.message)).toContain(
			'Solo puede existir una autoría global para la obra completa.'
		);
	});

	it('rejects more than one group for the same jornada', () => {
		const proposal = {
			atribucion_id: null,
			composicion_autoria_id: individualId,
			perfil_metrico: false,
			autores: [{ autor_id: autorA, orden: 1 }],
			evidencias: [evidencia()]
		};
		const issues = validateAutoriaPayload(
			{
				grupos: [
					{
						grupo_atribucion_id: null,
						jornada_id: 'jornada-1',
						propuestas: [proposal]
					},
					{
						grupo_atribucion_id: null,
						jornada_id: 'jornada-1',
						propuestas: [proposal]
					}
				]
			},
			{
				...options(),
				jornadaIds: new Set(['jornada-1'])
			}
		);

		expect(issues.map((issue) => issue.message)).toContain(
			'Solo puede existir un grupo de autoría por jornada.'
		);
	});
});

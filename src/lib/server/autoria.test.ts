import { describe, expect, it } from 'vitest';
import { validateAutoriaPayload } from './autoria';

const tipoId = '4d5d5f74-3571-4e14-b6d5-558f2ad9fdb7';
const individualId = '11111111-1111-4111-8111-111111111111';
const colaboradaId = '22222222-2222-4222-8222-222222222222';
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
			[colaboradaId, 'colaborada']
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
								atribucion_preferente: true,
								usable_perfil_metrico: true,
								disponible_laboratorio: true,
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
								atribucion_preferente: false,
								usable_perfil_metrico: false,
								disponible_laboratorio: true,
								autores: [
									{ autor_id: autorA, orden: 1 },
									{ autor_id: autorB, orden: 2 }
								],
								evidencias: [evidencia()]
							},
							{
								atribucion_id: null,
								composicion_autoria_id: colaboradaId,
								atribucion_preferente: false,
								usable_perfil_metrico: false,
								disponible_laboratorio: true,
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
			'La composicion individual exige exactamente 1 autor.',
			'La composicion colaborada exige 2 o mas autores.'
		]);
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
								atribucion_preferente: false,
								usable_perfil_metrico: true,
								disponible_laboratorio: true,
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
								atribucion_preferente: false,
								usable_perfil_metrico: false,
								disponible_laboratorio: true,
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
								atribucion_preferente: false,
								usable_perfil_metrico: false,
								disponible_laboratorio: true,
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
			atribucion_preferente: false,
			usable_perfil_metrico: false,
			disponible_laboratorio: true,
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
			atribucion_preferente: false,
			usable_perfil_metrico: false,
			disponible_laboratorio: true,
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
			atribucion_preferente: false,
			usable_perfil_metrico: false,
			disponible_laboratorio: true,
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

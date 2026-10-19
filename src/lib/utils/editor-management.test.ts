import { describe, expect, it } from 'vitest';
import {
	bulkAssignmentsSchema,
	createWorksSchema,
	editorCreateSchema,
	assignmentSnapshot
} from './editor-management';
import { canManageEditors } from './permissions';

const id = 'a0545e64-475c-4f94-9ad5-45de872dc2f5';
const work = { obra_id: id, editor_asignado: null, reviewer_ids: [] };

describe('gestión editorial', () => {
	it('reserva la gestión a administración e IP', () => {
		expect(canManageEditors('admin')).toBe(true);
		expect(canManageEditors('ip')).toBe(true);
		for (const role of ['editor', 'revisor', 'anon', ''])
			expect(canManageEditors(role)).toBe(false);
	});
	it('normaliza los datos de alta sin admitir roles enviados por el cliente', () => {
		const value = editorCreateSchema.parse({
			nombre_completo: ' Ana ',
			email: ' ANA@EXAMPLE.COM ',
			institucion: '',
			orcid: '',
			role: 'admin'
		});
		expect(value).toEqual({
			nombre_completo: 'Ana',
			email: 'ana@example.com',
			institucion: null,
			orcid: null
		});
	});
	it('rechaza correos, ORCID y longitudes inválidos', () => {
		const base = { nombre_completo: 'Ana', email: 'ana@example.com', institucion: '', orcid: '' };
		for (const patch of [
			{ email: 'sin-correo' },
			{ nombre_completo: '' },
			{ orcid: 'texto' },
			{ institucion: 'a'.repeat(201) }
		]) {
			expect(editorCreateSchema.safeParse({ ...base, ...patch }).success).toBe(false);
		}
	});
	it('rechaza lotes vacíos, duplicados, sin snapshot o de más de 500 obras', () => {
		for (const works of [
			[],
			[work, work],
			[{ obra_id: id }],
			Array.from({ length: 501 }, () => work)
		]) {
			expect(
				bulkAssignmentsSchema.safeParse({ operation: 'editor', target: id, works }).success
			).toBe(false);
		}
		expect(
			bulkAssignmentsSchema.safeParse({ operation: 'editor', target: id, works: [work] }).success
		).toBe(true);
	});
	it('evita crear dos veces el mismo título dentro de un lote', () => {
		expect(
			createWorksSchema.safeParse({
				titles: [' La vida es sueño ', 'la vida es sueno'],
				editor_asignado: id
			}).success
		).toBe(false);
		expect(
			createWorksSchema.safeParse({ titles: ['Primera', 'Segunda'], editor_asignado: id }).success
		).toBe(true);
	});
	it('conserva la selección revisada sin enviar campos ajenos a las asignaciones', () => {
		const reviewers = ['b', 'a'];
		expect(assignmentSnapshot([{ ...work, titulo: 'Prueba', reviewer_ids: reviewers }])).toEqual([
			{ ...work, reviewer_ids: ['a', 'b'] }
		]);
		expect(reviewers).toEqual(['b', 'a']);
	});
});

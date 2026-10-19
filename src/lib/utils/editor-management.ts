import { z } from 'zod';
import type { AssignmentWork } from '$lib/types/editor-management.types';

const optionalText = (max: number) =>
	z
		.string()
		.trim()
		.max(max)
		.transform((v) => v || null);
const editorFields = {
	nombre_completo: z.string().trim().min(1, 'El nombre es obligatorio').max(200),
	institucion: optionalText(200),
	orcid: z
		.string()
		.trim()
		.regex(/^(?:\d{4}-\d{4}-\d{4}-\d{3}[\dX])?$/, 'ORCID inválido')
		.transform((v) => v || null)
};
export const editorCreateSchema = z.object({
	...editorFields,
	email: z.string().trim().toLowerCase().email('Correo inválido').max(255)
});
export const editorUpdateSchema = z.object({ ...editorFields, activo: z.boolean() });
export const bulkAssignmentsSchema = z.object({
	operation: z.enum(['editor', 'add_reviewer', 'remove_reviewer']),
	target: z.string().uuid(),
	works: z
		.array(
			z.object({
				obra_id: z.string().uuid(),
				editor_asignado: z.string().uuid().nullable(),
				reviewer_ids: z.array(z.string().uuid()).max(100)
			})
		)
		.min(1)
		.max(500)
		.refine(
			(rows) => new Set(rows.map((row) => row.obra_id)).size === rows.length,
			'Hay obras repetidas en la selección'
		)
});
export const createWorksSchema = z.object({
	titles: z
		.array(z.string().trim().min(1).max(300))
		.min(1)
		.max(100)
		.refine(
			(titles) => new Set(titles.map(normalizeWorkTitle)).size === titles.length,
			'Hay títulos repetidos'
		),
	editor_asignado: z.string().uuid()
});

export function normalizeWorkTitle(title: string) {
	return title.normalize('NFD').replace(/\p{M}/gu, '').trim().toLowerCase();
}

export function assignmentSnapshot(works: AssignmentWork[]) {
	return works.map(({ obra_id, editor_asignado, reviewer_ids }) => ({
		obra_id,
		editor_asignado,
		reviewer_ids: [...reviewer_ids].sort()
	}));
}

export const invitationLabels = {
	pending: 'Sin enviar',
	sent: 'Enviada',
	accepted: 'Aceptada'
};

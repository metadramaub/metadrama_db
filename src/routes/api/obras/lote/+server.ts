import { json } from '@sveltejs/kit';
import type { RequestHandler } from './$types';
import { requireEditorManager } from '$lib/server/editor-management';
import { createObras } from '$lib/server/create-obras';
import { createWorksSchema } from '$lib/utils/editor-management';
import { validationErrorResponse } from '$lib/server/http';

export const POST: RequestHandler = async ({ locals, request }) => {
	await requireEditorManager(locals);
	const parsed = createWorksSchema.safeParse(await request.json().catch(() => null));
	if (!parsed.success) return validationErrorResponse(parsed.error);
	const works = await createObras(locals, parsed.data.titles, parsed.data.editor_asignado);
	return json({ obras: works }, { status: 201 });
};

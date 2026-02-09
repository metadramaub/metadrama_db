import { json } from '@sveltejs/kit';
import type { z } from 'zod';

export function validationErrorResponse(error: z.ZodError) {
	return json(
		{
			error: 'validation_error',
			details: error.issues.map((issue) => ({
				path: issue.path.join('.'),
				message: issue.message
			}))
		},
		{ status: 422 }
	);
}

export function forbiddenResponse(message: string) {
	return json({ error: 'forbidden', message }, { status: 403 });
}

export function conflictResponse(message: string, details?: unknown) {
	return json({ error: 'conflict', message, details }, { status: 409 });
}

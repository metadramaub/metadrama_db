import { json } from '@sveltejs/kit';
import type { z } from 'zod';

export function validationErrorResponse(error: z.ZodError) {
	const details = error.issues.map((issue) => ({
		path: issue.path.join('.'),
		message: issue.message
	}));
	// Sin un `message` legible, quien consuma la respuesta solo puede enseñar un texto
	// genérico y el motivo real se pierde.
	const message = details
		.slice(0, 3)
		.map((detail) => (detail.path ? `${detail.path}: ${detail.message}` : detail.message))
		.join(' · ');
	return json(
		{
			error: 'validation_error',
			message: details.length > 3 ? `${message} · y ${details.length - 3} más` : message,
			details
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

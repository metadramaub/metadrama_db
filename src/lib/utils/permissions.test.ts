import { describe, expect, it } from 'vitest';
import { canTransitionState, canReadAllObras, canEditByState, normalizeRole } from './permissions';

describe('permissions', () => {
	it('normalizes role names', () => {
		expect(normalizeRole('IP')).toBe('ip');
		expect(normalizeRole(' admin ')).toBe('admin');
	});

	it('validates read access scope', () => {
		expect(canReadAllObras('admin')).toBe(true);
		expect(canReadAllObras('ip')).toBe(true);
		expect(canReadAllObras('revisor')).toBe(true);
		expect(canReadAllObras('editor')).toBe(false);
	});

	it('enforces editor state transitions', () => {
		expect(canTransitionState('editor', 'borrador', 'pendiente')).toBe(true);
		expect(canTransitionState('editor', 'pendiente', 'borrador')).toBe(true);
		expect(canTransitionState('editor', 'pendiente', 'validado')).toBe(false);
	});

	it('enforces revisor state transitions', () => {
		expect(canTransitionState('revisor', 'pendiente', 'en_revision')).toBe(true);
		expect(canTransitionState('revisor', 'en_revision', 'validado')).toBe(true);
		expect(canTransitionState('revisor', 'validado', 'publicado')).toBe(false);
	});

	it('allows admin/ip to transition any state', () => {
		expect(canTransitionState('admin', 'borrador', 'publicado')).toBe(true);
		expect(canTransitionState('ip', 'en_revision', 'borrador')).toBe(true);
	});

	it('enforces editable states for editor', () => {
		expect(canEditByState('editor', 'borrador')).toBe(true);
		expect(canEditByState('editor', 'pendiente')).toBe(true);
		expect(canEditByState('editor', 'validado')).toBe(false);
	});
});

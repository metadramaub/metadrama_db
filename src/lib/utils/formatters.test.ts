import { describe, expect, it } from 'vitest';
import { clampPercentage } from './formatters';

describe('formatters', () => {
	it('clamps percentage boundaries', () => {
		expect(clampPercentage(-2)).toBe(0);
		expect(clampPercentage(37.4)).toBe(37);
		expect(clampPercentage(125)).toBe(100);
	});
});

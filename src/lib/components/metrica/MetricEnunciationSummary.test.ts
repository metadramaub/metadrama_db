import { describe, expect, it } from 'vitest';
import { render } from 'svelte/server';
import MetricEnunciationSummary from './MetricEnunciationSummary.svelte';

const text = (html: string) => html.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ');

describe('presentación de prosa y canto', () => {
	it('muestra presencia y referencias de prosa sin atribuirle versos ni porcentaje', () => {
		const { body } = render(MetricEnunciationSummary, {
			props: {
				rows: [
					{
						tipo: 'prosa',
						formas: ['Romance'],
						localizaciones: [{ v_anterior: 56, v_posterior: 57 }]
					}
				]
			}
		});
		expect(text(body)).toContain('Presente');
		expect(text(body)).toContain('Entre vv. 56 y 57');
		expect(text(body)).not.toContain('2 vv.');
		expect(text(body)).not.toContain('%');
	});

	it('mantiene la extensión y el porcentaje de los versos cantados', () => {
		const { body } = render(MetricEnunciationSummary, {
			props: {
				rows: [
					{
						tipo: 'cantado',
						formas: ['Romance'],
						versos: 6,
						porcentaje: 6
					}
				]
			}
		});
		expect(text(body)).toContain('6 vv.');
		expect(text(body)).toContain('6 %');
	});
});

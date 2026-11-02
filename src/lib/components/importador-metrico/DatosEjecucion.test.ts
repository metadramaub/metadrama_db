import { describe, expect, it } from 'vitest';
import { render } from 'svelte/server';
import DatosEjecucion from './DatosEjecucion.svelte';
import { metadatosIniciales } from '$lib/server/importador-metrico/vista-previa';

describe('datos opcionales de ejecución', () => {
	it('ofrece campos editables sin exigir identidad o parámetros desconocidos', () => {
		const { body } = render(DatosEjecucion, { props: { metadatos: { ...metadatosIniciales(), ia_generador: 'ChatGPT', ia_modo: 'Instant' } } });
		for (const nombre of ['ia_generador', 'ia_modelo', 'ia_modo', 'ia_plan', 'ia_parametros']) expect(body).toContain(`name="${nombre}"`);
		expect(body).toContain('Instant');
		expect(body).not.toContain(' required');
	});
});

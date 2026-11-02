import { describe, expect, it } from 'vitest';
import { informeEquivalencias, informeSeguimiento } from './informes.mjs';

describe('informes del piloto', () => {
	it('acredita guardados por identidad, nunca por coincidencia de título', () => {
		const lote = { obras: [
			{ numero: 1, titulo: 'La misma', obra_id: 'obra-1', revision: 'Revisada' },
			{ numero: 2, titulo: 'La misma', revision: 'Aplazada', observacion: 'Numeración pendiente' }
		] };
		const informe = informeSeguimiento(lote, { consultado_en: '2026-11-02', importaciones: [
			{ titulo: 'La misma', obra_id: 'obra-1', importacion_id: 'imp-1', importado_en: '2026-11-02' }
		] });
		expect(informe).toContain('1 guardadas de 2');
		expect(informe).toContain('Sin guardado confirmado | Aplazada. Numeración pendiente');
	});
	it('una candidata no cubre una forma y una forma no cubre sus arquitecturas', () => {
		const catalogo = { fecha_consulta_formas: '2026-11-02', formas: [
			{ nombre: 'Forma A', slug: 'a', arquitecturas: [{ nombre: 'Arquitectura A', slug: 'arq' }] },
			{ nombre: 'Forma B', slug: 'b', arquitecturas: [] },
			{ nombre: 'Forma C', slug: 'c', arquitecturas: [] }
		] };
		const reglas = { version: 'v1', reglas: [
			{ id: 'directa', literales: ['nombre'], tipo: 'equivalencia_propuesta', candidatas: [{ forma_slug: 'a', arquitectura_slug: null }], fundamento: 'Sin inferencias' },
			{ id: 'ambigua', literales: ['dudoso'], tipo: 'candidatas_orientativas', candidatas: [{ forma_slug: 'b', arquitectura_slug: null }], fundamento: 'Pendiente' }
		] };
		const informe = informeEquivalencias(catalogo, reglas, [{ literal: 'rima | texto', origenes: ['Obra, t01'], resultados: new Set(['Sin equivalencia']) }]);
		expect(informe).toContain('3 formas; 2 sin regla directa');
		expect(informe).toContain('| Forma B | — | ambigua |');
		expect(informe).toContain('| Forma C | — | — |');
		expect(informe).toContain('| Forma A | Arquitectura A | — |');
		expect(informe).toContain('rima \\| texto');
	});
	it('sitúa las decisiones y el resumen antes de la evidencia, conservando el detalle en el anexo', () => {
		const catalogo = { fecha_consulta_formas: '2026-11-02', formas: [{ nombre: 'Romance', slug: 'romance', arquitecturas: [] }] };
		const reglas = { version: 'v1', reglas: [{ id: 'letrilla', literales: ['letrilla'], tipo: 'candidatas_orientativas', candidatas: [{ forma_slug: 'romance', arquitectura_slug: null }], fundamento: 'Nombre ambiguo' }] };
		const observaciones = [{ literal: 'letrilla', origenes: ['Obra, t01 (1–8)'], resultados: new Set(['Sin resolver']), apariciones: [{ obra: 'Obra', fila: 't01', v_ini: 1, v_fin: 8, regla_id: 'letrilla', formas: ['romance'], formas_identificadas: [], notas: ['Una nota de la edición.'] }] }];
		const informe = informeEquivalencias(catalogo, reglas, observaciones, [], { decisiones: [{ asunto: 'Letrilla', actual: 'Sin resolver', propuesta: 'Conservar literal', decidir: 'Revisar candidatas' }], casos: 'Caso complejo conservado', evidencias: ['- archivo y hash'] });
		const secciones = ['## Decisiones pendientes', '## Tabla resumen', '## Procedencia en las obras del piloto', '## Casos complejos', '## Anexo técnico y documental'];
		for (let i = 1; i < secciones.length; i++) expect(informe.indexOf(secciones[i])).toBeGreaterThan(informe.indexOf(secciones[i - 1]));
		expect(informe).toContain('[letrilla](#termino-1) (candidata)');
		expect(informe).toContain('Solo candidata; sin equivalencia directa');
		expect(informe).toContain('Caso complejo conservado');
		expect(informe).toContain('Una nota de la edición.');
		expect(informe).toContain('#### letrilla');
		expect(informe).toContain('archivo y hash');
	});
});

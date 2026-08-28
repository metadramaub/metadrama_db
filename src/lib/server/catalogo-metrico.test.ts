import { beforeEach, describe, expect, it } from 'vitest';
import { loadMetricCatalog, olvidarCatalogoMetricoEnMemoria } from './catalogo-metrico';

/**
 * El catálogo se lee de memoria mientras su revisión no cambie.
 *
 * Construirlo son unas treinta consultas, cuatro de ellas vistas derivadas que recorren el catálogo
 * entero: medidas por PostgREST iban entre 750 y 1.500 ms cada una y llegaron a dar un 500 por
 * `statement timeout`. Como solo cambia por migración, basta con preguntar por la revisión.
 *
 * Lo que se fija aquí es justo eso: que con la misma revisión **no se vuelve a preguntar**, que con
 * otra sí, y que el sandbox del editor —que cambia cada vez que alguien guarda— nunca se guarda.
 */
function baseDeMentira(revision: number, llamadas: Map<string, number>) {
	const from = (tabla: string) => {
		llamadas.set(tabla, (llamadas.get(tabla) ?? 0) + 1);
		const constructor: Record<string, unknown> = {
			select: () => constructor,
			order: () => constructor,
			eq: () => constructor,
			not: () => constructor,
			in: () => constructor,
			limit: () => constructor,
			is: () => constructor,
			gt: () => constructor,
			filter: () => constructor,
			maybeSingle: () =>
				Promise.resolve({ data: { revision, modelo_version: 99 }, error: null }),
			then: (resolver: (valor: unknown) => unknown) => resolver({ data: [], error: null })
		};
		return constructor;
	};
	return { from } as unknown as App.Locals['supabase'];
}

describe('el catálogo se guarda en memoria por su revisión', () => {
	beforeEach(() => olvidarCatalogoMetricoEnMemoria());

	it('no vuelve a preguntar por el catálogo si la revisión no ha cambiado', async () => {
		const llamadas = new Map<string, number>();
		await loadMetricCatalog(baseDeMentira(4400, llamadas));
		await loadMetricCatalog(baseDeMentira(4400, llamadas));
		await loadMetricCatalog(baseDeMentira(4400, llamadas));

		// La revisión se pregunta siempre: es lo que mantiene honesta la caché.
		expect(llamadas.get('catalogo_metrico_estado')).toBe(3);
		// El catálogo, una sola vez.
		expect(llamadas.get('formas_metricas')).toBe(1);
		expect(llamadas.get('opciones_eleccion_metrica')).toBe(1);
		expect(llamadas.get('grupos_eleccion_metrica_resueltos')).toBe(1);
		expect(llamadas.get('arquitecturas_reglas_longitud')).toBe(1);
	});

	it('reconstruye cuando la revisión cambia', async () => {
		const llamadas = new Map<string, number>();
		await loadMetricCatalog(baseDeMentira(4400, llamadas));
		await loadMetricCatalog(baseDeMentira(4401, llamadas));

		expect(llamadas.get('formas_metricas')).toBe(2);
		expect(llamadas.get('opciones_eleccion_metrica')).toBe(2);
	});

	it('nunca guarda el sandbox del editor, que cambia cada vez que alguien escribe', async () => {
		const llamadas = new Map<string, number>();
		await loadMetricCatalog(baseDeMentira(4400, llamadas));
		await loadMetricCatalog(baseDeMentira(4400, llamadas));

		expect(llamadas.get('anotaciones_metricas')).toBe(2);
		expect(llamadas.get('anotacion_realizaciones')).toBe(2);
		expect(llamadas.get('anotacion_elecciones_resueltas')).toBe(2);
	});
});

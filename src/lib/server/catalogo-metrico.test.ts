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
			range: () => constructor,
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
		await loadMetricCatalog(baseDeMentira(4400, llamadas), { incluirSandbox: true });
		await loadMetricCatalog(baseDeMentira(4400, llamadas), { incluirSandbox: true });

		expect(llamadas.get('anotaciones_metricas')).toBe(2);
		expect(llamadas.get('anotacion_realizaciones')).toBe(2);
		expect(llamadas.get('anotacion_elecciones_resueltas')).toBe(2);
	});

	it('abrir una obra no descarga las anotaciones del laboratorio ni de otras obras', async () => {
		const llamadas = new Map<string, number>();
		const frio = await loadMetricCatalog(baseDeMentira(4400, llamadas));
		const caliente = await loadMetricCatalog(baseDeMentira(4400, llamadas));
		for (const tabla of ['anotacion_escenarios_prueba','anotaciones_metricas','anotacion_realizaciones','anotacion_elecciones_resueltas','anotacion_desviaciones']) {
			expect(llamadas.has(tabla)).toBe(false);
		}
		expect(frio.editorSandbox.sequences).toEqual([]);
		expect(caliente.editorSandbox.sequences).toEqual([]);
	});
});

/**
 * Una base que se porta como PostgREST: ordena por lo que se le pide, aplica el rango y **nunca
 * devuelve más de 1000 filas**, sin avisar. Solo `opciones_eleccion_metrica` tiene filas.
 */
function baseQueCorta(opciones: Record<string, unknown>[]) {
	const from = (tabla: string) => {
		const ordenes: { columna: string; ascendente: boolean }[] = [];
		let rango: [number, number] = [0, Number.POSITIVE_INFINITY];
		const resolver = () => {
			const filas = tabla === 'opciones_eleccion_metrica' ? [...opciones] : [];
			filas.sort((a, b) => {
				for (const { columna, ascendente } of ordenes) {
					const x = String(a[columna] ?? '').padStart(12, '0');
					const y = String(b[columna] ?? '').padStart(12, '0');
					if (x !== y) return (x < y ? -1 : 1) * (ascendente ? 1 : -1);
				}
				return 0;
			});
			const hasta = Math.min(rango[1], rango[0] + 999);
			return { data: filas.slice(rango[0], hasta + 1), error: null };
		};
		const constructor: Record<string, unknown> = {
			select: () => constructor,
			order: (columna: string, opciones?: { ascending?: boolean }) => {
				ordenes.push({ columna, ascendente: opciones?.ascending !== false });
				return constructor;
			},
			eq: () => constructor,
			in: () => constructor,
			range: (desde: number, hasta: number) => {
				rango = [desde, hasta];
				return constructor;
			},
			maybeSingle: () => Promise.resolve({ data: { revision: 1, modelo_version: 99 }, error: null }),
			then: (seguir: (valor: unknown) => unknown) => seguir(resolver())
		};
		return constructor;
	};
	return { from } as unknown as App.Locals['supabase'];
}

describe('el catálogo se lee entero aunque pase de mil filas', () => {
	beforeEach(() => olvidarCatalogoMetricoEnMemoria());

	it('trae todas las opciones, también las que empatan en el orden justo en el corte', async () => {
		// 2.500 opciones con solo cinco valores de `orden`: cada página corta dentro de un empate,
		// que es lo que pasó en noviembre de 2026 con las treinta opciones de `orden` 20.
		const opciones = Array.from({ length: 2500 }, (_, indice) => ({
			opcion_eleccion_id: `opcion-${String(indice).padStart(5, '0')}`,
			orden: indice % 5
		}));
		const catalogo = await loadMetricCatalog(baseQueCorta(opciones));
		const ids = catalogo.domain.choiceOptions.map((opcion) => String(opcion.opcion_eleccion_id));

		expect(ids).toHaveLength(2500);
		expect(new Set(ids).size).toBe(2500);
	});
});

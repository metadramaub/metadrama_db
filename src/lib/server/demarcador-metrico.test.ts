import { describe, expect, it } from 'vitest';
import { cargarCatalogoDemarcador } from './demarcador-metrico';

const payload = {
	forms: [
		{ forma_id: 'romance', slug: 'romance', nombre: 'Romance', definicion: null, grado_especificacion: 'especifica', tipo_registro: 'forma' },
		{ forma_id: 'soneto', slug: 'soneto', nombre: 'Soneto', definicion: null, grado_especificacion: 'especifica', tipo_registro: 'forma' }
	],
	architectures: [
		{ arquitectura_id: 'romance-8', forma_id: 'romance', slug: 'octosilabica', nombre: 'Octosilábica', descripcion: null, principal: true, tipo_rima_id: 'asonante', unidad_versos_min: 4, unidad_versos_max: null },
		{ arquitectura_id: 'soneto-11', forma_id: 'soneto', slug: 'canonica', nombre: 'Canónica', descripcion: null, principal: true, tipo_rima_id: 'consonante', unidad_versos_min: 14, unidad_versos_max: 14 }
	],
	metricPatterns: [
		{ esquema_metrico_id: 'metro-romance', arquitectura_id: 'romance-8', seccion_id: null },
		{ esquema_metrico_id: 'metro-soneto', arquitectura_id: 'soneto-11', seccion_id: null }
	],
	metricPositions: [
		{ esquema_metrico_id: 'metro-romance', metro_id: 'm8', posicion: 1 },
		{ esquema_metrico_id: 'metro-soneto', metro_id: 'm11', posicion: 1 }
	],
	metricOptions: [],
	metres: [
		{ metro_id: 'm8', slug: 'octosilabo', nombre: 'Octosílabo', silabas: 8 },
		{ metro_id: 'm11', slug: 'endecasilabo', nombre: 'Endecasílabo', silabas: 11 }
	],
	rhymePatterns: [
		{ esquema_rima_id: 'rima-romance', arquitectura_id: 'romance-8', slug: 'pares', nombre: 'Pares', notacion: '-a-a…', tipo_rima_id: 'asonante', tipo_secuencia: 'ciclo', seccion_id: null, modalidad: 'definitoria' },
		{ esquema_rima_id: 'rima-tercetos', arquitectura_id: 'soneto-11', slug: 'tercetos', nombre: 'Tercetos', notacion: 'CDECDE', tipo_rima_id: 'consonante', tipo_secuencia: 'secuencia', seccion_id: 'seccion-tercetos', modalidad: 'admitida' }
	],
	rhymePositions: [],
	sections: [
		{ seccion_id: 'cuartetos', arquitectura_id: 'soneto-11', seccion_padre_id: null, tipo_seccion: 'cuartetos', nombre: 'Cuartetos', orden: 1 },
		{ seccion_id: 'tercetos', arquitectura_id: 'soneto-11', seccion_padre_id: null, tipo_seccion: 'tercetos', nombre: 'Tercetos', orden: 2 }
	],
	repetitions: [],
	traits: [],
	traitValues: [],
	architectureTraits: [],
	choiceGroups: [],
	choiceOptions: [],
	vocabularies: [
		{ termino_id: 'asonante', termino: 'asonante', etiqueta: 'Asonante', categoria: 'tipo_rima' },
		{ termino_id: 'consonante', termino: 'consonante', etiqueta: 'Consonante', categoria: 'tipo_rima' }
	]
};

const lengthRules = [
	{ arquitectura_id: 'romance-8', arquitectura_nombre: 'Octosilábica', modulo_versos: 2, residuo_versos: 0, minimo_versos: 4, origen: 'ciclo_rima', explicacion: 'ciclos de rima completos de 2 versos' },
	{ arquitectura_id: 'soneto-11', arquitectura_nombre: 'Canónica', modulo_versos: 14, residuo_versos: 0, minimo_versos: 14, origen: 'secciones_fijas', explicacion: 'estructuras completas de 14 versos' }
];

const structuralLevels = [
	{ forma_id: 'romance', nivel_estructural: 'serie' },
	{ forma_id: 'soneto', nivel_estructural: 'composicion' }
];

const client = {
	rpc: async () => ({ data: payload, error: null }),
	from: (table: string) => ({
		select: async () => ({
			data: table === 'arquitecturas_reglas_longitud' ? lengthRules : structuralLevels,
			error: null
		})
	})
};

describe('proyección del catálogo para el demarcador', () => {
	it('mantiene la forma como identidad y la arquitectura como precisión', async () => {
		const catalogo = await cargarCatalogoDemarcador(client);
		const romance = catalogo.hipotesis.find((item) => item.formaId === 'romance');

		expect(catalogo.formas.find((item) => item.id === 'romance')?.nombre).toBe('Romance');
		expect(romance?.arquitecturaNombre).toBe('Octosilábica');
		expect(romance?.nivelEstructural).toBe('serie');
		expect(romance?.evidencias.find((item) => item.dimension === 'metro:grupo')?.valores[0].clave).toBe('arte_menor');
	});

	it('no convierte un esquema de sección del soneto en patrón de la unidad completa', async () => {
		const catalogo = await cargarCatalogoDemarcador(client);
		const soneto = catalogo.hipotesis.find((item) => item.formaId === 'soneto');

		expect(soneto?.evidencias.some((item) => item.dimension === 'rima:distribucion')).toBe(false);
		expect(soneto?.evidencias.find((item) => item.dimension === 'estructura:orden')?.valores[0].etiqueta).toBe('Cuartetos + Tercetos');
		expect(soneto?.evidencias.find((item) => item.dimension === 'extension:versos')).toMatchObject({
			minimo: 14,
			maximo: null,
			modulo: 14,
			residuo: 0,
			reglaLongitud: 'estructuras completas de 14 versos'
		});
		expect(soneto?.unidadVersos).toBe(14);
		expect(soneto?.presentacion.metro.esquemas[0]).toHaveLength(14);
		expect(soneto?.evidencias).toContainEqual(
			expect.objectContaining({
				dimension: 'estructura:agrupacion:14',
				pregunta: '¿Se distinguen grupos regulares de 14 versos dentro del pasaje?'
			})
		);
	});
});

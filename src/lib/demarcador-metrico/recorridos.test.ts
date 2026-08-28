import { describe, expect, it } from 'vitest';
import { crearRespuesta, ordenarFormas } from './motor';
import type {
	CatalogoDemarcador,
	EvidenciaNormativa,
	HipotesisMetrica,
	PreguntaDemarcador
} from './modelo';

function evidencia(
	dimension: string,
	familiaCognitiva: EvidenciaNormativa['familiaCognitiva'],
	valores: Array<{ clave: string; etiqueta: string }>,
	override: Partial<EvidenciaNormativa> = {}
): EvidenciaNormativa {
	return {
		dimension,
		familiaCognitiva,
		etiqueta: override.etiqueta ?? dimension,
		pregunta: override.pregunta ?? dimension,
		ayuda: override.ayuda ?? '',
		tipo: override.tipo ?? 'categoria',
		valores,
		minimo: override.minimo ?? null,
		maximo: override.maximo ?? null,
		modulo: override.modulo ?? null,
		residuo: override.residuo ?? null,
		desplazamientos: override.desplazamientos ?? null,
		reglaLongitud: override.reglaLongitud ?? null,
		modalidad: override.modalidad ?? 'definitoria',
		observabilidad: override.observabilidad ?? 'directa',
		coste: override.coste ?? 0.2,
		orden: override.orden ?? 10,
		fuente: override.fuente ?? 'norma'
	};
}

function hipotesis(
	formaId: string,
	formaNombre: string,
	arquitecturaNombre: string,
	evidencias: EvidenciaNormativa[],
	override: Partial<HipotesisMetrica> = {}
): HipotesisMetrica {
	return {
		id: `${formaId}:${arquitecturaNombre}`,
		formaId,
		formaSlug: formaId,
		formaNombre,
		formaDefinicion: null,
		nivelEstructural: 'estrofa',
		arquitecturaId: `${formaId}:${arquitecturaNombre}`,
		arquitecturaSlug: arquitecturaNombre,
		arquitecturaNombre,
		arquitecturaDescripcion: null,
		arquitecturaPrincipal: true,
		unidadVersos: null,
		presentacion: {
			rejilla: null,
			metro: { descripcion: null },
			rima: { tipo: null, esquemas: [] },
			estructura: null,
			repeticiones: [],
			rasgos: []
		},
		evidencias,
		...override
	};
}

const arteMenor = evidencia('metro:grupo', 'metro', [
	{ clave: 'arte_menor', etiqueta: 'Arte menor' }
]);
const medidaUniforme = evidencia('metro:uniformidad', 'metro', [
	{ clave: 'misma_medida', etiqueta: 'Sí, predomina una medida' }
]);
const octosilabos = evidencia('metro:exacto', 'metro', [{ clave: '8', etiqueta: '8 sílabas' }], {
	observabilidad: 'especializada',
	coste: 0.55
});
const consonante = evidencia(
	'rima:tipo',
	'rima',
	[{ clave: 'consonante', etiqueta: 'Consonante' }],
	{ observabilidad: 'especializada' }
);

const catalogo: CatalogoDemarcador = {
	formas: [],
	advertencias: [],
	hipotesis: [
		hipotesis(
			'romance',
			'Romance',
			'Octosilábica',
			[
				arteMenor,
				medidaUniforme,
				octosilabos,
				evidencia('extension:versos', 'extension', [], {
					tipo: 'numero',
					minimo: 4,
					maximo: null
				}),
				evidencia('rima:tipo', 'rima', [{ clave: 'asonante', etiqueta: 'Asonante' }], {
					observabilidad: 'especializada'
				})
			],
			{ nivelEstructural: 'serie' }
		),
		hipotesis('redondilla', 'Redondilla', 'Octosilábica', [
			arteMenor,
			medidaUniforme,
			octosilabos,
			evidencia('extension:versos', 'extension', [], {
				tipo: 'numero',
				minimo: 4,
				maximo: 4
			}),
			consonante
		]),
		hipotesis(
			'soneto',
			'Soneto',
			'Canónica',
			[
				evidencia('metro:grupo', 'metro', [{ clave: 'arte_mayor', etiqueta: 'Arte mayor' }]),
				evidencia('extension:versos', 'extension', [], {
					tipo: 'numero',
					minimo: 14,
					maximo: 14
				}),
				consonante
			],
			{ nivelEstructural: 'composicion', unidadVersos: 14 }
		)
	]
};

function pregunta(
	dimension: string,
	familiaCognitiva: PreguntaDemarcador['familiaCognitiva'],
	tipo: PreguntaDemarcador['tipo'] = 'categoria'
): PreguntaDemarcador {
	return {
		id: dimension,
		dimension,
		familiaCognitiva,
		pregunta: dimension,
		ayuda: '',
		tipo,
		opciones: [],
		observabilidad: 'directa',
		coste: 0,
		utilidad: 1
	};
}

describe('recorridos de referencia del demarcador', () => {
	it('mantiene grados sin cerrar después de una observación general', () => {
		const resultados = ordenarFormas(catalogo, [
			crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_menor', 'Arte menor')
		]);

		expect(resultados[0].nivel).toBe('candidata');
		expect(resultados.every((resultado) => resultado.nivel === 'candidata')).toBe(true);
	});

	it('sitúa el romance con encaje alto a partir de observaciones accesibles', () => {
		const resultados = ordenarFormas(catalogo, [
			crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_menor', 'Arte menor'),
			crearRespuesta(
				pregunta('metro:uniformidad', 'metro'),
				'misma_medida',
				'Sí, predomina una medida'
			),
			crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 20, '20 versos'),
			crearRespuesta(pregunta('rima:tipo', 'rima'), 'asonante', 'Asonante')
		]);

		expect(resultados[0].formaNombre).toBe('Romance');
		expect(resultados[0].nivel).toBe('alto');
	});

	it('una precisión desconocida no perjudica una identificación bien apoyada', () => {
		const resultados = ordenarFormas(catalogo, [
			crearRespuesta(pregunta('metro:grupo', 'metro'), 'arte_menor', 'Arte menor'),
			crearRespuesta(
				pregunta('metro:uniformidad', 'metro'),
				'misma_medida',
				'Sí, predomina una medida'
			),
			crearRespuesta(pregunta('metro:exacto', 'metro'), 'desconocido', 'No sé'),
			crearRespuesta(pregunta('extension:versos', 'extension', 'numero'), 20, '20 versos'),
			crearRespuesta(pregunta('rima:tipo', 'rima'), 'asonante', 'Asonante')
		]);

		expect(resultados[0].formaNombre).toBe('Romance');
		expect(resultados[0].nivel).toBe('alto');
	});
});

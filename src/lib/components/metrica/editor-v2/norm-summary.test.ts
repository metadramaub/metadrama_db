import { describe, expect, it } from 'vitest';
import type { MetricCatalogDomainData, MetricCatalogDomainRow } from '$lib/metrica/catalogo';
import { metricNormFacts } from './norm-summary';

function domain(overrides: Partial<MetricCatalogDomainData> = {}): MetricCatalogDomainData {
	const empty = [] as MetricCatalogDomainRow[];
	return {
		forms: empty,
		configurations: empty,
		traditions: empty,
		formTraditions: empty,
		aliases: empty,
		formRelations: empty,
		verseModels: empty,
		verseSegments: empty,
		metricPatterns: empty,
		metricPositions: empty,
		metricOptions: empty,
		rhymePatterns: empty,
		rhymePositions: empty,
		rhymeLinks: empty,
		rhymeRestrictions: empty,
		patternCombinations: empty,
		sections: empty,
		repetitionPatterns: empty,
		repetitionPositions: empty,
		traits: empty,
		traitValues: empty,
		configurationTraits: empty,
		choiceGroups: empty,
		choiceOptions: empty,
		sources: empty,
		sourceClaims: empty,
		...overrides
	};
}

/**
 * El pareado alirado rima en consonante y la norma solo decía «Rima fija: aa». El régimen se declara
 * arriba cuando es uno —§ 3.3— y entonces sube a la norma; cuando varía, baja a cada disposición,
 * que es donde lo pinta la rejilla y donde `MetricPositionGrid` ya sabía enseñarlo.
 */
/**
 * En la redondilla el quiebro es una licencia y en la manriqueña es lo que la define, y el renglón
 * de la medida las decía igual. La modalidad no aparece por su cuenta: un rasgo `admitida` sin
 * límite de posiciones no sube a la norma, así que este renglón es el único sitio donde se afirma.
 */
describe('el grado del pie quebrado', () => {
	function conQuebrado(modalidad: string | null) {
		return domain({
			metricPatterns: [{ arquitectura_id: 'a', esquema_metrico_id: 'em' }],
			metricOptions: [
				{ esquema_metrico_id: 'em', metro_id: 'm8', rol: 'dominante' },
				{ esquema_metrico_id: 'em', metro_id: 'm4', rol: 'quebrado' },
				{ esquema_metrico_id: 'em', metro_id: 'm5', rol: 'quebrado' }
			],
			verseModels: [
				{ metro_id: 'm8', silabas: 8 },
				{ metro_id: 'm4', silabas: 4 },
				{ metro_id: 'm5', silabas: 5 }
			],
			traits: [{ rasgo_id: 'r', slug: 'pie_quebrado', nombre: 'Pie quebrado' }],
			configurationTraits: modalidad
				? [{ arquitectura_id: 'a', rasgo_id: 'r', modalidad }]
				: []
		});
	}

	function medida(modalidad: string | null) {
		return metricNormFacts({
			architectureId: 'a',
			unitPlan: null,
			lengthRule: null,
			domain: conQuebrado(modalidad)
		}).find((fact) => fact.label === 'Medida')?.value;
	}

	function rasgo(modalidad: string | null) {
		return metricNormFacts({
			architectureId: 'a',
			unitPlan: null,
			lengthRule: null,
			domain: conQuebrado(modalidad)
		}).find((fact) => fact.label === 'Pie quebrado')?.value;
	}

	it('la medida dice la base y nada más', () => {
		expect(medida('admitida')).toBe('Base de 8 sílabas');
		expect(medida('definitoria')).toBe('Base de 8 sílabas');
	});

	it('el grado y las medidas del quiebro van en su rasgo', () => {
		expect(rasgo('admitida')).toBe('admitido; de 4 o 5 sílabas');
		expect(rasgo('habitual')).toBe('habitual; de 4 o 5 sílabas');
		expect(rasgo('definitoria')).toBe('obligatorio; de 4 o 5 sílabas');
	});

	/**
	 * Un rasgo admitido sin límite de posiciones no sube a la norma, porque es dato de la
	 * realización. El quiebro es la excepción: cambia la medida de la estrofa, y en seis
	 * arquitecturas ni siquiera se pregunta desde que se declaró dónde cae.
	 */
	it('sube aunque solo esté admitido y sin límite', () => {
		expect(rasgo('admitida')).toBeDefined();
	});
});

describe('el régimen de rima', () => {
	const regimenes = [
		{ id: 't-cons', slug: 'consonante', label: 'Consonante' },
		{ id: 't-ason', slug: 'asonante', label: 'Asonante' }
	];

	it('sube a la norma cuando la arquitectura declara uno solo', () => {
		const facts = metricNormFacts({
			architectureId: 'alirado',
			unitPlan: null,
			lengthRule: null,
			rhymeTypes: regimenes,
			domain: domain({
				configurations: [{ arquitectura_id: 'alirado', tipo_rima_id: 't-cons' }],
				rhymePatterns: [
					{
						arquitectura_id: 'alirado',
						esquema_rima_id: 'e1',
						notacion: 'aa',
						modalidad: 'definitoria',
						tipo_rima_id: 't-cons'
					}
				]
			})
		});
		expect(facts).toContainEqual({ label: 'Régimen de rima', value: 'Consonante' });
		expect(facts).toContainEqual({ label: 'Rima fija', value: 'aa' });
	});

	it('no lo repite arriba cuando cada disposición trae el suyo', () => {
		const facts = metricNormFacts({
			architectureId: 'cualquiera',
			unitPlan: null,
			lengthRule: null,
			rhymeTypes: regimenes,
			domain: domain({
				configurations: [{ arquitectura_id: 'cualquiera', tipo_rima_id: null }],
				rhymePatterns: [
					{
						arquitectura_id: 'cualquiera',
						esquema_rima_id: 'e1',
						notacion: 'aa',
						modalidad: 'admitida',
						tipo_rima_id: 't-ason'
					},
					{
						arquitectura_id: 'cualquiera',
						esquema_rima_id: 'e2',
						notacion: 'aa',
						modalidad: 'admitida',
						tipo_rima_id: 't-cons'
					}
				]
			})
		});
		expect(facts.some((fact) => fact.label === 'Régimen de rima')).toBe(false);
	});
});

describe('resumen de la norma', () => {
	it('muestra extensión, partes, posiciones métricas y rima definitoria', () => {
		const facts = metricNormFacts({
			architectureId: 'a',
			unitPlan: { extent: { minimum: 4, maximum: 4 }, countFromRange: true },
			lengthRule: {
				arquitectura_id: 'a',
				arquitectura_nombre: 'Octosilábica',
				modulo_versos: 4,
				residuo_versos: 0,
				minimo_versos: 4,
				origen: 'unidad',
				explicacion: 'unidades completas de 4 versos',
				desplazamientos: [0]
			},
			domain: domain({
				sections: [
					{
						arquitectura_id: 'a',
						seccion_id: 's',
						nombre: 'Miembros',
						repeticiones_min: 2,
						repeticiones_max: 2,
						versos_min: 2,
						versos_max: 2
					}
				],
				verseModels: [{ metro_id: 'm8', silabas: 8 }],
				metricPatterns: [{ arquitectura_id: 'a', esquema_metrico_id: 'em' }],
				metricPositions: [1, 2, 3, 4].map((posicion) => ({
					esquema_metrico_id: 'em',
					metro_id: 'm8',
					posicion,
					alternativa: 1,
					opcional: false
				})),
				rhymePatterns: [
					{
						arquitectura_id: 'a',
						esquema_rima_id: 'er',
						modalidad: 'definitoria',
						notacion: 'abba'
					}
				]
			})
		});

		expect(facts).toEqual([
			{ label: 'Extensión', value: 'unidades completas de 4 versos' },
			{ label: 'Partes fijas', value: 'Miembros: 2 × 2 versos' },
			{ label: 'Medida fija', value: '8·8·8·8' },
			{ label: 'Rima fija', value: 'abba' }
		]);
	});

	it('omite los esquemas que el editor debe elegir', () => {
		const facts = metricNormFacts({
			architectureId: 'a',
			unitPlan: { extent: { minimum: 2, maximum: 2 }, countFromRange: true },
			lengthRule: null,
			domain: domain({
				rhymePatterns: [
					{
						arquitectura_id: 'a',
						esquema_rima_id: 'er',
						modalidad: 'definitoria',
						notacion: 'aa'
					}
				],
				choiceOptions: [{ esquema_rima_id: 'er' }]
			})
		});

		expect(facts).toEqual([{ label: 'Extensión', value: '2 versos por unidad' }]);
	});

	it('no concatena los esquemas métricos y de rima de variedades alternativas', () => {
		const facts = metricNormFacts({
			architectureId: 'a',
			unitPlan: { extent: { minimum: 6, maximum: 6 }, countFromRange: true },
			lengthRule: null,
			domain: domain({
				verseModels: [
					{ metro_id: 'm7', silabas: 7 },
					{ metro_id: 'm11', silabas: 11 }
				],
				metricPatterns: [
					{ arquitectura_id: 'a', esquema_metrico_id: 'em1' },
					{ arquitectura_id: 'a', esquema_metrico_id: 'em2' }
				],
				metricPositions: [
					...['m7', 'm11'].map((metro_id, index) => ({
						esquema_metrico_id: 'em1',
						metro_id,
						posicion: index + 1,
						alternativa: 1,
						opcional: false
					})),
					...['m11', 'm7'].map((metro_id, index) => ({
						esquema_metrico_id: 'em2',
						metro_id,
						posicion: index + 1,
						alternativa: 1,
						opcional: false
					}))
				],
				rhymePatterns: [
					{
						arquitectura_id: 'a',
						esquema_rima_id: 'er1',
						modalidad: 'definitoria',
						notacion: 'ababcc'
					},
					{
						arquitectura_id: 'a',
						esquema_rima_id: 'er2',
						modalidad: 'definitoria',
						notacion: 'abbacc'
					}
				],
				patternCombinations: [
					{
						variedad_id: 'v1',
						esquema_metrico_id: 'em1',
						esquema_rima_id: 'er1'
					},
					{
						variedad_id: 'v2',
						esquema_metrico_id: 'em2',
						esquema_rima_id: 'er2'
					}
				],
				choiceOptions: [
					{ grupo_eleccion_id: 'g', variedad_id: 'v1' },
					{ grupo_eleccion_id: 'g', variedad_id: 'v2' }
				]
			})
		});

		expect(facts).toEqual([
			{ label: 'Extensión', value: '6 versos por unidad' },
			{
				label: 'Medida',
				value: 'Combina versos de 7 y 11 sílabas; la distribución depende de la variedad.',
				estado: 'pasaje'
			}
		]);
	});

	it('muestra la medida dominante, los quebrados y su máximo normativo', () => {
		const facts = metricNormFacts({
			architectureId: 'a',
			unitPlan: { extent: { minimum: 10, maximum: 10 }, countFromRange: true },
			lengthRule: null,
			domain: domain({
				sections: [
					{
						arquitectura_id: 'a',
						seccion_id: 's1',
						nombre: 'Primera quintilla',
						repeticiones_min: 1,
						repeticiones_max: 1,
						versos_min: 5,
						versos_max: 5
					},
					{
						arquitectura_id: 'a',
						seccion_id: 's2',
						nombre: 'Segunda quintilla',
						repeticiones_min: 1,
						repeticiones_max: 1,
						versos_min: 5,
						versos_max: 5
					}
				],
				verseModels: [
					{ metro_id: 'm8', silabas: 8 },
					{ metro_id: 'm4', silabas: 4 },
					{ metro_id: 'm5', silabas: 5 }
				],
				metricPatterns: [{ arquitectura_id: 'a', esquema_metrico_id: 'em' }],
				metricOptions: [
					{ esquema_metrico_id: 'em', metro_id: 'm8', rol: 'dominante' },
					{ esquema_metrico_id: 'em', metro_id: 'm4', rol: 'quebrado' },
					{ esquema_metrico_id: 'em', metro_id: 'm5', rol: 'quebrado' }
				],
				traits: [{ rasgo_id: 'r', slug: 'pie_quebrado', nombre: 'Pie quebrado' }],
				configurationTraits: [
					{
						arquitectura_id: 'a',
						rasgo_id: 'r',
						modalidad: 'admitida',
						posiciones_max: 2
					}
				]
			})
		});

		expect(facts).toEqual([
			{ label: 'Extensión', value: '10 versos por unidad' },
			{
				label: 'Partes fijas',
				value: 'Primera quintilla: 5 versos · Segunda quintilla: 5 versos'
			},
			{
				label: 'Medida',
				value: 'Base de 8 sílabas'
			},
			{
				label: 'Pie quebrado',
				value: 'admite hasta 2 posiciones; de 4 o 5 sílabas',
				estado: 'admite'
			}
		]);
	});

	it('reserva el resumen para rasgos fijos o límites y no duplica elecciones admitidas', () => {
		const facts = metricNormFacts({
			architectureId: 'a',
			unitPlan: null,
			lengthRule: null,
			domain: domain({
				traits: [
					{ rasgo_id: 'densidad', nombre: 'Densidad de rima' },
					{ rasgo_id: 'final', nombre: 'Final acentual' }
				],
				traitValues: [
					{ valor_id: 'total', nombre: 'Total' },
					{ valor_id: 'esdrujulo', nombre: 'Esdrújulo' }
				],
				configurationTraits: [
					{
						arquitectura_id: 'a',
						rasgo_id: 'densidad',
						valor_id: 'total',
						modalidad: 'definitoria'
					},
					{
						arquitectura_id: 'a',
						rasgo_id: 'final',
						valor_id: 'esdrujulo',
						modalidad: 'admitida'
					}
				]
			})
		});

		expect(facts).toEqual([{ label: 'Densidad de rima', value: 'Total; obligatorio' }]);
	});

	it('hace visibles las restricciones variables que la primera estancia convierte en patrón', () => {
		const facts = metricNormFacts({
			architectureId: 'a',
			unitPlan: null,
			lengthRule: null,
			domain: domain({
				sections: [
					{
						arquitectura_id: 'a',
						seccion_id: 'estancia',
						nombre: 'Estancia',
						repeticiones_min: 3,
						repeticiones_max: null,
						versos_min: 5,
						versos_max: 20,
						esquema_metrico_id: 'em',
						primera_realizacion_define_patron: true
					},
					{
						arquitectura_id: 'a',
						seccion_id: 'remate',
						nombre: 'Remate o envío',
						repeticiones_min: 0,
						repeticiones_max: 1,
						versos_min: 1,
						versos_max: 20
					}
				],
				verseModels: [
					{ metro_id: 'm7', silabas: 7 },
					{ metro_id: 'm11', silabas: 11 }
				],
				metricPatterns: [
					{ arquitectura_id: 'a', esquema_metrico_id: 'em', tipo_secuencia: 'conjunto' }
				],
				metricOptions: [
					{ esquema_metrico_id: 'em', metro_id: 'm7' },
					{ esquema_metrico_id: 'em', metro_id: 'm11' }
				],
				rhymePatterns: [
					{
						arquitectura_id: 'a',
						esquema_rima_id: 'er',
						seccion_id: 'estancia',
						modalidad: 'definitoria',
						tipo_secuencia: 'abierta',
						nombre: 'Esquema consonante repetido entre estancias',
						descripcion: 'El esquema concreto es libre y se repite.'
					}
				],
				rhymeRestrictions: [
					{
						esquema_rima_id: 'er',
						tipo: 'identidad_entre_repeticiones',
						descripcion: 'El esquema concreto es libre, pero vuelve idéntico en todas las estancias.'
					}
				]
			})
		});

		expect(facts).toEqual([
			{
				label: 'Estructura',
				value: '3 o más estancias; 5–20 versos por estancia; la primera fija el patrón de las demás'
			},
			{ label: 'Parte opcional', value: 'Remate o envío: 1–20 versos' },
			{
				label: 'Medida',
				value: 'Estancia: versos de 7 y 11 sílabas; la primera fija la distribución de las demás',
				estado: 'pasaje'
			},
			{
				label: 'Rima',
				value: 'Estancia: esquema consonante repetido entre estancias',
				estado: 'pasaje'
			},
			{
				label: 'Restricciones de rima',
				value: 'El esquema concreto es libre, pero vuelve idéntico en todas las estancias'
			}
		]);
	});

	it('incluye las repeticiones definitorias, pero no las modalidades meramente admitidas', () => {
		const facts = metricNormFacts({
			architectureId: 'a',
			unitPlan: null,
			lengthRule: null,
			domain: domain({
				repetitionPatterns: [
					{
						arquitectura_id: 'a',
						modalidad: 'definitoria',
						nombre: 'Palabras finales repetidas',
						descripcion: 'Seis palabras finales se permutan y se recuperan en el terceto.'
					},
					{
						arquitectura_id: 'a',
						modalidad: 'admitida',
						nombre: 'Repetición parcial'
					}
				]
			})
		});

		expect(facts).toEqual([
			{
				label: 'Repetición',
				value: 'Seis palabras finales se permutan y se recuperan en el terceto'
			}
		]);
	});
	/**
	 * El caso que faltaba. La prueba de arriba alimenta solo las dos secciones de primer nivel de
	 * esta misma arquitectura, así que pasaba mientras la implementación **no filtraba nada**: en la
	 * base la estancia lleva dentro un fronte —con dos pies—, un eslabón y una sirima, y todas ellas
	 * salían anunciadas como estructura de la secuencia, con cinco renglones «Estructura» seguidos.
	 */
	it('describe las partes de la unidad sin confundirlas con la estructura de la secuencia', () => {
		const facts = metricNormFacts({
			architectureId: 'a',
			unitPlan: null,
			lengthRule: null,
			domain: domain({
				sections: [
					{
						arquitectura_id: 'a',
						seccion_id: 'estancia',
						nombre: 'Estancia',
						orden: 1,
						repeticiones_min: 3,
						repeticiones_max: null,
						versos_min: 5,
						versos_max: 20,
						primera_realizacion_define_patron: true
					},
					{
						arquitectura_id: 'a',
						seccion_id: 'remate',
						nombre: 'Remate o envío',
						orden: 2,
						repeticiones_min: 0,
						repeticiones_max: 1,
						versos_min: 1,
						versos_max: 20
					},
					{
						arquitectura_id: 'a',
						seccion_id: 'fronte',
						seccion_padre_id: 'estancia',
						nombre: 'Fronte',
						orden: 1,
						repeticiones_min: 1,
						repeticiones_max: 1,
						versos_min: 4,
						versos_max: 18
					},
					{
						arquitectura_id: 'a',
						seccion_id: 'pie1',
						seccion_padre_id: 'fronte',
						nombre: 'Primer pie',
						orden: 1,
						repeticiones_min: 1,
						repeticiones_max: 1,
						versos_min: 2,
						versos_max: 9
					},
					{
						arquitectura_id: 'a',
						seccion_id: 'pie2',
						seccion_padre_id: 'fronte',
						nombre: 'Segundo pie',
						orden: 2,
						repeticiones_min: 1,
						repeticiones_max: 1,
						versos_min: 2,
						versos_max: 9
					},
					{
						arquitectura_id: 'a',
						seccion_id: 'eslabon',
						seccion_padre_id: 'estancia',
						nombre: 'Eslabón',
						orden: 2,
						repeticiones_min: 0,
						repeticiones_max: 1,
						versos_min: 1,
						versos_max: 1
					},
					{
						arquitectura_id: 'a',
						seccion_id: 'sirima',
						seccion_padre_id: 'estancia',
						nombre: 'Sirima',
						orden: 3,
						repeticiones_min: 1,
						repeticiones_max: 1,
						versos_min: 1,
						versos_max: 16
					}
				]
			})
		});

		expect(facts).toEqual([
			{
				// En orden de árbol, y el eslabón dice que puede no estar.
				label: 'Partes',
				value:
					'Fronte: 4–18 versos · Primer pie: 2–9 versos · Segundo pie: 2–9 versos · ' +
					'Eslabón: 1 verso (opcional) · Sirima: 1–16 versos'
			},
			{
				label: 'Estructura',
				value: '3 o más estancias; 5–20 versos por estancia; la primera fija el patrón de las demás'
			},
			{ label: 'Parte opcional', value: 'Remate o envío: 1–20 versos' }
		]);
	});

	/** Una sección que aparece una sola vez no es una serie, y decirlo en plural sobraba. */
	it('no llama serie a una parte que aparece una sola vez', () => {
		const facts = metricNormFacts({
			architectureId: 'a',
			unitPlan: null,
			lengthRule: null,
			domain: domain({
				sections: [
					{
						arquitectura_id: 'a',
						seccion_id: 'cabeza',
						nombre: 'Cabeza',
						orden: 1,
						repeticiones_min: 1,
						repeticiones_max: 1,
						versos_min: 2,
						versos_max: 4
					}
				]
			})
		});

		expect(facts).toEqual([{ label: 'Parte', value: 'Cabeza: 2–4 versos' }]);
	});
	/** El esquema de la copla castellana y otras nueve arquitecturas: una posición y roles. */
	it('no cuenta dos veces un esquema que ya se ha leído por sus roles', () => {
		const facts = metricNormFacts({
			architectureId: 'a',
			unitPlan: null,
			lengthRule: null,
			domain: domain({
				verseModels: [
					{ metro_id: 'm4', silabas: 4 },
					{ metro_id: 'm5', silabas: 5 },
					{ metro_id: 'm8', silabas: 8 }
				],
				metricPatterns: [
					{ arquitectura_id: 'a', esquema_metrico_id: 'em', tipo_secuencia: 'ciclo' }
				],
				metricPositions: [{ esquema_metrico_id: 'em', posicion: 1, metro_id: 'm8' }],
				metricOptions: [
					{ esquema_metrico_id: 'em', metro_id: 'm8', rol: 'dominante' },
					{ esquema_metrico_id: 'em', metro_id: 'm4', rol: 'quebrado' },
					{ esquema_metrico_id: 'em', metro_id: 'm5', rol: 'quebrado' }
				]
			})
		});

		// Antes salía también «Medida fija: 8», que contradice al renglón de arriba.
		expect(facts).toEqual([
			{
				label: 'Medida',
				value: 'Base de 8 sílabas'
			}
		]);
	});
});

import { describe, expect, it } from 'vitest';
import {
	construirRejilla,
	type Rejilla,
	esquemaRimaPrincipal,
	perfilDeArquitectura,
	type EntradaRejilla,
	type EsquemaMetricoEntrada,
	type EsquemaRimaEntrada,
	type PosicionRimaEntrada,
	type SeccionEntrada
} from './rejilla';

/**
 * Un caso por perfil, con los datos del catálogo en vivo a 12 de agosto de 2026. Se eligen las
 * siete formas que el inventario de
 * `docs/dominio-metrico/presentacion-del-catalogo-publico.md` pone de ejemplo de cada molde: si
 * una de ellas deja de dibujarse, el perfil entero ha dejado de funcionar.
 */

function metricoIsosilabico(silabas: string): EsquemaMetricoEntrada {
	return {
		tipoSecuencia: 'ciclo',
		medidaUniforme: null,
		seccion: null,
		posiciones: [{ posicion: 1, silabas, alternativa: 1, opcional: false }],
		opciones: []
	};
}

function metricoSecuencia(medidas: (string | string[])[]): EsquemaMetricoEntrada {
	return {
		tipoSecuencia: 'secuencia',
		medidaUniforme: null,
		seccion: null,
		posiciones: medidas.flatMap((medida, indice) =>
			(Array.isArray(medida) ? medida : [medida]).map((silabas, alternativa) => ({
				posicion: indice + 1,
				silabas,
				alternativa: alternativa + 1,
				opcional: false
			}))
		),
		opciones: []
	};
}

/** `abba` o `ABBA ABBA`: el espacio separa bloques, el guion marca un verso suelto. */
function rima(
	id: string,
	notacion: string,
	extra: Partial<EsquemaRimaEntrada> & { seccionDePosiciones?: string } = {}
): EsquemaRimaEntrada {
	const posiciones: PosicionRimaEntrada[] = notacion
		.split(' ')
		.flatMap((bloque, indiceBloque) =>
			[...bloque].map((letra, indice) => ({
				bloque: indiceBloque + 1,
				posicion: indice + 1,
				clase: letra === '-' ? null : letra,
				suelto: letra === '-',
				seccion: extra.seccionDePosiciones ?? null
			}))
		);
	return {
		id,
		nombre: null,
		notacion,
		seccion: null,
		modalidad: 'admitida',
		posiciones,
		enlaces: [],
		...extra
	};
}

function seccion(nombre: string, partial: Partial<SeccionEntrada> = {}): SeccionEntrada {
	return {
		nombre,
		versosMin: null,
		versosMax: null,
		repeticionesMin: 1,
		repeticionesMax: 1,
		reutiliza: null,
		...partial
	};
}

function entrada(partial: Partial<EntradaRejilla>): EntradaRejilla {
	return { metricos: [], rimas: [], secciones: [], unidadMin: null, unidadMax: null, ...partial };
}

/** Las letras de una fila de rima, con la columna en la que empieza. */
const letras = (rejilla: Rejilla, indice = 0) => {
	const fila = rejilla.filasDeRima[indice];
	if (!fila) return '';
	return fila.clases.map((clase) => (clase.suelto ? '-' : (clase.clase ?? '·'))).join('');
};

const medidas = (rejilla: {
	celdas: { medida: { silabas: string | null; alternativas: string[] } | null }[];
}) =>
	rejilla.celdas
		.map((celda) =>
			celda.medida === null
				? '·'
				: (celda.medida.silabas ?? celda.medida.alternativas.join('/'))
		)
		.join(' ');

describe('la rejilla de posiciones', () => {
	it('dibuja el soneto con sus cuatro partes y la rima que abarca dos cuartetos', () => {
		const rejilla = construirRejilla(
			entrada({
				unidadMin: 14,
				unidadMax: 14,
				metricos: [metricoIsosilabico('11')],
				secciones: [
					seccion('Cuartetos', {
						versosMin: 4,
						versosMax: 4,
						repeticionesMin: 2,
						repeticionesMax: 2,
						reutiliza: { nombre: 'Cuarteto', slug: 'cuarteto' }
					}),
					seccion('Tercetos', {
						versosMin: 3,
						versosMax: 3,
						repeticionesMin: 2,
						repeticionesMax: 2,
						reutiliza: { nombre: 'Terceto', slug: 'terceto' }
					})
				],
				rimas: [
					rima('abba', 'ABBA ABBA', { seccion: 'Cuartetos', modalidad: 'habitual' }),
					rima('abab', 'ABAB ABAB', { seccion: 'Cuartetos', modalidad: 'excepcional' }),
					rima('cdcdcd', 'CDC DCD', { seccion: 'Tercetos', modalidad: 'habitual' }),
					rima('cdecde', 'CDE CDE', { seccion: 'Tercetos', modalidad: 'admitida' })
				]
			})
		);

		expect(rejilla?.celdas).toHaveLength(14);
		// Las cuatro disposiciones se dibujan, cada una sobre las columnas de su parte.
		expect(
			rejilla?.filasDeRima.map((fila) => `${fila.parte} ${fila.desde}-${fila.hasta} ${fila.clases
				.map((clase) => clase.clase ?? '-')
				.join('')}`)
		).toEqual([
			'Cuartetos 1-8 ABBAABBA',
			'Cuartetos 1-8 ABABABAB',
			'Tercetos 9-14 CDCDCD',
			'Tercetos 9-14 CDECDE'
		]);
		expect(medidas(rejilla!)).toBe('11 11 11 11 11 11 11 11 11 11 11 11 11 11');
		// Dos apariciones seguidas de la misma parte son una banda con su cuenta, no dos rótulos.
		expect(
			rejilla?.bandas.map(
				(banda) => `${banda.nombre} ${banda.desde}-${banda.hasta} ×${banda.apariciones}`
			)
		).toEqual(['Cuartetos 1-8 ×2', 'Tercetos 9-14 ×2']);
		expect(rejilla?.bandas[0].reutiliza).toEqual({ nombre: 'Cuarteto', slug: 'cuarteto' });
		expect(rejilla?.cicla).toBe(false);
	});

	it('dibuja el romance como un ciclo de dos versos con su enlace', () => {
		const rejilla = construirRejilla(
			entrada({
				metricos: [metricoIsosilabico('8')],
				rimas: [
					{
						...rima('asonancia-pares', '-a', { modalidad: 'definitoria' }),
						notacion: '[-a]…',
						enlaces: [{ desde: 2, hasta: 2, desplazamiento: 1, nota: null }]
					}
				]
			})
		);

		expect(rejilla?.celdas).toHaveLength(2);
		expect(medidas(rejilla!)).toBe('8 8');
		expect(letras(rejilla!)).toBe('-a');
		expect(rejilla?.filasDeRima[0].clases[0].suelto).toBe(true);
		expect(rejilla?.cicla).toBe(true);
		expect(rejilla?.enlaces).toEqual([
			{ desde: 2, hasta: 2, sentido: 'adelante', nota: null }
		]);
	});

	it('dibuja la estancia de la canción con la fronte, el eslabón y la sirima', () => {
		const estancia = rima('abcabccdeedff', 'abCabCcdeeDfF', { seccion: 'Estancia regular' });
		const partes = [
			'fronte',
			'fronte',
			'fronte',
			'fronte',
			'fronte',
			'fronte',
			'eslabón',
			'sirima',
			'sirima',
			'sirima',
			'sirima',
			'sirima',
			'sirima'
		];
		estancia.posiciones = estancia.posiciones.map((posicion, indice) => ({
			...posicion,
			seccion: partes[indice]
		}));

		const rejilla = construirRejilla(
			entrada({
				metricos: [metricoSecuencia(['7', '7', '11', '7', '7', '11', '7', '7', '7', '7', '11', '7', '11'])],
				secciones: [
					seccion('Estancia regular', {
						versosMin: 13,
						versosMax: 13,
						repeticionesMin: 3,
						repeticionesMax: null
					}),
					// El remate mide de 1 a 13 versos: no se puede dibujar y no entra.
					seccion('Remate o envío', {
						versosMin: 1,
						versosMax: 13,
						repeticionesMin: 0,
						repeticionesMax: 1
					})
				],
				rimas: [estancia]
			})
		);

		expect(rejilla?.celdas).toHaveLength(13);
		expect(medidas(rejilla!)).toBe('7 7 11 7 7 11 7 7 7 7 11 7 11');
		expect(letras(rejilla!)).toBe('abCabCcdeeDfF');
		expect(rejilla?.parte).toBe('Estancia regular');
		expect(rejilla?.repeticionesDeLaParte).toBe('×3 o más');
		expect(rejilla?.bandas.map((banda) => banda.nombre)).toEqual(['fronte', 'eslabón', 'sirima']);
		expect(rejilla?.bandas[2]).toMatchObject({ desde: 8, hasta: 13 });
	});

	it('trata las alternativas de una posición como una posición, no como varias', () => {
		const rejilla = construirRejilla(
			entrada({
				unidadMin: 4,
				unidadMax: 4,
				metricos: [metricoSecuencia(['6', '6', ['11', '10', '12'], '6'])],
				rimas: [rima('gitana', '-a-a')]
			})
		);

		expect(rejilla?.celdas).toHaveLength(4);
		expect(medidas(rejilla!)).toBe('6 6 11/10/12 6');
		expect(rejilla?.celdas[2].medida?.silabas).toBeNull();
	});

	it('no dibuja nada cuando la norma no fija posiciones', () => {
		const rejilla = construirRejilla(
			entrada({
				metricos: [
					{
						tipoSecuencia: 'conjunto',
						medidaUniforme: false,
						seccion: null,
						posiciones: [],
						opciones: [
							{ silabas: '7', rol: null },
							{ silabas: '11', rol: null }
						]
					}
				],
				rimas: [
					{
						id: 'orden-libre',
						nombre: 'Consonante de orden libre',
						notacion: null,
						seccion: null,
						modalidad: 'definitoria',
						posiciones: [],
						enlaces: []
					}
				]
			})
		);

		expect(rejilla).toBeNull();
	});

	it('dibuja una estrofa que se repite una sola vez y la rotula con sus repeticiones', () => {
		const rejilla = construirRejilla(
			entrada({
				unidadMin: 39,
				unidadMax: 39,
				metricos: [metricoIsosilabico('11')],
				secciones: [
					seccion('Estrofa', {
						versosMin: 6,
						versosMax: 6,
						repeticionesMin: 6,
						repeticionesMax: 6,
						reutiliza: { nombre: 'Sextina', slug: 'sextina-estrofa' }
					}),
					seccion('Remate', { versosMin: 3, versosMax: 3 })
				],
				rimas: []
			})
		);

		// Seis estrofas de seis versos más el remate son 39 columnas: se dibuja una y se rotula.
		expect(rejilla?.celdas).toHaveLength(9);
		expect(rejilla?.bandas[0]).toMatchObject({ nombre: 'Estrofa', repeticiones: '×6' });
		expect(rejilla?.bandas[1]).toMatchObject({ nombre: 'Remate', desde: 7, hasta: 9 });
	});

	it('deja mandar al ciclo de la unidad sobre las partes cuando la rima encadena', () => {
		const rejilla = construirRejilla(
			entrada({
				metricos: [metricoIsosilabico('11')],
				secciones: [
					seccion('Cadena de tercetos', {
						versosMin: 3,
						versosMax: 3,
						repeticionesMin: 1,
						repeticionesMax: null
					}),
					seccion('Serventesio final', { versosMin: 4, versosMax: 4 })
				],
				rimas: [
					{
						...rima('encadenado', 'ABA', { modalidad: 'definitoria' }),
						notacion: '[ABA]…',
						enlaces: [
							{ desde: 2, hasta: 1, desplazamiento: 1, nota: null },
							{ desde: 2, hasta: 3, desplazamiento: 1, nota: null }
						]
					}
				]
			})
		);

		expect(rejilla?.celdas).toHaveLength(3);
		expect(letras(rejilla!)).toBe('ABA');
		expect(rejilla?.cicla).toBe(true);
	});

	it('elige la disposición por modalidad y no por orden de llegada', () => {
		const elegido = esquemaRimaPrincipal([
			rima('abbba', 'abbba', { modalidad: 'excepcional' }),
			rima('ababa', 'ababa', { modalidad: 'habitual' }),
			{
				id: 'variable',
				nombre: 'Distribución admitida',
				notacion: null,
				seccion: null,
				modalidad: 'definitoria',
				posiciones: [],
				enlaces: []
			}
		]);

		// El abierto es el definitorio de la quintilla, pero declara que no hay disposición fija:
		// no puede ocupar la fila.
		expect(elegido?.id).toBe('ababa');
	});
});

describe('el perfil de una arquitectura', () => {
	const base = { variedades: 0, tieneCicloDeEstribillo: false };

	it('reconoce la estrofa de disposición elegible', () => {
		expect(
			perfilDeArquitectura({
				...entrada({
					unidadMin: 5,
					unidadMax: 5,
					metricos: [metricoIsosilabico('8')],
					rimas: [rima('ababa', 'ababa', { modalidad: 'habitual' })]
				}),
				...base
			})
		).toBe('estrofa_elegible');
	});

	it('reconoce la serie cíclica, la estrofa compuesta y la serie abierta', () => {
		expect(
			perfilDeArquitectura({
				...entrada({
					metricos: [metricoIsosilabico('8')],
					rimas: [
						{
							...rima('asonancia', '-a', { modalidad: 'definitoria' }),
							notacion: '[-a]…',
							enlaces: [{ desde: 2, hasta: 2, desplazamiento: 1, nota: null }]
						}
					]
				}),
				...base
			})
		).toBe('serie_ciclica');

		expect(
			perfilDeArquitectura({
				...entrada({
					unidadMin: 10,
					unidadMax: 10,
					metricos: [metricoIsosilabico('8')],
					secciones: [
						seccion('Primera quintilla', {
							versosMin: 5,
							versosMax: 5,
							reutiliza: { nombre: 'Quintilla', slug: 'quintilla' }
						}),
						seccion('Segunda quintilla', { versosMin: 5, versosMax: 5 })
					],
					rimas: []
				}),
				...base
			})
		).toBe('estrofa_compuesta');

		expect(
			perfilDeArquitectura({
				...entrada({
					metricos: [metricoIsosilabico('11')],
					rimas: []
				}),
				...base
			})
		).toBe('serie_abierta');
	});

	it('reconoce las estancias, el ciclo de estribillo y la combinatoria', () => {
		const cancion = entrada({
			secciones: [
				seccion('Estancia', { versosMin: 13, versosMax: 13, repeticionesMin: 3, repeticionesMax: null })
			]
		});
		expect(perfilDeArquitectura({ ...cancion, ...base })).toBe('estancias_declaradas');
		expect(
			perfilDeArquitectura({ ...entrada({}), ...base, tieneCicloDeEstribillo: true })
		).toBe('composicion_con_estribillo');
		expect(perfilDeArquitectura({ ...entrada({}), ...base, variedades: 7 })).toBe('combinatoria');
	});
});

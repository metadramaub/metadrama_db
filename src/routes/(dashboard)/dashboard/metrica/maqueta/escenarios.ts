/**
 * Los casos con los que se juzga una manera de preguntar.
 *
 * **La primera maqueta cubría el caso que casi no existe.** Medido sobre el corpus: de las 134
 * secuencias con unidad, solo 24 tienen una sola —el 2 % de los versos—, y las de más de diez son
 * el 53 % de las secuencias y **el 86 % de los versos**. La mayor llega a 118 unidades.
 *
 * Cuánto varían lo dicen las once secuencias que el sistema viejo anotó unidad por unidad:
 * **nunca son todas distintas**. El máximo del corpus son cuatro esquemas en 43 unidades, y siempre
 * hay uno dominante. Aun así entra aquí el caso que no se ha visto, porque lo que hay que saber no
 * es qué pasa de costumbre sino qué pasa el día que aparezca.
 *
 * Y los casos no son todos estrofas repetibles: hay series que no tienen unidades, composiciones
 * con partes y ciclos, y formas fijas que no preguntan nada. Una manera de preguntar que solo
 * funcione en la quintilla no sirve.
 */

export type RespuestaUnidad = {
	numero: number;
	vIni: number;
	vFin: number;
	valor: string;
};

export type RenglonNorma = {
	dimension: string;
	/** `fija` no hay que decidirla; `elige` sí; `admite` es una licencia rara. */
	estado: 'fija' | 'elige' | 'admite';
	texto: string;
};

export type PreguntaEscenario = {
	rotulo: string;
	/** Qué se responde: una vez para toda la secuencia, o una vez por unidad. */
	alcance: 'secuencia' | 'unidad';
	opcional: boolean;
	/** Con alcance de secuencia. */
	valor?: string;
	/** Con alcance de unidad, una entrada por unidad. */
	porUnidad?: RespuestaUnidad[];
	/** Lo que se ofrece, para que el desplegable no salga vacío. */
	opciones?: string[];
};

export type EscenarioMaqueta = {
	id: string;
	nombre: string;
	clase: string;
	porque: string;
	forma: string;
	partes: string[];
	norma: RenglonNorma[];
	preguntas: PreguntaEscenario[];
};

function porUnidad(valores: string[], versos: number, desde = 1): RespuestaUnidad[] {
	return valores.map((valor, indice) => ({
		numero: indice + 1,
		vIni: desde + indice * versos,
		vFin: desde + (indice + 1) * versos - 1,
		valor
	}));
}

const repetir = (valor: string, veces: number) => Array.from({ length: veces }, () => valor);

const TIPOLOGIAS = ['ababa', 'abbab', 'abaab', 'aabab', 'aabba', 'abbaa', 'ababb', 'abbba'];
const VOCALES = ['a-a', 'a-e', 'a-o', 'e-a', 'e-o', 'i-a', 'o-a', 'o-e'];

export const ESCENARIOS: EscenarioMaqueta[] = [
	{
		id: 'redondillas_estables',
		nombre: 'Tirada de redondillas con una suelta',
		clase: 'Estrofa repetible · 24 unidades',
		porque: 'lo normal es que no varíe, y de pronto una abba entre abab',
		forma: 'Redondilla',
		partes: [],
		norma: [
			{ dimension: 'Extensión', estado: 'fija', texto: 'unidades completas de 4 versos' },
			{ dimension: 'Medida', estado: 'fija', texto: 'octosílabo' },
			{ dimension: 'Régimen de rima', estado: 'fija', texto: 'consonante' },
			{ dimension: 'Disposición de la rima', estado: 'elige', texto: 'dos documentadas' },
			{ dimension: 'Pie quebrado', estado: 'admite', texto: 'de 4 o 5 sílabas' }
		],
		preguntas: [
			{
				rotulo: 'Esquema de rima',
				alcance: 'unidad',
				opcional: false,
				opciones: ['Abrazada · abba', 'Cruzada · abab'],
				porUnidad: porUnidad(
					[...repetir('abab', 14), 'abba', ...repetir('abab', 9)],
					4
				)
			},
			{ rotulo: 'Pie quebrado', alcance: 'unidad', opcional: true, porUnidad: [] }
		]
	},
	{
		id: 'quintillas_reales',
		nombre: 'Cincuenta y dos quintillas, tres esquemas',
		clase: 'Estrofa repetible · 52 unidades',
		porque: 'el patrón medido en El mágico prodigioso',
		forma: 'Quintilla',
		partes: [],
		norma: [
			{ dimension: 'Extensión', estado: 'fija', texto: 'unidades completas de 5 versos' },
			{ dimension: 'Medida', estado: 'fija', texto: 'octosílabo' },
			{ dimension: 'Régimen de rima', estado: 'fija', texto: 'consonante' },
			{ dimension: 'Disposición de la rima', estado: 'elige', texto: 'ocho documentadas; dos clases, sin verso suelto y sin tres seguidos iguales' },
			{ dimension: 'Pie quebrado', estado: 'admite', texto: 'una posición, de 4 o 5 sílabas' }
		],
		preguntas: [
			{
				rotulo: 'Esquema de rima',
				alcance: 'unidad',
				opcional: false,
				opciones: TIPOLOGIAS,
				porUnidad: porUnidad(
					[
						...repetir('ababa', 18),
						'abbab',
						...repetir('ababa', 9),
						'abbab',
						'abbab',
						...repetir('ababa', 5),
						'aabba',
						...repetir('ababa', 10),
						'abbab',
						'abbab',
						'aabba',
						...repetir('ababa', 3)
					],
					5
				)
			},
			{
				rotulo: 'Pie quebrado',
				alcance: 'unidad',
				opcional: true,
				porUnidad: porUnidad(repetir('', 52), 5)
					.filter((unidad) => [7, 31].includes(unidad.numero))
					.map((unidad) => ({ ...unidad, valor: 'v. 1 · tetrasílabo' }))
			}
		]
	},
	{
		id: 'quintillas_imposibles',
		nombre: 'Doce quintillas, todas distintas',
		clase: 'Estrofa repetible · el caso que no se ha visto',
		porque: 'el máximo real son 4 esquemas en 43 unidades',
		forma: 'Quintilla',
		partes: [],
		norma: [
			{ dimension: 'Extensión', estado: 'fija', texto: 'unidades completas de 5 versos' },
			{ dimension: 'Medida', estado: 'fija', texto: 'octosílabo' },
			{ dimension: 'Régimen de rima', estado: 'fija', texto: 'consonante' },
			{ dimension: 'Disposición de la rima', estado: 'elige', texto: 'ocho documentadas' },
			{ dimension: 'Pie quebrado', estado: 'admite', texto: 'una posición, de 4 o 5 sílabas' }
		],
		preguntas: [
			{
				rotulo: 'Esquema de rima',
				alcance: 'unidad',
				opcional: false,
				opciones: TIPOLOGIAS,
				porUnidad: porUnidad([...TIPOLOGIAS, ...TIPOLOGIAS.slice(0, 4)], 5)
			},
			{
				rotulo: 'Pie quebrado',
				alcance: 'unidad',
				opcional: true,
				porUnidad: porUnidad(repetir('', 12), 5)
					.filter((unidad) => [2, 5, 9, 12].includes(unidad.numero))
					.map((unidad) => ({ ...unidad, valor: 'v. 1 · tetrasílabo' }))
			}
		]
	},
	{
		id: 'sexteto_lira',
		nombre: 'Ocho sextetos-lira',
		clase: 'Estrofa repetible · con variedad',
		porque: 'la variedad combina medida y rima: dos respuestas en una',
		forma: 'Sexteto-lira',
		partes: [],
		norma: [
			{ dimension: 'Extensión', estado: 'fija', texto: 'unidades completas de 6 versos' },
			{ dimension: 'Medida', estado: 'elige', texto: 'heptasílabos y endecasílabos, según la variedad' },
			{ dimension: 'Régimen de rima', estado: 'fija', texto: 'consonante' },
			{ dimension: 'Variedad', estado: 'elige', texto: 'ocho combinaciones de medida y rima' }
		],
		preguntas: [
			{
				rotulo: 'Variedad',
				alcance: 'unidad',
				opcional: false,
				opciones: ['A1 · aBaBcC', 'A2 · ABABcC', 'B1 · aBaBCC'],
				porUnidad: porUnidad(
					['A2', 'A2', 'A2', 'A1', 'A2', 'A2', 'A1', 'A2'].map((v) => `${v} · aBaBcC`),
					6
				)
			}
		]
	},
	{
		id: 'romance',
		nombre: 'Romance de trescientos versos',
		clase: 'Serie no estrófica · sin unidades',
		porque: 'no hay unidad que recorrer: se responde una vez',
		forma: 'Romance',
		partes: [],
		norma: [
			{ dimension: 'Extensión', estado: 'fija', texto: 'serie abierta, sin unidad' },
			{ dimension: 'Medida', estado: 'fija', texto: 'octosílabo' },
			{ dimension: 'Régimen de rima', estado: 'fija', texto: 'asonante en los pares' },
			{ dimension: 'Vocales', estado: 'elige', texto: 'las veinte del repertorio' }
		],
		preguntas: [
			{ rotulo: 'Vocales de la asonancia', alcance: 'secuencia', opcional: false, valor: 'e-o', opciones: VOCALES }
		]
	},
	{
		id: 'endecasilabo_suelto',
		nombre: 'Endecasílabo suelto de doscientos versos',
		clase: 'Serie no estrófica · cinco rasgos',
		porque: 'cinco preguntas seguidas, y ninguna es una elección entre esquemas',
		forma: 'Endecasílabo suelto',
		partes: [],
		norma: [
			{ dimension: 'Extensión', estado: 'fija', texto: 'serie abierta, sin unidad' },
			{ dimension: 'Medida', estado: 'fija', texto: 'endecasílabo' },
			{ dimension: 'Régimen de rima', estado: 'fija', texto: 'sin rima obligada' },
			{ dimension: 'Densidad de rima', estado: 'elige', texto: 'ninguna, esporádica o mayoritaria' },
			{ dimension: 'Organización en pareados', estado: 'elige', texto: 'ninguna, ocasionales o habituales' },
			{ dimension: 'Dístico final', estado: 'admite', texto: '' },
			{ dimension: 'Encadenamiento interior', estado: 'admite', texto: '' },
			{ dimension: 'Final acentual', estado: 'admite', texto: 'esdrújulo' }
		],
		preguntas: [
			{ rotulo: 'Densidad de rima', alcance: 'secuencia', opcional: false, valor: 'Esporádica', opciones: ['Ninguna', 'Esporádica', 'Mayoritaria'] },
			{ rotulo: 'Organización en pareados', alcance: 'secuencia', opcional: false, valor: 'Ocasionales', opciones: ['Ninguna', 'Ocasionales', 'Habituales'] },
			{ rotulo: 'Dístico final', alcance: 'secuencia', opcional: true, valor: 'Presente', opciones: ['Presente'] },
			{ rotulo: 'Encadenamiento interior', alcance: 'secuencia', opcional: true, valor: '', opciones: ['Presente'] },
			{ rotulo: 'Final acentual', alcance: 'secuencia', opcional: true, valor: '', opciones: ['Esdrújulo'] }
		]
	},
	{
		id: 'villancico',
		nombre: 'Villancico con tres ciclos',
		clase: 'Composición · partes y ciclos',
		porque: 'las partes se repiten y cada ciclo responde lo suyo',
		forma: 'Villancico',
		partes: ['Cabeza', 'Mudanza', 'Vuelta', 'Repetición del estribillo'],
		norma: [
			{ dimension: 'Extensión', estado: 'fija', texto: 'cabeza y ciclos de mudanza, vuelta y estribillo' },
			{ dimension: 'Medida', estado: 'elige', texto: 'hexasílabo u octosílabo, el mismo en todo' },
			{ dimension: 'Régimen de rima', estado: 'fija', texto: 'consonante' },
			{ dimension: 'Rima de la mudanza', estado: 'elige', texto: 'tres documentadas' },
			{ dimension: 'Repetición del estribillo', estado: 'elige', texto: 'entera o en parte' }
		],
		preguntas: [
			{ rotulo: 'Cabeza · Medida de los versos', alcance: 'secuencia', opcional: false, valor: 'Octosílabo', opciones: ['Hexasílabo', 'Octosílabo'] },
			{
				rotulo: 'Mudanza · Esquema de rima',
				alcance: 'unidad',
				opcional: false,
				opciones: ['Mudanza en redondilla · abba', 'Mudanza en redondilla cruzada · abab'],
				porUnidad: [
					{ numero: 1, vIni: 5, vFin: 8, valor: 'abba' },
					{ numero: 2, vIni: 14, vFin: 17, valor: 'abba' },
					{ numero: 3, vIni: 23, vFin: 26, valor: 'abab' }
				]
			},
			{
				rotulo: 'Repetición del estribillo',
				alcance: 'unidad',
				opcional: false,
				opciones: ['Se repite entero', 'Se repite solo en parte'],
				porUnidad: [
					{ numero: 1, vIni: 9, vFin: 12, valor: 'Se repite entero' },
					{ numero: 2, vIni: 18, vFin: 21, valor: 'Se repite entero' },
					{ numero: 3, vIni: 27, vFin: 30, valor: 'Se repite solo en parte' }
				]
			}
		]
	},
	{
		id: 'enlazada',
		nombre: 'Redondilla enlazada de cuarenta versos',
		clase: 'Serie enlazada · no pregunta nada',
		porque: 'la norma lo fija todo: solo hay que marcar el rango',
		forma: 'Redondilla enlazada',
		partes: [],
		norma: [
			{ dimension: 'Extensión', estado: 'fija', texto: 'unidades completas de 4 versos, enlazadas' },
			{ dimension: 'Medida', estado: 'fija', texto: 'octosílabo con quebrado' },
			{ dimension: 'Régimen de rima', estado: 'fija', texto: 'consonante' },
			{ dimension: 'Disposición de la rima', estado: 'fija', texto: 'abba, enlazando con la siguiente' }
		],
		preguntas: []
	}
];

export type Grupo = {
	valor: string;
	unidades: RespuestaUnidad[];
	rangos: string;
};

/** Las unidades agrupadas por lo que responden, de la más repetida a la menos. */
export function agrupar(lista: RespuestaUnidad[]): Grupo[] {
	const mapa = new Map<string, RespuestaUnidad[]>();
	for (const unidad of lista) {
		const actual = mapa.get(unidad.valor) ?? [];
		actual.push(unidad);
		mapa.set(unidad.valor, actual);
	}
	return [...mapa.entries()]
		.map(([valor, unidades]) => ({ valor, unidades, rangos: describirRangos(unidades) }))
		.sort((a, b) => b.unidades.length - a.unidades.length);
}

/** «vv. 1-90, 106-110» en vez de dieciocho números sueltos. */
export function describirRangos(lista: RespuestaUnidad[]): string {
	if (lista.length === 0) return '';
	const tramos: { desde: number; hasta: number }[] = [];
	for (const unidad of lista) {
		const ultimo = tramos.at(-1);
		if (ultimo && unidad.vIni === ultimo.hasta + 1) {
			ultimo.hasta = unidad.vFin;
			continue;
		}
		tramos.push({ desde: unidad.vIni, hasta: unidad.vFin });
	}
	return 'vv. ' + tramos.map((tramo) => `${tramo.desde}-${tramo.hasta}`).join(', ');
}

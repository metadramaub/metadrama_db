/**
 * Los escenarios de variación con los que se juzga una maqueta.
 *
 * **La maqueta anterior cubría el caso que casi no existe.** Medido sobre el corpus real: de las
 * 134 secuencias con unidad, solo 24 tienen una sola —el 2 % de los versos—, y las de más de diez
 * unidades son el 53 % de las secuencias y **el 86 % de los versos**. La mayor llega a 118 unidades.
 *
 * Y cuánto varían se sabe por las 11 secuencias que los editores del sistema viejo anotaron unidad
 * por unidad: **nunca son todas distintas**. El máximo de variedad en todo el corpus son cuatro
 * esquemas en 43 unidades, y siempre hay uno dominante —52 unidades con 3 esquemas y el mayoritario
 * 32 veces; 42 con 3 y el mayoritario 36—.
 *
 * Aun así aquí se incluye el caso que no se ha visto nunca —todas distintas, con quebrados
 * dispersos—, porque una maqueta que solo aguante lo corriente no sirve: lo que hay que saber es
 * qué pasa el día que aparezca.
 */

export type UnidadMaqueta = {
	numero: number;
	vIni: number;
	vFin: number;
	respuesta: string;
	/** El verso quebrado de esta unidad, si lo hay. */
	quebrado: number | null;
};

export type EscenarioMaqueta = {
	id: string;
	nombre: string;
	porque: string;
	forma: string;
	versosPorUnidad: number;
	/** Las partes de la unidad, cuando la arquitectura las tiene. */
	partes: string[];
	unidades: UnidadMaqueta[];
};

/** Construye las unidades a partir de la lista de respuestas, una por unidad. */
function unidades(
	respuestas: string[],
	versosPorUnidad: number,
	quebrados: Record<number, number> = {},
	desde = 1
): UnidadMaqueta[] {
	return respuestas.map((respuesta, indice) => ({
		numero: indice + 1,
		vIni: desde + indice * versosPorUnidad,
		vFin: desde + (indice + 1) * versosPorUnidad - 1,
		respuesta,
		quebrado: quebrados[indice + 1] ?? null
	}));
}

const repetir = (valor: string, veces: number) => Array.from({ length: veces }, () => valor);

/** Las ocho tipologías de la quintilla, en el orden en que las ofrece el catálogo. */
const TIPOLOGIAS = [
	'ababa',
	'abbab',
	'abaab',
	'aabab',
	'aabba',
	'abbaa',
	'ababb',
	'abbba'
];

export const ESCENARIOS: EscenarioMaqueta[] = [
	{
		id: 'una',
		nombre: 'Una sola unidad',
		porque: '24 secuencias · el 2 % de los versos',
		forma: 'Quintilla',
		versosPorUnidad: 5,
		partes: [],
		unidades: unidades(['ababa'], 5)
	},
	{
		id: 'doce_iguales',
		nombre: 'Doce unidades, todas iguales',
		porque: 'lo corriente en tirada corta',
		forma: 'Quintilla',
		versosPorUnidad: 5,
		partes: [],
		unidades: unidades(repetir('ababa', 12), 5)
	},
	{
		id: 'cincuenta_real',
		nombre: 'Cincuenta y dos unidades, tres esquemas',
		porque: 'el patrón medido en El mágico prodigioso',
		forma: 'Quintilla',
		versosPorUnidad: 5,
		partes: [],
		unidades: unidades(
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
		id: 'todas_distintas',
		nombre: 'Doce unidades, todas distintas',
		porque: 'no se ha visto nunca; el máximo real son 4 esquemas en 43 unidades',
		forma: 'Quintilla',
		versosPorUnidad: 5,
		partes: [],
		unidades: unidades(
			[...TIPOLOGIAS, ...TIPOLOGIAS.slice(0, 4)],
			5,
			{ 2: 1, 5: 1, 9: 1, 12: 1 }
		)
	},
	{
		id: 'quebrados',
		nombre: 'Veinte unidades, quebrados sueltos',
		porque: 'el rasgo raro repartido por la tirada',
		forma: 'Quintilla',
		versosPorUnidad: 5,
		partes: [],
		unidades: unidades(repetir('ababa', 20), 5, { 3: 1, 11: 1, 17: 1 })
	},
	{
		id: 'copla_real',
		nombre: 'Doce coplas reales, con sus dos partes',
		porque: 'partes y muchas unidades a la vez',
		forma: 'Copla real',
		versosPorUnidad: 10,
		partes: ['Primera quintilla', 'Segunda quintilla'],
		unidades: unidades(
			[
				...repetir('ababa · ababa', 5),
				'ababa · abbab',
				...repetir('ababa · ababa', 3),
				'abbab · ababa',
				...repetir('ababa · ababa', 2)
			],
			10,
			{ 7: 6 }
		)
	}
];

export type Grupo = {
	respuesta: string;
	unidades: UnidadMaqueta[];
	rangos: string;
};

/**
 * Las unidades agrupadas por lo que responden, de la más repetida a la menos.
 *
 * Es la operación que todas las maquetas del caso difícil necesitan: con cuarenta unidades y dos
 * respuestas, lo que hay que enseñar son las dos respuestas, no las cuarenta unidades.
 */
export function agrupar(lista: UnidadMaqueta[]): Grupo[] {
	const mapa = new Map<string, UnidadMaqueta[]>();
	for (const unidad of lista) {
		const actual = mapa.get(unidad.respuesta) ?? [];
		actual.push(unidad);
		mapa.set(unidad.respuesta, actual);
	}
	return [...mapa.entries()]
		.map(([respuesta, unidadesDelGrupo]) => ({
			respuesta,
			unidades: unidadesDelGrupo,
			rangos: describirRangos(unidadesDelGrupo)
		}))
		.sort((a, b) => b.unidades.length - a.unidades.length);
}

/** «vv. 1-90, 106-110» en vez de dieciocho números sueltos. */
export function describirRangos(lista: UnidadMaqueta[]): string {
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

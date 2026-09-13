/**
 * Lee esquemas de rima dentro de un texto corrido.
 *
 * Un esquema es una tira de letras de rima —`aBaBcC`, `ABBA ABBA CDE CDE`, `aab:aab:bba:bba`— y
 * hay que reconocerlo en medio de la prosa, donde no viene marcado de ninguna manera fiable: el
 * volcado del PDF se come las cursivas y las comillas.
 *
 * **El peligro no es no ver un esquema, sino ver uno donde hay palabras.** El alfabeto de rima
 * usa `a`–`h`, y con esas ocho letras se escriben palabras españolas enteras. Al cotejar las dos
 * pasadas, la primera versión de esta lectura daba `decada` veinticinco veces: era «de cada»,
 * unido por encima del espacio. De ahí las tres cautelas de abajo, y de ahí que se prefiera
 * perder un esquema raro antes que inventar uno.
 */

const limpia = (t) =>
	String(t ?? '')
		.replace(/\s+/g, ' ')
		.trim();

/**
 * Palabras españolas que se escriben con las ocho letras del alfabeto de rima.
 *
 * No es una lista cerrada del idioma: son las que de verdad han aparecido en los volcados de los
 * seis libros. Se amplía cuando salga otra.
 */
const PALABRAS = new Set([
	'acaba',
	'acabe',
	'beba',
	'bebe',
	'cabe',
	'cada',
	'cede',
	'deba',
	'debe',
	'decae',
	'face',
	'haba',
	'hace',
	'hada',
	'hecha',
	'fecha'
]);

/**
 * Devuelve los esquemas de un texto, cada uno con la posición donde asoma por primera vez.
 *
 * La posición sirve para enseñar el pasaje: un esquema sin su contexto no se puede juzgar.
 */
export function esquemasDe(texto) {
	const hallados = new Map();
	for (const m of limpia(texto).matchAll(/\b[a-hA-H][a-hA-H'ºᵃ:\- ]{3,}[a-hA-H]\b/g)) {
		// 1. Cada trozo separado por espacio tiene que valer por sí solo. «de cada» no es `decada`,
		//    y «acaba de leerse» no es `acabade`: basta con exigir tres letras a cada lado.
		if (m[0].split(' ').some((t) => t.replace(/[:'-]/g, '').length < 3)) continue;

		const crudo = m[0].replace(/[\s:'-]/g, '');
		// 2. Cuatro letras mínimo y alguna repetida: un esquema repite rimas, una sigla no.
		if (!/^[a-hA-H]{4,}$/.test(crudo)) continue;
		if (!/(.).*\1/i.test(crudo)) continue;
		// 3. Y que no sea una palabra.
		if (PALABRAS.has(crudo.toLowerCase())) continue;

		if (!hallados.has(crudo)) hallados.set(crudo, m.index);
	}
	return hallados;
}

/** El mismo esquema escrito con otras mayúsculas es el mismo esquema para buscarlo. */
export const claveDe = (e) =>
	String(e)
		.replace(/[\s:'-]/g, '')
		.toLowerCase();

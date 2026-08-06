/**
 * Localiza en qué página de una fuente aparece un pasaje.
 *
 * Los volcados de `pdftotext -layout` separan las páginas con un salto de página (\f) y dejan
 * el número como una línea suelta dentro del bloque. Se busca el pasaje, se mira su bloque y
 * se devuelven los números que contiene: normalmente uno, y dos cuando el PDF escaneó un
 * pliego de dos páginas (Quilis), en cuyo caso el par es izquierda y derecha.
 *
 * No todas las fuentes sirven para esto. Navarro Tomás conserva 37 números en todo el libro y
 * Jauralde viene de un epub sin paginar: ahí se cita por el epígrafe numerado o por el título
 * de la sección, que es lo estable. El Diccionario es alfabético y se cita por su entrada.
 *
 * Uso: node scripts/lib/localizar.mjs <fichero> "<texto>"
 */
import { readFileSync } from 'node:fs';

export function localizar(ruta, aguja) {
	const bloques = readFileSync(ruta, 'utf-8').split('\f');
	const buscado = aguja.toLowerCase();
	const hallazgos = [];
	let linea = 1;

	for (const bloque of bloques) {
		const lineas = bloque.split(/\r?\n/);
		if (bloque.toLowerCase().includes(buscado)) {
			const paginas = lineas
				.map((l) => l.trim())
				.filter((l) => /^\d{1,4}$/.test(l))
				.map(Number);
			const dentro = lineas.findIndex((l) => l.toLowerCase().includes(buscado));
			hallazgos.push({
				linea: linea + dentro,
				paginas,
				texto: lineas[dentro].trim()
			});
		}
		linea += lineas.length;
	}
	return hallazgos;
}

if (process.argv[1]?.endsWith('localizar.mjs')) {
	const [, , ruta, aguja] = process.argv;
	const r = localizar(ruta, aguja);
	if (!r.length) console.log('  (sin resultados)');
	for (const h of r.slice(0, 4)) {
		console.log(`  pp. ${h.paginas.join('/') || '?'}  (línea ${h.linea})  ${h.texto.slice(0, 68)}`);
	}
}

/**
 * Comprueba que lo que un verificador dice haber transcrito está de verdad en la fuente.
 *
 * Es la pieza que hace defendible la auditoría entera. Un dictamen dice «el original dice tal
 * cosa» y adjunta la transcripción; esto **relee el fichero y comprueba que esa transcripción
 * aparece ahí**. Un verificador que cite mal queda invalidado por máquina, no por otro agente,
 * y sin depender de que nadie se lea los 267 dictámenes a mano.
 *
 * No exige coincidencia carácter a carácter, porque sería un test que nadie pasa: los volcados
 * traen ruido de OCR —«E ndecha», «heptasñabo», guiones de división al final de línea, tildes
 * perdidas— y quien transcribe junta las líneas partidas. Lo que se mide es **cuánta de la
 * transcripción se encuentra literalmente en la fuente**, en tiras de seis palabras seguidas:
 * una paráfrasis disfrazada de cita cae por debajo del umbral aunque suene igual, y una
 * transcripción honesta con ruido de OCR lo pasa.
 *
 * Lo que este script NO hace: decir si el dictamen acierta. Solo si sus pruebas existen.
 *
 * Uso:
 *   node scripts/valida-dictamenes.mjs
 *   node scripts/valida-dictamenes.mjs --carpeta docs/dominio-metrico/auditoria-fuentes/dictamenes
 */

import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BIBLIOTECA = join(RAIZ, 'docs', 'dominio-metrico', 'bibliografía');
const CARPETA_POR_DEFECTO = join(
	RAIZ,
	'docs',
	'dominio-metrico',
	'auditoria-fuentes',
	'dictamenes'
);

const FICHERO_DE_LA_FUENTE = {
	1968: join(BIBLIOTECA, 'definiciones_Morley&Bruerton.md'),
	1969: join(BIBLIOTECA, 'txt', 'Quilis-1969-metrica-espanola.txt'),
	1972: join(BIBLIOTECA, 'txt', 'Navarro-Tomas-1972-metrica-espanola.txt'),
	2014: join(BIBLIOTECA, 'txt', 'Dominguez-Caparros-2014-metrica-espanola.txt'),
	2016: join(BIBLIOTECA, 'txt', 'Dominguez-Caparros-1999-diccionario-metrica.txt'),
	2020: join(BIBLIOTECA, 'txt', 'Jauralde-Pou-2020-metrica-espanola.txt')
};

/** Umbral por debajo del cual una «transcripción» deja de serlo. */
const UMBRAL = 0.75;
const TIRA = 6;

/**
 * Deja el texto en lo que ambos lados comparten: palabras, en minúscula y sin tildes.
 *
 * Se van los guiones de división de línea —un `ma-\nnera` del volcado y el `manera` de la
 * transcripción son la misma palabra—, los saltos, la puntuación y las marcas de Markdown con
 * que el catálogo destaca lo que le importa.
 */
function normalizar(texto) {
	return (texto ?? '')
		.normalize('NFD')
		.replace(/[̀-ͯ­]/g, '')
		.toLowerCase()
		.replace(/[-–—]\s*\n\s*/g, '')
		.replace(/[*_«»""''(),.;:¡!¿?[\]]/g, ' ')
		.replace(/\s+/g, ' ')
		.trim();
}

/**
 * Qué proporción de la transcripción se encuentra literalmente en la fuente.
 *
 * Se parte en tiras de seis palabras solapadas y se cuenta cuántas aparecen. Seis es bastante
 * para que una coincidencia no sea casual y poco para que un error de OCR no arrastre el
 * fragmento entero: si una palabra está mal leída, caen las seis tiras que la contienen y
 * sobreviven las demás.
 */
function proporcionHallada(transcripcion, fuente) {
	const palabras = normalizar(transcripcion).split(' ').filter(Boolean);
	if (palabras.length < TIRA) {
		return { proporcion: fuente.includes(normalizar(transcripcion)) ? 1 : 0, tiras: 1 };
	}
	let halladas = 0;
	const total = palabras.length - TIRA + 1;
	const perdidas = [];
	for (let i = 0; i < total; i += 1) {
		const tira = palabras.slice(i, i + TIRA).join(' ');
		if (fuente.includes(tira)) halladas += 1;
		else if (perdidas.length < 3) perdidas.push(tira);
	}
	return { proporcion: halladas / total, tiras: total, perdidas };
}

function main() {
	const argv = process.argv.slice(2);
	const indice = argv.indexOf('--carpeta');
	const carpeta = indice >= 0 ? argv[indice + 1] : CARPETA_POR_DEFECTO;

	if (!existsSync(carpeta)) {
		console.error(`No hay nada que validar en ${carpeta}`);
		process.exit(1);
	}

	/**
	 * Todos los nombres que el catálogo da a cada forma, para comprobar los silencios.
	 *
	 * Una forma se llama de varias maneras, y un silencio que solo descarta una de ellas no está
	 * comprobado: Navarro puede no decir «zéjel» y tratarlo como «cantiga de estribillo».
	 */
	const denominaciones = new Map();
	for (const fila of query(
		`select fo.nombre as forma, coalesce(array_agg(d.nombre) filter (where d.nombre is not null), '{}') as alias
		 from formas_metricas fo
		 left join denominaciones_metricas d on d.forma_id = fo.forma_id
		 group by fo.nombre`
	)) {
		denominaciones.set(fila.forma, [fila.forma, ...(fila.alias ?? [])]);
	}

	const fuentes = new Map();
	let comprobadas = 0;
	let caidas = 0;

	for (const fichero of readdirSync(carpeta).filter((f) => f.endsWith('.json'))) {
		// El nombre puede traer lote —`1972-3.json`—, y la fuente son los cuatro primeros dígitos.
		const anio = fichero.slice(0, 4);
		const ruta = FICHERO_DE_LA_FUENTE[anio];
		if (!ruta || !existsSync(ruta)) {
			console.log(`\n${fichero}: no sé contra qué fichero validarlo`);
			continue;
		}
		if (!fuentes.has(anio)) fuentes.set(anio, normalizar(readFileSync(ruta, 'utf-8')));
		const fuente = fuentes.get(anio);
		const datos = JSON.parse(readFileSync(join(carpeta, fichero), 'utf-8'));

		console.log(`\n=== ${datos.fuente ?? anio} ===`);
		for (const d of datos.dictamenes ?? []) {
			// Se valida la transcripción del original y cada cita que sostiene un defecto. Lo que
			// el catálogo registra no se valida contra la fuente: **ese es justamente el texto que
			// se está juzgando**, y si coincidiera del todo no habría nada que auditar.
			//
			// Una afirmación puede consistir en un **silencio** —que la fuente no registre una
			// forma—, y entonces no hay pasaje que transcribir: el dictamen enumera lo que sí
			// registra y razona la ausencia. De esa prosa solo se puede validar lo que venga
			// entrecomillado, que es lo único que pretende ser cita.
			// El dictamen tiene que **declarar** de cuál de los dos casos se trata. Adivinarlo
			// leyendo su prosa sería exactamente el vicio que esta auditoría persigue.
			const naturaleza = String(d.naturaleza ?? '').toLowerCase();
			if (!naturaleza) {
				console.log(
					`  FALTA ${d.sobre ?? d.id}: no declara \`naturaleza\` («cita» o «silencio»), así que`,
					'no se sabe si su `texto_original` pretende ser una transcripción'
				);
			}
			const esSilencio = naturaleza === 'silencio';
			const entrecomillados = esSilencio
				? [...String(d.texto_original ?? '').matchAll(/[«"]([^»"]{12,})[»"]/g)].map((m, i) => [
						`cita ${i + 1} dentro del silencio`,
						m[1]
					])
				: [['texto_original', d.texto_original]];

			// Un silencio se comprueba al revés que una cita: no hay pasaje que localizar, sino
			// **una ausencia que confirmar**. Si el dictamen declara qué términos buscó y no
			// encontró, se vuelven a buscar aquí: es la única comprobación mecánica fuerte que
			// admite este caso, y sin ella el validador apenas roza los silencios.
			if (esSilencio) {
				// Si el dictamen no declara qué buscó, se le impone una lista mejor que la suya:
				// **todos los nombres que el catálogo da a esa forma**. Un silencio que se sostiene
				// solo porque el verificador buscó un nombre y no se le ocurrieron los otros no es
				// un silencio comprobado.
				const forma = String(d.sobre ?? '')
					.split('·')[0]
					.trim();
				const terminos = d.terminos_ausentes ?? denominaciones.get(forma) ?? [];
				if (!d.terminos_ausentes && terminos.length) {
					console.log(
						`  ···  ${d.sobre ?? d.id}: silencio comprobado contra las denominaciones del catálogo`
					);
				}
				if (!terminos.length) {
					console.log(
						`  ---  ${d.sobre ?? d.id}: silencio sin \`terminos_ausentes\`, no se puede comprobar por máquina`
					);
				}
				for (const termino of terminos) {
					comprobadas += 1;
					const aparece = fuente.includes(normalizar(termino));
					if (aparece) caidas += 1;
					console.log(
						`  ${aparece ? 'CAE ' : 'ok  '} ${d.sobre ?? d.id} · ausencia de «${termino}»: ` +
							(aparece ? 'SÍ APARECE en la fuente' : 'confirmada')
					);
				}
			}

			const pruebas = [
				...entrecomillados,
				...(d.defectos ?? []).map((f, i) => [`defecto ${i + 1} · ${f.tipo}`, f.cita_literal])
			].filter(([, texto]) => texto && String(texto).trim().length > 20);
			if (!pruebas.length) {
				console.log(`  ---  ${d.sobre ?? d.id}: sin transcripción que validar`);
			}

			for (const [etiqueta, texto] of pruebas) {
				const { proporcion, tiras, perdidas } = proporcionHallada(texto, fuente);
				comprobadas += 1;
				const pasa = proporcion >= UMBRAL;
				if (!pasa) caidas += 1;
				const marca = pasa ? 'ok  ' : 'CAE ';
				console.log(
					`  ${marca} ${d.sobre ?? d.id} · ${etiqueta}: ${(proporcion * 100).toFixed(0)}% de ${tiras} tiras`
				);
				if (!pasa && perdidas?.length) {
					console.log(`       no está en la fuente: «${perdidas[0]}…»`);
				}
			}
		}
	}

	console.log(`\n${comprobadas} transcripciones comprobadas · ${caidas} no aparecen en su fuente`);
	if (caidas > 0) {
		console.log('Un dictamen cuya prueba no está en la fuente no vale: se repite.');
	}
	process.exitCode = caidas > 0 ? 1 : 0;
}

main();

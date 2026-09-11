/**
 * Nivel 0 y nivel 1 de la auditoría de las afirmaciones de las fuentes.
 *
 * Comprueba **lo que no exige leer**: que cada localizador respeta la convención de su fuente,
 * que el ancla que declara existe de verdad en el volcado —el § de Navarro, la entrada del
 * Diccionario, el epígrafe de Jauralde, el capítulo de Morley y Bruerton— y que la página
 * declarada coincide con la que sale del propio texto. Y para lo que resuelve, **extrae el
 * pasaje**, que es lo único que van a ver después los verificadores: nadie audita con el libro
 * entero en contexto.
 *
 * El método y las fases están en `docs/dominio-metrico/plan-auditoria-fuentes.md`. Este script
 * es su fase 0 y no emite ningún juicio de fidelidad: dice dónde está el pasaje o dice que no
 * lo encuentra, y ahí acaba. Que una afirmación resuelva no significa que sea cierta.
 *
 * **Sobre qué texto se cita.** No todos los volcados sirven igual, y uno no servía en absoluto:
 * el de Quilis se había generado con `pdftotext -layout` sobre un libro a dos columnas, y la
 * herramienta fundía las dos línea a línea —«la re-» de la izquierda pegado a «contramos» de la
 * derecha—, de modo que cualquier cita literal sacada de ahí podía ser un empalme de dos
 * columnas distintas. Se regeneró sin `-layout` el 11 de septiembre de 2026. Los demás se
 * comprobaron uno a uno y leen seguido.
 *
 * Uso:
 *   node scripts/audit-fuentes.mjs
 *   node scripts/audit-fuentes.mjs --salida docs/dominio-metrico/auditoria-fuentes
 */

import { mkdirSync, readFileSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BIBLIOTECA = join(RAIZ, 'docs', 'dominio-metrico', 'bibliografía');
const SALIDA_POR_DEFECTO = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');

// --------------------------------------------------------------------------
// Las seis fuentes y cómo se ancla un pasaje en cada una
// --------------------------------------------------------------------------

/**
 * Cada fuente se identifica por su año, que es lo único estable: el título se repite entre
 * ellas —tres se llaman *Métrica española*— y el `fuente_id` no dice nada a quien lea el
 * informe.
 *
 * `anclas` enumera las que esa fuente admite. `pagina: false` significa que **una página citada
 * ahí es sospechosa por construcción**, no que sea falsa: el epub de Jauralde no está paginado,
 * así que el número tuvo que salir de otro sitio.
 */
const FUENTES = {
	1968: {
		nombre: 'Morley y Bruerton 1968',
		fichero: join(BIBLIOTECA, 'definiciones_Morley&Bruerton.md'),
		anclas: ['epigrafe'],
		pagina: false,
		nota: 'Copia a mano del capítulo V, confirmada fiel. Vale como original.'
	},
	1969: {
		nombre: 'Quilis 1969',
		fichero: join(BIBLIOTECA, 'txt', 'Quilis-1969-metrica-espanola.txt'),
		anclas: ['parrafo', 'pagina'],
		pagina: true,
		nota: 'Regenerado sin -layout el 11 de septiembre de 2026. Dos páginas impresas por hoja.'
	},
	1972: {
		nombre: 'Navarro Tomás 1972',
		fichero: join(BIBLIOTECA, 'txt', 'Navarro-Tomas-1972-metrica-espanola.txt'),
		anclas: ['parrafo', 'pagina'],
		pagina: true,
		nota: 'El § está en el cuerpo y el índice mapea § → página impresa.'
	},
	2014: {
		nombre: 'Domínguez Caparrós 2014',
		fichero: join(BIBLIOTECA, 'txt', 'Dominguez-Caparros-2014-metrica-espanola.txt'),
		anclas: ['pagina'],
		pagina: true,
		nota: 'Volcado paginado y a una columna.'
	},
	2016: {
		nombre: 'Diccionario 2016',
		fichero: join(BIBLIOTECA, 'txt', 'Dominguez-Caparros-1999-diccionario-metrica.txt'),
		anclas: ['entrada', 'pagina'],
		pagina: true,
		nota: 'El fichero dice 1999 en su nombre pero es la 3.ª edición de 2016.'
	},
	2020: {
		nombre: 'Jauralde Pou 2020',
		fichero: join(BIBLIOTECA, 'txt', 'Jauralde-Pou-2020-metrica-espanola.txt'),
		anclas: ['epigrafe'],
		pagina: false,
		nota: 'Viene de un epub sin paginar: no hay página que comprobar.'
	}
};

// --------------------------------------------------------------------------
// Lectura de los volcados
// --------------------------------------------------------------------------

/**
 * Los pies de página de verdad, separados de los números que no lo son.
 *
 * Una línea que solo contiene un número no siempre es un pie: en el índice de Caparrós 2014 las
 * primeras son `9`, `104`, `10`, `135`, `159`… —la numeración del índice mezclada con la de sus
 * entradas—, y tomarlas por páginas desplazaba el cálculo entero. Lo que distingue a un pie es
 * que **forma una cuenta que avanza**: se busca el primer par consecutivo y a partir de ahí solo
 * se acepta un número mayor que el anterior y cercano a él.
 */
function pesarLosPies(lineas) {
	const candidatos = [];
	lineas.forEach((linea, indice) => {
		const solo = linea.trim();
		if (/^\d{1,4}$/.test(solo)) candidatos.push({ linea: indice + 1, pagina: Number(solo) });
	});

	let arranque = -1;
	for (let i = 0; i < candidatos.length - 1 && arranque < 0; i += 1) {
		for (let j = i + 1; j < candidatos.length; j += 1) {
			if (candidatos[j].linea - candidatos[i].linea > 200) break;
			if (candidatos[j].pagina === candidatos[i].pagina + 1) arranque = i;
			if (arranque >= 0) break;
		}
	}
	if (arranque < 0) return candidatos;

	const pies = [candidatos[arranque]];
	for (let i = arranque + 1; i < candidatos.length; i += 1) {
		const anterior = pies[pies.length - 1].pagina;
		const actual = candidatos[i].pagina;
		if (actual > anterior && actual <= anterior + 10) pies.push(candidatos[i]);
	}
	return pies;
}

/**
 * Un volcado, con sus pies de página y sus bloques de hoja.
 *
 * `pdftotext` separa las hojas con un salto de página; los bloques se conservan porque dicen
 * cuántas páginas impresas lleva cada hoja —dos en Quilis, cuyo PDF escaneó pliegos dobles—,
 * pero **quien manda para situar un pasaje es el pie**, no el bloque.
 */
function leerVolcado(ruta) {
	if (!existsSync(ruta)) return null;
	const texto = readFileSync(ruta, 'utf-8');
	const lineas = texto.split(/\r?\n/);
	const pies = pesarLosPies(lineas);
	const bloques = [];
	let inicio = 1;
	for (const bloque of texto.split('\f')) {
		const suyas = bloque.split(/\r?\n/);
		bloques.push({
			linea_inicio: inicio,
			linea_fin: inicio + suyas.length - 1,
			paginas: suyas
				.map((l) => l.trim())
				.filter((l) => /^\d{1,4}$/.test(l))
				.map(Number)
		});
		inicio += suyas.length;
	}
	return { ruta, lineas, bloques, pies };
}

/**
 * En qué página cae una línea.
 *
 * **El número va al pie**, no a la cabeza: en los cuatro volcados paginados la línea suelta con
 * el número aparece *después* del texto de esa página. Tomar el número del bloque que contiene
 * la línea daba sistemáticamente la página anterior, y con ese error el informe acusaba a
 * veinticuatro afirmaciones correctas del Diccionario de citar mal. La página de una línea es
 * **el primer número que aparece de ella en adelante**.
 */
function paginasDeLinea(volcado, linea) {
	const siguiente = volcado.pies.find((p) => p.linea >= linea);
	return siguiente ? [siguiente.pagina] : [];
}

/**
 * El índice de Navarro Tomás mapea cada § a su página impresa.
 *
 * Es lo que salva la paginación de ese libro: el cuerpo solo lleva el número en la línea del
 * titulillo, mezclado con el nombre del período, y ahí no se puede confiar. Las líneas del
 * índice son `207. Endecha real ............. 283`.
 */
function indiceDeNavarro(volcado) {
	const mapa = new Map();
	if (!volcado) return mapa;
	volcado.lineas.forEach((linea) => {
		const hallazgo = linea.match(/^\s*(\d{1,3})\.\s+(.+?)\s*\.{3,}\s*(\d{1,4})\s*$/);
		if (hallazgo) mapa.set(Number(hallazgo[1]), Number(hallazgo[3]));
	});
	return mapa;
}

// --------------------------------------------------------------------------
// Qué declara un localizador
// --------------------------------------------------------------------------

/**
 * Descompone el localizador en las anclas que declara.
 *
 * No normaliza ni corrige: si alguien escribió «Entrada «Sestina»» sobre un epígrafe de
 * capítulo, aquí sale como entrada y el informe lo marca como convención rota. Corregirlo sería
 * tapar justamente lo que se audita.
 */
function anclasDeclaradas(localizador) {
	const texto = localizador ?? '';
	const paginas = [...texto.matchAll(/\bpp?\.\s*(\d{1,4})(?:\s*[-–]\s*(\d{1,4}))?/g)].flatMap(
		(m) => (m[2] ? [Number(m[1]), Number(m[2])] : [Number(m[1])])
	);
	const parrafos = [...texto.matchAll(/§{1,2}\s*(\d+(?:\.\d+)*)/g)].map((m) => m[1]);
	// Un «§§ 67 y 68» declara dos: el segundo va suelto tras la conjunción.
	const segundos = [...texto.matchAll(/§§\s*\d+(?:\.\d+)*\s+y\s+(\d+(?:\.\d+)*)/g)].map(
		(m) => m[1]
	);
	const entrecomillado = [...texto.matchAll(/«([^»]+)»/g)].map((m) => m[1]);
	const esEntrada = /\bs\.\s*v\.|entrada|glosario/i.test(texto);
	return {
		paginas,
		parrafos: [...new Set([...parrafos, ...segundos])],
		// Un «s. v. «x»» puede además llevar epígrafes: se prueban las dos lecturas y basta con
		// que una resuelva. Distinguirlas de antemano obligaría a acertar la intención de quien
		// escribió el localizador, que es justo lo que no se puede dar por supuesto.
		entradas: esEntrada ? entrecomillado : [],
		epigrafes: entrecomillado
	};
}

/**
 * Los apellidos de las otras cinco, para detectar un localizador que remite fuera de su fuente.
 *
 * `s. v. «cuarteto alirado», recogido en el Diccionario` cuelga de Navarro Tomás y manda a otra
 * obra. Puede ser una nota inocente de quien anotó o puede ser que la afirmación sea del
 * Diccionario y se haya atribuido a Navarro; **el nivel 0 no lo decide**, solo lo señala.
 */
const APELLIDOS = {
	1968: /morley|bruerton/i,
	1969: /quilis/i,
	1972: /navarro/i,
	2014: /caparr[óo]s|métrica española de 2014/i,
	2016: /diccionario/i,
	2020: /jauralde/i
};

function remiteFuera(localizador, anio) {
	const texto = localizador ?? '';
	return Object.entries(APELLIDOS)
		.filter(([otro, patron]) => String(otro) !== String(anio) && patron.test(texto))
		.map(([otro]) => FUENTES[otro].nombre);
}

// --------------------------------------------------------------------------
// Resolución del ancla en el volcado
// --------------------------------------------------------------------------

const NORMALIZA = (s) =>
	s.toLowerCase().normalize('NFD').replace(/[̀-ͯ­]/g, '').replace(/\s+/g, ' ').trim();

/** El § de Navarro abre párrafo: `207. E ndecha real.—`. El índice lleva puntos y se descarta. */
function buscarParrafoNavarro(volcado, numero) {
	const patron = new RegExp(`^\\s*${numero}\\.\\s`);
	for (let i = 0; i < volcado.lineas.length; i += 1) {
		const linea = volcado.lineas[i];
		if (patron.test(linea) && !/\.{3,}/.test(linea)) return i + 1;
	}
	return null;
}

/** El § de Quilis abre párrafo con su número jerárquico y un título en mayúscula. */
function buscarParrafoQuilis(volcado, numero) {
	const patron = new RegExp(`^\\s*${numero.replace(/\./g, '\\.')}\\.\\s*[A-ZÁÉÍÓÚ]`);
	for (let i = 0; i < volcado.lineas.length; i += 1) {
		if (patron.test(volcado.lineas[i])) return i + 1;
	}
	return null;
}

/**
 * La entrada de un diccionario o de un glosario.
 *
 * El Diccionario escribe `octava alirada (Navarro Tomás). Estrofa formada por…`: **la autoridad
 * va entre paréntesis antes del punto**, y exigir el punto pegado al lema daba por inexistentes
 * cinco entradas que están ahí. El glosario de Navarro Tomás, que también se cita así, abre en
 * mayúscula.
 */
function buscarEntrada(volcado, entrada) {
	const buscada = NORMALIZA(entrada);
	for (let i = 0; i < volcado.lineas.length; i += 1) {
		const cabeza = volcado.lineas[i].match(/^\s{0,4}([^.()]{1,60}?)\s*(?:\([^)]*\))?\.\s/);
		if (cabeza && NORMALIZA(cabeza[1]) === buscada) return i + 1;
	}
	return null;
}

/**
 * El epígrafe, en Jauralde y en Morley y Bruerton.
 *
 * En Jauralde hay que saltarse el índice, donde los mismos títulos aparecen antes que en el
 * cuerpo: se devuelve la **última** coincidencia, que es la del texto. En Morley y Bruerton los
 * epígrafes son encabezados de Markdown.
 */
function buscarEpigrafe(volcado, epigrafe) {
	const buscado = NORMALIZA(epigrafe);
	let ultima = null;
	for (let i = 0; i < volcado.lineas.length; i += 1) {
		// Se quitan la marca de Markdown, la numeración romana del capítulo y los puntos guía del
		// índice: `### **Sestina**`, `V. Definición de las Formas Métricas` y `Seguidillas ..... 341`
		// son el mismo encabezado escrito de tres maneras.
		const limpia = NORMALIZA(
			volcado.lineas[i]
				.replace(/^#+\s*/, '')
				.replace(/\*/g, '')
				.replace(/^\s*[IVXLC]+\.\s*/, '')
				.replace(/\s*\.{3,}\s*\d*\s*$/, '')
		);
		if (limpia === buscado) ultima = i + 1;
	}
	return ultima;
}

/**
 * Dónde empieza una página impresa.
 *
 * Como el número va al pie, el texto de la página N va **desde el pie anterior hasta el suyo**.
 */
function buscarPagina(volcado, numero) {
	const indice = volcado.pies.findIndex((p) => p.pagina === numero);
	if (indice < 0) return null;
	return indice === 0 ? 1 : volcado.pies[indice - 1].linea + 1;
}

// --------------------------------------------------------------------------
// Nivel 1: el extracto
// --------------------------------------------------------------------------

const LINEAS_EXTRACTO = 70;

/**
 * El pasaje y su contexto, que es lo único que verá el verificador.
 *
 * Se da contexto generoso por delante y por detrás porque el defecto que más importa —que la
 * fuente matice donde la afirmación afirma— suele estar en la frase siguiente, no en la citada.
 */
function extraer(volcado, linea) {
	const inicio = Math.max(1, linea - 3);
	const fin = Math.min(volcado.lineas.length, linea + LINEAS_EXTRACTO);
	return {
		fichero: volcado.ruta.slice(volcado.ruta.indexOf('bibliografía')),
		linea_inicio: inicio,
		linea_fin: fin,
		paginas_del_bloque: paginasDeLinea(volcado, linea),
		texto: volcado.lineas.slice(inicio - 1, fin).join('\n')
	};
}

// --------------------------------------------------------------------------
// El dictamen de nivel 0 de una afirmación
// --------------------------------------------------------------------------

function auditarAfirmacion(fila, volcado, perfil, indiceNavarro) {
	const anclas = anclasDeclaradas(fila.localizador);
	const avisos = [];
	let linea = null;
	let resuelta_por = null;

	if (!fila.localizador) avisos.push('sin localizador');

	// ---- ¿Declara algún ancla que se pueda seguir?
	//
	// «Apartado de la canción alirada» o «Índice de estrofas» no son localizadores: nombran un
	// sitio sin decir cuál. No acusan a la afirmación de ser falsa, pero **impiden
	// comprobarla**, y eso es un defecto por sí solo.
	const usadas = [
		anclas.paginas.length ? 'pagina' : null,
		anclas.parrafos.length ? 'parrafo' : null,
		anclas.entradas.length ? 'entrada' : null,
		anclas.epigrafes.length ? 'epigrafe' : null
	].filter(Boolean);
	if (!usadas.length && fila.localizador)
		avisos.push('localizador no seguible: no da página, § ni epígrafe entrecomillado');

	// Citar página donde no hay paginación comprobable es el único uso de ancla que se marca por
	// sí mismo: los demás se juzgan por si resuelven, no por su forma.
	if (anclas.paginas.length && !perfil.pagina) {
		avisos.push('cita página en una fuente sin paginación comprobable');
	}

	const fuera = remiteFuera(fila.localizador, fila.anio);
	for (const otra of fuera) avisos.push(`el localizador remite a ${otra}`);

	if (!volcado) return { anclas, avisos: [...avisos, 'falta el volcado'], extracto: null };

	// ---- Resolución, por orden de precisión: párrafo, entrada, epígrafe y por último página.
	//
	// **Basta con que una de las anclas declaradas resuelva.** Un localizador como
	// `§ 30, § 245 y glosario, s. v. «Lay»` declara tres sitios, y que el tercero no case no
	// significa que la afirmación no se pueda comprobar: los fallos solo se cuentan si no queda
	// ninguno en pie. Hacerlo al revés llenaba el informe de acusaciones a citas correctas.
	const fallos = [];
	const intentos = [
		...anclas.parrafos.map((n) => [
			`§ ${n}`,
			() =>
				fila.anio === 1972 ? buscarParrafoNavarro(volcado, n) : buscarParrafoQuilis(volcado, n)
		]),
		...anclas.entradas.map((e) => [`entrada «${e}»`, () => buscarEntrada(volcado, e)]),
		...anclas.epigrafes.map((e) => [`epígrafe «${e}»`, () => buscarEpigrafe(volcado, e)]),
		...anclas.paginas.map((p) => [`p. ${p}`, () => buscarPagina(volcado, p)])
	];
	for (const [etiqueta, buscar] of intentos) {
		const hallada = buscar();
		if (hallada && !linea) {
			linea = hallada;
			resuelta_por = etiqueta;
		} else if (!hallada) {
			fallos.push(etiqueta);
		}
	}
	if (!linea && fallos.length)
		avisos.push(`no resuelve ninguna de sus anclas: ${fallos.join(', ')}`);

	// ---- La página declarada contra la que sale del texto.
	let pagina_declarada = anclas.paginas[0] ?? null;
	let pagina_hallada = null;
	// Si la afirmación solo declara una página, resolverla *por* esa página y después comprobar
	// que cae en ella es una tautología: no dice nada. La comparación solo vale cuando el pasaje
	// se localizó por otra vía —un §, una entrada, un epígrafe— y la página es un dato aparte.
	const resueltaPorPagina = (resuelta_por ?? '').startsWith('p. ');
	if (linea && perfil.pagina && !resueltaPorPagina) {
		const delBloque = paginasDeLinea(volcado, linea);
		pagina_hallada = delBloque.length ? delBloque : null;
		if (fila.anio === 1972 && anclas.parrafos.length) {
			const delIndice = indiceNavarro.get(Number(anclas.parrafos[0]));
			if (delIndice) pagina_hallada = [delIndice];
		}
		if (pagina_declarada && pagina_hallada && !pagina_hallada.includes(pagina_declarada)) {
			avisos.push(`declara p. ${pagina_declarada} y el pasaje cae en ${pagina_hallada.join('/')}`);
		}
	}

	return {
		anclas,
		avisos,
		resuelta_por,
		linea,
		pagina_declarada,
		pagina_hallada,
		extracto: linea ? extraer(volcado, linea) : null
	};
}

// --------------------------------------------------------------------------
// Informe
// --------------------------------------------------------------------------

function informe(dictamenes, volcados) {
	const hoy = new Date().toISOString().slice(0, 10);
	const lineas = [];
	const total = dictamenes.length;
	const resueltas = dictamenes.filter((d) => d.linea).length;

	lineas.push('# Auditoría de las fuentes · nivel 0');
	lineas.push('');
	lineas.push(`Generado el ${hoy} con \`npm run audit:fuentes\`. **No se edita a mano.**`);
	lineas.push('');
	lineas.push(
		'**Este script no dictamina.** Prepara el trabajo: sitúa cada afirmación en su volcado,',
		'extrae el pasaje y dice de cuáles no ha sabido. Se intentó que juzgara y no sirve —cada',
		'vez que «detectó» algo, el equivocado era él: veinticuatro acusaciones por leer la',
		'paginación al revés, cinco entradas dadas por inexistentes que estaban ahí con la',
		'autoridad entre paréntesis, ocho epígrafes de Jauralde que tampoco faltaban—. **Que una',
		'afirmación resuelva no dice nada sobre si es cierta, y que no resuelva tampoco dice que',
		'sea falsa.** Eso lo deciden los verificadores con el texto delante, que es la fase',
		'siguiente del [plan](../plan-auditoria-fuentes.md).'
	);
	lineas.push('');
	lineas.push(`De **${total}** afirmaciones resuelven su localizador **${resueltas}**.`);
	lineas.push('');

	lineas.push('## Por fuente');
	lineas.push('');
	lineas.push('| Fuente | Afirmaciones | Resuelven | Con aviso | Volcado |');
	lineas.push('| --- | ---: | ---: | ---: | --- |');
	for (const anio of Object.keys(FUENTES)) {
		const suyas = dictamenes.filter((d) => String(d.anio) === anio);
		if (!suyas.length) continue;
		const perfil = FUENTES[anio];
		lineas.push(
			`| ${perfil.nombre} | ${suyas.length} | ${suyas.filter((d) => d.linea).length} | ` +
				`${suyas.filter((d) => d.avisos.length).length} | ${volcados[anio] ? perfil.nota : '**falta**'} |`
		);
	}
	lineas.push('');

	const conAviso = dictamenes.filter((d) => d.avisos.length);
	lineas.push('## Lo que el verificador tendrá que resolver a mano');
	lineas.push('');
	if (!conAviso.length) {
		lineas.push('Ninguna afirmación queda sin situar.');
	} else {
		lineas.push(
			`**${conAviso.length}** afirmaciones llegan a la verificación con algo sin resolver.`,
			'No son defectos: son los casos en que el script no ha sabido situar el pasaje por sí',
			'solo, y el verificador tendrá que buscarlo y **explicar por qué es esa página o esa',
			'sección**.'
		);
		lineas.push('');
		lineas.push('| Fuente | Sobre | Localizador | Qué falta |');
		lineas.push('| --- | --- | --- | --- |');
		for (const d of conAviso) {
			lineas.push(
				`| ${FUENTES[d.anio]?.nombre ?? d.anio} | ${d.sobre} | ${d.localizador ?? '—'} | ` +
					`${d.avisos.join('; ')} |`
			);
		}
	}
	lineas.push('');

	const sinAncla = dictamenes.filter((d) =>
		d.avisos.some((a) => a.startsWith('localizador no seguible'))
	);
	lineas.push('### Localizadores que nadie puede seguir');
	lineas.push('');
	lineas.push(
		'Esto sí es un defecto, y no hace falta leer la fuente para verlo: **«Índice de estrofas» o',
		'«Apartado sobre el verso libre» nombran un sitio sin decir cuál.** No acusan a la',
		'afirmación de ser falsa; impiden comprobarla, que para una sección titulada «Lo que dicen',
		'las fuentes» es igual de grave.'
	);
	lineas.push('');
	for (const d of sinAncla) {
		lineas.push(`- **${d.sobre}** · ${FUENTES[d.anio]?.nombre} · «${d.localizador}»`);
	}
	lineas.push('');

	lineas.push('## Qué se extrajo');
	lineas.push('');
	lineas.push(
		'Un JSON por fuente en [`extractos/`](./extractos/), con el pasaje y su contexto para cada',
		'afirmación que resuelve. Es lo único que ven los verificadores: **nunca el libro entero**.'
	);
	lineas.push('');
	return lineas.join('\n');
}

// --------------------------------------------------------------------------

function main() {
	const argv = process.argv.slice(2);
	const indiceSalida = argv.indexOf('--salida');
	const salida = indiceSalida >= 0 ? argv[indiceSalida + 1] : SALIDA_POR_DEFECTO;

	const filas = query(`
		select a.afirmacion_id, a.localizador, a.resumen, a.confianza, f.anio, f.cita,
			coalesce(fo.nombre, fo2.nombre) as forma,
			ar.nombre as arquitectura, er.nombre as esquema_rima
		from afirmaciones_fuentes_metricas a
		join fuentes_metricas f using (fuente_id)
		left join formas_metricas fo on fo.forma_id = a.forma_id
		left join arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
		left join formas_metricas fo2 on fo2.forma_id = ar.forma_id
		left join esquemas_rima er on er.esquema_rima_id = a.esquema_rima_id
		order by f.anio, coalesce(fo.nombre, fo2.nombre)
	`);

	const volcados = {};
	for (const [anio, perfil] of Object.entries(FUENTES))
		volcados[anio] = leerVolcado(perfil.fichero);
	const indiceNavarro = indiceDeNavarro(volcados[1972]);

	const dictamenes = filas.map((fila) => {
		const perfil = FUENTES[fila.anio];
		const resultado = auditarAfirmacion(fila, volcados[fila.anio], perfil, indiceNavarro);
		return {
			afirmacion_id: fila.afirmacion_id,
			anio: fila.anio,
			fuente: perfil?.nombre ?? String(fila.anio),
			sobre: fila.arquitectura
				? `${fila.forma} · ${fila.arquitectura}`
				: (fila.esquema_rima ?? fila.forma ?? '—'),
			localizador: fila.localizador,
			resumen: fila.resumen,
			...resultado
		};
	});

	mkdirSync(join(salida, 'extractos'), { recursive: true });
	for (const anio of Object.keys(FUENTES)) {
		const suyas = dictamenes.filter((d) => String(d.anio) === anio);
		if (!suyas.length) continue;
		writeFileSync(
			join(salida, 'extractos', `${anio}.json`),
			`${JSON.stringify({ fuente: FUENTES[anio].nombre, afirmaciones: suyas }, null, '\t')}\n`,
			'utf-8'
		);
	}
	writeFileSync(join(salida, 'informe-nivel-0.md'), `${informe(dictamenes, volcados)}`, 'utf-8');

	const resueltas = dictamenes.filter((d) => d.linea).length;
	const conAviso = dictamenes.filter((d) => d.avisos.length).length;
	console.log(`${dictamenes.length} afirmaciones · ${resueltas} resuelven · ${conAviso} con aviso`);
	console.log(`Informe y extractos en ${salida}`);
}

main();

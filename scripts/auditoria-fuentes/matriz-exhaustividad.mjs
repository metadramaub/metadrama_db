/**
 * Fase 4 de la auditoría de fuentes: **la matriz forma × fuente**.
 *
 * Las tres pasadas anteriores auditan lo que el catálogo dice. Esta audita lo que **no** dice: la
 * regla de exhaustividad pide que toda fuente que trate una forma tenga su afirmación, y que el
 * silencio de una fuente se registre igual que su palabra. Eso no se comprueba afirmación por
 * afirmación —una afirmación que no existe no se puede leer— sino **forma por forma**.
 *
 * Aquí no se juzga nada. Se dibuja el tablero y se marcan los huecos:
 *
 *   1. las 43 unidades del catálogo, con todas sus denominaciones;
 *   2. cuántas afirmaciones tiene cada una de cada fuente, contando también las que cuelgan de sus
 *      arquitecturas y de sus esquemas de rima, que son de la forma aunque no lo parezcan;
 *   3. **cuántas veces nombra cada fuente cada denominación**, leyendo los volcados.
 *
 * El cruce de 2 y 3 es lo único que importa: una celda vacía cuya denominación no aparece en el
 * libro es un silencio esperable; una celda vacía cuya denominación aparece treinta veces es una
 * laguna. Esa columna es la que convierte 258 celdas en una lista corta de trabajo.
 *
 * El recuento de menciones es **una pista, no un veredicto**: cuenta cadenas, y una forma puede
 * estar tratada bajo un nombre que el catálogo no recoge, o nombrada de paso sin ser tratada. Lo
 * que decide sigue siendo abrir el libro.
 *
 *   node scripts/auditoria-fuentes/matriz-exhaustividad.mjs
 */

import { existsSync, readFileSync, writeFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { query } from '../lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('../..', import.meta.url));

/** Los volcados, por año de la fuente. Morley y Bruerton es una copia a mano, no un volcado. */
const VOLCADOS = {
	1968: 'docs/dominio-metrico/bibliografía/txt/definiciones_Morley&Bruerton.md',
	1969: 'docs/dominio-metrico/bibliografía/txt/Quilis-1969-metrica-espanola.txt',
	1972: 'docs/dominio-metrico/bibliografía/txt/Navarro-Tomas-1972-metrica-espanola.txt',
	2014: 'docs/dominio-metrico/bibliografía/txt/Dominguez-Caparros-2014-metrica-espanola.txt',
	2016: 'docs/dominio-metrico/bibliografía/txt/Dominguez-Caparros-1999-diccionario-metrica.txt',
	2020: 'docs/dominio-metrico/bibliografía/txt/Jauralde-Pou-2020-metrica-espanola.txt'
};

/**
 * Sin tildes y en minúsculas, que es como hay que buscar en un volcado de OCR.
 *
 * **Y con el guion tratado como espacio.** El catálogo escribe «Cuarteto-lira» y Caparrós escribe
 * «cuarteto lira»: sin esto, su epígrafe no contaba y la celda salía a cero. Lo mismo hace el guion
 * de corte de línea que el OCR deja pegado.
 */
function plano(texto) {
	return texto
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.replace(/[­‐-―-]/g, ' ')
		.toLowerCase();
}

/**
 * Cuenta las apariciones de una denominación en un texto ya aplanado.
 *
 * Se exige frontera de palabra a los dos lados para que «octava» no cuente dentro de «octavilla»,
 * y se admite el **plural**, porque los manuales titulan en plural —«Estrofas de ocho versos»— y
 * definen en singular: no contarlo dejaría a cero fuentes que tratan la forma en su epígrafe.
 *
 * Las denominaciones de menos de cuatro letras no se cuentan: son demasiado frecuentes como
 * fragmento de otra cosa y el recuento diría más ruido que señal.
 */
function menciones(textoPlano, denominacion) {
	const base = plano(denominacion).trim();
	if (base.length < 4) return 0;
	const escapada = base.replace(/[.*+?^${}()|[\]\\]/g, '\\$&').replace(/\s+/g, '\\s+');
	const patron = new RegExp(`(?<![a-z0-9])${escapada}(e?s)?(?![a-z0-9])`, 'g');
	return (textoPlano.match(patron) ?? []).length;
}

// ═══════════════════════════════════════════════════════════════════ Los datos

const fuentes = query(
	`select fuente_id::text as id, anio, autoria, titulo from public.fuentes_metricas order by anio`
);

const unidades = query(`
	select forma_id::text as id, nombre, slug, tipo_registro
	from public.formas_metricas
	where activo
	order by tipo_registro, nombre
`);

/**
 * Las denominaciones de cada unidad: su nombre y todos los alias, **incluidos los de sus
 * arquitecturas y esquemas de rima**, que es donde viven los nombres históricos —«octava rima»,
 * «copla de pie quebrado»—. Buscar solo por el nombre del catálogo daría ceros falsos.
 */
const alias = query(`
	select coalesce(d.forma_id, a.forma_id, ar.forma_id)::text as forma_id, d.nombre
	from public.denominaciones_metricas d
	left join public.arquitecturas_forma a on a.arquitectura_id = d.arquitectura_id
	left join public.esquemas_rima e on e.esquema_rima_id = d.esquema_rima_id
	left join public.arquitecturas_forma ar on ar.arquitectura_id = e.arquitectura_id
	where coalesce(d.forma_id, a.forma_id, ar.forma_id) is not null
`);

/** Las afirmaciones, atribuidas a la forma de la que cuelgan directa o indirectamente. */
const afirmaciones = query(`
	select coalesce(af.forma_id, a.forma_id, ar.forma_id)::text as forma_id, f.anio
	from public.afirmaciones_fuentes_metricas af
	join public.fuentes_metricas f using (fuente_id)
	left join public.arquitecturas_forma a on a.arquitectura_id = af.arquitectura_id
	left join public.esquemas_rima e on e.esquema_rima_id = af.esquema_rima_id
	left join public.arquitecturas_forma ar on ar.arquitectura_id = e.arquitectura_id
`);

// ═══════════════════════════════════════════════════════════════════ El cruce

const textos = new Map();
for (const [anio, ruta] of Object.entries(VOLCADOS)) {
	if (!existsSync(RAIZ + ruta)) {
		console.error(`  falta el volcado de ${anio}: ${ruta}`);
		continue;
	}
	textos.set(Number(anio), plano(readFileSync(RAIZ + ruta, 'utf-8')));
}

const denominaciones = new Map();
for (const u of unidades) denominaciones.set(u.id, new Set([u.nombre]));
for (const a of alias) denominaciones.get(a.forma_id)?.add(a.nombre);

const cuenta = new Map();
for (const af of afirmaciones) {
	if (!af.forma_id) continue;
	const clave = `${af.forma_id}|${af.anio}`;
	cuenta.set(clave, (cuenta.get(clave) ?? 0) + 1);
}

/**
 * Dos formas del catálogo se llaman **las dos «Sextina»**: la estrofa de seis endecasílabos y la
 * composición que se hace con ellas. Se distinguen por su slug, no por su nombre, así que en esta
 * matriz —donde cada fila ha de poder señalarse sin ambigüedad— el nombre repetido lleva el slug.
 */
const repetidos = new Set(
	unidades.map((u) => u.nombre).filter((n, i, t) => t.indexOf(n) !== i)
);

const filas = unidades.map((u) => {
	const etiqueta = repetidos.has(u.nombre) ? `${u.nombre} (${u.slug})` : u.nombre;
	const nombres = [...denominaciones.get(u.id)].sort();
	const celdas = fuentes.map((f) => {
		const texto = textos.get(f.anio) ?? '';
		const porNombre = [];
		let total = 0;
		for (const n of nombres) {
			const veces = menciones(texto, n);
			if (veces > 0) porNombre.push({ nombre: n, veces });
			total += veces;
		}
		porNombre.sort((x, y) => y.veces - x.veces);
		return {
			anio: f.anio,
			afirmaciones: cuenta.get(`${u.id}|${f.anio}`) ?? 0,
			menciones: total,
			porNombre: porNombre.slice(0, 4)
		};
	});
	return { ...u, etiqueta, denominaciones: nombres, celdas };
});

// ═══════════════════════════════════════════════════════════════════ La salida

const vacias = [];
for (const fila of filas) {
	for (const c of fila.celdas) {
		if (c.afirmaciones === 0) vacias.push({ forma: fila.etiqueta, id: fila.id, ...c });
	}
}
const sinNinguna = filas.filter((f) => f.celdas.every((c) => c.afirmaciones === 0));
const conRuido = vacias.filter((c) => c.menciones > 0).sort((a, b) => b.menciones - a.menciones);

writeFileSync(
	RAIZ + 'docs/dominio-metrico/auditoria-fuentes/matriz-exhaustividad.json',
	JSON.stringify({ generado: new Date().toISOString().slice(0, 10), fuentes, filas }, null, '\t') +
		'\n',
	'utf-8'
);

const dondeSale = (c) => c.porNombre.map((p) => `«${p.nombre}» ×${p.veces}`).join(', ');
const L = [];
L.push('# Matriz de exhaustividad · forma × fuente');
L.push('');
L.push('Generado por `node scripts/auditoria-fuentes/matriz-exhaustividad.mjs`. **No juzga nada**: dice cuántas');
L.push('afirmaciones tiene cada celda y cuántas veces nombra esa fuente a esa forma. El recuento de');
L.push('menciones cuenta cadenas, así que es una pista para saber dónde mirar, no un veredicto.');
L.push('');
L.push(
	`${filas.length} unidades × ${fuentes.length} fuentes = **${filas.length * fuentes.length} celdas**, de las que **${vacias.length}** están vacías.`
);
L.push('');
L.push('## Las que no tienen ninguna fuente');
L.push('');
if (!sinNinguna.length) L.push('Ninguna: las 43 tienen al menos una afirmación.');
for (const f of sinNinguna) {
	L.push(`- **${f.etiqueta}** — ${f.celdas.reduce((s, c) => s + c.menciones, 0)} menciones en total`);
	for (const c of f.celdas.filter((x) => x.menciones > 0)) {
		L.push(`  - ${c.anio}: ${c.menciones} · ${dondeSale(c)}`);
	}
}
L.push('');
L.push('## Celdas vacías donde la fuente sí nombra la forma');
L.push('');
L.push('Ordenadas por menciones. Cada una es un silencio que hay que justificar o una laguna.');
L.push('');
L.push('| forma | fuente | menciones | dónde |');
L.push('| --- | --- | --- | --- |');
for (const c of conRuido) L.push(`| ${c.forma} | ${c.anio} | ${c.menciones} | ${dondeSale(c)} |`);
L.push('');
L.push('## El tablero');
L.push('');
L.push(`| forma | ${fuentes.map((f) => f.anio).join(' | ')} |`);
L.push(`| --- | ${fuentes.map(() => '---').join(' | ')} |`);
for (const fila of filas) {
	const celdas = fila.celdas.map((c) =>
		c.afirmaciones > 0 ? `**${c.afirmaciones}**` : c.menciones > 0 ? `· ${c.menciones}` : '—'
	);
	L.push(`| ${fila.etiqueta} | ${celdas.join(' | ')} |`);
}
L.push('');
L.push('Negrita: afirmaciones. `· n`: sin afirmación, pero la fuente la nombra n veces. `—`: silencio limpio.');
L.push('');

writeFileSync(RAIZ + 'docs/dominio-metrico/auditoria-fuentes/matriz-exhaustividad.md', L.join('\n'), 'utf-8');

console.log(`${filas.length} unidades × ${fuentes.length} fuentes`);
console.log(`${vacias.length} celdas vacías, ${conRuido.length} con la forma nombrada en el libro`);
console.log(`${sinNinguna.length} formas sin ninguna fuente`);
console.log('Matriz en docs/dominio-metrico/auditoria-fuentes/matriz-exhaustividad.md');

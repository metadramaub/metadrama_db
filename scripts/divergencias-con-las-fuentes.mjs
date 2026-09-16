/**
 * Dónde el catálogo se aparta de sus fuentes **en los datos**, no en la prosa.
 *
 * La auditoría de fuentes comprobó una cosa: que cada afirmación diga lo que su libro dice. Esto
 * mira la otra, que nadie había mirado: **si lo que el catálogo declara —esquemas, modalidades,
 * denominaciones— tiene respaldo en las seis voces que la ficha publica**.
 *
 * No es lo mismo que un error. La definición y el uso son del proyecto, se apoyan en las fuentes y
 * **pueden disentir de ellas**; lo que no vale es disentir sin saberlo. Este informe no corrige
 * nada: **localiza las divergencias para que las decida el IP**, que dirá en cada caso si son
 * desviación deliberada o descuido.
 *
 * Tampoco mira la prosa. La definición y la descripción de una ficha no repiten lo que los datos ya
 * enseñan —metro, rima, rasgos, estructura, partes—, sino lo que no cabe en ellos; de modo que para
 * saber si falta un esquema o si sobra, **mandan los datos y no el texto**.
 *
 * ## Las cuatro preguntas
 *
 * 1. **Esquemas de rima que el catálogo declara y ninguna fuente de esa forma enuncia.** Interesa
 *    sobre todo con modalidad `definitoria`: un esquema que define una forma y que nadie sostiene.
 * 2. **Esquemas que las fuentes dan y el catálogo no tiene.** Es la comprobación mecánica nº 2 vista
 *    desde aquí, y **su lista no es una lista de trabajo**: el volcado de Navarro lee la `c` como
 *    `e` —`abe:abe` por `abc:abc`— y algunas cadenas son varias estrofas seguidas. Cada candidato
 *    pasa dos filtros que solo puede aplicar quien abra el libro: que la cadena esté bien leída y
 *    que el esquema sea de esa forma y no de otra.
 * 3. **Denominaciones sin eco**, que el catálogo atribuye a una fuente que no las usa, o que no
 *    declaran de dónde salen.
 * 4. **Lo que el catálogo declara fijo y su fuente matiza.** Aquí aparecieron, por casualidad, el
 *    «aunque no es obligatorio» del esquema de la estancia y el «parecería dudosa la unidad de la
 *    novena como estrofa». Se buscan las fichas que matizan en formas que declaran un `definitoria`.
 *
 * **Lo que este informe NO puede decir** es si un esquema métrico del catálogo tiene respaldo: el
 * nuestro es un slug —`7-11-7-11-7-7-11`— y las fuentes lo dicen en prosa, «de siete y once
 * sílabas». Compararlos por texto da 94 falsos de 99, así que esa dimensión queda fuera y se lee a
 * mano el día que toque.
 *
 * Uso:
 *   node scripts/divergencias-con-las-fuentes.mjs
 */

import { writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const SALIDA = join(RAIZ, 'docs', 'dominio-metrico', 'divergencias-con-las-fuentes.md');

/** Las marcas con que una fuente deja abierto lo que el catálogo cierra. */
const MATIZ =
	/\b(no es obligatorio|no siempre|no necesariamente|parecer[íi]a|rara vez|puede variar|suele|generalmente|normalmente|por lo com[úu]n|a veces|probablemente|quiz[áa]s?)\b/gi;

/** Para comparar un esquema con la prosa que lo cita: solo letras y cifras. */
const plano = (s) =>
	String(s ?? '')
		.toLowerCase()
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.replace(/[^a-z0-9]/g, '');

// ─────────────────────────────────────────────────────────── Lo que dice la base

const afirmaciones = query(
	`select left(a.afirmacion_id::text, 8) as id,
		coalesce(fm.forma_id, fm2.forma_id, fm3.forma_id) as forma_id,
		f.anio, a.localizador, a.resumen
	from public.afirmaciones_fuentes_metricas a
	join public.fuentes_metricas f using (fuente_id)
	left join public.formas_metricas fm on fm.forma_id = a.forma_id
	left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
	left join public.formas_metricas fm2 on fm2.forma_id = ar.forma_id
	left join public.esquemas_rima e on e.esquema_rima_id = a.esquema_rima_id
	left join public.arquitecturas_forma ar2 on ar2.arquitectura_id = e.arquitectura_id
	left join public.formas_metricas fm3 on fm3.forma_id = ar2.forma_id`
);

const vocesDe = new Map();
for (const a of afirmaciones) {
	if (!a.forma_id) continue;
	if (!vocesDe.has(a.forma_id)) vocesDe.set(a.forma_id, []);
	vocesDe.get(a.forma_id).push(a);
}
const prosaDe = (formaId) => plano((vocesDe.get(formaId) ?? []).map((a) => a.resumen).join(' '));

const esquemas = query(
	`select fm.nombre as forma, fm.forma_id, ar.nombre as arquitectura, e.notacion, e.modalidad
	from public.formas_metricas fm
	join public.arquitecturas_forma ar on ar.forma_id = fm.forma_id
	join public.esquemas_rima e on e.arquitectura_id = ar.arquitectura_id
	where fm.activo and coalesce(e.notacion, '') <> ''
	order by fm.nombre, e.modalidad, e.notacion`
);

const denominaciones = query(
	`select fm.nombre as forma, fm.forma_id, d.nombre, f.anio
	from public.formas_metricas fm
	join public.denominaciones_metricas d on d.forma_id = fm.forma_id
	left join public.fuentes_metricas f on f.fuente_id = d.fuente_id
	where fm.activo and d.forma_id is not null
	order by fm.nombre, d.nombre`
);

// ─────────────────────────────────────────────────────────── 1 · esquemas sin respaldo

const ORDEN = { definitoria: 0, habitual: 1, admitida: 2, excepcional: 3 };
const sinRespaldo = esquemas
	.filter((e) => !prosaDe(e.forma_id).includes(plano(e.notacion)))
	.sort((a, b) => (ORDEN[a.modalidad] ?? 9) - (ORDEN[b.modalidad] ?? 9) || a.forma.localeCompare(b.forma));

// ─────────────────────────────────────────────────────────── 3 · denominaciones

const sinEco = denominaciones.filter((d) => !prosaDe(d.forma_id).includes(plano(d.nombre)));
const sinFuente = denominaciones.filter((d) => !d.anio);

// ─────────────────────────────────────────────────────────── 4 · lo fijo que la fuente matiza

const conDefinitoria = new Set(
	esquemas.filter((e) => e.modalidad === 'definitoria').map((e) => e.forma_id)
);
const nombreDe = new Map(esquemas.map((e) => [e.forma_id, e.forma]));
const matizadas = [];
for (const a of afirmaciones) {
	if (!a.forma_id || !conDefinitoria.has(a.forma_id)) continue;
	const marcas = [...new Set([...String(a.resumen ?? '').matchAll(MATIZ)].map((m) => m[0].toLowerCase()))];
	if (marcas.length) matizadas.push({ ...a, forma: nombreDe.get(a.forma_id), marcas });
}

// ─────────────────────────────────────────────────────────── El informe

const L = [];
L.push('# Divergencias del catálogo con sus fuentes');
L.push('');
L.push('Generado por `node scripts/divergencias-con-las-fuentes.mjs`. **No se edita a mano.**');
L.push('');
L.push('**Esto no es una lista de errores.** La definición y el uso de cada forma son del proyecto:');
L.push('se apoyan en las fuentes y pueden apartarse de ellas. Lo que este informe busca es que ningún');
L.push('desacuerdo quede **sin saberse**. Cada caso lo decide el IP: desviación deliberada o descuido.');
L.push('');
L.push('Mira **los datos** —esquemas, modalidades, denominaciones—, no la prosa: la definición y la');
L.push('descripción no repiten lo que los datos enseñan, sino lo que no cabe en ellos.');
L.push('');
L.push(
	`| | cuántos |\n| --- | --- |\n| Esquemas de rima que ninguna fuente enuncia | **${sinRespaldo.length}** de ${esquemas.length} |\n| — de ellos, \`definitoria\` | **${sinRespaldo.filter((e) => e.modalidad === 'definitoria').length}** |\n| Denominaciones sin eco en sus fuentes | ${sinEco.length} de ${denominaciones.length} |\n| Denominaciones sin fuente declarada | ${sinFuente.length} |\n| Afirmaciones que matizan en formas con esquema definitorio | ${matizadas.length} |`
);
L.push('');
L.push('---');
L.push('');
L.push('## 1 · Esquemas que el catálogo declara y ninguna de sus seis voces enuncia');
L.push('');
L.push('El orden es por modalidad: primero lo que **define** una forma, que es donde un desacuerdo');
L.push('pesa más. Una ausencia aquí puede ser tres cosas: que la notación se escriba distinto —nuestros');
L.push('corchetes, las mayúsculas—, que el esquema venga de la práctica del corpus y no de un libro, o');
L.push('que nadie lo sostenga. Solo lo tercero es un problema, y distinguirlo exige abrir la fuente.');
L.push('');
L.push('| forma | arquitectura | notación | modalidad |');
L.push('| --- | --- | --- | --- |');
for (const e of sinRespaldo)
	L.push(`| ${e.forma} | ${e.arquitectura ?? '—'} | \`${e.notacion}\` | **${e.modalidad}** |`);
L.push('');
L.push('## 2 · Esquemas que las fuentes dan y el catálogo no tiene');
L.push('');
L.push('Los cuenta la comprobación mecánica nº 2, en');
L.push('[senales-mecanicas.md](./auditoria-fuentes/senales-mecanicas.md). **Su lista no es una lista de');
L.push('trabajo**: el volcado de Navarro Tomás lee la `c` como `e` —imprime `abe:abe` donde el libro dice');
L.push('`abc:abc`— y algunas cadenas son varias estrofas seguidas leídas de corrido. Cada candidato pasa');
L.push('dos filtros que solo aplica quien abra el libro: que la cadena esté bien leída, y que el esquema');
L.push('sea de esa forma y no de otra.');
L.push('');
L.push('Queda fuera de esta vuelta, y sigue pendiente.');
L.push('');
L.push('## 3 · Denominaciones');
L.push('');
L.push('### Sin eco: el catálogo las atribuye a una fuente cuya ficha no las menciona');
L.push('');
L.push('| forma | denominación | fuente que se le atribuye |');
L.push('| --- | --- | --- |');
for (const d of sinEco) L.push(`| ${d.forma} | ${d.nombre} | ${d.anio ?? '—'} |`);
L.push('');
L.push('### Sin fuente declarada');
L.push('');
L.push('| forma | denominación |');
L.push('| --- | --- |');
for (const d of sinFuente) L.push(`| ${d.forma} | ${d.nombre} |`);
L.push('');
L.push('## 4 · Lo que el catálogo declara fijo y su fuente deja abierto');
L.push('');
L.push('Afirmaciones que llevan una marca de cautela en formas cuyo esquema de rima es `definitoria`.');
L.push('**La mayoría no serán nada**: una fuente puede matizar sobre algo que no es lo que el esquema');
L.push('fija. Pero por aquí salieron, sin buscarlas, el «aunque no es obligatorio» del esquema de la');
L.push('estancia y el «parecería dudosa la unidad de la novena como estrofa».');
L.push('');
L.push('| forma | fuente | afirmación | marcas |');
L.push('| --- | --- | --- | --- |');
for (const m of matizadas)
	L.push(
		`| ${m.forma} | ${m.anio} | \`${m.id}\` | ${m.marcas.map((x) => `«${x}»`).join(', ')} |`
	);
L.push('');

writeFileSync(SALIDA, L.join('\n'), 'utf-8');
console.log(
	`${sinRespaldo.length} esquemas sin respaldo (${sinRespaldo.filter((e) => e.modalidad === 'definitoria').length} definitorios) · ` +
		`${sinEco.length} denominaciones sin eco y ${sinFuente.length} sin fuente · ${matizadas.length} afirmaciones que matizan`
);
console.log('Informe en docs/dominio-metrico/divergencias-con-las-fuentes.md');

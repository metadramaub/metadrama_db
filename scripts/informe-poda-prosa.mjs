import { query } from './lib/consulta.mjs';
import { writeFileSync } from 'node:fs';

/**
 * Qué prosa del catálogo repite algo que ya está dicho en un dato estructurado.
 *
 * El criterio es el del IP, y es más severo que «lo dibuja la figura»: sobra también lo que ya
 * dicen la denominación, la modalidad, el régimen de rima, la extensión o la ficha de otra forma.
 * Cada frase se marca con la razón por la que sobra, para poder discutirla una a una.
 */

const norm = (t) =>
	t.normalize('NFD').replace(/[\u0300-\u036f]/g, '').toLowerCase();
const palabras = (t) => norm(t).replace(/[^a-z0-9 ]/g, ' ').split(/\s+/).filter((p) => p.length > 3);

const DIBUJO = new Set(`
verso versos posicion posiciones silaba silabas medida medidas rima rimas clase clases
heptasilabo heptasilabos heptasilaba heptasilabas endecasilabo endecasilabos endecasilaba endecasilabas
octosilabo octosilabos hexasilabo hexasilabos pentasilabo pentasilabos decasilabo decasilabos
dodecasilabo dodecasilabos alejandrino alejandrinos trisilabo trisilabos tetrasilabo tetrasilabos
primero primera primeros primeras segundo segunda segundos segundas tercero tercera terceros
cuarto cuarta quinto quinta sexto sexta septimo septima octavo noveno decimo ultimo ultima ultimos
uno unos dos tres cuatro cinco seis siete ocho nueve diez once doce trece catorce
impares pares mismo misma mismos mismas cada aplica aplican ocupa ocupan ocupando
repetido repetida repetidos repetidas repite repiten repitiendo ciclo ciclos serie
estrofa estrofas unidad unidades bloque bloques parte partes seccion secciones
suelto sueltos suelta sueltas asonancia asonancias consonante consonantes consonancia
riman rima quedan queda comparten comparte alternan alterna alternancia alternando
abrazada abrazado cruzada cruzado pareado pareados final finales
declara declaran registra registran emplea emplean presenta presentan
toda todo todas todos durante entre sobre desde hasta segun libre fija fijo fijas fijos
carecen normativamente cierran cierra centrales enlazan modelo
`.trim().split(/\s+/));

const MODALIDAD = /\b(m[aá]s frecuente|menos frecuente|poco frecuente|muy rara|es rara|raras? vez|habitual|lo m[aá]s corriente|la m[aá]s corriente|documentada|documentado|excepcional|la segunda m[aá]s|la m[aá]s simple|la m[aá]s antigua|no todas las fuentes)\b/i;
const REGIMEN = /\bla rima es (consonante|asonante)|de rima (consonante|asonante)|rima en consonante\b/i;
const EXTENSION = /\b(de \w+ a \w+ versos|consta de \w+ versos|tiene \w+ versos)\b/i;

/** Nombres de todas las formas y sus denominaciones, para detectar que se habla de otra. */
const formas = query(`select forma_id, slug, nombre from formas_metricas where activo`);
const denomsPorForma = new Map();
for (const d of query(`select forma_id, nombre from denominaciones_metricas where forma_id is not null`)) {
	const l = denomsPorForma.get(d.forma_id) ?? [];
	l.push(d.nombre);
	denomsPorForma.set(d.forma_id, l);
}
const otrasFormas = (formaId) =>
	formas
		.filter((f) => f.forma_id !== formaId)
		.flatMap((f) => [f.nombre, ...(denomsPorForma.get(f.forma_id) ?? [])])
		.map((n) => norm(n))
		.filter((n) => n.length > 5);

/** Denominaciones del propio esquema, que hacen redundante nombrarlas en la prosa. */
const denomsPorEsquema = new Map();
for (const d of query(`select esquema_rima_id, nombre from denominaciones_metricas where esquema_rima_id is not null`)) {
	const l = denomsPorEsquema.get(d.esquema_rima_id) ?? [];
	l.push(norm(d.nombre));
	denomsPorEsquema.set(d.esquema_rima_id, l);
}

function razon(frase, ctx) {
	const p = palabras(frase);
	if (!p.length) return null;
	const n = norm(frase);
	if (p.filter((w) => DIBUJO.has(w) || /^\d+$/.test(w)).length / p.length >= 0.75) {
		return 'lo dibuja la figura';
	}
	if (MODALIDAD.test(frase)) return 'lo dice la modalidad';
	if (REGIMEN.test(frase)) return 'lo dice el régimen de rima declarado';
	if (EXTENSION.test(frase)) return 'lo dice la extensión declarada';
	for (const d of ctx.denoms ?? []) if (n.includes(d)) return `ya es denominación suya («${d}»)`;
	for (const o of ctx.otras ?? []) if (n.includes(o)) return `habla de otra forma («${o}»)`;
	return null;
}

const CAMPOS = [
	{
		etiqueta: 'esquemas_metricos.nombre',
		sql: `select f.slug || '/' || a.slug sujeto, em.slug clave, em.nombre texto, f.forma_id, null::uuid esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_metricos em on em.arquitectura_id=a.arquitectura_id
			where f.activo and em.nombre is not null`
	},
	{
		etiqueta: 'esquemas_metricos.descripcion',
		sql: `select f.slug || '/' || a.slug sujeto, em.slug clave, em.descripcion texto, f.forma_id, null::uuid esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_metricos em on em.arquitectura_id=a.arquitectura_id
			where f.activo and em.descripcion is not null`
	},
	{
		etiqueta: 'esquema_metrico_posiciones.nota',
		sql: `select f.slug || '/' || a.slug sujeto, em.slug || ' pos.' || p.posicion clave, p.nota texto, f.forma_id, null::uuid esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_metricos em on em.arquitectura_id=a.arquitectura_id
			join esquema_metrico_posiciones p on p.esquema_metrico_id=em.esquema_metrico_id
			where f.activo and p.nota is not null`
	},
	{
		etiqueta: 'esquemas_rima.descripcion',
		sql: `select f.slug || '/' || a.slug sujeto, er.slug clave, er.descripcion texto, f.forma_id, er.esquema_rima_id esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_rima er on er.arquitectura_id=a.arquitectura_id
			where f.activo and er.descripcion is not null`
	},
	{
		etiqueta: 'esquema_rima_posiciones.nota',
		sql: `select f.slug || '/' || a.slug sujeto, er.slug || ' pos.' || p.posicion clave, p.nota texto, f.forma_id, er.esquema_rima_id esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_rima er on er.arquitectura_id=a.arquitectura_id
			join esquema_rima_posiciones p on p.esquema_rima_id=er.esquema_rima_id
			where f.activo and p.nota is not null`
	},
	{
		etiqueta: 'esquema_rima_enlaces.nota',
		sql: `select f.slug || '/' || a.slug sujeto, er.slug clave, l.nota texto, f.forma_id, er.esquema_rima_id esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_rima er on er.arquitectura_id=a.arquitectura_id
			join esquema_rima_enlaces l on l.esquema_rima_id=er.esquema_rima_id
			where f.activo and l.nota is not null`
	},
	{
		etiqueta: 'esquema_rima_restricciones.descripcion',
		sql: `select f.slug || '/' || a.slug sujeto, er.slug || ' · ' || rr.tipo clave, rr.descripcion texto, f.forma_id, er.esquema_rima_id esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join esquemas_rima er on er.arquitectura_id=a.arquitectura_id
			join esquema_rima_restricciones rr on rr.esquema_rima_id=er.esquema_rima_id
			where f.activo and rr.descripcion is not null`
	},
	{
		etiqueta: 'estructuras_secciones.nota',
		sql: `select f.slug || '/' || a.slug sujeto, s.slug clave, s.nota texto, f.forma_id, null::uuid esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join estructuras_secciones s on s.arquitectura_id=a.arquitectura_id
			where f.activo and s.nota is not null`
	},
	{
		etiqueta: 'variedades_arquitectura.descripcion',
		sql: `select f.slug || '/' || a.slug sujeto, v.slug clave, v.descripcion texto, f.forma_id, null::uuid esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join variedades_arquitectura v on v.arquitectura_id=a.arquitectura_id and v.activo
			where f.activo and v.descripcion is not null`
	},
	{
		etiqueta: 'repeticiones_metricas.descripcion',
		sql: `select f.slug || '/' || a.slug sujeto, r.slug clave, r.descripcion texto, f.forma_id, null::uuid esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join repeticiones_metricas r on r.arquitectura_id=a.arquitectura_id
			where f.activo and r.descripcion is not null`
	},
	{
		etiqueta: 'arquitectura_rasgos.nota',
		sql: `select f.slug || '/' || a.slug sujeto, rg.slug clave, ar.nota texto, f.forma_id, null::uuid esquema
			from formas_metricas f join arquitecturas_forma a on a.forma_id=f.forma_id and a.activo
			join arquitectura_rasgos ar on ar.arquitectura_id=a.arquitectura_id
			join rasgos_metricos rg on rg.rasgo_id=ar.rasgo_id
			where f.activo and ar.nota is not null`
	},
	{
		etiqueta: 'forma_relaciones.nota',
		sql: `select f.slug sujeto, r.tipo_relacion clave, r.nota texto, f.forma_id, null::uuid esquema
			from formas_metricas f join forma_relaciones r on r.forma_origen_id=f.forma_id
			where f.activo and r.nota is not null`
	}
];

/**
 * Frases señaladas por la heurística pero revisadas y conservadas por decisión del IP.
 *
 * No son «falsos positivos» genéricos: cada clave corresponde a una decisión expresa. Se
 * excluyen del pendiente para que regenerar el informe no reabra una entrada ya cerrada.
 */
const CONSERVAR = new Set([
	'esquemas_rima.descripcion|silva/consonante_regular|pareados-regulares|La clase de rima se renueva en cada bloque.',
	'arquitectura_rasgos.nota|silva/consonante_irregular|organizacion_en_pareados|Los pareados predominan, pero no forman una pauta regular ni excluyen otros enlaces.',
	'arquitectura_rasgos.nota|endecasilabo_suelto/endecasilabica|densidad_de_rima|El pasaje sigue siendo suelto mientras los versos rimados no alcancen la mitad.',
	'arquitectura_rasgos.nota|endecasilabo_suelto/endecasilabica|organizacion_en_pareados|Los pareados ocasionales no alteran la clasificación mientras los versos rimados no alcancen la mitad.',
	'arquitectura_rasgos.nota|silva/libre|organizacion_en_pareados|Puede aparecer algún pareado aislado sin que la serie se organice en pareados.',
	'arquitectura_rasgos.nota|copla_de_pie_quebrado/octosilabica_con_quebrados|densidad_de_rima|La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.',
	'arquitectura_rasgos.nota|sextilla/pie_quebrado|densidad_de_rima|La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.',
	'arquitectura_rasgos.nota|cancion_petrarquista/estancias_consonantes_variables|densidad_de_rima|La distribución elegida se repite en todas las estancias; la variación afecta al patrón, no a la presencia de rima.',
	'arquitectura_rasgos.nota|silva/consonante_regular|organizacion_en_pareados|El pareado constituye la unidad regular de organización de esta arquitectura.',
	'arquitectura_rasgos.nota|sexteto/dodecasilabica|densidad_de_rima|La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.',
	'arquitectura_rasgos.nota|sexteto/alejandrina|densidad_de_rima|La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.',
	'arquitectura_rasgos.nota|sextilla/heptasilabica|densidad_de_rima|La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.',
	'arquitectura_rasgos.nota|sextilla/hexasilabica|densidad_de_rima|La distribución de las consonancias es variable, pero la rima alcanza a todos los versos.',
	'estructuras_secciones.nota|cancion_petrarquista/regular_13_versos|remate|El remate puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o adoptar un esquema nuevo; siempre combina heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.',
	'estructuras_secciones.nota|cancion_petrarquista/estancias_consonantes_variables|remate|El remate puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o adoptar un esquema nuevo; siempre combina heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.',
	'repeticiones_metricas.descripcion|sextina/clasica|palabra_final|Las seis palabras finales se permutan durante seis estrofas y reaparecen en el terceto final, una en el interior y otra al final de cada verso. No se prescribe una única asociación por parejas.',
	'repeticiones_metricas.descripcion|sextina/doble_petrarquista|palabra_final|Las seis palabras finales se permutan durante dos ciclos estróficos y reaparecen en el terceto final, una en el interior y otra al final de cada verso. No se prescribe una única asociación por parejas.',
	'repeticiones_metricas.descripcion|sextina/doble_montemayor|palabra_final|Las seis palabras finales se distribuyen en doce combinaciones estróficas distintas y reaparecen en dos tercetos finales.',
	'forma_relaciones.nota|copla_real|compuesta_por|Las dos quintillas se separan por una pausa estructural y conservan rimas independientes.',
	'forma_relaciones.nota|decima|sucede_historicamente_a|Entre finales del siglo XVI y las primeras décadas del XVII, la espinela reemplaza progresivamente a la copla real como modalidad dominante de décima. Se trata de una sucesión histórica más que de una derivación entre ambas formas.',
	'forma_relaciones.nota|sexteto_lira|derivada_de|Es una variedad de la lira garcilasiana ampliada a seis versos, no una modificación del sexteto isosilábico: conserva la combinación de heptasílabos y endecasílabos y el cierre en pareado.',
	'forma_relaciones.nota|terceto_encadenado|relacionada_con|Se construye enlazando tercetos, pero la rima central de cada unidad se resuelve en la siguiente; por eso constituye una serie indivisible y no una repetición de tercetos independientes.',
	'forma_relaciones.nota|terceto_encadenado|relacionada_con|El cierre cruzado recibe el nombre correspondiente al arte de sus cuatro versos: serventesio en la arquitectura endecasilábica y redondilla cruzada en la octosilábica.',
	'forma_relaciones.nota|endecha_real|derivada_de|Deriva del romance heptasílabo, pero alarga a endecasílabo el cuarto verso de cada cuarteto. Conserva la asonancia única sostenida durante toda la composición y la extensión libre; la distinguen la heterometría regular y que la asonancia recaiga cada cuatro versos, no cada dos.',
	'forma_relaciones.nota|sextina|compuesta_por|La arquitectura clásica repite seis veces la estrofa; las dos arquitecturas dobles, doce.',
	'forma_relaciones.nota|sexteto|contrasta_con|«Sextina» designa la composición de palabras finales repetidas, mientras que «sexta rima» —también llamada «sextina real» por parte de la bibliografía— designa el sexteto endecasílabo ABABCC. La primera carece de rima convencional; la segunda es una estrofa consonante de seis versos.',
	'forma_relaciones.nota|soneto|compuesta_por|Los dos cuartetos forman los ocho primeros versos y comparten sus dos clases de rima.',
	'forma_relaciones.nota|soneto|compuesta_por|Los dos tercetos forman los seis últimos versos y entrelazan entre sí sus clases de rima.',
	'forma_relaciones.nota|novena|compuesta_por|La copla novena combina una redondilla y una quintilla; sus dos arquitecturas invierten el orden de los componentes.',
	'forma_relaciones.nota|decima|compuesta_por|La espinela articula dos redondillas mediante dos versos de enlace; la aumentada conserva la primera y amplía el miembro final a seis versos.',
	'forma_relaciones.nota|terceto_encadenado|relacionada_con|La arquitectura octosilábica cierra la cadena con una redondilla cruzada, equivalente funcional del serventesio final de la endecasilábica.'
]);

const lineas = [
	'# Poda de la prosa del catálogo',
	'',
	'Generado del catálogo el 13 de agosto de 2026. Repasa la prosa de **los niveles bajos**: la que',
	'acompaña a cada esquema, posición, enlace, sección, rasgo, variedad, repetición y relación.',
	'',
	'**Fuera de la poda**, y por decisión del IP: `formas_metricas.definicion` y',
	'`arquitecturas_forma.descripcion`. Esas dos sitúan la forma y no repiten un dato menudo: son',
	'la prosa que la ficha necesita para presentar aquello de lo que luego enseña las piezas.',
	'',
	'',
	'> Este archivo enseña únicamente **decisiones pendientes**. Las entradas aprobadas ya están',
	'> aplicadas mediante migraciones; cuando una prosa se conserva aunque la heurística la señale,',
	'> la decisión expresa queda registrada en el generador para que no vuelva a abrirse.',
	'',
	'Una frase se marca cuando lo que dice **ya está en un dato estructurado**: la figura, la',
	'denominación del propio esquema, la modalidad, el régimen de rima declarado, la extensión o la',
	'ficha de otra forma. Cada marca lleva su razón entre paréntesis para poder discutirla, porque',
	'la razón es lo que se aprueba o se rechaza: si el dato no lo dice, la frase se queda.',
	'',
	'Cada texto lleva una de estas dos propuestas:',
	'',
	'- **Quitar entero** — todas sus frases repiten un dato. El campo quedaría vacío.',
	'- **Acortar** — una parte dice algo que no está en ningún otro sitio, y esa se conserva.',
	'',
	'Dentro de cada texto, `—` es la frase que sobra y `+` la que se queda.',
	''
];

let totalFrases = 0;
let totalFuera = 0;
let enteros = 0;
let totalTocados = 0;
let totalTextos = 0;
const resumen = [];

for (const campo of CAMPOS) {
	const filas = query(campo.sql);
	const conPoda = [];
	let frasesCampo = 0;
	let fueraCampo = 0;
	for (const r of filas) {
		if (CONSERVAR.has(`${campo.etiqueta}|${r.sujeto}|${r.clave}|${r.texto}`)) continue;
		const ctx = {
			denoms: r.esquema ? (denomsPorEsquema.get(r.esquema) ?? []) : [],
			otras: otrasFormas(r.forma_id)
		};
		const frases = String(r.texto).split(/(?<=\.)\s+/).filter((f) => f.trim());
		const marcas = frases.map((f) => ({ frase: f, razon: razon(f, ctx) }));
		frasesCampo += frases.length;
		const fuera = marcas.filter((m) => m.razon).length;
		fueraCampo += fuera;
		if (fuera === 0) continue;
		if (fuera === frases.length) enteros += 1;
		totalTocados += 1;
		conPoda.push({ ...r, marcas, entero: fuera === frases.length });
	}
	totalTextos += filas.length;
	totalFrases += frasesCampo;
	totalFuera += fueraCampo;
	resumen.push({ campo: campo.etiqueta, textos: filas.length, tocados: conPoda.length, enteros: conPoda.filter((x) => x.entero).length, frases: frasesCampo, fuera: fueraCampo });
	if (conPoda.length === 0) continue;
	lineas.push(`## ${campo.etiqueta}`, '', `${conPoda.length} de ${filas.length} textos, ${fueraCampo} de ${frasesCampo} frases.`, '');
	for (const r of conPoda) {
		lineas.push(
			`**${r.sujeto}** · \`${r.clave}\` — ${r.entero ? '**quitar entero**' : '**acortar**'}`
		);
		lineas.push('', `Dice: «${String(r.texto).replaceAll('\n', ' ')}»`, '');
		for (const m of r.marcas) {
			lineas.push(m.razon ? `- ~~${m.frase}~~ _(${m.razon})_` : `- ${m.frase}`);
		}
		// Lo que de verdad hay que juzgar en un texto que se acorta es **cómo queda**, no qué
		// frase cae: media descripción puede quedarse coja aunque cada frase suelta sobre.
		if (!r.entero) {
			const queda = r.marcas.filter((m) => !m.razon).map((m) => m.frase.trim()).join(' ');
			lineas.push('', `**Quedaría:** «${queda}»`);
			// Un resto de tres palabras no es una descripción: es media frase. Cuando pasa, lo que
			// hay que decidir es el texto entero —quitarlo o dejarlo— y no dónde cortarlo.
			if (queda.split(/\s+/).length < 6) {
				lineas.push('', '⚠ **El resto queda cojo**: decidir el texto entero, no el corte.');
			}
		}
		lineas.push('');
	}
}

lineas.splice(
	lineas.indexOf('Dentro de cada texto, `—` es la frase que sobra y `+` la que se queda.') + 2,
	0,
	'| Campo | Quitar entero | Acortar | Sin tocar |',
	'|---|---|---|---|',
	...resumen.map(
		(r) =>
			`| \`${r.campo}\` | ${r.enteros} | ${r.tocados - r.enteros} | ${r.textos - r.tocados} |`
	),
	'',
	`**${totalFuera} frases de ${totalFrases}.** ${enteros} textos se quitarían enteros, ` +
		`${totalTocados - enteros} se acortarían y ${totalTextos - totalTocados} no se tocan.`,
	''
);

writeFileSync('docs/dominio-metrico/poda-de-la-prosa.md', lineas.join('\n'));
console.log(`frases fuera: ${totalFuera}/${totalFrases} · textos enteros: ${enteros}`);

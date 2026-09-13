/**
 * Las tres comprobaciones que ninguna de las dos pasadas hace, sobre las 267 afirmaciones.
 *
 * La muestra humana de la segunda ronda dejó tres huecos, y los tres son huecos **de método**, no
 * de esfuerzo: se le pidió a cada verificador que juzgara una ficha contra su fuente, y hay
 * defectos que no se ven mirando una ficha sola.
 *
 * - **Anclaje.** La silva arromanzada salió del grupo «limpia» —conforme para A, sin señal en el
 *   cotejo— con el defecto de colgar de la forma teniendo arquitectura propia. Ni A, ni B, ni el
 *   cotejo miran nunca de qué cuelga una afirmación: las tres leen el texto y se olvidan de la
 *   columna.
 * - **Esquemas huérfanos.** El cotejo ya avisa de que la fuente da un esquema que la ficha no
 *   registra, pero no dice si el catálogo lo tiene **en otro sitio**. Sin eso el aviso no se puede
 *   priorizar: en el septeto-lira señaló dieciséis esquemas y solo dos eran trabajo de verdad.
 * - **Vocabulario importado.** Van cuatro cláusulas que viajaron de un libro a otro y quedaron
 *   firmadas por quien no las dijo —la gaya ciencia, los entremeses, la seguidilla gitana y el
 *   «que sí recoge en el *Diccionario*»—. Las cuatro se encontraron de casualidad, cruzando
 *   fichas a mano. Esto las busca.
 *
 * **Ninguna de las tres dictamina.** Señalan dónde mirar, y están calibradas para señalar poco:
 * en esta auditoría, cada acusación mecánica que se construyó dio primero falsos positivos, y la
 * regla que quedó es que **cuando un comprobador se dispara en más de la mitad de los casos, el
 * sospechoso es el comprobador**.
 *
 * Uso:
 *   node scripts/senales-mecanicas.mjs
 */

import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';
import { esquemasDe, claveDe } from './lib/esquemas.mjs';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');
const A = join(BASE, 'dictamenes');
const B = join(BASE, 'dictamenes-b');
const SALIDA = join(BASE, 'senales-mecanicas.md');
const SALIDA_JSON = join(BASE, 'senales-mecanicas.json');

const limpia = (t, n = 0) => {
	const s = String(t ?? '')
		.replace(/\s+/g, ' ')
		.trim();
	return n && s.length > n ? `${s.slice(0, n)}…` : s;
};

const sinTildes = (t) => limpia(t).normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase();

/** El texto reducido a palabras sueltas, para buscar frases sin que estorbe la puntuación. */
const aPalabras = (t) =>
	sinTildes(t)
		.replace(/[^a-z0-9]+/g, ' ')
		.trim();

const nombra = (texto, aguja) => aPalabras(texto).includes(aPalabras(aguja));

// ══════════════════════════════════════════════════════════════════ Lo que dice la base

function leerCatalogo() {
	const afirmaciones = query(`
		select left(a.afirmacion_id::text, 8) id, f.anio, f.autoria,
			coalesce(a.forma_id, ar.forma_id, are.forma_id) forma_id,
			coalesce(fo.nombre, foa.nombre, foe.nombre) forma,
			a.arquitectura_id, ar.nombre arquitectura,
			a.esquema_rima_id, a.rasgo_id, a.tradicion_id,
			a.localizador, a.resumen,
			(a.forma_id is not null) cuelga_de_forma
		from public.afirmaciones_fuentes_metricas a
		join public.fuentes_metricas f using (fuente_id)
		left join public.formas_metricas fo on fo.forma_id = a.forma_id
		left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
		left join public.formas_metricas foa on foa.forma_id = ar.forma_id
		left join public.esquemas_rima er on er.esquema_rima_id = a.esquema_rima_id
		left join public.arquitecturas_forma are on are.arquitectura_id = er.arquitectura_id
		left join public.formas_metricas foe on foe.forma_id = are.forma_id
		order by f.anio, 5;
	`);

	const arquitecturas = query(`
		select ar.arquitectura_id, ar.forma_id, fo.nombre forma, ar.nombre, ar.orden
		from public.arquitecturas_forma ar
		join public.formas_metricas fo using (forma_id)
		where ar.activo and fo.activo
		order by fo.nombre, ar.orden;
	`);

	const denominaciones = query(`
		select d.nombre, d.arquitectura_id, ar.forma_id
		from public.denominaciones_metricas d
		join public.arquitecturas_forma ar using (arquitectura_id)
		where ar.activo and d.arquitectura_id is not null;
	`);

	const esquemas = query(`
		select e.notacion, ar.forma_id, fo.nombre forma, ar.nombre arquitectura
		from public.esquemas_rima e
		join public.arquitecturas_forma ar using (arquitectura_id)
		join public.formas_metricas fo on fo.forma_id = ar.forma_id
		where e.notacion is not null and ar.activo and fo.activo;
	`);

	return { afirmaciones, arquitecturas, denominaciones, esquemas };
}

/** Las transcripciones literales: la de la lectura ciega si la hay, y si no la de la pasada A. */
function leerTranscripciones() {
	const t = new Map();
	const cargar = (carpeta, campo, marca) => {
		if (!existsSync(carpeta)) return;
		for (const f of readdirSync(carpeta).filter((x) => x.endsWith('.json'))) {
			const d = JSON.parse(readFileSync(join(carpeta, f), 'utf-8'));
			for (const x of d[campo] ?? []) {
				const texto = limpia(x.texto_original);
				if (!texto) continue;
				// La ciega manda: leyó la fuente sin tener delante lo que el catálogo dice de ella.
				if (marca === 'B' || !t.has(x.id)) t.set(x.id, { texto, pasada: marca });
			}
		}
	};
	cargar(A, 'dictamenes', 'A');
	cargar(B, 'lecturas', 'B');
	return t;
}

// ══════════════════════════════════════════════════════ 1 · Anclaje
//
// Una afirmación cuelga de **una** cosa: la forma, una arquitectura, un esquema de rima, un rasgo
// o una tradición. Si su texto habla solo de una realización que el catálogo tiene levantada como
// arquitectura, y aun así cuelga de la forma, la ficha de esa arquitectura se queda sin la fuente
// que la documenta y la de la forma se queda con una fuente que no habla de ella.
//
// Se mira por dos caminos independientes, y lo que importa es dónde se cruzan:
//
//   a) El texto nombra, **con una denominación de dos o más palabras**, una sola arquitectura de
//      su forma. Se exigen dos palabras porque los nombres de una sola —«octosílaba»,
//      «endecasílaba»— salen en cualquier página de métrica sin señalar nada.
//   b) La misma fuente, sobre la misma forma, **sí ancló otras afirmaciones** en arquitecturas.
//      Es la asimetría que delató a la silva: dos hermanas colgadas de su arquitectura y esta no.

function comprobarAnclaje({ afirmaciones, arquitecturas, denominaciones }) {
	const porForma = new Map();
	for (const a of arquitecturas) {
		if (!porForma.has(a.forma_id)) porForma.set(a.forma_id, []);
		porForma.get(a.forma_id).push(a);
	}

	// Frases que nombran una arquitectura: su nombre precedido del de la forma, y sus
	// denominaciones registradas. Una frase que valga para dos arquitecturas de la misma forma
	// —«octavilla italiana» vale para cuatro— no identifica a ninguna, y se descarta luego.
	const frases = new Map();
	const anotar = (forma_id, arquitectura_id, texto) => {
		const f = aPalabras(texto);
		if (f.split(' ').length < 2) return;
		const k = `${forma_id}|${f}`;
		if (!frases.has(k)) frases.set(k, { forma_id, frase: f, arqs: new Set() });
		frases.get(k).arqs.add(arquitectura_id);
	};
	for (const a of arquitecturas) anotar(a.forma_id, a.arquitectura_id, `${a.forma} ${a.nombre}`);
	for (const d of denominaciones) anotar(d.forma_id, d.arquitectura_id, d.nombre);

	const porId = new Map(arquitecturas.map((a) => [a.arquitectura_id, a]));

	// Qué grupos fuente+forma tienen unas afirmaciones ancladas y otras no.
	const grupos = new Map();
	for (const a of afirmaciones) {
		const k = `${a.anio}|${a.forma_id}`;
		if (!grupos.has(k)) grupos.set(k, []);
		grupos.get(k).push(a);
	}

	const senaladas = [];
	for (const a of afirmaciones) {
		if (!a.cuelga_de_forma) continue;
		const arqs = porForma.get(a.forma_id) ?? [];
		if (arqs.length < 2) continue;

		const texto = aPalabras(`${a.resumen} ${a.localizador}`);
		const tocadas = new Map();
		for (const { forma_id, frase, arqs: ids } of frases.values()) {
			if (forma_id !== a.forma_id || ids.size !== 1) continue;
			if (!texto.includes(frase)) continue;
			const id = [...ids][0];
			if (!tocadas.has(id)) tocadas.set(id, []);
			tocadas.get(id).push(frase);
		}

		const hermanas = (grupos.get(`${a.anio}|${a.forma_id}`) ?? []).filter((x) => x.arquitectura_id);

		const unaSola = tocadas.size === 1 ? [...tocadas.keys()][0] : null;
		if (!unaSola && !hermanas.length) continue;

		senaladas.push({
			id: a.id,
			anio: a.anio,
			forma: a.forma,
			resumen: a.resumen,
			localizador: a.localizador,
			nombra: unaSola ? (porId.get(unaSola)?.nombre ?? null) : null,
			nombra_por: unaSola ? tocadas.get(unaSola) : [],
			hermanas_ancladas: hermanas.map((x) => `${x.id} → ${x.arquitectura}`),
			// Las dos señales a la vez son la combinación que encontró la silva arromanzada.
			peso: (unaSola ? 1 : 0) + (hermanas.length ? 1 : 0)
		});
	}
	senaladas.sort((x, y) => y.peso - x.peso || x.anio - y.anio);
	return senaladas;
}

// ══════════════════════════════════════════════════════ 2 · Esquemas huérfanos
//
// La fuente da un esquema que la ficha no registra. La pregunta que decide si eso es trabajo o
// ruido no es esa, sino **si el catálogo lo tiene en alguna parte**, y se responde en cuatro
// escalones, de menos a más:
//
//   modelado    → está en `esquemas_rima` de esa forma. El catálogo lo conoce de verdad.
//   hermana     → lo registra otra afirmación sobre la misma forma. Está, pero lo firma otra fuente.
//   otra forma  → aparece en el catálogo, colgando de otra forma. Casi siempre coincidencia.
//   sin rastro  → en ningún sitio. **Este es el único escalón que puede ser una laguna.**

function comprobarEsquemas({ afirmaciones, esquemas }, transcripciones) {
	const modelados = new Map();
	for (const e of esquemas) {
		const k = claveDe(e.notacion);
		if (!modelados.has(k)) modelados.set(k, []);
		modelados.get(k).push(e);
	}
	const enFichas = new Map();
	for (const a of afirmaciones)
		for (const e of esquemasDe(a.resumen).keys()) {
			const k = claveDe(e);
			if (!enFichas.has(k)) enFichas.set(k, []);
			enFichas.get(k).push(a);
		}

	const filas = [];
	const sinLectura = [];
	for (const a of afirmaciones) {
		const t = transcripciones.get(a.id);
		if (!t) {
			sinLectura.push(a);
			continue;
		}
		const propios = new Set([...esquemasDe(a.resumen).keys()].map(claveDe));
		const huerfanos = [];
		for (const [e, pos] of esquemasDe(t.texto)) {
			const k = claveDe(e);
			if (propios.has(k)) continue;
			const mod = modelados.get(k) ?? [];
			const fich = (enFichas.get(k) ?? []).filter((x) => x.id !== a.id);
			const donde = mod.some((x) => x.forma === a.forma)
				? 'modelado'
				: fich.some((x) => x.forma === a.forma)
					? 'hermana'
					: mod.length || fich.length
						? 'otra forma'
						: 'sin rastro';
			huerfanos.push({
				esquema: e,
				donde,
				en: [
					...new Set([
						...mod.filter((x) => x.forma !== a.forma).map((x) => `${x.forma} · ${x.arquitectura}`),
						...fich.filter((x) => x.forma !== a.forma).map((x) => `${x.forma} · ${x.anio}`),
						...fich.filter((x) => x.forma === a.forma).map((x) => `${x.id} (${x.anio})`)
					])
				].slice(0, 4),
				contexto: limpia(t.texto.slice(Math.max(0, pos - 95), pos + 95))
			});
		}
		if (!huerfanos.length) continue;
		filas.push({
			id: a.id,
			anio: a.anio,
			forma: a.forma,
			pasada: t.pasada,
			resumen: a.resumen,
			huerfanos,
			sin_rastro: huerfanos.filter((h) => h.donde === 'sin rastro').length
		});
	}
	filas.sort((x, y) => y.sin_rastro - x.sin_rastro || x.anio - y.anio);
	return { filas, sinLectura };
}

// ══════════════════════════════════════════════════════ 3 · Vocabulario importado
//
// Dos maneras de que una cláusula acabe firmada por quien no la dijo, y las dos se han dado ya:
//
//   a) La afirmación **nombra a otro autor o a otro libro**. A veces la fuente lo cita de verdad
//      —el *Diccionario* remite a Navarro Tomás a cada paso—, pero fue así como se coló «que sí
//      recoge en el *Diccionario*» dentro de la voz de Caparrós.
//   b) Dos afirmaciones firmadas por **fuentes distintas** comparten una tirada literal larga.
//      Que dos manuales digan lo mismo del zéjel es normal; que lo digan con las mismas veinte
//      palabras seguidas, no.

const MARCAS_DE_FUENTE = [
	{ anio: 1968, marcas: ['morley', 'bruerton'] },
	{ anio: 1969, marcas: ['quilis'] },
	{ anio: 1972, marcas: ['navarro tomas'] },
	{ anio: 2016, marcas: ['diccionario'] },
	{ anio: 2020, marcas: ['jauralde'] }
];

const SOLAPE = 7;

function comprobarVocabulario({ afirmaciones }) {
	const ajenas = [];
	for (const a of afirmaciones) {
		const citadas = [];
		for (const f of MARCAS_DE_FUENTE) {
			if (f.anio === a.anio) continue;
			const m = f.marcas.find((x) => nombra(a.resumen, x));
			if (!m) continue;
			// Caparrós firma dos de los seis libros: que uno nombre al otro no es cruce de voces.
			const mismoAutor = [f.anio, a.anio].every((n) => n === 2014 || n === 2016);
			citadas.push({ anio: f.anio, marca: m, mismo_autor: mismoAutor });
		}
		if (citadas.length)
			ajenas.push({ id: a.id, anio: a.anio, forma: a.forma, citadas, resumen: a.resumen });
	}

	// Tiradas literales compartidas entre fuentes distintas. Se guarda dónde empieza cada ventana
	// para poder volver a pegarlas: dos ventanas que arrancan en `i` e `i+1` son una tirada de
	// SOLAPE+1 palabras, y así hasta donde llegue la coincidencia.
	const palabras = new Map(
		afirmaciones.map((a) => [a.id, aPalabras(a.resumen).split(' ').filter(Boolean)])
	);
	const ventanas = new Map();
	for (const a of afirmaciones) {
		const p = palabras.get(a.id);
		for (let i = 0; i + SOLAPE <= p.length; i += 1) {
			const k = p.slice(i, i + SOLAPE).join(' ');
			if (!ventanas.has(k)) ventanas.set(k, []);
			ventanas.get(k).push({ a, i });
		}
	}
	const pares = new Map();
	for (const l of ventanas.values()) {
		for (let i = 0; i < l.length; i += 1)
			for (let j = i + 1; j < l.length; j += 1) {
				if (l[i].a.anio === l[j].a.anio) continue;
				const [x, y] = [l[i], l[j]].sort((p, q) => p.a.id.localeCompare(q.a.id));
				const kk = `${x.a.id}|${y.a.id}`;
				if (!pares.has(kk)) pares.set(kk, { x: x.a, y: y.a, inicios: new Set() });
				pares.get(kk).inicios.add(x.i);
			}
	}

	const solapes = [...pares.values()]
		.map(({ x, y, inicios }) => {
			const orden = [...inicios].sort((p, q) => p - q);
			let mejor = { desde: orden[0], hasta: orden[0] + SOLAPE };
			let desde = orden[0];
			for (let k = 1; k <= orden.length; k += 1) {
				const corta = k === orden.length || orden[k] !== orden[k - 1] + 1;
				if (!corta) continue;
				const hasta = orden[k - 1] + SOLAPE;
				if (hasta - desde > mejor.hasta - mejor.desde) mejor = { desde, hasta };
				desde = orden[k];
			}
			const tirada = palabras.get(x.id).slice(mejor.desde, mejor.hasta).join(' ');
			return {
				a: { id: x.id, anio: x.anio, forma: x.forma },
				b: { id: y.id, anio: y.anio, forma: y.forma },
				ventanas: orden.length,
				palabras: mejor.hasta - mejor.desde,
				tirada,
				mismo_autor: [x.anio, y.anio].every((n) => n === 2014 || n === 2016),
				misma_forma: x.forma === y.forma
			};
		})
		.sort((p, q) => q.palabras - p.palabras || q.ventanas - p.ventanas);

	return { ajenas, solapes };
}

// ══════════════════════════════════════════════════════════════════════════ La hoja

function main() {
	const catalogo = leerCatalogo();
	const transcripciones = leerTranscripciones();
	const anclaje = comprobarAnclaje(catalogo);
	const { filas: esquemas, sinLectura } = comprobarEsquemas(catalogo, transcripciones);
	const { ajenas, solapes } = comprobarVocabulario(catalogo);

	const total = catalogo.afirmaciones.length;
	const md = [];
	md.push('# Tres comprobaciones mecánicas sobre las afirmaciones');
	md.push('');
	md.push(
		`Generado el ${new Date().toISOString().slice(0, 10)} con \`npm run senales:mecanicas\`.`
	);
	md.push('**No se edita a mano.**');
	md.push('');
	md.push(
		`Sobre las **${total}** afirmaciones del catálogo. Ninguna de las tres dictamina: señalan`,
		'dónde mirar. Una señal que al leerla no lleva a nada es una lectura perdida; un defecto que',
		'nadie señala se queda publicado.'
	);
	md.push('');
	md.push('| Comprobación | Señaladas | De cuántas |');
	md.push('|---|---:|---:|');
	md.push(`| 1 · Anclaje | ${anclaje.length} | ${total} |`);
	md.push(
		`| 2 · Esquemas huérfanos | ${esquemas.length} | ${total - sinLectura.length} con transcripción |`
	);
	md.push(`| 3a · Nombra otra fuente | ${ajenas.length} | ${total} |`);
	md.push(`| 3b · Tirada literal compartida | ${solapes.length} pares | ${total} |`);
	md.push('');

	// ---------------------------------------------------------------- 1
	md.push('## 1 · Anclaje');
	md.push('');
	md.push('De qué cuelga la afirmación. Las que llevan **las dos señales** van primero: son la');
	md.push('combinación que encontró la silva arromanzada.');
	md.push('');
	for (const s of anclaje) {
		md.push(
			`### ${s.forma} · ${s.anio} · \`${s.id}\`${s.peso === 2 ? ' — **las dos señales**' : ''}`
		);
		md.push('');
		if (s.nombra)
			md.push(`- **Nombra solo la arquitectura «${s.nombra}»**, por: ${s.nombra_por.join(', ')}`);
		if (s.hermanas_ancladas.length)
			md.push(
				`- **Hermanas de la misma fuente que sí van ancladas:** ${s.hermanas_ancladas.join(' · ')}`
			);
		md.push('');
		md.push(`**Localizador:** ${limpia(s.localizador)}`);
		md.push('');
		md.push(`**Texto:** ${limpia(s.resumen)}`);
		md.push('');
	}

	// ---------------------------------------------------------------- 2
	md.push('## 2 · Esquemas que la fuente da y la ficha no registra');
	md.push('');
	md.push('Ordenadas por cuántos no aparecen **en ninguna parte del catálogo**, que es lo único');
	md.push('que puede ser una laguna. Lo demás está y lo firma otro.');
	md.push('');
	if (sinLectura.length) {
		md.push(
			`> **${sinLectura.length} afirmaciones no tienen transcripción literal** y quedan fuera de esta`,
			'> comprobación. Hay que releerlas antes de darla por pasada:',
			`> ${sinLectura.map((x) => `\`${x.id}\` ${x.forma} (${x.anio})`).join(' · ')}`
		);
		md.push('');
	}
	for (const f of esquemas) {
		md.push(
			`### ${f.forma} · ${f.anio} · \`${f.id}\` — ${f.sin_rastro} sin rastro de ${f.huerfanos.length}`
		);
		md.push('');
		md.push(`Transcripción de la pasada ${f.pasada}.`);
		md.push('');
		for (const h of f.huerfanos) {
			md.push(`- \`${h.esquema}\` — **${h.donde}**${h.en.length ? ` (${h.en.join(', ')})` : ''}`);
			md.push(`  <br>…${h.contexto}…`);
		}
		md.push('');
		md.push(`**Texto de la ficha:** ${limpia(f.resumen)}`);
		md.push('');
	}

	// ---------------------------------------------------------------- 3
	md.push('## 3a · La afirmación nombra otra fuente');
	md.push('');
	md.push('Puede que la fuente cite de verdad —el *Diccionario* remite a Navarro Tomás a cada');
	md.push('paso—. Hay que comprobar que la cita es suya y no nuestra.');
	md.push('');
	for (const x of ajenas) {
		md.push(
			`### ${x.forma} · ${x.anio} · \`${x.id}\` → nombra ${x.citadas
				.map((c) => `**${c.marca}** (${c.anio}${c.mismo_autor ? ', mismo autor' : ''})`)
				.join(', ')}`
		);
		md.push('');
		md.push(limpia(x.resumen));
		md.push('');
	}

	md.push(`## 3b · Tiradas de ${SOLAPE} palabras o más compartidas entre fuentes distintas`);
	md.push('');
	for (const s of solapes) {
		md.push(
			`- **${s.palabras} palabras** · \`${s.a.id}\` (${s.a.anio} ${s.a.forma}) ↔ \`${s.b.id}\` (${s.b.anio} ${s.b.forma})` +
				`${s.mismo_autor ? ' — mismo autor' : ''}${s.misma_forma ? '' : ' — **formas distintas**'}`
		);
		md.push(`  <br>«…${s.tirada}…»`);
	}
	md.push('');

	writeFileSync(SALIDA, `${md.join('\n')}\n`, 'utf-8');

	// El mismo resultado sin transcripciones, para que quede en el repositorio.
	writeFileSync(
		SALIDA_JSON,
		`${JSON.stringify(
			{
				generado: new Date().toISOString().slice(0, 10),
				total,
				anclaje: anclaje.map(({ resumen: _r, localizador: _l, ...r }) => r),
				esquemas: esquemas.map(({ resumen: _r, huerfanos, ...r }) => ({
					...r,
					huerfanos: huerfanos.map(({ contexto: _c, ...h }) => h)
				})),
				sin_transcripcion: sinLectura.map((x) => ({ id: x.id, anio: x.anio, forma: x.forma })),
				nombra_otra_fuente: ajenas.map(({ resumen: _r, ...r }) => r),
				tiradas_compartidas: solapes
			},
			null,
			'\t'
		)}\n`,
		'utf-8'
	);

	console.log(`${total} afirmaciones`);
	console.log(
		`  1 · anclaje: ${anclaje.length} (${anclaje.filter((x) => x.peso === 2).length} con las dos señales)`
	);
	const escalones = {};
	for (const f of esquemas)
		for (const h of f.huerfanos) escalones[h.donde] = (escalones[h.donde] ?? 0) + 1;
	const conRastro = esquemas.filter((f) => f.sin_rastro).length;
	console.log(
		`  2 · esquemas: ${esquemas.length} fichas con algún huérfano · ${conRastro} con alguno sin rastro`
	);
	console.log(
		`      ${Object.entries(escalones)
			.sort((a, b) => b[1] - a[1])
			.map(([k, v]) => `${v} ${k}`)
			.join(' · ')}`
	);
	if (sinLectura.length)
		console.log(`      ${sinLectura.length} afirmaciones sin transcripción literal`);
	console.log(`  3a · nombra otra fuente: ${ajenas.length}`);
	console.log(`  3b · tiradas compartidas: ${solapes.length} pares`);
	console.log(`\nHoja en ${SALIDA}`);
}

main();

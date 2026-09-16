/**
 * La hoja de correcciones: qué habría que tocar en «Lo que dicen las fuentes», y por qué.
 *
 * Se lee de todo lo que la auditoría ha producido y **no cambia nada**: propone. Ninguna corrección
 * del catálogo se aplica sin que David la haya visto y aprobado, y las que son cuestión filológica
 * no las decide él sino el IP.
 *
 * **Cada afirmación es una ficha que se basta a sí misma.** Es el punto entero de este fichero: la
 * auditoría dejó cuatro documentos —el dictamen de la pasada A, la lectura ciega de la B, el cotejo
 * de las dos y las señales mecánicas— y decidir sobre una sola afirmación obligaba a abrir los
 * cuatro y la base. Con 31 de fondo y 53 materiales eso son cientos de saltos, y cada salto es una
 * ocasión de decidir con la información a medias, que es justamente el vicio que esta auditoría
 * persigue. Aquí va todo junto, en el mismo orden siempre, para que la vista lo aprenda.
 *
 * Reparte cada afirmación según lo que pide de quien la lea, que no es lo mismo en todas:
 *
 * - **De fondo.** La fuente dice algo distinto o más matizado de lo que el catálogo le atribuye,
 *   o no se ha podido confirmar. Hay que releer y reescribir.
 * - **Material.** Un dato que está mal y cuya corrección no exige juicio: una comilla que no es
 *   textual, un § que no es el que contiene el pasaje, un localizador que nadie puede seguir, una
 *   afirmación colgada de donde no toca.
 * - **Filológico.** No hay error: hay una decisión que el proyecto no ha tomado. Va al IP.
 * - **Solo observación.** Conforme, pero algo señala que el catálogo se aparta del original sin
 *   mentir —omite un matiz, invierte el orden, cierra una lista abierta—. **Aquí va lo que hay que
 *   mirar «a la mínima duda».**
 * - **Conforme con la comprobación anotada.** Se dejó constancia de qué se cotejó y no hay
 *   divergencia. Se lista en una línea, no pide decisión.
 * - **Conforme y sin nada anotado.** No se revisa: si nada apunta a que esté mal, no hay por dónde
 *   empezar a dudar. Se cuenta, para que se vea cuánto es.
 *
 * La hoja lleva transcripciones de las seis monografías, así que **no entra en el repositorio**.
 * Lo que sí se guarda es `decisiones.json`, que solo tiene identificadores, veredictos y señales.
 *
 * Uso:
 *   node scripts/auditoria-fuentes/hoja-correcciones.mjs
 */

import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from '../lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('../..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');
const DICTAMENES = join(BASE, 'dictamenes');
const DICTAMENES_B = join(BASE, 'dictamenes-b');
const COTEJO = join(BASE, 'cotejo.json');
const MECANICAS = join(BASE, 'senales-mecanicas.json');
const HOJA = join(BASE, 'correcciones.md');
const DECISIONES = join(BASE, 'decisiones.json');
const MUESTRA = join(BASE, 'muestra-humana.json');
const PROPUESTAS = join(BASE, 'propuestas.json');

/** Los defectos que se arreglan sin discutir nada, frente a los que piden releer. */
const MATERIALES = new Set([
	'cita literal inexacta',
	'localizador falso',
	'anclaje equivocado',
	'convención rota',
	'anacronismo de edición'
]);

/**
 * Las observaciones de una afirmación conforme son de dos clases, y solo una pide mirada.
 *
 * Unas **confirman** —«el esquema y el número de versos coinciden literalmente»—: son el
 * verificador enseñando que comprobó, y no hay nada que decidir. Otras **señalan que el catálogo
 * se aparta del original** aunque no mienta: omite un matiz, invierte el orden, generaliza, cierra
 * lo que la fuente deja abierto. Esas son las que David pidió ver «a la mínima duda».
 *
 * La distinción se hace por las palabras con que se dice una divergencia. Es una heurística sobre
 * prosa, o sea falible, así que **no oculta nada**: lo que cae del lado de la confirmación sigue
 * listado en la hoja, aunque en una línea en vez de en una ficha entera.
 */
const SEÑALES_DE_DUDA =
	/\bomit|\bno (dice|aparece|menciona|recoge|figura|está|consta)|\baña[dn]|\binvierte|\bsustituy|\bgeneraliza|\bcierra\b|\bamplía|\bdiscrepan|\binconsisten|\bno se puede confirmar|\bno pude|\bdebería|\bvalorar|\bincompleta|\bmatiz|\bsalvo que|\bqueda fuera|\bes una inferencia|\bes una glosa/i;

/**
 * Junta el texto en una línea y lo recorta a `n` caracteres. **Con `n = 0` no recorta nada**, que
 * es lo que hace falta donde se enseña un texto para aprobarlo: sin esa salida, pedir «entero» con
 * un cero devolvía la cadena vacía y un puntito suspensivo, y la hoja enseñaba el texto propuesto
 * reducido a «…».
 */
const limpia = (t, n = 900) => {
	const s = String(t ?? '')
		.replace(/\s+/g, ' ')
		.trim();
	return n > 0 && s.length > n ? `${s.slice(0, n)}…` : s;
};

const leer = (ruta) => (existsSync(ruta) ? JSON.parse(readFileSync(ruta, 'utf-8')) : null);

/**
 * El veredicto que vale, que no siempre es el del verificador.
 *
 * Donde un humano ha comprobado la afirmacion contra la fuente, **manda el humano**: para eso se
 * hizo la muestra. Si dio la razon al verificador, no cambia nada; si discrepo, se invierte el
 * veredicto, porque una discrepancia solo puede ir en dos direcciones —una conforme que era un
 * defecto, o un defecto que no lo era—.
 *
 * Sin esto la hoja de correcciones se construiria sobre veredictos que ya sabemos falsos: se
 * genera de los dictamenes, y el dictamen de una afirmacion comprobada sigue diciendo lo que dijo
 * el agente.
 */
function veredictoEfectivo(d) {
	const h = d.comprobacion_humana;
	if (!h || h.coincide !== false) return d.veredicto;
	if (d.veredicto === 'conforme') return 'defecto';
	if (d.veredicto === 'defecto') return 'conforme';
	return d.veredicto;
}

/**
 * Lo que la lectura ciega contradice de la pasada A.
 *
 * Mientras la B estuvo incompleta, el reparto en cubos se hizo solo con A, y eso dejaba fuera de
 * la revisión el caso más interesante de todos: **la afirmación que A dio por conforme y B
 * desmiente**. Son dos y muy distintas entre sí:
 *
 * - B dice que el localizador no lleva al pasaje y A no anotó ningún «localizador falso». Es un
 *   arreglo sin juicio, así que basta con que baje a material.
 * - B dice que la fuente **no trata esa forma** cuando la afirmación del catálogo pretende ser una
 *   cita. O falla la lectura o falla la ficha, y en cualquiera de los dos casos hay que releer.
 */
function contradiceB(d) {
	if (!d.b) return [];
	const roces = [];
	const yaSabido = (d.defectos ?? []).some((f) => f.tipo === 'localizador falso');
	if (d.b.el_localizador_lleva_al_pasaje === false && !yaSabido) {
		roces.push({
			cubo: 'material',
			que: `la lectura ciega dice que el localizador no lleva al pasaje${
				d.b.donde_esta_de_verdad ? `, sino a: ${limpia(d.b.donde_esta_de_verdad, 220)}` : ''
			}`
		});
	}
	if (d.b.no_trata_esta_forma === true && String(d.naturaleza ?? '').toLowerCase() === 'cita') {
		roces.push({
			cubo: 'fondo',
			que: 'la lectura ciega dice que la fuente **no trata esta forma**, y la ficha la cita como si la tratara'
		});
	}
	return roces;
}

function cubo(d) {
	// **Una discrepancia humana nunca se archiva.** Invertir el veredicto y seguir el curso normal
	// enterraba hallazgos: al dar por conforme un defecto mal tipificado, la afirmacion caia en el
	// monton de las que no piden nada, y con ella lo que el humano habia escrito. Discrepar no
	// significa «lo contrario», significa «esto hay que releerlo».
	if (d.comprobacion_humana && d.comprobacion_humana.coincide === false) return 'fondo';

	const roces = contradiceB(d);
	if (roces.some((r) => r.cubo === 'fondo')) return 'fondo';

	const veredicto = veredictoEfectivo(d);
	if (veredicto === 'duda_filologica') return 'filologico';
	if (veredicto === 'no confirmado') return 'fondo';
	if (veredicto === 'defecto') {
		// Un defecto que solo ve un humano no trae la taxonomia rellena, y sin ella no se puede
		// decir que sea material: va a fondo, que es donde se relee.
		if (d.comprobacion_humana?.coincide === false && d.veredicto === 'conforme') return 'fondo';
		const tipos = (d.defectos ?? []).map((f) => f.tipo);
		return tipos.length && tipos.every((t) => MATERIALES.has(t)) ? 'material' : 'fondo';
	}
	if (roces.length) return 'material';

	const nota = String(d.observaciones ?? '').trim();
	if (nota.length <= 30) return 'limpio';
	return SEÑALES_DE_DUDA.test(nota) ? 'observacion' : 'confirmacion';
}

/** Una sola línea que diga qué hay que hacer con esta ficha. Es lo que se lee primero. */
function queDecidir(d, clave) {
	if (clave === 'filologico') return 'Lo decide el IP: no hay error, hay una convención sin fijar.';
	if (clave === 'fondo') return 'Releer la fuente y reescribir el resumen.';
	if (clave === 'observacion') return 'Mirar si el matiz señalado tiene que entrar en la ficha.';
	const tipos = new Set((d.defectos ?? []).map((f) => f.tipo));
	const roces = contradiceB(d).map((r) => r.que);
	// **«Anclaje equivocado» se ha usado en dos sentidos, y solo uno es el de la taxonomía.**
	// El plan lo define como colgar de la forma o la arquitectura que no es —un cambio de columna,
	// sin tocar prosa—. Pero los dieciocho dictámenes que lo llevan describen otra cosa: una
	// cláusula de la afirmación viene de un § o una página distintos de los que se citan. Eso es de
	// la familia del localizador, y arreglarlo obliga a partir el localizador o a recortar la
	// afirmación: **sí se toca el texto**. Mientras los dictámenes no se reetiqueten, la ficha dice
	// lo que hay que hacer de verdad en vez de repetir la etiqueta.
	if (tipos.has('anclaje equivocado'))
		return 'Parte de la afirmación viene de otro pasaje: partir el localizador o recortar el texto.';
	if (tipos.has('localizador falso') || roces.length)
		return 'Corregir el localizador. La prosa no se toca.';
	return 'Arreglo material: se corrige sin juicio de por medio.';
}

const TITULOS = {
	fondo: 'De fondo · la fuente dice otra cosa, o no se ha podido confirmar',
	material: 'Material · se corrige sin juicio de por medio',
	filologico: 'Filológico · no es un error, es una decisión sin tomar (IP)',
	observacion: 'Solo observación · conforme, pero con algo anotado'
};

const ORDEN = ['fondo', 'material', 'filologico', 'observacion'];

// ══════════════════════════════════════════════════════════════ Reunir las cuatro fuentes

/** Los dictámenes de la pasada A, deduplicados por afirmación. */
function leerPasadaA() {
	const todos = [];
	for (const fichero of readdirSync(DICTAMENES)
		.filter((f) => f.endsWith('.json'))
		.sort()) {
		let datos;
		try {
			datos = JSON.parse(readFileSync(join(DICTAMENES, fichero), 'utf-8'));
		} catch {
			console.error(`${fichero}: no se puede interpretar, se salta.`);
			continue;
		}
		for (const d of datos.dictamenes ?? []) {
			todos.push({ ...d, fuente: datos.fuente ?? fichero.slice(0, 4), fichero, lote: datos.lote });
		}
	}
	// Un mismo lote pudo escribirse dos veces —un intento que se cortó y su relanzamiento—, así
	// que se deduplica por afirmación.
	//
	// **Y el piloto no gana nunca.** Tres afirmaciones tienen dos dictámenes: el del piloto, que
	// corrió antes que nada con errores sembrados, y el del lote que las auditó después. Quedarse
	// con el último leído en orden alfabético daba el del piloto —`2014.json` va detrás de
	// `2014-1.json`—, que además juzgó un texto anterior: en dos de los tres casos el piloto decía
	// «defecto» y el lote «conforme», y la copla de arte mayor de Caparrós llevaba semanas en el
	// cubo de fondo por un endurecimiento que ya estaba corregido cuando pasó el verificador de
	// verdad.
	const porId = new Map();
	for (const d of todos) {
		const clave = `${d.fuente}·${d.id}`;
		const previo = porId.get(clave);
		const esDeLote = (x) => x.lote !== null && x.lote !== undefined;
		if (previo && esDeLote(previo) && !esDeLote(d)) continue;
		porId.set(clave, d);
	}
	return [...porId.values()];
}

/** Las lecturas ciegas, por identificador. */
function leerPasadaB() {
	const porId = new Map();
	if (!existsSync(DICTAMENES_B)) return porId;
	for (const f of readdirSync(DICTAMENES_B)
		.filter((x) => x.endsWith('.json'))
		.sort()) {
		let datos;
		try {
			datos = JSON.parse(readFileSync(join(DICTAMENES_B, f), 'utf-8'));
		} catch {
			continue;
		}
		for (const l of datos.lecturas ?? []) porId.set(l.id, l);
	}
	return porId;
}

function main() {
	if (!existsSync(DICTAMENES)) {
		console.error('No hay dictámenes todavía.');
		process.exit(1);
	}

	// Lo que el catálogo dice **hoy**. La hoja se genera muchas veces a lo largo de la ronda, y
	// entre una y otra se migran correcciones: el texto vigente tiene que salir de la base.
	const enLaBase = new Map(
		query(
			`select left(afirmacion_id::text, 8) id, resumen, localizador
			 from public.afirmaciones_fuentes_metricas;`
		).map((x) => [x.id, x])
	);

	const pasadaB = leerPasadaB();
	const cotejo = new Map((leer(COTEJO) ?? []).map((x) => [x.id, x.senales]));

	const mecanicas = leer(MECANICAS);
	const anclaje = new Map((mecanicas?.anclaje ?? []).map((x) => [x.id, x]));
	const huerfanos = new Map(
		(mecanicas?.esquemas ?? [])
			.filter((x) => x.sin_rastro)
			.map((x) => [x.id, x.huerfanos.filter((h) => h.donde === 'sin rastro').map((h) => h.esquema)])
	);
	const ajenas = new Map((mecanicas?.nombra_otra_fuente ?? []).map((x) => [x.id, x.citadas]));
	const tiradas = new Map();
	for (const t of mecanicas?.tiradas_compartidas ?? []) {
		for (const [uno, otro] of [
			[t.a, t.b],
			[t.b, t.a]
		]) {
			if (!tiradas.has(uno.id)) tiradas.set(uno.id, []);
			tiradas.get(uno.id).push({ con: otro, palabras: t.palabras, tirada: t.tirada });
		}
	}

	const humanas = existsSync(MUESTRA)
		? new Map(
				(JSON.parse(readFileSync(MUESTRA, 'utf-8')).muestra ?? [])
					.filter((m) => m.coincide_con_el_dictamen !== null)
					.map((m) => [
						`${m.fuente}·${m.id}`,
						{
							coincide: m.coincide_con_el_dictamen,
							hallazgo: m.hallazgo_humano,
							clasificacion: m.clasificacion
						}
					])
			)
		: new Map();

	const dictamenes = leerPasadaA().map((d) => ({
		...d,
		comprobacion_humana: humanas.get(`${d.fuente}·${d.id}`) ?? null,
		b: pasadaB.get(d.id) ?? null,
		cotejo: cotejo.get(d.id) ?? null
	}));

	const decisionesPrevias = existsSync(DECISIONES)
		? new Map(JSON.parse(readFileSync(DECISIONES, 'utf-8')).map((d) => [`${d.fuente}·${d.id}`, d]))
		: new Map();

	/**
	 * Lo que se propone escribir en su lugar, si ya está redactado.
	 *
	 * Aprobar un cambio es leer el texto viejo y el nuevo enfrentados, no reconstruir el cambio a
	 * partir de un veredicto. Mientras una propuesta no esté redactada, la ficha lo dice en vez de
	 * callarlo: **una corrección sin texto propuesto no está lista para migrar**.
	 */
	const propuestas = existsSync(PROPUESTAS)
		? new Map(Object.entries(JSON.parse(readFileSync(PROPUESTAS, 'utf-8'))))
		: new Map();

	const cubos = {
		fondo: [],
		material: [],
		filologico: [],
		observacion: [],
		confirmacion: [],
		limpio: []
	};
	for (const d of dictamenes) cubos[cubo(d)].push(d);

	// Un número correlativo por ficha, para que el índice y la entrada se encuentren sin depender
	// de cómo cada visor construya los anclajes de los títulos.
	let n = 0;
	for (const clave of ORDEN) for (const d of cubos[clave]) d.numero = n += 1;

	// ---------------------------------------------------------------- La hoja
	const hoy = new Date().toISOString().slice(0, 10);
	const md = [];
	const pendientes = ORDEN.reduce((t, c) => t + cubos[c].length, 0);

	md.push('# Hoja de correcciones de «Lo que dicen las fuentes»');
	md.push('');
	md.push(`Generada el ${hoy} con \`npm run correcciones:hoja\`. **No se edita a mano** y **no`);
	md.push('cambia nada en la base**: propone, y cada cambio lo aprueba David antes de migrarse.');
	md.push('');
	md.push(
		`De **${dictamenes.length}** afirmaciones, **${pendientes}** piden mirada y`,
		`**${cubos.confirmacion.length + cubos.limpio.length}** salieron conformes sin ninguna divergencia señalada. Estas no se revisan:`,
		'si nada apunta a que estén mal, no hay por dónde empezar a dudar.'
	);
	md.push('');
	md.push('**Cada ficha se basta a sí misma.** Trae, siempre en este orden: qué hay que decidir,');
	md.push('qué señaló cada pasada, lo que dice la fuente leída de las dos maneras, lo que el');
	md.push('catálogo dice hoy y lo que se propone decir. No hace falta abrir nada más.');
	md.push('');

	// ---- Índice
	md.push('## Índice');
	md.push('');
	for (const clave of ORDEN) {
		if (!cubos[clave].length) continue;
		md.push(`**${TITULOS[clave]} — ${cubos[clave].length}**`);
		md.push('');
		for (const d of cubos[clave]) {
			const previa = decisionesPrevias.get(`${d.fuente}·${d.id}`);
			const hecho = previa?.estado && previa.estado !== 'pendiente';
			md.push(
				`- ${hecho ? '~~' : ''}**${d.numero}** · ${d.sobre} · ${d.fuente}${hecho ? '~~' : ''}` +
					`${hecho ? ` — ya ${previa.estado}` : ` — ${queDecidir(d, clave)}`}`
			);
		}
		md.push('');
	}

	for (const clave of ORDEN) {
		const lista = cubos[clave];
		md.push(`## ${TITULOS[clave]} — ${lista.length}`);
		md.push('');
		if (!lista.length) {
			md.push('Nada en este cubo.');
			md.push('');
			continue;
		}
		for (const d of lista) {
			const previa = decisionesPrevias.get(`${d.fuente}·${d.id}`);
			md.push(`### ${d.numero} · ${d.sobre} · ${d.fuente}`);
			md.push('');
			md.push(`\`${d.id}\``);
			md.push('');
			if (previa?.estado && previa.estado !== 'pendiente') {
				md.push(`> ✔ **Ya ${previa.estado}.**${previa.nota ? ` ${previa.nota}` : ''}`);
				md.push('');
			}
			md.push(`**Qué hay que decidir:** ${queDecidir(d, clave)}`);
			md.push('');

			// ---- Qué señaló cada quien
			md.push('**Quién señala qué**');
			md.push('');
			md.push(
				`- *Pasada A* — **${veredictoEfectivo(d)}**` +
					(veredictoEfectivo(d) !== d.veredicto ? ` (el verificador dijo «${d.veredicto}»)` : '')
			);
			for (const f of d.defectos ?? []) {
				md.push(`   - **${f.tipo}** (${f.gravedad}). ${limpia(f.explicacion, 500)}`);
				if (f.cita_literal) md.push(`      - En la fuente: «${limpia(f.cita_literal, 300)}»`);
			}
			if (d.observaciones && String(d.observaciones).trim().length > 30) {
				md.push(`   - *Observó:* ${limpia(d.observaciones, 500)}`);
			}

			if (!d.b) {
				md.push('- *Lectura ciega* — **no la hay.** Esta ficha tiene un solo par de ojos.');
			} else {
				const roces = contradiceB(d);
				md.push(
					`- *Lectura ciega* — localizador ${
						d.b.el_localizador_lleva_al_pasaje === false ? '**no lleva al pasaje**' : 'correcto'
					}${d.b.no_trata_esta_forma === true ? ' · **dice que la fuente no trata esta forma**' : ''}`
				);
				if (d.b.donde_esta_de_verdad) {
					md.push(`   - Está en: ${limpia(d.b.donde_esta_de_verdad, 300)}`);
				}
				for (const r of roces) md.push(`   - **Contradice a la pasada A:** ${r.que}`);
			}

			const s = d.cotejo;
			if (s?.matices?.length) {
				md.push(
					`- *Cotejo* — matices que la fuente tiene y el catálogo no: ${s.matices.join(', ')}`
				);
			}
			if (s?.esquemas?.length) {
				md.push(
					`- *Cotejo* — esquemas que la fuente da y la ficha no registra: \`${s.esquemas.join('`, `')}\``
				);
			}
			if (anclaje.has(d.id)) {
				const a = anclaje.get(d.id);
				md.push(
					`- *Anclaje* — ${a.nombra ? `nombra solo la arquitectura «${a.nombra}»` : ''}` +
						`${a.nombra && a.hermanas_ancladas.length ? '; ' : ''}` +
						`${a.hermanas_ancladas.length ? `hermanas de la misma fuente sí ancladas: ${a.hermanas_ancladas.join(', ')}` : ''}`
				);
			}
			if (huerfanos.has(d.id)) {
				md.push(
					`- *Esquemas huérfanos* — sin rastro en ninguna parte del catálogo: \`${huerfanos.get(d.id).join('`, `')}\``
				);
			}
			if (ajenas.has(d.id)) {
				md.push(
					`- *Vocabulario* — la ficha nombra otra fuente: ${ajenas
						.get(d.id)
						.map((c) => `**${c.marca}** (${c.anio}${c.mismo_autor ? ', mismo autor' : ''})`)
						.join(', ')}`
				);
			}
			for (const t of tiradas.get(d.id) ?? []) {
				md.push(
					`- *Vocabulario* — comparte **${t.palabras} palabras seguidas** con \`${t.con.id}\` (${t.con.anio} ${t.con.forma})` +
						`<br>      «…${t.tirada}…»`
				);
			}
			if (d.comprobacion_humana) {
				const h = d.comprobacion_humana;
				md.push(
					`- *Comprobado a mano* — ${h.coincide ? 'confirma' : '**NO confirma**'} el dictamen.` +
						`${h.clasificacion ? ` Clasificado: ${h.clasificacion}.` : ''}`
				);
				md.push(`   - ${limpia(h.hallazgo, 900)}`);
			}
			md.push('');

			// ---- Las dos lecturas de la fuente
			md.push(`**Dice la fuente** *(transcripción de la pasada A)*`);
			md.push('');
			md.push(limpia(d.texto_original));
			md.push('');
			if (d.b?.lo_que_dice_la_fuente) {
				md.push('**Dice la fuente** *(lectura ciega, sin ver el catálogo)*');
				md.push('');
				md.push(limpia(d.b.lo_que_dice_la_fuente, 1400));
				md.push('');
			}

			// ---- Antes y después
			// **El texto actual se lee de la base, no del dictamen.** El `texto_registrado` del
			// dictamen es el que tenía la afirmación el día que la juzgó la pasada A, y quedó
			// congelado ahí: para todo lo ya corregido, enseñarlo como «actual» es enseñar el texto
			// viejo a quien está aprobando el nuevo. Cuando los dos difieren se muestran los dos,
			// cada uno con su nombre, porque el de A es el que explica los defectos que se citan
			// más arriba.
			// **Estos tres bloques no se recortan nunca.** `limpia` corta por defecto a 900
			// caracteres, y aquí eso significaba enseñar el texto propuesto con puntos suspensivos
			// al final: nadie puede aprobar lo que no ve entero. Se recorta la prosa de los
			// verificadores, que es larga y de la que basta el principio; no lo que se decide.
			const vigente = enLaBase.get(d.id);
			const actual = limpia(vigente?.resumen ?? d.texto_registrado, 0);
			const deA = limpia(d.texto_registrado, 0);
			md.push('**Texto actual del catálogo**');
			md.push('');
			md.push(actual);
			md.push('');
			if (vigente && actual !== deA) {
				// Difieren por dos motivos muy distintos y conviene no confundirlos. Si la
				// afirmación ya se corrigió, el de la pasada A es el texto viejo y hay que verlo,
				// porque es el que explican los defectos de arriba. Si no se ha tocado, lo que
				// pasa es que **el verificador retecleó nuestro texto en vez de copiarlo**: son
				// nueve casos de los 199 sin corregir, todos de menos de doce caracteres de
				// diferencia, y enseñar dos textos casi idénticos no ayuda a nadie.
				const yaCorregida = previa?.estado && previa.estado !== 'pendiente';
				if (yaCorregida) {
					md.push('*Texto que juzgó la pasada A, ya sustituido:*');
					md.push('');
					md.push(deA);
				} else {
					md.push(
						'> La pasada A trabajó sobre una copia de este texto con alguna variante menor de',
						'> transcripción. Lo que se juzga es el de arriba.'
					);
				}
				md.push('');
			}
			const propuesta = propuestas.get(d.id);
			md.push('**Texto propuesto**');
			md.push('');
			md.push(
				propuesta?.resumen
					? limpia(propuesta.resumen, 0)
					: previa?.estado && previa.estado !== 'pendiente'
						? '*(ya aplicado: el texto actual de arriba es el corregido)*'
						: '*(por redactar — sin esto no se migra)*'
			);
			md.push('');
			md.push(
				`**Localizador:** \`${vigente?.localizador ?? d.localizador_declarado ?? '—'}\`` +
					(propuesta?.localizador ? ` → \`${propuesta.localizador}\`` : '')
			);
			if (d.por_que_ahi) {
				md.push('');
				md.push(`*Dónde se comprobó:* ${limpia(d.por_que_ahi, 300)}`);
			}
			md.push('');
			md.push('---');
			md.push('');
		}
	}

	md.push(`## Conformes, con la comprobación anotada — ${cubos.confirmacion.length}`);
	md.push('');
	md.push(
		'Se dejó constancia de qué se cotejó, pero no hay ninguna divergencia señalada. **No piden',
		'decisión.** Se resumen en una línea por si quieres tirar del hilo de alguna.'
	);
	md.push('');
	for (const d of cubos.confirmacion) {
		md.push(`- **${d.sobre}** · ${d.fuente} — ${limpia(d.observaciones, 160)}`);
	}
	md.push('');

	md.push(`## Conformes sin nada anotado — ${cubos.limpio.length}`);
	md.push('');
	md.push('No piden revisión. Se listan solo para que conste cuáles son.');
	md.push('');
	for (const d of cubos.limpio) md.push(`- ${d.sobre} · ${d.fuente}`);
	md.push('');

	writeFileSync(HOJA, `${md.join('\n')}\n`, 'utf-8');

	// ---------------------------------------------------- El registro de decisiones
	//
	// Sin una línea de las fuentes: solo identificadores, veredicto, señales y en qué estado está
	// la decisión. Por eso este sí entra en el repositorio, y es el rastro de qué aprobó un humano.
	const registro = dictamenes
		.map((d) => {
			const clave = `${d.fuente}·${d.id}`;
			const previa = decisionesPrevias.get(clave);
			const c = cubo(d);
			return {
				id: d.id,
				fuente: d.fuente,
				sobre: d.sobre,
				veredicto: d.veredicto,
				veredicto_efectivo: veredictoEfectivo(d),
				comprobado_a_mano: d.comprobacion_humana ? d.comprobacion_humana.coincide : null,
				lectura_ciega: Boolean(d.b),
				contradice_b: contradiceB(d).map((r) => r.cubo),
				senales: {
					matices: d.cotejo?.matices?.length ?? 0,
					esquemas_sin_registrar: d.cotejo?.esquemas?.length ?? 0,
					esquemas_sin_rastro: huerfanos.get(d.id)?.length ?? 0,
					anclaje: anclaje.has(d.id),
					nombra_otra_fuente: ajenas.has(d.id),
					tiradas_compartidas: (tiradas.get(d.id) ?? []).length
				},
				cubo: c,
				defectos: (d.defectos ?? []).map((f) => `${f.tipo} (${f.gravedad})`),
				estado: previa?.estado ?? (c === 'limpio' ? 'no requiere revisión' : 'pendiente'),
				nota: previa?.nota ?? ''
			};
		})
		.sort((a, b) => a.fuente.localeCompare(b.fuente) || a.sobre.localeCompare(b.sobre));

	writeFileSync(DECISIONES, `${JSON.stringify(registro, null, '\t')}\n`, 'utf-8');

	const sinLectura = dictamenes.filter((d) => !d.b).length;
	const movidas = dictamenes.filter((d) => contradiceB(d).length).length;

	console.log(`${dictamenes.length} afirmaciones`);
	for (const clave of [...ORDEN, 'confirmacion', 'limpio']) {
		console.log(`  ${String(cubos[clave].length).padStart(3)}  ${clave}`);
	}
	console.log(`\n${movidas} afirmaciones donde la lectura ciega contradice a la pasada A`);
	if (sinLectura) console.log(`${sinLectura} sin lectura ciega`);
	console.log(`\nHoja en ${HOJA}`);
	console.log(`Registro de decisiones en ${DECISIONES}`);
}

main();

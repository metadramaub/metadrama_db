/**
 * La hoja de correcciones: qué habría que tocar en «Lo que dicen las fuentes», y por qué.
 *
 * Se lee de los dictámenes ya emitidos y **no cambia nada**: propone. Ninguna corrección del
 * catálogo se aplica sin que David la haya visto y aprobado, y las que son cuestión filológica
 * no las decide él sino el IP.
 *
 * Reparte cada afirmación según lo que pide de quien la lea, que no es lo mismo en todas:
 *
 * - **De fondo.** La fuente dice algo distinto o más matizado de lo que el catálogo le atribuye,
 *   o no se ha podido confirmar. Hay que releer y reescribir.
 * - **Material.** Un dato que está mal y cuya corrección no exige juicio: una comilla que no es
 *   textual, un § que no es el que contiene el pasaje, un localizador que nadie puede seguir.
 * - **Filológico.** No hay error: hay una decisión que el proyecto no ha tomado. Va al IP.
 * - **Solo observación.** Conforme, pero el verificador señaló que el catálogo se aparta del
 *   original sin mentir —omite un matiz, invierte el orden, cierra una lista abierta—. **Aquí va
 *   lo que hay que mirar «a la mínima duda».**
 * - **Conforme con la comprobación anotada.** El verificador dejó constancia de qué cotejó y no
 *   señala ninguna divergencia. Se lista en una línea, no pide decisión.
 * - **Conforme y sin nada anotado.** No se revisa: si nada apunta a que esté mal, no hay por dónde
 *   empezar a dudar. Se cuenta, para que se vea cuánto es.
 *
 * La hoja lleva transcripciones de las seis monografías, así que **no entra en el repositorio**.
 * Lo que sí se guarda es `decisiones.json`, que solo tiene identificadores y veredictos.
 *
 * Uso:
 *   node scripts/hoja-correcciones.mjs
 */

import { readFileSync, readdirSync, writeFileSync, existsSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');
const DICTAMENES = join(BASE, 'dictamenes');
const HOJA = join(BASE, 'correcciones.md');
const DECISIONES = join(BASE, 'decisiones.json');
const MUESTRA = join(BASE, 'muestra-humana.json');

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

function cubo(d) {
	// **Una discrepancia humana nunca se archiva.** Invertir el veredicto y seguir el curso normal
	// enterraba hallazgos: al dar por conforme un defecto mal tipificado, la afirmacion caia en el
	// monton de las que no piden nada, y con ella lo que el humano habia escrito. Discrepar no
	// significa «lo contrario», significa «esto hay que releerlo».
	if (d.comprobacion_humana && d.comprobacion_humana.coincide === false) return 'fondo';
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
	const nota = String(d.observaciones ?? '').trim();
	if (nota.length <= 30) return 'limpio';
	return SEÑALES_DE_DUDA.test(nota) ? 'observacion' : 'confirmacion';
}

const TITULOS = {
	fondo: 'De fondo · la fuente dice otra cosa, o no se ha podido confirmar',
	material: 'Material · se corrige sin juicio de por medio',
	filologico: 'Filológico · no es un error, es una decisión sin tomar (IP)',
	observacion: 'Solo observación · conforme, pero con algo anotado'
};

const ORDEN = ['fondo', 'material', 'filologico', 'observacion'];

const limpia = (t, n = 900) => {
	const s = String(t ?? '')
		.replace(/\s+/g, ' ')
		.trim();
	return s.length > n ? `${s.slice(0, n)}…` : s;
};

function main() {
	if (!existsSync(DICTAMENES)) {
		console.error('No hay dictámenes todavía.');
		process.exit(1);
	}

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
			todos.push({ ...d, fuente: datos.fuente ?? fichero.slice(0, 4), fichero });
		}
	}

	// Un mismo lote pudo escribirse dos veces —un intento que se cortó y su relanzamiento—, así
	// que se deduplica por afirmación quedándose con el último dictamen leído.
	const porId = new Map();
	for (const d of todos) porId.set(`${d.fuente}·${d.id}`, d);
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
	const dictamenes = [...porId.values()].map((d) => ({
		...d,
		comprobacion_humana: humanas.get(`${d.fuente}·${d.id}`) ?? null
	}));

	const decisionesPrevias = existsSync(DECISIONES)
		? new Map(JSON.parse(readFileSync(DECISIONES, 'utf-8')).map((d) => [`${d.fuente}·${d.id}`, d]))
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

	// ---------------------------------------------------------------- La hoja
	const hoy = new Date().toISOString().slice(0, 10);
	const md = [];
	md.push('# Hoja de correcciones de «Lo que dicen las fuentes»');
	md.push('');
	md.push(`Generada el ${hoy} con \`npm run correcciones:hoja\`. **No se edita a mano** y **no`);
	md.push('cambia nada en la base**: propone, y cada cambio lo aprueba David antes de migrarse.');
	md.push('');
	md.push(
		`De **${dictamenes.length}** afirmaciones dictaminadas, **${ORDEN.reduce((n, c) => n + cubos[c].length, 0)}** piden`,
		`mirada y **${cubos.confirmacion.length + cubos.limpio.length}** salieron conformes sin ninguna divergencia señalada. Estas no se revisan:`,
		'si nada apunta a que estén mal, no hay por dónde empezar a dudar.'
	);
	md.push('');

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
			md.push(`### ${d.sobre} · ${d.fuente}`);
			md.push('');
			md.push(`\`${d.id}\` · localizador declarado: **${d.localizador_declarado ?? '—'}**`);
			if (previa?.estado && previa.estado !== 'pendiente') {
				md.push(`> Ya decidido: **${previa.estado}**${previa.nota ? ` — ${previa.nota}` : ''}`);
			}
			md.push('');
			if (d.comprobacion_humana) {
				const h = d.comprobacion_humana;
				md.push(
					`> **Comprobado a mano.** ${h.coincide ? 'Confirma' : 'NO confirma'} el dictamen, que decia` +
						` «${d.veredicto}». ${h.clasificacion ? `Clasificado como: ${h.clasificacion}.` : ''}`
				);
				md.push('>');
				md.push(`> ${limpia(h.hallazgo, 900)}`);
				md.push('');
			}
			for (const f of d.defectos ?? []) {
				md.push(`- **${f.tipo}** (${f.gravedad}). ${limpia(f.explicacion, 500)}`);
				if (f.cita_literal) md.push(`  - En la fuente: «${limpia(f.cita_literal, 300)}»`);
			}
			if (d.observaciones && String(d.observaciones).trim().length > 30) {
				md.push(`- *Observación del verificador:* ${limpia(d.observaciones, 500)}`);
			}
			md.push('');
			md.push(`**Dice la fuente:** ${limpia(d.texto_original)}`);
			md.push('');
			md.push(`**Registra el catálogo:** ${limpia(d.texto_registrado)}`);
			if (d.por_que_ahi) {
				md.push('');
				md.push(`*Dónde se comprobó:* ${limpia(d.por_que_ahi, 300)}`);
			}
			md.push('');
		}
	}

	md.push(`## Conformes, con la comprobación anotada — ${cubos.confirmacion.length}`);
	md.push('');
	md.push(
		'El verificador dejó constancia de qué cotejó, pero no señala ninguna divergencia. **No piden',
		'decisión.** Se resumen en una línea por si quieres tirar del hilo de alguna; el dictamen',
		'entero está en `dictamenes/`.'
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
	// Sin una línea de las fuentes: solo identificadores, veredicto y en qué estado está la
	// decisión. Por eso este sí entra en el repositorio, y es el rastro de qué aprobó un humano.
	const registro = dictamenes
		.map((d) => {
			const clave = `${d.fuente}·${d.id}`;
			const previa = decisionesPrevias.get(clave);
			return {
				id: d.id,
				fuente: d.fuente,
				sobre: d.sobre,
				veredicto: d.veredicto,
				veredicto_efectivo: veredictoEfectivo(d),
				comprobado_a_mano: d.comprobacion_humana ? d.comprobacion_humana.coincide : null,
				cubo: cubo(d),
				defectos: (d.defectos ?? []).map((f) => `${f.tipo} (${f.gravedad})`),
				estado: previa?.estado ?? (cubo(d) === 'limpio' ? 'no requiere revisión' : 'pendiente'),
				nota: previa?.nota ?? ''
			};
		})
		.sort((a, b) => a.fuente.localeCompare(b.fuente) || a.sobre.localeCompare(b.sobre));

	writeFileSync(DECISIONES, `${JSON.stringify(registro, null, '\t')}\n`, 'utf-8');

	console.log(`${dictamenes.length} afirmaciones dictaminadas`);
	for (const clave of [...ORDEN, 'confirmacion', 'limpio']) {
		console.log(`  ${String(cubos[clave].length).padStart(3)}  ${clave}`);
	}
	console.log(`\nHoja en ${HOJA}`);
	console.log(`Registro de decisiones en ${DECISIONES}`);
}

main();

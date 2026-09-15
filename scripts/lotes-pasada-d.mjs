/**
 * Reparte en lotes las afirmaciones que ninguna comprobación mecánica alcanza, para la pasada D.
 *
 * La pasada D es **descomposición en cláusulas**: no emite veredicto, parte el resumen en sus
 * aserciones y exige para cada una un fragmento literal del pasaje, o la etiqueta de que no está.
 * Las tres preguntas por cláusula —¿está el dato?, ¿con la misma fuerza?, ¿con la misma extensión?—
 * son las tres familias de defecto que esta auditoría ha encontrado de verdad.
 *
 * **A quién se lanza.** No a las 267, sino al hueco que la máquina no puede mirar: las afirmaciones
 * que **no comparten con su pasaje ninguna tirada de seis palabras seguidas**, porque parafrasean en
 * vez de reutilizar el léxico de la fuente. De ese conjunto se descartan dos clases que lo son por
 * accidente y no por paráfrasis:
 *
 * - **Resúmenes muy cortos.** Con menos de veinticinco palabras, una tirada de seis no sale ni
 *   escribiendo fiel: la ausencia no dice nada.
 * - **Pasajes que el nivel 1 no resolvió.** Sin extracto no hay contra qué comparar, y el defecto
 *   está en el localizador, no en la ficha.
 *
 * Queda el núcleo: resumen largo, ventana amplia y aun así cero coincidencia.
 *
 * **El lote no lleva el pasaje.** Lleva el resumen, el localizador ya confirmado por la pasada C y
 * las denominaciones que el catálogo reconoce. El pasaje lo abre el verificador, porque la regla que
 * justifica esta pasada —seguir leyendo hasta el final del epígrafe— no se puede cumplir sobre un
 * extracto recortado.
 *
 * Uso:
 *   node scripts/lotes-pasada-d.mjs               # dice qué saldría, sin escribir
 *   node scripts/lotes-pasada-d.mjs --escribe
 */

import { existsSync, mkdirSync, readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');
const LOTES_D = join(BASE, 'lotes-d');
const DICTAMENES_D = join(BASE, 'dictamenes-d');
const ANIOS = [1968, 1969, 1972, 2014, 2016, 2020];

/** Seis por lote: la descomposición es más lenta que localizar, y el epígrafe hay que leerlo entero. */
const POR_LOTE = 6;
const TIRADA = 6;
const MINIMO_RESUMEN = 25;

const escribe = process.argv.includes('--escribe');

const palabras = (t) =>
	String(t ?? '')
		.normalize('NFD')
		.replace(/[̀-ͯ]/g, '')
		.toLowerCase()
		.replace(/[^a-z0-9]+/g, ' ')
		.trim()
		.split(' ')
		.filter(Boolean);

/** Si el resumen y el pasaje comparten alguna tirada de seis palabras, la máquina ya la alcanza. */
function seTocan(resumen, pasaje) {
	const R = palabras(resumen);
	const del = new Set();
	for (let i = 0; i + TIRADA <= R.length; i += 1) del.add(R.slice(i, i + TIRADA).join(' '));
	if (!del.size) return false;
	const P = palabras(pasaje);
	for (let i = 0; i + TIRADA <= P.length; i += 1) if (del.has(P.slice(i, i + TIRADA).join(' '))) return true;
	return false;
}

// ─────────────────────────────────────────────────────────── Lo que dice la base

const fichas = new Map(
	query(
		`select left(a.afirmacion_id::text, 8) as id, f.anio, a.localizador, a.resumen,
			coalesce(fm.nombre, fm2.nombre, fm3.nombre) as forma,
			coalesce(fm.forma_id, fm2.forma_id, fm3.forma_id) as forma_id
		from public.afirmaciones_fuentes_metricas a
		join public.fuentes_metricas f using (fuente_id)
		left join public.formas_metricas fm on fm.forma_id = a.forma_id
		left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
		left join public.formas_metricas fm2 on fm2.forma_id = ar.forma_id
		left join public.esquemas_rima e on e.esquema_rima_id = a.esquema_rima_id
		left join public.arquitecturas_forma ar2 on ar2.arquitectura_id = e.arquitectura_id
		left join public.formas_metricas fm3 on fm3.forma_id = ar2.forma_id`
	).map((r) => [r.id, r])
);

/** Las denominaciones que el catálogo reconoce, para que un silencio se busque por todos sus nombres. */
const denominaciones = new Map();
for (const d of query(
	`select forma_id, nombre from public.denominaciones_metricas where forma_id is not null`
)) {
	if (!denominaciones.has(d.forma_id)) denominaciones.set(d.forma_id, []);
	denominaciones.get(d.forma_id).push(d.nombre);
}

// ─────────────────────────────────────────────────────────── Quién entra

const yaRepartidas = new Set();
for (const carpeta of [LOTES_D, DICTAMENES_D]) {
	if (!existsSync(carpeta)) continue;
	for (const fichero of readdirSync(carpeta).filter((f) => f.endsWith('.json'))) {
		const d = JSON.parse(readFileSync(join(carpeta, fichero), 'utf-8'));
		for (const x of d.afirmaciones ?? d.lecturas ?? []) yaRepartidas.add(x.id);
	}
}

const nucleo = [];
const descartadas = { corta: 0, sinPasaje: 0, alcanzada: 0, yaRepartida: 0 };
for (const anio of ANIOS) {
	const ruta = join(BASE, 'extractos', `${anio}.json`);
	if (!existsSync(ruta)) {
		console.error(`  falta el extracto de ${anio}; se genera con npm run audit:fuentes`);
		continue;
	}
	for (const a of JSON.parse(readFileSync(ruta, 'utf-8')).afirmaciones ?? []) {
		const id = String(a.afirmacion_id).slice(0, 8);
		const ficha = fichas.get(id);
		if (!ficha) continue;
		const pasaje = a.extracto?.texto ?? '';
		if (seTocan(ficha.resumen, pasaje)) {
			descartadas.alcanzada += 1;
			continue;
		}
		if (!pasaje.trim()) {
			descartadas.sinPasaje += 1;
			continue;
		}
		if (palabras(ficha.resumen).length < MINIMO_RESUMEN) {
			descartadas.corta += 1;
			continue;
		}
		if (yaRepartidas.has(id)) {
			descartadas.yaRepartida += 1;
			continue;
		}
		nucleo.push({
			id,
			sobre: ficha.forma ?? a.sobre,
			localizador: ficha.localizador,
			texto_registrado: ficha.resumen,
			denominaciones: denominaciones.get(ficha.forma_id) ?? [],
			anio
		});
	}
}

// ─────────────────────────────────────────────────────────── El reparto

nucleo.sort((x, y) => x.anio - y.anio || x.sobre.localeCompare(y.sobre));

const porAnio = new Map();
for (const x of nucleo) {
	if (!porAnio.has(x.anio)) porAnio.set(x.anio, []);
	porAnio.get(x.anio).push(x);
}

if (escribe) {
	mkdirSync(LOTES_D, { recursive: true });
	mkdirSync(DICTAMENES_D, { recursive: true });
}

let lotes = 0;
for (const [anio, suyas] of [...porAnio].sort((a, b) => a[0] - b[0])) {
	const cuantos = Math.ceil(suyas.length / POR_LOTE);
	for (let i = 0; i < cuantos; i += 1) {
		const trozo = suyas.slice(i * POR_LOTE, (i + 1) * POR_LOTE);
		const nombre = `${anio}-${i + 1}.json`;
		lotes += 1;
		console.log(`${nombre}   ${trozo.length}`);
		for (const x of trozo) console.log(`     ${x.id} ${x.sobre}`);
		if (!escribe) continue;
		writeFileSync(
			join(LOTES_D, nombre),
			JSON.stringify(
				{
					fuente: fichas.get(trozo[0].id).anio,
					anio,
					lote: i + 1,
					de: cuantos,
					afirmaciones: trozo.map(({ anio: _, ...resto }) => resto)
				},
				null,
				1
			),
			'utf-8'
		);
	}
}

console.log(
	`\n${nucleo.length} afirmaciones en ${lotes} lotes.` +
		`\nFuera: ${descartadas.alcanzada} que la máquina ya alcanza, ${descartadas.corta} de resumen corto,` +
		` ${descartadas.sinPasaje} sin pasaje resuelto, ${descartadas.yaRepartida} ya repartidas.`
);
if (!escribe) console.log('\nNada escrito. Repite con `--escribe`.');

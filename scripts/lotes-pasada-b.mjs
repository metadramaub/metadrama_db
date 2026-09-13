/**
 * Reparte en lotes las afirmaciones que todavía no tienen lectura ciega.
 *
 * La pasada B se despachó en lotes a mano, y **los lotes nunca cubrieron las 267**: se armaron
 * sobre la marcha, tres sesiones se cortaron por el tope de cinco horas y las afirmaciones que
 * iban en los agentes muertos no volvieron a repartirse. Quedaron 43 sin leer a ciegas, y como
 * `estado:fuentes` medía la pasada B contra los lotes de B —no contra el catálogo— el hueco no
 * salía por ninguna parte.
 *
 * Esto lo cierra por el otro lado: **el censo son las afirmaciones de la base**, y un lote es lo
 * que falta por leer. Se puede ejecutar cuantas veces haga falta; solo escribe los lotes que no
 * existen todavía.
 *
 * Uso:
 *   node scripts/lotes-pasada-b.mjs           # dice qué falta, sin escribir
 *   node scripts/lotes-pasada-b.mjs --escribe # escribe los lotes que falten
 */

import { readFileSync, readdirSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');
const B = join(BASE, 'dictamenes-b');
const LOTES_B = join(BASE, 'lotes-b');

/** Diez por lote, como los que ya se despacharon: un lote de otro tamaño no es comparable. */
const POR_LOTE = 10;

const escribe = process.argv.includes('--escribe');

/**
 * Los identificadores que ya tienen lectura ciega, leídos de los dictámenes y no de los lotes.
 *
 * Una lectura vale si trae transcripción literal, **o** si declara que la fuente no trata esa
 * forma: entonces no hay pasaje que transcribir y lo que se guarda es qué se buscó y dónde. Ocho
 * de las lecturas hechas son de esas, y contarlas como huecos mandaría a releer un silencio.
 */
function yaLeidas() {
	const vistos = new Set();
	if (!existsSync(B)) return vistos;
	for (const f of readdirSync(B).filter((x) => x.endsWith('.json'))) {
		const d = JSON.parse(readFileSync(join(B, f), 'utf-8'));
		for (const l of d.lecturas ?? []) {
			if (String(l.texto_original ?? '').trim() || l.no_trata_esta_forma === true) vistos.add(l.id);
		}
	}
	return vistos;
}

/** El número más alto de lote que ya existe para una fuente, para seguir contando desde ahí. */
function ultimoLote(anio) {
	if (!existsSync(LOTES_B)) return 0;
	return readdirSync(LOTES_B)
		.map((f) => f.match(new RegExp(`^${anio}-(\\d+)\\.json$`)))
		.filter(Boolean)
		.reduce((n, m) => Math.max(n, Number(m[1])), 0);
}

function main() {
	const afirmaciones = query(`
		select left(a.afirmacion_id::text, 8) id, f.anio,
			coalesce(fo.nombre, foa.nombre || ' · ' || ar.nombre, foe.nombre) sobre,
			a.localizador,
			coalesce(
				(
					select array_agg(distinct d.nombre order by d.nombre)
					from public.denominaciones_metricas d
					where d.forma_id = coalesce(a.forma_id, ar.forma_id, are.forma_id)
				),
				'{}'
			) denominaciones
		from public.afirmaciones_fuentes_metricas a
		join public.fuentes_metricas f using (fuente_id)
		left join public.formas_metricas fo on fo.forma_id = a.forma_id
		left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
		left join public.formas_metricas foa on foa.forma_id = ar.forma_id
		left join public.esquemas_rima er on er.esquema_rima_id = a.esquema_rima_id
		left join public.arquitecturas_forma are on are.arquitectura_id = er.arquitectura_id
		left join public.formas_metricas foe on foe.forma_id = are.forma_id
		order by f.anio, 3;
	`);

	const vistos = yaLeidas();
	const faltan = afirmaciones.filter((a) => !vistos.has(a.id));

	console.log(`${afirmaciones.length} afirmaciones · ${vistos.size} con lectura ciega`);
	if (!faltan.length) {
		console.log('No falta ninguna por leer a ciegas.');
		return;
	}
	console.log(`Faltan ${faltan.length}.\n`);

	const porAnio = new Map();
	for (const a of faltan) {
		if (!porAnio.has(a.anio)) porAnio.set(a.anio, []);
		porAnio.get(a.anio).push(a);
	}

	if (escribe) mkdirSync(LOTES_B, { recursive: true });

	for (const [anio, lista] of [...porAnio].sort((x, y) => x[0] - y[0])) {
		let n = ultimoLote(anio);
		for (let i = 0; i < lista.length; i += POR_LOTE) {
			n += 1;
			const trozo = lista.slice(i, i + POR_LOTE);
			const nombre = `${anio}-${n}.json`;
			const contenido = {
				anio,
				lote: n,
				afirmaciones: trozo.map((a) => ({
					id: a.id,
					sobre: a.sobre,
					localizador_declarado: a.localizador,
					denominaciones_del_catalogo: a.denominaciones ?? []
				}))
			};
			console.log(
				`${nombre}  ${String(trozo.length).padStart(2)}  ${trozo.map((a) => a.sobre).join(', ')}`
			);
			if (escribe) {
				if (existsSync(join(LOTES_B, nombre))) {
					console.log(`   ya existía, no se toca`);
					continue;
				}
				writeFileSync(join(LOTES_B, nombre), `${JSON.stringify(contenido, null, '\t')}\n`, 'utf-8');
			}
		}
	}

	if (!escribe) console.log('\nNada escrito. Repite con `--escribe` para crear los lotes.');
	else
		console.log(
			'\nLos lotes se despachan con el texto exacto de',
			'`docs/dominio-metrico/auditoria-fuentes/instrucciones-verificador-b.md`.'
		);
}

main();

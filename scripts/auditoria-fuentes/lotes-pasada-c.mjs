/**
 * Reparte en lotes las afirmaciones cuyo localizador está en duda, para la pasada C.
 *
 * La pasada C es **localización ciega**: recibe lo que la afirmación dice y **no** dónde dice el
 * catálogo que lo dice, y busca el pasaje por su cuenta. El plan la describía desde el principio y
 * no se ejecutó nunca, con la consecuencia de que las dos pasadas que sí corrieron empiezan las
 * dos por donde el catálogo señala —que es la manera de no ver jamás que el sitio es otro—. El
 * localizador desplazado acabó siendo la familia de defectos más numerosa de la auditoría.
 *
 * No se lanza sobre las 267: se lanza **donde hay duda**, que es donde una tercera opinión decide
 * algo. Son tres situaciones, y la tercera es la que la justificó:
 *
 * - La pasada A marcó «localizador falso» o «anclaje equivocado».
 * - La lectura ciega dice que el localizador no lleva al pasaje y A no había anotado nada.
 * - Las dos anteriores **se contradicen** entre sí.
 *
 * Al estrenarla sobre cuatro afirmaciones de Caparrós 2014 en que A y B discrepaban, **B se
 * equivocó en tres de las cuatro**. De ahí que una discrepancia no se resuelva a favor de nadie
 * por defecto: se manda una tercera lectura y después se comprueba en el PDF.
 *
 * Uso:
 *   node scripts/auditoria-fuentes/lotes-pasada-c.mjs               # dice qué falta, sin escribir
 *   node scripts/auditoria-fuentes/lotes-pasada-c.mjs --escribe
 *   node scripts/auditoria-fuentes/lotes-pasada-c.mjs --ids 008e03ef,28847825 --escribe
 */

import { readFileSync, readdirSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { query } from '../lib/consulta.mjs';

const RAIZ = fileURLToPath(new URL('../..', import.meta.url));
const BASE = join(RAIZ, 'docs', 'dominio-metrico', 'auditoria-fuentes');
const DECISIONES = join(BASE, 'decisiones.json');
const C = join(BASE, 'dictamenes-c');
const LOTES_C = join(BASE, 'lotes-c');

/** Ocho por lote: la C obliga a abrir el PDF varias veces por afirmación y sale más lenta que las otras. */
const POR_LOTE = 8;

const escribe = process.argv.includes('--escribe');
const soloIds = (() => {
	const i = process.argv.indexOf('--ids');
	return i >= 0 ? new Set(process.argv[i + 1].split(',').map((x) => x.trim())) : null;
})();

/**
 * Los que ya están atendidos, que **no es lo mismo que los ya leídos**.
 *
 * Cuenta tanto los que tienen localización ciega como los que ya están metidos en un lote, aunque
 * nadie lo haya despachado todavía. Sin lo segundo, ejecutar esto dos veces vuelve a repartir las
 * mismas afirmaciones en lotes nuevos con otro número: la segunda tirada creó veintiún ficheros
 * duplicados antes de que se viera.
 */
function yaAtendidas() {
	const vistos = new Set();
	for (const [carpeta, campo] of [
		[C, 'localizaciones'],
		[LOTES_C, 'afirmaciones']
	]) {
		if (!existsSync(carpeta)) continue;
		for (const f of readdirSync(carpeta).filter((x) => x.endsWith('.json'))) {
			const d = JSON.parse(readFileSync(join(carpeta, f), 'utf-8'));
			for (const l of d[campo] ?? []) vistos.add(l.id);
		}
	}
	return vistos;
}

function ultimoLote(anio) {
	if (!existsSync(LOTES_C)) return 0;
	return readdirSync(LOTES_C)
		.map((f) => f.match(new RegExp(`^${anio}-(\\d+)\\.json$`)))
		.filter(Boolean)
		.reduce((n, m) => Math.max(n, Number(m[1])), 0);
}

/** ¿El localizador de esta afirmación está en duda? */
function enDuda(d) {
	if (d.estado !== 'pendiente') return null;
	const tipos = (d.defectos ?? []).join(' ');
	const porA = /localizador falso|anclaje equivocado/.test(tipos);
	const porB = (d.contradice_b ?? []).includes('material');
	if (porA && porB) return 'las dos pasadas lo señalan';
	if (porA) return 'la pasada A lo marcó';
	if (porB) return 'solo la lectura ciega lo señala';
	return null;
}

function main() {
	if (!existsSync(DECISIONES)) {
		console.error(
			'No hay `decisiones.json`. Genera antes la hoja con `npm run correcciones:hoja`.'
		);
		process.exit(1);
	}
	const decisiones = JSON.parse(readFileSync(DECISIONES, 'utf-8'));
	const hechas = yaAtendidas();

	const candidatas = new Map();
	for (const d of decisiones) {
		const motivo = soloIds ? (soloIds.has(d.id) ? 'pedida a mano' : null) : enDuda(d);
		if (!motivo || hechas.has(d.id)) continue;
		candidatas.set(d.id, motivo);
	}

	if (!candidatas.size) {
		console.log('No hay ninguna afirmación con el localizador en duda pendiente de localizar.');
		return;
	}

	// El texto se saca de la base, que es la fuente de verdad, y **el localizador no se saca**:
	// es justamente lo que el verificador no puede ver.
	const filas = query(`
		select left(a.afirmacion_id::text, 8) id, f.anio,
			coalesce(fo.nombre, foa.nombre || ' · ' || ar.nombre, foe.nombre) sobre,
			a.resumen
		from public.afirmaciones_fuentes_metricas a
		join public.fuentes_metricas f using (fuente_id)
		left join public.formas_metricas fo on fo.forma_id = a.forma_id
		left join public.arquitecturas_forma ar on ar.arquitectura_id = a.arquitectura_id
		left join public.formas_metricas foa on foa.forma_id = ar.forma_id
		left join public.esquemas_rima er on er.esquema_rima_id = a.esquema_rima_id
		left join public.arquitecturas_forma are on are.arquitectura_id = er.arquitectura_id
		left join public.formas_metricas foe on foe.forma_id = are.forma_id
		order by f.anio, 3;
	`).filter((x) => candidatas.has(x.id));

	console.log(
		`${filas.length} afirmaciones con el localizador en duda y sin localización ciega.\n`
	);

	const porAnio = new Map();
	for (const x of filas) {
		if (!porAnio.has(x.anio)) porAnio.set(x.anio, []);
		porAnio.get(x.anio).push(x);
	}

	if (escribe) mkdirSync(LOTES_C, { recursive: true });

	for (const [anio, lista] of [...porAnio].sort((a, b) => a[0] - b[0])) {
		let n = ultimoLote(anio);
		for (let i = 0; i < lista.length; i += POR_LOTE) {
			n += 1;
			const trozo = lista.slice(i, i + POR_LOTE);
			const nombre = `${anio}-${n}.json`;
			console.log(`${nombre}  ${String(trozo.length).padStart(2)}`);
			for (const x of trozo) console.log(`     ${x.id} ${x.sobre} — ${candidatas.get(x.id)}`);
			if (escribe && !existsSync(join(LOTES_C, nombre))) {
				writeFileSync(
					join(LOTES_C, nombre),
					`${JSON.stringify(
						{
							anio,
							lote: n,
							afirmaciones: trozo.map((x) => ({ id: x.id, sobre: x.sobre, texto: x.resumen }))
						},
						null,
						'\t'
					)}\n`,
					'utf-8'
				);
			}
		}
	}

	if (!escribe) console.log('\nNada escrito. Repite con `--escribe` para crear los lotes.');
	else
		console.log(
			'\nLos lotes se despachan con el texto exacto de',
			'`docs/dominio-metrico/auditoria-fuentes/instrucciones-verificador-c.md`.'
		);
}

main();

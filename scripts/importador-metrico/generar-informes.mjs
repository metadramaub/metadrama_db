import { rutaPiloto } from '../lib/importador-metrico/rutas.mjs';
/** Solo SELECT opcional. Genera seguimiento del lote e informe completo para revisión. */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { normalizarExtraccion } from '../lib/importador-metrico/normalizacion.mjs';
import { completarExtraccion } from '../lib/importador-metrico/completar-extraccion.mjs';
import { informeSeguimiento, informeEquivalencias, reglasPorDenominacion } from '../lib/importador-metrico/informes.mjs';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const args = process.argv.slice(2);
if (args.some((a) => !['--comprobar', '--actualizar-guardados'].includes(a)) || (args.includes('--comprobar') && args.includes('--actualizar-guardados'))) {
	throw new Error('Uso: generar-informes.mjs [--comprobar | --actualizar-guardados]');
}
const read = (name) => JSON.parse(readFileSync(rutaPiloto(name), 'utf8'));
const lote = read('seguimiento-lote.json');
if (lote.obras.length !== 20 || new Set(lote.obras.map((o) => o.numero)).size !== 20) throw new Error('El seguimiento debe identificar las veinte obras sin duplicados.');
if (args.includes('--actualizar-guardados')) {
	const { query } = await import('../lib/consulta.mjs');
	const importaciones = query('select i.obra_id,i.importacion_id,o.titulo,i.importado_en,i.usada_en_corpus from public.importaciones_metricas i join public.obras o on o.obra_id=i.obra_id order by i.importado_en');
	writeFileSync(rutaPiloto('registro-guardados.json'), JSON.stringify({ consultado_en: new Date().toISOString(), importaciones }, null, 2) + '\n');
}
const registro = read('registro-guardados.json');
const reglas = read('equivalencias.propuestas.json'), catalogo = read('catalogo-referencia.json');
const bibliografia = read('bibliografia-contraste.json');
const observaciones = new Map(), problemas = [], evidencias = [];
// El inventario lee las veinte respuestas del lote 0.27, no la última entrada del seguimiento.
const lote027 = 'docs/importador-metrico/evaluacion/ensayos/v0.27/ChatGPT GPT-6 High/';
const cotejo = JSON.parse(readFileSync(join(repo, lote027, 'revision-transcripcion.json'), 'utf8'));
const slugTitulo = (titulo) =>
	titulo.split(' (')[0].normalize('NFD').replace(/\p{M}/gu, '').toLowerCase().replace(/[^a-z0-9]+/g, '-');
for (const obra of cotejo.obras) {
	const archivo = lote027 + obra.archivo;
	obra.titulo = lote.obras.find((o) => slugTitulo(o.titulo) === obra.slug)?.titulo ?? obra.slug;
	if (!archivo) continue;
	const path = resolve(repo, archivo);
	if (!path.startsWith(repo + '/') && !path.startsWith(repo + '\\')) throw new Error('Entrada fuera del repositorio');
	if (!existsSync(path)) { problemas.push(`${obra.titulo}: falta el archivo local ${archivo}.`); continue; }
	const contenido = readFileSync(path, 'utf8');
	evidencias.push(`- ${obra.titulo}: \`${archivo}\`, SHA-256 \`${createHash('sha256').update(contenido).digest('hex')}\`.`);
	try {
		const raw = completarExtraccion(JSON.parse(contenido));
		let resultado;
		let preparacionBloqueada = false;
		try {
			resultado = normalizarExtraccion(raw, { reglas, catalogo, bibliografia });
		} catch (error) {
			// Una obra bloqueada por cifras sigue aportando su vocabulario al inventario.
			preparacionBloqueada = true;
			problemas.push(`${obra.titulo}: ${error.message}; se conserva el inventario y se muestran por separado las reglas disponibles por denominación.`);
			resultado = { segmentos: raw.tramos.map((fuente) => ({ fuente, v_ini: fuente.v_ini, v_fin: fuente.v_fin, candidatas: [], regla_id: null })) };
		}
		for (const s of resultado.segmentos) {
			const literal = s.fuente.denominacion_literal ?? '(sin denominación)';
			if (!observaciones.has(literal)) observaciones.set(literal, { literal, origenes: [], resultados: new Set(), apariciones: [] });
			const o = observaciones.get(literal);
			const origen = `${obra.titulo}, ${s.fuente.id} (${s.v_ini}–${s.v_fin})`;
			const destino = s.identificacion_revisada ?? s.propuesta;
			if (!o.origenes.includes(origen)) {
				o.origenes.push(origen);
				o.apariciones.push({ obra: obra.titulo, fila: s.fuente.id, v_ini: s.v_ini, v_fin: s.v_fin,
					preparacion_bloqueada: preparacionBloqueada, regla_id: s.regla_id, formas: destino ? [destino.forma_slug] : s.candidatas.map((c) => c.forma_slug),
					formas_identificadas: destino ? [destino.forma_slug] : [],
					notas: (raw.notas ?? []).filter((n) => s.fuente.notas_ref?.includes(n.id)).map((n) => n.texto_literal).filter(Boolean) });
			}
			const disponibles = reglasPorDenominacion(literal, reglas.reglas);
			if (preparacionBloqueada) o.resultados.add('Preparación bloqueada por incidencias de la obra; ' + (disponibles.length ? 'reglas disponibles por denominación: ' + disponibles.map((r) => r.id).join(', ') : 'sin coincidencia literal general; notas y patrones sin evaluar'));
			else o.resultados.add(destino ? `${destino.forma_slug}${destino.arquitectura_slug ? ' / ' + destino.arquitectura_slug : ''} (${s.regla_id})` : s.candidatas.length ? `Sin resolver; candidatas: ${s.candidatas.map((c) => c.forma_slug).join(', ')}` : 'Sin identificación en esta preparación');
		}
	} catch (error) { problemas.push(`${obra.titulo}: ${error.message}`); }
}
const coincidencias = registro.importaciones.filter((i) => !lote.obras.some((o) => o.obra_id === i.obra_id));
const seguimiento = informeSeguimiento(lote, registro) + (coincidencias.length ? `\n## Importaciones sin vincular al seguimiento\n\n${coincidencias.map((i) => `- ${i.titulo}: obra_id ${i.obra_id}. Revisar identidad antes de vincular.`).join('\n')}\n` : '');
const complejos = readFileSync(join(repo, 'docs/importador-metrico/equivalencias/casos-complejos-equivalencias.md'), 'utf8').replace(/^# .*\r?\n/, '').replace(/^## /gm, '### ');
const revision = informeEquivalencias(catalogo, reglas, [...observaciones.values()], problemas, {
	decisiones: read('decisiones-equivalencias.json').decisiones, casos: complejos, evidencias
});
for (const [nombre, contenido] of [['seguimiento-lote.md', seguimiento], ['revision-equivalencias.md', revision]]) {
	const path = rutaPiloto(nombre);
	if (args.includes('--comprobar')) {
		if (!existsSync(path) || readFileSync(path, 'utf8').replaceAll('\r\n', '\n') !== contenido.replaceAll('\r\n', '\n')) throw new Error(`Informe desactualizado: ${nombre}`);
	} else writeFileSync(path, contenido);
}
console.log(JSON.stringify({ obras: lote.obras.length, guardadas: lote.obras.filter((o) => registro.importaciones.some((i) => i.obra_id === o.obra_id)).length, formas_catalogo: catalogo.formas.length, terminos_observados: observaciones.size, entradas_no_disponibles_o_invalidas: problemas }, null, 2));

/** Solo SELECT opcional. Genera seguimiento del lote e informe completo para revisión. */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';
import { normalizarExtraccion } from '../lib/importador-metrico/normalizacion.mjs';
import { informeSeguimiento, informeEquivalencias } from '../lib/importador-metrico/informes.mjs';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const root = join(repo, 'docs/importador-metrico/piloto');
const args = process.argv.slice(2);
if (args.some((a) => !['--comprobar', '--actualizar-guardados'].includes(a)) || (args.includes('--comprobar') && args.includes('--actualizar-guardados'))) {
	throw new Error('Uso: generar-informes.mjs [--comprobar | --actualizar-guardados]');
}
const read = (name) => JSON.parse(readFileSync(join(root, name), 'utf8'));
const lote = read('seguimiento-lote.json');
if (lote.obras.length !== 20 || new Set(lote.obras.map((o) => o.numero)).size !== 20) throw new Error('El seguimiento debe identificar las veinte obras sin duplicados.');
if (args.includes('--actualizar-guardados')) {
	const { query } = await import('../lib/consulta.mjs');
	const importaciones = query('select i.obra_id,i.importacion_id,o.titulo,i.importado_en,i.usada_en_corpus from public.importaciones_metricas i join public.obras o on o.obra_id=i.obra_id order by i.importado_en');
	writeFileSync(join(root, 'registro-guardados.json'), JSON.stringify({ consultado_en: new Date().toISOString(), importaciones }, null, 2) + '\n');
}
const registro = read('registro-guardados.json');
const reglas = read('equivalencias.propuestas.json'), catalogo = read('catalogo-referencia.json');
const bibliografia = read('bibliografia-contraste.json');
const observaciones = new Map(), problemas = [], evidencias = [];
for (const obra of lote.obras) {
	const archivo = obra.entradas.at(-1);
	if (!archivo) continue;
	const path = resolve(repo, archivo);
	if (!path.startsWith(repo + '/') && !path.startsWith(repo + '\\')) throw new Error('Entrada fuera del repositorio');
	if (!existsSync(path)) { problemas.push(`${obra.titulo}: falta el archivo local ${archivo}.`); continue; }
	const contenido = readFileSync(path, 'utf8');
	evidencias.push(`- ${obra.titulo}: \`${archivo}\`, SHA-256 \`${createHash('sha256').update(contenido).digest('hex')}\`.`);
	try {
		const raw = JSON.parse(contenido);
		const resultado = normalizarExtraccion(raw, { reglas, catalogo, bibliografia });
		for (const s of resultado.segmentos) {
			const literal = s.fuente.denominacion_literal ?? '(sin denominación)';
			if (!observaciones.has(literal)) observaciones.set(literal, { literal, origenes: [], resultados: new Set(), apariciones: [] });
			const o = observaciones.get(literal);
			const origen = `${obra.titulo}, ${s.fuente.id} (${s.v_ini}–${s.v_fin})`;
			const destino = s.identificacion_revisada ?? s.propuesta;
			if (!o.origenes.includes(origen)) {
				o.origenes.push(origen);
				o.apariciones.push({ obra: obra.titulo, fila: s.fuente.id, v_ini: s.v_ini, v_fin: s.v_fin,
					regla_id: s.regla_id, formas: destino ? [destino.forma_slug] : s.candidatas.map((c) => c.forma_slug),
					formas_identificadas: destino ? [destino.forma_slug] : [],
					notas: (raw.notas ?? []).filter((n) => s.fuente.notas_ref?.includes(n.id)).map((n) => n.texto_literal).filter(Boolean) });
			}
			o.resultados.add(destino ? `${destino.forma_slug}${destino.arquitectura_slug ? ' / ' + destino.arquitectura_slug : ''} (${s.regla_id})` : s.candidatas.length ? `Sin resolver; candidatas: ${s.candidatas.map((c) => c.forma_slug).join(', ')}` : 'Sin equivalencia');
		}
	} catch (error) { problemas.push(`${obra.titulo}: ${error.message}`); }
}
const coincidencias = registro.importaciones.filter((i) => !lote.obras.some((o) => o.obra_id === i.obra_id));
const seguimiento = informeSeguimiento(lote, registro) + (coincidencias.length ? `\n## Importaciones sin vincular al seguimiento\n\n${coincidencias.map((i) => `- ${i.titulo}: obra_id ${i.obra_id}. Revisar identidad antes de vincular.`).join('\n')}\n` : '');
const complejos = readFileSync(join(root, '../casos-complejos-equivalencias.md'), 'utf8').replace(/^# .*\r?\n/, '').replace(/^## /gm, '### ');
const revision = informeEquivalencias(catalogo, reglas, [...observaciones.values()], problemas, {
	decisiones: read('decisiones-equivalencias.json').decisiones, casos: complejos, evidencias
});
for (const [nombre, contenido] of [['seguimiento-lote.md', seguimiento], ['revision-equivalencias.md', revision]]) {
	const path = join(root, nombre);
	if (args.includes('--comprobar')) {
		if (!existsSync(path) || readFileSync(path, 'utf8').replaceAll('\r\n', '\n') !== contenido.replaceAll('\r\n', '\n')) throw new Error(`Informe desactualizado: ${nombre}`);
	} else writeFileSync(path, contenido);
}
console.log(JSON.stringify({ obras: lote.obras.length, guardadas: lote.obras.filter((o) => registro.importaciones.some((i) => i.obra_id === o.obra_id)).length, formas_catalogo: catalogo.formas.length, terminos_observados: observaciones.size, entradas_no_disponibles_o_invalidas: problemas }, null, 2));

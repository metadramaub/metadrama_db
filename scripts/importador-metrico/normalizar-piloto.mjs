/** Produce el ensayo de normalización del lote aceptado. Solo archivos locales. */
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import {
	normalizarExtraccion,
	informeNormalizacion
} from '../lib/importador-metrico/normalizacion.mjs';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');
const root = join(repo, 'docs/importador-metrico/piloto');
const read = (name) => JSON.parse(readFileSync(join(root, name), 'utf8'));
const args = process.argv.slice(2);
if (args.some((a) => a !== '--comprobar')) {
	console.error('Uso: node scripts/importador-metrico/normalizar-piloto.mjs [--comprobar]');
	process.exit(64);
}

try {
	const reglas = read('equivalencias.propuestas.json');
	const catalogo = read('catalogo-referencia.json');
	const bibliografia = read('bibliografia-contraste.json');
	const fuentes = read('fuentes.json');
	const revision = read('revision-humana.json');
	const segmentacion = read('segmentacion.propuestas.json');
	if (
		revision.esquema !== 'versologia-revision-transcripcion/0.1' ||
		!revision.responsable ||
		!revision.fecha
	)
		throw new Error('Falta identificar la revisión de transcripción');
	const refs = [...new Set(fuentes.fotografias.map((f) => f.obra_ref))].sort();
	if (
		revision.revisiones.length !== refs.length ||
		new Set(revision.revisiones.map((r) => r.obra_ref)).size !== refs.length
	)
		throw new Error('La revisión no identifica las cuatro obras sin duplicados');
	const decisiones =
		segmentacion.estado === 'criterios_de_desviacion_acordados'
			? [
					...segmentacion.propuestas.filter((p) => p.estado === 'resuelta_como_desviacion'),
					...segmentacion.observaciones.filter((p) => p.accion === 'registrar_desviacion_de_metro')
				].map((p) => ({ ...p, estado: 'acordada', fundamento: p.motivo }))
			: [];
	const outputs = new Map();
	const results = [];
	for (const ref of refs) {
		const archivo = `extracciones/${ref}.json`;
		const raw = readFileSync(join(root, archivo));
		const sha256 = createHash('sha256').update(raw).digest('hex');
		const accepted = revision.revisiones.find((r) => r.obra_ref === ref);
		if (
			accepted?.archivo !== archivo ||
			accepted.sha256 !== sha256 ||
			!['aceptada_sin_correcciones', 'aceptada_con_correccion'].includes(accepted.resultado)
		)
			throw new Error(`La extracción no coincide con la versión aceptada: ${ref}`);
		const result = normalizarExtraccion(JSON.parse(raw.toString('utf8')), {
			reglas,
			catalogo,
			fuentes,
			decisiones,
			bibliografia
		});
		result.revision_transcripcion = {
			...accepted,
			responsable: accepted.responsable ?? revision.responsable,
			fecha: accepted.fecha ?? revision.fecha
		};
		result.entradas_sha256 = Object.fromEntries(
			[
				'equivalencias.propuestas.json',
				'catalogo-referencia.json',
				'auditoria-tercetos-2026-10-26.json',
				'segmentacion.propuestas.json',
				'revision-humana.json',
				'bibliografia-contraste.json'
			].map((name) => [
				name,
				createHash('sha256')
					.update(readFileSync(join(root, name)))
					.digest('hex')
			])
		);
		results.push(result);
		outputs.set(join(root, `normalizadas/${ref}.json`), JSON.stringify(result, null, 2) + '\n');
		outputs.set(join(root, `normalizadas/${ref}.md`), informeNormalizacion(result));
	}
	const total = results.reduce((n, r) => n + r.cobertura.versos, 0);
	const sum = (key) => results.reduce((n, r) => n + r.cobertura[key].versos, 0);
	const resumen =
		[
			'# Primer ensayo de normalización',
			'**Borrador local.** La aceptación de las cuatro transcripciones está registrada. Las equivalencias propuestas todavía no son identificaciones revisadas.',
			`Reglas ${reglas.version}; catálogo revisión ${catalogo.estado.revision}. Total: ${total} versos. No se escribe en Supabase.`,
			'| Obra | Versos | Forma revisada | Solo propuesta | Con candidatas | Sin resolver | Informe |',
			'| --- | --- | --- | --- | --- | --- | --- |',
			...results.map(
				(r) =>
					`| ${r.metadatos.titulo} | ${r.cobertura.versos} | ${r.cobertura.forma_revisada.versos} | ${r.cobertura.forma_solo_propuesta.versos} | ${r.cobertura.con_candidatas.versos} | ${r.cobertura.sin_resolver.versos} | [Abrir](./normalizadas/${r.obra_ref}.md) |`
			),
			`\nEn el lote hay ${sum('forma_revisada')} versos con forma revisada y ${sum('forma_solo_propuesta')} con una correspondencia única pendiente de aprobación. Las listas de candidatas abarcan ${sum('con_candidatas')} versos; otros ${sum('sin_resolver')} permanecen sin resolver. Ninguna de estas cantidades es una probabilidad de acierto.`,
			'\nLos segmentos conservan las filas de la fuente; no afirman la segmentación definitiva de las fichas. Los 133 versos de t16 de Los locos conservan el v. 2666 como adición estructural. No se elimina del total de la obra.',
			'\nLa revisión siguiente debe decidir las correspondencias y su ámbito. Cualquier aprobación se registra en la regla, con responsable, fecha y fundamento; no se deduce de que una forma tenga el mismo nombre.'
		].join('\n') + '\n';
	outputs.set(join(root, 'informe-normalizacion.md'), resumen);
	const apoyo =
		[
			`# Referencia de correspondencias ${reglas.version}`,
			'Generada desde las mismas reglas que usa el normalizador local. Es apoyo para proponer normalizaciones posteriores a la extracción literal; no autoriza a reescribir la declaración original ni a afirmar revisiones humanas.',
			...reglas.reglas.map((r) =>
				[
					`## ${r.id}`,
					`Literales: ${r.literales.map((l) => `«${l}»`).join('; ')}.`,
					`Tipo: ${r.tipo}. Revisión: ${r.aprobacion ? 'aprobada en el ámbito indicado' : 'pendiente'}.`,
					`Ámbito: ${r.ambito?.obras.join(', ') ?? (r.aprobacion ? 'correspondencia terminológica aprobada para el corpus mínimo' : 'propuesta general, pendiente de validar')}.`,
					`Destinos o candidatas: ${r.candidatas.map((c) => c.forma_slug + (c.arquitectura_slug ? '/' + c.arquitectura_slug : '')).join('; ') || 'sin destino respaldado'}. Exhaustividad: ${r.exhaustividad}.`,
					r.fundamento,
					`Detalles de la fuente: ${r.detalles_fuente.map((d) => (d.nombre ? `${d.nombre}: ${d.literal}` : d.literal)).join('; ') || 'sin otros detalles declarados'}.`,
					'No inferir canto, medidas, ausencia de desviaciones ni respuestas de unidad no declaradas.'
				].join('\n\n')
			)
		].join('\n\n') + '\n';
	outputs.set(
		join(repo, `prompts/importador-metrico/referencia-equivalencias-${reglas.version}.md`),
		apoyo
	);
	// Todas las entradas se comprueban antes de escribir el primer derivado.
	for (const [path, content] of outputs) {
		if (args.includes('--comprobar')) {
			if (!existsSync(path) || readFileSync(path, 'utf8').replaceAll('\r\n', '\n') !== content)
				throw new Error(`Derivado desactualizado: ${path}`);
		} else {
			mkdirSync(dirname(path), { recursive: true });
			writeFileSync(path, content);
		}
	}
	console.log(
		JSON.stringify(
			{
				obras: results.length,
				versos: total,
				forma_revisada: sum('forma_revisada'),
				solo_propuesta: sum('forma_solo_propuesta'),
				con_candidatas: sum('con_candidatas'),
				sin_resolver: sum('sin_resolver'),
				derivados: outputs.size
			},
			null,
			2
		)
	);
} catch (error) {
	console.error(error.message);
	process.exitCode = 1;
}

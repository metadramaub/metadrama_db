/** Ensaya el contrato mínimo sobre el piloto. No confirma importaciones ni conecta con la DB. */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { z } from 'zod';
import {
	prepararFichaMinima,
	validarFichaMinima,
	resumirFichaMinima,
	fichaMinimaSchema
} from '../lib/importador-metrico/ficha-minima.mjs';

const root = resolve(
	dirname(fileURLToPath(import.meta.url)),
	'../../docs/importador-metrico/piloto'
);
const args = process.argv.slice(2);
if (args.some((a) => a !== '--comprobar')) {
	console.error('Uso: node scripts/importador-metrico/preparar-piloto.mjs [--comprobar]');
	process.exit(64);
}
const read = (name) => JSON.parse(readFileSync(join(root, name), 'utf8'));
const digest = (name) =>
	createHash('sha256')
		.update(readFileSync(join(root, name)))
		.digest('hex');
const cell = (s) =>
	String(s ?? '—')
		.replaceAll('|', '\\|')
		.replaceAll('\n', ' ');

try {
	const catalogo = {
		...read('catalogo-referencia.json'),
		generos: read('auditoria-flujo-2026-10-26.json')
			.vocabularios.filter((v) => v.categoria === 'genero')
			.map((v) => v.termino),
		metros: read('auditoria-campos-2026-10-22.json').metros_ejemplo.map((m) => m.slug),
		secciones: [
			...(read('catalogo-referencia.json').secciones ?? []),
			...read('auditoria-campos-2026-10-22.json').secciones_cancion
		]
	};
	const revision = read('revision-humana.json');
	const refs = revision.revisiones.map((r) => r.obra_ref).sort();
	if (!refs.length || new Set(refs).size !== refs.length)
		throw new Error('Revisión de transcripción vacía o duplicada');
	const outputs = new Map();
	const resultados = [];
	for (const ref of refs) {
		const normalizada = read(`normalizadas/${ref}.json`);
		const aceptada = revision.revisiones.find((r) => r.obra_ref === ref);
		if (
			aceptada.resultado !== 'aceptada_sin_correcciones' ||
			aceptada.sha256 !== digest(aceptada.archivo) ||
			normalizada.revision_transcripcion?.sha256 !== aceptada.sha256 ||
			normalizada.obra_ref !== ref
		)
			throw new Error(`La transcripción no coincide con la versión aceptada: ${ref}`);
		for (const [archivo, hash] of Object.entries(normalizada.entradas_sha256)) {
			if (digest(archivo) !== hash)
				throw new Error(`Entrada de normalización cambiada: ${archivo}`);
		}
		const datos = prepararFichaMinima(normalizada, { genero: 'comedia_o_tragicomedia' });
		for (const archivo of [
			'fuentes.json',
			'auditoria-flujo-2026-10-26.json',
			'auditoria-campos-2026-10-22.json'
		])
			datos.procedencia.entradas_sha256[archivo] = digest(archivo);
		const validacion = validarFichaMinima(datos, { catalogo });
		if (validacion.errores.length) throw new Error(`${ref}: ${JSON.stringify(validacion.errores)}`);
		const resumen = resumirFichaMinima(validacion.datos);
		const vista = {
			esquema: 'versologia-vista-previa-minima/0.2',
			persistido: false,
			confirmacion: null,
			datos: validacion.datos,
			resumen,
			avisos: validacion.avisos
		};
		resultados.push(vista);
		outputs.set(join(root, `preparadas/${ref}.json`), JSON.stringify(vista, null, 2) + '\n');
		outputs.set(
			join(root, `preparadas/${ref}.md`),
			[
				`# ${datos.metadatos.titulo}: vista previa de ficha mínima`,
				'**Ensayo local, sin guardar ni confirmar.** No equivale a una aprobación de correspondencias ni a una ficha creada en Supabase.',
				`Autor: ${datos.metadatos.autor_nombre}. Género seleccionado para este lote: ${datos.metadatos.genero}.`,
				`Fechas: ${datos.metadatos.fecha_inicio}–${datos.metadatos.fecha_fin}. Fuente opcional conservada: ${datos.metadatos.fuente_fecha ?? 'sin fuente'}.`,
				`Edición: ${datos.metadatos.edicion_base}`,
				`Ámbito numerado: ${resumen.extension} posiciones; ${resumen.jornadas} jornadas y ${resumen.bloques} secuencias propuestas. Forma identificada en la vista previa: ${resumen.forma_identificada}; sin resolver: ${resumen.forma_pendiente}.`,
				'| Fila | Rango | Literal de edición | Forma | Posibilidades |',
				'| --- | --- | --- | --- | --- |',
				...datos.segmentos.map(
					(s) =>
						`| ${[s.ref, `${s.v_ini}–${s.v_fin}`, s.origen.denominacion_literal, s.identificacion?.forma_slug, s.candidatas.map((c) => c.forma_slug).join('; ') || null].map(cell).join(' | ')} |`
				),
				'## Límites de esta vista',
				...validacion.avisos.map((a) => `- ${a.mensaje}`),
				'- La autoría se conserva como referencia nominal del ensayo; falta resolverla al catálogo de autores antes de guardar en DB.',
				'- La extensión no genera unidades ni confirma transiciones. Las desviaciones y detalles originales están conservados en el JSON.'
			]
				.join('\n\n')
				.replaceAll('|\n\n|', '|\n|') + '\n'
		);
	}
	outputs.set(
		join(root, 'ficha-minima.schema.json'),
		JSON.stringify(z.toJSONSchema(fichaMinimaSchema), null, 2) + '\n'
	);
	outputs.set(
		join(root, 'informe-contrato-minimo.md'),
		[
			'# Ensayo del contrato de ficha mínima',
			'**Vistas previas locales.** No hay importaciones confirmadas, cambios en Supabase ni nuevas aprobaciones filológicas. La confirmación y los permisos solo se ensayan con usuarios sintéticos en las pruebas.',
			'| Obra | Ámbito numerado | Jornadas | Secuencias propuestas | Forma identificada en la vista previa | Forma sin resolver | Vista previa |',
			'| --- | --- | --- | --- | --- | --- | --- |',
			...resultados.map(
				({ datos: d, resumen: r }) =>
					`| ${cell(d.metadatos.titulo)} | ${r.extension} | ${r.jornadas} | ${r.bloques} | ${r.forma_identificada} | ${r.forma_pendiente} | [ver](./preparadas/${d.obra_ref}.md) |`
			),
			'El contrato exige género, fechas, autor y edición. Fuente de datación y fundamentos de autoría pueden estar vacíos; tampoco exige editor asignado.',
			'El perfil mantiene los versos pendientes en el denominador. El remate de Canción y las desviaciones de Los locos se conservan; no se crean respuestas v2. La segmentación sigue siendo provisional.',
			'El JSON Schema describe campos y tipos. Las comprobaciones entre rangos, catálogo, identificaciones y permisos se ejecutan en el módulo; no quedan certificadas por JSON Schema solo.',
			'La referencia del catálogo es la conservada con el piloto. La futura integración deberá resolver identidades y consultar el catálogo vigente en el servidor.'
		]
			.join('\n\n')
			.replaceAll('|\n\n|', '|\n|') + '\n'
	);
	for (const [file, content] of outputs) {
		if (args.includes('--comprobar')) {
			if (!existsSync(file) || readFileSync(file, 'utf8').replaceAll('\r\n', '\n') !== content)
				throw new Error(`Derivado desactualizado: ${file}`);
		} else {
			mkdirSync(dirname(file), { recursive: true });
			writeFileSync(file, content);
		}
	}
	console.log(
		JSON.stringify(
			{
				obras: refs.length,
				posiciones_numeradas: resultados.reduce((n, r) => n + r.resumen.extension, 0),
				forma_identificada: resultados.reduce((n, r) => n + r.resumen.forma_identificada, 0),
				confirmaciones: 0,
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

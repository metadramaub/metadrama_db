/** Comprueba destinos locales del área reorganizada, sin red ni base de datos. */
import { existsSync, readFileSync, readdirSync } from 'node:fs';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '..');
function markdown(dir) {
	return readdirSync(dir, { withFileTypes: true }).flatMap((e) =>
		e.isDirectory()
			? markdown(join(dir, e.name))
			: e.name.endsWith('.md')
				? [join(dir, e.name)]
				: []
	);
}
const files = [
	...markdown(join(repo, 'docs/importador-metrico')),
	...markdown(join(repo, 'prompts/importador-metrico')),
	...[
		'AGENTS.md',
		'CLAUDE.md',
		'docs/guia-documentacion.md',
		'data/importador-metrico/README.md'
	].map((p) => join(repo, p))
];
const errors = [];
for (const path of files) {
	// Los ejemplos de código no son enlaces navegables.
	const text = readFileSync(path, 'utf8').replace(/```[\s\S]*?```/g, '');
	for (const match of text.matchAll(/\]\(([^)]+)\)/g)) {
		const raw = match[1].replace(/^<|>$/g, '');
		if (/^(?:[a-z][a-z\d+.-]*:|#)/i.test(raw)) continue;
		const target = decodeURIComponent(raw.split('#')[0]);
		if (target && !existsSync(resolve(dirname(path), target)))
			errors.push(`${path.slice(repo.length + 1)} → ${target}`);
	}
}
// También protege los originales cuyo contenido no debe cambiar durante una reorganización.
let originals = 0;
for (const [folder, manifest, key] of [
	['docs/importador-metrico/evaluacion/referencias', 'revision-humana.json', 'revisiones'],
	['docs/importador-metrico/evaluacion/ensayos/anteriores', 'manifest.json', 'archivos']
]) {
	const records = JSON.parse(readFileSync(join(repo, folder, manifest), 'utf8'))[key];
	for (const record of records) {
		const path = join(repo, folder, record.archivo);
		if (
			!existsSync(path) ||
			createHash('sha256').update(readFileSync(path)).digest('hex') !== record.sha256
		)
			errors.push(`Original ausente o modificado: ${folder}/${record.archivo}`);
		originals++;
	}
}
if (errors.length) {
	console.error(errors.join('\n'));
	process.exitCode = 1;
} else
	console.log(
		`Enlaces locales comprobados en ${files.length} documentos y hashes de ${originals} originales (sin comprobar anclas, red ni rutas escritas como texto).`
	);

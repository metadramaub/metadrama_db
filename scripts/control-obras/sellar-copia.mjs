/** Sella los archivos privados, crea otra carpeta y comprueba cada byte mediante SHA-256. */
import { readFileSync, writeFileSync, readdirSync, cpSync, existsSync, mkdirSync } from 'node:fs';
import { resolve, join, relative, sep, basename } from 'node:path';
import { createHash } from 'node:crypto';
const origen = resolve(
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim()
);
const raiz = resolve('backups');
if (!origen.startsWith(raiz + sep)) throw Error('La copia debe estar dentro de backups/.');
const replica = resolve('backups/control-obras-replicas', basename(origen));
if (existsSync(replica)) throw Error('La réplica ya existe; no se sobrescribe.');
const lista = (dir) =>
	readdirSync(dir, { withFileTypes: true }).flatMap((e) =>
		e.isDirectory() ? lista(join(dir, e.name)) : [join(dir, e.name)]
	);
const sha = (p) => createHash('sha256').update(readFileSync(p)).digest('hex');
const archivos = lista(origen)
	.filter((f) => basename(f) !== 'manifest.json')
	.map((f) => ({
		ruta: relative(origen, f).split(sep).join('/'),
		bytes: readFileSync(f).length,
		sha256: sha(f)
	}))
	.sort((a, b) => a.ruta.localeCompare(b.ruta));
const manifiesto = {
	sellado_en: new Date().toISOString(),
	origen,
	replica,
	archivos,
	alcance:
		'Copias lógicas y restauración de public, auth, storage e historial; no objetos binarios externos. Réplica en el mismo disco, no respaldo externo independiente.'
};
writeFileSync(join(origen, 'manifest.json'), JSON.stringify(manifiesto, null, 2) + '\n', 'utf8');
mkdirSync(resolve('backups/control-obras-replicas'), { recursive: true });
cpSync(origen, replica, { recursive: true, errorOnExist: true, force: false });
for (const f of [
	...archivos,
	{ ruta: 'manifest.json', sha256: sha(join(origen, 'manifest.json')) }
])
	if (sha(join(replica, f.ruta)) !== f.sha256) throw Error('Réplica no idéntica: ' + f.ruta);
console.log(
	`Copia y réplica verificadas: ${archivos.length + 1} archivos. Manifiesto: ${join(origen, 'manifest.json')}`
);

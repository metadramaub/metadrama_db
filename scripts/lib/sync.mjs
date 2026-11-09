/**
 * Carpeta compartida para lo que no va por git: material con derechos ajenos (bibliografía,
 * fotos de ediciones) o demasiado pesado. Vive en OneDrive y la ven todas las copias locales.
 *
 * La misma regla que fuenteovejuna-data: la variable VERSOLOGIA_SYNC_DIR (en el entorno o en
 * .env) y, si no está, OneDriveCommercial\Investigacion\versologia-data-sync.
 */
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = resolve(dirname(fileURLToPath(import.meta.url)), '../..');

function desdeEnv() {
	const ruta = join(repo, '.env');
	if (!existsSync(ruta)) return null;
	const linea = readFileSync(ruta, 'utf8')
		.split(/\r?\n/)
		.find((l) => /^\s*VERSOLOGIA_SYNC_DIR\s*=/.test(l));
	return linea ? linea.split('=').slice(1).join('=').trim().replace(/^["']|["']$/g, '') : null;
}

export function carpetaSync() {
	const configurada =
		process.env.VERSOLOGIA_SYNC_DIR ||
		desdeEnv() ||
		(process.env.OneDriveCommercial && join(process.env.OneDriveCommercial, 'Investigacion', 'versologia-data-sync'));
	if (!configurada || !existsSync(configurada))
		throw new Error(
			'No encuentro versologia-data-sync. Define VERSOLOGIA_SYNC_DIR en .env con la ruta de la carpeta de OneDrive.'
		);
	return configurada;
}

/** Ruta dentro de la carpeta sync: rutaSync('bibliografía', 'txt', 'Quilis-1969-metrica-espanola.txt'). */
export const rutaSync = (...partes) => join(carpetaSync(), ...partes);

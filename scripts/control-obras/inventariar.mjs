/** Inventario reproducible de solo lectura. Las definiciones y datos privados van a backups/. */
import { mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { query } from '../lib/consulta.mjs';

export const campos = [
	'edicion',
	'editor_asignado',
	'fecha_asignacion',
	'estado',
	'visible_publico',
	'fecha_cambio_estado',
	'fecha_publicacion',
	'autor_ficha_publico',
	'bibliografia',
	'observaciones',
	'sin_figuras_donaire',
	'sin_personajes_sobrenaturales',
	'sin_eventos_sobrenaturales',
	'tipo_ficha'
];

const destino = resolve(
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim()
);
if (!destino.startsWith(resolve('backups') + '\\') && !destino.startsWith(resolve('backups') + '/'))
	throw Error('El inventario privado debe guardarse dentro de backups/.');
mkdirSync(destino, { recursive: true });
const filas = query(readFileSync(new URL('./inventario.sql', import.meta.url), 'utf8'));
writeFileSync(
	join(destino, 'inventario.json'),
	JSON.stringify({ consultado_en: new Date().toISOString(), filas }, null, 2) + '\n',
	'utf8'
);
console.log(
	`Inventario de ${filas.length} bloques guardado en ${destino}. No se ha escrito en Supabase.`
);

/**
 * Comprueba que todo campo que el gestor del catálogo declara escribible existe de verdad como
 * columna.
 *
 * Existe porque este fallo ha mordido tres veces en agosto de 2026 y ninguna lo detectó nada:
 * `db push`, `npm run check` y las pruebas pasan sobre una lista de campos inventada. Solo se
 * nota al intentar guardar, y ni siquiera siempre — `normalizeValues` **descarta en silencio**
 * los campos que no figuran en la lista, de modo que un nombre mal escrito no da error: hace que
 * ese campo no se guarde nunca. Así estuvo la modalidad de los esquemas de rima, que el gestor
 * dejaba editar y la base no llegaba a recibir.
 *
 * Uso: npm run audit:campos
 */
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { query } from './lib/consulta.mjs';

const ENDPOINT = fileURLToPath(
	new URL('../src/routes/api/metrica/entidades/+server.ts', import.meta.url)
);

/** Campos que el endpoint compone antes de escribir y que por eso no son columnas. */
const SINTETICOS = new Set(['destino', 'medida', 'objetivo']);

const fuente = readFileSync(ENDPOINT, 'utf-8');
const bloque = fuente.slice(fuente.indexOf('const resources'), fuente.indexOf('const resourceSchema'));
const recursos = [...bloque.matchAll(/(\w+):\s*\{\s*table:\s*'([^']+)',([\s\S]*?)\n\t\},/g)];

const columnas = new Map();
for (const fila of query(
	`select table_name, string_agg(column_name, ',') as cols
	 from information_schema.columns where table_schema = 'public' group by 1`
)) {
	columnas.set(fila.table_name, new Set(fila.cols.split(',')));
}

const fantasmas = [];
for (const [, nombre, tabla, cuerpo] of recursos) {
	const cols = columnas.get(tabla);
	if (!cols) {
		fantasmas.push(`${nombre}: la tabla «${tabla}» no existe`);
		continue;
	}
	const declarados = [...new Set([...cuerpo.matchAll(/'([a-z_]+)'/g)].map((m) => m[1]))];
	const malos = declarados.filter((campo) => !cols.has(campo) && !SINTETICOS.has(campo));
	if (malos.length > 0) fantasmas.push(`${nombre} (${tabla}): ${malos.join(', ')}`);
}

console.log(`Recursos declarados por el gestor: ${recursos.length}`);
if (fantasmas.length === 0) {
	console.log('Todos sus campos existen como columna.');
	process.exit(0);
}
console.error('\nCampos que no existen como columna:');
for (const linea of fantasmas) console.error(`  ✗ ${linea}`);
console.error(
	'\nUn campo que no existe no da error al guardar: se descarta en silencio, y ese dato no se guarda nunca.'
);
process.exit(1);

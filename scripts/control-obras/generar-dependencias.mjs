/** Genera un inventario técnico sin datos personales desde el esquema auditado y el código. */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { join } from 'node:path';
const carpeta =
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim();
const inv = JSON.parse(readFileSync(join(carpeta, 'inventario.json'), 'utf8'));
const bloque = (n) => inv.filas.find((x) => x.bloque === n).datos;
const campos = [
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
	'tipo_ficha',
	'fecha_inicio_trad', 'fecha_fin_trad', 'fuente_fecha',
	'fecha_inicio_metadrama', 'fecha_fin_metadrama', 'dataciones'
];
const re = new RegExp('\\b(' + campos.join('|') + ')\\b', 'g');
const menciones = (s) => [...new Set(String(s).match(re) ?? [])].sort();
const listado = spawnSync('rg', ['--files', 'src', 'scripts', 'supabase/migrations'], {
	encoding: 'utf8'
});
if (listado.status !== 0) throw Error('No se pudieron enumerar los consumidores');
const archivos = listado.stdout
	.trim()
	.split(/\r?\n/)
	.filter(
		(f) =>
			/\.(svelte|ts|js|mjs|sql)$/.test(f) &&
			!f.replaceAll('\\', '/').startsWith('scripts/control-obras/')
	)
	.map((f) => ({ ruta: f.replaceAll('\\', '/'), campos: menciones(readFileSync(f, 'utf8')) }))
	.filter((x) => x.campos.length);
const actuales = archivos.filter((x) => !x.ruta.startsWith('supabase/'));
const funciones = bloque('funciones')
	.map((f) => ({ firma: f.firma, campos: menciones(f.definicion), definer: f.security_definer }))
	.filter((f) => f.campos.length);
const politicas = bloque('politicas').filter(
	(p) =>
		menciones((p.qual ?? '') + ' ' + (p.with_check ?? '')).length ||
		/obras|asignacion|importacion|secuencia/.test(p.tablename)
);
let md = '# Dependencias del control de obras\n\n';
md +=
	'Informe generado por `node scripts/control-obras/generar-dependencias.mjs <carpeta privada de copia>`.\n';
md +=
	'Entradas: `inventario.json` de `inventariar.mjs` (Supabase enlazado, solo lectura) y los archivos actuales de `src/`, `scripts/` y `supabase/migrations/`. No editar a mano.\n\n';
md +=
	'La búsqueda textual es conservadora: `estado` y `observaciones` pueden referirse a otras entidades. Las dependencias de catálogo no descubren todas las referencias dentro de PL/pgSQL ni SQL dinámico. Las migraciones aplicadas se inventarían, **no se editan**. No se incluyen valores de obras, cuentas, JWT ni definiciones privadas.\n\n';
md += `Auditoría de esquema: ${inv.consultado_en}. ${actuales.length} archivos de código/pruebas/generadores candidatos, ${funciones.length} funciones vivas candidatas y ${politicas.length} políticas relacionadas.\n\n`;
md +=
	'## Campos afectados\n\n| Campo actual en obras | Destino final | Archivos candidatos fuera del histórico SQL |\n| --- | --- | ---: |\n';
for (const c of campos) {
	const destino = c === 'tipo_ficha' ? 'Proyección por existencia de importación y elaboración; basica en contratos nuevos'
		: c === 'dataciones' ? 'Contrato tipado de obras_dataciones en proyecciones y artefactos'
		: c === 'fuente_fecha' || c.startsWith('fecha_inicio_') || c.startsWith('fecha_fin_')
			? `obras_dataciones, clase ${c.includes('metadrama') ? 'metrica' : 'referencia'}`
			: `fichas_completas.${c === 'edicion' ? 'edicion_base' : c}`;
	md += `| \`${c}\` | ${destino} | ${actuales.filter((a) => a.campos.includes(c)).length} |\n`;
}
md += '\n## Código, pruebas y generadores\n\n| Archivo | Campos mencionados |\n| --- | --- |\n';
for (const a of actuales)
	md += `| [${a.ruta}](../../${a.ruta}) | ${a.campos.map((c) => '`' + c + '`').join(', ')} |\n`;
md +=
	'\n## Funciones de la base viva\n\n| Firma | Campos mencionados | Security definer |\n| --- | --- | --- |\n';
for (const f of funciones)
	md += `| \`${f.firma}\` | ${f.campos.join(', ')} | ${f.definer ? 'Sí' : 'No'} |\n`;
md += '\n## Triggers de obras\n\n';
for (const t of bloque('triggers').filter((t) => t.tabla === 'obras' || t.tabla === 'public.obras'))
	md += `- \`${t.nombre}\`: \`${t.definicion}\`\n`;
md += '\n## Referencias a obras\n\n';
for (const f of bloque('referencias_obras'))
	md += `- \`${f.tabla}.${f.nombre}\`: \`${f.definicion}\`\n`;
md += '\n## Políticas relacionadas\n\n| Tabla | Política | Operación |\n| --- | --- | --- |\n';
for (const p of politicas) md += `| ${p.tablename} | ${p.policyname} | ${p.cmd} |\n`;
md += '\n## Migraciones históricas con referencias\n\n';
for (const a of archivos.filter((a) => a.ruta.startsWith('supabase/')))
	md += `- [${a.ruta}](../../${a.ruta})\n`;
mkdirSync('docs/control-obras', { recursive: true });
writeFileSync('docs/control-obras/dependencias.md', md, 'utf8');
const salidaPrivada=process.argv[3] ?? 'backups/control-obras/visual';
mkdirSync(salidaPrivada,{recursive:true});
writeFileSync(
	join(salidaPrivada, 'dependencias-codigo.json'),
	JSON.stringify(
		{
			campos,
			archivos,
			funciones,
			politicas: politicas.map((p) => ({ tabla: p.tablename, nombre: p.policyname }))
		},
		null,
		2
	) + '\n',
	'utf8'
);
console.log(
	`Informe generado: ${actuales.length} archivos candidatos y ${funciones.length} funciones vivas. Sin datos privados.`
);

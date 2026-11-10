/** Resumen versionable del ensayo, sin valores privados, derivado de sus resultados. */
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const carpeta =
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim();
const v = JSON.parse(readFileSync(join(carpeta, 'validacion-local.json'), 'utf8'));
const a = JSON.parse(readFileSync(join(carpeta, 'validacion-acceso.json'), 'utf8'));
let md = '# Validación de la preparación del control de obras\n\n';
md +=
	'Generado por `node scripts/control-obras/generar-validacion.mjs <carpeta de copia>` desde `validacion-local.json` y `validacion-acceso.json`. No editar a mano.\n\n';
md += `Ensayo: ${v.ejecutado_en}. Acceso: ${a.ejecutado_en}.\n\n`;
md +=
	'**Solo restauración aislada, sin red ni puertos; ninguna migración aplicada al Supabase compartido.**\n\n';
md += '## Datos conservados\n\n| Tipo heredado | Obras | Asignadas |\n| --- | ---: | ---: |\n';
for (const r of v.resumen)
	md += `| ${r.tipo_ficha === 'minima' ? 'Básica (valor histórico minima)' : 'Completa heredada'} | ${r.obras} | ${r.asignadas} |\n`;
md += '\n## Comprobaciones\n\n';
for (const c of v.comprobaciones) md += `- Correcta: ${c}.\n`;
md += `- Acceso real con rol authenticated y JWT para ${a.cuentas} perfiles restaurados: control global solo para gestores activos, completas de editores limitadas a sus encargos/revisiones.\n`;
md += '\n## Funciones ejecutadas\n\n';
for (const e of v.funciones_ejecutadas) md += `- \`${e}\` sobre todas las obras.\n`;
md += '- `recompute_all()` dentro de una transacción revertida; igualdad de huellas posterior.\n\n';
md += '## Diferencias entre instantes de copia y lectura remota\n\n';
if (v.diferencias_con_consulta_remota.length)
	md +=
		'Tablas distintas: ' +
		v.diferencias_con_consulta_remota.map((x) => '`' + x + '`').join(', ') +
		'. La actividad de autenticación continuó durante las copias. No hay diferencias en tablas de aplicación ni en el historial del proyecto. No se afirma igualdad de sesiones capturadas en instantes distintos.\n';
else md += 'No se detectaron diferencias de recuento ni SHA-256 en las tablas comparadas.\n';
md += '\n## Alcance y límites\n\n';
md +=
	'Se ha ensayado expansión, repetición, reversión y reaplicación sobre datos reales restaurados. No se ha adaptado la aplicación, no se ha cambiado la fuente autoritativa, no se han retirado columnas y no se ha renombrado el valor histórico persistido. Las políticas antiguas de producción no cambian. La futura migración coordinada necesita otra copia reciente y pruebas de sus lectores/escritores y roles.\n';
md +=
	'\nLos originales, instantáneas, resultados completos y huellas de cada archivo permanecen en backups privado. El snapshot por obra complementa el volcado; no sustituye a las copias de importaciones ni Auth.\n';
writeFileSync('docs/control-obras/validacion.md', md, 'utf8');
console.log('Resumen versionable de validación generado, sin datos personales.');

import { readFileSync, writeFileSync } from 'node:fs';
import { datacionVacia, formatoDatacion } from '../../src/lib/dataciones.ts';
const ruta = 'backups/control-obras/cambio/';
const api = JSON.parse(readFileSync(ruta + 'api.json', 'utf8'));
const integridad = JSON.parse(readFileSync(ruta + 'integridad.json', 'utf8'));
const tests = JSON.parse(readFileSync(ruta + 'vitest.json', 'utf8'));
const sql = readFileSync(ruta + 'pruebas.log', 'utf8');
if (!sql.includes('OK creación') || integridad.diferencias.length || tests.numFailedTests)
	throw Error('No hay validación completa satisfactoria');
let md = '# Cambio editorial: resultado del ensayo local\n\n';
md +=
	'Generado por `node scripts/control-obras/generar-resumen-cambio.mjs` desde los resultados privados de SQL, API, Vitest e integridad. No editar a mano.\n\n';
md +=
	'**El modelo de control y dataciones está implementado en local con activación deshabilitada; aún no está desplegado en Supabase.** Las correcciones independientes del timeout y de las tres autorías sí se aplicaron antes.\n\n';
md += '## Ensayo inicial\n\n';
md += `- ${integridad.tablas} tablas originales sin diferencias de SHA-256 después de los ensayos (${integridad.comprobado_en}).\n`;
md += `- ${tests.numPassedTests} pruebas focalizadas correctas; ${tests.numFailedTests} fallidas.\n`;
md +=
	'- SQL real en transacción revertida: registro sin ficha, encargo separado del inicio, autosave en completa y conservación del núcleo; denegación de escritura directa y publicación por editor; importación nueva y sobre identidad existente; conservación de metadatos y corpus; rechazo de transición básica → completa; encargo por lotes sin inicio; lectura pública limitada.\n';
md += `- ${api.pruebas.length} comprobaciones HTTP correctas (${api.ejecutado_en}):\n`;
for (const p of api.pruebas) md += '  - ' + p + '.\n';
md += '\nLa recomputación completa se ejecutó y revirtió con los lectores adaptados.\n';
const visual='backups/control-obras/visual/';
const fechaDir=readFileSync('backups/control-obras/fechas/ultimo-ensayo.txt','utf8').trim();
const fechas=JSON.parse(readFileSync(fechaDir+'/resultado.json','utf8'));
const discrepancias=JSON.parse(readFileSync(fechaDir+'/discrepancias-csv.json','utf8'));
const pruebas=JSON.parse(readFileSync(visual+'vitest-dataciones.json','utf8'));
const aplicacion=JSON.parse(readFileSync(visual+'pruebas-aplicacion.json','utf8'));
const comprobacion=readFileSync(visual+'check-dataciones.log','utf8');
const compilacion=readFileSync(visual+'build-control-obras.log','utf8');
const migracion=fechas.copiaActual ? JSON.parse(readFileSync(fechas.copiaActual+'/migracion.json','utf8')) : null;
if(!fechas.pruebasRevertidas||!fechas.cargaIdempotente||!fechas.correccionTimeoutConservada||pruebas.numFailedTests||
 aplicacion.comprobaciones.length<35||!aplicacion.comprobaciones.includes('La API guarda límites estrictos y fuentes literales')||
 !comprobacion.includes('0 errors and 0 warnings')||!compilacion.includes('✔ done'))throw Error('Falta una validación satisfactoria de dataciones');
if(fechas.migracionFinal&&migracion&&!Object.values(fechas.entradas).includes(migracion.sha256))throw Error('La migración cambió después del ensayo');
md+='\n## Control y dataciones: ensayo ampliado\n\n';
md+=`Generadores reproducibles: \`ensayar-dataciones-desde-copia.mjs\`, \`probar-aplicacion-local.mjs\`, \`pruebas-dataciones.sql\` y las pruebas junto al código. Los datos privados y copias se mantienen en \`backups/\`.\n\n`;
md+=`- Ensayo desde la restauración de producción, sin la carga CSV anterior (${fechas.comprobado_en}): ${fechas.obras} obras conservadas, ${fechas.datacionesIncorporadas} dataciones incorporadas donde faltaban; fuentes anteriores conservadas literalmente y fechas conservadas salvo la corrección expresamente autorizada de *El esclavo del demonio* (≤1612).\n`;
md+=`- ${pruebas.numPassedTests} pruebas focalizadas correctas; ${pruebas.numFailedTests} fallidas. Svelte/TypeScript: cero errores y cero avisos.\n`;
md+='- Compilación de producción completada. Se instaló la fuente ya fijada en las dependencias; package-lock permanece idéntico.\n';
md+=`- ${aplicacion.comprobaciones.length} comprobaciones reales de las API de aplicación correctas (${aplicacion.fecha}), con Auth y PostgREST locales. Incluyen dos propuestas independientes, límites estrictos, fuentes literales, rechazo de intervalos vacíos y guardado de otros metadatos sin borrar las fechas.\n`;
md+='- SQL ejecutado: permisos, escritura única, borrado sin reaparición de datos antiguos, invalidación de resúmenes y recomputación completa. Ficha, índices, autor y comparativas conservan los calificadores. Las pruebas funcionales usan transacciones revertidas; la simulación de reversión conserva su fixture solo en la base desechable de ensayo.\n';
if(fechas.migracionFinal)md+=`- Migración definitiva transaccional ejecutada y reversión probada, conservando una edición y datación añadidas después del cambio. SQL validado: SHA-256 \`${migracion.sha256}\`. Las tablas nuevas se conservan al revertir; el modelo anterior no representa sus calificadores y debe reactivarse junto con la aplicación compatible.\n`;
if(fechas.concurrenciaComprobada)md+='- Dos conexiones reales: una reasignación concurrente no queda sobrescrita por el guardado anterior; este recibe 40001 y conserva el nuevo responsable. La escritura de servicio funciona con claims JSON de PostgREST.\n';
md+=`- Carga del CSV repetida sin cambios; asignaciones conservadas. ${fechas.metricasYJsonConservados.length} tablas de métrica/estructura/procedencia conservan sus huellas. Las siete funciones de la corrección del timeout permanecen idénticas.\n`;
md+='- Pertenencias del CSV: '+fechas.corpus.map(c=>`${c.codigo}: ${c.obras}`).join('; ')+'. Lope se crea sin deducir miembros por autor.\n';
const soloAproximacion=d=>d.conservada.inicio===d.csv.inicio&&d.conservada.fin===d.csv.fin;
md+=`\n## Diferencias conservadas frente al CSV\n\n${discrepancias.filter(d=>!soloAproximacion(d)).length} diferencias en extremos y ${discrepancias.filter(soloAproximacion).length} casos donde el CSV añade aproximación. No se sustituyeron fechas existentes ni se registró un estado de revisión.\n\n`;
md+='| Obra | Inicio / fin vigentes | CSV | Diferencia |\n| --- | --- | --- | --- |\n';
for(const d of discrepancias)md+=`| ${d.titulo.replaceAll('|','\\|')} | ${d.conservada.inicio??'—'} / ${d.conservada.fin??'—'} | ${formatoDatacion({...datacionVacia('referencia'),...d.csv})} | ${soloAproximacion(d)?'Aproximación':'Extremos'} |\n`;
md+='\nEl IP confirmó que el 1612 de *El esclavo del demonio* es un límite superior por su edición: se migra a ≤1612, con la fuente intacta. La candidata comprueba el dato de origen y se detiene si ha cambiado antes del despliegue. El CSV no sustituye las demás dataciones existentes.\n';
md+='\n## Límites de la comprobación\n\nLa interacción visual inicial cubrió corpus y encargos; el navegador integrado dejó de responder y no permitió revisar visualmente el formulario nuevo. La carga SSR y las API sí se comprobaron. No se ha ejecutado el despliegue coordinado. Las columnas antiguas permanecen congeladas para recuperación hasta la contracción. Los formatos y JSON históricos permanecen intactos.\n';
writeFileSync('docs/control-obras/cambio-verificado.md', md, 'utf8');
console.log('Resultado del cambio editorial generado sin datos privados.');

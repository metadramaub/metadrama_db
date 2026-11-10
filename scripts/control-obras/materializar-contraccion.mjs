/** Solo incorpora a db push los mismos bytes cuya recuperación se ha probado. */
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
const escribir=process.argv.includes('--escribir');
if(process.argv.slice(2).some(a=>a!=='--escribir'))throw Error('Opción desconocida');
const dir=readFileSync('backups/control-obras/contraccion/ultima-restauracion.txt','utf8').trim();
const meta=JSON.parse(readFileSync(dir+'/candidata.json','utf8'));
const restauracion=JSON.parse(readFileSync(dir+'/restauracion.json','utf8'));
const validacion=JSON.parse(readFileSync(dir+'/validacion.json','utf8'));
const copia=JSON.parse(readFileSync(validacion.copia+'/manifest.json','utf8'));
const pruebas=JSON.parse(readFileSync('backups/control-obras/visual/vitest-contraccion.json','utf8'));
const api=JSON.parse(readFileSync('backups/control-obras/visual/pruebas-aplicacion.json','utf8'));
const check=readFileSync('backups/control-obras/visual/check-contraccion-corregido.log','utf8');
const build=readFileSync('backups/control-obras/visual/build-contraccion.log','utf8');
const bytes=readFileSync(meta.archivo);
if(createHash('sha256').update(bytes).digest('hex')!==meta.sha256||validacion.sha256!==meta.sha256||
 !validacion.reversionConDatosPosteriores||!validacion.reaplicacionComprobada||validacion.diferencias.length||
 !copia.archivos.length||pruebas.numFailedTests||pruebas.numPassedTests<193||api.comprobaciones.length<37||
 Date.parse(api.fecha)<Date.parse(restauracion.fecha)||!check.includes('0 errors and 0 warnings')||!build.includes('✔ done'))throw Error('Falta validación completa de la candidata actual');
const destino='supabase/migrations/20261110220000_contraer_modelo_de_obras.sql';
if(existsSync(destino)&&!readFileSync(destino).equals(bytes))throw Error('No se sobrescribe una migración distinta');
if(escribir&&!existsSync(destino))writeFileSync(destino,bytes,{flag:'wx'});
console.log(escribir?'Contracción materializada, sin ejecutar SQL.':'Contracción comprobada, sin materializar.');

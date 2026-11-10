/** Cotejo de solo lectura. No decide identidades ambiguas ni modifica asignaciones. */
import {readFileSync,writeFileSync} from 'node:fs';
import {createHash} from 'node:crypto';
import {exigirAislamiento,filas} from './local-db.mjs';
exigirAislamiento();
const dir='backups/control-obras/visual';
const csv=JSON.parse(readFileSync(dir+'/csv-original.json','utf8').replace(/^\uFEFF/,''));
const obras=filas(`select o.obra_id,o.titulo,o.variantes_titulo,o.autores,o.fecha_inicio_trad,o.fecha_fin_trad,
 o.fuente_fecha,o.edicion,o.tipo_ficha,o.editor_asignado,e.nombre_completo as editor_nombre,o.corpus
 from public.obras_editoriales o left join public.editores e on e.user_id=o.editor_asignado`);
const editores=filas("select user_id,nombre_completo,coalesce(activo,true) as activo from public.editores where email not like '%@example.invalid'");
const normalizar=s=>String(s??'').normalize('NFD').replace(/\p{Diacritic}/gu,'').toLowerCase().replace(/[^\p{L}\p{N}]+/gu,' ').trim();
const entradas=csv.map(r=>{
	const titulo=normalizar(r['Título de la obra']);
	const tituloRepetido=csv.filter(f=>normalizar(f['Título de la obra'])===titulo).length>1;
	let candidatos=obras.filter(o=>[o.titulo,...o.variantes_titulo??[]].some(t=>normalizar(t)===titulo||
		(tituloRepetido&&normalizar(t.replace(/\s*\([^)]*\)\s*$/,''))===titulo)));
	const sugeridos=candidatos.length?[]:obras.filter(o=>normalizar(o.titulo).replaceAll(' ','')===titulo.replaceAll(' ',''));
	let resolucion='titulo';
	if(candidatos.length>1){
		const tokens=normalizar(r['Atribución tradicional']).split(' ').filter(t=>!['de','del','la','el','los','las','y'].includes(t));
		const conEvidencia=candidatos.filter(o=>{
			const evidencia=new Set(normalizar((o.edicion??'')+' '+(o.titulo.match(/\(([^)]+)\)/)?.[1]??'')).split(' '));
			return tokens.length>=2&&tokens.every(t=>evidencia.has(t));
		});
		if(conEvidencia.length===1){candidatos=conEvidencia;resolucion='autor_explicito_en_edicion_o_rotulo';}
	}
	if(!candidatos.length&&sugeridos.length===1){candidatos=sugeridos;resolucion='titulo_igual_sin_espacios';}
	const identificada=candidatos.length===1;
	const responsables=r.Asignaciones?.trim()?editores.filter(e=>normalizar(e.nombre_completo)===normalizar(r.Asignaciones)):[];
	const abreviados=responsables.length||!r.Asignaciones?.trim()?[]:editores.filter(e=>{
		const a=normalizar(e.nombre_completo),b=normalizar(r.Asignaciones);return a.startsWith(b+' ')||b.startsWith(a+' ');
	});
	return {numero:r['N.º'],fuente:r,resolucion,estado:identificada?(resolucion==='titulo'?'coincidencia_unica_por_titulo':'coincidencia_resuelta_con_evidencia'):candidatos.length?'identidad_ambigua':sugeridos.length?'variante_ortografica_por_confirmar':'sin_coincidencia_exacta',
	 candidatos,sugeridos,responsables,abreviados,asignacion:identificada?(r.Asignaciones?.trim()?responsables.length===1?(candidatos[0].editor_asignado===responsables[0].user_id?'coincide':'difiere'):abreviados.length===1&&candidatos[0].editor_asignado===abreviados[0].user_id?'coincide_con_nombre_abreviado_por_confirmar':'responsable_sin_correspondencia_unica':candidatos[0].editor_asignado?'asignada_solo_en_base':'sin_asignacion'):'identidad_pendiente',
	 autoria:candidatos.length===1?(candidatos[0].autores.length?candidatos[0].autores.some(a=>normalizar(a)===normalizar(r['Atribución tradicional']))?'coincide_literal_tradicional':'literal_distinto_por_revisar':'sin_autoria_en_base'):'identidad_pendiente',
	 datacion:candidatos.length===1?(candidatos[0].fecha_inicio_trad==null&&candidatos[0].fecha_fin_trad==null?'sin_fecha_en_base':'con_fecha_en_base'):'identidad_pendiente'};
});
const repetidas=entradas.filter((r,i)=>r.candidatos.length===1&&entradas.some((p,j)=>j<i&&p.candidatos[0]?.obra_id===r.candidatos[0].obra_id));
if(repetidas.length)throw Error('Dos filas del CSV se enlazarían a la misma obra: revisar identidad');
const resumen={filas:entradas.length,unicas:entradas.filter(r=>r.candidatos.length===1).length,resueltasConEvidencia:entradas.filter(r=>r.estado==='coincidencia_resuelta_con_evidencia').length,ambiguas:entradas.filter(r=>r.estado==='identidad_ambigua').length,variantes:entradas.filter(r=>r.sugeridos.length).length,sinCoincidencia:entradas.filter(r=>!r.candidatos.length&&!r.sugeridos.length).length,
 corpus:Object.fromEntries([...new Set(csv.map(r=>r.Tipo))].map(t=>[t,csv.filter(r=>r.Tipo===t).length])),asignaciones:Object.fromEntries([...new Set(entradas.map(r=>r.asignacion))].map(t=>[t,entradas.filter(r=>r.asignacion===t).length]))};
const contenido={cotejado_en:new Date().toISOString(),origen_sha256:createHash('sha256').update(readFileSync(dir+'/csv-original.json')).digest('hex'),metodo:'Título o variante exactos tras normalizar diacríticos, puntuación y espacios. Los títulos repetidos se desambiguan solo si la edición o el rótulo identifican explícitamente al autor. Se admite una variante única que solo difiera en espacios. Las abreviaciones de responsables siguen identificadas como tales. Sin decidir por número de fila.',resumen,entradas};
writeFileSync(dir+'/cotejo-csv-conciliado.json',JSON.stringify(contenido,null,2)+'\n','utf8');
console.log(JSON.stringify(resumen));

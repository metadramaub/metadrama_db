/** Traslado administrativo excepcional autorizado por el IP: dos anotaciones V2
 * quedan incompletas. El guardado editorial exige contestar todas las preguntas;
 * aquí se insertan sus unidades sin inventar rimas ni modificar esas validaciones.
 * Por defecto ensaya con rollback. --aplicar confirma la transacción.
 * Requiere copia completa y snapshot previos según CLAUDE.md.
 */
import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { createHash, randomUUID } from 'node:crypto';
import { query, tryQuery } from './lib/consulta.mjs';
import { cargarObras } from './lib/migracion/datos.mjs';
import { cargarCatalogo } from './lib/metrica/catalogo.mjs';
import { planificarObra } from './lib/migracion/aplicador.mjs';
import { realizacionesDe } from './lib/metrica/realizaciones.mjs';

const ruta =
	'docs/dominio-metrico/migracion/respuestas/la-tragedia-del-duque-de-berganza.resoluciones.json';
const archivo = readFileSync(ruta, 'utf8'),
	reglas = JSON.parse(archivo);
const lit = (v) => (v == null ? 'null' : `'${String(v).replaceAll("'", "''")}'`);
const json = (v) => `${lit(JSON.stringify(v))}::jsonb`;
const exigir = (c, m) => {
	if (!c) throw new Error(m);
};
const ids = (filas) => filas.map((s) => `${lit(s.id)}::uuid`).join(',');
const actuales = query(
	`select to_jsonb(s) as fila from public.secuencias_metricas s where obra_id=${lit(reglas.obra_id)}::uuid order by v_ini`
).map((r) => r.fila);
const existentes = query(
	`select a.anotacion_id from public.anotaciones_metricas a join public.secuencias_metricas s using(secuencia_id) where s.obra_id=${lit(reglas.obra_id)}::uuid`
);
if (existentes.length) {
	exigir(
		existentes.length === 3 &&
			actuales.length === 3 &&
			actuales.every((s) => reglas.conservar.some((r) => r.id === s.secuencia_id)),
		'Hay una migración parcial diferente; revisar.'
	);
	console.log('Las tres secuencias ya tienen V2. No se sobrescribe su revisión.');
	process.exit(0);
}
exigir(actuales.length === 5, 'Ha cambiado el número de secuencias.');
const obra = cargarObras().find((o) => o.slug === reglas.obra);
exigir(obra && obra.secuencias.length === 5, 'No aparecen las cinco secuencias legadas.');
for (const r of [...reglas.conservar, ...reglas.eliminar]) {
	const s = obra.secuencias.find((s) => s.secuencia_id === r.id);
	exigir(
		s && s.v_ini === r.v_ini && s.v_fin === r.v_fin && s.termino_legado === r.termino,
		'Ha cambiado un origen revisado.'
	);
}
const { porId: catalogo } = cargarCatalogo();
const metros = query('select metro_id,nombre,silabas from public.metros where activo');
const editor = query(
	`select editor_asignado from public.obras where obra_id=${lit(reglas.obra_id)}::uuid`
)[0]?.editor_asignado;
exigir(editor, 'Falta el editor asignado.');
const planes = reglas.conservar.map((r) => {
	const s = obra.secuencias.find((s) => s.secuencia_id === r.id);
	if (!r.rima_pendiente) {
		const plan = planificarObra(
			{ ...obra, secuencias: [s], fundibles: [] },
			new Map(),
			catalogo,
			metros
		).anotaciones[0];
		exigir(
			plan?.datos && plan.datos.elecciones.length === 8,
			'Las octavas no producen sus ocho respuestas.'
		);
		return { ...plan, incompleta: false };
	}
	const arq = catalogo.get(s.arquitectura_propuesta_id);
	const reparto = realizacionesDe(arq, s.v_ini, s.v_fin);
	exigir(
		!reparto.problema && reparto.unidades.length === (r.v_fin - r.v_ini + 1) / 4,
		'No se reparten las redondillas.'
	);
	return {
		secuencia: s,
		resultado: 'pendiente',
		incompleta: true,
		datos: {
			anotacion_id: randomUUID(),
			secuencia_id: r.id,
			forma_id: arq.forma_id,
			arquitectura_id: s.arquitectura_propuesta_id,
			v_ini: s.v_ini,
			v_fin: s.v_fin,
			unidades: reparto.unidades,
			elecciones: [],
			desviaciones: []
		}
	};
});
const retiradas = actuales.filter((s) => reglas.eliminar.some((r) => r.id === s.secuencia_id));
const sql = [
	`select set_config('request.jwt.claims',json_build_object('sub',${lit(editor)})::text,true);`,
	`select 1 from public.obras where obra_id=${lit(reglas.obra_id)}::uuid for update;`,
	`select 1 from public.secuencias_metricas where obra_id=${lit(reglas.obra_id)}::uuid for update;`,
	`do $guardas$ begin
 if not exists(select 1 from public.obras where obra_id=${lit(reglas.obra_id)}::uuid and total_versos=876 and editor_asignado=${lit(editor)}::uuid) then raise exception 'Cambió la obra'; end if;
 if (select count(*) from public.secuencias_metricas where obra_id=${lit(reglas.obra_id)}::uuid)<>5
 or exists(select 1 from jsonb_array_elements(${json(actuales)}) e left join public.secuencias_metricas s on s.secuencia_id=(e->>'secuencia_id')::uuid where to_jsonb(s) is distinct from e)
 then raise exception 'Cambió una secuencia desde la lectura'; end if;
 if exists(select 1 from public.anotaciones_metricas a join public.secuencias_metricas s using(secuencia_id) where s.obra_id=${lit(reglas.obra_id)}::uuid)
 or exists(select 1 from public.secuencias_subtipos_estrofa where secuencia_id in (${ids(reglas.eliminar)}))
 or exists(select 1 from public.secuencias_caracterizaciones_rango where secuencia_id in (${ids(reglas.eliminar)}))
 or exists(select 1 from public.comentarios_internos where secuencia_id in (${ids(reglas.eliminar)}))
 then raise exception 'Hay datos nuevos que revisar antes de migrar o eliminar'; end if;
 end; $guardas$;`
];
for (const p of planes) {
	const d = p.datos;
	if (!p.incompleta) sql.push(`select public.guardar_anotacion_metrica(${json(d)});`);
	else {
		sql.push(`insert into public.anotaciones_metricas(anotacion_id,secuencia_id,forma_id,arquitectura_id,v_ini,v_fin,created_by,updated_by)
  values(${lit(d.anotacion_id)}::uuid,${lit(d.secuencia_id)}::uuid,${lit(d.forma_id)}::uuid,${lit(d.arquitectura_id)}::uuid,${d.v_ini},${d.v_fin},${lit(editor)}::uuid,${lit(editor)}::uuid);`);
		sql.push(`insert into public.anotacion_realizaciones(realizacion_id,anotacion_id,realizacion_padre_id,seccion_id,orden,v_ini,v_fin,etiqueta,observaciones)
  select realizacion_id,${lit(d.anotacion_id)}::uuid,realizacion_padre_id,seccion_id,orden,v_ini,v_fin,etiqueta,observaciones
  from jsonb_populate_recordset(null::public.anotacion_realizaciones,${json(d.unidades)});`);
	}
	const decisiones = {
		procedencia: reglas.procedencia,
		criterio: reglas.criterio,
		fuente: { archivo: ruta, sha256: createHash('sha256').update(archivo).digest('hex') },
		rima_pendiente: p.incompleta,
		origen_original: actuales.find((s) => s.secuencia_id === d.secuencia_id),
		...(d.v_ini === 129 ? { secuencias_eliminadas: retiradas } : {})
	};
	sql.push(`insert into public.migracion_secuencias(secuencia_id,obra_id,anotacion_id,termino_legado,origen_termino_id,resultado,respuestas,notas,migrada_por)
 select s.secuencia_id,s.obra_id,a.anotacion_id,${lit(p.secuencia.termino_legado)},s.estrofa_tipo_id,${lit(p.resultado)},${json(decisiones)},${lit(p.incompleta ? 'Traslado autorizado con el esquema de rima pendiente en todas las redondillas.' : null)},${lit(editor)}::uuid
 from public.secuencias_metricas s join public.anotaciones_metricas a using(secuencia_id) where s.secuencia_id=${lit(d.secuencia_id)}::uuid;`);
}
sql.push(
	`delete from public.secuencias_metricas where obra_id=${lit(reglas.obra_id)}::uuid and secuencia_id in (${ids(reglas.eliminar)});`
);
sql.push(`set constraints all immediate;`);
sql.push(`do $final$ begin
 if (select count(*) from public.secuencias_metricas where obra_id=${lit(reglas.obra_id)}::uuid)<>3
 or (select count(*) from public.migracion_secuencias where obra_id=${lit(reglas.obra_id)}::uuid)<>3
 or (select count(*) from public.anotacion_realizaciones r join public.anotaciones_metricas a using(anotacion_id) join public.secuencias_metricas s using(secuencia_id) where s.obra_id=${lit(reglas.obra_id)}::uuid)<>38
 or (select count(*) from public.anotacion_elecciones e join public.anotaciones_metricas a using(anotacion_id) join public.secuencias_metricas s using(secuencia_id) where s.obra_id=${lit(reglas.obra_id)}::uuid)<>8
 then raise exception 'El resultado no coincide con tres secuencias, 38 unidades y ocho respuestas'; end if;
 if (select jsonb_array_length(respuestas->'secuencias_eliminadas') from public.migracion_secuencias where secuencia_id=${lit(reglas.conservar[2].id)}::uuid) is distinct from 2
 then raise exception 'Falta el archivo de las dos secuencias eliminadas'; end if;
 end; $final$;`);
mkdirSync('backups/migracion/berganza', { recursive: true });
writeFileSync(
	'backups/migracion/berganza/plan.json',
	JSON.stringify(
		planes.map((p) => p.datos),
		null,
		2
	)
);
writeFileSync('backups/migracion/berganza/aplicacion.sql', `begin;\n${sql.join('\n')}\ncommit;`);
const aplicar = process.argv.includes('--aplicar');
const resultado = tryQuery(`begin;\n${sql.join('\n')}\n${aplicar ? 'commit' : 'rollback'};`);
exigir(!resultado.error, resultado.error);
console.log(
	aplicar
		? 'Aplicadas tres secuencias y eliminadas dos; rima de las redondillas pendiente.'
		: 'Ensayo completo superado y deshecho.'
);
if (aplicar) query('select public.recompute_all();');

/** Compone la candidata desde definiciones auditadas; nunca consulta ni modifica producción. */
import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
const carpeta =
	process.argv[2] ?? readFileSync('backups/control-obras/ultima-preparacion.txt', 'utf8').trim();
const inventario = JSON.parse(readFileSync(join(carpeta, 'inventario.json'), 'utf8'));
const bloque = (n) => inventario.filas.find((x) => x.bloque === n).datos;
const movidos = [
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
	'sin_eventos_sobrenaturales'
];
const columnas = bloque('columnas')
	.filter((c) => c.table_name === 'obras')
	.map((c) => c.column_name);
const expresion = (c) =>
	['fecha_inicio_trad','fecha_fin_trad','fuente_fecha','fecha_inicio_metadrama','fecha_fin_metadrama'].includes(c)
		? `d${c.includes('metadrama') ? 'm' : 'r'}.${c === 'fuente_fecha' ? 'fuente' : c.includes('inicio') ? 'inicio' : 'fin'}`
		: c === 'tipo_ficha'
		? "case when f.obra_id is not null then 'completa' when i.importacion_id is not null then 'basica' else 'sin_ficha' end"
		: c === 'estado'
			? "coalesce(f.estado,(select termino_id from public.vocabularios where categoria='estado' and termino='borrador'))"
			: c === 'edicion'
				? "coalesce(f.edicion_base,i.datos_confirmados#>>'{metadatos,edicion_base}')"
				: c === 'visible_publico'
					? 'coalesce(f.visible_publico,false)'
					: c.startsWith('sin_') && movidos.includes(c)
						? `coalesce(f.${c},false)`
						: movidos.includes(c)
							? `f.${c}`
							: `o.${c}`;
let sql = `-- GENERADO por generar-cambio.mjs. SOLO restauración aislada; no es despliegue automático.\nbegin;\nset local lock_timeout='5s';\nset local statement_timeout='120s';\ndo $$ begin if current_database()<>'control_obras_preparacion' then raise exception 'Solo ensayo local'; end if; end $$;\n`;
sql += readFileSync(new URL('./lectura-editorial.sql',import.meta.url),'utf8')+'\n';
sql += readFileSync(new URL('./dataciones.sql',import.meta.url),'utf8')+'\n';
sql += `create or replace view public.obras_editoriales with(security_invoker=true) as select\n`;
sql += columnas.map((c) => `${expresion(c)} as ${c}`).join(',\n');
sql += `,f.inicio_elaboracion,f.procedencia_registro,i.importacion_id,i.importado_por,
coalesce((select array_agg(c.codigo order by c.codigo) from public.obras_corpus oc join public.corpus c using(corpus_id) where oc.obra_id=o.obra_id),'{}'::text[]) as corpus,
public.autores_de_obra_editorial(o.obra_id) as autores,
coalesce((select jsonb_agg(to_jsonb(d)-'obra_id' order by d.clase) from public.obras_dataciones d where d.obra_id=o.obra_id),'[]'::jsonb) as dataciones
from public.obras o left join public.fichas_completas f using(obra_id)
left join public.importaciones_metricas i on i.obra_id=o.obra_id and i.usada_en_corpus
left join public.obras_dataciones dr on dr.obra_id=o.obra_id and dr.clase='referencia'
left join public.obras_dataciones dm on dm.obra_id=o.obra_id and dm.clase='metrica';
revoke all on public.obras_editoriales from public,anon,authenticated;
grant select on public.obras_editoriales to authenticated;
grant select,insert,update,delete on public.obras_editoriales to service_role;
grant insert,update,delete on public.obras_editoriales to authenticated;
`;
const ignoradas = new Set(['impedir_publicacion_minima', 'guardar_ficha_minima']);
for (const f of bloque('funciones')) {
	if (ignoradas.has(f.firma.split('(')[0])) continue;
	if (!/public\.obras\b/.test(f.definicion)) continue;
	let def = f.definicion
		.replace(/public\.obras\b/g, 'public.obras_editoriales')
		.replace(/'minima'/g, "'basica'");
	if (f.firma.startsWith('can_view_obra_ficha_publica('))
		def = def.replaceAll(
			'o.editor_asignado = auth.uid()',
			'(o.editor_asignado = auth.uid() and exists(select 1 from public.editores e where e.user_id=auth.uid() and coalesce(e.activo,true)))'
		);
	// Los registros ahora proceden de una vista con LEFT JOIN: bloquear solo su tabla central.
	def = def.replace(
		/from public\.obras_editoriales where obra_id = \(v_peticion\.x->>'obra_id'\)::uuid for update/g,
		"from public.obras_editoriales where obra_id = (v_peticion.x->>'obra_id')::uuid"
	);
	if (f.firma.startsWith('gestionar_asignaciones_lote('))
		def = def.replace('La asignación de una básica requiere el recorrido de elaboración detallada',
			'La asignación de una básica requiere la transición a completa, todavía pendiente').replace(
			'select * into v_obra from',
			"perform 1 from public.obras where obra_id=(v_peticion.x->>'obra_id')::uuid for update;\n    select * into v_obra from"
		);
	if (f.firma.startsWith('gestionar_asignaciones_lote('))
		def = def.replace(
			"if p_operacion = 'editor' then",
			`if v_obra.tipo_ficha='sin_ficha' and p_operacion<>'editor' then
      raise exception 'Encarga primero la completa antes de asignar revisores' using errcode='23514';
    end if;
    if p_operacion = 'editor' then
      if v_obra.tipo_ficha='sin_ficha' then perform public.iniciar_ficha_completa(v_obra.obra_id,null,false); end if;`
		);
	if (f.firma.startsWith('eliminar_ficha_basica('))
		def = def
			.replace('for update of o,i', 'for update of i')
			.replace(
				'select o.obra_id,o.tipo_ficha',
				'perform 1 from public.obras where obra_id=(select obra_id from public.importaciones_metricas where importacion_id=p_importacion) for update;\n select o.obra_id,o.tipo_ficha'
			);
	sql += def + ';\n';
}
let guardar = bloque('funciones').find((f) =>
	f.firma.startsWith('guardar_ficha_minima(')
).definicion;
guardar = guardar
	.replace(/guardar_ficha_minima/g, 'guardar_ficha_basica')
	.replace(/public\.obras\b/g, 'public.obras_editoriales')
	.replace(/'minima'/g, "'basica'");
guardar = guardar
	.replace(
		"p_coincidencias_revisadas uuid[] DEFAULT '{}'::uuid[])",
		"p_coincidencias_revisadas uuid[] DEFAULT '{}'::uuid[], p_obra uuid DEFAULT NULL)"
	)
	.replace('v_obra uuid:=gen_random_uuid()', 'v_obra uuid:=coalesce(p_obra,gen_random_uuid())')
	.replace(
		'if v_anterior.datos_confirmados is distinct from p_datos',
		'if (p_obra is not null and v_anterior.obra_id<>p_obra) or v_anterior.datos_confirmados is distinct from p_datos'
	);
guardar = guardar.replace(
	'  if not extensions.jsonb_matches_schema(public.esquema_documento_minimo(),p_datos)',
	`  if p_obra is not null then
    perform 1 from public.obras where obra_id=p_obra for update;
    if not found then raise exception 'Obra de destino no encontrada' using errcode='P0002'; end if;
    if exists(select 1 from public.fichas_completas where obra_id=p_obra)
      or exists(select 1 from public.importaciones_metricas where obra_id=p_obra)
      or exists(select 1 from public.secuencias_metricas where obra_id=p_obra)
      or exists(select 1 from public.jornadas where obra_id=p_obra) then
      raise exception 'La obra ya tiene ficha o estructura; no se sobrescribe' using errcode='23514';
    end if;
  end if;
  if not extensions.jsonb_matches_schema(public.esquema_documento_minimo(),p_datos)`
);
guardar = guardar.replace(
	/  insert into public\.obras_editoriales\([\s\S]*?(?=  insert into public\.grupos_atribucion)/,
		(m) => `  if p_obra is null then\n${m}  else
    update public.obras set genero_id=coalesce(genero_id,v_genero) where obra_id=p_obra;
    insert into public.obras_dataciones(obra_id,clase,inicio,fin,fuente)
    select p_obra,'referencia',(v_meta->>'fecha_inicio')::integer,(v_meta->>'fecha_fin')::integer,v_meta->>'fuente_fecha'
    where (v_meta->>'fecha_inicio' is not null or v_meta->>'fecha_fin' is not null or nullif(v_meta->>'fuente_fecha','') is not null)
    on conflict(obra_id,clase) do update set inicio=excluded.inicio,fin=excluded.fin,
      fuente=coalesce(obras_dataciones.fuente,excluded.fuente)
    where obras_dataciones.inicio is null and obras_dataciones.fin is null;
  end if;\n`
);
// Las autorías vigentes de la obra de destino se conservan; el autor de la básica queda en el JSON.
guardar = guardar.replace(
	'  insert into public.grupos_atribucion(grupo_atribucion_id,obra_id)',
	'  if not exists(select 1 from public.atribuciones where obra_id=v_obra) then\n  insert into public.grupos_atribucion(grupo_atribucion_id,obra_id)'
);
guardar = guardar.replace(
	/(insert into public\.atribucion_evidencias\([\s\S]*?;)/,
	'$1\n  end if;'
);
sql +=
	'drop function if exists public.guardar_ficha_basica(uuid,uuid,jsonb,jsonb,uuid[]);\n' +
	guardar +
	';\nrevoke all on function public.guardar_ficha_basica(uuid,uuid,jsonb,jsonb,uuid[],uuid) from public,anon;\ngrant execute on function public.guardar_ficha_basica(uuid,uuid,jsonb,jsonb,uuid[],uuid) to authenticated;\n';
sql += readFileSync(new URL('./cambio-editorial.sql', import.meta.url), 'utf8').replace(
	/create trigger (completas_\w+)/g,
	'drop trigger if exists $1 on public.fichas_completas;\ncreate trigger $1'
);
sql += readFileSync(new URL('./politicas-editoriales.sql', import.meta.url), 'utf8');
sql += readFileSync(new URL('./productores-dataciones.sql', import.meta.url), 'utf8');
sql += '\ncommit;\n';
writeFileSync('scripts/control-obras/002-cambio-ensayo.sql', sql, 'utf8');
console.log('Candidata de cambio generada desde las definiciones auditadas. Sin conexión remota.');

-- GENERADO por generar-cambio.mjs. SOLO restauración aislada; no es despliegue automático.
begin;
set local lock_timeout='5s';
set local statement_timeout='120s';
do $$ begin if current_database()<>'control_obras_preparacion' then raise exception 'Solo ensayo local'; end if; end $$;
-- Evita expandir las políticas de autoría dentro de una subconsulta por fila del inventario.
-- La comprobación de acceso se mantiene explícita antes de leer las propuestas.
create or replace function public.autores_de_obra_editorial(p_obra uuid) returns text[]
language plpgsql stable security definer set search_path='' as $$
declare mantenimiento boolean:=auth.uid() is null and session_user in ('postgres','supabase_admin');
        servicio boolean:=coalesce(nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'role','')='service_role';
begin
 if not(mantenimiento or servicio or public.auth_puede_ver_obra(p_obra) or
   (exists(select 1 from public.importaciones_metricas where obra_id=p_obra) and public.auth_puede_consultar_importacion(p_obra))) then
  return '{}'::text[];
 end if;
 return coalesce((select array_agg(distinct au.nombre_completo::text order by au.nombre_completo::text)
  from public.atribuciones a join public.atribucion_autores aa using(atribucion_id)
  join public.autores au using(autor_id) where a.obra_id=p_obra),'{}'::text[]);
end $$;
revoke all on function public.autores_de_obra_editorial(uuid) from public,anon;
grant execute on function public.autores_de_obra_editorial(uuid) to authenticated,service_role,postgres;

-- Expansión: el registro conserva las columnas históricas, congeladas para recuperación.
create table if not exists public.obras_dataciones (
 obra_id uuid not null references public.obras(obra_id) on delete cascade,
 clase text not null check(clase in ('referencia','metrica')),
 inicio integer, fin integer,
 inicio_inclusivo boolean not null default true,
 fin_inclusivo boolean not null default true,
 aproximada boolean not null default false,
 fuente text,
 primary key(obra_id,clase),
 check(inicio is null or inicio between 1 and 9999),
 check(fin is null or fin between 1 and 9999),
 check(inicio is null or fin is null or inicio + case when inicio_inclusivo then 0 else 1 end
   <= fin - case when fin_inclusivo then 0 else 1 end),
 check(inicio is not null or fin is not null or nullif(fuente,'') is not null)
);
alter table public.obras_dataciones enable row level security;
revoke all on public.obras_dataciones from public,anon,authenticated;
grant select on public.obras_dataciones to authenticated;
grant all on public.obras_dataciones to service_role;
drop policy if exists dataciones_consulta on public.obras_dataciones;
create policy dataciones_consulta on public.obras_dataciones for select to authenticated using (
 public.auth_puede_ver_obra(obra_id) or
 (exists(select 1 from public.importaciones_metricas i where i.obra_id=obras_dataciones.obra_id)
  and public.auth_puede_consultar_importacion(obra_id))
);
-- Copia literal: ninguna procedencia ni marca de revisión. La segunda ejecución no repone fechas borradas.
do $$ begin
 if not exists(select 1 from pg_description where objoid='public.obras_dataciones'::regclass and objsubid=0) then
  insert into public.obras_dataciones(obra_id,clase,inicio,fin,fuente)
  select obra_id,'referencia',fecha_inicio_trad,fecha_fin_trad,fuente_fecha from public.obras
   where fecha_inicio_trad is not null or fecha_fin_trad is not null or nullif(fuente_fecha,'') is not null;
  insert into public.obras_dataciones(obra_id,clase,inicio,fin)
  select obra_id,'metrica',fecha_inicio_metadrama,fecha_fin_metadrama from public.obras
   where fecha_inicio_metadrama is not null or fecha_fin_metadrama is not null;
  comment on table public.obras_dataciones is 'Dataciones de referencia y métrica; expansión inicial copiada.';
 end if;
end $$;

-- Corrección expresamente confirmada por el IP: el 1612 de esta edición es un límite superior.
-- Se conserva la fuente; si el dato cambia antes del despliegue se exige volver a cotejarlo.
do $$ declare d public.obras_dataciones%rowtype; begin
 select * into d from public.obras_dataciones where obra_id='443d1994-5ded-436e-a89f-54dcd538d732' and clase='referencia';
 if found then
  if d.inicio=1612 and d.fin is null then
   if encode(extensions.digest(convert_to(coalesce(d.fuente,''),'UTF8'),'sha256'),'hex')<>'90081a0b1319129d5b309da7fc11c49f315477b47ff9767035c25704efee8bed' then
    raise exception 'Ha cambiado la fuente de El esclavo del demonio; volver a cotejar antes de desplegar';
   end if;
   update public.obras_dataciones set inicio=null,fin=1612,inicio_inclusivo=true,fin_inclusivo=true
    where obra_id=d.obra_id and clase=d.clase;
  elsif d.inicio is null and d.fin=1612 and d.fin_inclusivo then null;
  else raise exception 'Ha cambiado la datación de El esclavo del demonio; volver a cotejar antes de desplegar';
  end if;
 end if;
end $$;

-- Operación interna atómica: el trigger de la proyección y el importador comprueban sus propios permisos.
-- No se concede EXECUTE a usuarios ni a PostgREST.
create or replace function public.escribir_dataciones_obra(p_obra uuid,p_dataciones jsonb) returns void
language plpgsql security definer set search_path='' as $$
declare d jsonb;
begin
 if jsonb_typeof(p_dataciones) is distinct from 'array' or jsonb_array_length(p_dataciones)>2 then
  raise exception 'Se admite una datación por clase' using errcode='22023'; end if;
 if exists(select 1 from jsonb_array_elements(p_dataciones) x group by x->>'clase' having count(*)>1) then
  raise exception 'Clase de datación repetida' using errcode='22023'; end if;
 delete from public.obras_dataciones where obra_id=p_obra and clase not in
  (select x->>'clase' from jsonb_array_elements(p_dataciones) x);
 for d in select value from jsonb_array_elements(p_dataciones) loop
  if d->>'clase' is null or d->>'clase' not in ('referencia','metrica') then
   raise exception 'Clase de datación inválida' using errcode='22023'; end if;
  if d->>'inicio' is null and d->>'fin' is null and coalesce(d->>'fuente','')='' then
   delete from public.obras_dataciones where obra_id=p_obra and clase=d->>'clase';
  else
   insert into public.obras_dataciones(obra_id,clase,inicio,fin,inicio_inclusivo,fin_inclusivo,aproximada,fuente)
   values(p_obra,d->>'clase',(d->>'inicio')::integer,(d->>'fin')::integer,
    coalesce((d->>'inicio_inclusivo')::boolean,true),coalesce((d->>'fin_inclusivo')::boolean,true),
    coalesce((d->>'aproximada')::boolean,false),d->>'fuente')
   on conflict(obra_id,clase) do update set inicio=excluded.inicio,fin=excluded.fin,
    inicio_inclusivo=excluded.inicio_inclusivo,fin_inclusivo=excluded.fin_inclusivo,
    aproximada=excluded.aproximada,fuente=excluded.fuente
   where (obras_dataciones.inicio,obras_dataciones.fin,obras_dataciones.inicio_inclusivo,
    obras_dataciones.fin_inclusivo,obras_dataciones.aproximada,obras_dataciones.fuente)
    is distinct from (excluded.inicio,excluded.fin,excluded.inicio_inclusivo,excluded.fin_inclusivo,excluded.aproximada,excluded.fuente);
  end if;
 end loop;
end $$;
revoke all on function public.escribir_dataciones_obra(uuid,jsonb) from public,anon,authenticated;

create or replace function public.datacion_marca_suciedad() returns trigger
language plpgsql security definer set search_path='' as $$
declare id uuid:=coalesce(new.obra_id,old.obra_id);
begin
 -- Reutilizar la ruta de invalidación real del registro (sin modificar sus fechas históricas).
 update public.obras set updated_at=now() where obra_id=id;
 update public.obras_resumen set metrica_sucia=true where obra_id=id;
 update public.autores_resumen set metrica_sucia=true where autor_id in (
  select aa.autor_id from public.atribuciones a join public.atribucion_autores aa using(atribucion_id) where a.obra_id=id);
 return coalesce(new,old);
end $$;
revoke all on function public.datacion_marca_suciedad() from public,anon,authenticated;
drop trigger if exists dataciones_suciedad on public.obras_dataciones;
create trigger dataciones_suciedad after insert or update or delete on public.obras_dataciones
 for each row execute function public.datacion_marca_suciedad();

create or replace view public.obras_editoriales with(security_invoker=true) as select
o.obra_id as obra_id,
o.titulo as titulo,
o.titulo_normalizado as titulo_normalizado,
o.variantes_titulo as variantes_titulo,
dr.inicio as fecha_inicio_trad,
dr.fin as fecha_fin_trad,
dr.fuente as fuente_fecha,
dm.inicio as fecha_inicio_metadrama,
dm.fin as fecha_fin_metadrama,
coalesce(f.edicion_base,i.datos_confirmados#>>'{metadatos,edicion_base}') as edicion,
f.editor_asignado as editor_asignado,
f.fecha_asignacion as fecha_asignacion,
coalesce(f.estado,(select termino_id from public.vocabularios where categoria='estado' and termino='borrador')) as estado,
coalesce(f.visible_publico,false) as visible_publico,
f.fecha_cambio_estado as fecha_cambio_estado,
f.observaciones as observaciones,
o.genero_id as genero_id,
o.total_versos as total_versos,
f.bibliografia as bibliografia,
o.created_at as created_at,
o.updated_at as updated_at,
f.autor_ficha_publico as autor_ficha_publico,
o.slug as slug,
coalesce(f.sin_figuras_donaire,false) as sin_figuras_donaire,
coalesce(f.sin_personajes_sobrenaturales,false) as sin_personajes_sobrenaturales,
coalesce(f.sin_eventos_sobrenaturales,false) as sin_eventos_sobrenaturales,
f.fecha_publicacion as fecha_publicacion,
case when f.obra_id is not null then 'completa' when i.importacion_id is not null then 'basica' else 'sin_ficha' end as tipo_ficha,f.inicio_elaboracion,f.procedencia_registro,i.importacion_id,i.importado_por,
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
CREATE OR REPLACE FUNCTION public.recompute_autor_resumen(p_autor_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_alcance text;
	v_perfil jsonb;
	v_perfil_hijos jsonb;
	v_total integer;
	v_n_obras integer;
	v_n_jorn integer;
	v_ne_medio double precision;
	v_ne_agg double precision;
	v_n_units integer;
begin
	foreach v_alcance in array array['publico', 'completo'] loop
		with units as (
			select u.scope, u.obra_id, u.jornada_v_ini, u.jornada_v_fin
			from public.perfil_metrico_unidades() u
			where u.autor_id = p_autor_id
		), elig as (
			select un.*
			from units un
			join public.obras_editoriales o on o.obra_id = un.obra_id
			join public.vocabularios v
				on v.termino_id = o.estado
				and v.categoria = 'estado'
				and lower(v.termino) = 'publicado'
			where v_alcance = 'completo' or coalesce(o.visible_publico, false)
		), unit_perfil as (
			select
				e.scope,
				public.perfil_artefacto_obra_rango(
					e.obra_id,
					case when e.scope = 'obra' then null else e.jornada_v_ini end,
					case when e.scope = 'obra' then null else e.jornada_v_fin end,
					'forma'
				) as perfil,
				public.perfil_artefacto_obra_rango(
					e.obra_id,
					case when e.scope = 'obra' then null else e.jornada_v_ini end,
					case when e.scope = 'obra' then null else e.jornada_v_fin end,
					'arquitectura'
				) as perfil_hijos,
				case when e.scope = 'obra' then r.numero_efectivo_formas else null end as ne_obra
			from elig e
			left join public.obras_resumen r on r.obra_id = e.obra_id
		), unit_calc as (
			select
				up.*,
				coalesce((select sum(value::integer) from jsonb_each_text(up.perfil)), 0) as versos
			from unit_perfil up
		), perfil_pairs as (
			select kv.key as forma, sum(kv.value::integer) as versos
			from unit_calc uc cross join lateral jsonb_each_text(uc.perfil) kv
			group by kv.key
		), perfil_pairs_hijos as (
			select kv.key as forma, sum(kv.value::integer) as versos
			from unit_calc uc cross join lateral jsonb_each_text(uc.perfil_hijos) kv
			group by kv.key
		), agg as (
			select
				coalesce(jsonb_object_agg(forma, versos), '{}'::jsonb) as perfil_agg,
				coalesce(sum(versos), 0)::integer as total_versos
			from perfil_pairs
		), agg_hijos as (
			select coalesce(jsonb_object_agg(forma, versos), '{}'::jsonb) as perfil_hijos_agg
			from perfil_pairs_hijos
		), counts as (
			select
				count(*) filter (where scope = 'obra')::integer as n_obras,
				count(*) filter (where scope = 'jornada')::integer as n_jorn,
				avg(ne_obra) filter (where scope = 'obra') as ne_medio,
				count(*)::integer as n_units
			from unit_calc
		)
		select
			a.perfil_agg, ah.perfil_hijos_agg, a.total_versos,
			c.n_obras, c.n_jorn, c.ne_medio, c.n_units
		into v_perfil, v_perfil_hijos, v_total, v_n_obras, v_n_jorn, v_ne_medio, v_n_units
		from agg a cross join agg_hijos ah cross join counts c;

		if coalesce(v_n_units, 0) = 0 then
			delete from public.autores_resumen
			where autor_id = p_autor_id and alcance = v_alcance;
		else
			v_ne_agg := public.numero_efectivo_from_perfil(v_perfil);

			insert into public.autores_resumen (
				autor_id, alcance,
				n_obras_completas, n_jornadas_sueltas, total_versos_autor,
				perfil_formas, perfil_formas_hijos,
				numero_efectivo_formas_medio, numero_efectivo_formas_agregado,
				metrica_sucia, actualizado_en
			) values (
				p_autor_id, v_alcance,
				coalesce(v_n_obras, 0), coalesce(v_n_jorn, 0), coalesce(v_total, 0),
				coalesce(v_perfil, '{}'::jsonb), coalesce(v_perfil_hijos, '{}'::jsonb),
				v_ne_medio, v_ne_agg, false, now()
			)
			on conflict (autor_id, alcance) do update set
				n_obras_completas = excluded.n_obras_completas,
				n_jornadas_sueltas = excluded.n_jornadas_sueltas,
				total_versos_autor = excluded.total_versos_autor,
				perfil_formas = excluded.perfil_formas,
				perfil_formas_hijos = excluded.perfil_formas_hijos,
				numero_efectivo_formas_medio = excluded.numero_efectivo_formas_medio,
				numero_efectivo_formas_agregado = excluded.numero_efectivo_formas_agregado,
				metrica_sucia = false,
				actualizado_en = now();
		end if;
	end loop;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.recompute_all()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_obra_id uuid;
	v_autor_id uuid;
	v_publicado_id uuid;
begin
	select termino_id into v_publicado_id
	from public.vocabularios
	where categoria = 'estado' and lower(termino) = 'publicado'
	limit 1;

	if v_publicado_id is null then raise exception 'No existe estado=publicado en vocabularios'; end if;

	for v_obra_id in select obra_id from public.obras_editoriales where estado = v_publicado_id loop
		perform public.recompute_obra_resumen(v_obra_id);
		perform public.recompute_artefactos_obra(v_obra_id);
	end loop;
	for v_autor_id in select distinct autor_id from public.perfil_metrico_unidades() where autor_id is not null loop
		perform public.recompute_autor_resumen(v_autor_id);
		perform public.recompute_artefactos_autor(v_autor_id);
	end loop;
	delete from public.autores_resumen ar
	where not exists (select 1 from public.perfil_metrico_unidades() u where u.autor_id = ar.autor_id);
	perform public.recompute_artefactos_globales();
end;
$function$
;
CREATE OR REPLACE FUNCTION public.secuencia_respeta_lo_declarado_en_la_obra()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
	v_obra public.obras_editoriales%rowtype;
begin
	select * into v_obra from public.obras_editoriales where obra_id = new.obra_id;
	if not found then
		return new;
	end if;

	if v_obra.sin_figuras_donaire
	   and new.intervencion_figuras_donaire in ('exclusiva', 'compartida') then
		raise exception 'La obra está marcada como que no tiene figuras de donaire: quita la marca antes de anotarlo en la secuencia.'
			using errcode = 'check_violation';
	end if;

	if v_obra.sin_personajes_sobrenaturales
	   and new.intervencion_personajes_sobrenaturales in ('exclusiva', 'compartida') then
		raise exception 'La obra está marcada como que no tiene personajes sobrenaturales: quita la marca antes de anotarlo en la secuencia.'
			using errcode = 'check_violation';
	end if;

	if v_obra.sin_eventos_sobrenaturales and new.evento_sobrenatural then
		raise exception 'La obra está marcada como que no tiene eventos sobrenaturales: quita la marca antes de anotarlo en la secuencia.'
			using errcode = 'check_violation';
	end if;

	return new;
end
$function$
;
CREATE OR REPLACE FUNCTION public.autor_ficha_artefacto_json(p_autor_id uuid, p_alcance text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_autor public.autores%rowtype;
	v_resumen public.autores_resumen%rowtype;
	v_publicado_id uuid;
	v_obras jsonb;
begin
	if p_alcance not in ('publico', 'completo') then
		raise exception 'Alcance desconocido: %', p_alcance;
	end if;

	select * into v_autor from public.autores where autor_id = p_autor_id;
	select * into v_resumen
	from public.autores_resumen
	where autor_id = p_autor_id and alcance = p_alcance;
	if v_autor.autor_id is null or v_resumen.autor_id is null then
		return null;
	end if;

	select termino_id into v_publicado_id
	from public.vocabularios
	where categoria = 'estado' and lower(termino) = 'publicado'
	limit 1;

	with autor_links as (
		select
			coalesce(g.obra_id, j.obra_id) as obra_id,
			a.perfil_metrico,
			coalesce(vc.termino, 'individual') as composicion_term,
			case when g.jornada_id is null then 'obra' else 'jornada' end as scope,
			j.jornada_num,
			(select count(*) from public.atribuciones a2
				where a2.grupo_atribucion_id = a.grupo_atribucion_id) as n_prop_grupo
		from public.atribucion_autores aa
		join public.atribuciones a on a.atribucion_id = aa.atribucion_id
		join public.grupos_atribucion g on g.grupo_atribucion_id = a.grupo_atribucion_id
		left join public.jornadas j on j.jornada_id = g.jornada_id
		left join public.vocabularios vc on vc.termino_id = a.composicion_autoria_id
		where aa.autor_id = p_autor_id
	), obras_elegibles as (
		select distinct al.obra_id
		from autor_links al
		join public.obras_editoriales o on o.obra_id = al.obra_id
		where o.estado = v_publicado_id
			and (p_alcance = 'completo' or coalesce(o.visible_publico, false))
	), perfil_obras as (
		select distinct u.obra_id
		from public.perfil_metrico_unidades() u
		where u.autor_id = p_autor_id
	), items as (
		select
			o.fecha_inicio_trad as sort_fecha,
			lower(o.titulo) as sort_titulo,
			jsonb_build_object(
				'obra_id', o.obra_id,
				'slug', o.slug,
				'titulo', o.titulo,
				'genero_term', (select vg.termino from public.vocabularios vg
					where vg.termino_id = o.genero_id limit 1),
				'fecha_inicio_trad', o.fecha_inicio_trad,
				'fecha_fin_trad', o.fecha_fin_trad,
				'total_versos', coalesce(r.total_versos, o.total_versos),
				'visible_publico', coalesce(o.visible_publico, false),
				'tramos', coalesce(r.tramos, '[]'::jsonb),
				'jornadas_tramos', coalesce(r.jornadas_tramos, '[]'::jsonb),
				'cuadros_tramos', coalesce(r.cuadros_tramos, '[]'::jsonb),
				'numero_efectivo_formas', r.numero_efectivo_formas,
				'densidad_transiciones', r.densidad_transiciones,
				'n_formas_distintas', r.n_formas_distintas,
				'sostiene_perfil', po.obra_id is not null,
				'vinculos', (
					select coalesce(jsonb_agg(distinct jsonb_build_object(
						'scope', al.scope,
						'jornada_num', al.jornada_num,
						'composicion_term', al.composicion_term,
						'perfil_metrico', al.perfil_metrico,
						'unica_propuesta', al.n_prop_grupo = 1
					)), '[]'::jsonb)
					from autor_links al where al.obra_id = o.obra_id
				)
			) as item
		from obras_elegibles oe
		join public.obras_editoriales o on o.obra_id = oe.obra_id
		left join public.obras_resumen r on r.obra_id = o.obra_id
		left join perfil_obras po on po.obra_id = o.obra_id
	)
	select coalesce(jsonb_agg(item order by sort_fecha nulls last, sort_titulo), '[]'::jsonb)
	into v_obras
	from items;

	return jsonb_build_object(
		'schema_version', 1,
		'alcance', p_alcance,
		'autor', jsonb_build_object(
			'autor_id', v_autor.autor_id,
			'slug', v_autor.slug,
			'nombre_completo', v_autor.nombre_completo,
			'variantes_nombre', coalesce(v_autor.variantes_nombre, array[]::text[]),
			'viaf_id', v_autor.viaf_id,
			'wikidata_id', v_autor.wikidata_id,
			'bnedatos_id', v_autor.bnedatos_id
		),
		'obras', v_obras,
		'resumen', jsonb_build_object(
			'n_obras_completas', v_resumen.n_obras_completas,
			'n_jornadas_sueltas', v_resumen.n_jornadas_sueltas,
			'total_versos_autor', v_resumen.total_versos_autor,
			'perfil_formas', v_resumen.perfil_formas,
			'perfil_formas_hijos', v_resumen.perfil_formas_hijos,
			'numero_efectivo_formas_medio', v_resumen.numero_efectivo_formas_medio,
			'numero_efectivo_formas_agregado', v_resumen.numero_efectivo_formas_agregado
		)
	);
end;
$function$
;
CREATE OR REPLACE FUNCTION public.get_obra_ficha_publica_base_without_slugs(p_obra_id uuid, p_include_hidden boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
	if not exists (
		select 1
		from public.obras_editoriales o
		where o.obra_id = p_obra_id
			and public.can_view_obra_ficha_publica(o.obra_id, p_include_hidden)
	) then
		return null;
	end if;

	return public.ficha_publica_json(p_obra_id, p_include_hidden);
end;
$function$
;
CREATE OR REPLACE FUNCTION public.ficha_publica_base_json(p_obra_id uuid, p_include_hidden boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_obra public.obras_editoriales%rowtype;
begin
 if exists(select 1 from public.obras_editoriales where obra_id=p_obra_id and tipo_ficha='basica') then
  raise exception using errcode='42501',message='La ficha básica requiere el productor combinado, todavía no habilitado';
 end if; /* importador:aislado */
	select o.*
	into v_obra
	from public.obras_editoriales o
	where o.obra_id = p_obra_id
	limit 1;

	if not found then
		return null;
	end if;

	return (
		with jornadas_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'jornada_id', j.jornada_id,
						'jornada_num', j.jornada_num,
						'v_ini', j.v_ini,
						'v_fin', j.v_fin
					)
					order by j.jornada_num
				),
				'[]'::jsonb
			) as items
			from public.jornadas j
			where j.obra_id = v_obra.obra_id
		),
		cuadros_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'cuadro_id', c.cuadro_id,
						'jornada_id', c.jornada_id,
						'cuadro_num', c.cuadro_num,
						'v_ini', c.v_ini,
						'v_fin', c.v_fin
					)
					order by j.jornada_num, c.cuadro_num
				),
				'[]'::jsonb
			) as items
			from public.cuadros c
			join public.jornadas j on j.jornada_id = c.jornada_id
			where j.obra_id = v_obra.obra_id
		),
		grupos_base as (
			select
				g.grupo_atribucion_id,
				g.obra_id as obra_ref_id,
				g.jornada_id,
				j.jornada_num,
				g.created_at
			from public.grupos_atribucion g
			left join public.jornadas j on j.jornada_id = g.jornada_id
			where coalesce(g.obra_id, j.obra_id) = v_obra.obra_id
		),
		propuestas_base as (
			select
				a.atribucion_id,
				a.grupo_atribucion_id,
				a.composicion_autoria_id,
				coalesce(vc.etiqueta, vc.termino, 'individual') as composicion_autoria_term,
				a.created_at
			from public.atribuciones a
			join grupos_base gb on gb.grupo_atribucion_id = a.grupo_atribucion_id
			left join public.vocabularios vc on vc.termino_id = a.composicion_autoria_id
		),
		autoria_autores_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'autor_id', t.autor_id,
						'nombre_completo', t.nombre_completo
					)
					order by t.nombre_completo
				),
				'[]'::jsonb
			) as items
			from (
				select distinct au.autor_id, au.nombre_completo
				from grupos_base gb
				join propuestas_base pb on pb.grupo_atribucion_id = gb.grupo_atribucion_id
				join public.atribucion_autores aa on aa.atribucion_id = pb.atribucion_id
				join public.autores au on au.autor_id = aa.autor_id
				where gb.jornada_id is null
					and (
						select count(*)
						from propuestas_base pb_count
						where pb_count.grupo_atribucion_id = gb.grupo_atribucion_id
					) = 1
			) t
		),
		grupos_autoria_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'grupo_atribucion_id', gb.grupo_atribucion_id,
						'scope', case when gb.jornada_id is null then 'obra' else 'jornada' end,
						'obra_id', gb.obra_ref_id,
						'jornada_id', gb.jornada_id,
						'jornada_num', gb.jornada_num,
						'propuestas', coalesce(prop.items, '[]'::jsonb)
					)
					order by case when gb.jornada_id is null then 0 else 1 end, coalesce(gb.jornada_num, 0), gb.created_at
				),
				'[]'::jsonb
			) as items
			from grupos_base gb
			left join lateral (
				select coalesce(
					jsonb_agg(
						jsonb_build_object(
							'atribucion_id', pb.atribucion_id,
							'composicion_autoria_id', pb.composicion_autoria_id,
							'composicion_autoria_term', pb.composicion_autoria_term,
							'autores', coalesce(aut.items, '[]'::jsonb),
							'evidencias', coalesce(evi.items, '[]'::jsonb)
						)
						order by pb.created_at, pb.atribucion_id
					),
					'[]'::jsonb
				) as items
				from propuestas_base pb
				left join lateral (
					select coalesce(
						jsonb_agg(
							jsonb_build_object(
								'autor_id', au.autor_id,
								'nombre_completo', au.nombre_completo
							)
							order by coalesce(aa.orden, 2147483647), au.nombre_completo
						),
						'[]'::jsonb
					) as items
					from public.atribucion_autores aa
					join public.autores au on au.autor_id = aa.autor_id
					where aa.atribucion_id = pb.atribucion_id
				) aut on true
				left join lateral (
					select coalesce(
						jsonb_agg(
							jsonb_build_object(
								'atribucion_evidencia_id', ae.atribucion_evidencia_id,
								'tipo_atribucion_id', ae.tipo_atribucion_id,
								'tipo_atribucion_term', coalesce(vt.etiqueta, vt.termino, 'sin_tipo'),
								'fuente_autoria', ae.fuente_autoria
							)
							order by coalesce(vt.termino, ''), ae.created_at, ae.atribucion_evidencia_id
						),
						'[]'::jsonb
					) as items
					from public.atribucion_evidencias ae
					left join public.vocabularios vt on vt.termino_id = ae.tipo_atribucion_id
					where ae.atribucion_id = pb.atribucion_id
				) evi on true
				where pb.grupo_atribucion_id = gb.grupo_atribucion_id
			) prop on true
		),
		caracterizaciones_by_secuencia as (
			select
				scr.secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'caracterizacion_rango_id', scr.caracterizacion_rango_id,
							'tipo_caracterizacion_rango_id', scr.tipo_caracterizacion_rango_id,
							'tipo_caracterizacion_rango_term', coalesce(tv.etiqueta, tv.termino, 'sin_tipo'),
							'v_ini', scr.v_ini,
							'v_fin', scr.v_fin,
							'observaciones', case when exists (
                                select 1 from public.traslados_observaciones_caracterizacion t
                                where t.caracterizacion_rango_id = scr.caracterizacion_rango_id
                              ) then null else scr.observaciones end
						)
						order by scr.v_ini, scr.v_fin, scr.caracterizacion_rango_id
					),
					'[]'::jsonb
				) as items
			from public.secuencias_caracterizaciones_rango scr
			join public.secuencias_metricas sm on sm.secuencia_id = scr.secuencia_id
			left join public.vocabularios tv on tv.termino_id = scr.tipo_caracterizacion_rango_id
			where sm.obra_id = v_obra.obra_id
			group by scr.secuencia_id
		),
		subtipos_by_secuencia as (
			-- **Los esquemas de una tirada se cuentan, no se enumeran.** El esquema de rima se responde
			-- una vez por estrofa, asi que una tirada de setenta y ocho redondillas traia setenta y ocho
			-- entradas y el codigo de barras se llenaba de rayas. Lo que dice algo es cuantas estrofas
			-- llevan cada disposicion: abba 64, abab 14. La clave conserva su nombre viejo porque es la
			-- que la ficha ya sabe pintar.
			select
				secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'subtipo_estrofa_id', esquema_rima_id,
							'subtipo_estrofa_term', nombre,
							'notacion', notacion,
							'unidades', unidades
						)
						order by unidades desc, nombre
					),
					'[]'::jsonb
				) as items
			from (
				select
					sm.secuencia_id,
					er.esquema_rima_id,
					coalesce(er.nombre, er.notacion, 'sin_subtipo') as nombre,
					er.notacion,
					count(*)::int as unidades
				from public.secuencias_metricas sm
				join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
				join public.anotacion_elecciones e on e.anotacion_id = a.anotacion_id
				join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
				where sm.obra_id = v_obra.obra_id
				group by sm.secuencia_id, er.esquema_rima_id, er.nombre, er.notacion
			) contados
			group by secuencia_id
		),
		rasgos_by_secuencia as (
			-- **Lo que se observo y no es la forma.** La asonancia de un romance, la densidad de rima de
			-- una silva, el distico final de una tirada de sueltos: respuestas de la anotacion que hasta
			-- hoy no salian de la base. Solo de asonancias hay cincuenta y siete que nadie veia.
			select
				sm.secuencia_id,
				coalesce(
					jsonb_agg(
						distinct jsonb_build_object(
							'rasgo_slug', rm.slug,
							'rasgo_term', rm.nombre,
							'valor_slug', rv.slug,
							'valor_term', rv.nombre
						)
					),
					'[]'::jsonb
				) as items
			from public.secuencias_metricas sm
			join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
			join public.anotacion_elecciones e on e.anotacion_id = a.anotacion_id
			join public.rasgo_valores rv on rv.valor_id = e.valor_rasgo_id
			join public.rasgos_metricos rm on rm.rasgo_id = rv.rasgo_id
			where sm.obra_id = v_obra.obra_id
			group by sm.secuencia_id
		),
		metros_by_secuencia as (
			-- La medida de los versos tal como se respondio, con cuantas estrofas la llevan.
			select
				secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object('metro_slug', slug, 'metro_term', nombre, 'unidades', unidades)
						order by unidades desc, nombre
					),
					'[]'::jsonb
				) as items
			from (
				select sm.secuencia_id, m.slug, m.nombre, count(*)::int as unidades
				from public.secuencias_metricas sm
				join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
				join public.anotacion_elecciones e on e.anotacion_id = a.anotacion_id
				join public.metros m on m.metro_id = e.metro_id
				where sm.obra_id = v_obra.obra_id
				group by sm.secuencia_id, m.slug, m.nombre
			) contados
			group by secuencia_id
		),
		desviaciones_by_secuencia as (
			-- **Lo que se aparta de la norma**: la laguna, el verso corto, la rima que no esta en el
			-- repertorio. Es de lo poco que el editor anota sobre lo que ve y no sobre lo que la forma
			-- prescribe, y tampoco llegaba a la ficha.
			select
				sm.secuencia_id,
				coalesce(
					jsonb_agg(
						jsonb_build_object(
							'dimension', d.dimension,
							'relacion_norma', d.relacion_norma,
							'v_ini', d.v_ini,
							'v_fin', d.v_fin,
							'observaciones', d.observaciones
						)
						order by d.v_ini
					),
					'[]'::jsonb
				) as items
			from public.secuencias_metricas sm
			join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
			join public.anotacion_desviaciones d on d.anotacion_id = a.anotacion_id
			where sm.obra_id = v_obra.obra_id
			group by sm.secuencia_id
		),
		secuencias_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'secuencia_id', sm.secuencia_id,
						'v_ini', sm.v_ini,
						'v_fin', sm.v_fin,
						'n_versos', sm.n_versos,
						'estrofa_tipo_id', fo.arquitectura_id,
						'estrofa_tipo_term', coalesce(fo.arquitectura_nombre, fo.forma_nombre, 'sin_estrofa'),
						'estrofa_forma_term', coalesce(fo.forma_nombre, 'sin_estrofa'),
						'estrofa_forma_slug', fo.forma_slug,
						'estrofa_tipo_forma', fo.tipo_forma,
						'inaugura_espacio', sm.inaugura_espacio,
						'versos_partidos', sm.versos_partidos,
						'intervencion_personajes_femeninos', sm.intervencion_personajes_femeninos,
						'generos_intervinientes', sm.generos_intervinientes,
						'intervencion_figuras_donaire', sm.intervencion_figuras_donaire,
						'intervencion_personajes_sobrenaturales', sm.intervencion_personajes_sobrenaturales,
						'evento_sobrenatural', sm.evento_sobrenatural,
						'sinopsis', sm.sinopsis,
						'jornada_id', jornada_ref.jornada_id,
						'jornada_num', jornada_ref.jornada_num,
						'cuadro_id', cuadro_ref.cuadro_id,
						'cuadro_num', cuadro_ref.cuadro_num,
						'cuadro_continua', cuadro_ref.v_fin is not null and sm.v_fin > cuadro_ref.v_fin,
						'caracterizaciones_rango', coalesce(cseq.items, '[]'::jsonb),
						'subtipos_estrofa', coalesce(sseq.items, '[]'::jsonb),
						'rasgos', coalesce(rseq.items, '[]'::jsonb),
						'metros', coalesce(mseq.items, '[]'::jsonb),
						'desviaciones', coalesce(dseq.items, '[]'::jsonb)
					)
					order by sm.v_ini
				),
				'[]'::jsonb
			) as items
			from public.secuencias_metricas sm
			left join public.formas_de_la_obra(v_obra.obra_id) fo on fo.secuencia_id = sm.secuencia_id
			-- **Una secuencia pertenece al cuadro donde empieza.** Antes se exigia que cupiera entera,
			-- y como el tablado se vacia muchas veces en mitad de una tirada -pasa en el 31 % de los
			-- cambios de cuadro de Fuente Ovejuna y de Peribanez-, esas secuencias se quedaban sin
			-- cuadro: nulos donde habia un dato. Que la tirada siga sonando despues del corte no es un
			-- problema que resolver, es lo que hay que poder medir, y para eso va `cuadro_continua`.
			left join lateral (
				select j.jornada_id, j.jornada_num
				from public.jornadas j
				where j.obra_id = sm.obra_id
					and sm.v_ini between j.v_ini and j.v_fin
				order by j.jornada_num
				limit 1
			) jornada_ref on true
			left join lateral (
				select c.cuadro_id, c.cuadro_num, c.v_fin
				from public.cuadros c
				where c.jornada_id = jornada_ref.jornada_id
					and sm.v_ini between c.v_ini and c.v_fin
				order by c.cuadro_num
				limit 1
			) cuadro_ref on true
			left join caracterizaciones_by_secuencia cseq on cseq.secuencia_id = sm.secuencia_id
			left join subtipos_by_secuencia sseq on sseq.secuencia_id = sm.secuencia_id
			left join rasgos_by_secuencia rseq on rseq.secuencia_id = sm.secuencia_id
			left join metros_by_secuencia mseq on mseq.secuencia_id = sm.secuencia_id
			left join desviaciones_by_secuencia dseq on dseq.secuencia_id = sm.secuencia_id
			where sm.obra_id = v_obra.obra_id
		),
		sinopsis_metrica_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'secuencia_id', sm.secuencia_id,
						'v_ini', sm.v_ini,
						'v_fin', sm.v_fin,
						'n_versos', sm.n_versos,
						'estrofa_tipo_id', fo.arquitectura_id,
						'estrofa_tipo_term', coalesce(fo.arquitectura_nombre, fo.forma_nombre, 'sin_estrofa'),
						-- **La forma nombra el pasaje; la arquitectura es el detalle.** La sinopsis rotulaba
						-- «Octosilabica consonante» donde tenia que decir «Quintilla», y no podia arreglarse
						-- en la pantalla porque este bloque no mandaba el nombre de la forma.
						'estrofa_forma_term', coalesce(fo.forma_nombre, 'sin_estrofa'),
						'estrofa_forma_slug', fo.forma_slug,
						'estrofa_tipo_forma', fo.tipo_forma,
						'sinopsis', sm.sinopsis
					)
					order by sm.v_ini
				),
				'[]'::jsonb
			) as items
			from public.secuencias_metricas sm
			left join public.formas_de_la_obra(v_obra.obra_id) fo on fo.secuencia_id = sm.secuencia_id
			where sm.obra_id = v_obra.obra_id
		),
		distribucion_base as (
			select
				coalesce(fo.forma_nombre, 'sin_estrofa') as forma,
				fo.forma_slug,
				fo.tipo_forma as forma_tipo_forma,
				sum(fo.n_versos)::int as versos
			from public.formas_de_la_obra(v_obra.obra_id) fo
			group by 1, 2, 3
		),
		distribucion_totales as (
			select coalesce(sum(d.versos), 0)::numeric as versos_totales
			from distribucion_base d
		),
		distribucion_json as (
			select coalesce(
				jsonb_agg(
					jsonb_build_object(
						'forma', d.forma,
						'forma_slug', d.forma_slug,
						'forma_tipo_forma', d.forma_tipo_forma,
						'versos', d.versos,
						'porcentaje',
							case
								when t.versos_totales > 0 then round((d.versos::numeric * 100.0) / t.versos_totales, 2)
								else 0
							end
					)
					order by d.versos desc, d.forma
				),
				'[]'::jsonb
			) as items
			from distribucion_base d
			cross join distribucion_totales t
		),
		comentarios_publicos_json as (
			select public.get_obra_comentarios_publicos(v_obra.obra_id, p_include_hidden) as items
		)
		select jsonb_build_object(
			'obra',
			jsonb_build_object(
				'obra_id', v_obra.obra_id,
				'titulo', v_obra.titulo,
				'variantes_titulo', coalesce(v_obra.variantes_titulo, '{}'::text[]),
				'fecha_inicio_trad', v_obra.fecha_inicio_trad,
				'fecha_fin_trad', v_obra.fecha_fin_trad,
				'fuente_fecha', v_obra.fuente_fecha,
				'genero_term', (
					select coalesce(vg.etiqueta, vg.termino)
					from public.vocabularios vg
					where vg.termino_id = v_obra.genero_id
					limit 1
				),
				'total_versos', v_obra.total_versos,
				'edicion', v_obra.edicion,
				'observaciones', v_obra.observaciones,
				'bibliografia', v_obra.bibliografia,
				'updated_at', v_obra.updated_at,
				'autor_ficha_publico', v_obra.autor_ficha_publico,
				'autor_ficha_email_publico', (
					select e.email
					from public.editores e
					where e.user_id = v_obra.editor_asignado
					limit 1
				),
				'autor_ficha_orcid_publico', (
					select e.orcid
					from public.editores e
					where e.user_id = v_obra.editor_asignado
					limit 1
				),
				'visible_publico', v_obra.visible_publico
			),
			'autoria',
			jsonb_build_object(
				'autores', (select items from autoria_autores_json),
				'grupos', (select items from grupos_autoria_json)
			),
			'estructura',
			jsonb_build_object(
				'jornadas', (select items from jornadas_json),
				'cuadros', (select items from cuadros_json)
			),
			'metrica',
			jsonb_build_object(
				'secuencias', (select items from secuencias_json),
				'distribucion_formas', (select items from distribucion_json)
			),
			'sinopsis_metrica',
			jsonb_build_object(
				'secuencias', (select items from sinopsis_metrica_json)
			),
			'comentarios_publicos',
			coalesce((select items from comentarios_publicos_json), '[]'::jsonb)
		)
	);
end;
$function$
;
CREATE OR REPLACE FUNCTION public.eliminar_ficha_basica(p_importacion uuid, p_confirmacion text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
 v_obra uuid; v_tipo text; v_editor uuid; v_titulo text; v_vigente boolean;
begin
 if not public.auth_is_admin_or_ip() or not public.auth_puede_importar_metrica() then
  raise exception using errcode='42501',message='Solo admin o IP pueden eliminar fichas básicas';
 end if;
 -- Bloqueo compartido con las operaciones que modifiquen el tipo o asignación de la obra.
 perform 1 from public.obras where obra_id=(select obra_id from public.importaciones_metricas where importacion_id=p_importacion) for update;
 select o.obra_id,o.tipo_ficha,o.editor_asignado,i.datos_confirmados#>>'{metadatos,titulo}',i.usada_en_corpus
 into v_obra,v_tipo,v_editor,v_titulo,v_vigente
 from public.importaciones_metricas i join public.obras_editoriales o using(obra_id)
 where i.importacion_id=p_importacion for update of i;
 if not found then raise exception using errcode='P0002',message='La ficha ya no está disponible'; end if;
 if v_tipo<>'basica' or not v_vigente or v_editor is not null then
  raise exception using errcode='23514',message='La obra ya no es una ficha básica disponible para eliminar';
 end if;
 if p_confirmacion is null or btrim(p_confirmacion)<>btrim(v_titulo) then
  raise exception using errcode='22023',message='Escribe el título de la obra para confirmar';
 end if;
 if exists(select 1 from public.secuencias_metricas s join public.anotaciones_metricas a using(secuencia_id) where s.obra_id=v_obra) then
  raise exception using errcode='23514',message='La obra contiene anotaciones detalladas y no puede eliminarse desde el importador';
 end if;
 -- Los FK eliminan en la misma transacción jornadas, secuencias e importaciones de esa obra.
 delete from public.obras_editoriales where obra_id=v_obra;
 return jsonb_build_object('eliminada',true,'obra_id',v_obra);
end;
$function$
;
CREATE OR REPLACE FUNCTION public.ficha_publica_dominio_json(p_obra_id uuid, p_include_hidden boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_payload jsonb;
	v_obra_slug text;
	v_author_slugs jsonb := '{}'::jsonb;
	v_sequence jsonb;
	v_sequences jsonb := '[]'::jsonb;
	v_synopsis_sequence jsonb;
	v_synopsis_sequences jsonb := '[]'::jsonb;
	v_sequence_id uuid;
	v_annotation_id uuid;
	v_architecture_slug text;
	v_rhyme_schemes jsonb;
	v_features jsonb;
	v_metres jsonb;
	v_varieties jsonb;
begin
 if exists(select 1 from public.obras_editoriales where obra_id=p_obra_id and tipo_ficha='basica') then
  raise exception using errcode='42501',message='La ficha básica requiere el productor combinado, todavía no habilitado';
 end if; /* importador:aislado */
	v_payload := public.ficha_publica_base_json(p_obra_id, p_include_hidden);

	if v_payload is null then
		return null;
	end if;

	select o.slug
	into v_obra_slug
	from public.obras_editoriales o
	where o.obra_id = p_obra_id;

	-- Una secuencia conserva una sola anotación efectiva: la primera por orden, igual que
	-- `formas_de_la_obra`. Las respuestas salen sin aplanar su realización ni su sección.
	for v_sequence in
		select value
		from jsonb_array_elements(coalesce(v_payload #> '{metrica,secuencias}', '[]'::jsonb))
	loop
		v_sequence_id := (v_sequence ->> 'secuencia_id')::uuid;
		v_annotation_id := null;
		v_architecture_slug := null;

		select a.anotacion_id, arq.slug
		into v_annotation_id, v_architecture_slug
		from public.anotaciones_metricas a
		left join public.arquitecturas_forma arq on arq.arquitectura_id = a.arquitectura_id
		where a.secuencia_id = v_sequence_id
		order by a.orden, a.created_at, a.anotacion_id
		limit 1;

		select coalesce(jsonb_agg(row_data order by realization_order nulls first, section_order nulls first, choice_created, choice_id), '[]'::jsonb)
		into v_rhyme_schemes
		from (
			select
				jsonb_build_object(
					'eleccion_id', e.eleccion_id,
					'esquema_rima_id', er.esquema_rima_id,
					'nombre', coalesce(er.nombre, case when nullif(btrim(e.valor_texto), '') is not null then 'Esquema observado' end),
					'notacion', coalesce(er.notacion, nullif(btrim(e.valor_texto), '')),
					'realizacion_id', r.realizacion_id,
					'realizacion_padre_id', r.realizacion_padre_id,
					'realizacion_orden', r.orden,
					'realizacion_v_ini', r.v_ini,
					'realizacion_v_fin', r.v_fin,
					'seccion_id', section_ref.seccion_id,
					'seccion_nombre', coalesce(section_ref.nombre, section_ref.slug),
					'seccion_orden', section_ref.orden,
					'posicion_unidad', e.posicion_unidad,
					'observaciones', e.observaciones
				) as row_data,
				r.orden as realization_order,
				section_ref.orden as section_order,
				e.created_at as choice_created,
				e.eleccion_id as choice_id
			from public.anotacion_elecciones_resueltas e
			left join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
			left join public.anotacion_realizaciones r on r.realizacion_id = e.realizacion_id
			left join public.estructuras_secciones section_ref
				on section_ref.seccion_id = coalesce(e.seccion_tratada_id, e.seccion_id, er.seccion_id)
			where e.anotacion_id = v_annotation_id
				and (
					e.esquema_rima_id is not null
					or (e.dimension = 'rima' and nullif(btrim(e.valor_texto), '') is not null)
				)
		) rows;

		select coalesce(jsonb_agg(row_data order by feature_name, feature_value, realization_order nulls first, choice_created, choice_id), '[]'::jsonb)
		into v_features
		from (
			select
				jsonb_build_object(
					'eleccion_id', e.eleccion_id,
					'rasgo_slug', rm.slug,
					'rasgo_nombre', rm.nombre,
					'valor_slug', rv.slug,
					'valor_nombre', rv.nombre,
					'realizacion_id', r.realizacion_id,
					'realizacion_padre_id', r.realizacion_padre_id,
					'realizacion_orden', r.orden,
					'realizacion_v_ini', r.v_ini,
					'realizacion_v_fin', r.v_fin,
					'seccion_id', section_ref.seccion_id,
					'seccion_nombre', coalesce(section_ref.nombre, section_ref.slug),
					'seccion_orden', section_ref.orden,
					'observaciones', e.observaciones
				) as row_data,
				rm.nombre as feature_name,
				rv.nombre as feature_value,
				r.orden as realization_order,
				e.created_at as choice_created,
				e.eleccion_id as choice_id
			from public.anotacion_elecciones_resueltas e
			join public.rasgo_valores rv on rv.valor_id = e.valor_rasgo_id
			join public.rasgos_metricos rm on rm.rasgo_id = rv.rasgo_id
			left join public.anotacion_realizaciones r on r.realizacion_id = e.realizacion_id
			left join public.estructuras_secciones section_ref
				on section_ref.seccion_id = coalesce(e.seccion_tratada_id, e.seccion_id)
			where e.anotacion_id = v_annotation_id
		) rows;

		select coalesce(jsonb_agg(row_data order by metre_name, realization_order nulls first, choice_created, choice_id), '[]'::jsonb)
		into v_metres
		from (
			select
				jsonb_build_object(
					'eleccion_id', e.eleccion_id,
					'metro_id', m.metro_id,
					'metro_slug', m.slug,
					'metro_nombre', m.nombre,
					'realizacion_id', r.realizacion_id,
					'realizacion_padre_id', r.realizacion_padre_id,
					'realizacion_orden', r.orden,
					'realizacion_v_ini', r.v_ini,
					'realizacion_v_fin', r.v_fin,
					'seccion_id', section_ref.seccion_id,
					'seccion_nombre', coalesce(section_ref.nombre, section_ref.slug),
					'seccion_orden', section_ref.orden,
					'posicion_unidad', e.posicion_unidad,
					'observaciones', e.observaciones
				) as row_data,
				m.nombre as metre_name,
				r.orden as realization_order,
				e.created_at as choice_created,
				e.eleccion_id as choice_id
			from public.anotacion_elecciones_resueltas e
			join public.metros m on m.metro_id = e.metro_id
			left join public.anotacion_realizaciones r on r.realizacion_id = e.realizacion_id
			left join public.estructuras_secciones section_ref
				on section_ref.seccion_id = coalesce(e.seccion_tratada_id, e.seccion_id)
			where e.anotacion_id = v_annotation_id
		) rows;

		select coalesce(jsonb_agg(row_data order by variety_order nulls last, variety_name, realization_order nulls first, choice_created, choice_id), '[]'::jsonb)
		into v_varieties
		from (
			select
				jsonb_build_object(
					'eleccion_id', e.eleccion_id,
					'variedad_id', va.variedad_id,
					'variedad_slug', va.slug,
					'variedad_nombre', va.nombre,
					'realizacion_id', r.realizacion_id,
					'realizacion_padre_id', r.realizacion_padre_id,
					'realizacion_orden', r.orden,
					'realizacion_v_ini', r.v_ini,
					'realizacion_v_fin', r.v_fin,
					'observaciones', e.observaciones
				) as row_data,
				va.orden as variety_order,
				va.nombre as variety_name,
				r.orden as realization_order,
				e.created_at as choice_created,
				e.eleccion_id as choice_id
			from public.anotacion_elecciones_resueltas e
			join public.variedades_arquitectura va on va.variedad_id = e.variedad_id
			left join public.anotacion_realizaciones r on r.realizacion_id = e.realizacion_id
			where e.anotacion_id = v_annotation_id
		) rows;

		v_sequence :=
			v_sequence
				- 'estrofa_tipo_id'
				- 'estrofa_tipo_term'
				- 'estrofa_forma_term'
				- 'estrofa_forma_slug'
				- 'estrofa_tipo_forma'
				- 'subtipos_estrofa'
				- 'rasgos'
				- 'metros'
			|| jsonb_build_object(
				'forma_nombre', v_sequence ->> 'estrofa_forma_term',
				'forma_slug', v_sequence -> 'estrofa_forma_slug',
				'tipo_forma', v_sequence -> 'estrofa_tipo_forma',
				'arquitectura_id', v_sequence -> 'estrofa_tipo_id',
				'arquitectura_slug', to_jsonb(v_architecture_slug),
				'arquitectura_nombre', v_sequence ->> 'estrofa_tipo_term',
				'esquemas_rima', v_rhyme_schemes,
				'rasgos', v_features,
				'metros', v_metres,
				'variedades', v_varieties
			);

		v_sequences := v_sequences || jsonb_build_array(v_sequence);
	end loop;

	v_payload := jsonb_set(v_payload, '{metrica,secuencias}', v_sequences, true);

	-- La sinopsis usa el mismo vocabulario actual, aunque no necesita las respuestas métricas.
	for v_synopsis_sequence in
		select value
		from jsonb_array_elements(coalesce(v_payload #> '{sinopsis_metrica,secuencias}', '[]'::jsonb))
	loop
		v_synopsis_sequence :=
			v_synopsis_sequence
				- 'estrofa_tipo_id'
				- 'estrofa_tipo_term'
				- 'estrofa_forma_term'
				- 'estrofa_forma_slug'
				- 'estrofa_tipo_forma'
			|| jsonb_build_object(
				'forma_nombre', coalesce(v_synopsis_sequence ->> 'estrofa_forma_term', v_synopsis_sequence ->> 'estrofa_tipo_term'),
				'forma_slug', v_synopsis_sequence -> 'estrofa_forma_slug',
				'tipo_forma', v_synopsis_sequence -> 'estrofa_tipo_forma',
				'arquitectura_id', v_synopsis_sequence -> 'estrofa_tipo_id',
				'arquitectura_nombre', v_synopsis_sequence ->> 'estrofa_tipo_term'
			);

		v_synopsis_sequences := v_synopsis_sequences || jsonb_build_array(v_synopsis_sequence);
	end loop;

	v_payload := jsonb_set(v_payload, '{sinopsis_metrica,secuencias}', v_synopsis_sequences, true);

	select coalesce(jsonb_object_agg(a.autor_id::text, a.slug), '{}'::jsonb)
	into v_author_slugs
	from public.autores a
	where exists (
		select 1
		from (
			select (author_item->>'autor_id')::uuid as autor_id
			from jsonb_path_query(v_payload, '$.autoria.autores[*]') as top_authors(author_item)
			where author_item ? 'autor_id'
			union
			select (author_item->>'autor_id')::uuid as autor_id
			from jsonb_path_query(v_payload, '$.autoria.grupos[*].propuestas[*].autores[*]') as nested_authors(author_item)
			where author_item ? 'autor_id'
		) ids
		where ids.autor_id = a.autor_id
	);

	v_payload := jsonb_set(v_payload, '{obra,slug}', to_jsonb(v_obra_slug), true);

	v_payload := jsonb_set(
		v_payload,
		'{autoria,autores}',
		coalesce(
			(
				select jsonb_agg(
					author_item || jsonb_build_object(
						'slug', coalesce(v_author_slugs ->> (author_item->>'autor_id'), '')
					)
					order by author_ord
				)
				from jsonb_array_elements(coalesce(v_payload #> '{autoria,autores}', '[]'::jsonb))
					with ordinality as author_rows(author_item, author_ord)
			),
			'[]'::jsonb
		),
		true
	);

	v_payload := jsonb_set(
		v_payload,
		'{autoria,grupos}',
		coalesce(
			(
				select jsonb_agg(
					group_item || jsonb_build_object(
						'propuestas',
						coalesce(
							(
								select jsonb_agg(
									proposal_item || jsonb_build_object(
										'autores',
										coalesce(
											(
												select jsonb_agg(
													author_item || jsonb_build_object(
														'slug', coalesce(v_author_slugs ->> (author_item->>'autor_id'), '')
													)
													order by author_ord
												)
												from jsonb_array_elements(coalesce(proposal_item->'autores', '[]'::jsonb))
													with ordinality as author_rows(author_item, author_ord)
											),
											'[]'::jsonb
										)
									)
									order by proposal_ord
								)
								from jsonb_array_elements(coalesce(group_item->'propuestas', '[]'::jsonb))
									with ordinality as proposal_rows(proposal_item, proposal_ord)
							),
							'[]'::jsonb
						)
					)
					order by group_ord
				)
				from jsonb_array_elements(coalesce(v_payload #> '{autoria,grupos}', '[]'::jsonb))
					with ordinality as group_rows(group_item, group_ord)
			),
			'[]'::jsonb
		),
		true
	);

	return v_payload;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.next_obras_slug(base text, current_obra_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
	v_base text := coalesce(nullif(public.metadrama_slugify(base), ''), 'obra');
	v_candidate text := v_base;
	v_suffix integer := 2;
begin
	loop
		if not exists (
			select 1
			from public.obras_editoriales o
			where o.slug = v_candidate
				and (current_obra_id is null or o.obra_id <> current_obra_id)
		) then
			return v_candidate;
		end if;

		v_candidate := v_base || '-' || v_suffix::text;
		v_suffix := v_suffix + 1;
	end loop;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.get_equipo_publico()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
	select coalesce(
		jsonb_agg(
			jsonb_build_object(
				'nombre_completo', equipo.nombre_completo,
				'orcid', equipo.orcid,
				'total_obras', equipo.total_obras,
				'obras', equipo.obras
			)
			order by equipo.total_obras desc, lower(equipo.nombre_completo), equipo.nombre_completo
		),
		'[]'::jsonb
	)
	from (
		select
			e.nombre_completo,
			e.orcid,
			count(o.obra_id)::integer as total_obras,
			coalesce(
				jsonb_agg(
					jsonb_build_object(
						'titulo', o.titulo,
						'slug', o.slug
					)
					order by lower(o.titulo), o.titulo
				) filter (where o.obra_id is not null),
				'[]'::jsonb
			) as obras
		from public.editores e
		join public.vocabularios rol on rol.termino_id = e.role
		left join public.obras_editoriales o
			on o.editor_asignado = e.user_id
			and o.visible_publico is true
		where rol.categoria = 'role_editor'
			and lower(rol.termino) = 'editor'
			and coalesce(e.activo, true)
			and lower(trim(e.nombre_completo)) <> 'sin asignar'
		group by e.user_id, e.nombre_completo, e.orcid
	) equipo;
$function$
;
CREATE OR REPLACE FUNCTION public.recompute_obra_resumen_metricas(p_obra_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_total_versos              int;
  v_n_secuencias              int;
  v_n_jornadas                int;
  v_tramos                    jsonb;
  v_perfil_formas             jsonb;
  v_formas_presentes          text[];
  v_tipos_forma_presentes     text[];
  v_metros_presentes          text[];
  v_variaciones_presentes     text[];
  v_subtipos_presentes        text[];
  v_n_formas_distintas        int;
  v_numero_efectivo_formas    float;
  v_p_max                     float;
  v_densidad_transiciones     float;
  v_pct_cantado               float;
  v_tiene_versos_partidos     boolean;
  v_tiene_cambio_espacio      boolean;
  v_intervencion_femenina     text;
  v_intervencion_donaire      text;
  v_intervencion_sobrenaturales text;
  v_tiene_evento_sobrenatural boolean;
  v_ficha                     jsonb;
  v_autores                   text[];
begin
 if exists(select 1 from public.obras_editoriales where obra_id=p_obra_id and tipo_ficha='basica') then
  raise exception using errcode='42501',message='La ficha básica requiere el productor combinado, todavía no habilitado';
 end if; /* importador:aislado */
  -- 1. Total versos y número de secuencias
  select
    coalesce(sum(sm.n_versos), 0)::int,
    count(*)::int
  into v_total_versos, v_n_secuencias
  from public.secuencias_metricas sm
  where sm.obra_id = p_obra_id;

  -- 2. Número de jornadas
  select count(*)::int
  into v_n_jornadas
  from public.jornadas j
  where j.obra_id = p_obra_id;

  -- 3. Tramos fusionados y perfil de formas
  with seq_formas as (
    select
      fo.v_ini,
      fo.v_fin,
      fo.n_versos,
      fo.forma_slug,
      fo.tipo_forma,
      row_number() over (order by fo.v_ini) as rn
    from public.formas_de_la_obra(p_obra_id) fo
  ),
  island_groups as (
    select *,
      rn - row_number() over (partition by forma_slug order by rn) as grp
    from seq_formas
  ),
  merged_tramos as (
    select
      forma_slug,
      tipo_forma,
      min(v_ini) as v_ini,
      max(v_fin)  as v_fin
    from island_groups
    group by forma_slug, tipo_forma, grp
  ),
  perfil as (
    -- **Una secuencia sin forma no entra en el reparto.** Hoy son las 92 obras del corpus legado, y
    -- una clave nula no cabe en un objeto: `jsonb_object_agg` lo rechaza y se lleva el recompute
    -- entero por delante. El barcode sí las conserva, porque ahí lo que se dibuja es el pasaje.
    select forma_slug, sum(n_versos)::int as n_versos
    from seq_formas
    where forma_slug is not null
    group by forma_slug
  )
  select
    (select coalesce(
        jsonb_agg(
          jsonb_build_object('i', v_ini, 'f', v_fin, 's', forma_slug, 't', tipo_forma)
          order by v_ini
        ),
        '[]'::jsonb
      ) from merged_tramos),
    (select coalesce(jsonb_object_agg(forma_slug, n_versos), '{}'::jsonb) from perfil)
  into v_tramos, v_perfil_formas;

  -- 4. Arrays de filtro: formas y tipos de forma
  select
    array_agg(distinct forma_slug) filter (where forma_slug is not null),
    array_agg(distinct tipo_forma) filter (where tipo_forma is not null)
  into v_formas_presentes, v_tipos_forma_presentes
  from public.formas_de_la_obra(p_obra_id) t;

  -- 5. Metros presentes.
  --
  -- **Salen de dos sitios y hay que sumarlos.** La medida de toda forma isosilábica es
  -- arquitectura y no se pregunta —una obra entera de redondillas no tendría ninguna respuesta de
  -- metro—, y donde sí se pregunta, la medida es lo que el editor eligió. Así que se unen lo que
  -- la arquitectura fija en sus esquemas y lo que la anotación responde.
  select array_agg(distinct slug) filter (where slug is not null)
  into v_metros_presentes
  from (
    select m.slug
    from public.anotaciones_metricas a
    join public.secuencias_metricas sm on sm.secuencia_id = a.secuencia_id
    join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
    join public.esquema_metrico_posiciones emp on emp.esquema_metrico_id = em.esquema_metrico_id
    join public.metros m on m.metro_id = emp.metro_id
    where sm.obra_id = p_obra_id

    union

    select m.slug
    from public.anotaciones_metricas a
    join public.secuencias_metricas sm on sm.secuencia_id = a.secuencia_id
    join public.anotacion_elecciones e on e.anotacion_id = a.anotacion_id
    join public.metros m on m.metro_id = e.metro_id
    where sm.obra_id = p_obra_id
  ) metros;

  -- 6. Variaciones presentes (caracterizacion_rango usados en secuencias de la obra)
  select array_agg(distinct v.termino) filter (where v.termino is not null)
  into v_variaciones_presentes
  from public.secuencias_metricas sm
  join public.secuencias_caracterizaciones_rango scr on scr.secuencia_id = sm.secuencia_id
  join public.vocabularios v on v.termino_id = scr.tipo_caracterizacion_rango_id
  where sm.obra_id = p_obra_id;

  -- 6b. Los esquemas de rima elegidos, que son el filtro que antes daban los subtipos de estrofa.
  --
  -- Las 379 filas de `secuencias_subtipos_estrofa` eran todas esquemas de quintilla: nombraban la
  -- disposición de la rima, que en el catálogo nuevo es una respuesta y no un término aparte.
  -- **La clave lleva la forma delante.** El slug del esquema no identifica uno: `abab` está en la
  -- redondilla, el cuarteto, el cuarteto-lira y el villancico, y `cdcdcd` nombra los tercetos del
  -- soneto. Sin la forma, filtrar por `abab` mezclaba obras que no comparten nada salvo la letra,
  -- y el selector no podía anidar cada esquema bajo la forma a la que pertenece. Mismo defecto y
  -- misma corrección que `perfil_formas_hijos` en `20260910130000`.
  select array_agg(distinct f.slug || '/' || er.slug) filter (where er.slug is not null)
  into v_subtipos_presentes
  from public.anotaciones_metricas a
  join public.secuencias_metricas sm on sm.secuencia_id = a.secuencia_id
  join public.anotacion_elecciones e on e.anotacion_id = a.anotacion_id
  join public.esquemas_rima er on er.esquema_rima_id = e.esquema_rima_id
  join public.arquitecturas_forma arq on arq.arquitectura_id = er.arquitectura_id
  join public.formas_metricas f on f.forma_id = arq.forma_id
  where sm.obra_id = p_obra_id;

  -- 7. n_formas_distintas y p_max
  select
    count(distinct forma_slug)::int,
    max(pct)
  into v_n_formas_distintas, v_p_max
  from (
    select
      fo.forma_slug,
      sum(fo.n_versos)::float / nullif(v_total_versos, 0) as pct
    from public.formas_de_la_obra(p_obra_id) fo
    group by fo.forma_slug
  ) forma_pcts;

  -- 8. Número efectivo de formas: exp(H) con H = −Σ p_i · ln(p_i)
  select exp(-sum(p_i * ln(nullif(p_i, 0))))
  into v_numero_efectivo_formas
  from (
    select sum(fo.n_versos)::float / nullif(v_total_versos, 0) as p_i
    from public.formas_de_la_obra(p_obra_id) fo
    where fo.forma_slug is not null
    group by fo.forma_slug
  ) proportions;

  -- 9. Densidad de transiciones
  v_densidad_transiciones := case
    when v_total_versos > 0 then (v_n_secuencias::float / v_total_versos) * 100
    else 0
  end;

  -- 10. % cantado (caracterizacion_rango = 'cantado')
  -- **En porcentaje, como dice su nombre.** Guardaba la fraccion -0,0077 para una obra con el
  -- 0,77 % cantado-, y nadie la leia todavia, asi que se corrige antes de que alguien la pinte.
  select coalesce(
    sum(scr.v_fin - scr.v_ini + 1)::float * 100 / nullif(v_total_versos, 0),
    0
  )
  into v_pct_cantado
  from public.secuencias_metricas sm
  join public.secuencias_caracterizaciones_rango scr
    on scr.secuencia_id = sm.secuencia_id
  join public.vocabularios vcant
    on vcant.termino_id = scr.tipo_caracterizacion_rango_id
   and vcant.categoria  = 'caracterizacion_rango'
   and vcant.termino    = 'cantado'
  where sm.obra_id = p_obra_id;

  -- 11. Flags booleanos
  select
    bool_or(coalesce(sm.versos_partidos,   false)),
    bool_or(coalesce(sm.inaugura_espacio,  false))
  into v_tiene_versos_partidos, v_tiene_cambio_espacio
  from public.secuencias_metricas sm
  where sm.obra_id = p_obra_id;

  -- 12. Intervenciones agregadas (enum real: sin_intervencion|exclusiva|compartida → mixta)
  select
    case
      when count(case when sm.intervencion_personajes_femeninos = 'exclusiva'  then 1 end) > 0
       and count(case when sm.intervencion_personajes_femeninos = 'compartida' then 1 end) > 0
      then 'mixta'
      when count(case when sm.intervencion_personajes_femeninos = 'exclusiva'  then 1 end) > 0
      then 'exclusiva'
      when count(case when sm.intervencion_personajes_femeninos = 'compartida' then 1 end) > 0
      then 'compartida'
      else 'sin_intervencion'
    end,
    case
      when count(case when sm.intervencion_figuras_donaire = 'exclusiva'  then 1 end) > 0
       and count(case when sm.intervencion_figuras_donaire = 'compartida' then 1 end) > 0
      then 'mixta'
      when count(case when sm.intervencion_figuras_donaire = 'exclusiva'  then 1 end) > 0
      then 'exclusiva'
      when count(case when sm.intervencion_figuras_donaire = 'compartida' then 1 end) > 0
      then 'compartida'
      else 'sin_intervencion'
    end,
    case
      when count(case when sm.intervencion_personajes_sobrenaturales = 'exclusiva'  then 1 end) > 0
       and count(case when sm.intervencion_personajes_sobrenaturales = 'compartida' then 1 end) > 0
      then 'mixta'
      when count(case when sm.intervencion_personajes_sobrenaturales = 'exclusiva'  then 1 end) > 0
      then 'exclusiva'
      when count(case when sm.intervencion_personajes_sobrenaturales = 'compartida' then 1 end) > 0
      then 'compartida'
      else 'sin_intervencion'
    end
  into v_intervencion_femenina, v_intervencion_donaire, v_intervencion_sobrenaturales
  from public.secuencias_metricas sm
  where sm.obra_id = p_obra_id;

  -- 13. UPSERT
  -- **La ficha se guarda entera.** Es la misma que devuelve `ficha_publica_json`, asi que el
  -- navegador puede cargarla de una vez en lugar de pedirle a la base que la construya en cada
  -- visita. Lo que aqui se guarda es **lo que ve un anonimo**: el permiso no es contenido, y lo que
  -- solo ven admin, IP o el editor asignado se resuelve aparte.
  select coalesce(sm.evento_sobrenatural, false)
  into v_tiene_evento_sobrenatural
  from public.secuencias_metricas sm
  where sm.obra_id = p_obra_id and sm.evento_sobrenatural
  limit 1;
  v_tiene_evento_sobrenatural := coalesce(v_tiene_evento_sobrenatural, false);

  v_ficha := public.ficha_publica_json(p_obra_id, false);

  -- **Quien firma la obra, para el listado.** El buscador lo reconstruia en vivo encadenando cuatro
  -- consultas -grupos, atribuciones, enlaces y autores- solo para poner el nombre bajo el titulo.
  --
  -- Cuenta **solo el grupo con una sola atribucion**, que es la misma regla que aplicaba el
  -- buscador: si de una obra se propone mas de una autoria, no hay un nombre que poner y se deja en
  -- blanco. Lo matizado -quien propone que, y con que grado de certeza- esta en la ficha.
  select coalesce(array_agg(distinct a.nombre_completo), '{}')
  into v_autores
  from public.grupos_atribucion g
  join public.atribuciones t on t.grupo_atribucion_id = g.grupo_atribucion_id
  join public.atribucion_autores aa on aa.atribucion_id = t.atribucion_id
  join public.autores a on a.autor_id = aa.autor_id
  where g.obra_id = p_obra_id
    and (
      select count(*) from public.atribuciones t2
      where t2.grupo_atribucion_id = g.grupo_atribucion_id
    ) = 1;

  insert into public.obras_resumen (
    obra_id,
    total_versos, n_secuencias, n_jornadas,
    n_formas_distintas, numero_efectivo_formas, p_max, densidad_transiciones,
    pct_cantado,
    tramos, perfil_formas,
    formas_presentes, metros_presentes, tipos_forma_presentes, variaciones_presentes,
    subtipos_presentes,
    tiene_versos_partidos, tiene_cambio_espacio,
    intervencion_femenina, intervencion_donaire, intervencion_sobrenaturales,
    tiene_evento_sobrenatural, ficha, autores,
    metrica_sucia, actualizado_en
  ) values (
    p_obra_id,
    v_total_versos, v_n_secuencias, v_n_jornadas,
    v_n_formas_distintas, v_numero_efectivo_formas, v_p_max, v_densidad_transiciones,
    v_pct_cantado,
    v_tramos, v_perfil_formas,
    v_formas_presentes, v_metros_presentes, v_tipos_forma_presentes, v_variaciones_presentes,
    v_subtipos_presentes,
    v_tiene_versos_partidos, v_tiene_cambio_espacio,
    v_intervencion_femenina, v_intervencion_donaire, v_intervencion_sobrenaturales,
    v_tiene_evento_sobrenatural, v_ficha, v_autores,
    false, now()
  )
  on conflict (obra_id) do update set
    tiene_evento_sobrenatural   = excluded.tiene_evento_sobrenatural,
    ficha                       = excluded.ficha,
    autores                     = excluded.autores,
    total_versos                = excluded.total_versos,
    n_secuencias                = excluded.n_secuencias,
    n_jornadas                  = excluded.n_jornadas,
    n_formas_distintas          = excluded.n_formas_distintas,
    numero_efectivo_formas      = excluded.numero_efectivo_formas,
    p_max                       = excluded.p_max,
    densidad_transiciones       = excluded.densidad_transiciones,
    pct_cantado                 = excluded.pct_cantado,
    tramos                      = excluded.tramos,
    perfil_formas               = excluded.perfil_formas,
    formas_presentes            = excluded.formas_presentes,
    metros_presentes            = excluded.metros_presentes,
    tipos_forma_presentes       = excluded.tipos_forma_presentes,
    variaciones_presentes       = excluded.variaciones_presentes,
    subtipos_presentes          = excluded.subtipos_presentes,
    tiene_versos_partidos       = excluded.tiene_versos_partidos,
    tiene_cambio_espacio        = excluded.tiene_cambio_espacio,
    intervencion_femenina       = excluded.intervencion_femenina,
    intervencion_donaire        = excluded.intervencion_donaire,
    intervencion_sobrenaturales = excluded.intervencion_sobrenaturales,
    metrica_sucia               = false,
    actualizado_en              = now();
end;
$function$
;
CREATE OR REPLACE FUNCTION public.obra_publica_visible(p_obra_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.obras_editoriales o
    join public.vocabularios v on v.termino_id = o.estado
    where o.obra_id = p_obra_id
      and v.categoria = 'estado'
      and lower(v.termino) = 'publicado'
      and coalesce(o.visible_publico, false) = true
  );
$function$
;
CREATE OR REPLACE FUNCTION public.obra_publicada_asignada(p_obra_id uuid, p_user uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  select exists (
    select 1
    from public.obras_editoriales o
    join public.vocabularios v on v.termino_id = o.estado
    where o.obra_id = p_obra_id
      and v.categoria = 'estado'
      and lower(v.termino) = 'publicado'
      and o.editor_asignado = p_user
  );
$function$
;
CREATE OR REPLACE FUNCTION public.recompute_obra_resumen_estructura(p_obra_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if exists(select 1 from public.obras_editoriales where obra_id=p_obra_id and tipo_ficha='basica') then
  raise exception using errcode='42501',message='La ficha básica requiere el productor combinado, todavía no habilitado';
 end if; /* importador:aislado */
  update public.obras_resumen
  set
    jornadas_tramos = (
      select coalesce(
        jsonb_agg(
          jsonb_build_object('i', j.v_ini, 'f', j.v_fin, 'n', j.jornada_num)
          order by j.v_ini, j.v_fin, j.jornada_num
        ),
        '[]'::jsonb
      )
      from public.jornadas j
      where j.obra_id = p_obra_id
    ),
    cuadros_tramos = (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'i', c.v_ini,
            'f', c.v_fin,
            'n', c.cuadro_num,
            'j', j.jornada_num
          )
          order by c.v_ini, c.v_fin, j.jornada_num, c.cuadro_num
        ),
        '[]'::jsonb
      )
      from public.cuadros c
      join public.jornadas j on j.jornada_id = c.jornada_id
      where j.obra_id = p_obra_id
    )
  where obra_id = p_obra_id;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.get_obra_ficha_publica(p_obra_id uuid, p_include_hidden boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
	if not exists (
		select 1
		from public.obras_editoriales o
		where o.obra_id = p_obra_id
			and public.can_view_obra_ficha_publica(o.obra_id, p_include_hidden)
	) then
		return null;
	end if;

	return public.ficha_publica_json(p_obra_id, p_include_hidden);
end;
$function$
;
CREATE OR REPLACE FUNCTION public.get_autores_listado_publico()
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  with adm as (select public.auth_is_admin_or_ip() as is_admin),
  -- Obras del perfil por autor (distinct), con versos y filtro de visibilidad por rol.
  autor_obras as (
    select distinct
      u.autor_id,
      o.obra_id,
      o.slug,
      o.titulo,
      coalesce(orr.total_versos, o.total_versos) as total_versos
    from public.perfil_metrico_unidades() u
    join public.obras_editoriales o on o.obra_id = u.obra_id
    join public.vocabularios ev
      on ev.termino_id = o.estado and ev.categoria = 'estado' and lower(ev.termino) = 'publicado'
    left join public.obras_resumen orr on orr.obra_id = o.obra_id
    cross join adm
    where adm.is_admin or coalesce(o.visible_publico, false)
  ),
  -- Top 5 por autor (por extensión).
  top_obras as (
    select autor_id,
      coalesce(jsonb_agg(
        jsonb_build_object('slug', slug, 'titulo', titulo, 'total_versos', total_versos)
        order by total_versos desc nulls last, titulo
      ), '[]'::jsonb) as items
    from (
      select autor_id, slug, titulo, total_versos,
        row_number() over (partition by autor_id order by total_versos desc nulls last, titulo) as rn
      from autor_obras
    ) ranked
    where rn <= 5
    group by autor_id
  )
  select coalesce(jsonb_agg(item order by nombre_norm), '[]'::jsonb)
  from (
    select
      lower(coalesce(a.nombre_normalizado, a.nombre_completo)) as nombre_norm,
      jsonb_build_object(
        'slug', a.slug,
        'nombre_completo', a.nombre_completo,
        'wikidata_id', a.wikidata_id,
        'total_versos_autor', ar.total_versos_autor,
        'n_obras_completas', ar.n_obras_completas,
        'n_jornadas_sueltas', ar.n_jornadas_sueltas,
        'numero_efectivo_formas_agregado', ar.numero_efectivo_formas_agregado,
        'perfil_formas', ar.perfil_formas,
        'top_obras', coalesce(t.items, '[]'::jsonb)
      ) as item
    from public.autores_resumen ar
    join public.autores a on a.autor_id = ar.autor_id
    left join top_obras t on t.autor_id = ar.autor_id
    where ar.alcance = case when (select is_admin from adm) then 'completo' else 'publico' end
  ) sub;
$function$
;
CREATE OR REPLACE FUNCTION public.get_autor_publico(p_slug text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_publicado_id uuid;
  v_autor public.autores%rowtype;
  v_admin boolean := public.auth_is_admin_or_ip();
begin
  select termino_id into v_publicado_id
  from public.vocabularios
  where categoria = 'estado' and lower(termino) = 'publicado'
  limit 1;
  if v_publicado_id is null then
    return null;
  end if;

  select * into v_autor from public.autores where slug = p_slug limit 1;
  if not found then
    return null;
  end if;

  return (
    with autor_links as (
      select
        coalesce(g.obra_id, j.obra_id) as obra_id,
        a.atribucion_id,
        a.perfil_metrico,
        coalesce(vc.termino, 'individual') as composicion_term,
        case when g.jornada_id is null then 'obra' else 'jornada' end as scope,
        j.jornada_num,
        (select count(*) from public.atribuciones a2
          where a2.grupo_atribucion_id = a.grupo_atribucion_id) as n_prop_grupo
      from public.atribucion_autores aa
      join public.atribuciones a on a.atribucion_id = aa.atribucion_id
      join public.grupos_atribucion g on g.grupo_atribucion_id = a.grupo_atribucion_id
      left join public.jornadas j on j.jornada_id = g.jornada_id
      left join public.vocabularios vc on vc.termino_id = a.composicion_autoria_id
      where aa.autor_id = v_autor.autor_id
    ),
    visible_obras as (
      select distinct al.obra_id
      from autor_links al
      join public.obras_editoriales o on o.obra_id = al.obra_id
      where o.estado = v_publicado_id
        and (v_admin or coalesce(o.visible_publico, false))
    ),
    perfil_obras as (
      select distinct u.obra_id
      from public.perfil_metrico_unidades() u
      where u.autor_id = v_autor.autor_id
    ),
    obras_json as (
      select coalesce(jsonb_agg(item order by sort_fecha nulls last, sort_titulo), '[]'::jsonb) as items
      from (
        select
          o.fecha_inicio_trad as sort_fecha,
          lower(o.titulo)     as sort_titulo,
          jsonb_build_object(
            'obra_id', o.obra_id,
            'slug', o.slug,
            'titulo', o.titulo,
            'genero_term', (select vg.termino from public.vocabularios vg
                            where vg.termino_id = o.genero_id limit 1),
            'fecha_inicio_trad', o.fecha_inicio_trad,
            'fecha_fin_trad', o.fecha_fin_trad,
            'total_versos', coalesce(orr.total_versos, o.total_versos),
            'visible_publico', coalesce(o.visible_publico, false),
            'tramos', coalesce(orr.tramos, '[]'::jsonb),
            'jornadas_tramos', coalesce(orr.jornadas_tramos, '[]'::jsonb),
            'cuadros_tramos', coalesce(orr.cuadros_tramos, '[]'::jsonb),
            'numero_efectivo_formas', orr.numero_efectivo_formas,
            'densidad_transiciones', orr.densidad_transiciones,
            'n_formas_distintas', orr.n_formas_distintas,
            'sostiene_perfil', (po.obra_id is not null),
            'vinculos', (
              select coalesce(jsonb_agg(distinct jsonb_build_object(
                'scope', al.scope,
                'jornada_num', al.jornada_num,
                'composicion_term', al.composicion_term,
                'perfil_metrico', al.perfil_metrico,
                'unica_propuesta', (al.n_prop_grupo = 1)
              )), '[]'::jsonb)
              from autor_links al
              where al.obra_id = o.obra_id
            )
          ) as item
        from visible_obras vo
        join public.obras_editoriales o on o.obra_id = vo.obra_id
        left join public.obras_resumen orr on orr.obra_id = o.obra_id
        left join perfil_obras po on po.obra_id = o.obra_id
      ) sub
    )
    select jsonb_build_object(
      'autor', jsonb_build_object(
        'autor_id', v_autor.autor_id,
        'slug', v_autor.slug,
        'nombre_completo', v_autor.nombre_completo,
        'variantes_nombre', coalesce(v_autor.variantes_nombre, '{}'::text[]),
        'viaf_id', v_autor.viaf_id,
        'wikidata_id', v_autor.wikidata_id,
        'bnedatos_id', v_autor.bnedatos_id
      ),
      'obras', (select items from obras_json)
    )
  );
end;
$function$
;
CREATE OR REPLACE FUNCTION public.can_view_obra_ficha_publica(p_obra_id uuid, p_include_hidden boolean DEFAULT false)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
	select exists (
		select 1
		from public.obras_editoriales o
		join public.vocabularios estado
			on estado.termino_id = o.estado
			and estado.categoria = 'estado'
		where o.obra_id = p_obra_id
			and (
				(
					lower(estado.termino) = 'publicado'
					and (
						coalesce(o.visible_publico, false)
						or (
							coalesce(p_include_hidden, false)
							and (
								public.auth_is_admin_or_ip()
								or (o.editor_asignado = auth.uid() and exists(select 1 from public.editores e where e.user_id=auth.uid() and coalesce(e.activo,true)))
							)
						)
					)
				)
				or (
					lower(estado.termino) in ('vista_previa', 'listo_para_publicar')
					and (
						public.auth_is_admin_or_ip()
						or (o.editor_asignado = auth.uid() and exists(select 1 from public.editores e where e.user_id=auth.uid() and coalesce(e.activo,true)))
					)
				)
			)
	);
$function$
;
CREATE OR REPLACE FUNCTION public.get_obra_comentarios_publicos(p_obra_id uuid, p_include_hidden boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
	select coalesce(
		jsonb_agg(
			jsonb_build_object(
				'comentario_id', ci.comentario_id,
				'comentario', ci.comentario,
				'created_at', ci.created_at,
				'seccion', ci.seccion,
				'secuencia_id', ci.secuencia_id,
				'jornada_id', ci.jornada_id,
				'cuadro_id', ci.cuadro_id,
				'nombre_editor', e.nombre_completo
			)
			order by ci.created_at, ci.comentario_id
		),
		'[]'::jsonb
	)
	from public.obras_editoriales o
	join public.comentarios_internos ci
		on ci.obra_id = o.obra_id
	join public.vocabularios tipo
		on tipo.termino_id = ci.tipo_comentario_id
		and tipo.categoria = 'tipo_comentario'
		and tipo.termino = 'observacion_publica'
	left join public.editores e
		on e.user_id = ci.user_id
	where o.obra_id = p_obra_id
		and public.can_view_obra_ficha_publica(o.obra_id, p_include_hidden)
		and ci.visible_publico = true;
$function$
;
CREATE OR REPLACE FUNCTION public.auth_puede_editar_obra(p_obra_id uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select exists (
  select 1 from public.obras_editoriales o
  join public.editores e on e.user_id=auth.uid()
  join public.vocabularios vr on vr.termino_id=e.role
  where o.obra_id=p_obra_id and o.tipo_ficha='completa' and coalesce(e.activo,true)
   and (lower(vr.termino) in ('admin','ip')
     or (lower(vr.termino)='editor' and o.editor_asignado=e.user_id)));
$function$
;
CREATE OR REPLACE FUNCTION public.sync_editor_identity_in_public_summaries()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
	if new.nombre_completo is not distinct from old.nombre_completo
		and new.orcid is not distinct from old.orcid then
		return new;
	end if;

	if new.nombre_completo is distinct from old.nombre_completo then
		update public.obras_editoriales
		set autor_ficha_publico = new.nombre_completo
		where editor_asignado = new.user_id
			and autor_ficha_publico is distinct from new.nombre_completo;
	end if;

	update public.obras_resumen resumen
	set metrica_sucia = true
	from public.obras_editoriales obra
	where resumen.obra_id = obra.obra_id
		and obra.editor_asignado = new.user_id;

	return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.plan_recompute_datos_publicos()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_publicado_id uuid;
	v_obras jsonb;
	v_autores jsonb;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden planificar el recálculo público'
			using errcode = '42501';
	end if;

	select termino_id
	into v_publicado_id
	from public.vocabularios
	where categoria = 'estado'
		and lower(termino) = 'publicado'
	limit 1;

	if v_publicado_id is null then
		raise exception 'No existe estado=publicado en vocabularios';
	end if;

	select coalesce(
		jsonb_agg(
			jsonb_build_object('id', obra.obra_id, 'titulo', obra.titulo)
			order by lower(obra.titulo), obra.obra_id
		),
		'[]'::jsonb
	)
	into v_obras
	from public.obras_editoriales obra
	where obra.estado = v_publicado_id;

	select coalesce(
		jsonb_agg(
			jsonb_build_object('id', autor.autor_id, 'nombre', autor.nombre_completo)
			order by lower(autor.nombre_completo), autor.autor_id
		),
		'[]'::jsonb
	)
	into v_autores
	from (
		select distinct a.autor_id, a.nombre_completo
		from public.perfil_metrico_unidades() unidad
		join public.autores a on a.autor_id = unidad.autor_id
		where unidad.autor_id is not null
	) autor;

	return jsonb_build_object('obras', v_obras, 'autores', v_autores);
end;
$function$
;
CREATE OR REPLACE FUNCTION public.finalizar_recompute_datos_publicos()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_eliminados integer;
	v_id uuid;
	v_publicado_id uuid;
begin
	if not public.auth_is_admin_or_ip() then
		raise exception 'Solo admin o IP pueden finalizar el recálculo público' using errcode = '42501';
	end if;

	delete from public.autores_resumen resumen
	where not exists (
		select 1 from public.perfil_metrico_unidades() unidad
		where unidad.autor_id = resumen.autor_id
	);
	get diagnostics v_eliminados = row_count;

	select termino_id into v_publicado_id
	from public.vocabularios
	where categoria = 'estado' and lower(termino) = 'publicado'
	limit 1;

	for v_id in select obra_id from public.obras_editoriales where estado = v_publicado_id loop
		perform public.recompute_artefactos_obra(v_id);
	end loop;
	for v_id in select distinct autor_id from public.autores_resumen loop
		perform public.recompute_artefactos_autor(v_id);
	end loop;

	delete from public.artefactos_publicos ap
	where ap.tipo in ('obra_ficha', 'obra_analisis')
		and not exists (select 1 from public.obras_editoriales o where o.obra_id = ap.entidad_id and o.estado = v_publicado_id);
	delete from public.artefactos_publicos ap
	where ap.tipo = 'autor_ficha'
		and not exists (select 1 from public.autores_resumen ar where ar.autor_id = ap.entidad_id and ar.alcance = ap.alcance);

	perform public.recompute_artefactos_globales();
	return v_eliminados;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.recompute_artefactos_globales()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_alcance text;
	v_publicado_id uuid;
	v_obras jsonb;
	v_autores jsonb;
	v_comparativas jsonb;
begin
	select termino_id into v_publicado_id
	from public.vocabularios
	where categoria = 'estado' and lower(termino) = 'publicado'
	limit 1;

	foreach v_alcance in array array['publico', 'completo'] loop
		select coalesce(jsonb_agg(jsonb_build_object(
			'obra_id', o.obra_id,
			'slug', o.slug,
			'titulo', o.titulo,
			'fecha_inicio_trad', o.fecha_inicio_trad,
			'fecha_fin_trad', o.fecha_fin_trad,
			'fecha_inicio_metadrama', o.fecha_inicio_metadrama,
			'fecha_fin_metadrama', o.fecha_fin_metadrama,
			'total_versos', o.total_versos,
			'genero_id', o.genero_id,
			'updated_at', o.updated_at,
			'visible_publico', o.visible_publico,
			'autores', coalesce(r.autores, array[]::text[]),
			'tramos', coalesce(r.tramos, '[]'::jsonb),
			'jornadas_tramos', coalesce(r.jornadas_tramos, '[]'::jsonb),
			'cuadros_tramos', coalesce(r.cuadros_tramos, '[]'::jsonb),
			'numero_efectivo_formas', r.numero_efectivo_formas,
			'densidad_transiciones', r.densidad_transiciones,
			'n_formas_distintas', r.n_formas_distintas,
			'formas_presentes', coalesce(r.formas_presentes, array[]::text[]),
			'metros_presentes', coalesce(r.metros_presentes, array[]::text[]),
			'tipos_forma_presentes', coalesce(r.tipos_forma_presentes, array[]::text[]),
			'variaciones_presentes', coalesce(r.variaciones_presentes, array[]::text[]),
			'subtipos_presentes', coalesce(r.subtipos_presentes, array[]::text[])
		) order by lower(o.titulo), o.obra_id), '[]'::jsonb)
		into v_obras
		from public.obras_editoriales o
		join public.obras_resumen r on r.obra_id = o.obra_id
		where o.estado = v_publicado_id
			and (v_alcance = 'completo' or coalesce(o.visible_publico, false));

		perform public.guardar_artefacto_publico(
			format('indices/obras/%s.json', v_alcance),
			'obras_indice', null, v_alcance,
			jsonb_build_object('schema_version', 1, 'alcance', v_alcance, 'obras', v_obras), 1
		);

		select coalesce(jsonb_agg(jsonb_build_object(
			'autor_id', a.autor_id,
			'slug', a.slug,
			'nombre_completo', a.nombre_completo,
			'wikidata_id', a.wikidata_id,
			'total_versos_autor', (ar.payload #>> '{resumen,total_versos_autor}')::integer,
			'n_obras_completas', (ar.payload #>> '{resumen,n_obras_completas}')::integer,
			'n_jornadas_sueltas', (ar.payload #>> '{resumen,n_jornadas_sueltas}')::integer,
			'numero_efectivo_formas_agregado',
				(ar.payload #>> '{resumen,numero_efectivo_formas_agregado}')::double precision,
			'perfil_formas', coalesce(ar.payload #> '{resumen,perfil_formas}', '{}'::jsonb),
			'top_obras', (
				select coalesce(jsonb_agg(jsonb_build_object(
					'slug', top_obra.value ->> 'slug',
					'titulo', top_obra.value ->> 'titulo',
					'total_versos', (top_obra.value ->> 'total_versos')::integer
				) order by (top_obra.value ->> 'total_versos')::integer desc nulls last,
					top_obra.value ->> 'titulo'), '[]'::jsonb)
				from (
					select obra.value
					from jsonb_array_elements(coalesce(ar.payload -> 'obras', '[]'::jsonb)) obra(value)
					where (obra.value ->> 'sostiene_perfil')::boolean
					order by (obra.value ->> 'total_versos')::integer desc nulls last,
						obra.value ->> 'titulo'
					limit 5
				) top_obra
			)
		) order by lower(a.nombre_completo), a.autor_id), '[]'::jsonb)
		into v_autores
		from public.autores a
		join public.artefactos_publicos ar
			on ar.entidad_id = a.autor_id
			and ar.tipo = 'autor_ficha'
			and ar.alcance = v_alcance
			and not ar.sucio;

		perform public.guardar_artefacto_publico(
			format('indices/autores/%s.json', v_alcance),
			'autores_indice', null, v_alcance,
			jsonb_build_object('schema_version', 1, 'alcance', v_alcance, 'autores', v_autores), 1
		);

		v_comparativas := public.corpus_comparativas_artefacto_json(v_alcance);
		perform public.guardar_artefacto_publico(
			format('corpus/comparativas/%s.json', v_alcance),
			'corpus_comparativas', null, v_alcance, v_comparativas, 3
		);
	end loop;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.recompute_artefactos_obra(p_obra_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_ficha jsonb;
	v_analisis jsonb;
begin
 if exists(select 1 from public.obras_editoriales where obra_id=p_obra_id and tipo_ficha='basica') then
  raise exception using errcode='42501',message='La ficha básica requiere el productor combinado, todavía no habilitado';
 end if; /* importador:aislado */
	select ficha into v_ficha from public.obras_resumen where obra_id = p_obra_id;
	if v_ficha is null then
		raise exception 'La obra % no tiene ficha precomputada', p_obra_id;
	end if;

	v_analisis := public.analisis_obra_publico_json(p_obra_id);
	perform public.guardar_artefacto_publico(
		format('obras/%s/ficha/publico.json', p_obra_id),
		'obra_ficha', p_obra_id, 'publico',
		jsonb_build_object('schema_version', 1, 'ficha', v_ficha), 1
	);
	perform public.guardar_artefacto_publico(
		format('obras/%s/analisis/publico.json', p_obra_id),
		'obra_analisis', p_obra_id, 'publico', v_analisis, 3
	);
end;
$function$
;
CREATE OR REPLACE FUNCTION public.ficha_publica_json(p_obra_id uuid, p_include_hidden boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_payload jsonb;
	v_sequence jsonb;
	v_sequences jsonb := '[]'::jsonb;
	v_structural_level text;
	v_obra public.obras_editoriales%rowtype;
begin
	v_payload := public.ficha_publica_dominio_json(p_obra_id, p_include_hidden);

	if v_payload is null then
		return null;
	end if;

	-- La cuenta sirve para editar; no es por sí sola un canal público de contacto.
	v_payload := v_payload #- '{obra,autor_ficha_email_publico}';

	select * into v_obra from public.obras_editoriales where obra_id = p_obra_id;

	v_payload := jsonb_set(
		v_payload,
		'{obra}',
		(v_payload -> 'obra') || jsonb_build_object(
			'sin_figuras_donaire', coalesce(v_obra.sin_figuras_donaire, false),
			'sin_personajes_sobrenaturales', coalesce(v_obra.sin_personajes_sobrenaturales, false),
			'sin_eventos_sobrenaturales', coalesce(v_obra.sin_eventos_sobrenaturales, false),
			'fecha_publicacion', v_obra.fecha_publicacion
		),
		true
	);

	for v_sequence in
		select value
		from jsonb_array_elements(coalesce(v_payload #> '{metrica,secuencias}', '[]'::jsonb))
	loop
		v_structural_level := null;

		select fm.nivel_estructural
		into v_structural_level
		from public.arquitecturas_forma architecture
		join public.formas_metricas fm on fm.forma_id = architecture.forma_id
		where architecture.arquitectura_id = nullif(v_sequence ->> 'arquitectura_id', '')::uuid;

		v_sequence := v_sequence || jsonb_build_object(
			'nivel_estructural', v_structural_level,
			'esquemas_rima', public.ficha_publica_enriquece_respuestas(v_sequence -> 'esquemas_rima'),
			'rasgos', (
				select coalesce(
					jsonb_agg(
						respuesta.value || jsonb_build_object(
							'rasgo_escala', rasgo.escala_recuento,
							'rasgo_naturaleza', rasgo.naturaleza
						)
						order by respuesta.ordinality
					),
					'[]'::jsonb
				)
				from jsonb_array_elements(
					coalesce(public.ficha_publica_enriquece_respuestas(v_sequence -> 'rasgos'), '[]'::jsonb)
				) with ordinality as respuesta(value, ordinality)
				left join public.rasgos_metricos rasgo on rasgo.slug = respuesta.value ->> 'rasgo_slug'
			),
			'metros', public.ficha_publica_enriquece_respuestas(v_sequence -> 'metros'),
			'variedades', public.ficha_publica_enriquece_respuestas(v_sequence -> 'variedades')
		);

		v_sequences := v_sequences || jsonb_build_array(v_sequence);
	end loop;

	return jsonb_set(v_payload, '{metrica,secuencias}', v_sequences, true);
end;
$function$
;
CREATE OR REPLACE FUNCTION public.trasladar_observaciones_a_comentarios(p_caracterizaciones uuid[], p_responsable uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
  v_id uuid;
  v_nota record;
  v_anterior public.traslados_observaciones_caracterizacion%rowtype;
  v_comentario uuid;
  v_tipo_comentario uuid;
  v_total integer := 0;
  v_texto text;
begin
  if not exists (
    select 1 from public.editores e join public.vocabularios v on v.termino_id = e.role
    where e.user_id = p_responsable and v.termino in ('admin','ip')
  ) then raise exception 'El traslado necesita un responsable admin o IP'; end if;

  select termino_id into strict v_tipo_comentario from public.vocabularios
  where categoria = 'tipo_comentario' and termino = 'observacion_publica';

  for v_id in select distinct unnest(p_caracterizaciones) order by 1 loop
    select r.*, o.obra_id, o.editor_asignado, v.termino as tipo into v_nota
    from public.secuencias_caracterizaciones_rango r
    join public.secuencias_metricas s using (secuencia_id)
    join public.obras_editoriales o using (obra_id)
    join public.vocabularios v on v.termino_id = r.tipo_caracterizacion_rango_id
    where r.caracterizacion_rango_id = v_id for update of r;
    if not found then raise exception 'No existe la caracterización %', v_id; end if;
    if nullif(btrim(v_nota.observaciones), '') is null then
      raise exception 'La caracterización % no tiene nota que trasladar', v_id;
    end if;
    if v_nota.tipo not in ('cantado','prosa','evocacion_metrica') then
      raise exception 'El destino de % requiere revisión individual; no es una nota enunciativa', v_id;
    end if;
    if v_nota.editor_asignado is null then raise exception 'Falta autor para %', v_id; end if;

    select * into v_anterior from public.traslados_observaciones_caracterizacion
    where caracterizacion_rango_id = v_id;
    if found then
      if v_anterior.origen ->> 'observaciones' is distinct from v_nota.observaciones
        or (v_anterior.origen ->> 'secuencia_id')::uuid is distinct from v_nota.secuencia_id
        or (v_anterior.origen ->> 'v_ini')::integer is distinct from v_nota.v_ini
        or (v_anterior.origen ->> 'v_fin')::integer is distinct from v_nota.v_fin
        or (v_anterior.origen ->> 'tipo_caracterizacion_rango_id')::uuid is distinct from v_nota.tipo_caracterizacion_rango_id
      then raise exception 'Ha cambiado el origen ya trasladado de %; revisar antes de repetir', v_id; end if;
      continue; -- No sobrescribir comentarios que el editor haya corregido o eliminado.
    end if;

    v_texto := case when v_nota.v_ini = v_nota.v_fin
      then format('**V. %s.**', v_nota.v_ini)
      else format('**Vv. %s–%s.**', v_nota.v_ini, v_nota.v_fin) end
      || E'\n\n' || v_nota.observaciones;

    insert into public.comentarios_internos (
      obra_id, secuencia_id, user_id, comentario, tipo_comentario_id,
      visible_publico, publicado_por, publicado_at, created_at
    ) values (
      v_nota.obra_id, v_nota.secuencia_id, v_nota.editor_asignado, v_texto, v_tipo_comentario,
      true, p_responsable, now(), v_nota.created_at
    ) returning comentario_id into v_comentario;

    insert into public.traslados_observaciones_caracterizacion (
      caracterizacion_rango_id, comentario_id, obra_id, origen, trasladado_por
    ) values (v_id, v_comentario, v_nota.obra_id, to_jsonb(v_nota), p_responsable);
    v_total := v_total + 1;
  end loop;
  return v_total;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.auth_puede_consultar_importacion(p_obra uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select public.auth_puede_importar_metrica() or exists (
    select 1 from public.obras_editoriales o join public.editores e on e.user_id=auth.uid()
    where o.obra_id=p_obra and o.editor_asignado=e.user_id and coalesce(e.activo,true));
$function$
;
CREATE OR REPLACE FUNCTION public.auth_respeta_limite_minima(p_obra uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
  select exists (select 1 from public.obras_editoriales o where o.obra_id=p_obra and
    (o.tipo_ficha='completa' or public.auth_puede_consultar_importacion(o.obra_id)));
$function$
;
CREATE OR REPLACE FUNCTION public.coincidencias_importacion_metrica(p_titulo text)
 RETURNS TABLE(obra_id uuid, titulo text, tipo_ficha text, autores text[])
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
  if not public.auth_puede_importar_metrica() then
    raise exception using errcode='42501',message='La sesión no puede consultar coincidencias de importación';
  end if;
  return query select o.obra_id,o.titulo,o.tipo_ficha,coalesce((
    select array_agg(distinct au.nombre_completo::text order by au.nombre_completo::text)
    from public.atribuciones a join public.atribucion_autores aa on aa.atribucion_id=a.atribucion_id
    join public.autores au on au.autor_id=aa.autor_id where a.obra_id=o.obra_id
  ),array[]::text[])
  from public.obras_editoriales o
  where public.normalizar_titulo_importacion(p_titulo)<>'' and exists (
    select 1 from unnest(array[o.titulo] || coalesce(o.variantes_titulo,array[]::text[])) t(valor)
    where public.normalizar_titulo_importacion(t.valor)=public.normalizar_titulo_importacion(p_titulo))
  order by lower(o.titulo),o.obra_id;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.listar_fichas_basicas(p_desde integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
begin
 if not public.auth_puede_importar_metrica() then
  raise exception using errcode='42501',message='La sesión no puede consultar fichas básicas';
 end if;
 if p_desde is null or p_desde<0 then raise exception using errcode='22023',message='Página inválida'; end if;
 return (
  with pagina as materialized (
   select i.* ,e.nombre_completo::text as importado_por_nombre
   from public.importaciones_metricas i join public.obras_editoriales o using(obra_id)
   join public.editores e on e.user_id=i.importado_por
   where o.tipo_ficha='basica' and i.usada_en_corpus
   order by i.importado_en desc,i.importacion_id limit 51 offset p_desde
  )
  select coalesce(jsonb_agg(jsonb_build_object(
   'importacion_id',i.importacion_id,'obra_id',i.obra_id,
   'titulo',i.datos_confirmados#>>'{metadatos,titulo}',
   'autor_nombre',i.datos_confirmados#>>'{metadatos,autor_nombre}',
   'importado_por',i.importado_por_nombre,'importado_en',i.importado_en,
   'modificado_en',i.modificado_en,
   'formas_pendientes',coalesce((select jsonb_agg(jsonb_build_object(
     'denominacion',coalesce(s#>>'{origen,denominacion_literal}','Forma sin resolver'),
     'v_ini',(s->>'v_ini')::integer,'v_fin',(s->>'v_fin')::integer
    ) order by (s->>'v_ini')::integer)
    from jsonb_array_elements(i.datos_confirmados->'segmentos') s
    where s->'identificacion'='null'::jsonb),'[]'::jsonb),
   'comprobacion_registrada',i.datos_confirmados ? 'comprobacion',
   'avisos_longitud',coalesce(i.datos_confirmados#>'{comprobacion,avisos_longitud}','[]'::jsonb),
   'incidencias_fuente',coalesce((select jsonb_agg(jsonb_build_object('descripcion',c->>'descripcion'))
      from jsonb_array_elements(i.entrada_original->'incidencias') c),'[]'::jsonb)
  ) order by i.importado_en desc,i.importacion_id),'[]'::jsonb) from pagina i
 );
end;
$function$
;
CREATE OR REPLACE FUNCTION public.impedir_v2_en_basica()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin
 if new.secuencia_id is not null and exists (
  select 1 from public.secuencias_metricas s join public.obras_editoriales o using(obra_id)
  where s.secuencia_id=new.secuencia_id and o.tipo_ficha='basica') then
  raise exception using errcode='23514',message='La métrica de una ficha básica se registra mediante el importador';
 end if;
 return new;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.perfil_artefacto_obra_rango(p_obra_id uuid, p_v_ini integer DEFAULT NULL::integer, p_v_fin integer DEFAULT NULL::integer, p_nivel text DEFAULT 'forma'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_payload jsonb;
	v_perfil jsonb;
begin
 if exists(select 1 from public.obras_editoriales where obra_id=p_obra_id and tipo_ficha='basica') then
  raise exception using errcode='42501',message='La ficha básica requiere el productor combinado, todavía no habilitado';
 end if; /* importador:aislado */
	if p_nivel not in ('forma', 'arquitectura') then
		raise exception 'Nivel de perfil desconocido: %', p_nivel;
	end if;

	select payload into v_payload
	from public.artefactos_publicos
	where clave = format('obras/%s/analisis/publico.json', p_obra_id)
		and not sucio;

	if v_payload is null then
		if p_nivel = 'forma' then
			return public.perfil_formas_rango(p_obra_id, p_v_ini, p_v_fin);
		end if;
		return public.perfil_formas_hijos_rango(p_obra_id, p_v_ini, p_v_fin);
	end if;

	select coalesce(jsonb_object_agg(clave, versos), '{}'::jsonb)
	into v_perfil
	from (
		select
			case
				when p_nivel = 'forma' then s.value ->> 'forma'
				else concat_ws('/', s.value ->> 'forma', s.value ->> 'arquitectura')
			end as clave,
			sum(coalesce((s.value ->> 'n')::integer, 0))::integer as versos
		from jsonb_array_elements(coalesce(v_payload -> 'secuencias', '[]'::jsonb)) s(value)
		where (p_v_ini is null or (s.value ->> 'i')::integer >= p_v_ini)
			and (p_v_fin is null or (s.value ->> 'f')::integer <= p_v_fin)
			and s.value ->> 'forma' is not null
			and (p_nivel = 'forma' or s.value ->> 'arquitectura' is not null)
		group by 1
	) perfiles
	where clave is not null and clave <> '';

	return coalesce(v_perfil, '{}'::jsonb);
end;
$function$
;
CREATE OR REPLACE FUNCTION public.auth_obra_es_detallada(p_obra uuid)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO ''
AS $function$
 select exists(select 1 from public.obras_editoriales where obra_id=p_obra and tipo_ficha='completa');
$function$
;
CREATE OR REPLACE FUNCTION public.gestionar_asignaciones_lote(p_operacion text, p_destino uuid, p_obras jsonb)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_actor uuid := auth.uid();
  v_lote uuid := gen_random_uuid();
  v_peticion record;
  v_obra public.obras_editoriales%rowtype;
  v_anteriores uuid[];
  v_esperados uuid[];
  v_nuevos uuid[];
  v_antes jsonb;
  v_despues jsonb;
  v_cambios integer := 0;
begin
  if not exists (
    select 1 from public.editores e join public.vocabularios v on v.termino_id = e.role
    where e.user_id = v_actor and coalesce(e.activo, true) and lower(v.termino) in ('admin', 'ip')
  ) then
    raise exception 'Solo administración o IP pueden cambiar asignaciones.' using errcode = '42501';
  end if;
  if p_operacion is null or p_operacion not in ('editor', 'add_reviewer', 'remove_reviewer') then
    raise exception 'Operación de asignación inválida.' using errcode = '22023';
  end if;
  if p_obras is null or jsonb_typeof(p_obras) <> 'array' then
    raise exception 'Selecciona las obras.' using errcode = '22023';
  end if;
  if jsonb_array_length(p_obras) not between 1 and 500 then
    raise exception 'Selecciona entre 1 y 500 obras.' using errcode = '22023';
  end if;
  if exists (
    select 1 from jsonb_array_elements(p_obras) x
    where jsonb_typeof(x) <> 'object' or not (x ? 'obra_id' and x ? 'editor_asignado' and x ? 'reviewer_ids')
      or x->>'obra_id' is null or jsonb_typeof(x->'reviewer_ids') <> 'array'
  ) then
    raise exception 'La selección está incompleta. Recarga la página.' using errcode = '22023';
  end if;
  if (select count(distinct (x->>'obra_id')::uuid) from jsonb_array_elements(p_obras) x) <> jsonb_array_length(p_obras) then
    raise exception 'La selección contiene obras repetidas.' using errcode = '22023';
  end if;
  -- Bloquea el destino para impedir que se deshabilite durante el reparto.
  perform 1 from public.editores e where e.user_id = p_destino
    and (p_operacion = 'remove_reviewer' or coalesce(e.activo, true)) for share;
  if not found then
    raise exception 'El editor de destino no existe o está deshabilitado.' using errcode = '22023';
  end if;
  -- Orden estable: dos lotes solapados no toman las obras en orden inverso.
  for v_peticion in
    select x from jsonb_array_elements(p_obras) x order by (x->>'obra_id')::uuid
  loop
    perform 1 from public.obras where obra_id=(v_peticion.x->>'obra_id')::uuid for update;
    select * into v_obra from public.obras_editoriales where obra_id = (v_peticion.x->>'obra_id')::uuid;
    if not found then
      raise exception 'Una obra ya no existe. Recarga la página.' using errcode = 'PT409';
    end if;
    if v_obra.tipo_ficha='basica' then raise exception using errcode='42501',message='La asignación de una básica requiere la transición a completa, todavía pendiente'; end if; /* importador:aislado */ select coalesce(array_agg(r.revisor_id order by r.revisor_id), '{}'::uuid[]) into v_anteriores
      from public.obras_revisores r where r.obra_id = v_obra.obra_id;
    select coalesce(array_agg(value::uuid order by value::uuid), '{}'::uuid[]) into v_esperados
      from jsonb_array_elements_text(v_peticion.x->'reviewer_ids');
    if v_obra.editor_asignado is distinct from (v_peticion.x->>'editor_asignado')::uuid
      or v_anteriores is distinct from v_esperados then
      raise exception 'Han cambiado las asignaciones de «%». Recarga la página y revisa el lote.', v_obra.titulo using errcode = 'PT409';
    end if;
    v_antes := jsonb_build_object('editor_asignado', v_obra.editor_asignado, 'reviewer_ids', v_anteriores);
    if v_obra.tipo_ficha='sin_ficha' and p_operacion<>'editor' then
      raise exception 'Encarga primero la completa antes de asignar revisores' using errcode='23514';
    end if;
    if p_operacion = 'editor' then
      if v_obra.tipo_ficha='sin_ficha' then perform public.iniciar_ficha_completa(v_obra.obra_id,null,false); end if;
      -- El editor responsable no puede ser también revisor de la misma obra.
      delete from public.obras_revisores where obra_id = v_obra.obra_id and revisor_id = p_destino;
      if v_obra.editor_asignado is distinct from p_destino then
        update public.obras_editoriales set editor_asignado = p_destino where obra_id = v_obra.obra_id;
      end if;
      v_obra.editor_asignado := p_destino;
    elsif p_operacion = 'add_reviewer' then
      if v_obra.editor_asignado = p_destino then
        raise exception '«%» ya tiene a esa persona como editor responsable. No puede revisar su propia obra.', v_obra.titulo using errcode = '22023';
      end if;
      insert into public.obras_revisores(obra_id, revisor_id, asignado_por)
        values (v_obra.obra_id, p_destino, v_actor) on conflict (obra_id, revisor_id) do nothing;
    else
      delete from public.obras_revisores where obra_id = v_obra.obra_id and revisor_id = p_destino;
    end if;
    select coalesce(array_agg(r.revisor_id order by r.revisor_id), '{}'::uuid[]) into v_nuevos
      from public.obras_revisores r where r.obra_id = v_obra.obra_id;
    v_despues := jsonb_build_object('editor_asignado', v_obra.editor_asignado, 'reviewer_ids', v_nuevos);
    if v_antes is distinct from v_despues then
      insert into public.asignaciones_historial(lote_id, obra_id, realizado_por, operacion, antes, despues)
        values (v_lote, v_obra.obra_id, v_actor, p_operacion, v_antes, v_despues);
      v_cambios := v_cambios + 1;
    end if;
  end loop;
  return v_cambios;
end;
$function$
;
CREATE OR REPLACE FUNCTION public.analisis_obra_publico_json(p_obra_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
	v_ficha jsonb;
	v_secuencias jsonb;
	v_cuadros jsonb;
	v_jornadas jsonb;
	v_hechos jsonb;
	v_transiciones jsonb;
	v_fenomenos jsonb;
	v_perfil_formas jsonb;
	v_enunciacion jsonb;
	v_articulacion jsonb;
	v_metricas jsonb;
	v_total integer;
	v_total_versos integer;
	v_n_jornadas integer;
	v_n_formas integer;
	v_diversidad double precision;
	v_densidad double precision;
begin
 if exists(select 1 from public.obras_editoriales where obra_id=p_obra_id and tipo_ficha='basica') then
  raise exception using errcode='42501',message='La ficha básica requiere el productor combinado, todavía no habilitado';
 end if; /* importador:aislado */
	select
		r.ficha,
		r.total_versos,
		r.n_jornadas,
		r.n_formas_distintas,
		r.numero_efectivo_formas,
		r.densidad_transiciones
	into
		v_ficha,
		v_total_versos,
		v_n_jornadas,
		v_n_formas,
		v_diversidad,
		v_densidad
	from public.obras_resumen r
	where r.obra_id = p_obra_id;

	if v_ficha is null then
		return null;
	end if;

	v_secuencias := coalesce(v_ficha #> '{metrica,secuencias}', '[]'::jsonb);
	v_cuadros := coalesce(v_ficha #> '{estructura,cuadros}', '[]'::jsonb);
	v_jornadas := coalesce(v_ficha #> '{estructura,jornadas}', '[]'::jsonb);
	v_total := jsonb_array_length(v_secuencias);
	v_total_versos := coalesce(v_total_versos, (
		select sum((s.value ->> 'n_versos')::integer)::integer
		from jsonb_array_elements(v_secuencias) s(value)
	), 0);

	select coalesce(jsonb_agg(
		jsonb_strip_nulls(jsonb_build_object(
			'id', s.value ->> 'secuencia_id',
			'i', (s.value ->> 'v_ini')::integer,
			'f', (s.value ->> 'v_fin')::integer,
			'n', (s.value ->> 'n_versos')::integer,
			'j', (s.value ->> 'jornada_num')::integer,
			'c', (s.value ->> 'cuadro_num')::integer,
			'forma', s.value ->> 'forma_slug',
			'tipo_forma', s.value ->> 'tipo_forma',
			'arquitectura', s.value ->> 'arquitectura_slug',
			'cuadro_continua', (s.value ->> 'cuadro_continua')::boolean,
			'cortes_cuadro', (
				select count(*)::integer
				from jsonb_array_elements(v_cuadros) cuadro(value)
				where (cuadro.value ->> 'cuadro_num')::integer > 1
					and (cuadro.value ->> 'v_ini')::integer > (s.value ->> 'v_ini')::integer
					and (cuadro.value ->> 'v_ini')::integer <= (s.value ->> 'v_fin')::integer
			),
			'versos_partidos', (s.value ->> 'versos_partidos')::boolean,
			'cambio_espacio', (s.value ->> 'inaugura_espacio')::boolean,
			'evento_sobrenatural', (s.value ->> 'evento_sobrenatural')::boolean,
			'intervencion_femenina', s.value ->> 'intervencion_personajes_femeninos',
			'generos_intervinientes', s.value -> 'generos_intervinientes',
			'intervencion_donaire', s.value ->> 'intervencion_figuras_donaire',
			'intervencion_sobrenaturales', s.value ->> 'intervencion_personajes_sobrenaturales',
			'caracterizaciones', coalesce(s.value -> 'caracterizaciones_rango', '[]'::jsonb),
			'metros', coalesce(s.value -> 'metros', '[]'::jsonb),
			'esquemas', coalesce(s.value -> 'esquemas_rima', '[]'::jsonb),
			'rasgos', coalesce(s.value -> 'rasgos', '[]'::jsonb),
			'variedades', coalesce(s.value -> 'variedades', '[]'::jsonb),
			'desviaciones', coalesce(s.value -> 'desviaciones', '[]'::jsonb)
		)) order by s.ordinality), '[]'::jsonb)
	into v_hechos
	from jsonb_array_elements(v_secuencias) with ordinality s(value, ordinality);

	with sec as (
		select
			coalesce(nullif(value ->> 'forma_slug', ''), 'sin-forma-anotada') as forma,
			value ->> 'tipo_forma' as tipo_forma,
			(value ->> 'n_versos')::integer as versos
		from jsonb_array_elements(v_secuencias)
	), agrupadas as (
		select forma, max(tipo_forma) as tipo_forma, sum(versos)::integer as versos,
			count(*)::integer as secuencias
		from sec
		group by forma
	)
	select coalesce(jsonb_object_agg(forma, jsonb_build_object(
		'tipo_forma', tipo_forma,
		'versos', versos,
		'secuencias', secuencias,
		'proporcion_versos', case when v_total_versos > 0 then versos::numeric / v_total_versos else null end,
		'longitud_media_secuencia', case when secuencias > 0 then versos::numeric / secuencias else null end
	)), '{}'::jsonb)
	into v_perfil_formas
	from agrupadas;

	with orden as (
		select
			s.ordinality,
			coalesce(s.value ->> 'forma_slug', 'sin-forma-anotada') as forma,
			lag(coalesce(s.value ->> 'forma_slug', 'sin-forma-anotada'))
				over (order by s.ordinality) as forma_anterior
		from jsonb_array_elements(v_secuencias) with ordinality s(value, ordinality)
	), grupos as (
		select forma_anterior as de, forma as a, count(*)::integer as veces
		from orden
		where forma_anterior is not null
		group by forma_anterior, forma
	)
	select coalesce(jsonb_agg(jsonb_build_object(
		'de', de,
		'a', a,
		'veces', veces
	) order by veces desc, de, a), '[]'::jsonb)
	into v_transiciones
	from grupos;

	with sec as (
		select value
		from jsonb_array_elements(v_secuencias)
	), metricas(nombre, campo, es_intervencion) as (
		values
			('versos_partidos', 'versos_partidos', false),
			('cambios_espacio', 'inaugura_espacio', false),
			('eventos_sobrenaturales', 'evento_sobrenatural', false),
			('intervencion_femenina', 'intervencion_personajes_femeninos', true),
			('intervencion_donaire', 'intervencion_figuras_donaire', true),
			('intervencion_sobrenaturales', 'intervencion_personajes_sobrenaturales', true)
	), conteos as (
		select
			m.nombre,
			count(*) filter (
				where case when m.es_intervencion
					then s.value ->> m.campo in ('exclusiva', 'compartida')
					else (s.value ->> m.campo)::boolean is true end
			)::integer as si,
			count(*) filter (
				where case when m.es_intervencion
					then s.value ->> m.campo = 'sin_intervencion'
					else (s.value ->> m.campo)::boolean is false end
			)::integer as no,
			count(*) filter (where s.value ->> m.campo is null)::integer as sin_respuesta,
			count(*) filter (where s.value ->> m.campo = 'exclusiva')::integer as exclusiva,
			count(*) filter (where s.value ->> m.campo = 'compartida')::integer as compartida
		from metricas m cross join sec s
		group by m.nombre
	)
	select coalesce(jsonb_object_agg(nombre, jsonb_build_object(
		'si', si,
		'no', no,
		'sin_respuesta', sin_respuesta,
		'total_respondidas', si + no,
		'proporcion', case when si + no > 0 then si::numeric / (si + no) else null end,
		'exclusiva', exclusiva,
		'compartida', compartida
	)), '{}'::jsonb)
	into v_fenomenos
	from conteos;

	-- Cada género tiene el mismo denominador: secuencias con respuesta. Las categorías
	-- se solapan; «no» significa no seleccionado, no una inferencia sobre voces indeterminadas.
	select v_fenomenos || coalesce(jsonb_object_agg('intervencion_' || g.nombre, jsonb_build_object(
		'si', g.si, 'no', g.respondidas - g.si, 'sin_respuesta', v_total - g.respondidas,
		'total_respondidas', g.respondidas,
		'proporcion', g.si::numeric / nullif(g.respondidas, 0),
		'exclusiva', g.exclusiva, 'compartida', g.si - g.exclusiva
	)), '{}'::jsonb) into v_fenomenos
	from (
		select m.nombre,
			count(*) filter (where s.value -> 'generos_intervinientes' ? m.genero)::integer as si,
			count(*) filter (where jsonb_typeof(s.value -> 'generos_intervinientes') = 'array')::integer as respondidas,
			count(*) filter (where s.value -> 'generos_intervinientes' = jsonb_build_array(m.genero))::integer as exclusiva
		from (values ('masculina','masculino'),('femenina','femenino'),('indeterminada','indeterminado')) m(nombre,genero)
		left join jsonb_array_elements(v_secuencias) s(value) on true
		group by m.nombre
	) g;

	-- range_agg fusiona rangos solapados o contiguos antes de contar versos: el mismo pasaje no
	-- pesa dos veces si una caracterización se registró en fragmentos coincidentes.
	with rangos_crudos as (
		select
			replace(
				translate(lower(c.value ->> 'tipo_caracterizacion_rango_term'), 'áéíóúüñ', 'aeiouun'),
				' ', '_'
			) as tipo,
			int4range(
				(c.value ->> 'v_ini')::integer,
				(c.value ->> 'v_fin')::integer + 1,
				'[)'
			) as rango,
			coalesce(nullif(s.value ->> 'forma_slug', ''), 'sin-forma-anotada') as forma
		from jsonb_array_elements(v_secuencias) s(value)
		cross join lateral jsonb_array_elements(coalesce(s.value -> 'caracterizaciones_rango', '[]'::jsonb)) c(value)
		where nullif(c.value ->> 'tipo_caracterizacion_rango_term', '') is not null
	), rangos as (
		select * from rangos_crudos
		where tipo in ('cantado', 'evocacion_metrica')
	), por_tipo as (
		select tipo, range_agg(rango) as rangos, array_agg(distinct forma order by forma) as formas
		from rangos
		group by tipo
	), conteos as (
		select
			tipo,
			coalesce((select sum(upper(r) - lower(r)) from unnest(rangos) r), 0)::integer as versos,
			formas
		from por_tipo
	)
	select coalesce(jsonb_object_agg(tipo, jsonb_build_object(
		'versos', versos,
		'proporcion_versos', case when v_total_versos > 0 then versos::numeric / v_total_versos else null end,
		'formas', to_jsonb(formas)
	)), '{}'::jsonb)
	into v_enunciacion
	from conteos;

	-- Prosa: los extremos son versos de referencia, nunca una longitud de texto.
	with pasajes as (
		select
			(c.value ->> 'v_ini')::integer as anterior,
			(c.value ->> 'v_fin')::integer as posterior,
			coalesce(nullif(s.value ->> 'forma_slug', ''), 'sin-forma-anotada') as forma
		from jsonb_array_elements(v_secuencias) s(value)
		cross join lateral jsonb_array_elements(coalesce(s.value -> 'caracterizaciones_rango', '[]'::jsonb)) c(value)
		where replace(translate(lower(c.value ->> 'tipo_caracterizacion_rango_term'),
			'áéíóúüñ', 'aeiouun'), ' ', '_') = 'prosa'
	), limites as (
		select distinct anterior, posterior from pasajes
	)
	select v_enunciacion || case when exists(select 1 from pasajes) then
		jsonb_build_object('prosa', jsonb_build_object(
			'presente', true,
			'localizaciones', (select jsonb_agg(jsonb_build_object(
				'v_anterior', anterior, 'v_posterior', posterior) order by anterior, posterior) from limites),
			'formas', (select to_jsonb(array_agg(distinct forma order by forma)) from pasajes)
		)) else '{}'::jsonb end
	into v_enunciacion;

	with cuadros_ordenados as (
		select
			(c.value ->> 'v_ini')::integer as limite,
			row_number() over (
				partition by c.value ->> 'jornada_id'
				order by (c.value ->> 'v_ini')::integer
			) as posicion
		from jsonb_array_elements(v_cuadros) c(value)
	), limites as (
		select limite from cuadros_ordenados where posicion > 1
	), sec as (
		select
			s.value ->> 'secuencia_id' as id,
			(s.value ->> 'v_ini')::integer as v_ini,
			(s.value ->> 'v_fin')::integer as v_fin,
			coalesce(s.value ->> 'forma_slug', 'sin-forma-anotada') as forma
		from jsonb_array_elements(v_secuencias) s(value)
	), clasificados as (
		select
			l.limite,
			anterior.id as anterior_id,
			siguiente.id as siguiente_id,
			anterior.forma as forma_anterior,
			siguiente.forma as forma_siguiente
		from limites l
		left join lateral (
			select id, forma from sec where v_ini <= l.limite - 1 and v_fin >= l.limite - 1 limit 1
		) anterior on true
		left join lateral (
			select id, forma from sec where v_ini <= l.limite and v_fin >= l.limite limit 1
		) siguiente on true
	), conteos as (
		select
			count(*)::integer as total,
			count(*) filter (where anterior_id is null or siguiente_id is null)::integer as sin_cobertura,
			count(*) filter (where anterior_id = siguiente_id)::integer as parten_secuencia,
			count(*) filter (where anterior_id is not null and siguiente_id is not null and anterior_id <> siguiente_id)::integer as cambian_secuencia,
			count(*) filter (where anterior_id is not null and siguiente_id is not null and anterior_id <> siguiente_id and forma_anterior = forma_siguiente)::integer as cambian_secuencia_misma_forma
		from clasificados
	), extremos as (
		select coalesce(jsonb_agg(jsonb_build_object(
			'jornada', (j.value ->> 'jornada_num')::integer,
			'abre', (
				select coalesce(s.value ->> 'forma_slug', 'sin-forma-anotada')
				from jsonb_array_elements(v_secuencias) s(value)
				where (s.value ->> 'v_ini')::integer between (j.value ->> 'v_ini')::integer and (j.value ->> 'v_fin')::integer
				order by (s.value ->> 'v_ini')::integer limit 1
			),
			'cierra', (
				select coalesce(s.value ->> 'forma_slug', 'sin-forma-anotada')
				from jsonb_array_elements(v_secuencias) s(value)
				where (s.value ->> 'v_ini')::integer between (j.value ->> 'v_ini')::integer and (j.value ->> 'v_fin')::integer
				order by (s.value ->> 'v_ini')::integer desc limit 1
			)
		) order by (j.value ->> 'jornada_num')::integer), '[]'::jsonb) as jornadas
		from jsonb_array_elements(v_jornadas) j(value)
	)
	select jsonb_build_object(
		'cambios_cuadro_total', c.total,
		'cambios_cuadro_sin_cobertura', c.sin_cobertura,
		'cambios_cuadro_que_parten_secuencia', c.parten_secuencia,
		'cambios_cuadro_con_cambio_secuencia', c.cambian_secuencia,
		'cambios_secuencia_misma_forma', c.cambian_secuencia_misma_forma,
		'proporcion_cambios_cuadro_con_cambio_secuencia',
			case when c.total - c.sin_cobertura > 0
				then c.cambian_secuencia::numeric / (c.total - c.sin_cobertura) else null end,
		'jornadas', e.jornadas
	)
	into v_articulacion
	from conteos c cross join extremos e;

	v_metricas := jsonb_build_object(
		'total_versos', v_total_versos,
		'total_secuencias', v_total,
		'n_jornadas', v_n_jornadas,
		'n_formas_distintas', v_n_formas,
		'numero_efectivo_formas', v_diversidad,
		'densidad_transiciones', v_densidad,
		'longitud_media_secuencia', case when v_total > 0 then v_total_versos::numeric / v_total else null end,
		'proporcion_italiana', case when v_total_versos > 0 then (
			select coalesce(sum((s.value ->> 'n_versos')::integer), 0)::numeric / v_total_versos
			from jsonb_array_elements(v_secuencias) s(value)
			where s.value ->> 'tipo_forma' = 'forma_italiana'
		) else null end,
		'proporcion_sin_forma', case when v_total_versos > 0 then (
			select coalesce(sum((s.value ->> 'n_versos')::integer), 0)::numeric / v_total_versos
			from jsonb_array_elements(v_secuencias) s(value)
			where nullif(s.value ->> 'forma_slug', '') is null
		) else null end
	);

	return jsonb_build_object(
		'schema_version', 3,
		'obra_id', p_obra_id,
		'total_secuencias', v_total,
		'total_transiciones', greatest(v_total - 1, 0),
		'metricas', v_metricas,
		'perfil_formas', v_perfil_formas,
		'articulacion', v_articulacion,
		'enunciacion', v_enunciacion,
		'secuencias', v_hechos,
		'transiciones', v_transiciones,
		'fenomenos', v_fenomenos
	);
end;
$function$
;
drop function if exists public.guardar_ficha_basica(uuid,uuid,jsonb,jsonb,uuid[]);
CREATE OR REPLACE FUNCTION public.guardar_ficha_basica(p_peticion uuid, p_autor uuid, p_datos jsonb, p_entrada_original jsonb, p_coincidencias_revisadas uuid[] DEFAULT '{}'::uuid[], p_obra uuid DEFAULT NULL)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
<<importar>>
declare
  v_actor uuid:=auth.uid(); v_obra uuid:=coalesce(p_obra,gen_random_uuid()); v_importacion uuid:=gen_random_uuid();
  v_grupo uuid:=gen_random_uuid(); v_atribucion uuid:=gen_random_uuid(); v_secuencia uuid;
  v_anterior public.importaciones_metricas%rowtype;
  v_genero uuid; v_borrador uuid; v_tradicional uuid; v_unica uuid; v_individual uuid;
  v_meta jsonb; v_fila jsonb; v_candidata jsonb; v_detalle jsonb; v_desviacion jsonb;
  v_forma uuid; v_arquitectura uuid; v_inicio integer; v_fin integer;
  v_prev integer; v_num integer; v_total bigint:=0; v_ahora timestamptz:=now();
  v_revisadas uuid[]; v_coincidencias uuid[]; v_desplazamientos jsonb;
begin
  if not public.auth_puede_importar_metrica() then
    raise exception using errcode='42501',message='La sesión no puede importar métrica';
  end if;
  if p_peticion is null or p_autor is null or p_datos is null or p_entrada_original is null
    or jsonb_typeof(p_entrada_original)<>'object' or pg_column_size(p_entrada_original)>10485760
    or pg_column_size(p_datos)>10485760 then
    raise exception using errcode='22023',message='Petición incompleta o documento demasiado grande';
  end if;
  select coalesce(array_agg(distinct id order by id),array[]::uuid[]) into v_revisadas
    from unnest(coalesce(p_coincidencias_revisadas,array[]::uuid[])) ids(id) where id is not null;
  -- La misma clave se serializa incluso entre dos transacciones simultáneas.
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text||':'||p_peticion::text,0));
  select * into v_anterior from public.importaciones_metricas
    where importado_por=v_actor and peticion_id=p_peticion;
  if found then
    if (p_obra is not null and v_anterior.obra_id<>p_obra) or v_anterior.datos_confirmados is distinct from p_datos or v_anterior.autor_id<>p_autor
      or v_anterior.entrada_original is distinct from p_entrada_original
      or v_anterior.coincidencias_revisadas is distinct from v_revisadas then
      raise exception using errcode='23505',message='La petición ya se usó con otros datos';
    end if;
    return jsonb_build_object('obra_id',v_anterior.obra_id,'importacion_id',v_anterior.importacion_id,'repetida',true);
  end if;
  if p_obra is not null then
    perform 1 from public.obras where obra_id=p_obra for update;
    if not found then raise exception 'Obra de destino no encontrada' using errcode='P0002'; end if;
    if exists(select 1 from public.fichas_completas where obra_id=p_obra)
      or exists(select 1 from public.importaciones_metricas where obra_id=p_obra)
      or exists(select 1 from public.secuencias_metricas where obra_id=p_obra)
      or exists(select 1 from public.jornadas where obra_id=p_obra) then
      raise exception 'La obra ya tiene ficha o estructura; no se sobrescribe' using errcode='23514';
    end if;
  end if;
  if not extensions.jsonb_matches_schema(public.esquema_documento_minimo(),p_datos) then
    raise exception using errcode='23514',message='El documento no cumple el contrato de ficha mínima';
  end if;
  if not extensions.jsonb_matches_schema(public.esquema_extraccion_minima(),p_entrada_original)
    or (p_entrada_original->>'obra_ref') is distinct from (p_datos->>'obra_ref') then
    raise exception using errcode='23514',message='Falta la extracción original de esta obra';
  end if;
  -- Ediciones que numeran cada jornada desde 1: desplazamientos recalculados desde el original.
  v_desplazamientos:=public.comprobar_numeracion_minima(p_datos,p_entrada_original);
  v_meta:=p_datos->'metadatos';
  if btrim(v_meta->>'titulo')='' or btrim(v_meta->>'edicion_base')='' then
    raise exception using errcode='23514',message='Título y edición no pueden estar vacíos';
  end if;
  if not exists (select 1 from public.autores where autor_id=p_autor
    and btrim(nombre_completo)=btrim(v_meta->>'autor_nombre')) then
    raise exception using errcode='23514',message='Selecciona un autor del catálogo y su nombre vigente';
  end if;
  select termino_id into v_genero from public.vocabularios
    where categoria='genero' and termino=v_meta->>'genero' and coalesce(activo,true);
  select termino_id into v_borrador from public.vocabularios where categoria='estado' and termino='borrador';
  select termino_id into v_tradicional from public.vocabularios where categoria='tipo_atribucion' and termino='tradicional';
  select termino_id into v_unica from public.vocabularios where categoria='modalidad_atribucion' and termino='unica';
  select termino_id into v_individual from public.vocabularios where categoria='composicion_autoria' and termino='individual';
  if v_genero is null or v_borrador is null or v_tradicional is null or v_unica is null or v_individual is null then
    raise exception using errcode='23514',message='Faltan referencias del vocabulario';
  end if;
  if (v_meta->>'fecha_inicio')::integer>(v_meta->>'fecha_fin')::integer then
    raise exception using errcode='23514',message='Fechas invertidas';
  end if;
  -- Un título coincidente pide revisión; no impone identidad, ni siquiera con el mismo autor.
  perform pg_advisory_xact_lock(hashtextextended(public.normalizar_titulo_importacion(v_meta->>'titulo'),1));
  select coalesce(array_agg(c.obra_id order by c.obra_id),array[]::uuid[]) into v_coincidencias
    from public.coincidencias_importacion_metrica(v_meta->>'titulo') c;
  if v_coincidencias is distinct from v_revisadas then
    raise exception using errcode='23505',message='Revisa las coincidencias antes de confirmar que se trata de otra obra';
  end if;
  v_prev:=null; v_num:=0;
  for v_fila in select value from jsonb_array_elements(p_datos->'jornadas') loop
    v_num:=v_num+1; v_inicio:=(v_fila->>'v_ini')::integer; v_fin:=(v_fila->>'v_fin')::integer;
    if (v_fila->>'numero')::integer<>v_num or v_fin<v_inicio
      or (v_prev is not null and v_inicio::bigint<>v_prev::bigint+1) then
      raise exception using errcode='23514',message='Jornadas desordenadas, discontinuas o con rangos invertidos';
    end if;
    v_prev:=v_fin;
  end loop;
  if (p_datos#>>'{segmentos,0,v_ini}')::integer<>(p_datos#>>'{jornadas,0,v_ini}')::integer or
    (p_datos->'segmentos'->-1->>'v_fin')::integer<>v_prev then
    raise exception using errcode='23514',message='Jornadas y segmentos no cubren el mismo rango';
  end if;
  if (select count(*)<>count(distinct value->>'ref') from jsonb_array_elements(p_datos->'segmentos')) then
    raise exception using errcode='23514',message='Referencias de segmento repetidas';
  end if;

  if p_obra is null then
  insert into public.obras_editoriales(obra_id,titulo,estado,tipo_ficha,visible_publico,genero_id,
    edicion,fecha_inicio_trad,fecha_fin_trad,fuente_fecha,observaciones)
  values(v_obra,v_meta->>'titulo',v_borrador,'basica',false,v_genero,v_meta->>'edicion_base',
    (v_meta->>'fecha_inicio')::integer,(v_meta->>'fecha_fin')::integer,v_meta->>'fuente_fecha',
    (select string_agg(value,E'\n' order by ord) from jsonb_array_elements_text(v_meta->'observaciones') with ordinality as o(value,ord)));
  else
    update public.obras set genero_id=coalesce(genero_id,v_genero) where obra_id=p_obra;
    insert into public.obras_dataciones(obra_id,clase,inicio,fin,fuente)
    select p_obra,'referencia',(v_meta->>'fecha_inicio')::integer,(v_meta->>'fecha_fin')::integer,v_meta->>'fuente_fecha'
    where (v_meta->>'fecha_inicio' is not null or v_meta->>'fecha_fin' is not null or nullif(v_meta->>'fuente_fecha','') is not null)
    on conflict(obra_id,clase) do update set inicio=excluded.inicio,fin=excluded.fin,
      fuente=coalesce(obras_dataciones.fuente,excluded.fuente)
    where obras_dataciones.inicio is null and obras_dataciones.fin is null;
  end if;
  if not exists(select 1 from public.atribuciones where obra_id=v_obra) then
  insert into public.grupos_atribucion(grupo_atribucion_id,obra_id) values(v_grupo,v_obra);
  insert into public.atribuciones(atribucion_id,obra_id,grupo_atribucion_id,tipo_atribucion_id,
    modalidad_atribucion_id,composicion_autoria_id,perfil_metrico,fuente_autoria)
  values(v_atribucion,v_obra,v_grupo,v_tradicional,v_unica,v_individual,true,v_meta->>'fundamento_autoria');
  insert into public.atribucion_autores(atribucion_id,autor_id,orden) values(v_atribucion,p_autor,1);
  insert into public.atribucion_evidencias(atribucion_id,tipo_atribucion_id,fuente_autoria,orden)
    values(v_atribucion,v_tradicional,v_meta->>'fundamento_autoria',1);
  end if;
  insert into public.jornadas(obra_id,jornada_num,v_ini,v_fin)
    select v_obra,(j->>'numero')::integer,(j->>'v_ini')::integer,(j->>'v_fin')::integer
    from jsonb_array_elements(p_datos->'jornadas') as r(j);
  insert into public.importaciones_metricas(importacion_id,obra_id,peticion_id,importado_por,
    importado_en,autor_id,genero_id,entrada_original,datos_confirmados,sha256_jsonb,coincidencias_revisadas)
  values(v_importacion,v_obra,p_peticion,v_actor,v_ahora,p_autor,v_genero,
    p_entrada_original,p_datos,encode(extensions.digest(convert_to(p_datos::text,'UTF8'),'sha256'),'hex'),v_revisadas);

  v_prev:=null;
  for v_fila in select value from jsonb_array_elements(p_datos->'segmentos') loop
    v_inicio:=(v_fila->>'v_ini')::integer; v_fin:=(v_fila->>'v_fin')::integer;
    if v_fin<v_inicio or (v_prev is not null and v_inicio::bigint<>v_prev::bigint+1) or not exists (
      select 1 from public.jornadas j where j.obra_id=v_obra and v_inicio>=j.v_ini
        and importar.v_fin<=j.v_fin) then
      raise exception using errcode='23514',message='Segmentos discontinuos, invertidos o fuera de jornada';
    end if;
    v_prev:=v_fin; v_total:=v_total+v_fin::bigint-v_inicio+1;
    perform public.comprobar_origen_minimo(v_fila,p_entrada_original,v_desplazamientos);
    perform public.comprobar_destino_minimo(v_fila->'identificacion');
    v_forma:=null; v_arquitectura:=null;
    if v_fila->'identificacion'<>'null'::jsonb then
      select forma_id into v_forma from public.formas_metricas where slug=v_fila#>>'{identificacion,forma_slug}';
      select arquitectura_id into v_arquitectura from public.arquitecturas_forma where forma_id=v_forma
        and slug=v_fila#>>'{identificacion,arquitectura_slug}';
    end if;
    if v_arquitectura is not null and jsonb_array_length(v_fila->'candidatas')>0 then
      raise exception using errcode='23514',message='Una arquitectura identificada no mantiene candidatas';
    end if;
    if (select count(*)<>count(distinct value) from jsonb_array_elements(v_fila->'candidatas')) then
      raise exception using errcode='23514',message='Candidatas repetidas';
    end if;
    for v_candidata in select value from jsonb_array_elements(v_fila->'candidatas') loop
      perform public.comprobar_destino_minimo(v_candidata);
      if v_forma is not null and ((v_candidata->>'forma_slug') is distinct from
        (v_fila#>>'{identificacion,forma_slug}') or v_candidata->>'arquitectura_slug' is null) then
        raise exception using errcode='23514',message='Candidata incompatible con la forma identificada';
      end if;
    end loop;
    for v_detalle in select value from jsonb_array_elements(v_fila->'detalles_fuente') loop
      if v_detalle ? 'rasgo_slug' and (v_forma is null or
        (v_detalle->>'rasgo_slug'='distico_final' and v_fin::bigint-v_inicio+1<2) or not exists (
          select 1 from public.rasgos_metricos r join public.rasgo_valores rv using(rasgo_id)
          join public.arquitectura_rasgos ar using(rasgo_id)
          join public.arquitecturas_forma a using(arquitectura_id)
          where r.slug=v_detalle->>'rasgo_slug' and rv.slug=v_detalle->>'valor_slug'
            and r.activo and rv.activo and a.activo and a.forma_id=v_forma
            and (ar.valor_id is null or ar.valor_id=rv.valor_id)
            and (v_arquitectura is null or a.arquitectura_id=v_arquitectura))) then
        raise exception using errcode='23514',message='Rasgo o valor ajeno a la forma y arquitectura conocidas';
      end if;
      if v_detalle->>'tipo_seccion'='remate' and (
        (v_detalle->>'n_versos')::integer>v_fin::bigint-v_inicio+1 or v_forma is null or not exists (
          select 1 from public.estructuras_secciones s join public.arquitecturas_forma a using(arquitectura_id)
          where a.forma_id=v_forma and a.activo and s.tipo_seccion=v_detalle->>'tipo_seccion'
            and (s.versos_min is null or (v_detalle->>'n_versos')::integer>=s.versos_min)
            and (s.versos_max is null or (v_detalle->>'n_versos')::integer<=s.versos_max)
            and (v_arquitectura is null or a.arquitectura_id=v_arquitectura))) then
        raise exception using errcode='23514',message='Detalle revisado sin contexto de catálogo o fuera del pasaje';
      end if;
    end loop;
    for v_desviacion in select value from jsonb_array_elements(v_fila->'desviaciones') loop
      if (v_desviacion->>'v_ini')::integer<v_inicio or (v_desviacion->>'v_fin')::integer>v_fin
        or (v_desviacion->>'v_fin')::integer<(v_desviacion->>'v_ini')::integer
        or not (v_fila#>'{origen,notas_ref}' ? (v_desviacion->>'nota_ref'))
        or not exists (select 1 from jsonb_array_elements(p_entrada_original->'notas') n
          where n->>'id'=v_desviacion->>'nota_ref'
            and n->>'texto_literal'=v_desviacion->>'texto_fuente')
        or (v_desviacion->>'dimension'='metro' and v_desviacion->>'relacion_norma' in ('sobra','falta'))
        or (v_desviacion->>'dimension'='estructura' and v_desviacion->>'relacion_norma' in ('menor_que_norma','mayor_que_norma'))
        or (v_desviacion->>'metro_observado_slug' is not null and not exists (
          select 1 from public.metros where slug=v_desviacion->>'metro_observado_slug' and activo)) then
        raise exception using errcode='23514',message='Desviación fuera del pasaje o sin referencia válida';
      end if;
    end loop;
    v_secuencia:=gen_random_uuid();
    insert into public.secuencias_metricas(secuencia_id,obra_id,v_ini,v_fin,n_versos)
      values(v_secuencia,v_obra,v_inicio,v_fin,v_fin-v_inicio+1);
    insert into public.metrica_minima_secuencias(secuencia_id,importacion_id,segmento_ref,forma_id,
      arquitectura_id,segmentacion,datos_minimos)
    values(v_secuencia,v_importacion,v_fila->>'ref',v_forma,v_arquitectura,v_fila->>'segmentacion',
      v_fila - array['ref','v_ini','v_fin','identificacion','segmentacion']);
  end loop;
  update public.obras_editoriales set total_versos=v_total::integer where obra_id=v_obra;
  return jsonb_build_object('obra_id',v_obra,'importacion_id',v_importacion,'repetida',false);
end;
$function$
;
revoke all on function public.guardar_ficha_basica(uuid,uuid,jsonb,jsonb,uuid[],uuid) from public,anon;
grant execute on function public.guardar_ficha_basica(uuid,uuid,jsonb,jsonb,uuid[],uuid) to authenticated;
-- Escritura única de la proyección. Las columnas editoriales antiguas quedan congeladas
-- para recuperación hasta la contracción; ninguna función adaptada debe leerlas.
create or replace function public.auth_puede_editar_obra(p_obra_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.fichas_completas f
  join public.editores e on e.user_id=auth.uid() join public.vocabularios v on v.termino_id=e.role
  where f.obra_id=p_obra_id and (f.procedencia_registro='legado' or f.inicio_elaboracion is not null)
   and coalesce(e.activo,true) and
   (v.termino in ('admin','ip') or (v.termino in ('editor','revisor') and f.editor_asignado=e.user_id)));
$$;
-- Los registros heredados no tienen una fecha de inicio reconstruible; mantienen su acceso.
create or replace function public.auth_obra_es_detallada(p_obra uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.fichas_completas f where f.obra_id=p_obra
  and (f.procedencia_registro='legado' or f.inicio_elaboracion is not null));
$$;
create or replace function public.auth_puede_ver_obra(p_obra_id uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select exists(select 1 from public.editores e join public.vocabularios v on v.termino_id=e.role
  where e.user_id=auth.uid() and coalesce(e.activo,true) and
   (v.termino in ('admin','ip') or exists(select 1 from public.fichas_completas f
    where f.obra_id=p_obra_id and (f.editor_asignado=e.user_id or exists(
     select 1 from public.obras_revisores r where r.obra_id=f.obra_id and r.revisor_id=e.user_id)))));
$$;

create or replace function public.escribir_obra_editorial() returns trigger
language plpgsql security definer set search_path='' as $$
declare
 actor uuid:=auth.uid(); gestor boolean:=public.auth_is_admin_or_ip();
 servicio boolean:=coalesce(nullif(current_setting('request.jwt.claims',true),'')::jsonb->>'role',current_setting('request.jwt.claim.role',true),'')='service_role'
                   or (actor is null and session_user in ('postgres','supabase_admin'));
 id uuid; borrador uuid; actual public.fichas_completas%rowtype; fechas jsonb; marca_actual timestamptz;
begin
 select termino_id into borrador from public.vocabularios where categoria='estado' and termino='borrador';
 if tg_op='INSERT' then
  if not(gestor or servicio or (new.tipo_ficha='basica' and public.auth_puede_importar_metrica())) then
   raise exception 'No puedes crear obras' using errcode='42501';
  end if;
  id:=coalesce(new.obra_id,gen_random_uuid());
  insert into public.obras(obra_id,titulo,titulo_normalizado,variantes_titulo,genero_id,total_versos,slug,estado,tipo_ficha)
  values(id,new.titulo,new.titulo_normalizado,new.variantes_titulo,new.genero_id,
   new.total_versos,coalesce(new.slug,''),borrador,case when new.tipo_ficha='basica' then 'minima' else 'completa' end);
  perform public.escribir_dataciones_obra(id,coalesce(new.dataciones,jsonb_build_array(
   jsonb_build_object('clase','referencia','inicio',new.fecha_inicio_trad,'fin',new.fecha_fin_trad,'fuente',new.fuente_fecha),
   jsonb_build_object('clase','metrica','inicio',new.fecha_inicio_metadrama,'fin',new.fecha_fin_metadrama))));
  if new.tipo_ficha='completa' or new.editor_asignado is not null or
     (new.tipo_ficha is null and (new.edicion is not null or new.estado is not null)) then
   insert into public.fichas_completas(obra_id,editor_asignado,fecha_asignacion,procedencia_registro,
    estado,edicion_base,bibliografia,observaciones,visible_publico,sin_figuras_donaire,
    sin_personajes_sobrenaturales,sin_eventos_sobrenaturales)
   values(id,new.editor_asignado,case when new.editor_asignado is not null then now() end,
    'nuevo',coalesce(new.estado,borrador),new.edicion,new.bibliografia,new.observaciones,
    coalesce(new.visible_publico,false),coalesce(new.sin_figuras_donaire,false),
    coalesce(new.sin_personajes_sobrenaturales,false),coalesce(new.sin_eventos_sobrenaturales,false));
  end if;
  -- Al importar, la fila de importación se escribe después y el tipo de la proyección aún es sin_ficha.
  new.obra_id:=id;
  select slug,created_at,updated_at,dataciones into new.slug,new.created_at,new.updated_at,new.dataciones from public.obras_editoriales where obra_id=id;
  return new;
 end if;
 id:=old.obra_id;
 select updated_at into marca_actual from public.obras where obra_id=id for update;
 if not found then raise exception 'Obra no encontrada' using errcode='P0002'; end if;
 if marca_actual is distinct from old.updated_at then
  raise exception 'La obra ha cambiado durante el guardado. Conserva los cambios y recarga los datos' using errcode='40001';
 end if;
 if new.obra_id is distinct from old.obra_id and tg_op='UPDATE' then raise exception 'No se cambia la identidad'; end if;
 if tg_op='DELETE' then
  if not(gestor or servicio) then raise exception 'No puedes eliminar obras' using errcode='42501'; end if;
  delete from public.obras where obra_id=id; return old;
 end if;
 if not(gestor or servicio or public.auth_puede_editar_obra(id)) then
  -- La RPC del importador completa extensión antes de confirmar la copia, sin elaboración completa.
  if not(public.auth_puede_importar_metrica() and (old.tipo_ficha='sin_ficha' or exists(
      select 1 from public.importaciones_metricas where obra_id=id and importado_por=actor)) and
    (to_jsonb(new)-'total_versos')=(to_jsonb(old)-'total_versos')) then
   raise exception 'No puedes editar esta obra' using errcode='42501';
  end if;
 end if;
 if new.tipo_ficha is distinct from old.tipo_ficha then
  raise exception 'Utiliza la operación de inicio o importación de ficha' using errcode='23514';
 end if;
 if old.tipo_ficha<>'completa' and row(new.editor_asignado,new.edicion,new.bibliografia,new.observaciones,
  new.visible_publico,new.estado,new.sin_figuras_donaire,new.sin_personajes_sobrenaturales,new.sin_eventos_sobrenaturales)
  is distinct from row(old.editor_asignado,old.edicion,old.bibliografia,old.observaciones,
  old.visible_publico,old.estado,old.sin_figuras_donaire,old.sin_personajes_sobrenaturales,old.sin_eventos_sobrenaturales) then
  raise exception 'Estos datos requieren una ficha completa' using errcode='PT409';
 end if;
 if not(gestor or servicio) and row(new.editor_asignado,new.visible_publico,new.autor_ficha_publico)
    is distinct from row(old.editor_asignado,old.visible_publico,old.autor_ficha_publico) then
  raise exception 'Asignación y publicación reservadas a gestores' using errcode='42501';
 end if;
 if not(gestor or servicio) and new.estado is distinct from old.estado and not exists(
  select 1 from public.vocabularios a cross join public.vocabularios b
  where a.termino_id=old.estado and b.termino_id=new.estado and
   (a.termino||':'||b.termino) in ('borrador:vista_previa','vista_previa:borrador',
     'vista_previa:listo_para_publicar','listo_para_publicar:borrador')) then
  raise exception 'Transición editorial no permitida' using errcode='42501';
 end if;
 if not(gestor or servicio) and old.tipo_ficha='completa' and old.estado<>borrador and
    (to_jsonb(new)-'estado') is distinct from (to_jsonb(old)-'estado') then
  raise exception 'El contenido solo se edita en borrador' using errcode='42501';
 end if;
 update public.obras set titulo=new.titulo,titulo_normalizado=new.titulo_normalizado,
  variantes_titulo=new.variantes_titulo,genero_id=new.genero_id,
  total_versos=new.total_versos,slug=new.slug where obra_id=id;
 if new.dataciones is distinct from old.dataciones then
  perform public.escribir_dataciones_obra(id,new.dataciones);
 elsif row(new.fecha_inicio_trad,new.fecha_fin_trad,new.fuente_fecha,new.fecha_inicio_metadrama,new.fecha_fin_metadrama)
   is distinct from row(old.fecha_inicio_trad,old.fecha_fin_trad,old.fuente_fecha,old.fecha_inicio_metadrama,old.fecha_fin_metadrama) then
  -- Compatibilidad temporal con clientes anteriores; las demás ediciones no pierden los calificadores.
  select jsonb_agg(coalesce((select to_jsonb(d)-'obra_id' from public.obras_dataciones d
   where d.obra_id=id and d.clase=x->>'clase'),'{}')||x) into fechas from jsonb_array_elements(jsonb_build_array(
   jsonb_build_object('clase','referencia','inicio',new.fecha_inicio_trad,'fin',new.fecha_fin_trad,'fuente',new.fuente_fecha),
   jsonb_build_object('clase','metrica','inicio',new.fecha_inicio_metadrama,'fin',new.fecha_fin_metadrama))) x;
  perform public.escribir_dataciones_obra(id,fechas);
 end if;
 update public.fichas_completas set editor_asignado=new.editor_asignado,
  fecha_asignacion=case when editor_asignado is distinct from new.editor_asignado then now() else fecha_asignacion end,
  edicion_base=new.edicion,bibliografia=new.bibliografia,observaciones=new.observaciones,
  estado=new.estado,visible_publico=new.visible_publico,fecha_cambio_estado=case when estado is distinct from new.estado then now() else fecha_cambio_estado end,
  sin_figuras_donaire=new.sin_figuras_donaire,sin_personajes_sobrenaturales=new.sin_personajes_sobrenaturales,
  sin_eventos_sobrenaturales=new.sin_eventos_sobrenaturales,updated_at=now() where obra_id=id;
 select * into new from public.obras_editoriales where obra_id=id;
 return new;
end $$;
revoke all on function public.escribir_obra_editorial() from public,anon,authenticated;
drop trigger if exists escritura_obra_editorial on public.obras_editoriales;
create trigger escritura_obra_editorial instead of insert or update or delete on public.obras_editoriales
 for each row execute function public.escribir_obra_editorial();

-- Mover los disparadores cuya semántica pertenece a la completa.
drop trigger if exists obras_declaran_por_sus_secuencias on public.obras;
drop trigger if exists completas_declaran_por_sus_secuencias on public.fichas_completas;
create trigger completas_declaran_por_sus_secuencias after update of sin_figuras_donaire,sin_personajes_sobrenaturales,sin_eventos_sobrenaturales
 on public.fichas_completas for each row execute function public.obra_declara_por_sus_secuencias();
drop trigger if exists trigger_obras_enforce_public_visibility on public.obras;
drop trigger if exists completas_visibilidad on public.fichas_completas;
create trigger completas_visibilidad before insert or update on public.fichas_completas
 for each row execute function public.obras_enforce_public_visibility();
drop trigger if exists trigger_obras_sync_autor_ficha_publico on public.obras;
drop trigger if exists completas_credito on public.fichas_completas;
create trigger completas_credito before insert or update of editor_asignado on public.fichas_completas
 for each row execute function public.sync_obra_autor_ficha_publico();
drop trigger if exists trg_obras_recuerda_su_publicacion on public.obras;
drop trigger if exists completas_recuerda_publicacion on public.fichas_completas;
create trigger completas_recuerda_publicacion before insert or update on public.fichas_completas
 for each row execute function public.obra_recuerda_su_publicacion();
drop trigger if exists trg_mark_autores_dirty_on_obra on public.obras;
drop trigger if exists completas_autores_dirty on public.fichas_completas;
create trigger completas_autores_dirty after update of visible_publico,estado on public.fichas_completas
 for each row execute function public.mark_autores_resumen_dirty_on_obra();
drop trigger if exists trg_mark_resumen_dirty_editor_asignado on public.obras;
drop trigger if exists completas_editor_dirty on public.fichas_completas;
create trigger completas_editor_dirty after update of editor_asignado on public.fichas_completas
 for each row execute function public.mark_obra_resumen_dirty_by_editor_asignado();

-- Una obra sin encargo no abre el editor. La creación de la completa es explícita.
create or replace function public.iniciar_ficha_completa(p_obra uuid,p_editor uuid default null,p_iniciar boolean default false)
returns void language plpgsql security definer set search_path='' as $$
declare actor uuid:=auth.uid(); borrador uuid; f public.fichas_completas%rowtype;
begin
 perform 1 from public.obras where obra_id=p_obra for update;
 if not found then raise exception 'Obra no encontrada' using errcode='P0002'; end if;
 if not public.auth_is_admin_or_ip() then
  select * into f from public.fichas_completas where obra_id=p_obra;
  if not found or f.editor_asignado is distinct from actor or not public.auth_puede_ver_obra(p_obra) or p_editor is not null then
   raise exception 'Solo gestores pueden encargar una completa' using errcode='42501';
  end if;
 elsif exists(select 1 from public.importaciones_metricas where obra_id=p_obra) and
       not exists(select 1 from public.fichas_completas where obra_id=p_obra) then
  raise exception 'La transición de básica a completa está pendiente' using errcode='23514';
 end if;
 if p_editor is not null and not exists(select 1 from public.editores where user_id=p_editor and coalesce(activo,true)) then
  raise exception 'Editor no disponible' using errcode='22023';
 end if;
 select termino_id into borrador from public.vocabularios where categoria='estado' and termino='borrador';
 insert into public.fichas_completas(obra_id,editor_asignado,fecha_asignacion,procedencia_registro,estado,inicio_elaboracion)
 values(p_obra,p_editor,case when p_editor is not null then now() end,'nuevo',borrador,case when p_iniciar then now() end)
 on conflict(obra_id) do update set inicio_elaboracion=case when p_iniciar then coalesce(fichas_completas.inicio_elaboracion,now()) else fichas_completas.inicio_elaboracion end;
end $$;
revoke all on function public.iniciar_ficha_completa(uuid,uuid,boolean) from public,anon;
grant execute on function public.iniciar_ficha_completa(uuid,uuid,boolean) to authenticated;

-- El núcleo no acepta escrituras directas de usuarios: pasan por la proyección con sus guardas.
create or replace function public.listar_corpus_gestion() returns jsonb
language plpgsql stable security definer set search_path='' as $$
begin
 if not public.auth_is_admin_or_ip() then raise exception 'Solo gestores pueden consultar corpus' using errcode='42501'; end if;
 return coalesce((select jsonb_agg(jsonb_build_object('codigo',codigo,'nombre',nombre) order by codigo) from public.corpus),'[]'::jsonb);
end $$;
revoke all on function public.listar_corpus_gestion() from public,anon;
grant execute on function public.listar_corpus_gestion() to authenticated;

create or replace function public.destino_importacion_metrica(p_obra uuid) returns jsonb
language plpgsql stable security definer set search_path='' as $$
begin
 if not public.auth_puede_importar_metrica() then raise exception 'No puedes importar' using errcode='42501'; end if;
 return (select jsonb_build_object('obra_id',o.obra_id,'titulo',o.titulo) from public.obras_editoriales o
  where o.obra_id=p_obra and o.tipo_ficha='sin_ficha');
end $$;
revoke all on function public.destino_importacion_metrica(uuid) from public,anon;
grant execute on function public.destino_importacion_metrica(uuid) to authenticated;

create or replace function public.gestionar_corpus(p_operacion text,p_codigo text,p_nombre text default null,p_obras uuid[] default '{}')
returns void language plpgsql security definer set search_path='' as $$
declare id uuid;
begin
 if not public.auth_is_admin_or_ip() then raise exception 'Solo gestores pueden modificar corpus' using errcode='42501'; end if;
 if p_operacion not in ('crear','renombrar','anadir','retirar') or p_codigo is null or btrim(p_codigo)='' then
  raise exception 'Operación o código inválido' using errcode='22023'; end if;
 if p_operacion='crear' then
  if p_nombre is null or btrim(p_nombre)='' then raise exception 'Indica un nombre' using errcode='22023'; end if;
  insert into public.corpus(codigo,nombre) values(btrim(p_codigo),btrim(p_nombre)); return;
 end if;
 select corpus_id into id from public.corpus where codigo=p_codigo for update;
 if not found then raise exception 'Corpus no encontrado' using errcode='P0002'; end if;
 if p_operacion='renombrar' then
  if p_nombre is null or btrim(p_nombre)='' then raise exception 'Indica un nombre' using errcode='22023'; end if;
  update public.corpus set nombre=btrim(p_nombre) where corpus_id=id; return;
 end if;
 if coalesce(cardinality(p_obras),0) not between 1 and 500 then raise exception 'Selecciona entre 1 y 500 obras' using errcode='22023'; end if;
 if p_operacion='anadir' then
  insert into public.obras_corpus(obra_id,corpus_id) select distinct unnest(p_obras),id on conflict do nothing;
 else delete from public.obras_corpus where corpus_id=id and obra_id=any(p_obras); end if;
end $$;
revoke all on function public.gestionar_corpus(text,text,text,uuid[]) from public,anon;
grant execute on function public.gestionar_corpus(text,text,text,uuid[]) to authenticated;

revoke insert,update,delete on public.obras from authenticated,anon;
-- El escritor antiguo es SECURITY DEFINER: revocar la tabla por sí solo no lo desactiva.
-- Se conserva para la reversión, sin permitir nuevas importaciones fuera del contrato básico.
revoke execute on function public.guardar_ficha_minima(uuid,uuid,jsonb,jsonb,uuid[]) from public,anon,authenticated,service_role;
-- Sustituir políticas SELECT permisivas antiguas; no esconder solo la pestaña.
do $$ declare p record; begin
 for p in select policyname from pg_policies where schemaname='public' and tablename='obras' and cmd='SELECT' loop
  execute format('drop policy %I on public.obras',p.policyname);
 end loop;
end $$;
create policy obras_consulta_editorial on public.obras for select to authenticated using(
 public.auth_is_admin_or_ip() or public.auth_puede_ver_obra(obra_id) or
 (public.auth_puede_importar_metrica() and exists(select 1 from public.importaciones_metricas i where i.obra_id=obras.obra_id)));
-- La salida individual pública sigue exclusivamente en RPC y artefactos autorizados.
revoke select on public.obras,public.obras_editoriales from anon;
-- Los lectores públicos necesitan identidad/visibilidad antes de recuperar su artefacto.
-- Proyección cerrada: nunca entrega observaciones, bibliografía ni datos de importación.
create or replace view public.obras_consulta_publica with(security_barrier=true) as
 select o.obra_id,o.titulo,o.slug,o.genero_id,f.estado,f.visible_publico,f.editor_asignado,
  dr.inicio as fecha_inicio_trad,dr.fin as fecha_fin_trad,dm.inicio as fecha_inicio_metadrama,dm.fin as fecha_fin_metadrama,
  o.total_versos,o.updated_at,
  coalesce((select jsonb_agg(to_jsonb(d)-'obra_id' order by d.clase) from public.obras_dataciones d where d.obra_id=o.obra_id),'[]'::jsonb) as dataciones
 from public.obras o join public.fichas_completas f using(obra_id)
 left join public.obras_dataciones dr on dr.obra_id=o.obra_id and dr.clase='referencia'
 left join public.obras_dataciones dm on dm.obra_id=o.obra_id and dm.clase='metrica'
 where public.can_view_obra_ficha_publica(o.obra_id,true);
revoke all on public.obras_consulta_publica from public;
grant select on public.obras_consulta_publica to anon,authenticated,service_role;
notify pgrst,'reload schema';
-- Las políticas legadas dependían de obras.editor_asignado. Ese campo queda congelado.
-- Las mismas relaciones de estructura y autoría consultan ahora el encargo vigente.
do $$ declare p record; usar text; comprobar text; sentencia text; begin
 for p in select * from pg_policies where schemaname='public'
  and tablename not in ('obras','fichas_completas')
  and policyname not in ('jornadas_importadas_consulta','secuencias_importadas_consulta')
  and (coalesce(qual,'')||coalesce(with_check,'')) ~ '\mobras o\M' loop
  usar:=regexp_replace(p.qual,'\m(public\.)?obras o\M','public.fichas_completas o','g');
  comprobar:=regexp_replace(p.with_check,'\m(public\.)?obras o\M','public.fichas_completas o','g');
  sentencia:=format('alter policy %I on public.%I',p.policyname,p.tablename);
  if usar is not null then sentencia:=sentencia||' using ('||usar||')'; end if;
  if comprobar is not null then sentencia:=sentencia||' with check ('||comprobar||')'; end if;
  execute sentencia;
 end loop;
end $$;
alter policy jornadas_importadas_consulta on public.jornadas using (
 exists(select 1 from public.importaciones_metricas i where i.obra_id=jornadas.obra_id and i.usada_en_corpus)
 and public.auth_puede_consultar_importacion(jornadas.obra_id));
alter policy secuencias_importadas_consulta on public.secuencias_metricas using (
 exists(select 1 from public.importaciones_metricas i where i.obra_id=secuencias_metricas.obra_id and i.usada_en_corpus)
 and public.auth_puede_consultar_importacion(secuencias_metricas.obra_id));
-- Ampliar el contrato JSON sin reinterpretar ni reescribir importaciones históricas.
do $$
declare p record; original text; nueva text;
begin
 for p in select oid,proname from pg_proc where pronamespace='public'::regnamespace and proname in (
  'autor_ficha_artefacto_json','ficha_publica_base_json','get_autor_publico',
  'recompute_artefactos_globales','corpus_comparativas_artefacto_json') loop
  original:=pg_get_functiondef(p.oid);
  if original ~ '''dataciones''\s*,' then continue; end if;
  if p.proname='corpus_comparativas_artefacto_json' then
   nueva:=replace(original,'''fecha_inicio_trad'', (meta ->> ''fecha_inicio_trad'')::integer,',
    '''dataciones'', coalesce(meta -> ''dataciones'',''[]''::jsonb), ''fecha_inicio_trad'', (meta ->> ''fecha_inicio_trad'')::integer,');
  else
   nueva:=regexp_replace(original,'''fecha_inicio_trad'',\s*([a-z_]+)\.fecha_inicio_trad,',
    '''dataciones'', \1.dataciones, ''fecha_inicio_trad'', \1.fecha_inicio_trad,');
  end if;
  if nueva=original then raise exception 'No se encontró el productor de dataciones: %',p.proname; end if;
  execute nueva;
 end loop;
end $$;

commit;

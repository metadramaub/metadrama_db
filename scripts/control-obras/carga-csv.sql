-- Consumido por preparar-carga-csv.mjs. La entrada conserva literalmente el CSV y su hash.
-- No crea fichas, no asigna responsables, no interpreta el año de ordenación ni toca métrica.
do $$
declare r record; p jsonb; e jsonb; oid uuid; gid uuid; aid uuid; pid uuid;
 tipo uuid; composicion uuid; modalidad uuid; modalidad_desconocida uuid; fuente text; marca text; fuente_general text;
begin
 select termino_id into modalidad from public.vocabularios where categoria='modalidad_atribucion' and termino='unica';
 select termino_id into modalidad_desconocida from public.vocabularios where categoria='modalidad_atribucion' and termino='desconocida';
 for r in select fila from _carga_control_candidata loop
  oid:=(r.fila->>'obra_id')::uuid;
  perform 1 from public.obras where obra_id=oid for update;
  if not found then raise exception 'No existe el destino de fila %',r.fila->>'numero'; end if;
  marca:=format('CSV control de corpus %s, fila %s',left(r.fila->>'origen_sha256',12),r.fila->>'numero');
  fuente_general:=marca||E'\nAtribución tradicional: '||(r.fila#>>'{fuente_original,Atribución tradicional}')||
   E'\nResultado ETSO: '||(r.fila->>'resultado_etso');
  if r.fila->>'corpus' is not null then
   insert into public.obras_corpus(obra_id,corpus_id)
   select oid,corpus_id from public.corpus where codigo=r.fila->>'corpus' on conflict do nothing;
   if not exists(select 1 from public.corpus where codigo=r.fila->>'corpus') then raise exception 'Corpus inexistente'; end if;
  end if;
  insert into public.obras_dataciones(obra_id,clase,inicio,fin,inicio_inclusivo,fin_inclusivo,aproximada,fuente)
  values(oid,'referencia',(r.fila#>>'{fecha,inicio}')::integer,(r.fila#>>'{fecha,fin}')::integer,
   (r.fila#>>'{fecha,inicio_inclusivo}')::boolean,(r.fila#>>'{fecha,fin_inclusivo}')::boolean,(r.fila#>>'{fecha,aproximada}')::boolean,
   marca||E'\nDatación CSV: '||(r.fila->>'fecha_literal')||E'\nFuente: '||coalesce(r.fila->>'fuente_fecha',''))
  on conflict(obra_id,clase) do update set inicio=excluded.inicio,fin=excluded.fin,
   inicio_inclusivo=excluded.inicio_inclusivo,fin_inclusivo=excluded.fin_inclusivo,aproximada=excluded.aproximada,
   fuente=coalesce(nullif(obras_dataciones.fuente,''),excluded.fuente)
  where obras_dataciones.inicio is null and obras_dataciones.fin is null and
   (excluded.inicio is not null or excluded.fin is not null or nullif(obras_dataciones.fuente,'') is null);
  select grupo_atribucion_id into gid from public.grupos_atribucion where obra_id=oid order by created_at limit 1;
  if gid is null then insert into public.grupos_atribucion(obra_id) values(oid) returning grupo_atribucion_id into gid; end if;
  for p in select value from jsonb_array_elements(r.fila->'propuestas') loop
   aid:=null;
   if p->>'autor' is not null then
    select autor_id into aid from public.autores where nombre_completo=p->>'autor';
    if aid is null then insert into public.autores(nombre_completo) values(p->>'autor') returning autor_id into aid; end if;
   end if;
   select termino_id into composicion from public.vocabularios where categoria='composicion_autoria'
    and termino=case when aid is null then 'desconocida' else 'individual' end;
   select a.atribucion_id into pid from public.atribuciones a where a.grupo_atribucion_id=gid
    and a.composicion_autoria_id=composicion and
     (select coalesce(array_agg(aa.autor_id order by aa.autor_id),'{}') from public.atribucion_autores aa where aa.atribucion_id=a.atribucion_id)
      =case when aid is null then '{}'::uuid[] else array[aid] end limit 1;
   if pid is null then
    select termino_id into tipo from public.vocabularios where categoria='tipo_atribucion' and termino=p#>>'{evidencias,0,tipo}';
    insert into public.atribuciones(grupo_atribucion_id,obra_id,tipo_atribucion_id,modalidad_atribucion_id,composicion_autoria_id,fuente_autoria,perfil_metrico)
    values(gid,oid,tipo,case when aid is null then modalidad_desconocida else modalidad end,composicion,fuente_general,false) returning atribucion_id into pid;
    if aid is not null then insert into public.atribucion_autores(atribucion_id,autor_id,orden) values(pid,aid,1); end if;
   end if;
   for e in select value from jsonb_array_elements(p->'evidencias') loop
    select termino_id into tipo from public.vocabularios where categoria='tipo_atribucion' and termino=e->>'tipo';
    fuente:=fuente_general||E'\nLectura de esta evidencia: '||(e->>'literal');
    if exists(select 1 from public.atribucion_evidencias where atribucion_id=pid and tipo_atribucion_id=tipo) then
     update public.atribucion_evidencias set fuente_autoria=concat_ws(E'\n\n',nullif(fuente_autoria,''),fuente)
     where atribucion_id=pid and tipo_atribucion_id=tipo and position(marca in coalesce(fuente_autoria,''))=0;
    else
     insert into public.atribucion_evidencias(atribucion_id,tipo_atribucion_id,fuente_autoria) values(pid,tipo,fuente);
    end if;
   end loop;
  end loop;
 end loop;
end $$;

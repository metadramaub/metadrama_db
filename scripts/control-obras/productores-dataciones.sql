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

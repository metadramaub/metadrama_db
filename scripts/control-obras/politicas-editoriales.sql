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

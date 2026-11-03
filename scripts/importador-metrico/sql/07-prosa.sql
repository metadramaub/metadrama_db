-- Valida la procedencia de secuencias unidas por prosa sin alterar las filas de la edición.
create or replace function public.comprobar_origen_minimo(p_fila jsonb,p_original jsonb)
returns void language plpgsql set search_path='' as $$
declare
 refs jsonb:=coalesce(p_fila#>'{origen,tramos_ref}',jsonb_build_array(p_fila#>>'{origen,tramo_ref}'));
 r jsonb; anterior jsonb; prosa jsonb; c jsonb; n integer:=0;
 ord bigint; prev_ord bigint; jornada integer; lo integer; hi integer;
 inicio integer:=(p_fila->>'v_ini')::integer; fin integer:=(p_fila->>'v_fin')::integer;
begin
 if jsonb_array_length(refs)<>(select count(distinct value) from jsonb_array_elements(refs))
   or refs->>0 is distinct from p_fila#>>'{origen,tramo_ref}' then
  raise exception using errcode='23514',message='Referencias de origen inválidas';
 end if;
 for c in select value from jsonb_array_elements(refs) loop
  select t,orden into r,ord from jsonb_array_elements(p_original->'tramos') with ordinality as x(t,orden)
    where t->>'id'=c#>>'{}';
  if r is null or r->>'v_ini' is null or r->>'v_fin' is null then
   raise exception using errcode='23514',message='Fila métrica de origen inexistente o sin rango';
  end if;
  if anterior is null then
   lo:=(r->>'v_ini')::integer; jornada:=(r->>'jornada')::integer;
   if (r->>'fuente_id') is distinct from (p_fila#>>'{origen,fuente_id}') or
      (r->>'denominacion_literal') is distinct from (p_fila#>>'{origen,denominacion_literal}') then
    raise exception using errcode='23514',message='El segmento no corresponde a su fila de origen';
   end if;
  else
   prosa:=p_original->'tramos'->(prev_ord::integer);
   if ord<>prev_ord+2 or (r->>'v_ini')::integer<>(anterior->>'v_fin')::integer+1 or
      (r->>'jornada')::integer is distinct from jornada or jornada is null or
      (prosa->>'jornada')::integer is distinct from jornada or
      lower(btrim(prosa->>'denominacion_literal')) !~ '^(carta en |pasaje en )?prosa$' or
      prosa->>'denominacion_literal' is null or prosa->>'v_ini' is not null or
      prosa->>'v_fin' is not null or prosa->>'n_versos_fuente' is not null then
    raise exception using errcode='23514',message='La unión requiere prosa sin numeración entre filas consecutivas de una jornada';
   end if;
   if (anterior->>'v_fin')::integer>=inicio and (r->>'v_ini')::integer<=fin then
    n:=n+1;
    if not exists(select 1 from jsonb_array_elements(coalesce(p_fila->'caracterizaciones','[]')) p
      where p->>'termino'='prosa' and p->>'tramo_ref'=prosa->>'id'
       and p->>'literal'=prosa->>'denominacion_literal'
       and (p->>'v_ini')::integer=(anterior->>'v_fin')::integer
       and (p->>'v_fin')::integer=(r->>'v_ini')::integer) then
     raise exception using errcode='23514',message='Falta localizar la prosa de la unión';
    end if;
   end if;
  end if;
  hi:=(r->>'v_fin')::integer; anterior:=r; prev_ord:=ord;
 end loop;
 if lo>inicio or hi<fin or lo is null or hi is null then
  raise exception using errcode='23514',message='El segmento no corresponde a su fila de origen';
 end if;
 if jsonb_array_length(coalesce(p_fila->'caracterizaciones','[]'))<>n then
  raise exception using errcode='23514',message='Caracterización de prosa sin origen o fuera del pasaje';
 end if;
 for c in select value from jsonb_array_elements(p_fila#>'{origen,notas_ref}') loop
  if not exists(select 1 from jsonb_array_elements(p_original->'notas') nota
    where nota->>'id'=c#>>'{}' and exists(select 1 from jsonb_array_elements_text(refs) as z(ref)
      where nota->'tramos_ref' ? ref)) then
   raise exception using errcode='23514',message='Nota sin correspondencia con el tramo original';
  end if;
 end loop;
end;
$$;
revoke all on function public.comprobar_origen_minimo(jsonb,jsonb) from public,anon,authenticated;

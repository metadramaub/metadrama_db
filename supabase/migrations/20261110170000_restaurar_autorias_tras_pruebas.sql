-- El IP confirmó que estas tres atribuciones a Lope procedían de sus pruebas y pidió revertirlas.
-- Se corrige únicamente el autor de las propuestas existentes, conservando evidencias y estructura.
begin;
set local lock_timeout='5s';
set local statement_timeout='60s';
do $$
declare caso record; obra uuid; propuesta uuid; anterior uuid; destino uuid; n integer;
begin
 for caso in select * from (values
  ('dido-y-eneas','Dido y Eneas','Guillem de Castro'),
  ('valor-agravio-y-mujer','Valor, agravio y mujer','Ana Caro de Mallén'),
  ('el-amor-al-uso','El amor al uso','Antonio de Solís')
 ) x(slug,titulo,autor) loop
  select o.obra_id into obra from public.obras o where o.slug=caso.slug and replace(o.titulo,chr(160),' ')=caso.titulo for update;
  if obra is null then raise exception 'No se identifica inequívocamente %',caso.titulo; end if;
  select a.autor_id into destino from public.autores a where a.nombre_completo=caso.autor;
  if destino is null then raise exception 'Falta el autor %',caso.autor; end if;
  select count(*) into n from public.atribuciones a where a.obra_id=obra;
  if n<>1 then raise exception 'Han cambiado las propuestas de %; revisar antes de corregir',caso.titulo; end if;
  select a.atribucion_id into propuesta from public.atribuciones a where a.obra_id=obra for update;
  select count(*) into n from public.atribucion_autores aa where aa.atribucion_id=propuesta;
  if n<>1 then raise exception 'Han cambiado los autores de %; revisar antes de corregir',caso.titulo; end if;
  select aa.autor_id into anterior from public.atribucion_autores aa where aa.atribucion_id=propuesta for update;
  if anterior=destino then continue; end if;
  if not exists(select 1 from public.autores where autor_id=anterior and nombre_completo='Lope de Vega') then
   raise exception 'La autoría de % ya no corresponde a la prueba indicada; no se sobrescribe',caso.titulo;
  end if;
  update public.atribucion_autores set autor_id=destino where atribucion_id=propuesta and autor_id=anterior;
  if not found then raise exception 'No se pudo corregir %',caso.titulo; end if;
 end loop;
end $$;
commit;

-- CANDIDATA DE PREPARACIÓN. Fuera de supabase/migrations: no desplegar con db push.
-- Fase aditiva; las columnas originales siguen siendo autoritativas para la app actual.
begin;
set local lock_timeout='5s';
set local statement_timeout='120s';
do $$ begin
 if current_database()<>'control_obras_preparacion' then
  raise exception 'Candidata restringida a la restauración local control_obras_preparacion';
 end if;
 if exists(select 1 from public.obras where tipo_ficha not in ('minima','completa')) then
  raise exception 'Tipos de origen desconocidos';
 end if;
end $$;

create table if not exists public.fichas_completas (
 obra_id uuid primary key references public.obras(obra_id) on delete cascade,
 editor_asignado uuid references public.editores(user_id),
 fecha_asignacion timestamptz,
 inicio_elaboracion timestamptz,
 procedencia_registro text not null check(procedencia_registro in ('legado','nuevo')),
 edicion_base text,
 bibliografia text,
 observaciones text,
 sin_figuras_donaire boolean not null default false,
 sin_personajes_sobrenaturales boolean not null default false,
 sin_eventos_sobrenaturales boolean not null default false,
 estado uuid not null references public.vocabularios(termino_id),
 visible_publico boolean,
 fecha_cambio_estado timestamptz,
 fecha_publicacion timestamptz,
 autor_ficha_publico text,
 created_at timestamptz not null default now(),
 updated_at timestamptz not null default now()
);
comment on column public.fichas_completas.inicio_elaboracion is
 'Inicio explícito; NULL en registros heredados porque no se conoce. No se deduce de asignación, created_at ni cantidad de anotación.';
comment on column public.fichas_completas.procedencia_registro is
 'Legado conserva todas las obras antes marcadas completa, sin certificar que se hubieran iniciado.';

insert into public.fichas_completas(
 obra_id,editor_asignado,fecha_asignacion,inicio_elaboracion,procedencia_registro,
 edicion_base,bibliografia,observaciones,sin_figuras_donaire,sin_personajes_sobrenaturales,
 sin_eventos_sobrenaturales,estado,visible_publico,fecha_cambio_estado,fecha_publicacion,
 autor_ficha_publico,created_at,updated_at)
select obra_id,editor_asignado,fecha_asignacion,null,'legado',edicion,bibliografia,observaciones,
 sin_figuras_donaire,sin_personajes_sobrenaturales,sin_eventos_sobrenaturales,
 estado,visible_publico,fecha_cambio_estado,fecha_publicacion,autor_ficha_publico,created_at,updated_at
from public.obras where tipo_ficha='completa'
on conflict(obra_id) do nothing;

create table if not exists public.corpus (
 corpus_id uuid primary key default gen_random_uuid(),
 codigo text not null unique check(btrim(codigo)<>''),
 nombre text not null check(btrim(nombre)<>''),
 descripcion text,
 activo boolean not null default true,
 created_at timestamptz not null default now()
);
create table if not exists public.obras_corpus (
 obra_id uuid not null references public.obras(obra_id) on delete cascade,
 corpus_id uuid not null references public.corpus(corpus_id) on delete restrict,
 primary key(obra_id,corpus_id)
);
create index if not exists obras_corpus_por_corpus on public.obras_corpus(corpus_id,obra_id);
-- Los códigos están acordados; nombres definitivos y pertenencias se gestionarán después.
insert into public.corpus(codigo,nombre) values
 ('C60','Canon60'),('TAD','Teatro de Dido'),('LOPE','Métrica de Lope de Vega')
on conflict(codigo) do nothing;

alter table public.fichas_completas enable row level security;
alter table public.corpus enable row level security;
alter table public.obras_corpus enable row level security;
revoke all on public.fichas_completas,public.corpus,public.obras_corpus from public,anon,authenticated;
grant all on public.fichas_completas,public.corpus,public.obras_corpus to service_role;
grant select on public.fichas_completas,public.corpus,public.obras_corpus to authenticated;
drop policy if exists ficha_completa_consulta on public.fichas_completas;
create policy ficha_completa_consulta on public.fichas_completas for select to authenticated
 using(public.auth_puede_ver_obra(obra_id));
drop policy if exists corpus_gestores_consulta on public.corpus;
create policy corpus_gestores_consulta on public.corpus for select to authenticated
 using(public.auth_is_admin_or_ip());
drop policy if exists obras_corpus_gestores_consulta on public.obras_corpus;
create policy obras_corpus_gestores_consulta on public.obras_corpus for select to authenticated
 using(public.auth_is_admin_or_ip());

-- Proyección del futuro control. No cambia todavía el listado ni los permisos antiguos.
create or replace view public.control_obras_preparacion with(security_invoker=true) as
select o.obra_id,o.titulo,o.slug,o.genero_id,o.fecha_inicio_trad,o.fecha_fin_trad,o.fuente_fecha,
 case when f.obra_id is not null then 'completa'
      when i.importacion_id is not null then 'basica' else 'sin_ficha' end as tipo_ficha,
 f.editor_asignado,f.fecha_asignacion,f.inicio_elaboracion,f.procedencia_registro,
 f.estado,f.visible_publico,f.edicion_base as edicion_completa,
 i.importacion_id,i.importado_por,i.importado_en,
 i.datos_confirmados#>>'{metadatos,edicion_base}' as edicion_basica,
 coalesce((select array_agg(c.codigo order by c.codigo)
   from public.obras_corpus oc join public.corpus c using(corpus_id)
   where oc.obra_id=o.obra_id),'{}'::text[]) as corpus
from public.obras o left join public.fichas_completas f using(obra_id)
left join public.importaciones_metricas i on i.obra_id=o.obra_id and i.usada_en_corpus
where public.auth_is_admin_or_ip();
revoke all on public.control_obras_preparacion from public,anon;
grant select on public.control_obras_preparacion to authenticated,service_role;

-- La repetición no puede ocultar una copia divergente.
do $$ begin
 if exists(select 1 from public.obras o full join public.fichas_completas f using(obra_id)
 where (o.tipo_ficha='completa' or f.obra_id is not null) and (
   o.obra_id is null or o.tipo_ficha<>'completa' or f.obra_id is null or
   row(o.editor_asignado,o.fecha_asignacion,o.edicion,o.bibliografia,o.observaciones,
       o.sin_figuras_donaire,o.sin_personajes_sobrenaturales,o.sin_eventos_sobrenaturales,
       o.estado,o.visible_publico,o.fecha_cambio_estado,o.fecha_publicacion,o.autor_ficha_publico,
       o.created_at,o.updated_at)
   is distinct from
   row(f.editor_asignado,f.fecha_asignacion,f.edicion_base,f.bibliografia,f.observaciones,
       f.sin_figuras_donaire,f.sin_personajes_sobrenaturales,f.sin_eventos_sobrenaturales,
       f.estado,f.visible_publico,f.fecha_cambio_estado,f.fecha_publicacion,f.autor_ficha_publico,
       f.created_at,f.updated_at))) then
  raise exception 'El traslado de los campos completos no conserva el origen';
 end if;
end $$;
commit;

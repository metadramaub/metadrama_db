begin;

-- Bloque B de la migración estructural del dominio métrico.
--
-- Hasta ahora un verso se podía expresar de dos maneras incompatibles: como término
-- del vocabulario genérico (`metro_id`) o como modelo de verso del dominio
-- (`modelo_verso_id`), y una restricción obligaba a elegir exactamente una. El criterio
-- para decidir no estaba escrito en ninguna parte: era «si necesita hemistiquios,
-- cámbiate de tabla». 200 posiciones usaban la primera vía y 8 la segunda.
--
-- El metro pasa a ser una entidad del dominio: su medida y, cuando la tiene, su
-- estructura interna. Un octosílabo es un metro simple sin segmentos; un alejandrino,
-- uno compuesto de dos heptasílabos.
--
-- Se conservan los UUID de origen como identificadores de los metros nuevos, así que
-- ninguna de las 348 referencias existentes necesita reescribirse: solo cambia la tabla
-- a la que apuntan.

create table public.metros (
	metro_id uuid primary key default gen_random_uuid(),
	slug text not null unique check (slug = btrim(slug) and slug <> ''),
	nombre text not null check (btrim(nombre) <> ''),
	silabas integer not null check (silabas > 0),
	tipo text not null default 'simple' check (tipo in ('simple', 'compuesto')),
	-- El arte no se almacena como verdad independiente: se deriva de la medida.
	arte text generated always as (case when silabas >= 9 then 'mayor' else 'menor' end) stored,
	tipo_cesura text null,
	descripcion text null,
	estado_revision text not null default 'borrador'
		check (estado_revision in ('borrador', 'revisada', 'aprobada', 'retirada')),
	activo boolean not null default true,
	orden integer null,
	origen_termino_id uuid null unique
		references public.vocabularios (termino_id) on update cascade on delete set null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now()
);

comment on table public.metros is
	'Tipos de verso del dominio métrico: su medida y, si es compuesto, su estructura interna. Sustituye al doble mecanismo de metro del vocabulario y modelo de verso.';
comment on column public.metros.arte is
	'Arte mayor o menor derivado del número de sílabas. No se declara ni se edita.';

create table public.metro_segmentos (
	segmento_id uuid primary key default gen_random_uuid(),
	metro_id uuid not null references public.metros (metro_id)
		on update cascade on delete cascade,
	posicion integer not null check (posicion > 0),
	silabas integer not null check (silabas > 0),
	funcion text null,
	pausa_posterior text null,
	alternativa integer not null default 1 check (alternativa > 0),
	nota text null,
	created_at timestamptz not null default now(),
	updated_at timestamptz not null default now(),
	unique (metro_id, alternativa, posicion)
);

comment on table public.metro_segmentos is
	'Hemistiquios de un metro compuesto. Un metro simple no tiene segmentos.';

-- 1 · Los metros simples heredan el identificador del término de origen, de modo que
-- las claves ajenas existentes siguen siendo válidas sin reescribir un solo valor.

insert into public.metros (
	metro_id, slug, nombre, silabas, tipo, estado_revision, activo, orden, origen_termino_id
)
select
	termino.termino_id,
	termino.termino,
	initcap(replace(termino.termino, '_', ' ')),
	termino.numero_silabas,
	'simple',
	'revisada',
	termino.activo,
	termino.orden,
	termino.termino_id
from public.vocabularios termino
where termino.categoria = 'metro'
	and termino.numero_silabas is not null;

-- 2 · El único modelo de verso existente —el dodecasílabo compuesto de la copla de arte
-- mayor— pasa a ser un metro por derecho propio, distinto del dodecasílabo simple.

insert into public.metros (
	metro_id, slug, nombre, silabas, tipo, tipo_cesura, descripcion, estado_revision, activo
)
select
	modelo.modelo_verso_id,
	modelo.slug,
	modelo.nombre,
	coalesce(modelo.silabas_totales, 12),
	'compuesto',
	modelo.tipo_cesura,
	modelo.descripcion,
	modelo.estado_revision,
	modelo.activo
from public.modelos_verso modelo;

insert into public.metro_segmentos (
	metro_id, posicion, silabas, funcion, pausa_posterior, alternativa, nota
)
select
	segmento.modelo_verso_id,
	segmento.posicion,
	segmento.silabas,
	segmento.funcion,
	segmento.pausa_posterior,
	segmento.alternativa,
	segmento.nota
from public.modelo_verso_segmentos segmento;

-- 3 · El alejandrino recupera su estructura. Hasta ahora era un verso de catorce
-- sílabas sin partes, indistinguible de cualquier otro de esa medida.

update public.metros
set tipo = 'compuesto',
	tipo_cesura = 'central',
	descripcion = coalesce(
		descripcion,
		'Verso de catorce sílabas organizado en dos hemistiquios heptasílabos.'
	)
where slug = 'alejandrino';

insert into public.metro_segmentos (metro_id, posicion, silabas, funcion, pausa_posterior)
select metro.metro_id, posicion.posicion, 7, posicion.funcion, posicion.pausa
from public.metros metro
cross join (
	values (1, 'primer_hemistiquio', 'cesura'), (2, 'segundo_hemistiquio', null)
) as posicion (posicion, funcion, pausa)
where metro.slug = 'alejandrino';

-- 4 · Las referencias dejan de apuntar al vocabulario genérico.

alter table public.esquema_metrico_posiciones
	drop constraint patron_metrico_posiciones_metro_id_fkey,
	drop constraint patron_metrico_posiciones_modelo_verso_id_fkey,
	drop constraint patron_metrico_posiciones_check;

update public.esquema_metrico_posiciones
set metro_id = coalesce(metro_id, modelo_verso_id);

alter table public.esquema_metrico_posiciones
	drop column modelo_verso_id;

alter table public.esquema_metrico_posiciones
	alter column metro_id set not null,
	add constraint esquema_metrico_posiciones_metro_id_fkey
		foreign key (metro_id) references public.metros (metro_id)
		on update cascade on delete restrict;

alter table public.esquema_metrico_opciones
	drop constraint patron_metrico_opciones_metro_id_fkey,
	add constraint esquema_metrico_opciones_metro_id_fkey
		foreign key (metro_id) references public.metros (metro_id)
		on update cascade on delete restrict;

alter table public.opciones_eleccion_metrica
	drop constraint opciones_eleccion_metrica_metro_id_fkey,
	add constraint opciones_eleccion_metrica_metro_id_fkey
		foreign key (metro_id) references public.metros (metro_id)
		on update cascade on delete restrict;

-- 5 · Los modelos de verso desaparecen absorbidos, y con ellos `patron_acentual`:
-- el proyecto no registra el ritmo acentual de los versos.

drop table public.modelo_verso_segmentos;
drop table public.modelos_verso;

-- 6 · Permisos y auditoría, con el mismo patrón que el resto del catálogo.

do $$
declare
	v_table text;
begin
	foreach v_table in array array['metros', 'metro_segmentos']
	loop
		execute format('alter table public.%I enable row level security', v_table);
		execute format(
			'create policy %I on public.%I for all to authenticated using (public.auth_is_admin_or_ip()) with check (public.auth_is_admin_or_ip())',
			v_table || '_admin_ip',
			v_table
		);
		execute format(
			'grant select, insert, update, delete on table public.%I to authenticated',
			v_table
		);
		execute format(
			'create trigger %I before update on public.%I for each row execute function public.actualizar_updated_at()',
			'trigger_' || v_table || '_updated_at',
			v_table
		);
		execute format(
			'create trigger %I after insert or update or delete on public.%I for each statement execute function public.marcar_catalogo_metrico_actualizado()',
			'trigger_' || v_table || '_catalogo_revision',
			v_table
		);
	end loop;
end;
$$;

create index metro_segmentos_metro_idx on public.metro_segmentos (metro_id);

update public.catalogo_metrico_estado
set modelo_version = 44,
	actualizado_en = now()
where id = true;

commit;

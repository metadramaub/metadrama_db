begin;

-- Secciones y repeticiones reciben identificador legible.
--
-- Eran las dos únicas entidades del catálogo sin `slug`, y por eso solo se podían nombrar
-- por su UUID. La consecuencia se vio al generar las preguntas de medida del villancico:
-- hubo que inventar `medida_mudanza_2`, donde el `_2` lo puso el orden de aparición y
-- cambiaría de dueño si mañana se añade una sección intermedia.
--
-- La nomenclatura es la del resto del catálogo: minúsculas, palabras separadas por guion
-- bajo, y el nombre dice solo lo que su contexto no dice.
--
--   secciones     el tipo de sección; si se repite dentro de la arquitectura, se distingue
--                 por el ancestro que las separa
--   repeticiones  el tipo, precisado con la modalidad concreta que declara
--
-- La única arquitectura con tipos repetidos es la del villancico cuyo estribillo aparece
-- tras la primera copla: su primer ciclo es estructuralmente distinto de los siguientes, y
-- ni el padre desambigua, porque las dos mudanzas cuelgan de sendas coplas. La distinción
-- sube al ciclo.

-- ---------------------------------------------------------------------------
-- 1 · Secciones
-- ---------------------------------------------------------------------------

alter table public.estructuras_secciones add column if not exists slug text;

update public.estructuras_secciones set slug = tipo_seccion where slug is null;

-- Las del villancico con estribillo tardío que cuelgan del primer ciclo, distinguidas por él:
-- ni el padre las separa, porque las dos mudanzas cuelgan de sendas coplas.
with recursive descendencia as (
	select seccion.seccion_id
	from public.estructuras_secciones seccion
	where seccion.tipo_seccion = 'primer_ciclo'
	union all
	select hija.seccion_id
	from public.estructuras_secciones hija
	join descendencia on descendencia.seccion_id = hija.seccion_padre_id
)
update public.estructuras_secciones seccion
set slug = seccion.tipo_seccion || '_inicial'
where seccion.seccion_id in (select seccion_id from descendencia)
	and seccion.tipo_seccion in ('copla', 'mudanza', 'enlace_vuelta');

do $$
declare
	v_duplicados integer;
begin
	select count(*) into v_duplicados
	from (
		select arquitectura_id, slug
		from public.estructuras_secciones
		group by arquitectura_id, slug
		having count(*) > 1
	) as repetidos;
	if v_duplicados <> 0 then
		raise exception '% slugs de sección repetidos dentro de su arquitectura', v_duplicados;
	end if;
end;
$$;

alter table public.estructuras_secciones
	alter column slug set not null,
	add constraint estructuras_secciones_slug_check
		check (slug = btrim(slug) and slug <> ''),
	add constraint estructuras_secciones_arquitectura_slug_key
		unique (arquitectura_id, slug);

comment on column public.estructuras_secciones.slug is
	'Identificador legible y estable dentro de su arquitectura. Deriva del tipo de sección y se precisa cuando ese tipo se repite.';

-- ---------------------------------------------------------------------------
-- 2 · Repeticiones
-- ---------------------------------------------------------------------------

alter table public.repeticiones_metricas add column if not exists slug text;

-- Lo que distingue a tres represas idénticas está hoy en la opción que las apunta.
update public.repeticiones_metricas repeticion
set slug = case opcion.slug
	when 'total' then 'represa_total'
	when 'parcial' then 'represa_parcial'
	when 'implicita' then 'represa_implicita'
	when 'sin_represa_material' then 'represa_ausente'
	else opcion.slug
end
from public.opciones_eleccion_metrica opcion
where opcion.repeticion_id = repeticion.repeticion_id;

update public.repeticiones_metricas set slug = tipo where slug is null;

do $$
declare
	v_duplicados integer;
begin
	select count(*) into v_duplicados
	from (
		select arquitectura_id, slug
		from public.repeticiones_metricas
		group by arquitectura_id, slug
		having count(*) > 1
	) as repetidos;
	if v_duplicados <> 0 then
		raise exception '% slugs de repetición repetidos dentro de su arquitectura', v_duplicados;
	end if;
end;
$$;

alter table public.repeticiones_metricas
	alter column slug set not null,
	add constraint repeticiones_metricas_slug_check
		check (slug = btrim(slug) and slug <> ''),
	add constraint repeticiones_metricas_arquitectura_slug_key
		unique (arquitectura_id, slug);

comment on column public.repeticiones_metricas.slug is
	'Identificador legible y estable dentro de su arquitectura. Deriva del tipo y de la modalidad concreta que declara.';

-- ---------------------------------------------------------------------------
-- 3 · Las preguntas de medida dejan de numerarse por orden de aparición
-- ---------------------------------------------------------------------------

update public.grupos_eleccion_metrica grupo
set slug = format('medida_%s', seccion.slug)
from public.estructuras_secciones seccion
where seccion.seccion_id = grupo.seccion_id
	and grupo.slug like 'medida\_%'
	and grupo.dimension = 'metro';

do $$
declare
	v_mal integer;
begin
	select count(*) into v_mal
	from public.grupos_eleccion_metrica
	where slug ~ '_[0-9]+$' and slug like 'medida\_%';
	if v_mal <> 0 then
		raise exception 'Quedan % preguntas de medida numeradas por orden', v_mal;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 53,
	revision = revision + 1,
	actualizado_en = now();

commit;

-- La primera estancia de la canción declara el patrón.
--
-- `define_norma` ya obliga a que las respuestas de metro y rima coincidan entre las
-- realizaciones de una sección. Faltaba declarar dos hechos distintos que la interfaz no podía
-- deducir de ese booleano: que la primera realización es el lugar donde se declara la norma y
-- que su extensión también se repite. Sin este dato el editor ofrecía tres estancias editables
-- y un atajo de copia, aunque las fuentes dicen que el patrón de la primera debe repetirse
-- rigurosamente en las demás.

begin;

alter table public.estructuras_secciones
	add column if not exists primera_realizacion_define_patron boolean not null default false;

comment on column public.estructuras_secciones.primera_realizacion_define_patron is
	'La primera realización declara la extensión y las respuestas que definen la norma; las realizaciones posteriores las heredan y solo una desviación puede contradecirlas.';

update public.estructuras_secciones s
set
	primera_realizacion_define_patron = true,
	nota = 'La primera estancia declara la extensión, las medidas por posición y el esquema de rima; las demás los repiten exactamente.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where s.arquitectura_id = a.arquitectura_id
	and f.slug = 'cancion_petrarquista'
	and a.slug = 'estancias_consonantes_variables'
	and s.slug = 'estancia';

-- El remate no hereda necesariamente la estancia. Las fuentes admiten una estancia completa,
-- un fragmento —a menudo parte de la sirima— o un esquema nuevo; el único repertorio métrico
-- común que fijan es la combinación de heptasílabos y endecasílabos.
update public.estructuras_secciones s
set
	nota = 'Puede reproducir una estancia completa, tomar solo una parte —a menudo la sirima— o presentar un esquema nuevo, siempre con heptasílabos y endecasílabos. Suele comenzar con un verso suelto y dirigirse a la propia canción.',
	updated_at = now()
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where s.arquitectura_id = a.arquitectura_id
	and f.slug = 'cancion_petrarquista'
	and s.slug = 'remate';

-- La extensión compartida se protege también fuera de la interfaz. Es un constraint trigger
-- diferido porque el guardado sustituye el árbol completo dentro de una transacción.
create or replace function public.validar_extension_patron_realizaciones_editor_metrico()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
declare
	v_secuencia_id uuid := coalesce(new.secuencia_prueba_id, old.secuencia_prueba_id);
	v_incompatibles integer;
begin
	select count(*)
	into v_incompatibles
	from (
		select r.seccion_id, r.realizacion_padre_id
		from public.realizaciones_editor_metrico r
		join public.estructuras_secciones s on s.seccion_id = r.seccion_id
		where r.secuencia_prueba_id = v_secuencia_id
			and s.primera_realizacion_define_patron
		group by r.seccion_id, r.realizacion_padre_id
		having count(distinct (r.v_fin - r.v_ini + 1)) > 1
	) discrepancias;

	if v_incompatibles > 0 then
		raise exception 'Las realizaciones cuyo patrón declara la primera deben tener la misma extensión';
	end if;

	return null;
end;
$function$;

drop trigger if exists realizaciones_editor_metrico_extension_patron
	on public.realizaciones_editor_metrico;

create constraint trigger realizaciones_editor_metrico_extension_patron
after insert or update or delete on public.realizaciones_editor_metrico
deferrable initially deferred
for each row execute function public.validar_extension_patron_realizaciones_editor_metrico();

do $$
declare
	v_total integer;
	v_mal integer;
begin
	select count(*) into v_total
	from public.estructuras_secciones s
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where s.primera_realizacion_define_patron;

	if v_total <> 1 then
		raise exception 'Hay % secciones cuyo patrón declara la primera, en vez de 1', v_total;
	end if;

	select count(*) into v_mal
	from public.estructuras_secciones s
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where s.primera_realizacion_define_patron
		and not (
			f.slug = 'cancion_petrarquista'
			and a.slug = 'estancias_consonantes_variables'
			and s.slug = 'estancia'
		);

	if v_mal <> 0 then
		raise exception 'La marca de patrón se aplicó a una sección inesperada';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

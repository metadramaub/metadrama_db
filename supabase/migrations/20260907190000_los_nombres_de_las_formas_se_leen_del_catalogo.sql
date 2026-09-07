-- Los nombres de las formas se leen del catálogo
--
-- Las tablas precomputadas guardan **slugs**, y la etiqueta visible se resuelve al leer. Ese
-- resolutor —`loadPublicVocabulario`— seguía preguntándole al vocabulario legado, así que con los
-- slugs del catálogo nuevo acertaba por casualidad cuando el nombre coincidía y fallaba cuando no:
-- en la ficha de autor se leían «Romance» y «Redondilla» junto a «silva» y «seguidilla» en
-- minúscula, que es el slug crudo saliendo a la pantalla.
--
-- Esta función le da lo mismo que le daba el vocabulario, pero del catálogo: **las formas**, con su
-- tradición; **las arquitecturas**, colgando de su forma, que es la jerarquía que el catálogo de
-- obras usa para agrupar; y **los esquemas de rima**, que son lo que ahora guarda
-- `subtipos_presentes`. Los metros van también, que antes venían de la categoría `metro`.
--
-- Es `security definer` a propósito, como el resto de lo que sirve a la zona pública: son nombres
-- que la ficha de cualquier obra publicada ya enseña.

begin;

create or replace function public.vocabulario_metrico_publico()
returns table (
	categoria text,
	termino_id uuid,
	termino text,
	etiqueta text,
	termino_padre_id uuid,
	nivel integer,
	tipo_forma text,
	orden integer
)
language sql
stable
security definer
set search_path to 'public'
as $function$
	-- Las formas, que son las que agrupan.
	select
		'estrofa_tipo'::text,
		f.forma_id,
		f.slug,
		f.nombre,
		null::uuid,
		1,
		case t.nombre
			when 'Española' then 'forma_espanola'
			when 'Italiana' then 'forma_italiana'
		end,
		null::integer
	from public.formas_metricas f
	left join public.formas_tradiciones ft on ft.forma_id = f.forma_id
	left join public.tradiciones_metricas t on t.tradicion_id = ft.tradicion_id
	where f.activo

	union all

	-- Las arquitecturas, colgando de su forma: es la jerarquía que el buscador agrupa.
	select
		'estrofa_tipo'::text,
		a.arquitectura_id,
		a.slug,
		a.nombre,
		a.forma_id,
		2,
		null,
		a.orden
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where a.activo and f.activo

	union all

	-- Los esquemas de rima, que es lo que guarda hoy `subtipos_presentes`.
	select
		'estrofa_tipo'::text,
		er.esquema_rima_id,
		er.slug,
		coalesce(er.nombre, er.notacion),
		a.forma_id,
		2,
		null,
		null::integer
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where a.activo and f.activo and er.slug is not null

	union all

	select
		'metro'::text,
		m.metro_id,
		m.slug,
		m.nombre,
		null::uuid,
		1,
		null,
		m.orden
	from public.metros m
	where m.activo;
$function$;

comment on function public.vocabulario_metrico_publico() is
	'Los nombres visibles del catálogo métrico para la zona pública: formas, arquitecturas, esquemas de rima y metros, con la forma de una fila de vocabulario para que el resolutor de etiquetas no distinga de dónde vienen.';

grant execute on function public.vocabulario_metrico_publico() to anon, authenticated;

do $guarda$
declare
	v_formas integer;
	v_metros integer;
	v_sin_nombre integer;
begin
	select
		count(*) filter (where categoria = 'estrofa_tipo' and nivel = 1),
		count(*) filter (where categoria = 'metro'),
		count(*) filter (where etiqueta is null or btrim(etiqueta) = '')
	into v_formas, v_metros, v_sin_nombre
	from public.vocabulario_metrico_publico();

	if v_formas = 0 then
		raise exception 'La función no devuelve ninguna forma.';
	end if;
	if v_metros = 0 then
		raise exception 'La función no devuelve ningún metro.';
	end if;
	if v_sin_nombre > 0 then
		raise exception '% filas salen sin nombre visible', v_sin_nombre;
	end if;

	raise notice 'Vocabulario métrico público: % formas y % metros, todos con nombre', v_formas, v_metros;
end
$guarda$;

commit;

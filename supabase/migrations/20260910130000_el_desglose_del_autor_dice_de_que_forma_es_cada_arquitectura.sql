-- El desglose del perfil de autor dice de qué forma es cada arquitectura
--
-- `perfil_formas_hijos_rango` agregaba por el slug de la arquitectura a secas, y **esos slugs no
-- son únicos**: `octosilabica` existe en ocho formas —romance, redondilla, sextilla, terceto,
-- septilla, octava aguda y las dos coplas—, `endecasilabica` en otras ocho, `heterometrica_
-- consonante` en las seis liras. El desglose no se leía mal: **contaba mal**, sumando en un mismo
-- cubo los versos de formas distintas. En los resúmenes de autor de hoy, seis de las quince claves
-- eran ambiguas.
--
-- La clave pasa a ser `forma_slug/arquitectura_slug`, que es la que identifica de verdad una
-- arquitectura. `recompute_autor_resumen` no se toca: agrega sumando por clave de texto, y le da
-- igual cuál sea.
--
-- Esto vino de la sustitución del 7 de septiembre de 2026: hasta entonces la clave era el término
-- hoja del vocabulario legado, que sí era único en todo el árbol. Al pasar a la arquitectura se
-- perdió esa garantía sin que nadie lo notara, porque el nombre seguía saliendo por pantalla.

create or replace function public.perfil_formas_hijos_rango(p_obra_id uuid, p_v_ini integer default null::integer, p_v_fin integer default null::integer)
returns jsonb
language sql
stable
security definer
set search_path to 'public'
as $function$
	select coalesce(jsonb_object_agg(clave, versos), '{}'::jsonb)
	from (
		select fo.forma_slug || '/' || fo.arquitectura_slug as clave, sum(fo.n_versos)::int as versos
		from public.formas_de_la_obra(p_obra_id) fo
		where (p_v_ini is null or fo.v_ini >= p_v_ini)
			and (p_v_fin is null or fo.v_fin <= p_v_fin)
			and fo.arquitectura_slug is not null
			and fo.forma_slug is not null
		group by 1
	) t;
$function$;

-- ---------------------------------------------------------------------------
-- La guarda ejecuta la función, no solo la declara
--
-- Un cuerpo entrecomillado no se revalida al aplicarse: hay que llamarlo. Se busca una obra
-- publicada con arquitecturas anotadas y se comprueba que todas sus claves llevan ya la forma
-- delante y nombran un par que existe en el catálogo.
-- ---------------------------------------------------------------------------
do $guarda$
declare
  v_obra   uuid;
  v_perfil jsonb;
  v_malas  text;
begin
  select sm.obra_id into v_obra
  from public.secuencias_metricas sm
  join public.anotaciones_metricas a on a.secuencia_id = sm.secuencia_id
  where a.arquitectura_id is not null
  group by sm.obra_id
  order by count(*) desc
  limit 1;

  if v_obra is null then
    raise notice 'Sin obras con arquitectura anotada: la guarda no puede ejecutar la función.';
    return;
  end if;

  v_perfil := public.perfil_formas_hijos_rango(v_obra, null, null);

  if v_perfil = '{}'::jsonb then
    raise exception 'perfil_formas_hijos_rango devolvió vacío para una obra con arquitecturas anotadas.';
  end if;

  select string_agg(kv.key, ', ')
  into v_malas
  from jsonb_each_text(v_perfil) kv
  where not exists (
    select 1
    from public.arquitecturas_forma a
    join public.formas_metricas f on f.forma_id = a.forma_id
    where f.slug || '/' || a.slug = kv.key
  );

  if v_malas is not null then
    raise exception 'Estas claves del desglose no nombran un par forma/arquitectura del catálogo: %', v_malas;
  end if;
end;
$guarda$;

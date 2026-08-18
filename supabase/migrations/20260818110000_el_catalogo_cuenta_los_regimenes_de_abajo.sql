-- El catálogo cuenta también los regímenes que se declaran abajo
--
-- El régimen de rima se declara en dos niveles: en la arquitectura cuando es uno, y en cada
-- disposición cuando dentro de ella varía. El listado de `/formas` y la cabecera de la ficha
-- solo miraban el primero, y **descartaban en silencio** las arquitecturas que no lo declaran.
--
-- Dos consecuencias medidas. La canción petrarquista se anunciaba «rima Consonante» a secas,
-- ocultando que una de sus tres arquitecturas no rima. Y el villancico, cuyas dos arquitecturas
-- mezclan asonante y consonante y por eso no lo declaran arriba, **no aparecía bajo ningún
-- filtro de rima**: se quedaba fuera del buscador entero.
--
-- Lo que faltaba no era un dato sino leerlo: los esquemas ya declaran su régimen. La ficha lo
-- tiene todo en su carga; el listado no traía los esquemas, así que se le añade la lista de
-- regímenes de cada arquitectura, ya resumida.
--
-- Esto **no rellena hacia arriba**: `arquitecturas_forma.tipo_rima_id` sigue vacío donde debe
-- estarlo, y la tarjeta de la arquitectura sigue diciendo «según la disposición». Lo que cambia
-- es solo el resumen de la forma, que es la unión de lo que sus arquitecturas usan de verdad.

begin;

create or replace function public.get_catalogo_formas_publicas()
returns jsonb
language sql
stable
set search_path to 'public'
as $function$
	select jsonb_build_object(
		'formas', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.nombre)
			from (
				select forma_id, slug, nombre, definicion, tipo_registro, nivel_estructural, orden
				from public.formas_metricas
				where activo
			) x
		), '[]'::jsonb),
		'arquitecturas', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.orden nulls last, x.nombre)
			from (
				select
					a.arquitectura_id,
					a.forma_id,
					a.tipo_rima_id,
					a.orden,
					a.nombre,
					-- Los regímenes que declaran sus disposiciones. Es el mismo dato que la ficha
					-- lee de `esquemasRima`; aquí se resume porque el listado no carga esquemas.
					coalesce((
						select jsonb_agg(distinct er.tipo_rima_id)
						from public.esquemas_rima er
						where er.arquitectura_id = a.arquitectura_id
							and er.tipo_rima_id is not null
					), '[]'::jsonb) as regimenes_de_disposicion
				from public.arquitecturas_forma a
				where a.activo
			) x
		), '[]'::jsonb),
		'tiposRima', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.termino)
			from (
				select termino_id, termino, etiqueta
				from public.vocabularios
				where categoria = 'tipo_rima'
			) x
		), '[]'::jsonb),
		'denominaciones', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.nombre)
			from (
				select forma_id, arquitectura_id, esquema_rima_id, nombre, preferente
				from public.denominaciones_metricas
				where forma_id is not null
			) x
		), '[]'::jsonb),
		'tradiciones', coalesce((
			select jsonb_agg(to_jsonb(x) order by x.nombre)
			from (
				select tradicion_id, nombre
				from public.tradiciones_metricas
			) x
		), '[]'::jsonb),
		'formasTradiciones', coalesce((
			select jsonb_agg(to_jsonb(x))
			from (
				select forma_id, tradicion_id
				from public.formas_tradiciones
			) x
		), '[]'::jsonb)
	);
$function$;

-- Una función SQL no está probada hasta que se ejecuta: se ejecuta aquí y se comprueba que la
-- canción y el villancico traen ya los dos regímenes que sus disposiciones declaran.
do $$
declare
	v_payload jsonb;
	v_cancion integer;
	v_villancico integer;
begin
	v_payload := public.get_catalogo_formas_publicas();

	if v_payload is null or v_payload->'arquitecturas' is null then
		raise exception 'El catálogo público no devuelve arquitecturas.';
	end if;

	select count(distinct r.valor) into v_cancion
	from jsonb_array_elements(v_payload->'arquitecturas') a
	cross join lateral jsonb_array_elements_text(a->'regimenes_de_disposicion') as r(valor)
	where a->>'forma_id' = (
		select forma_id::text from public.formas_metricas where slug = 'cancion_petrarquista'
	);

	if v_cancion < 2 then
		raise exception 'La canción declara % regímenes de disposición; se esperaban al menos 2.', v_cancion;
	end if;

	select count(distinct r.valor) into v_villancico
	from jsonb_array_elements(v_payload->'arquitecturas') a
	cross join lateral jsonb_array_elements_text(a->'regimenes_de_disposicion') as r(valor)
	where a->>'forma_id' = (
		select forma_id::text from public.formas_metricas where slug = 'villancico'
	);

	if v_villancico < 2 then
		raise exception 'El villancico declara % regímenes de disposición; se esperaban al menos 2.', v_villancico;
	end if;
end $$;

commit;

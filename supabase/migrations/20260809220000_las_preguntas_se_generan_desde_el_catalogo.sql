-- Las preguntas del editor se generan desde el catálogo.
--
-- Culmina la auditoría de las preguntas. Hasta aquí se declaró todo lo que faltaba —los siete
-- huecos— y se soltó la respuesta de la opción para que regenerarlas no rompa nada guardado.
-- Esto añade la pieza que faltaba: **la función que las deriva**.
--
-- OCTAVO HUECO. Al escribirla apareció uno más, y del mismo tipo que los otros: **un grupo de
-- dimensión rasgo no declara sobre qué rasgo pregunta**. Se sabía solo mirando sus opciones, que
-- es justo lo que se quiere poder regenerar. Se añade `rasgo_id` al grupo.
--
-- Queda una excepción declarada: `rasgos_de_la_serie` del endecasílabo suelto reúne **dos
-- rasgos independientes** —dístico final y encadenamiento interior— en una sola pregunta de
-- casillas. Eso no es un rasgo con varios valores sino dos preguntas de sí o no presentadas
-- juntas, y su `rasgo_id` queda nulo a propósito. La generación lo respeta y no lo toca.
--
-- CÓMO SE DERIVA CADA DIMENSIÓN, que es lo que la revisión ha ido estableciendo:
--
--   rima        Los esquemas concretos de la arquitectura, o los de la que reutiliza su
--               sección. Los abiertos y los de restricciones nunca son opción: declaran que la
--               norma no fija la disposición.
--   metro       Si el conjunto es de medida uniforme, un juego de metros para todo el tramo;
--               si no, ese juego por cada posición. Cuando hay roles declarados solo se
--               ofrecen los quebrados, porque el verso dominante se da por sentado.
--   rasgo       Los valores que la arquitectura admite: los que declara, o todos los del
--               vocabulario cuando deja el eje abierto.
--   repetición  Las repeticiones de la arquitectura, con el comportamiento que ellas mismas
--               declaran desde que se mudó ahí.
--   combinación Las variedades de la arquitectura.
--
-- LA FUNCIÓN NO ESCRIBE POR DEFECTO. `generar_opciones_eleccion_metrica()` devuelve qué
-- cambiaría; solo con `p_aplicar => true` toca la tabla. Es deliberado: mientras las etiquetas
-- se sigan escribiendo a mano conviene ver el efecto antes de causarlo, y un informe que se
-- puede pedir cuando se quiera es además la manera de detectar que el dato y la pregunta se han
-- separado.

begin;

-- ---------------------------------------------------------------------------
-- 1 · La pregunta de rasgo declara sobre qué rasgo pregunta
-- ---------------------------------------------------------------------------

alter table public.grupos_eleccion_metrica
	add column if not exists rasgo_id uuid references public.rasgos_metricos (rasgo_id)
		on update cascade on delete cascade;

comment on column public.grupos_eleccion_metrica.rasgo_id is
	'Rasgo sobre el que pregunta, en los grupos de dimensión rasgo. Nulo cuando la pregunta reúne varios rasgos independientes en una sola lista de casillas, que es presentación y no un rasgo con varios valores.';

update public.grupos_eleccion_metrica g
set rasgo_id = u.rasgo_id, updated_at = now()
from (
	select o.grupo_eleccion_id, min(rv.rasgo_id::text)::uuid as rasgo_id
	from public.opciones_eleccion_metrica o
	join public.rasgo_valores rv on rv.valor_id = o.valor_rasgo_id
	group by o.grupo_eleccion_id
	having count(distinct rv.rasgo_id) = 1
) u
where u.grupo_eleccion_id = g.grupo_eleccion_id;

-- ---------------------------------------------------------------------------
-- 2 · La derivación
-- ---------------------------------------------------------------------------

create or replace function public.opciones_eleccion_derivadas()
returns table (
	grupo_eleccion_id uuid,
	metro_id uuid,
	esquema_metrico_id uuid,
	esquema_rima_id uuid,
	seccion_id uuid,
	repeticion_id uuid,
	valor_rasgo_id uuid,
	variedad_id uuid,
	posicion_unidad integer,
	materializa_seccion_id uuid,
	extension_desde_seccion_id uuid,
	orden integer
)
language sql
stable
set search_path to 'public'
as $function$
	-- Rima
	select g.grupo_eleccion_id, null::uuid, null::uuid, er.esquema_rima_id, null::uuid,
		null::uuid, null::uuid, null::uuid, null::integer, null::uuid, null::uuid,
		row_number() over (partition by g.grupo_eleccion_id order by er.notacion, er.slug)::integer
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
	join public.esquemas_rima er
		on er.arquitectura_id = coalesce(s.arquitectura_referenciada_id, a.arquitectura_id)
	where g.dimension = 'rima'
		and g.tipo_control = 'opciones'
		and g.activo
		and er.tipo_secuencia not in ('abierta', 'restricciones')

	union all

	-- Metro. La medida uniforme se responde una vez para el tramo; la que varía, por posición.
	select g.grupo_eleccion_id, adm.metro_id, null::uuid, null::uuid, null::uuid,
		null::uuid, null::uuid, null::uuid, pos.posicion, null::uuid, null::uuid,
		row_number() over (
			partition by g.grupo_eleccion_id order by pos.posicion, adm.silabas
		)::integer
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
	join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
	join lateral (
		select eo.metro_id, mt.silabas
		from public.esquema_metrico_opciones eo
		join public.metros mt on mt.metro_id = eo.metro_id
		where eo.esquema_metrico_id = em.esquema_metrico_id
			and (
				not exists (
					select 1 from public.esquema_metrico_opciones e2
					where e2.esquema_metrico_id = em.esquema_metrico_id and e2.rol is not null
				)
				or eo.rol = 'quebrado'
			)
	) adm on true
	join lateral (
		select case when em.medida_uniforme then null::integer else n end as posicion
		from generate_series(
			1,
			case when em.medida_uniforme then 1
				else coalesce(
					s.versos_max,
					-- Una sección contenedora no declara su extensión: la suma de sus partes.
					-- Es la regla que ya rige en el modelo, «cualquier estructura con secciones
					-- deriva de las secciones», y la estancia sin rima es el caso: su cuerpo
					-- llega a dieciocho versos y su pareado final añade dos.
					(
						select sum(h.versos_max)::integer
						from public.estructuras_secciones h
						where h.seccion_padre_id = s.seccion_id
					),
					a.unidad_versos_max,
					1
				) end
		) as n
	) pos on true
	where g.dimension = 'metro'
		and g.tipo_control = 'opciones'
		and g.activo
		and em.medida_uniforme is not null

	union all

	-- Metro declarado por posiciones. Cuando el esquema fija una secuencia y una de sus
	-- posiciones admite varias medidas, la pregunta es por esa posición: el tercer verso de la
	-- seguidilla gitana puede ser de diez, once o doce sílabas.
	select g.grupo_eleccion_id, p.metro_id, null::uuid, null::uuid, null::uuid,
		null::uuid, null::uuid, null::uuid, p.posicion, null::uuid, null::uuid,
		p.alternativa::integer
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
	join public.esquema_metrico_posiciones p
		on p.esquema_metrico_id = em.esquema_metrico_id
	where g.dimension = 'metro'
		and g.tipo_control = 'opciones'
		and g.activo
		and em.medida_uniforme is null
		and p.posicion in (
			select p2.posicion
			from public.esquema_metrico_posiciones p2
			where p2.esquema_metrico_id = em.esquema_metrico_id
			group by p2.posicion
			having count(distinct p2.metro_id) > 1
		)

	union all

	-- Rasgo. Los valores que la arquitectura admite para el rasgo por el que pregunta.
	select g.grupo_eleccion_id, null::uuid, null::uuid, null::uuid, null::uuid,
		null::uuid, adm.valor_id, null::uuid, null::integer, null::uuid, null::uuid,
		row_number() over (partition by g.grupo_eleccion_id order by adm.orden)::integer
	from public.grupos_eleccion_metrica g
	join lateral (
		select distinct coalesce(ar.valor_id, rv.valor_id) as valor_id, rv.orden
		from public.arquitectura_rasgos ar
		join public.rasgo_valores rv on rv.rasgo_id = ar.rasgo_id and rv.activo
		where ar.arquitectura_id = g.arquitectura_id
			and ar.rasgo_id = g.rasgo_id
			and (ar.valor_id is null or ar.valor_id = rv.valor_id)
	) adm on true
	where g.dimension = 'rasgo'
		and g.tipo_control = 'opciones'
		and g.activo
		and g.rasgo_id is not null

	union all

	-- Repetición, con el comportamiento que la propia repetición declara.
	select g.grupo_eleccion_id, null::uuid, null::uuid, null::uuid, null::uuid,
		rp.repeticion_id, null::uuid, null::uuid, null::integer,
		rp.materializa_seccion_id, rp.extension_desde_seccion_id,
		row_number() over (partition by g.grupo_eleccion_id order by rp.slug)::integer
	from public.grupos_eleccion_metrica g
	join public.repeticiones_metricas rp on rp.arquitectura_id = g.arquitectura_id
	where g.dimension = 'repeticion'
		and g.tipo_control = 'opciones'
		and g.activo

	union all

	-- Combinación: las variedades reconocidas.
	select g.grupo_eleccion_id, null::uuid, null::uuid, null::uuid, null::uuid,
		null::uuid, null::uuid, v.variedad_id, null::integer, null::uuid, null::uuid,
		row_number() over (partition by g.grupo_eleccion_id order by v.orden, v.slug)::integer
	from public.grupos_eleccion_metrica g
	join public.variedades_arquitectura v on v.arquitectura_id = g.arquitectura_id
	where g.dimension = 'combinacion'
		and g.tipo_control = 'opciones'
		and g.activo
$function$;

comment on function public.opciones_eleccion_derivadas() is
	'Las opciones que el catálogo produce para cada pregunta del editor. Es la única definición de qué se admite: la usan la generación y, más adelante, la validación.';

-- ---------------------------------------------------------------------------
-- 3 · El informe: qué cambiaría si se generaran
-- ---------------------------------------------------------------------------

create or replace function public.generar_opciones_eleccion_metrica(p_aplicar boolean default false)
returns table (forma text, grupo text, escritas integer, derivadas integer, veredicto text)
language plpgsql
set search_path to 'public'
as $function$
begin
	if p_aplicar then
		raise exception 'Aplicar la generación todavía no está implementado: las etiquetas de las opciones se escriben a mano y hay que decidir cómo se derivan antes de sobrescribirlas';
	end if;

	return query
	with derivadas as (
		select d.grupo_eleccion_id, count(*)::integer as n
		from public.opciones_eleccion_derivadas() d
		group by d.grupo_eleccion_id
	),
	escritas as (
		select o.grupo_eleccion_id, count(*)::integer as n
		from public.opciones_eleccion_metrica o
		where o.activo
		group by o.grupo_eleccion_id
	)
	select f.nombre::text, g.slug::text,
		coalesce(e.n, 0), coalesce(d.n, 0),
		case
			when g.tipo_control <> 'opciones' then 'respuesta abierta, no se genera'
			when d.n is null then 'sin derivar: falta declarar algo'
			when coalesce(e.n, 0) = d.n then 'coincide'
			else 'difiere'
		end::text
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	left join derivadas d on d.grupo_eleccion_id = g.grupo_eleccion_id
	left join escritas e on e.grupo_eleccion_id = g.grupo_eleccion_id
	where g.activo
	order by
		case
			when g.tipo_control <> 'opciones' then 2
			when coalesce(e.n, 0) = coalesce(d.n, 0) then 3
			else 1
		end,
		f.nombre, g.slug;
end;
$function$;

comment on function public.generar_opciones_eleccion_metrica(boolean) is
	'Compara las opciones escritas a mano con las que el catálogo deriva, pregunta a pregunta. No escribe: pedir el informe es la manera de comprobar que el dato y el formulario no se han separado.';

grant execute on function public.opciones_eleccion_derivadas() to authenticated;
grant execute on function public.generar_opciones_eleccion_metrica(boolean) to authenticated;

-- La prueba: hoy la derivación tiene que coincidir con lo escrito en todo lo derivable.
do $$
declare
	v_difieren integer;
	v_sin_derivar integer;
begin
	select count(*) filter (where veredicto = 'difiere'),
		count(*) filter (where veredicto = 'sin derivar: falta declarar algo')
	into v_difieren, v_sin_derivar
	from public.generar_opciones_eleccion_metrica();

	if v_difieren <> 0 then
		raise exception 'La derivación difiere de lo escrito en % preguntas', v_difieren;
	end if;
	-- Solo puede quedar sin derivar la pregunta que reúne dos rasgos independientes.
	if v_sin_derivar > 1 then
		raise exception 'Hay % preguntas sin derivar y solo se admite una', v_sin_derivar;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

-- La asonancia se anota en todas
--
-- **F33.** Una asonancia se registra diciendo en qué vocales asuena —`a-e`, `o-a`, `i`…— y esa
-- pregunta existía en **9 de las 27 arquitecturas** que tienen algún esquema asonante. En las otras
-- 18 el editor podía decir que el pasaje asuena, porque lo dice el esquema elegido, pero no en qué.
-- Decidido el 29 de agosto de 2026: se anota en todas.
--
-- **Las 18 no son un grupo homogéneo**, y por eso no se les pone la misma pregunta:
--
-- * **7 solo asuenan** —las siete seguidillas—: ahí la pregunta es **obligatoria**, como en el
--   romance.
-- * **11 mezclan regímenes** —seis octavas agudas, dos tercetos, dos villancicos y el pareado—: el
--   mismo pasaje puede rimar en consonante, así que la pregunta es **opcional**. El vacío no queda
--   ambiguo: el esquema elegido ya dice el régimen, de modo que «esquema asonante sin vocales» se
--   detecta comparando, y no hace falta inventar preguntas condicionales, que el modelo no tiene.
--
-- **Y faltaba la `u`.** El repertorio traía `a`, `e`, `i`, `o` entre las agudas —pero `u-a`, `u-e`
-- y `u-o` entre las llanas—, así que una asonancia aguda en `ú` no se podía anotar.
--
-- **Donde el final agudo es definitorio, solo se ofrecen las agudas.** Las seis octavas agudas
-- declaran «Final acentual = Agudo» con modalidad `definitoria`, y en un verso agudo la asonancia
-- no puede tener dos vocales. La regla no es de la octava aguda: mira lo que la arquitectura fija,
-- así que donde el final agudo solo está `admitida` —canción petrarquista, endecasílabo suelto,
-- octava real, septeto compuesto— se sigue ofreciendo todo, que es lo correcto.

begin;

-- ---------------------------------------------------------------------------
-- La vocal que faltaba
-- ---------------------------------------------------------------------------

insert into public.rasgo_valores (rasgo_id, slug, nombre, activo)
select r.rasgo_id, 'u', 'u', true
from public.rasgos_metricos r
where r.slug = 'vocales_asonancia'
on conflict do nothing;

-- ---------------------------------------------------------------------------
-- Las 18 arquitecturas declaran el rasgo y lo preguntan
-- ---------------------------------------------------------------------------

-- Quiénes son: las que tienen algún esquema asonante y todavía no preguntan las vocales. El
-- régimen de un esquema puede venir de la arquitectura, así que se lee con `coalesce`.
create temporary table f33_candidatas on commit drop as
select
	a.arquitectura_id,
	count(*) filter (where v.termino is not null and v.termino not ilike '%asonan%') = 0 as solo_asuena
from public.arquitecturas_forma a
join public.esquemas_rima er on er.arquitectura_id = a.arquitectura_id
left join public.vocabularios v on v.termino_id = coalesce(er.tipo_rima_id, a.tipo_rima_id)
where a.activo
	and not exists (
		select 1 from public.grupos_eleccion_metrica g
		where g.arquitectura_id = a.arquitectura_id and g.slug = 'vocales_asonancia' and g.activo
	)
group by a.arquitectura_id
having count(*) filter (where v.termino ilike '%asonan%') > 0;

insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad)
select c.arquitectura_id, r.rasgo_id, null, 'admitida'
from f33_candidatas c
cross join public.rasgos_metricos r
where r.slug = 'vocales_asonancia'
on conflict do nothing;

insert into public.grupos_eleccion_metrica (
	arquitectura_id, slug, dimension, alcance, tipo_control, rasgo_id,
	selecciones_min, selecciones_max, define_norma, activo, orden, ayuda_editor
)
select
	c.arquitectura_id, 'vocales_asonancia', 'rasgo', 'secuencia', 'opciones', r.rasgo_id,
	case when c.solo_asuena then 1 else 0 end, 1, false, true, 2,
	case
		when c.solo_asuena then 'En qué vocales asuena el pasaje.'
		else 'En qué vocales asuena el pasaje, si es que asuena: se deja vacía cuando la rima es consonante.'
	end
from f33_candidatas c
cross join public.rasgos_metricos r
where r.slug = 'vocales_asonancia'
on conflict (arquitectura_id, slug) do nothing;

-- ---------------------------------------------------------------------------
-- Y donde el final agudo es definitorio, solo las agudas
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.opciones_eleccion_derivadas()
 RETURNS TABLE(grupo_eleccion_id uuid, etiqueta text, descripcion text, metro_id uuid, esquema_metrico_id uuid, esquema_rima_id uuid, seccion_id uuid, repeticion_id uuid, valor_rasgo_id uuid, variedad_id uuid, posicion_unidad integer, materializa_seccion_id uuid, extension_desde_seccion_id uuid, orden integer)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public'
AS $function$
		-- Rima: los esquemas de la arquitectura que la sección reutiliza, o los de la propia. Un
		-- esquema declarado para una sección solo se ofrece en la pregunta que trata de ella.
		select g.grupo_eleccion_id,
			-- El régimen entra en la etiqueta cuando la arquitectura no declara uno solo: si sus
			-- disposiciones varían, es lo que las distingue, y sin él el pareado ofrecía dos opciones
			-- llamadas «aa». Es la misma regla que la ficha pública aplica a cada fila de rima.
			concat_ws(' · ', nullif(er.nombre, ''), nullif(er.notacion, ''),
				case when a.tipo_rima_id is null then (
					select tr.etiqueta from public.vocabularios tr where tr.termino_id = er.tipo_rima_id
				) end)::text,
			er.descripcion,
			null::uuid, null::uuid, er.esquema_rima_id, null::uuid,
			null::uuid, null::uuid, null::uuid, null::integer, null::uuid, null::uuid,
			row_number() over (
				partition by g.grupo_eleccion_id order by er.nombre nulls last, er.notacion, er.slug
			)::integer
		from public.preguntas_metricas g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
		join public.esquemas_rima er
			on er.arquitectura_id = coalesce(s.arquitectura_referenciada_id, a.arquitectura_id)
		where g.dimension = 'rima' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and er.tipo_secuencia not in ('abierta', 'restricciones')
			and er.seccion_id is not distinct from g.seccion_tratada_id

		union all

		select g.grupo_eleccion_id,
			case when pos.posicion is null then adm.nombre
				else 'Verso ' || pos.posicion || ' · ' || adm.nombre end::text,
			null::text,
			adm.metro_id, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, null::uuid, pos.posicion, null::uuid, null::uuid,
			row_number() over (
				partition by g.grupo_eleccion_id order by pos.posicion, adm.silabas
			)::integer
		from public.preguntas_metricas g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		join lateral (
			select eo.metro_id, mt.silabas, mt.nombre
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
		where g.dimension = 'metro' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and em.medida_uniforme is not null

		union all

		select g.grupo_eleccion_id,
			('Verso ' || p.posicion || ' · ' || mt.nombre)::text,
			null::text,
			p.metro_id, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, null::uuid, p.posicion, null::uuid, null::uuid,
			p.alternativa::integer
		from public.preguntas_metricas g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		join public.esquema_metrico_posiciones p on p.esquema_metrico_id = em.esquema_metrico_id
		join public.metros mt on mt.metro_id = p.metro_id
		where g.dimension = 'metro' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and em.medida_uniforme is null
			and p.posicion in (
				select p2.posicion from public.esquema_metrico_posiciones p2
				where p2.esquema_metrico_id = em.esquema_metrico_id
				group by p2.posicion having count(distinct p2.metro_id) > 1
			)

		union all

		select g.grupo_eleccion_id,
			case when adm.valores = 1 then r.nombre else adm.nombre end::text,
			adm.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			null::uuid, adm.valor_id, null::uuid, null::integer, null::uuid, null::uuid,
			row_number() over (partition by g.grupo_eleccion_id order by adm.orden)::integer
		from public.preguntas_metricas g
		join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
		join lateral (
			select distinct coalesce(ar.valor_id, rv.valor_id) as valor_id, rv.orden, rv.nombre,
				rv.descripcion,
				(select count(*) from public.rasgo_valores t where t.rasgo_id = r.rasgo_id and t.activo)
					as valores
			from public.arquitectura_rasgos ar
			join public.rasgo_valores rv on rv.rasgo_id = ar.rasgo_id and rv.activo
			where ar.arquitectura_id = g.arquitectura_id and ar.rasgo_id = g.rasgo_id
				and (ar.valor_id is null or ar.valor_id = rv.valor_id)
				-- **Una asonancia aguda se nombra con una sola vocal.** Se nombra por la tónica y la
				-- final, y en un verso agudo no hay vocal después de la tónica: por eso el repertorio
				-- tiene `a`, `e`, `i`, `o`, `u` frente a `a-e`, `o-a`… —los pares valen también para
				-- el esdrújulo, que asuena como el llano ignorando la intermedia—. Donde la norma
				-- **fija** el final agudo, las de dos vocales no pueden darse, y ofrecerlas es ruido.
				and (
					r.slug <> 'vocales_asonancia'
					or rv.nombre not like '%-%'
					or not exists (
						select 1
						from public.arquitectura_rasgos final_ar
						join public.rasgos_metricos final_r on final_r.rasgo_id = final_ar.rasgo_id
						join public.rasgo_valores final_v on final_v.valor_id = final_ar.valor_id
						where final_ar.arquitectura_id = g.arquitectura_id
							and final_r.slug = 'final_acentual'
							and final_v.slug = 'agudo'
							and final_ar.modalidad = 'definitoria'
					)
				)
		) adm on true
		where g.dimension = 'rasgo' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
			and g.rasgo_id is not null

		union all

		select g.grupo_eleccion_id, rp.nombre::text, rp.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			rp.repeticion_id, null::uuid, null::uuid, null::integer,
			rp.materializa_seccion_id, rp.extension_desde_seccion_id,
			row_number() over (partition by g.grupo_eleccion_id order by rp.slug)::integer
		from public.preguntas_metricas g
		join public.repeticiones_metricas rp on rp.arquitectura_id = g.arquitectura_id
		where g.dimension = 'repeticion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo

		union all

		select g.grupo_eleccion_id, v.nombre::text, v.descripcion,
			null::uuid, null::uuid, null::uuid, null::uuid,
			null::uuid, null::uuid, v.variedad_id, null::integer, null::uuid, null::uuid,
			row_number() over (partition by g.grupo_eleccion_id order by v.orden, v.slug)::integer
		from public.preguntas_metricas g
		join public.variedades_arquitectura v on v.arquitectura_id = g.arquitectura_id
		where g.dimension = 'combinacion' and g.tipo_control in ('opciones', 'opciones_y_esquema') and g.activo
	$function$;


do $comprobacion$
declare
	v_preguntan integer;
	v_obligatorias integer;
	v_opcionales integer;
	v_agudas integer;
	v_octava integer;
	v_seguidilla integer;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecuta la derivación**, que es lo único que prueba que las opciones salen: una función
	-- entrecomillada compila igual con una condición mal escrita.
	select count(*) into v_preguntan
	from public.preguntas_metricas g
	where g.slug = 'vocales_asonancia' and g.activo;

	if v_preguntan <> 28 then
		raise exception 'Preguntan las vocales % arquitecturas, y son 28: las 10 de antes y las 18 nuevas.', v_preguntan;
	end if;

	select count(*) filter (where g.selecciones_min = 1), count(*) filter (where g.selecciones_min = 0)
	into v_obligatorias, v_opcionales
	from public.preguntas_metricas g
	where g.slug = 'vocales_asonancia' and g.activo;

	if v_opcionales <> 11 then
		raise exception 'Hay % preguntas opcionales, y son 11: las que mezclan regímenes.', v_opcionales;
	end if;

	raise notice 'Vocales de la asonancia: % obligatorias y % opcionales.', v_obligatorias, v_opcionales;

	-- La `u` está, y con ella son cinco agudas y veinte valores.
	select count(*) into v_agudas
	from public.rasgo_valores rv
	join public.rasgos_metricos r on r.rasgo_id = rv.rasgo_id
	where r.slug = 'vocales_asonancia' and rv.activo and rv.nombre not like '%-%';

	if v_agudas <> 5 then
		raise exception 'El repertorio tiene % vocales agudas, y son 5.', v_agudas;
	end if;

	-- Una octava aguda ofrece **solo** las cinco agudas...
	select count(*) into v_octava
	from public.opciones_eleccion_metrica o
	join public.preguntas_metricas g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where g.slug = 'vocales_asonancia' and f.slug = 'octava_aguda';

	if v_octava <> 5 * 6 then
		raise exception 'Las seis octavas agudas ofrecen % opciones en total, y son 30: cinco agudas cada una.', v_octava;
	end if;

	-- ...y una seguidilla, las veinte.
	select count(*) into v_seguidilla
	from public.opciones_eleccion_metrica o
	join public.preguntas_metricas g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where g.slug = 'vocales_asonancia' and f.slug = 'seguidilla';

	if v_seguidilla <> 20 * 7 then
		raise exception 'Las siete seguidillas ofrecen % opciones, y son 140: las veinte cada una.', v_seguidilla;
	end if;

	raise notice 'La octava aguda ofrece solo las 5 agudas; la seguidilla, las 20.';
end
$comprobacion$;

commit;

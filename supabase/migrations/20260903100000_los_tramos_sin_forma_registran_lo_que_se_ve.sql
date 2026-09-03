-- Los tramos sin forma registran lo que se ve
--
-- La versificación irregular y el verso aislado no preguntaban nada: un editor marcaba el pasaje y
-- ahí acababa el registro. Este es el plan de **F63**, escrito en
-- `docs/dominio-metrico/plan-f63-los-tramos-registran-lo-que-se-ve.md`.
--
-- **Un tramo puede tener arquitectura; lo que no puede es que declare norma.** Es lo que decían ya,
-- literalmente, las dos guardas que lo impedían —«no puede tener arquitecturas **normativas**»—,
-- implementadas más estrictas que su propia frase. Aquí pasan a decir lo que decían, y se añade lo
-- que faltaba: nada normativo puede colgar de la arquitectura de un tramo, y eso se vigila en las
-- seis tablas por las que podría entrar.
--
-- Hace falta por dos razones de mecanismo. La primera, que **la migración entra directa**: una
-- arquitectura que declara `origen_termino_id` reclama el término legado y
-- `propuesta_metrica_secuencia` la propone sin ninguna fila de equivalencia, así que las ocho
-- secuencias de arte conocido llegan enteras. La segunda, que **las preguntas cuelgan de una
-- arquitectura**: sin ella no hay dónde ponerlas.
--
-- **Qué se pregunta:** la medida de cada verso y la rima observada, las dos escritas de una vez y
-- validadas contra el número de versos del rango. Son las dos series que hacen comparable un pasaje
-- irregular con cualquier otro, que es lo que permitirá ver si varios coinciden. El arte, la
-- densidad de rima y el periodo **no se preguntan: se derivan** de ahí.
--
-- La medida es obligatoria y la rima no: un pasaje sin rima no debería obligar a escribir cuarenta
-- guiones. Las ocho secuencias migradas llegarán sin serie, y `npm run audit:anotaciones` las dirá
-- una por una, que es exactamente lo que se quiere saber.
--
-- *El término `irregular` a secas no recibe arquitectura*: es una sola secuencia —*El mágico
-- prodigioso*, vv. 2191–2201— y antes hay que preguntar a quien la anotó por qué eligió el término
-- madre y no uno de los tres específicos.

begin;

-- ---------------------------------------------------------------------------
-- Qué es declarar norma
-- ---------------------------------------------------------------------------

create or replace function public.arquitectura_declara_norma(p_arquitectura_id uuid)
returns boolean
language sql
stable
set search_path to 'public'
as $declara$
	-- Todo lo que una arquitectura puede afirmar sobre cómo es su forma. Si no afirma ninguna de
	-- estas cosas, no describe una norma: solo da un sitio del que colgar preguntas.
	select exists (select 1 from public.esquemas_metricos x where x.arquitectura_id = p_arquitectura_id)
		or exists (select 1 from public.esquemas_rima x where x.arquitectura_id = p_arquitectura_id)
		or exists (select 1 from public.estructuras_secciones x where x.arquitectura_id = p_arquitectura_id)
		or exists (select 1 from public.arquitectura_rasgos x where x.arquitectura_id = p_arquitectura_id)
		or exists (select 1 from public.repeticiones_metricas x where x.arquitectura_id = p_arquitectura_id)
		or exists (select 1 from public.variedades_arquitectura x where x.arquitectura_id = p_arquitectura_id)
		or exists (
			select 1
			from public.arquitecturas_forma a
			where a.arquitectura_id = p_arquitectura_id
				and (
					a.demarcable
					or a.tipo_rima_id is not null
					or a.unidad_versos_min is not null
					or a.unidad_versos_max is not null
				)
		);
$declara$;

comment on function public.arquitectura_declara_norma(uuid) is
	'Si la arquitectura afirma algo sobre cómo es su forma: esquemas, secciones, rasgos, repeticiones, variedades, o los flags de la propia fila.';

-- ---------------------------------------------------------------------------
-- Las guardas dicen lo que decían
-- ---------------------------------------------------------------------------

create or replace function public.validar_tramo_sin_forma_sin_arquitectura()
returns trigger
language plpgsql
set search_path to 'public'
as $tramo$
declare
	v_culpable text;
begin
	if new.tipo_registro <> 'sin_forma' then
		return new;
	end if;

	select a.slug
	into v_culpable
	from public.arquitecturas_forma a
	where a.forma_id = new.forma_id
		and public.arquitectura_declara_norma(a.arquitectura_id)
	limit 1;

	if v_culpable is not null then
		raise exception 'Un tramo sin forma no puede tener arquitecturas normativas, y «%» lo es', v_culpable;
	end if;

	return new;
end;
$tramo$;

create or replace function public.validar_arquitectura_de_forma_con_norma()
returns trigger
language plpgsql
set search_path to 'public'
as $arquitectura$
begin
	if not exists (
		select 1
		from public.formas_metricas
		where forma_id = new.forma_id
			and tipo_registro = 'sin_forma'
	) then
		return new;
	end if;

	-- Lo que la propia fila puede afirmar. Lo que cuelgue de ella lo vigilan los disparadores de
	-- las seis tablas normativas, más abajo.
	if new.demarcable
		or new.tipo_rima_id is not null
		or new.unidad_versos_min is not null
		or new.unidad_versos_max is not null
	then
		raise exception 'La arquitectura de un tramo sin forma no declara norma: ni es demarcable, ni fija régimen de rima, ni límites de unidad';
	end if;

	return new;
end;
$arquitectura$;

-- ---------------------------------------------------------------------------
-- Y nada normativo cuelga de la arquitectura de un tramo
-- ---------------------------------------------------------------------------

create or replace function public.validar_norma_no_cuelga_de_un_tramo()
returns trigger
language plpgsql
set search_path to 'public'
as $cuelga$
begin
	if new.arquitectura_id is not null and exists (
		select 1
		from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		where a.arquitectura_id = new.arquitectura_id
			and f.tipo_registro = 'sin_forma'
	) then
		raise exception 'Un tramo sin forma no admite %, que es una declaración normativa', tg_table_name;
	end if;

	return new;
end;
$cuelga$;

comment on function public.validar_norma_no_cuelga_de_un_tramo() is
	'Impide que una declaración normativa se cuelgue de la arquitectura de un tramo sin forma. Va en las seis tablas por las que podría entrar.';

do $disparadores$
declare
	v_tabla text;
begin
	foreach v_tabla in array array[
		'esquemas_metricos', 'esquemas_rima', 'estructuras_secciones',
		'arquitectura_rasgos', 'repeticiones_metricas', 'variedades_arquitectura'
	] loop
		execute format(
			'drop trigger if exists trigger_norma_no_cuelga_de_un_tramo on public.%I',
			v_tabla
		);
		execute format(
			'create trigger trigger_norma_no_cuelga_de_un_tramo before insert or update of arquitectura_id on public.%I for each row execute function public.validar_norma_no_cuelga_de_un_tramo()',
			v_tabla
		);
	end loop;
end
$disparadores$;

-- ---------------------------------------------------------------------------
-- Una respuesta también puede escribirse como serie de medidas
-- ---------------------------------------------------------------------------

alter table public.grupos_eleccion_metrica
	drop constraint if exists grupos_eleccion_metrica_tipo_control_check;

alter table public.grupos_eleccion_metrica
	add constraint grupos_eleccion_metrica_tipo_control_check
	check (tipo_control in ('opciones', 'esquema_rima', 'opciones_y_esquema', 'serie_medidas'));

-- ---------------------------------------------------------------------------
-- Qué puede ser una serie de medidas
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validar_grupo_eleccion_metrica()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
	declare
		v_configuracion_seccion uuid;
	begin
		if new.seccion_id is not null then
			select arquitectura_id
			into v_configuracion_seccion
			from public.estructuras_secciones
			where seccion_id = new.seccion_id;

			if v_configuracion_seccion is distinct from new.arquitectura_id then
				raise exception 'La sección de alcance no pertenece a la arquitectura del grupo';
			end if;
		end if;

		-- Los dos controles que ofrecen escribir un esquema hablan siempre de rima, y una unidad
		-- rima de una sola manera. Lo que los separa es el mínimo: el abierto exige respuesta y el
		-- híbrido admite dejarla en blanco, porque el esquema catalogado se marca solo si es el que
		-- se ha visto.
		if new.tipo_control in ('esquema_rima', 'opciones_y_esquema') then
			if new.dimension <> 'rima' then
				raise exception 'Un control de esquema debe pertenecer a la dimensión de rima';
			end if;
			if new.selecciones_max <> 1 then
				raise exception 'Un control de esquema admite una sola respuesta';
			end if;
		end if;

		if new.tipo_control = 'esquema_rima' and new.selecciones_min <> 1 then
			raise exception 'Un control de esquema abierto necesita exactamente una respuesta';
		end if;

		-- La serie de medidas es la regla paralela: habla siempre de medida, se escribe una
		-- vez y se exige, porque es lo único que hace comparable un pasaje sin norma.
		if new.tipo_control = 'serie_medidas' then
			if new.dimension <> 'metro' then
				raise exception 'Una serie de medidas debe pertenecer a la dimensión de metro';
			end if;
			if new.selecciones_min <> 1 or new.selecciones_max <> 1 then
				raise exception 'Una serie de medidas se escribe una sola vez y es obligatoria';
			end if;
		end if;

		return new;
	end;
	$function$;

-- ---------------------------------------------------------------------------
-- La anotación de un tramo puede declarar su arquitectura
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validar_anotacion_metrica()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
	v_tipo_registro text;
	v_slug text;
begin
	select tipo_registro, slug
	into v_tipo_registro, v_slug
	from public.formas_metricas
	where forma_id = new.forma_id
		and activo;

	if v_tipo_registro is null then
		raise exception 'La entrada métrica no está activa';
	end if;

	if v_tipo_registro = 'sin_forma' then
		-- **Un tramo sí admite arquitectura**, siempre que sea suya. Lo que no admite es que esa
		-- arquitectura declare norma, y de eso se encargan las guardas del catálogo.
		if new.arquitectura_id is not null and not exists (
			select 1
			from public.arquitecturas_forma configuracion
			where configuracion.arquitectura_id = new.arquitectura_id
				and configuracion.forma_id = new.forma_id
				and configuracion.activo
		) then
			raise exception 'La arquitectura no pertenece a este tramo';
		end if;
		if v_slug = 'verso_aislado' and new.v_fin <> new.v_ini then
			raise exception 'Verso aislado debe abarcar exactamente un verso';
		end if;
		if v_slug = 'irregular' and new.v_fin - new.v_ini + 1 < 2 then
			raise exception 'Versificación irregular debe abarcar al menos dos versos';
		end if;
		return new;
	end if;

	if new.arquitectura_id is null or not exists (
		select 1
		from public.arquitecturas_forma configuracion
		where configuracion.arquitectura_id = new.arquitectura_id
			and configuracion.forma_id = new.forma_id
			and configuracion.activo
	) then
		raise exception 'La arquitectura no pertenece a una forma activa';
	end if;

	return new;
end;
$function$;

-- ---------------------------------------------------------------------------
-- Y la respuesta escrita se lee según su control
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.validar_anotacion_eleccion()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
declare
	v_arquitectura uuid;
	v_seccion_unidad uuid;
	v_padre uuid;
	v_longitud integer;
	v_entidades integer;
	v_escrito integer;
	v_admitida boolean;
	v_control text;
	v_medidas text[];
begin
	select arquitectura_id, v_fin - v_ini + 1
	into v_arquitectura, v_longitud
	from public.anotaciones_metricas
	where anotacion_id = new.anotacion_id;

	v_entidades := num_nonnulls(
		new.metro_id, new.esquema_metrico_id, new.esquema_rima_id, new.seccion_id,
		new.repeticion_id, new.valor_rasgo_id, new.variedad_id
	);

	if v_entidades = 0 and new.valor_texto is null then
		raise exception 'Una respuesta sin dato no se guarda';
	end if;

	if new.realizacion_id is not null then
		select seccion_id, realizacion_padre_id, v_fin - v_ini + 1
		into v_seccion_unidad, v_padre, v_longitud
		from public.anotacion_realizaciones
		where realizacion_id = new.realizacion_id and anotacion_id = new.anotacion_id;

		if not found then
			raise exception 'La unidad no pertenece a la secuencia';
		end if;
	end if;

	-- Un tramo sin forma no declara arquitectura: su respuesta se sostiene sola.
	if v_arquitectura is null then
		return new;
	end if;

	if v_entidades = 1 then
		-- ¿La ofrece el catálogo? Se busca entre las preguntas de la arquitectura, **heredadas
		-- incluidas**: ya no hace falta preguntar aparte por lo que la parte reutiliza.
		select exists (
			select 1
			from public.opciones_eleccion_metrica o
			join public.preguntas_metricas g on g.grupo_eleccion_id = o.grupo_eleccion_id
			where g.activo
				and g.arquitectura_id = v_arquitectura
				and g.dimension = new.dimension
				and g.seccion_tratada_id is not distinct from new.seccion_tratada_id
				and g.seccion_id is not distinct from (
					case when v_padre is not null then v_seccion_unidad end
				)
				and o.metro_id is not distinct from new.metro_id
				and o.esquema_metrico_id is not distinct from new.esquema_metrico_id
				and o.esquema_rima_id is not distinct from new.esquema_rima_id
				and o.seccion_id is not distinct from new.seccion_id
				and o.repeticion_id is not distinct from new.repeticion_id
				and o.valor_rasgo_id is not distinct from new.valor_rasgo_id
				and o.variedad_id is not distinct from new.variedad_id
				and o.posicion_unidad is not distinct from new.posicion_unidad
		) into v_admitida;

		if not v_admitida then
			raise exception 'La respuesta no está admitida por la norma de esta arquitectura en la dimensión %', new.dimension;
		end if;
	else
		-- **Qué se ha escrito lo dice el control de la pregunta**, no la dimensión: una notación de
		-- rima se lee letra a letra y una serie de medidas, número a número.
		select g.tipo_control
		into v_control
		from public.preguntas_metricas g
		where g.activo
			and g.arquitectura_id = v_arquitectura
			and g.dimension = new.dimension
			and g.tipo_control in ('esquema_rima', 'opciones_y_esquema', 'serie_medidas')
			and g.seccion_tratada_id is not distinct from new.seccion_tratada_id
			and g.seccion_id is not distinct from (
				case when v_padre is not null then v_seccion_unidad end
			)
		limit 1;

		if v_control is null then
			raise exception 'Esta arquitectura no admite escribir la respuesta en la dimensión %', new.dimension;
		end if;

		if v_control = 'serie_medidas' then
			-- Una medida por verso, separadas por espacios: `11 7 11 11 7`.
			v_medidas := regexp_split_to_array(btrim(new.valor_texto), '\s+');
			if exists (select 1 from unnest(v_medidas) medida where medida !~ '^[0-9]{1,2}$') then
				raise exception 'La serie de medidas solo admite números de una o dos cifras, y trae «%»', new.valor_texto;
			end if;
			v_escrito := coalesce(array_length(v_medidas, 1), 0);
			if v_longitud is not null and v_escrito <> v_longitud then
				raise exception 'La serie debe traer % medidas, una por verso, y trae %', v_longitud, v_escrito;
			end if;
		else
			-- Una notación se lee verso a verso. Se descuentan los separadores que la propia notación
			-- trae —`abcabc|defdef`, `abba:cdcd`— y los espacios.
			v_escrito := length(regexp_replace(new.valor_texto, '[:|[:space:]]', '', 'g'));
			if v_longitud is not null and v_escrito <> v_longitud then
				raise exception 'El esquema de rima debe tener % posiciones y tiene %', v_longitud, v_escrito;
			end if;
		end if;
	end if;

	return new;
end;
$function$;

-- ---------------------------------------------------------------------------
-- El rótulo de una serie de medidas
-- ---------------------------------------------------------------------------

create or replace view public.grupos_eleccion_metrica_resueltos as
SELECT g.grupo_eleccion_id,
    g.arquitectura_id,
    g.slug,
    g.ayuda_editor,
    g.dimension,
    g.alcance,
    g.seccion_id,
    g.selecciones_min,
    g.selecciones_max,
    g.permite_aplicar_global,
    g.activo,
    g.orden,
    g.created_at,
    g.updated_at,
    g.tipo_control,
    g.define_norma,
    g.rasgo_id,
    g.seccion_tratada_id,
        CASE
            WHEN g.dimension = 'rasgo'::text THEN rm.nombre
            WHEN g.dimension = 'repeticion'::text THEN rep.nombre
            ELSE concat_ws(' · '::text, COALESCE(s.nombre, st.nombre),
            CASE g.dimension
                WHEN 'rima'::text THEN
                CASE
                    WHEN g.tipo_control = 'esquema_rima'::text THEN 'Esquema de rima observado'::text
                    ELSE 'Esquema de rima'::text
                END
                WHEN 'metro'::text THEN
                CASE
                    WHEN g.tipo_control = 'serie_medidas'::text THEN 'Medida de cada verso'::text
                    WHEN m.quebrados THEN 'Medida de los quebrados'::text
                    WHEN m.posicional AND m.posiciones = 1 THEN 'Medida del verso '::text || m.primera_posicion
                    WHEN m.posicional THEN 'Medida de cada verso'::text
                    ELSE 'Medida de los versos'::text
                END
                WHEN 'combinacion'::text THEN 'Variedad'::text
                ELSE NULL::text
            END)
        END AS nombre
   FROM preguntas_metricas g
     LEFT JOIN estructuras_secciones s ON s.seccion_id = g.seccion_id
     LEFT JOIN estructuras_secciones st ON st.seccion_id = g.seccion_tratada_id
     LEFT JOIN rasgos_metricos rm ON rm.rasgo_id = g.rasgo_id
     LEFT JOIN LATERAL ( SELECT COALESCE(bool_and(o.posicion_unidad IS NOT NULL), false) AS posicional,
            COALESCE(bool_or(eo.rol = 'quebrado'::text), false) AS quebrados,
            count(DISTINCT o.posicion_unidad) FILTER (WHERE o.posicion_unidad IS NOT NULL) AS posiciones,
            min(o.posicion_unidad) AS primera_posicion
           FROM opciones_eleccion_metrica o
             LEFT JOIN esquemas_metricos em ON em.arquitectura_id = g.arquitectura_id
             LEFT JOIN esquema_metrico_opciones eo ON eo.esquema_metrico_id = em.esquema_metrico_id AND eo.metro_id = o.metro_id
          WHERE o.grupo_eleccion_id = g.grupo_eleccion_id) m ON g.dimension = 'metro'::text
     LEFT JOIN LATERAL ( SELECT ms.nombre
           FROM repeticiones_metricas rp
             JOIN estructuras_secciones ms ON ms.seccion_id = rp.materializa_seccion_id
          WHERE rp.arquitectura_id = g.arquitectura_id
         LIMIT 1) rep ON g.dimension = 'repeticion'::text;;

-- ---------------------------------------------------------------------------
-- Las cuatro arquitecturas y sus ocho preguntas
-- ---------------------------------------------------------------------------

insert into public.arquitecturas_forma (
	forma_id, slug, nombre, descripcion, principal, demarcable, modalidad, activo, orden, origen_termino_id
)
select
	f.forma_id, d.slug, d.nombre, d.descripcion, d.principal, false, 'admitida', true, d.orden,
	(select v.termino_id from public.vocabularios v where v.termino = d.termino_legado)
from (values
	('irregular', 'arte_menor', 'De arte menor', 'Un pasaje sin norma cuyos versos son todos de ocho sílabas o menos.', false, 1, 'irregular_arte_menor'),
	('irregular', 'arte_mayor', 'De arte mayor', 'Un pasaje sin norma cuyos versos son todos de nueve sílabas o más.', false, 2, 'irregular_arte_mayor'),
	('irregular', 'mixta', 'Mixta', 'Un pasaje sin norma que alterna versos de arte menor y de arte mayor.', false, 3, 'irregular_mixto'),
	('verso_aislado', 'cualquier_medida', 'De cualquier medida', 'Un verso solo, de la medida que sea, que no forma parte de ninguna estrofa ni serie.', true, 1, null)
) as d(forma_slug, slug, nombre, descripcion, principal, orden, termino_legado)
join public.formas_metricas f on f.slug = d.forma_slug and f.tipo_registro = 'sin_forma'
on conflict (forma_id, slug) do nothing;

insert into public.grupos_eleccion_metrica (
	arquitectura_id, slug, dimension, alcance, tipo_control,
	selecciones_min, selecciones_max, define_norma, activo, orden, ayuda_editor
)
select
	a.arquitectura_id, d.slug, d.dimension, 'secuencia', d.tipo_control,
	d.minimo, 1, false, true, d.orden, d.ayuda
from (values
	('medida_de_cada_verso', 'metro', 'serie_medidas', 1, 1, 'Una medida por verso, separadas por espacios: 11 7 11 11 7.'),
	('rima_observada', 'rima', 'esquema_rima', 1, 2, 'Una letra por verso y un guion donde el verso queda suelto: -a-ab b.')
) as d(slug, dimension, tipo_control, minimo, orden, ayuda)
cross join (
	select a.arquitectura_id
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.tipo_registro = 'sin_forma' and a.activo
) a
on conflict (arquitectura_id, slug) do nothing;

do $comprobacion$
declare
	v_arquitecturas integer;
	v_preguntas integer;
	v_con_destino integer;
	v_forma uuid;
	v_arquitectura uuid;
	v_fallo text;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Las guardas se ejecutan**, con un caso que debe pasar y otro que debe fallar. Un cuerpo
	-- entrecomillado no se revalida al cambiar lo que hay debajo.

	select count(*) into v_arquitecturas
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.tipo_registro = 'sin_forma' and a.activo;

	if v_arquitecturas <> 4 then
		raise exception 'Los tramos tienen % arquitecturas, y son 4: tres artes y el verso aislado.', v_arquitecturas;
	end if;

	select count(*) into v_preguntas
	from public.preguntas_metricas g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.tipo_registro = 'sin_forma' and g.activo;

	if v_preguntas <> 8 then
		raise exception 'Los tramos ofrecen % preguntas, y son 8: dos por arquitectura.', v_preguntas;
	end if;

	-- Y se leen con su rótulo, que es derivado y podría no salir.
	if not exists (
		select 1
		from public.grupos_eleccion_metrica_resueltos g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.tipo_registro = 'sin_forma' and g.nombre = 'Medida de cada verso'
	) then
		raise exception 'La serie de medidas no se rotula «Medida de cada verso».';
	end if;

	-- La guarda deja pasar lo que no declara norma...
	select f.forma_id into v_forma from public.formas_metricas f where f.slug = 'irregular';
	insert into public.arquitecturas_forma (forma_id, slug, nombre, demarcable, activo)
	values (v_forma, 'sonda_sin_norma', 'Sonda', false, true)
	returning arquitectura_id into v_arquitectura;

	-- ...y no deja pasar lo que sí.
	begin
		insert into public.esquemas_rima (arquitectura_id, slug, notacion, modalidad, tipo_secuencia)
		values (v_arquitectura, 'sonda', 'aa', 'admitida', 'secuencia');
		v_fallo := 'un esquema de rima colgó de la arquitectura de un tramo';
	exception when others then
		-- Que falle no basta: tiene que fallar **por esto**, no por una columna mal escrita.
		if sqlerrm not like '%tramo sin forma%' then
			raise exception 'La sonda del esquema falló por otra razón: %', sqlerrm;
		end if;
	end;

	if v_fallo is not null then
		raise exception 'La guarda no sujeta: %', v_fallo;
	end if;

	begin
		insert into public.arquitecturas_forma (forma_id, slug, nombre, demarcable, activo)
		values (v_forma, 'sonda_demarcable', 'Sonda', true, true);
		v_fallo := 'una arquitectura demarcable entró en un tramo';
	exception when others then
		if sqlerrm not like '%no declara norma%' then
			raise exception 'La sonda de la arquitectura falló por otra razón: %', sqlerrm;
		end if;
	end;

	if v_fallo is not null then
		raise exception 'La guarda no sujeta: %', v_fallo;
	end if;

	delete from public.arquitecturas_forma where arquitectura_id = v_arquitectura;

	-- Y las ocho secuencias legadas de arte conocido ya tienen a dónde ir.
	select count(*) into v_con_destino
	from public.secuencias_metricas s
	join public.vocabularios v on v.termino_id = s.estrofa_tipo_id
	join public.propuesta_metrica_secuencia p on p.secuencia_id = s.secuencia_id
	where v.termino in ('irregular_arte_menor', 'irregular_arte_mayor', 'irregular_mixto')
		and p.arquitectura_propuesta_id is not null;

	if v_con_destino <> 8 then
		raise exception 'Solo % de las 8 secuencias legadas encuentran destino.', v_con_destino;
	end if;

	raise notice 'Cuatro arquitecturas, ocho preguntas, las guardas sujetan y las 8 secuencias legadas tienen destino.';
end
$comprobacion$;

commit;

-- Los enunciados de las preguntas se derivan del catálogo.
--
-- Cubiertas las respuestas, quedaba el enunciado. Estaba escrito a mano en
-- `grupos_eleccion_metrica.nombre`, uno por pregunta, y decía siempre lo mismo de maneras
-- distintas: «¿Qué esquema de rima presenta la estancia?», «¿Qué esquema tiene la primera
-- quintilla?», «¿Cómo se distribuyen las dos rimas?», «¿Qué patrón tiene la mudanza?»,
-- «Disposición de la rima». Son la misma pregunta cinco veces.
--
-- EL ENUNCIADO PASA A SER CORTO Y SIN ARTÍCULO, con la sección delante cuando la hay:
-- «Mudanza · Esquema de rima», «Estancia · Medida de cada verso», «Medida de los quebrados».
-- Sin artículo porque el catálogo no declara el género de nada, y no hacía falta inventarlo
-- para escribir «la mudanza» y «el enlace»: la sección se nombra y ya está.
--
-- POR QUÉ LA SECCIÓN VA DENTRO DEL ENUNCIADO Y NO APARTE. Porque el enunciado no es
-- decoración: `MetricStructureEditor` pliega en una sola pregunta las que comparten dimensión
-- y enunciado, y así es como las dos mudanzas del villancico —que son **dos secciones
-- distintas con el mismo nombre**, la de la primera copla y la de las siguientes— se responden
-- juntas. Derivar del nombre de la sección conserva ese plegado; derivar del identificador lo
-- habría roto sin que nada avisara.
--
-- EL RASGO SE PREGUNTA DESDE EL RASGO. Es el hueco que destapó la lectura: `final_acentual` se
-- preguntaba «¿Predominan los finales esdrújulos?» en la canción y «¿Presenta un final acentual
-- destacado?» en otras cuatro formas; `organizacion_en_pareados`, «¿Hay pareados intercalados?»
-- en el endecasílabo suelto y «¿Cuánto organizan los pareados la serie?» en la silva. El mismo
-- rasgo preguntado de dos maneras, porque no tenía dónde guardar la suya. Ahora la tiene.
--
-- *De `organizacion_en_pareados` se conserva la pregunta de la silva, la que admite grado. Que
-- en el endecasílabo suelto se preguntara por sí o por no es el asunto de la transversal sobre
-- los rasgos que miden dos magnitudes, y no se resuelve aquí.*
--
-- Y UN HALLAZGO QUE NO SE ARREGLA AQUÍ. El grupo de los tercetos del soneto no declara su
-- sección, y derivado se queda en «Esquema de rima» sin decir de qué, al lado de «Cuartetos ·
-- Esquema de rima». Parecía un descuido y se intentó declarar la sección «Tercetos» que ya
-- existe —y la guarda lo paró: esa sección **remite a la forma Terceto**, de modo que la
-- pregunta habría pasado a ofrecer los esquemas del terceto suelto, que son los de «qué verso
-- queda suelto», en vez de los cuatro del soneto, que abarcan los seis versos de una vez y
-- riman los dos tercetos entre sí. Se perdían siete de las 91 respuestas propuestas.
--
-- No falta, pues, una clave foránea: falta decidir si el soneto tiene una sección de seis
-- versos para sus tercetos, distinta de la de tres que hoy remite a la forma suelta. Es una
-- decisión sobre la estructura del soneto y queda anotada en las cuestiones para el IP.

begin;

-- ---------------------------------------------------------------------------
-- 1 · El rasgo declara su pregunta
-- ---------------------------------------------------------------------------

alter table public.rasgos_metricos add column if not exists pregunta text;

comment on column public.rasgos_metricos.pregunta is
	'Cómo se le pregunta al editor por este rasgo. Vive aquí y no en cada grupo de elección para que el mismo rasgo no se pregunte de dos maneras en dos formas.';

update public.rasgos_metricos set pregunta = '¿Cierra con un dístico?', updated_at = now()
where slug = 'distico_final';
update public.rasgos_metricos set pregunta = '¿Encadena la rima por dentro?', updated_at = now()
where slug = 'encadenamiento_interior';
update public.rasgos_metricos set pregunta = '¿Presenta un final acentual destacado?', updated_at = now()
where slug = 'final_acentual';
update public.rasgos_metricos set pregunta = '¿Cuánto organizan los pareados la serie?', updated_at = now()
where slug = 'organizacion_en_pareados';
update public.rasgos_metricos set pregunta = '¿Qué vocales caracterizan la asonancia?', updated_at = now()
where slug = 'vocales_asonancia';

-- ---------------------------------------------------------------------------
-- 2 · La prosa que repetía un dato ya declarado
-- ---------------------------------------------------------------------------

-- Las denominaciones están en `denominaciones_metricas` y la ficha ya las muestra; que la
-- respuesta se pueda aplicar a todas las unidades lo dice `permite_aplicar_global`; y cuántas
-- tipologías hay se cuenta. Dicho dos veces, se separa en cuanto una de las dos cambie.
update public.grupos_eleccion_metrica set ayuda_editor = null, updated_at = now()
where ayuda_editor in (
	'Elige la disposición de esta redondilla. «Cuarteta» es la denominación equivalente de la cruzada.',
	'Abrazada es el cuarteto; cruzada es el serventesio.',
	'Se registra por estrofa. Puedes aplicar el mismo esquema a todas y corregir únicamente las que cambien.',
	'Puede aplicar la misma respuesta a todas y corregir solo las excepciones.',
	'Puede aplicar la misma respuesta a todas las coplas posteriores y corregir solo las excepciones.',
	'Elige una de las ocho tipologías reconocidas actualmente por el proyecto.'
);

-- ---------------------------------------------------------------------------
-- 3 · El enunciado deja de escribirse
-- ---------------------------------------------------------------------------

drop view if exists public.propuesta_elecciones_secuencia;

alter table public.grupos_eleccion_metrica drop column nombre;

create view public.grupos_eleccion_metrica_resueltos with (security_invoker = on) as
select g.*,
	case
		when g.dimension = 'rasgo' then rm.pregunta
		-- La repetición no se rotula por la sección que la contiene —«Ciclo de copla y
		-- repetición del estribillo»— sino por la que hace aparecer, que es lo que el editor
		-- decide.
		when g.dimension = 'repeticion' then rep.nombre
		else concat_ws(' · ', s.nombre,
			case g.dimension
				when 'rima' then case
					when g.tipo_control = 'esquema_rima' then 'Esquema de rima observado'
					else 'Esquema de rima' end
				when 'metro' then case
					when m.quebrados then 'Medida de los quebrados'
					when m.posicional then 'Medida de cada verso'
					else 'Medida de los versos' end
				when 'combinacion' then 'Variedad'
			end)
	end as nombre
from public.grupos_eleccion_metrica g
left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
left join public.rasgos_metricos rm on rm.rasgo_id = g.rasgo_id
left join lateral (
	-- Si la medida se pregunta verso a verso, y si lo que se pregunta son los quebrados: las
	-- dos cosas las dicen ya las opciones y el papel que el esquema métrico da a cada metro.
	select coalesce(bool_and(o.posicion_unidad is not null), false) as posicional,
		coalesce(bool_and(eo.rol = 'quebrado'), false) as quebrados
	from public.opciones_eleccion_metrica o
	left join public.esquemas_metricos em on em.arquitectura_id = g.arquitectura_id
	left join public.esquema_metrico_opciones eo
		on eo.esquema_metrico_id = em.esquema_metrico_id and eo.metro_id = o.metro_id
	where o.grupo_eleccion_id = g.grupo_eleccion_id
) m on g.dimension = 'metro'
left join lateral (
	select ms.nombre
	from public.repeticiones_metricas rp
	join public.estructuras_secciones ms on ms.seccion_id = rp.materializa_seccion_id
	where rp.arquitectura_id = g.arquitectura_id
	limit 1
) rep on g.dimension = 'repeticion';

comment on view public.grupos_eleccion_metrica_resueltos is
	'Las preguntas del editor con su enunciado calculado al leer. El enunciado es corto y sin artículo, con el nombre de la sección delante cuando la pregunta se refiere a una: el editor pliega en una sola las preguntas que comparten dimensión y enunciado, y así las dos mudanzas del villancico se siguen respondiendo juntas.';

grant select on public.grupos_eleccion_metrica_resueltos to authenticated;

create view public.propuesta_elecciones_secuencia as
with derivado as (
	select er.origen_termino_id as termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.esquemas_rima er
	join public.opciones_eleccion_metrica o on o.esquema_rima_id = er.esquema_rima_id
	where er.origen_termino_id is not null
	union all
	select rv.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.rasgo_valores rv
	join public.opciones_eleccion_metrica o on o.valor_rasgo_id = rv.valor_id
	where rv.origen_termino_id is not null
	union all
	select va.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.variedades_arquitectura va
	join public.opciones_eleccion_metrica o on o.variedad_id = va.variedad_id
	where va.origen_termino_id is not null
	union all
	select m.origen_termino_id, o.grupo_eleccion_id, o.opcion_eleccion_id
	from public.metros m
	join public.opciones_eleccion_metrica o on o.metro_id = m.metro_id
	where m.origen_termino_id is not null
),
declarado as (
	select e.termino_id, e.grupo_eleccion_id, o.opcion_eleccion_id
	from public.equivalencias_respuestas_legadas e
	join public.opciones_eleccion_metrica o
		on o.grupo_eleccion_id = e.grupo_eleccion_id
		and o.metro_id is not distinct from e.metro_id
		and o.esquema_rima_id is not distinct from e.esquema_rima_id
		and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
		and o.variedad_id is not distinct from e.variedad_id
		and o.repeticion_id is not distinct from e.repeticion_id
		and o.posicion_unidad is not distinct from e.posicion_unidad
),
reclamado as (
	select termino_id, grupo_eleccion_id, opcion_eleccion_id from derivado
	union
	select termino_id, grupo_eleccion_id, opcion_eleccion_id from declarado
)
select p.secuencia_id, g.grupo_eleccion_id, g.nombre as pregunta,
	r.opcion_eleccion_id, o.nombre as respuesta, g.alcance
from public.propuesta_metrica_secuencia p
join reclamado r on r.termino_id = p.estrofa_tipo_id
join public.grupos_eleccion_metrica_resueltos g
	on g.grupo_eleccion_id = r.grupo_eleccion_id
	and g.arquitectura_id = p.arquitectura_propuesta_id
	and g.activo
join public.opciones_eleccion_metrica o on o.opcion_eleccion_id = r.opcion_eleccion_id
left join public.arquitecturas_forma a on a.arquitectura_id = p.arquitectura_propuesta_id
where g.alcance = 'secuencia'
	or g.alcance = 'unidad'
		and a.unidad_versos_min is not null
		and (p.v_fin - p.v_ini + 1) = a.unidad_versos_min;

comment on view public.propuesta_elecciones_secuencia is
	'Las respuestas que el término legado ya contenía, para cada secuencia. Las de ámbito unidad solo se proponen cuando la secuencia es una sola unidad.';

grant select on public.propuesta_elecciones_secuencia to authenticated;

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
	v_mal text;
begin
	-- Ninguna pregunta puede quedarse sin enunciado: si alguna no se deriva, es que falta
	-- declarar algo, no que haya que volver a escribirla a mano.
	select count(*), string_agg(slug, ', ') into v_n, v_mal
	from public.grupos_eleccion_metrica_resueltos
	where activo and coalesce(btrim(nombre), '') = '';
	if v_n <> 0 then
		raise exception '% preguntas se quedan sin enunciado: %', v_n, v_mal;
	end if;

	-- Todo rasgo que se pregunte tiene que decir cómo se pregunta.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	join public.rasgos_metricos rm on rm.rasgo_id = g.rasgo_id
	where g.activo and coalesce(btrim(rm.pregunta), '') = '';
	if v_n <> 0 then
		raise exception '% rasgos preguntados no declaran su pregunta', v_n;
	end if;

	-- El plegado del editor tiene que seguir plegando lo mismo: tres preguntas del villancico
	-- que se responden juntas, y ninguna otra.
	select count(*) into v_n from (
		select 1 from public.grupos_eleccion_metrica_resueltos
		where activo group by arquitectura_id, dimension, nombre having count(*) > 1
	) s;
	if v_n <> 3 then
		raise exception 'El editor plegaría % preguntas en vez de las 3 del villancico', v_n;
	end if;

	-- Y las respuestas que el término legado ya contenía no pueden moverse: si se movieran,
	-- es que la derivación cambió qué ofrece alguna pregunta, no solo cómo se rotula.
	select count(*) into v_n from public.propuesta_elecciones_secuencia;
	if v_n <> 91 then
		raise exception 'La propuesta de respuestas debe seguir dando 91 filas, y da %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

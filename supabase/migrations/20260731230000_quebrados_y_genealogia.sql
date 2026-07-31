begin;

-- Tres cosas pequeñas y una que estaba rota.
--
-- 1 · `validar_posicion_opcion_eleccion_metrica` exigía que una elección posicional
--     colgara de una sección. Se escribió cuando «alcance unidad + sección» era la única
--     manera de dirigirse a una unidad; desde que la unidad envolvente existe, una pregunta
--     sin sección **es** la pregunta por la unidad entera, que es justo donde una posición
--     tiene sentido. La regla rechazaba hoy las posiciones de la copla real y las de la
--     copla de pie quebrado.
--
-- 2 · La copla de pie quebrado partía en dos respuestas inconexas dónde caen los quebrados
--     —doce booleanos— y cuánto miden —cuatro medidas—. Nada ligaba «hay quebrado en la 3»
--     con «los quebrados miden 4». Pasa a ser una sola respuesta posicional de medida, como
--     ya la tiene la copla real.
--
-- 3 · El sexteto-lira no declaraba ningún parentesco. No es un sexteto modificado: es una
--     ampliación de la lira garcilasiana, y su heterometría de 7 y 11 no es una medida más
--     sino su principio constructivo.

-- ---------------------------------------------------------------------------
-- 1 · Una elección posicional se dirige a la unidad o a una de sus partes
-- ---------------------------------------------------------------------------

create or replace function public.validar_posicion_opcion_eleccion_metrica()
returns trigger
language plpgsql
set search_path to 'public'
as $$
declare
	v_dimension text;
	v_alcance text;
begin
	if new.posicion_unidad is null then
		return new;
	end if;

	select dimension, alcance
	into v_dimension, v_alcance
	from public.grupos_eleccion_metrica
	where grupo_eleccion_id = new.grupo_eleccion_id;

	-- La posición se cuenta dentro de la unidad, así que la pregunta tiene que hacerse por
	-- unidad. Que apunte a una sección o a la unidad entera es indiferente aquí.
	if v_alcance <> 'unidad' then
		raise exception 'Una elección posicional debe preguntarse por unidad';
	end if;

	if (v_dimension = 'metro' and new.metro_id is null)
		or (v_dimension = 'rasgo' and new.rasgo_id is null)
		or v_dimension not in ('metro', 'rasgo')
	then
		raise exception
			'Una elección posicional debe asignar un metro o un rasgo según la dimensión del grupo';
	end if;

	return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · Los quebrados de la copla de pie quebrado: una sola respuesta
-- ---------------------------------------------------------------------------

create temporary table copla_quebrada on commit drop as
select arquitectura.arquitectura_id
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
where forma.slug = 'copla_de_pie_quebrado';

-- El vector de doce booleanos desaparece: el rasgo describe una propiedad, no una posición.
delete from public.grupos_eleccion_metrica
where slug = 'posiciones_pies_quebrados'
	and arquitectura_id in (select arquitectura_id from copla_quebrada);

-- La pregunta que queda pasa a decir, de una vez, qué verso es quebrado y cuánto mide.
update public.grupos_eleccion_metrica
set nombre = 'Versos quebrados',
	ayuda_editor = 'Señala qué versos son quebrados y con qué medida. El resto son octosílabos.',
	dimension = 'metro',
	alcance = 'unidad',
	seccion_id = null,
	selecciones_min = 1,
	selecciones_max = 12
where slug = 'medidas_pies_quebrados'
	and arquitectura_id in (select arquitectura_id from copla_quebrada);

delete from public.opciones_eleccion_metrica
where grupo_eleccion_id in (
	select grupo_eleccion_id
	from public.grupos_eleccion_metrica
	where slug = 'medidas_pies_quebrados'
		and arquitectura_id in (select arquitectura_id from copla_quebrada)
);

insert into public.opciones_eleccion_metrica (
	grupo_eleccion_id, slug, nombre, metro_id, posicion_unidad, orden
)
select
	grupo.grupo_eleccion_id,
	format('verso_%s_%s_silabas', posicion.n, metro.silabas),
	format('Verso %s · %s sílabas', posicion.n, metro.silabas),
	metro.metro_id,
	posicion.n,
	posicion.n * 10 + metro.silabas
from public.grupos_eleccion_metrica grupo
cross join generate_series(1, 12) as posicion(n)
cross join public.metros metro
where grupo.slug = 'medidas_pies_quebrados'
	and grupo.arquitectura_id in (select arquitectura_id from copla_quebrada)
	and metro.silabas between 4 and 7
	and metro.tipo = 'simple';

do $$
declare
	v_opciones integer;
begin
	select count(*) into v_opciones
	from public.opciones_eleccion_metrica opcion
	join public.grupos_eleccion_metrica grupo
		on grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	where grupo.slug = 'medidas_pies_quebrados';
	if v_opciones <> 48 then
		raise exception 'Se esperaban 48 opciones de verso quebrado y hay %', v_opciones;
	end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · El sexteto-lira desciende de la lira
-- ---------------------------------------------------------------------------

insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision)
select
	origen.forma_id,
	destino.forma_id,
	'derivada_de',
	'El sexteto-lira no es un sexteto modificado: amplía la lira garcilasiana a seis versos y conserva su principio constructivo, el contraste entre el heptasílabo que impulsa y el endecasílabo que reposa.',
	'revisada'
from public.formas_metricas origen, public.formas_metricas destino
where origen.slug = 'sexteto_lira'
	and destino.slug = 'lira'
	and not exists (
		select 1 from public.forma_relaciones existente
		where existente.forma_origen_id = origen.forma_id
			and existente.forma_destino_id = destino.forma_id
			and existente.tipo_relacion = 'derivada_de'
	);

commit;

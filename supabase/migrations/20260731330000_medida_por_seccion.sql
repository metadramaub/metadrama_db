begin;

-- La medida se pregunta donde puede variar, y el esquema de la copla de arte mayor por unidad.
--
-- Cuatro preguntas tenían alcance de secuencia, que es afirmar que el hecho no varía dentro
-- del pasaje. Y lo que no varía y además es estructural no se pregunta: lo declara la
-- arquitectura. El alcance de secuencia queda para los rasgos, que describen el pasaje sin
-- cambiar su estructura.
--
-- 1 · El villancico y el zéjel preguntaban «¿qué medidas aparecen?» y admitían marcar las
--     dos, de modo que registraban que hay hexasílabos y octosílabos sin decir dónde. Lo
--     habitual es que sean isosilábicos, pero pueden mezclar medidas —una cabeza hexasílaba
--     con coplas octosílabas—, así que la medida pertenece a cada sección y ahí se pregunta.
--     Que el editor pueda declarar de una vez que toda la composición es isosilábica es un
--     atajo de interfaz, no una afirmación del modelo.
--
--     Se registran 6 y 8 porque son las medidas típicas. Una distinta se registra como
--     desviación, que es el mecanismo previsto para lo que la norma no contempla.
--
-- 2 · La copla de arte mayor elegía uno de sus tres esquemas una sola vez para toda la
--     tirada. Los tres alternan de estrofa en estrofa, así que la pregunta es por unidad,
--     como en la quintilla, la redondilla o el soneto.

-- ---------------------------------------------------------------------------
-- 1 · La medida del villancico y del zéjel, sección por sección
-- ---------------------------------------------------------------------------

create temporary table arquitecturas_con_secciones on commit drop as
select arquitectura.arquitectura_id, arquitectura.slug as arquitectura_slug, forma.slug as forma_slug
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
where forma.slug in ('villancico', 'zejel');

delete from public.grupos_eleccion_metrica
where slug = 'medidas_realizadas'
	and arquitectura_id in (select arquitectura_id from arquitecturas_con_secciones);

-- Las secciones que sostienen versos son las que pueden tener medida propia; las que solo
-- agrupan otras —el ciclo de copla, la copla misma— no miden nada.
create temporary table secciones_con_versos on commit drop as
select
	seccion.seccion_id,
	seccion.arquitectura_id,
	seccion.tipo_seccion,
	seccion.nombre,
	seccion.orden,
	row_number() over (
		partition by seccion.arquitectura_id, seccion.tipo_seccion
		order by seccion.orden, seccion.nombre
	) as repeticion,
	row_number() over (
		partition by seccion.arquitectura_id
		order by seccion.orden, seccion.nombre
	) as posicion
from public.estructuras_secciones seccion
join arquitecturas_con_secciones arquitectura
	on arquitectura.arquitectura_id = seccion.arquitectura_id
where seccion.versos_min is not null;

-- Cada una de ellas declara el conjunto de medidas admitidas, como ya hacían las del zéjel.
update public.estructuras_secciones seccion
set esquema_metrico_id = (
	select esquema.esquema_metrico_id
	from public.esquemas_metricos esquema
	where esquema.arquitectura_id = seccion.arquitectura_id
		and esquema.tipo = 'conjunto_permitido'
	limit 1
)
where seccion.seccion_id in (select seccion_id from secciones_con_versos)
	and seccion.esquema_metrico_id is null;

insert into public.grupos_eleccion_metrica (
	arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, seccion_id, tipo_control,
	selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
)
select
	seccion.arquitectura_id,
	case when seccion.repeticion = 1
		then format('medida_%s', seccion.tipo_seccion)
		else format('medida_%s_%s', seccion.tipo_seccion, seccion.repeticion)
	end,
	format('¿Qué miden los versos de «%s»?', seccion.nombre),
	'Lo habitual es que toda la composición use una sola medida. Si otra sección difiere, respóndela por separado.',
	'metro', 'unidad', seccion.seccion_id, 'opciones',
	1, 1, true, 'revisada', true, seccion.posicion
from secciones_con_versos seccion;

insert into public.opciones_eleccion_metrica (grupo_eleccion_id, slug, nombre, metro_id, orden)
select grupo.grupo_eleccion_id, metro.slug, format('%s sílabas', metro.silabas), metro.metro_id, metro.silabas
from public.grupos_eleccion_metrica grupo
join secciones_con_versos seccion on seccion.seccion_id = grupo.seccion_id
cross join public.metros metro
where metro.silabas in (6, 8) and metro.tipo = 'simple'
	and grupo.dimension = 'metro'
	and grupo.slug like 'medida\_%';

-- ---------------------------------------------------------------------------
-- 2 · El esquema de la copla de arte mayor se elige en cada copla
-- ---------------------------------------------------------------------------

update public.grupos_eleccion_metrica grupo
set alcance = 'unidad',
	permite_aplicar_global = true,
	ayuda_editor = 'Elige uno de los tres esquemas reconocidos. Si toda la tirada usa el mismo, puedes aplicarlo a todas las coplas.'
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
where arquitectura.arquitectura_id = grupo.arquitectura_id
	and forma.slug = 'copla_de_arte_mayor'
	and grupo.slug = 'esquema_rima';

-- ---------------------------------------------------------------------------
-- Comprobaciones
-- ---------------------------------------------------------------------------

do $$
declare
	v_secuencia integer;
	v_grupos integer;
	v_opciones integer;
begin
	select count(*) into v_secuencia
	from public.grupos_eleccion_metrica
	where alcance = 'secuencia' and dimension in ('metro', 'rima', 'estructura', 'repeticion');
	if v_secuencia <> 0 then
		raise exception 'Quedan % preguntas estructurales con alcance de secuencia', v_secuencia;
	end if;

	select count(*), count(*) filter (where true) into v_grupos, v_opciones
	from public.grupos_eleccion_metrica grupo
	join public.arquitecturas_forma arquitectura on arquitectura.arquitectura_id = grupo.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug in ('villancico', 'zejel') and grupo.dimension = 'metro';
	if v_grupos <> 14 then
		raise exception 'Se esperaban 14 preguntas de medida por sección y hay %', v_grupos;
	end if;

	select count(*) into v_opciones
	from public.opciones_eleccion_metrica opcion
	join public.grupos_eleccion_metrica grupo on grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	join public.arquitecturas_forma arquitectura on arquitectura.arquitectura_id = grupo.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug in ('villancico', 'zejel') and grupo.dimension = 'metro';
	if v_opciones <> 28 then
		raise exception 'Se esperaban 28 opciones de medida y hay %', v_opciones;
	end if;
end;
$$;

commit;

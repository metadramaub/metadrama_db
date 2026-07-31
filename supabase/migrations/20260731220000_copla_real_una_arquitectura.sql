begin;

-- La copla real es una sola arquitectura, y el pie quebrado un rasgo suyo.
--
-- Tenerlo o no tenerlo no cambia la norma: son diez octosílabos en dos quintillas, y uno o
-- dos de esos versos pueden ser quebrados. Eso es un rasgo admitido de la arquitectura, no
-- una arquitectura distinta. Las dos que había —`con_pie_quebrado` y `sin_pie_quebrado`—
-- se funden en una.
--
-- Dónde caen los quebrados no lo fija la norma: lo dice el editor. Por eso se pregunta, y
-- se pregunta como medida de una posición —«la posición 3 es tetrasílaba»— y no como doce
-- booleanos sueltos que no se ligan con la medida. Es el defecto D7.

-- ---------------------------------------------------------------------------
-- 1 · Las dos arquitecturas se funden en la que ya reutiliza la quintilla
-- ---------------------------------------------------------------------------

create temporary table copla_real_arquitecturas on commit drop as
select
	arquitectura.arquitectura_id,
	arquitectura.slug
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
where forma.slug = 'copla_real';

do $$
declare
	v_total integer;
begin
	select count(*) into v_total from copla_real_arquitecturas;
	if v_total <> 2 then
		raise exception 'Se esperaban 2 arquitecturas de copla real y hay %', v_total;
	end if;
end;
$$;

-- La pregunta por las posiciones del quebrado se traslada a la arquitectura que se
-- conserva, para no perderla al retirar la otra.
update public.grupos_eleccion_metrica grupo
set arquitectura_id = (select arquitectura_id from copla_real_arquitecturas where slug = 'sin_pie_quebrado'),
	seccion_id = null,
	selecciones_min = 0,
	nombre = 'Versos quebrados',
	ayuda_editor = 'Señala qué versos son quebrados y con qué medida. Déjalo vacío si la copla no los tiene.'
where grupo.slug = 'posiciones_pie_quebrado'
	and grupo.arquitectura_id = (select arquitectura_id from copla_real_arquitecturas where slug = 'con_pie_quebrado');

-- Las opciones de esa pregunta apuntan al metro de cuatro sílabas, que no pertenece a
-- ninguna arquitectura, así que el traslado no las invalida.

-- El rasgo pasa a admitido y se traslada, en vez de duplicarse: la copla real lo admite,
-- no lo exige.
update public.arquitectura_rasgos rasgo
set arquitectura_id = (select arquitectura_id from copla_real_arquitecturas where slug = 'sin_pie_quebrado'),
	modalidad = 'admitida',
	nota = 'Uno o dos de los diez versos pueden ser quebrados. Dónde caen lo observa el editor.'
from public.rasgos_metricos catalogo
where catalogo.rasgo_id = rasgo.rasgo_id
	and catalogo.slug = 'pie_quebrado'
	and rasgo.arquitectura_id = (select arquitectura_id from copla_real_arquitecturas where slug = 'con_pie_quebrado');

delete from public.arquitecturas_forma
where arquitectura_id = (select arquitectura_id from copla_real_arquitecturas where slug = 'con_pie_quebrado');

-- La que queda deja de llamarse por lo que no tiene.
update public.arquitecturas_forma arquitectura
set slug = 'octosilabica_consonante',
	nombre = 'Octosilábica consonante',
	principal = true,
	descripcion = 'Diez octosílabos en dos quintillas. Uno o dos versos pueden ser quebrados.'
from public.formas_metricas forma
where forma.forma_id = arquitectura.forma_id
	and forma.slug = 'copla_real';

do $$
declare
	v_total integer;
	v_grupos integer;
begin
	select count(*) into v_total
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'copla_real';
	if v_total <> 1 then
		raise exception 'La copla real debe quedar con una arquitectura y tiene %', v_total;
	end if;

	select count(*) into v_grupos
	from public.grupos_eleccion_metrica grupo
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = grupo.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'copla_real';
	if v_grupos <> 3 then
		raise exception 'La copla real debe conservar sus tres preguntas y tiene %', v_grupos;
	end if;
end;
$$;

commit;

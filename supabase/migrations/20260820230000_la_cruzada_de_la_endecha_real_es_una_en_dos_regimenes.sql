-- La cruzada de la endecha real es una en dos regímenes
--
-- Al revisar cómo se leen sus disposiciones, el IP notó que las dos cruzadas quedaban separadas
-- por los versos sueltos, y preguntó si no estarían mal codificadas. Están: no en el reparto en
-- dos esquemas, sino en la **modalidad**, y la fuente lo dice sin ambigüedad. El *Diccionario*
-- describe la variante así:
--
-- > «Riman en asonante los versos pares. El verso endecasílabo puede ocupar otro lugar; y **pueden
-- > rimar, en consonante o en asonante, los versos pares, por un lado, y los impares, por otro**.
-- > Puede encontrarse, igualmente, sin rima.»
--
-- O sea: la cruzada es **una sola variante ofrecida en los dos regímenes**, sin preferir ninguno,
-- y en la misma enumeración que la ausencia de rima. El `excepcional` de la consonante no lo
-- sostiene ninguna de las trece afirmaciones de la forma: era una inferencia, seguramente de que
-- la consonancia extrañe en una forma asonante por naturaleza.
--
-- Puestas las dos en `admitida` —que es donde están ya la abrazada y la suelta, las otras dos
-- variantes de esa misma enumeración—, el orden las deja contiguas sin tocar el orden: primero
-- manda la modalidad y luego el nombre, y «Cruzada asonante» y «Cruzada consonante» se siguen.
--
-- **Y los nombres pasan a decir su régimen, todos.** Convivían tres estilos: uno decía dónde cae
-- la asonancia, otro solo la disposición y otros dos disposición y régimen. Con el régimen
-- impreso además en su columna desde ayer, la regla que el IP eligió es que **cada fila se lea
-- sola**: el nombre nombra la disposición y su régimen, y la columna lo confirma. Solo hay que
-- tocar «Abrazada»: «Asonancia sostenida en los versos cuartos» y «Versos sueltos» ya dicen el
-- suyo al decir la rima misma.
--
-- *El pareado tiene el otro caso del catálogo —dos disposiciones `aa` llamadas «Asonante» y
-- «Consonante»— y se le aplicará la misma regla en su revisión, junto con el régimen «Otras» que
-- hoy declara arriba teniendo dos abajo.*

begin;

do $$
declare
	v_arq uuid;
	v_actual text;
	v_n integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'endecha_real' and a.slug = 'heptasilabica_con_endecasilabo' and a.activo;

	if v_arq is null then
		raise exception 'La endecha real no tiene su arquitectura principal activa.';
	end if;

	-- ------------------------------------- La cruzada, en los dos regímenes y al mismo nivel
	select modalidad into v_actual from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'cruzada-consonante';

	if not found then
		raise exception 'No existe la cruzada consonante de la endecha real.';
	end if;
	if v_actual is distinct from 'excepcional' and v_actual is distinct from 'admitida' then
		raise exception 'La modalidad de la cruzada consonante no es la esperada. Dice: %', v_actual;
	end if;
	update public.esquemas_rima set modalidad = 'admitida'
	where arquitectura_id = v_arq and slug = 'cruzada-consonante';

	-- Las cuatro variantes que el Diccionario enumera están al mismo nivel, que es como las da.
	select count(*) into v_n
	from public.esquemas_rima
	where arquitectura_id = v_arq
		and slug in ('abrazada', 'cruzada', 'cruzada-consonante', 'suelta')
		and modalidad = 'admitida';
	if v_n <> 4 then
		raise exception 'Solo % de las cuatro variantes están en «admitida».', v_n;
	end if;

	-- Y la asonantada sigue siendo la corriente, que es lo que la fuente narra.
	if not exists (
		select 1 from public.esquemas_rima
		where arquitectura_id = v_arq and slug = 'asonantada' and modalidad = 'habitual'
	) then
		raise exception 'La asonantada ha dejado de ser la disposición habitual.';
	end if;

	-- --------------------------------------------- Cada fila dice su disposición y su régimen
	update public.esquemas_rima set nombre = 'Abrazada asonante'
	where arquitectura_id = v_arq and slug = 'abrazada' and nombre in ('Abrazada', 'Abrazada asonante');

	select count(*) into v_n
	from public.esquemas_rima
	where arquitectura_id = v_arq
		and (nombre ilike '%asonan%' or nombre ilike '%consonante%' or nombre ilike '%sueltos%');
	if v_n <> 5 then
		raise exception 'Solo % de las cinco disposiciones dicen su régimen en el nombre.', v_n;
	end if;

	-- ------------------------------------------------------------------ Comprobación
	-- Las dos cruzadas quedan contiguas: mandan la modalidad y luego el nombre.
	select string_agg(nombre, ' | ' order by
		case modalidad
			when 'definitoria' then 0 when 'habitual' then 1 when 'admitida' then 2 else 3 end,
		nombre)
	into v_actual
	from public.esquemas_rima where arquitectura_id = v_arq;

	if v_actual is distinct from
		'Asonancia sostenida en los versos cuartos | Abrazada asonante | Cruzada asonante | '
		|| 'Cruzada consonante | Versos sueltos'
	then
		raise exception 'El orden de las disposiciones no es el esperado. Sale: %', v_actual;
	end if;
end $$;

commit;

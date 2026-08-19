-- La silva de consonantes se sostiene en su heterometría
--
-- La nota de la relación con el pareado decía lo mismo en tres frases y dejaba en el aire cuál
-- de las cuatro silvas contrastaba: nombraba la de consonantes y la endecasilábica sin decir que
-- la segunda es la consecuencia, no otro sujeto.
--
-- Lo que hay que entender es una sola cosa: la silva de consonantes **son** pareados de siete y
-- once, y lo único que la mantiene silva es que alterna las dos medidas. De ahí se sigue el caso
-- de la endecasilábica, sin necesidad de presentarlo como un segundo contraste.
--
-- Que el solape lo reconoce la propia fuente ya está donde debe: en la afirmación de Morley y
-- Bruerton, que dice de su silva 1.ª que «se podría llamar pareados de 7 y 11».

begin;

do $$
declare
	v_silva uuid;
	v_pareado uuid;
	v_actual text;
	v_viejo constant text :=
		'En el fondo son la misma figura: la silva de consonantes podría llamarse pareados de siete y once. Lo que las separa es que la silva fija esa alternancia y corre como serie abierta, mientras que el pareado es una estrofa de dos versos cuya medida declara cada pasaje y que admite también asonancia. De ahí que una serie de solo endecasílabos con pareados sistemáticos se registre como tirada de pareados y no como silva: sin heterometría no queda nada que las distinga.';
	v_nuevo constant text :=
		'La silva de consonantes son pareados de siete y once, y lo único que la mantiene silva es que alterna las dos medidas. Sin esa heterometría no queda nada que las distinga: por eso una serie de solo endecasílabos con pareados sistemáticos se registra como tirada de pareados.';
begin
	select forma_id into v_silva from public.formas_metricas where slug = 'silva' and activo;
	select forma_id into v_pareado from public.formas_metricas where slug = 'pareado' and activo;

	select nota into v_actual
	from public.forma_relaciones
	where forma_origen_id = v_silva
		and forma_destino_id = v_pareado
		and tipo_relacion = 'contrasta_con';

	if not found then
		raise exception 'No existe la relación entre la silva y el pareado.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La nota de la relación no es la esperada. Dice: %', v_actual;
	end if;

	update public.forma_relaciones
	set nota = v_nuevo
	where forma_origen_id = v_silva
		and forma_destino_id = v_pareado
		and tipo_relacion = 'contrasta_con';
end $$;

commit;

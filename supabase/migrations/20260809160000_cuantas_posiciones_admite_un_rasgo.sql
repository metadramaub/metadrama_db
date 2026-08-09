-- Cuántas posiciones de la unidad puede ocupar un rasgo.
--
-- Es el sexto hueco que encontró la auditoría de las preguntas del editor, el 9 de agosto de
-- 2026, y el único que no estaba en las opciones sino en el grupo: la copla real admite el pie
-- quebrado en **una o dos** de sus diez posiciones, y esa norma vivía en `selecciones_max` de
-- la pregunta y en una nota en prosa —«Uno o dos de los diez versos pueden ser quebrados»—.
-- Retirar las preguntas sin declararla perdería la norma.
--
-- Se añade **solo el máximo**, y conviene explicar por qué no también el mínimo: el mínimo se
-- deriva de la modalidad con la que la arquitectura declara el rasgo. `definitoria` significa
-- que el rasgo tiene que aparecer, de modo que el mínimo es uno —la copla de pie quebrado no
-- lo es si no quiebra ningún verso—; `admitida` significa que puede no aparecer, de modo que el
-- mínimo es cero. Declararlo sería escribir lo que ya se deduce, y añadir una columna que
-- nadie rellenaría con algo distinto de lo derivable es justo lo que le pasó a `valor_numero`.
--
-- El máximo, en cambio, no se deduce de nada. Cuando no se declara, el techo es la extensión de
-- la unidad: la copla de pie quebrado admite hasta doce quebrados porque tiene hasta doce
-- versos. Lo que la copla real necesita decir es que su techo es **más bajo que su unidad**.
--
-- No cambia ninguna anotación ni ninguna pregunta: declara en el catálogo un hecho que hasta
-- ahora solo estaba en el formulario.

begin;

alter table public.arquitectura_rasgos
	add column if not exists posiciones_max integer;

alter table public.arquitectura_rasgos
	drop constraint if exists arquitectura_rasgos_posiciones_max_check;

alter table public.arquitectura_rasgos
	add constraint arquitectura_rasgos_posiciones_max_check
	check (posiciones_max is null or posiciones_max >= 1);

comment on column public.arquitectura_rasgos.posiciones_max is
	'Cuántas posiciones de la unidad puede ocupar el rasgo como máximo, cuando el techo es más bajo que la propia unidad: la copla real admite el pie quebrado en dos de sus diez versos. Nulo significa que no hay más límite que la extensión de la unidad. El mínimo no se declara porque lo da la modalidad: «definitoria» exige al menos una posición y «admitida» permite ninguna.';

do $$
declare
	v_arq uuid;
	v_rasgo uuid;
	v_n integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'copla_real' and a.slug = 'octosilabica_consonante';

	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'pie_quebrado';

	if num_nonnulls(v_arq, v_rasgo) <> 2 then
		raise exception 'Falta la copla real o el rasgo del pie quebrado';
	end if;

	update public.arquitectura_rasgos
	set posiciones_max = 2,
		nota = 'Dónde caen los quebrados lo observa el editor; cuántos caben lo declara el catálogo.',
		updated_at = now()
	where arquitectura_id = v_arq and rasgo_id = v_rasgo;

	select count(*) into v_n from public.arquitectura_rasgos
	where arquitectura_id = v_arq and rasgo_id = v_rasgo and posiciones_max = 2;
	if v_n <> 1 then
		raise exception 'La copla real debe declarar un techo de dos posiciones quebradas';
	end if;

	-- Lo declarado tiene que coincidir con lo que la pregunta permite hoy: si no, uno de los
	-- dos está mal y hay que mirarlo antes de derivar nada.
	select g.selecciones_max into v_n
	from public.grupos_eleccion_metrica g
	where g.arquitectura_id = v_arq and g.slug = 'posiciones_pie_quebrado';
	if v_n <> 2 then
		raise exception 'La pregunta de la copla real permitía % respuestas, no 2', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

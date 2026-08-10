-- El tipo de repetición solo dice lo que hay.
--
-- `repeticiones_metricas.tipo` admitía cinco valores desde la migración fundacional del 28 de
-- julio —`palabra_final · verso · estribillo · seccion · otro`— y el catálogo, ya contrastado con
-- las seis fuentes en sus 29 entradas, solo ha usado dos.
--
-- Uno de los tres que sobran **era además un defecto**: `estribillo` y `seccion` no son
-- excluyentes, porque un estribillo es una sección. El demarcador pregunta con este vocabulario
-- —«¿Qué elemento se repite de forma estructural?»— y las opciones de una pregunta tienen que
-- serlo. Hoy no daba guerra porque `seccion` no tenía ni una fila, pero la primera repetición de
-- una sección que no fuera estribillo podría haberse codificado de las dos maneras, sin nada que
-- eligiera entre ellas.
--
-- `otro` no es una clase sino la ausencia de una, y `verso` es una clase legítima que ninguna
-- forma ha necesitado. Con el gestor camino de dejar de ser editable y todo yendo por migración,
-- un valor nuevo se añade en la migración que lo necesite, y entonces se sabrá qué es.

begin;

alter table public.repeticiones_metricas
	drop constraint if exists repeticiones_metricas_tipo_check;

alter table public.repeticiones_metricas
	add constraint repeticiones_metricas_tipo_check
	check (tipo in ('palabra_final', 'estribillo'));

do $$
declare
	v_n integer;
	v_mal text;
	v_json jsonb;
begin
	-- Las once siguen ahí y ninguna ha cambiado de clase.
	select count(*), string_agg(distinct tipo, ', ') into v_n, v_mal
	from public.repeticiones_metricas;
	if v_n <> 11 or v_mal <> 'estribillo, palabra_final' then
		raise exception 'Las repeticiones son % con tipos «%»', v_n, v_mal;
	end if;

	-- La restricción rechaza de verdad lo retirado. Se prueba insertando y deshaciendo, porque
	-- una restricción que no se ejerce es una promesa.
	begin
		insert into public.repeticiones_metricas (arquitectura_id, slug, nombre, tipo)
		select arquitectura_id, 'prueba_tipo_retirado', 'Prueba', 'seccion'
		from public.arquitecturas_forma limit 1;
		raise exception 'La restricción admitió el tipo `seccion`, que debía rechazar';
	exception
		when check_violation then
			null;
	end;

	-- Y lo que proyecta repeticiones sigue corriendo.
	select public.obtener_catalogo_demarcador() into v_json;
	if not (v_json ? 'repetitions') then
		raise exception 'El catálogo del demarcador salió sin repeticiones';
	end if;

	select public.get_forma_metrica_publica_jerarquica('villancico') into v_json;
	if coalesce(jsonb_array_length(v_json -> 'repeticiones'), 0) <> 6 then
		raise exception 'La ficha del villancico proyecta % repeticiones en vez de 6',
			coalesce(jsonb_array_length(v_json -> 'repeticiones'), 0);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

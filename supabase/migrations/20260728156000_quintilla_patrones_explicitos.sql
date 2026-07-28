begin;

do $$
declare
	v_forma_id uuid;
	v_configuracion_id uuid;
begin
	select forma_id
	into v_forma_id
	from public.formas_metricas
	where slug = 'quintilla';

	if v_forma_id is null then
		raise exception 'No se encontró la forma quintilla en el catálogo métrico';
	end if;

	select configuracion_id
	into v_configuracion_id
	from public.configuraciones_forma
	where forma_id = v_forma_id
		and slug = 'octosilabica_consonante';

	if v_configuracion_id is null then
		raise exception 'No se encontró la configuración octosilábica consonante de quintilla';
	end if;

	update public.formas_metricas
	set definicion = 'Estrofa de cinco versos octosílabos con rima consonante distribuida en dos clases. El catálogo reconoce ocho tipologías de rima: siete ordinarias y la excepción documentada abbba.'
	where forma_id = v_forma_id;

	-- La lista cerrada de ocho esquemas ya expresa el espacio de posibilidades.
	-- Mantener además un patrón general de restricciones duplicaba la misma norma.
	delete from public.patrones_rima
	where configuracion_id = v_configuracion_id
		and origen_termino_id is null
		and comportamiento = 'restricciones';

	update public.patrones_rima pr
	set
		descripcion = null,
		nombre = case
			when v.termino = 'quintilla_8_abbba'
				then 'Tipología 8 excepcional (abbba)'
			else format(
				'Tipología %s (%s)',
				substring(v.termino from 'quintilla_([0-9]+)_'),
				pr.esquema
			)
		end
	from public.vocabularios v
	where pr.configuracion_id = v_configuracion_id
		and pr.origen_termino_id = v.termino_id
		and v.termino like 'quintilla\_%' escape '\';

	update public.patron_rima_posiciones posicion
	set nota = null
	from public.patrones_rima patron
	where posicion.patron_rima_id = patron.patron_rima_id
		and patron.configuracion_id = v_configuracion_id;
end;
$$;

create or replace function public.sincronizar_posiciones_patron_rima_fijo()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_posicion integer;
	v_clase text;
begin
	if new.comportamiento <> 'secuencia_fija'
		or new.esquema is null
		or new.esquema !~ '^[A-Za-z-]+$'
	then
		return new;
	end if;

	delete from public.patron_rima_posiciones
	where patron_rima_id = new.patron_rima_id;

	for v_posicion in 1..char_length(new.esquema) loop
		v_clase := substring(new.esquema from v_posicion for 1);

		insert into public.patron_rima_posiciones (
			patron_rima_id,
			bloque,
			posicion,
			ubicacion,
			clase_rima,
			suelto,
			opcional
		)
		values (
			new.patron_rima_id,
			1,
			v_posicion,
			'final',
			case when v_clase = '-' then null else v_clase end,
			v_clase = '-',
			false
		);
	end loop;

	return new;
end;
$$;

drop trigger if exists patrones_rima_sincronizar_posiciones_fijas
	on public.patrones_rima;

create trigger patrones_rima_sincronizar_posiciones_fijas
after insert or update of esquema, comportamiento
on public.patrones_rima
for each row
execute function public.sincronizar_posiciones_patron_rima_fijo();

comment on function public.sincronizar_posiciones_patron_rima_fijo() is
	'Convierte automáticamente un esquema fijo simple, como ababa o -a-a, en posiciones computables. Los patrones complejos continúan editándose mediante sus posiciones.';

update public.catalogo_metrico_estado
set modelo_version = 5
where id;

commit;

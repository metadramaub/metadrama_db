begin;

-- Un vocabulario para cada pregunta, y solo uno.
--
-- El catálogo tenía cuatro vocabularios distintos para «cuánta fuerza normativa tiene esto»
-- —`arquitecturas_forma.grado`, `esquemas_rima.fijeza`, `repeticiones_metricas.fijeza` y
-- `arquitectura_rasgos.modalidad`— con dieciocho valores de los que se usaban doce, y dos
-- para «qué forma tiene la secuencia» —`esquemas_metricos.tipo` y
-- `esquemas_rima.comportamiento`— que compartían dos valores y divergían en el resto para
-- decir lo mismo.
--
-- La escala normativa no mide permiso: en este modelo todo es posible aunque no tenga
-- nombre. Mide **cuánto ha fijado la norma o la crítica esa combinación**, que es lo que el
-- catálogo sabe y lo que se puede analizar.
--
--   definitoria  sin esto no es esa forma
--   preferente   es lo esperable, lo que la tradición fijó como típico
--   admitida     está registrada porque aparece, pero no es lo típico
--   excepcional  documentada y rara
--
-- Y la forma de la secuencia deja de mezclar cuatro cosas —la forma, la apertura, la
-- codificación y un estado de revisión— para decir solo la forma:
--
--   ciclo          se repite hasta agotar la extensión
--   secuencia      cada posición se declara una vez
--   conjunto       medidas admitidas sin orden
--   restricciones  la norma se expresa como restricciones, no como posiciones
--   abierta        la norma no fija ninguna disposición
--
-- El caso que más se aclara es el de los diez esquemas que decían `fijeza = libre` y
-- `comportamiento = libre`: eran el mismo hecho dos veces, y ninguno de los dos era
-- normatividad. Pasan a `tipo_secuencia = abierta` con modalidad **definitoria**, porque el
-- sexteto sí tiene norma de rima —es consonante y de orden libre—: lo que no tiene es
-- disposición fijada.

-- ---------------------------------------------------------------------------
-- 1 · La escala normativa
-- ---------------------------------------------------------------------------

alter table public.arquitecturas_forma rename column grado to modalidad;
alter table public.arquitecturas_forma drop constraint if exists arquitecturas_forma_grado_check;
alter table public.arquitecturas_forma alter column modalidad drop default;

update public.arquitecturas_forma
set modalidad = case modalidad
	when 'fija' then 'preferente'
	when 'canonica' then 'preferente'
	when 'rara' then 'excepcional'
	when 'irregular_documentada' then 'excepcional'
	else 'admitida'
end;

alter table public.arquitecturas_forma
	add constraint arquitecturas_forma_modalidad_check
	check (modalidad in ('preferente', 'admitida', 'excepcional'));
alter table public.arquitecturas_forma alter column modalidad set default 'admitida';

comment on column public.arquitecturas_forma.modalidad is
	'Cuánto ha fijado la tradición esta realización. Una arquitectura nunca es definitoria: una realización no define su forma.';

alter table public.esquemas_rima rename column fijeza to modalidad;
alter table public.esquemas_rima drop constraint if exists esquemas_rima_fijeza_check;
alter table public.esquemas_rima drop constraint if exists patrones_rima_fijeza_check;
alter table public.esquemas_rima alter column modalidad drop default;

update public.esquemas_rima
set modalidad = case modalidad
	when 'fijo' then 'definitoria'
	when 'libre' then 'definitoria'
	when 'no_aplica' then 'definitoria'
	when 'preferente' then 'preferente'
	else 'admitida'
end;

alter table public.esquemas_rima
	add constraint esquemas_rima_modalidad_check
	check (modalidad in ('definitoria', 'preferente', 'admitida', 'excepcional'));
alter table public.esquemas_rima alter column modalidad set default 'admitida';

alter table public.repeticiones_metricas rename column fijeza to modalidad;
alter table public.repeticiones_metricas drop constraint if exists repeticiones_metricas_fijeza_check;
alter table public.repeticiones_metricas drop constraint if exists patrones_repeticion_fijeza_check;
alter table public.repeticiones_metricas alter column modalidad drop default;

update public.repeticiones_metricas
set modalidad = case modalidad
	when 'fija' then 'definitoria'
	when 'canonica' then 'preferente'
	when 'habitual' then 'preferente'
	else 'admitida'
end;

alter table public.repeticiones_metricas
	add constraint repeticiones_metricas_modalidad_check
	check (modalidad in ('definitoria', 'preferente', 'admitida', 'excepcional'));
alter table public.repeticiones_metricas alter column modalidad set default 'admitida';

alter table public.arquitectura_rasgos drop constraint if exists arquitectura_rasgos_modalidad_check;
alter table public.arquitectura_rasgos drop constraint if exists configuracion_rasgos_modalidad_check;
alter table public.arquitectura_rasgos alter column modalidad drop default;

update public.arquitectura_rasgos
set modalidad = case modalidad
	when 'habitual' then 'preferente'
	when 'destacable' then 'excepcional'
	else modalidad
end;

alter table public.arquitectura_rasgos
	add constraint arquitectura_rasgos_modalidad_check
	check (modalidad in ('definitoria', 'preferente', 'admitida', 'excepcional'));
alter table public.arquitectura_rasgos alter column modalidad set default 'admitida';

-- ---------------------------------------------------------------------------
-- 2 · La forma de la secuencia
-- ---------------------------------------------------------------------------

alter table public.esquemas_metricos rename column tipo to tipo_secuencia;
alter table public.esquemas_metricos drop constraint if exists esquemas_metricos_tipo_check;
alter table public.esquemas_metricos drop constraint if exists patrones_metricos_tipo_check;

update public.esquemas_metricos
set tipo_secuencia = case tipo_secuencia
	when 'secuencia_repetible' then 'ciclo'
	when 'secuencia_fija' then 'secuencia'
	when 'conjunto_permitido' then 'conjunto'
	when 'abierta' then 'abierta'
	else tipo_secuencia
end;

alter table public.esquemas_metricos
	add constraint esquemas_metricos_tipo_secuencia_check
	check (tipo_secuencia in ('ciclo', 'secuencia', 'conjunto', 'restricciones', 'abierta'));

alter table public.esquemas_rima rename column comportamiento to tipo_secuencia;
alter table public.esquemas_rima drop constraint if exists esquemas_rima_comportamiento_check;
alter table public.esquemas_rima drop constraint if exists patrones_rima_comportamiento_check;
alter table public.esquemas_rima alter column tipo_secuencia drop default;

-- El disparador que deriva posiciones de una notación simple leía la columna por su nombre
-- viejo. Se recrea antes del `update`, porque ese `update` lo dispara.
create or replace function public.sincronizar_posiciones_esquema_rima_fijo()
returns trigger
language plpgsql
set search_path to 'public'
as $sincronizar$
declare
	v_posicion integer;
	v_clase text;
begin
	if new.tipo_secuencia <> 'secuencia'
		or new.notacion is null
		or new.notacion !~ '^[A-Za-z-]+$'
	then
		return new;
	end if;

	delete from public.esquema_rima_posiciones
	where esquema_rima_id = new.esquema_rima_id;

	for v_posicion in 1..char_length(new.notacion) loop
		v_clase := substring(new.notacion from v_posicion for 1);

		insert into public.esquema_rima_posiciones (
			esquema_rima_id, bloque, posicion, ubicacion, clase_rima, suelto, opcional
		)
		values (
			new.esquema_rima_id, 1, v_posicion, 'final',
			case when v_clase = '-' then null else v_clase end,
			v_clase = '-',
			false
		);
	end loop;

	return new;
end;
$sincronizar$;

comment on function public.sincronizar_posiciones_esquema_rima_fijo() is
	'Convierte automáticamente una notación simple, como ababa o -a-a, en posiciones computables. Los esquemas complejos continúan editándose mediante sus posiciones.';

update public.esquemas_rima
set tipo_secuencia = case tipo_secuencia
	when 'secuencia_fija' then 'secuencia'
	when 'secuencia_repetible' then 'ciclo'
	when 'libre' then 'abierta'
	when 'pendiente_revision' then 'abierta'
	else tipo_secuencia
end;

alter table public.esquemas_rima
	add constraint esquemas_rima_tipo_secuencia_check
	check (tipo_secuencia in ('ciclo', 'secuencia', 'conjunto', 'restricciones', 'abierta'));
alter table public.esquemas_rima alter column tipo_secuencia set default 'secuencia';

comment on column public.esquemas_rima.tipo_secuencia is
	'Qué forma tiene la disposición. No dice cuántos versos abarca: eso lo dice la extensión de aquello a lo que pertenece.';

-- ---------------------------------------------------------------------------
-- 3 · El ámbito deja de repetir el nivel de la forma
-- ---------------------------------------------------------------------------
--
-- Decía `estrofa` en todo esquema de una estrofa y `serie` en todo esquema de una serie:
-- 93 de 116 filas repetían `formas_metricas.nivel_estructural`. Lo único que no se deriva es
-- si el esquema describe la unidad entera o una parte suya.

do $$
declare
	v_tabla text;
begin
	foreach v_tabla in array array['esquemas_metricos', 'esquemas_rima', 'repeticiones_metricas']
	loop
		execute format('alter table public.%I drop constraint if exists %I', v_tabla, v_tabla || '_ambito_check');
		execute format('alter table public.%I alter column ambito drop default', v_tabla);
		execute format($sql$
			update public.%I
			set ambito = case ambito when 'seccion' then 'seccion' else 'unidad' end
		$sql$, v_tabla);
		execute format($sql$
			alter table public.%I add constraint %I check (ambito in ('unidad', 'seccion'))
		$sql$, v_tabla, v_tabla || '_ambito_check');
		execute format($sql$alter table public.%I alter column ambito set default 'unidad'$sql$, v_tabla);
	end loop;
end;
$$;

-- Los esquemas de una composición que decían `estrofa` describían una parte, no el todo.
update public.esquemas_rima esquema
set ambito = 'seccion'
from public.arquitecturas_forma arquitectura, public.formas_metricas forma
where arquitectura.arquitectura_id = esquema.arquitectura_id
	and forma.forma_id = arquitectura.forma_id
	and forma.nivel_estructural = 'composicion'
	and exists (
		select 1 from public.estructuras_secciones seccion
		where seccion.esquema_rima_id = esquema.esquema_rima_id
	);

-- ---------------------------------------------------------------------------
-- 4 · Una sola lista de dimensiones
-- ---------------------------------------------------------------------------
--
-- Las desviaciones decían `medida` donde las elecciones dicen `metro`. Una desviación no se
-- podía cruzar con una elección sin traducir. La tabla no tiene datos.

alter table public.desviaciones_editor_metrico
	drop constraint if exists desviaciones_editor_metrico_dimension_check;

update public.desviaciones_editor_metrico set dimension = 'metro' where dimension = 'medida';

alter table public.desviaciones_editor_metrico
	add constraint desviaciones_editor_metrico_dimension_check
	check (dimension in ('metro', 'rima', 'estructura', 'repeticion', 'rasgo', 'combinacion'));

-- ---------------------------------------------------------------------------
-- 5 · La única función que leía una de estas columnas
-- ---------------------------------------------------------------------------

create or replace function public.regla_longitud_arquitectura_metrica(p_arquitectura_id uuid)
returns table (
	modulo_versos integer,
	residuo_versos integer,
	minimo_versos integer,
	origen text,
	explicacion text
)
language plpgsql
stable
set search_path to 'public'
as $$
declare
	v_unidad_min integer;
	v_unidad_max integer;
	v_longitud_ciclo integer;
begin
	select arquitectura.unidad_versos_min, arquitectura.unidad_versos_max
	into v_unidad_min, v_unidad_max
	from public.arquitecturas_forma arquitectura
	where arquitectura.arquitectura_id = p_arquitectura_id
		and arquitectura.activo;

	if not found then
		return;
	end if;

	-- La unidad declarada manda: el pasaje contiene un número entero de unidades.
	if v_unidad_min is not null then
		if v_unidad_min = v_unidad_max and v_unidad_min > 1 then
			return query
			select v_unidad_min, 0, v_unidad_min, 'unidad'::text,
				format('unidades completas de %s versos', v_unidad_min);
		elsif v_unidad_max > v_unidad_min then
			return query
			select 1, 0, v_unidad_min, 'unidad'::text,
				format('unidades de %s a %s versos', v_unidad_min, v_unidad_max);
		end if;
		return;
	end if;

	-- Si la unidad es abierta, la congruencia solo puede venir de un ciclo de rima.
	select count(*)::integer into v_longitud_ciclo
	from public.esquema_rima_posiciones posicion
	join public.esquemas_rima rima
		on rima.esquema_rima_id = posicion.esquema_rima_id
	where rima.arquitectura_id = p_arquitectura_id
		and rima.tipo_secuencia = 'ciclo';

	if v_longitud_ciclo > 1 then
		return query
		select v_longitud_ciclo, 0, v_longitud_ciclo, 'ciclo_rima'::text,
			format('ciclos completos de %s versos', v_longitud_ciclo);
	end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- Comprobaciones
-- ---------------------------------------------------------------------------

do $$
declare
	v_mal integer;
begin
	select count(*) into v_mal from public.arquitecturas_forma
	where modalidad not in ('preferente', 'admitida', 'excepcional');
	if v_mal <> 0 then raise exception '% arquitecturas con modalidad inválida', v_mal; end if;

	select count(*) into v_mal from public.esquemas_rima
	where modalidad not in ('definitoria', 'preferente', 'admitida', 'excepcional')
		or tipo_secuencia not in ('ciclo', 'secuencia', 'conjunto', 'restricciones', 'abierta')
		or ambito not in ('unidad', 'seccion');
	if v_mal <> 0 then raise exception '% esquemas de rima inválidos', v_mal; end if;

	select count(*) into v_mal from public.esquemas_metricos
	where tipo_secuencia not in ('ciclo', 'secuencia', 'conjunto', 'restricciones', 'abierta')
		or ambito not in ('unidad', 'seccion');
	if v_mal <> 0 then raise exception '% esquemas métricos inválidos', v_mal; end if;

	-- Ningún esquema abierto conserva posiciones: si las tuviera, no estaría abierto.
	select count(*) into v_mal
	from public.esquemas_rima rima
	join public.esquema_rima_posiciones posicion
		on posicion.esquema_rima_id = rima.esquema_rima_id
	where rima.tipo_secuencia = 'abierta';
	if v_mal <> 0 then raise exception '% posiciones en esquemas abiertos', v_mal; end if;
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 52,
	revision = revision + 1,
	actualizado_en = now();

commit;

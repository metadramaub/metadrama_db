begin;

-- La compatibilidad del rango se deriva del catálogo. No se guarda un segundo
-- tamaño que pueda quedar desincronizado:
--   1. numero_versos en estrofas y composiciones simples;
--   2. secciones superiores de extensión exacta;
--   3. ciclos repetibles de rima;
--   4. ciclos métricos repetibles.
--
-- La pareja módulo/resto permite expresar tanto 5n (quintilla) como 3n + 1
-- (terceto encadenado con su verso final de cierre).
create or replace function public.regla_longitud_configuracion_metrica(
	p_configuracion_id uuid
)
returns table (
	modulo_versos integer,
	residuo_versos integer,
	minimo_versos integer,
	origen text,
	explicacion text
)
language plpgsql
stable
set search_path = public
as $$
declare
	v_numero_versos integer;
	v_total_secciones integer;
	v_secciones_no_derivables integer;
	v_secciones_abiertas integer;
	v_longitud_abierta integer;
	v_longitud_minima integer;
	v_longitud_fija integer;
	v_total_patrones integer;
	v_patrones_con_posiciones integer;
	v_longitudes_distintas integer;
	v_longitud_ciclo integer;
begin
	select configuracion.numero_versos
	into v_numero_versos
	from public.configuraciones_forma configuracion
	where configuracion.configuracion_id = p_configuracion_id
		and configuracion.activo;

	if not found then
		return;
	end if;

	if v_numero_versos is not null and v_numero_versos > 1 then
		return query
		select
			v_numero_versos,
			0,
			v_numero_versos,
			'numero_versos'::text,
			format('unidades completas de %s versos', v_numero_versos);
		return;
	end if;

	select
		count(*)::integer,
		count(*) filter (
			where seccion.versos_min is null
				or seccion.versos_max is null
				or seccion.versos_min <> seccion.versos_max
				or (
					seccion.repeticiones_max is not null
					and coalesce(seccion.repeticiones_min, 0) <> seccion.repeticiones_max
				)
		)::integer,
		count(*) filter (where seccion.repeticiones_max is null)::integer,
		max(seccion.versos_min) filter (where seccion.repeticiones_max is null)::integer,
		coalesce(
			sum(seccion.versos_min * coalesce(seccion.repeticiones_min, 0)),
			0
		)::integer,
		coalesce(
			sum(
				seccion.versos_min * coalesce(seccion.repeticiones_min, 0)
			) filter (where seccion.repeticiones_max is not null),
			0
		)::integer
	into
		v_total_secciones,
		v_secciones_no_derivables,
		v_secciones_abiertas,
		v_longitud_abierta,
		v_longitud_minima,
		v_longitud_fija
	from public.estructuras_secciones seccion
	where seccion.configuracion_id = p_configuracion_id
		and seccion.seccion_padre_id is null;

	if v_total_secciones > 0 and v_secciones_no_derivables = 0 then
		if v_secciones_abiertas = 0 and v_longitud_minima > 1 then
			return query
			select
				v_longitud_minima,
				0,
				v_longitud_minima,
				'secciones_fijas'::text,
				format('estructuras completas de %s versos', v_longitud_minima);
			return;
		elsif v_secciones_abiertas = 1 and v_longitud_abierta > 1 then
			return query
			select
				v_longitud_abierta,
				mod(v_longitud_fija, v_longitud_abierta),
				v_longitud_minima,
				'secciones_repetibles'::text,
				case
					when v_longitud_fija = 0 then
						format('bloques completos de %s versos', v_longitud_abierta)
					else
						format(
							'bloques completos de %s versos más %s %s fijo%s',
							v_longitud_abierta,
							v_longitud_fija,
							case when v_longitud_fija = 1 then 'verso' else 'versos' end,
							case when v_longitud_fija = 1 then '' else 's' end
						)
				end;
			return;
		end if;
	end if;

	select
		count(*)::integer,
		count(*) filter (where patron.longitud > 0)::integer,
		count(distinct patron.longitud) filter (where patron.longitud > 0)::integer,
		min(patron.longitud) filter (where patron.longitud > 0)::integer
	into
		v_total_patrones,
		v_patrones_con_posiciones,
		v_longitudes_distintas,
		v_longitud_ciclo
	from (
		select
			rima.patron_rima_id,
			count(posicion.posicion_id)::integer as longitud
		from public.patrones_rima rima
		left join public.patron_rima_posiciones posicion
			on posicion.patron_rima_id = rima.patron_rima_id
		where rima.configuracion_id = p_configuracion_id
			and rima.comportamiento = 'secuencia_repetible'
			and rima.estado_revision <> 'retirada'
		group by rima.patron_rima_id
	) patron;

	if v_total_patrones > 0
		and v_total_patrones = v_patrones_con_posiciones
		and v_longitudes_distintas = 1
		and v_longitud_ciclo > 1
	then
		return query
		select
			v_longitud_ciclo,
			0,
			v_longitud_ciclo,
			'ciclo_rima'::text,
			format('ciclos completos de rima de %s versos', v_longitud_ciclo);
		return;
	end if;

	select
		count(*)::integer,
		count(*) filter (where patron.longitud > 0)::integer,
		count(distinct patron.longitud) filter (where patron.longitud > 0)::integer,
		min(patron.longitud) filter (where patron.longitud > 0)::integer
	into
		v_total_patrones,
		v_patrones_con_posiciones,
		v_longitudes_distintas,
		v_longitud_ciclo
	from (
		select
			metrico.patron_metrico_id,
			count(posicion.posicion_id)::integer as longitud
		from public.patrones_metricos metrico
		left join public.patron_metrico_posiciones posicion
			on posicion.patron_metrico_id = metrico.patron_metrico_id
		where metrico.configuracion_id = p_configuracion_id
			and metrico.tipo = 'secuencia_repetible'
			and metrico.estado_revision <> 'retirada'
		group by metrico.patron_metrico_id
	) patron;

	if v_total_patrones > 0
		and v_total_patrones = v_patrones_con_posiciones
		and v_longitudes_distintas = 1
		and v_longitud_ciclo > 1
	then
		return query
		select
			v_longitud_ciclo,
			0,
			v_longitud_ciclo,
			'ciclo_metrico'::text,
			format('ciclos métricos completos de %s versos', v_longitud_ciclo);
	end if;
end;
$$;

comment on function public.regla_longitud_configuracion_metrica(uuid) is
	'Deriva la congruencia que debe cumplir la longitud inclusiva de una secuencia. No duplica la norma del catálogo.';

create or replace view public.configuraciones_forma_reglas_longitud
with (security_invoker = true)
as
select
	configuracion.configuracion_id,
	configuracion.nombre as configuracion_nombre,
	regla.modulo_versos,
	regla.residuo_versos,
	regla.minimo_versos,
	regla.origen,
	regla.explicacion
from public.configuraciones_forma configuracion
cross join lateral public.regla_longitud_configuracion_metrica(
	configuracion.configuracion_id
) regla
where configuracion.activo;

comment on view public.configuraciones_forma_reglas_longitud is
	'Reglas de compatibilidad de longitud derivadas para el registrador de secuencias.';

grant select on public.configuraciones_forma_reglas_longitud to authenticated;

create or replace function public.validar_secuencia_editor_metrico()
returns trigger
language plpgsql
set search_path = public
as $$
declare
	v_regla record;
	v_longitud integer;
	v_nombre_configuracion text;
begin
	if not exists (
		select 1
		from public.configuraciones_forma configuracion
		join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
		where configuracion.configuracion_id = new.configuracion_id
			and configuracion.forma_id = new.forma_id
			and configuracion.activo
			and forma.activo
			and forma.seleccionable
	) then
		raise exception 'La configuración no pertenece a una forma activa y seleccionable';
	end if;

	select *
	into v_regla
	from public.regla_longitud_configuracion_metrica(new.configuracion_id);

	if found then
		v_longitud := new.v_fin - new.v_ini + 1;
		if v_longitud < v_regla.minimo_versos
			or mod(
				mod(v_longitud - v_regla.residuo_versos, v_regla.modulo_versos)
					+ v_regla.modulo_versos,
				v_regla.modulo_versos
			) <> 0
		then
			select nombre into v_nombre_configuracion
			from public.configuraciones_forma
			where configuracion_id = new.configuracion_id;

			raise exception
				'La secuencia contiene % versos. «%» exige %; revisa el rango. Si la fuente presenta una laguna, incorpora el verso que ocupa esa posición y registra la desviación.',
				v_longitud,
				v_nombre_configuracion,
				v_regla.explicacion;
		end if;
	end if;

	return new;
end;
$$;

-- Villancico: «enlace» y «vuelta» son dos nombres para una misma función
-- dentro del criterio del proyecto, no dos secciones acumulables.
do $$
declare
	v_configuracion_id uuid;
	v_patron_relaciones_id uuid;
	v_seccion_copla_id uuid;
	v_seccion_enlace_id uuid;
	v_seccion_vuelta_id uuid;
begin
	select configuracion.configuracion_id
	into v_configuracion_id
	from public.configuraciones_forma configuracion
	join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
	where forma.slug = 'villancico'
		and configuracion.slug = 'estructura_habitual';

	if v_configuracion_id is null then
		raise exception 'No se encontró la configuración habitual del villancico';
	end if;

	select seccion_id into v_seccion_copla_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and seccion_padre_id is null
		and tipo_seccion = 'copla';

	select seccion_id into v_seccion_enlace_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and seccion_padre_id = v_seccion_copla_id
		and tipo_seccion = 'enlace';

	select seccion_id into v_seccion_vuelta_id
	from public.estructuras_secciones
	where configuracion_id = v_configuracion_id
		and seccion_padre_id = v_seccion_copla_id
		and tipo_seccion = 'vuelta';

	if v_seccion_enlace_id is null or v_seccion_vuelta_id is null then
		raise exception 'No se encontraron las secciones heredadas de enlace y vuelta';
	end if;

	delete from public.unidades_editor_metrico enlace
	where enlace.seccion_id = v_seccion_enlace_id
		and exists (
			select 1
			from public.unidades_editor_metrico vuelta
			where vuelta.secuencia_prueba_id = enlace.secuencia_prueba_id
				and vuelta.unidad_padre_id is not distinct from enlace.unidad_padre_id
				and vuelta.seccion_id = v_seccion_vuelta_id
		);

	update public.unidades_editor_metrico
	set seccion_id = v_seccion_vuelta_id
	where seccion_id = v_seccion_enlace_id;

	update public.desviaciones_editor_metrico
	set seccion_observada_id = v_seccion_vuelta_id
	where seccion_observada_id = v_seccion_enlace_id;

	update public.opciones_eleccion_metrica
	set
		seccion_id = case
			when seccion_id = v_seccion_enlace_id then v_seccion_vuelta_id
			else seccion_id
		end,
		materializa_seccion_id = case
			when materializa_seccion_id = v_seccion_enlace_id then v_seccion_vuelta_id
			else materializa_seccion_id
		end,
		extension_desde_seccion_id = case
			when extension_desde_seccion_id = v_seccion_enlace_id then v_seccion_vuelta_id
			else extension_desde_seccion_id
		end
	where seccion_id = v_seccion_enlace_id
		or materializa_seccion_id = v_seccion_enlace_id
		or extension_desde_seccion_id = v_seccion_enlace_id;

	delete from public.estructuras_secciones
	where seccion_id = v_seccion_enlace_id;

	update public.estructuras_secciones
	set
		tipo_seccion = 'enlace_vuelta',
		nombre = 'Enlace o vuelta',
		orden = 2,
		nota = 'Sección opcional que enlaza la mudanza con la recuperación de la rima de la cabeza o estribillo.'
	where seccion_id = v_seccion_vuelta_id;

	update public.estructuras_secciones
	set orden = 3
	where configuracion_id = v_configuracion_id
		and seccion_padre_id = v_seccion_copla_id
		and tipo_seccion = 'estribillo';

	update public.formas_metricas
	set definicion = 'Forma compuesta de arte menor, normalmente hexasílaba u octosílaba, formada por una cabeza o estribillo inicial y una o más coplas. Cada copla contiene una mudanza, generalmente de cuatro versos con esquema abba o abab, un posible enlace o vuelta y la repetición total, parcial o implícita del estribillo.'
	where forma_id = (
		select forma_id
		from public.configuraciones_forma
		where configuracion_id = v_configuracion_id
	);

	update public.configuraciones_forma
	set descripcion = 'Cabeza opcional de dos a cuatro versos y una o más coplas con mudanza de cuatro versos, enlace o vuelta opcional y recuperación del estribillo.'
	where configuracion_id = v_configuracion_id;

	select patron_rima_id into v_patron_relaciones_id
	from public.patrones_rima
	where configuracion_id = v_configuracion_id
		and comportamiento = 'restricciones'
	limit 1;

	if v_patron_relaciones_id is not null then
		update public.patrones_rima
		set
			nombre = 'Relación entre mudanza, enlace o vuelta y estribillo',
			descripcion = 'Cuando existe, el enlace o vuelta conecta la rima final de la mudanza con la recuperación de la cabeza o estribillo.'
		where patron_rima_id = v_patron_relaciones_id;

		delete from public.patron_rima_restricciones
		where patron_rima_id = v_patron_relaciones_id
			and valor_texto in ('enlace_con_mudanza', 'vuelta_con_estribillo');

		insert into public.patron_rima_restricciones (
			patron_rima_id,
			tipo,
			valor_texto,
			descripcion,
			obligatoria
		)
		values (
			v_patron_relaciones_id,
			'otra',
			'enlace_vuelta',
			'Cuando aparece, el enlace o vuelta articula el paso de la mudanza a la rima de la cabeza o estribillo.',
			false
		);
	end if;
end;
$$;

-- Soneto: los cuatro patrones ya pertenecen al catálogo, pero faltaba el
-- contrato que los presenta como una única pregunta de la secuencia.
do $$
declare
	v_configuracion_id uuid;
	v_grupo_id uuid;
	v_total_patrones integer;
begin
	select configuracion.configuracion_id
	into v_configuracion_id
	from public.configuraciones_forma configuracion
	join public.formas_metricas forma on forma.forma_id = configuracion.forma_id
	where forma.slug = 'soneto'
		and configuracion.slug = 'endecasilabo_consonante';

	if v_configuracion_id is null then
		raise exception 'No se encontró la configuración formalizada del soneto';
	end if;

	select count(*) into v_total_patrones
	from public.patrones_rima
	where configuracion_id = v_configuracion_id
		and esquema in (
			'ABBAABBACDCDCD',
			'ABBAABBACDECDE',
			'ABBAABBACDEDCE',
			'ABBAABBACDCEDE'
		);

	if v_total_patrones <> 4 then
		raise exception
			'Se esperaban cuatro patrones de tercetos del soneto y se encontraron %',
			v_total_patrones;
	end if;

	insert into public.grupos_eleccion_metrica (
		configuracion_id,
		slug,
		nombre,
		ayuda_editor,
		dimension,
		alcance,
		selecciones_min,
		selecciones_max,
		estado_revision,
		orden,
		activo
	)
	values (
		v_configuracion_id,
		'esquema_tercetos',
		'¿Qué esquema presentan los tercetos?',
		'Los cuartetos ABBA ABBA forman parte de la norma. Selecciona únicamente la disposición observada en los seis versos finales.',
		'rima',
		'secuencia',
		1,
		1,
		'revisada',
		1,
		true
	)
	on conflict (configuracion_id, slug) do update
	set
		nombre = excluded.nombre,
		ayuda_editor = excluded.ayuda_editor,
		dimension = excluded.dimension,
		alcance = excluded.alcance,
		seccion_id = null,
		selecciones_min = excluded.selecciones_min,
		selecciones_max = excluded.selecciones_max,
		estado_revision = excluded.estado_revision,
		orden = excluded.orden,
		activo = excluded.activo
	returning grupo_eleccion_id into v_grupo_id;

	delete from public.elecciones_editor_metrico
	where grupo_eleccion_id = v_grupo_id;

	delete from public.opciones_eleccion_metrica
	where grupo_eleccion_id = v_grupo_id;

	insert into public.opciones_eleccion_metrica (
		grupo_eleccion_id,
		slug,
		nombre,
		descripcion,
		patron_rima_id,
		orden
	)
	select
		v_grupo_id,
		case patron.esquema
			when 'ABBAABBACDCDCD' then 'CDCDCD'
			when 'ABBAABBACDECDE' then 'CDECDE'
			when 'ABBAABBACDEDCE' then 'CDEDCE'
			when 'ABBAABBACDCEDE' then 'CDCEDE'
		end,
		case patron.esquema
			when 'ABBAABBACDCDCD' then 'CDCDCD · rima cruzada'
			when 'ABBAABBACDECDE' then 'CDECDE · rima paralela'
			when 'ABBAABBACDEDCE' then 'CDEDCE · rima conclusiva'
			when 'ABBAABBACDCEDE' then 'CDCEDE · rima nuclear'
		end,
		patron.descripcion,
		patron.patron_rima_id,
		case patron.esquema
			when 'ABBAABBACDCDCD' then 1
			when 'ABBAABBACDECDE' then 2
			when 'ABBAABBACDEDCE' then 3
			when 'ABBAABBACDCEDE' then 4
		end
	from public.patrones_rima patron
	where patron.configuracion_id = v_configuracion_id
		and patron.esquema in (
			'ABBAABBACDCDCD',
			'ABBAABBACDECDE',
			'ABBAABBACDEDCE',
			'ABBAABBACDCEDE'
		);
end;
$$;

update public.catalogo_metrico_estado
set
	modelo_version = 17,
	actualizado_en = now()
where id = true;

commit;

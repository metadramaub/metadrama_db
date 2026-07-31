begin;

-- La copla real reutiliza el repertorio de la quintilla en vez de copiarlo · defecto D8.
--
-- Cada una de sus dos arquitecturas guardaba sus propios ocho esquemas de rima —`ababa`,
-- `abbab`, `abaab`…—, idénticos a los ocho de la quintilla. Dieciséis filas para decir dos
-- veces lo que ya estaba dicho una. Mantener el mismo repertorio en tres sitios obliga a
-- corregirlo en tres, y rompe la comparación: dos secuencias con la misma disposición
-- apuntarían a esquemas distintos según la forma desde la que se registraran.
--
-- El mecanismo ya existe y lo usa la novena: la sección declara con
-- `arquitectura_referenciada_id` qué arquitectura realiza como componente, y entonces sus
-- opciones pueden apuntar a los esquemas de esa arquitectura. `validar_opcion_eleccion_metrica`
-- lo admite exactamente en ese caso.
--
-- Las dos preguntas por la rima vuelven además a su sección. Estaban sin anclar desde que
-- se disolvió la sección `copla_real` que las contenía, y el anclaje es ahora necesario:
-- es lo que autoriza a la opción a señalar un esquema de otra arquitectura.

-- ---------------------------------------------------------------------------
-- 1 · Cada quintilla de la copla real realiza la arquitectura de la quintilla
-- ---------------------------------------------------------------------------

update public.estructuras_secciones seccion
set arquitectura_referenciada_id = (
	select componente.arquitectura_id
	from public.arquitecturas_forma componente
	join public.formas_metricas forma_componente
		on forma_componente.forma_id = componente.forma_id
	where forma_componente.slug = 'quintilla'
		and componente.slug = 'octosilabica_consonante'
)
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
where seccion.arquitectura_id = arquitectura.arquitectura_id
	and forma.slug = 'copla_real'
	and seccion.tipo_seccion in ('primera_quintilla', 'segunda_quintilla');

-- ---------------------------------------------------------------------------
-- 2 · Cada pregunta vuelve a su sección
-- ---------------------------------------------------------------------------

update public.grupos_eleccion_metrica grupo
set seccion_id = seccion.seccion_id
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
join public.estructuras_secciones seccion
	on seccion.arquitectura_id = arquitectura.arquitectura_id
where grupo.arquitectura_id = arquitectura.arquitectura_id
	and forma.slug = 'copla_real'
	and (
		(grupo.slug = 'rima_primera_quintilla' and seccion.tipo_seccion = 'primera_quintilla')
		or (grupo.slug = 'rima_segunda_quintilla' and seccion.tipo_seccion = 'segunda_quintilla')
	);

-- ---------------------------------------------------------------------------
-- 3 · Las opciones señalan el esquema de la quintilla con su misma notación
-- ---------------------------------------------------------------------------

with equivalencia as (
	select
		copiado.esquema_rima_id as copiado_id,
		quintilla.esquema_rima_id as quintilla_id
	from public.esquemas_rima copiado
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = copiado.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	join public.esquemas_rima quintilla
		on quintilla.notacion = copiado.notacion
	join public.arquitecturas_forma componente
		on componente.arquitectura_id = quintilla.arquitectura_id
	join public.formas_metricas forma_componente
		on forma_componente.forma_id = componente.forma_id
	where forma.slug = 'copla_real'
		and forma_componente.slug = 'quintilla'
		and componente.slug = 'octosilabica_consonante'
)
update public.opciones_eleccion_metrica opcion
set esquema_rima_id = equivalencia.quintilla_id
from equivalencia
where opcion.esquema_rima_id = equivalencia.copiado_id;

-- ---------------------------------------------------------------------------
-- 4 · Los dieciséis esquemas copiados se retiran
-- ---------------------------------------------------------------------------

do $$
declare
	v_referidos integer;
begin
	select count(*) into v_referidos
	from public.migracion_termino_destinos destino
	join public.esquemas_rima rima
		on rima.esquema_rima_id = destino.esquema_rima_id
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = rima.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'copla_real';
	if v_referidos > 0 then
		raise exception
			'% trazas de migración apuntan a los esquemas copiados de la copla real', v_referidos;
	end if;
end;
$$;

delete from public.esquemas_rima rima
using public.arquitecturas_forma arquitectura, public.formas_metricas forma
where rima.arquitectura_id = arquitectura.arquitectura_id
	and forma.forma_id = arquitectura.forma_id
	and forma.slug = 'copla_real';

do $$
declare
	v_propios integer;
	v_opciones integer;
begin
	select count(*) into v_propios
	from public.esquemas_rima rima
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = rima.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'copla_real';
	if v_propios > 0 then
		raise exception 'La copla real conserva % esquemas de rima propios', v_propios;
	end if;

	-- Las treinta y dos opciones deben seguir señalando un esquema, ahora el de la quintilla.
	select count(*) into v_opciones
	from public.opciones_eleccion_metrica opcion
	join public.grupos_eleccion_metrica grupo
		on grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = grupo.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	join public.esquemas_rima rima
		on rima.esquema_rima_id = opcion.esquema_rima_id
	join public.arquitecturas_forma destino
		on destino.arquitectura_id = rima.arquitectura_id
	join public.formas_metricas forma_destino
		on forma_destino.forma_id = destino.forma_id
	where forma.slug = 'copla_real'
		and grupo.dimension = 'rima'
		and forma_destino.slug = 'quintilla';
	if v_opciones <> 32 then
		raise exception 'Se esperaban 32 opciones apuntando a la quintilla y hay %', v_opciones;
	end if;
end;
$$;

commit;

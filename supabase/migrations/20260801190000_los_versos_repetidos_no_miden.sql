begin;

-- Los versos repetidos no vuelven a medirse.
--
-- La medida se preguntó en cada sección con versos, y eso incluyó la represa. Pero la represa
-- no tiene versos propios: son los del estribillo, repetidos enteros o en parte. Preguntar su
-- medida es pedir dos veces el mismo dato y admitir que se respondan cosas distintas, que es
-- una contradicción que el catálogo no debería poder representar. Una pregunta cuyo resultado
-- se deriva no pertenece al catálogo.
--
-- El criterio no nombra formas. Una sección cuyos versos los pone otra sección —la que una
-- opción materializa derivando su extensión desde otra— no declara medida propia: mide lo que
-- mida aquella. Vale igual para el villancico con cabeza, para el que empieza por copla y para
-- el zéjel, y valdrá para lo que se catalogue después.
--
-- La represa parcial repite menos versos, no versos de otra medida: la derivación es la misma.

create temporary table secciones_repetidas on commit drop as
select distinct
	seccion.seccion_id,
	seccion.arquitectura_id,
	coalesce(seccion.nombre, seccion.tipo_seccion) as nombre
from public.estructuras_secciones seccion
join public.opciones_eleccion_metrica opcion
	on opcion.materializa_seccion_id = seccion.seccion_id
where opcion.extension_desde_seccion_id is not null;

create temporary table preguntas_redundantes on commit drop as
select grupo.grupo_eleccion_id
from public.grupos_eleccion_metrica grupo
join secciones_repetidas seccion on seccion.seccion_id = grupo.seccion_id
where grupo.dimension = 'metro';

-- Las respuestas de prueba que colgaban de esas preguntas se van con ellas: son datos del
-- laboratorio, no anotaciones de obras.
delete from public.elecciones_editor_metrico
where grupo_eleccion_id in (select grupo_eleccion_id from preguntas_redundantes);

delete from public.opciones_eleccion_metrica
where grupo_eleccion_id in (select grupo_eleccion_id from preguntas_redundantes);

delete from public.grupos_eleccion_metrica
where grupo_eleccion_id in (select grupo_eleccion_id from preguntas_redundantes);

-- ---------------------------------------------------------------------------
-- Comprobaciones
-- ---------------------------------------------------------------------------

do $$
declare
	v_redundantes integer;
	v_villancico integer;
begin
	select count(*) into v_redundantes
	from public.grupos_eleccion_metrica grupo
	join public.estructuras_secciones seccion on seccion.seccion_id = grupo.seccion_id
	join public.opciones_eleccion_metrica opcion
		on opcion.materializa_seccion_id = seccion.seccion_id
	where grupo.dimension = 'metro' and opcion.extension_desde_seccion_id is not null;
	if v_redundantes <> 0 then
		raise exception 'Quedan % preguntas de medida sobre versos repetidos', v_redundantes;
	end if;

	-- La sección que sí pone los versos conserva la suya.
	select count(*) into v_villancico
	from public.grupos_eleccion_metrica grupo
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = grupo.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'villancico' and grupo.dimension = 'metro';
	if v_villancico = 0 then
		raise exception 'El villancico se ha quedado sin ninguna pregunta de medida';
	end if;
end;
$$;

commit;

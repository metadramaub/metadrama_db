begin;

-- Los dos defectos del informe de conformidad que no dependen de una decisión editorial.
--
-- El resto de los cuarenta y cuatro sí la dependen, y en su mayoría la pregunta ya está
-- escrita en revisiones-formas/cuestiones-para-el-ip.md. No se tocan aquí.

-- ---------------------------------------------------------------------------
-- D6 · Cuatro slugs con un UUID incrustado
--
-- Los slugs son identificadores estables y legibles, y serán clave de comparación entre
-- corpus. Los cuatro pertenecen al mismo grupo y sus prefijos ya los distinguen, así que
-- el UUID no aportaba unicidad: solo ruido de importación.
-- ---------------------------------------------------------------------------

update public.opciones_eleccion_metrica
set slug = regexp_replace(slug, '_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', '')
where slug ~ '_[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';

do $$
declare
	v_restantes integer;
begin
	select count(*) into v_restantes
	from public.opciones_eleccion_metrica
	where slug ~ '[0-9a-f]{8}-[0-9a-f]{4}-';
	if v_restantes > 0 then
		raise exception 'Quedan % slugs con UUID incrustado', v_restantes;
	end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- D12 · El esquema de los tercetos del soneto se pregunta por unidad
--
-- La ontología lo tiene decidido en su arquetipo de composición cerrada: «ELECCIÓN por
-- unidad · ¿qué esquema de tercetos?», y añade que un pasaje de tres sonetos seguidos se
-- deriva del rango y «cada uno conserva su propia elección de tercetos». Con la unidad
-- envolvente esa lectura pasa a ser además la única posible: mientras la pregunta tuviera
-- alcance de secuencia, todos los sonetos de un pasaje habrían compartido por fuerza el
-- mismo esquema.
--
-- Los otros cinco grupos que el informe señala con el mismo defecto no se tocan: en cada
-- uno la pregunta de nivel está abierta con el IP —si la medida de la sextilla isométrica
-- es arquitectura como lo es en la redondilla, si los tres esquemas de la copla de arte
-- mayor pueden alternar dentro de una tirada, si las medidas del villancico y del zéjel
-- forman repertorio cerrado—.
-- ---------------------------------------------------------------------------

update public.grupos_eleccion_metrica grupo
set alcance = 'unidad'
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma
	on forma.forma_id = arquitectura.forma_id
where arquitectura.arquitectura_id = grupo.arquitectura_id
	and forma.slug = 'soneto'
	and grupo.slug = 'esquema_tercetos'
	and grupo.alcance = 'secuencia';

do $$
begin
	if not exists (
		select 1
		from public.grupos_eleccion_metrica grupo
		join public.arquitecturas_forma arquitectura
			on arquitectura.arquitectura_id = grupo.arquitectura_id
		join public.formas_metricas forma
			on forma.forma_id = arquitectura.forma_id
		where forma.slug = 'soneto'
			and grupo.slug = 'esquema_tercetos'
			and grupo.alcance = 'unidad'
	) then
		raise exception 'El esquema de tercetos del soneto no quedó con alcance de unidad';
	end if;
end;
$$;

commit;

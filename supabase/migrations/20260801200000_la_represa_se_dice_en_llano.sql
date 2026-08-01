begin;

-- La represa se dice en llano, y sigue llamándose represa por dentro.
--
-- «Represa» es el término de la bibliografía, pero no es de uso común, y el editor que no lo
-- conoce no puede deducirlo del formulario: lo que ve es una sección con un nombre técnico
-- donde lo que ocurre es que el estribillo vuelve a aparecer. El nombre visible pasa a decir
-- eso; el slug, que es la identidad analítica de la sección y de cada respuesta, no cambia.
-- Así las consultas, los informes y la bibliografía siguen hablando de represa sin obligar al
-- editor a aprenderse la palabra para anotar.
--
-- «Vuelta» no era candidato: en el villancico ya nombra la sección que enlaza la mudanza con
-- el estribillo, y dos cosas distintas no pueden compartir nombre en el mismo formulario.

update public.estructuras_secciones
set
	nombre = 'Repetición del estribillo',
	nota = coalesce(nota || ' ', '') || 'En la bibliografía se denomina represa.'
where tipo_seccion = 'represa';

update public.grupos_eleccion_metrica
set ayuda_editor = 'Elige lo que ocurre después de esta copla. La repetición del estribillo es lo que la bibliografía llama represa.'
where slug = 'represa_estribillo';

update public.opciones_eleccion_metrica opcion
set
	nombre = case grupo.nombre
		when '¿Reaparece materialmente el estribillo?' then 'Sí, se repite entero'
		else 'Se repite entero'
	end,
	descripcion = coalesce(opcion.descripcion, 'Represa total.')
from public.grupos_eleccion_metrica grupo
where grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	and grupo.slug = 'represa_estribillo'
	and opcion.slug = 'total';

update public.opciones_eleccion_metrica opcion
set
	nombre = 'Se repite solo en parte',
	descripcion = coalesce(opcion.descripcion, 'Represa parcial.')
from public.grupos_eleccion_metrica grupo
where grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	and grupo.slug = 'represa_estribillo'
	and opcion.slug = 'parcial';

update public.opciones_eleccion_metrica opcion
set
	nombre = 'Se sobreentiende, no está escrito',
	descripcion = coalesce(opcion.descripcion, 'Represa implícita.')
from public.grupos_eleccion_metrica grupo
where grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	and grupo.slug = 'represa_estribillo'
	and opcion.slug = 'implicita';

update public.opciones_eleccion_metrica opcion
set nombre = 'No, no vuelve a aparecer'
from public.grupos_eleccion_metrica grupo
where grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	and grupo.slug = 'represa_estribillo'
	and opcion.slug = 'sin_represa_material';

-- El contenedor que agrupa la copla y la repetición también lo decía en técnico.
update public.estructuras_secciones
set nombre = 'Copla y posible repetición del estribillo'
where tipo_seccion in ('ciclo_copla', 'primer_ciclo')
	and nombre in ('Copla y posible represa', 'Copla y posible represa del estribillo');

-- ---------------------------------------------------------------------------
-- Comprobaciones
-- ---------------------------------------------------------------------------

do $$
declare
	v_visible integer;
	v_slugs integer;
begin
	select count(*) into v_visible
	from public.estructuras_secciones
	where tipo_seccion = 'represa' and nombre <> 'Repetición del estribillo';
	if v_visible <> 0 then
		raise exception 'Quedan % secciones de represa con el nombre técnico a la vista', v_visible;
	end if;

	-- La identidad analítica no se ha tocado.
	select count(*) into v_slugs
	from public.estructuras_secciones
	where tipo_seccion = 'represa';
	if v_slugs = 0 then
		raise exception 'Ha desaparecido el tipo de sección represa';
	end if;

	select count(*) into v_visible
	from public.opciones_eleccion_metrica opcion
	join public.grupos_eleccion_metrica grupo on grupo.grupo_eleccion_id = opcion.grupo_eleccion_id
	where grupo.slug = 'represa_estribillo' and opcion.nombre ilike '%represa%';
	if v_visible <> 0 then
		raise exception 'Quedan % respuestas que dicen «represa» al editor', v_visible;
	end if;
end;
$$;

commit;

-- Una respuesta no se borra porque se edite el catálogo, y una repetición tiene nombre.
--
-- Dos correcciones que salen de revisar lo que quedó ayer.
--
-- 1 · EL BORRADO EN CASCADA ERA UN ERROR. Al soltar la respuesta de la opción se le dieron
-- claves foráneas a las entidades del catálogo copiando el patrón de `opciones_eleccion_metrica`,
-- donde el borrado en cascada tiene sentido: una opción **es** catálogo, y si desaparece el
-- esquema al que apunta debe desaparecer con él.
--
-- Pero una respuesta **no es catálogo: es dato sobre una obra**. Que borrar un esquema de rima
-- se llevara por delante las anotaciones que lo usaban es justo lo contrario de lo que el
-- proyecto quiere, y contradice además la razón de haber hecho el cambio —que el catálogo pueda
-- moverse sin tocar lo guardado—. No llegó a pasar, pero pudo: esta misma sesión se retiró una
-- variedad, y una respuesta que la hubiera usado habría desaparecido sin aviso.
--
-- Pasan a `restrict`, como ya estaban el metro y el valor de rasgo. A partir de aquí el
-- catálogo se niega a borrar algo que una anotación esté usando, que es la protección correcta:
-- obliga a mirar la anotación antes, en vez de perderla.
--
-- 2 · LAS REPETICIONES NO TENÍAN NOMBRE. Es el noveno hueco, y aparece al preguntarse cómo
-- derivar las etiquetas de las preguntas. La regla que sirve para todo lo demás es «la etiqueta
-- es el nombre de la entidad, compuesto con la posición cuando la pregunta es posicional», y
-- funciona en las cinco dimensiones **salvo en la repetición**, cuyas opciones se rotulan «Se
-- repite entero» o «Se sobreentiende, no está escrito» sin que la repetición tenga dónde decir
-- cómo se llama.
--
-- No es prosa de formulario: es el nombre de una realización de la repetición, y su sitio es la
-- repetición. Con él, la etiqueta deja de escribirse a mano también aquí.

begin;

-- ---------------------------------------------------------------------------
-- 1 · Borrar catálogo no borra anotación
-- ---------------------------------------------------------------------------

alter table public.elecciones_editor_metrico
	drop constraint elecciones_editor_metrico_esquema_metrico_id_fkey,
	add constraint elecciones_editor_metrico_esquema_metrico_id_fkey
		foreign key (esquema_metrico_id) references public.esquemas_metricos (esquema_metrico_id)
		on update cascade on delete restrict;

alter table public.elecciones_editor_metrico
	drop constraint elecciones_editor_metrico_esquema_rima_id_fkey,
	add constraint elecciones_editor_metrico_esquema_rima_id_fkey
		foreign key (esquema_rima_id) references public.esquemas_rima (esquema_rima_id)
		on update cascade on delete restrict;

alter table public.elecciones_editor_metrico
	drop constraint elecciones_editor_metrico_seccion_id_fkey,
	add constraint elecciones_editor_metrico_seccion_id_fkey
		foreign key (seccion_id) references public.estructuras_secciones (seccion_id)
		on update cascade on delete restrict;

alter table public.elecciones_editor_metrico
	drop constraint elecciones_editor_metrico_repeticion_id_fkey,
	add constraint elecciones_editor_metrico_repeticion_id_fkey
		foreign key (repeticion_id) references public.repeticiones_metricas (repeticion_id)
		on update cascade on delete restrict;

alter table public.elecciones_editor_metrico
	drop constraint elecciones_editor_metrico_variedad_id_fkey,
	add constraint elecciones_editor_metrico_variedad_id_fkey
		foreign key (variedad_id) references public.variedades_arquitectura (variedad_id)
		on update cascade on delete restrict;

do $$
declare
	v_n integer;
begin
	-- Ninguna clave hacia el catálogo puede borrar en cascada. Las que apuntan a la prueba
	-- —la secuencia y la realización— sí deben hacerlo: son el contenedor de la respuesta.
	select count(*) into v_n
	from pg_constraint c
	where c.conrelid = 'public.elecciones_editor_metrico'::regclass
		and c.contype = 'f'
		and c.confdeltype = 'c'
		and c.confrelid <> 'public.secuencias_editor_metrico'::regclass
		and c.confrelid <> 'public.realizaciones_editor_metrico'::regclass;
	if v_n <> 0 then
		raise exception 'Quedan % claves del catálogo que borrarían la anotación en cascada', v_n;
	end if;
end;
$$;

-- ---------------------------------------------------------------------------
-- 2 · La repetición dice cómo se llama
-- ---------------------------------------------------------------------------

alter table public.repeticiones_metricas
	add column if not exists nombre text;

comment on column public.repeticiones_metricas.nombre is
	'Cómo se llama esta realización de la repetición, en la lengua con que se le presenta al editor: «Se repite entero», «Se sobreentiende, no está escrito». Es el nombre de la entidad, no el rótulo de una pregunta, y de él se deriva la etiqueta.';

update public.repeticiones_metricas rp
set nombre = o.nombre, updated_at = now()
from (
	select distinct on (repeticion_id) repeticion_id, nombre
	from public.opciones_eleccion_metrica
	where repeticion_id is not null
	order by repeticion_id, orden nulls last
) o
where o.repeticion_id = rp.repeticion_id
	and rp.nombre is null;

-- Las que ninguna pregunta ofrece toman un nombre a partir de lo que ya declaran.
update public.repeticiones_metricas
set nombre = initcap(replace(slug, '_', ' ')), updated_at = now()
where nombre is null;

alter table public.repeticiones_metricas alter column nombre set not null;

do $$
declare
	v_n integer;
begin
	-- Toda repetición que una pregunta ofrezca debe rotularse igual que su opción: si no, la
	-- etiqueta derivada cambiaría lo que el editor ve.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.repeticiones_metricas rp on rp.repeticion_id = o.repeticion_id
	where o.nombre is distinct from rp.nombre;
	if v_n <> 0 then
		raise exception 'En % opciones de repetición el nombre no coincide con el de la repetición', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

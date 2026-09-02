-- El estribillo del villancico vuelve siempre
--
-- Las dos arquitecturas de la forma decían lo contrario la una de la otra sobre lo mismo:
--
--   | arquitectura | sección | repeticiones |
--   |---|---|---|
--   | Estribillo tras la primera copla | «Estribillo» | **1-1** |
--   | Estribillo inicial | «Repetición del estribillo» | 0-1 |
--
-- Y la que está bien es la primera. **El estribillo no puede faltar: es lo que define un
-- villancico.** Cuando la fuente antigua no lo copia —un «etc.», una acotación «y cantan»— es por
-- ahorro de espacio, no porque no se cante, y las ediciones modernas lo restituyen. Lo que varía no
-- es si vuelve, sino **cuánto vuelve**: de un estribillo de cuatro versos pueden repetirse solo dos.
--
-- Esa es justamente la pregunta que la arquitectura ya hace —«se repite entero» o «se repite solo en
-- parte»—, obligatoria y con dos respuestas afirmativas. Con la sección en `0-1` esa pregunta era
-- contradictoria: obligaba a decir que sí sobre algo que el catálogo declaraba prescindible, y un
-- ciclo sin repetición no se podía guardar ni declarar. Con la sección en `1-1` la pregunta dice lo
-- que tiene que decir.
--
-- **No se toca el zéjel**, que declara la suya igual de opcional y cuyo contenedor se llama «Copla y
-- *posible* repetición del estribillo»: allí fue deliberado y su verso de vuelta funciona de otro
-- modo. Queda como cuestión aparte.
--
-- Consecuencia de la que conviene dejar constancia: el ciclo toma su extensión de sus partes, así
-- que su mínimo pasa de cuatro versos —la mudanza— a cinco, la mudanza más un verso de estribillo.

begin;

do $$
declare
	v_seccion uuid;
	v_min integer;
	v_max integer;
begin
	select s.seccion_id, s.repeticiones_min, s.repeticiones_max
	into v_seccion, v_min, v_max
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Villancico'
		and a.nombre = 'Estribillo inicial'
		and s.nombre = 'Repetición del estribillo';

	if v_seccion is null then
		raise exception 'No está la repetición del estribillo del villancico: revisa el catálogo antes de seguir.';
	end if;

	if v_min = 1 and v_max = 1 then
		raise notice 'La repetición del estribillo ya era obligatoria.';
		return;
	end if;

	if v_min <> 0 or v_max <> 1 then
		raise exception 'La repetición del estribillo declara % a % apariciones, que no es lo que se acordó cambiar.', v_min, v_max;
	end if;

	update public.estructuras_secciones
	set repeticiones_min = 1, repeticiones_max = 1
	where seccion_id = v_seccion;
end $$;

do $$
declare
	v_fila record;
	v_leidas integer := 0;
	v_opciones integer;
	v_zejel record;
begin
	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- Las dos arquitecturas del villancico dicen ya lo mismo del estribillo del ciclo.
	for v_fila in
		select a.nombre as arquitectura, s.nombre, s.repeticiones_min, s.repeticiones_max
		from public.estructuras_secciones s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.nombre = 'Villancico' and s.nombre in ('Estribillo', 'Repetición del estribillo')
	loop
		v_leidas := v_leidas + 1;
		if v_fila.repeticiones_min <> 1 or v_fila.repeticiones_max <> 1 then
			raise exception 'En «%» el estribillo del ciclo declara % a % apariciones.',
				v_fila.arquitectura, v_fila.repeticiones_min, v_fila.repeticiones_max;
		end if;
	end loop;

	if v_leidas <> 2 then
		raise exception 'Se han comprobado % secciones de estribillo del villancico, y son 2.', v_leidas;
	end if;

	-- Las otras partes del ciclo siguen siendo opcionales: el enlace y la vuelta sí pueden faltar.
	if exists (
		select 1 from public.estructuras_secciones s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.nombre = 'Villancico' and s.nombre in ('Enlace', 'Vuelta')
			and (s.repeticiones_min <> 0 or s.repeticiones_max <> 1)
	) then
		raise exception 'El enlace o la vuelta del villancico han dejado de ser opcionales.';
	end if;

	-- Y la pregunta que dice cuánto vuelve sigue en pie con sus dos respuestas, que es lo que
	-- ahora tiene sentido preguntar. Se lee de la vista, que ejecuta la función de opciones.
	select count(*) into v_opciones
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Villancico' and a.nombre = 'Estribillo inicial' and g.dimension = 'repeticion';

	if v_opciones <> 2 then
		raise exception 'La pregunta de la repetición ofrece % respuestas, y debían ser 2.', v_opciones;
	end if;

	-- El zéjel no se ha tocado de refilón.
	select s.repeticiones_min as minimo, s.repeticiones_max as maximo into v_zejel
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Zéjel' and s.nombre = 'Repetición del estribillo';

	if v_zejel.minimo <> 0 or v_zejel.maximo <> 1 then
		raise exception 'La repetición del estribillo del zéjel ha cambiado a % - %, y no debía tocarse.',
			v_zejel.minimo, v_zejel.maximo;
	end if;
end $$;

commit;

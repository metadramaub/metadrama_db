-- La repetición declara cómo se realiza, en vez de dejarlo en la opción que la ofrece.
--
-- Era el último obstáculo para poder generar las preguntas. Al soltar la respuesta de la opción
-- se comprobó que la correspondencia era exacta en las cinco dimensiones, **salvo por un
-- detalle**: las opciones de repetición no solo apuntaban a una repetición, sino que llevaban
-- además su comportamiento —si materializa una sección y de dónde toma su extensión—. Eso no
-- se podía derivar de `repeticiones_metricas`, que solo tenía `regla` en texto libre.
--
-- La correspondencia es uno a uno: cada opción apunta a una repetición distinta y cada
-- repetición tiene un comportamiento fijo. El villancico tiene tres —la represa entera, la
-- parcial y la que se sobreentiende— y el zéjel dos. Así que el comportamiento **es de la
-- repetición**, no de la pregunta que la ofrece, y ahí se muda.
--
-- Qué gana el catálogo. Que «represa total» signifique lo mismo mire quien lo mire, y no solo
-- dentro del formulario. Hoy, para saber que una represa entera toma su extensión de la cabeza,
-- había que ir a la opción de una pregunta; a partir de ahora lo dice la repetición.
--
-- Las columnas de la opción **se conservan por ahora**, porque son lo que lee el editor. Cuando
-- las opciones se generen, tomarán el comportamiento de la repetición, de modo que habrá una
-- sola fuente y el editor seguirá funcionando igual. Es el paso siguiente.
--
-- Esto avanza además la revisión transversal de las reglas de repetición, que pedía decidir si
-- ese comportamiento estructurado pertenece a la repetición. Pertenece.

begin;

alter table public.repeticiones_metricas
	add column if not exists materializa_seccion_id uuid
		references public.estructuras_secciones (seccion_id)
		on update cascade on delete cascade,
	add column if not exists extension_desde_seccion_id uuid
		references public.estructuras_secciones (seccion_id)
		on update cascade on delete cascade;

comment on column public.repeticiones_metricas.materializa_seccion_id is
	'Sección que la repetición hace aparecer cuando se realiza. Nulo cuando la repetición no escribe versos: la represa que se sobreentiende no materializa nada.';
comment on column public.repeticiones_metricas.extension_desde_seccion_id is
	'Sección de la que la repetición toma su extensión, cuando reproduce otra entera. La represa total del villancico mide lo que mide su cabeza. Nulo cuando la extensión no se deriva de otra sección, como en la represa parcial.';

do $$
declare
	v_n integer;
	v_conflictos integer;
begin
	-- La mudanza solo es correcta si cada repetición tiene un comportamiento único: si dos
	-- opciones de la misma repetición dijeran cosas distintas, el dato no cabría aquí.
	select count(*) into v_conflictos
	from (
		select o.repeticion_id
		from public.opciones_eleccion_metrica o
		where o.repeticion_id is not null
		group by o.repeticion_id
		having count(distinct coalesce(o.materializa_seccion_id, '00000000-0000-0000-0000-000000000000'::uuid)) > 1
			or count(distinct coalesce(o.extension_desde_seccion_id, '00000000-0000-0000-0000-000000000000'::uuid)) > 1
	) s;
	if v_conflictos <> 0 then
		raise exception '% repeticiones reciben comportamientos distintos según la opción', v_conflictos;
	end if;

	update public.repeticiones_metricas rp
	set materializa_seccion_id = o.materializa_seccion_id,
		extension_desde_seccion_id = o.extension_desde_seccion_id,
		updated_at = now()
	from (
		select distinct on (repeticion_id)
			repeticion_id, materializa_seccion_id, extension_desde_seccion_id
		from public.opciones_eleccion_metrica
		where repeticion_id is not null
		order by repeticion_id, orden nulls last
	) o
	where o.repeticion_id = rp.repeticion_id;

	-- Lo mudado tiene que coincidir con lo que la opción sigue diciendo.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.repeticiones_metricas rp on rp.repeticion_id = o.repeticion_id
	where o.materializa_seccion_id is distinct from rp.materializa_seccion_id
		or o.extension_desde_seccion_id is distinct from rp.extension_desde_seccion_id;
	if v_n <> 0 then
		raise exception 'En % opciones el comportamiento mudado no coincide con el declarado', v_n;
	end if;

	-- Y toda repetición que una pregunta ofrezca debe haber recibido el suyo.
	select count(*) into v_n
	from public.repeticiones_metricas rp
	where exists (
		select 1 from public.opciones_eleccion_metrica o where o.repeticion_id = rp.repeticion_id
	)
	and rp.materializa_seccion_id is null
	and rp.extension_desde_seccion_id is null
	and exists (
		select 1 from public.opciones_eleccion_metrica o
		where o.repeticion_id = rp.repeticion_id
			and (o.materializa_seccion_id is not null or o.extension_desde_seccion_id is not null)
	);
	if v_n <> 0 then
		raise exception 'Quedan % repeticiones sin su comportamiento', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

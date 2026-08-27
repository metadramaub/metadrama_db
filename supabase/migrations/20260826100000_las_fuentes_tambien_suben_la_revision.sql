-- Las fuentes también suben la revisión del catálogo
--
-- `catalogo_metrico_estado.revision` sube por disparador cada vez que cambia algo del catálogo, y
-- va a pasar a ser **la llave de una caché en el servidor**: el gestor del catálogo lee la revisión
-- y, si no ha cambiado, devuelve lo que ya tiene en memoria en vez de reconstruirlo con treinta
-- consultas. Una llave así solo vale si la sube *todo* lo que el catálogo lee.
--
-- Contado contra la base: de las **veinticinco tablas** que carga el gestor, veintitrés tenían el
-- disparador y **dos no** —`fuentes_metricas` y `afirmaciones_fuentes_metricas`—. Son las seis
-- monografías y lo que cada una respalda, así que hoy editar una fuente o mover una afirmación no
-- cambiaba la revisión, y con la caché puesta ese cambio no se habría visto hasta el reinicio
-- siguiente.
--
-- Se cierra el hueco antes de poner la caché, no después.

begin;

do $$
declare
	v_antes integer;
	v_despues integer;
	v_fuente uuid;
	v_faltan text;
begin
	if to_regprocedure('public.marcar_catalogo_metrico_actualizado()') is null then
		raise exception 'No está la función que sube la revisión.';
	end if;

	create trigger trigger_fuentes_metricas_catalogo_revision
	after insert or delete or update on public.fuentes_metricas
	for each statement execute function public.marcar_catalogo_metrico_actualizado();

	create trigger trigger_afirmaciones_fuentes_metricas_catalogo_revision
	after insert or delete or update on public.afirmaciones_fuentes_metricas
	for each statement execute function public.marcar_catalogo_metrico_actualizado();

	-- ------------------------------------------------------------------ Comprobaciones
	--
	-- **Se ejecuta lo que se toca.** Un disparador declarado no es un disparador que funcione, así
	-- que se toca una fuente de verdad y se mira si la revisión sube. El cambio se deshace.
	select revision into v_antes from public.catalogo_metrico_estado where id;
	if v_antes is null then
		raise exception 'No hay fila de estado del catálogo donde comprobarlo.';
	end if;

	select fuente_id into v_fuente from public.fuentes_metricas limit 1;
	if v_fuente is null then
		raise exception 'No hay ninguna fuente donde comprobarlo.';
	end if;

	update public.fuentes_metricas
	set updated_at = updated_at
	where fuente_id = v_fuente;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'Tocar una fuente no ha subido la revisión: % y seguía en %.',
			v_despues, v_antes;
	end if;

	-- Y ahora ninguna de las veinticinco se queda fuera.
	select string_agg(t, ', ') into v_faltan
	from (
		select unnest(array[
			'formas_metricas', 'arquitecturas_forma', 'estructuras_secciones', 'esquemas_rima',
			'esquema_rima_posiciones', 'esquema_rima_enlaces', 'esquema_rima_restricciones',
			'esquemas_metricos', 'esquema_metrico_posiciones', 'esquema_metrico_opciones',
			'metros', 'metro_segmentos', 'variedades_arquitectura', 'repeticiones_metricas',
			'repeticion_posiciones', 'rasgos_metricos', 'rasgo_valores', 'arquitectura_rasgos',
			'grupos_eleccion_metrica', 'denominaciones_metricas', 'forma_relaciones',
			'tradiciones_metricas', 'formas_tradiciones', 'fuentes_metricas',
			'afirmaciones_fuentes_metricas'
		]) t
		except
		select c.relname
		from pg_trigger tg
		join pg_class c on c.oid = tg.tgrelid
		join pg_proc p on p.oid = tg.tgfoid
		where p.proname = 'marcar_catalogo_metrico_actualizado' and not tg.tgisinternal
	) f;
	if v_faltan is not null then
		raise exception 'Estas tablas del catálogo no suben la revisión: %', v_faltan;
	end if;
end $$;

commit;

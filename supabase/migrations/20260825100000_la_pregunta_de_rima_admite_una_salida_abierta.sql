-- La pregunta de rima admite una salida abierta
--
-- Paso 3 de B1. Abre el tercer valor de `grupos_eleccion_metrica.tipo_control` y no toca ningún
-- grupo: el reparto va después, forma por forma.
--
-- **Por qué un tercer valor y no una columna aparte.** Se consideró un booleano
-- `admite_esquema_libre` al lado de `tipo_control`, y pierde por tres razones del propio sistema.
-- `tipo_control` ya es el único interruptor por el que ramifica `MetricChoiceField.svelte` y por el
-- que rotula `grupos_eleccion_metrica_resueltos`, y un booleano convertiría ese rótulo en un 2×2.
-- Los tres valores quedan uno a uno con los tres grados del criterio —§ 3.3, regla 2—, de modo que
-- el auditor lee una estrategia por arquitectura en una sola columna. Y un booleano solo tendría
-- sentido con `dimension = 'rima'`, luego necesitaría su propia guarda y sería nulo en sesenta de
-- los setenta y dos grupos.
--
-- El argumento a favor del booleano era la ortogonalidad —cómo se responde frente a si hay salida—,
-- pero `esquema_rima` **ya mezcla hoy las dos cosas**: significa a la vez «sin lista» y «con
-- salida». El tercer valor regulariza en vez de complicar.
--
-- Qué significa cada uno, y es el reparto del criterio:
--
--   opciones             la norma acota un repertorio y el catálogo lo tiene entero
--   opciones_y_esquema   lo acota, y además se puede declarar el que se observe
--   esquema_rima         no acota nada más que el régimen: solo se escribe
--
-- **La validación no puede copiarse tal cual.** `esquema_rima` exige exactamente una respuesta, y
-- el híbrido no: la copla manriqueña y la décima-lira preguntan su disposición con `0-1`, porque el
-- esquema catalogado se marca solo si es el que se ha visto. Lo que sí comparten es que **la
-- respuesta es una sola cuando la hay** —una unidad rima de una manera— y que la dimensión es la de
-- rima. Eso es lo que pasa a exigir el disparador.
--
-- Las guardas prueban las tres puertas ejecutándolas: que el valor nuevo entra, que una dimensión
-- ajena se rechaza y que dos respuestas se rechazan. Un `check` no está probado hasta que algo
-- intenta atravesarlo.

begin;

do $$
declare
	v_grupo uuid;
	v_original text;
	v_n integer;
	v_mensaje text;
begin
	-- ------------------------------------------------------------------- El valor nuevo
	select count(*) into v_n
	from pg_constraint
	where conrelid = 'public.grupos_eleccion_metrica'::regclass
		and conname = 'grupos_eleccion_metrica_tipo_control_check';
	if v_n <> 1 then
		raise exception 'No está la guarda de tipo_control que se esperaba.';
	end if;

	-- Nadie usa todavía el valor nuevo, que es lo que hace segura la sustitución de la guarda.
	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where tipo_control not in ('opciones', 'esquema_rima');
	if v_n <> 0 then
		raise exception '% grupos declaran ya un tipo_control fuera de los dos conocidos.', v_n;
	end if;

	alter table public.grupos_eleccion_metrica
		drop constraint grupos_eleccion_metrica_tipo_control_check;
	alter table public.grupos_eleccion_metrica
		add constraint grupos_eleccion_metrica_tipo_control_check
		check (tipo_control = any (array['opciones', 'esquema_rima', 'opciones_y_esquema']));

	-- ------------------------------------------------------------------- La validación
	create or replace function public.validar_grupo_eleccion_metrica()
	returns trigger
	language plpgsql
	set search_path to 'public'
	as $validar$
	declare
		v_configuracion_seccion uuid;
	begin
		if new.seccion_id is not null then
			select arquitectura_id
			into v_configuracion_seccion
			from public.estructuras_secciones
			where seccion_id = new.seccion_id;

			if v_configuracion_seccion is distinct from new.arquitectura_id then
				raise exception 'La sección de alcance no pertenece a la arquitectura del grupo';
			end if;
		end if;

		-- Los dos controles que ofrecen escribir un esquema hablan siempre de rima, y una unidad
		-- rima de una sola manera. Lo que los separa es el mínimo: el abierto exige respuesta y el
		-- híbrido admite dejarla en blanco, porque el esquema catalogado se marca solo si es el que
		-- se ha visto.
		if new.tipo_control in ('esquema_rima', 'opciones_y_esquema') then
			if new.dimension <> 'rima' then
				raise exception 'Un control de esquema debe pertenecer a la dimensión de rima';
			end if;
			if new.selecciones_max <> 1 then
				raise exception 'Un control de esquema admite una sola respuesta';
			end if;
		end if;

		if new.tipo_control = 'esquema_rima' and new.selecciones_min <> 1 then
			raise exception 'Un control de esquema abierto necesita exactamente una respuesta';
		end if;

		return new;
	end;
	$validar$;

	-- ------------------------------------------------------------------ Comprobaciones
	-- Se prueban sobre un grupo real y se deshace lo probado. Sin esto, la guarda y el disparador
	-- quedarían escritos y sin atravesar.
	select grupo_eleccion_id, tipo_control into v_grupo, v_original
	from public.grupos_eleccion_metrica
	where dimension = 'rima' and tipo_control = 'opciones' and activo
	order by slug
	limit 1;
	if v_grupo is null then
		raise exception 'No hay ningún grupo de rima con lista sobre el que probar.';
	end if;

	-- 1. El valor nuevo entra.
	update public.grupos_eleccion_metrica
	set tipo_control = 'opciones_y_esquema'
	where grupo_eleccion_id = v_grupo;
	if not exists (
		select 1 from public.grupos_eleccion_metrica
		where grupo_eleccion_id = v_grupo and tipo_control = 'opciones_y_esquema'
	) then
		raise exception 'El tipo de control nuevo no se ha guardado.';
	end if;

	-- 2. Dos respuestas se rechazan.
	begin
		update public.grupos_eleccion_metrica
		set selecciones_max = 2
		where grupo_eleccion_id = v_grupo;
		raise exception 'Se ha admitido un control de esquema con dos respuestas.';
	exception when others then
		get stacked diagnostics v_mensaje = message_text;
		if v_mensaje <> 'Un control de esquema admite una sola respuesta' then
			raise;
		end if;
	end;

	-- 3. Una dimensión ajena se rechaza.
	begin
		update public.grupos_eleccion_metrica
		set dimension = 'metro'
		where grupo_eleccion_id = v_grupo;
		raise exception 'Se ha admitido un control de esquema fuera de la dimensión de rima.';
	exception when others then
		get stacked diagnostics v_mensaje = message_text;
		if v_mensaje <> 'Un control de esquema debe pertenecer a la dimensión de rima' then
			raise;
		end if;
	end;

	-- 4. Un valor inventado sigue sin entrar.
	begin
		update public.grupos_eleccion_metrica
		set tipo_control = 'lo_que_sea'
		where grupo_eleccion_id = v_grupo;
		raise exception 'La guarda de tipo_control admite cualquier cosa.';
	exception when check_violation then
		null;
	end;

	-- Y se deja como estaba: el reparto no es de esta migración.
	update public.grupos_eleccion_metrica
	set tipo_control = v_original
	where grupo_eleccion_id = v_grupo;

	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where tipo_control not in ('opciones', 'esquema_rima');
	if v_n <> 0 then
		raise exception 'Han quedado % grupos con el tipo de control nuevo, y no debía quedar ninguno.', v_n;
	end if;
end $$;

commit;

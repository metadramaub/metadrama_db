-- Una pregunta puede responderse por realización.
--
-- `alcance` decía de qué se responde una pregunta, con dos valores: `secuencia`, una vez para todo
-- el pasaje, y `unidad`, una vez por unidad. Faltaba el tercero.
--
-- EL CASO QUE LO DESTAPA es la represa del villancico. Su pregunta —«¿vuelve el estribillo?
-- entero, en parte, se sobreentiende»— está atada al **ciclo de copla**, que se repite tantas
-- veces como coplas tenga la composición y contiene una reaparición del estribillo cada vez.
-- Con `alcance = 'unidad'` solo cabe una respuesta para todo el villancico, y **Navarro Tomás
-- documenta expresamente repeticiones «parciales o totales» dentro de la misma composición**. Un
-- villancico cuyo estribillo vuelve entero tras la primera copla, en parte tras la segunda y no
-- vuelve tras la tercera no se podía registrar.
--
-- No todas las preguntas atadas a una sección repetida son así, y por eso el valor nuevo no se
-- aplica en bloque: «la medida de la estancia» de la canción petrarquista está atada a una sección
-- que se repite tres o más veces y **se responde una sola vez**, porque la medida es la misma en
-- todas. La diferencia no es estructural sino de la norma, así que se declara.
--
-- NO HACE FALTA COLUMNA NUEVA EN NINGUNA PARTE. `elecciones_editor_metrico.realizacion_prueba_id`
-- ya permite colgar una respuesta de una realización concreta, y `realizaciones_editor_metrico`
-- guarda cada realización con su sección y sus versos. Lo que faltaba era declararlo.
--
-- El editor V2 todavía no pregunta por realización; hasta que lo haga trata este alcance como
-- `unidad`, de modo que no desaparece ninguna pregunta de la pantalla. Queda anotado.

begin;

alter table public.grupos_eleccion_metrica
	drop constraint if exists grupos_eleccion_metrica_alcance_check;

alter table public.grupos_eleccion_metrica
	add constraint grupos_eleccion_metrica_alcance_check
	check (alcance in ('secuencia', 'unidad', 'realizacion'));

-- Responder por realización exige saber de qué sección, igual que responder por secuencia exige
-- no tener ninguna.
alter table public.grupos_eleccion_metrica
	drop constraint if exists grupos_eleccion_metrica_check1;

alter table public.grupos_eleccion_metrica
	add constraint grupos_eleccion_metrica_check1
	check (
		(alcance = 'secuencia' and seccion_id is null)
		or alcance = 'unidad'
		or (alcance = 'realizacion' and seccion_id is not null)
	);

-- Las tres preguntas de repetición del catálogo son las de la represa, y las tres cuelgan del
-- ciclo que se repite. Se declaran una a una y no por una regla, porque la regla las confundiría
-- con la medida de la estancia.
update public.grupos_eleccion_metrica g
set alcance = 'realizacion',
	updated_at = now()
where g.dimension = 'repeticion';

do $$
declare
	v_n integer;
	v_mal text;
	v_json jsonb;
	v_grupo uuid;
begin
	-- Las tres preguntas de represa —dos del villancico y una del zéjel— y ninguna más.
	select count(*), string_agg(f.slug || '·' || a.slug, ', ' order by f.slug, a.slug)
	into v_n, v_mal
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where g.alcance = 'realizacion';
	if v_n <> 3 then
		raise exception '% preguntas por realización en vez de 3: %', v_n, v_mal;
	end if;

	-- La sección de la que cuelgan puede ocurrir más de una vez; si no, responder por realización
	-- no significaría nada.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	join public.estructuras_secciones s on s.seccion_id = g.seccion_id
	where g.alcance = 'realizacion'
		and coalesce(s.repeticiones_max, 2) < 2;
	if v_n <> 0 then
		raise exception '% preguntas por realización cuelgan de una sección que ocurre una vez', v_n;
	end if;

	-- El contraejemplo, que es lo que justifica declararlo en vez de deducirlo: la medida y la rima
	-- de la estancia cuelgan de una sección que se repite tres o más veces y siguen respondiéndose
	-- **una sola vez**, porque son las mismas en todas las estancias.
	select count(*), string_agg(g.slug || '=' || g.alcance, ', ' order by g.slug) into v_n, v_mal
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'cancion_petrarquista'
		and g.slug in ('medida_estancia', 'esquema_rima_estancia')
		and g.alcance <> 'unidad';
	if v_n <> 0 then
		raise exception '% preguntas de la estancia dejaron de responderse por unidad: %', v_n, v_mal;
	end if;

	-- La restricción se ejerce, no se promete: por realización sin sección debe rechazarse.
	select grupo_eleccion_id into v_grupo
	from public.grupos_eleccion_metrica where alcance = 'realizacion' limit 1;
	begin
		update public.grupos_eleccion_metrica
		set seccion_id = null
		where grupo_eleccion_id = v_grupo;
		raise exception 'La restricción admitió una pregunta por realización sin sección';
	exception
		when check_violation then
			null;
	end;

	-- Y lo que proyecta grupos sigue corriendo.
	select count(*) into v_n from public.grupos_eleccion_metrica_resueltos where alcance = 'realizacion';
	if v_n <> 3 then
		raise exception 'La vista resuelve % grupos por realización en vez de 3', v_n;
	end if;

	-- Cambiar el alcance no puede dejar sin opciones a ninguna pregunta. Se comprueba el
	-- invariante y no un total, que envejece en cuanto el catálogo crece.
	select count(*), string_agg(g.slug, ', ' order by g.slug) into v_n, v_mal
	from public.grupos_eleccion_metrica g
	where g.tipo_control = 'opciones' and g.activo
		and not exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = g.grupo_eleccion_id
		);
	if v_n <> 0 then
		raise exception '% preguntas se quedan sin opciones: %', v_n, v_mal;
	end if;

	-- Las tres de la represa conservan sus opciones, que es lo que este cambio no debe tocar.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	where g.alcance = 'realizacion';
	if v_n <> 8 then
		raise exception 'Las preguntas por realización ofrecen % opciones en vez de 8', v_n;
	end if;

	select public.obtener_catalogo_demarcador() into v_json;
	if not (v_json ? 'choiceGroups') then
		raise exception 'El catálogo del demarcador salió sin grupos';
	end if;

	select public.get_forma_metrica_publica_jerarquica('villancico') into v_json;
	if v_json is null then
		raise exception 'La ficha del villancico salió vacía';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

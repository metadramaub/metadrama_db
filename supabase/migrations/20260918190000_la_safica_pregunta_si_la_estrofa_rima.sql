-- La sáfica pregunta si la estrofa rima
--
-- Lo señaló el criterio **D17** de `npm run audit:metrica` —«una unidad cuya rima no está fija y
-- nadie pregunta»—, replicado a mano porque el audit necesita Docker para volcar y aquí no lo hay.
--
-- La arquitectura sáfica quedó con dos disposiciones: los cuatro versos sueltos, marcada
-- `definitoria`, y la consonante en el primero y el tercero, `admitida`. Eso incumple la regla 1 de
-- [criterios de nivel § 3.3](../../docs/dominio-metrico/criterios-de-nivel.md): **donde la norma no
-- fija una sola disposición, el editor tiene que poder decir cuál leyó.**
--
-- ══ Y al mirarlo de cerca, el defecto no era la falta de pregunta sino la etiqueta
--
-- `definitoria` significa que el esquema **define la forma**: sin él no es esa forma. Y las fuentes
-- dicen lo contrario. Navarro, en su «Índice de estrofas»: «desde el neoclasicismo se ha compuesto
-- también con los versos rimados». Quilis: «a partir del Neoclasicismo solían rimar el primero y
-- tercer endecasílabos». El *Diccionario*: «originariamente no lleva rima, **aunque es posible
-- encontrar esta estrofa con rima consonante o asonante**». Una sáfica rimada sigue siendo una
-- sáfica.
--
-- De modo que los versos sueltos son **lo habitual y no lo definitorio**, y esta migración corrige
-- eso antes de añadir la pregunta. El audit no pedía este cambio: pedía una pregunta. Pero poner la
-- pregunta dejando la etiqueta habría escondido que la etiqueta era falsa —y además el catálogo no
-- deja ofrecer como opción un esquema definitorio, así que el editor habría podido declarar la
-- rimada y no la suelta, que es la corriente—.
--
-- ══ La de Francisco de la Torre no cambia
--
-- Se queda con su único esquema `definitoria`, y por eso D17 no la señala. Ahí la ausencia de rima
-- sí define: Navarro la describe en «endecasílabos sueltos» y el *Diccionario* «sin rima entre sí»;
-- la rima alterna que este último menciona va con un «hay quien admite» que no fija norma.

begin;

do $$
declare
	v_safica uuid;
	v_grupo uuid;
	v_suelta uuid;
	v_rimada uuid;
	v_n integer;
	v_antes bigint;
	v_despues bigint;
begin
	select a.arquitectura_id into v_safica
	from public.arquitecturas_forma a
	join public.formas_metricas f using (forma_id)
	where f.slug = 'estrofa_safica' and a.slug = 'safica';
	if v_safica is null then
		raise exception 'No encuentro la arquitectura sáfica.';
	end if;

	select esquema_rima_id into v_suelta from public.esquemas_rima
	where arquitectura_id = v_safica and slug = 'sin_rima';
	select esquema_rima_id into v_rimada from public.esquemas_rima
	where arquitectura_id = v_safica and slug = 'a-a-';
	if v_suelta is null or v_rimada is null then
		raise exception 'No encuentro las dos disposiciones de la sáfica.';
	end if;

	-- Que se parte de donde se cree: una definitoria y una admitida, y ninguna pregunta de rima.
	select count(*) into v_n from public.esquemas_rima
	where esquema_rima_id = v_suelta and modalidad = 'definitoria';
	if v_n <> 1 then
		raise exception 'La disposición suelta no está marcada definitoria; no la toco.';
	end if;
	select count(*) into v_n from public.grupos_eleccion_metrica
	where arquitectura_id = v_safica and dimension = 'rima';
	if v_n <> 0 then
		raise exception 'La sáfica ya pregunta su rima.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	-- ------------------------------------------------------------------ La etiqueta
	update public.esquemas_rima
	set modalidad = 'habitual',
		descripcion =
			'Los cuatro versos van sueltos, que es como la estrofa entró en castellano y como la '
			|| 'definen las fuentes. Desde el Neoclasicismo también se compone rimada, de modo que la '
			|| 'ausencia de rima es lo corriente y no lo que la define.'
	where esquema_rima_id = v_suelta;

	-- ------------------------------------------------------------------ La pregunta
	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, dimension, alcance, selecciones_min, selecciones_max,
		permite_aplicar_global, activo, orden, tipo_control, define_norma, ayuda_editor
	)
	values (
		v_safica, 'disposicion_rima', 'rima', 'unidad', 1, 1, true, true, 1, 'opciones_y_esquema',
		false,
		'La sáfica nace sin rima y desde el Neoclasicismo se compone también rimada. Marca lo que '
		|| 'leas, y si la disposición no es ninguna de las dos, escríbela.'
	)
	returning grupo_eleccion_id into v_grupo;

	-- **Las opciones no se insertan**: `opciones_eleccion_metrica` es una vista sobre
	-- `opciones_eleccion_derivadas()`, que las saca de los esquemas de rima de la arquitectura. Por
	-- eso el orden importa: primero se quita el `definitoria` —un esquema definitorio no se ofrece,
	-- y lo vigila `trg_definitoria_no_se_ofrece`— y luego se crea la pregunta, que ya las encuentra
	-- las dos. Se comprueban abajo leyendo la vista.

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que ninguna de las dos disposiciones se declara ya definitoria, que es lo que las fuentes
	-- sostienen.
	select count(*) into v_n from public.esquemas_rima
	where arquitectura_id = v_safica and modalidad = 'definitoria';
	if v_n <> 0 then
		raise exception 'Queda alguna disposición de la sáfica marcada definitoria.';
	end if;

	-- Que la pregunta existe, es de rima, y ofrece las dos con salida abierta.
	select count(*) into v_n from public.grupos_eleccion_metrica
	where arquitectura_id = v_safica and dimension = 'rima' and activo
		and tipo_control = 'opciones_y_esquema' and selecciones_min = 1 and selecciones_max = 1;
	if v_n <> 1 then
		raise exception 'La pregunta de rima no ha quedado como se pretendía.';
	end if;
	-- Que la función deriva las dos opciones, la suelta y la rimada.
	select count(*) into v_n from public.opciones_eleccion_metrica
	where grupo_eleccion_id = v_grupo and esquema_rima_id in (v_suelta, v_rimada);
	if v_n <> 2 then
		raise exception 'La pregunta ofrece % opciones y esperaba dos.', v_n;
	end if;

	-- Y que la de Francisco de la Torre sigue exenta: una sola disposición y definitoria.
	select count(*) into v_n
	from public.esquemas_rima e
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'estrofa_safica' and a.slug = 'de_la_torre' and e.modalidad = 'definitoria';
	if v_n <> 1 then
		raise exception 'La arquitectura de la Torre ha dejado de fijar su rima.';
	end if;
	select count(*) into v_n
	from public.esquemas_rima e
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'estrofa_safica' and a.slug = 'de_la_torre';
	if v_n <> 1 then
		raise exception 'La arquitectura de la Torre tiene % disposiciones y esperaba una.', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;

-- La repetición no necesita una regla en prosa.
--
-- Cierre de la transversal de las reglas de repetición. Preguntaba tres cosas y dos ya estaban
-- respondidas desde el 9 de agosto, cuando el comportamiento se mudó de la opción a la
-- repetición: `materializa_seccion_id` dice qué sección hace aparecer y `extension_desde_seccion_id`
-- de dónde toma su extensión. Las opciones del editor se derivan de ella, no al revés.
--
-- Quedaba `regla`, y resulta que **no es una regla**. De sus once filas:
--
--   · En las **ocho represas** parafrasea a `descripcion`. «La repetición reproduce íntegramente
--     la primera aparición del estribillo» frente a «Represa total: el estribillo vuelve entero,
--     con todos sus versos». Lo mismo, dos veces.
--   · En **dos de las tres sextinas** repite en prosa el ciclo `ABCDEF → FAEBDC → …` que ya está
--     como dato en `repeticion_posiciones`, con sus 36 y 72 filas de bloque y posición de origen.
--   · Lo único suyo son las **salvedades** de las tres sextinas sobre lo que la fuente *no* fija.
--     Eso es una nota, no una regla, y es lo que hay que salvar.
--
-- Tampoco la lee nada que calcule: el `regla` que el demarcador enseña es el de las reglas de
-- longitud, otra columna. Los tres sitios que la usaban la usaban como etiqueta de respaldo, y
-- desde el 9 de agosto las repeticiones tienen `nombre` para eso.
--
-- Se retira, y antes se conserva lo que solo ella decía.

begin;

-- ---------------------------------------------------------------------------
-- 1 · Las salvedades de la sextina pasan a la descripción
-- ---------------------------------------------------------------------------
--
-- Son lo contrario de un dato: dicen qué **no** determina la forma, y por eso no pueden vivir en
-- `repeticion_posiciones`. La de Montemayor es además la razón de que esa sextina no tenga
-- ninguna posición declarada.

update public.repeticiones_metricas set
	descripcion = 'Seis palabras finales permutadas en seis estrofas y recuperadas en el terceto. En el terceto aparecen las seis, una interior y otra final en cada verso: la forma no impone una única asociación por parejas.',
	updated_at = now()
where slug = 'palabra_final'
	and arquitectura_id in (
		select a.arquitectura_id from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'sextina' and a.slug = 'clasica'
	);

update public.repeticiones_metricas set
	descripcion = 'Seis palabras finales permutadas durante dos ciclos estróficos y recuperadas en el terceto. En el terceto aparecen las seis, una interior y otra final en cada verso: la forma no impone una única asociación por parejas.',
	updated_at = now()
where slug = 'palabra_final'
	and arquitectura_id in (
		select a.arquitectura_id from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'sextina' and a.slug = 'doble_petrarquista'
	);

update public.repeticiones_metricas set
	descripcion = 'Seis palabras finales distribuidas en doce combinaciones estróficas distintas y dos tercetos finales. No se declaran sus posiciones porque la fuente no da ni la secuencia de las doce permutaciones ni una distribución por parejas.',
	updated_at = now()
where slug = 'palabra_final'
	and arquitectura_id in (
		select a.arquitectura_id from public.arquitecturas_forma a
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.slug = 'sextina' and a.slug = 'doble_montemayor'
	);

-- ---------------------------------------------------------------------------
-- 2 · Y la columna se va
-- ---------------------------------------------------------------------------

alter table public.repeticiones_metricas drop column regla;

comment on column public.repeticiones_metricas.descripcion is
	'Qué distingue a esta manera de repetir de sus hermanas, y las salvedades sobre lo que la forma no determina. Lo que sí determina no se escribe aquí: la sección que hace aparecer y de dónde toma su extensión son columnas, y el orden en que vuelven las palabras finales de una sextina son sus posiciones.';

comment on column public.repeticiones_metricas.tipo is
	'Qué se repite: el estribillo de un villancico o de un zéjel, o las palabras finales de una sextina.';

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
begin
	select count(*) into v_n
	from information_schema.columns
	where table_schema = 'public' and table_name = 'repeticiones_metricas' and column_name = 'regla';
	if v_n <> 0 then
		raise exception 'La columna `regla` sigue ahí';
	end if;

	-- Las once repeticiones siguen estando, y las tres salvedades de la sextina conservadas.
	select count(*) into v_n from public.repeticiones_metricas;
	if v_n <> 11 then raise exception 'Quedan % repeticiones en vez de 11', v_n; end if;

	select count(*) into v_n from public.repeticiones_metricas
	where slug = 'palabra_final'
		and (descripcion ilike '%no impone una única asociación por parejas%'
			or descripcion ilike '%la fuente no da%');
	if v_n <> 3 then
		raise exception 'Solo % de las 3 sextinas conserva su salvedad', v_n;
	end if;

	-- Y el comportamiento sigue siendo dato, que es lo que hace innecesaria la prosa.
	select count(*) into v_n from public.repeticiones_metricas where materializa_seccion_id is not null;
	if v_n <> 5 then
		raise exception '% repeticiones materializan una sección en vez de 5', v_n;
	end if;

	-- Nada de esto puede haber movido lo que el editor ofrece.
	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 405 then raise exception 'Las opciones dejaron de ser 405 y son %', v_n; end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

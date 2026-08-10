-- La primera quintilla es una quintilla.
--
-- Último eco de lo del villancico. Allí el catálogo decía que la cabeza y la represa eran dos
-- clases de sección distintas cuando las dos son el estribillo; aquí dice que «la primera
-- quintilla» es otra clase de cosa que «la segunda quintilla», cuando las dos son quintillas.
--
-- Son cinco parejas en cuatro formas, y en todas el `slug` ya dice cuál es cada una:
--
--   copla real          `primera_quintilla`   / `segunda_quintilla`    → quintilla
--   sextilla doble      `primera_sextilla`    / `segunda_sextilla`     → sextilla
--   copla de arte mayor `primera_semiestrofa` / `segunda_semiestrofa`  → semiestrofa
--   décima espinela     `primera_redondilla`  / `segunda_redondilla`   → redondilla
--   décima aumentada    `primer_bloque`       / `segundo_bloque`       → bloque
--
-- La última pareja no es dos veces lo mismo —uno es de cuatro versos y otro de ocho— pero los dos
-- son bloques, y su tamaño ya los separa.
--
-- NO SE REESTRUCTURA NADA. Convertirlas en «una sección repetida dos veces» sería llevar el caso
-- del villancico hasta el final, y la décima espinela lo desmiente sola: sus dos redondillas
-- ocupan las posiciones 1 y 3, con el enlace en medio, así que no son una sección repetida sino
-- dos sitios con algo entre ellos. Y en la copla real, donde sí son adyacentes, cada quintilla
-- tiene su propia pregunta de rima porque pueden rimar distinto.
--
-- EN PANTALLA NO CAMBIA NADA: las diez tienen nombre propio —«Primera quintilla», «Segunda
-- quintilla»— y el tipo solo se usa como etiqueta de reserva cuando falta el nombre.

begin;

update public.estructuras_secciones
set tipo_seccion = regexp_replace(tipo_seccion, '^(primer|segund)[ao]?_', ''),
	updated_at = now()
where tipo_seccion ~ '^(primer|segund)[ao]?_';

do $$
declare
	v_n integer;
	v_mal text;
	v_json jsonb;
	v_slug text;
begin
	-- No queda ningún tipo con ordinal.
	select count(*), string_agg(distinct tipo_seccion, ', ') into v_n, v_mal
	from public.estructuras_secciones where tipo_seccion ~ '^(primer|segund)';
	if v_n <> 0 then
		raise exception 'Quedan % secciones con tipo ordinal: %', v_n, v_mal;
	end if;

	-- Y las cinco parejas comparten ya su clase, con el nombre esperado.
	select count(*), string_agg(x.slug || '→' || x.tipo_seccion, ', ' order by x.slug)
	into v_n, v_mal
	from public.estructuras_secciones x
	where x.slug in (
			'primera_quintilla', 'segunda_quintilla', 'primera_sextilla', 'segunda_sextilla',
			'primera_semiestrofa', 'segunda_semiestrofa', 'primera_redondilla',
			'segunda_redondilla', 'primer_bloque', 'segundo_bloque'
		)
		and x.tipo_seccion <> regexp_replace(x.slug, '^(primer|segund)[ao]?_', '');
	if v_n <> 0 then
		raise exception '% secciones no quedaron en su clase: %', v_n, v_mal;
	end if;

	-- Las diez siguen ahí, con su nombre intacto: esto solo cambia la clase.
	select count(*) into v_n
	from public.estructuras_secciones
	where slug in (
		'primera_quintilla', 'segunda_quintilla', 'primera_sextilla', 'segunda_sextilla',
		'primera_semiestrofa', 'segunda_semiestrofa', 'primera_redondilla',
		'segunda_redondilla', 'primer_bloque', 'segundo_bloque'
	) and coalesce(btrim(nombre), '') <> '';
	if v_n <> 10 then
		raise exception 'Solo % de las diez secciones conservan nombre', v_n;
	end if;

	-- Y las fichas de las cuatro formas siguen saliendo con su árbol.
	foreach v_slug in array array['copla_real', 'sextilla', 'copla_de_arte_mayor', 'decima'] loop
		select public.get_forma_metrica_publica_jerarquica(v_slug) into v_json;
		if coalesce(jsonb_array_length(v_json -> 'secciones'), 0) = 0 then
			raise exception 'La ficha de % salió sin secciones', v_slug;
		end if;
	end loop;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

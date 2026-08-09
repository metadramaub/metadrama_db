-- La sexta rima deja de ser variedad y pasa a ser denominación.
--
-- Sale de la lectura transversal del concepto de variedad, del 9 de agosto de 2026.
--
-- Una variedad es, por definición, una **pareja** de esquema métrico y esquema de rima que el
-- proyecto reconoce dentro de una arquitectura; el esquema lo impone con dos columnas NOT NULL,
-- y su contraprueba en los criterios de nivel dice que «si los dos ejes son libres, no hace
-- falta». La prueba que debe pasar es restringir qué parejas se admiten.
--
-- **La sexta rima no restringe ninguna pareja.** Su arquitectura, `sexteto · endecasilabica`,
-- tiene **un solo esquema métrico** —`11-repetido`—, de modo que no hay combinaciones que
-- limitar: 1 × 2 = 2, y declarar una de las dos no excluye nada. Lo que hace en realidad es dar
-- nombre a la disposición ABABCC, que es exactamente el trabajo de una denominación.
--
-- El catálogo ya nombra así otras disposiciones: «Cuarteta» cuelga del esquema cruzado de la
-- redondilla, «Sextilla alterna» de `ababab`. Son once denominaciones sobre esquemas de rima, y
-- la sexta rima pasa a ser una más.
--
-- Qué se conserva. Los tres nombres que la bibliografía le da —«Sexteto clásico», «Sextina
-- real» de Jauralde y «Sextina antigua» del Diccionario— colgaban de la variedad y pasan al
-- esquema con su fuente. La descripción de la variedad, que explicaba la disposición, pasa al
-- esquema, que no tenía ninguna. Y el término legado `sexta_rima` sigue declarando su destino:
-- lo hereda la denominación nueva, así que la equivalencia no se pierde.
--
-- Orden de las operaciones. Las denominaciones apuntan a la variedad con `ON DELETE CASCADE`,
-- de modo que borrarla primero se las llevaría por delante: hay que moverlas antes. Y
-- `origen_termino_id` es único en las dos tablas, así que la variedad debe desaparecer antes de
-- que la denominación reclame el término.
--
-- Ninguna obra usa `sexta_rima` ni responde una elección que apunte a esta variedad
-- —comprobado—, así que no se mueve ninguna anotación. Tras esto quedan **siete variedades, las
-- siete del sexteto-lira**, cuyo caso es distinto y sigue abierto para el IP.

begin;

do $$
declare
	v_variedad uuid;
	v_esquema uuid;
	v_termino uuid;
	v_descripcion text;
	v_n integer;
begin
	select v.variedad_id, v.esquema_rima_id, v.origen_termino_id, v.descripcion
	into v_variedad, v_esquema, v_termino, v_descripcion
	from public.variedades_arquitectura v
	join public.arquitecturas_forma a on a.arquitectura_id = v.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sexteto' and v.slug = 'sexta_rima';

	if num_nonnulls(v_variedad, v_esquema) <> 2 then
		raise exception 'No está la variedad «Sexta rima» del sexteto, o no declara esquema de rima';
	end if;

	-- La arquitectura tiene un solo esquema métrico: es lo que hace que no sea una variedad.
	select count(*) into v_n from public.esquemas_metricos em
	join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sexteto' and a.slug = 'endecasilabica';
	if v_n <> 1 then
		raise exception 'La sexta rima solo deja de ser variedad si su arquitectura tiene un único esquema métrico, y tiene %', v_n;
	end if;

	-- 1 · Los nombres de la bibliografía pasan de la variedad al esquema.
	update public.denominaciones_metricas
	set variedad_id = null,
		esquema_rima_id = v_esquema,
		updated_at = now()
	where variedad_id = v_variedad;

	-- 2 · La descripción explica la disposición, así que su sitio es el esquema.
	update public.esquemas_rima
	set descripcion = coalesce(descripcion, v_descripcion),
		updated_at = now()
	where esquema_rima_id = v_esquema;

	-- 3 · Se retira la variedad, lo que libera el término legado.
	delete from public.variedades_arquitectura where variedad_id = v_variedad;

	-- 4 · El nombre propio de la disposición, con el origen legado que tenía la variedad.
	insert into public.denominaciones_metricas (
		esquema_rima_id, nombre, slug_normalizado, preferente, origen_termino_id
	)
	values (v_esquema, 'Sexta rima', 'sexta_rima', true, v_termino);

	-- Guardas.
	select count(*) into v_n from public.denominaciones_metricas
	where esquema_rima_id = v_esquema;
	if v_n <> 4 then
		raise exception 'El esquema ABABCC debe declarar cuatro nombres, no %', v_n;
	end if;

	select count(*) into v_n from public.variedades_arquitectura;
	if v_n <> 7 then
		raise exception 'Deben quedar siete variedades, las del sexteto-lira, y quedan %', v_n;
	end if;

	select count(*) into v_n from public.variedades_arquitectura v
	join public.arquitecturas_forma a on a.arquitectura_id = v.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug <> 'sexteto_lira';
	if v_n <> 0 then
		raise exception 'Ninguna variedad debe quedar fuera del sexteto-lira, y quedan %', v_n;
	end if;

	-- La equivalencia del término legado no se pierde al cambiar de destino.
	select count(*) into v_n from public.denominaciones_metricas
	where origen_termino_id = v_termino;
	if v_n <> 1 then
		raise exception 'El término legado «sexta_rima» debe seguir declarando su destino';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

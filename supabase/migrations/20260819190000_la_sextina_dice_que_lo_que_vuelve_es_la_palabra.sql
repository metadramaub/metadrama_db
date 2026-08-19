-- La sextina dice que lo que vuelve es la palabra
--
-- Siete de sus diecisiete textos no se ven, y los siete repiten algo que la ficha ya dice: dos
-- notas de posición métrica, dos descripciones de esquema métrico —las cuatro sobre los tres
-- versos del remate, que la fila «Medida» dibuja—, una descripción de esquema de rima que la
-- rejilla pinta con seis guiones, y **dos notas de sección** que dicen exactamente lo que ya
-- dice, y visible, la descripción de la repetición.
--
-- Las dos definiciones crecen con lo que explica la forma y no está en ninguna parte: que lo que
-- la organiza no es la rima sino la palabra, la genealogía —Arnaut Daniel, Petrarca, entrada
-- tardía y escaso arraigo en España— y el aviso de no confundir la estrofa con la sextina real,
-- que es un sexteto consonante y otra cosa.
--
-- Las cuatro descripciones de arquitectura y las tres de repetición **no se tocan**: son cortas,
-- exactas y no derivadas. La de Montemayor calla lo del cierre por parejas a propósito, porque
-- Navarro Tomás advierte que no detalla la disposición en los dos tercetos.

begin;

-- ---------------------------------------------------------------------------
-- 1 · Las dos definiciones
-- ---------------------------------------------------------------------------
do $$
declare
	fila record;
	v_actual text;
begin
	for fila in
		select *
		from (values
			(
				'sextina',
				'Composición endecasilábica formada por seis o doce sextinas y cerrada por uno o dos tercetos. Seis palabras finales aparecen en cada estrofa, permutadas en órdenes sucesivos, y vuelven en el cierre en posición interior y final.',
				'Composición endecasilábica formada por seis o doce sextinas y cerrada por uno o dos tercetos. Lo que la organiza no es la rima sino la repetición: seis palabras finales, las mismas en toda la composición, vuelven en cada estrofa en un orden distinto que sigue una permutación fija, y comparecen por última vez en el cierre, una en el interior y otra al final de cada verso. La inventó Arnaut Daniel, la fijó Petrarca y entró en España en el siglo XVI, donde arraigó poco.'
			),
			(
				'sextina_estrofa',
				'Estrofa de seis endecasílabos sin rima convencional. Cada verso termina en una palabra distinta que funciona como palabra-rima; en la composición homónima, esas seis palabras se permutan de una estrofa a otra.',
				'Estrofa de seis endecasílabos sin rima convencional: lo que se repite de una estrofa a otra no es un sonido sino una palabra entera. Cada verso termina en una palabra distinta, y esas seis son las que la composición homónima permuta estrofa tras estrofa. Fuera de ella la estrofa no se usa sola, y conviene no confundirla con la sextina real, que es otra cosa: un sexteto endecasílabo consonante.'
			)
		) as t(slug, viejo, nuevo)
	loop
		select definicion into v_actual from public.formas_metricas where slug = fila.slug and activo;

		if not found then
			raise exception 'No existe la forma activa «%».', fila.slug;
		end if;

		if v_actual is distinct from fila.viejo and v_actual is distinct from fila.nuevo then
			raise exception 'La definición de «%» no es la esperada. Dice: %', fila.slug, v_actual;
		end if;

		update public.formas_metricas set definicion = fila.nuevo where slug = fila.slug;
	end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 2 · Los siete textos que no se ven
--
-- Las dos notas de sección del remate decían: «Las seis palabras comparecen una vez: cada verso
-- contiene una en el interior y otra al final, sin un orden universal por parejas.» Es
-- exactamente lo que dice, y **visible**, la descripción de la repetición de esas mismas dos
-- arquitecturas. Se van sin pérdida.
-- ---------------------------------------------------------------------------
do $$
declare
	v_formas uuid[];
	v_restantes integer;
begin
	select array_agg(forma_id) into v_formas
	from public.formas_metricas where slug like 'sextina%' and activo;

	if array_length(v_formas, 1) <> 2 then
		raise exception 'No hay dos formas activas de sextina.';
	end if;

	-- Antes de retirar las notas de sección, que lo que dicen siga estando a la vista.
	if (
		select count(*) from public.repeticiones_metricas r
		join public.arquitecturas_forma a on a.arquitectura_id = r.arquitectura_id
		where a.forma_id = any (v_formas)
			and r.descripcion ilike '%una en el interior y otra al final%'
	) < 2 then
		raise exception 'La descripción visible de la repetición ya no dice lo del cierre.';
	end if;

	update public.estructuras_secciones s
	set nota = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = s.arquitectura_id and a.forma_id = any (v_formas) and s.nota is not null;

	update public.esquemas_rima er
	set descripcion = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = er.arquitectura_id
		and a.forma_id = any (v_formas)
		and er.descripcion is not null;

	update public.esquemas_metricos em
	set descripcion = null
	from public.arquitecturas_forma a
	where a.arquitectura_id = em.arquitectura_id
		and a.forma_id = any (v_formas)
		and em.descripcion is not null;

	update public.esquema_metrico_posiciones p
	set nota = null
	from public.esquemas_metricos em, public.arquitecturas_forma a
	where em.esquema_metrico_id = p.esquema_metrico_id
		and a.arquitectura_id = em.arquitectura_id
		and a.forma_id = any (v_formas)
		and p.nota is not null;

	select
		(select count(*) from public.estructuras_secciones s join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id where a.forma_id = any (v_formas) and s.nota is not null)
		+ (select count(*) from public.esquemas_rima er join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id where a.forma_id = any (v_formas) and er.descripcion is not null)
		+ (select count(*) from public.esquemas_metricos em join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id where a.forma_id = any (v_formas) and em.descripcion is not null)
		+ (select count(*) from public.esquema_metrico_posiciones p join public.esquemas_metricos em on em.esquema_metrico_id = p.esquema_metrico_id join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id where a.forma_id = any (v_formas) and p.nota is not null)
	into v_restantes;

	if v_restantes > 0 then
		raise exception 'Quedan % textos ocultos en las dos sextinas.', v_restantes;
	end if;

	-- Y las tres descripciones de repetición, que son las que sostienen todo, siguen ahí.
	if (
		select count(*) from public.repeticiones_metricas r
		join public.arquitecturas_forma a on a.arquitectura_id = r.arquitectura_id
		where a.forma_id = any (v_formas) and r.descripcion is not null
	) <> 3 then
		raise exception 'Las tres descripciones de repetición no están completas.';
	end if;
end $$;

-- ---------------------------------------------------------------------------
-- 3 · La relación entre las dos formas dice por qué son dos
-- ---------------------------------------------------------------------------
do $$
declare
	v_composicion uuid;
	v_estrofa uuid;
	v_actual text;
	v_viejo constant text :=
		'La arquitectura clásica repite seis veces la estrofa; las dos arquitecturas dobles, doce.';
	v_nuevo constant text :=
		'La arquitectura clásica repite seis veces la estrofa; las dos dobles, doce. Son dos formas distintas porque la estrofa es una unidad cerrada de seis versos y la composición es una estructura mayor que las ordena y las cierra con un remate.';
begin
	select forma_id into v_composicion from public.formas_metricas where slug = 'sextina' and activo;
	select forma_id into v_estrofa from public.formas_metricas where slug = 'sextina_estrofa' and activo;

	select nota into v_actual
	from public.forma_relaciones
	where forma_origen_id = v_composicion and forma_destino_id = v_estrofa;

	if not found then
		raise exception 'No existe la relación entre las dos sextinas.';
	end if;

	if v_actual is distinct from v_viejo and v_actual is distinct from v_nuevo then
		raise exception 'La nota de la relación no es la esperada. Dice: %', v_actual;
	end if;

	update public.forma_relaciones
	set nota = v_nuevo
	where forma_origen_id = v_composicion and forma_destino_id = v_estrofa;
end $$;

commit;

-- Donde se documenta el quiebro, se declara
--
-- Cuatro arquitecturas dicen en su nota en qué verso cae el quiebro y lo preguntaban en **todos**.
-- El editor ofrecía tetrasílabo y pentasílabo en cada verso de la estrofa, así que anotar una
-- quintilla quebrada pedía además señalar dónde, cuando la tradición solo documenta un sitio.
--
-- **Por qué pasaba.** Hay dos mecanismos y estas estaban en el que no restringe:
--
--   * `medida_uniforme = false` + roles en `esquema_metrico_opciones`: la función que deriva las
--     opciones enumera `generate_series(1, unidad_versos_max)` y ofrece el quebrado en cada verso.
--   * `medida_uniforme = null` + `esquema_metrico_posiciones`: solo ofrece donde una posición
--     declara más de un metro. Así funcionan la manriqueña, la sextilla de pie quebrado y las tres
--     enlazadas, que declaran **todos** sus versos —el octosílabo en los plenos, el tetrasílabo y el
--     pentasílabo en los quebrados— y por eso solo preguntan donde hay algo que elegir.
--
-- Estas cuatro pasan al segundo, con la misma forma que la manriqueña.
--
-- **El quiebro sigue sin ser obligatorio.** `pie_quebrado` se queda `admitida` con su
-- `posiciones_max`, y la posición declarada ofrece las tres medidas: el octosílabo es la respuesta
-- de que ahí no hay quiebro. Un quiebro en otro verso deja de ser una respuesta y pasa a ser una
-- desviación, que es donde se lee lo que se aparta de la norma; si el corpus lo repite, será otra
-- norma y se declarará.
--
-- **Las cuatro, y lo que las sostiene:**
--
--   | forma · arquitectura            | verso | fuente |
--   |---------------------------------|-------|--------|
--   | Quintilla · Octosilábica cons.  | 1     | Navarro Tomás § 154: «la quintilla con verso inicial quebrado fue la estrofa más usada por Castillejo» |
--   | Septilla · Octosilábica         | 5     | una realización áurea de Baltasar del Alcázar, con el quinto verso quebrado |
--   | Novena · Redondilla + quintilla | 5     | «el único caso que las fuentes documentan»: Jauralde recoge de Castillejo `8a 8b 8b 8a 4c 8c 8d 8d 8c` |
--   | Oncena · Quintilla + sextilla   | 8, 11 | el *Claro escuro* de Juan de Mena como modelo, `abaab:cdecde`, repetido por Álvarez Gato, Gómez Manrique y Tapia |
--
-- **No entran las otras dos que nombran un verso**, porque su nota dice que nadie lo documenta:
-- la novena en orden 5+4 —«ninguna fuente documenta un ejemplo con quebrado… *caería* en el
-- primero»— y la oncena en orden 6-5, cuya posición sale de trasladar la sextilla de pie quebrado
-- al principio y no de una realización leída. Declarar una inferencia sería afirmar más de lo que
-- se sabe.
--
-- **Ni las tres que preguntan en todos los versos con razón**, y su nota lo dice: la copla real
-- —«la tradición no fija en qué verso»—, la redondilla —«sin fijar en qué versos cae»— y la copla
-- de arte menor. La copla castellana queda aparte: nombra un verso **y** un patrón alterno.
--
-- No se borra ninguna fila: las posiciones que faltan se añaden y la que ya había se respeta.

begin;

do $$
declare
	v_caso record;
	v_esquema uuid;
	v_versos integer;
	v_octo uuid;
	v_tetra uuid;
	v_penta uuid;
	v_posicion integer;
	v_uniforme boolean;
begin
	select metro_id into v_octo from public.metros where silabas = 8 and tipo = 'simple' and activo;
	select metro_id into v_tetra from public.metros where silabas = 4 and tipo = 'simple' and activo;
	select metro_id into v_penta from public.metros where silabas = 5 and tipo = 'simple' and activo;

	if v_octo is null or v_tetra is null or v_penta is null then
		raise exception 'Faltan el octosílabo, el tetrasílabo o el pentasílabo en el catálogo de metros.';
	end if;

	for v_caso in
		select * from (values
			('Quintilla', 'Octosilábica consonante', array[1]),
			('Septilla', 'Octosilábica', array[5]),
			('Novena', 'Redondilla + quintilla', array[5]),
			('Oncena', 'Quintilla + sextilla', array[8, 11])
		) as t(forma, arquitectura, quebrados)
	loop
		select em.esquema_metrico_id, em.medida_uniforme, a.unidad_versos_max
		into v_esquema, v_uniforme, v_versos
		from public.esquemas_metricos em
		join public.arquitecturas_forma a on a.arquitectura_id = em.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.nombre = v_caso.forma and a.nombre = v_caso.arquitectura;

		if v_esquema is null then
			raise exception 'No está el esquema métrico de % · %.', v_caso.forma, v_caso.arquitectura;
		end if;

		if v_versos is null then
			raise exception '% · % no declara cuántos versos mide su unidad.', v_caso.forma, v_caso.arquitectura;
		end if;

		-- La unidad tiene que llegar hasta el último verso quebrado que se va a declarar.
		if v_versos < (select max(q) from unnest(v_caso.quebrados) as q) then
			raise exception '% · % mide % versos y se quiere quebrar el %.',
				v_caso.forma, v_caso.arquitectura, v_versos,
				(select max(q) from unnest(v_caso.quebrados) as q);
		end if;

		-- El octosílabo en cada verso: es lo que la norma pone donde no pregunta nada.
		for v_posicion in 1..v_versos loop
			insert into public.esquema_metrico_posiciones
				(esquema_metrico_id, posicion, metro_id, opcional, alternativa)
			values (v_esquema, v_posicion, v_octo, false, 1)
			on conflict (esquema_metrico_id, alternativa, posicion) do nothing;
		end loop;

		-- Y las dos medidas del quiebro donde se documenta.
		foreach v_posicion in array v_caso.quebrados loop
			insert into public.esquema_metrico_posiciones
				(esquema_metrico_id, posicion, metro_id, opcional, alternativa)
			values (v_esquema, v_posicion, v_tetra, true, 2)
			on conflict (esquema_metrico_id, alternativa, posicion) do nothing;
			insert into public.esquema_metrico_posiciones
				(esquema_metrico_id, posicion, metro_id, opcional, alternativa)
			values (v_esquema, v_posicion, v_penta, true, 3)
			on conflict (esquema_metrico_id, alternativa, posicion) do nothing;
		end loop;

		-- Y con las posiciones escritas, el esquema pasa al mecanismo que las respeta.
		update public.esquemas_metricos
		set medida_uniforme = null
		where esquema_metrico_id = v_esquema;
	end loop;
end $$;

do $$
declare
	v_caso record;
	v_ofrecidas integer[];
	v_esperadas integer[];
	v_medidas integer;
begin
	-- ------------------------------------------------------------------ Comprobación
	--
	-- **Se ejecuta la función**, leyendo la vista derivada: qué versos ofrece ahora cada una.
	for v_caso in
		select * from (values
			('Quintilla', 'Octosilábica consonante', array[1]),
			('Septilla', 'Octosilábica', array[5]),
			('Novena', 'Redondilla + quintilla', array[5]),
			('Oncena', 'Quintilla + sextilla', array[8, 11])
		) as t(forma, arquitectura, quebrados)
	loop
		select array_agg(distinct o.posicion_unidad order by o.posicion_unidad)
		into v_ofrecidas
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.nombre = v_caso.forma and a.nombre = v_caso.arquitectura and g.dimension = 'metro';

		v_esperadas := v_caso.quebrados;

		if v_ofrecidas is distinct from v_esperadas then
			raise exception '% · % ofrece el quiebro en % y debía ofrecerlo en %.',
				v_caso.forma, v_caso.arquitectura, v_ofrecidas, v_esperadas;
		end if;

		-- Y en cada uno de esos versos, las tres medidas: el octosílabo dice que ahí no hay quiebro.
		select count(distinct o.metro_id) into v_medidas
		from public.opciones_eleccion_metrica o
		join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		where f.nombre = v_caso.forma and a.nombre = v_caso.arquitectura and g.dimension = 'metro'
			and o.posicion_unidad = v_caso.quebrados[1];

		if v_medidas <> 3 then
			raise exception '% · % ofrece % medidas en el verso quebrado, y debían ser 3.',
				v_caso.forma, v_caso.arquitectura, v_medidas;
		end if;
	end loop;

	-- Las que no entran siguen preguntando en todos los versos: no se las ha tocado de refilón.
	select array_agg(distinct o.posicion_unidad order by o.posicion_unidad)
	into v_ofrecidas
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.nombre = 'Redondilla' and a.nombre = 'Octosilábica' and g.dimension = 'metro';

	if v_ofrecidas is distinct from array[1, 2, 3, 4] then
		raise exception 'La redondilla ofrece el quiebro en %, y debía seguir ofreciéndolo en los cuatro versos.', v_ofrecidas;
	end if;
end $$;

commit;

-- Las fuentes del catálogo son seis monografías, y solo seis.
--
-- Había once registradas. Ocho se consultaron por internet y no tienen la autoridad que el
-- catálogo exige de una fuente: se retiran. Con ellas se van siete afirmaciones sobre el
-- villancico, la redondilla doble, el zéjel, la copla de pie quebrado, la copla real y la
-- décima. **Lo que decían no se pierde**: está en las definiciones que justificaban, y al
-- revisar cada una de esas formas se buscará su equivalente en las seis autorizadas.
--
-- Las que quedan, más las tres que faltaban por dar de alta:
--
--   Quilis 1969          · Métrica española
--   Morley y Bruerton 1968 · Cronología de las comedias de Lope de Vega
--   Navarro Tomás 1972   · Métrica española
--   Domínguez Caparrós 2014 · Métrica española
--   Domínguez Caparrós 2016 · Diccionario de métrica española
--   Jauralde Pou 2020    · Métrica española
--
-- Se retira además la URL del Diccionario: apuntaba al primer capítulo suelto del editor, y
-- la fuente es el libro.

begin;

do $$
declare
	v_borradas integer;
	v_afirmaciones integer;
	v_quedan integer;
begin
	select count(*) into v_afirmaciones
	from public.afirmaciones_fuentes_metricas af
	join public.fuentes_metricas fu on fu.fuente_id = af.fuente_id
	where fu.autoria not like '%Domínguez Caparrós%' and fu.autoria not like '%Morley%';

	delete from public.fuentes_metricas
	where autoria not like '%Domínguez Caparrós%' and autoria not like '%Morley%';
	get diagnostics v_borradas = row_count;

	raise notice 'Fuentes retiradas: % · afirmaciones que colgaban de ellas: %',
		v_borradas, v_afirmaciones;

	update public.fuentes_metricas set url = null where url is not null;

	insert into public.fuentes_metricas (tipo, autoria, titulo, anio, publicacion, cita)
	select * from (values
		('monografía', 'Antonio Quilis', 'Métrica española', 1969,
			'Madrid: Ediciones Alcalá',
			'Quilis, Antonio. Métrica española. Madrid: Ediciones Alcalá, 1969.'),
		('monografía', 'Tomás Navarro Tomás', 'Métrica española', 1972,
			'Madrid: Guadarrama',
			'Navarro Tomás, Tomás. Métrica española. Reseña histórica y descriptiva. Madrid: Guadarrama, 1972.'),
		('monografía', 'Pablo Jauralde Pou', 'Métrica española', 2020,
			'Madrid: Cátedra',
			'Jauralde Pou, Pablo. Métrica española. Madrid: Cátedra, 2020.')
	) as t(tipo, autoria, titulo, anio, publicacion, cita)
	where not exists (
		select 1 from public.fuentes_metricas x
		where x.autoria = t.autoria and x.anio = t.anio
	);

	select count(*) into v_quedan from public.fuentes_metricas;
	if v_quedan <> 6 then
		raise exception 'Deberían quedar seis fuentes y quedan %', v_quedan;
	end if;

	raise notice 'Fuentes autorizadas del catálogo: %', v_quedan;
end $$;

comment on table public.fuentes_metricas is
	'Las seis monografías de métrica española que respaldan el catálogo. Una fuente es una publicación bibliográfica autorizada; una página web o un capítulo suelto no lo son.';

commit;

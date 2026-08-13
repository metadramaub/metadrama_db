-- La clase de rima marca el arte del verso, como su notación.
--
-- Al dibujar la unidad verso a verso salió que **ocho esquemas guardan una cosa en
-- `clase_rima` y otra en `notacion`**. El zéjel guarda `AABBBA` y publica `a(a) | [bbba]…`; el
-- romance endecasílabo guarda `a` y publica `[-A]…`; la canción de trece guarda
-- `ABCABCCDEEDFF` y publica `abCabC:cdeeDfF`. La rejilla pinta la clase, así que en esos ocho
-- las letras dibujadas contradecían la notación impresa dos líneas más abajo.
--
-- **La notación acierta en los ocho**, y se comprobó uno a uno contra su esquema métrico: en
-- todos ellos la medida cambia de verso a verso —o es toda de arte menor, en el zéjel y el
-- terceto encadenado octosilábico— y la clase guardada lo ignoraba. Los otros 62 esquemas con
-- posiciones ya cuadran letra por letra y caja por caja, así que la convención del catálogo es
-- la que la ficha publica desde el principio: **la mayúscula marca el arte mayor y la minúscula
-- el arte menor, y no son clases de rima distintas**. Esta migración pone a los ocho de acuerdo
-- con ella.
--
-- La corrección se escribe como la secuencia completa de cada esquema, y no posición a
-- posición, para que se lea igual que se lee su notación. Se aplica a las posiciones que rimen,
-- en orden de lectura: los versos sueltos no llevan clase y la notación no les da letra.

do $$
declare
	corregidas integer;
begin
	with correcciones(forma_slug, arquitectura_slug, esquema_slug, secuencia) as (values
		-- 7-7-11-7-7-11-7-7-7-7-11-7-11: mayúscula en los endecasílabos 3, 6, 11 y 13. El
		-- eslabón —el heptasílabo séptimo— rima con el sexto, y por eso es `c` junto a `C`.
		('cancion_petrarquista', 'regular_13_versos', 'abcabccdeedff', 'abCabCcdeeDfF'),
		-- 7-7-7-11: el endecasílabo cierra el cuarteto.
		('endecha_real', 'heptasilabica_con_endecasilabo', 'abrazada', 'abbA'),
		('endecha_real', 'heptasilabica_con_endecasilabo', 'cruzada', 'aA'),
		-- 7-7-7-7-11.
		('endecha_real', 'heptasilabica_con_endecasilabo_de_cinco', 'redondilla_con_endecasilabo', 'abbaA'),
		-- Serie entera de endecasílabos: la asonancia de los pares es de arte mayor.
		('romance', 'endecasilabica', 'asonancia-pares', 'A'),
		-- Ciclo 7-11: el pareado rima consigo mismo, y sus dos versos no miden igual.
		('silva', 'consonante_regular', 'pareados-regulares', 'aA'),
		-- Octosílabos: arte menor de principio a fin.
		('terceto_encadenado', 'octosilabica_consonante', 'encadenado-con-serventesio', 'aba'),
		-- Hexasílabos u octosílabos: arte menor también.
		('zejel', 'estribillo_y_coplas_monorrimas', 'estribillo-mudanza-vuelta', 'aabbba')
	),
	objetivo as (
		select er.esquema_rima_id, c.secuencia
		from correcciones c
		join public.formas_metricas f on f.slug = c.forma_slug
		join public.arquitecturas_forma a
			on a.forma_id = f.forma_id and a.slug = c.arquitectura_slug
		join public.esquemas_rima er
			on er.arquitectura_id = a.arquitectura_id and er.slug = c.esquema_slug
	),
	numeradas as (
		select
			p.posicion_id,
			o.secuencia,
			row_number() over (partition by p.esquema_rima_id order by p.bloque, p.posicion) as orden
		from public.esquema_rima_posiciones p
		join objetivo o using (esquema_rima_id)
		where p.clase_rima is not null
	)
	update public.esquema_rima_posiciones p
	set clase_rima = substr(n.secuencia, n.orden::int, 1),
		updated_at = now()
	from numeradas n
	where p.posicion_id = n.posicion_id
		and p.clase_rima is distinct from substr(n.secuencia, n.orden::int, 1);

	get diagnostics corregidas = row_count;
	if corregidas = 0 then
		raise exception 'no se corrigió ninguna posición: las ocho correcciones no encontraron su esquema';
	end if;
	raise notice 'posiciones corregidas: %', corregidas;
end;
$$;

-- La guarda comprueba **todo el catálogo**, no solo lo corregido: para cada esquema con
-- notación y con posiciones, las letras de la notación tienen que ser exactamente las clases
-- guardadas, en orden de lectura y con su caja. Es la comprobación que destapó los ocho.
do $$
declare
	descuadre record;
begin
	select
		f.slug as forma,
		er.slug as esquema,
		er.notacion,
		regexp_replace(er.notacion, '[^a-zA-Z]', '', 'g') as letras,
		coalesce((
			select string_agg(p.clase_rima, '' order by p.bloque, p.posicion)
			from public.esquema_rima_posiciones p
			where p.esquema_rima_id = er.esquema_rima_id and p.clase_rima is not null
		), '') as clases
	into descuadre
	from public.formas_metricas f
	join public.arquitecturas_forma a on a.forma_id = f.forma_id and a.activo
	join public.esquemas_rima er on er.arquitectura_id = a.arquitectura_id
	where f.activo
		and er.notacion is not null and er.notacion <> ''
		and exists (
			select 1 from public.esquema_rima_posiciones p
			where p.esquema_rima_id = er.esquema_rima_id
		)
		and regexp_replace(er.notacion, '[^a-zA-Z]', '', 'g') <> coalesce((
			select string_agg(p.clase_rima, '' order by p.bloque, p.posicion)
			from public.esquema_rima_posiciones p
			where p.esquema_rima_id = er.esquema_rima_id and p.clase_rima is not null
		), '')
	limit 1;

	if found then
		raise exception 'la notación y las clases no cuadran en %/%: «%» frente a «%»',
			descuadre.forma, descuadre.esquema, descuadre.letras, descuadre.clases;
	end if;
end;
$$;

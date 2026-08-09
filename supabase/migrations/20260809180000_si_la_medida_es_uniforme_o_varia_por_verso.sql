-- Si la medida es uniforme en el tramo o varía verso a verso.
--
-- Séptimo y último hueco de la auditoría de las preguntas del editor, y el único que no se vio
-- revisando el catálogo: apareció al **escribir la derivación y contrastarla** contra las
-- opciones escritas a mano. La dimensión del metro daba 39 derivadas frente a 167.
--
-- Las preguntas de medida son de dos clases. Unas se responden con **una sola medida para todo
-- el tramo** —«¿qué miden los versos de la mudanza?», y la mudanza del villancico es
-- isosilábica—. Otras, con **una medida por verso** —la estancia de la canción petrarquista
-- combina heptasílabos y endecasílabos posición a posición—.
--
-- Las dos usan un esquema métrico que declara un conjunto de medidas admitidas, y las dos
-- pueden estar ancladas a una sección, de modo que **ni el tipo ni el anclaje las separan**. Lo
-- que las separaba estaba en la prosa: la descripción del conjunto de la canción dice «cada
-- posición de la estancia se registra como heptasílaba o endecasílaba» y la del villancico,
-- «sin imponer un orden fijo».
--
-- Es un hecho de métrica y no de formulario, y por eso se declara: que la mudanza sea
-- isosilábica es una propiedad de la mudanza, no una decisión sobre cómo preguntarla.
--
-- Con esto la derivación cuadra exacto, y la guarda del final lo comprueba: para cada pregunta
-- de medida, las opciones escritas a mano deben coincidir con las que salen del catálogo
-- —posiciones por metros admitidos, o un solo juego de metros cuando la medida es uniforme—.
--
-- No cambia ninguna pregunta ni ninguna anotación.

begin;

alter table public.esquemas_metricos
	add column if not exists medida_uniforme boolean;

comment on column public.esquemas_metricos.medida_uniforme is
	'Solo para los esquemas que declaran un conjunto de medidas admitidas. Verdadero cuando todos los versos del tramo comparten una misma medida —la mudanza del villancico es isosilábica—; falso cuando cada posición tiene la suya —la estancia de la canción combina heptasílabos y endecasílabos—. Nulo cuando el esquema no declara conjunto y su medida sale de las posiciones.';

do $$
declare
	v_n integer;
	v_fila record;
	v_derivadas integer;
	v_escritas integer;
begin
	-- Uniformes: el tramo entero comparte medida.
	update public.esquemas_metricos em
	set medida_uniforme = true, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where a.arquitectura_id = em.arquitectura_id
		and f.forma_id = a.forma_id
		and f.slug in ('villancico', 'zejel')
		and em.slug = 'conjunto-6-8';

	-- Heterométricos: cada posición declara la suya.
	update public.esquemas_metricos em
	set medida_uniforme = false, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where a.arquitectura_id = em.arquitectura_id
		and f.forma_id = a.forma_id
		and (
			(f.slug in ('silva', 'cancion_petrarquista') and em.slug = 'conjunto-7-11')
			or (f.slug = 'pareado' and em.slug = 'conjunto-4-14')
			or (f.slug = 'copla_de_pie_quebrado' and em.slug = 'octosilabos-con-quebrados-4-5')
			or (f.slug = 'copla_real' and em.slug = '8-repetido')
		);

	select count(*) into v_n from public.esquemas_metricos where medida_uniforme is true;
	if v_n <> 3 then
		raise exception 'Deben ser tres los esquemas de medida uniforme, y son %', v_n;
	end if;

	select count(*) into v_n from public.esquemas_metricos where medida_uniforme is false;
	if v_n <> 7 then
		raise exception 'Deben ser siete los esquemas heterométricos, y son %', v_n;
	end if;

	-- Todo esquema que declare un conjunto de medidas tiene que decir de qué clase es.
	select count(*) into v_n
	from public.esquemas_metricos em
	where em.medida_uniforme is null
		and exists (
			select 1 from public.esquema_metrico_opciones eo
			where eo.esquema_metrico_id = em.esquema_metrico_id
		);
	if v_n <> 0 then
		raise exception 'Quedan % esquemas con conjunto de medidas y sin declarar su clase', v_n;
	end if;

	-- LA PRUEBA: la derivación tiene que reproducir las opciones escritas a mano.
	for v_fila in
		select g.grupo_eleccion_id, g.slug, f.nombre as forma,
			-- Cuántas posiciones cubre la pregunta: las de su sección si está anclada a una,
			-- y si no, las de la unidad.
			coalesce(s.versos_max, a.unidad_versos_max) as posiciones,
			em.medida_uniforme,
			-- Los metros admitidos; cuando hay roles declarados, solo los quebrados, porque el
			-- verso dominante no se pregunta.
			(
				select count(*) from public.esquema_metrico_opciones eo
				where eo.esquema_metrico_id = em.esquema_metrico_id
					and (
						not exists (
							select 1 from public.esquema_metrico_opciones eo2
							where eo2.esquema_metrico_id = em.esquema_metrico_id
								and eo2.rol is not null
						)
						or eo.rol = 'quebrado'
					)
			) as metros
		from public.grupos_eleccion_metrica g
		join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
		join public.formas_metricas f on f.forma_id = a.forma_id
		join public.esquemas_metricos em on em.arquitectura_id = a.arquitectura_id
		left join public.estructuras_secciones s on s.seccion_id = g.seccion_id
		where g.dimension = 'metro'
			and em.medida_uniforme is not null
	loop
		v_derivadas := case
			when v_fila.medida_uniforme then v_fila.metros
			else v_fila.posiciones * v_fila.metros
		end;

		select count(*) into v_escritas from public.opciones_eleccion_metrica
		where grupo_eleccion_id = v_fila.grupo_eleccion_id;

		if v_derivadas <> v_escritas then
			raise exception
				'La derivación no cuadra en % · %: salen % opciones y hay % escritas',
				v_fila.forma, v_fila.slug, v_derivadas, v_escritas;
		end if;
	end loop;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

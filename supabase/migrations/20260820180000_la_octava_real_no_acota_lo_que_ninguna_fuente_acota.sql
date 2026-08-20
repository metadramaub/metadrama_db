-- La octava real no acota lo que ninguna fuente acota
--
-- Se retira la restricción `numero_clases: 3` que esta misma mañana se le puso al esquema abierto
-- de la octava real. Era **una inducción mía**, y así se planteó al IP: de que el *Diccionario*
-- hable de «otra disposición de la rima de los seis primeros versos» y Jauralde del pareado
-- conservado, deduje que las clases seguirían siendo tres. Ninguna fuente lo dice, y Jauralde
-- apunta justo en contra: «recibió **variaciones de todo tipo** a lo largo del tiempo».
--
-- Con la restricción fuera, la fila de rima vuelve de «Acotado» a «Abierto», que es lo honesto:
-- de las disposiciones no catalogadas el catálogo no sabe cuántas clases emplean. Lo que sí
-- queda dicho es lo que las fuentes sí sostienen, y por las dos vías que corresponden: **qué
-- varía**, en la descripción del esquema abierto, y **qué persiste**, en el rasgo del dístico
-- final, con su frecuencia.
--
-- La descripción se reescribe además con la redacción del IP, que dice mejor las dos cosas a la
-- vez —que la rima admite otro orden y dónde—: «La rima admite otro orden, sobre todo en los seis
-- primeros versos, aunque es poco frecuente.»
--
-- Acompaña a esta migración un cambio de la tarjeta pública, que imprimía la restricción y la
-- descripción con dos tratamientos distintos como si fueran de rango distinto.

begin;

do $$
declare
	v_arq uuid;
	v_abierto uuid;
	v_ficha jsonb;
	v_n integer;

	c_descripcion constant text :=
		'La rima admite otro orden, sobre todo en los seis primeros versos, aunque es poco '
		|| 'frecuente.';
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'octava_real' and a.slug = 'endecasilabica_consonante' and a.activo;

	select esquema_rima_id into v_abierto from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'distribucion-variable';

	if v_abierto is null then
		raise exception 'La octava real no tiene su esquema de disposición variable.';
	end if;

	delete from public.esquema_rima_restricciones
	where esquema_rima_id = v_abierto and tipo = 'numero_clases';

	update public.esquemas_rima set descripcion = c_descripcion
	where esquema_rima_id = v_abierto;

	-- El esquema abierto no acota ya nada, y lo que dice lo dice su descripción.
	select count(*) into v_n
	from public.esquema_rima_restricciones where esquema_rima_id = v_abierto;
	if v_n <> 0 then
		raise exception 'El esquema abierto conserva % restricciones.', v_n;
	end if;

	v_ficha := public.get_forma_metrica_publica('octava_real');
	if not exists (
		select 1 from jsonb_array_elements(v_ficha -> 'esquemasRima') e
		where e ->> 'esquema_rima_id' = v_abierto::text and e ->> 'descripcion' = c_descripcion
	) then
		raise exception 'La ficha no trae la redacción nueva del esquema abierto.';
	end if;

	-- Y lo que persiste sigue declarado donde le toca, con su frecuencia.
	if not exists (
		select 1 from jsonb_array_elements(v_ficha -> 'arquitecturaRasgos') r
		join public.rasgos_metricos rm on rm.rasgo_id = (r ->> 'rasgo_id')::uuid
		where rm.slug = 'distico_final' and r ->> 'modalidad' = 'habitual'
	) then
		raise exception 'La octava real ha perdido el dístico final como rasgo habitual.';
	end if;
end $$;

commit;

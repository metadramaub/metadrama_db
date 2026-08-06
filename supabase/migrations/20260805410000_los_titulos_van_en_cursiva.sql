-- Los títulos de obra van en cursiva.
--
-- Las afirmaciones citan obras —La Araucana, la Teseida, el Arte poética de Rengifo— y las
-- escribían en redonda, mezcladas con el resto de la frase. La ficha interpreta Markdown
-- desde el 5 de agosto, así que `*así*` se lee ya como cursiva y no hay razón para no usarla.
--
-- Se distingue lo que es cada cosa:
--
--   · **Título de obra** → cursiva: *La Araucana*, *Soledades*, *Laurel de Apolo*.
--   · **Título de una pieza dentro de una obra** → comillas, como estaba: la canción «A la
--     flor de Gnido» es una composición dentro del cancionero de Garcilaso, no un libro.
--   · **Cita literal** → comillas: «Si de mi baja lira», «es una invitación a la palabrería».
--
-- Nueve afirmaciones, de cinco formas.

begin;

do $$
declare
	v_cambios integer := 0;
	v_n integer;
	v_par record;
begin
	for v_par in
		select * from (values
			-- quintilla
			('en su Arte poética de 1592', 'en su *Arte poética* de 1592'),
			-- lira
			('es su Canción V,', 'es su *Canción V*,'),
			-- octava real
			('modificó en su Teseida la primitiva', 'modificó en su *Teseida* la primitiva'),
			('con su poema Octava rima,', 'con su poema *Octava rima*,'),
			('el comienzo de La Araucana de Ercilla', 'el comienzo de *La Araucana* de Ercilla'),
			-- décima
			('cita el Laurel de Apolo de Lope', 'cita el *Laurel de Apolo* de Lope'),
			-- silva
			('en Don Juan de Austria en Flandes;', 'en *Don Juan de Austria en Flandes*;'),
			('la de las Soledades de Góngora', 'la de las *Soledades* de Góngora'),
			('el comienzo de La vida es sueño de Calderón', 'el comienzo de *La vida es sueño* de Calderón'),
			('con Quevedo antes de las Soledades', 'con Quevedo antes de las *Soledades*')
		) as t(viejo, nuevo)
	loop
		update public.afirmaciones_fuentes_metricas
		set resumen = replace(resumen, v_par.viejo, v_par.nuevo)
		where resumen like '%' || v_par.viejo || '%';
		get diagnostics v_n = row_count;
		if v_n = 0 then
			raise exception 'No se encontró para poner en cursiva: %', v_par.viejo;
		end if;
		v_cambios := v_cambios + v_n;
	end loop;

	raise notice 'Títulos puestos en cursiva: %', v_cambios;
end $$;

comment on column public.afirmaciones_fuentes_metricas.localizador is
	'En castellano llano, sin abreviaturas de especialista. Página donde el volumen la conserva, epígrafe numerado en Navarro Tomás, título de sección en Jauralde —que viene de un epub sin paginar— y nombre de la entrada en el Diccionario, que es alfabético. Los títulos de obra van en *cursiva*, las piezas dentro de una obra y las citas literales entre «comillas». `scripts/lib/localizar.mjs` da la página de un pasaje sobre los volcados de `docs/dominio-metrico/bibliografía/txt/`.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

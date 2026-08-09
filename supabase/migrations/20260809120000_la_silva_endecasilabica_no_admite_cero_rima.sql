-- La silva endecasilábica deja de ofrecer «ninguna» organización en pareados.
--
-- Era el único solape declarado del catálogo: `Silva · Endecasilábica` y `Endecasílabo suelto`
-- ofrecían los dos el valor `ninguna` del rasgo `organizacion_en_pareados`, de modo que una
-- serie de once versos sin pareados encajaba en las dos formas y el demarcador no podía
-- separarlas.
--
-- **El valor contradice a la fuente de la que sale la propia arquitectura.** `Silva ·
-- Endecasilábica` viene del término legado `silva_de_endecasilabos`, que copia literalmente la
-- silva 3.ª de Morley y Bruerton: «todos de 11 sílabas, la mayoría (del 50 al 98 %) rimados».
-- Ofrecer `ninguna` es admitir el 0 % de rima en una arquitectura definida por tener entre el
-- 50 y el 98 %.
--
-- Morley y Bruerton habían visto este mismo problema y lo cortaron con un número: clasifican un
-- pasaje como sueltos «cuando el porcentaje de los versos rimados es menos de 50», y advierten
-- expresamente que su silva 3.ª «se puede parecer a los sueltos o pareados de 11». Las dos
-- definiciones encajan sin hueco ni solape, y son las de la fuente especializada en el corpus
-- dramático, que es el criterio cuantificador que el proyecto quiere seguir.
--
-- Las otras fuentes acompañan. Navarro Tomás (§ 158) dice que en la silva los versos podían
-- estar rimados en su totalidad o quedar sueltos **algunos** de ellos. Quilis lleva los poemas
-- sin rima a un epígrafe aparte de versos sueltos. Caparrós 2014 llama verso suelto al caso en
-- que ninguno lleva rima, aunque lo clasifique como una clase de silva. Jauralde trata el verso
-- blanco como fenómeno de ausencia de rima, y además es moderno: no describe la silva áurea.
--
-- La única fuente que admite una silva sin rima es el Diccionario —«también se considera silva
-- la combinación de endecasílabos y heptasílabos sin rima»—, y habla de **siete y once**, no de
-- la serie solo endecasilábica que produce el conflicto. Por decisión del IP esa lectura se
-- conserva **solo en las afirmaciones de fuente**, que ya la recogen, y no se codifica como
-- opción: el catálogo no ofrecerá una silva heterométrica sin rima.
--
-- Qué cambia exactamente: la pregunta de la silva endecasilábica pasa de tres opciones
-- —ninguna, habituales, predominantes— a dos. `ninguna` queda solo en el endecasílabo suelto.
-- No se toca la arquitectura `Silva · Libre`, que nombra el extremo bajo de la escala y no
-- declara ningún grupo de elección, ni el rasgo, que conserva sus cinco grados porque los usan
-- otras formas.
--
-- No afecta a ninguna anotación: comprobado que ninguna secuencia real ni prueba del editor
-- responde hoy ese grupo de elección.

begin;

do $$
declare
	v_arq uuid;
	v_grupo uuid;
	v_n integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'silva' and a.slug = 'endecasilabica';

	select grupo_eleccion_id into v_grupo
	from public.grupos_eleccion_metrica
	where arquitectura_id = v_arq and slug = 'organizacion_en_pareados';

	if num_nonnulls(v_arq, v_grupo) <> 2 then
		raise exception 'Falta la silva endecasilábica o su pregunta de organización en pareados';
	end if;

	-- Nadie ha respondido todavía esta pregunta: retirar la opción no reescribe ninguna
	-- respuesta guardada. Si algún día lo hubiera, la migración debe detenerse.
	select count(*) into v_n
	from public.elecciones_editor_metrico e
	join public.opciones_eleccion_metrica o
		on o.opcion_eleccion_id = e.opcion_eleccion_id
	join public.rasgo_valores rv on rv.valor_id = o.valor_rasgo_id
	where o.grupo_eleccion_id = v_grupo and rv.slug = 'ninguna';
	if v_n <> 0 then
		raise exception 'Hay % respuestas guardadas con «ninguna» en la silva endecasilábica', v_n;
	end if;

	delete from public.opciones_eleccion_metrica o
	using public.rasgo_valores rv
	where o.grupo_eleccion_id = v_grupo
		and rv.valor_id = o.valor_rasgo_id
		and rv.slug = 'ninguna';

	-- La descripción de la arquitectura dice ahora por qué su rima no puede faltar.
	update public.arquitecturas_forma
	set descripcion = 'Serie de endecasílabos en la que la mayoría de los versos riman, sin orden fijo y con predominio de los dísticos. Si las rimas dejan de ser mayoritarias, el pasaje es una serie de endecasílabos sueltos y no una silva.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_arq;

	select count(*) into v_n
	from public.opciones_eleccion_metrica where grupo_eleccion_id = v_grupo;
	if v_n <> 2 then
		raise exception 'La silva endecasilábica debe ofrecer dos grados, no %', v_n;
	end if;

	-- Ninguna arquitectura de la silva puede ofrecer ya el grado «ninguna».
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	join public.rasgo_valores rv on rv.valor_id = o.valor_rasgo_id
	where f.slug = 'silva' and rv.slug = 'ninguna';
	if v_n <> 0 then
		raise exception 'La silva sigue ofreciendo el grado «ninguna» en % opción(es)', v_n;
	end if;

	-- Y el endecasílabo suelto debe conservarlo: es el reparto que esto establece.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	join public.rasgo_valores rv on rv.valor_id = o.valor_rasgo_id
	where f.slug = 'endecasilabo_suelto' and rv.slug = 'ninguna';
	if v_n <> 1 then
		raise exception 'El endecasílabo suelto debe conservar el grado «ninguna»';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

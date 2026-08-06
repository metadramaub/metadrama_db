-- Lo que el editor pregunta de la endecha real.
--
-- La forma no tenía ninguna elección declarada, y ahora hace falta por dos motivos.
--
-- 1 · **Qué disposición presenta.** Son cinco y ninguna se deriva de las otras: la asonancia
--     sostenida, los versos sueltos, la cruzada, la abrazada y la de cinco versos de sor Juana.
--     Sin la pregunta, el registrador no podría decir cuál está viendo y el demarcador
--     propondría siempre la definitoria. La dimensión es `combinacion` y no `rima` porque una
--     de las opciones cambia también el metro —cinco versos en lugar de cuatro—, y la variedad
--     es la figura que ata metro y rima; el modelo lo exige así, y es el mismo patrón que usa
--     la tipología del sexteto-lira.
--
--     Para que todas las opciones apunten a una variedad, la asonantada se declara como tal y
--     preferente. No deja de ser la rima definitoria de la arquitectura: la variedad solo la
--     hace elegible junto a las otras cuatro.
--
-- 2 · **Qué vocales asuenan.** Es serie de asonancia sostenida, igual que el romance, así que
--     hereda su misma pregunta y su mismo vocabulario de valores. Se pregunta una vez por
--     pasaje y no crea una forma distinta.
--
-- Las dos son de alcance `secuencia`: valen para el pasaje entero. Un pasaje que cambiara de
-- disposición a mitad no es una endecha real que varía, sino dos pasajes distintos, y eso lo
-- resuelve la demarcación. Por eso ninguno lleva `define_norma`, que el modelo reserva para las
-- elecciones de unidad.

begin;

do $$
declare
	v_arq uuid;
	v_grupo uuid;
	v_rima_asonantada uuid;
	v_metrico uuid;
	v_asonantada uuid;
	v_suelta uuid;
	v_cruzada uuid;
	v_abrazada uuid;
	v_sorjuana uuid;
	v_rasgo_vocales uuid;
	v_opciones integer;
begin
	select a.arquitectura_id into v_arq
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'endecha_real' and a.slug = 'heptasilabica_con_endecasilabo';

	select esquema_rima_id into v_rima_asonantada
	from public.esquemas_rima where arquitectura_id = v_arq and slug = 'asonantada';

	select esquema_metrico_id into v_metrico
	from public.esquemas_metricos where arquitectura_id = v_arq and nombre = '7-7-7-11';

	if v_rima_asonantada is null or v_metrico is null then
		raise exception 'Falta la rima asonantada o el esquema métrico 7-7-7-11';
	end if;

	-- La asonantada pasa a ser también variedad, y preferente: es la norma de la forma.
	insert into public.variedades_arquitectura
		(arquitectura_id, slug, nombre, descripcion, esquema_metrico_id, esquema_rima_id, preferente, orden, estado_revision)
	values
		(v_arq, 'asonantada', 'De asonancia sostenida',
		 'La forma corriente de la endecha real: una sola asonancia en el endecasílabo, mantenida durante todo el pasaje.',
		 v_metrico, v_rima_asonantada, true, 0, 'revisada')
	returning variedad_id into v_asonantada;

	update public.variedades_arquitectura set preferente = false
	where arquitectura_id = v_arq and slug <> 'asonantada';

	select variedad_id into v_suelta from public.variedades_arquitectura where arquitectura_id = v_arq and slug = 'suelta';
	select variedad_id into v_cruzada from public.variedades_arquitectura where arquitectura_id = v_arq and slug = 'cruzada';
	select variedad_id into v_abrazada from public.variedades_arquitectura where arquitectura_id = v_arq and slug = 'abrazada';
	select variedad_id into v_sorjuana from public.variedades_arquitectura where arquitectura_id = v_arq and slug = 'redondilla_con_endecasilabo';

	if v_suelta is null or v_cruzada is null or v_abrazada is null or v_sorjuana is null then
		raise exception 'Falta alguna de las cuatro variedades de la endecha real';
	end if;

	-- 1 · La disposición.

	insert into public.grupos_eleccion_metrica
		(arquitectura_id, seccion_id, slug, nombre, ayuda_editor, dimension, alcance,
		 tipo_control, selecciones_min, selecciones_max, define_norma, permite_aplicar_global,
		 orden, activo, estado_revision)
	values
		(v_arq, null, 'disposicion', '¿Qué disposición presenta la endecha real?',
		 'La asonancia sostenida es la forma corriente: una sola rima en el endecasílabo, mantenida durante todo el pasaje. Las demás cierran la rima dentro de cada cuarteto o prescinden de ella.',
		 'combinacion', 'secuencia', 'opciones', 1, 1, false, false, 1, true, 'revisada')
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica
		(grupo_eleccion_id, slug, nombre, descripcion, variedad_id, orden, activo)
	values
		(v_grupo, 'asonantada', 'Asonancia sostenida',
		 'Una sola asonancia en el endecasílabo de cada cuarteto, que recorre el pasaje entero. Los tres heptasílabos quedan sueltos.',
		 v_asonantada, 1, true),
		(v_grupo, 'suelta', 'Sin rima',
		 'Los cuatro versos sueltos. Es la forma con que la combinación se empleó antes de recibir rimas.',
		 v_suelta, 2, true),
		(v_grupo, 'cruzada', 'Cruzada',
		 'El segundo heptasílabo rima con el endecasílabo, y la rima no pasa al cuarteto siguiente.',
		 v_cruzada, 3, true),
		(v_grupo, 'abrazada', 'Abrazada',
		 'El endecasílabo cierra con la rima del primer heptasílabo y los dos centrales riman entre sí.',
		 v_abrazada, 4, true),
		(v_grupo, 'redondilla_con_endecasilabo', 'Redondilla con endecasílabo',
		 'Cinco versos: una redondilla heptasílaba y un endecasílabo que repite la rima del primero.',
		 v_sorjuana, 5, true);

	-- 2 · Las vocales de la asonancia, con el vocabulario del romance.
	--
	-- Una opción de rasgo solo puede ofrecerse si la arquitectura admite ese rasgo, así que hay
	-- que declararlo antes. Es `admitida` y no `definitoria`: qué vocales asuenan no cambia la
	-- forma, igual que en el romance.

	select rasgo_id into v_rasgo_vocales from public.rasgos_metricos where slug = 'vocales_asonancia';
	if v_rasgo_vocales is null then
		raise exception 'No está el rasgo «vocales_asonancia»';
	end if;

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, nota)
	values (v_arq, v_rasgo_vocales, 'admitida',
		'La realización concreta declara las vocales que asuenan en los endecasílabos, sin crear una forma distinta.')
	on conflict do nothing;

	insert into public.grupos_eleccion_metrica
		(arquitectura_id, seccion_id, slug, nombre, ayuda_editor, dimension, alcance,
		 tipo_control, selecciones_min, selecciones_max, define_norma, permite_aplicar_global,
		 orden, activo, estado_revision)
	values
		(v_arq, null, 'vocales_asonancia', '¿Qué vocales caracterizan la asonancia?',
		 'Selecciona las vocales que comparten los endecasílabos. Esta elección no crea una forma distinta de endecha real.',
		 'rasgo', 'secuencia', 'opciones', 1, 1, false, false, 2, true, 'revisada')
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica
		(grupo_eleccion_id, slug, nombre, descripcion, valor_rasgo_id, orden, activo)
	select v_grupo, o.slug, o.nombre, o.descripcion, o.valor_rasgo_id, o.orden, o.activo
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'romance' and a.slug = 'octosilabica' and g.slug = 'vocales_asonancia';

	get diagnostics v_opciones = row_count;
	if v_opciones = 0 then
		raise exception 'No se copió ninguna vocal del romance: ¿cambió su grupo de asonancia?';
	end if;

	raise notice 'Endecha real · disposición con 5 opciones y % vocales de asonancia', v_opciones;
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

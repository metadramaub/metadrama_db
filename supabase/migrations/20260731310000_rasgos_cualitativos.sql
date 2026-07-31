begin;

-- Los rasgos cualitativos dejan de ser texto libre.
--
-- Catorce literales vivían en `esquema_rima_restricciones.valor_texto`, una columna sin
-- catálogo detrás: nada podía apuntarlos, elegirlos ni contarlos. Por eso dos formas decían
-- casi lo mismo con cadenas distintas —`pareados_no_sistematicos` frente a
-- `sin_organizacion_normativa_en_pareados`— y una forma decía lo mismo dos veces
-- —`predominio_versos_sueltos` y `rima_minoritaria`—.
--
-- No eran un problema sino tres:
--
-- 1 · Duplicación. El zéjel guardaba en prosa lo que su esquema ya dice con seis posiciones
--     y un enlace. El villancico guardaba en prosa una sección que ya existe, «Enlace o
--     vuelta», colgada de un esquema de rima sin posiciones ni enlaces.
--
-- 2 · Definición repetida. `predominio_versos_sueltos`, `rima_minoritaria` y
--     `pareados_no_sistematicos` estaban en las cinco arquitecturas del endecasílabo suelto:
--     no distinguían nada y ya están en la definición de la forma. Lo que sí dicen —que los
--     versos sueltos predominan— pasa a ser una restricción tipada, que es computable.
--
-- 3 · Un rasgo transversal sin catalogar. El resto describe una sola cosa vista desde tres
--     formas: cuánto organizan los pareados la serie. Ninguna en la silva libre, ocasionales
--     en el endecasílabo suelto, habituales en la silva endecasílaba, predominantes en la
--     irregular, regulares en la silva de consonantes y en el pareado. Es una escala, y como
--     tal se cataloga.
--
-- Con ello, ocho arquitecturas que solo se distinguían por esas frases se reducen a cuatro:
-- el endecasílabo suelto pasa de cinco a una y la silva de cuatro a tres. La silva conserva
-- `consonante_regular` porque su alternancia `7-11` y su esquema `aA | bB | cC` sí son
-- contenido computable, y nunca dependió de ningún literal.

-- ---------------------------------------------------------------------------
-- 1 · El catálogo de rasgos
-- ---------------------------------------------------------------------------

insert into public.rasgos_metricos (slug, nombre, descripcion, tipo_valor, observabilidad, demarcable, estado_revision)
values
	(
		'organizacion_en_pareados', 'Organización en pareados',
		'En qué grado los pareados organizan una serie. Es la escala que separa el endecasílabo suelto de la silva y de la tirada de pareados.',
		'catalogo', 'directa', true, 'revisada'
	),
	(
		'distico_final', 'Dístico final',
		'La serie concluye con dos versos rimados entre sí.',
		'catalogo', 'directa', true, 'revisada'
	),
	(
		'encadenamiento_interior', 'Encadenamiento interior',
		'La rima final de un verso enlaza con una posición interior del siguiente.',
		'catalogo', 'especializada', false, 'revisada'
	);

insert into public.rasgo_valores (rasgo_id, slug, nombre, descripcion, orden)
select rasgo.rasgo_id, valor.slug, valor.nombre, valor.descripcion, valor.orden
from public.rasgos_metricos rasgo
cross join (values
	('ninguna', 'Ninguna', 'La serie no se organiza normativamente mediante pareados.', 1),
	('ocasionales', 'Ocasionales', 'Presenta pareados intercalados, pero no organizan la serie.', 2),
	('habituales', 'Habituales', 'Los pareados son frecuentes, aunque no obligatorios.', 3),
	('predominantes', 'Predominantes', 'Los pareados organizan predominantemente la serie.', 4),
	('regulares', 'Regulares', 'La serie se organiza sistemáticamente en pareados.', 5)
) as valor(slug, nombre, descripcion, orden)
where rasgo.slug = 'organizacion_en_pareados';

insert into public.rasgo_valores (rasgo_id, slug, nombre, descripcion, orden)
select rasgo.rasgo_id, 'presente', 'Presente',
	case rasgo.slug
		when 'distico_final' then 'La serie concluye con un dístico rimado.'
		else 'La rima final de un verso enlaza con una posición interior del siguiente.'
	end,
	1
from public.rasgos_metricos rasgo
where rasgo.slug in ('distico_final', 'encadenamiento_interior');

-- ---------------------------------------------------------------------------
-- 2 · Las duplicaciones se retiran
-- ---------------------------------------------------------------------------

-- El zéjel: su esquema `A(A) | BBBA` ya declara la mudanza monorrima y la vuelta.
delete from public.esquema_rima_restricciones
where tipo = 'otra' and valor_texto = 'mudanza_monorrima_y_vuelta_al_estribillo';

-- El villancico: la sección «Enlace o vuelta» ya existe en las dos arquitecturas. El esquema
-- que sostenía la frase no tenía posiciones ni enlaces, así que se retira entero.
delete from public.esquemas_rima
where slug = 'relacion-mudanza-estribillo'
	and arquitectura_id in (
		select arquitectura.arquitectura_id
		from public.arquitecturas_forma arquitectura
		join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
		where forma.slug = 'villancico'
	);

-- ---------------------------------------------------------------------------
-- 3 · El endecasílabo suelto: una arquitectura y tres preguntas
-- ---------------------------------------------------------------------------

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_esquema uuid;
	v_grupo uuid;
	v_organizacion uuid;
	v_distico uuid;
	v_encadenamiento uuid;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'endecasilabo_suelto';

	select rasgo_id into v_organizacion from public.rasgos_metricos where slug = 'organizacion_en_pareados';
	select rasgo_id into v_distico from public.rasgos_metricos where slug = 'distico_final';
	select rasgo_id into v_encadenamiento from public.rasgos_metricos where slug = 'encadenamiento_interior';

	select arquitectura_id into v_arq
	from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'puro_sin_distico_final';

	delete from public.arquitecturas_forma
	where forma_id = v_forma and arquitectura_id <> v_arq;

	update public.arquitecturas_forma
	set slug = 'endecasilabica',
		nombre = 'Endecasilábica',
		descripcion = 'Serie abierta de endecasílabos en la que predominan los versos sueltos. Los pareados intercalados, el dístico final y el encadenamiento interior los observa el editor.',
		principal = true,
		grado = 'canonica',
		orden = 1
	where arquitectura_id = v_arq;

	select esquema_rima_id into v_esquema
	from public.esquemas_rima where arquitectura_id = v_arq limit 1;

	-- Lo que decían `predominio_versos_sueltos` y `rima_minoritaria` es un solo hecho, y ya
	-- existe un tipo de restricción para expresarlo.
	delete from public.esquema_rima_restricciones
	where esquema_rima_id = v_esquema and tipo = 'otra';

	insert into public.esquema_rima_restricciones (esquema_rima_id, tipo, valor_texto, descripcion, obligatoria)
	values (
		v_esquema, 'versos_sueltos', 'predominantes',
		'Predominan los versos sueltos: las rimas son minoritarias en el conjunto de la serie.',
		true
	);

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, nota)
	values
		(v_arq, v_organizacion, 'admitida', 'Ninguna u ocasionales: si los pareados organizaran la serie, sería una silva o una tirada de pareados.'),
		(v_arq, v_distico, 'admitida', null),
		(v_arq, v_encadenamiento, 'admitida', null);

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
	)
	values (
		v_arq, 'organizacion_en_pareados', '¿Hay pareados intercalados?',
		'En el endecasílabo suelto los pareados nunca organizan la serie; solo pueden aparecer de forma ocasional.',
		'rasgo', 'secuencia', 'opciones', 1, 1, false, 'revisada', true, 1
	)
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica (grupo_eleccion_id, slug, nombre, descripcion, valor_rasgo_id, orden)
	select v_grupo, valor.slug, valor.nombre, valor.descripcion, valor.valor_id, valor.orden
	from public.rasgo_valores valor
	where valor.rasgo_id = v_organizacion and valor.slug in ('ninguna', 'ocasionales');

	insert into public.grupos_eleccion_metrica (
		arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
		selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
	)
	values (
		v_arq, 'rasgos_de_la_serie', '¿Presenta alguno de estos rasgos?',
		'Déjalo sin marcar cuando no caractericen la secuencia.',
		'rasgo', 'secuencia', 'opciones', 0, 2, false, 'revisada', true, 2
	)
	returning grupo_eleccion_id into v_grupo;

	insert into public.opciones_eleccion_metrica (grupo_eleccion_id, slug, nombre, descripcion, valor_rasgo_id, orden)
	select
		v_grupo,
		rasgo.slug,
		rasgo.nombre,
		valor.descripcion,
		valor.valor_id,
		case rasgo.slug when 'distico_final' then 1 else 2 end
	from public.rasgos_metricos rasgo
	join public.rasgo_valores valor on valor.rasgo_id = rasgo.rasgo_id and valor.slug = 'presente'
	where rasgo.slug in ('distico_final', 'encadenamiento_interior');
end;
$$;

-- ---------------------------------------------------------------------------
-- 4 · La silva: la escala deja de ser tres arquitecturas
-- ---------------------------------------------------------------------------

do $$
declare
	v_forma uuid;
	v_irregular uuid;
	v_libre uuid;
	v_regular uuid;
	v_endecasilabica uuid;
	v_esquema uuid;
	v_organizacion uuid;
	v_grupo uuid;
	v_arq uuid;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'silva';
	select rasgo_id into v_organizacion from public.rasgos_metricos where slug = 'organizacion_en_pareados';

	select arquitectura_id into v_irregular from public.arquitecturas_forma where forma_id = v_forma and slug = 'consonante_irregular';
	select arquitectura_id into v_libre from public.arquitecturas_forma where forma_id = v_forma and slug = 'libre';
	select arquitectura_id into v_regular from public.arquitecturas_forma where forma_id = v_forma and slug = 'consonante_regular';
	select arquitectura_id into v_endecasilabica from public.arquitecturas_forma where forma_id = v_forma and slug = 'endecasilabica';

	-- `libre` y `consonante_irregular` solo se distinguían por el grado, que ahora se
	-- pregunta. La que queda declara lo único que ambas declaraban: consonancia de orden
	-- libre sobre heptasílabos y endecasílabos.
	delete from public.arquitecturas_forma where arquitectura_id = v_libre;

	update public.arquitecturas_forma
	set nombre = 'Consonante de orden libre',
		descripcion = 'Heptasílabos y endecasílabos con rima consonante sin orden fijo. Cuánto organizan los pareados la serie lo observa el editor.',
		principal = true
	where arquitectura_id = v_irregular;

	select esquema_rima_id into v_esquema from public.esquemas_rima where arquitectura_id = v_irregular limit 1;

	update public.esquemas_rima
	set slug = 'consonante-orden-libre',
		nombre = 'Consonante de orden libre'
	where esquema_rima_id = v_esquema;

	delete from public.esquema_rima_restricciones where esquema_rima_id = v_esquema and tipo = 'otra';

	delete from public.esquema_rima_restricciones
	where tipo = 'otra'
		and esquema_rima_id in (
			select esquema_rima_id from public.esquemas_rima where arquitectura_id = v_endecasilabica
		);

	-- La regular no dependía de ningún literal: su alternancia y su esquema la declaran.
	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
	select v_regular, v_organizacion, valor.valor_id, 'definitoria',
		'La alternancia 7-11 y el esquema aA | bB | cC organizan la serie en pareados sistemáticos.'
	from public.rasgo_valores valor
	where valor.rasgo_id = v_organizacion and valor.slug = 'regulares';

	-- Las dos de orden libre preguntan el grado.
	foreach v_arq in array array[v_irregular, v_endecasilabica]
	loop
		insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, modalidad, nota)
		values (v_arq, v_organizacion, 'admitida', null);

		insert into public.grupos_eleccion_metrica (
			arquitectura_id, slug, nombre, ayuda_editor, dimension, alcance, tipo_control,
			selecciones_min, selecciones_max, permite_aplicar_global, estado_revision, activo, orden
		)
		values (
			v_arq, 'organizacion_en_pareados', '¿Cuánto organizan los pareados la serie?',
			'Si la organizan sistemáticamente, la secuencia no es una silva sino una tirada de pareados.',
			'rasgo', 'secuencia', 'opciones', 1, 1, false, 'revisada', true, 1
		)
		returning grupo_eleccion_id into v_grupo;

		insert into public.opciones_eleccion_metrica (grupo_eleccion_id, slug, nombre, descripcion, valor_rasgo_id, orden)
		select v_grupo, valor.slug, valor.nombre, valor.descripcion, valor.valor_id, valor.orden
		from public.rasgo_valores valor
		where valor.rasgo_id = v_organizacion
			and valor.slug in ('ninguna', 'habituales', 'predominantes');
	end loop;
end;
$$;

-- ---------------------------------------------------------------------------
-- 5 · El pareado cierra la escala
-- ---------------------------------------------------------------------------

insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
select arquitectura.arquitectura_id, rasgo.rasgo_id, valor.valor_id, 'definitoria',
	'Una tirada de pareados es la organización sistemática misma: es el extremo de la escala.'
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
join public.rasgos_metricos rasgo on rasgo.slug = 'organizacion_en_pareados'
join public.rasgo_valores valor on valor.rasgo_id = rasgo.rasgo_id and valor.slug = 'regulares'
where forma.slug = 'pareado';

-- ---------------------------------------------------------------------------
-- 6 · El metro observado en una desviación vuelve al catálogo de metros
-- ---------------------------------------------------------------------------
--
-- Apuntaba a `vocabularios`, el vocabulario heredado, mientras todo metro de la norma apunta
-- a `public.metros`. Una desviación que dijera «aquí hay un heptasílabo» no era comparable
-- con el heptasílabo de la norma. La tabla no tiene datos, así que el cambio es libre.

alter table public.desviaciones_editor_metrico
	drop constraint if exists desviaciones_editor_metrico_metro_observado_id_fkey;

alter table public.desviaciones_editor_metrico
	add constraint desviaciones_editor_metrico_metro_observado_id_fkey
	foreign key (metro_observado_id) references public.metros (metro_id)
	on update cascade on delete restrict;

-- ---------------------------------------------------------------------------
-- Comprobaciones
-- ---------------------------------------------------------------------------

do $$
declare
	v_literales integer;
	v_arqs integer;
begin
	select count(*) into v_literales
	from public.esquema_rima_restricciones where tipo = 'otra';
	if v_literales <> 0 then
		raise exception 'Quedan % restricciones de texto libre', v_literales;
	end if;

	select count(*) into v_arqs
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'endecasilabo_suelto';
	if v_arqs <> 1 then
		raise exception 'El endecasílabo suelto debe quedar con una arquitectura y tiene %', v_arqs;
	end if;

	select count(*) into v_arqs
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'silva';
	if v_arqs <> 3 then
		raise exception 'La silva debe quedar con tres arquitecturas y tiene %', v_arqs;
	end if;
end;
$$;

commit;

begin;

-- Las respuestas del IP, llevadas al catálogo.

-- ---------------------------------------------------------------------------
-- 1 · Las denominaciones del romance, completas y en su sitio
-- ---------------------------------------------------------------------------
--
-- «Endecha» y «Romance endecha» nombran el romance heptasílabo, no el hexasílabo: estaban en
-- las dos medidas menores. El hexasílabo se conoce como romancillo hexasílabo, y el
-- heptasílabo admite además ese mismo nombre con su medida. Y el endecasílabo tenía solo
-- «Romance real», faltándole los dos nombres por los que más se le conoce.

delete from public.denominaciones_metricas denominacion
using public.arquitecturas_forma arquitectura, public.formas_metricas forma
where arquitectura.arquitectura_id = denominacion.arquitectura_id
	and forma.forma_id = arquitectura.forma_id
	and forma.slug = 'romance'
	and arquitectura.slug = 'hexasilabico'
	and denominacion.nombre in ('Endecha', 'Romance endecha');

insert into public.denominaciones_metricas (arquitectura_id, nombre, slug_normalizado, tipo_alias, idioma)
select arquitectura.arquitectura_id, nombre.nombre, nombre.slug, 'equivalente', 'es'
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
join (values
	('hexasilabico', 'Romancillo hexasílabo', 'romancillo_hexasilabo'),
	('heptasilabico', 'Romancillo heptasílabo', 'romancillo_heptasilabo'),
	('endecasilabico', 'Romance heroico', 'romance_heroico'),
	('endecasilabico', 'Romance mayor', 'romance_mayor')
) as nombre(arquitectura, nombre, slug) on nombre.arquitectura = arquitectura.slug
where forma.slug = 'romance'
	and not exists (
		select 1 from public.denominaciones_metricas existente
		where existente.arquitectura_id = arquitectura.arquitectura_id
			and existente.nombre = nombre.nombre
	);

-- ---------------------------------------------------------------------------
-- 2 · La endecha real
-- ---------------------------------------------------------------------------
--
-- Estrofa heterométrica de cuatro versos que rompe la serie de heptasílabos introduciendo un
-- endecasílabo en el último. Conserva el régimen del romance —asonancia en los pares, impares
-- sueltos—, pero es estrofa cerrada y no serie abierta, así que es forma propia.

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_metrico uuid;
	v_rima uuid;
	v_asonante uuid;
	v_hepta uuid;
	v_endeca uuid;
begin
	select esquema.tipo_rima_id into v_asonante
	from public.esquemas_rima esquema
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = esquema.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'romance' and esquema.slug = 'asonancia-pares'
	limit 1;

	select metro_id into v_hepta from public.metros where slug = 'heptasilabo';
	select metro_id into v_endeca from public.metros where slug = 'endecasilabo';

	insert into public.formas_metricas (
		slug, nombre, definicion, nivel_estructural, tipo_registro, grado_especificacion,
		seleccionable, estado_revision, activo
	)
	values (
		'endecha_real', 'Endecha real',
		'Estrofa de cuatro versos que combina tres heptasílabos con un endecasílabo final, con asonancia en los versos pares e impares sueltos. Rompe la serie regular de heptasílabos introduciendo el verso de arte mayor al cerrar cada estrofa.',
		'estrofa', 'forma', 'especifica', true, 'revisada', true
	)
	returning forma_id into v_forma;

	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, unidad_versos_min, unidad_versos_max, estado_revision, activo, orden
	)
	values (
		v_forma, 'heptasilabica_con_endecasilabo', 'Heptasilábica con endecasílabo final',
		'Tres heptasílabos y un endecasílabo, con asonancia en los pares.',
		true, true, 'preferente', v_asonante, 4, 4, 'revisada', true, 1
	)
	returning arquitectura_id into v_arq;

	insert into public.esquemas_metricos (
		arquitectura_id, slug, nombre, ambito, tipo_secuencia, estado_revision
	)
	values (v_arq, '7-7-7-11', '7-7-7-11', 'unidad', 'secuencia', 'revisada')
	returning esquema_metrico_id into v_metrico;

	insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
	values (v_metrico, 1, v_hepta, 1), (v_metrico, 2, v_hepta, 1),
		(v_metrico, 3, v_hepta, 1), (v_metrico, 4, v_endeca, 1);

	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito, modalidad,
		tipo_secuencia, estado_revision
	)
	values (v_arq, 'asonancia-pares', 'Asonancia en los versos pares', '-a-a', v_asonante,
		'unidad', 'definitoria', 'secuencia', 'revisada')
	returning esquema_rima_id into v_rima;

	insert into public.denominaciones_metricas (forma_id, nombre, slug_normalizado, tipo_alias, idioma)
	values (v_forma, 'Cuarteto de endecha', 'cuarteto_de_endecha', 'equivalente', 'es');

	insert into public.forma_relaciones (forma_origen_id, forma_destino_id, tipo_relacion, nota, estado_revision)
	select v_forma, destino.forma_id, 'relacionada_con',
		'Conserva el régimen de rima del romance —asonancia en los pares, impares sueltos— pero es estrofa cerrada de cuatro versos, no serie abierta.',
		'revisada'
	from public.formas_metricas destino where destino.slug = 'romance';
end;
$$;

-- ---------------------------------------------------------------------------
-- 3 · El quebrado de la sextilla puede ser de cuatro o de cinco
-- ---------------------------------------------------------------------------
--
-- La posición no varía —tercero y sexto—, pero la medida sí: el quebrado es la mitad del
-- verso largo o algo semejante, y sobre octosílabo eso admite tetrasílabo y pentasílabo. Las
-- medidas menores exigirían un quebrado aún más breve; eso no se formaliza, porque lo típico
-- y lo que el corpus necesita es la sextilla de ocho con quebrado de cuatro o cinco.

insert into public.esquema_metrico_posiciones (esquema_metrico_id, posicion, metro_id, alternativa)
select posicion.esquema_metrico_id, posicion.posicion, pentasilabo.metro_id, 2
from public.esquema_metrico_posiciones posicion
join public.esquemas_metricos esquema
	on esquema.esquema_metrico_id = posicion.esquema_metrico_id
join public.arquitecturas_forma arquitectura
	on arquitectura.arquitectura_id = esquema.arquitectura_id
join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
join public.metros metro on metro.metro_id = posicion.metro_id
cross join public.metros pentasilabo
where forma.slug = 'sextilla'
	and arquitectura.slug in ('pie_quebrado', 'doble_pie_quebrado')
	and metro.silabas = 4
	and pentasilabo.slug = 'pentasilabo'
	and not exists (
		select 1 from public.esquema_metrico_posiciones alternativa
		where alternativa.esquema_metrico_id = posicion.esquema_metrico_id
			and alternativa.posicion = posicion.posicion
			and alternativa.alternativa = 2
	);

-- ---------------------------------------------------------------------------
-- 4 · La silva libre recupera su arquitectura, para poder llevar su nombre
-- ---------------------------------------------------------------------------
--
-- Se había fundido con la irregular porque solo las separaba una frase en prosa. Ahora el
-- grado de organización en pareados es un rasgo con valores catalogados, así que la
-- distinción es computable y puede vivir como arquitectura: y hace falta que viva ahí, porque
-- «Silva libre» es un nombre de la tradición y una denominación no puede apuntar al valor de
-- un rasgo.
--
-- Cada una declara su grado como rasgo definitorio en lugar de preguntarlo.

do $$
declare
	v_forma uuid;
	v_irregular uuid;
	v_libre uuid;
	v_esquema uuid;
	v_rasgo uuid;
	v_ninguna uuid;
	v_predominantes uuid;
	v_consonante uuid;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'silva';
	select arquitectura_id into v_irregular
	from public.arquitecturas_forma where forma_id = v_forma and slug = 'consonante_irregular';

	select rasgo_id into v_rasgo from public.rasgos_metricos where slug = 'organizacion_en_pareados';
	select valor_id into v_ninguna from public.rasgo_valores
	where rasgo_id = v_rasgo and slug = 'ninguna';
	select valor_id into v_predominantes from public.rasgo_valores
	where rasgo_id = v_rasgo and slug = 'predominantes';

	select tipo_rima_id into v_consonante
	from public.esquemas_rima where arquitectura_id = v_irregular limit 1;

	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, estado_revision, activo, orden
	)
	values (
		v_forma, 'libre', 'Libre',
		'Serie abierta de heptasílabos y endecasílabos con rima consonante distribuida al arbitrio del poeta, sin orden fijo y admitiendo versos sueltos. Es la silva más irregular: no se organiza en pareados y, si aparece alguno, es un caso aislado.',
		false, true, 'admitida', v_consonante, 'revisada', true, 4
	)
	returning arquitectura_id into v_libre;

	insert into public.esquemas_metricos (
		arquitectura_id, slug, nombre, ambito, tipo_secuencia, estado_revision
	)
	select v_libre, origen.slug, origen.nombre, origen.ambito, origen.tipo_secuencia, 'revisada'
	from public.esquemas_metricos origen
	where origen.arquitectura_id = v_irregular
	returning esquema_metrico_id into v_esquema;

	insert into public.esquema_metrico_opciones (esquema_metrico_id, metro_id, orden)
	select v_esquema, origen.metro_id, origen.orden
	from public.esquema_metrico_opciones origen
	join public.esquemas_metricos esquema
		on esquema.esquema_metrico_id = origen.esquema_metrico_id
	where esquema.arquitectura_id = v_irregular;

	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, tipo_rima_id, ambito, modalidad, tipo_secuencia, estado_revision
	)
	values (v_libre, 'consonante-orden-libre', 'Consonante de orden libre', v_consonante,
		'unidad', 'definitoria', 'abierta', 'revisada')
	returning esquema_rima_id into v_esquema;

	insert into public.esquema_rima_restricciones (esquema_rima_id, tipo, valor_texto, descripcion, obligatoria)
	values (v_esquema, 'versos_sueltos', 'admitidos', 'Puede contener versos sueltos.', true);

	insert into public.denominaciones_metricas (arquitectura_id, nombre, slug_normalizado, tipo_alias, idioma)
	values (v_libre, 'Silva libre', 'silva_libre', 'equivalente', 'es');

	-- El grado deja de preguntarse: cada arquitectura lo declara.
	delete from public.grupos_eleccion_metrica
	where arquitectura_id = v_irregular and slug = 'organizacion_en_pareados';

	delete from public.arquitectura_rasgos
	where arquitectura_id = v_irregular and rasgo_id = v_rasgo;

	insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
	values
		(v_irregular, v_rasgo, v_predominantes, 'definitoria', 'Los pareados organizan predominantemente la serie.'),
		(v_libre, v_rasgo, v_ninguna, 'definitoria', 'No se organiza en pareados; si aparece alguno, es un caso aislado.');
end;
$$;

-- ---------------------------------------------------------------------------
-- Comprobaciones
-- ---------------------------------------------------------------------------

do $$
declare
	v_formas integer;
	v_denominaciones integer;
	v_alternativas integer;
begin
	select count(*) into v_formas from public.formas_metricas where tipo_registro = 'forma';
	if v_formas <> 27 then
		raise exception 'Se esperaban 27 formas y hay %', v_formas;
	end if;

	select count(*) into v_denominaciones
	from public.denominaciones_metricas denominacion
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = denominacion.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'romance';
	if v_denominaciones <> 7 then
		raise exception 'El romance debe tener siete denominaciones y tiene %', v_denominaciones;
	end if;

	select count(*) into v_alternativas
	from public.esquema_metrico_posiciones where alternativa = 2;
	if v_alternativas <> 6 then
		raise exception 'Se esperaban seis quebrados alternativos y hay %', v_alternativas;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 56,
	revision = revision + 1,
	actualizado_en = now();

commit;

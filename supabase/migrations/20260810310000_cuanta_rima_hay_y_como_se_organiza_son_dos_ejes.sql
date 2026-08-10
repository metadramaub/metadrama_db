-- Cuánta rima hay y cómo se organiza son dos ejes, no uno.
--
-- Último pendiente de modelo salido de las lecturas transversales. `organizacion_en_pareados`
-- graduaba *ninguna · ocasionales · habituales · predominantes · regulares* y se usaba para decir
-- dos cosas distintas:
--
--   En la **silva libre**, `ninguna` significa «los versos riman, pero no en pareados» —lo dice su
--   propia descripción: «si aparece alguno, es un caso aislado»—.
--   En el **endecasílabo suelto**, `ninguna` convive con `versos_sueltos = predominantes`, o sea
--   «casi no hay rima que organizar».
--
-- Misma palabra, dos magnitudes. Y la consecuencia es que **la frontera entre la silva y el
-- endecasílabo suelto estaba expresada en el eje equivocado**: no se distinguen por los pareados,
-- se distinguen por cuánta rima hay. Los pareados son la forma que esa rima toma en el teatro.
--
-- LAS FUENTES LOS SEPARAN. Morley y Bruerton ponen número y siempre a lo mismo: al endecasílabo
-- suelto «lo cuentan como suelto cuando el porcentaje de los versos **rimados** es menor del
-- 50 %», y a la silva de endecasílabos «del **50 al 98 % rimados** y en su mayor parte dísticos».
-- Jauralde gradúa solo el primer eje, distinguiendo «la desaparición **sistemática** de la rima
-- —verso blanco— de la **esporádica** —verso suelto—». Y Navarro Tomás cuenta el proceso con los
-- dos separados: «desde 1588 Lope intercaló pareados en los pasajes escritos en endecasílabos y
-- heptasílabos **sueltos**… La silva dramática nace de rimar un pasaje que antes iba suelto».
--
-- SE DECLARA SOLO DONDE LA NORMA DEJA EL REPARTO ABIERTO. En el romance o la quintilla el esquema
-- ya dice qué posiciones quedan sueltas, así que la densidad se calcula y no se guarda: el
-- catálogo no guarda lo que puede calcular. Quedan cinco arquitecturas, las de la familia de la
-- silva y el endecasílabo suelto, que es donde vivía el problema. La silva consonante regular
-- queda fuera por eso mismo: su esquema aA | bB | cC rima todos los versos, y una guarda lo
-- comprobó al primer intento de declararla.
--
-- Y LOS DOS RANGOS QUEDAN DISJUNTOS: el endecasílabo suelto admite `ninguna` y `esporádica`; la
-- silva, `mayoritaria` y `total`. Esa es exactamente la línea del 50 % de M&B, y ahora una guarda
-- la sostiene.

begin;

-- ---------------------------------------------------------------------------
-- 1 · El eje que faltaba
-- ---------------------------------------------------------------------------

insert into public.rasgos_metricos
	(slug, nombre, descripcion, tipo_valor, observabilidad, demarcable, pregunta, estado_revision)
values (
	'densidad_de_rima',
	'Densidad de rima',
	'Cuántos versos de la serie riman, frente a los que quedan sueltos. Es independiente de cómo se organice la rima que haya: una silva libre rima casi todo sin formar pareados, y un endecasílabo suelto con algún dístico intercalado forma pareados sin apenas rimar.',
	'catalogo', 'directa', true,
	'¿Cuántos versos riman?',
	'revisada'
)
on conflict (slug) do nothing;

insert into public.rasgo_valores (rasgo_id, slug, nombre, descripcion, orden)
select r.rasgo_id, v.slug, v.nombre, v.descripcion, v.orden
from public.rasgos_metricos r
cross join (values
	('ninguna', 'Ninguna', 'Ningún verso rima: es el verso blanco de Jauralde, la desaparición sistemática de la rima.', 1),
	('esporadica', 'Esporádica', 'Rima menos de la mitad de los versos. Morley y Bruerton cuentan un pasaje como suelto por debajo de ese umbral.', 2),
	('mayoritaria', 'Mayoritaria', 'Rima más de la mitad, pero no todos. Es el tramo del 50 al 98 % en que Morley y Bruerton sitúan la silva de endecasílabos.', 3),
	('total', 'Total', 'Riman todos los versos de la serie.', 4)
) as v(slug, nombre, descripcion, orden)
where r.slug = 'densidad_de_rima'
	and not exists (
		select 1 from public.rasgo_valores rv
		where rv.rasgo_id = r.rasgo_id and rv.slug = v.slug
	);

-- ---------------------------------------------------------------------------
-- 2 · Qué admite cada arquitectura
-- ---------------------------------------------------------------------------

insert into public.arquitectura_rasgos (arquitectura_id, rasgo_id, valor_id, modalidad, nota)
select a.arquitectura_id, r.rasgo_id, rv.valor_id, v.modalidad, v.nota
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
join public.rasgos_metricos r on r.slug = 'densidad_de_rima'
join lateral (values
	-- El endecasílabo suelto, por debajo del umbral de M&B. Las fuentes discrepan sobre si
	-- admite alguna rima: el Diccionario dice que no rima ninguno y M&B lo cuentan suelto hasta
	-- el 50 %, así que se declaran los dos y el editor dice cuál vio.
	('endecasilabo_suelto', 'endecasilabica', 'ninguna', 'definitoria',
		'Jauralde llama verso blanco a la desaparición sistemática de la rima.'),
	('endecasilabo_suelto', 'endecasilabica', 'esporadica', 'admitida',
		'Morley y Bruerton cuentan el pasaje como suelto mientras los versos rimados no lleguen a la mitad, y observan que Lope intercalaba dísticos con frecuencia creciente.'),
	-- Y la silva, por encima. Ninguna de sus cuatro baja del umbral: si bajara, sería un pasaje
	-- suelto con rimas, que es de donde la silva dramática nació.
	('silva', 'endecasilabica', 'mayoritaria', 'definitoria',
		'Morley y Bruerton la sitúan entre el 50 y el 98 % de versos rimados.'),
	('silva', 'consonante_irregular', 'mayoritaria', 'admitida', null),
	('silva', 'consonante_irregular', 'total', 'admitida', null),
	('silva', 'libre', 'mayoritaria', 'admitida', null),
	('silva', 'libre', 'total', 'admitida', null)
) as v(forma, arq, valor, modalidad, nota) on v.forma = f.slug and v.arq = a.slug
join public.rasgo_valores rv on rv.rasgo_id = r.rasgo_id and rv.slug = v.valor
where not exists (
	select 1 from public.arquitectura_rasgos ar
	where ar.arquitectura_id = a.arquitectura_id and ar.rasgo_id = r.rasgo_id
		and ar.valor_id = rv.valor_id
);

-- ---------------------------------------------------------------------------
-- 3 · Se pregunta donde hay más de un valor admitido
-- ---------------------------------------------------------------------------

insert into public.grupos_eleccion_metrica
	(arquitectura_id, slug, ayuda_editor, dimension, tipo_control, alcance, rasgo_id,
	 selecciones_min, selecciones_max, permite_aplicar_global, define_norma, estado_revision, orden)
select a.arquitectura_id, 'densidad_de_rima', v.ayuda, 'rasgo', 'opciones', 'secuencia',
	r.rasgo_id, 1, 1, false, false, 'revisada', 90
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
join public.rasgos_metricos r on r.slug = 'densidad_de_rima'
join lateral (values
	('endecasilabo_suelto', 'endecasilabica',
		'Si llegara a rimar más de la mitad de los versos, el pasaje ya no sería suelto sino una silva.'),
	('silva', 'consonante_irregular', null),
	('silva', 'libre', null)
) as v(forma, arq, ayuda) on v.forma = f.slug and v.arq = a.slug
where not exists (
	select 1 from public.grupos_eleccion_metrica g
	where g.arquitectura_id = a.arquitectura_id and g.rasgo_id = r.rasgo_id
);

-- ---------------------------------------------------------------------------
-- 4 · Y el eje viejo deja de cargar con lo que no era suyo
-- ---------------------------------------------------------------------------

update public.rasgos_metricos
set descripcion = 'Cómo se organiza la rima que hay: si los versos rimados forman pareados y con cuánta sistematicidad. No dice cuántos versos riman —eso es la densidad de rima—, sino qué figura dibujan los que lo hacen.',
	pregunta = '¿Cuánto organizan los pareados la serie?',
	updated_at = now()
where slug = 'organizacion_en_pareados';

update public.arquitectura_rasgos ar
set nota = 'Los dísticos que Lope intercalaba desde 1588 no convierten el pasaje en silva: lo que lo convertiría es que rimara más de la mitad de los versos.'
from public.rasgos_metricos r, public.rasgo_valores rv,
	public.arquitecturas_forma a, public.formas_metricas f
where ar.rasgo_id = r.rasgo_id and ar.valor_id = rv.valor_id
	and ar.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and r.slug = 'organizacion_en_pareados' and rv.slug = 'ocasionales'
	and f.slug = 'endecasilabo_suelto';

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
	v_mal text;
begin
	-- Lo que sostiene todo: los rangos son disjuntos. Si una silva admitiera `esporadica` o el
	-- endecasílabo suelto `mayoritaria`, la frontera del 50 % dejaría de separarlos.
	select count(*), string_agg(f.slug || '·' || a.slug || '=' || rv.slug, ', ') into v_n, v_mal
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos r on r.rasgo_id = ar.rasgo_id
	join public.rasgo_valores rv on rv.valor_id = ar.valor_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where r.slug = 'densidad_de_rima'
		and (
			(f.slug = 'silva' and rv.slug in ('ninguna', 'esporadica'))
			or (f.slug = 'endecasilabo_suelto' and rv.slug in ('mayoritaria', 'total'))
		);
	if v_n <> 0 then
		raise exception 'La silva y el endecasílabo suelto se solapan en densidad: %', v_mal;
	end if;

	-- Solo se declara donde la norma deja el reparto abierto: donde el esquema dice qué
	-- posiciones quedan sueltas, la densidad se calcula.
	select count(*) into v_n
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos r on r.rasgo_id = ar.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = ar.arquitectura_id
	where r.slug = 'densidad_de_rima'
		and not exists (
			select 1 from public.esquemas_rima er
			where er.arquitectura_id = a.arquitectura_id and er.tipo_secuencia = 'abierta'
		);
	if v_n <> 0 then
		raise exception '% arquitecturas declaran densidad teniendo su rima fijada por posiciones', v_n;
	end if;

	-- Cuatro arquitecturas: las tres silvas de rima abierta y el endecasílabo suelto.
	select count(distinct ar.arquitectura_id) into v_n
	from public.arquitectura_rasgos ar
	join public.rasgos_metricos r on r.rasgo_id = ar.rasgo_id
	where r.slug = 'densidad_de_rima';
	if v_n <> 4 then
		raise exception '% arquitecturas declaran densidad en vez de 4', v_n;
	end if;

	-- Tres preguntas, las de las arquitecturas que admiten más de un valor. Y ninguna donde el
	-- valor es único: eso se deriva.
	select count(*) into v_n
	from public.grupos_eleccion_metrica g
	join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
	where r.slug = 'densidad_de_rima';
	if v_n <> 3 then
		raise exception 'Hay % preguntas de densidad en vez de 3', v_n;
	end if;

	select count(*), string_agg(a.slug, ', ') into v_n, v_mal
	from public.grupos_eleccion_metrica g
	join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	where r.slug = 'densidad_de_rima'
		and (
			select count(*) from public.arquitectura_rasgos ar
			where ar.arquitectura_id = g.arquitectura_id and ar.rasgo_id = g.rasgo_id
		) < 2;
	if v_n <> 0 then
		raise exception '% preguntas de densidad no ofrecen alternativa: %', v_n, v_mal;
	end if;

	-- El editor las ve ya redactadas desde el rasgo.
	select nombre into v_mal
	from public.grupos_eleccion_metrica_resueltos where slug = 'densidad_de_rima' limit 1;
	if v_mal <> '¿Cuántos versos riman?' then
		raise exception 'La pregunta de densidad se enuncia «%»', v_mal;
	end if;

	-- Y las opciones suben en seis: dos por cada una de las tres preguntas.
	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 411 then
		raise exception 'Las opciones son % en vez de 411', v_n;
	end if;

	select count(*) into v_n from public.propuesta_elecciones_secuencia;
	if v_n <> 91 then
		raise exception 'Las respuestas propuestas dejaron de ser 91 y son %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

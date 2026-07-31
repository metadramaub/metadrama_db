begin;

-- Nomenclatura del catálogo: una convención para todos.
--
-- Las arquitecturas y los esquemas se fueron creando forma por forma, cada uno con el
-- criterio del momento. El resultado eran once maneras distintas de nombrar lo mismo —«R1 ·
-- ababcc», «Tipología 1 (ababa)», «Esquema fijo abbaaccddc», «ABBAACCA», «Cruzada»,
-- «Quintilla ababa», «Patrón principal»…— y ningún identificador estable para los esquemas,
-- que no tenían slug.
--
-- La regla que gobierna todo lo que sigue: **un nombre dice solo lo que su contexto no dice
-- ya**. La interfaz muestra siempre la arquitectura dentro de su forma y el esquema dentro
-- de su arquitectura; la unidad declarada ya dice la extensión y la notación ya dice la
-- disposición. Repetirlos alarga sin distinguir.
--
-- Los UUID no se tocan: son aleatorios a propósito y ninguno lleva información dentro.

-- ---------------------------------------------------------------------------
-- Vocabulario auxiliar para derivar los nombres
-- ---------------------------------------------------------------------------

create temporary table palabra_metro (
	silabas integer primary key,
	singular text not null,
	plural text not null
) on commit drop;

insert into palabra_metro (silabas, singular, plural) values
	(4, 'tetrasílabo', 'tetrasílabos'),
	(5, 'pentasílabo', 'pentasílabos'),
	(6, 'hexasílabo', 'hexasílabos'),
	(7, 'heptasílabo', 'heptasílabos'),
	(8, 'octosílabo', 'octosílabos'),
	(11, 'endecasílabo', 'endecasílabos'),
	(12, 'dodecasílabo', 'dodecasílabos'),
	(14, 'alejandrino', 'alejandrinos');

create temporary table numeral (n integer primary key, palabra text not null) on commit drop;

insert into numeral (n, palabra) values
	(1, 'Un'), (2, 'Dos'), (3, 'Tres'), (4, 'Cuatro'), (5, 'Cinco'), (6, 'Seis'),
	(7, 'Siete'), (8, 'Ocho'), (9, 'Nueve'), (10, 'Diez'), (11, 'Once'), (12, 'Doce'),
	(13, 'Trece'), (14, 'Catorce');

-- ---------------------------------------------------------------------------
-- 1 · El esquema métrico recibe slug y un nombre derivado de sus medidas
--
-- slug: la secuencia literal. `8-8-8-8-8`, `7-11-7-7-11`, `11-repetido`, `conjunto-7-11`.
-- nombre: la medida cuando es única, la secuencia cuando no lo es, el ciclo cuando se
-- repite y el conjunto cuando está abierto.
-- ---------------------------------------------------------------------------

alter table public.esquemas_metricos add column slug text;

-- Dos esquemas del pareado se declaran `secuencia_repetible` pero guardan su medida como
-- conjunto de opciones, sin ninguna posición. Es una incoherencia del dato, no de la regla:
-- el tipo efectivo se deduce de dónde están realmente las medidas.
create temporary table medida_esquema on commit drop as
select
	esquema.esquema_metrico_id,
	esquema.nombre as nombre_actual,
	case
		when esquema.tipo <> 'conjunto_permitido'
			and not exists (
				select 1 from public.esquema_metrico_posiciones posicion
				where posicion.esquema_metrico_id = esquema.esquema_metrico_id
			)
			then 'conjunto_permitido'
		else esquema.tipo
	end as tipo,
	(
		select array_agg(metro.silabas order by posicion.posicion)
		from public.esquema_metrico_posiciones posicion
		join public.metros metro on metro.metro_id = posicion.metro_id
		where posicion.esquema_metrico_id = esquema.esquema_metrico_id
	) as secuencia,
	(
		select array_agg(distinct metro.silabas order by metro.silabas)
		from public.esquema_metrico_opciones opcion
		join public.metros metro on metro.metro_id = opcion.metro_id
		where opcion.esquema_metrico_id = esquema.esquema_metrico_id
	) as conjunto
from public.esquemas_metricos esquema;

update public.esquemas_metricos esquema
set slug = case
		when medida.tipo = 'conjunto_permitido'
			then 'conjunto-' || array_to_string(medida.conjunto, '-')
		when medida.tipo = 'secuencia_repetible'
			then array_to_string(medida.secuencia, '-') || '-repetido'
		else array_to_string(medida.secuencia, '-')
	end
from medida_esquema medida
where medida.esquema_metrico_id = esquema.esquema_metrico_id;

update public.esquemas_metricos esquema
set nombre = derivado.nombre
from (
	select
		medida.esquema_metrico_id,
		case
			-- El sexteto-lira rotula sus esquemas M1…M5 y R1…R3, y sus siete variedades se
			-- nombran componiendo esos rótulos. El rótulo dice algo que la secuencia no dice.
			when medida.nombre_actual ~ '^[A-Z][0-9]+ · ' then
				split_part(medida.nombre_actual, ' · ', 1)
			when medida.tipo = 'conjunto_permitido' and cardinality(medida.conjunto) = 2 then
				upper(left(palabra_1.singular, 1)) || substr(palabra_1.singular, 2)
					|| case when left(palabra_2.singular, 1) = 'o' then ' u ' else ' o ' end
					|| palabra_2.singular
			when medida.tipo = 'conjunto_permitido' and cardinality(medida.conjunto) = 3 then
				upper(left(palabra_1.singular, 1)) || substr(palabra_1.singular, 2)
					|| ', ' || palabra_2.singular
					|| case when left(palabra_3.singular, 1) = 'o' then ' u ' else ' o ' end
					|| palabra_3.singular
			when medida.tipo = 'conjunto_permitido' then
				'De ' || medida.conjunto[1] || ' a '
					|| medida.conjunto[cardinality(medida.conjunto)] || ' sílabas'
			when medida.tipo = 'secuencia_repetible' and cardinality(medida.secuencia) = 1 then
				upper(left(inicial.singular, 1)) || substr(inicial.singular, 2) || ' repetido'
			when medida.tipo = 'secuencia_repetible' then
				array_to_string(medida.secuencia, '-') || ' repetido'
			when medida.distintas = 1 then
				numeral.palabra || ' ' || inicial.plural
			else array_to_string(medida.secuencia, '-')
		end as nombre
	from (
		select
			medida_esquema.*,
			(
				select count(distinct valor)
				from unnest(medida_esquema.secuencia) as valor
			) as distintas
		from medida_esquema
	) medida
	left join palabra_metro inicial on inicial.silabas = medida.secuencia[1]
	left join numeral on numeral.n = cardinality(medida.secuencia)
	left join palabra_metro palabra_1 on palabra_1.silabas = medida.conjunto[1]
	left join palabra_metro palabra_2 on palabra_2.silabas = medida.conjunto[2]
	left join palabra_metro palabra_3 on palabra_3.silabas = medida.conjunto[3]
) derivado
where derivado.esquema_metrico_id = esquema.esquema_metrico_id;

alter table public.esquemas_metricos
	alter column slug set not null,
	add constraint esquemas_metricos_slug_check check (slug = btrim(slug) and slug <> ''),
	add constraint esquemas_metricos_arquitectura_id_slug_key unique (arquitectura_id, slug);

comment on column public.esquemas_metricos.slug is
	'Identificador legible y estable: la secuencia literal de medidas. Único dentro de su arquitectura.';

-- ---------------------------------------------------------------------------
-- 2 · El esquema de rima recibe slug, y su nombre deja de repetir la notación
-- ---------------------------------------------------------------------------

alter table public.esquemas_rima add column slug text;

update public.esquemas_rima
set slug = lower(notacion)
where notacion ~ '^[A-Za-z-]+$';

update public.esquemas_rima
set slug = 'abcabc-defdef'
where notacion = 'abcabc:defdef';

-- Los que no tienen una notación computable llevan un slug descriptivo.
create temporary table slug_descriptivo (nombre text primary key, slug text not null) on commit drop;

insert into slug_descriptivo (nombre, slug) values
	('Cuerpo sin rima', 'cuerpo-sin-rima'),
	('Esquema consonante repetido entre estancias', 'consonante-repetido'),
	('Distribución variable', 'distribucion-variable'),
	('Distribución consonante variable', 'consonante-variable'),
	('Otro esquema regular', 'regular-distinto-de-abcabc-defdef'),
	('Predominio de versos sueltos', 'versos-sueltos'),
	('Predominio de versos sueltos con encadenamiento interior', 'versos-sueltos-encadenados'),
	('Predominio de rima consonante con pareados no sistemáticos', 'consonante-con-pareados-no-sistematicos'),
	('Pareados consonantes sistemáticos', 'pareados-sistematicos'),
	('Pareados consonantes regulares', 'pareados-regulares'),
	('Pareados consonantes predominantes', 'pareados-predominantes'),
	('Rima libre sin organización en pareados', 'libre-sin-pareados'),
	('Asonancia en los versos pares', 'asonancia-pares'),
	('Encadenamiento consonante con cierre en serventesio', 'encadenado-con-serventesio'),
	('Primer verso suelto', 'primer-verso-suelto'),
	('Verso central suelto', 'verso-central-suelto'),
	('Relación entre mudanza, enlace o vuelta y estribillo', 'relacion-mudanza-estribillo'),
	('Estribillo, mudanza monorrima y vuelta', 'estribillo-mudanza-vuelta'),
	-- El pareado no declara nada: es el defecto D2 y su norma la decide el IP.
	('Patrón principal', 'sin-declarar');

update public.esquemas_rima rima
set slug = slug_descriptivo.slug
from slug_descriptivo
where rima.nombre = slug_descriptivo.nombre
	and rima.slug is null;

-- El nombre no repite lo que la notación ya dice.
update public.esquemas_rima
set nombre = null
where notacion is not null
	and (lower(nombre) = lower(notacion) or lower(nombre) = lower('Esquema fijo ' || notacion));

update public.esquemas_rima
set nombre = btrim(replace(nombre, '(' || notacion || ')', ''))
where notacion is not null
	and nombre like '%(' || notacion || ')';

update public.esquemas_rima
set nombre = null
where nombre = 'Patrón principal';

-- Los rótulos R1…R3 del sexteto-lira se conservan por la misma razón que M1…M5.
update public.esquemas_rima
set nombre = split_part(nombre, ' · ', 1)
where notacion is not null
	and nombre like '% · ' || notacion;

alter table public.esquemas_rima
	alter column slug set not null,
	add constraint esquemas_rima_slug_check check (slug = btrim(slug) and slug <> ''),
	add constraint esquemas_rima_arquitectura_id_slug_key unique (arquitectura_id, slug);

comment on column public.esquemas_rima.slug is
	'Identificador legible y estable: la notación en minúsculas, o una etiqueta descriptiva cuando la notación no es computable. Único dentro de su arquitectura.';
comment on column public.esquemas_rima.nombre is
	'Nombre tradicional o analítico. Nulo cuando la notación ya lo dice todo: la interfaz cae en ella.';

-- ---------------------------------------------------------------------------
-- 3 · La arquitectura deja de repetir la forma, la extensión y la notación
-- ---------------------------------------------------------------------------

create temporary table nomenclatura_arquitectura (
	forma text,
	slug_actual text,
	slug_nuevo text,
	nombre_nuevo text
) on commit drop;

insert into nomenclatura_arquitectura (forma, slug_actual, slug_nuevo, nombre_nuevo) values
	('cancion_petrarquista', 'cuerpo_sin_rima_pareado_final', 'sin_rima_con_pareado_final', 'Sin rima, con pareado final'),
	('cancion_petrarquista', 'estancias_consonantes_variables', 'estancias_consonantes_variables', 'Estancias consonantes variables'),
	('cancion_petrarquista', 'regular_13_abCabC_cdeeDfF', 'regular_13_versos', 'Regular de 13 versos'),
	('copla_de_arte_mayor', 'ocho_dodecasilabos_compuestos', 'dodecasilabica_compuesta', 'Dodecasilábica compuesta'),
	('copla_de_pie_quebrado', 'variable_5_12', 'octosilabica_con_quebrados', 'Octosilábica con quebrados'),
	('copla_manriqueña', 'dos_sextillas_abcabc_defdef', 'dos_sextillas', 'Dos sextillas'),
	('copla_real', 'con_pie_quebrado', 'con_pie_quebrado', 'Con pie quebrado'),
	('copla_real', 'sin_pie_quebrado', 'sin_pie_quebrado', 'Sin pie quebrado'),
	('decima_aumentada', 'octosilabica_abbaaccddeed', 'octosilabica', 'Octosilábica'),
	('decima_espinela', 'octosilabica_abbaaccddc', 'octosilabica', 'Octosilábica'),
	('doble_sextilla', 'otro_esquema_regular', 'otro_esquema_regular', 'Otro esquema regular'),
	('endecasilabo_suelto', 'con_pareados_sin_distico_final', 'con_pareados_sin_distico_final', 'Con pareados, sin dístico final'),
	('endecasilabo_suelto', 'con_pareados_y_distico_final', 'con_pareados_con_distico_final', 'Con pareados y dístico final'),
	('endecasilabo_suelto', 'encadenado_interior', 'encadenado_interior', 'Encadenado interior'),
	('endecasilabo_suelto', 'puro_con_distico_final', 'puro_con_distico_final', 'Puro, con dístico final'),
	('endecasilabo_suelto', 'puro_sin_distico_final', 'puro_sin_distico_final', 'Puro, sin dístico final'),
	('lira', 'heptasilabica_endecasilabica_consonante', 'heptasilabica_endecasilabica', 'Heptasilábica y endecasilábica'),
	('novena', 'quintilla_redondilla', 'quintilla_redondilla', 'Quintilla + redondilla'),
	('novena', 'redondilla_quintilla', 'redondilla_quintilla', 'Redondilla + quintilla'),
	('octava_real', 'endecasilabica_consonante', 'endecasilabica_consonante', 'Endecasilábica consonante'),
	('pareado', 'pareado_de_arte_menor', 'arte_menor', 'De arte menor'),
	('pareado', 'pareado_hexasilabo', 'hexasilabico', 'Hexasilábico'),
	('pareado', 'pareado_octosilabo', 'octosilabico', 'Octosilábico'),
	('pareados_endecasilabos', 'endecasilabicos_consonantes', 'endecasilabicos_consonantes', 'Endecasílabos consonantes'),
	('quintilla', 'octosilabica_consonante', 'octosilabica_consonante', 'Octosilábica consonante'),
	('redondilla', 'doble_enlazada', 'doble_enlazada', 'Doble enlazada'),
	('redondilla', 'simple', 'simple', 'Simple'),
	('romance', 'endecasilabico_heroico', 'endecasilabico', 'Endecasílabo'),
	('romance', 'heptasilabico_romancillo', 'heptasilabico', 'Heptasílabo'),
	('romance', 'hexasilabico_romancillo', 'hexasilabico', 'Hexasílabo'),
	('romance', 'octosilabico_asonante', 'octosilabico', 'Octosílabo'),
	('seguidilla', 'compuesta_7575575_asonante', 'compuesta', 'Compuesta'),
	('seguidilla', 'simple_7575_asonante', 'simple', 'Simple'),
	('sexta_rima', 'endecasilabica_consonante', 'endecasilabica_consonante', 'Endecasilábica consonante'),
	('sexteto', 'arte_mayor_consonante_variable', 'arte_mayor_consonante_variable', 'De arte mayor, consonante variable'),
	('sexteto_lira', 'heterometrica_consonante', 'heterometrica_consonante', 'Heterométrica consonante'),
	('sextilla', 'isometrica', 'isometrica', 'Isométrica'),
	('sextilla', 'pie_quebrado_884884', 'pie_quebrado', 'De pie quebrado'),
	('sextina', 'clasica_6x6_mas_3', 'clasica', 'Clásica'),
	('sextina', 'doble_12x6_mas_3', 'doble', 'Doble'),
	('silva', 'consonantes_irregular', 'consonante_irregular', 'Consonante irregular'),
	('silva', 'consonantes_regular', 'consonante_regular', 'Consonante regular'),
	('silva', 'endecasilabica', 'endecasilabica', 'Endecasilábica'),
	('silva', 'libre', 'libre', 'Libre'),
	('soneto', 'endecasilabo_consonante', 'endecasilabico_consonante', 'Endecasilábico consonante'),
	('terceto', 'endecasilabico_consonante', 'endecasilabico_consonante', 'Endecasilábico consonante'),
	('terceto_encadenado', 'endecasilabico_consonante', 'endecasilabico_consonante', 'Endecasilábico consonante'),
	('terceto_encadenado', 'octosilabico', 'octosilabico', 'Octosilábico'),
	('tercetos_sin_encadenar', 'endecasilabico_consonante', 'endecasilabicos_consonantes', 'Endecasílabos consonantes'),
	('villancico', 'estribillo_inicial', 'estribillo_inicial', 'Estribillo inicial'),
	('villancico', 'estribillo_tras_primera_copla', 'estribillo_tras_primera_copla', 'Estribillo tras la primera copla'),
	('zejel', 'estribillo_y_coplas_monorrimas', 'estribillo_y_coplas_monorrimas', 'Estribillo y coplas monorrimas');

update public.arquitecturas_forma arquitectura
set slug = nomenclatura.slug_nuevo,
	nombre = nomenclatura.nombre_nuevo
from nomenclatura_arquitectura nomenclatura, public.formas_metricas forma
where forma.forma_id = arquitectura.forma_id
	and forma.slug = nomenclatura.forma
	and arquitectura.slug = nomenclatura.slug_actual;

-- ---------------------------------------------------------------------------
-- Comprobaciones
-- ---------------------------------------------------------------------------

do $$
declare
	v_pendientes integer;
begin
	select count(*) into v_pendientes
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where forma.slug <> 'pareado' or arquitectura.slug <> 'principal';
	if v_pendientes <> 52 then
		raise exception 'Se esperaban 52 arquitecturas renombradas y hay %', v_pendientes;
	end if;

	select count(*) into v_pendientes from public.esquemas_metricos where slug is null;
	if v_pendientes > 0 then
		raise exception '% esquemas métricos se quedaron sin slug', v_pendientes;
	end if;
	select count(*) into v_pendientes from public.esquemas_rima where slug is null;
	if v_pendientes > 0 then
		raise exception '% esquemas de rima se quedaron sin slug', v_pendientes;
	end if;

	-- Ningún nombre de arquitectura debe empezar por el nombre de su forma.
	select count(*) into v_pendientes
	from public.arquitecturas_forma arquitectura
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where lower(arquitectura.nombre) like lower(forma.nombre) || ' %';
	if v_pendientes > 0 then
		raise exception '% nombres de arquitectura siguen repitiendo su forma', v_pendientes;
	end if;

	-- Ningún nombre de esquema de rima debe repetir su notación.
	select count(*) into v_pendientes
	from public.esquemas_rima
	where notacion is not null
		and nombre is not null
		and lower(nombre) like '%' || lower(notacion) || '%';
	if v_pendientes > 0 then
		raise exception '% nombres de esquema de rima siguen repitiendo su notación', v_pendientes;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set modelo_version = 50,
	actualizado_en = now()
where id = true;

commit;

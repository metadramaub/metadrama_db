-- La seguidilla no se agota en las arquitecturas simple y compuesta.
--
-- Las seis fuentes autorizadas la tratan. Coinciden en el núcleo de versos largos y cortos,
-- pero documentan varias construcciones estables que deben poder registrarse sin convertirlas
-- en desviaciones: la estrofa de tres versos, la chamberga, la gitana y la real. La fluctuación
-- histórica de la simple y las series arromanzadas quedan documentadas en las afirmaciones;
-- su formalización se resolverá en la revisión transversal de los casos abiertos.
--
-- La revisión de los usos legados descubre además un defecto general de la equivalencia. Cuando
-- un término reclamaba una forma pero no una arquitectura, la vista elegía siempre la principal,
-- aunque la extensión fuese imposible. Ahora elige entre las arquitecturas compatibles con la
-- longitud. La ausencia de regla derivada significa longitud abierta, no incompatibilidad. Si no
-- hay ninguna candidata, conserva la forma, deja la arquitectura sin proponer y explica la duda.

begin;

do $$
declare
	v_forma uuid;
	v_simple uuid;
	v_compuesta uuid;
	v_tres uuid;
	v_chamberga uuid;
	v_gitana uuid;
	v_real uuid;
	v_esquema uuid;
	v_rima uuid;
	v_m3 uuid;
	v_m5 uuid;
	v_m6 uuid;
	v_m7 uuid;
	v_m10 uuid;
	v_m11 uuid;
	v_m12 uuid;
	v_asonante uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'seguidilla';
	select arquitectura_id into v_simple from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'simple';
	select arquitectura_id into v_compuesta from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'compuesta';

	-- El catálogo aún no necesitaba estos dos metros como entidades propias.
	insert into public.metros (
		slug, nombre, silabas, tipo, descripcion, estado_revision, activo, orden
	)
	values
		('trisilabo', 'Trisílabo', 3, 'simple', 'Verso de tres sílabas métricas.',
		 'revisada', true, 3),
		('decasilabo', 'Decasílabo', 10, 'simple', 'Verso de diez sílabas métricas.',
		 'revisada', true, 10)
	on conflict (slug) do update
	set nombre = excluded.nombre,
		silabas = excluded.silabas,
		tipo = excluded.tipo,
		descripcion = excluded.descripcion,
		estado_revision = excluded.estado_revision,
		activo = true,
		updated_at = now();

	select metro_id into v_m3 from public.metros where slug = 'trisilabo';
	select metro_id into v_m5 from public.metros where slug = 'pentasilabo';
	select metro_id into v_m6 from public.metros where slug = 'hexasilabo';
	select metro_id into v_m7 from public.metros where slug = 'heptasilabo';
	select metro_id into v_m10 from public.metros where slug = 'decasilabo';
	select metro_id into v_m11 from public.metros where slug = 'endecasilabo';
	select metro_id into v_m12 from public.metros where slug = 'dodecasilabo';
	select termino_id into v_asonante from public.vocabularios
	where categoria = 'tipo_rima' and termino = 'asonante';

	if num_nonnulls(
		v_forma, v_simple, v_compuesta, v_m3, v_m5, v_m6, v_m7,
		v_m10, v_m11, v_m12, v_asonante,
		v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 17 then
		raise exception 'Falta la seguidilla vigente, un metro o una fuente autorizada';
	end if;

	select count(*) into v_n from public.fuentes_metricas
	where fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	update public.formas_metricas
	set definicion = 'Forma estrófica de arte menor basada en la combinación de versos largos y cortos. La seguidilla simple consta de cuatro versos 7-5-7-5 con asonancia en los pares; la compuesta añade un terceto 5-7-5 con asonancia propia. Se documentan también las variedades de tres versos, chamberga, gitana y real, con distribuciones métricas estables. Históricamente admite fluctuaciones de medida y puede organizarse en series.',
		estado_revision = 'aprobada',
		updated_at = now()
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set slug = 'simple',
		nombre = 'Simple',
		descripcion = 'Cuatro versos 7-5-7-5; los impares quedan sueltos y los pares comparten asonancia.',
		modalidad = 'preferente',
		unidad_versos_min = 4,
		unidad_versos_max = 4,
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_simple;

	update public.arquitecturas_forma
	set slug = 'compuesta',
		nombre = 'Compuesta',
		descripcion = 'Una seguidilla simple seguida de un terceto 5-7-5; cada parte tiene su propia asonancia.',
		modalidad = 'preferente',
		unidad_versos_min = 7,
		unidad_versos_max = 7,
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_compuesta;

	-- Tres versos: 5-7-5, con asonancia entre los extremos.
	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, unidad_versos_min, unidad_versos_max, estado_revision, activo, orden
	)
	values (
		v_forma, 'tres_versos', 'De tres versos',
		'Tres versos 5-7-5 con asonancia entre los pentasílabos extremos.',
		false, true, 'admitida', v_asonante, 3, 3, 'revisada', true, 3
	)
	returning arquitectura_id into v_tres;

	insert into public.esquemas_metricos (
		arquitectura_id, slug, nombre, ambito, tipo_secuencia, descripcion, estado_revision
	)
	values (v_tres, '5-7-5', '5-7-5', 'unidad', 'secuencia',
		'Pentasílabos en los extremos y heptasílabo en el centro.', 'revisada')
	returning esquema_metrico_id into v_esquema;
	insert into public.esquema_metrico_posiciones
		(esquema_metrico_id, posicion, metro_id, alternativa)
	values (v_esquema, 1, v_m5, 1), (v_esquema, 2, v_m7, 1), (v_esquema, 3, v_m5, 1);
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito,
		modalidad, tipo_secuencia, descripcion, estado_revision
	)
	values (v_tres, 'asonancia-extremos', 'Asonancia en los extremos', 'a-a', v_asonante,
		'unidad', 'definitoria', 'secuencia',
		'Los pentasílabos primero y tercero comparten asonancia; el heptasílabo queda suelto.',
		'revisada');

	-- Chamberga: simple seguida de tres pareados 3-7, cada uno con asonancia propia.
	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, unidad_versos_min, unidad_versos_max, estado_revision, activo, orden
	)
	values (
		v_forma, 'chamberga', 'Chamberga',
		'Una seguidilla simple seguida de tres pareados 3-7, cada uno con una asonancia distinta.',
		false, true, 'admitida', v_asonante, 10, 10, 'revisada', true, 4
	)
	returning arquitectura_id into v_chamberga;

	insert into public.esquemas_metricos (
		arquitectura_id, slug, nombre, ambito, tipo_secuencia, descripcion, estado_revision
	)
	values (v_chamberga, '7-5-7-5-3-7-3-7-3-7', '7-5-7-5 + 3-7 + 3-7 + 3-7',
		'unidad', 'secuencia', 'Cuarteta simple seguida de tres pares de trisílabo y heptasílabo.',
		'revisada')
	returning esquema_metrico_id into v_esquema;
	insert into public.esquema_metrico_posiciones
		(esquema_metrico_id, posicion, metro_id, alternativa)
	values
		(v_esquema, 1, v_m7, 1), (v_esquema, 2, v_m5, 1),
		(v_esquema, 3, v_m7, 1), (v_esquema, 4, v_m5, 1),
		(v_esquema, 5, v_m3, 1), (v_esquema, 6, v_m7, 1),
		(v_esquema, 7, v_m3, 1), (v_esquema, 8, v_m7, 1),
		(v_esquema, 9, v_m3, 1), (v_esquema, 10, v_m7, 1);
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito,
		modalidad, tipo_secuencia, descripcion, estado_revision
	)
	values (v_chamberga, 'asonancias-por-pareados', 'Asonancias por pareados', '-a-abbccdd',
		v_asonante, 'unidad', 'definitoria', 'secuencia',
		'La cuarteta presenta -a-a y cada pareado añadido comparte una asonancia distinta.',
		'revisada');
	insert into public.estructuras_secciones (
		arquitectura_id, slug, tipo_seccion, nombre, orden, repeticiones_min,
		repeticiones_max, versos_min, versos_max, arquitectura_referenciada_id, nota
	)
	values (v_chamberga, 'cuerpo', 'cuerpo', 'Cuerpo', 1, 1, 1, 4, 4, v_simple,
		'La cuarteta inicial realiza la seguidilla simple.');
	insert into public.estructuras_secciones (
		arquitectura_id, slug, tipo_seccion, nombre, orden, repeticiones_min,
		repeticiones_max, versos_min, versos_max, nota
	)
	values (v_chamberga, 'pareado', 'pareado', 'Pareado añadido', 2, 3, 3, 2, 2,
		'Cada repetición consta de trisílabo y heptasílabo con una asonancia propia.');

	-- Gitana: 6-6-(10/11/12)-6, con asonancia en los pares.
	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, unidad_versos_min, unidad_versos_max, estado_revision, activo, orden
	)
	values (
		v_forma, 'gitana', 'Gitana',
		'Cuatro versos 6-6-(10/11/12)-6 con asonancia en el segundo y el cuarto.',
		false, true, 'admitida', v_asonante, 4, 4, 'revisada', true, 5
	)
	returning arquitectura_id into v_gitana;
	insert into public.esquemas_metricos (
		arquitectura_id, slug, nombre, ambito, tipo_secuencia, descripcion, estado_revision
	)
	values (v_gitana, '6-6-10-11-12-6', '6-6-(10/11/12)-6', 'unidad', 'secuencia',
		'Hexasílabos en primero, segundo y cuarto; el tercero admite diez, once o doce sílabas.',
		'revisada')
	returning esquema_metrico_id into v_esquema;
	insert into public.esquema_metrico_posiciones
		(esquema_metrico_id, posicion, metro_id, alternativa)
	values
		(v_esquema, 1, v_m6, 1), (v_esquema, 2, v_m6, 1),
		(v_esquema, 3, v_m10, 1), (v_esquema, 3, v_m11, 2),
		(v_esquema, 3, v_m12, 3), (v_esquema, 4, v_m6, 1);
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito,
		modalidad, tipo_secuencia, descripcion, estado_revision
	)
	values (v_gitana, 'asonancia-pares', 'Asonancia en los versos pares', '-a-a', v_asonante,
		'unidad', 'definitoria', 'secuencia',
		'El segundo y el cuarto verso comparten asonancia; primero y tercero quedan sueltos.',
		'revisada');

	-- Real: 10-6-10-6, con asonancia en los pares.
	insert into public.arquitecturas_forma (
		forma_id, slug, nombre, descripcion, principal, demarcable, modalidad,
		tipo_rima_id, unidad_versos_min, unidad_versos_max, estado_revision, activo, orden
	)
	values (
		v_forma, 'real', 'Real',
		'Cuatro versos 10-6-10-6 con asonancia en el segundo y el cuarto.',
		false, true, 'admitida', v_asonante, 4, 4, 'revisada', true, 6
	)
	returning arquitectura_id into v_real;
	insert into public.esquemas_metricos (
		arquitectura_id, slug, nombre, ambito, tipo_secuencia, descripcion, estado_revision
	)
	values (v_real, '10-6-10-6', '10-6-10-6', 'unidad', 'secuencia',
		'Decasílabos en las posiciones impares y hexasílabos en las pares.', 'revisada')
	returning esquema_metrico_id into v_esquema;
	insert into public.esquema_metrico_posiciones
		(esquema_metrico_id, posicion, metro_id, alternativa)
	values
		(v_esquema, 1, v_m10, 1), (v_esquema, 2, v_m6, 1),
		(v_esquema, 3, v_m10, 1), (v_esquema, 4, v_m6, 1);
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito,
		modalidad, tipo_secuencia, descripcion, estado_revision
	)
	values (v_real, 'asonancia-pares', 'Asonancia en los versos pares', '-a-a', v_asonante,
		'unidad', 'definitoria', 'secuencia',
		'El segundo y el cuarto verso comparten asonancia; primero y tercero quedan sueltos.',
		'revisada');

	-- Una afirmación autosuficiente por cada una de las seis fuentes.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_mb, v_forma, 'Definición «Seguidilla»',
		 'La caracteriza por la combinación de heptasílabos y pentasílabos en estrofas de cuatro o siete versos y representa sus asonancias como XaYa:bZb. Advierte que el ritmo pesa más que el cómputo silábico estricto y que las medidas pueden variar ligeramente.',
		 'alta', 'revisada'),
		(v_quilis, v_forma, '§§ 5.4.3.3 y 5.4.6.2',
		 'Distingue la simple 7-5-7-5, atestiguada desde las jarchas, la gitana 6-6-(10/11)-6 con rima parcial en los pares y la compuesta 7-5-7-5-5-7-5.',
		 'alta', 'revisada'),
		(v_navarro, v_forma, '§§ 216, 450 y 498; repertorio final',
		 'Define la simple 7-5-7-5 con impares sueltos y pares asonantes, y documenta su antigua fluctuación. Registra además la estrofa 5-7-5, la compuesta, la chamberga, la gitana 6-6-(10/11)-6 y la real 10-6-10-6, junto con series arromanzadas, formas con eco y otras prolongaciones.',
		 'alta', 'revisada'),
		(v_cap14, v_forma, 'pp. 191-194',
		 'Presenta como norma simple 7-5-7-5 con asonancia en los pares, aunque recoge fluctuación métrica, consonancia y rima de los impares. La simple puede funcionar como estrofa o como poema; distingue asimismo la compuesta, la chamberga y la gitana.',
		 'alta', 'revisada'),
		(v_dicc, v_forma, 'Entradas «seguidilla» y sus variedades',
		 'Define la simple y sus modificaciones habituales, la compuesta, la chamberga, la gitana —cuyo tercer verso puede tener diez, once o doce sílabas—, la real 10-6-10-6 y la serie simple arromanzada que mantiene una misma asonancia entre estrofas.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma, 'Apartados «Seguidillas» y «Formas mixtas en cuartetos y septetos»',
		 'Describe la cuarteta de versos largos y cortos, normalmente 7-5-7-5 con asonancia en los pares, y subraya su fluctuación histórica. Recoge la compuesta, la chamberga, la gitana, la real 10-6-10-6 y la extensión en series arromanzadas.',
		 'alta', 'revisada');

	select count(*) into v_n from public.arquitecturas_forma
	where forma_id = v_forma and activo;
	if v_n <> 6 then
		raise exception 'La Seguidilla debe tener seis arquitecturas activas, no %', v_n;
	end if;

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La Seguidilla debe tener seis afirmaciones de fuente, no %', v_n;
	end if;
end;
$$;

-- La vista conserva la vía de equivalencia y añade la comprobación independiente de longitud.
-- Sus columnas nuevas se añaden al final para no romper las vistas que dependen de ella.
create or replace view public.propuesta_metrica_secuencia as
with recursive
reclamaciones as (
	select f.origen_termino_id as termino_id, f.forma_id, null::uuid as arquitectura_id,
		null::text as detalle, 1 as prioridad
	from public.formas_metricas f where f.origen_termino_id is not null
	union all
	select f.forma_id, f.forma_id, null::uuid, null::text, 2
	from public.formas_metricas f join public.vocabularios v on v.termino_id = f.forma_id
	union all
	select a.origen_termino_id, a.forma_id, a.arquitectura_id, null::text, 1
	from public.arquitecturas_forma a where a.origen_termino_id is not null
	union all
	select e.origen_termino_id, arq.forma_id, e.arquitectura_id,
		'esquema de rima «' || e.nombre || '»', 1
	from public.esquemas_rima e
	join public.arquitecturas_forma arq on arq.arquitectura_id = e.arquitectura_id
	where e.origen_termino_id is not null
	union all
	select va.origen_termino_id, arq.forma_id, va.arquitectura_id,
		'variedad «' || va.nombre || '»', 1
	from public.variedades_arquitectura va
	join public.arquitecturas_forma arq on arq.arquitectura_id = va.arquitectura_id
	where va.origen_termino_id is not null
	union all
	select d.origen_termino_id, coalesce(d.forma_id, arq.forma_id), d.arquitectura_id,
		null::text, 3
	from public.denominaciones_metricas d
	left join public.arquitecturas_forma arq on arq.arquitectura_id = d.arquitectura_id
	where d.origen_termino_id is not null
	union all
	select rv.origen_termino_id, null::uuid, null::uuid,
		r.nombre || ' = ' || rv.nombre, 4
	from public.rasgo_valores rv
	join public.rasgos_metricos r on r.rasgo_id = rv.rasgo_id
	where rv.origen_termino_id is not null
	union all
	select m.origen_termino_id, null::uuid, null::uuid, 'metro «' || m.nombre || '»', 4
	from public.metros m where m.origen_termino_id is not null
),
reclamacion as (
	select distinct on (termino_id) termino_id, forma_id, arquitectura_id, detalle
	from reclamaciones
	order by termino_id, (forma_id is null), prioridad
),
ascendencia as (
	select v.termino_id as origen, v.termino_id as actual, 0 as salto
	from public.vocabularios v where v.categoria = 'estrofa_tipo'
	union all
	select a.origen, padre.termino_id, a.salto + 1
	from ascendencia a
	join public.vocabularios hijo on hijo.termino_id = a.actual
	join public.vocabularios padre on padre.termino_id = hijo.termino_padre_id
	where a.salto < 8
),
heredada as (
	select distinct on (a.origen)
		a.origen as termino_id, r.forma_id, r.arquitectura_id, v.termino as desde
	from ascendencia a
	join reclamacion r on r.termino_id = a.actual
	join public.vocabularios v on v.termino_id = a.actual
	where a.salto > 0 and r.forma_id is not null
	order by a.origen, a.salto
),
resolucion as (
	select v.termino_id,
		case
			when d.forma_id is not null then 'directa'
			when d.termino_id is not null and h.forma_id is not null then 'rasgo'
			when d.termino_id is not null then 'rasgo'
			when h.forma_id is not null then 'ascendencia'
			else 'sin_destino'
		end as via,
		coalesce(d.forma_id, h.forma_id) as forma_id,
		case when d.forma_id is not null then d.arquitectura_id else h.arquitectura_id end
			as arquitectura_id,
		d.detalle,
		case when d.forma_id is null then h.desde end as heredado_de
	from public.vocabularios v
	left join reclamacion d on d.termino_id = v.termino_id
	left join heredada h on h.termino_id = v.termino_id
	where v.categoria = 'estrofa_tipo'
)
select
	s.secuencia_id,
	s.obra_id,
	s.v_ini,
	s.v_fin,
	s.estrofa_tipo_id,
	voc.termino as termino_legado,
	f.forma_id as forma_propuesta_id,
	f.nombre as forma_propuesta,
	coalesce(arq_directa.arquitectura_id, arq_compatible.arquitectura_id)
		as arquitectura_propuesta_id,
	coalesce(arq_directa.nombre, arq_compatible.nombre) as arquitectura_propuesta,
	coalesce(r.via, 'sin_tipo') as via,
	r.detalle,
	r.heredado_de,
	case
		when f.forma_id is null then null
		when arq_directa.arquitectura_id is not null then
			regla_directa.arquitectura_id is null
			or (
				(s.v_fin - s.v_ini + 1) >= regla_directa.minimo_versos
				and (s.v_fin - s.v_ini + 1) % regla_directa.modulo_versos
					= regla_directa.residuo_versos
			)
		else arq_compatible.arquitectura_id is not null
	end as longitud_compatible,
	case
		when f.forma_id is null then null
		when arq_directa.arquitectura_id is not null
			and regla_directa.arquitectura_id is not null
			and not (
				(s.v_fin - s.v_ini + 1) >= regla_directa.minimo_versos
				and (s.v_fin - s.v_ini + 1) % regla_directa.modulo_versos
					= regla_directa.residuo_versos
			)
		then format(
			'La arquitectura «%s» no admite una secuencia de %s versos: %s.',
			arq_directa.nombre, s.v_fin - s.v_ini + 1, regla_directa.explicacion
		)
		when r.arquitectura_id is null and arq_compatible.arquitectura_id is null
		then format(
			'Ninguna arquitectura activa de «%s» admite una secuencia de %s versos.',
			f.nombre, s.v_fin - s.v_ini + 1
		)
		else null
	end as motivo_revision
from public.secuencias_metricas s
left join public.vocabularios voc on voc.termino_id = s.estrofa_tipo_id
left join resolucion r on r.termino_id = s.estrofa_tipo_id
left join public.formas_metricas f on f.forma_id = r.forma_id
left join public.arquitecturas_forma arq_directa
	on arq_directa.arquitectura_id = r.arquitectura_id
left join public.arquitecturas_reglas_longitud regla_directa
	on regla_directa.arquitectura_id = arq_directa.arquitectura_id
left join lateral (
	select a.arquitectura_id, a.nombre
	from public.arquitecturas_forma a
	left join public.arquitecturas_reglas_longitud regla
		on regla.arquitectura_id = a.arquitectura_id
	where a.forma_id = f.forma_id
		and a.activo
		and r.arquitectura_id is null
		and (
			regla.arquitectura_id is null
			or (
				(s.v_fin - s.v_ini + 1) >= regla.minimo_versos
				and (s.v_fin - s.v_ini + 1) % regla.modulo_versos = regla.residuo_versos
			)
		)
	order by a.principal desc, a.orden nulls last
	limit 1
) arq_compatible on true;

comment on view public.propuesta_metrica_secuencia is
	'Propuesta revisable de forma y arquitectura para cada secuencia legada. La vía explica el origen de la equivalencia; longitud_compatible y motivo_revision comprueban por separado si la extensión cabe en la arquitectura. Cuando el término solo da la forma, se elige la arquitectura principal entre las compatibles. Una arquitectura sin regla derivada se considera de longitud abierta.';

grant select on public.propuesta_metrica_secuencia to authenticated;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

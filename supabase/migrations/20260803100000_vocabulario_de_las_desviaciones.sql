-- Vocabulario de las desviaciones, y la articulación en los esquemas observados.
--
-- Ejecuta el bloque A de docs/dominio-metrico/plan-desviaciones-y-caracterizaciones.md.
-- `desviaciones_editor_metrico` está vacía, así que aquí no se migra ningún dato real: se
-- cierra el vocabulario antes de que el laboratorio siga probando con uno que va a cambiar.
--
-- Lo que este archivo NO hace: tocar las caracterizaciones por rango de producción. Eso es
-- el bloque B y necesita antes la capa de desviaciones sobre secuencias reales.

-- ---------------------------------------------------------------------------
-- 1 · Cinco dimensiones
--
-- `combinacion` era la única sin columna donde nombrar lo observado, y una variedad es un
-- nombre para una combinación de elecciones: si las elecciones se desvían por separado, la
-- desviación de variedad se deriva.
-- ---------------------------------------------------------------------------

alter table public.desviaciones_editor_metrico
	drop constraint if exists desviaciones_editor_metrico_dimension_check;

update public.desviaciones_editor_metrico
set dimension = 'rima'
where dimension = 'combinacion';

alter table public.desviaciones_editor_metrico
	add constraint desviaciones_editor_metrico_dimension_check
	check (dimension in ('metro', 'rima', 'estructura', 'repeticion', 'rasgo'));

-- ---------------------------------------------------------------------------
-- 2 · Seis relaciones
--
-- `omision` duplicaba `falta_elemento_esperado` y `adicion` duplicaba
-- `aparece_elemento_no_esperado`; `sustitucion` y `ruptura` son `diferente` con y sin valor
-- observado. Los nombres largos se acortan porque ahora son los únicos de su idea.
-- ---------------------------------------------------------------------------

alter table public.desviaciones_editor_metrico
	drop constraint if exists desviaciones_editor_metrico_relacion_norma_check;

update public.desviaciones_editor_metrico
set relacion_norma = case relacion_norma
	when 'falta_elemento_esperado' then 'falta'
	when 'omision' then 'falta'
	when 'aparece_elemento_no_esperado' then 'sobra'
	when 'adicion' then 'sobra'
	when 'sustitucion' then 'diferente'
	when 'ruptura' then 'diferente'
	else relacion_norma
end;

alter table public.desviaciones_editor_metrico
	add constraint desviaciones_editor_metrico_relacion_norma_check
	check (relacion_norma in (
		'diferente',
		'falta',
		'sobra',
		'menor_que_norma',
		'mayor_que_norma',
		'otra'
	));

-- ---------------------------------------------------------------------------
-- 3 · Qué relación admite cada dimensión
--
-- Una rima no es «menor que la norma» y un rasgo no se «rompe». Ofrecerlas todas obligaba
-- al editor a descartar a mano opciones que no significan nada en su dimensión.
-- ---------------------------------------------------------------------------

alter table public.desviaciones_editor_metrico
	drop constraint if exists desviaciones_editor_metrico_relacion_dimension_check;

alter table public.desviaciones_editor_metrico
	add constraint desviaciones_editor_metrico_relacion_dimension_check
	check (
		case dimension
			-- Una medida solo puede sobrar o faltar.
			when 'metro' then relacion_norma in ('menor_que_norma', 'mayor_que_norma', 'otra')
			-- Un esquema es otro; no tiene tamaño.
			when 'rima' then relacion_norma in ('diferente', 'otra')
			-- Falta una sección, o la que hay es más corta.
			when 'estructura' then relacion_norma in (
				'falta', 'sobra', 'menor_que_norma', 'mayor_que_norma', 'diferente', 'otra'
			)
			when 'repeticion' then relacion_norma in (
				'falta', 'sobra', 'menor_que_norma', 'mayor_que_norma', 'diferente', 'otra'
			)
			-- Un rasgo está, no está, o es otro valor.
			when 'rasgo' then relacion_norma in ('falta', 'sobra', 'diferente', 'otra')
			else false
		end
	);

-- ---------------------------------------------------------------------------
-- 4 · El valor observado corresponde a su dimensión
--
-- Hasta ahora nada impedía una desviación con `dimension = metro` y `seccion_observada_id`
-- puesto: cinco columnas sueltas sin relación con la dimensión declarada.
-- ---------------------------------------------------------------------------

alter table public.desviaciones_editor_metrico
	drop constraint if exists desviaciones_editor_metrico_observado_dimension_check;

alter table public.desviaciones_editor_metrico
	add constraint desviaciones_editor_metrico_observado_dimension_check
	check (
		num_nonnulls(
			metro_observado_id,
			esquema_rima_observado_id,
			seccion_observada_id,
			repeticion_observada_id,
			valor_rasgo_observado_id
		) <= 1
		and (metro_observado_id is null or dimension = 'metro')
		and (esquema_rima_observado_id is null or dimension = 'rima')
		and (seccion_observada_id is null or dimension = 'estructura')
		and (repeticion_observada_id is null or dimension = 'repeticion')
		and (valor_rasgo_observado_id is null or dimension = 'rasgo')
	);

-- ---------------------------------------------------------------------------
-- 5 · `falta` nunca lleva valor observado
--
-- No había nada que observar: por eso falta.
-- ---------------------------------------------------------------------------

alter table public.desviaciones_editor_metrico
	drop constraint if exists desviaciones_editor_metrico_falta_sin_observado_check;

alter table public.desviaciones_editor_metrico
	add constraint desviaciones_editor_metrico_falta_sin_observado_check
	check (
		relacion_norma <> 'falta'
		or num_nonnulls(
			metro_observado_id,
			esquema_rima_observado_id,
			seccion_observada_id,
			repeticion_observada_id,
			valor_rasgo_observado_id
		) = 0
	);

comment on column public.desviaciones_editor_metrico.relacion_norma is
	'La relación lleva siempre el hecho; el valor observado es precisión añadida, no una vía alternativa. Contar versos hipométricos es siempre `relacion_norma = menor_que_norma`, conozca o no la fila su medida exacta.';

-- ---------------------------------------------------------------------------
-- 6 · El esquema observado admite la articulación interna
--
-- La pausa de la espinela y la frontera entre fronte y sirima se anotan con dos puntos,
-- como en la notación que el catálogo ya usa para la canción petrarquista. Los dos puntos
-- no son una posición del esquema, así que no cuentan para la longitud.
-- ---------------------------------------------------------------------------

create or replace function public.validar_eleccion_editor_metrico()
returns trigger
language plpgsql
set search_path to 'public'
as $_$
declare
	v_configuracion_id uuid;
	v_alcance text;
	v_seccion_grupo uuid;
	v_seccion_unidad uuid;
	v_padre_unidad uuid;
	v_maximo integer;
	v_tipo_control text;
	v_longitud_esperada integer;
	v_total integer;
begin
	select arquitectura_id into v_configuracion_id
	from public.secuencias_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id;

	select alcance, seccion_id, selecciones_max, tipo_control
	into v_alcance, v_seccion_grupo, v_maximo, v_tipo_control
	from public.grupos_eleccion_metrica
	where grupo_eleccion_id = new.grupo_eleccion_id
		and arquitectura_id = v_configuracion_id
		and activo;

	if v_alcance is null then
		raise exception 'El grupo de elección no pertenece a la arquitectura seleccionada';
	end if;

	if v_tipo_control = 'opciones' then
		if new.opcion_eleccion_id is null or new.valor_texto is not null then
			raise exception 'Esta pregunta necesita una opción normalizada';
		end if;
		if not exists (
			select 1 from public.opciones_eleccion_metrica
			where opcion_eleccion_id = new.opcion_eleccion_id
				and grupo_eleccion_id = new.grupo_eleccion_id
				and activo
		) then
			raise exception 'La opción no pertenece al grupo de elección';
		end if;
	elsif v_tipo_control = 'esquema_rima' then
		if new.opcion_eleccion_id is not null or new.valor_texto is null then
			raise exception 'Esta pregunta necesita un esquema de rima observado';
		end if;
		new.valor_texto := upper(regexp_replace(btrim(new.valor_texto), '\s+', '', 'g'));
		if new.valor_texto !~ '^[-A-Z:]+$' then
			raise exception 'El esquema de rima solo admite letras, guiones y dos puntos';
		end if;
	else
		raise exception 'Tipo de control editorial no reconocido';
	end if;

	if v_alcance = 'secuencia' and new.realizacion_prueba_id is not null then
		raise exception 'Una elección de secuencia no puede vincularse a una unidad';
	elsif v_alcance = 'unidad' and new.realizacion_prueba_id is null then
		raise exception 'Una elección de unidad necesita una unidad concreta';
	end if;

	if new.realizacion_prueba_id is not null then
		select seccion_id, realizacion_padre_id, v_fin - v_ini + 1
		into v_seccion_unidad, v_padre_unidad, v_longitud_esperada
		from public.realizaciones_editor_metrico
		where realizacion_prueba_id = new.realizacion_prueba_id
			and secuencia_prueba_id = new.secuencia_prueba_id;

		if not found then
			raise exception 'La unidad no pertenece a la secuencia';
		end if;

		if v_seccion_grupo is null then
			-- La pregunta se refiere a la unidad entera, no a una de sus partes.
			if v_padre_unidad is not null then
				raise exception 'La pregunta se refiere a la unidad y no a una de sus partes';
			end if;
		elsif v_seccion_grupo is distinct from v_seccion_unidad then
			raise exception 'El grupo de elección no se aplica a esta clase de unidad';
		end if;
	elsif v_tipo_control = 'esquema_rima' then
		select v_fin - v_ini + 1
		into v_longitud_esperada
		from public.secuencias_editor_metrico
		where secuencia_prueba_id = new.secuencia_prueba_id;
	end if;

	if v_tipo_control = 'esquema_rima'
		and length(replace(new.valor_texto, ':', '')) <> v_longitud_esperada
	then
		raise exception
			'El esquema de rima debe tener % posiciones y tiene %',
			v_longitud_esperada,
			length(replace(new.valor_texto, ':', ''));
	end if;

	select count(*)
	into v_total
	from public.elecciones_editor_metrico
	where secuencia_prueba_id = new.secuencia_prueba_id
		and grupo_eleccion_id = new.grupo_eleccion_id
		and realizacion_prueba_id is not distinct from new.realizacion_prueba_id
		and eleccion_prueba_id <> new.eleccion_prueba_id;

	if v_total + 1 > v_maximo then
		raise exception 'La elección supera la cardinalidad máxima del grupo';
	end if;

	return new;
end;
$_$;

-- ---------------------------------------------------------------------------
-- 7 · La notación de la canción regular recupera su articulación
--
-- El catálogo escribía `abCabC:cdeeDfF` en la descripción y `ABCABCCDEEDFF` en la
-- notación, así que la frontera entre fronte y sirima solo vivía en una nota en prosa.
-- Las minúsculas de la notación histórica no vuelven: no son clases de rima sino medida,
-- y ya están, verso por verso, en el patrón métrico de la estancia.
-- ---------------------------------------------------------------------------

update public.esquemas_rima e
set notacion = 'ABCABC:CDEEDFF',
	updated_at = now()
from public.arquitecturas_forma a
where a.arquitectura_id = e.arquitectura_id
	and a.slug = 'regular_13_abCabC_cdeeDfF'
	and e.notacion = 'ABCABCCDEEDFF';

-- ---------------------------------------------------------------------------
-- 8 · El final acentual también puede ser agudo
--
-- El rasgo solo tenía `esdrujulo`, heredado de las formas `*_de_esdrujulos`. Se marca
-- cuando predomina lo raro: en español lo normal es la mayoría de llanas, y por eso lo
-- llano no se marca nunca.
-- ---------------------------------------------------------------------------

insert into public.rasgo_valores (rasgo_id, slug, nombre, descripcion, orden)
select r.rasgo_id, 'agudo', 'Agudo', 'Final de verso agudo.', 20
from public.rasgos_metricos r
where r.slug = 'final_acentual'
on conflict do nothing;

update public.rasgo_valores v
set orden = coalesce(v.orden, 10)
from public.rasgos_metricos r
where r.rasgo_id = v.rasgo_id
	and r.slug = 'final_acentual'
	and v.slug = 'esdrujulo'
	and v.orden is null;

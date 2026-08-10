-- Las restricciones aprenden a decir lo que solo la prosa decía.
--
-- Segundo paso de la transversal de los esquemas abiertos. `esquema_rima_restricciones` admitía
-- cinco tipos y el dato usaba **uno**: las cinco filas que hay son todas `versos_sueltos`. Los
-- otros cuatro —`numero_clases`, `max_consecutivos`, `prohibe_pareado_final`, `otra`— nunca se
-- han usado, y mientras tanto la norma que sí enuncian las fuentes vivía en las descripciones.
--
-- Al releer esas descripciones, de las seis que parecían llevar norma **solo dos la llevan**:
--
--   Canción · estancias consonantes variables — «el esquema concreto es libre dentro de la
--   estancia, pero **debe repetirse idénticamente en todas las estancias**».
--
--   Sextilla · doble de pie quebrado — «el patrón debe ser **regular** y **no coincidir con el
--   patrón manriqueño**».
--
-- Las otras cuatro dicen «la rima es consonante, sin una disposición fija», que es exactamente lo
-- que ya declaran `tipo_rima_id` y `tipo_secuencia = 'abierta'`. Son prosa redundante, no norma.
--
-- Se añaden los cuatro tipos que hacen falta para decir aquello como dato:
--
--   `identidad_entre_repeticiones`  el esquema, sea cual sea, vuelve igual en cada repetición
--   `regularidad`                   hay un patrón, aunque la norma no diga cuál
--   `excluye_esquema`               no puede coincidir con otro esquema declarado
--   `min_alternancias`              la rima cambia de clase al menos N veces
--
-- El último no se usa todavía: es el que formaliza la cláusula que le falta al criterio de la
-- quintilla, y va en el paso siguiente junto con la comprobación de sus ocho tipologías.
--
-- `excluye_esquema` necesita apuntar a un esquema, no nombrarlo: el «patrón manriqueño» de la
-- sextilla es `abcabc-defdef`, su hermano en la misma arquitectura, que además lleva la
-- denominación «Copla manriqueña». Se le da una clave foránea.
--
-- *La prosa que estas dos restricciones vuelven redundante no se retira aquí. La ficha pública no
-- muestra todavía las restricciones, así que podarla ahora haría desaparecer la norma de la
-- página. Primero se enseña el dato, después se quita el texto.*

begin;

-- ---------------------------------------------------------------------------
-- 1 · Una restricción puede referirse a otro esquema
-- ---------------------------------------------------------------------------

alter table public.esquema_rima_restricciones
	add column if not exists esquema_referido_id uuid
		references public.esquemas_rima (esquema_rima_id)
		on update cascade on delete restrict;

comment on column public.esquema_rima_restricciones.esquema_referido_id is
	'El esquema al que la restricción se refiere, cuando habla de otro: la sextilla doble de pie quebrado exige que su disposición no coincida con la manriqueña, que es su hermana.';

alter table public.esquema_rima_restricciones drop constraint esquema_rima_restricciones_check;
alter table public.esquema_rima_restricciones add constraint esquema_rima_restricciones_check
	check (num_nonnulls(valor_numero, valor_texto, esquema_referido_id) <= 1);

-- ---------------------------------------------------------------------------
-- 2 · Y aprende cuatro maneras nuevas de restringir
-- ---------------------------------------------------------------------------

alter table public.esquema_rima_restricciones drop constraint esquema_rima_restricciones_tipo_check;
alter table public.esquema_rima_restricciones add constraint esquema_rima_restricciones_tipo_check
	check (tipo = any (array[
		'numero_clases',
		'max_consecutivos',
		'min_alternancias',
		'prohibe_pareado_final',
		'versos_sueltos',
		'identidad_entre_repeticiones',
		'regularidad',
		'excluye_esquema',
		'otra'
	]));

comment on column public.esquema_rima_restricciones.tipo is
	'Qué limita esta restricción. Son las maneras de acotar una disposición sin enumerarla: cuántas clases de rima admite, cuántos versos seguidos pueden compartirla, cuántas veces debe cambiar, si prohíbe el pareado final, cuántos versos quedan sueltos, si el esquema vuelve igual en cada repetición, si exige regularidad sin decir cuál, o si excluye otro esquema.';

-- ---------------------------------------------------------------------------
-- 3 · Las dos normas que estaban en prosa
-- ---------------------------------------------------------------------------

insert into public.esquema_rima_restricciones (esquema_rima_id, tipo, obligatoria, descripcion)
select er.esquema_rima_id, 'identidad_entre_repeticiones', true,
	'El esquema concreto es libre, pero vuelve idéntico en todas las estancias de la canción.'
from public.esquemas_rima er
join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
join public.formas_metricas f on f.forma_id = a.forma_id
where f.slug = 'cancion_petrarquista' and a.slug = 'estancias_consonantes_variables'
	and er.slug = 'consonante-repetido'
	and not exists (
		select 1 from public.esquema_rima_restricciones x
		where x.esquema_rima_id = er.esquema_rima_id and x.tipo = 'identidad_entre_repeticiones'
	);

insert into public.esquema_rima_restricciones (esquema_rima_id, tipo, obligatoria, descripcion)
select er.esquema_rima_id, 'regularidad', true,
	'La disposición debe ser regular, aunque la norma no fije cuál.'
from public.esquemas_rima er
join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
join public.formas_metricas f on f.forma_id = a.forma_id
where f.slug = 'sextilla' and a.slug = 'doble_pie_quebrado' and er.slug = 'consonante-variable'
	and not exists (
		select 1 from public.esquema_rima_restricciones x
		where x.esquema_rima_id = er.esquema_rima_id and x.tipo = 'regularidad'
	);

insert into public.esquema_rima_restricciones
	(esquema_rima_id, tipo, esquema_referido_id, obligatoria, descripcion)
select er.esquema_rima_id, 'excluye_esquema', manriqueno.esquema_rima_id, true,
	'No puede coincidir con la disposición manriqueña, que es el otro esquema de esta arquitectura.'
from public.esquemas_rima er
join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
join public.formas_metricas f on f.forma_id = a.forma_id
join public.esquemas_rima manriqueno
	on manriqueno.arquitectura_id = a.arquitectura_id and manriqueno.slug = 'abcabc-defdef'
where f.slug = 'sextilla' and a.slug = 'doble_pie_quebrado' and er.slug = 'consonante-variable'
	and not exists (
		select 1 from public.esquema_rima_restricciones x
		where x.esquema_rima_id = er.esquema_rima_id and x.tipo = 'excluye_esquema'
	);

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
begin
	select count(*) into v_n from public.esquema_rima_restricciones;
	if v_n <> 8 then
		raise exception 'Hay % restricciones en vez de las 5 que había más las 3 nuevas', v_n;
	end if;

	-- Una exclusión sin esquema al que referirse no dice nada.
	select count(*) into v_n from public.esquema_rima_restricciones
	where tipo = 'excluye_esquema' and esquema_referido_id is null;
	if v_n <> 0 then
		raise exception '% exclusiones no dicen a qué esquema se refieren', v_n;
	end if;

	-- Y el esquema excluido tiene que ser hermano suyo: excluir el de otra arquitectura sería
	-- decir algo que no puede ocurrir.
	select count(*) into v_n
	from public.esquema_rima_restricciones x
	join public.esquemas_rima propio on propio.esquema_rima_id = x.esquema_rima_id
	join public.esquemas_rima ajeno on ajeno.esquema_rima_id = x.esquema_referido_id
	where x.esquema_referido_id is not null
		and propio.arquitectura_id is distinct from ajeno.arquitectura_id;
	if v_n <> 0 then
		raise exception '% restricciones excluyen un esquema de otra arquitectura', v_n;
	end if;

	-- La sextilla doble declara ya sus dos normas, y la canción la suya.
	select count(*) into v_n
	from public.esquema_rima_restricciones x
	join public.esquemas_rima er on er.esquema_rima_id = x.esquema_rima_id
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sextilla' and a.slug = 'doble_pie_quebrado';
	if v_n <> 2 then
		raise exception 'La sextilla doble declara % restricciones en vez de 2', v_n;
	end if;

	-- Bajan de diez a ocho los esquemas abiertos que no declaran nada más que su tipo de rima.
	select count(*) into v_n
	from public.esquemas_rima er
	where er.tipo_secuencia = 'abierta'
		and not exists (
			select 1 from public.esquema_rima_restricciones x
			where x.esquema_rima_id = er.esquema_rima_id
		);
	if v_n <> 8 then
		raise exception 'Quedan % esquemas abiertos sin restricción en vez de 8', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

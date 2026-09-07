-- Lo que no hay se marca una vez
--
-- Las tres declaraciones nacieron esta misma tarde con tres estados —sí, no y pendiente—, y al
-- verlas en pantalla se vio que **la pregunta no es simétrica**. Decir que no cierra la pregunta en
-- todas las secuencias; decir que sí no marca un sí en ninguna, solo deja de cerrarla, que es
-- exactamente lo que ya pasa mientras nadie dice nada. Con un sí y un no juntos, marcar sí parecía
-- hacer lo contrario de marcar no, y no hacía nada.
--
-- Así que en pantalla es **una casilla**, y el modelo pasa a decir lo mismo que ella: `sin_…`, dos
-- estados, `not null`, marcada o sin marcar. Lo que de verdad afirma que las hay son las
-- secuencias, que es donde se declara la intervención; la obra solo sirve para **no tener que
-- responder que no cuarenta y seis veces**.
--
-- El traslado no pierde nada: `tiene_… = false` —«no las hay»— es la casilla marcada, y tanto el
-- `true` como el nulo eran «sigue preguntándose». Los `true` sembrados esta tarde en 6 obras con
-- donaire y 3 con personajes sobrenaturales no se pierden como información: los siguen diciendo sus
-- secuencias, una por una, que es de donde se leyeron.
--
-- `secuencias_metricas.evento_sobrenatural` no se toca: ahí sí hay tres estados de verdad, porque
-- un evento ocurre, no ocurre o todavía no se ha mirado.

begin;

-- ---------------------------------------------------------------------------
-- Las columnas dicen lo que dice la casilla
-- ---------------------------------------------------------------------------

alter table public.obras
	add column if not exists sin_figuras_donaire boolean not null default false,
	add column if not exists sin_personajes_sobrenaturales boolean not null default false,
	add column if not exists sin_eventos_sobrenaturales boolean not null default false;

comment on column public.obras.sin_figuras_donaire is
	'Marcado: en la obra no hay figuras de donaire, y sus secuencias no lo preguntan. Sin marcar: se pregunta en cada una.';
comment on column public.obras.sin_personajes_sobrenaturales is
	'Marcado: en la obra no hay personajes sobrenaturales —alegóricos, magos, santos que obran milagros, apariciones— y sus secuencias no lo preguntan.';
comment on column public.obras.sin_eventos_sobrenaturales is
	'Marcado: en la obra no ocurren eventos sobrenaturales, y sus secuencias no lo preguntan.';

do $traslado$
declare
	v_donaire integer;
	v_personajes integer;
begin
	if exists (
		select 1 from information_schema.columns
		where table_schema = 'public' and table_name = 'obras' and column_name = 'tiene_figuras_donaire'
	) then
		execute $sql$
			update public.obras
			set sin_figuras_donaire = (tiene_figuras_donaire is false),
				sin_personajes_sobrenaturales = (tiene_personajes_sobrenaturales is false),
				sin_eventos_sobrenaturales = (tiene_eventos_sobrenaturales is false)
		$sql$;
	end if;

	select count(*) filter (where sin_figuras_donaire), count(*) filter (where sin_personajes_sobrenaturales)
	into v_donaire, v_personajes
	from public.obras;

	raise notice 'Marcadas sin donaire: % · sin personajes sobrenaturales: %', v_donaire, v_personajes;
end
$traslado$;

-- ---------------------------------------------------------------------------
-- La coherencia, con las columnas nuevas
-- ---------------------------------------------------------------------------

create or replace function public.secuencia_respeta_lo_declarado_en_la_obra()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
declare
	v_obra public.obras%rowtype;
begin
	select * into v_obra from public.obras where obra_id = new.obra_id;
	if not found then
		return new;
	end if;

	if v_obra.sin_figuras_donaire
	   and new.intervencion_figuras_donaire in ('exclusiva', 'compartida') then
		raise exception 'La obra está marcada como que no tiene figuras de donaire: quita la marca antes de anotarlo en la secuencia.'
			using errcode = 'check_violation';
	end if;

	if v_obra.sin_personajes_sobrenaturales
	   and new.intervencion_personajes_sobrenaturales in ('exclusiva', 'compartida') then
		raise exception 'La obra está marcada como que no tiene personajes sobrenaturales: quita la marca antes de anotarlo en la secuencia.'
			using errcode = 'check_violation';
	end if;

	if v_obra.sin_eventos_sobrenaturales and new.evento_sobrenatural then
		raise exception 'La obra está marcada como que no tiene eventos sobrenaturales: quita la marca antes de anotarlo en la secuencia.'
			using errcode = 'check_violation';
	end if;

	return new;
end
$function$;

create or replace function public.obra_declara_por_sus_secuencias()
returns trigger
language plpgsql
set search_path to 'public'
as $function$
begin
	-- **Marcar es responder por las secuencias que callaban**, no borrar lo que dicen. Por eso
	-- primero se comprueba que ninguna diga lo contrario, y solo entonces se rellenan los huecos.
	if new.sin_figuras_donaire then
		if exists (
			select 1 from public.secuencias_metricas sm
			where sm.obra_id = new.obra_id
			  and sm.intervencion_figuras_donaire in ('exclusiva', 'compartida')
		) then
			raise exception 'Alguna secuencia declara la intervención de una figura de donaire: quítala antes de marcar que la obra no las tiene.'
				using errcode = 'check_violation';
		end if;
		update public.secuencias_metricas
		set intervencion_figuras_donaire = 'sin_intervencion'
		where obra_id = new.obra_id and intervencion_figuras_donaire is null;
	end if;

	if new.sin_personajes_sobrenaturales then
		if exists (
			select 1 from public.secuencias_metricas sm
			where sm.obra_id = new.obra_id
			  and sm.intervencion_personajes_sobrenaturales in ('exclusiva', 'compartida')
		) then
			raise exception 'Alguna secuencia declara la intervención de un personaje sobrenatural: quítala antes de marcar que la obra no los tiene.'
				using errcode = 'check_violation';
		end if;
		update public.secuencias_metricas
		set intervencion_personajes_sobrenaturales = 'sin_intervencion'
		where obra_id = new.obra_id and intervencion_personajes_sobrenaturales is null;
	end if;

	if new.sin_eventos_sobrenaturales then
		if exists (
			select 1 from public.secuencias_metricas sm
			where sm.obra_id = new.obra_id and sm.evento_sobrenatural
		) then
			raise exception 'Alguna secuencia declara un evento sobrenatural: quítalo antes de marcar que la obra no los tiene.'
				using errcode = 'check_violation';
		end if;
		update public.secuencias_metricas
		set evento_sobrenatural = false
		where obra_id = new.obra_id and evento_sobrenatural is null;
	end if;

	return new;
end
$function$;

drop trigger if exists obras_declaran_por_sus_secuencias on public.obras;
create trigger obras_declaran_por_sus_secuencias
	after update of
		sin_figuras_donaire,
		sin_personajes_sobrenaturales,
		sin_eventos_sobrenaturales
	on public.obras
	for each row
	execute function public.obra_declara_por_sus_secuencias();

alter table public.obras
	drop column if exists tiene_figuras_donaire,
	drop column if exists tiene_personajes_sobrenaturales,
	drop column if exists tiene_eventos_sobrenaturales;

-- ---------------------------------------------------------------------------
-- La guarda ejecuta lo que toca
--
-- Los dos disparadores acaban de reescribirse sobre columnas nuevas y las viejas ya no existen: un
-- cuerpo entrecomillado no se revalida al borrarlas, así que hay que hacerlos saltar. Lo que se
-- escribe para probar se deshace: cada intento vive en su bloque y sale por una excepción.
-- ---------------------------------------------------------------------------

do $guarda$
declare
	v_obra uuid;
	v_secuencia uuid;
	v_salto boolean;
	v_sin_responder integer;
begin
	-- 1 · Una secuencia no puede declarar lo que su obra tiene marcado que no hay.
	select sm.secuencia_id into v_secuencia
	from public.obras o
	join public.secuencias_metricas sm on sm.obra_id = o.obra_id
	where o.sin_figuras_donaire
	limit 1;

	if v_secuencia is not null then
		v_salto := false;
		begin
			update public.secuencias_metricas
			set intervencion_figuras_donaire = 'exclusiva'
			where secuencia_id = v_secuencia;
			raise exception 'NO_SALTO';
		exception
			when check_violation then v_salto := true;
			when raise_exception then v_salto := false;
		end;
		if not v_salto then
			raise exception 'Una secuencia pudo declarar donaire en una obra marcada como que no lo tiene.';
		end if;
	else
		raise notice 'Ninguna obra marcada sin donaire tiene secuencias: ese disparador no se prueba aquí.';
	end if;

	-- 2 · Una obra no puede marcar que no hay lo que alguna de sus secuencias declara.
	select o.obra_id into v_obra
	from public.obras o
	where exists (
		select 1 from public.secuencias_metricas sm
		where sm.obra_id = o.obra_id
		  and sm.intervencion_figuras_donaire in ('exclusiva', 'compartida')
	)
	limit 1;

	if v_obra is not null then
		v_salto := false;
		begin
			update public.obras set sin_figuras_donaire = true where obra_id = v_obra;
			raise exception 'NO_SALTO';
		exception
			when check_violation then v_salto := true;
			when raise_exception then v_salto := false;
		end;
		if not v_salto then
			raise exception 'Una obra pudo marcar que no hay el donaire que alguna de sus secuencias declara.';
		end if;
	else
		raise notice 'Ninguna obra declara donaire: ese disparador no se prueba aquí.';
	end if;

	-- 3 · Al marcarlo, la obra responde por las secuencias que callaban.
	select o.obra_id into v_obra
	from public.obras o
	where exists (
		select 1 from public.secuencias_metricas sm
		where sm.obra_id = o.obra_id and sm.evento_sobrenatural is null
	)
	limit 1;

	if v_obra is not null then
		begin
			update public.obras set sin_eventos_sobrenaturales = true where obra_id = v_obra;

			select count(*) into v_sin_responder
			from public.secuencias_metricas
			where obra_id = v_obra and evento_sobrenatural is null;

			if v_sin_responder > 0 then
				raise exception 'La obra % marcó que no hay eventos y % secuencias siguen sin responder', v_obra, v_sin_responder;
			end if;

			raise exception 'NO_SALTO';
		exception
			when raise_exception then
				if sqlerrm <> 'NO_SALTO' then
					raise;
				end if;
		end;
	end if;

	raise notice 'Disparadores probados sobre las columnas nuevas.';
end
$guarda$;

commit;

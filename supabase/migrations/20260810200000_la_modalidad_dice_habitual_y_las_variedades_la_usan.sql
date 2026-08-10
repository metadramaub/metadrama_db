-- La modalidad dice «habitual», y las variedades dejan de responderla con un sí o un no.
--
-- Dos arreglos del mismo eje, salidos de la auditoría del 10 de agosto de 2026.
--
-- EL VALOR `preferente` SE LLAMA AHORA `habitual`. Estorbaba porque sonaba al oficio de
-- `principal` —cuál se propone— cuando dice otra cosa: cuán corriente es. La prueba de que la
-- palabra era mala es que **la interfaz ya la traducía**: el demarcador mostraba «habitual»
-- donde la columna decía «preferente», y las descripciones del catálogo llevan años escribiendo
-- «alternativa habitual para la mudanza». Se adopta la palabra que ya se usaba al hablar.
--
-- La escala queda: `definitoria` sin esto no es la forma · `habitual` es lo corriente ·
-- `admitida` se documenta · `excepcional` se documenta advirtiendo que es rara.
--
-- Y REPORTA LO QUE SOSTIENE LA BIBLIOGRAFÍA, no lo que muestre el corpus. Es una distinción que
-- conviene dejar escrita antes de clasificar nada: si el día de mañana el recuento del corpus
-- dice que una disposición rara no lo era tanto, eso es un hallazgo del proyecto y pide su
-- propia columna. No se corrige a Morley y Bruerton sobreescribiendo lo que dijeron.
--
-- LAS VARIEDADES DEJAN EL BOOLEANO. `variedades_arquitectura.preferente` respondía con un sí o un
-- no al mismo eje que las demás gradúan en cuatro, y no daba para lo que las fuentes dicen: de
-- las siete tipologías del sexteto-lira, Morley y Bruerton «consideran **regular** la forma
-- aBaBcC y citan además abbacC, AabBcC y AabBCC entre otras». Eso son tres estados, no dos.
-- Pasa a `modalidad`, con el mismo vocabulario que el resto del catálogo.
--
-- El `true` que había —A1 · aBaBcC— pasa a `habitual`, que es exactamente lo que M&B, Quilis y
-- Navarro Tomás dan como la forma regular. Las otras seis quedan `admitida` a la espera del
-- tramo de la clasificación, y no `excepcional`, porque afirmar que son raras es precisamente lo
-- que hay que ir a comprobar.

begin;

-- ---------------------------------------------------------------------------
-- 1 · `preferente` pasa a `habitual` en las cuatro tablas que lo gradúan
-- ---------------------------------------------------------------------------

alter table public.esquemas_rima drop constraint esquemas_rima_modalidad_check;
alter table public.arquitecturas_forma drop constraint arquitecturas_forma_modalidad_check;
alter table public.arquitectura_rasgos drop constraint arquitectura_rasgos_modalidad_check;
alter table public.repeticiones_metricas drop constraint repeticiones_metricas_modalidad_check;

update public.esquemas_rima set modalidad = 'habitual', updated_at = now()
where modalidad = 'preferente';
update public.arquitecturas_forma set modalidad = 'habitual', updated_at = now()
where modalidad = 'preferente';
update public.arquitectura_rasgos set modalidad = 'habitual'
where modalidad = 'preferente';
update public.repeticiones_metricas set modalidad = 'habitual', updated_at = now()
where modalidad = 'preferente';

alter table public.esquemas_rima add constraint esquemas_rima_modalidad_check
	check (modalidad = any (array['definitoria', 'habitual', 'admitida', 'excepcional']));
alter table public.arquitectura_rasgos add constraint arquitectura_rasgos_modalidad_check
	check (modalidad = any (array['definitoria', 'habitual', 'admitida', 'excepcional']));
alter table public.repeticiones_metricas add constraint repeticiones_metricas_modalidad_check
	check (modalidad = any (array['definitoria', 'habitual', 'admitida', 'excepcional']));
-- Una arquitectura nunca es definitoria: una realización no define su forma.
alter table public.arquitecturas_forma add constraint arquitecturas_forma_modalidad_check
	check (modalidad = any (array['habitual', 'admitida', 'excepcional']));

-- ---------------------------------------------------------------------------
-- 2 · Las variedades gradúan como todo lo demás
-- ---------------------------------------------------------------------------

alter table public.variedades_arquitectura add column if not exists modalidad text;

update public.variedades_arquitectura
set modalidad = case when preferente then 'habitual' else 'admitida' end,
	updated_at = now()
where modalidad is null;

alter table public.variedades_arquitectura alter column modalidad set not null;
alter table public.variedades_arquitectura alter column modalidad set default 'admitida';
alter table public.variedades_arquitectura add constraint variedades_arquitectura_modalidad_check
	check (modalidad = any (array['definitoria', 'habitual', 'admitida', 'excepcional']));

alter table public.variedades_arquitectura drop column preferente;

-- ---------------------------------------------------------------------------
-- 3 · Lo que significan, ahora que se llaman como se hablan
-- ---------------------------------------------------------------------------

comment on column public.esquemas_rima.modalidad is
	'Cuánto ha fijado la tradición esta disposición, **según la bibliografía declarada**. `definitoria` cuando la arquitectura no es ella misma sin este esquema; `habitual` cuando las fuentes la dan como la corriente; `admitida` cuando la documentan sin destacarla; `excepcional` cuando la documentan advirtiendo que es rara. No dice qué frecuencia tiene en el corpus: eso, cuando se mida, será otra columna.';

comment on column public.arquitecturas_forma.modalidad is
	'Cuánto ha fijado la tradición esta realización, **según la bibliografía declarada**. Una arquitectura nunca es definitoria: una realización no define su forma. No dice cuál se propone por defecto —eso es `principal`, que señala la realización general— ni qué frecuencia tiene en el corpus.';

comment on column public.arquitectura_rasgos.modalidad is
	'Si el rasgo define esta arquitectura o solo se admite en ella, **según la bibliografía declarada**. `definitoria` cuando sin él la arquitectura sería otra; `admitida` cuando aparece y se registra sin que la caracterice.';

comment on column public.repeticiones_metricas.modalidad is
	'Cuánto ha fijado la tradición esta manera de repetir, **según la bibliografía declarada**. Misma escala que en los esquemas de rima.';

comment on column public.variedades_arquitectura.modalidad is
	'Cuánto ha fijado la tradición esta disposición entre las de su arquitectura, **según la bibliografía declarada**. Sustituye a un booleano que solo distinguía dos casos: de las siete tipologías del sexteto-lira, las fuentes dan una por regular y citan otras tres, que no es lo mismo que decir que las seis restantes son iguales.';

-- ---------------------------------------------------------------------------
-- Las pruebas
-- ---------------------------------------------------------------------------

do $$
declare
	v_n integer;
	v_mal text;
begin
	-- No puede quedar un `preferente` en ninguna de las cinco.
	select count(*) into v_n from (
		select 1 from public.esquemas_rima where modalidad = 'preferente'
		union all select 1 from public.arquitecturas_forma where modalidad = 'preferente'
		union all select 1 from public.arquitectura_rasgos where modalidad = 'preferente'
		union all select 1 from public.repeticiones_metricas where modalidad = 'preferente'
		union all select 1 from public.variedades_arquitectura where modalidad = 'preferente'
	) s;
	if v_n <> 0 then
		raise exception 'Quedan % filas diciendo «preferente»', v_n;
	end if;

	-- Y los recuentos tienen que ser los mismos que había: 10 esquemas, 30 arquitecturas,
	-- 1 repetición. Si cambiaran, es que el update tocó lo que no debía.
	select count(*) into v_n from public.esquemas_rima where modalidad = 'habitual';
	if v_n <> 10 then raise exception '% esquemas habituales en vez de 10', v_n; end if;
	select count(*) into v_n from public.arquitecturas_forma where modalidad = 'habitual';
	if v_n <> 30 then raise exception '% arquitecturas habituales en vez de 30', v_n; end if;
	select count(*) into v_n from public.repeticiones_metricas where modalidad = 'habitual';
	if v_n <> 1 then raise exception '% repeticiones habituales en vez de 1', v_n; end if;

	-- La variedad que era la preferente del sexteto-lira es la que ahora es habitual, y solo esa.
	select string_agg(v.slug, ', ') into v_mal
	from public.variedades_arquitectura v where v.modalidad = 'habitual';
	if v_mal is distinct from 'a1_aBaBcC' then
		raise exception 'La variedad habitual quedó siendo «%»', coalesce(v_mal, 'ninguna');
	end if;

	select count(*) into v_n from public.variedades_arquitectura where modalidad = 'admitida';
	if v_n <> 6 then raise exception '% variedades admitidas en vez de 6', v_n; end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

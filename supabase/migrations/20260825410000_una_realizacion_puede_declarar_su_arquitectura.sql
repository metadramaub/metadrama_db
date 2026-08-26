-- Una realización puede declarar su arquitectura
--
-- B5, primera mitad: el modelo. La segunda, en la migración siguiente, es abrirlo a la décima.
--
-- **El problema.** `secuencias_editor_metrico` lleva **una sola arquitectura**, así que una décima
-- aumentada entre décimas normales solo cabía partiendo el pasaje o registrándola como desviación
-- `estructura` / `mayor_que_norma` —es decir, anotándola como el error que no es—. El catálogo
-- sostiene lo contrario, y lo dice la propia descripción de la arquitectura: «Alarga el miembro final
-- de cuatro versos a seis… **Aparece intercalada entre décimas normales**». Morley y Bruerton la
-- documentan así.
--
-- **Dónde va, y por qué no en las desviaciones.** `desviaciones_editor_metrico` tiene una columna
-- «observada» por dimensión y le falta justo la de la arquitectura, de modo que el hueco tenía la
-- forma de la solución. Pero **conceptualmente no es una desviación**: una desviación registra que
-- el pasaje se aparta de su norma, y aquí la norma admite la estrofa larga. Va donde ocurre: en la
-- **realización**.
--
-- Nulo significa «la de la secuencia», que es el caso de todas las realizaciones existentes y será
-- el de casi todas siempre.
--
-- **Dos guardas, y las dos son de criterio.**
--
-- 1. **La misma forma.** Una excepción es otra arquitectura *de la misma forma*: una décima que
--    crece sigue siendo una décima. Admitir cualquiera convertiría la secuencia en un cajón y
--    desharía el criterio de que un cambio que obliga a abrir otra secuencia es otra forma.
--    *Queda anotado que el día que se quiera admitir, por ejemplo, un pareado cerrando una alirada
--    como parte de la misma secuencia, esta guarda es la que habrá que reabrir.*
--
-- 2. **Solo donde el catálogo lo declare.** `arquitecturas_forma` gana `intercalable`, que dice si
--    esa arquitectura aparece intercalada entre realizaciones de otra de su forma. Nace en `false`
--    para las noventa y tres, y la migración siguiente la levanta **solo en la décima aumentada**,
--    que es la única que hoy lo afirma. Se cierra a propósito: la seguidilla compuesta entre simples
--    es imaginable, pero ninguna fuente la documenta así, y ofrecerlo en las cuarenta y una formas
--    invita a que un editor marque excepción donde en realidad empieza otra secuencia. ⇒ **cuestión
--    para el IP**: si el corpus trae otra, se abre.
--
-- La validación va en disparador y no en `check` porque cruza tres tablas —la realización, su
-- secuencia y la arquitectura—, y un `check` no puede mirar fuera de su fila.

begin;

do $$
declare
	v_n integer;
begin
	-- ------------------------------------------------------------ Qué arquitecturas se intercalan
	alter table public.arquitecturas_forma
		add column if not exists intercalable boolean not null default false;

	comment on column public.arquitecturas_forma.intercalable is
		'Si esta arquitectura aparece intercalada entre realizaciones de otra de su misma forma, de '
		'modo que una secuencia puede contener las dos. Lo declara el catálogo forma por forma: no '
		'basta con que dos arquitecturas midan distinto.';

	-- ------------------------------------------------------- Qué arquitectura tiene una realización
	alter table public.realizaciones_editor_metrico
		add column if not exists arquitectura_id uuid;

	comment on column public.realizaciones_editor_metrico.arquitectura_id is
		'La arquitectura de esta realización cuando no es la de su secuencia. Nulo significa «la de '
		'la secuencia», que es el caso corriente. Solo admite arquitecturas de la misma forma y '
		'declaradas intercalables.';

	if not exists (
		select 1 from pg_constraint
		where conname = 'realizaciones_editor_metrico_arquitectura_id_fkey'
	) then
		alter table public.realizaciones_editor_metrico
			add constraint realizaciones_editor_metrico_arquitectura_id_fkey
			foreign key (arquitectura_id) references public.arquitecturas_forma(arquitectura_id)
			on update cascade on delete restrict;
	end if;

	-- ------------------------------------------------------------------- Las dos guardas
	create or replace function public.validar_arquitectura_de_realizacion()
	returns trigger
	language plpgsql
	set search_path to 'public'
	as $validar$
	declare
		v_forma_secuencia uuid;
		v_forma_excepcion uuid;
		v_intercalable boolean;
	begin
		if new.arquitectura_id is null then
			return new;
		end if;

		-- Una excepción es de la unidad, no de una parte suya: una sección no cambia de
		-- arquitectura, cambia la estrofa entera.
		if new.realizacion_padre_id is not null or new.seccion_id is not null then
			raise exception 'Solo una unidad completa puede declarar otra arquitectura, no una de sus partes';
		end if;

		select a.forma_id into v_forma_secuencia
		from public.secuencias_editor_metrico s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		where s.secuencia_prueba_id = new.secuencia_prueba_id;

		select forma_id, intercalable into v_forma_excepcion, v_intercalable
		from public.arquitecturas_forma
		where arquitectura_id = new.arquitectura_id;

		if v_forma_secuencia is null then
			raise exception 'La secuencia no declara arquitectura: no hay de qué ser excepción';
		end if;
		if v_forma_excepcion is distinct from v_forma_secuencia then
			raise exception 'Una realización solo puede declarar otra arquitectura de su misma forma';
		end if;
		if not coalesce(v_intercalable, false) then
			raise exception 'Esa arquitectura no está declarada intercalable en el catálogo';
		end if;

		return new;
	end;
	$validar$;

	drop trigger if exists trigger_validar_arquitectura_de_realizacion
		on public.realizaciones_editor_metrico;
	create constraint trigger trigger_validar_arquitectura_de_realizacion
		after insert or update on public.realizaciones_editor_metrico
		deferrable initially deferred
		for each row execute function public.validar_arquitectura_de_realizacion();

	-- ------------------------------------------------------------------ Comprobaciones
	-- Nada de lo anotado se ha movido: todas las realizaciones siguen siendo de su secuencia.
	select count(*) into v_n
	from public.realizaciones_editor_metrico where arquitectura_id is not null;
	if v_n <> 0 then
		raise exception '% realizaciones declaran ya una arquitectura, y no debía haber ninguna.', v_n;
	end if;

	-- Y ninguna arquitectura se declara intercalable todavía: eso lo hace la migración siguiente,
	-- forma por forma y con su fuente.
	select count(*) into v_n from public.arquitecturas_forma where intercalable;
	if v_n <> 0 then
		raise exception '% arquitecturas nacen intercalables, y debían nacer todas en falso.', v_n;
	end if;
end $$;

commit;

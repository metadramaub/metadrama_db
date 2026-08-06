-- Qué significa cada tipo de denominación, y tres que lo usaban mal.
--
-- `tipo_alias` admite cinco valores y ninguno estaba documentado, así que se han ido usando
-- por intuición y no siempre igual. Se fija el criterio y se corrige lo que no lo cumple.
--
--   equivalente      · Otro nombre vigente para lo mismo. Es el caso normal.
--   variante_grafica · El mismo nombre escrito de otra manera.
--   abreviatura      · Forma abreviada de un nombre más largo.
--   historico        · Nombre **de otra época**, que hoy ya no se usa. Lo que lo hace
--                      histórico es cuándo se dijo, no quién lo dijo.
--   posterior        · Nombre acuñado **después** de la forma, para algo que ya existía sin él.
--
-- Tres correcciones:
--
-- 1 · **«Quintilla de Fray Luis de León» no es histórica.** Es como Morley y Bruerton llaman
--     a la lira de cinco versos, y Morley y Bruerton son de 1968: críticos contemporáneos, no
--     una fuente de época. Un nombre no se vuelve histórico porque lo use una fuente que
--     nosotros leemos como bibliografía. Pasa a `equivalente`, que es lo que es: otro nombre
--     vigente, el que emplea la obra sobre la que se data a Lope.
--
--     Los otros cinco `historico` sí lo son: «Redondilla de diez versos» es como Espinel llamó
--     a la décima en el siglo XVI, «Estrofa de fray Luis de León» es nombre de tradición, y
--     «Octava real regular», «Irregular» y «Verso suelto» vienen del vocabulario retirado.
--
-- 2 · **«Cuarteta» estaba tres veces, una con tipo distinto.** Se escribió sobre los tres
--     esquemas `abab` de la redondilla —octosílaba, heptasílaba y hexasílaba—, que es correcto,
--     pero una de ellas ya existía como `posterior` y el `on conflict do nothing` de aquella
--     migración no la detectó: no hay índice único que lo impida. Se unifica en `equivalente`,
--     porque «cuarteta» no es posterior a la redondilla cruzada sino el nombre que la tradición
--     le da desde el principio, según el Diccionario y Quilis.
--
-- 3 · **Y se impide que vuelva a duplicarse**, con el índice único que faltaba: un mismo
--     nombre no puede repetirse sobre el mismo destino.

begin;

do $$
declare
	v_borradas integer;
begin
	-- 1 · Un crítico del siglo XX no acuña un nombre histórico.
	update public.denominaciones_metricas
	set tipo_alias = 'equivalente'
	where slug_normalizado = 'quintilla_de_fray_luis_de_leon';

	-- 2 · Unificar «Cuarteta» y dejar una por esquema.
	update public.denominaciones_metricas
	set tipo_alias = 'equivalente'
	where nombre = 'Cuarteta';

	-- Se conserva la más antigua de cada destino: `alias_id` es uuid y no se puede ordenar
	-- por él, así que manda `created_at`.
	delete from public.denominaciones_metricas d
	where d.alias_id in (
		select alias_id
		from (
			select
				alias_id,
				row_number() over (
					partition by
						slug_normalizado,
						coalesce(forma_id, arquitectura_id, esquema_metrico_id, esquema_rima_id,
							variedad_id, seccion_id, repeticion_id)
					order by created_at, alias_id::text
				) as fila
			from public.denominaciones_metricas
		) x
		where x.fila > 1
	);
	get diagnostics v_borradas = row_count;

	raise notice 'Denominaciones duplicadas retiradas: %', v_borradas;
end $$;

-- 3 · Que no vuelva a pasar. `coalesce` porque los destinos son excluyentes y todos menos uno
--     están a null: sin él, dos filas con el mismo nombre y distinto destino no chocarían,
--     pero dos idénticas tampoco, porque en SQL null nunca es igual a null.
create unique index if not exists denominaciones_metricas_sin_duplicados
on public.denominaciones_metricas (
	slug_normalizado,
	coalesce(forma_id, arquitectura_id, esquema_metrico_id, esquema_rima_id, variedad_id, seccion_id, repeticion_id)
);

comment on column public.denominaciones_metricas.tipo_alias is
	'`equivalente`, el caso normal: otro nombre vigente para lo mismo. `variante_grafica`, el mismo nombre escrito de otra manera. `abreviatura`. `historico`, nombre de otra época que hoy no se usa —lo decide **cuándo se dijo**, no quién lo dijo: el nombre que emplea una monografía del siglo XX es equivalente, no histórico—. `posterior`, nombre acuñado después de la forma para algo que ya existía sin él.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

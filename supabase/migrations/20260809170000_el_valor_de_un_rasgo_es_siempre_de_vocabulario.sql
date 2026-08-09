-- El valor de un rasgo sale siempre de su vocabulario.
--
-- `arquitectura_rasgos` nació con tres maneras excluyentes de dar valor a un rasgo: `valor_id`,
-- que apunta al vocabulario controlado de `rasgo_valores`; `valor_numero`, para un valor
-- numérico; y `valor_texto`, para uno libre. Un `check` permitía solo una de las tres.
--
-- **Las dos últimas no se han usado nunca**: las 26 filas declaradas usan `valor_id`. Y no es
-- casualidad, sino el modelo funcionando como debe. La ontología prefiere el vocabulario
-- normalizado justamente para que una respuesta pueda compararse entre secuencias, que es lo
-- que un número suelto o un texto libre impiden.
--
-- Se retiran las dos. Una columna sin usar y sin sentido documentado no es inocua: invita a
-- rellenarse con lo primero que encaje. Estuvo a punto de pasar con la cardinalidad del pie
-- quebrado de la copla real, que cabía en `valor_numero` a costa de significar otra cosa —«el
-- valor del rasgo es 2» en vez de «caben dos posiciones»— y acabó en una columna propia.
--
-- Si algún día hace falta un rasgo genuinamente numérico, se añade entonces con su sentido
-- claro. No se toca `elecciones_editor_metrico.valor_texto`, que es otra tabla y **sí se usa**:
-- guarda las respuestas abiertas, como el esquema de rima observado de un sexteto.

begin;

do $$
declare
	v_n integer;
begin
	select count(*) into v_n from public.arquitectura_rasgos
	where valor_numero is not null or valor_texto is not null;
	if v_n <> 0 then
		raise exception 'Hay % filas que usan valor_numero o valor_texto: no se pueden retirar', v_n;
	end if;
end;
$$;

alter table public.arquitectura_rasgos
	drop constraint if exists configuracion_rasgos_check;

alter table public.arquitectura_rasgos drop column if exists valor_numero;
alter table public.arquitectura_rasgos drop column if exists valor_texto;

comment on column public.arquitectura_rasgos.valor_id is
	'Valor que la arquitectura declara para el rasgo, tomado siempre del vocabulario de `rasgo_valores`. Nulo deja el eje abierto; varias filas del mismo rasgo declaran el subconjunto de valores admitidos.';

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

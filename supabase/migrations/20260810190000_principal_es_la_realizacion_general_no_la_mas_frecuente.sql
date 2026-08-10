-- `principal` es la realización general, no la más frecuente.
--
-- La clasificación de la modalidad empezó contrastando `principal` con `modalidad` en las trece
-- formas con más de una arquitectura. En doce, la principal es una de las preferentes. En la
-- sextilla no: propone la **Octosilábica**, que es `admitida`, teniendo una `preferente` —**De
-- pie quebrado**—, que es la que Navarro Tomás y Jauralde dan como la usual.
--
-- Parecía el único error del eje y **no lo es**. La sextilla como estrofa de seis octosílabos es
-- la realización general; la de pie quebrado es una **especialización** de ella. Que la
-- especialización se documente más veces no la convierte en la base: el editor abre por la
-- estrofa simple y baja a la especialización cuando la encuentra, no al revés.
--
-- La regla vale para las trece: el romance octosilábico, la redondilla octosilábica, la
-- seguidilla simple, la décima espinela, el sexteto endecasílabo. En todas, `principal` es la
-- realización de la que las demás son especializaciones o variantes de medida.
--
-- Así que los dos ejes son aún más independientes de lo que parecía, y ninguno se deriva del
-- otro:
--
--   `principal`  cuál es la realización general de la forma. Una por forma.
--   `modalidad`  cuánto ha fijado la tradición cada una. Una escala, para todas.
--
-- No se toca ninguna fila: lo que faltaba era la regla escrita, que es lo que permitió que la
-- sextilla pareciera un error durante media hora.

begin;

comment on column public.arquitecturas_forma.principal is
	'Cuál es la realización **general** de la forma, aquella de la que las demás son especializaciones o variantes de medida, y que el editor propone por defecto. Exactamente una por forma. No es la más frecuente ni la más asentada —eso lo dice `modalidad`—: la sextilla propone la octosilábica aunque la de pie quebrado esté más documentada, porque la de pie quebrado es una especialización de aquella.';

do $$
declare
	v_n integer;
begin
	select count(*) into v_n
	from public.formas_metricas f
	where f.activo and f.tipo_registro = 'forma' and (
		select count(*) from public.arquitecturas_forma a
		where a.forma_id = f.forma_id and a.activo and a.principal
	) <> 1;
	if v_n <> 0 then
		raise exception '% formas no tienen exactamente una arquitectura principal', v_n;
	end if;

	-- La sextilla sigue proponiendo la octosilábica, que es el caso que fija la regla.
	select count(*) into v_n
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'sextilla' and a.principal and a.slug <> 'octosilabica';
	if v_n <> 0 then
		raise exception 'La sextilla dejó de proponer la octosilábica';
	end if;
end;
$$;

commit;

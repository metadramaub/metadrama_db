begin;

-- Dos omisiones, no dos decisiones.
--
-- 1 · Cinco esquemas de rima no declaraban su tipo. Los cuartetos del soneto y las cuatro
--     mudanzas del villancico son consonantes sin discusión: los cuatro esquemas de tercetos
--     del soneto sí lo declaran y solo el de los cuartetos se quedó sin él. El sexto esquema
--     sin tipo, `versos-sueltos` del endecasílabo suelto, se queda como está: ahí no hay rima
--     que tipificar.
--
-- 2 · La canción petrarquista era la única forma con varias arquitecturas y ninguna
--     principal, así que el editor no tenía qué ofrecer por defecto. La regular de trece
--     versos es la canónica y la que más aparece.

update public.esquemas_rima esquema
set tipo_rima_id = (
	select referencia.tipo_rima_id
	from public.esquemas_rima referencia
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = referencia.arquitectura_id
	join public.formas_metricas forma
		on forma.forma_id = arquitectura.forma_id
	where forma.slug = 'redondilla' and referencia.slug = 'abab'
	limit 1
)
from public.arquitecturas_forma arquitectura
join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
where arquitectura.arquitectura_id = esquema.arquitectura_id
	and esquema.tipo_rima_id is null
	and (
		(forma.slug = 'soneto' and esquema.slug = 'abba')
		or (forma.slug = 'villancico' and esquema.slug in ('abba', 'abab'))
	);

update public.arquitecturas_forma arquitectura
set principal = true
from public.formas_metricas forma
where forma.forma_id = arquitectura.forma_id
	and forma.slug = 'cancion_petrarquista'
	and arquitectura.slug = 'regular_13_versos';

do $$
declare
	v_sin_tipo integer;
	v_principales integer;
begin
	select count(*) into v_sin_tipo
	from public.esquemas_rima esquema
	join public.arquitecturas_forma arquitectura
		on arquitectura.arquitectura_id = esquema.arquitectura_id
	join public.formas_metricas forma on forma.forma_id = arquitectura.forma_id
	where esquema.tipo_rima_id is null and forma.slug in ('soneto', 'villancico');
	if v_sin_tipo <> 0 then
		raise exception 'Quedan % esquemas del soneto o el villancico sin tipo de rima', v_sin_tipo;
	end if;

	select count(*) into v_principales
	from public.formas_metricas forma
	where forma.tipo_registro = 'forma'
		and not exists (
			select 1 from public.arquitecturas_forma arquitectura
			where arquitectura.forma_id = forma.forma_id and arquitectura.principal
		);
	if v_principales <> 0 then
		raise exception '% formas siguen sin arquitectura principal', v_principales;
	end if;
end;
$$;

commit;

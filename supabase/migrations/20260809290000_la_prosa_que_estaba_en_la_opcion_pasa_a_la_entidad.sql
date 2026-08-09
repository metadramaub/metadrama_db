-- La prosa que estaba en la opción pasa a la entidad que la merecía.
--
-- Al derivar las opciones se vio qué explicaciones se perdían, y la mayoría no eran ninguna
-- pérdida: 107 de metro repetían la etiqueta —«El verso 17 tiene 11 sílabas»— y otras tantas
-- reformulaban el nombre del valor. Pero seis entidades sí tenían dicha en la opción una prosa
-- que les faltaba a ellas, y ahí el hueco es real: no sobraba la explicación, faltaba
-- declararla donde se dice una sola vez.
--
-- El caso del rasgo lo enseña bien. «Esdrújulo» aparecía descrito de tres maneras distintas en
-- tres opciones —«total o mayoritariamente», «mayoritariamente», y una tercera variante—,
-- porque cada una se escribió por su lado. Escrito en el valor, se dice una vez y no puede
-- separarse de sí mismo.
--
-- De «Cuarteta» no queda rastro en la prosa a propósito: ya está registrada como denominación
-- de `abab`, y la ficha la muestra por esa vía. Repetirla en la descripción era decir dos veces
-- lo mismo en dos sitios que podían dejar de coincidir.

begin;

update public.esquemas_rima
set descripcion = 'Las dos clases de rima alternan verso a verso.',
	updated_at = now()
where slug = 'abab' and descripcion is null;

update public.esquemas_rima
set descripcion = 'La primera clase de rima abre y cierra, y encierra dentro un pareado de la segunda.',
	updated_at = now()
where slug = 'abba' and descripcion is null;

update public.repeticiones_metricas
set descripcion = 'Represa total: el estribillo vuelve entero, con todos sus versos.',
	updated_at = now()
where slug = 'represa_total' and descripcion is null;

update public.repeticiones_metricas
set descripcion = 'Represa parcial: vuelve solo una parte del estribillo, normalmente sus últimos versos.',
	updated_at = now()
where slug = 'represa_parcial' and descripcion is null;

update public.repeticiones_metricas
set descripcion = 'Represa implícita: el texto no vuelve a escribir el estribillo, pero la forma lo da por cantado.',
	updated_at = now()
where slug = 'represa_implicita' and descripcion is null;

update public.rasgo_valores rv
set descripcion = 'La secuencia usa total o mayoritariamente palabras esdrújulas a final de verso.',
	updated_at = now()
from public.rasgos_metricos r
where r.rasgo_id = rv.rasgo_id and r.slug = 'final_acentual' and rv.slug = 'esdrujulo'
	and rv.descripcion is null;

do $$
declare
	v_n integer;
begin
	-- Ninguna entidad que tuviera prosa en su opción puede quedarse sin ella.
	select count(*) into v_n
	from public.opciones_eleccion_metrica_manual m
	where m.descripcion is not null
		and (
			exists (
				select 1 from public.esquemas_rima e
				where e.esquema_rima_id = m.esquema_rima_id and e.descripcion is null
			)
			or exists (
				select 1 from public.repeticiones_metricas p
				where p.repeticion_id = m.repeticion_id and p.descripcion is null
			)
			or exists (
				select 1 from public.rasgo_valores v
				where v.valor_id = m.valor_rasgo_id and v.descripcion is null
			)
		);
	if v_n <> 0 then
		raise exception '% opciones explicaban una entidad que sigue sin explicación propia', v_n;
	end if;

	select count(*) into v_n from public.opciones_eleccion_metrica;
	if v_n <> 405 then
		raise exception 'Las opciones derivadas dejaron de ser 405 y son %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

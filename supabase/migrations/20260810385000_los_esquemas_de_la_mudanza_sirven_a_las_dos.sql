-- Los esquemas de la mudanza sirven a las dos mudanzas.
--
-- CORRIGE UN FALLO INTRODUCIDO HOY. La migración `20260810350000` dio `seccion_id` a los seis
-- esquemas de rima del villancico creyendo que era lo que les faltaba para colocarse bajo su parte.
-- No lo era, y además los sacó del catálogo: **tres preguntas se quedaron sin ninguna opción** y la
-- ficha pública dejó de enseñar la rima de la mudanza.
--
-- POR QUÉ. Un esquema de rima se ofrece en una pregunta cuando `er.seccion_id is not distinct from
-- g.seccion_tratada_id`. Mientras los seis no señalaban sección, casaban con preguntas que tampoco
-- la señalan. Al darles una, dejaron de casar con las suyas.
--
-- Y NO BASTABA CON DECLARARLA EN LA PREGUNTA, que era el arreglo evidente. La arquitectura de
-- estribillo posterior tiene **dos mudanzas** —`mudanza_inicial`, la de la copla que abre, y
-- `mudanza`, la de las demás— y **los mismos tres esquemas sirven a las dos**. Un esquema solo
-- puede apuntar a una sección, así que señalar la sección concreta es justamente lo que no se puede
-- hacer aquí: `abba` no es la rima de *esa* mudanza sino la de *una* mudanza.
--
-- Se revierte, pues, la parte del villancico. Lo demás de aquella migración se queda: los cuatro
-- esquemas métricos que sí hablan de una parte concreta —el estribillo de la seguidilla compuesta y
-- el remate de las tres sextinas— y la corrección de la silva.
--
-- LA FICHA NO PIERDE NADA, porque nunca lo usó para esto: llega a la rima de una sección **por las
-- preguntas atadas a esa sección**, no por el `seccion_id` del esquema. Eso ya funcionaba, y por eso
-- el error pasó las pruebas de aquella migración.
--
-- QUEDA UNA GUARDA MEJOR QUE UN NÚMERO. La de entonces contaba opciones contra una cifra fija, que
-- envejece; esta comprueba el invariante: **ninguna pregunta activa de opciones se queda sin
-- ninguna**. Eso es lo que había que haber vigilado.

begin;

update public.esquemas_rima e
set seccion_id = null,
	updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where a.arquitectura_id = e.arquitectura_id
	and f.forma_id = a.forma_id
	and f.slug = 'villancico'
	and e.seccion_id is not null;

do $$
declare
	v_n integer;
	v_mal text;
	v_json jsonb;
begin
	-- El invariante: ninguna pregunta activa de opciones sin opciones.
	select count(*), string_agg(f.slug || '·' || a.slug || '·' || g.slug, ', ' order by g.slug)
	into v_n, v_mal
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where g.tipo_control = 'opciones' and g.activo
		and not exists (
			select 1 from public.opciones_eleccion_metrica o
			where o.grupo_eleccion_id = g.grupo_eleccion_id
		);
	if v_n <> 0 then
		raise exception '% preguntas se quedan sin opciones: %', v_n, v_mal;
	end if;

	-- Las tres de la mudanza vuelven a ofrecer sus tres esquemas.
	select count(*) into v_n
	from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and g.dimension = 'rima';
	if v_n <> 9 then
		raise exception 'Las preguntas de rima del villancico ofrecen % opciones en vez de 9', v_n;
	end if;

	-- Lo que sí hablaba de una parte concreta sigue diciéndolo.
	select count(*) into v_n from public.esquemas_metricos where seccion_id is not null;
	if v_n <> 4 then
		raise exception '% esquemas métricos con sección en vez de 4', v_n;
	end if;

	select count(*) into v_n from public.esquemas_rima where seccion_id is not null;
	if v_n <> 11 then
		raise exception '% esquemas de rima con sección en vez de 11', v_n;
	end if;

	-- Y la ficha del villancico vuelve a traer la rima de sus mudanzas.
	select public.get_forma_metrica_publica_jerarquica('villancico') into v_json;
	if coalesce(jsonb_array_length(v_json -> 'esquemasRima'), 0) < 6 then
		raise exception 'La ficha del villancico trae % esquemas de rima',
			coalesce(jsonb_array_length(v_json -> 'esquemasRima'), 0);
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

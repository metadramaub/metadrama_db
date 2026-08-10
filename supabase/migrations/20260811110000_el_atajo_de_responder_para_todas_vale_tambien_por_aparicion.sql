-- El atajo de responder para todas vale también por aparición.
--
-- REVIERTE `20260811100000`, aplicada hace unos minutos, que apagó `permite_aplicar_global` en las
-- preguntas por realización y prohibió la combinación. Estaba mal razonada.
--
-- El IP lo señaló: **responder una vez para todas las unidades y corregir después las que varían
-- es el patrón bueno**, no una trampa, y lo es en cualquier secuencia que repita una forma. El
-- editor V2 ya lo hacía así y lo tenía escrito: la pregunta se pliega arriba mientras las
-- respuestas son uniformes, se despliega en cuanto una difiere, y lo que se guarda sigue siendo la
-- respuesta de cada unidad.
--
-- Apagarlo en la represa no protegía la distinción entre un estribillo que vuelve entero y otro
-- que vuelve a medias: solo obligaba a responder cuatro veces lo mismo en un villancico de cuatro
-- coplas. El alcance por realización dice **de qué se responde**; el atajo dice **cómo se rellena**,
-- y son cosas distintas que no se estorban.

begin;

alter table public.grupos_eleccion_metrica
	drop constraint if exists grupos_eleccion_metrica_global_check;

update public.grupos_eleccion_metrica
set permite_aplicar_global = true,
	updated_at = now()
where alcance = 'realizacion' and not permite_aplicar_global;

do $$
declare
	v_n integer;
begin
	select count(*) into v_n
	from public.grupos_eleccion_metrica
	where alcance = 'realizacion' and not permite_aplicar_global;
	if v_n <> 0 then
		raise exception '% preguntas por aparición se quedaron sin el atajo', v_n;
	end if;

	select count(*) into v_n from public.grupos_eleccion_metrica where alcance = 'realizacion';
	if v_n <> 3 then
		raise exception 'Hay % preguntas por aparición en vez de 3', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

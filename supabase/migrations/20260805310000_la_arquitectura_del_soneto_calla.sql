-- La arquitectura del soneto no precisaba nada, y hablaba de más.
--
-- Decía: «Catorce endecasílabos consonantes repartidos en dos cuartetos y dos tercetos. Unos
-- y otros riman como lo hacen el cuarteto y el terceto endecasílabos, que son formas del
-- catálogo por derecho propio.»
--
-- La primera frase repite la definición de la forma palabra por palabra. La segunda explica
-- una relación interna del catálogo —que el cuarteto y el terceto existen aparte— que al
-- lector no le dice nada de cómo es un soneto, y «por derecho propio» es además una manera
-- rara de decirlo.
--
-- El soneto tiene una sola arquitectura, así que no hay hermanas de las que distinguirla: no
-- hay nada que una descripción pueda añadir aquí. **Se queda vacía**, que es la respuesta
-- honesta. La regla vale para el barrido que queda: si una arquitectura no precisa nada sobre
-- la definición de su forma, se calla en vez de parafrasearla.

begin;

update public.arquitecturas_forma a
set descripcion = null
from public.formas_metricas f
where f.forma_id = a.forma_id and f.slug = 'soneto';

comment on column public.arquitecturas_forma.descripcion is
	'Qué distingue a **esta** realización de sus hermanas. Si vale igual para todas, pertenece a la definición de la forma; y si la forma tiene una sola arquitectura, casi nunca hay nada que añadir. Vacía es mejor que una paráfrasis de la definición.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

begin;

-- La matriz de importación se retira.
--
-- Registraba, término a término del vocabulario heredado, qué clasificación se le proponía
-- al importarlo y a qué entidad del catálogo nuevo debía ir a parar. Sirvió para hacer la
-- importación y para no perder nada por el camino, pero desde entonces las decisiones han
-- cambiado tanto —la unidad, el metro, la limpieza, la nomenclatura— que sus pendientes ya
-- no describen nada actual: un término marcado «requiere revisión» en junio puede llevar
-- resuelto desde julio por una decisión que la matriz no conoce.
--
-- Antes de retirarla, su contenido y el del vocabulario que describe quedaron volcados en
-- [el vocabulario heredado](../../docs/dominio-metrico/historico/vocabulario-heredado.md):
-- los 119 términos con sus definiciones, rasgos, jerarquía de subtipos y destino actual.
-- Ninguno se quedó sin rastro. Ese documento es desde ahora la referencia para responder si
-- se perdió información al migrar o si algo quedó en un nivel que no le toca.
--
-- **`vocabularios` no se toca.** Las secuencias métricas ya registradas en las obras siguen
-- apuntando a esos términos, y `formas_metricas.origen_termino_id` sigue diciendo de cuál
-- procede cada forma. Lo que desaparece es la matriz de revisión, no el vocabulario.

drop table public.migracion_termino_destinos;
drop table public.migracion_terminos_metricos;
drop function if exists public.guardar_revision_migracion_metrica(jsonb);

update public.catalogo_metrico_estado
set modelo_version = 51,
	actualizado_en = now()
where id = true;

commit;

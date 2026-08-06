-- La nota de los cuartetos del soneto sobra desde que su rima se lee.
--
-- Decía: «Los dos cuartetos comparten sus dos clases de rima: no estrenan rima el segundo.»
--
-- Tenía sentido cuando la ficha no enseñaba la rima de los cuartetos por ninguna parte y la
-- nota era el único sitio donde se decía algo de ella. Ahora la sección la muestra —«ABBA
-- ABBA» y «ABAB ABAB», con la repetición escrita en la propia etiqueta—, y la nota repite en
-- prosa lo que esas dos notaciones ya dicen: que las clases del segundo cuarteto son las del
-- primero.
--
-- Es el mismo caso que el romance y la redondilla: **no escribir lo que la ficha deriva**. Con
-- la diferencia de que aquí lo que lo hace redundante no fue un cambio en el dato sino uno en
-- cómo se lee, que es un motivo igual de bueno para retirarlo.

begin;

update public.estructuras_secciones s
set nota = null
from public.arquitecturas_forma a
join public.formas_metricas f on f.forma_id = a.forma_id
where a.arquitectura_id = s.arquitectura_id
	and f.slug = 'soneto'
	and s.slug = 'cuarteto';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

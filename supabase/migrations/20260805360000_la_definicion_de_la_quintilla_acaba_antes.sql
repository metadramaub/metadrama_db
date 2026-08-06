-- La definición de la quintilla acababa una frase tarde.
--
-- Terminaba en: «La disposición no está fijada, y la tradición ha ido reconociendo las que
-- evitan tres versos seguidos con una misma rima, con la excepción de abbba.»
--
-- Que una tradición vaya reconociendo las posibilidades que aparecen no dice nada de la
-- quintilla: vale para cualquier forma. Y el detalle de `abbba` ya lo dice su propia
-- descripción, dos líneas más abajo en la misma ficha.
--
-- Lo que sí define a la quintilla —cinco octosílabos, dos clases de rima, ninguna en un solo
-- verso— está entero en la primera frase. Se corta ahí.

begin;

update public.formas_metricas
set definicion = 'Estrofa de cinco versos octosílabos con rima consonante repartida en dos clases, cada una en dos versos por lo menos: ninguno queda suelto.'
where slug = 'quintilla';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

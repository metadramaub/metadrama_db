-- La asonancia de la endecha real no va «en los pares».
--
-- La relación con el romance quedó diciendo que la endecha real «conserva su asonancia
-- sostenida en los pares». No es exacto: en el romance riman los versos pares, y en la endecha
-- real solo el cuarto de cada cuarteto. El segundo heptasílabo, que también es par, queda
-- suelto. Lo que conserva del romance es la asonancia **sostenida en una sola rima durante toda
-- la composición**, que es lo que la hace serie; no la posición donde cae.
--
-- Las fuentes usan «pares» porque cuentan sobre el cuarteto —Domínguez Caparrós escribe «los
-- versos pares de toda la composición»—, y en su cita puede quedar así. En nuestra prosa no,
-- porque de los dos pares del cuarteto solo rima uno.

begin;

update public.forma_relaciones r
set nota = 'Es un romance heptasílabo cuyo cuarto verso se alarga a endecasílabo. Conserva de él la asonancia única sostenida durante toda la composición y la extensión libre; lo que la separa es la heterometría regular y que la rima cae cada cuatro versos, no cada dos.'
from public.formas_metricas o, public.formas_metricas d
where o.forma_id = r.forma_origen_id
	and d.forma_id = r.forma_destino_id
	and o.slug = 'endecha_real'
	and d.slug = 'romance'
	and r.tipo_relacion = 'derivada_de';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

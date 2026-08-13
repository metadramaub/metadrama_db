-- Las notas que nadie lee salen del catálogo, y la que dice algo se queda.
--
-- Segunda tanda de la poda, aprobada campo a campo por el IP sobre `npm run poda:informe`.
--
--   · **Todas** las notas de posición métrica que sobraban: la ficha no ha enseñado nunca ese
--     campo, y lo que decían era la figura en palabras o el nombre de otra forma.
--   · Dos de las tres notas de posición de rima. **La de la décima aumentada se queda**: explica
--     cómo crece su miembro final respecto de la espinela, y eso no lo dibuja nada.
--   · Las notas de enlace que repetían el enlace. La ficha ya deriva la frase de un enlace a
--     partir de sus posiciones y su desplazamiento —«el verso 2 conserva su rima en cada
--     repetición»—, así que escribirlo otra vez a mano es la regla 1 de `donde-vive-la-prosa`.
--     Las tres que sí añaden algo se quedan.
--
-- Se vacían 39 notas, con su texto anterior en el comentario de cada una.

-- esquema_metrico_posiciones.nota · 31 notas

-- sextina/doble_montemayor · 11-repetido pos.1: «Esta posición se repite en los seis versos de los dos tercetos finales.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sextina' and a.slug = 'doble_montemayor'
	and em.slug = '11-repetido' and p.posicion = 1
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-11-7-11-7-11 pos.1: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-11-7-11-7-11' and p.posicion = 1
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-11-7-11-7-11 pos.2: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-11-7-11-7-11' and p.posicion = 2
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-11-7-11-7-11 pos.3: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-11-7-11-7-11' and p.posicion = 3
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-11-7-11-7-11 pos.4: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-11-7-11-7-11' and p.posicion = 4
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-11-7-11-7-11 pos.5: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-11-7-11-7-11' and p.posicion = 5
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-11-7-11-7-11 pos.6: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-11-7-11-7-11' and p.posicion = 6
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-7-11 pos.1: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-7-11' and p.posicion = 1
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-7-11 pos.2: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-7-11' and p.posicion = 2
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-7-11 pos.3: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-7-11' and p.posicion = 3
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-7-11 pos.4: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-7-11' and p.posicion = 4
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-7-11 pos.5: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-7-11' and p.posicion = 5
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-7-11 pos.6: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-7-11' and p.posicion = 6
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-11-7-11 pos.1: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-11-7-11' and p.posicion = 1
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-11-7-11 pos.2: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-11-7-11' and p.posicion = 2
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-11-7-11 pos.3: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-11-7-11' and p.posicion = 3
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-11-7-11 pos.4: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-11-7-11' and p.posicion = 4
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-11-7-11 pos.5: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-11-7-11' and p.posicion = 5
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-11-7-11 pos.6: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-11-7-11' and p.posicion = 6
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-7-7-11 pos.1: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-7-7-11' and p.posicion = 1
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-7-7-11 pos.2: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-7-7-11' and p.posicion = 2
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-7-7-11 pos.3: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-7-7-11' and p.posicion = 3
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-7-7-11 pos.4: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-7-7-11' and p.posicion = 4
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-7-7-11 pos.5: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-7-7-11' and p.posicion = 5
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 7-7-7-7-7-11 pos.6: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '7-7-7-7-7-11' and p.posicion = 6
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-11-11 pos.1: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-11-11' and p.posicion = 1
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-11-11 pos.2: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-11-11' and p.posicion = 2
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-11-11 pos.3: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-11-11' and p.posicion = 3
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-11-11 pos.4: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-11-11' and p.posicion = 4
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-11-11 pos.5: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-11-11' and p.posicion = 5
	and coalesce(p.alternativa, 1) = 1;

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-11-11 pos.6: «Posición fija de la tipología de sexteto-lira.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante'
	and em.slug = '11-7-7-11-11-11' and p.posicion = 6
	and coalesce(p.alternativa, 1) = 1;

-- esquema_rima_posiciones.nota · 2 notas

-- silva/consonante_regular · pareados-regulares pos.1: «Primer verso del pareado.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'silva' and a.slug = 'consonante_regular'
	and er.slug = 'pareados-regulares' and p.bloque = 1 and p.posicion = 1;

-- zejel/estribillo_y_coplas_monorrimas · estribillo-mudanza-vuelta pos.2: «Segundo verso cuando el estribillo es un dístico.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'zejel' and a.slug = 'estribillo_y_coplas_monorrimas'
	and er.slug = 'estribillo-mudanza-vuelta' and p.bloque = 1 and p.posicion = 2;

-- esquema_rima_enlaces.nota · 6 notas

-- terceto_encadenado/endecasilabica_consonante · encadenado-con-serventesio (2→1): «La rima central pasa al primer verso del terceto siguiente.»
update public.esquema_rima_enlaces l set nota = null, updated_at = now()
from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
where l.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'terceto_encadenado' and a.slug = 'endecasilabica_consonante'
	and er.slug = 'encadenado-con-serventesio' and l.posicion_origen = 2 and l.posicion_destino = 1;

-- terceto_encadenado/endecasilabica_consonante · encadenado-con-serventesio (2→3): «La rima central pasa al tercer verso del terceto siguiente.»
update public.esquema_rima_enlaces l set nota = null, updated_at = now()
from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
where l.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'terceto_encadenado' and a.slug = 'endecasilabica_consonante'
	and er.slug = 'encadenado-con-serventesio' and l.posicion_origen = 2 and l.posicion_destino = 3;

-- terceto_encadenado/octosilabica_consonante · encadenado-con-serventesio (2→1): «La rima central pasa al primer verso del terceto siguiente.»
update public.esquema_rima_enlaces l set nota = null, updated_at = now()
from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
where l.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'terceto_encadenado' and a.slug = 'octosilabica_consonante'
	and er.slug = 'encadenado-con-serventesio' and l.posicion_origen = 2 and l.posicion_destino = 1;

-- terceto_encadenado/octosilabica_consonante · encadenado-con-serventesio (2→3): «La rima central pasa al tercer verso del terceto siguiente.»
update public.esquema_rima_enlaces l set nota = null, updated_at = now()
from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
where l.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'terceto_encadenado' and a.slug = 'octosilabica_consonante'
	and er.slug = 'encadenado-con-serventesio' and l.posicion_origen = 2 and l.posicion_destino = 3;

-- endecha_real/heptasilabica_con_endecasilabo · asonantada (4→4): «La asonancia del endecasílabo se mantiene en el cuarteto siguiente y en todos los demás.»
update public.esquema_rima_enlaces l set nota = null, updated_at = now()
from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
where l.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'endecha_real' and a.slug = 'heptasilabica_con_endecasilabo'
	and er.slug = 'asonantada' and l.posicion_origen = 4 and l.posicion_destino = 4;

-- endecha_real/hexasilabica_con_endecasilabo · asonantada (4→4): «La asonancia del endecasílabo se mantiene en el cuarteto siguiente y en todos los demás.»
update public.esquema_rima_enlaces l set nota = null, updated_at = now()
from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
where l.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
	and a.forma_id = f.forma_id and f.slug = 'endecha_real' and a.slug = 'hexasilabica_con_endecasilabo'
	and er.slug = 'asonantada' and l.posicion_origen = 4 and l.posicion_destino = 4;

do $$
declare
	n integer;
begin
	-- La de la décima aumentada tenía que sobrevivir: es la excepción que pidió el IP.
	select count(*) into n
	from public.esquema_rima_posiciones p
	join public.esquemas_rima er using (esquema_rima_id)
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'decima' and a.slug = 'aumentada' and p.nota is not null;
	if n = 0 then
		raise exception 'se ha borrado la nota de la décima aumentada, que estaba salvada';
	end if;

	-- Y las notas de enlace que sí aportan.
	select count(*) into n from public.esquema_rima_enlaces where nota is not null;
	if n = 0 then
		raise exception 'no queda ninguna nota de enlace y tres tenían que quedarse';
	end if;
end;
$$;

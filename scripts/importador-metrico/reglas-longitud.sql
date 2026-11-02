-- Solo lectura. Referencia del importador: misma vista que consultan el editor v2 y la API.
select f.slug as forma, a.slug as arquitectura, r.*
from public.arquitecturas_reglas_longitud r
join public.arquitecturas_forma a using (arquitectura_id)
join public.formas_metricas f using (forma_id)
where a.activo and f.activo
order by f.slug, a.slug;

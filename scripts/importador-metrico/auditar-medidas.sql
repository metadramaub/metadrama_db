-- Solo lectura de definiciones. No ejecuta productores ni modifica artefactos.
select p.proname as nombre,p.oid::regprocedure::text as firma,pg_get_functiondef(p.oid) as definicion
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' and p.proname in (
  'analisis_obra_publico_json','corpus_comparativas_artefacto_json',
  'recompute_obra_resumen','recompute_obra_resumen_metricas','recompute_autor_resumen',
  'numero_efectivo_from_perfil','resumen_estadistico_json',
  'perfil_formas_rango','perfil_formas_hijos_rango','perfil_artefacto_obra_rango',
  'perfil_metrico_unidades','formas_de_la_obra'
) order by p.proname;

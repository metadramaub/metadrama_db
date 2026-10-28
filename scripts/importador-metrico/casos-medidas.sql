-- SELECT sobre datos sintéticos. No lee obras ni ejecuta productores de artefactos.
with muestra as (select 1 as v_ini,100 as v_fin),
  todas as (select unnest(array[0.6,0.0]::numeric[]) valor),
  presentes as (select valor from todas where valor>0)
select jsonb_build_object(
  'origen','Casos sintéticos de fórmulas y predicados observados; no ejecuta el pipeline completo',
  'diversidad_actual_una_forma_mitad_conocida',exp(-(0.5::numeric*ln(0.5::numeric))),
  'diversidad_condicionada_una_forma',exp(-(1.0::numeric*ln(1.0::numeric))),
  'mediana_todas_las_obras',(select percentile_cont(0.5) within group(order by valor) from todas),
  'mediana_donde_aparece',(select percentile_cont(0.5) within group(order by valor) from presentes),
  'filas_con_limites_nulos_predicado_actual',(select count(*) from muestra where v_ini>=null::integer and v_fin<=null::integer),
  'filas_con_limites_nulos_opcionales',(select count(*) from muestra where (null::integer is null or v_ini>=null::integer) and (null::integer is null or v_fin<=null::integer)),
  'densidad_actual_una_secuencia_100_versos',1::numeric/100*100,
  'cambios_entre_secuencias_una_secuencia',greatest(1-1,0),
  'perfil_confirmado_600_de_1000',600::numeric/1000,
  'perfil_maximo_si_200_pendientes_son_esa_forma',800::numeric/1000
) as casos;

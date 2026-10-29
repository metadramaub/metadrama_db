-- Entrada del ensayo. Solo SELECT; ejecutar únicamente en la copia Docker.
-- Las básicas se leen de la copia fija, nunca de jornadas/secuencias de trabajo.
begin read only;
select jsonb_build_object(
 'catalogo',(select jsonb_agg(jsonb_build_object('slug',f.slug,'tipo_registro',f.tipo_registro,
   'arquitecturas',coalesce((select jsonb_agg(a.slug order by a.slug) from public.arquitecturas_forma a where a.forma_id=f.forma_id),'[]'::jsonb)) order by f.slug)
   from public.formas_metricas f),
 'registros',(select coalesce(jsonb_agg(jsonb_build_object(
   'obra_id',o.obra_id,'publicada',v.termino='publicado',
   'basica',to_jsonb(i),
   'detallada',case when v.termino='publicado' then jsonb_build_object(
     'metadatos',jsonb_build_object('titulo',o.titulo,'edicion_base',o.edicion,
       'fecha_inicio',case when o.fecha_inicio_metadrama is not null or o.fecha_fin_metadrama is not null then o.fecha_inicio_metadrama else o.fecha_inicio_trad end,
       'fecha_fin',case when o.fecha_inicio_metadrama is not null or o.fecha_fin_metadrama is not null then o.fecha_fin_metadrama else o.fecha_fin_trad end,
       'criterio_fecha',case when o.fecha_inicio_metadrama is not null or o.fecha_fin_metadrama is not null then 'metadrama' else 'tradicional' end,
       'fuente_fecha',o.fuente_fecha),
     'jornadas',coalesce((select jsonb_agg(jsonb_build_object('ref',j.jornada_id,'numero',j.jornada_num,'v_ini',j.v_ini,'v_fin',j.v_fin) order by j.v_ini,j.jornada_id)
       from public.jornadas j where j.obra_id=o.obra_id),'[]'::jsonb),
     'autorias',coalesce((select jsonb_agg(jsonb_build_object('autor_id',u.autor_id,'ambito',u.scope,'jornada_id',u.jornada_id,'v_ini',u.jornada_v_ini,'v_fin',u.jornada_v_fin) order by u.autor_id,u.scope,u.jornada_id)
       from public.perfil_metrico_unidades() u where u.obra_id=o.obra_id),'[]'::jsonb),
     'secuencias',coalesce((select jsonb_agg(jsonb_build_object(
       'ref',s.secuencia_id,'v_ini',s.v_ini,'v_fin',s.v_fin,
       'forma_slug',s.forma_slug,'arquitectura_slug',s.arquitectura_slug,
       'n_anotaciones',(select count(*) from public.anotaciones_metricas x where x.secuencia_id=s.secuencia_id),
       'detalles',coalesce((select jsonb_agg(to_jsonb(e) order by e.eleccion_id) from public.anotacion_elecciones e where e.anotacion_id=a.anotacion_id),'[]'::jsonb),
       'desviaciones',coalesce((select jsonb_agg(to_jsonb(d) order by d.v_ini,d.desviacion_id) from public.anotacion_desviaciones d where d.anotacion_id=a.anotacion_id),'[]'::jsonb)
       ) order by s.v_ini,s.secuencia_id)
       from public.formas_de_la_obra(o.obra_id) s
       left join lateral (select x.anotacion_id from public.anotaciones_metricas x where x.secuencia_id=s.secuencia_id order by x.orden,x.anotacion_id limit 1) a on true),'[]'::jsonb),
     'evidencia_adicional',jsonb_build_object('estado_editorial','publicado','exhaustividad_auditada',false,
       'realizaciones',coalesce((select jsonb_agg(to_jsonb(r) order by r.anotacion_id,r.orden,r.realizacion_id)
         from public.anotacion_realizaciones r join public.anotaciones_metricas am using(anotacion_id)
         join public.secuencias_metricas sm using(secuencia_id) where sm.obra_id=o.obra_id),'[]'::jsonb),
       'caracterizaciones',coalesce((select jsonb_agg(to_jsonb(c) order by c.secuencia_id,c.v_ini,c.v_fin,c.caracterizacion_rango_id)
         from public.secuencias_caracterizaciones_rango c join public.secuencias_metricas sm using(secuencia_id) where sm.obra_id=o.obra_id),'[]'::jsonb))
   ) else null end
 ) order by o.obra_id),'[]'::jsonb)
 from public.obras o join public.vocabularios v on v.termino_id=o.estado
 left join public.importaciones_metricas i on i.obra_id=o.obra_id and i.usada_en_corpus
 where (o.tipo_ficha='completa' and v.termino='publicado') or i.importacion_id is not null)
);
commit;

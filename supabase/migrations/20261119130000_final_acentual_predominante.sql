begin;

alter table public.anotaciones_metricas
	add column final_acentual_predominante text
	check (final_acentual_predominante in ('agudo', 'esdrujulo'));

-- Una observación se refiere a los límites exactos que se leyeron.
create function public.limpiar_final_acentual_al_cambiar_tramo()
returns trigger language plpgsql set search_path = public as $$
begin
	if row(old.secuencia_id, old.escenario_id, old.v_ini, old.v_fin)
		is distinct from row(new.secuencia_id, new.escenario_id, new.v_ini, new.v_fin) then
		new.final_acentual_predominante := null;
	end if;
	return new;
end;
$$;

create trigger limpiar_final_acentual_al_cambiar_tramo
	before update of secuencia_id, escenario_id, v_ini, v_fin on public.anotaciones_metricas
	for each row execute function public.limpiar_final_acentual_al_cambiar_tramo();

-- El mismo dato efectivo alimenta la ficha, los recuentos y el filtro.
create function public.final_acentual_de_secuencia(p_anotacion uuid)
returns text language sql stable set search_path = public as $$
	select case when f.slug in ('endecasilabo_suelto', 'endecasilabo_encadenado') and exists (
		select 1
		from public.anotacion_elecciones_resueltas e
		join public.grupos_eleccion_metrica g using (grupo_eleccion_id)
		join public.rasgo_valores rv on rv.valor_id = e.valor_rasgo_id
		join public.rasgos_metricos rm on rm.rasgo_id = rv.rasgo_id
		where e.anotacion_id = a.anotacion_id
			and g.slug = 'final_acentual_destacado' and g.alcance = 'secuencia'
			and rm.slug = 'final_acentual' and rv.slug = 'esdrujulo'
			and num_nonnulls(e.realizacion_id, e.posicion_unidad, e.repeticion_id,
				e.seccion_id, e.seccion_tratada_id) = 0
	) then 'esdrujulo' else a.final_acentual_predominante end
	from public.anotaciones_metricas a
	join public.formas_metricas f using (forma_id)
	left join public.secuencias_metricas s using (secuencia_id)
	where a.anotacion_id = p_anotacion and a.v_fin > a.v_ini
		and f.slug not in ('verso_aislado', 'prosa')
		and (a.escenario_id is not null or (a.v_ini = s.v_ini and a.v_fin = s.v_fin));
$$;

create function public.recuento_final_acentual_autor(p_autor uuid, p_alcance text)
returns jsonb language sql stable set search_path = public as $$
	with secuencias as (
		select distinct s ->> 'secuencia_id' as secuencia_id,
			s ->> 'final_acentual_predominante' as valor
		from public.perfil_metrico_unidades() u
		join public.obras_editoriales o on o.obra_id = u.obra_id
		join public.vocabularios v on v.termino_id = o.estado
		join public.obras_resumen r on r.obra_id = o.obra_id
		cross join lateral jsonb_array_elements(coalesce(r.ficha #> '{metrica,secuencias}', '[]'::jsonb)) s
		where u.autor_id = p_autor and o.tipo_ficha = 'completa'
			and v.categoria = 'estado' and lower(v.termino) = 'publicado'
			and (p_alcance = 'completo' or o.visible_publico)
			and s ->> 'final_acentual_predominante' in ('agudo', 'esdrujulo')
			and (u.jornada_id is null or (
				(s ->> 'v_ini')::integer >= u.jornada_v_ini and (s ->> 'v_fin')::integer <= u.jornada_v_fin
			))
	)
	select coalesce(jsonb_object_agg(valor, cantidad), '{}'::jsonb)
	from (select valor, count(*) as cantidad from secuencias where valor is not null group by valor) c;
$$;

revoke all on function public.final_acentual_de_secuencia(uuid) from public, anon, authenticated;
revoke all on function public.recuento_final_acentual_autor(uuid, text) from public, anon, authenticated;

-- Los productores conservan su propietario y sus permisos al reemplazar el cuerpo.
do $$
declare
	propietario_ficha text;
	propietario_autor text;
begin
	select pg_get_userbyid(proowner) into propietario_ficha
	from pg_proc where oid = 'public.ficha_publica_dominio_json(uuid,boolean)'::regprocedure;
	select pg_get_userbyid(proowner) into propietario_autor
	from pg_proc where oid = 'public.autor_ficha_artefacto_json(uuid,text)'::regprocedure;
	execute format('grant execute on function public.final_acentual_de_secuencia(uuid) to %I',
		propietario_ficha);
	execute format('grant execute on function public.recuento_final_acentual_autor(uuid,text) to %I',
		propietario_autor);
end;
$$;

do $migracion$
declare
	cambio record;
	original text;
	nueva text;
begin
	for cambio in select * from (values
		('public.guardar_anotacion_metrica(jsonb)',
		'delete from public.anotacion_desviaciones',
		$sql$
		-- Los finales que ya estaban en un rango se pueden guardar de nuevo con ese rango.
		if exists (
			select 1
			from (
				select rv.valor_id, (d ->> 'v_ini')::integer as v_ini,
					(d ->> 'v_fin')::integer as v_fin, count(*) as cantidad
				from jsonb_array_elements(coalesce(p_datos -> 'desviaciones', '[]'::jsonb)) d
				join public.rasgo_valores rv on rv.valor_id = nullif(d ->> 'valor_rasgo_observado_id', '')::uuid
				join public.rasgos_metricos rm on rm.rasgo_id = rv.rasgo_id
				where rm.slug = 'final_acentual' and rv.slug in ('agudo', 'esdrujulo')
				group by 1, 2, 3
			) propuesta
			where propuesta.cantidad > (
				select count(*) from public.anotacion_desviaciones anterior
				where anterior.anotacion_id = v_secuencia_id
					and anterior.valor_rasgo_observado_id = propuesta.valor_id
					and anterior.v_ini = propuesta.v_ini
					and anterior.v_fin = propuesta.v_fin
			)
		) then
			raise exception 'Registra los finales agudos o esdrújulos como final acentual predominante.';
		end if;

		delete from public.anotacion_desviaciones$sql$),
		('public.guardar_anotacion_metrica(jsonb)',
		'return v_secuencia_id;',
		$sql$
		if p_datos ? 'final_acentual_predominante' then
			if p_datos ->> 'final_acentual_predominante' is not null and (
				v_v_fin <= v_v_ini
				or v_v_ini <> (p_datos ->> 'v_ini')::integer
				or v_v_fin <> (p_datos ->> 'v_fin')::integer
				or exists (
					select 1 from public.formas_metricas
					where forma_id = (p_datos ->> 'forma_id')::uuid and slug in ('verso_aislado', 'prosa')
				)
				or (v_real_id is not null and not exists (
					select 1 from public.obras_editoriales o
					where o.obra_id = v_real.obra_id and o.tipo_ficha = 'completa'
				))
			) then
				raise exception 'El final predominante requiere al menos dos versos de la misma secuencia detallada.';
			end if;
			update public.anotaciones_metricas
			set final_acentual_predominante = p_datos ->> 'final_acentual_predominante'
			where anotacion_id = v_secuencia_id;
		end if;
		return v_secuencia_id;$sql$),
		('public.ficha_publica_dominio_json(uuid,boolean)',
		'''rasgos'', v_features,',
		'''rasgos'', v_features, ''final_acentual_predominante'', public.final_acentual_de_secuencia(v_annotation_id),'),
		('public.analisis_obra_publico_json(uuid)',
		'''rasgos'', coalesce(s.value -> ''rasgos'', ''[]''::jsonb),',
		'''rasgos'', coalesce(s.value -> ''rasgos'', ''[]''::jsonb),
		 ''final_acentual_predominante'', s.value -> ''final_acentual_predominante'','),
		('public.autor_ficha_artefacto_json(uuid,text)',
		'''n_obras_completas'', v_resumen.n_obras_completas,',
		'''n_obras_completas'', v_resumen.n_obras_completas,
		 ''finales_acentuales'', public.recuento_final_acentual_autor(p_autor_id, p_alcance),'),
		('public.recompute_artefactos_globales()',
		'''variaciones_presentes'', coalesce(r.variaciones_presentes, array[]::text[]),',
		$sql$'variaciones_presentes', coalesce(r.variaciones_presentes, array[]::text[]),
		'finales_acentuales_presentes', array(
			select distinct s ->> 'final_acentual_predominante'
			from jsonb_array_elements(coalesce(r.ficha #> '{metrica,secuencias}', '[]'::jsonb)) s
			where s ->> 'final_acentual_predominante' in ('agudo', 'esdrujulo')
			order by 1
		),$sql$),
		('public.corpus_comparativas_artefacto_json(text)',
		'''perfil_formas'', coalesce(analisis -> ''perfil_formas'', ''{}''::jsonb),',
		$sql$'perfil_formas', coalesce(analisis -> 'perfil_formas', '{}'::jsonb),
		'finales_acentuales', (
			select coalesce(jsonb_agg(jsonb_build_object(
				'forma', s ->> 'forma', 'v_ini', s -> 'i', 'v_fin', s -> 'f',
				'valor', s ->> 'final_acentual_predominante'
			) order by (s ->> 'i')::integer), '[]'::jsonb)
			from jsonb_array_elements(coalesce(analisis -> 'secuencias', '[]'::jsonb)) s
			where s ->> 'final_acentual_predominante' in ('agudo', 'esdrujulo')
		),$sql$)
	) as cambios(firma, ancla, reemplazo)
	loop
		original := pg_get_functiondef(cambio.firma::regprocedure);
		nueva := replace(original, cambio.ancla, cambio.reemplazo);
		if nueva = original or (length(original) - length(replace(original, cambio.ancla, ''))) <> length(cambio.ancla) then
			raise exception 'No se encontró una sola ancla para el final acentual en %', cambio.firma;
		end if;
		execute nueva;
	end loop;
end;
$migracion$;

update public.obras_resumen set metrica_sucia = true;
update public.autores_resumen set metrica_sucia = true;
notify pgrst, 'reload schema';
commit;

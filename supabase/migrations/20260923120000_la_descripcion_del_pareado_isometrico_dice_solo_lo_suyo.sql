-- La descripción del pareado isométrico dice solo lo que lo distingue de su hermana
--
-- La migración anterior le escribió una descripción de cuatro renglones que contaba dónde aparece el
-- pareado —estribillos, refranes, máximas, motes y divisas— y qué pasa cuando los dos versos no
-- miden igual. Lo primero ya está en la definición de la forma, que es su sitio; lo segundo es de la
-- alirada. Una descripción de arquitectura dice qué la separa de sus hermanas y nada más.
--
-- Tampoco le toca hablar de «norma» ni de «pasaje»: son palabras del modelo y del anotador, no de la
-- prosa del catálogo.

begin;

do $cambio$
declare
	v_arq uuid;
	v_actual text;
begin
	select a.arquitectura_id, a.descripcion into v_arq, v_actual
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'pareado' and a.slug = 'cualquier_medida';

	if v_arq is null then
		raise exception 'No existe la arquitectura isométrica del pareado.';
	end if;

	update public.arquitecturas_forma
	set descripcion = 'Los dos versos son de la misma medida, cualquiera que esta sea.',
		updated_at = now()
	where arquitectura_id = v_arq;
end
$cambio$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

do $guarda$
declare
	v_descripcion text;
	v_alirado text;
begin
	select a.descripcion into v_descripcion
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'pareado' and a.slug = 'cualquier_medida';

	if v_descripcion <> 'Los dos versos son de la misma medida, cualquiera que esta sea.' then
		raise exception 'La descripción del pareado isométrico no es la que esta migración escribe.';
	end if;

	-- La de su hermana no se ha tocado: es la que sigue diciendo cuál es la mezcla.
	select a.descripcion into v_alirado
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'pareado' and a.slug = 'alirado';

	if v_alirado not like 'Los dos versos son uno heptasílabo y otro endecasílabo%' then
		raise exception 'La descripción del pareado alirado ha cambiado.';
	end if;
end
$guarda$;

commit;

-- El zéjel conserva la prosa que aclara lo que la figura no puede decir por sí sola: la rima de
-- la mudanza cambia en cada ciclo y «cabeza» nombra la primera posición del estribillo. Las demás
-- glosas repetían letras, cantidades, jerarquías o comportamientos ya estructurados.

begin;

do $$
declare
	actualizadas integer;
begin
	update public.formas_metricas
	set definicion = 'Composición de forma fija y arte menor, normalmente octosílaba, que abre con un estribillo de uno o dos versos y continúa con una o más coplas. Cada copla se divide en una mudanza de tres versos monorrimos, con una rima nueva en cada estrofa, y un verso de vuelta que recupera la rima del estribillo; después el estribillo suele repetirse. Se distingue del villancico por la mudanza monorrima de tres versos y porque la vuelta sigue directamente, sin verso de enlace.',
		updated_at = now()
	where slug = 'zejel'
		and definicion = 'Composición de forma fija y arte menor, normalmente octosílaba, que abre con un estribillo de uno o dos versos y continúa con una o más coplas. Cada copla se divide en una mudanza de tres versos monorrimos, con una rima nueva en cada estrofa, y un verso de vuelta que recupera la rima del estribillo; después el estribillo suele repetirse. Se distingue del villancico por esa mudanza monorrima, frente a la redondilla, y porque la vuelta sigue a la mudanza sin verso de enlace.';
	get diagnostics actualizadas = row_count;
	if actualizadas <> 1 then
		raise exception 'se esperaba actualizar una definición del zéjel y se actualizaron %', actualizadas;
	end if;

	update public.esquemas_rima er
	set descripcion = 'El estribillo mantiene su rima; cada mudanza emplea una rima nueva en sus tres versos y la vuelta recupera la del estribillo.',
		updated_at = now()
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where er.arquitectura_id = a.arquitectura_id
		and f.slug = 'zejel'
		and er.slug = 'estribillo-mudanza-vuelta'
		and er.descripcion = 'El estribillo comparte una clase de rima; cada mudanza introduce una clase nueva en sus tres versos y la vuelta recupera la del estribillo.';
	get diagnostics actualizadas = row_count;
	if actualizadas <> 1 then
		raise exception 'se esperaba actualizar una glosa de rima del zéjel y se actualizaron %', actualizadas;
	end if;

	update public.esquema_rima_posiciones p
	set nota = null, updated_at = now()
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where p.esquema_rima_id = er.esquema_rima_id
		and f.slug = 'zejel'
		and er.slug = 'estribillo-mudanza-vuelta'
		and p.nota in (
			'Primer verso del estribillo inicial.',
			'Primera posición monorrima de la mudanza.',
			'Segunda posición monorrima de la mudanza.',
			'Tercera posición monorrima de la mudanza.',
			'Verso de vuelta: recupera la rima del estribillo.'
		);
	get diagnostics actualizadas = row_count;
	if actualizadas <> 5 then
		raise exception 'se esperaban cinco notas posicionales y se vaciaron %', actualizadas;
	end if;

	update public.esquema_rima_enlaces e
	set nota = 'La vuelta recupera directamente la rima del estribillo, sin verso de enlace.',
		updated_at = now()
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where e.esquema_rima_id = er.esquema_rima_id
		and f.slug = 'zejel'
		and er.slug = 'estribillo-mudanza-vuelta'
		and e.nota = 'La vuelta enlaza directamente con la rima del estribillo; el zéjel no añade un verso de enlace independiente.';
	get diagnostics actualizadas = row_count;
	if actualizadas <> 1 then
		raise exception 'se esperaba actualizar una nota de enlace del zéjel y se actualizaron %', actualizadas;
	end if;

	update public.estructuras_secciones s
	set nota = null, updated_at = now()
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where s.arquitectura_id = a.arquitectura_id
		and f.slug = 'zejel'
		and (
			(s.slug = 'ciclo_copla' and s.nota = 'Contenedor repetible. La copla y la posible represa son secciones hermanas.')
			or (s.slug = 'copla' and s.nota = 'Unidad fija de cuatro versos: tres de mudanza y uno de vuelta.')
			or (s.slug = 'mudanza' and s.nota = 'Tres versos con una nueva rima común.')
			or (s.slug = 'represa' and s.nota = 'Reaparición material completa del estribillo después de la copla. En la bibliografía se denomina represa.')
			or (s.slug = 'vuelta' and s.nota = 'Recupera la rima del estribillo sin verso de enlace independiente.')
		);
	get diagnostics actualizadas = row_count;
	if actualizadas <> 5 then
		raise exception 'se esperaban cinco notas de sección y se vaciaron %', actualizadas;
	end if;

	update public.repeticiones_metricas r
	set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where r.arquitectura_id = a.arquitectura_id
		and f.slug = 'zejel'
		and (
			(r.slug = 'represa_ausente' and r.descripcion = 'Registra solo la ausencia observable de represa material, sin afirmar una repetición implícita.')
			or (r.slug = 'represa_total' and r.descripcion = 'Reaparición material completa; su extensión se deriva de la cabeza.')
		);
	get diagnostics actualizadas = row_count;
	if actualizadas <> 2 then
		raise exception 'se esperaban dos descripciones de repetición y se vaciaron %', actualizadas;
	end if;

	select count(*) into actualizadas
	from public.estructuras_secciones s
	join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'zejel'
		and s.nota = 'La función es estribillo; «cabeza» indica que su primera aparición abre la composición.';
	if actualizadas <> 1 then
		raise exception 'la nota terminológica de la cabeza no quedó conservada';
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

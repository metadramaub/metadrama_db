-- El villancico conserva en la definición una lectura continua de la forma, pero deja de repetir
-- en cada dimensión lo que ya expresan la rejilla, el árbol y las elecciones estructuradas.
--
-- La relación de rima entre mudanza, enlace o vuelta y estribillo no se formaliza aquí: sus
-- realizaciones son demasiado variables para reducirlas a una restricción única. Queda inventariada
-- la duda de si el Editor V2 debe registrar por separado la rima del estribillo y la del enlace.
-- `grupos_eleccion_metrica.ayuda_editor` no es prosa pública y se conserva intacta.

begin;

do $$
declare
	actualizadas integer;
	ayudas_antes integer;
	ayudas_despues integer;
begin
	select count(*) into ayudas_antes
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico'
		and g.slug = 'represa_estribillo'
		and g.ayuda_editor = 'La edición crítica debe ofrecer los versos repetidos. Indica si vuelve el estribillo entero o solo una parte.';
	if ayudas_antes <> 2 then
		raise exception 'se esperaban dos ayudas editoriales de represa y se encontraron %', ayudas_antes;
	end if;

	update public.formas_metricas
	set definicion = 'Forma compuesta de arte menor articulada por un estribillo y una o más coplas. En su configuración clásica, un estribillo inicial o cabeza de dos a cuatro versos abre la composición; cada copla contiene una mudanza, normalmente de cuatro versos organizados en dos miembros simétricos, y suele incluir un enlace o vuelta cuyo primer verso enlaza con la rima final de la mudanza y cuyos versos finales recuperan la rima del estribillo. Este puede repetirse total o parcialmente después de cada copla. Predominan los octosílabos y hexasílabos, que pueden distribuirse de manera distinta entre el estribillo y las coplas. La tradición documenta ampliaciones y supresiones de estas partes, así como configuraciones en las que una copla precede a la primera aparición del estribillo.',
		updated_at = now()
	where slug = 'villancico'
		and definicion = 'Forma compuesta de arte menor articulada por un estribillo y una o más coplas. En su configuración clásica, un estribillo inicial o cabeza de dos a cuatro versos abre la composición; cada copla contiene una mudanza, normalmente de cuatro versos organizados en dos miembros simétricos, y una vuelta cuyo primer verso enlaza con la rima final de la mudanza y cuyos versos finales recuperan la rima de la cabeza. El estribillo puede repetirse total o parcialmente después de cada copla. Predominan los octosílabos y hexasílabos. La tradición documenta ampliaciones y supresiones de estas partes, además de una modalidad moderna en la que una cuarteta precede al estribillo.';
	get diagnostics actualizadas = row_count;
	if actualizadas <> 1 then
		raise exception 'se esperaba actualizar una definición de villancico y se actualizaron %', actualizadas;
	end if;

	with objetivo(slug, descripcion_actual, descripcion_nueva) as (values
		(
			'estribillo_inicial',
			'El estribillo inicial funciona como cabeza. Le siguen una o más coplas, formadas por mudanza y vuelta, y las repeticiones totales o parciales del estribillo.',
			'El estribillo inicial funciona como cabeza. Le siguen uno o más ciclos formados por una copla —con mudanza y, cuando aparece, enlace o vuelta— y una posible repetición total o parcial del estribillo.'
		),
		(
			'estribillo_tras_primera_copla',
			'Modalidad moderna en la que una primera copla precede a la primera aparición del estribillo. Navarro Tomás documenta como realización general una cuarteta octosilábica seguida, sin enlace ni vuelta, por un estribillo en cuarteta hexasílaba.',
			'Configuración en la que una copla precede a la primera aparición del estribillo. El estribillo y las mudanzas pueden emplear medidas distintas; una realización combina una cuarteta octosilábica con un estribillo en cuarteta hexasílaba, sin enlace ni vuelta.'
		)
	)
	update public.arquitecturas_forma a
	set descripcion = o.descripcion_nueva, updated_at = now()
	from objetivo o
	join public.formas_metricas f on f.slug = 'villancico'
	where a.forma_id = f.forma_id and a.slug = o.slug and a.descripcion = o.descripcion_actual;
	get diagnostics actualizadas = row_count;
	if actualizadas <> 2 then
		raise exception 'se esperaban dos descripciones de arquitectura y se actualizaron %', actualizadas;
	end if;

	update public.esquemas_metricos em
	set descripcion = 'El estribillo y las coplas suelen compartir medida, pero pueden emplear metros distintos.',
		updated_at = now()
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where em.arquitectura_id = a.arquitectura_id
		and f.slug = 'villancico'
		and em.slug = 'conjunto-6-8'
		and em.medida_uniforme
		and em.descripcion = 'La forma emplea versos de arte menor, normalmente hexasílabos u octosílabos, sin imponer una secuencia posicional única.';
	get diagnostics actualizadas = row_count;
	if actualizadas <> 2 then
		raise exception 'se esperaban dos glosas métricas y se actualizaron %', actualizadas;
	end if;

	-- El disparador de esquemas fijos regenera las cuatro posiciones desde la notación: los impares
	-- quedan sueltos y los pares comparten una única asonancia.
	update public.esquemas_rima er
	set slug = '-a-a', notacion = '-a-a', descripcion = null, updated_at = now()
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where er.arquitectura_id = a.arquitectura_id
		and f.slug = 'villancico'
		and er.slug = 'abcb'
		and er.notacion = 'abcb'
		and er.descripcion = 'El segundo y el cuarto verso comparten asonancia; los demás no se vinculan a ella.';
	get diagnostics actualizadas = row_count;
	if actualizadas <> 2 then
		raise exception 'se esperaban dos mudanzas asonantadas y se actualizaron %', actualizadas;
	end if;

	update public.estructuras_secciones s
	set nota = case
			when s.slug = 'mudanza' then 'Suele organizar sus cuatro versos en dos miembros simétricos.'
			else null
		end,
		updated_at = now()
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where s.arquitectura_id = a.arquitectura_id
		and f.slug = 'villancico'
		and (
			(s.slug = 'copla' and s.nota = 'Unidad formada por una mudanza y, cuando se realiza, por el enlace o vuelta.')
			or (s.slug = 'mudanza' and s.nota = 'Parte de la copla anterior al enlace o vuelta, normalmente organizada en dos miembros simétricos.')
			or (s.slug = 'enlace_vuelta' and s.nota = 'Parte final de la copla que enlaza la mudanza con el estribillo.')
			or (a.slug = 'estribillo_inicial' and s.slug = 'cabeza' and s.nota = 'Primera aparición del estribillo cuando ocupa la posición inicial de la composición.')
			or (a.slug = 'estribillo_inicial' and s.slug = 'ciclo_copla' and s.nota = 'Unidad repetible formada por una copla y la repetición del estribillo que la sigue.')
			or (a.slug = 'estribillo_inicial' and s.slug = 'represa' and s.nota = 'Reaparición del estribillo después de una copla.')
			or (a.slug = 'estribillo_tras_primera_copla' and s.slug = 'ciclo_copla' and s.nota = 'Unidad repetible formada por una copla y el estribillo que la sigue.')
			or (a.slug = 'estribillo_tras_primera_copla' and s.slug = 'estribillo' and s.nota = 'El estribillo que sigue a cada copla. En el primer ciclo es su primera aparición; en los siguientes, una repetición total o parcial.')
		);
	get diagnostics actualizadas = row_count;
	if actualizadas <> 11 then
		raise exception 'se esperaban once notas de sección y se actualizaron %', actualizadas;
	end if;

	update public.repeticiones_metricas r
	set descripcion = case
			when r.slug = 'represa_parcial' then 'Se repiten solo algunos versos del estribillo completo, a menudo los dos últimos.'
			else null
		end,
		updated_at = now()
	from public.arquitecturas_forma a
	join public.formas_metricas f on f.forma_id = a.forma_id
	where r.arquitectura_id = a.arquitectura_id
		and f.slug = 'villancico'
		and (
			(r.slug = 'represa_total' and r.descripcion = 'El estribillo vuelve entero, con todos sus versos.')
			or (r.slug = 'represa_parcial' and r.descripcion = 'Solo vuelve una parte del estribillo; se registran únicamente los versos presentes.')
		);
	get diagnostics actualizadas = row_count;
	if actualizadas <> 4 then
		raise exception 'se esperaban cuatro glosas de repetición y se actualizaron %', actualizadas;
	end if;

	update public.forma_relaciones r
	set nota = 'Ambas formas articulan estribillo y coplas. El zéjel fija una mudanza monorrima de tres versos seguida directamente por la vuelta. El villancico emplea habitualmente una mudanza de cuatro versos —consonante en `abba` o `abab`, aunque también admite una disposición asonantada— y puede incorporar un enlace antes de recuperar el estribillo.',
		updated_at = now()
	from public.formas_metricas origen, public.formas_metricas destino
	where r.forma_origen_id = origen.forma_id
		and r.forma_destino_id = destino.forma_id
		and origen.slug = 'villancico'
		and destino.slug = 'zejel'
		and r.tipo_relacion = 'contrasta_con'
		and r.nota = 'Ambas formas articulan estribillo y coplas. El zéjel fija una mudanza monorrima de tres versos seguida directamente por la vuelta; el villancico admite otras mudanzas y puede incorporar enlace o vuelta.';
	get diagnostics actualizadas = row_count;
	if actualizadas <> 1 then
		raise exception 'se esperaba actualizar una relación con el zéjel y se actualizaron %', actualizadas;
	end if;

	select count(*) into ayudas_despues
	from public.grupos_eleccion_metrica g
	join public.arquitecturas_forma a on a.arquitectura_id = g.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico'
		and g.slug = 'represa_estribillo'
		and g.ayuda_editor = 'La edición crítica debe ofrecer los versos repetidos. Indica si vuelve el estribillo entero o solo una parte.';
	if ayudas_despues <> ayudas_antes then
		raise exception 'la ayuda editorial de represa cambió durante la poda';
	end if;
end;
$$;

do $$
declare
	incorrectas integer;
	esquemas integer;
begin
	select count(*) into esquemas
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and er.slug = '-a-a' and er.notacion = '-a-a';
	if esquemas <> 2 then
		raise exception 'se esperaban dos disposiciones -a-a y se encontraron %', esquemas;
	end if;

	select count(*) into incorrectas
	from public.esquemas_rima er
	join public.arquitecturas_forma a on a.arquitectura_id = er.arquitectura_id
	join public.formas_metricas f on f.forma_id = a.forma_id
	where f.slug = 'villancico' and er.slug = '-a-a'
		and (
			select count(*) <> 4
				or count(*) filter (where p.posicion in (1, 3) and p.suelto and p.clase_rima is null) <> 2
				or count(*) filter (where p.posicion in (2, 4) and not p.suelto and p.clase_rima = 'a') <> 2
			from public.esquema_rima_posiciones p
			where p.esquema_rima_id = er.esquema_rima_id
		);
	if incorrectas <> 0 then
		raise exception '% disposiciones -a-a no tienen dos impares sueltos y una asonancia en los pares', incorrectas;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

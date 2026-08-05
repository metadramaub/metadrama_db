-- El romance: definición, descripciones y lo que dicen las fuentes.
--
-- Primera forma de la revisión de definiciones, y la que más pesa en el corpus con 71
-- secuencias. Se aplica la política acordada: la definición afirma lo que la forma es, en
-- tercera persona, sin hablar del catálogo ni del registrador; y las fuentes entran cuando
-- dicen algo que la definición no puede llevar sin volverse farragosa.
--
-- Qué cambia y por qué:
--
-- · La definición terminaba diciendo «el catálogo distingue configuraciones exactas de seis,
--   siete, ocho y once sílabas». Eso habla del catálogo, no del romance, y además usa
--   «configuración», que es vocabulario retirado. Lo que sí dice del romance, y lo dicen las
--   dos fuentes, es que el octosílabo es su realización no marcada y que las demás medidas
--   reciben nombre propio.
--
-- · Las cuatro descripciones de arquitectura repetían «con una misma asonancia en los versos
--   pares y versos impares sueltos», que es exactamente la definición de la forma. Una
--   descripción debe decir lo que distingue a **esa** arquitectura de sus hermanas, que aquí
--   es solo la medida y lo que la tradición ha hecho con ella.
--
-- · «Configuración prototípica» pasa a decirse en castellano: cuando se dice «romance» sin
--   más, se entiende octosílabo.

begin;

do $$
declare
	v_forma uuid;
	v_caparros uuid;
	v_mb uuid;
	v_arq record;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'romance';
	select fuente_id into v_caparros from public.fuentes_metricas
	where autoria like '%Domínguez Caparrós%' and titulo like '%Diccionario%';
	select fuente_id into v_mb from public.fuentes_metricas
	where autoria like '%Morley%';

	if v_forma is null or v_caparros is null or v_mb is null then
		raise exception 'Falta el romance o alguna de las dos fuentes que lo documentan';
	end if;

	update public.formas_metricas
	set definicion = 'Serie abierta de versos isométricos en la que los pares comparten una misma asonancia y los impares quedan sueltos. Su extensión no está fijada de antemano. El octosílabo es su realización no marcada —cuando se dice «romance» sin más, se entiende octosílabo—, y las demás medidas reciben nombre propio.'
	where forma_id = v_forma;

	for v_arq in
		select a.arquitectura_id, a.slug
		from public.arquitecturas_forma a
		where a.forma_id = v_forma
	loop
		update public.arquitecturas_forma
		set descripcion = case v_arq.slug
			when 'octosilabica' then
				'Realización no marcada del romance, y la más frecuente en el teatro del Siglo de Oro.'
			when 'heptasilabica' then
				'Romance en heptasílabos. La tradición lo llama romancillo, y endecha cuando el asunto es luctuoso.'
			when 'hexasilabica' then
				'Romance en hexasílabos, que la tradición cuenta también entre los romancillos.'
			when 'endecasilabica' then
				'Romance en endecasílabos, el único de arte mayor. Se conoce como romance heroico o romance real.'
			else descripcion
		end
		where arquitectura_id = v_arq.arquitectura_id;
	end loop;

	-- Las fuentes: solo lo que añade o precisa algo que la definición no lleva.
	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, forma_id, arquitectura_id, localizador, resumen, confianza)
	select * from (values
		(v_caparros, v_forma, null::uuid, 's. v. romance',
			'Define el romance como serie de octosílabos indeterminada en número de versos, con asonancia en los pares y los impares sueltos, y añade que puede dividirse por el sentido en grupos de cuatro versos y admitir estribillos intercalados.',
			'alta'),
		(v_caparros, v_forma, null::uuid, 's. v. romance',
			'Cuando el romance se compone en versos distintos del octosílabo, recibe denominaciones específicas. Es la razón de que la medida sea aquí una arquitectura y no un rasgo.',
			'alta'),
		(v_mb, v_forma, null::uuid, 'V, «Romance»',
			'Nombra las variedades por su medida: romancillo o endechas en seis y siete sílabas, romance heroico o romance real en once.',
			'alta')
	) as t(fuente_id, forma_id, arquitectura_id, localizador, resumen, confianza)
	where not exists (
		select 1 from public.afirmaciones_fuentes_metricas x
		where x.fuente_id = t.fuente_id and x.forma_id = t.forma_id
			and x.resumen = t.resumen
	);

	-- Y una precisión que solo toca a una arquitectura.
	insert into public.afirmaciones_fuentes_metricas
		(fuente_id, arquitectura_id, localizador, resumen, confianza)
	select v_caparros, a.arquitectura_id, 's. v. endecha',
		'«Endecha» nombra el asunto antes que la forma: hay endechas en redondillas o en versos sueltos, y como romancillo admite además versos de cinco o seis sílabas. Por eso figura como denominación y no como identidad de esta arquitectura.',
		'alta'
	from public.arquitecturas_forma a
	where a.forma_id = v_forma and a.slug = 'heptasilabica'
		and not exists (
			select 1 from public.afirmaciones_fuentes_metricas x
			where x.arquitectura_id = a.arquitectura_id and x.fuente_id = v_caparros
		);

	raise notice 'Romance: definición, cuatro descripciones y las afirmaciones de sus fuentes.';
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

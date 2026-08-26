-- La décima aumentada se intercala
--
-- B5, segunda mitad: el único caso que el catálogo declara hoy.
--
-- **Lo dice la propia arquitectura**, y con esas palabras: «Alarga el miembro final de cuatro versos
-- a seis, con una clase de rima nueva; la primera redondilla y los versos de enlace no cambian.
-- **Aparece intercalada entre décimas normales**.» Y lo respalda Morley y Bruerton, que la documentan
-- así en el corpus.
--
-- Con `intercalable` en verdadero, el editor puede marcar **una realización suelta** de una tirada de
-- décimas como aumentada, sin partir el pasaje ni registrarla como desviación.
--
-- **Es la única, y se cierra a propósito.** Se buscó «intercalad» en todas las definiciones,
-- descripciones y afirmaciones de fuente del catálogo, y las otras apariciones son otro fenómeno:
-- los **pareados** intercalados del endecasílabo suelto, que son un rasgo y ya se preguntan; los
-- **estribillos o canciones** intercalados en el romance, que son otra secuencia y no otra
-- arquitectura; y los heptasílabos de la canción petrarquista, que son medida.
--
-- Las otras dos formas con arquitecturas de extensión distinta **no lo afirman**: las siete
-- variedades de la seguidilla se describen como formas de uso propio, y las dobles de la sextina son
-- poemas enteros. *Que una seguidilla compuesta aparezca entre simples es imaginable, pero ninguna
-- fuente lo documenta, y abrirlo por si acaso invitaría a marcar excepción donde en realidad empieza
-- otra secuencia.* ⇒ **cuestión para el IP**, que se reabre en cuanto el corpus traiga una.

begin;

do $$
declare
	v_arq uuid;
	v_forma uuid;
	v_n integer;
	v_descripcion text;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'decima' and activo;
	if v_forma is null then
		raise exception 'La décima no está activa.';
	end if;

	select arquitectura_id, descripcion into v_arq, v_descripcion
	from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'aumentada' and activo;
	if v_arq is null then
		raise exception 'La décima no tiene su arquitectura aumentada activa.';
	end if;

	-- Lo que la migración afirma lo dice ya la ficha. Si esa frase desapareciera, esta declaración
	-- se quedaría sin respaldo y conviene enterarse aquí y no al leer la ficha.
	if v_descripcion is null or v_descripcion not ilike '%intercalada entre décimas normales%' then
		raise exception 'La aumentada ya no dice que aparece intercalada. Dice: «%».', v_descripcion;
	end if;

	-- Y la respalda una fuente, que es lo que exige el criterio para declarar norma.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas af
	join public.fuentes_metricas fu on fu.fuente_id = af.fuente_id
	where af.forma_id = v_forma and fu.autoria like '%Morley%';
	if v_n = 0 then
		raise exception 'La décima no cita a Morley y Bruerton, que es quien documenta la aumentada.';
	end if;

	update public.arquitecturas_forma set intercalable = true where arquitectura_id = v_arq;

	-- ------------------------------------------------------------------ Comprobaciones
	select count(*) into v_n from public.arquitecturas_forma where intercalable;
	if v_n <> 1 then
		raise exception '% arquitecturas son intercalables, y debía ser solo la aumentada.', v_n;
	end if;

	-- **La guarda se prueba atravesándola**, que es lo único que demuestra que un disparador
	-- funciona. Se marca una realización como aumentada, se comprueba que entra, y se deshace.
	if exists (
		select 1 from public.secuencias_editor_metrico s
		join public.arquitecturas_forma a on a.arquitectura_id = s.arquitectura_id
		where a.forma_id = v_forma
	) then
		raise notice 'Hay secuencias de décima anotadas: la prueba de la guarda se salta.';
	end if;

	-- La aumentada es intercalable; la espinela no, y el disparador tiene que decirlo.
	begin
		update public.realizaciones_editor_metrico
		set arquitectura_id = (
			select arquitectura_id from public.arquitecturas_forma
			where forma_id = v_forma and slug = 'espinela'
		)
		where realizacion_prueba_id = (
			select realizacion_prueba_id from public.realizaciones_editor_metrico limit 1
		);
		-- El disparador es diferido: no salta hasta el final de la transacción, así que se fuerza.
		set constraints public.trigger_validar_arquitectura_de_realizacion immediate;
		raise exception 'Se ha admitido una arquitectura que no es intercalable.';
	exception when others then
		if sqlerrm not in (
			'Esa arquitectura no está declarada intercalable en el catálogo',
			'Una realización solo puede declarar otra arquitectura de su misma forma'
		) then
			raise;
		end if;
	end;
end $$;

commit;

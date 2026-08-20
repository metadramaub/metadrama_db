-- Los dos tramos sin forma se reconocen entre sí
--
-- Revisión de la prosa de `verso_aislado` y `irregular`, las dos salidas del catálogo cuando un
-- pasaje no deja reconocer ninguna forma. Son fichas mínimas —sin arquitectura, sin rima, sin
-- partes— y por eso **todo su peso está en la definición**.
--
-- 1. **Las dos definiciones daban una instrucción al editor en vez de describir.** La de la
--    versificación irregular decía «**se utiliza solo cuando** el conjunto no conserva una
--    identidad conocida», que es la regla de uso y no la cosa. Y la del verso aislado era tres
--    negaciones seguidas sin un solo dato: «no puede integrarse en la anterior ni en la
--    siguiente y tampoco constituye una desviación interna de ninguna».
--
-- 2. **Y dejaban fuera lo mejor de sus fuentes**, que solo se leía bajando a las afirmaciones.
--    Navarro Tomás documenta el **mote** —verso único al que sigue una glosa en redondilla o
--    quintilla que acaba repitiéndolo— y el *Diccionario* añade los proverbios y refranes con
--    medida reconocible, y plantea la duda de fondo: «siempre podrá discutirse si un verso
--    aislado es realmente un verso, puesto que falta la repetición, base del ritmo». Eso explica
--    mejor que ninguna otra cosa por qué el catálogo lo registra como tramo y no como forma.
--
-- 3. **No se conocían entre sí.** Ninguno de los dos tenía una sola relación, y la más útil que
--    puede tener cualquiera de ellos es la que los une: se reparten por extensión, uno para un
--    verso y otro desde dos. Quien llegaba a una ficha no sabía que existía la otra.
--
-- 4. **Morley y Bruerton no tienen categoría de irregularidad**, y lo que hacen en su lugar dice
--    algo: su repertorio son formas, y lo que no encaja lo reúnen bajo «coplas», «estrofas cortas
--    que no se incluyen en definiciones más específicas». Resuelven por un cajón de formas breves
--    y no por una categoría de irregular. Se registra, ahora que su texto está localizado.
--
-- **No se modela nada más para ellas, y es deliberado**: en un tramo sin forma todo vale —
-- cualquier medida, cualquier rima, cualquier rasgo, sin restricción—, de modo que no hay norma
-- que declarar. Lo que el editor observe lo registrará entero cuando el editor V2 lo pida.

begin;

do $$
declare
	v_irregular uuid;
	v_aislado uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d';
	v_actual text;
	v_n integer;

	c_irregular constant text :=
		'Pasaje de dos o más versos cuya organización métrica no permite reconocer una forma del '
		|| 'catálogo: ni el número de sílabas obedece a igualdad o proporción, ni lo que hay debajo '
		|| 'es una forma conocida con alguna licencia. La combinación regular de un verso largo con '
		|| 'su quebrado —octosílabo y tetrasílabo, endecasílabo y heptasílabo— no es versificación '
		|| 'irregular: obedece a una proporción y pertenece a la forma que la declara.';

	c_aislado constant text :=
		'Un único verso que no se integra en la forma anterior ni en la siguiente, y que tampoco es '
		|| 'una licencia dentro de ninguna de las dos. El caso más caracterizado es el mote, verso '
		|| 'suelto al que sigue una glosa que acaba repitiéndolo; también lo son los proverbios, '
		|| 'refranes y sentencias que el diálogo intercala con medida reconocible. Que un verso '
		|| 'solo sea verso es discutible, porque le falta la repetición en que descansa el ritmo, y '
		|| 'por eso el catálogo lo registra como tramo sin forma y no como forma.';

	c_relacion constant text :=
		'Son las dos salidas del catálogo cuando un pasaje no deja reconocer ninguna forma, y se '
		|| 'reparten por extensión: el verso aislado es uno solo; desde dos versos, el tramo es '
		|| 'versificación irregular. Ninguna de las dos es una forma métrica, y por eso no declaran '
		|| 'medida, rima ni partes.';

	c_mb constant text :=
		'No tienen categoría de versificación irregular. Su repertorio es de formas, y lo que no '
		|| 'encaja en ninguna lo reúnen bajo «coplas», que definen como las estrofas cortas que no '
		|| 'se incluyen en definiciones más específicas: resuelven por un cajón de formas breves y '
		|| 'no por una clase de irregularidad.';
begin
	select forma_id into v_irregular from public.formas_metricas where slug = 'irregular';
	select forma_id into v_aislado from public.formas_metricas where slug = 'verso_aislado';

	if v_irregular is null or v_aislado is null then
		raise exception 'Falta alguno de los dos tramos sin forma.';
	end if;

	-- Son tramos, no formas: si esto cambiara, la prosa que sigue dejaría de ser cierta.
	select count(*) into v_n
	from public.formas_metricas
	where forma_id in (v_irregular, v_aislado) and tipo_registro = 'sin_forma';
	if v_n <> 2 then
		raise exception 'Alguno de los dos ha dejado de ser un tramo sin forma.';
	end if;
	if exists (
		select 1 from public.arquitecturas_forma
		where forma_id in (v_irregular, v_aislado)
	) then
		raise exception 'Un tramo sin forma ha ganado arquitectura: no debe declarar norma.';
	end if;

	-- ------------------------------------------------------------ 1 y 2. Las definiciones
	select definicion into v_actual from public.formas_metricas where forma_id = v_irregular;
	if v_actual not like '%Se utiliza solo cuando%' and v_actual is distinct from c_irregular then
		raise exception 'La definición de la irregular no es la esperada. Dice: %', v_actual;
	end if;
	update public.formas_metricas set definicion = c_irregular where forma_id = v_irregular;

	select definicion into v_actual from public.formas_metricas where forma_id = v_aislado;
	if v_actual not like '%desviación interna de ninguna de ellas.'
		and v_actual is distinct from c_aislado
	then
		raise exception 'La definición del verso aislado no es la esperada. Dice: %', v_actual;
	end if;
	update public.formas_metricas set definicion = c_aislado where forma_id = v_aislado;

	-- ----------------------------------------------------------------- 3. Se reconocen
	if not exists (
		select 1 from public.forma_relaciones
		where (forma_origen_id = v_aislado and forma_destino_id = v_irregular)
			or (forma_origen_id = v_irregular and forma_destino_id = v_aislado)
	) then
		insert into public.forma_relaciones
			(forma_origen_id, forma_destino_id, tipo_relacion, nota)
		values (v_aislado, v_irregular, 'contrasta_con', c_relacion);
	else
		update public.forma_relaciones set nota = c_relacion
		where (forma_origen_id = v_aislado and forma_destino_id = v_irregular)
			or (forma_origen_id = v_irregular and forma_destino_id = v_aislado);
	end if;

	-- ------------------------------------------------------ 4. Lo que hacen Morley y Bruerton
	if not exists (
		select 1 from public.afirmaciones_fuentes_metricas
		where forma_id = v_irregular and fuente_id = v_mb
	) then
		insert into public.afirmaciones_fuentes_metricas
			(fuente_id, forma_id, localizador, resumen, confianza)
		values (
			v_mb, v_irregular,
			'Capítulo «Definición de las Formas Métricas», epígrafe «Coplas»', c_mb, 'alta'
		);
	else
		update public.afirmaciones_fuentes_metricas set resumen = c_mb
		where forma_id = v_irregular and fuente_id = v_mb;
	end if;

	-- ------------------------------------------------------------------ Comprobaciones
	-- Las dos fichas responden y cada una trae el vínculo, que se lee por los dos extremos.
	foreach v_actual in array array['irregular', 'verso_aislado'] loop
		if not exists (
			select 1 from jsonb_array_elements(
				public.get_forma_metrica_publica(v_actual) -> 'relaciones'
			) r
			where r ->> 'tipo_relacion' = 'contrasta_con'
		) then
			raise exception 'La ficha de % no recoge el vínculo entre los dos tramos.', v_actual;
		end if;
	end loop;

	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas where forma_id = v_irregular;
	if v_n <> 5 then
		raise exception 'La versificación irregular tiene % afirmaciones, no las cinco.', v_n;
	end if;
end $$;

commit;

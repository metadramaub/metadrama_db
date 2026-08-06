-- El terceto y su serie se nombran el uno al otro, y queda dicho por qué son dos formas.
--
-- Las dos ya estaban relacionadas en `forma_relaciones` desde antes de esta revisión, con una
-- nota exacta: «La serie se construye mediante unidades de terceto enlazadas; no es un subtipo
-- porque cambia el nivel estructural.» Lo que faltaba es que **se leyera**: la ficha pública no
-- mostraba las relaciones. Ya las muestra, en las dos direcciones, porque la misma fila dice
-- una cosa desde el origen y otra desde el destino.
--
-- Aquí solo queda que las definiciones se nombren, que es lo que un lector busca primero.
--
-- **Por qué son dos formas y no una con opción de seriarse.** El modelo ya permite seriar una
-- estrofa dentro de su propia forma: el demarcador comprueba `versos % unidad` y, si divide,
-- declara tantas repeticiones como quepan. Cuarenta versos de redondilla son diez redondillas,
-- no una forma nueva, y por eso no existe ninguna «serie de décimas».
--
-- Una forma `serie` aparte se justifica solo cuando seriar **cambia la estructura**, y eso es
-- medible: son las formas cuyos enlaces de rima cruzan el límite del bloque. Doce versos de
-- terceto encadenado no son cuatro tercetos independientes, porque la rima del verso central
-- de cada uno vive en el siguiente y la cadena no cierra hasta el final. Si fueran una sola
-- forma, el demarcador tendría que elegir entre «cuatro unidades» y «una unidad abierta» sin
-- ningún dato que lo distinga, y esa es justamente la distinción que un editor anota.
--
-- Se anota también en `forma_relaciones` para que la razón viaje con el dato y no solo con
-- esta migración.

begin;

do $$
declare
	v_terceto uuid;
	v_cadena uuid;
begin
	select forma_id into v_terceto from public.formas_metricas where slug = 'terceto';
	select forma_id into v_cadena from public.formas_metricas where slug = 'terceto_encadenado';

	if v_terceto is null or v_cadena is null then
		raise exception 'Falta el terceto o el terceto encadenado';
	end if;

	update public.formas_metricas
	set definicion = 'Estrofa de tres versos endecasílabos en la que dos riman en consonante y el tercero queda suelto. Rara vez aparece aislada: lo normal es que se suceda en series o entre en la composición de otra forma, como los dos tercetos del soneto. Cuando las unidades se enlazan por la rima, la serie resultante es el terceto encadenado, que se cataloga aparte.'
	where forma_id = v_terceto;

	update public.formas_metricas
	set definicion = 'Serie continua de versos isométricos con rima consonante en la que cada terceto presta la rima de su verso central al terceto siguiente, que la usa en el primero y el tercero. El enlace no se cierra hasta el final, donde un verso más recupera la rima pendiente. Se cataloga aparte del terceto porque la rima cruza el límite de la unidad: la serie entera es una sola unidad abierta, no una sucesión de estrofas que puedan contarse por separado.'
	where forma_id = v_cadena;

	-- La razón, con el dato y no solo en el historial de migraciones.
	update public.forma_relaciones
	set nota = 'La serie se construye con unidades de terceto enlazadas, pero no es un subtipo ni una repetición del terceto: la rima del verso central de cada unidad vive en la siguiente, de modo que el pasaje no se puede dividir en tercetos independientes. Esa es la razón de que sean dos formas y no una estrofa que se repite.'
	where forma_origen_id = v_cadena and forma_destino_id = v_terceto;

	-- Y el cierre, que el catálogo ya declaraba bien: cuarteta en octosílabos, no serventesio,
	-- que es de arte mayor por definición. Se ajusta el nombre al de la sección y el esquema.
	update public.forma_relaciones
	set nota = 'La serie encadenada cierra con una estrofa cruzada de cuatro versos: un serventesio en la endecasilábica y una redondilla cruzada en la octosilábica, porque «serventesio» nombra solo el cuarteto de arte mayor.'
	where forma_origen_id = v_cadena
		and forma_destino_id = (select forma_id from public.formas_metricas where slug = 'cuarteto');
end $$;

comment on table public.forma_relaciones is
	'Cómo se relacionan dos formas entre sí. Se declara en una dirección y se lee en las dos: la copla real está «compuesta por» quintillas, y desde la quintilla eso se lee como «entra en la composición de». La `nota` explica la relación, y cuando dos formas se parecen mucho es el sitio donde decir por qué siguen siendo dos.';

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

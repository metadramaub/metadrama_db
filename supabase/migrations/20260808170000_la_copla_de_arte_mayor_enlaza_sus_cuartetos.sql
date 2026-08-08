-- La copla de arte mayor contrastada con las seis fuentes autorizadas.
--
-- Declaraba una sola afirmación y, sobre todo, **dos de sus tres esquemas de rima contradicen a
-- las fuentes**. Es el hallazgo de esta revisión y obliga a tocar el dato, no solo la prosa.
--
-- 1. Los dos cuartetos tienen que enlazarse, y el catálogo permitía que no lo hicieran. Cuatro
--    fuentes lo dicen y una de ellas lo declara necesario. Caparrós 2014: «Es necesario que se
--    establezca un enlace entre las dos partes de la estrofa: una rima debe ser común a los dos
--    cuartetos, y el cuarto y quinto versos deben rimar entre sí». El Diccionario: «Es
--    característico que una de las rimas sea común a los dos cuartetos, y que los versos cuarto
--    y quinto tengan la misma rima». Navarro Tomás: «con sólo tres rimas». Jauralde: «dos o
--    tres rimas consonantes distribuidas en dos cuartetos, que se enlazan por la misma rima de
--    los versos cuarto y quinto».
--
--    El catálogo tenía ABBAACCA, ABBACDCD y ABABCDCD. El primero cumple. Los otros dos **no
--    enlazan**: su segundo cuarteto estrena dos rimas nuevas, de modo que la estrofa lleva
--    cuatro y los versos cuarto y quinto no riman. Se retiran y se sustituyen por los otros dos
--    esquemas que las fuentes documentan como frecuentes —ABABBCCB y ABBAACAC—, que aparecen
--    con esa misma lista en Caparrós 2014 y en el Diccionario.
--
--    No es un recorte del repertorio: son tres antes y tres después. Es la corrección de un
--    dato que afirmaba de la forma algo que la bibliografía niega. Navarro Tomás documenta una
--    copla de cuatro rimas ABBA:CDDC en una carta de Tirso de Molina, pero la presenta como
--    caso singular —los propios personajes aluden al carácter antiguo de la estrofa—, no como
--    disposición frecuente.
--
-- 2. El verso no está fijado en doce sílabas. Jauralde: «Dada la estructura rítmica del verso
--    (óoo ó en cada hemistiquio, con una o dos sílabas antes y después), su número de sílabas
--    varía entre diez y dieciséis». La arquitectura sigue llamándose dodecasilábica compuesta
--    porque el dodecasílabo es la realización regular y la del corpus, pero su descripción deja
--    de presentar la medida como invariable y la fluctuación queda en la afirmación.
--
-- 3. Morley y Bruerton no la registran: no figura entre las formas métricas de Lope de Vega. Es
--    coherente con que las otras cinco la sitúen en la poesía culta de fines de la Edad Media,
--    y ese silencio se declara como los demás.
--
-- Sobre la equivalencia de los dos esquemas retirados. Los términos legados
-- `copla_de_arte_mayor_tipo_2_ABBACDCD` y `..._tipo_3_ABABCDCD` los reclamaban por
-- `origen_termino_id`, y llevan la notación en el propio nombre. **No se traspasa ese origen a
-- los esquemas nuevos**: sería hacer que un término llamado ABBACDCD reclamara un esquema
-- ABABBCCB, es decir, afirmar una equivalencia falsa para conservar una cifra. Los dos términos
-- siguen resolviendo a la forma y a su arquitectura por ascendencia, que es la vía correcta
-- cuando el término nombra algo que el catálogo ya no reconoce.
--
-- Ninguna secuencia de las obras usa hoy esos dos términos, así que la vista no cambia de
-- tamaño. Si alguna apareciera, la equivalencia la llevaría a la forma sin proponer esquema, y
-- eso es exactamente lo que debe pasar: la anotación dice una disposición que la bibliografía
-- no reconoce en esta forma, y el informe de migración debe verla.

begin;

do $$
declare
	v_forma uuid;
	v_arq uuid;
	v_nuevo_2 uuid;
	v_nuevo_3 uuid;
	v_consonante uuid := 'e0eec235-4a89-4a3c-9cb7-350ac883f7e1'::uuid;
	v_mb uuid := 'b9a035c9-8771-460d-aa7d-b85f6c090e9d'::uuid;
	v_quilis uuid := '51c372ab-f61c-4942-abe6-d3330b54f4be'::uuid;
	v_navarro uuid := '1d62f1f2-37e2-4b78-a361-08d123f91f42'::uuid;
	v_cap14 uuid := '1f0765c9-3851-451b-9f63-55dbf9ac28fb'::uuid;
	v_dicc uuid := '2e54db97-8085-40e3-8fab-87c96b5f7d59'::uuid;
	v_jauralde uuid := '2888f16d-7e95-40d2-9f1a-8d878f642fff'::uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'copla_de_arte_mayor';
	select arquitectura_id into v_arq from public.arquitecturas_forma
	where forma_id = v_forma and slug = 'dodecasilabica_compuesta';

	if num_nonnulls(
		v_forma, v_arq, v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde
	) <> 8 then
		raise exception 'Falta la copla de arte mayor vigente, su arquitectura o una fuente';
	end if;

	select count(*) into v_n from public.fuentes_metricas
	where fuente_id in (v_mb, v_quilis, v_navarro, v_cap14, v_dicc, v_jauralde);
	if v_n <> 6 then
		raise exception 'No están registradas las seis fuentes autorizadas';
	end if;

	-- El enlace entre los cuartetos entra en la definición, porque es lo que la norma exige.
	update public.formas_metricas
	set definicion = 'Estrofa de ocho versos de arte mayor, cada uno partido por una cesura en dos hemistiquios, distribuidos en dos cuartetos de rima cruzada o abrazada. Los dos cuartetos no son independientes: una rima es común a ambos y los versos cuarto y quinto riman entre sí, de modo que la estrofa se sostiene sobre dos o tres rimas consonantes y no sobre cuatro.',
		estado_revision = 'aprobada',
		updated_at = now()
	where forma_id = v_forma;

	update public.arquitecturas_forma
	set descripcion = 'Ocho versos de arte mayor de dos hemistiquios separados por cesura. El dodecasílabo 6 + 6 es su realización regular, aunque el ritmo del verso admite alguna fluctuación de medida.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_arq;

	-- Los dos esquemas que no enlazan los cuartetos se sustituyen por los que documentan las
	-- fuentes. Sus orígenes legados no se traspasan: el término nombra la notación que reclama.
	insert into public.esquemas_rima (
		arquitectura_id, slug, nombre, notacion, tipo_rima_id, ambito,
		modalidad, tipo_secuencia, descripcion, estado_revision
	)
	values
		(v_arq, 'ababbccb', null, 'ABABBCCB', v_consonante, 'unidad', 'admitida', 'secuencia',
		 'Los dos cuartetos cruzan sus rimas y comparten la segunda, que enlaza el cuarto verso con el quinto.',
		 'revisada'),
		(v_arq, 'abbaacac', null, 'ABBAACAC', v_consonante, 'unidad', 'admitida', 'secuencia',
		 'El primer cuarteto abraza sus rimas y el segundo las cruza, conservando la primera, que enlaza el cuarto verso con el quinto.',
		 'revisada');

	select esquema_rima_id into v_nuevo_2 from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'ababbccb';
	select esquema_rima_id into v_nuevo_3 from public.esquemas_rima
	where arquitectura_id = v_arq and slug = 'abbaacac';

	-- La pregunta del editor tiene que ofrecer los esquemas corregidos, no los retirados: es la
	-- misma pregunta y sigue teniendo tres opciones.
	update public.opciones_eleccion_metrica o
	set esquema_rima_id = v_nuevo_2,
		slug = 'ababbccb',
		nombre = 'ABABBCCB',
		updated_at = now()
	from public.esquemas_rima er
	where er.esquema_rima_id = o.esquema_rima_id
		and er.arquitectura_id = v_arq
		and er.slug = 'abbacdcd';

	update public.opciones_eleccion_metrica o
	set esquema_rima_id = v_nuevo_3,
		slug = 'abbaacac',
		nombre = 'ABBAACAC',
		updated_at = now()
	from public.esquemas_rima er
	where er.esquema_rima_id = o.esquema_rima_id
		and er.arquitectura_id = v_arq
		and er.slug = 'ababcdcd';

	delete from public.esquemas_rima
	where arquitectura_id = v_arq and slug in ('abbacdcd', 'ababcdcd');

	update public.esquemas_rima
	set descripcion = 'El primer cuarteto abraza sus rimas y el segundo repite la primera al principio y al final, que es la disposición del *Laberinto de Fortuna* de Juan de Mena.',
		estado_revision = 'revisada',
		updated_at = now()
	where arquitectura_id = v_arq and slug = 'abbaacca';

	-- Los nombres que la bibliografía da a la forma.
	delete from public.denominaciones_metricas where forma_id = v_forma;
	insert into public.denominaciones_metricas (
		forma_id, nombre, slug_normalizado, preferente, fuente_id
	)
	values
		(v_forma, 'Copla de Juan de Mena', 'copla_de_juan_de_mena', false, v_quilis),
		(v_forma, 'Octava de arte mayor', 'octava_de_arte_mayor', false, v_dicc),
		(v_forma, 'Antigua octava castellana', 'antigua_octava_castellana', false, v_dicc);

	-- Una afirmación autosuficiente por cada una de las seis fuentes.
	delete from public.afirmaciones_fuentes_metricas where forma_id = v_forma;
	insert into public.afirmaciones_fuentes_metricas (
		fuente_id, forma_id, localizador, resumen, confianza, estado_revision
	)
	values
		(v_mb, v_forma, 'Capítulo «Definición de las Formas Métricas»',
		 'No la registran entre las formas métricas empleadas por Lope de Vega. Su repertorio de estrofas de ocho versos recoge la octava real, de ocho endecasílabos ABABABCC, pero ninguna copla de arte mayor.',
		 'alta', 'revisada'),
		(v_quilis, v_forma, '§ 5.4.7.1',
		 'La llama también copla de Juan de Mena, por ser la estrofa que el poeta empleó en el *Laberinto de Fortuna*, y señala que procede de la tradición provenzal a través de Galicia. Indica que sus versos son generalmente dodecasílabos y da como combinación de rima ABBAACCA.',
		 'alta', 'revisada'),
		(v_navarro, v_forma, '§ 57 y repertorio final',
		 'La describe como dos cuartetos en versos de arte mayor con sólo tres rimas, generalmente en forma abrazada ABBA:ACCA, y otras veces con un cuarteto abrazado y otro cruzado. Registra aparte, como caso singular, una carta de Tirso de Molina en *Quien calla otorga* compuesta en una copla de cuatro rimas finales ABBA:CDDC y otras cuatro en los primeros hemistiquios, cuyos personajes aluden al carácter antiguo de la estrofa.',
		 'alta', 'revisada'),
		(v_cap14, v_forma, 'pp. 200-201',
		 'La define como combinación de ocho versos de arte mayor con dos o tres rimas consonantes distribuidas en dos cuartetos de rima cruzada o abrazada, y establece como necesario que una rima sea común a los dos cuartetos y que los versos cuarto y quinto rimen entre sí. Da como distribuciones más frecuentes ABBAACCA, ABABBCCB y ABBAACAC. La caracteriza como propia de la poesía culta de tono solemne y elevado de fines de la Edad Media.',
		 'alta', 'revisada'),
		(v_dicc, v_forma, 'Entrada «copla de arte mayor»',
		 'La define como combinación de ocho versos de arte mayor con dos o tres rimas consonantes en dos cuartetos de rima cruzada o abrazada, y señala como característico que una de las rimas sea común a los dos cuartetos y que los versos cuarto y quinto tengan la misma rima, estableciendo así un enlace entre las dos partes. Da como esquemas más comunes ABBAACCA, ABABBCCB y ABBAACAC, y recoge antigua octava castellana, copla de Juan de Mena, octava de arte mayor y octava de Juan de Mena como otros nombres.',
		 'alta', 'revisada'),
		(v_jauralde, v_forma, 'Apartado «Coplas de arte mayor»',
		 'La define como combinación de ocho versos con dos o tres rimas consonantes distribuidas en dos cuartetos que se enlazan por la misma rima de los versos cuarto y quinto. Precisa que, dada la estructura rítmica del verso, con un hemistiquio de ritmo marcado y una o dos sílabas antes y después, su número de sílabas varía entre diez y dieciséis. Señala que con ella escribieron Santillana, Mena e Imperial los grandes poemas del siglo XV.',
		 'alta', 'revisada');

	select count(*) into v_n from public.afirmaciones_fuentes_metricas
	where forma_id = v_forma;
	if v_n <> 6 then
		raise exception 'La Copla de arte mayor debe tener seis afirmaciones, no %', v_n;
	end if;

	select count(*) into v_n from public.esquemas_rima where arquitectura_id = v_arq;
	if v_n <> 3 then
		raise exception 'La Copla de arte mayor debe conservar tres esquemas de rima, no %', v_n;
	end if;

	-- Ningún esquema puede declarar cuatro clases de rima: la forma exige enlace.
	select count(*) into v_n from public.esquemas_rima
	where arquitectura_id = v_arq
		and notacion is not null
		and cardinality(
			array(select distinct unnest(string_to_array(upper(notacion), null)))
		) > 3;
	if v_n <> 0 then
		raise exception 'Hay % esquema(s) de arte mayor con más de tres clases de rima', v_n;
	end if;

	-- La pregunta del editor sigue ofreciendo tres opciones, y todas apuntan a un esquema vivo.
	select count(*) into v_n from public.opciones_eleccion_metrica o
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = o.grupo_eleccion_id
	join public.esquemas_rima er on er.esquema_rima_id = o.esquema_rima_id
	where g.arquitectura_id = v_arq and er.arquitectura_id = v_arq;
	if v_n <> 3 then
		raise exception 'La pregunta de arte mayor debe ofrecer tres esquemas vivos, no %', v_n;
	end if;
end;
$$;

update public.catalogo_metrico_estado
set revision = revision + 1,
	actualizado_en = now()
where id;

commit;

-- BORRADOR: ensayado en PostgreSQL aislado; NO aplicar sin el control V2 de patrones.
-- Páginas impresas verificadas visualmente. Véase ../prosa-pie-quebrado.md.
begin;
set local lock_timeout = '5s';

-- sextilla · definición
do $$ begin
 if not exists(select 1 from public.formas_metricas where forma_id='b2de4d5a-1174-4d0c-9d13-a2a4206a0e09'::uuid and definicion is not distinct from 'Estrofa de seis versos de arte menor que riman todos en consonante. Lo que no está fijado es su disposición, y esa libertad la define tanto como el número de versos: la tradición ha dado nombre a las más frecuentes —alterna, correlativa, simétrica— pero las enumera siempre en abierto, de modo que las recogidas aquí son las documentadas y no todas las posibles. Se cultiva de ocho a cuatro sílabas, y las más breves son tardías. Cuando el tercer verso y el sexto se quiebran en otros más breves resulta la sextilla de pie quebrado, de la que procede la copla de Jorge Manrique.') then
  raise exception 'Cambió la prosa previa de sextilla · definición; revisar antes de aplicar';
 end if;
 update public.formas_metricas set definicion='Estrofa de seis versos de arte menor que riman todos en consonante. Lo que no está fijado es su disposición, y esa libertad la define tanto como el número de versos: la tradición ha dado nombre a las más frecuentes —alterna, correlativa, simétrica— pero las enumera siempre en abierto, de modo que las recogidas aquí son las documentadas y no todas las posibles. Se cultiva de ocho a cuatro sílabas, y las más breves son tardías. La sextilla de pie quebrado combina octosílabos con versos más breves: su disposición más conocida sitúa los quebrados en tercero y sexto, y también está documentada la que los sitúa en segundo y quinto. La primera, agrupada de dos en dos, es la empleada en las coplas de Jorge Manrique.' where forma_id='b2de4d5a-1174-4d0c-9d13-a2a4206a0e09'::uuid;
end $$;

-- sextilla · pie_quebrado · descripción
do $$ begin
 if not exists(select 1 from public.arquitecturas_forma where arquitectura_id='d9186929-efe3-48cb-8819-818cbfd5df25'::uuid and descripcion is not distinct from 'Es la sextilla más conocida, y la que dio fama a la estrofa: Jorge Manrique la empleó en las coplas por la muerte de su padre, agrupada de dos en dos. El quiebro cae normalmente en el tercer verso y el sexto, pero la tradición lo documenta también en otras posiciones. El nombre de manriqueña se reparte: Quilis y Domínguez Caparrós lo dan a esta estrofa de seis, y Navarro Tomás y Jauralde a la agrupación de doce.') then
  raise exception 'Cambió la prosa previa de sextilla · pie_quebrado · descripción; revisar antes de aplicar';
 end if;
 update public.arquitecturas_forma set descripcion='Combina cuatro octosílabos con dos versos quebrados. La disposición más conocida coloca los quebrados en tercero y sexto; otra los coloca en segundo y quinto. Puede aparecer como estrofa independiente o agrupada de dos en dos. Los nombres copla de pie quebrado y manriqueña no tienen el mismo alcance en todas las fuentes: pueden designar la sextilla, y el segundo se aplica también a su agrupación doble.' where arquitectura_id='d9186929-efe3-48cb-8819-818cbfd5df25'::uuid;
end $$;

-- copla_castellana · definición
do $$ begin
 if not exists(select 1 from public.formas_metricas where forma_id='d009c46f-af6f-47a3-a5f2-6f7dff1799f3'::uuid and definicion is not distinct from 'Estrofa de ocho versos octosílabos repartidos en dos semiestrofas de cuatro que **no comparten ninguna rima**: cada una estrena las suyas, de modo que las dos son redondillas enteras y la estrofa suma cuatro clases consonantes. Pueden ir las dos cruzadas, las dos abrazadas o combinarse en cualquier orden. Algún verso puede aparecer quebrado en cuatro sílabas. Esa cuarta rima es lo único que la separa de la copla de arte menor, donde una rima vuelve de la primera mitad a la segunda, y de ahí que se la tenga por más sencilla: derivada de aquella, se impuso sobre ella en el siglo XV y siguió siendo la estrofa corriente de ocho versos en el XVI y el XVII, en el teatro y en el epigrama. Sin rima que enlace las dos mitades, lo que la distingue de dos redondillas seguidas no es la organización métrica sino la manera en que el texto las agrupa: lo que une las semiestrofas, dicho por la tradición, es la disposición gráfica.') then
  raise exception 'Cambió la prosa previa de copla_castellana · definición; revisar antes de aplicar';
 end if;
 update public.formas_metricas set definicion='Estrofa de ocho versos octosílabos repartidos en dos semiestrofas de cuatro que no comparten ninguna rima: cada una estrena las suyas, de modo que las dos son redondillas enteras y la estrofa suma cuatro clases consonantes. Pueden ir las dos cruzadas, las dos abrazadas o combinarse en cualquier orden. Algunos versos pueden aparecer quebrados en cuatro sílabas. Esa cuarta rima es lo único que la separa de la copla de arte menor, donde una rima vuelve de la primera mitad a la segunda, y de ahí que se la tenga por más sencilla: derivada de aquella, se impuso sobre ella en el siglo XV y siguió siendo la estrofa corriente de ocho versos en el XVI y el XVII, en el teatro y en el epigrama. Sin rima que enlace las dos mitades, lo que la distingue de dos redondillas seguidas no es la organización métrica sino la manera en que el texto las agrupa: lo que une las semiestrofas, dicho por la tradición, es la disposición gráfica.' where forma_id='d009c46f-af6f-47a3-a5f2-6f7dff1799f3'::uuid;
end $$;

-- copla_castellana · octosilabica · descripción
do $$ begin
 if not exists(select 1 from public.arquitecturas_forma where arquitectura_id='f56f68a2-c1d9-4cea-938b-29ae21074641'::uuid and descripcion is not distinct from 'Ocho octosílabos en dos grupos de cuatro, con dos clases de rima consonante en cada uno y ninguna común a los dos. El quiebro, cuando lo hay, es tetrasílabo.') then
  raise exception 'Cambió la prosa previa de copla_castellana · octosilabica · descripción; revisar antes de aplicar';
 end if;
 update public.arquitecturas_forma set descripcion='Ocho versos de base octosilábica en dos grupos de cuatro, con dos clases de rima consonante en cada uno y ninguna común a los dos. Admite uno o varios versos quebrados; se documentan tanto quebrados aislados como alternancia de versos plenos y quebrados.' where arquitectura_id='f56f68a2-c1d9-4cea-938b-29ae21074641'::uuid;
end $$;

-- copla_castellana · nota del quebrado
do $$ begin
 if not exists(select 1 from public.arquitectura_rasgos where arquitectura_id='f56f68a2-c1d9-4cea-938b-29ae21074641'::uuid and rasgo_id='da3028d1-4bd1-4b49-b6c0-8e3a08efabc6'::uuid and nota is not distinct from 'El quiebro que documentan las fuentes es tetrasílabo y suele ser uno solo. Se documenta en el sexto verso, y también alternando versos plenos y quebrados en las dos semiestrofas. El catálogo admite además el pentasílabo, que el *Diccionario* cuenta como el mismo quebrado: «si el verso tetrasílabo tiene cinco sílabas, hay que tener en cuenta la sinafía y compensación entre versos».') then
  raise exception 'Cambió la prosa previa de copla_castellana · nota del quebrado; revisar antes de aplicar';
 end if;
 update public.arquitectura_rasgos set nota='El quebrado es tetrasílabo y no tiene una única posición: se documenta aislado en sexto y también alternando con versos plenos en ambas semiestrofas. El pentasílabo se interpreta mediante sinafía o compensación con el verso anterior.' where arquitectura_id='f56f68a2-c1d9-4cea-938b-29ae21074641'::uuid and rasgo_id='da3028d1-4bd1-4b49-b6c0-8e3a08efabc6'::uuid;
end $$;

-- copla_real · definición
do $$ begin
 if not exists(select 1 from public.formas_metricas where forma_id='04f3b8a4-cae2-4b49-8396-10a780d174e6'::uuid and definicion is not distinct from 'Estrofa de diez octosílabos organizada en dos quintillas separadas por una pausa estructural. Cada quintilla lleva sus propias rimas consonantes, sin ninguna común a las dos, y ambas pueden repetir o no el mismo esquema; esa independencia es lo que la separa de la décima espinela. Admite que uno o dos versos aparezcan quebrados. La libertad de combinar las disposiciones es más teórica que real: en el teatro de Lope la segunda quintilla es siempre `aabba` y la primera casi siempre `ababa`, y antes, en el siglo XV, la combinación `abaab:cdccd` llegó a valer por la estrofa entera.') then
  raise exception 'Cambió la prosa previa de copla_real · definición; revisar antes de aplicar';
 end if;
 update public.formas_metricas set definicion='Estrofa de diez octosílabos organizada en dos quintillas separadas por una pausa estructural. Cada quintilla lleva sus propias rimas consonantes, sin ninguna común a las dos, y ambas pueden repetir o no el mismo esquema; esa independencia es lo que la separa de la décima espinela. Admite uno o varios versos quebrados, sobre todo en la segunda quintilla. La libertad de combinar las disposiciones es más teórica que real: en el teatro de Lope la segunda quintilla es siempre `aabba` y la primera casi siempre `ababa`, y antes, en el siglo XV, la combinación `abaab:cdccd` llegó a valer por la estrofa entera.' where forma_id='04f3b8a4-cae2-4b49-8396-10a780d174e6'::uuid;
end $$;

-- copla_real · octosilabica_consonante · descripción
do $$ begin
 if not exists(select 1 from public.arquitecturas_forma where arquitectura_id='a81a8c9d-dde9-4023-b332-70692dd1b04b'::uuid and descripcion is not distinct from 'Diez octosílabos. El quiebro, cuando lo hay, cae en uno o dos versos y suele ser tetrasílabo; si tiene cinco sílabas, se compensa con el octosílabo anterior.') then
  raise exception 'Cambió la prosa previa de copla_real · octosilabica_consonante · descripción; revisar antes de aplicar';
 end if;
 update public.arquitecturas_forma set descripcion='Diez versos de base octosilábica. Puede haber uno o varios quebrados, sobre todo en la segunda quintilla, en posición interior o final. El quebrado suele ser tetrasílabo; si tiene cinco sílabas, se interpreta mediante sinafía o compensación con el octosílabo anterior.' where arquitectura_id='a81a8c9d-dde9-4023-b332-70692dd1b04b'::uuid;
end $$;

-- copla_real · nota del quebrado
do $$ begin
 if not exists(select 1 from public.arquitectura_rasgos where arquitectura_id='a81a8c9d-dde9-4023-b332-70692dd1b04b'::uuid and rasgo_id='da3028d1-4bd1-4b49-b6c0-8e3a08efabc6'::uuid and nota is not distinct from 'El quiebro cae sobre todo en la segunda mitad de la estrofa, y la tradición no fija en qué verso.') then
  raise exception 'Cambió la prosa previa de copla_real · nota del quebrado; revisar antes de aplicar';
 end if;
 update public.arquitectura_rasgos set nota='El quiebro aparece sobre todo en la segunda quintilla, en posición interior o final, y puede afectar a varios versos.' where arquitectura_id='a81a8c9d-dde9-4023-b332-70692dd1b04b'::uuid and rasgo_id='da3028d1-4bd1-4b49-b6c0-8e3a08efabc6'::uuid;
end $$;

-- quintilla · definición
do $$ begin
 if not exists(select 1 from public.formas_metricas where forma_id='4d6d8107-5f7f-4b22-a26e-676df130ffdf'::uuid and definicion is not distinct from 'Estrofa de cinco versos de arte menor que riman en consonante sobre dos clases. Más que por una disposición fija, la tradición la caracteriza por lo que procura evitar: tres versos seguidos con la misma rima y el pareado final. De ahí salen sus cinco disposiciones clásicas, aunque el uso documenta alguna más. Dentro de un mismo poema la disposición puede cambiar de una quintilla a otra. El octosílabo es su realización no marcada; el heptasílabo y el hexasílabo están documentados, y las fuentes la definen en «octosílabos o menores», de modo que medidas más breves no quedan excluidas por la norma aunque el catálogo no las declare.') then
  raise exception 'Cambió la prosa previa de quintilla · definición; revisar antes de aplicar';
 end if;
 update public.formas_metricas set definicion='Estrofa de cinco versos de arte menor que riman en consonante sobre dos clases. Más que por una disposición fija, la tradición la caracteriza por lo que procura evitar: tres versos seguidos con la misma rima y el pareado final. De ahí salen sus cinco disposiciones clásicas, aunque el uso documenta alguna más. Dentro de un mismo poema la disposición puede cambiar de una quintilla a otra. El octosílabo es su realización no marcada; el heptasílabo y el hexasílabo están documentados, y las fuentes la definen en «octosílabos o menores», de modo que medidas más breves no quedan excluidas por la norma aunque el catálogo no las declare. En la realización octosilábica se documentan tanto un quebrado inicial como dos quebrados en segundo y quinto.' where forma_id='4d6d8107-5f7f-4b22-a26e-676df130ffdf'::uuid;
end $$;

-- novena · redondilla_quintilla · descripción
do $$ begin
 if not exists(select 1 from public.arquitecturas_forma where arquitectura_id='e5847ceb-1ad4-4373-897b-e6c5939feba3'::uuid and descripcion is not distinct from 'Nueve octosílabos consonantes distribuidos en una redondilla de cuatro versos seguida de una quintilla de cinco.') then
  raise exception 'Cambió la prosa previa de novena · redondilla_quintilla · descripción; revisar antes de aplicar';
 end if;
 update public.arquitecturas_forma set descripcion='Redondilla seguida de quintilla, de base octosilábica y rima consonante. Admite versos quebrados en la quintilla; el quebrado que abre esa parte es una realización documentada, no la única.' where arquitectura_id='e5847ceb-1ad4-4373-897b-e6c5939feba3'::uuid;
end $$;

-- novena · quintilla_redondilla · descripción
do $$ begin
 if not exists(select 1 from public.arquitecturas_forma where arquitectura_id='aa3f925f-c9db-4959-bad2-f1b52475aaf0'::uuid and descripcion is not distinct from 'Nueve octosílabos consonantes distribuidos en una quintilla de cinco versos seguida de una redondilla de cuatro.') then
  raise exception 'Cambió la prosa previa de novena · quintilla_redondilla · descripción; revisar antes de aplicar';
 end if;
 update public.arquitecturas_forma set descripcion='Quintilla seguida de redondilla, de base octosilábica y rima consonante. Se documentan realizaciones con la quintilla en versos plenos y quebrados en la redondilla.' where arquitectura_id='aa3f925f-c9db-4959-bad2-f1b52475aaf0'::uuid;
end $$;

-- novena · nota del quebrado
do $$ begin
 if not exists(select 1 from public.arquitectura_rasgos where arquitectura_id='e5847ceb-1ad4-4373-897b-e6c5939feba3'::uuid and rasgo_id='da3028d1-4bd1-4b49-b6c0-8e3a08efabc6'::uuid and nota is not distinct from 'En el orden 4+5 el quiebro abre la quintilla, que con ese orden es el quinto verso de la estrofa. Es el único caso que las fuentes documentan: Jauralde recoge de Castillejo «8a 8b 8b 8a 4c 8c 8d 8d 8c», con un solo quebrado tetrasílabo.') then
  raise exception 'Cambió la prosa previa de novena · nota del quebrado; revisar antes de aplicar';
 end if;
 update public.arquitectura_rasgos set nota='En el orden 4+5 los quebrados se documentan en la quintilla. El quinto verso, que abre esa parte, es una de sus posiciones documentadas.' where arquitectura_id='e5847ceb-1ad4-4373-897b-e6c5939feba3'::uuid and rasgo_id='da3028d1-4bd1-4b49-b6c0-8e3a08efabc6'::uuid;
end $$;

-- quintilla · nota del quebrado
do $$ begin
 if not exists(select 1 from public.arquitectura_rasgos where arquitectura_id='053ef367-629a-427c-aee1-425c4f111304'::uuid and rasgo_id='da3028d1-4bd1-4b49-b6c0-8e3a08efabc6'::uuid and nota is not distinct from 'La tradición documenta la quintilla con el primer verso quebrado como estrofa suelta, y no solo como mitad de una copla mayor: fue la más usada por Castillejo. El quiebro que documentan las fuentes es tetrasílabo, y la medida de la estrofa sigue siendo la suya. El catálogo admite además el pentasílabo, que el *Diccionario* cuenta como el mismo quebrado: «si el verso tetrasílabo tiene cinco sílabas, hay que tener en cuenta la sinafía y compensación entre versos».') then
  raise exception 'Cambió la prosa previa de quintilla · nota del quebrado; revisar antes de aplicar';
 end if;
 update public.arquitectura_rasgos set nota='Se documenta un quebrado en el primer verso y otra disposición con quebrados en el segundo y el quinto.' where arquitectura_id='053ef367-629a-427c-aee1-425c4f111304'::uuid and rasgo_id='da3028d1-4bd1-4b49-b6c0-8e3a08efabc6'::uuid;
end $$;

-- copla_castellana · ayuda del formulario
do $$ begin
 if not exists(select 1 from public.grupos_eleccion_metrica where grupo_eleccion_id='6c05ce67-3a29-4067-a0c7-dea5cb241775'::uuid and ayuda_editor is not distinct from 'El quiebro es una licencia, no la norma: marca los versos que veas acortados y su medida, y deja la pregunta en blanco si no hay ninguno. Ninguna fuente dice cuántos admite la forma, así que el máximo que ofrece la pantalla —7— se deriva de que no pueden estarlo todos.') then
  raise exception 'Cambió la prosa previa de copla_castellana · ayuda del formulario; revisar antes de aplicar';
 end if;
 update public.grupos_eleccion_metrica set ayuda_editor='Indica la medida de los versos quebrados y deja los demás sin marcar: conservan las ocho sílabas. Debe quedar algún octosílabo pleno.' where grupo_eleccion_id='6c05ce67-3a29-4067-a0c7-dea5cb241775'::uuid;
end $$;

-- copla_real · ayuda del formulario
do $$ begin
 if not exists(select 1 from public.grupos_eleccion_metrica where grupo_eleccion_id='58a8be4c-94e0-4c59-89ca-db8e56158cb7'::uuid and ayuda_editor is not distinct from 'Selecciona únicamente las posiciones quebradas; el resto de los versos son octosílabos.') then
  raise exception 'Cambió la prosa previa de copla_real · ayuda del formulario; revisar antes de aplicar';
 end if;
 update public.grupos_eleccion_metrica set ayuda_editor='Indica la medida de los versos quebrados y deja los demás sin marcar: conservan las ocho sílabas. Debe quedar algún octosílabo pleno.' where grupo_eleccion_id='58a8be4c-94e0-4c59-89ca-db8e56158cb7'::uuid;
end $$;

-- novena · ayuda del formulario
do $$ begin
 if not exists(select 1 from public.grupos_eleccion_metrica where grupo_eleccion_id='690ef505-90bb-47d5-bb20-dad17884cd6a'::uuid and ayuda_editor is not distinct from 'El quiebro es una licencia, no la norma: marca los versos que veas acortados y su medida, y deja la pregunta en blanco si no hay ninguno. Las fuentes documentan uno solo; si el pasaje trae más, regístralo como desviación.') then
  raise exception 'Cambió la prosa previa de novena · ayuda del formulario; revisar antes de aplicar';
 end if;
 update public.grupos_eleccion_metrica set ayuda_editor='Señala los quebrados de la quintilla, en los versos 5 a 9, y su medida. Los demás versos conservan las ocho sílabas.' where grupo_eleccion_id='690ef505-90bb-47d5-bb20-dad17884cd6a'::uuid;
end $$;

-- sextilla · ayuda del formulario
do $$ begin
 if not exists(select 1 from public.grupos_eleccion_metrica where grupo_eleccion_id='28761280-741f-468a-abe3-ac4b73ea07f6'::uuid and ayuda_editor is not distinct from 'La norma ya dice qué versos van quebrados; lo que no fija es cuánto miden. Indica si cada uno es de cuatro o de cinco sílabas.') then
  raise exception 'Cambió la prosa previa de sextilla · ayuda del formulario; revisar antes de aplicar';
 end if;
 update public.grupos_eleccion_metrica set ayuda_editor='Elige la disposición completa: quebrados en tercero y sexto, o en segundo y quinto. Después indica cuánto mide cada uno; la rima se responde aparte.' where grupo_eleccion_id='28761280-741f-468a-abe3-ac4b73ea07f6'::uuid;
end $$;

-- quintilla · ayuda del formulario
do $$ begin
 if not exists(select 1 from public.grupos_eleccion_metrica where grupo_eleccion_id='e36768c2-1a0d-4468-bc5d-13a900d29864'::uuid and ayuda_editor is not distinct from 'El quiebro es una licencia, no la norma: marca los versos que veas acortados y su medida, y deja la pregunta en blanco si no hay ninguno. Las fuentes documentan uno solo; si el pasaje trae más, regístralo como desviación.') then
  raise exception 'Cambió la prosa previa de quintilla · ayuda del formulario; revisar antes de aplicar';
 end if;
 update public.grupos_eleccion_metrica set ayuda_editor='Puedes dejar la quintilla sin quebrados, señalar el inicial o elegir la disposición con segundo y quinto quebrados. Después indica su medida.' where grupo_eleccion_id='e36768c2-1a0d-4468-bc5d-13a900d29864'::uuid;
end $$;

-- copla_castellana · fuente 1969
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='8e712f47-d5db-4bdb-af0a-568a88a71dec'::uuid and resumen is not distinct from 'No registra una estrofa de ocho versos con cuatro rimas independientes: su única estrofa de ocho versos **de arte menor** es la octavilla, cuyas dos combinaciones de rima comparten rima entre las dos mitades; **las otras tres del § 5.4.7 —copla de arte mayor, octava real y octava italiana— son de arte mayor**.') then
  raise exception 'Cambió la prosa previa de copla_castellana · fuente 1969; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set resumen='No emplea el nombre copla castellana: reúne las estrofas de ocho versos de arte menor bajo octavilla. Tras describir sus combinaciones habituales y la aparición de coplas de pie quebrado al alternar octosílabos y tetrasílabos, reproduce de Santillana una estrofa del *Diálogo de Bías contra Fortuna* con disposición `abba:cddc` y el sexto verso quebrado. Ese ejemplo sí presenta cuatro rimas independientes, aunque no le dé epígrafe propio.' where afirmacion_id='8e712f47-d5db-4bdb-af0a-568a88a71dec'::uuid;
end $$;

-- copla_castellana · localizador 1969
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='8e712f47-d5db-4bdb-af0a-568a88a71dec'::uuid and localizador is not distinct from '§ 5.4.7.4, «Octavilla», p. 108') then
  raise exception 'Cambió la prosa previa de copla_castellana · localizador 1969; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set localizador='§ 5.4.7.4, «Octavilla», pp. 108-109' where afirmacion_id='8e712f47-d5db-4bdb-af0a-568a88a71dec'::uuid;
end $$;

-- copla_castellana · fuente 1972
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='11ffbe13-861e-4892-829d-2088b3be5d95'::uuid and resumen is not distinct from 'La define como ocho octosílabos en dos grupos de cuatro **con cuatro rimas, como pareja de redondillas independientes**, y enumera las cuatro disposiciones: las dos mitades cruzadas, `abab:cdcd`; las dos abrazadas, `abba:cddc`; o combinadas, `abab:cddc` y `abba:cdcd`. La sigue históricamente: no hay ningún ejemplo en el *Cancionero de Baena* de 1445; Santillana la usa en las coplas sobre el Condestable y, con el sexto verso quebrado, en el *Diálogo de Bías contra Fortuna* y en los *Gozos de Nuestra Señora*; en el *Cancionero general* de 1511 ya supera a la de arte menor, y «llegaron éstas a ser de uso tan familiar en el siglo XVI que recibieron el nombre de coplas castellanas». Observa además lo que su falta de enlace implica: «suprimido el enlace de la rima, la unión de las semiestrofas quedaba reducida a un simple efecto de representación gráfica».') then
  raise exception 'Cambió la prosa previa de copla_castellana · fuente 1972; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set resumen='La define como ocho octosílabos en dos grupos de cuatro con cuatro rimas, como pareja de redondillas independientes, y enumera las cuatro disposiciones: las dos mitades cruzadas, `abab:cdcd`; las dos abrazadas, `abba:cddc`; o combinadas, `abab:cddc` y `abba:cdcd`. La sigue históricamente: no hay ningún ejemplo en el *Cancionero de Baena* de 1445; Santillana la usa en las coplas sobre el Condestable y, con el sexto verso quebrado, en el *Diálogo de Bías contra Fortuna* y en los *Gozos de Nuestra Señora*; en el *Cancionero general* de 1511 ya supera a la de arte menor, y «llegaron éstas a ser de uso tan familiar en el siglo XVI que recibieron el nombre de coplas castellanas». Observa además lo que su falta de enlace implica: «suprimido el enlace de la rima, la unión de las semiestrofas quedaba reducida a un simple efecto de representación gráfica». En el § 68 documenta además octavas de cuatro rimas con versos alternativamente plenos y quebrados, junto a la variedad con el sexto quebrado: el ejemplo aislado no agota las posiciones posibles.' where afirmacion_id='11ffbe13-861e-4892-829d-2088b3be5d95'::uuid;
end $$;

-- copla_castellana · localizador 1972
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='11ffbe13-861e-4892-829d-2088b3be5d95'::uuid and localizador is not distinct from '§ 65') then
  raise exception 'Cambió la prosa previa de copla_castellana · localizador 1972; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set localizador='§ 65, pp. 129-130, y § 68, p. 134' where afirmacion_id='11ffbe13-861e-4892-829d-2088b3be5d95'::uuid;
end $$;

-- copla_castellana · fuente 2016
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='a6d9d28c-19fb-4fe9-a0c4-88449d1418ad'::uuid and resumen is not distinct from 'Repite la definición y las cuatro disposiciones, y ejemplifica con Baltasar del Alcázar. La sitúa en la poesía menos elevada, en los decires del final de la Edad Media, en el teatro y en el epigrama del siglo XVI.') then
  raise exception 'Cambió la prosa previa de copla_castellana · fuente 2016; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set resumen='Define ocho octosílabos, algunos ocasionalmente tetrasílabos, en dos semiestrofas de cuatro con dos rimas consonantes diferentes en cada una. Da las cuatro disposiciones habituales y ejemplifica con Baltasar del Alcázar. En la entrada «copla de pie quebrado» incluye además una estrofa de Álvarez Gato de rima `abba:cddc` con quebrados en segundo, cuarto y sexto: la licencia no queda limitada a un único verso. Sitúa la copla castellana en los decires del final de la Edad Media, el teatro y el epigrama del siglo XVI.' where afirmacion_id='a6d9d28c-19fb-4fe9-a0c4-88449d1418ad'::uuid;
end $$;

-- copla_castellana · localizador 2016
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='a6d9d28c-19fb-4fe9-a0c4-88449d1418ad'::uuid and localizador is not distinct from 'Entrada «copla castellana», pp. 88-89') then
  raise exception 'Cambió la prosa previa de copla_castellana · localizador 2016; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set localizador='Entradas «copla castellana», pp. 88-89, y «copla de pie quebrado», pp. 91-92' where afirmacion_id='a6d9d28c-19fb-4fe9-a0c4-88449d1418ad'::uuid;
end $$;

-- copla_real · fuente 1972
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='62e8c279-bf8c-49c4-90f5-c697d500202f'::uuid and resumen is not distinct from 'Explica que la copla de semiestrofas equivalentes 5-5, con dos rimas distintas en cada parte, apareció a mediados del siglo XV y se formó sobre el antiguo modelo de 4-4, en el que el papel de la redondilla sirvió de base para el triunfo de la quintilla. Señala que el tipo simétrico abaab:cdccd, repetido con preferencia por Juan de Mena, se destacó sobre las demás combinaciones hasta reconocerse como representación característica de la estrofa y como una de las más peculiares de la poesía castellana del siglo XV.') then
  raise exception 'Cambió la prosa previa de copla_real · fuente 1972; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set resumen='Explica que la copla de semiestrofas equivalentes 5-5, con dos rimas distintas en cada parte, apareció a mediados del siglo XV y se formó sobre el antiguo modelo de 4-4, en el que el papel de la redondilla sirvió de base para el triunfo de la quintilla. Señala que el tipo simétrico abaab:cdccd, repetido con preferencia por Juan de Mena, se destacó sobre las demás combinaciones hasta reconocerse como representación característica de la estrofa y como una de las más peculiares de la poesía castellana del siglo XV. En el § 68 documenta la copla real afectada por el pie quebrado, sobre todo en su segunda mitad: un quebrado final, otro interior y realizaciones con dos o más. No establece un máximo de dos quebrados.' where afirmacion_id='62e8c279-bf8c-49c4-90f5-c697d500202f'::uuid;
end $$;

-- copla_real · localizador 1972
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='62e8c279-bf8c-49c4-90f5-c697d500202f'::uuid and localizador is not distinct from '§ 66, pp. 131-132') then
  raise exception 'Cambió la prosa previa de copla_real · localizador 1972; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set localizador='§ 66, pp. 130-132, y § 68, p. 135' where afirmacion_id='62e8c279-bf8c-49c4-90f5-c697d500202f'::uuid;
end $$;

-- novena · fuente 1972
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='d8f31c19-6307-43c3-bcae-25311834d2c7'::uuid and resumen is not distinct from 'Describe la novena cancioneril como una redondilla seguida de una quintilla: la redondilla suele ser *abba* y la quintilla admite sus distintas variantes. Antes de 1450 documenta dos o tres rimas que enlazan ambas partes y, más tarde, cuatro rimas independientes; registra también el orden 5+4 y realizaciones con versos quebrados.') then
  raise exception 'Cambió la prosa previa de novena · fuente 1972; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set resumen='Describe la novena cancioneril como redondilla y quintilla: la redondilla suele ser `abba` y la quintilla admite sus variantes. Antes de 1450 documenta dos o tres rimas que enlazan ambas partes y, más tarde, cuatro independientes. En el § 68 distingue coplas de 4+5 con algún verso corto, generalmente en la quintilla, y coplas de 5+4 con quintilla de octosílabos plenos y quebrados en la redondilla, que documenta en Gómez Manrique y Juan Tallante. Por tanto, los dos órdenes tienen realizaciones quebradas.' where afirmacion_id='d8f31c19-6307-43c3-bcae-25311834d2c7'::uuid;
end $$;

-- novena · localizador 1972
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='d8f31c19-6307-43c3-bcae-25311834d2c7'::uuid and localizador is not distinct from '§§ 67 y 68, pp. 132-134') then
  raise exception 'Cambió la prosa previa de novena · localizador 1972; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set localizador='§ 67, pp. 132-133, y § 68, p. 134' where afirmacion_id='d8f31c19-6307-43c3-bcae-25311834d2c7'::uuid;
end $$;

-- quintilla · fuente 1972
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='ce47ab90-459c-4877-a35a-bcc6856c28c5'::uuid and resumen is not distinct from 'Al resumir el período renacentista registra el uso suelto de la quintilla quebrada: mientras decaen las coplas reales y castellanas y aumentan «las redondillas y quintillas emancipadas», **«la quintilla con verso inicial quebrado fue la estrofa más usada por Castillejo»**. En el mismo pasaje anota que el teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos, que en el § 131 describe como «la quintilla con quebrado inicial de Castillejo a la cual se antepone un octosílabo».') then
  raise exception 'Cambió la prosa previa de quintilla · fuente 1972; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set resumen='Al resumir el período renacentista registra el uso suelto de la quintilla quebrada: mientras decaen las coplas reales y castellanas y aumentan «las redondillas y quintillas emancipadas», «la quintilla con verso inicial quebrado fue la estrofa más usada por Castillejo». En el mismo pasaje anota que el teatro dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos, que en el § 131 describe como «la quintilla con quebrado inicial de Castillejo a la cual se antepone un octosílabo». En el § 124, nota 20, documenta además una quintilla de Ximénez de Urrea, «A la muerte de una gentil mora», con los versos segundo y quinto quebrados y rimados entre sí, `abaab`. Esa disposición no es el quebrado inicial de Castillejo.' where afirmacion_id='ce47ab90-459c-4877-a35a-bcc6856c28c5'::uuid;
end $$;

-- quintilla · localizador 1972
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='ce47ab90-459c-4877-a35a-bcc6856c28c5'::uuid and localizador is not distinct from '§§ 131 y 154, pp. 221 y 247') then
  raise exception 'Cambió la prosa previa de quintilla · localizador 1972; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set localizador='§ 124, nota 20, p. 217; §§ 131 y 154, pp. 221 y 247' where afirmacion_id='ce47ab90-459c-4877-a35a-bcc6856c28c5'::uuid;
end $$;

-- quintilla · fuente 2020
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='a5faa793-08ed-4f60-b274-29f5ebdd5d3a'::uuid and resumen is not distinct from 'Recoge abbba entre las disposiciones de la quintilla octosílaba y, más abajo, bajo «Quintilla octosilábica», **la llama «escasa» frente a «la mayoritaria ababa»**, y documenta además quintillas hexasilábicas y heptasilábicas. Registra también combinaciones con uno o dos versos sueltos —abcab, abbca, abaca, **abcaa y otras**— que describe como transgresión de las viejas normas.') then
  raise exception 'Cambió la prosa previa de quintilla · fuente 2020; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set resumen='Recoge abbba entre las disposiciones de la quintilla octosílaba y, más abajo, bajo «Quintilla octosilábica», la llama «escasa» frente a «la mayoritaria ababa», y documenta además quintillas hexasilábicas y heptasilábicas. Registra también combinaciones con uno o dos versos sueltos —abcab, abbca, abaca, abcaa y otras— que describe como transgresión de las viejas normas. En «Quintilla octosilábica» denomina quintillas de pie quebrado a las que acortan alguno de sus versos y documenta el doble quiebro en segundo y último, con el ejemplo de Ximénez de Urrea.' where afirmacion_id='a5faa793-08ed-4f60-b274-29f5ebdd5d3a'::uuid;
end $$;

-- quintilla · localizador 2020
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='a5faa793-08ed-4f60-b274-29f5ebdd5d3a'::uuid and localizador is not distinct from 'Apartados «Quintillas», «Quintilla hexasilábica» y «Quintilla heptasilábica»') then
  raise exception 'Cambió la prosa previa de quintilla · localizador 2020; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set localizador='Apartados «Quintillas», «Quintilla hexasilábica», «Quintilla heptasilábica» y «Quintilla octosilábica»' where afirmacion_id='a5faa793-08ed-4f60-b274-29f5ebdd5d3a'::uuid;
end $$;

-- sextilla · fuente 1969
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='669606fe-2f85-4f7d-b890-b582cd4e46d2'::uuid and resumen is not distinct from 'Define la sextilla como estrofa de versos de arte menor «con varias combinaciones de rima: aabaab, abcabc, ababab, **etc.**». La enumeración queda expresamente abierta. Añade que la más conocida es la copla de pie quebrado, llamada también copla de Jorge Manrique o estrofa manriqueña, que se diferencia en que los versos tercero y sexto son tetrasílabos, y documenta también una variante con los quebrados en segundo y quinto lugar. Al ejemplificar la sextilla con el *Martín Fierro* escribe `abbccb`, marcando como clase `a` un verso que no rima con ningún otro de la estrofa, donde Domínguez Caparrós escribe un guion.') then
  raise exception 'Cambió la prosa previa de sextilla · fuente 1969; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set resumen='Define la sextilla como estrofa de versos de arte menor «con varias combinaciones de rima: aabaab, abcabc, ababab, etc.». La enumeración queda expresamente abierta. Añade que la más conocida es la copla de pie quebrado, llamada también copla de Jorge Manrique o estrofa manriqueña, que se diferencia en que los versos tercero y sexto son tetrasílabos, y documenta también una variante con los quebrados en segundo y quinto lugar: la de Unamuno en *A sus ojos*, con rima `aabccb`. Al ejemplificar la sextilla con el *Martín Fierro* escribe `abbccb`, marcando como clase `a` un verso que no rima con ningún otro de la estrofa, donde Domínguez Caparrós escribe un guion.' where afirmacion_id='669606fe-2f85-4f7d-b890-b582cd4e46d2'::uuid;
end $$;

-- sextilla · fuente 2016
do $$ begin
 if not exists(select 1 from public.afirmaciones_fuentes_metricas where afirmacion_id='9df9b891-953f-4a6e-a1ca-5095c06a740c'::uuid and resumen is not distinct from 'Define la sextilla como estrofa de seis versos de arte menor cuya rima puede adoptar variadas disposiciones, y recoge «redondilla de seis versos» como otro nombre. Tipifica la alterna, con dos rimas alternadas; la correlativa, en que el primer verso rima con el cuarto, el segundo con el quinto y el tercero con el sexto; y la paralela, dividida en dos partes de tres versos ordenadas simétricamente. La sextilla de pie quebrado la describe como copla de pie quebrado en dos semiestrofas de tres versos con rima consonante, con disposiciones aabaab, aabccb o abcabc. La entrada «sextilla» tiene además un segundo sentido, que recoge de Vicente Salvá y remite a «sexteto».') then
  raise exception 'Cambió la prosa previa de sextilla · fuente 2016; revisar antes de aplicar';
 end if;
 update public.afirmaciones_fuentes_metricas set resumen='Define la sextilla como estrofa de seis versos de arte menor cuya rima puede adoptar variadas disposiciones, y recoge «redondilla de seis versos» como otro nombre. Tipifica la alterna, con dos rimas alternadas; la correlativa, en que el primer verso rima con el cuarto, el segundo con el quinto y el tercero con el sexto; y la paralela, dividida en dos partes de tres versos ordenadas simétricamente. La sextilla de pie quebrado la describe como copla de pie quebrado en dos semiestrofas de tres versos con rima consonante, con disposiciones aabaab, aabccb o abcabc. La entrada «sextilla» tiene además un segundo sentido, que recoge de Vicente Salvá y remite a «sexteto». El ejemplo de Lucas Fernández que ilustra la entrada «sextilla de pie quebrado», en la p. 391, sitúa los quebrados en segundo y quinto y rima `aabccb`: la entrada no restringe esta forma a los quebrados en tercero y sexto.' where afirmacion_id='9df9b891-953f-4a6e-a1ca-5095c06a740c'::uuid;
end $$;

-- Las posiciones abiertas siguen conservando al menos un octosílabo.
-- El límite de la pregunta no se presenta como un máximo bibliográfico del rasgo.
do $$
declare
 r record; v_arq uuid; v_em uuid; v_nuevo uuid; v_rasgo uuid;
 v_ocho uuid; v_cuatro uuid; v_cinco uuid; v_pos integer;
begin
 select rasgo_id into strict v_rasgo from public.rasgos_metricos where slug='pie_quebrado';
 select metro_id into strict v_ocho from public.metros where silabas=8;
 select metro_id into strict v_cuatro from public.metros where silabas=4;
 select metro_id into strict v_cinco from public.metros where silabas=5;

 for r in select * from (values
  ('copla_castellana','octosilabica',0,1),('copla_real','octosilabica_consonante',0,2),
  ('novena','redondilla_quintilla',0,1),('sextilla','pie_quebrado',2,2),
  ('quintilla','octosilabica_consonante',0,1)
 ) q(forma,arq,minimo,maximo) loop
  if (select count(*) from public.grupos_eleccion_metrica g
   join public.arquitecturas_forma a using(arquitectura_id) join public.formas_metricas f using(forma_id)
   where f.slug=r.forma and a.slug=r.arq and g.dimension='metro'
    and g.selecciones_min=r.minimo and g.selecciones_max=r.maximo)<>1 then
   raise exception 'Cambió la pregunta previa de %: revisar límites antes de aplicar',r.forma;
  end if;
 end loop;

 for r in select * from (values ('copla_castellana',7),('copla_real',9)) q(forma,tope) loop
  select a.arquitectura_id into strict v_arq from public.arquitecturas_forma a
   join public.formas_metricas f using(forma_id) where f.slug=r.forma and a.activo;
  select esquema_metrico_id into strict v_em from public.esquemas_metricos where arquitectura_id=v_arq;
  update public.esquemas_metricos set tipo_secuencia='ciclo',medida_uniforme=false where esquema_metrico_id=v_em;
  delete from public.esquema_metrico_posiciones where esquema_metrico_id=v_em;
  insert into public.esquema_metrico_posiciones(esquema_metrico_id,posicion,metro_id,alternativa)
   values(v_em,1,v_ocho,1);
  update public.arquitectura_rasgos set posiciones_max=null where arquitectura_id=v_arq and rasgo_id=v_rasgo;
  update public.grupos_eleccion_metrica set selecciones_max=r.tope,
   ayuda_editor='Indica la medida de los versos quebrados y deja los demás sin marcar: conservan las ocho sílabas. Debe quedar algún octosílabo pleno.'
   where arquitectura_id=v_arq and dimension='metro';
 end loop;

 -- La novena 4+5 admite los quebrados en su quintilla; la 5+4, en su redondilla.
 for r in select * from (values ('redondilla_quintilla',5,9),('quintilla_redondilla',6,9)) q(slug,primera,ultima) loop
  select a.arquitectura_id into strict v_arq from public.arquitecturas_forma a
   join public.formas_metricas f using(forma_id) where f.slug='novena' and a.slug=r.slug and a.activo;
  select esquema_metrico_id into strict v_em from public.esquemas_metricos where arquitectura_id=v_arq;
  update public.esquemas_metricos set tipo_secuencia='secuencia',medida_uniforme=null where esquema_metrico_id=v_em;
  delete from public.esquema_metrico_posiciones where esquema_metrico_id=v_em;
  insert into public.esquema_metrico_posiciones(esquema_metrico_id,posicion,metro_id,alternativa)
   select v_em,n,v_ocho,1 from generate_series(1,9) n;
  insert into public.esquema_metrico_posiciones(esquema_metrico_id,posicion,metro_id,alternativa)
   select v_em,n,m.metro_id,m.alternativa from generate_series(r.primera,r.ultima) n
   cross join (values(v_cuatro,2),(v_cinco,3)) m(metro_id,alternativa);
  insert into public.esquema_metrico_opciones(esquema_metrico_id,metro_id,rol,orden)
   values(v_em,v_ocho,'dominante',1),(v_em,v_cuatro,'quebrado',2),(v_em,v_cinco,'quebrado',3)
   on conflict do nothing;
  if r.slug='redondilla_quintilla' then
   update public.arquitectura_rasgos set posiciones_max=null where arquitectura_id=v_arq and rasgo_id=v_rasgo;
   update public.grupos_eleccion_metrica set selecciones_max=5,
    ayuda_editor='Señala los quebrados de la quintilla, en los versos 5 a 9, y su medida. Los demás versos conservan las ocho sílabas.'
    where arquitectura_id=v_arq and dimension='metro';
  else
   if exists(select 1 from public.arquitectura_rasgos where arquitectura_id=v_arq and rasgo_id=v_rasgo)
    or exists(select 1 from public.grupos_eleccion_metrica where arquitectura_id=v_arq and dimension='metro') then
     raise exception 'La novena 5+4 ya declara un quebrado: revisar el estado previo';
   end if;
   insert into public.arquitectura_rasgos(arquitectura_id,rasgo_id,modalidad,posiciones_max,nota)
    values(v_arq,v_rasgo,'admitida',null,'En el orden 5+4 la quintilla conserva sus octosílabos plenos y los quebrados se documentan en la redondilla.');
   insert into public.grupos_eleccion_metrica(arquitectura_id,slug,dimension,alcance,tipo_control,selecciones_min,selecciones_max,permite_aplicar_global,define_norma,activo,orden,ayuda_editor)
    values(v_arq,'posiciones_pie_quebrado','metro','unidad','opciones',0,4,true,false,true,2,
     'Señala los quebrados de la redondilla, en los versos 6 a 9, y su medida. La quintilla permanece en octosílabos plenos.');
  end if;
 end loop;

 -- Cada disposición se declara entera; no son cuatro versos que puedan mezclarse.
 for r in select * from (values ('sextilla','pie_quebrado',6),('quintilla','octosilabica_consonante',5)) q(forma,arq,longitud) loop
  select a.arquitectura_id into strict v_arq from public.arquitecturas_forma a
   join public.formas_metricas f using(forma_id) where f.slug=r.forma and a.slug=r.arq and a.activo;
  select esquema_metrico_id into strict v_em from public.esquemas_metricos where arquitectura_id=v_arq;
  update public.esquemas_metricos set tipo_secuencia='secuencia' where esquema_metrico_id=v_em;
  insert into public.esquemas_metricos(arquitectura_id,slug,nombre,tipo_secuencia,medida_uniforme)
   values(v_arq,'quebrados_segundo_quinto','Quebrados en segundo y quinto','secuencia',null)
   returning esquema_metrico_id into v_nuevo;
  for v_pos in 1..r.longitud loop
   if v_pos in (2,5) then
    insert into public.esquema_metrico_posiciones(esquema_metrico_id,posicion,metro_id,alternativa)
     values(v_nuevo,v_pos,v_cuatro,1),(v_nuevo,v_pos,v_cinco,2);
   else
    insert into public.esquema_metrico_posiciones(esquema_metrico_id,posicion,metro_id,alternativa)
     values(v_nuevo,v_pos,v_ocho,1);
   end if;
  end loop;
  insert into public.esquema_metrico_opciones(esquema_metrico_id,metro_id,rol,orden)
   values(v_nuevo,v_ocho,'dominante',1),(v_nuevo,v_cuatro,'quebrado',2),(v_nuevo,v_cinco,'quebrado',3);
  if r.forma='sextilla' then
   update public.grupos_eleccion_metrica set ayuda_editor='Elige la disposición completa: quebrados en tercero y sexto, o en segundo y quinto. Después indica cuánto mide cada uno; la rima se responde aparte.'
    where arquitectura_id=v_arq and dimension='metro';
  else
   update public.arquitectura_rasgos set posiciones_max=2
    where arquitectura_id=v_arq and rasgo_id=v_rasgo;
   update public.grupos_eleccion_metrica set selecciones_max=2,
    ayuda_editor='Puedes dejar la quintilla sin quebrados, señalar el inicial o elegir la disposición con segundo y quinto quebrados. Después indica su medida.'
    where arquitectura_id=v_arq and dimension='metro';
  end if;
 end loop;
end $$;

-- Una elección de medidas admite un esquema completo o no lo admite. Esta función
-- solo examina el dato posicional; no une rima y medida ni introduce otra «variedad».
create function public.admite_disposicion_quebrados(p_arquitectura uuid,p_medidas jsonb)
returns boolean language sql stable set search_path=public as $$
 with medidas as (
  select (v->>'posicion')::integer posicion,(v->>'metro_id')::uuid metro_id
  from jsonb_array_elements(coalesce(p_medidas,'[]'::jsonb)) v
 ), modelos as (
  select em.esquema_metrico_id,a.unidad_versos_min longitud
  from public.esquemas_metricos em join public.arquitecturas_forma a using(arquitectura_id)
  where em.arquitectura_id=p_arquitectura and em.tipo_secuencia='secuencia'
   and exists(select 1 from public.esquema_metrico_opciones eo where eo.esquema_metrico_id=em.esquema_metrico_id and eo.rol='quebrado')
 )
 select not exists(select 1 from modelos) or (
  (select count(*)=count(distinct posicion) from medidas)
  and exists (
   select 1 from modelos em
   where not exists(select 1 from medidas where posicion is null or metro_id is null or posicion not between 1 and em.longitud)
    and not exists(
     select 1 from generate_series(1,em.longitud) n
     where not exists(
      select 1 from public.esquema_metrico_posiciones p join public.metros m using(metro_id)
      where p.esquema_metrico_id=em.esquema_metrico_id and p.posicion=n
       and (exists(select 1 from medidas e where e.posicion=n and e.metro_id=p.metro_id)
        or (not exists(select 1 from medidas e where e.posicion=n) and m.silabas=8))
     )
    )
  )
 );
$$;

create function public.comprobar_disposiciones_quebrados(p_anotacion uuid)
returns void language plpgsql set search_path=public as $$
declare r record; v_medidas jsonb;
begin
 for r in
  select rz.realizacion_id,coalesce(rz.arquitectura_id,am.arquitectura_id) arquitectura_id
  from public.anotacion_realizaciones rz join public.anotaciones_metricas am using(anotacion_id)
  join public.arquitecturas_forma a on a.arquitectura_id=coalesce(rz.arquitectura_id,am.arquitectura_id)
  join public.formas_metricas f on f.forma_id=a.forma_id
  where am.anotacion_id=p_anotacion and rz.realizacion_padre_id is null
   and ((f.slug='sextilla' and a.slug='pie_quebrado') or (f.slug='quintilla' and a.slug='octosilabica_consonante'))
 loop
  select coalesce(jsonb_agg(jsonb_build_object('posicion',e.posicion_unidad,'metro_id',e.metro_id)),'[]'::jsonb)
   into v_medidas from public.anotacion_elecciones e
   where e.anotacion_id=p_anotacion and e.realizacion_id=r.realizacion_id
    and e.dimension='metro' and e.metro_id is not null and e.posicion_unidad is not null;
  if not public.admite_disposicion_quebrados(r.arquitectura_id,v_medidas) then
   raise exception 'Los quebrados deben corresponder a una disposición completa del catálogo' using errcode='23514';
  end if;
 end loop;
end $$;

create function public.validar_disposiciones_quebrados_diferidas()
returns trigger language plpgsql security definer set search_path=public as $$
begin
 if tg_op<>'INSERT' then perform public.comprobar_disposiciones_quebrados(old.anotacion_id); end if;
 if tg_op<>'DELETE' and (tg_op='INSERT' or new.anotacion_id is distinct from old.anotacion_id) then
  perform public.comprobar_disposiciones_quebrados(new.anotacion_id);
 end if;
 return null;
end $$;

create constraint trigger comprobar_quebrados_elecciones
 after insert or update or delete on public.anotacion_elecciones
 deferrable initially deferred for each row execute function public.validar_disposiciones_quebrados_diferidas();
create constraint trigger comprobar_quebrados_realizaciones
 after insert or update or delete on public.anotacion_realizaciones
 deferrable initially deferred for each row execute function public.validar_disposiciones_quebrados_diferidas();
create constraint trigger comprobar_quebrados_anotaciones
 after insert or update on public.anotaciones_metricas
 deferrable initially deferred for each row execute function public.validar_disposiciones_quebrados_diferidas();

-- Los comprobadores internos no son endpoints públicos. El disparador usa SECURITY
-- DEFINER para comprobar el estado final incluso al recuperar el rol authenticated
-- al terminar el guardado. La función pura solo lee catálogo público.
revoke all on function public.comprobar_disposiciones_quebrados(uuid) from public,anon,authenticated;
revoke all on function public.validar_disposiciones_quebrados_diferidas() from public,anon,authenticated;
grant execute on function public.comprobar_disposiciones_quebrados(uuid) to service_role;

-- Guardas de catálogo y de preservación de las respuestas anteriores.
do $$
declare r record;
begin
 for r in select distinct am.anotacion_id from public.anotaciones_metricas am
  join public.formas_metricas f using(forma_id) where f.slug in ('sextilla','quintilla')
 loop perform public.comprobar_disposiciones_quebrados(r.anotacion_id); end loop;
 if (select count(*) from public.opciones_eleccion_metrica o join public.grupos_eleccion_metrica g using(grupo_eleccion_id)
   join public.arquitecturas_forma a using(arquitectura_id) join public.formas_metricas f using(forma_id)
   where f.slug='sextilla' and a.slug='pie_quebrado' and g.dimension='metro')<>8 then
  raise exception 'La sextilla debe ofrecer cuatro posiciones candidatas, de cuatro o cinco sílabas';
 end if;
end $$;



-- El énfasis no forma parte del contenido filológico: se retira en todo el
-- catálogo, también de las fichas que no necesitan cambios de medida o rima.
update public.formas_metricas
 set definicion=replace(definicion,'**','') where strpos(definicion,'**')>0;
update public.arquitecturas_forma
 set descripcion=replace(descripcion,'**','') where strpos(descripcion,'**')>0;
update public.afirmaciones_fuentes_metricas
 set resumen=replace(resumen,'**','') where strpos(resumen,'**')>0;

commit;

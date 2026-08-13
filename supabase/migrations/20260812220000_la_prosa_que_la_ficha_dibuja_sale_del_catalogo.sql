-- La prosa que la ficha ya dibuja sale del catálogo.
--
-- Desde que la ficha dibuja la unidad verso a verso, buena parte de la prosa de los niveles bajos
-- dice en palabras lo que la figura enseña: «Cuatro octosílabos» donde se leen cuatro casillas con
-- un 8, «Las dos clases de rima alternan verso a verso» donde se lee `abab`. No estaban mal
-- escritas —la **regla 1** de `donde-vive-la-prosa.md` ya decía «no escribir lo que la ficha
-- deriva»—: es que la ficha pasó a derivar mucho más.
--
-- Se vacían 138 textos, **todos ellos aprobados uno a uno por el IP** sobre el informe que
-- genera `npm run poda:informe`. Cada uno lleva encima, en un comentario, lo que decía, para que
-- el registro no dependa de esta base.
--
-- **Lo que esta migración no toca**, por decisión del IP:
--   · la definición de la forma y la descripción de la arquitectura, que sitúan y no repiten;
--   · las notas de enlaces de rima, de repeticiones, de rasgos y de relaciones, que sí aportan
--     —una relación que habla de otra forma está haciendo justamente lo que debe—;
--   · los textos cuya única razón para sobrar era nombrar otra forma: se revisan aparte, porque
--     a veces esa referencia es lo único que aporta el texto;
--   · los que solo se acortan, que se revisan uno a uno para que la frase no quede coja.

-- esquemas_metricos.nombre · 42 textos
-- cuarteto/endecasilabica · 11-repetido: «Endecasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'cuarteto' and a.slug = 'endecasilabica' and em.slug = '11-repetido';

-- sexteto/alejandrina · 14-repetido: «Seis alejandrinos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto' and a.slug = 'alejandrina' and em.slug = '14-repetido';

-- sexteto/dodecasilabica · 12-repetido: «Seis dodecasílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto' and a.slug = 'dodecasilabica' and em.slug = '12-repetido';

-- sexteto/endecasilabica · 11-repetido: «Seis endecasílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto' and a.slug = 'endecasilabica' and em.slug = '11-repetido';

-- decima/aumentada · 8-repetido: «Doce octosílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'decima' and a.slug = 'aumentada' and em.slug = '8-repetido';

-- redondilla/octosilabica · 8-repetido: «Cuatro octosílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'octosilabica' and em.slug = '8-repetido';

-- redondilla/doble_enlazada · 8-repetido: «Ocho octosílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'doble_enlazada' and em.slug = '8-repetido';

-- decima/espinela · 8-repetido: «Diez octosílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'decima' and a.slug = 'espinela' and em.slug = '8-repetido';

-- sextina_estrofa/endecasilabica_sin_rima · 11-repetido: «Endecasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextina_estrofa' and a.slug = 'endecasilabica_sin_rima' and em.slug = '11-repetido';

-- sextina/clasica · 11-repetido: «Endecasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextina' and a.slug = 'clasica' and em.slug = '11-repetido';

-- sextina/doble_petrarquista · 11-repetido: «Endecasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextina' and a.slug = 'doble_petrarquista' and em.slug = '11-repetido';

-- sextina/doble_montemayor · 11-repetido: «Endecasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextina' and a.slug = 'doble_montemayor' and em.slug = '11-repetido';

-- sextilla/heptasilabica · 7-repetido: «Seis heptasílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextilla' and a.slug = 'heptasilabica' and em.slug = '7-repetido';

-- sextilla/hexasilabica · 6-repetido: «Seis hexasílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextilla' and a.slug = 'hexasilabica' and em.slug = '6-repetido';

-- sextilla/octosilabica · 8-repetido: «Seis octosílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextilla' and a.slug = 'octosilabica' and em.slug = '8-repetido';

-- silva/consonante_regular · 7-11-repetido: «7-11 repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'silva' and a.slug = 'consonante_regular' and em.slug = '7-11-repetido';

-- silva/endecasilabica · 11-repetido: «Endecasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'silva' and a.slug = 'endecasilabica' and em.slug = '11-repetido';

-- endecasilabo_suelto/endecasilabica · 11-repetido: «Endecasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'endecasilabo_suelto' and a.slug = 'endecasilabica' and em.slug = '11-repetido';

-- soneto/endecasilabica_consonante · 11-repetido: «Endecasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'soneto' and a.slug = 'endecasilabica_consonante' and em.slug = '11-repetido';

-- villancico/estribillo_tras_primera_copla · conjunto-6-8: «Hexasílabo u octosílabo»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'villancico' and a.slug = 'estribillo_tras_primera_copla' and em.slug = 'conjunto-6-8';

-- silva/libre · conjunto-7-11: «Heptasílabo o endecasílabo»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'silva' and a.slug = 'libre' and em.slug = 'conjunto-7-11';

-- copla_real/octosilabica_consonante · 8-repetido: «Diez octosílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'copla_real' and a.slug = 'octosilabica_consonante' and em.slug = '8-repetido';

-- novena/redondilla_quintilla · 8-repetido: «Nueve octosílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'novena' and a.slug = 'redondilla_quintilla' and em.slug = '8-repetido';

-- redondilla/hexasilabica · 6-repetido: «Cuatro hexasílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'hexasilabica' and em.slug = '6-repetido';

-- copla_de_arte_mayor/dodecasilabica_compuesta · 12-repetido: «Ocho dodecasílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'copla_de_arte_mayor' and a.slug = 'dodecasilabica_compuesta' and em.slug = '12-repetido';

-- novena/quintilla_redondilla · 8-repetido: «Nueve octosílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'novena' and a.slug = 'quintilla_redondilla' and em.slug = '8-repetido';

-- redondilla/heptasilabica · 7-repetido: «Cuatro heptasílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'heptasilabica' and em.slug = '7-repetido';

-- villancico/estribillo_inicial · conjunto-6-8: «Hexasílabo u octosílabo»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'villancico' and a.slug = 'estribillo_inicial' and em.slug = 'conjunto-6-8';

-- zejel/estribillo_y_coplas_monorrimas · conjunto-6-8: «Hexasílabo u octosílabo»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'zejel' and a.slug = 'estribillo_y_coplas_monorrimas' and em.slug = 'conjunto-6-8';

-- silva/consonante_irregular · conjunto-7-11: «Heptasílabo o endecasílabo»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'silva' and a.slug = 'consonante_irregular' and em.slug = 'conjunto-7-11';

-- pareado/cualquier_medida · conjunto-4-14: «De 4 a 14 sílabas»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'pareado' and a.slug = 'cualquier_medida' and em.slug = 'conjunto-4-14';

-- terceto/endecasilabica_consonante · 11-repetido: «Tres endecasílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'terceto' and a.slug = 'endecasilabica_consonante' and em.slug = '11-repetido';

-- quintilla/octosilabica_consonante · 8-repetido: «Cinco octosílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'quintilla' and a.slug = 'octosilabica_consonante' and em.slug = '8-repetido';

-- octava_real/endecasilabica_consonante · 11-repetido: «Ocho endecasílabos»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'octava_real' and a.slug = 'endecasilabica_consonante' and em.slug = '11-repetido';

-- terceto_encadenado/endecasilabica_consonante · 11-repetido: «Endecasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'terceto_encadenado' and a.slug = 'endecasilabica_consonante' and em.slug = '11-repetido';

-- romance/octosilabica · 8-repetido: «Octosílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'romance' and a.slug = 'octosilabica' and em.slug = '8-repetido';

-- terceto_encadenado/octosilabica_consonante · 8-repetido: «Octosílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'terceto_encadenado' and a.slug = 'octosilabica_consonante' and em.slug = '8-repetido';

-- cancion_petrarquista/estancias_consonantes_variables · conjunto-7-11: «Heptasílabo o endecasílabo»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'cancion_petrarquista' and a.slug = 'estancias_consonantes_variables' and em.slug = 'conjunto-7-11';

-- cancion_petrarquista/sin_rima_con_pareado_final · conjunto-7-11: «Heptasílabo o endecasílabo»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'cancion_petrarquista' and a.slug = 'sin_rima_con_pareado_final' and em.slug = 'conjunto-7-11';

-- romance/endecasilabica · 11-repetido: «Endecasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'romance' and a.slug = 'endecasilabica' and em.slug = '11-repetido';

-- romance/hexasilabica · 6-repetido: «Hexasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'romance' and a.slug = 'hexasilabica' and em.slug = '6-repetido';

-- romance/heptasilabica · 7-repetido: «Heptasílabo repetido»
update public.esquemas_metricos em set nombre = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'romance' and a.slug = 'heptasilabica' and em.slug = '7-repetido';

-- esquemas_metricos.descripcion · 35 textos
-- decima/aumentada · 8-repetido: «Un octosílabo en cada una de las doce posiciones.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'decima' and a.slug = 'aumentada' and em.slug = '8-repetido';

-- redondilla/octosilabica · 8-repetido: «La misma medida se aplica a las 4 posiciones de la unidad.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'octosilabica' and em.slug = '8-repetido';

-- redondilla/doble_enlazada · 8-repetido: «La misma medida se aplica a las 8 posiciones de la unidad.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'doble_enlazada' and em.slug = '8-repetido';

-- decima/espinela · 8-repetido: «Un octosílabo en cada una de las diez posiciones.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'decima' and a.slug = 'espinela' and em.slug = '8-repetido';

-- sextina_estrofa/endecasilabica_sin_rima · 11-repetido: «La misma medida endecasilábica ocupa los seis versos.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextina_estrofa' and a.slug = 'endecasilabica_sin_rima' and em.slug = '11-repetido';

-- silva/consonante_regular · 7-11-repetido: «Ciclo de dos posiciones: un heptasílabo seguido de un endecasílabo, repetido durante toda la serie.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'silva' and a.slug = 'consonante_regular' and em.slug = '7-11-repetido';

-- silva/endecasilabica · 11-repetido: «Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'silva' and a.slug = 'endecasilabica' and em.slug = '11-repetido';

-- endecasilabo_suelto/endecasilabica · 11-repetido: «Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'endecasilabo_suelto' and a.slug = 'endecasilabica' and em.slug = '11-repetido';

-- soneto/endecasilabica_consonante · 11-repetido: «El mismo modelo endecasílabo se aplica a los catorce versos fijados por la configuración.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'soneto' and a.slug = 'endecasilabica_consonante' and em.slug = '11-repetido';

-- sexteto_lira/heterometrica_consonante · 7-11-7-11-7-11: «Alternancia de heptasílabos y endecasílabos.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and em.slug = '7-11-7-11-7-11';

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-7-11: «Endecasílabos en las posiciones 1, 4 y 6.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and em.slug = '11-7-7-11-7-11';

-- sexteto_lira/heterometrica_consonante · 7-7-7-11-7-11: «Endecasílabos en las posiciones 4 y 6.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and em.slug = '7-7-7-11-7-11';

-- sexteto_lira/heterometrica_consonante · 7-7-7-7-7-11: «Cinco heptasílabos y endecasílabo final.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and em.slug = '7-7-7-7-7-11';

-- sexteto_lira/heterometrica_consonante · 11-7-7-11-11-11: «Endecasílabos en las posiciones 1, 4, 5 y 6.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and em.slug = '11-7-7-11-11-11';

-- seguidilla/simple · 7-5-7-5: «Heptasílabos en las posiciones impares y pentasílabos en las pares.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'seguidilla' and a.slug = 'simple' and em.slug = '7-5-7-5';

-- endecha_real/heptasilabica_con_endecasilabo · 7-7-7-11: «Ciclo de cuatro posiciones: tres heptasílabos y un endecasílabo, repetido durante toda la serie.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'endecha_real' and a.slug = 'heptasilabica_con_endecasilabo' and em.slug = '7-7-7-11';

-- seguidilla/gitana · 6-6-10-11-12-6: «Hexasílabos en primero, segundo y cuarto; el tercero admite diez, once o doce sílabas.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'seguidilla' and a.slug = 'gitana' and em.slug = '6-6-10-11-12-6';

-- seguidilla/real · 10-6-10-6: «Decasílabos en las posiciones impares y hexasílabos en las pares.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'seguidilla' and a.slug = 'real' and em.slug = '10-6-10-6';

-- novena/redondilla_quintilla · 8-repetido: «Una posición octosilábica fija por cada uno de los nueve versos.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'novena' and a.slug = 'redondilla_quintilla' and em.slug = '8-repetido';

-- redondilla/hexasilabica · 6-repetido: «La misma medida se aplica a las 4 posiciones de la unidad.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'hexasilabica' and em.slug = '6-repetido';

-- copla_de_arte_mayor/dodecasilabica_compuesta · 12-repetido: «El modelo compuesto 6 + 6 ocupa las ocho posiciones de la estrofa.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'copla_de_arte_mayor' and a.slug = 'dodecasilabica_compuesta' and em.slug = '12-repetido';

-- novena/quintilla_redondilla · 8-repetido: «Una posición octosilábica fija por cada uno de los nueve versos.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'novena' and a.slug = 'quintilla_redondilla' and em.slug = '8-repetido';

-- redondilla/heptasilabica · 7-repetido: «La misma medida se aplica a las 4 posiciones de la unidad.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'heptasilabica' and em.slug = '7-repetido';

-- endecha_real/heptasilabica_con_endecasilabo_de_cinco · redondilla_con_endecasilabo: «Ciclo de cinco posiciones: cuatro heptasílabos y un endecasílabo.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'endecha_real' and a.slug = 'heptasilabica_con_endecasilabo_de_cinco' and em.slug = 'redondilla_con_endecasilabo';

-- terceto/endecasilabica_consonante · 11-repetido: «Una posición endecasilábica por cada uno de los tres versos de la estrofa.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'terceto' and a.slug = 'endecasilabica_consonante' and em.slug = '11-repetido';

-- quintilla/octosilabica_consonante · 8-repetido: «Una posición octosilábica por cada uno de los cinco versos de la estrofa.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'quintilla' and a.slug = 'octosilabica_consonante' and em.slug = '8-repetido';

-- octava_real/endecasilabica_consonante · 11-repetido: «Una posición endecasilábica fija por cada uno de los ocho versos.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'octava_real' and a.slug = 'endecasilabica_consonante' and em.slug = '11-repetido';

-- terceto_encadenado/endecasilabica_consonante · 11-repetido: «Un verso endecasílabo por cada posición del ciclo métrico, repetido durante toda la serie.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'terceto_encadenado' and a.slug = 'endecasilabica_consonante' and em.slug = '11-repetido';

-- lira/heptasilabica_endecasilabica · 7-11-7-7-11: «Heptasílabos en las posiciones 1, 3 y 4; endecasílabos en las posiciones 2 y 5.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'lira' and a.slug = 'heptasilabica_endecasilabica' and em.slug = '7-11-7-7-11';

-- romance/octosilabica · 8-repetido: «Un verso octosílabo por cada posición del ciclo, repetido durante toda la serie.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'romance' and a.slug = 'octosilabica' and em.slug = '8-repetido';

-- terceto_encadenado/octosilabica_consonante · 8-repetido: «Un verso octosílabo por cada posición del ciclo métrico, repetido durante toda la serie.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'terceto_encadenado' and a.slug = 'octosilabica_consonante' and em.slug = '8-repetido';

-- endecha_real/hexasilabica_con_endecasilabo · hexasilabica_con_endecasilabo: «Ciclo de cuatro posiciones: tres hexasílabos y un endecasílabo.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'endecha_real' and a.slug = 'hexasilabica_con_endecasilabo' and em.slug = 'hexasilabica_con_endecasilabo';

-- romance/endecasilabica · 11-repetido: «Un endecasílabo por cada posición del ciclo, repetido durante toda la serie.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'romance' and a.slug = 'endecasilabica' and em.slug = '11-repetido';

-- romance/hexasilabica · 6-repetido: «Un verso de 6 sílabas por cada posición del ciclo, repetido durante toda la serie.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'romance' and a.slug = 'hexasilabica' and em.slug = '6-repetido';

-- romance/heptasilabica · 7-repetido: «Un verso de 7 sílabas por cada posición del ciclo, repetido durante toda la serie.»
update public.esquemas_metricos em set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'romance' and a.slug = 'heptasilabica' and em.slug = '7-repetido';

-- esquema_metrico_posiciones.nota · 21 textos
-- romance/octosilabica · 8-repetido pos.1: «El ciclo métrico de un solo verso se repite durante toda la serie.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'romance' and a.slug = 'octosilabica'
		and em.slug = '8-repetido' and p.posicion = 1 and coalesce(p.alternativa, 1) = 1;

-- terceto_encadenado/endecasilabica_consonante · 11-repetido pos.1: «El ciclo métrico de un solo verso se repite durante toda la serie.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'terceto_encadenado' and a.slug = 'endecasilabica_consonante'
		and em.slug = '11-repetido' and p.posicion = 1 and coalesce(p.alternativa, 1) = 1;

-- terceto_encadenado/octosilabica_consonante · 8-repetido pos.1: «Medida documentada por la definición heredada; la configuración permanece pendiente de revisión.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'terceto_encadenado' and a.slug = 'octosilabica_consonante'
		and em.slug = '8-repetido' and p.posicion = 1 and coalesce(p.alternativa, 1) = 1;

-- silva/consonante_regular · 7-11-repetido pos.1: «Primera posición del pareado regular.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'silva' and a.slug = 'consonante_regular'
		and em.slug = '7-11-repetido' and p.posicion = 1 and coalesce(p.alternativa, 1) = 1;

-- silva/consonante_regular · 7-11-repetido pos.2: «Segunda posición del pareado regular.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'silva' and a.slug = 'consonante_regular'
		and em.slug = '7-11-repetido' and p.posicion = 2 and coalesce(p.alternativa, 1) = 1;

-- silva/endecasilabica · 11-repetido pos.1: «El endecasílabo se repite durante toda la serie.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'silva' and a.slug = 'endecasilabica'
		and em.slug = '11-repetido' and p.posicion = 1 and coalesce(p.alternativa, 1) = 1;

-- endecasilabo_suelto/endecasilabica · 11-repetido pos.1: «El endecasílabo se repite durante toda la serie.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'endecasilabo_suelto' and a.slug = 'endecasilabica'
		and em.slug = '11-repetido' and p.posicion = 1 and coalesce(p.alternativa, 1) = 1;

-- sextina_estrofa/endecasilabica_sin_rima · 11-repetido pos.1: «Esta posición se repite en los seis versos de la estrofa.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'sextina_estrofa' and a.slug = 'endecasilabica_sin_rima'
		and em.slug = '11-repetido' and p.posicion = 1 and coalesce(p.alternativa, 1) = 1;

-- lira/heptasilabica_endecasilabica · 7-11-7-7-11 pos.3: «Segundo heptasílabo.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'lira' and a.slug = 'heptasilabica_endecasilabica'
		and em.slug = '7-11-7-7-11' and p.posicion = 3 and coalesce(p.alternativa, 1) = 1;

-- lira/heptasilabica_endecasilabica · 7-11-7-7-11 pos.5: «Segundo endecasílabo.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'lira' and a.slug = 'heptasilabica_endecasilabica'
		and em.slug = '7-11-7-7-11' and p.posicion = 5 and coalesce(p.alternativa, 1) = 1;

-- seguidilla/simple · 7-5-7-5 pos.3: «Segundo heptasílabo.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'seguidilla' and a.slug = 'simple'
		and em.slug = '7-5-7-5' and p.posicion = 3 and coalesce(p.alternativa, 1) = 1;

-- seguidilla/simple · 7-5-7-5 pos.4: «Segundo pentasílabo.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'seguidilla' and a.slug = 'simple'
		and em.slug = '7-5-7-5' and p.posicion = 4 and coalesce(p.alternativa, 1) = 1;

-- romance/endecasilabica · 11-repetido pos.1: «El ciclo métrico de un solo verso se repite durante toda la serie.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'romance' and a.slug = 'endecasilabica'
		and em.slug = '11-repetido' and p.posicion = 1 and coalesce(p.alternativa, 1) = 1;

-- seguidilla/gitana · 6-6-10-11-12-6 pos.2: «Segundo hexasílabo.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'seguidilla' and a.slug = 'gitana'
		and em.slug = '6-6-10-11-12-6' and p.posicion = 2 and coalesce(p.alternativa, 1) = 1;

-- seguidilla/gitana · 6-6-10-11-12-6 pos.4: «Hexasílabo final.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'seguidilla' and a.slug = 'gitana'
		and em.slug = '6-6-10-11-12-6' and p.posicion = 4 and coalesce(p.alternativa, 1) = 1;

-- seguidilla/gitana · 6-6-10-11-12-6 pos.2: «Segundo hexasílabo.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'seguidilla' and a.slug = 'gitana'
		and em.slug = '6-6-10-11-12-6' and p.posicion = 2 and coalesce(p.alternativa, 1) = 2;

-- romance/hexasilabica · 6-repetido pos.1: «El ciclo métrico de un solo verso se repite durante toda la serie.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'romance' and a.slug = 'hexasilabica'
		and em.slug = '6-repetido' and p.posicion = 1 and coalesce(p.alternativa, 1) = 1;

-- romance/heptasilabica · 7-repetido pos.1: «El ciclo métrico de un solo verso se repite durante toda la serie.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'romance' and a.slug = 'heptasilabica'
		and em.slug = '7-repetido' and p.posicion = 1 and coalesce(p.alternativa, 1) = 1;

-- seguidilla/gitana · 6-6-10-11-12-6 pos.4: «Hexasílabo final.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'seguidilla' and a.slug = 'gitana'
		and em.slug = '6-6-10-11-12-6' and p.posicion = 4 and coalesce(p.alternativa, 1) = 2;

-- seguidilla/gitana · 6-6-10-11-12-6 pos.2: «Segundo hexasílabo.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'seguidilla' and a.slug = 'gitana'
		and em.slug = '6-6-10-11-12-6' and p.posicion = 2 and coalesce(p.alternativa, 1) = 3;

-- seguidilla/gitana · 6-6-10-11-12-6 pos.4: «Hexasílabo final.»
update public.esquema_metrico_posiciones p set nota = null, updated_at = now()
	from public.esquemas_metricos em, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_metrico_id = em.esquema_metrico_id and em.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'seguidilla' and a.slug = 'gitana'
		and em.slug = '6-6-10-11-12-6' and p.posicion = 4 and coalesce(p.alternativa, 1) = 3;

-- esquemas_rima.descripcion · 24 textos
-- cuarteto/endecasilabica · abab: «Las dos clases de rima alternan verso a verso. Es la disposición del serventesio, y en el soneto una realización documentada aunque menos frecuente.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'cuarteto' and a.slug = 'endecasilabica' and er.slug = 'abab';

-- soneto/endecasilabica_consonante · abababab: «Los dos cuartetos alternan sus rimas y comparten las dos clases. El Diccionario la registra como la otra distribución posible, aunque es rara.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'soneto' and a.slug = 'endecasilabica_consonante' and er.slug = 'abababab';

-- villancico/estribillo_inicial · abab: «Alternativa habitual para la mudanza de cuatro versos.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'villancico' and a.slug = 'estribillo_inicial' and er.slug = 'abab';

-- villancico/estribillo_tras_primera_copla · abab: «Alternativa habitual para la mudanza de cuatro versos.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'villancico' and a.slug = 'estribillo_tras_primera_copla' and er.slug = 'abab';

-- villancico/estribillo_tras_primera_copla · abba: «Alternativa habitual para la mudanza de cuatro versos.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'villancico' and a.slug = 'estribillo_tras_primera_copla' and er.slug = 'abba';

-- seguidilla/tres_versos · asonancia-extremos: «Los pentasílabos primero y tercero comparten asonancia; el heptasílabo queda suelto.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'seguidilla' and a.slug = 'tres_versos' and er.slug = 'asonancia-extremos';

-- seguidilla/gitana · asonancia-pares: «El segundo y el cuarto verso comparten asonancia; primero y tercero quedan sueltos.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'seguidilla' and a.slug = 'gitana' and er.slug = 'asonancia-pares';

-- seguidilla/real · asonancia-pares: «El segundo y el cuarto verso comparten asonancia; primero y tercero quedan sueltos.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'seguidilla' and a.slug = 'real' and er.slug = 'asonancia-pares';

-- villancico/estribillo_inicial · abba: «Alternativa habitual para la mudanza de cuatro versos.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'villancico' and a.slug = 'estribillo_inicial' and er.slug = 'abba';

-- sexteto/endecasilabica · ababcc: «Los cuatro primeros versos alternan dos rimas y los dos últimos cierran con un pareado de tercera rima.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto' and a.slug = 'endecasilabica' and er.slug = 'ababcc';

-- sextilla/octosilabica · distribucion-variable: «La sextilla admite distintas distribuciones de rima consonante.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextilla' and a.slug = 'octosilabica' and er.slug = 'distribucion-variable';

-- sextilla/pie_quebrado · distribucion-variable: «La sextilla admite distintas distribuciones de rima consonante.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextilla' and a.slug = 'pie_quebrado' and er.slug = 'distribucion-variable';

-- decima/aumentada · abbaaccddeed: «Esquema documentado de doce versos con pausa tras el primer bloque abba.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'decima' and a.slug = 'aumentada' and er.slug = 'abbaaccddeed';

-- quintilla/octosilabica_consonante · abaab: «La primera clase se repite en el centro y la segunda cierra la estrofa.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'quintilla' and a.slug = 'octosilabica_consonante' and er.slug = 'abaab';

-- sextilla/octosilabica · ababab: «Dos rimas que se alternan verso a verso a lo largo de la estrofa.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sextilla' and a.slug = 'octosilabica' and er.slug = 'ababab';

-- redondilla/octosilabica · abab: «Las dos clases de rima alternan verso a verso.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'octosilabica' and er.slug = 'abab';

-- seguidilla/simple · -a-a: «Los versos 1 y 3 quedan sueltos; los versos 2 y 4 comparten asonancia.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'seguidilla' and a.slug = 'simple' and er.slug = '-a-a';

-- sexteto_lira/heterometrica_consonante · abbacc: «Rima abrazada abba en los cuatro primeros versos y pareado final cc.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and er.slug = 'abbacc';

-- sexteto_lira/heterometrica_consonante · ababcc: «Alternancia abab en los cuatro primeros versos y pareado final cc.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'sexteto_lira' and a.slug = 'heterometrica_consonante' and er.slug = 'ababcc';

-- quintilla/octosilabica_consonante · ababa: «Las dos clases alternan verso a verso. Es la disposición más simple y más antigua, y la más frecuente en el teatro áureo.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'quintilla' and a.slug = 'octosilabica_consonante' and er.slug = 'ababa';

-- copla_de_pie_quebrado/octosilabica_con_quebrados · distribucion-variable: «La rima es consonante, sin una disposición fija entre las posiciones de la unidad.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'copla_de_pie_quebrado' and a.slug = 'octosilabica_con_quebrados' and er.slug = 'distribucion-variable';

-- redondilla/heptasilabica · abab: «Las dos clases de rima alternan verso a verso.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'heptasilabica' and er.slug = 'abab';

-- redondilla/hexasilabica · abab: «Las dos clases de rima alternan verso a verso.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'redondilla' and a.slug = 'hexasilabica' and er.slug = 'abab';

-- cancion_petrarquista/sin_rima_con_pareado_final · cuerpo-sin-rima: «Todos los versos del cuerpo carecen normativamente de rima.»
update public.esquemas_rima er set descripcion = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where er.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'cancion_petrarquista' and a.slug = 'sin_rima_con_pareado_final' and er.slug = 'cuerpo-sin-rima';

-- esquema_rima_posiciones.nota · 9 textos
-- romance/octosilabica · asonancia-pares pos.2: «Verso par con la misma asonancia en cada repetición del ciclo.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
	from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'romance' and a.slug = 'octosilabica'
		and er.slug = 'asonancia-pares' and p.bloque = 1 and p.posicion = 2;

-- silva/consonante_regular · pareados-regulares pos.2: «Segundo verso del pareado.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
	from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'silva' and a.slug = 'consonante_regular'
		and er.slug = 'pareados-regulares' and p.bloque = 1 and p.posicion = 2;

-- decima/espinela · abbaaccddc pos.5: «Repite la rima última de la primera redondilla y anuncia la primera de la segunda.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
	from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'decima' and a.slug = 'espinela'
		and er.slug = 'abbaaccddc' and p.bloque = 1 and p.posicion = 5;

-- decima/espinela · abbaaccddc pos.6: «Repite la rima última de la primera redondilla y anuncia la primera de la segunda.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
	from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'decima' and a.slug = 'espinela'
		and er.slug = 'abbaaccddc' and p.bloque = 1 and p.posicion = 6;

-- decima/aumentada · abbaaccddeed pos.5: «Repite la rima última de la primera redondilla y anuncia la primera de la segunda.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
	from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'decima' and a.slug = 'aumentada'
		and er.slug = 'abbaaccddeed' and p.bloque = 1 and p.posicion = 5;

-- decima/aumentada · abbaaccddeed pos.6: «Repite la rima última de la primera redondilla y anuncia la primera de la segunda.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
	from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'decima' and a.slug = 'aumentada'
		and er.slug = 'abbaaccddeed' and p.bloque = 1 and p.posicion = 6;

-- romance/hexasilabica · asonancia-pares pos.2: «Verso par con la misma asonancia en cada repetición del ciclo.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
	from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'romance' and a.slug = 'hexasilabica'
		and er.slug = 'asonancia-pares' and p.bloque = 1 and p.posicion = 2;

-- romance/heptasilabica · asonancia-pares pos.2: «Verso par con la misma asonancia en cada repetición del ciclo.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
	from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'romance' and a.slug = 'heptasilabica'
		and er.slug = 'asonancia-pares' and p.bloque = 1 and p.posicion = 2;

-- romance/endecasilabica · asonancia-pares pos.2: «Verso par con la misma asonancia en cada repetición del ciclo.»
update public.esquema_rima_posiciones p set nota = null, updated_at = now()
	from public.esquemas_rima er, public.arquitecturas_forma a, public.formas_metricas f
	where p.esquema_rima_id = er.esquema_rima_id and er.arquitectura_id = a.arquitectura_id
		and a.forma_id = f.forma_id and f.slug = 'romance' and a.slug = 'endecasilabica'
		and er.slug = 'asonancia-pares' and p.bloque = 1 and p.posicion = 2;

-- estructuras_secciones.nota · 7 textos
-- silva/consonante_regular · pareado: «Cada bloque repite un heptasílabo y un endecasílabo con la misma rima consonante.»
update public.estructuras_secciones s set nota = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where s.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'silva' and a.slug = 'consonante_regular' and s.slug = 'pareado';

-- novena/redondilla_quintilla · quintilla: «Cinco octosílabos que riman como una quintilla, que el catálogo recoge como forma aparte.»
update public.estructuras_secciones s set nota = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where s.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'novena' and a.slug = 'redondilla_quintilla' and s.slug = 'quintilla';

-- novena/quintilla_redondilla · quintilla: «Cinco octosílabos que riman como una quintilla, que el catálogo recoge como forma aparte.»
update public.estructuras_secciones s set nota = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where s.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'novena' and a.slug = 'quintilla_redondilla' and s.slug = 'quintilla';

-- novena/redondilla_quintilla · redondilla: «Cuatro octosílabos que riman como una redondilla, que el catálogo recoge como forma aparte.»
update public.estructuras_secciones s set nota = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where s.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'novena' and a.slug = 'redondilla_quintilla' and s.slug = 'redondilla';

-- novena/quintilla_redondilla · redondilla: «Cuatro octosílabos que riman como una redondilla, que el catálogo recoge como forma aparte.»
update public.estructuras_secciones s set nota = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where s.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'novena' and a.slug = 'quintilla_redondilla' and s.slug = 'redondilla';

-- decima/espinela · enlace: «Versos centrales ac que enlazan ambos bloques.»
update public.estructuras_secciones s set nota = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where s.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'decima' and a.slug = 'espinela' and s.slug = 'enlace';

-- cancion_petrarquista/sin_rima_con_pareado_final · pareado_final: «Dos versos de rima consonante.»
update public.estructuras_secciones s set nota = null, updated_at = now()
	from public.arquitecturas_forma a, public.formas_metricas f
	where s.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
		and f.slug = 'cancion_petrarquista' and a.slug = 'sin_rima_con_pareado_final' and s.slug = 'pareado_final';

-- Tres correcciones que el IP señaló al revisar, y que no salían del criterio automático.

-- La copla real contaba además cómo se rellena el formulario. La prosa del catálogo describe la
-- forma, no el acto de anotarla, y de la primera frase se encarga la figura.
update public.esquemas_metricos em
set descripcion = 'Uno o dos versos pueden aparecer quebrados.', updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'copla_real' and a.slug = 'octosilabica_consonante' and em.slug = '8-repetido';

-- El zéjel decía «El catálogo registra qué medidas aparecen en cada secuencia sin imponer un orden
-- fijo», que es obvio y además habla del catálogo en vez de la forma; lo anterior es el repertorio.
update public.esquemas_metricos em set descripcion = null, updated_at = now()
from public.arquitecturas_forma a, public.formas_metricas f
where em.arquitectura_id = a.arquitectura_id and a.forma_id = f.forma_id
	and f.slug = 'zejel' and a.slug = 'estribillo_y_coplas_monorrimas' and em.slug = 'conjunto-6-8';

do $$
declare
	restantes integer;
begin
	-- Ninguno de los textos vaciados puede seguir ahí, y lo que se salvó tiene que seguir entero.
	select count(*) into restantes
	from public.esquemas_metricos em
	join public.arquitecturas_forma a using (arquitectura_id)
	join public.formas_metricas f using (forma_id)
	where f.slug = 'copla_real' and em.slug = '8-repetido'
		and em.descripcion <> 'Uno o dos versos pueden aparecer quebrados.';
	if restantes > 0 then
		raise exception 'la descripción de la copla real no quedó como se aprobó';
	end if;

	select count(*) into restantes from public.esquema_rima_enlaces where nota is not null;
	if restantes = 0 then
		raise exception 'las notas de los enlaces de rima se han perdido, y estaban salvadas';
	end if;

	select count(*) into restantes from public.repeticiones_metricas where descripcion is not null;
	if restantes = 0 then
		raise exception 'las descripciones de las repeticiones se han perdido, y estaban salvadas';
	end if;

	select count(*) into restantes from public.arquitectura_rasgos where nota is not null;
	if restantes = 0 then
		raise exception 'las notas de los rasgos se han perdido, y estaban salvadas';
	end if;

	select count(*) into restantes from public.forma_relaciones where nota is not null;
	if restantes = 0 then
		raise exception 'las notas de las relaciones se han perdido, y estaban salvadas';
	end if;
end;
$$;

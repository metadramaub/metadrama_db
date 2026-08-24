-- El vocabulario legado declara lo que sabía
--
-- Primera migración de A1. La revisión completa del vocabulario viejo —24 de agosto de 2026—
-- encontró que **los términos legados sabían más de lo que declaraban**: 42 de ellos guardan su
-- esquema de rima literal en `patron_especifico`, y el árbol de 89 términos con padre distingue
-- las realizaciones que el editor nuevo pregunta una a una.
--
-- Nada de eso llegaba a la propuesta de migración porque `origen_termino_id` es **único en cada
-- tabla**: un término solo puede reclamar una cosa, y varios de estos dicen dos o tres a la vez.
-- Para eso existe `equivalencias_respuestas_legadas`, construida en su día y con solo siete filas:
-- permite que **un término declare varias respuestas** sin tocar ninguna reclamación.
--
-- Esta migración **no modifica ni borra nada**: solo inserta. Las reclamaciones existentes se
-- quedan donde están.
--
-- Lo que se declara, y de dónde sale cada cosa:
--
-- - **Las redondillas.** `redondilla_regular` y `redondilla_cruzada` llevan su disposición escrita
--   en `patron_especifico` —«abba» y «abab»—. Son 26 secuencias anotadas que hasta hoy llegaban al
--   editor sin disposición ninguna.
-- - **Los endecasílabos sueltos.** El nombre legado *es* la respuesta: «puro» significa sin
--   pareados y sin rima; «con pareados», pareados ocasionales y rima esporádica; el sufijo
--   `_sin_distico_final` responde la pregunta del dístico, y «encadenado», la del encadenamiento.
--   *Que «puro» a secas lleve dístico final lo confirmó el IP el 24 de agosto: el hermano
--   `_puro_sin_distico_final` existe justamente para negarlo.* Son 26 secuencias más.
-- - **La silva de consonantes irregular.** Su definición legada dice que «aunque la mayoría son
--   pareados, puede dejar algunos versos sueltos sin rimar», que es exactamente la opción
--   «Mayoritaria» —«rima más de la mitad, pero no todos»—. Son 11 secuencias.
-- - **Los esdrújulos.** Seis términos llevan el sufijo `_de_esdrujulos` y son **un solo rasgo dicho
--   seis veces**; por el único de `origen_termino_id`, un valor de rasgo solo podía reclamar uno.
--   Aquí caben los cinco que tienen dónde caer. *El sexto, `endecasilabo_suelto_de_esdrujulos`, se
--   queda fuera porque el endecasílabo suelto no pregunta por el final acentual: es un hueco del
--   catálogo nuevo, no de la equivalencia, y queda anotado como pendiente.*
--
-- Todo lo que entra aquí es **propuesta derivada, no observación**: se deriva de cómo se catalogó
-- la secuencia, no de haberla mirado verso a verso. El editor la confirma o la corrige.

begin;

-- --------------------------------------------------------------------------- Las declaraciones
with entrada (termino, forma, arq, grupo, esquema, valor, nota) as (
	values
	-- Las redondillas: la disposición está en `patron_especifico`
	('redondilla_regular'::text, 'redondilla'::text, 'octosilabica'::text, 'disposicion_rima'::text,
		'abba'::text, null::text,
		'El término legado declara su disposición en el propio dato: patron_especifico = «abba».'::text),
	('redondilla_cruzada', 'redondilla', 'octosilabica', 'disposicion_rima', 'abab', null,
		'El término legado declara su disposición en el propio dato: patron_especifico = «abab».'),

	-- Los endecasílabos sueltos: el nombre es la respuesta
	('endecasilabo_suelto_puro', 'endecasilabo_suelto', 'endecasilabica',
		'organizacion_en_pareados', null, 'ninguna',
		'«Puro» es el endecasílabo suelto sin pareados de ninguna clase.'),
	('endecasilabo_suelto_puro', 'endecasilabo_suelto', 'endecasilabica',
		'densidad_de_rima', null, 'ninguna',
		'«Puro» es el endecasílabo suelto sin rima, salvo el dístico con que cierra.'),
	('endecasilabo_suelto_puro', 'endecasilabo_suelto', 'endecasilabica',
		'distico_final', null, 'presente',
		'«Puro» a secas lleva dístico final: el término hermano _sin_distico_final existe para negarlo.'),
	('endecasilabo_suelto_puro_sin_distico_final', 'endecasilabo_suelto', 'endecasilabica',
		'organizacion_en_pareados', null, 'ninguna',
		'«Puro» es el endecasílabo suelto sin pareados de ninguna clase.'),
	('endecasilabo_suelto_puro_sin_distico_final', 'endecasilabo_suelto', 'endecasilabica',
		'densidad_de_rima', null, 'ninguna',
		'«Puro» es el endecasílabo suelto sin rima, y este además no cierra con dístico.'),
	('endecasilabo_suelto_con_pareados', 'endecasilabo_suelto', 'endecasilabica',
		'organizacion_en_pareados', null, 'ocasionales',
		'El término distingue por los pareados, que aparecen sin organizar la serie.'),
	('endecasilabo_suelto_con_pareados', 'endecasilabo_suelto', 'endecasilabica',
		'densidad_de_rima', null, 'esporadica',
		'Si hay pareados, hay rima, y en un endecasílabo suelto solo puede ser esporádica: si pasara de ahí el pasaje sería una silva.'),
	('endecasilabo_suelto_con_pareados', 'endecasilabo_suelto', 'endecasilabica',
		'distico_final', null, 'presente',
		'El término no niega el dístico final, y el hermano _y_sin_distico_final existe para eso.'),
	('endecasilabo_suelto_con_pareados_y_sin_distico_final', 'endecasilabo_suelto', 'endecasilabica',
		'organizacion_en_pareados', null, 'ocasionales',
		'El término distingue por los pareados, que aparecen sin organizar la serie.'),
	('endecasilabo_suelto_con_pareados_y_sin_distico_final', 'endecasilabo_suelto', 'endecasilabica',
		'densidad_de_rima', null, 'esporadica',
		'Si hay pareados, hay rima, y en un endecasílabo suelto solo puede ser esporádica.'),
	('endecasilabo_suelto_encadenado', 'endecasilabo_suelto', 'endecasilabica',
		'encadenamiento_interior', null, 'presente',
		'Es lo único que el término declara; su densidad de rima y sus pareados quedan por decidir.'),

	-- La silva ordinaria: su definición legada dice la densidad
	('silva_de_consonantes_irregular', 'silva', 'consonante_irregular', 'densidad_de_rima', null,
		'mayoritaria',
		'La definición legada dice que «aunque la mayoría son pareados, puede dejar algunos versos sueltos sin rimar»: eso es rimar más de la mitad, pero no todos.'),

	-- Los esdrújulos: un solo rasgo dicho en cinco sitios
	('cancion_sin_rima_de_esdrujulos', 'cancion_petrarquista', 'sin_rima_con_pareado_final',
		'final_acentual_destacado', null, 'esdrujulo', 'El término nombra el final acentual.'),
	('octava_real_de_esdrujulos', 'octava_real', 'endecasilabica_consonante',
		'final_acentual_destacado', null, 'esdrujulo', 'El término nombra el final acentual.'),
	('sexteto_lira_de_esdrujulos', 'sexteto_lira', 'heterometrica_consonante',
		'final_acentual_destacado', null, 'esdrujulo', 'El término nombra el final acentual.'),
	('soneto_de_esdrújulos', 'soneto', 'endecasilabica_consonante',
		'final_acentual_destacado', null, 'esdrujulo', 'El término nombra el final acentual.'),
	('terceto_de_esdrujulos', 'terceto', 'endecasilabica_consonante',
		'final_acentual_destacado', null, 'esdrujulo', 'El término nombra el final acentual.')
),
resuelta as (
	select
		e.termino,
		v.termino_id,
		g.grupo_eleccion_id,
		er.esquema_rima_id,
		rv.valor_id,
		e.nota
	from entrada e
	join public.vocabularios v on v.termino = e.termino and v.categoria = 'estrofa_tipo'
	join public.formas_metricas f on f.slug = e.forma
	join public.arquitecturas_forma a on a.forma_id = f.forma_id and a.slug = e.arq
	join public.grupos_eleccion_metrica g
		on g.arquitectura_id = a.arquitectura_id and g.slug = e.grupo and g.activo
	left join public.esquemas_rima er
		on e.esquema is not null and er.arquitectura_id = a.arquitectura_id and er.notacion = e.esquema
	left join public.rasgos_metricos r on r.rasgo_id = g.rasgo_id
	left join public.rasgo_valores rv
		on e.valor is not null and rv.rasgo_id = r.rasgo_id and rv.slug = e.valor and rv.activo
)
insert into public.equivalencias_respuestas_legadas
	(termino_id, grupo_eleccion_id, esquema_rima_id, valor_rasgo_id, nota)
select r.termino_id, r.grupo_eleccion_id, r.esquema_rima_id, r.valor_id, r.nota
from resuelta r
where not exists (
	select 1 from public.equivalencias_respuestas_legadas x
	where x.termino_id = r.termino_id and x.grupo_eleccion_id = r.grupo_eleccion_id
);

-- ------------------------------------------------------------------------------ Comprobaciones
do $$
declare
	v_n integer;
	v_termino text;
	v_grupo text;
begin
	-- 1. Ninguna fila se ha quedado sin valor: si un `left join` falló, la fila entró vacía.
	select count(*) into v_n from public.equivalencias_respuestas_legadas
	where metro_id is null and esquema_rima_id is null and valor_rasgo_id is null
		and variedad_id is null and repeticion_id is null;
	if v_n <> 0 then
		raise exception 'Han entrado % equivalencias sin ninguna respuesta.', v_n;
	end if;

	-- 2. Las diecinueve declaraciones están puestas. Si alguna no resolvió, aquí se nota.
	select count(*) into v_n from public.equivalencias_respuestas_legadas;
	if v_n <> 26 then
		raise exception 'La tabla tiene % filas; se esperaban las 7 de antes mas las 19 nuevas.', v_n;
	end if;

	-- 3. Toda respuesta declarada corresponde a una opción que el editor ofrece de verdad.
	--    Es la comprobación que importa: una equivalencia que no case con ninguna opción no
	--    llegaría nunca al editor y se quedaría en un apunte muerto.
	select v.termino, g.slug into v_termino, v_grupo
	from public.equivalencias_respuestas_legadas e
	join public.vocabularios v on v.termino_id = e.termino_id
	join public.grupos_eleccion_metrica g on g.grupo_eleccion_id = e.grupo_eleccion_id
	where not exists (
		select 1 from public.opciones_eleccion_metrica o
		where o.grupo_eleccion_id = e.grupo_eleccion_id
			and o.metro_id is not distinct from e.metro_id
			and o.esquema_rima_id is not distinct from e.esquema_rima_id
			and o.valor_rasgo_id is not distinct from e.valor_rasgo_id
			and o.variedad_id is not distinct from e.variedad_id
			and o.repeticion_id is not distinct from e.repeticion_id
			and o.posicion_unidad is not distinct from e.posicion_unidad
	)
	limit 1;
	if v_termino is not null then
		raise exception 'La equivalencia de «%» para «%» no casa con ninguna opción del editor.',
			v_termino, v_grupo;
	end if;

	-- 4. Y las secuencias que motivaban esto ya reciben su propuesta.
	select count(distinct p.secuencia_id) into v_n
	from public.propuesta_metrica_secuencia p
	join public.vocabularios v on v.termino_id = p.estrofa_tipo_id
	join public.propuesta_elecciones_secuencia pe on pe.secuencia_id = p.secuencia_id
	where v.termino = 'endecasilabo_suelto_puro';
	if v_n = 0 then
		raise exception 'Las secuencias de endecasílabo suelto puro siguen sin propuesta.';
	end if;

	select count(distinct p.secuencia_id) into v_n
	from public.propuesta_metrica_secuencia p
	join public.vocabularios v on v.termino_id = p.estrofa_tipo_id
	join public.propuesta_elecciones_secuencia pe on pe.secuencia_id = p.secuencia_id
	where v.termino = 'silva_de_consonantes_irregular';
	if v_n = 0 then
		raise exception 'Las silvas de consonantes irregulares siguen sin propuesta.';
	end if;
end $$;

commit;

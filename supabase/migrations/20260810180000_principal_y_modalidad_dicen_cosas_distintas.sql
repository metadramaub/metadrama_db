-- `principal` y `modalidad` dicen cosas distintas, y una de las dos no lo decía.
--
-- La auditoría de la modalidad, del 10 de agosto de 2026, empezó por sospechar que las dos
-- columnas se pisaban. No se pisan: **se pisan en la palabra, no en el contenido**.
--
--   `principal`  cuál de las arquitecturas se propone por defecto. Una por forma, siempre.
--   `modalidad`  cuánto ha fijado la tradición cada una. Una escala, para todas.
--
-- Ninguna se deriva de la otra, y el romance lo demuestra: sus **cuatro** arquitecturas son
-- `preferente`, así que la modalidad no señala una sola y borrar `principal` dejaría al editor
-- sin saber cuál proponer. Al revés tampoco: `principal` es un bit por forma y no distingue
-- entre la endecha real, cuyas dos arquitecturas no principales son `excepcional`, y la
-- seguidilla, cuyas cuatro son solo `admitida`.
--
-- Lo que hacía posible la confusión es que **`modalidad` estaba declarada y `principal` no**.
-- La única de la familia con comentario era la primera —«cuánto ha fijado la tradición esta
-- realización»— y la segunda no decía nada, de modo que la palabra `preferente` acababa
-- leyéndose como el oficio de `principal`. Se declara.
--
-- El dato sí tiene problemas, y se arreglan en la clasificación por tramos que viene después:
-- la sextilla propone una `admitida` teniendo una `preferente`; el romance marca las cuatro
-- como preferentes; el sexteto y la silva no marcan ninguna. Esta migración no toca ninguna
-- fila: solo escribe lo que las columnas significan, que es la condición para poder discutir
-- si el dato está bien.

begin;

comment on column public.arquitecturas_forma.principal is
	'Cuál de las arquitecturas de la forma se propone por defecto en el editor y representa a la forma donde solo cabe una. Exactamente una por forma. No dice cuán frecuente es —eso lo dice `modalidad`—, sino cuál se ofrece primero: el romance tiene cuatro arquitecturas preferentes y solo una principal.';

comment on column public.esquemas_rima.modalidad is
	'Cuánto ha fijado la tradición esta disposición. `definitoria` cuando la arquitectura no es ella misma sin este esquema; `preferente` cuando las fuentes la dan como la normal; `admitida` cuando la documentan sin destacarla; `excepcional` cuando la documentan advirtiendo que es rara.';

comment on column public.arquitectura_rasgos.modalidad is
	'Si el rasgo define esta arquitectura o solo se admite en ella. `definitoria` cuando sin él la arquitectura sería otra; `admitida` cuando aparece y se registra sin que la caracterice.';

comment on column public.repeticiones_metricas.modalidad is
	'Cuánto ha fijado la tradición esta manera de repetir. Misma escala que en los esquemas de rima.';

comment on column public.variedades_arquitectura.preferente is
	'Si esta es la disposición que las fuentes dan como normal entre las de su arquitectura. Es el mismo papel que `modalidad = preferente` en los esquemas, en una tabla que solo necesita distinguir dos casos.';

comment on column public.denominaciones_metricas.preferente is
	'Si este es el nombre por el que el proyecto llama a lo que nombra, entre todos sus sinónimos. No tiene que ver con la frecuencia de la cosa nombrada, sino con cómo la llamamos nosotros.';

do $$
declare
	v_n integer;
begin
	-- La regla que sostiene todo lo anterior: una principal por forma, ni ninguna ni dos. Los
	-- dos tramos sin forma quedan fuera porque no tienen arquitecturas, que es justo lo que los
	-- separa de las formas.
	select count(*) into v_n
	from public.formas_metricas f
	where f.activo and f.tipo_registro = 'forma' and (
		select count(*) from public.arquitecturas_forma a
		where a.forma_id = f.forma_id and a.activo and a.principal
	) <> 1;
	if v_n <> 0 then
		raise exception '% formas no tienen exactamente una arquitectura principal', v_n;
	end if;

	-- Y que las seis columnas de la familia digan ya qué significan.
	select count(*) into v_n
	from (values
		('arquitecturas_forma', 'principal'),
		('arquitecturas_forma', 'modalidad'),
		('esquemas_rima', 'modalidad'),
		('arquitectura_rasgos', 'modalidad'),
		('repeticiones_metricas', 'modalidad'),
		('variedades_arquitectura', 'preferente'),
		('denominaciones_metricas', 'preferente')
	) as v(tabla, columna)
	where col_description(('public.' || v.tabla)::regclass, (
		select a.attnum from pg_attribute a
		where a.attrelid = ('public.' || v.tabla)::regclass and a.attname = v.columna
	)) is null;
	if v_n <> 0 then
		raise exception '% columnas de la familia siguen sin declarar qué significan', v_n;
	end if;
end;
$$;

commit;

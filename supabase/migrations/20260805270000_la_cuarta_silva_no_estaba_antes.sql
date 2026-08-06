-- La silva 4 de Morley y Bruerton tampoco estaba en el vocabulario viejo.
--
-- Al escribir la afirmación de Morley y Bruerton quedó dicho que el catálogo nuevo no recoge
-- su cuarto tipo. Cotejado después contra el vocabulario legado, la omisión resulta ser
-- **heredada**: el IP declaró cuatro silvas y ninguna es esa. En los 119 términos de
-- `estrofa_tipo` solo la familia del romance menciona los versos pares.
--
-- El cotejo, además, aclara de dónde salen las cuatro del vocabulario viejo:
--
--   Morley y Bruerton          Vocabulario del IP                  Catálogo nuevo
--   ------------------------   --------------------------------   -------------------------
--   1 · aAbBcC                 silva_de_consonantes_regular       Regular · Regulares
--   2 · 7 y 11 sin orden fijo  silva_libre                        Libre · Ninguna
--   —                          silva_de_consonantes_irregular     Orden libre · Predominantes
--   3 · solo de once           silva_de_endecasilabos             Endecasilábica
--   4 · rimas en los pares     —                                  —
--
-- Que el vocabulario viejo se hizo sobre Morley y Bruerton no es conjetura: la definición de
-- `silva_de_endecasilabos` copia su cifra literalmente, «del 50 al 98% son rimados». Y la
-- definición de `silva_libre` traduce casi palabra por palabra su tipo 2, «sin orden fijo de
-- extensión o rima, con algunos versos sin rima».
--
-- Lo que el IP añadió por su cuenta es `silva_de_consonantes_irregular`, que parte el tipo 2
-- según si los pareados predominan. El rasgo `Organización en pareados` del catálogo nuevo
-- —ninguna, ocasionales, habituales, predominantes, regulares— es la sistematización de esa
-- distinción suya: la lleva a cinco grados y la hace correr también por el endecasílabo
-- suelto y el pareado.
--
-- Se precisa la afirmación para que diga esto, que es más útil que constatar una ausencia:
-- el cuarto tipo no se perdió en la migración, nunca se declaró.

begin;

do $$
declare
	v_forma uuid;
	v_mb uuid;
	v_n integer;
begin
	select forma_id into v_forma from public.formas_metricas where slug = 'silva';
	select fuente_id into v_mb from public.fuentes_metricas where autoria like '%Morley%';

	if v_forma is null or v_mb is null then
		raise exception 'Falta la silva o la fuente de Morley y Bruerton';
	end if;

	update public.afirmaciones_fuentes_metricas
	set resumen = 'Distinguen cuatro tipos: la silva de consonantes aAbBcC; los versos de siete y once mezclados irregularmente, sin orden fijo de extensión ni de rima y con algunos sin rimar; los de once sílabas solos, del 50 al 98 % rimados y en su mayor parte dísticos, con algún ABAB y ABBA; y un cuarto tipo de siete y once mezclados con **todas las rimas en los pares**. Los tres primeros son el origen declarado de las realizaciones del catálogo —el vocabulario del proyecto llegó a copiar su cifra del 50 al 98 %—; el cuarto no se ha declarado nunca, ni aquí ni antes, y no aparece en el corpus.'
	where fuente_id = v_mb and forma_id = v_forma;
	get diagnostics v_n = row_count;

	if v_n <> 1 then
		raise exception 'Se esperaba una afirmación de Morley y Bruerton sobre la silva y hay %', v_n;
	end if;

	raise notice 'Silva · precisada la afirmación de Morley y Bruerton sobre su cuarto tipo';
end $$;

update public.catalogo_metrico_estado
set revision = revision + 1, actualizado_en = now()
where id;

commit;

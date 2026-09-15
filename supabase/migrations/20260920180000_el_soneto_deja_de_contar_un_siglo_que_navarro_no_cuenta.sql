-- El soneto deja de contar un siglo que Navarro no cuenta, y recobra a Petrarca
--
-- **La única afirmación que la hoja mandaba al IP, y no era para el IP.** Estaba en el cubo
-- «filológico» porque la ficha decía que los sonetos de Santillana eran «anteriores en un siglo» al
-- éxito de la forma y el § 107 no da ninguna cifra. Al abrirlo resultó que el problema no era una
-- convención sin fijar sino tres cosas comprobables, ninguna de las cuales necesita una decisión
-- filológica.
--
-- ══ Lo que dice Navarro Tomás, § 107, p. 205
--
--   «Los sonetos que el Marqués de Santillana compuso a mediados del siglo XV no habían tenido
--   divulgación. Tal precedente era ignorado en la época de Boscán y Garcilaso, efectivos
--   introductores de esta forma métrica en la poesía española. Su modelo directo fueron los sonetos
--   del Petrarca, que también Santillana había tenido presentes. […] Desde Boscán y Garcilaso hasta
--   el modernismo el orden de las rimas de los cuartetos ha sido uniformemente con raras excepciones
--   ABBA:ABBA.»
--
-- ══ Y lo que decía la ficha
--
--   1. «**anterior en un siglo**». El número no está en la fuente **y no cuadra**: el propio libro
--      fecha en la p. 204 la conversación de Boscán con Navagiero en 1526, y de mediados del XV a
--      1526 van unos setenta y cinco años.
--   2. «Que ese intento no tuviera continuidad **es lo que hace** de Boscán y Garcilaso los
--      introductores efectivos». La relación de causa es nuestra: Navarro dice que el precedente fue
--      ignorado y que ellos son los introductores efectivos, y no une las dos cosas. Misma familia
--      que las nueve glosas de `20260920100000`.
--   3. **Se había caído Petrarca**, que está en la frase siguiente y es lo más sustantivo del pasaje.
--
-- ══ Y entra la cautela de los cuartetos
--
-- «Uniformemente con raras excepciones» es **el único sitio donde Navarro fija el orden de rimas de
-- los cuartetos**, y con su reserva puesta. El catálogo no lo recogía de él.
--
-- Encaja además exactamente con lo que la arquitectura ya declara: `ABBA ABBA` como **habitual** y
-- `ABAB ABAB` como **excepcional**. Las combinaciones de tercetos que el mismo § enumera son otra
-- cosa y no entran aquí: van con el montón de esquemas por registrar.
--
-- Texto aprobado por David el 20 de septiembre de 2026.

begin;

do $$
declare
	v_antes_resumen constant text :=
		'Estudia los sonetos del Marqués de Santillana como primer intento de aclimatación, '
		'anterior en un siglo al éxito de la forma. Que ese intento no tuviera continuidad es lo '
		'que hace de Boscán y Garcilaso los introductores efectivos.';
	v_despues_resumen constant text :=
		'Sitúa los sonetos que el Marqués de Santillana compuso «a mediados del siglo XV» como un '
		'precedente que «no había tenido divulgación» y que «era ignorado en la época de Boscán y '
		'Garcilaso, **efectivos introductores** de esta forma métrica en la poesía española». Añade '
		'que el modelo directo de estos fueron los sonetos de Petrarca, **que también Santillana '
		'había tenido presentes**, y que desde Boscán y Garcilaso hasta el modernismo el orden de '
		'las rimas de los cuartetos ha sido «uniformemente con raras excepciones» ABBA:ABBA.';
	v_antes_loc constant text := '§ 107';
	v_despues_loc constant text := '§ 107, p. 205';
	v_n integer;
	v_antes bigint;
	v_despues bigint;
begin
	-- Que la afirmación tiene hoy, palabra por palabra, el texto y el localizador de antes.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = '022cea3a'
		and resumen = v_antes_resumen and localizador = v_antes_loc;
	if v_n <> 1 then
		raise exception 'La afirmación del soneto no tiene hoy el texto que esta migración espera; no la toco.';
	end if;

	select revision into v_antes from public.catalogo_metrico_estado where id;

	update public.afirmaciones_fuentes_metricas
	set resumen = v_despues_resumen, localizador = v_despues_loc
	where left(afirmacion_id::text, 8) = '022cea3a';

	-- ══════════════════════════════════════════════════════════ Comprobaciones
	--
	-- Que quedó con las dos cosas nuevas, releídas de la tabla.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas
	where left(afirmacion_id::text, 8) = '022cea3a'
		and resumen = v_despues_resumen and localizador = v_despues_loc;
	if v_n <> 1 then
		raise exception 'La afirmación del soneto no quedó con el texto nuevo.';
	end if;

	-- Que el siglo inventado no queda en ninguna ficha del catálogo.
	select count(*) into v_n
	from public.afirmaciones_fuentes_metricas where resumen like '%anterior en un siglo%';
	if v_n <> 0 then
		raise exception '% fichas siguen diciendo «anterior en un siglo».', v_n;
	end if;

	-- Y que la cautela que entra es la que la arquitectura ya declaraba: ABBA ABBA habitual y
	-- ABAB ABAB excepcional. Si alguien cambiara eso, esta afirmación dejaría de sostenerlo.
	select count(*) into v_n
	from public.formas_metricas f
	join public.arquitecturas_forma ar on ar.forma_id = f.forma_id
	join public.esquemas_rima e on e.arquitectura_id = ar.arquitectura_id
	where f.slug = 'soneto'
		and ((e.notacion = 'ABBA ABBA' and e.modalidad = 'habitual')
			or (e.notacion = 'ABAB ABAB' and e.modalidad = 'excepcional'));
	if v_n <> 2 then
		raise exception 'Los cuartetos del soneto ya no son ABBA habitual y ABAB excepcional: son % esquemas.', v_n;
	end if;

	select revision into v_despues from public.catalogo_metrico_estado where id;
	if v_despues <= v_antes then
		raise exception 'La revisión del catálogo no subió: % y seguía en %.', v_despues, v_antes;
	end if;
end $$;

commit;

-- El nombre de la arquitectura se lee pegado al de su forma
--
-- El nombre de una arquitectura no aparece nunca solo: la ficha, el catálogo y el editor lo pintan
-- junto al de su forma —«Soneto · Endecasilábica»—, y estaba escrito para concordar con la palabra
-- «arquitectura», que no sale en ninguna pantalla. De ahí salían dos problemas a la vez, y esta
-- migración corrige los dos en las **58 arquitecturas** afectadas de las 95 activas:
--
-- 1. **La denominación tradicional.** La métrica española dice «romance octosílabo» y «redondilla
--    octosílaba», no «octosilábico». Todas las medidas pasan a `-sílabo`/`-sílaba`.
-- 2. **La concordancia.** Con la forma, que es lo que se lee al lado: masculino en cuarteto,
--    sexteto, septeto, terceto, soneto, romance y endecasílabo suelto; femenino en las demás.
--    Alcanza también a `Heterométrica consonante` bajo las tres liras masculinas, a
--    `Alejandrina` del sexteto y a `Compuesta` del septeto.
--
-- Lo que no se toca y no es descuido:
--
-- - **Los slugs.** Viajan en `obras_resumen.perfil_formas_hijos`, en el JSON de la ficha y en las
--   URLs del catálogo público, así que renombrarlos es otra tarea, con su recompute y su repaso de
--   enlaces. Queda pendiente, no descartado. Ese día habrá que resolver además dos desajustes que
--   esta migración deja a la vista: `terceto/endecasilabica_consonante` se llamará «Endecasílabo»,
--   y los slugs seguirán diciendo `octosilabica` mientras el nombre dice «Octosílabo».
-- - **`endecasilabo_suelto/endecasilabica`**, que solo concuerda. La tautología «Endecasílabo
--   suelto · Endecasílabo» es real, pero «Sin rima» sería falso: un pasaje de sueltos admite rimas
--   esporádicas y puede organizarse en pareados. Cómo se nombra la única arquitectura de una forma
--   que ya lo dice todo se decide otro día.
-- - **Las dos sextinas.** `sextina` y `sextina_estrofa` son dos formas distintas —composición fija
--   y estrofa—, y por eso hay dos arquitecturas `principal` con el mismo nombre de forma.
--
-- Nada de esto es estructura: solo cambia `arquitecturas_forma.nombre`. Después hay que
-- **recomputar los datos públicos**, porque el nombre viaja dentro de `obras_resumen.ficha`.

update public.arquitecturas_forma a
set nombre = nuevo.nombre,
    updated_at = now()
from (
  values
    ('copla_castellana',   'octosilabica',                            'Octosílaba'),
    ('copla_de_arte_mayor','dodecasilabica_compuesta',                'Dodecasílaba compuesta'),
    ('copla_de_arte_menor','octosilabica',                            'Octosílaba'),
    ('copla_real',         'octosilabica_consonante',                 'Octosílaba consonante'),
    ('cuarteto',           'endecasilabica',                          'Endecasílabo'),
    ('cuarteto_lira',      'heterometrica_consonante',                'Heterométrico consonante'),
    ('decima',             'endecasilabica',                          'Endecasílaba'),
    ('decima',             'heptasilabica',                           'Heptasílaba'),
    ('decima',             'hexasilabica',                            'Hexasílaba'),
    ('decima',             'pentasilabica',                           'Pentasílaba'),
    ('endecasilabo_suelto','endecasilabica',                          'Endecasílabo'),
    ('endecha_real',       'heptasilabica_con_endecasilabo',          'Heptasílaba con endecasílabo final'),
    ('endecha_real',       'heptasilabica_con_endecasilabo_de_cinco', 'Heptasílaba de cinco versos'),
    ('endecha_real',       'hexasilabica_con_endecasilabo',           'Hexasílaba con endecasílabo final'),
    ('lira',               'heptasilabica_endecasilabica',            'Heptasílaba y endecasílaba'),
    ('octava_aguda',       'endecasilabica',                          'Endecasílaba'),
    ('octava_aguda',       'decasilabica',                            'Decasílaba'),
    ('octava_aguda',       'octosilabica',                            'Octosílaba'),
    ('octava_aguda',       'heptasilabica',                           'Heptasílaba'),
    ('octava_aguda',       'hexasilabica',                            'Hexasílaba'),
    ('octava_aguda',       'pentasilabica',                           'Pentasílaba'),
    ('octava_real',        'endecasilabica_consonante',               'Endecasílaba consonante'),
    ('quintilla',          'heptasilabica',                           'Heptasílaba'),
    ('quintilla',          'hexasilabica',                            'Hexasílaba'),
    ('quintilla',          'octosilabica_consonante',                 'Octosílaba consonante'),
    ('redondilla',         'octosilabica',                            'Octosílaba'),
    ('redondilla',         'heptasilabica',                           'Heptasílaba'),
    ('redondilla',         'hexasilabica',                            'Hexasílaba'),
    ('redondilla_enlazada','octosilabica_con_quebrado',               'Octosílaba con quebrado'),
    ('romance',            'octosilabica',                            'Octosílabo'),
    ('romance',            'hexasilabica',                            'Hexasílabo'),
    ('romance',            'heptasilabica',                           'Heptasílabo'),
    ('romance',            'endecasilabica',                          'Endecasílabo'),
    ('romance',            'pentasilabica',                           'Pentasílabo'),
    ('romance',            'tetrasilabica',                           'Tetrasílabo'),
    ('septeto',            'endecasilabica',                          'Endecasílabo'),
    ('septeto',            'compuesta',                               'Compuesto'),
    ('septeto_lira',       'heterometrica_consonante',                'Heterométrico consonante'),
    ('septilla',           'octosilabica',                            'Octosílaba'),
    ('septilla_enlazada',  'octosilabica_con_quebrado',               'Octosílaba con quebrado'),
    ('sexteto',            'alejandrina',                             'Alejandrino'),
    ('sexteto',            'dodecasilabica',                          'Dodecasílabo'),
    ('sexteto',            'endecasilabica',                          'Endecasílabo'),
    ('sexteto_lira',       'heterometrica_consonante',                'Heterométrico consonante'),
    ('sextilla',           'octosilabica',                            'Octosílaba'),
    ('sextilla',           'pentasilabica',                           'Pentasílaba'),
    ('sextilla',           'tetrasilabica',                           'Tetrasílaba'),
    ('sextilla',           'heptasilabica',                           'Heptasílaba'),
    ('sextilla',           'hexasilabica',                            'Hexasílaba'),
    ('sextilla_enlazada',  'octosilabica_con_quebrado',               'Octosílaba con quebrado'),
    ('sextina_estrofa',    'endecasilabica_sin_rima',                 'Endecasílaba sin rima'),
    ('silva',              'endecasilabica',                          'Endecasílaba'),
    ('soneto',             'endecasilabica_consonante',               'Endecasílabo consonante'),
    ('terceto',            'octosilabica',                            'Octosílabo'),
    ('terceto',            'hexasilabica',                            'Hexasílabo'),
    ('terceto',            'endecasilabica_consonante',               'Endecasílabo'),
    ('terceto_encadenado', 'endecasilabica_consonante',               'Endecasílabo consonante'),
    ('terceto_encadenado', 'octosilabica_consonante',                 'Octosílabo consonante')
) as nuevo(forma_slug, arquitectura_slug, nombre)
join public.formas_metricas f on f.slug = nuevo.forma_slug
where a.forma_id = f.forma_id
  and a.slug = nuevo.arquitectura_slug
  and a.nombre is distinct from nuevo.nombre;

-- ---------------------------------------------------------------------------
-- La guarda mira el estado final, no el número de filas cambiadas
--
-- Reaplicarla no cambia ninguna fila —el `is distinct from` la hace idempotente—, así que contar
-- actualizaciones diría «cero» tanto si funcionó como si el par (forma, arquitectura) no existe. Lo
-- que se comprueba es que las 58 se llamen hoy como deben.
-- ---------------------------------------------------------------------------
do $guarda$
declare
  v_faltan text;
begin
  select string_agg(format('%s/%s', esperado.forma_slug, esperado.arquitectura_slug), ', ')
  into v_faltan
  from (
    values
      ('copla_castellana',   'octosilabica',                            'Octosílaba'),
      ('copla_de_arte_mayor','dodecasilabica_compuesta',                'Dodecasílaba compuesta'),
      ('copla_de_arte_menor','octosilabica',                            'Octosílaba'),
      ('copla_real',         'octosilabica_consonante',                 'Octosílaba consonante'),
      ('cuarteto',           'endecasilabica',                          'Endecasílabo'),
      ('cuarteto_lira',      'heterometrica_consonante',                'Heterométrico consonante'),
      ('decima',             'endecasilabica',                          'Endecasílaba'),
      ('decima',             'heptasilabica',                           'Heptasílaba'),
      ('decima',             'hexasilabica',                            'Hexasílaba'),
      ('decima',             'pentasilabica',                           'Pentasílaba'),
      ('endecasilabo_suelto','endecasilabica',                          'Endecasílabo'),
      ('endecha_real',       'heptasilabica_con_endecasilabo',          'Heptasílaba con endecasílabo final'),
      ('endecha_real',       'heptasilabica_con_endecasilabo_de_cinco', 'Heptasílaba de cinco versos'),
      ('endecha_real',       'hexasilabica_con_endecasilabo',           'Hexasílaba con endecasílabo final'),
      ('lira',               'heptasilabica_endecasilabica',            'Heptasílaba y endecasílaba'),
      ('octava_aguda',       'endecasilabica',                          'Endecasílaba'),
      ('octava_aguda',       'decasilabica',                            'Decasílaba'),
      ('octava_aguda',       'octosilabica',                            'Octosílaba'),
      ('octava_aguda',       'heptasilabica',                           'Heptasílaba'),
      ('octava_aguda',       'hexasilabica',                            'Hexasílaba'),
      ('octava_aguda',       'pentasilabica',                           'Pentasílaba'),
      ('octava_real',        'endecasilabica_consonante',               'Endecasílaba consonante'),
      ('quintilla',          'heptasilabica',                           'Heptasílaba'),
      ('quintilla',          'hexasilabica',                            'Hexasílaba'),
      ('quintilla',          'octosilabica_consonante',                 'Octosílaba consonante'),
      ('redondilla',         'octosilabica',                            'Octosílaba'),
      ('redondilla',         'heptasilabica',                           'Heptasílaba'),
      ('redondilla',         'hexasilabica',                            'Hexasílaba'),
      ('redondilla_enlazada','octosilabica_con_quebrado',               'Octosílaba con quebrado'),
      ('romance',            'octosilabica',                            'Octosílabo'),
      ('romance',            'hexasilabica',                            'Hexasílabo'),
      ('romance',            'heptasilabica',                           'Heptasílabo'),
      ('romance',            'endecasilabica',                          'Endecasílabo'),
      ('romance',            'pentasilabica',                           'Pentasílabo'),
      ('romance',            'tetrasilabica',                           'Tetrasílabo'),
      ('septeto',            'endecasilabica',                          'Endecasílabo'),
      ('septeto',            'compuesta',                               'Compuesto'),
      ('septeto_lira',       'heterometrica_consonante',                'Heterométrico consonante'),
      ('septilla',           'octosilabica',                            'Octosílaba'),
      ('septilla_enlazada',  'octosilabica_con_quebrado',               'Octosílaba con quebrado'),
      ('sexteto',            'alejandrina',                             'Alejandrino'),
      ('sexteto',            'dodecasilabica',                          'Dodecasílabo'),
      ('sexteto',            'endecasilabica',                          'Endecasílabo'),
      ('sexteto_lira',       'heterometrica_consonante',                'Heterométrico consonante'),
      ('sextilla',           'octosilabica',                            'Octosílaba'),
      ('sextilla',           'pentasilabica',                           'Pentasílaba'),
      ('sextilla',           'tetrasilabica',                           'Tetrasílaba'),
      ('sextilla',           'heptasilabica',                           'Heptasílaba'),
      ('sextilla',           'hexasilabica',                            'Hexasílaba'),
      ('sextilla_enlazada',  'octosilabica_con_quebrado',               'Octosílaba con quebrado'),
      ('sextina_estrofa',    'endecasilabica_sin_rima',                 'Endecasílaba sin rima'),
      ('silva',              'endecasilabica',                          'Endecasílaba'),
      ('soneto',             'endecasilabica_consonante',               'Endecasílabo consonante'),
      ('terceto',            'octosilabica',                            'Octosílabo'),
      ('terceto',            'hexasilabica',                            'Hexasílabo'),
      ('terceto',            'endecasilabica_consonante',               'Endecasílabo'),
      ('terceto_encadenado', 'endecasilabica_consonante',               'Endecasílabo consonante'),
      ('terceto_encadenado', 'octosilabica_consonante',                 'Octosílabo consonante')
  ) as esperado(forma_slug, arquitectura_slug, nombre)
  where not exists (
    select 1
    from public.arquitecturas_forma a
    join public.formas_metricas f on f.forma_id = a.forma_id
    where f.slug = esperado.forma_slug
      and a.slug = esperado.arquitectura_slug
      and a.nombre = esperado.nombre
  );

  if v_faltan is not null then
    raise exception 'Estas arquitecturas no se llaman como deben tras la migración: %', v_faltan;
  end if;
end;
$guarda$;

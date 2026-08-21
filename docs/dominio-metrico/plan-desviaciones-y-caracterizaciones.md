# Plan · desviaciones, caracterizaciones y rasgos

Estado: decidido, no ejecutado · 3 de agosto de 2026

Este documento cierra el vocabulario de las desviaciones y reparte lo que hoy se registra
como «caracterización por rango» entre sus tres destinos reales. Es una pieza concreta
dentro del [plan de migración de las anotaciones](./plan-migracion-anotaciones.md), que
sigue siendo el marco general; aquí no se repite nada de lo que aquel ya establece sobre
copias de seguridad, trazabilidad y condiciones previas.

Todas las cifras proceden de un volcado de la base enlazada del 3 de agosto de 2026.

## 1 · Por qué

El vocabulario de desviaciones tiene seis dimensiones y diez relaciones, y varias dicen lo
mismo: `omision` duplica `falta_elemento_esperado`, `adicion` duplica
`aparece_elemento_no_esperado`, y `sustitucion` y `ruptura` son `diferente` con y sin valor
observado. La dimensión `combinacion` es además la única sin columna donde nombrar lo
observado.

Y en paralelo, el mecanismo de caracterización por rango se estaba usando para otra cosa:
**203 de sus 231 filas son desviaciones**, y todas marcan uno, dos o tres versos dentro de
secuencias de sesenta a doscientos cincuenta. No había otro sitio donde ponerlas.

## 2 · El modelo

### Una desviación

| Campo | Qué es |
| --- | --- |
| `secuencia_id` · `realizacion_id` | A qué secuencia pertenece y, si procede, en qué unidad o sección cae |
| `v_ini` · `v_fin` | **Obligatorio.** Una desviación siempre está localizada |
| `dimension` | `metro` · `rima` · `estructura` · `repeticion` · `rasgo` |
| `relacion` | `diferente` · `falta` · `sobra` · `menor_que_norma` · `mayor_que_norma` · `otra` |
| observado | Una columna por dimensión, apuntando al vocabulario normalizado |
| `observaciones` | La descripción mínima; es donde vive hoy el texto del verso |

### La regla que evita dos formas de decir lo mismo

**La relación lleva siempre el hecho. El valor observado es precisión añadida, no una vía
alternativa.** Contar versos hipométricos es siempre una sola pregunta —
`relacion = menor_que_norma`— tanto si la fila conoce su medida exacta como si no.

### Qué relación admite cada dimensión

| Dimensión | Relaciones | Por qué |
| --- | --- | --- |
| `metro` | menor · mayor · otra | Una medida solo puede sobrar o faltar |
| `rima` | diferente · otra | Un esquema es otro; no tiene tamaño |
| `estructura` | falta · sobra · menor · mayor · diferente · otra | Falta una sección, o la que hay es más corta |
| `repeticion` | falta · sobra · menor · mayor · diferente · otra | Igual |
| `rasgo` | falta · sobra · diferente · otra | Un rasgo está, no está, o es otro valor |

### Tres invariantes que hoy no existen

1. La columna de observado corresponde a la dimensión. Hoy nada impide una desviación con
   `dimension = metro` y `seccion_observada_id` puesto.
2. Si hay valor observado, concuerda con la relación. Un `menor_que_norma` con un
   eneasílabo donde la norma es octosílaba es una incoherencia.
3. `falta` nunca lleva valor observado: no había nada que observar.

### Derivado, nunca guardado

La hipometría y la hipermetría. Con metro observado, comparándolo con la norma; sin él,
leyendo la relación. La pantalla lo dice —«heptasílabo · una sílaba menos que la norma»—;
la tabla no lo almacena.

## 3 · Las decisiones

1. **Fenómenos enunciativos se quedan.** `cantado` y `prosa` son caracterizaciones reales y
   no métricas. Siguen en `secuencias_caracterizaciones_rango`, con su rango, que es la
   granularidad con la que se usan.
2. **Las irregularidades métricas se migran a desviaciones**: `hipometrico`,
   `hipermetrico`, `rima_defectuosa` y `laguna`.
3. **`final_acentual` se migra a rasgo.** Ya existe en el catálogo como rasgo transversal.
4. **Se retira la dimensión `combinacion`.**
5. **Las relaciones quedan en seis**, con la regla del punto 2 y las tres invariantes.
6. **Se guarda la realidad y se muestra el diagnóstico**: la desviación registra el metro
   observado cuando se conoce, y el sentido se enseña calculado.
7. **Las desviaciones llevan rango de versos siempre.**
8. **Una secuencia con forma no tiene observación libre.** Lo que el editor quiera anotar va
   a `comentarios_internos`, que ya se ancla a la secuencia, se tipifica y puede hacerse
   público. Se conservan la observación del tramo sin forma y la descripción de cada
   desviación.
9. **`final_acentual` se pregunta por unidad en las formas estróficas y por secuencia en las
   series**, que no materializan unidades. El catálogo declara el alcance por arquitectura,
   así que es configuración y no cambio de modelo.
10. **`patron_alternativo` desaparece sin sustituto.** No era una categoría: era la falta de
    sitio para decir algo del comportamiento de la rima dentro de un romance.
11. **Un romance que empieza a rimar en el primer verso es desviación, no elección.**
12. **La articulación interna se anota en el esquema de rima con dos puntos**, como en la
    notación que el catálogo ya usa para la canción petrarquista.
13. **Las filas sin observación no se adivinan.** Saltarán durante la migración y se
    resuelven con su autora.
14. **Se añade el valor `agudo` al rasgo `final_acentual`**, que hoy solo tiene `esdrujulo`.
    El rasgo significa predominancia: se marca cuando predomina lo raro y nunca se marca lo
    llano, que es el caso por defecto del español.
15. **La modalidad no interviene.** Dice cómo se relaciona un rasgo con la norma de una
    forma —el soneto «admite» finales esdrújulos—, no cuánto aparece en un pasaje.
16. **Se cataloga el ciclo de rima desfasado del romance** (`a + suelto`), para que las
    desviaciones de las decisiones 10 y 11 puedan nombrar lo observado en vez de
    describirlo en prosa. Escribir el esquema verso a verso no vale: son secuencias de 227 y
    294 versos.

## 4 · El uso real

91 obras · 260 secuencias · 231 caracterizaciones por rango.

| Término | Filas | Tramos internos | Obras | Destino |
| --- | ---: | ---: | ---: | --- |
| hipermetrico | 129 | 129 | 3 | `metro` · `mayor_que_norma` |
| hipometrico | 56 | 56 | 4 | `metro` · `menor_que_norma` |
| rima_defectuosa | 16 | 16 | 3 | `rima` · `diferente` |
| cantado | 12 | 9 | 5 | Se queda |
| patron_alternativo | 8 | 8 | 2 | Caso por caso, §5 |
| prosa | 5 | 5 | 1 | Se queda |
| mayoria_agudas | 2 | 1 | 2 | Rasgo `final_acentual` = `agudo` |
| laguna | 2 | 2 | 2 | `estructura` · `falta` |
| mayoria_esdrujulas | 1 | 1 | 1 | Rasgo `final_acentual` = `esdrujulo` |

Además, 379 filas en `secuencias_subtipos_estrofa`, **todas esquemas de quintilla**
(`quintilla_1_ababa` 266, `quintilla_5_aabba` 79 y cinco más). Traducción sin decisiones:
una elección de `esquema_rima` sobre la arquitectura de la quintilla.

`final_acentual` son **tres filas en todo el corpus**, y las dos que marcan tramo interno
están en una obra de pruebas. No se construye un mecanismo de rangos para los rasgos.

### Concentración

| Obra | Editor asignado | Filas afectadas |
| --- | --- | ---: |
| Valor, agravio y mujer | María Isabel Cuena | 159 |
| El caballero de Olmedo | María Isabel Cuena | 42 |
| El amor al uso | Ana Vicente | 6 |
| Dido y Eneas | Gaston Gilabert | 3 |
| El mágico prodigioso | Emma González Mesas | 1 |

**201 de 211 filas, el 95 %, son de una sola persona.** En hipo e hipermetría, 180 de 185.

## 5 · Los ocho `patron_alternativo`

| Obra | Forma | Qué señaló | Destino |
| --- | --- | --- | --- |
| Olmedo | romance e-o | Riman el 3.º y el 5.º, impares | `rima` · `sobra` |
| Olmedo | romance a-a | Riman el 1.º y el 3.º | `rima` · `sobra` |
| Valor… | romance a | La rima empieza en impar | `rima` · `diferente`, ciclo desfasado |
| Valor… | romance e-a | La rima se salta un verso y se retoma | `rima` · `diferente` |
| Valor… | romance a-e | Pasa de impares a pares a mitad | `rima` · `diferente` |
| Olmedo | décima espinela | Pausa sintáctica antes de los 3 últimos | `estructura` · `diferente`, con el esquema observado |
| Valor… | décima espinela | Sin observación | Decisión 13 |
| Olmedo | terceto encadenado | Sin observación | Decisión 13 |

## 6 · El trabajo

### Bloque A · Ahora, sin datos de por medio

`desviaciones_editor_metrico` **está vacía**: cero filas. Cambiar su vocabulario no migra
nada. Y conviene hacerlo ya, porque el laboratorio existe para que los editores prueben lo
que se va a quedar.

1. Migración sobre `desviaciones_editor_metrico`: quitar `combinacion` de la restricción de
   `dimension`; sustituir la de `relacion_norma` por los seis valores, renombrando
   `falta_elemento_esperado` a `falta` y `aparece_elemento_no_esperado` a `sobra`; añadir
   las tres invariantes como `check`.
2. Ampliar el validador del esquema observado para admitir los dos puntos. Hoy es
   `^[A-Z-]+$` y los rechaza. Afecta solo a `elecciones.valor_texto`: los esquemas
   catalogados ya los admiten —existe uno guardado como `abcabc:defdef`—.
3. Corregir la notación de los esquemas que llevan los dos puntos en su descripción pero no
   en su notación. El de la canción regular guarda `ABCABCCDEEDFF` y pasa a
   `ABCABC:CDEEDFF`, que marca la frontera entre fronte y sirima, hoy solo escrita en una
   nota en prosa. Las minúsculas de la notación histórica `abCabC:cdeeDfF` no vuelven: no
   son clases de rima sino medida, y ya viven en el patrón métrico.
4. Añadir el valor `agudo` al rasgo `final_acentual`.
5. En la aplicación: el mapa de relaciones de `sequence-draft.ts`, el formulario de
   desviaciones, el diagnóstico derivado en pantalla y los tests.

### Bloque B · Cuando exista la capa de desviaciones sobre secuencias reales

Es el paso 5 de la ruta de [CONTEXTO-PARA-CONTINUAR](./CONTEXTO-PARA-CONTINUAR.md). Las
desviaciones viven hoy en tablas `*_editor_metrico` que no tocan las secuencias reales.

6. Catalogar el ciclo de rima desfasado del romance (decisión 16), antes de migrar.
7. Migrar las 203 irregularidades. Es **automática y sin pérdida**: el rango ya está, el
   sentido lo da el término y el texto del verso pasa a `observaciones` tal cual.
8. Migrar las 3 filas de `final_acentual` al rasgo.
9. Migrar los 8 `patron_alternativo` según §5, con las dos filas sin observación marcadas
   para revisión.
10. Retirar `irregularidades_metricas`, `final_acentual` y `patron_alternativo` del
    vocabulario `caracterizacion_rango`, que queda solo con `fenomenos_enunciativos`.

La capa precomputada no condiciona nada: se rehará entera cuando el modelo esté cerrado.
Conviene recordar entonces que `obras_resumen.variaciones_presentes` alimentaba un filtro
del catálogo público y que `pct_cantado` depende de `cantado`, que se queda.

### Bloque C · Con las editoras

11. **Las 180 medidas exactas**, opcional y aditivo. La migración deja «un verso más corto
    de lo que pide la norma»; afinar a «heptasílabo» exige contar sílabas, y no debe
    deducirse por regla: convertir «hipométrico» en «heptasílabo» automáticamente
    escribiría en la base una medida que nadie ha contado. Como el texto del verso viaja en
    las observaciones, es completar un campo en filas que ya existen, no volver a anotar. Se
    hace después del bloque B, con el editor nuevo delante, y puede repartirse por obras.
12. **Las dos filas sin observación**, de la misma persona.
13. **La pausa sintáctica de la espinela** roza el límite de lo que el proyecto declara
    fuera de su alcance, como el ritmo acentual. Merece una línea en
    [cuestiones para el IP](./historico/cuestiones-por-forma-2026-08.md).

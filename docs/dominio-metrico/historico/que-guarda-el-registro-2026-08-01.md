# Qué guarda el registro

> **Archivado el 21 de agosto de 2026.** Tres secuencias inventadas, fila a fila, para ver qué
> escribía cada tabla. **Sus nombres de tabla ya no existen**: lo que aquí se llama
> `realizaciones_metricas`, `elecciones_metricas`, `desviaciones_metricas` y `realizacion_resuelta`
> son hoy las tablas `*_editor_metrico`, y una de sus tres formas de ejemplo —la copla de pie
> quebrado— se retiró del catálogo el 20 de agosto de 2026.
>
> Se conserva por el método —qué capa escribe qué, y cómo eso alimenta después las fichas—, no por
> sus nombres. Lo vigente: [el modelo aplicado](../implementacion-metrica.md).

Estado: **propuesta** · 1 de agosto de 2026

Tres secuencias inventadas, fila a fila, para ver qué escribe cada tabla y cómo eso alimenta
después las fichas y los análisis. Los identificadores reales son UUID; aquí se usan slugs
para poder leerlos.

## Las capas

```
lo que el editor afirma          lo que de ahí se deriva
─────────────────────────       ─────────────────────────
secuencias_metricas             realizacion_resuelta
  realizaciones_metricas          (regenerable, con modelo_version)
    elecciones_metricas
    desviaciones_metricas
```

La primera columna no se toca nunca: es la decisión editorial. La segunda se puede borrar y
reconstruir entera sin rozar una fila de la primera, y por eso vive aparte.

---

## Ejemplo 1 · Una tirada de doce redondillas

Versos 401–448 de una comedia. Todas abrazadas salvo la séptima, que es cruzada, y con un
verso hipométrico en la 401.

### secuencias_metricas

| secuencia_id | obra_id | v_ini | v_fin | n_versos | forma | arquitectura |
| --- | --- | ---: | ---: | ---: | --- | --- |
| `SEC-1` | `OBRA-A` | 401 | 448 | 48 | `redondilla` | `octosilabica` |

Una sola fila. La secuencia es «cada vez que cambia la forma», así que si en el verso 449
empieza un romance, esa es otra secuencia.

### realizaciones_metricas

Doce filas, una por unidad. **No las escribe el editor: las deriva el rango**, porque la
arquitectura declara que su unidad tiene cuatro versos.

| realizacion_id | secuencia | padre | seccion | orden | v_ini | v_fin |
| --- | --- | --- | --- | ---: | ---: | ---: |
| `R-1` | `SEC-1` | — | — | 1 | 401 | 404 |
| `R-2` | `SEC-1` | — | — | 2 | 405 | 408 |
| … | | | | | | |
| `R-12` | `SEC-1` | — | — | 12 | 445 | 448 |

`seccion` va en nulo porque la redondilla no tiene secciones: su unidad es la estrofa entera.
Esa es la definición operativa de unidad — la realización que no cuelga de ninguna otra y no
realiza ninguna sección.

### elecciones_metricas

| realizacion | grupo | opcion |
| --- | --- | --- |
| `R-1` | `disposicion_rima` | `abrazada` |
| `R-2` | `disposicion_rima` | `abrazada` |
| … | | |
| `R-7` | `disposicion_rima` | **`cruzada`** |
| … | | |
| `R-12` | `disposicion_rima` | `abrazada` |

Doce filas, **un clic**: el editor responde en la primera y aplica a toda la tirada, y luego
cambia solo la séptima. La medida no aparece porque no se pregunta: la arquitectura es la
octosilábica y eso ya lo dice.

### desviaciones_metricas

| realizacion | v_ini | v_fin | dimension | relacion_norma | metro_observado |
| --- | ---: | ---: | --- | --- | --- |
| `R-1` | 401 | 401 | `metro` | `menor_que_norma` | `heptasilabo` |

Un verso de siete donde la norma espera ocho. **La hipometría no se nombra**: se deriva de
comparar lo observado con lo que la arquitectura fija.

### realizacion_resuelta

| realizacion | obra | v_ini | v_fin | nivel | forma | arquitectura | seccion | metro | esquema_rima | notacion | procedencia |
| --- | --- | ---: | ---: | --- | --- | --- | --- | --- | --- | --- | --- |
| `R-1` | `OBRA-A` | 401 | 404 | unidad | redondilla | octosilabica | — | `8` | `abba` | `abba` | metro: norma+desviación · rima: elección |
| `R-2` | `OBRA-A` | 405 | 408 | unidad | redondilla | octosilabica | — | `8` | `abba` | `abba` | metro: norma · rima: elección |
| `R-7` | `OBRA-A` | 425 | 428 | unidad | redondilla | octosilabica | — | `8` | `abab` | `abab` | metro: norma · rima: elección |

Aquí está el punto: **`8` y `abba` no estaban escritos en ninguna de las tablas editoriales**.
Salen de resolver la arquitectura y la opción elegida. Si mañana se corrige el catálogo, esta
capa se regenera y se compara con la guardada, y ahí aparece qué anotaciones cambiaron de
significado.

---

## Ejemplo 2 · Un soneto

Versos 1050–1063. Cuartetos abrazados, tercetos `CDECDE`, sin finales esdrújulos destacables.

### secuencias_metricas

| secuencia_id | obra_id | v_ini | v_fin | n_versos | forma | arquitectura |
| --- | --- | ---: | ---: | ---: | --- | --- |
| `SEC-2` | `OBRA-A` | 1050 | 1063 | 14 | `soneto` | `endecasilabico_consonante` |

### realizaciones_metricas

Cinco filas: la unidad y sus cuatro secciones. Las secciones **sí** se materializan, porque la
arquitectura las declara y sus repeticiones son fijas —dos cuartetos y dos tercetos—.

| realizacion_id | padre | seccion | orden | v_ini | v_fin |
| --- | --- | --- | ---: | ---: | ---: |
| `R-20` | — | — | 1 | 1050 | 1063 |
| `R-21` | `R-20` | `cuarteto` | 1 | 1050 | 1053 |
| `R-22` | `R-20` | `cuarteto` | 2 | 1054 | 1057 |
| `R-23` | `R-20` | `terceto` | 3 | 1058 | 1060 |
| `R-24` | `R-20` | `terceto` | 4 | 1061 | 1063 |

### elecciones_metricas

| realizacion | grupo | opcion |
| --- | --- | --- |
| `R-21` | `esquema_cuartetos` | `abba` |
| `R-20` | `esquema_tercetos` | `CDECDE` |

**Dos clics para todo un soneto.** La pregunta de los cuartetos cuelga de la sección, así que
se responde una vez y vale para los dos —comparten sus dos clases de rima—. La de los tercetos
cuelga de la unidad y no de la sección, porque sus seis posiciones describen cómo se entrelazan
las rimas de un terceto con las del otro: abarca las dos secciones sin pertenecer a ninguna.

El rasgo `final_acentual` no genera fila: es de alcance secuencia y 0–1, y no se marcó.

> **La pregunta puede unir lo que la resolución separa.** Al editor se le pregunta una vez por
> los dos cuartetos y una vez por los dos tercetos, porque responder cuatro veces lo mismo no
> aporta nada. La capa resuelta lo reparte después. La simplicidad del editor y el grano del
> análisis son independientes: el grano se paga al resolver, no al registrar.

Por eso el esquema de seis posiciones **sigue haciendo falta en el catálogo** aunque la
resolución lo parta en dos. Es el único sitio donde queda dicho que los dos tercetos comparten
sus clases de rima: dos esquemas de tres posiciones, cada uno con su alfabeto, no podrían
distinguir `CDECDE` de `CDEDCE`.

### realizacion_resuelta

| realizacion | nivel | forma | seccion | metro | notacion | clases | reutiliza |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `R-20` | unidad | soneto | — | `11` | `ABBA ABBA CDECDE` | — | — |
| `R-21` | seccion | soneto | cuarteto | `11` | `ABBA` | A B B A | `cuarteto·endecasilabica` |
| `R-22` | seccion | soneto | cuarteto | `11` | `ABBA` | A B B A | `cuarteto·endecasilabica` |
| `R-23` | seccion | soneto | terceto | `11` | `CDE` | C D E | `terceto·endecasilabico_consonante` |
| `R-24` | seccion | soneto | terceto | `11` | `CDE` | C D E | `terceto·endecasilabico_consonante` |

**Cada sección lleva su propio esquema resuelto**, y la unidad lleva el completo, que sale de
juntar los de sus partes. Eso es lo lógico: un terceto es analizable como terceto, igual que un
cuarteto lo es como cuarteto, y una consulta por «tercetos encadenados con rima CDE» los
encuentra sin saber nada del soneto.

El reparto es mecánico y depende del esquema elegido:

| Elección | `R-23` | `R-24` |
| --- | --- | --- |
| `CDECDE` | C D E | C D E |
| `CDEDCE` | C D E | D C E |
| `CDCDCD` | C D C | D C D |
| `CDCEDE` | C D C | E D E |

**La columna `clases` es la que no se puede perder al repartir.** Las letras son las mismas en
las dos filas: la `C` de `R-23` y la `C` de `R-24` son la misma clase de rima, y por eso
`CDECDE` y `CDEDCE` se distinguen. Si cada terceto llevara su propio alfabeto, los dos
esquemas serían indistinguibles.

La columna `reutiliza` es la que hace que **un cuarteto sea analizable como cuarteto** esté
suelto o dentro de un soneto. Es lo que buscábamos al desgranar las estrofas básicas.

---

## Ejemplo 3 · Una copla de pie quebrado

Versos 700–709, diez versos, con quebrados tetrasílabos en el tercero y el noveno.

### secuencias_metricas · realizaciones_metricas

| secuencia_id | v_ini | v_fin | forma | arquitectura |
| --- | ---: | ---: | --- | --- |
| `SEC-3` | 700 | 709 | `copla_de_pie_quebrado` | `octosilabica_con_quebrados` |

| realizacion_id | seccion | v_ini | v_fin |
| --- | --- | ---: | ---: |
| `R-30` | — | 700 | 709 |

**Una sola realización de diez versos**, porque aquí la extensión de la unidad la declara el
pasaje: la arquitectura admite de cinco a doce.

### elecciones_metricas

| realizacion | grupo | opcion | posicion_unidad | metro |
| --- | --- | --- | ---: | --- |
| `R-30` | `medidas_pies_quebrados` | `verso_3_4_silabas` | 3 | `tetrasilabo` |
| `R-30` | `medidas_pies_quebrados` | `verso_9_4_silabas` | 9 | `tetrasilabo` |

**De dónde sale que el quebrado mide cuatro y no cinco: lo dice la opción elegida.** Cada una
de las 24 opciones encoge posición y medida en un solo dato —«Verso 3 · 4 sílabas»—, y el
editor elige la que observa. Son doce posiciones posibles por las dos medidas admitidas para
el quebrado; no son 24 esquemas métricos. La arquitectura declara el conjunto {4, 5, 8}, pero
el esquema estructurado todavía no distingue el octosílabo base de las dos medidas del
quebrado: esa regla sigue expresada en las descripciones y en la pregunta editorial.

Eso fue precisamente lo que corrigió el defecto D7. Antes había doce casillas para decir *dónde*
caía el quebrado y una pregunta aparte para decir *cuánto* medía, y nada ligaba «hay quebrado en
la 3» con «los quebrados miden 4». Ahora es una sola respuesta y no puede desligarse.

Dónde caen y cuánto miden no lo fija la norma, lo observa el editor. El disparador comprueba al
guardar que la posición 9 quepa en una unidad de diez versos y que no haya dos respuestas para
la misma posición.

### realizacion_resuelta

| realizacion | forma | metro | procedencia |
| --- | --- | --- | --- |
| `R-30` | copla_de_pie_quebrado | `8-8-4-8-8-8-8-8-4-8` | posiciones 3 y 9: elección · resto: norma |

Este es el caso donde la capa resuelta más trabajo ahorra. La secuencia de medidas **no está
escrita en ninguna parte**: sale de combinar el conjunto permitido de la arquitectura con las
dos respuestas posicionales y con la regla de que el resto son octosílabos.

---

## Cómo alimenta las fichas y los análisis

Hoy el perfil de un autor se calcula como `perfil_formas {slug: versos}` sobre
`secuencias_metricas.estrofa_tipo_id`, que apunta al vocabulario heredado: **un término por
secuencia y nada más**.

Con la capa resuelta, eso sale igual de barato y además salen cosas que hoy no se pueden
preguntar sin recorrer el catálogo:

| Pregunta | Cómo se responde |
| --- | --- |
| Perfil de formas de un autor | contar versos agrupando por `forma` |
| Qué disposición de redondilla prefiere | agrupar por `esquema_rima` filtrando `forma = redondilla` |
| Cuántos versos de cada medida escribe | agrupar por `metro` |
| Cuántos cuartetos abrazados hay, sueltos o dentro de sonetos | filtrar por `reutiliza` y `notacion` |
| Distancia entre dos obras por identidad de forma | comparar los vectores de `forma`/`arquitectura` |
| Distancia entre dos obras por rasgos | comparar los vectores de `rasgos` |

Las dos últimas son la razón de que la capa resuelta tenga que llevar **las dos cosas** —la
identidad y el vector de rasgos—. Si llevara solo la arquitectura, probar si distinguir por
rasgos da otro resultado obligaría a recorrer el catálogo, que es lo que estamos evitando.

Y una que hoy es imposible: **qué anotaciones cambiaron de significado al cambiar el
catálogo**. Se reconstruye la capa en paralelo y se compara con la guardada.

## Decidido

**Los hechos por posición van en tablas hijas.** La secuencia de medidas del ejemplo 3, las
clases de rima por posición y el vector de rasgos. Los análisis agregan sobre ellos, y agregar
sobre tablas hijas es más simple que sobre `jsonb`. Lo escalar —forma, arquitectura, sección,
notación, procedencia, versión— va en columnas de la fila resuelta.

**Se escribe al guardar, en la misma transacción**, y se vuelve a escribir cada vez que la
secuencia se modifica. Si la resolución falla, no se guarda: una realización sin resolver sería
peor que no tenerla.

**La difusión es otra capa y viene después.** Desde el dashboard se precomputará lo que
alimente las fichas públicas y los análisis, ya sea a otra tabla o a JSON publicados por una
acción de GitHub. Esa decisión no condiciona nada de lo anterior: la capa resuelta es la fuente
y lo demás son proyecciones regenerables, como el artefacto del demarcador.

**Las secuencias ya anotadas se migran cuando el editor V2 esté aprobado.** Lo que se pueda
resolver por regla se hará automático; las dudas se resolverán una a una consultando a los
editores a cargo de esas obras. Ninguna se asignará por conjetura, y el `modelo_version` dirá
con qué catálogo se resolvió cada una.

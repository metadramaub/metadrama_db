# F63 · Los tramos sin forma registran lo que se ve

**Aplicado el 3 de septiembre de 2026.**

*Al llevarlo a cabo aparecieron dos cosas que este plan no preveía, y se arreglaron con él:* la
propuesta de migración **adivinaba el arte** del término escueto —al no traer arquitectura caía en su
respaldo por compatibilidad y se quedaba con la primera, «De arte menor»—, y **la ficha pública pasó
a pintar las tres arquitecturas** como si describieran una norma, diciendo «Rima · Fijo» de algo que
no fija nada.

La versificación irregular y el verso aislado no preguntan nada. Un editor los marca y ahí acaba el
registro: se sabe dónde empieza y dónde acaba el pasaje, y nada más. Este plan les da qué registrar.

## Qué se busca, que no es lo que parece

Lo evidente sería mapear los cuatro términos legados y parar. **No basta**, porque el vocabulario
viejo guarda la conclusión, no la observación: `irregular_arte_menor` es lo que el editor dedujo, y
de ahí no sale ninguna pregunta nueva.

Lo que se busca es poder responder más adelante a **«¿esto se repite?»** — si varios pasajes
irregulares coinciden, quizá no sean irregulares sino algo que el catálogo aún no nombra. Eso exige
que lo registrado sea **comparable**, y prosa libre no lo es: dos editores describen el mismo pasaje
con palabras distintas y ninguna consulta los junta.

Lo que sí se cruza son **series**, y hay dos que describen un pasaje sin interpretarlo: la medida de
cada verso y la rima observada letra por verso. Son las mismas dos que C18 va a derivar de toda forma
regular, así que **irregulares y regulares quedan en el mismo espacio**: dos pasajes que coinciden
son dos series iguales, y eso se encuentra con una consulta, sin que nadie haya puesto una etiqueta.

*Contrastar el pasaje con el catálogo no es cosa de este registro: para eso está el demarcador.*

## Lo que hay hoy, medido

Las nueve secuencias legadas que caerían aquí, y los versos que traen:

| término legado | secuencias | versos | por secuencia |
|---|---|---|---|
| `irregular_mixto` | 6 | 147 | de 2 a 48 |
| `irregular` | 1 | 11 | 11 |
| `irregular_arte_menor` | 1 | 37 | 37 |
| `irregular_arte_mayor` | 1 | 2 | 2 |

**Ninguna tiene destino** en `propuesta_metrica_secuencia`: los cuatro términos no los reclama nadie,
así que hoy la migración las dejaría caer. Y de **verso aislado no hay ni una**: cero secuencias
legadas de un solo verso, porque el sistema viejo no dejaba registrarlo.

## La decisión: arquitectura sí, norma no

Un tramo sin forma **puede tener arquitectura**. Lo que no puede tener es una arquitectura que
declare una norma, que es lo que dicen —literalmente— las dos guardas que hoy lo impiden:

> Un tramo sin forma no puede tener arquitecturas normativas

Están bien puestas, una por cada lado: `validar_tramo_sin_forma_sin_arquitectura` sobre
`formas_metricas` y `validar_arquitectura_de_forma_con_norma` sobre `arquitecturas_forma`. Lo que
hacen es más estricto que lo que dicen: prohíben **cualquier** arquitectura. Este plan las deja
diciendo lo que ya decían, y añade la comprobación de que una arquitectura de un tramo **no declara
nada normativo**: ni esquema métrico, ni esquema de rima, ni secciones, ni regla de longitud, ni
rasgos; `demarcable = false`, `tipo_rima_id` nulo y sin límites de unidad.

Esa definición no contradice lo que el catálogo entiende por un tramo: «declara que **no hay norma**
para ese tramo» ([criterios de nivel](./criterios-de-nivel.md)). Lo que cambia no es qué es un
tramo, sino dónde se guarda esa ausencia de norma.

**Por qué hace falta.** Dos razones, y las dos son de mecanismo:

1. **La migración entra directa.** Una arquitectura que declara `origen_termino_id` reclama el
   término legado, y `propuesta_metrica_secuencia` la propone sin ninguna fila de equivalencia. Con
   una arquitectura por arte, las nueve secuencias llegan enteras: **faltarán las series, pero el
   arte que el editor dedujo se conserva**, y la migración no queda rota.
2. **Las preguntas cuelgan de una arquitectura.** `preguntas_metricas` se indexa por
   `arquitectura_id`. Sin arquitectura no hay dónde poner una pregunta, y sin pregunta el editor no
   tiene dónde escribir la serie. *La alternativa —que las preguntas cuelguen de una forma— es más
   limpia y bastante más cara; no compensa por dos entradas.*

### Todo lo que comprueba hoy la regla vieja

Cambiar cómo funcionan las no formas obliga a mover **todas** las piezas que dan por hecho que no
tienen arquitectura, no solo las dos guardas. Están inventariadas:

| dónde | qué comprueba hoy | qué pasa a comprobar |
|---|---|---|
| `validar_tramo_sin_forma_sin_arquitectura` · disparador sobre `formas_metricas` | el tramo no tiene ninguna arquitectura | ninguna de sus arquitecturas declara norma |
| `validar_arquitectura_de_forma_con_norma` · disparador sobre `arquitecturas_forma` | la arquitectura no es de un tramo | si lo es, no declara norma |
| `validar_anotacion_metrica` · disparador sobre `anotaciones_metricas` | una anotación de tramo **no trae** `arquitectura_id` | que la arquitectura sea suya, como en cualquier forma. *Sus otras dos reglas se conservan: el verso aislado abarca un verso y la irregular al menos dos* |
| `validar_anotacion_eleccion` | una respuesta escrita exige `tipo_control` de rima | acepta también `serie_medidas`, con la misma validación de longitud |
| **D10** en `audit-catalogo-metrico.mjs` y en [criterios de nivel](./criterios-de-nivel.md) | «un tramo sin forma no tiene arquitectura» | «no tiene arquitectura **normativa**»: el defecto salta si declara algo |
| `changeForm` en `MetricSequenceEditor.svelte` | vacía la configuración al elegir un tramo | le ofrece sus arquitecturas |

Las dos que **no** cambian, y que hay que comprobar que siguen igual: `get_catalogo_formas_publicas`
y `obtener_catalogo_demarcador` filtran por `tipo_registro = 'forma'`, así que los tramos siguen sin
salir ni en el catálogo público ni en el demarcador, tengan arquitectura o no.

## Las cuatro arquitecturas

**Versificación irregular**, una por arte, cada una reclamando su término:

| arquitectura | reclama | secuencias que recoge |
|---|---|---|
| De arte menor | `irregular_arte_menor` | 1 |
| De arte mayor | `irregular_arte_mayor` | 1 |
| Mixta | `irregular_mixto` | 6 |

**El término escueto, `irregular`, se queda sin destino a propósito.** Es una sola secuencia —*El
mágico prodigioso*, vv. 2191–2201, obra asignada a Emma González Mesas— y antes de darle sitio hay
que preguntar a quien la anotó por qué eligió el término madre y no uno de los tres específicos. Si
fue por duda, su destino es otro que el de un pasaje que de verdad no se puede clasificar.

**Verso aislado**, una sola —«De cualquier medida»— sin término legado que reclamar, porque no hay
corpus viejo que recoger.

**Y no hay una arquitectura por causa de la irregularidad.** Una laguna conocida no es un pasaje
irregular: es una forma real a la que le faltan versos, y eso se registra como desviación. Fuera de
ese caso, muchas veces un pasaje es irregular y punto, o no se sabe si es por el testimonio, así que
clasificarlo por su causa obligaría al editor a afirmar lo que no puede saber.

## Qué se pregunta, y qué se deriva

Dos preguntas, las dos **escritas de una vez**, no verso a verso: mismo dato, una sola escritura, y
el mecanismo ya existe y está probado —es el del esquema de rima abierto, que valida que haya una
posición por verso del rango—.

| pregunta | dimensión | se escribe | ejemplo |
|---|---|---|---|
| Medida de cada verso | `metro` | una medida por verso | `11 7 11 11 7 7` |
| Rima observada | `rima` | una letra por verso, guion para el suelto | `-a-ab b` |

**El verso aislado solo pregunta la medida.** Un verso solo no rima con nada: si rimara con el
anterior o con el siguiente, formaría parte de esa forma y es ahí donde habría que anotarlo.

**Y no se pregunta nada más, porque lo demás se deriva** de esas dos series: el arte —menor, mayor o
mixto—, cuántas medidas distintas hay, si el pasaje rima y con qué densidad, y si la serie tiene
periodo. Preguntar el arte sería guardar dos veces la misma cosa; la correspondencia con los cuatro
términos viejos se calcula desde ahí, y sirve además para **comprobar si el arte que dedujo el editor
antiguo coincide con el que dicen las medidas**.

## Plan

### 1 · La base

Una migración que hace cuatro cosas, en este orden, y que **ejecuta cada guarda que toca**: con un
caso que debe pasar y otro que debe fallar, porque un cuerpo entrecomillado no se revalida solo.

1. **Reescribe las tres guardas de la base** según la tabla de arriba.
2. **Añade `serie_medidas` a `tipo_control`** y lo acepta en `validar_anotacion_eleccion`, junto a
   `esquema_rima` y `opciones_y_esquema`, con la misma validación de longitud: tantas posiciones como
   versos.
3. **Crea las cuatro arquitecturas y sus ocho preguntas**, con `origen_termino_id` donde toca.
4. **Comprueba que ocho de las nueve secuencias legadas ya tienen destino**, contándolas. La novena
   es la de `irregular` a secas, que espera respuesta de quien la anotó.

### 2 · El auditor y su criterio

**D10 cambia de enunciado**, en el script y en [criterios de nivel](./criterios-de-nivel.md): de «un
tramo sin forma no tiene arquitectura» a «no tiene arquitectura normativa», detectando lo que la
guarda nueva prohíbe. Si no se cambia, el informe pasa de 0 defectos a 5 el día que se aplique la
migración.

### 3 · El editor

`changeForm` vacía hoy la configuración al elegir un tramo sin forma. Pasa a ofrecer sus
arquitecturas como las de cualquier forma. El campo escrito de medidas reutiliza el componente del
esquema de rima abierto, con su validación de longitud.

### 4 · Comprobación

1. Que ocho de las nueve secuencias legadas **tienen destino**: `propuesta_metrica_secuencia` las
   propone con su arquitectura, y el informe por obra deja de dejarlas caer.
2. Anotar en «Prueba» un pasaje irregular y un verso aislado, y comprobar en la base que las series
   se guardan y se releen.
3. Que **el catálogo público y el demarcador siguen sin verlos**: los dos filtran por
   `tipo_registro = 'forma'`, así que las arquitecturas nuevas no deben aparecer en `/formas`, ni en
   `/recursos/catalogo-metrico`, ni en el catálogo del demarcador. Se comprueba, no se supone.
4. `npm run audit:metrica`, que no debe encontrar defectos nuevos: **las cuatro arquitecturas no
   declaran norma, y varios criterios de nivel dan por hecho que una arquitectura la declara**.
5. `npm run audit:anotaciones`, `npm run check`, `npm run test`.

## Lo que este plan no hace

- **No migra nada.** Deja el destino puesto para cuando se migre.
- **No proyecta las series a notación comparable**, que es C18 y va después.

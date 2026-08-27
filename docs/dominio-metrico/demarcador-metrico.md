# Demarcador métrico

Este documento describe el contrato conceptual, la matemática y las decisiones de producto
del demarcador conectado al catálogo métrico. Debe actualizarse cuando cambie el motor, no
cuando se modifique una forma concreta del catálogo.

## Objetivo

El demarcador orienta la identificación de una forma a partir de hechos observables en un
pasaje. No clasifica automáticamente el texto ni exige que el usuario conozca de antemano la
norma que intenta identificar.

Hay dos recorridos:

1. **Identificación guiada**: parte de observaciones generales y propone formas compatibles.
2. **Comprobación de hipótesis**: prioriza preguntas definitorias de una forma elegida, pero no
   modifica artificialmente su puntuación ni oculta alternativas.

La identidad principal del resultado es siempre la **forma**. La **arquitectura** aparece como
una precisión subordinada de su realización estructural.

## Fuente de verdad

El demarcador consulta el catálogo actual al cargar la página. No mantiene JSON estáticos,
instantáneas ni versiones propias. La proyección se genera en
`src/lib/server/demarcador-metrico.ts` y consume únicamente formas seleccionables y
arquitecturas activas y demarcables.

Durante la fase de pruebas la función de lectura solo devuelve datos a perfiles admin o IP.
Ampliarla a otros editores o habilitar su ejecución para el rol anónimo es una decisión de
publicación y debe autorizarse después de revisar los campos expuestos.

La proyección transforma en evidencias:

- esquemas métricos y metros;
- extensión mínima y máxima de la unidad y reglas de longitud derivadas;
- nivel estructural de la forma: verso, estrofa, serie o composición;
- tipo y esquemas de rima con ámbito de unidad;
- secciones internas;
- repeticiones estructurales;
- rasgos métricos marcados como demarcables;
- elecciones declaradas por cada arquitectura.

Los esquemas con ámbito de sección no se presentan como esquemas completos de la forma.

## Norma y observación

La interfaz solo debe preguntar hechos que el usuario pueda observar. Los hechos derivados
—por ejemplo, que la norma sea una tirada abierta o una forma fija— se calculan y nunca se
preguntan directamente.

Cada evidencia conserva dos escalas del catálogo:

### Observabilidad

| Valor | Uso |
| --- | --- |
| `directa` | Puede preguntarse en el recorrido ordinario. |
| `especializada` | Solo se pregunta cuando la ganancia esperada justifica el coste. |
| `derivada` | No se pregunta; se obtiene de otras evidencias. |

### Modalidad

| Valor | Coincidencia | Contradicción |
| --- | ---: | ---: |
| `definitoria` | 1,00 | 1,25 |
| `habitual` | 0,62 | 0,45 |
| `admitida` | 0,28 | 0,10 |
| `excepcional` | 0,12 | 0,00 |

La asimetría es deliberada. Contradecir una condición definitoria pesa más que confirmarla;
no observar algo meramente admitido o excepcional apenas debe perjudicar una hipótesis.

## Puntuación de compatibilidad

El motor trabaja con hipótesis de arquitectura y después las agrupa por forma. Para una
hipótesis `h` y un conjunto de respuestas `R`:

```text
S(h) = P(h) + Σ ajuste(h, r), para cada r en R
```

`P(h)` es un desempate mínimo a favor de la arquitectura principal (`0,05`), no una
probabilidad previa. Para cada respuesta:

```text
si coincide:     ajuste =  fiabilidad(observabilidad) × peso_positivo(modalidad)
si contradice:   ajuste = -fiabilidad(observabilidad) × peso_negativo(modalidad)
si no se sabe:   ajuste = 0
si no hay dato:  ajuste = 0
```

La fiabilidad vale `1` para observación directa, `0,65` para especializada y `0` para
derivada. Una respuesta nunca elimina por sí sola una forma.

### Longitud regular y desviaciones

La extensión no se compara solo con un mínimo y un máximo. El motor consume la regla que el
catálogo deriva de la arquitectura y comprueba:

```text
L >= mínimo
L <= máximo, si existe
(L - residuo) mod módulo = 0, si existe congruencia
```

Así, el terceto encadenado admite regularmente `L = 3n + 1`: 4, 7, 10, 13, 16 versos,
etc. Catorce versos no son una coincidencia regular.

Una longitud no regular tampoco elimina la hipótesis. El motor calcula las realizaciones
regulares inmediatamente anterior y posterior. Para 14 versos en un terceto encadenado son
13 y 16: puede sobrar un verso respecto de la primera o faltar dos respecto de la segunda.
La interfaz presenta entonces «Posible con desviación» y explicita ambas distancias. La causa
puede ser una laguna, una adición, una desviación histórica o autorial, un error textual o una
delimitación incorrecta del pasaje; el demarcador no decide cuál sin evidencia adicional.

La pregunta se refiere a los versos del **pasaje seleccionado**, no a una unidad que el usuario
deba haber reconocido de antemano. El nivel estructural decide cómo se explica una coincidencia:

- 25 versos en una quintilla son cinco unidades regulares de 5 versos;
- 28 versos en un soneto son dos composiciones completas de 14, no un soneto de 28;
- 25 versos en un terceto encadenado forman una sola serie que cumple `3n + 1`.

Cuando dos lecturas cumplen la longitud —por ejemplo, cinco quintillas y un terceto encadenado
octosilábico— ninguna debe desaparecer. La siguiente pregunta busca una diferencia observable,
como la presencia de grupos independientes de cinco versos o de una serie articulada en grupos
de tres y un cierre.

La puntuación de una forma es la de su arquitectura más compatible:

```text
S(forma) = max S(arquitectura de la forma)
```

Este máximo expresa que basta con que una realización estructural admitida sea compatible.
También evita favorecer a las formas que tienen más arquitecturas.

Las etiquetas «Muy compatible», «Compatible», «Posible» y «Poco compatible» expresan
distancias relativas entre resultados. No son porcentajes ni probabilidades estadísticas.

## Selección de la siguiente pregunta

Las preguntas posibles se agrupan por dimensión observable. Su utilidad aproximada es:

```text
U(q) = separación(q)
     × cobertura(q)
     × respondibilidad(q)
     × (1 - coste(q))
     × penalización_por_no_sé(q)
     × impulso_de_hipótesis(q)
```

- `separación` es la entropía de las respuestas predichas entre las candidatas actuales;
- `cobertura` es la proporción de candidatas que declaran esa dimensión;
- `respondibilidad` procede de la observabilidad;
- `coste` representa dificultad cognitiva o técnica;
- después de «No sé», las preguntas de la misma familia cognitiva se multiplican por `0,22`;
- al comprobar una hipótesis, una pregunta definitoria suya se multiplica por `1,35`.

En el recorrido guiado la entrada es una clasificación sencilla: arte menor, arte mayor o
mezcla de ambos. Si la respuesta permite distinguir medidas concretas entre las candidatas, la
pregunta siguiente se limita a las que pertenecen al grupo elegido; en el caso mixto, ofrece las
combinaciones documentadas en esas arquitecturas. «No sé» evita esa precisión inmediata.

## Criterio de parada

El recorrido se detiene provisionalmente cuando:

- hay al menos dos respuestas concluyentes;
- la primera hipótesis acumula al menos dos coincidencias;
- su forma aventaja a la siguiente en `0,75` puntos;

o cuando no quedan preguntas útiles. El usuario puede solicitar afinamiento, pero el sistema
no fuerza preguntas especializadas para producir una falsa respuesta única.

## Explicabilidad

Cada resultado debe mostrar:

1. nombre de la forma;
2. arquitectura mejor situada, en segundo nivel;
3. grado cualitativo de compatibilidad;
4. evidencias que coinciden;
5. cuando sea útil, contradicciones y datos todavía desconocidos;
6. si la extensión no es regular, las longitudes regulares vecinas y los versos que faltan o
   sobran.

La explicación de la arquitectura reúne solo información ya normalizada en el catálogo:

- interpretación de la longitud del pasaje y número de unidades, si procede;
- patrón métrico representado por posiciones;
- tipo de rima y esquemas admitidos en notación compacta;
- organización de secciones y repeticiones;
- rasgos de la arquitectura con su modalidad;
- otras arquitecturas disponibles dentro de la misma forma.

La definición de la forma expresa lo común. El origen italiano del terceto encadenado
endecasilábico y su adaptación octosilábica al metro español pertenecen a las descripciones de
sus arquitecturas y deben mostrarse junto al resultado correspondiente.

La interfaz no muestra la puntuación numérica porque sirve para ordenar, no para comunicar
certeza.

## Límites actuales

- El demarcador no escande versos automáticamente.
- No interpreta por sí solo dónde empieza o termina una unidad si el usuario no puede verla.
- Las relaciones entre formas sirven para contextualizar resultados próximos, pero todavía
  no alteran la puntuación.
- Una propiedad derivada o no demarcable puede aparecer en la explicación final, pero nunca
  debe convertirse automáticamente en pregunta.

## Validación antes de publicar

La publicación requiere un corpus de recorridos esperados, como mínimo:

- romance y romancillo;
- soneto y sus arquitecturas;
- redondilla, cuarteta y formas generales próximas;
- silva, serie endecasilábica y verso suelto;
- villancico, zéjel y formas con repetición;
- casos incompletos y recorridos con varios «No sé».

Para cada caso se debe registrar: respuestas disponibles para un usuario no especialista,
posición esperada de la forma, preguntas evitadas, criterio de parada y explicaciones
mostradas. Los cambios de pesos se justifican contra este conjunto y se anotan aquí.

Antes de abrir la herramienta sin sesión también se debe revisar la función
`obtener_catalogo_demarcador()` y conceder explícitamente su ejecución al rol `anon`.

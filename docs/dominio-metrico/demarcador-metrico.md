# Demarcador métrico

Este documento describe el contrato conceptual, la matemática y las decisiones de producto
del demarcador conectado al catálogo métrico. Debe actualizarse cuando cambie el motor, no
cuando se modifique una forma concreta del catálogo.

**Con qué material trabaja hoy** —cuántas formas entran, qué puede preguntar de cada una, qué
rasgos quedan fuera, qué contrastes declara el catálogo— no se escribe aquí: lo regenera
`npm run demarcador:informe` en [informe-demarcador.md](./informe-demarcador.md) leyendo la base.
Lo que cambia al tocar el catálogo se regenera; lo que cambia al cambiar de idea se escribe.

## Objetivo

El demarcador orienta la identificación de una forma a partir de hechos observables en un
pasaje. No clasifica automáticamente el texto ni exige que el usuario conozca de antemano la
norma que intenta identificar.

Hay dos recorridos:

1. **Identificación guiada**: parte de observaciones generales y propone formas compatibles.
2. **Comprobación de hipótesis**: contrasta una forma contra **sus rivales**, no contra el catálogo.

**Son dos inferencias distintas y por eso no comparten criterio.** Identificar es clasificación
abierta: hay unas trescientas hipótesis y lo que conviene es la pregunta que mejor reparte la
población, que es la entropía. Comprobar es discriminación: la pregunta no es «¿cuál de trescientas?»
sino «¿es esta, y si no, con cuál la estoy confundiendo?». Una pregunta que parte el catálogo por la
mitad pero que la hipótesis y su rival responden igual vale **cero** para comprobar, y era justo la
que salía primera cuando los dos recorridos compartían fórmula.

La identidad principal del resultado es siempre la **forma**. La **arquitectura** aparece como
una precisión subordinada de su realización estructural.

## Fuente de verdad

El demarcador consulta el catálogo actual al cargar la página. No mantiene JSON estáticos,
instantáneas ni versiones propias. **Lo compilado se guarda un minuto en memoria del servidor**,
porque el catálogo solo cambia cuando lo cambia una migración y recompilar novecientas evidencias en
cada carga no lo mejora. El minuto tiene un precio que conviene saber: *una migración aplicada con el
servidor levantado tarda hasta un minuto en verse*. La proyección se genera en
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

Dos casos concretos, que costaron encontrarse y conviene no volver a discutir:

- **Un rasgo de presencia se pregunta como presencia.** Un rasgo de catálogo con un único valor
  posible es un booleano disfrazado: su contenido entero es estar presente. Se ofrece «sí / no», y el
  «no» es lo que permite que el rasgo **contradiga** a una forma. Sin él, la única salida honesta era
  «No sé», que puntúa cero y además penaliza al 22 % las demás preguntas de su familia.
- **Un rasgo deducible del esquema no se declara como rasgo.** El pareado final de una octava real ya
  está escrito en `ABABABCC`: declararlo aparte era pedir al editor que repitiera la notación, y
  dejaba el rasgo anotado en una forma y ausente en otra, con lo que no se podían comparar.

Y una distinción del metro que parece de detalle y decide un recorrido entero: **«admite cualquiera
de estas medidas» no es «las mezcla»**. Un esquema de tipo `conjunto` enumera el repertorio, y
`medida_uniforme` dice si dentro de la unidad se comparte una de ellas —el pareado isométrico mide
igual sus dos versos, sea cual sea la medida— o si se combinan —la silva alterna siete y once—. Declararlo mal resume el
repertorio en «mixto», y entonces responder «arte mayor» **contradice** a la forma en la primera
pregunta y la deja fuera del recorrido.

Cada evidencia conserva dos escalas del catálogo:

### Observabilidad

| Valor           | Uso                                                              |
| --------------- | ---------------------------------------------------------------- |
| `directa`       | Puede preguntarse en el recorrido ordinario.                     |
| `especializada` | Solo se pregunta cuando la ganancia esperada justifica el coste. |
| `derivada`      | No se pregunta; se obtiene de otras evidencias.                  |

### Modalidad

| Valor         | Coincidencia | Contradicción |
| ------------- | -----------: | ------------: |
| `definitoria` |         1,00 |          1,25 |
| `habitual`    |         0,62 |          0,45 |
| `admitida`    |         0,28 |          0,10 |
| `excepcional` |         0,12 |          0,00 |

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

Con menos de tres respuestas concluyentes, las formas se presentan como **candidatas**: las
coincidencias generales todavía son demasiado pobres para graduarlas. Después se emplean
«Encaje alto», «Encaje medio» y «Encaje bajo». El grado alto exige además una ventaja de `0,75`
respecto de la forma siguiente; un empate nunca puede producirlo. Son grados relativos de
compatibilidad, no porcentajes ni probabilidades estadísticas.

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
- repetir inmediatamente la misma familia cognitiva se multiplica por `0,45`, salvo la pregunta
  general de uniformidad que sigue a la división inicial del metro;
- **al comprobar una hipótesis, la separación no es la entropía sino la discriminación**: qué
  proporción de la masa rival predice algo distinto de lo que predice la hipótesis. Uno es la
  pregunta que la separa de todas; cero, la que no la separa de ninguna.

El impulso a las definitorias de la hipótesis —un `1,35` que cualquier entropía alta se comía— se
retiró al llegar la discriminación: premiaba lo que **define** una forma y no lo que la **distingue**,
y el endecasílabo es definitorio del soneto y de otras cuatro.

### Contra quién se contrasta

Al comprobar, las candidatas no son las doce mejores del catálogo sino la hipótesis y **sus
rivales**, que salen de tres fuentes sumadas: los contrastes que el catálogo declara en
`forma_relaciones`, los que las respuestas hayan puesto arriba, y los estructuralmente próximos
cuando no hay contraste declarado. **La hipótesis entra siempre**, aunque las respuestas la hayan
hundido: antes, si caía del puesto doce, el recorrido dejaba de tratar sobre ella en silencio, que es
abandonarla justo cuando hay que ponerla a prueba.

Estrechar el campo estrecha también las respuestas ofrecidas, porque las opciones de una pregunta se
juntan de las candidatas que la declaran. Si el campo estrecho no produce ninguna pregunta —hay
formas sin contraste declarado— se abre al general: vale más una pregunta general que ninguna.

**Una hipótesis refutada deja de gobernar.** Si el pasaje contradice algo que su norma fija, seguir
preguntando por lo que la separa de sus rivales es perseguir a un muerto: la pregunta ha vuelto a ser
«¿cuál es, entonces?», y el recorrido pasa al campo y al criterio del guiado.

### Dos preguntas cableadas, y por qué

El orden por utilidad no basta en dos sitios, y en los dos se corrigió con una regla fija:

- **el grupo de arte va primero** y la uniformidad después, porque casi todo lo demás depende de
  saber en qué mitad del catálogo estamos;
- **el tipo de rima va tercero**, en cuanto se cierra esa cadena. Dejado al cálculo quedaba el
  último, detrás de «cuántas sílabas» y «pie quebrado», que lo superan en separación aunque
  confirmen decenas de formas a la vez. Un romance octosílabo asonante costaba ocho preguntas y
  ahora cuesta cuatro: la rima es lo único que lo distingue de una sextilla octosílaba.

### Lo que no se pregunta aunque separe

`estructura:orden` —«¿qué organización interna reconoces?»— ofrece una etiqueta por arquitectura,
así que **sus opciones son la respuesta**: nombran la unidad completa. Y como cada arquitectura
aporta una etiqueta distinta, su separación es máxima y ganaba el primer puesto por delante del tipo
de rima. Queda **solo para el modo hipótesis**, donde quien la usa ya trae una forma en la cabeza, y
en ningún modo se pregunta si ya se respondió que no hay secciones internas.

Tras la primera respuesta, la utilidad se calcula sobre las arquitecturas de las doce formas
mejor situadas en ese momento, de modo que las formas muy alejadas no condicionen las preguntas
siguientes.

En el recorrido guiado la entrada es una clasificación sencilla: arte menor, arte mayor o
mezcla de ambos. Cuando todavía hay candidatas con una sola medida y con varias, se pregunta si
en general los versos siguen una misma medida. La formulación se refiere a la pauta del pasaje:
un verso aislado que parezca hipométrico o hipermétrico no obliga a responder que se combinan
varias medidas. A partir de ahí, la medida exacta vuelve a competir con la extensión, la rima,
la repetición y la estructura: solo aparece si separa bien las candidatas pese a su mayor coste.
Cuando se pregunta, se ofrecen únicamente medidas compatibles con las respuestas anteriores,
sin pedir al usuario que interprete qué función cumple cada una. «No sé» evita esa precisión.

## Criterio de parada

**Al identificar**, el recorrido se detiene provisionalmente cuando:

- hay al menos tres respuestas concluyentes;
- **se ha preguntado la extensión**, o no hay ninguna candidata que la declare;
- la primera hipótesis acumula al menos dos coincidencias;
- su forma aventaja a la siguiente en `0,75` puntos;

o cuando no quedan preguntas útiles.

*La extensión es condición porque las series —romance, silva, endecasílabo suelto— no tienen unidad
que comprobar y coinciden con menos evidencia que cualquier estrofa: sin ella, «arte menor + misma
medida + asonante» declaraba romance lo mismo a doscientos versos que a cuatro, donde lo probable es
una copla o una seguidilla.*

**Al comprobar, el final es un veredicto y no un ranking.** Un contraste termina de tres maneras:

- **sostenida**: nada la contradice y aventaja claramente a su rival;
- **refutada**: el pasaje contradice algo que su norma fija. Se exige que **todas** sus arquitecturas
  lo contradigan, porque una forma se sostiene si alguna de sus realizaciones encaja;
- **indecidible**: empata con su rival y **no queda ninguna discrepancia observable que preguntar**.
  No es un fracaso: cuando dos normas coinciden en todo lo que se puede ver en el pasaje, decirlo
  vale más que seguir pidiendo precisiones que no van a decidir nada.

Las discrepancias pendientes deciden los empates, no bloquean las victorias: exigir que no quedara
ninguna dejaba el recorrido sin final, porque dos formas casi siempre difieren en varias dimensiones. El usuario puede solicitar afinamiento, pero el sistema
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

Durante el recorrido, las candidatas se presentan resumidas y la explicación completa se abre
solo a petición del usuario. La cabecera compara las dos primeras con las respuestas disponibles;
si siguen empatadas, debe decirlo en vez de inventar una diferencia. El historial conserva las
respuestas a la vista y permite retomar el recorrido desde cualquiera de ellas.

La explicación de la arquitectura reúne solo información ya normalizada en el catálogo:

- interpretación de la longitud del pasaje y número de unidades, si procede;
- patrón métrico representado por posiciones;
- tipo de rima y esquemas admitidos en notación compacta;
- organización de secciones y repeticiones;
- rasgos de la arquitectura con su modalidad;
- otras arquitecturas disponibles dentro de la misma forma.

La presentación del metro deriva los roles declarados por el catálogo: una medida dominante y
otras medidas admitidas no se escriben como una suma. Cuando hay roles, se formula la pauta y las
variantes por separado; solo una secuencia de posiciones distintas se presenta como combinación.

La definición de la forma expresa lo común. El origen italiano del terceto encadenado
endecasilábico y su adaptación octosilábica al metro español pertenecen a las descripciones de
sus arquitecturas y deben mostrarse junto al resultado correspondiente.

La interfaz no muestra la puntuación numérica porque sirve para ordenar, no para comunicar
certeza.

## Límites actuales

- El demarcador no escande versos automáticamente.
- No interpreta por sí solo dónde empieza o termina una unidad si el usuario no puede verla.
- Las relaciones entre formas deciden **contra quién se contrasta** una hipótesis, pero todavía no
  alteran la puntuación.
- **La puntuación premia coincidir sin medir cuánto se juega cada forma.** Suma acuerdos, y cada
  acierto vale lo mismo para quien admite una sola realización que para quien admite infinitas:
  «catorce versos» es casi una prueba para el soneto —su única extensión— y no dice nada del septeto,
  al que le valen 7, 14, 21… Las dos se llevan el mismo punto. Su corolario: **«no declara» nunca
  penaliza**, así que una forma vaga no se equivoca nunca; y el que admite cualquier medida no cobra
  por la medida, así que el pareado siempre irá por detrás del cuarteto aunque los dos encajen. Hace
  falta ponderar cada coincidencia por la especificidad de la norma, y es lo único que puede separar
  dos formas que encajan las dos.
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

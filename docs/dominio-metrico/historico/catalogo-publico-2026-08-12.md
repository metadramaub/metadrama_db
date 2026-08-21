# La presentación del catálogo público

> **Histórico.** Cumplió su función el 12 de agosto de 2026: sirvió para inventariar los moldes del
> catálogo y rediseñar la ficha, y **ya no describe el estado**. Lo vigente vive donde se comprueba:
> los moldes y los perfiles, en `src/lib/metrica/rejilla.ts` y sus pruebas; por qué la ficha se lee
> dimensión a dimensión, en `PublicArchitectureCard.svelte`; el criterio del régimen de rima y la
> caja de las clases, en [criterios de nivel § 3.3](../criterios-de-nivel.md), con `D14` y `D15`
> comprobándolos. Se conserva por el razonamiento y por los recuentos del día que se hizo.

Escrito el 12 de agosto de 2026 e **implementado ese mismo día**. Inventario y diseño del **repaso
visual del catálogo público** —punto 13 de
[lo que queda pendiente](../CONTEXTO-PARA-CONTINUAR.md#qué-queda-pendiente)—, extendido al
demarcador y al recuadro de la norma del editor V2, porque las tres superficies pintan lo mismo y
lo pintaban distinto.

Todo lo que sigue está contrastado con la base enlazada el 12 de agosto de 2026: 57 arquitecturas
activas de 29 registros, con sus esquemas, posiciones, restricciones, secciones y grupos de
elección. Ningún recuento viene de un documento.

> **Estado: hecho, en dos tramos.** El primero puso la rejilla —`src/lib/metrica/rejilla.ts`, con
> sus pruebas, dibujada por `MetricPositionGrid.svelte` y consumida por la ficha, el demarcador y
> el editor V2—. El segundo, tras verla en pantalla, **rehízo la ficha entera**: la figura dejó de
> sumarse a la prosa que ya la decía y la arquitectura pasa a leerse dimensión a dimensión. Está
> contado en [la ficha por dimensiones](#la-ficha-por-dimensiones).
>
> Las cinco migraciones que sostienen el primer tramo —`20260812140000`, `150000` y `160000`— y el
> segundo —`180000`, `200000` y `210000`— **solo amplían proyecciones**. Las dos que sí tocan
> datos, `170000` y `190000`, corrigen lo que el dibujo destapó y están en
> [lo que salió al dibujarlo](#lo-que-salió-al-dibujarlo).

## El diagnóstico en una frase

`/formas/[slug]` aplicaba **una sola plantilla a las 57 arquitecturas**, y la plantilla enseñaba
prosa. Como la prosa la escribe el catálogo forma por forma, dos arquitecturas del mismo molde se
leían distinto —«Endecasílabo repetido» frente a «7-7-11-7-7-11-7-7-7-7-11-7-11»— y dos de moldes
opuestos se leían igual. Lo que ninguna enseñaba era **la estructura**: dónde cae cada medida y
cada clase de rima, qué parte ocupa qué versos, y qué de todo eso lo fija la norma y qué lo fija
la realización.

El demarcador sí lo enseñaba —pintaba las posiciones métricas en casillas— y era lo único de las
dos superficies que un editor podía leer de un vistazo. Lo que se ha hecho es llevar esa casilla a
la ficha, arreglarla, y **elegir qué se pinta según el molde de la arquitectura**, igual que el
editor V2 elige qué preguntas hace.

## Lo que se perdía por el camino

Verificado contra la base y contra el código, no deducido de las capturas.

**El cuello de botella no era el componente: era la RPC.** `get_forma_metrica_publica` decide qué
sale de la base, y de la medida solo sacaba `nombre` y `descripcion`. Las posiciones métricas, las
opciones, el metro, `tipo_secuencia` y `medida_uniforme` **no salían de la base**, así que la
ficha no podía dibujar la medida aunque quisiera. De la rima salían `nombre`, `notacion`,
`descripcion` y `seccion_id`, pero no `modalidad` ni `tipo_secuencia`; y de las posiciones de rima
solo las que tenían sección (`where p.seccion is not null`), sin `clase_rima` ni `suelto`. Es
decir: **la ficha no tenía las letras**. Por eso lo primero fue la migración.

Con eso dicho, lo que se perdía:

| Qué | Dónde se pierde | Consecuencia |
|---|---|---|
| Toda la estructura métrica | RPC no la envía | «7-7-11…» es el **nombre** que alguien escribió en `esquemas_metricos.nombre`, no un dato dibujado. 33 arquitecturas isosilábicas dicen lo mismo con 21 redacciones distintas |
| `modalidad` de los esquemas de rima | RPC + `mapearRima` | Las ocho tipologías de la quintilla salen iguales, y la base distingue `habitual` (ababa), `admitida` (4) y `excepcional` (3) |
| `modalidad` de las variedades | `formas-publicas.ts:490-494` | Las 7 del sexteto-lira salen iguales; A1 es `habitual` y las otras seis `admitida` |
| `posiciones_max` de un rasgo | RPC | La copla real admite **hasta 2** quebrados; la ficha solo dice que los admite |
| `reutiliza` de una sección | `PublicFormSectionTree.svelte` no lo pinta | El servidor lo calcula (`formas-publicas.ts:430-432`) y se tira. Los cuartetos del soneto no dicen que riman como el cuarteto endecasílabo, ni enlazan a él |
| `esquemasRima` de una sección | mismo componente | Se calcula y se tira; llega a la ficha por el otro camino, el de «Rima» |
| La partición en bloques | `partesDe` funde nombres consecutivos iguales | `ABBA ABBA` tiene dos bloques `cuarteto` y sale como **una** parte de 1 a 8; como solo se enumeran las partes cuando hay más de una, no sale nada |
| `regla` de una repetición | **La columna no existe** | `formas-publicas.ts:506` hace `String(r.regla)` sobre `undefined`: `/formas/villancico`, `/formas/zejel` y las tres sextinas **imprimen «undefined»** en el bloque «Repetición». La prueba pasa porque su fixture inventa el campo (`formas-publicas.test.ts:84`) |

Y dos defectos de composición visibles en las capturas:

- **La rima estaba plegada y lo demás no.** Cada disposición era un `<details>` cerrado, de modo
  que lo más informativo de la ficha —qué distingue `CDE DCE` de `CDE CDE`— exigía ocho clics,
  mientras «Rasgos que admite» enseñaba entero un dato marginal.
- **La descripción del esquema y la de su restricción se repiten.** En las estancias variables,
  «El esquema concreto es libre dentro de la estancia, pero debe repetirse idénticamente…» y
  «El esquema concreto es libre, pero vuelve idéntico…» son la misma frase apilada, porque la
  ficha pinta las dos y el catálogo las escribió las dos.

Del demarcador, el mismo defecto en su forma más grave: **las alternativas de una posición se
pintaban como posiciones**. Ordenaba las posiciones por `posicion` y mapeaba fila a fila, sin
agrupar por `alternativa`. La seguidilla gitana, que es `6-6-(10/11/12)-6`, salía con doce
casillas; la sextilla de pie quebrado, que es `8-8-4-8-8-4`, con ocho.

## El inventario: los moldes que hay de verdad

### La medida: seis moldes, y solo dos se parecen

| Molde | Arqs. | Qué declara la base | Ejemplos |
|---|---|---|---|
| **Isosilábica** | 32 | `ciclo` con **una** posición | soneto, quintilla, romance, sextina |
| **Isosilábica con quebrados** | 1 | `ciclo` de una posición **más** opciones con `rol` | copla real (8, con hasta 2 quebrados de 4 o 5) |
| **Ciclo de varias posiciones** | 4 | `ciclo` con 2-5 posiciones que se repiten | endecha real (7-7-7-11), silva regular (7-11) |
| **Secuencia fija** | 11 | `secuencia`, tantas posiciones como versos | lira (7-11-7-7-11), canción de 13, chamberga |
| **Secuencia con alternativa** | (3 de las 11) | posiciones con `alternativa` > 1 | seguidilla gitana (3.ª = 10, 11 o 12), sextilla de pie quebrado (3.ª y 6.ª = 4 o 5) |
| **Repertorio libre** | 6 | `conjunto`, `medida_uniforme = false` | silva, canción variable, pareado (9 medidas), copla de pie quebrado |
| **Repertorio uniforme** | 3 | `conjunto`, `medida_uniforme = true` | villancico ×2, zéjel (6 **u** 8, la misma en todo el pasaje) |

Las dos últimas filas son las que el IP señala: **la norma da el repertorio y la realización dice
dónde va cada medida**. Y no son el mismo caso: en la silva cada verso elige; en el villancico
elige la composición entera y luego todos los versos la siguen. Hoy las tres del villancico y las
seis de la silva se leen con la misma frase, «Heptasílabo o endecasílabo».

### La rima: cinco moldes

| Molde | Esquemas | Qué lo define | Ejemplos |
|---|---|---|---|
| **Cerrado de un bloque** | 49 | posiciones, un solo bloque, sin enlaces | quintilla ×8, lira, octava real |
| **Cerrado con secciones internas** | 3 | posiciones con `seccion` | canción de 13 (fronte / eslabón / sirima), décima ×2 |
| **Cerrado de varios bloques** | 7 | `bloque` > 1, todos con sección | soneto ×5, copla manriqueña |
| **Cíclico** | 11 | notación `[…]…`, con o sin enlace | romance ×4, terceto encadenado ×2, zéjel, silva regular |
| **Abierto** | 17 | sin posiciones; la norma son sus restricciones | quintilla («2 clases, 2 alternancias, ningún suelto»), silva, sextilla ×5 |

Nueve de los diecisiete abiertos **no tienen ninguna restricción**: dicen «distribución variable»
y nada más. No es un defecto de la ficha —es lo que hay en el catálogo—, pero la ficha los presenta
como si fueran un esquema más de la lista, con su guion de relleno delante.

### Las partes: cuatro moldes

- **Sin partes:** 25 arquitecturas. La unidad no se subdivide.
- **Partes fijas, una vez cada una:** copla de arte mayor, copla real, décima ×2, novena ×2,
  seguidilla compuesta y chamberga, sextilla doble, soneto. Se leen «N versos ×2».
- **Partes que reutilizan otra forma:** 7 arquitecturas —el soneto reutiliza cuarteto y terceto;
  la copla real, la quintilla; la novena, ambas; las sextinas, la sextina-estrofa—. **Es el dato
  más pedagógico del catálogo y hoy no se muestra.**
- **Partes con jerarquía y ciclo:** villancico ×2, zéjel y la canción sin rima. La estructura tiene
  contenedores (`Ciclo de copla y estribillo` → `Copla` → `Mudanza` + `Enlace`), y el árbol se pinta
  hoy con nombres y rangos, sin decir que el ciclo se repite ni dónde vuelve el estribillo.

### La repetición: no es una norma, son las respuestas de una pregunta

Las nueve repeticiones del catálogo son de dos clases distintas y la ficha las mezcla bajo el
mismo epígrafe:

- **Norma de la forma:** las tres sextinas —«Palabras finales repetidas», `definitoria`—.
- **Alternativas entre las que el editor elige:** villancico y zéjel —«Se repite entero» / «Se
  repite solo en parte» / «No, no vuelve a aparecer»—. Son las opciones de la pregunta
  `repeticion/realizacion`, no propiedades de la arquitectura.

## La propuesta: siete perfiles de ficha

Cruzando los tres inventarios, las 57 arquitecturas caen en siete perfiles. El perfil no se
escribe en el catálogo: **se deriva**, igual que `grid-rows.ts` deriva las filas del editor. Un
cambio en el modelo cambia el perfil solo.

### El recurso común: la rejilla de posiciones

Una fila por dimensión, una columna por verso. Es lo que el demarcador ya insinúa y lo que hace
identificable una forma en una secuencia real.

```
Soneto · endecasilábica consonante                              14 versos

 verso   1    2    3    4     5    6    7    8     9   10   11    12   13   14
 medida ┌11┐┌11┐┌11┐┌11┐  ┌11┐┌11┐┌11┐┌11┐  ┌11┐┌11┐┌11┐  ┌11┐┌11┐┌11┐
 rima   │ A││ B││ B││ A│  │ A││ B││ B││ A│  │ C││ D││ C│  │ D││ C││ D│
        └──┘└──┘└──┘└──┘  └──┘└──┘└──┘└──┘  └──┘└──┘└──┘  └──┘└──┘└──┘
        └── cuarteto ──┘  └── cuarteto ──┘  └─ terceto ─┘  └─ terceto ─┘
             rima como el Cuarteto endecasílabo →        ← y como el Terceto
```

Tres cosas que hoy no se dicen y aquí se dicen solas: los cuartetos son **dos bloques**, las
partes ocupan **estos** versos, y su rima **es la de otra forma del catálogo**, enlazada.

Una forma con partes con nombre dentro del esquema —la canción— usa la misma rejilla y la banda
inferior toma los nombres de `esquema_rima_posiciones.seccion`:

```
 verso   1    2    3    4    5    6    7    8    9   10   11   12   13
 medida  7    7   11    7    7   11    7    7    7    7   11    7   11
 rima    a    b    C    a    b    C    c    d    e    e    D    f    F
        └────────── fronte ──────────┘ └esl┘ └────────── sirima ─────────┘
```

Una serie cíclica dibuja **el ciclo**, no la serie, y marca el enlace:

```
Romance · octosilábica                                        serie abierta

 medida  8    8              ⟳ el ciclo se repite hasta el final de la serie
 rima    –    a  ──────┐
                       └──→  la misma asonancia en todos los versos pares
```

Un repertorio libre dibuja la indeterminación en vez de esconderla en una frase:

```
Silva · libre                                                 serie abierta

 medida  ?    ?    ?    ?    ?   …     cada verso: 7 u 11
                                       lo fija la realización, no la norma
 rima    consonante de orden libre · admite versos sueltos
```

Y una posición con alternativa la enseña como alternativa —lo que el demarcador hoy pinta mal—:

```
Seguidilla gitana                                                 4 versos

 medida  6    6   10/11/12   6
```

### Los siete perfiles

| Perfil | Arqs. | Qué se pinta |
|---|---|---|
| **1. Estrofa de disposición elegible** | 22 | Rejilla de la unidad + **tira de disposiciones** abiertas, ordenadas por modalidad, cada una con su rejilla mínima y su denominación |
| **2. Serie con ciclo** | 10 | Rejilla del ciclo + marca de repetición + el enlace dibujado |
| **3. Estrofa compuesta de partes** | 13 | Rejilla con bandas por sección; cada banda enlaza a la forma que reutiliza |
| **4. Estancias que se declaran** | 3 | Rejilla en hueco («la primera estancia lo fija») + la regla de identidad, dicha **una vez** |
| **5. Composición con ciclo de estribillo** | 3 | Diagrama de la composición: `cabeza → [copla → estribillo]…`, con las alternativas de represa como preguntas, no como normas |
| **6. Serie de medida o rima abiertas** | 5 | Sin rejilla: repertorio de medidas + restricciones en lista + rasgos con su escala |
| **7. Combinatoria de variedades** | 1 | Tabla de las 7 variedades del sexteto-lira, cada fila con su medida y su rima; los códigos internos `M1…M5` y `R1…R3` **dejan de salir a la web** |

Suman 57, y es el reparto que produce hoy `perfilDeArquitectura` sobre la base en vivo. El perfil
2 son romance ×4, endecha real ×3, terceto encadenado ×2 y la silva de pareados regulares; el 3,
copla de arte mayor, copla real, décima ×2, novena ×2, seguidilla compuesta y chamberga, sextilla
doble, soneto y las tres sextinas; el 6, las dos silvas irregulares, la endecasilábica, el
endecasílabo suelto y la copla de pie quebrado. El pareado sí dibuja rejilla —dos versos, con su
repertorio de nueve medidas recortado a `4–14` en la casilla—, así que queda en el perfil 1.

Los códigos internos merecen su propia línea: hoy `/formas/sexteto-lira` publica «M1», «M2», «R1»
y «R2» como si fueran nombres de esquema, y las siete variedades repiten en prosa lo que la tabla
diría en una línea («7-11-7-11-7-11 con rima ababcc»).

### El principio que ordena la ficha

**Separar lo que la norma fija de lo que fija la realización.** Es la lengua de la ontología
—declarar lo que la norma no fija— y es lo que un editor necesita para anotar. Cada arquitectura
quedaría en tres zonas:

1. **Lo fijo**: la rejilla, la extensión, las partes.
2. **Lo elegible**: las disposiciones alternativas, las medidas del repertorio, las variedades,
   las represas. Con su modalidad a la vista —`habitual`, `admitida`, `excepcional`—, que es lo que
   dice cuál esperar.
3. **Lo que se observa después**: los rasgos, con sus límites (`hasta 2 posiciones`).

Hoy las tres están mezcladas: «Rasgos que admite» y «Rima» son zonas 3 y 2 con el mismo peso
visual, y la zona 1 no existe.

## Qué se tocó

1. **Tres migraciones que amplían las proyecciones**, todas aditivas y sin cambiar un solo dato:
   - `20260812140000_las_rpc_publicas_envian_la_estructura`: posiciones y opciones métricas con
     las sílabas ya resueltas, `tipo_secuencia` y `medida_uniforme`, la modalidad de los esquemas
     de rima y de las variedades, `posiciones_max` de los rasgos, `seccion_tratada_id` de los
     grupos —por el que el servidor ya filtraba sin recibirlo— y una clave nueva,
     `posicionesRimaCompletas`, con la clase de rima y el verso suelto. Y en el demarcador,
     `alternativa` y `opcional` en las posiciones, `rol` en las opciones y la sección de las
     posiciones de rima.
   - `20260812150000_la_parte_reutiliza_lleva_a_su_forma`: qué forma hay al otro lado de una
     parte reutilizada, para poder enlazarla.
   - `20260812160000_la_parte_reutilizada_trae_tambien_su_medida`: y su medida y su rima, porque
     al dibujar salió que el cuerpo de la seguidilla compuesta y la estrofa de las sextinas se
     quedaban en blanco.

   **`posicionesRima` se quedó exactamente como estaba**, con su filtro y su orden, y lo nuevo
   viajó en claves nuevas: `main` comparte esta base y lee esa clave para nombrar las partes de un
   esquema. Sin filtro habría rotulado «Null, versos 1-4» hasta el siguiente despliegue. Las tres
   guardas **ejecutan** la función que tocan.

2. **`src/lib/metrica/rejilla.ts`**, puro y probado: recibe posiciones, secciones y extensión, y
   devuelve la rejilla o `null`. Devolver `null` es una respuesta legítima —la silva no tiene
   posiciones y fingirle una sería mentir—, y de ahí sale el perfil 6. `perfilDeArquitectura` vive
   ahí mismo y se deriva; no hay una columna que lo declare.

3. **`MetricPositionGrid.svelte`**, que lo dibuja, consumido por la ficha, por
   `DemarcadorResultCard` y por el recuadro de la norma del editor V2.

4. **La ficha, rehecha por zonas**: la rejilla arriba bajo «Cómo se dibuja», después lo elegible
   —con la modalidad de cada disposición a la vista y una minirrejilla por alternativa— y al final
   los rasgos. Las disposiciones ya no están plegadas.

5. **Los tres defectos**: el `undefined` de las repeticiones —que además dejó de mezclar la norma
   de la sextina con las respuestas del villancico—, las alternativas del demarcador y las partes
   fundidas de `partesDe`, que ahora distingue bloques y por fin enseña los dos cuartetos del
   soneto.

## La ficha por dimensiones

Lo anterior se vio en pantalla y **no bastaba**. La figura resolvía la estructura, pero se había
*sumado* a lo que ya estaba: la medida salía dibujada y otra vez como nombre, el reparto en partes
tres veces —en las bandas, en la lista de partes y en la glosa del esquema—, y en el soneto la
estructura llegaba a decirse cuatro veces. Añadir una figura buena a una plantilla que repetía no
quitaba repeticiones: las aumentaba.

La ficha se rehízo entera el 12 de agosto de 2026, en
`src/lib/components/metrica/PublicArchitectureCard.svelte`. **Una fila por dimensión** —extensión,
medida, rima, partes, repetición, rasgos—, cada una con la marca de quién la fija:

| | |
|---|---|
| **la fija la norma** | extensión, medida, partes, repetición |
| **la elige la realización** | disposición de rima, medida de repertorio abierto, variedades, represa |
| **se observa al anotar** | los rasgos que pueden no darse |

Cuatro decisiones que salieron de mirarla con el IP:

**La rima es una dimensión, con sus partes dentro.** El soneto elige una disposición para sus
cuartetos **y otra** para sus tercetos, y eso no se entendía. Ahora cada parte lleva su rótulo y su
cuenta —«Cuartetos — se elige una de 2», «Tercetos — se elige una de 4»— sin salirse de la
dimensión ni perder la alineación de las columnas, que es lo que deja ver que los tercetos
empiezan en el noveno verso. Se descartaron dos alternativas: una fila de tabla por parte, que
rompe esa alineación, y dibujar una realización entera con las demás como intercambios, que
depende de que la modalidad esté bien puesta y elige arbitrariamente cuando todas son `admitida`.

**El reparto es de la rima.** Las bandas dicen qué disposición cubre qué versos, así que dejaron de
ser una dimensión aparte.

**La glosa no repite la notación para colgarse de ella.** Se pide con un enlace bajo su grupo y se
abre **como una columna más de la rejilla**. No flota: un cuadro absoluto dentro de un contenedor
con `overflow-x` se recorta contra el borde y arrastra consigo la barra de scroll.

**Los rasgos son tres cosas distintas y la base ya lo sabía.** Lo que las separa es su grupo de
elección, que la proyección no enviaba —de ahí la migración `180000`—: si el rasgo no tiene grupo,
la arquitectura lo **afirma** y es norma; si lo tiene con varias opciones y una sola respuesta, sus
valores son **excluyentes** —la silva libre es de densidad `Total` **o** `Mayoritaria`, y en dos
líneas seguidas parecía que era las dos—; si es una opción que puede quedarse vacía, es un **sí o
un no**. Y donde hay variedades no hay dos preguntas: el sexteto-lira las ofrece con su medida y su
rima juntas, porque separarlas obligaba a recomponer siete parejas de memoria.

## Lo que salió al dibujarlo

Era lo que se esperaba de un dibujo: enseña lo que una frase tapa. Nada de esto se ha tocado,
porque son datos.

**Ocho esquemas tenían la caja de sus letras en desacuerdo con su notación.** `clase_rima`
guardaba una cosa y `notacion` otra, y la rejilla dibuja la primera:

| Esquema | Notación | Clases guardadas |
|---|---|---|
| endecha real · cruzada | `-a-A` | `-a-a` |
| endecha real · abrazada | `abbA` | `abba` |
| endecha real de cinco | `abbaA` | `abbaa` |
| romance endecasilábico | `[-A]…` | `-a` |
| silva de pareados regulares | `[aA]…` | `AA` |
| canción regular de 13 | `abCabC:cdeeDfF` | `ABCABCCDEEDFF` |
| terceto encadenado octosilábico | `[aba]…` | `ABA` |
| zéjel | `a(a) \| [bbba]…` | `AABBBA` |

La convención está escrita en la ficha —mayúscula es arte mayor— y eran dos criterios distintos
aplicados al mismo hecho: unos esquemas marcaban el arte en la clase y otros solo en la notación.
No era un empate: **la notación acertaba en los ocho**, comprobado uno a uno contra su esquema
métrico, porque en todos ellos la medida cambia de verso a verso —o es toda de arte menor, en el
zéjel y el terceto encadenado octosilábico— y la clase lo ignoraba.

**Corregido** el 12 de agosto de 2026 por
`20260812170000_la_clase_de_rima_marca_el_arte_del_verso`: 23 posiciones, escritas como la
secuencia completa de cada esquema para que se lean igual que se lee su notación. Los otros 62
esquemas con posiciones ya cuadraban, y ahora cuadran los 70. Para que no vuelva a separarse, la
comprobación es permanente: **`D14` de `npm run audit:metrica`**.

De ahí salió además un corolario en código. Si la caja marca el arte y no la clase, **quien cuente
clases no puede distinguirla**: el pareado `aA` de la silva es una sola rima, no dos, y `D13`
—que contrasta un esquema concreto contra el criterio de su abierto— las contaba aparte. Ahora
compara sin caja. El criterio, escrito, en
[criterios de nivel § 3.3](../criterios-de-nivel.md).

**Ocho arquitecturas no declaraban su régimen de rima, y la ficha no lo enseñaba en ninguna.**
`arquitecturas_forma.tipo_rima_id` estaba poblado en 49 de las 57 y solo salía a nivel de forma, en
la cabecera: la canción decía qué acota su rima sin decir que es consonante, que es lo primero que
hace falta saber. Al enseñarlo aparecieron los ocho huecos.

Mirándolos de cerca **no eran ocho**. `esquemas_rima` declara también su régimen, y lo tenía en 81
de 87: el dato no faltaba, vivía en el nivel de abajo. De ahí salió el criterio que ahora rige
—[§ 3.3 de los criterios de nivel](../criterios-de-nivel.md)—: **se declara siempre, arriba si el
régimen es uno y en cada disposición si dentro de la arquitectura varía**. Dos de los ocho estaban
bien callados —el villancico, que mezcla consonante y asonantada, y la canción sin rima, con el
cuerpo sin rimar y el pareado final consonante—; los seis restantes se corrigieron con
`20260812190000_toda_arquitectura_declara_su_regimen_de_rima`, con la fuente al lado de cada uno:

| Qué | Régimen | Fuente |
|---|---|---|
| Redondilla heptasílaba y hexasílaba | consonante | Jauralde registra las tres medidas como la misma estrofa; Morley y Bruerton, «ocasionalmente de seis o siete sílabas» |
| Endecha real hexasílaba | asonante | Navarro Tomás § 207: «se generalizó la forma asonantada a manera de romance» |
| Endecasílabo suelto | sin rima | Morley y Bruerton, «endecasílabos sin rima»; Domínguez Caparrós 2014, p. 232 |
| Endecha real de cinco versos | consonante | Navarro Tomás § 207 llama «redondilla heptasílaba» a la variedad de sor Juana, y él reserva ese término para la consonante |
| `suelta` de la endecha, y por contraste sus hermanas | sin rima / asonante | § 207: «lo habían empleado en versos sueltos, abcD» |

La comprobación es permanente: **`D15`**. Y llevó a dos huecos más de proyección, cerrados con
`200000` y `210000`, porque la RPC no enviaba el régimen de las disposiciones ni el vocabulario con
que escribirlo, y el villancico seguía leyéndose «sin declarar» después de declararlo.

**Nueve esquemas abiertos no dicen nada más que «distribución variable».** Ya estaba anotado
arriba; ahora se ve, porque su fila de rima queda vacía. Los tres sextetos, cuatro sextillas, la
copla de pie quebrado y la endecha suelta.

**Dos arquitecturas no declaran la medida de una parte y la heredan.** El cuerpo de la seguidilla
compuesta y la estrofa de las sextinas la toman ya de la forma que reutilizan, que es lo correcto,
pero conviene saber que no la declaran ellas.

**El villancico no tiene rejilla de unidad y el zéjel sí.** No es un fallo del dibujo: el zéjel
declara un esquema de la unidad entera —cabeza, mudanza y vuelta, seis posiciones— y el villancico
solo los de su mudanza. Es la misma asimetría que la [cuestión 6 y 7 del
villancico](../cuestiones-para-el-ip.md#villancico).

**Y una que no venía del dibujo sino de ir a comprobarlo: el informe de conformidad llevaba un día
diciendo «0 defectos» sin haber mirado ninguna opción.** `opciones_eleccion_metrica` dejó de ser
una tabla el 11 de agosto —hoy es una vista derivada de `opciones_eleccion_derivadas()`— y
`audit:metrica` lee un **volcado de datos**, que por definición no contiene vistas. Leía cero
opciones y las reglas que dependen de ellas —`D5`, `D6`, `D12` y las matrices de opciones— corrían
en vacío. Ahora esa relación se pide por consulta, y el informe **se planta si el modelo se queda
sin opciones** en vez de dar un aprobado silencioso. Con las 402 a la vista el resultado sigue
siendo 0 defectos, así que no tapaba nada; pero podía haberlo tapado.

## Lo que no se decide aquí

- **La `suelta` de la endecha real** —ciclo con notación y cero posiciones— no se puede dibujar.
  Es el punto 4 de lo pendiente y espera decisión del IP.
- **Los veintiún nombres de la misma medida.** `esquemas_metricos.nombre` sigue estando escrito a
  mano —«Endecasílabo repetido», «Ocho endecasílabos», «Tres endecasílabos»—; ahora la rejilla dice
  lo mismo dibujado, así que esos nombres pasan a ser glosa y podrían unificarse o retirarse.

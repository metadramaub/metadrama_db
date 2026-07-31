# Meta-modelo métrico

Estado: vigente · 31 de julio de 2026

Este documento define **qué tipos de entidad componen un dominio métrico y qué reglas los
gobiernan**, sin comprometerse con ninguna tradición de verso concreta. Es la capa
reutilizable: cualquier proyecto que quiera registrar y comparar el verso de un corpus puede
adoptarla y poblarla con su propia métrica.

No contiene ni un solo ejemplo español. La aplicación de este meta-modelo a la métrica
española y las decisiones tomadas para el corpus de METADRAMA están en
[la ontología métrica del proyecto](./ontologia-metrica.md), que cita este documento en vez
de repetirlo.

## 1 · Las tres capas

Un dominio métrico formalizado tiene tres capas, y confundirlas es el error que hace
inservible el resultado para cualquiera que no sea su autor.

| Capa | Qué contiene | Quién la puede reutilizar |
| --- | --- | --- |
| **Meta-modelo** | Tipos de entidad y reglas que los gobiernan | Cualquiera |
| **Catálogo de una tradición** | Las formas, metros y esquemas de una métrica concreta | Quien trabaje esa tradición |
| **Decisiones de un corpus** | Qué repertorios se cierran, qué es normal y qué desviación aquí | Nadie más, y por eso debe estar marcado |

La tercera capa es la que más se olvida. Cuando un proyecto decide que un repertorio de
esquemas está cerrado, o que cierta realización es residual, eso **no es un hecho de la
tradición**: es una decisión de alcance. Si no queda marcada en el dato, quien reutilice el
catálogo hereda esas decisiones creyendo que describe la métrica.

## 2 · El objeto

El meta-modelo describe **la norma de un pasaje de verso y lo que ese pasaje hace con
ella**. Presupone tres cosas, y solo tres:

1. El texto es una **sucesión lineal de versos** numerables.
2. Un verso tiene una **medida** comparable con la de otro verso.
3. Dos versos pueden **corresponderse** por su rima.

Todo lo demás es catálogo. Si una tradición mide por pies y no por sílabas, o si su rima es
aliterativa en vez de final, el meta-modelo no cambia: cambia lo que se declara como metro y
como esquema de rima.

## 3 · La secuencia y la unidad

La **secuencia** es el pasaje que el editor delimita por sus versos inicial y final, y el
nivel al que se asigna una identidad métrica. Dentro de una secuencia hay **una sola forma y
una sola arquitectura**.

Una forma define una **unidad**. La secuencia contiene una o más **realizaciones** de esa
unidad, y cuántas contiene **no se declara**: se deriva del rango y de la extensión que la
arquitectura declara.

| Nivel de la forma | La unidad es | La secuencia contiene |
| --- | --- | --- |
| Estrofa | la estrofa | N realizaciones |
| Composición de estructura fija | el poema completo | N realizaciones |
| Serie no estrófica | la serie abierta | exactamente una, de extensión libre |

De aquí sale la regla que más trabajo ahorra: **el catálogo nunca contiene a la vez una
forma y su serie**. Una sucesión de estrofas iguales es una secuencia con N unidades, no
otra forma.

> **Definición operativa de unidad.** La unidad es la realización que no cuelga de ninguna
> otra y no realiza ninguna sección. Todo lo demás cuelga de ella.

Hay dos repeticiones y conviene no confundirlas:

- **repetición del pasaje** — cuántas unidades hay: se deriva del rango;
- **repetición interna** — cuántas veces se repite una parte dentro de la unidad: pertenece
  a la arquitectura.

Una sección expresa siempre la segunda, nunca la primera.

## 4 · El procedimiento de nivel

Toda decisión de modelado se reduce a tres preguntas encadenadas.

> **1 · ¿Admite la norma que esto varíe de una unidad a otra dentro de la misma secuencia?**
>
> - Sí → es un **esquema**, una **variedad** o un **rasgo**.
> - No, pero si cambiara seguirías llamándolo igual → es una **arquitectura**.
> - No, y si cambiara tendrías que abrir otra secuencia → es otra **forma**.

La pregunta se responde desde la norma, no desde lo observado. Si la norma no admite la
variación y aun así aparece, no es una alternativa: es una desviación, o el final de la
secuencia.

> **2 · ¿Lo fija la norma o lo declara el pasaje?**
>
> Lo que fija la norma vive en el catálogo. Lo que declara el pasaje vive en la respuesta del
> editor.

> **3 · Si vive en el catálogo, ¿es constante en toda la secuencia o posicional dentro de la
> unidad?**
>
> Constante → **arquitectura**. Posicional → **esquema**.

De ahí sale también el alcance de las preguntas: lo que puede variar se pregunta por unidad;
lo que es constante ya lo dice la arquitectura y no se pregunta.

### Los dos contrapesos

Dos criterios opuestos que hacen falta a la vez, porque cada uno corrige el exceso del otro.

**Un nombre tradicional no crea una forma.** Cuando una tradición nombra una realización
concreta dentro de una forma que ya existe, eso es una **variedad reconocida** o una
**denominación**. La forma se reserva para lo que tiene norma propia.

**Pero la genealogía separa lo que la estructura acerca.** Dos formas pueden coincidir en
extensión y régimen de rima y no ser la misma cosa si nacen de principios constructivos
distintos. Ese parentesco se declara con una relación tipada, que no transmite propiedades.

> **El nombre no basta para separar, y la estructura no basta para unir.**

## 5 · Principio de asignabilidad

> **Todo lo que recibe un nombre debe poder registrarse y recuperarse, viva en el nivel que
> viva.**

El nivel decide *dónde* se guarda el dato y *cómo* se pregunta; nunca decide *si* se puede
decir. Este principio permite que una duda abierta no bloquee el modelo: se elige la
representación más reversible y el nombre sigue siendo asignable mientras tanto.

Su corolario práctico: **una entidad que puede recibir un nombre debe poder ser destino de
una denominación**. Si el modelo admite denominar formas, arquitecturas y esquemas pero no,
por ejemplo, valores de rasgo, entonces mover un hecho a un valor de rasgo le quita el
nombre. Eso es una pérdida, no una simplificación.

## 6 · Las entidades

### Forma

Una identidad métrica **asignable a una secuencia**. Define una unidad y puede tener varias
arquitecturas. **No hereda nada de nadie.**

Dos ejes independientes la califican:

| Eje | Valores | Qué dice |
| --- | --- | --- |
| Tipo de registro | forma · tramo sin forma | Si existe o no una norma |
| Grado de especificación | general · específica | Cuánto acota la norma |

Una **forma general** está definida por rasgos amplios que no llegan a fijar una identidad
cerrada; es una forma plena, con norma, secciones y esquemas, a la que solo le falta
especialización. Una **forma específica** fija esa norma. El identificador debe ofrecer la
forma más específica que encaje: cuando ninguna corresponde, la general es la respuesta
correcta, no un consuelo.

### Tramo sin forma

Declara que un pasaje **no tiene norma reconocible**. No es una forma: no tiene
arquitectura, esquemas ni variedades, y no compite como candidata.

Que no haya norma no impide describir. Lo que se pierde no es la capacidad de describir sino
la de comparar contra un modelo, y por eso lo que se registra ahí es **observación directa**,
nunca elección ni desviación.

### Arquitectura

Una realización estructural admitida por una forma: qué extensión tiene la unidad, cómo se
divide en secciones, cuántas veces se repite cada una dentro de la unidad y cómo enlaza la
rima los bloques entre sí. **Es constante en toda la secuencia.**

Dos arquitecturas de una forma difieren en la forma del recipiente, no en lo que lo llena.

### Metro

Un **tipo de verso**: su medida y, cuando la tiene, su estructura interna.

```text
metro
├── medida                   la unidad de cómputo de la tradición
├── tipo                     simple | compuesto
└── segmentos y cesura       solo los compuestos
```

Lo derivable no se almacena: cualquier clasificación que se siga de la medida —tramos de
arte, categorías de longitud— se calcula.

**Lo que altera el cómputo de la medida pertenece al metro, no al ritmo.** En las tradiciones
donde la terminación del verso modifica su cuenta, esa terminación es parte de cómo se mide y
debe modelarse con el metro, aunque el resto del ritmo quede fuera de alcance.

### Esquema métrico

La sucesión o el conjunto de metros dentro de una arquitectura. El orden importa y no se
reduce a un conjunto de medidas. Puede ser una secuencia fija, un conjunto permitido, una
secuencia repetible o abierto; sus posiciones pueden ser opcionales o alternativas.

### Esquema de rima

La disposición de las correspondencias de rima, guardada en dos planos:

- la **notación** legible, que es documentación;
- el **comportamiento computable**: posiciones con su clase, versos sin correspondencia
  esperados, enlaces entre posiciones y restricciones combinatorias cerradas.

Esa separación es la que permite formalizar los encadenamientos entre unidades sin que la
letra suelta tenga que expresarlo todo. **El timbre concreto de una rima no forma parte de la
identidad de la forma**: es un rasgo observado.

### Sección

Una parte **del interior de la unidad**, con extensión y repetición propias.

Una sección no existe nunca para decir que la unidad se repite, ni para ser la unidad.

Una sección puede **reutilizar la arquitectura de otra forma** en lugar de copiarla. Copiar
obliga a mantener el mismo repertorio en varios sitios y rompe la comparación.

### Repetición

Repite material que la rima no puede expresar: permutaciones léxicas, reapariciones de un
bloque. Cuando el orden importa, declara sus posiciones.

### Variedad

Una **pareja de esquema métrico y esquema de rima que el catálogo reconoce**, cuando no todas
las parejas posibles se dan. No crea forma ni arquitectura: es una alternativa con nombre
dentro de la misma norma.

Sin esta entidad, dos listas independientes ofrecerían el producto cartesiano completo —la
mayoría inexistente— o habría que inventar arquitecturas artificiales.

### Rasgo

Una **propiedad predicable de un tramo**, sin posición fija, posible en más de una forma.

Un rasgo se vincula a una arquitectura declarando **con qué modalidad** interviene:
definitoria, habitual, admitida o destacable. Ahí vive el matiz cualitativo, y por eso no hace
falta traducir «mayoría» a umbrales inventados.

Cuando el matiz tiene grados, el rasgo declara **valores cerrados y ordenados** en vez de una
frase. Escribirlo como texto libre lo haría incomparable, porque cada forma inventaría su
cadena.

> **Prueba de que un rasgo está bien puesto: que dos formas distintas puedan nombrar el mismo
> valor.**

Prueba de contraste: si necesita una posición, no es un rasgo, es parte del esquema. Un rasgo
booleano repetido N veces para señalar qué posiciones cumplen algo es un esquema disfrazado.

### Elección

Lo que el catálogo **pregunta al editor** cuando la respuesta no se puede derivar y la
diferencia tiene valor analítico.

> **Toda opción apunta por clave foránea a una entidad ya normalizada.** Nunca a texto libre.

No es una capa de atributos: decide qué parte del catálogo se presenta como pregunta. Y una
elección **nunca es una desviación**: dos alternativas admitidas son dos respuestas ordinarias
a la misma pregunta.

### Respuesta que define la norma

Algunas formas no fijan su esquema de antemano: lo fija la primera realización y las demás lo
repiten. El editor no elige entre alternativas catalogadas, **declara la norma de ese
pasaje**, y no se crea una entidad nueva por cada esquema observado.

Lo que la distingue de una elección ordinaria es **cuántas veces puede responderse distinto**,
no dónde se pregunta. Por eso se marca con un indicador propio y no con un alcance nuevo: la
pregunta se sigue haciendo donde le corresponde, y lo que se añade es que todas sus
realizaciones deben coincidir dentro del ámbito que las contiene.

Se responde en cada realización y no una sola vez, a propósito: así una realización que se
salga podrá registrarse como desviación localizada en vez de obligar a partir la secuencia.

### Denominación

Otro nombre de algo ya formalizado, apuntando **al nivel exacto que nombra**. Declara además
su relación temporal con el corpus: un nombre aplicado retrospectivamente no es equivalente a
uno coetáneo, y registrarlo como tal falsearía el testimonio.

Una denominación no es asignable y no crea nada.

### Tradición

El ámbito histórico del que procede una forma. Es una **pertenencia, no una herencia**: no
transmite rasgos estructurales y no organiza el selector. Una forma puede pertenecer a más de
una, y eso ya expresa que nació en una y se aclimató en otra.

### Relación

Un vínculo tipado entre dos formas: taxonomía, composición, derivación, sucesión histórica,
contraste. **Ninguna convierte a una forma en padre de otra ni transmite propiedades.**

### Desviación

Lo que la norma no prevé y aun así ocurre, localizado por rango y dimensión, apuntando a las
mismas entidades normalizadas del catálogo.

La diferencia respecto de la norma se **deriva de la comparación**: no hace falta una etiqueta
que nombre cada tipo de discrepancia.

## 7 · Norma y realización

La **norma** es lo que una forma es y admite; vive en el catálogo. La **realización** es lo
que un pasaje concreto hace.

> **Regla de comparabilidad.** Un hecho de la realización debe quedar registrado de la misma
> manera venga de donde venga: de lo que la arquitectura fija, de una respuesta del editor o
> de una desviación observada. El origen se guarda como un dato más; **no como el camino que
> hay que desandar para saber qué dice el pasaje.**

Es la regla que separa un modelo consultable de uno que solo su autor sabe leer. Un modelo
que guarde únicamente punteros al catálogo obliga a resolver la norma cada vez que se
pregunta algo tan simple como qué mide un verso, y esa resolución acaba viviendo en el código
de análisis, distinta en cada consulta.

De ella se siguen dos exigencias:

1. La realización se **materializa** al guardar, con la granularidad del verso, que es la
   unidad mínima común a todas las dimensiones.
2. Cada hecho materializado declara su **procedencia**: derivado de la norma, respondido por
   el editor u observado como desviación.

Rige además una **convención de mundo cerrado**: una realización guardada sin desviaciones se
considera conforme con su norma y con las respuestas registradas. La ausencia no significa
pendiente ni desconocido. La ausencia de una respuesta obligatoria, en cambio, impide
guardar: eso no se interpreta como conformidad.

## 8 · Puntos de extensión

Lo que sigue **no forma parte del meta-modelo** pero tiene su sitio declarado, para que
añadirlo no obligue a rehacerlo. Declarar dónde encajaría es distinto de dejar tablas vacías:
un hueco que nadie ha probado es una conjetura, y aquí solo se fija la restricción que la
extensión tendría que respetar.

### Ritmo acentual

Un dominio que quiera registrar el ritmo lo hará en dos sitios distintos, y no en uno:

- el **tipo rítmico como propiedad del metro** —una clasificación de los versos de una medida
  según su perfil acentual— cabe hoy sin cambios, como variedad del metro o como rasgo;
- el **patrón acentual de un verso concreto** exige que el verso sea una entidad de la capa de
  realización.

> **El ritmo nunca es un rasgo de la forma.** «Composición de versos de tal perfil rítmico»
> confunde una propiedad de cada verso con la norma de un poema, y es exactamente el error que
> este meta-modelo deshace.

La materialización por verso descrita en el apartado 7 deja abierta esa puerta sin coste: si
el grano de la realización es el verso, el patrón acentual es una columna más.

### Error frente a desviación

El meta-modelo distingue norma y desviación, pero no distingue **una licencia del autor de un
error de transmisión o de una laguna del testimonio**. Son tres cosas y solo hay dos
categorías.

Un dominio que edite textos con tradición manuscrita o impresa necesitará la tercera, y su
sitio es la desviación: no un tipo nuevo de entidad, sino una calificación de su causa. Lo que
no puede hacerse es tratarla como una dimensión más de la norma, porque el error no es una
propiedad del verso sino del testimonio que lo transmite.

### Agrupamientos para el análisis

Contar por categorías del estudio —familias de formas, conjuntos temáticos— es una decisión
analítica, no métrica. Su sitio es una capa de proyección versionada con el informe que la
usa. El meta-modelo no congela una elección analítica dentro del modelo del objeto, y las
relaciones tipadas dicen, con más precisión que una pertenencia, qué une a dos formas.

## 9 · Los seis errores que este meta-modelo evita

1. **Convertir una variante en una forma.** Un esquema distinto no es otra forma.
2. **Convertir una observación en una definición.** Que una forma admita algo no significa que
   un pasaje lo tenga.
3. **Confundir la unidad con el pasaje.** Una sucesión de unidades iguales no es una forma
   distinta.
4. **Hacer que la taxonomía gobierne el comportamiento.** Reordenar nombres no puede cambiar
   cálculos ni lo que el editor puede elegir.
5. **Usar la herencia para no decidir.** Un campo vacío no significa «lo mismo que el padre».
6. **Codificar el mismo fenómeno en niveles distintos según la forma.** Es lo que hace
   incomparables las cifras entre obras y autores, y el que más cuesta detectar: exige
   contrastar el catálogo por rasgos y no por nombres.

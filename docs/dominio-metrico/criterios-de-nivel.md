# Criterios de nivel del dominio métrico

Estado: vigente · 30 de julio de 2026

Este documento responde a una sola pregunta: **ante un hecho métrico observado, ¿en qué
nivel del catálogo debe registrarse?** Presupone la
[ontología del verso español](./ontologia-verso-espanol.md), que define qué es cada
fenómeno, y el procedimiento de nivel de [la implementación](./implementacion-metrica.md);
aquí se aplica caso por caso y se fijan las reglas comprobables.

Las reglas numeradas del apartado 6 se verifican contra los datos poblados. El resultado
vigente está en [informe-conformidad-catalogo.md](./informe-conformidad-catalogo.md) y se
regenera con:

```bash
npm run audit:metrica                       # contra la base enlazada
npm run audit:metrica -- --dump copia.sql   # contra un volcado local
```

## 1 · El procedimiento

Ante un hecho observado, la primera pregunta es siempre la de la variación, y se responde
**desde la norma, no desde lo observado**:

```text
¿Admite la norma que varíe de una unidad a otra dentro de la misma secuencia?
├── Sí ──────────────────────────────────► esquema, variedad o rasgo,
│                                          y elección si hay que preguntarlo
├── No, pero seguiría llamándose igual ──► ARQUITECTURA
└── No, y obligaría a abrir otra secuencia ► otra FORMA
```

Si la norma no admite la variación y aun así aparece, no es una alternativa: es una
desviación localizada, o el final de la secuencia. El límite entre ambas cosas: un cambio
que coincide con el final de una unidad completa y se sostiene abre una secuencia nueva;
un cambio en versos sueltos dentro de unidades regulares es una desviación.

Si el hecho varía, una segunda pregunta decide en qué dimensión vive:

```text
¿De qué habla?
├── de medidas ordenadas o admitidas ──► ESQUEMA MÉTRICO
├── de correspondencias de rima ───────► ESQUEMA DE RIMA
├── de parejas reconocidas de ambos ───► VARIEDAD
├── de material que se repite y la rima no expresa ──► REPETICIÓN
├── de una parte con extensión propia ─► SECCIÓN
└── de una propiedad del tramo sin posición fija ──► RASGO
```

Y una tercera decide si el editor debe intervenir:

```text
¿El catálogo produce una sola respuesta posible?
├── sí → se deriva; NO se crea una elección
└── no → ¿la diferencia tiene valor para el corpus?
    ├── sí → ELECCIÓN, con el alcance que dicte la primera pregunta
    └── no → se deja abierta en la norma y no se pregunta
```

Dos casos quedan fuera del recorrido: si el pasaje no conserva una norma reconocible es un
**tramo sin forma**, y si el hecho solo es otro nombre de algo ya formalizado es una
**denominación**.

## 2 · Prueba discriminante de cada nivel

| Nivel | Prueba | Contraprueba |
| --- | --- | --- |
| Forma | Es asignable y su cambio obliga a cortar la secuencia | Si solo cambia la medida o la rima, no es forma |
| Tramo sin forma | Declara que no hay norma para ese tramo | Si conserva estructura formalizable, es una forma general |
| Arquitectura | Constante en la secuencia; cambia el recipiente | Si varía entre unidades, es esquema |
| Metro | Es un tipo de verso con su medida y estructura interna | Si describe una sucesión, es esquema métrico |
| Esquema métrico | Ordena o admite medidas dentro de una arquitectura | Si la alternativa no es de medida, no le corresponde |
| Esquema de rima | Describe correspondencias entre posiciones | Si describe una propiedad global sin posiciones, es rasgo |
| Sección | Delimita una parte con extensión y repetición propias | Si nunca se materializa por separado, no es sección |
| Repetición | Repite material que la rima no puede expresar | Si es correspondencia fónica, es rima |
| Variedad | Restringe qué parejas de esquemas reconoce el proyecto | Si los dos ejes son libres, no hace falta |
| Rasgo | Se predica de un tramo, sin posición, en más de una forma | Si necesita una posición, pertenece al esquema |
| Elección | No se puede derivar y separa realizaciones con valor | Si el resultado es único, se deriva |
| Denominación | Nombra una entidad ya existente | Si nombra algo no formalizado, falta la entidad |
| Tradición · relación | Sitúa o vincula; nunca se asigna a una secuencia | Si hace falta para clasificar, está mal ubicado |

## 3 · Reglas por dimensión

### 3.1 · Extensión

Se declara una sola vez y en un solo sitio:

- estrofa o composición simple: extensión fija en la arquitectura;
- cualquier estructura con secciones: se deriva de las secciones;
- serie abierta: no se declara.

Cuando existen las dos vías no pueden contradecirse (**D4**). Una extensión fija se
expresa igualando mínimo y máximo, no con un campo aparte.

#### Una arquitectura no cambia la extensión de la unidad de su forma

Fijado el 21 de agosto de 2026, al crear las estrofas de siete, ocho, once y doce versos. **Es un
indicio, no una prohibición**: cuando una arquitectura declara una unidad de extensión distinta a
la de sus hermanas, lo más probable es que no sea una arquitectura sino **otra forma escondida
dentro de la primera**. Así estaban la copla de arte menor —`unidad = 8` dentro de la redondilla,
que mide 4— y la doble sextilla —`unidad = 12` dentro de la sextilla, que mide 6—, mientras el
mismo caso a diez versos ya eran dos formas, la décima y la copla real.

Lo que decide de verdad es **la articulación**: cuántos miembros tiene la estrofa, de qué tamaño, y
si comparten rima. La medida y la disposición son arquitectura. El nombre no decide nada — que la
tradición llame «octavilla» a algo no lo convierte en forma, y que no le dé nombre no se lo quita.

**Tres formas rompen el indicio con razón, y la comprobación las enumera** para que una cuarta se
note (migración `20260821170000`):

| Forma | Por qué |
| --- | --- |
| Décima | La *aumentada* estira el miembro final de cuatro versos a seis y aparece intercalada entre décimas normales: es la misma estrofa creciendo, y las fuentes la describen así |
| Sextina | La doble de Montemayor y la doble petrarquista repiten la composición entera |
| Seguidilla | La simple, la de tres versos, la compuesta, la chamberga y la gitana son la misma forma en extensiones que la tradición nombra por separado, y la compuesta contiene a la simple |

### 3.2 · Medida

Se aplica la pregunta de la variación, no un criterio de nombre.

> ¿Admite la norma que la medida cambie de una unidad a otra?

En una forma **isosilábica la respuesta es no por definición**, y eso cubre la mayor parte
del catálogo. El romance no pasa de octosílabo a endecasílabo a mitad de tirada, y una
tirada de redondillas tampoco cambia de ocho a seis sílabas entre estrofas: si lo hace, o
empieza otra secuencia o hay un anisosilabismo que se registra como desviación.

- **No varía** → **arquitectura**. Las cuatro medidas del romance y las tres de la
  redondilla son arquitecturas de una sola forma.
- **Varía** → **esquema métrico**, y elección por unidad. Solo ocurre en formas
  heterométricas cuya norma no fija las posiciones.

La respuesta es una afirmación filológica sobre el corpus y debe quedar escrita en la ficha
de la forma.

Una medida que solo afecta a algunas posiciones —el pie quebrado— nunca es arquitectura:
es una alternativa posicional del esquema métrico, registrada mediante opciones de metro
con su posición. Repetir un rasgo booleano por cada verso es un esquema métrico disfrazado
(**D7**).

#### Corolario: lo constante no se pregunta

Una alternativa **estructural y constante** en toda la secuencia no debe ser una pregunta:
debe ser una arquitectura. Si el catálogo la admite y no varía, elegirla *es* elegir la
arquitectura, y preguntarla aparte modela el mismo hecho dos veces (**D12**). Por eso el
alcance de secuencia queda reservado a los rasgos, que no tocan la arquitectura: las
vocales de la asonancia del romance o el final esdrújulo del soneto.

La excepción es la **ortogonalidad**: cuando el eje es independiente de otra variación
arquitectónica y combinarlos multiplicaría las arquitecturas sin necesidad. Es el mismo
argumento que justifica las variedades del sexteto-lira. Con tres o cuatro arquitecturas no
aplica; con doce, sí.

### 3.3 · Rima

**Una disposición de rima no crea nunca una arquitectura.** `ababa` y `abbab` son dos
esquemas de la misma quintilla. La arquitectura cambia solo si cambia el recipiente: la
redondilla doble enlazada lo es porque son ocho versos en dos bloques que comparten la rima
exterior, no porque su esquema sea distinto.

El **ámbito** de un esquema de rima es el nivel de la unidad que describe, y debe coincidir
con el de la pregunta que lo ofrece. Si la pregunta distingue solo una parte, el esquema
debe modelar esa parte: los cuatro esquemas de tercetos del soneto pertenecen a la sección
de los tercetos, no a la composición entera (**D5**).

Cuando la norma no fija la disposición hay **una sola vía admitida**: preguntar el esquema
observado como respuesta abierta, validada contra la extensión de la unidad. Los esquemas
vacíos que solo ocupan un hueco en la interfaz no son admisibles (**D2**), y toda
arquitectura debe declarar de algún modo cómo se comporta su rima (**D2b**).

**El régimen de rima se declara siempre, en el nivel que le corresponde.** Consonante, asonante o
sin rima es lo primero que hay que saber de una rima, y el catálogo lo admite en dos sitios: en la
arquitectura y en cada disposición. Va **arriba cuando el régimen es uno** —el soneto es consonante
y se acabó— y **abajo cuando dentro de la arquitectura varía**: el villancico admite `abba` y
`abab` consonantes junto a la asonantada `-a-a`, y la canción sin rima tiene el cuerpo sin rimar y
un pareado final consonante. Reducir esos dos a un valor sería falsearlos, y por eso dejan la
casilla de arriba vacía a propósito. Lo que no vale es que no esté en ninguno de los dos, y eso lo
comprueba **D15**. Ocho arquitecturas lo callaban hasta el 12 de agosto de 2026, cuando la ficha
empezó a enseñarlo y se vio el hueco.

**La caja de la clase marca el arte del verso, no una clase distinta.** `C` y `c` son la misma
rima sobre un endecasílabo y sobre un heptasílabo: así rima el eslabón de la estancia con el
sexto verso, y así rima consigo mismo el pareado `aA` de la silva regular. De ahí dos
consecuencias. La primera: quien cuente clases o alternancias debe hacerlo **sin distinguir
caja**, o inventará clases que no existen. La segunda: la notación que se publica y las
posiciones que se guardan tienen que decir lo mismo, letra por letra y caja por caja, sin contar
los versos sueltos —que la notación escribe con guion y las posiciones dejan sin clase— y eso lo
comprueba **D14**. Ocho esquemas lo incumplían hasta el 12 de agosto de 2026; se vio al dibujar
la rejilla, porque las letras contradecían la notación impresa debajo.

### 3.4 · Unidad, pasaje y secciones

Una forma define una unidad; la secuencia contiene una o más realizaciones de ella. Cuántas
contiene **se deriva del rango**, no se declara.

De ahí que una sección describa siempre el *interior* de la unidad. Una sección cuyo único
contenido es la extensión de la propia unidad no aporta nada y debe retirarse (**D11**): la
redondilla no necesita una sección «redondilla» de cuatro versos. La excepción son las
series, donde la sección repetible describe el ritmo interno de la serie —los tercetos del
terceto encadenado, los pareados de la silva—, que sí es una sola unidad.

Las dos repeticiones no se confunden: la del pasaje se deriva del rango; la interna —los
dos cuartetos del soneto, las seis estrofas de la sextina— pertenece a la arquitectura.

### 3.5 · Composición y reutilización

Cuando una sección realiza una arquitectura ya formalizada de otra forma, **se reutiliza;
no se copia** (**D8**). La novena reutiliza las arquitecturas de la redondilla y la
quintilla; la copla real reutiliza la arquitectura de la quintilla en sus dos secciones.

La composición se declara en dos niveles complementarios. `compuesta_por` vincula las
**formas** y permite leer la relación desde ambos extremos; `arquitectura_referenciada_id`
identifica la **arquitectura concreta** que realiza una sección y de la que hereda lo que no
declare por su cuenta. Ninguna convierte al componente en padre del compuesto, y ninguna
sustituye a la otra: toda reutilización que cruce dos formas debe tener al menos una relación
ontológica entre ellas (**D16**). `subtipo_de` sigue reservado a la taxonomía.

### 3.6 · Propiedades cualitativas

Las propiedades que la bibliografía expresa como predominio o frecuencia —predominan los
versos sueltos, los pareados no organizan sistemáticamente la serie, la serie concluye en
dístico— **son rasgos**. Se predican de un tramo, no dependen de una posición y valen para
más de una forma.

Se declaran como rasgos con sus valores y se vinculan a la arquitectura con su modalidad:
definitoria, habitual, admitida o excepcional. Ahí vive el matiz, y por eso no se traducen a
porcentajes.

Las restricciones del esquema de rima quedan reservadas a reglas combinatorias cerradas y
tipadas: número de clases, máximo de versos consecutivos con la misma rima, prohibición de
pareado final, admisión de versos sueltos. Un literal libre en una restricción genérica es
siempre un rasgo mal ubicado (**D9**).

### 3.7 · Grado de especificación

Son dos ejes independientes y no deben colapsarse en uno:

| Eje | Valores | Significado |
| --- | --- | --- |
| Tipo de registro | forma · tramo sin forma | Si existe o no una norma |
| Grado de especificación | general · específica | Cuánto acota la norma |

Una forma **general** está definida por rasgos amplios y no ha llegado a especializarse: el
sexteto, la copla de pie quebrado. Una forma **específica** fija esa norma: la sexta rima
fija `ABABCC` dentro de lo que el sexteto admite. El demarcador ofrece la más específica
que encaje, y la general es una respuesta legítima cuando ninguna especialización
corresponde.

De ahí que la taxonomía tenga una sola dirección posible: lo específico es subtipo de lo
general, nunca al revés (**D10**).

### 3.8 · Alcance de las preguntas

Se deduce de la primera pregunta: lo que puede variar entre unidades se pregunta **por
unidad**; lo que es necesariamente único en el tramo, **por secuencia**.

El criterio se aplica por igual a formas equivalentes. Dos estrofas isométricas repetibles
no pueden preguntar la medida una por unidad y otra por secuencia salvo que el proyecto
afirme expresamente que una de ellas no varía dentro de la tirada, y lo deje escrito.

## 4 · Regla de homogeneidad

**Un mismo fenómeno se codifica en el mismo nivel en todas las formas.** Cuando una forma
necesite apartarse, la excepción se declara y se justifica en su ficha; no se resuelve en
silencio.

Es la regla que sostiene la comparación cuantitativa. Si la medida vive como arquitectura
en unas formas y como elección en otras sin criterio, «número de arquitecturas distintas
por autor» deja de significar lo mismo en cada forma, y las cifras de uso métrico, autoría
y datación se vuelven incomparables sin que nadie lo advierta.

## 5 · Orden canónico de resolución

Cualquiera que sea el nivel elegido, el análisis debe poder preguntar de manera uniforme
«¿qué medida tiene esta secuencia?» o «¿qué rima presenta esta unidad?». Para que sea
posible, cada dimensión tiene un orden fijo de resolución:

```text
elección registrada
  → esquema declarado por la arquitectura
    → esquema heredado de la sección o de la arquitectura reutilizada
      → derivación de la norma
        → no declarado
```

Modelar una forma de manera que este orden no pueda aplicarse es motivo suficiente para
rechazar la formalización, aunque sea filológicamente defendible.

## 6 · Reglas comprobables

No dependen de una decisión editorial: si una salta, hay algo mal formalizado.

| Regla | Enunciado | Apartado |
| --- | --- | --- |
| D1 | Toda arquitectura declara al menos un esquema, una sección o una variedad | 2 |
| D2 | Ningún esquema de rima está vacío salvo cuando afirma la ausencia de rima | 3.3 |
| D2b | Toda arquitectura declara cómo se comporta su rima | 3.3 |
| D3 | Todo esquema métrico declara posiciones o un conjunto permitido | 3.2 |
| D4 | La extensión declarada no contradice la derivada de las secciones | 3.1 |
| D5 | Ninguna opción distingue menos posiciones que el esquema al que apunta | 3.3 |
| D6 | Los slugs son estables y legibles, sin UUID incrustado | 5 |
| D7 | Ningún rasgo booleano se repite como vector de posiciones | 3.2 |
| D8 | Un componente se reutiliza, no se copia | 3.5 |
| D9 | Ninguna propiedad cualitativa vive como literal libre en una restricción | 3.6 |
| D10 | Ninguna forma general es subtipo de una específica | 3.7 |
| D11 | Ninguna sección existe solo para repetir la unidad | 3.4 |
| D12 | Ninguna pregunta estructural tiene alcance de secuencia | 3.2 |
| D13 | Ningún esquema concreto contradice el criterio de su esquema abierto | 3.3 |
| D14 | La notación de un esquema y sus clases de rima dicen lo mismo | 3.3 |
| D15 | Toda arquitectura declara su régimen de rima, arriba o en sus disposiciones | 3.3 |
| D16 | Toda reutilización entre formas tiene una relación ontológica correspondiente | 3.5 |

El informe añade matrices descriptivas —dónde vive la medida, dónde la rima, qué alcance
tiene cada pregunta, qué ámbito declara cada esquema— que no son incumplimientos, sino el
material para decidir el apartado 7.

## 7 · Decisiones abiertas

El criterio las plantea bien; resolverlas corresponde al IP. Todas son ahora preguntas
factuales sobre el corpus, no dilemas de modelado.

1. **¿Puede alternar `abba` y `abab` dentro de una tirada de redondillas?** Si no puede,
   son dos arquitecturas más y la redondilla queda sin ninguna pregunta. Mientras la duda
   siga abierta se mantiene como esquema por unidad, porque los dos errores no cuestan lo
   mismo: modelarlo como esquema y equivocarse se corrige reclasificando filas; modelarlo
   como arquitectura y equivocarse habría partido secuencias que no debían partirse, y
   deshacerlo exige volver a delimitar a mano.
2. **¿Varía la medida en las formas heterométricas?** El isosilabismo resuelve la mayoría,
   pero quedan el pareado —¿cambia de medida entre dísticos?—, el terceto encadenado
   octosilábico y la silva endecasilábica, cuyo eje mezcla medida y organización de la
   rima.
3. **Soneto.** Bajar los cuatro esquemas a la sección de los tercetos obliga a declarar si
   `ABBA ABBA` es norma fija de los cuartetos y si la elección es por secuencia o por
   unidad: una secuencia puede contener varios sonetos con esquemas distintos.
4. **Repertorio de quintilla.** ¿La copla real y la novena ofrecen exactamente los mismos
   ocho esquemas que la quintilla? Solo entonces puede reutilizarse una única fuente.
5. **Pie quebrado.** Unificar en opciones de metro con posición obliga a decidir si el
   quebrado admite medidas distintas del tetrasílabo en la copla real, como ya admite la
   forma general.
6. **Promoción de los rasgos cualitativos.** Los dieciséis literales detectados deben
   convertirse en rasgos con valores y modalidad. Hay que decidir cuántos son
   —probablemente predominio de rima, organización en pareados, dístico final, pareados
   intercalados y encadenamiento interior— y qué modalidad tiene cada aparición.
7. **Rima del terceto.** No declara ningún esquema pese a que su contrato afirma
   consonancia 1-3. Hay que decidir si se formaliza como esquema de la estrofa aislada o si
   la forma solo existe como componente de las series.

## 8 · Cómo aplicar el criterio a una forma nueva

1. Delimitar la identidad y comprobar que puede asignarse a una secuencia.
2. Recorrer las tres preguntas del apartado 1 con cada hecho observado.
3. Declarar la extensión una sola vez.
4. Formalizar medida y rima en el ámbito de la unidad que describen.
5. Reutilizar los componentes ya formalizados en lugar de copiarlos.
6. Añadir una elección solo si la respuesta no puede derivarse.
7. Comprobar que el orden de resolución del apartado 5 puede aplicarse.
8. Ejecutar `npm run audit:metrica`, y escribir el porqué **en el catálogo** —definición,
   descripción de la arquitectura o afirmación de fuente—, no en una ficha aparte. Las de
   `revisiones-formas/` están en retirada desde el 5 de agosto de 2026: lo descriptivo vive en
   el dato y se lee en `/formas`. Las excepciones justificadas que no caben en el dato van al
   [registro de cuestiones](./historico/cuestiones-por-forma-2026-08.md).

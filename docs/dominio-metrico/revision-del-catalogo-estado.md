# Revisión del catálogo contra las fuentes · dónde vamos

Actualizado: 8 de agosto de 2026 · **27 formas revisadas de 27, y los dos tramos sin forma**

> **La revisión filológica está terminada.** Las 27 formas activas y los dos tramos sin forma
> se han contrastado con las seis monografías, y no queda ninguna ficha `.md` en
> `revisiones-formas/` salvo la lista de cuestiones para el IP. Lo que sigue abierto no es
> filológico sino de modelo, y está en [defectos aplazados](#defectos-del-modelo-aplazados):
> son lecturas transversales que se hacen sobre el catálogo entero, no forma por forma.

Este documento dice **en qué punto está la revisión del catálogo métrico y cómo se continúa**.
Es el único sitio donde se lleva la cuenta. Si retomas el trabajo, empieza aquí.

---

## Qué es esta revisión

El catálogo métrico se pobló importando el vocabulario legado del proyecto. Esa importación
trajo los datos, pero no su justificación: las definiciones eran de redacción propia y las
fuentes bibliográficas estaban sin contrastar o directamente ausentes.

La revisión consiste en **recorrer forma por forma y contrastarla con seis monografías**,
corrigiendo el dato cuando la bibliografía demuestra que estaba mal. No es una revisión de
estilo: en lo que va de proceso han aparecido errores de fondo —una serie registrada como
estrofa, rimas que afirmaban dos clases donde hay una, arquitecturas que faltaban—.

Al terminar, cada forma debe tener:

- una **definición** que sostenga lo que dice el dato;
- **afirmaciones de fuente** con localizador, una por cada cosa que la bibliografía dice;
- **arquitecturas, esquemas, rimas y rasgos** que respondan a los criterios de nivel;
- un **contrato del registrador**, es decir, qué se deriva y qué pregunta el editor;
- y su ficha `.md` **borrada**, porque el catálogo pasa a ser el documento vivo.

## Las seis fuentes, y por qué solo seis

| Fuente | Volcado en `bibliografía/txt/` |
| --- | --- |
| Morley y Bruerton 1968, *Cronología de las comedias de Lope de Vega* | sus definiciones, ya en `.md` |
| Quilis 1969, *Métrica española* | `Quilis-1969-metrica-espanola.txt` |
| Navarro Tomás 1972, *Métrica española* | `Navarro-Tomas-1972-metrica-espanola.txt` |
| Domínguez Caparrós 2014, *Métrica española* | `Dominguez-Caparros-2014-metrica-espanola.txt` |
| Domínguez Caparrós 2016, *Diccionario de métrica española* | `Dominguez-Caparros-1999-diccionario-metrica.txt` |
| Jauralde Pou 2020, *Métrica española* | `Jauralde-Pou-2020-metrica-espanola.txt` |

**El fichero del Diccionario dice 1999 en su nombre pero es la 3.ª edición de 2016.** El nombre
refiere a la edición original.

El directorio `bibliografía/` está fuera de git. Si faltan los volcados se regeneran con
`pdftotext -layout -enc UTF-8`; el epub de Jauralde se extrajo descomprimiéndolo y limpiando
etiquetas. **`metrica-clasificacion.pdf` no sirve para esto**: es un artículo sobre repertorios
métricos, no un manual de definiciones.

**Morley y Bruerton describen a Lope**, no el Siglo de Oro entero, y el catálogo es
deliberadamente más amplio en varios puntos —la redondilla cruzada, la copla real—. Esa
diferencia se registra como afirmación propia; no es un desacuerdo que haya que ocultar.

La revisión de las seis fuentes es **exhaustiva, no selectiva**. Cada fuente que menciona una
forma recibe su propia afirmación, aunque repita sustancialmente lo dicho por otra. Las
diferencias, variantes y aspectos no formalizados se destacan en el resumen, pero la
coincidencia entre autores nunca es motivo para omitir una fuente. Una fuente solo queda fuera
de una forma cuando, después de revisar el pasaje y su contexto, no la trata.

Antes había once fuentes. Las otras cinco se retiraron porque no cumplían el criterio de
autoridad —publicación bibliográfica académica identificable—. Las afirmaciones perdidas de
Décima, Copla de pie quebrado y Villancico ya se han recuperado tras revisar las seis fuentes
autorizadas, y la Copla real recuperó el suyo el 8 de agosto de 2026 partiendo de cero
afirmaciones, y el Zéjel el suyo el mismo día, también desde cero. **Las tres formas que se
quedaron sin respaldo lo han recuperado**; la Redondilla doble no es hoy una forma del
catálogo, sino una arquitectura de la redondilla, revisada con ella.

### Cómo se localiza un pasaje

`node scripts/lib/localizar.mjs <fichero> "<texto literal>"` devuelve la página. Funciona con
Caparrós 2014, el Diccionario y Quilis (que da pares, porque el PDF escaneó pliegos dobles).

**No funciona con Navarro Tomás ni con Jauralde.** El primero conserva 37 números de página en
todo el libro: se cita por `§` numerado. El segundo viene de un epub sin paginar: se cita por
el título de la sección. El Diccionario, alfabético, se cita `s. v. «entrada»`.

---

## Estado forma por forma

**Revisada** significa contrastada con las seis fuentes, prosa reescrita, ficha `.md` borrada.

| Forma | Fuentes | Afirmaciones | |
| --- | ---: | ---: | --- |
| Romance | 6 | 7 | revisada |
| Redondilla | 6 | 9 | revisada |
| Décima | 6 | 7 | revisada |
| Silva | 6 | 7 | revisada |
| Soneto | 6 | 7 | revisada |
| Quintilla | 6 | 6 | revisada |
| Lira | 6 | 6 | revisada |
| Octava real | 6 | 6 | revisada |
| Cuarteto | 6 | 7 | revisada |
| Pareado | 6 | 6 | revisada |
| Terceto encadenado | 5 | 5 | revisada |
| Endecha real | 5 | 12 | revisada |
| Terceto | 3 | 3 | revisada · las otras tres fuentes no lo tratan aparte |
| Canción petrarquista | 6 | 6 | revisada · el intervalo 5-20 y la canción sin rima son de Morley y Bruerton |
| Copla de arte mayor | 6 | 6 | revisada · **dos de sus tres esquemas contradecían a las fuentes** |
| Novena | 4 | 4 | fuentes revisadas · separación y apertura aplazadas |
| Seguidilla | 6 | 6 | revisada |
| Sexteto | 6 | 6 | revisada · las fuentes lo definen más ancho; el recorte del corpus queda anotado |
| Sexteto-lira | 6 | 6 | revisada · es una lira de seis versos; el repertorio de tipologías no es cerrado |
| Sextilla | 6 | 6 | revisada · sus disposiciones tienen nombre; el quebrado no siempre va en 3 y 6 |
| Sextina (estrofa y composición) | 6 | 7 | revisada |
| Villancico | 5 | 5 | revisada · jerarquía pública corregida; normalización paramétrica aplazada |
| Copla de pie quebrado | 6 | 6 | revisada |
| Copla real | 6 | 6 | revisada · recuperado su respaldo; cuatro denominaciones |
| Zéjel | 5 | 5 | revisada · Morley y Bruerton no lo tratan |
| Endecasílabo suelto | 6 | 6 | revisada · Morley y Bruerton dan el umbral del 50 % |
| Versificación irregular | 4 | 4 | tramo sin forma · revisado |
| Verso aislado | 2 | 2 | tramo sin forma · revisado |

El endecasílabo suelto se dejó expresamente para el final por decisión del IP, por ser el más
problemático. Resultó serlo menos de lo temido: las seis fuentes coinciden con lo que el
catálogo ya modelaba y **Morley y Bruerton dieron el umbral que faltaba** —un pasaje es de
sueltos cuando los versos rimados son menos del 50 %—.

La fila «Sextina» reúne dos formas activas distintas —la estrofa y la composición— revisadas
en una sola unidad de trabajo. El denominador cuenta las 27 formas activas y excluye los dos
tramos sin forma, que se revisaron aparte porque no tienen norma que contrastar.

### Lo que queda, y ya no es forma por forma

No queda ninguna forma por revisar. Lo abierto son las **lecturas transversales** de
[defectos aplazados](#defectos-del-modelo-aplazados), que se hacen sobre el catálogo entero:
el concepto de variedad, la modalidad y la primacía, las reglas de repetición, la
reutilización de secciones, el modelo de esquemas abiertos y la automatización de las
preguntas del editor. Las dudas filológicas que siguen abiertas están en
[cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md), y muchas se responden
juntas dentro de esas lecturas.

El territorio de los seis versos está cerrado —sexteto, sextilla y sexteto-lira—, y la lectura
confirmó que **las tres formas están bien separadas**: la frontera la marcan el metro y la
genealogía, no la extensión. Ninguna fuente las confunde, aunque varias usen un mismo nombre
para dos de ellas.

Las coplas también quedan cerradas, y **también están bien separadas, pero por otra razón**.
Las cuatro no comparten extensión —6, 8, 10 y de 5 a 12 versos—, así que nunca compiten. Lo que
la revisión aclara es que «copla» no nombra un parentesco: la de arte mayor es una octava culta
del siglo XV, la real son dos quintillas octosilábicas, la sextilla es una estrofa de seis y la
de pie quebrado es la salida general del quebrado. La única relación real que las fuentes
documentan entre dos de ellas es la de la copla real con la décima espinela, y es de contraste
—rimas independientes frente a rima común—, no de familia. El reparto en cuatro formas
distintas, sin familia que las agrupe, es el que corresponde.

Y las últimas cuatro dejaron una lección sobre el propio método: **buena parte de lo que las
fichas atribuían al criterio del IP estaba en la bibliografía y nadie lo había buscado**. El
intervalo 5-20 de la estancia y la arquitectura de canción sin rima, que la ficha declaraba
aportación del proyecto sin fuente, son literalmente de Morley y Bruerton; el umbral que separa
el endecasílabo suelto de la silva lo cuantifican ellos mismos; y «Verso aislado», que se
anotaba como duda de nomenclatura, es la expresión con que el *Diccionario* explica el verso
único de Navarro Tomás. Conviene recordarlo al abrir las lecturas transversales: antes de
declarar que algo es criterio propio, hay que haber leído a las seis.

---

## El procedimiento, forma por forma

1. **Leer el dato**, no la ficha: qué arquitecturas, esquemas, rimas, secciones, rasgos,
   denominaciones, relaciones y elecciones tiene hoy la forma.
2. **Buscar la forma en las seis fuentes** y leer los pasajes enteros, no la primera frase.
3. **Comparar y decidir**. Cuando la bibliografía contradice el dato, manda la bibliografía,
   salvo que el criterio del IP para el corpus sea deliberado y esté justificado.
4. **Comprobar las equivalencias legadas de la forma**. Hay que consultar sus usos en
   `propuesta_metrica_secuencia` y verificar que forma, arquitectura y longitud sean
   compatibles. Si el informe se equivoca, se corrige la regla común; no se retoca el informe
   generado ni se migra la anotación de la obra durante esta revisión.
5. **Escribir la migración**, con el razonamiento en la cabecera y una guarda al final que
   compruebe lo que acaba de escribirse.
6. **Aplicar** con `npm run db:push` y **verificar en vivo** consultando la base.
7. **Auditar** con `npm run audit:metrica` — introducir un defecto nuevo es fácil.
8. **Añadir la forma al contrato del registrador**, si no está: la auditoría lo comprueba.
9. **Borrar su ficha `.md`** y podar lo que quede resuelto en el registro de dudas.
10. **Commit**, en español, con el porqué en el cuerpo.

### Cómo consultar la base

`scripts/lib/consulta.mjs` exporta `query(sql)`. Desde un script del scratchpad hay que
importarlo con URL `file:///`, que en Windows es obligatorio para rutas absolutas.

### Criterios de la prosa

Están en [donde-vive-la-prosa.md](./donde-vive-la-prosa.md), son ocho y se aplican a todo lo
que se escribe en el catálogo. Los tres que más se olvidan:

- **Una afirmación de fuente dice lo que dice la fuente.** No opina sobre el catálogo ni
  explica qué hizo el proyecto con ese dato. Hay una guarda en migración que lo comprueba.
- **No se da por supuesto el contexto.** «Repite la definición del Diccionario» supone que el
  lector sabe que ese autor escribió un diccionario.
- **Los títulos de obra van en cursiva**, con Markdown: la prosa del catálogo lo admite y la
  ficha lo renderiza.

### Qué buscar en cada forma, además de las fuentes

1. **Definiciones que son decisiones del proyecto.** «El catálogo reconoce realizaciones de
   seis, siete y ocho sílabas» es una decisión, no una definición de la redondilla: su sitio es
   la descripción de cada arquitectura.
2. **Descripciones que repiten la definición** de su forma, palabra por palabra o casi.
3. **Razonamientos que solo viven en la ficha `.md`** y no en el dato. Si merecen sobrevivir,
   su sitio es el catálogo; si no, se van con la ficha.
4. **Dónde el proyecto se aparta de la bibliografía**, que merece afirmación propia.
5. **Las afirmaciones perdidas** con las cinco fuentes retiradas, si la forma es una de las
   seis afectadas.

### Lo que un cambio en el catálogo puede romper

| | Cómo se comprueba |
| --- | --- |
| **Catálogo público** `/formas` | Se genera del dato, pero hay que verificar que la consulta agregada conserve ids, jerarquía y claves únicas; el villancico demostró que una respuesta completa puede representarse mal si se aplana |
| **Demarcador** | Se compila del catálogo; subir `catalogo_metrico_estado.revision` lo marca desactualizado |
| **Editor V2** | Lee nombres de opciones y esquemas: un renombrado se ve ahí |
| **Equivalencias** | Hoy la vista devuelve 212 filas; revisar también `longitud_compatible` y `motivo_revision` para los usos de la forma |
| **Respuestas propuestas** | Hoy `select count(*) from propuesta_elecciones_secuencia` da 91 |

**Las dos cifras son un aviso, no una invariante.** Sirven para notar que algo se movió sin
querer, pero moverse no es de suyo un error: la revisión encuentra equivalencias mal hechas o
poco precisas, y corregirlas cambia el recuento con toda la razón. Lo que no vale es que
cambien sin explicación. Si cambian, se dice por qué en el cuerpo del commit y se actualiza la
cifra aquí.

**Y una regla que vale para todo**: no fiarse de las migraciones para saber qué hay. Consultar
siempre el catálogo en vivo y leer el esquema de las tablas antes de sacar conclusiones. Las
migraciones solo cuentan lo que pasó aquel día.

---

## Lo que esta revisión ha cambiado en el modelo

No estaba previsto, pero recorrer el catálogo destapó cosas del modelo. Todas aplicadas:

- **Bloque y sección no son lo mismo.** El bloque es la unidad de repetición y enlace —lo que
  cuenta `desplazamiento_bloque` y lo que separa `|`—; la sección es la parte con nombre, puede
  ser más fina que el bloque y existe aunque haya un solo bloque.
- **`tipo_alias` retirado.** Las denominaciones son nombres, sin más: no había manera
  defendible de clasificarlas.
- **`grado_especificacion` retirado.** Era andamiaje de un enfoque anterior del motor, nunca
  implementado. La clasificación que sirve es `nivel_estructural`.
- **Las relaciones entre formas se ven en la ficha pública**, que no las mostraba.
- **Una forma `serie` aparte solo se justifica cuando seriar cambia la estructura**, porque una
  estrofa ya se seria dentro de su propia forma.
- **Un esquema de rima puede afirmar de una forma algo que la bibliografía niega.** La copla de
  arte mayor declaraba `ABBACDCD` y `ABABCDCD`, cuyo segundo cuarteto estrena dos rimas nuevas.
  Cuatro fuentes exigen lo contrario —una rima común a los dos cuartetos y los versos cuarto y
  quinto rimando entre sí—, así que la estrofa lleva dos o tres rimas y nunca cuatro. Se
  sustituyeron por los dos que las fuentes documentan. Al retirar un esquema hay que repuntar
  las opciones de elección que lo referencian: la clave foránea lo impide y, sobre todo, la
  pregunta del editor debe ofrecer el dato corregido.
- **La equivalencia de un término genérico ya no impone siempre la arquitectura principal.**
  Primero descarta las arquitecturas incompatibles con la extensión; si ninguna encaja,
  conserva la forma y deja una duda explícita para el informe y el dashboard.

### Defectos del modelo aplazados

**Los esquemas abiertos necesitan una representación paramétrica general.** Las formas muy
estructuradas declaran medidas y rimas por posición; las más libres acaban repartiendo su
norma entre conjuntos permitidos, prosa y preguntas editoriales declaradas a mano. Cuando
termine la revisión filológica de las 27 formas, hay que comparar juntas todas estas formas
difíciles y diseñar restricciones computables —sin enumerar cada realización posible y sin
debilitar el modelo posicional de las formas fijas—. No se resolverá este problema adaptando
el modelo por separado a cada forma durante la revisión.

**La Novena general y la copla novena deben separarse al resolver ese modelo abierto.**
Caparrós y el *Diccionario* llaman novena a cualquier estrofa de nueve versos y niegan que
comparta necesariamente otra norma; Navarro Tomás y Jauralde caracterizan la copla novena
histórica como redondilla y quintilla, normalmente 4+5 y también 5+4. La copla novena tendrá
identidad de forma subordinada, no de arquitectura, y recibirá las dos arquitecturas actuales.
La separación no se aplica todavía porque falta decidir cómo hacer registrable y demarcable la
Novena general sin clasificar por defecto cualquier pasaje de nueve versos.

### La variedad · lectura hecha el 9 de agosto de 2026

**El concepto está bien definido, y ninguno de sus dos usos lo cumple.** Es el resultado de la
lectura, y deja una decisión de fondo para el IP.

**Qué es una variedad, según el modelo.** «Parejas de esquema métrico y esquema de rima que el
proyecto reconoce dentro de una arquitectura». Su prueba discriminante en
[criterios-de-nivel.md](./criterios-de-nivel.md) es *«restringe qué parejas de esquemas reconoce
el proyecto»*, y su contraprueba, *«si los dos ejes son libres, no hace falta»*. El esquema lo
impone: `esquema_metrico_id` y `esquema_rima_id` son **ambos NOT NULL**, de modo que una
variedad no puede existir sin sus dos patas. La definición es coherente en la tabla, en los
criterios y en la guía del editor, y **no se solapa con arquitectura**: el criterio explícito es
que la arquitectura cambia cuando cambia el recipiente, y una disposición de rima no crea nunca
una arquitectura.

**Uso real: 8 variedades en 2 arquitecturas de las 57 activas.** Y las dos fallan la
contraprueba:

- **La sexta rima** (sexteto endecasílabo) está en una arquitectura con **un solo esquema
  métrico**: no hay parejas que restringir. Lo que hace es dar nombre a la disposición
  `ABABCC`, que es el trabajo de una denominación. *Decidido por el IP: pasa a denominación.*
- **Las siete del sexteto-lira** están en la única arquitectura del catálogo con más de un
  esquema métrico y más de uno de rima —5 × 3 = 15 parejas posibles, 7 declaradas—. Pero
  **los dos ejes son libres**: nada impide combinar cualquier secuencia de medidas con
  cualquier disposición. Las siete no salen de una restricción documentada sino del vocabulario
  legado, donde eran siete subtipos escritos uno a uno; y ninguna de las seis fuentes prohíbe
  combinación alguna —dos cierran su enumeración en «y otras»—. El detalle, con el mapa de las
  quince casillas, en [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md#sexteto-lira).

**Lo que la lectura descarta.** Extender la variedad al resto del catálogo **no es viable**, y
no por criterio sino por estructura: **las 25 preguntas de rima están todas en arquitecturas con
un solo esquema métrico**. Convertirlas en variedades emparejaría cada disposición con el único
métrico disponible, es decir, información cero en la primera pata: 79 filas para repetir lo que
ya dicen los 79 esquemas de rima.

**Dar nombre no es su trabajo.** Para eso está la denominación, que ya admite colgar de forma,
arquitectura, esquema de rima, esquema métrico, sección, repetición o variedad —hoy hay **11
denominaciones sobre esquemas de rima**: «Cuarteta» sobre la redondilla cruzada, «Sextilla
alterna» sobre `ababab`—. Una opción que elige solo un esquema de rima no puede ser variedad:
le falta la otra pata, y dársela obligaría a inventarle un esquema métrico.

**Lo que queda por decidir**, y es del IP porque toca al concepto entero: si los dos ejes del
sexteto-lira son libres, la contraprueba del modelo dice que la variedad no hace falta **en
ninguno de los dos casos**, y el nivel se quedaría sin uso. La alternativa para esa forma son
dos preguntas cerradas —secuencia de medidas y disposición de rima— que cubren las quince
combinaciones y admiten lo que las fuentes documentan y el catálogo no tiene.

### Las preguntas del editor · auditoría del 9 de agosto de 2026

**El objetivo del IP es retirar por completo el sistema de preguntas y respuestas**, y tratar
todo lo que quede sin poder derivarse como lo que es: **una carencia de declaración del
catálogo**, no una razón para conservar la tabla. La auditoría dice que es viable.

Hoy hay **61 grupos de elección y 405 opciones** escritos uno a uno en migraciones. Eso es lo
que encarece el mantenimiento, porque una corrección filológica obliga a tocar dos sitios: pasó
con la copla de arte mayor, donde al sustituir dos esquemas hubo que repuntar además las
opciones que los referenciaban.

**Se derivan 56 de los 61 grupos.** Ninguna opción es texto libre: todas apuntan ya a una
entidad del catálogo.

| Dimensión | Grupos | De dónde salen las opciones | Sin declarar |
| --- | ---: | --- | ---: |
| Rima | 25 | 13 de los esquemas de su arquitectura · 7 de la arquitectura referenciada por la sección · 4 son respuesta abierta, ya marcada con `tipo_control = 'esquema_rima'` | 1 |
| Metro | 17 | 14 de `esquema_metrico_opciones`, que declara qué metros admite un esquema de tipo conjunto · 1 de las alternativas de `esquema_metrico_posiciones` | 2 |
| Rasgo | 15 | 13 de `arquitectura_rasgos` cruzado con `rasgo_valores` | 2 |
| Repetición | 3 | De las repeticiones declaradas | 0 |
| Combinación | 1 | De las variedades | 0 |

**El patrón del rasgo resultó ser el más limpio de todos**, y basta para generar la pregunta:
`definitoria` con valor fijo se deriva y no se pregunta; `admitida` con valor fijo produce una
pregunta opcional de un solo valor; `admitida` sin valor deja el eje abierto.

#### Los cinco huecos · declarados el 9 de agosto de 2026

Eran **el mismo tipo de carencia**: *qué subconjunto de lo posible admite esta arquitectura*.
Uno resultó no ser un hueco y los otros cuatro se resolvieron con dos cambios de estructura
(migración `20260809150000`).

**No era un hueco: la sextilla.** Ofrece uno de sus dos esquemas de rima porque el otro es de
tipo `abierta`, y **ningún esquema abierto se ofrece nunca como opción** —0 de 11 en todo el
catálogo, y 0 de 4 entre los de tipo `restricciones`—. Un esquema abierto declara que la norma
no fija la disposición; no es una alternativa elegible. Con eso, las reglas de la rima quedan
completas y sin nada que declarar:

| Situación de la arquitectura | Qué genera |
| --- | --- |
| Un solo esquema concreto | Nada: se deriva |
| Varios concretos | Pregunta con esos como opciones |
| Solo esquema abierto | Respuesta abierta, ya marcada con `tipo_control` |
| Abierto más concreto | Pregunta opcional para marcar el concreto |

**Cambio 1 · el papel del metro.** `esquema_metrico_opciones` gana la columna `rol`: nulo es
una alternativa entre iguales —el hexasílabo o el octosílabo del villancico—, `dominante` es el
verso base y `quebrado` el verso corto que lo interrumpe. La copla de pie quebrado ya declaraba
sus tres metros sin decir cuál era cuál; la copla real no declaraba ninguno, aunque su pregunta
ofrecía tetrasílabo y pentasílabo. Ahora las dos lo declaran y la pregunta se deriva: los
quebrados son los metros de rol `quebrado`.

**Cambio 2 · el subconjunto admitido de un rasgo.** `arquitectura_rasgos` podía decir «vale X»
o «queda abierto», pero no «admite estos dos de los cinco». Su clave primaria pasa a incluir el
valor, con `nulls not distinct` para que siga habiendo una sola fila cuando el eje se deja
abierto de verdad. La silva endecasilábica declara ahora `habituales` y `predominantes`; el
endecasílabo suelto, `ninguna` y `ocasionales`.

Que la carencia era real lo probaba la propia nota del endecasílabo suelto, que decía en prosa
«Ninguna u ocasionales»: **el dato estaba escrito, pero como texto y no como hecho computable**.
Es el ejemplo exacto de lo que la ontología quiere evitar.

Este cambio resuelve además parte de la transversal de los rasgos —la de las dos magnitudes, más
abajo—: declarar qué grados admite cada arquitectura hace explícito que la silva y el
endecasílabo suelto ocupan **tramos distintos de la misma escala**, que era justo lo que no se
podía expresar.

Con esto, **los 61 grupos son derivables** y la retirada del sistema de preguntas y respuestas
deja de depender de ninguna decisión filológica pendiente.

#### Los enunciados no son información

Es el hallazgo que hace viable la retirada total. **Solo 10 de los 61 enunciados citan
literalmente su sección**; los otros 51 son prosa redactada. Pero al cotejarlos con la entidad
que preguntan, resulta que **no añaden nada al nombre de esa entidad** —y que han derivado,
porque el mismo rasgo se pregunta de dos maneras según la forma:

| Rasgo | Enunciados que conviven hoy |
| --- | --- |
| Organización en pareados | «¿Cuánto organizan los pareados la serie?» y «¿Hay pareados intercalados?» |
| Final acentual | «¿Predominan los finales esdrújulos?» y «¿Presenta un final acentual destacado?», cuatro veces |
| Vocales de la asonancia | «¿Qué vocales caracterizan la asonancia?», siete veces idéntico |

Es exactamente la deriva que produce mantener a mano lo que puede derivarse. Un rótulo generado
—dimensión más nombre de la entidad— sería **más consistente que los 51 textos actuales**, no
menos.

#### Qué quedaría declarado

Nada de contenido métrico. Solo presentación: **el orden** en que se muestran las preguntas y,
si se quiere conservar, una ayuda al editor por dimensión y no por forma. Todo lo demás sale del
catálogo, que es donde el IP quiere que esté.

#### Un sexto hueco: la cardinalidad

Al declarar los cinco anteriores apareció otro que el barrido por dimensiones no veía, porque no
está en las opciones sino en el grupo: **cuántas respuestas admite una pregunta**. Doce grupos
tienen una cardinalidad distinta de «exactamente una», y once se derivan —el mínimo cero sale de
la modalidad `admitida`, el máximo sale de la extensión de la unidad o de la sección, el 2 del
pareado sale de sus dos versos—.

**El que no se derivaba era la copla real**, cuya pregunta admite de cero a dos posiciones
quebradas: nada decía que **como mucho dos** de sus diez versos pudieran quebrarse. Esa norma
vivía en `selecciones_max` y, otra vez, en una nota en prosa —«Uno o dos de los diez versos
pueden ser quebrados»—.

**Declarado el 9 de agosto** (migración `20260809160000`): `arquitectura_rasgos` gana
`posiciones_max`, que dice cuántas posiciones de la unidad puede ocupar el rasgo cuando el techo
es más bajo que la propia unidad. Solo el máximo: **el mínimo lo da la modalidad**, porque
`definitoria` exige al menos una posición —la copla de pie quebrado no lo es si no quiebra
ningún verso— y `admitida` permite ninguna. Declararlo habría sido escribir lo derivable, y
añadir una columna que nadie rellenaría con algo distinto de lo que ya se deduce es exactamente
lo que le pasó a `valor_numero`.

#### Un séptimo hueco, encontrado al probar la derivación

Al escribir la derivación y **contrastarla contra las 405 opciones escritas a mano**, la
dimensión del metro no cuadró: 39 derivadas frente a 167. El diagnóstico destapó un hecho
métrico que el catálogo no declara.

Las preguntas de medida son de dos clases y **nada las distingue en el dato**:

| Clase | Cómo se responde | Formas |
| --- | --- | --- |
| **Uniforme** | Una sola medida para toda la sección | Villancico y zéjel: «¿qué miden los versos de la mudanza?» |
| **Por posición** | Una medida por cada verso | Canción petrarquista, pareado, copla real, copla de pie quebrado |

Las dos usan un esquema métrico de tipo `conjunto` y las dos pueden estar ancladas a una
sección, de modo que ni el tipo ni el anclaje las separan. **Lo que las separa vive en la
prosa**: la descripción del conjunto de la canción dice «cada posición de la estancia se
registra como heptasílaba o endecasílaba», y la del villancico, «sin imponer un orden fijo».

Es un hecho de métrica y no de formulario: la mudanza del villancico **es isosilábica** y la
estancia de la canción **es heterométrica por posición**.

**Declarado el 9 de agosto** (migración `20260809180000`): `esquemas_metricos` gana
`medida_uniforme`, verdadero cuando todos los versos del tramo comparten medida y falso cuando
cada posición tiene la suya. Tres esquemas son uniformes —los del villancico y el zéjel— y siete
heterométricos.

#### La derivación, comprobada

La migración lleva una guarda que **recorre cada pregunta de medida y compara las opciones
escritas a mano con las que salen del catálogo** —posiciones por metros admitidos, o un solo
juego cuando la medida es uniforme—. Pasa: la derivación reproduce las **167 opciones de metro**
sin una sola diferencia.

Contrastadas después las tres dimensiones con una consulta de una pasada, **49 de los 53 grupos
con opciones se reproducen exactamente**, y los que no son **dos mecanismos ya estructurados que
esa consulta no cubría**, no carencias:

- la seguidilla gitana, cuyas tres medidas del tercer verso salen de las **alternativas de una
  posición** en `esquema_metrico_posiciones`, no de un conjunto;
- el grupo `rasgos_de_la_serie` del endecasílabo suelto, que **reúne dos rasgos distintos** en
  una sola pregunta.

Con los siete huecos declarados, **el catálogo contiene ya todo lo que hace falta para generar
el formulario**.

#### La respuesta ya no depende de la opción

Aplicado el 9 de agosto (migraciones `20260809190000` y `20260809200000`). Era la condición para
poder generar las preguntas: mientras una respuesta guardara `opcion_eleccion_id`, **regenerar
las opciones habría dejado huérfanas las respuestas**.

Ahora `elecciones_editor_metrico` guarda **el dato del catálogo que se eligió** —un metro, un
esquema, un valor de rasgo, una variedad, una repetición— y la posición cuando la hay. La
opción sigue existiendo y sigue siendo lo que el editor pinta; una vista,
`elecciones_editor_metrico_resueltas`, la resuelve de vuelta, de modo que **el formulario no
cambió**. La validación comprueba lo mismo que antes —que la elección esté admitida—, pero
sobre la entidad: cuando las opciones se deriven, cambiará de fuente sin tocar lo guardado.

La correspondencia resultó exacta en las cinco dimensiones, incluida la de repetición, donde
cada opción apunta a una repetición distinta. **Lo que sigue viviendo en la opción es cómo se
realiza esa repetición** —`materializa_seccion_id` y `extension_desde_seccion_id`—, y tendrá que
mudarse a `repeticiones_metricas` antes de poder retirar las opciones. Es exactamente lo que
anota la transversal de las reglas de repetición, que queda así enlazada con esta.

**Una lección de método.** El cambio pasó `db push`, `npm run check` y las 296 pruebas, y aun
así estaba roto: un segundo disparador, `validar_posicion_eleccion_editor_metrico`, seguía
leyendo la columna retirada, y **cualquier intento de guardar habría fallado**. No lo detectó
nada porque una función de PL/pgSQL no se compila hasta que se ejecuta y ninguna prueba escribe
en esa tabla. Lo destapó una inserción de prueba contra la base. *Al tocar una tabla con
disparadores, conviene ejercitarla, no solo migrarla.*

#### La generación, escrita y comprobada

Aplicado el 9 de agosto (migraciones `20260809210000` y `20260809220000`).

Antes hubo que **mudar a `repeticiones_metricas` el comportamiento que llevaba la opción**: si
la repetición materializa una sección y de dónde toma su extensión. La correspondencia era uno a
uno —cada opción apunta a una repetición distinta y cada repetición tiene un comportamiento
fijo—, así que el comportamiento es de la repetición y no de la pregunta que la ofrece. Con eso
avanza también la transversal de las reglas de repetición, que preguntaba justo eso.

`opciones_eleccion_derivadas()` produce las opciones de cada pregunta desde el catálogo, y
`generar_opciones_eleccion_metrica()` las compara con las escritas a mano. **De las 61
preguntas, 56 coinciden exactamente** —403 de las 405 opciones—, 4 son respuesta abierta y no se
generan, y una queda sin derivar.

**Dos huecos más, encontrados al escribirla.** El octavo: **un grupo de dimensión rasgo no
declaraba sobre qué rasgo pregunta**, cosa que solo se sabía mirando sus opciones, que es
justamente lo que se quiere regenerar; ahora lo declara con `rasgo_id`. Y una regla que faltaba
aplicar: **una sección contenedora no declara su extensión, se deriva de sus partes** —la
estancia sin rima de la canción mide lo que suman su cuerpo y su pareado final—, que es la regla
que el modelo ya tenía escrita y que la derivación no estaba usando.

**Lo que queda sin derivar es uno solo**: `rasgos_de_la_serie` del endecasílabo suelto reúne dos
rasgos independientes —dístico final y encadenamiento interior— en una lista de casillas. No es
un rasgo con varios valores, sino dos preguntas de sí o no presentadas juntas, y su `rasgo_id`
queda nulo a propósito.

**La función no escribe.** Devuelve qué cambiaría; aplicar está deliberadamente sin implementar,
porque las etiquetas de las opciones se siguen escribiendo a mano. Mientras tanto, pedir el
informe es la manera de comprobar que el dato y el formulario no se han separado.

#### Cómo se derivan las etiquetas

Analizadas las 405 escritas a mano, la regla es una: **la etiqueta es el nombre de la entidad**,
compuesto con la posición cuando la pregunta es posicional.

| Dimensión | Etiqueta |
| --- | --- |
| Combinación | El nombre de la variedad — coincide en 7 de 7 |
| Rasgo, un solo rasgo | El nombre del valor — coincide en 137 de 144 |
| Rasgo, varios rasgos | El nombre del **rasgo**, porque el valor es solo «Presente» |
| Rima | El nombre del esquema, y su notación cuando no tiene nombre |
| Metro | El nombre del metro, precedido del verso cuando la medida varía por posición |
| Repetición | El nombre de la repetición |

**Donde la regla no funcionaba era porque a la entidad le faltaba el nombre**, no porque la
etiqueta llevase información propia. Ese fue el **noveno hueco**: las repeticiones no tenían
`nombre`, y sus opciones se rotulaban «Se repite entero» o «Se sobreentiende, no está escrito»
sin que la repetición tuviera dónde decir cómo se llama. Declarado el 9 de agosto, con una
guarda que exige que el nombre de la repetición y el de su opción coincidan: si se separaran, la
etiqueta derivada cambiaría lo que el editor ve.

#### Borrar catálogo no borra anotación

Corrección de un error introducido el mismo día. Al soltar la respuesta de la opción se le
dieron claves foráneas al catálogo **con borrado en cascada**, copiando el patrón de las
opciones —donde tiene sentido, porque una opción *es* catálogo—. Pero una respuesta **es dato
sobre una obra**: que borrar un esquema de rima se llevara las anotaciones que lo usaban es lo
contrario de lo que se buscaba al hacer el cambio.

Pasaron a `restrict`, como ya estaban el metro y el valor de rasgo. **El catálogo se niega ahora
a borrar algo que una anotación use**, lo que obliga a mirar la anotación antes en vez de
perderla. Comprobado con un borrado real contra la base.

*Queda un matiz que conviene tener presente: la respuesta guarda un puntero, no una copia. Si se
edita la notación de un esquema, la respuesta antigua reflejará la nueva. Para conservar «lo que
el editor vio aquel día» haría falta versionar el catálogo, que es otra decisión y no está
tomada.*

### Datos asumidos que siguen viviendo en prosa

Barrido del 9 de agosto de 2026 sobre las notas y descripciones del catálogo, a petición del IP:
buscar información que se dé por supuesta en texto sin haberse convertido en dato procesable.
De 46 pasajes con aspecto de llevar dato, la mayoría **describen lo que el catálogo ya declara**
—«Endecasílabos en las posiciones 1, 4 y 6»— y son redundancia, no carencia; el criterio de
[dónde vive la prosa](./donde-vive-la-prosa.md) ya prohíbe escribir lo que la ficha deriva.

Los que sí señalan carencia:

- **La articulación de la estancia no está modelada.** Una nota dice «la fronte ocupa los versos
  1–6 y la sirima los versos 7–13; el verso 7 es el eslabón», pero la canción petrarquista no
  declara esas partes como secciones. Las tres son unidades con nombre tradicional y extensión
  propia, y hoy solo existen como frase.
- **La simetría de la mudanza tampoco.** «Normalmente organizada en dos miembros simétricos»
  aparece en tres notas del villancico, y es justamente la duda 1 de esa forma en
  [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md#villancico).
- **El límite de dos quebrados de la copla real**, arriba.

Y una redundancia recién creada, que conviene podar: la nota de la copla de pie quebrado dice
«El octosílabo es la medida dominante. Los pies quebrados son tetrasílabos o pentasílabos», que
desde el 9 de agosto **es exactamente lo que declara la columna `rol`**.

Al cerrar las transversales conviene repetir este barrido, porque cada cosa que se convierte en
dato deja atrás una frase que la repite.

**Un rasgo puede estar midiendo dos magnitudes a la vez.** Salió el 9 de agosto de 2026 al
intentar recuperar los porcentajes de Morley y Bruerton en `organizacion_en_pareados`, que es
el eje que separa la silva del endecasílabo suelto y del pareado. M&B cuentan **versos
rimados** —sueltos por debajo del 50 %, silva 3.ª del 50 al 98 %—, pero la arquitectura `Silva ·
Libre` declara el grado `ninguna` **y sí rima**: lo que no tiene son pareados. En esa forma
`ninguna` significa «ningún pareado», no «ninguna rima», de modo que un mismo grado se lee de
dos maneras según la arquitectura que lo declare.

Aparecieron a la vez otros dos obstáculos: `habituales` y `predominantes` caerían en el mismo
intervalo, porque las fuentes solo dan dos cortes y la distinción entre ambos es una partición
cualitativa propia del IP; y nada cuenta hoy los versos rimados, así que el porcentaje sería
declarativo y no verificable. **El IP decidió no cuantificar hasta separar las dos magnitudes.**
Al abrir la lectura de los rasgos hay que revisar si otros tienen el mismo problema, porque la
escala de cinco grados se extendió desde la silva al endecasílabo suelto y al pareado sin
comprobar que midiera lo mismo en los tres.

**Parte del problema se alivió el 9 de agosto**, al declarar los subconjuntos admitidos para
poder derivar las preguntas. Ahora la silva endecasilábica dice que admite `habituales` y
`predominantes`, y el endecasílabo suelto, `ninguna` y `ocasionales`: **los tramos son
explícitos y no se solapan**, de modo que la escala se lee sin ambigüedad aunque siga sin tener
cifras. Lo que queda por resolver es lo de fondo —que `ninguna` significa «ningún pareado» en la
silva libre, que sí rima— y sigue exigiendo separar las dos magnitudes.

**La modalidad y la primacía necesitan una lectura transversal.** Al terminar la revisión de
las formas hay que comprobar que `principal` y los valores de modalidad —`definitoria`,
`preferente`, `admitida`, `excepcional`, etc.— significan y se usan igual en todo el catálogo,
y aclarar qué relación existe entre ambos mecanismos. No se normalizarán forma por forma.

**Las reglas de repetición deben ser computables y la prosa debe tener responsabilidades
separadas.** Hoy `repeticiones_metricas.regla` es texto libre: el editor V2 no lo interpreta,
sino que calcula la aparición y la extensión mediante `materializa_seccion_id` y
`extension_desde_seccion_id`; el demarcador solo usa `regla` o `descripcion` para presentar un
resultado. Al cerrar la revisión hay que decidir si ese comportamiento estructurado pertenece
a la repetición, cómo se relaciona con las opciones de elección y qué texto público se deriva
de él. En la misma lectura transversal se precisará la separación entre `definicion`,
`descripcion`, `nota` y cualquier explicación derivada, sin duplicar un mismo dato en dos
campos.

**Hay que precisar qué hereda y qué puede restringir una reutilización.** El soneto reutiliza
el terceto aunque determina la rima de sus dos secciones, mientras el remate de la sextina
coincide con él en medida y extensión pero no en su norma consonante. Al cerrar la revisión
hay que auditar juntas todas las secciones reutilizadas y decidir si una composición puede
sobrescribir explícitamente parte de la arquitectura referenciada, si `Terceto` debe tener una
definición más amplia o si hace falta otra relación. No se corregirá un caso aislado antes de
resolver el significado general de la reutilización.

**La caja de las letras no es la clase de rima.**

`sincronizar_posiciones_esquema_rima_fijo` deriva las posiciones de la notación letra a letra y
**toma la caja por clase de rima**: de `-a-A` saca dos rimas donde hay una. La caja dice el arte
del verso, no con quién rima —la lira escribe `aBabB` y son dos rimas, no cuatro—. En la endecha
real hubo que corregirlo a mano. Volverá a pasar en cualquier rima entre arte menor y arte
mayor. Está anotado en [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md).

**Y la caja tampoco vive en el slug.** Conviene tenerlo claro porque induce a error: la caja es
dato —la mayúscula dice arte mayor— y se conserva en la columna `notacion`, `ABBAACCA`. Pero el
**slug de un esquema de rima va siempre en minúsculas**, sin excepción en todo el catálogo: la
octava real es `abababcc`, la lira `ababb`, el sexteto `ababcc`. Lo fija
[la norma de nomenclatura](./historico/revision-nomenclatura.md) —«la notación en
minúsculas»—, que incluso renombró un slug de la canción petrarquista por llevar mayúsculas.

Los slugs de caja mixta que sí existen están en **otras dos tablas**: `variedades_arquitectura`
—las siete tipologías del sexteto-lira, `a2_AbaBcC`— y once opciones de elección del soneto y
del propio sexteto-lira. Que existan ahí no significa que la convención de `esquemas_rima` haya
cambiado. Consultado el 8 de agosto de 2026: **se mantiene en minúsculas**, porque cambiarla
obligaría a renombrar todos los esquemas de rima del catálogo a cambio de nada que no diga ya
`notacion`.

---

## Documentos que acompañan a esta revisión

- [criterios-de-nivel.md](./criterios-de-nivel.md) — **de lectura obligada** antes de decidir si
  algo es arquitectura, esquema, variedad o rasgo. Es lo que resuelve las dudas de fondo.
- [donde-vive-la-prosa.md](./donde-vive-la-prosa.md) — los ocho criterios de redacción.
- [contratos-registrador-formas-revisadas.md](./contratos-registrador-formas-revisadas.md) —
  qué deriva y qué pregunta el editor en cada forma revisada.
- [revisiones-formas/cuestiones-para-el-ip.md](./revisiones-formas/cuestiones-para-el-ip.md) —
  lo que sigue sin decidir. Se poda a medida que se resuelve.
- [informe-conformidad-catalogo.md](./informe-conformidad-catalogo.md) — se regenera con
  `npm run audit:metrica`.
- [historico/plan-revision-del-catalogo.md](./historico/plan-revision-del-catalogo.md) — el
  diario de la fase A, ya cerrada: la normalización de nombres y la corrección de la caja de la
  rima. Archivado; su método vigente está fundido en este documento.

Las fichas `.md` de `revisiones-formas/` **se han retirado todas**. Del directorio solo queda
[cuestiones-para-el-ip.md](./revisiones-formas/cuestiones-para-el-ip.md), que no describe
formas sino decisiones pendientes. Lo descriptivo vive en el catálogo y se lee en `/formas`.

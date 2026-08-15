# Dónde vive la prosa del catálogo

Estado: **norma en aplicación** · abierto el 4 de agosto de 2026, en vigor desde el 5

El catálogo de formas de la web se genera del dato, así que todo lo que se lee ahí sale de
algún campo de texto del catálogo. Al construirlo apareció que **el mismo tipo de
información podía vivir en tres sitios distintos**, con las duplicaciones que eso trae.

Este documento era un aviso para auditar más tarde. Con la revisión ya en marcha pasa a ser
la norma que la gobierna: qué se escribe en cada campo y cuándo entra una fuente.

## La prosa del catálogo y la ayuda del editor

| Campo                           | Dónde                                                                                                    | Qué dice                                                                                                                                                                         |
| ------------------------------- | -------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `definicion`                    | `formas_metricas`                                                                                        | Qué **es** la forma, en tercera persona. No qué decidió el proyecto sobre ella, ni cómo se anota, ni qué hace el demarcador                                                      |
| `descripcion`                   | `arquitecturas_forma`, `variedades_arquitectura`, `esquemas_*`, `repeticiones_metricas`, `rasgo_valores` | Qué distingue a **esa** realización de sus hermanas. Si vale igual para todas, pertenece a la definición; si el nombre y los datos estructurados ya lo dicen, puede quedar vacía |
| `nota`                          | `estructuras_secciones`, `arquitectura_rasgos`, `esquema_rima_enlaces`                                   | Una precisión sobre esa parte concreta, **y solo si la ficha no la deriva ya del dato**                                                                                          |
| `afirmaciones_fuentes_metricas` | —                                                                                                        | Lo que una fuente **añade**, con su localizador                                                                                                                                  |

**Y una `nota` no debe llevar un dato que el catálogo podría declarar.** Es la regla 1 vista al
revés, y el barrido del 9 de agosto de 2026 encontró tres casos: la nota del endecasílabo suelto
decía «Ninguna u ocasionales», que era el subconjunto de grados admitidos y ahora es dato en
`arquitectura_rasgos`; la de la copla de pie quebrado decía cuál era el metro dominante, que
ahora lo dice `esquema_metrico_opciones.rol`; y la copla real sigue diciendo en prosa que solo
uno o dos de sus diez versos pueden quebrarse, que aún no es dato. El inventario está en
[el estado del catálogo](./revision-del-catalogo-estado.md#datos-asumidos-que-siguen-viviendo-en-prosa).

`repeticiones_metricas.regla` no debe convertirse en un quinto depósito de prosa. Su nombre
promete una restricción computable, pero hoy es texto libre. El efecto sí es ya dato de la
repetición —`materializa_seccion_id` y `extension_desde_seccion_id`, que dejaron de vivir en la
opción el 9 de agosto de 2026—; lo que queda es resolver qué dice `regla` y derivar de ella la
explicación pública. Anotado como revisión transversal en
[el estado del catálogo](./revision-del-catalogo-estado.md#defectos-del-modelo-aplazados).

**La pregunta del editor no es otro sitio de prosa.** Desde que las opciones se derivan del
catálogo, su etiqueta es el nombre de la entidad y su explicación es la `descripcion` de la
entidad: no hay dónde escribir prosa a la altura de la opción, ni falta. Escribirla dos veces
fue justamente lo que dejó a la quintilla describiendo su `aabab` como «cruzada, también llamada
Cuarteta», copiado de la redondilla, mientras su propio esquema decía lo correcto.

Tampoco el enunciado: se compone con la dimensión y el nombre de la sección. Para una elección de
rasgo se usa directamente `rasgos_metricos.nombre`. Las antiguas columnas
`formas_metricas.pregunta_arquitectura` y `rasgos_metricos.pregunta` solo reformulaban esos
nombres y se retiraron el 11 de agosto de 2026. El selector de arquitectura se llama siempre
«Arquitectura»; el contexto lo dan las opciones, no una pregunta especial escrita a mano.

Lo único específico del formulario que sigue escribiéndose es
`grupos_eleccion_metrica.ayuda_editor`, en el lugar exacto donde se toma la decisión. Su regla es
más estricta que la de una `nota`: **solo existe si hace falta un criterio para responder y ese
criterio no está ya en el nombre, las opciones, la descripción de estas, el rango o el control**.
El barrido del 11 de agosto retiró ayudas que repetían esos datos y conservó, por ejemplo, el
límite clasificatorio «si los pareados organizan sistemáticamente toda la secuencia, se registra
como tirada de pareados y no como silva».

El Editor V2 no vuelca las definiciones de la forma y la arquitectura. Muestra un resumen
estructurado de la norma elegida —extensión, partes, medidas y rimas fijas— y enlaza la ficha
pública completa en una pestaña nueva. Lo variable aparece en los controles inmediatamente
inferiores. Las explicaciones generales o complejas pertenecen a la guía del dashboard.

Ninguno de los campos del catálogo cuenta **cuándo se rellena** ni **de qué término legado vino**. «Solo se
declara cuando caracteriza la secuencia» describe el formulario; «heredada de
`octava_real_de_esdrujulos`» cuenta la migración. Estaba en cinco `arquitectura_rasgos.nota` y
ahora dice qué es el rasgo en esa forma: «Terminación esdrújula sostenida en los finales de
verso».

## Las tres reglas

**1 · No escribir lo que la ficha deriva.** La ficha genera frases a partir del dato: el
comportamiento de un enlace de rima, el arte de una notación, el número de versos de una
sección. Escribir a mano lo que ya se deriva produce la frase dos veces seguidas y, en
cuanto uno de los dos cambia, produce dos frases que se contradicen. Una `nota` se escribe
solo cuando la derivada se queda corta.

> El romance llegó a decir, seguidas: «el par mantiene la misma clase de asonancia durante
> toda la serie» (descripción del esquema) y «la misma asonancia de los versos pares se
> conserva al repetir el ciclo» (nota del enlace). La descripción dice la **forma del
> ciclo**; el enlace dice **qué se conserva al repetirlo**, y eso la ficha lo deriva.

**2 · Una fuente entra cuando añade.** La pregunta que decide es: _¿qué sé después de leer
esta afirmación que no supiera por la definición?_ Si la respuesta es «nada», la afirmación
sobra por muy autorizada que sea la fuente. Parafrasear la definición con firma no la
respalda: la alarga.

**3 · Se aspira a las seis.** Las seis monografías se consultan para cada forma, y entra la
que tenga algo propio que decir. Que una forma se apoye en dos fuentes cuando las otras
cuatro también hablan de ella es un vacío de lectura, no una decisión. La que de verdad no
diga nada, se calla; y que se calle es en sí un dato.

**4 · Una afirmación dice lo que dice su fuente, y nada más.** No opina sobre el catálogo
—«el catálogo conserva», «el proyecto adopta»—, no valora la bibliografía —«mide lo poco
fijado que está»— y no explica de dónde salen nuestros nombres. Contrastar una fuente con
otra sí vale: es lo que hacen entre sí Quilis y Jauralde sobre el soneto regular. Si la
divergencia entre una fuente y el catálogo importa, se escribe **el dato de la fuente** y la
divergencia se lee sola al ponerla junto a la definición.

**5 · Cada afirmación se lee sola, bajo su propia cita.** No da por sabido lo que solo está
dicho en otra: «repite la definición del Diccionario» supone que el lector ya sabe que hay
otra obra del mismo autor así llamada.

**6 · Los nombres del proyecto son los del proyecto.** Si una fuente llama «sexteto» a los
dos tercetos del soneto, eso sale en su cita; en las definiciones son dos tercetos, porque
así se separan las posiciones y así se vinculan las secciones. Y cuando dos fuentes
discrepan sobre qué es lo regular —Quilis da `ABBA ABBA CDC DCD`, Jauralde `CDE DCE`—, el
catálogo marca uno y señala que el otro difiere, sin equipararlos.

**7 · La definición acaba donde acaba lo que define.** No se alarga por alargarla. Fuera lo
que valdría para cualquier forma —«la tradición ha ido reconociendo las que aparecen»—, fuera
lo que la ficha dice dos líneas más abajo, y fuera la enumeración de lo que se lista debajo.
Si una arquitectura no precisa nada sobre su forma, se queda vacía; si la definición ya lo ha
dicho todo en una frase, se corta ahí.

**8 · «Reutiliza» no se entiende sin decir qué.** Una sección que toma el repertorio de otra
forma tiene que nombrarla: «riman como el cuarteto endecasílabo, que el catálogo recoge como
forma aparte», no «reutiliza la configuración simple». Y cuidado con explicar de más: «el
soneto no se formó sumando cuartetos» decía lo contrario de lo que se lee, porque el soneto
está hecho justamente de dos cuartetos y dos tercetos.

**9 · La descripción no cita; la afirmación no generaliza.** Es la regla 4 vista desde el otro
lado, y salió al revisar la seguidilla el 15 de agosto de 2026: las descripciones y las
afirmaciones se estaban diciendo lo mismo dos veces, una con firma y otra sin ella. Un nombre
entra en una `definicion` o una `descripcion` solo si es **parte del hecho**, no si es **quien lo
atestigua**. Sor Juana inventó la seguidilla real y por eso se llama así: el nombre es el hecho y
se queda. Que Correas la diera por regular a principios del XVII es el testimonio de un hecho que
se dice sin él —«ya era regular a principios del XVII»—, y Correas se va a su afirmación con su
localizador. Al revés, la afirmación aporta **lo localizado** —el ejemplo, el pasaje, la cifra, el
desacuerdo entre fuentes— y no repite la caracterización que la descripción ya hizo.

> La descripción de la seguidilla de tres versos dice que «fue bastante corriente a principios del
> siglo XVII»; la afirmación de Navarro Tomás § 216 trae el ejemplo de Lope en *Los pastores de
> Belén*. La primera se lee sin la segunda, y la segunda añade la prueba.

El destinatario por defecto es **la forma**. Una afirmación cuelga de una arquitectura solo
cuando lo que dice la fuente es exclusivamente de esa realización —«endecha» nombrando al
romancillo heptasílabo— y no del reparto de nombres en general.

## Se escribe en Markdown

Los campos de prosa admiten Markdown de una línea y la web lo interpreta: `**negrita**`,
`*cursiva*`, `` `código` `` y `[enlaces](/ruta)`. Lo hace
[`renderInlineMarkdown`](../../src/lib/utils/markdown.ts), que escapa el HTML antes de
interpretar las marcas, de modo que el texto del catálogo no puede inyectar etiquetas.

Sirve para lo que la prosa métrica necesita a menudo: destacar la palabra sobre la que gira
una discrepancia entre fuentes. «Tras el cuarto verso **debe** haber una pausa» dice, con esa
negrita, que la discusión está en el verbo — el Diccionario lo exige y Morley y Bruerton no.

Donde no cabe HTML —el `<meta name="description">` de la ficha— se imprime `stripMarkdown`,
que da el mismo texto sin marcas. Las dos salidas tienen que decir lo mismo, y hay pruebas
que lo comprueban en `src/lib/utils/markdown.test.ts`.

Con moderación: la negrita marca el punto en discusión, no adorna. Una definición entera en
negrita no destaca nada.

## Los localizadores

En castellano llano: nada de `s. v.`, `op. cit.` ni `ibid.`, que el lector de la web no
tiene por qué descifrar. Cada volumen tiene su unidad estable:

| Fuente                  | Se cita por          | Por qué                                                      |
| ----------------------- | -------------------- | ------------------------------------------------------------ |
| Domínguez Caparrós 2014 | Página               | El volcado conserva las 252 páginas                          |
| Diccionario 2016        | Entrada, y su página | Es alfabético: la entrada localiza mejor que el número       |
| Quilis 1969             | Página               | Escaneado por pliegos de dos, así que el bloque da un par    |
| Navarro Tomás 1972      | Epígrafe numerado    | Conserva 37 números en todo el libro; los `§` sí son fiables |
| Jauralde Pou 2020       | Título de sección    | Viene de un epub sin paginar                                 |
| Morley y Bruerton 1968  | Capítulo y epígrafe  | Se trabaja sobre el `.md`                                    |

[`scripts/lib/localizar.mjs`](../../scripts/lib/localizar.mjs) da la página de un pasaje
sobre los volcados de `bibliografía/txt/`: parte por saltos de página y devuelve los números
sueltos del bloque. Sirve para los tres primeros; para los otros tres no hay página que dar.

## Formas generales

El catálogo registra formas que no son unidades del repertorio áureo sino **descripciones
generales**: el cuarteto, el terceto, el pareado, el sexteto. Se registran de manera funcional,
porque el catálogo métrico se abrió más allá del corpus y porque sirven para describir lo que
otras formas reutilizan —los cuartetos del soneto riman como el cuarteto endecasílabo—.

Una forma general no tiene por qué tener afirmaciones de las seis fuentes ni una historia
propia: puede que la bibliografía apenas la trate como forma independiente. Eso también es un
dato, y se dice —Morley y Bruerton no definen el cuarteto: lo mencionan como uno de los
cierres posibles de un pasaje de sueltos—.

**Al revisar puede aparecer que faltan más.** Si una descripción necesita nombrar una unidad
que el catálogo no tiene, conviene anotarlo en
[cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md) en vez de rodearla.

## Lo que queda por mirar en el barrido

1. **Definiciones que en realidad son decisiones del proyecto.** «El catálogo reconoce
   realizaciones de seis, siete y ocho sílabas» es una decisión, no una definición de la
   redondilla. Su sitio es la descripción de cada arquitectura.
2. **Descripciones que repiten la definición** de su forma, palabra por palabra o casi.
3. **Razonamientos que hoy solo están en `revisiones-formas/`** y no en el dato: por qué
   `aabaa` no está en el repertorio de la quintilla, por qué la hexasílaba se corrigió de
   siete a seis, por qué «Silva libre» sigue siendo arquitectura pese a compartir esquemas
   con la irregular. Si merecen sobrevivir, su sitio es el catálogo.
4. **Dónde el proyecto se aparta de la bibliografía.** Morley y Bruerton describen a Lope; el
   catálogo cubre el Siglo de Oro y algo más, y en varios puntos es deliberadamente más
   amplio —la redondilla cruzada, la copla real—. Esa diferencia es información que merece
   afirmación propia, no un desacuerdo que haya que ocultar.
5. **Las afirmaciones que se fueron con las fuentes retiradas.** Villancico, copla de pie
   quebrado y décima ya recuperaron su respaldo tras consultar las seis fuentes autorizadas.
   Siguen pendientes redondilla doble, zéjel y copla real; al revisar cada una se busca en las
   seis el equivalente de lo que sostenían las fuentes retiradas.

## El destino de `revisiones-formas/`

Desaparecer. Lo descriptivo pasa al catálogo y se lee en la web; lo que quede abierto vive
en [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md). Hasta que una forma
se revise, su ficha sigue siendo el único sitio donde está el porqué.

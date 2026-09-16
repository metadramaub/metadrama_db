# Plan de auditoría de las afirmaciones de las fuentes

Escrito el 11 de septiembre de 2026. **Qué queda por hacer y en qué orden está en
[PENDIENTES](../PENDIENTES.md), bloque E**; este documento
describe el método y no se reescribe cada semana.

Se ejecuta por fases y cada una tiene criterio de salida: se puede parar entre dos sin dejar nada a
medias.

La sección «Lo que dicen las fuentes» de cada forma se construyó buscando en los volcados `.txt`
de las seis monografías y consultando después el PDF para dar con la página o el epígrafe. **Nadie
ha comprobado después que el pasaje esté donde se dice, que diga lo que se le atribuye y que no se
haya quedado fuera lo que importaba.** Este plan lo comprueba de manera que el resultado pueda
enseñarse: cada veredicto lleva su fragmento literal y su posición en el fichero, y quien dude
puede repetir la comprobación sin fiarse de nosotros.

## Lo que había al empezar

Contado contra la base el 11 de septiembre de 2026, antes de tocar nada.

| Fuente | Afirmaciones | Con página | Con § | Con epígrafe o entrada |
| --- | --- | --- | --- | --- |
| Morley y Bruerton 1968 | 36 | 0 | 0 | 35 |
| Quilis 1969 | 37 | 15 | 25 | 0 |
| Navarro Tomás 1972 | 51 | **6** | 49 | 8 |
| Domínguez Caparrós 2014 | 41 | 35 | 0 | 1 |
| Diccionario 2016 | 59 | 26 | — | 59 |
| Jauralde Pou 2020 | 43 | 0 | 3 | 41 |
| | **267** | **82** | | |

**43 formas activas y 223 pares forma-fuente cubiertos de los 258 posibles.**

Todo esto se publica en `/formas`, en la sección `#fuentes` de cada ficha. Una invención confirmada
no es una deuda interna: está en la web. Por eso se audita.

## Sobre qué se contrasta cada fuente

| Fuente | Material | Qué permite comprobar |
| --- | --- | --- |
| Morley y Bruerton 1968 | `definiciones_Morley&Bruerton.md` | **Copia a mano del capítulo V, confirmada fiel por David el 11 de septiembre de 2026.** Vale como original: se audita contra ella sin reservas y no hace falta el volumen de Gredos |
| Quilis 1969 | txt con saltos de página + PDF | página y §, con la cautela de que el PDF escaneó pliegos dobles y `localizar` devuelve pares |
| Navarro Tomás 1972 | txt con los §§ en el cuerpo + PDF | el § es verificable en el txt; **la página solo en el PDF**, porque el volcado conserva 37 números en 573 páginas |
| Domínguez Caparrós 2014 | txt paginado + PDF | página y pasaje, mecánicamente |
| Diccionario 2016 | txt paginado + PDF | la entrada existe o no existe, y la página |
| Jauralde Pou 2020 | txt de epub, sin paginar | solo el epígrafe: **cualquier página citada aquí es sospechosa por construcción** |

Las convenciones de cita de cada una están en [las fuentes del catálogo](./fuentes-del-catalogo.md)
y no se rediscuten aquí: la auditoría comprueba que se cumplen, no las cambia.

### El volcado no es el libro

**El `.txt` conserva bien el texto y reconstruye mal la estructura.** No es una cautela teórica:
en la fase 0 mordió cuatro veces en una tarde. El volcado de Quilis fundía las dos columnas del
libro línea a línea, de modo que una cita literal podía ser un empalme de dos columnas distintas
—se regeneró—; en Caparrós 2014 los números del índice son indistinguibles de los pies de página;
en Navarro el número va pegado al titulillo; y en Jauralde no hay páginas en absoluto.

De ahí la regla: **el volcado sirve para encontrar el pasaje y para leer su letra; la página y la
estructura se confirman en el PDF.** Un número de página que sale de un `.txt` es una inferencia
de quien lo extrajo, no un dato del libro. Se comprueba con `pdftotext -f N -l N` sobre la hoja
del PDF, o abriendo esa hoja, y **se anota qué número impreso se ha visto en ella**. Sin esa
comprobación, una página no se da por buena.

Cuidado con la diferencia entre **hoja del PDF y página impresa**: no coinciden —hay preliminares,
y el PDF de Quilis escaneó pliegos de dos páginas—, así que el desfase se establece una vez por
libro y se verifica leyendo el número en la hoja.

## 1. Qué cuenta como defecto

Sin esta lista, dos verificadores devuelven veredictos que no se pueden comparar ni sumar.

**Graves — la afirmación no se sostiene**

1. **Invención.** Nada en la fuente respalda lo dicho.
2. **Atribución cruzada.** Lo dicho está en otra de las seis, no en esta.
3. **Mezcla.** Funde dos pasajes distantes, o un pasaje con una inferencia nuestra, y lo presenta
   como una sola voz.
4. **Endurecimiento.** La fuente matiza —«suele», «a veces», «no es frecuente», «es posible
   encontrar»— y la afirmación afirma. **Es el defecto más probable y el más difícil de ver**,
   porque el resumen sigue pareciendo correcto.

**Medios — está, pero mal dicho o mal puesto**

5. **Localizador falso.** La página, el § o la entrada no contienen el pasaje.
6. **Cita literal inexacta.** Lo entrecomillado en «» no es textual.
7. **Omisión relevante.** El pasaje dice algo que cambia la lectura y la afirmación lo calla.
   Cuenta doble cuando lo callado contradice al catálogo.
8. **Anclaje equivocado.** Cuelga de la forma o la arquitectura que no es.

   **Cuidado: esta etiqueta se ha usado en dos sentidos y solo uno es este.** Las dieciocho
   afirmaciones que la llevan no cuelgan de la fila equivocada: lo que describen es que **una
   cláusula viene de un § o una página distintos de los que se citan**, que es de la familia del
   localizador y obliga a partir el localizador o a recortar el texto. El defecto de columna —el
   que aquí se define— **no lo detectó ningún verificador**: lo encontró la comprobación mecánica
   de anclaje, y el caso que lo destapó fue la silva arromanzada.

**Leves — formales**

9. **Convención rota.** Cita por página una fuente que se cita por §, o llama «Entrada» a un
   epígrafe de capítulo. *Ya hay un caso visto: «Entrada «Sestina»» en Morley y Bruerton, donde el
   epígrafe existe y solo está mal etiquetado.*
10. **Anacronismo de edición.** Página de una edición distinta de la citada.

**La gravedad se respeta en el informe.** Uno que mezcle una etiqueta mal puesta con una invención
pierde la fuerza justamente donde hace falta.

## 2. Los cuatro niveles de comprobación

**Nivel 0 — mecánico, sin agentes.** Recorre las 267 y comprueba lo que no exige leer: que el
localizador respeta la convención de su fuente, que la entrada del Diccionario existe como entrada,
que el § de Navarro existe en el txt, que el epígrafe de Jauralde existe como encabezado, que la
página declarada cae dentro del libro. Devuelve ya una lista de sospechosos y **cuesta cero**.

**Nivel 1 — extracción del pasaje.** Dado el localizador, saca el pasaje y su contexto a un fichero
pequeño de evidencia. `scripts/lib/localizar.mjs` ya hace la mitad. Para las 82 con página hay que
resolver antes, **una vez por libro**, el desfase entre la página impresa y la hoja del PDF, y
verificarlo con `pdftotext -f N -l N`: es la trampa clásica de este trabajo y explicaría por sí
sola una tanda entera de errores.

**Nivel 2 — juicio de fidelidad.** Aquí entran los agentes, y solo aquí. **Reciben el extracto, no
el libro.**

**Nivel 3 — adjudicación.** Solo lo que discrepe entre pasadas.

## 3. El doble ciego

Tres pasadas independientes que no se ven entre sí. Atacan cosas distintas y cuestan distinto.

- **Pasada A · verificador.** Recibe afirmación, localizador y extracto. Dictamina por la
  taxonomía. **Obligado a transcribir el fragmento literal que sostiene cada parte de la
  afirmación.** Barata. Caza invención, cita inexacta y anclaje.
- **Pasada B · reconstrucción ciega.** Recibe **solo el pasaje y el nombre de la forma, nunca la
  afirmación**, y escribe con sus palabras qué dice esa fuente de esa forma. Después se compara su
  resumen con el de la base: lo que está en la base y no en B es candidato a invención o
  endurecimiento; lo que está en B y no en la base es candidato a omisión. **Es la cara y la única
  que encuentra el matiz perdido.**
- **Pasada C · localización ciega.** Recibe **solo el texto de la afirmación, sin localizador**, y
  busca por su cuenta dónde lo dice la fuente, con `grep` sobre el txt y sin cargarlo entero. Si
  aterriza en otro sitio, el localizador está mal.

**La pasada B dejó de ser opcional el 11 de septiembre de 2026.** Se pensó recortarla por coste y
correr solo A y C. La primera muestra humana lo desmintió: de cuatro afirmaciones comprobadas a
mano, **una que el verificador había dado por conforme era un endurecimiento**. El catálogo decía
que Morley y Bruerton «reservan el nombre de lira» para un esquema que ellos dan solo como el más
corriente, enumerando otros tres, y que además admiten expresamente para la estrofa de cinco
versos. Ninguna comprobación mecánica lo habría visto: las citas estaban bien y el resumen sonaba
correcto.

De ahí la regla: **un «conforme» de una sola pasada no basta**, porque el endurecimiento es
invisible desde dentro del propio veredicto. A y C son el suelo; B es lo que sostiene las
conformes, que son cuatro de cada cinco afirmaciones.

Discrepancia entre pasadas → adjudicación con Opus, que ve las tres y el pasaje, nunca el
razonamiento de los agentes sobre lo que *debería* decir un manual de métrica.

## 4. Cómo se evita que el auditor mienta también

Sin esta sección lo demás no vale nada: un agente puede inventar tanto como quien anotó.

- **Ningún veredicto sin fragmento literal y su línea en el fichero.** Un script relee el txt en
  ese punto y comprueba que el fragmento está ahí, carácter a carácter. **El agente que cite mal
  queda invalidado por máquina, no por otro agente.**
- **Prohibido el conocimiento propio.** Si no está en el extracto, no existe. Nada de confirmar
  por memoria que Navarro Tomás «efectivamente sostiene» algo plausible: es el modo exacto en que
  un auditor de métrica española da por buena cualquier cosa bien escrita.
- **Errores sembrados.** Antes de empezar en serio se corrompen a propósito una docena de
  afirmaciones reales —cambiar una página, invertir un esquema de rima, convertir un «suele» en un
  «siempre», atribuir a Quilis lo de Caparrós— y se mezclan sin marca con las verdaderas. **Si una
  pasada no caza el 90 % de las sembradas, sus resultados se tiran y se reescribe el prompt.** Es
  lo único que mide si el sistema funciona; sin esto, «267 verificadas» es una frase vacía.
- **Muestra humana del 10 %**, al azar y contrastada contra el PDF, incluyendo casos que las tres
  pasadas dieron por buenos. Un auditor que solo se revisa donde ya sospecha no se revisa.
- **La auditoría no corrige nada.** Emite dictámenes. Las correcciones son un paso aparte y con
  visto bueno; las que sean dudas filológicas y no errores materiales van a
  [cuestiones para el IP](./cuestiones-para-el-ip.md).

### La ficha de dictamen

Una por afirmación, y **es el entregable de verdad**: no un veredicto suelto, sino lo que hace
falta para que otro pueda rehacer el juicio sin repetir el trabajo ni fiarse de nadie. Los tres
campos que la sostienen son el texto original literal, el texto que el catálogo registra y **la
explicación de por qué es esa página o esa sección**, con lo que se vio al comprobarlo.

```json
{
  "afirmacion_id": "…",
  "forma": "Octava real",
  "fuente": 2016,
  "localizador_declarado": "Entrada «octava real», p. 246",
  "naturaleza": "cita | silencio",

  "por_que_ahi": "La entrada «octava real» abre en la línea 10384 del volcado. La hoja 259 del PDF lleva impreso el número 246 y contiene esa entrada.",
  "confirmacion_pdf": { "hoja": 259, "numero_impreso": 246, "coincide": true },

  "texto_original": "octava real. Estrofa de ocho versos endecasílabos, de los que riman en consonante… Es posible, aunque no frecuente, encontrar otra disposición de la rima de los seis primeros versos.",
  "texto_registrado": "Advierte que «es posible, aunque no frecuente, encontrar otra disposición de la rima de los seis primeros versos»…",

  "veredicto": "conforme | defecto | duda_filologica",
  "defectos": [ { "tipo": "endurecimiento", "gravedad": "grave",
                  "cita_literal": "es posible, aunque no frecuente…", "linea": 12351 } ]
}
```

**Un silencio no tiene página, tiene ámbito.** No hay pasaje que señalar, así que declarar una
página sería inventarse un sitio. Lo que el localizador debe decir es **qué se recorrió para
concluir que no estaba**: `Cap. V, pp. 38-41` si la afirmación abarca el repertorio entero, o
`Cap. V, «Metros Españoles», pp. 38-39` si solo alcanza esa parte. Es lo único comprobable de una
ausencia, y además obliga a acotar: varias afirmaciones dicen «su repertorio» cuando en realidad
solo se miraron los metros españoles, y por ahí se colaron los contraejemplos.

**Una afirmación puede consistir en un silencio** —que una fuente no registre una forma—, y
entonces no hay pasaje que transcribir: el dictamen enumera lo que esa fuente sí recoge en esa
zona de su repertorio y razona la ausencia. Por eso declara su `naturaleza`: de una cita se exige
transcripción literal; de un silencio, el recuento de lo que hay. **Un silencio mal comprobado es
tan falso como una cita inventada**, y comprobarlo exige leer el repertorio entero, no el epígrafe
citado.

**`texto_original` se transcribe, no se resume**, y `npm run valida:dictamenes` comprueba después
que esa transcripción aparece de verdad en el fichero. Es lo que permite cotejar original y registro uno
al lado del otro, que es como se ve el endurecimiento y la omisión: leyendo los dos.

### Lo que solo se ve cruzando fichas

Un verificador mira una afirmación y no puede ver lo que solo aparece al comparar varias. Hay al
menos un defecto de esa clase, encontrado el 11 de septiembre de 2026 buscando una expresión en las
267: **una explicación de una fuente copiada en fichas de otra**.

La cláusula «su repertorio de enlaces entre estrofas es el de la gaya ciencia […] que Navarro Tomás
distingue expresamente de estas series enlazadas» aparece en cuatro afirmaciones. En la de Navarro
Tomás es legítima —es su terminología—. Las otras tres cuelgan del *Diccionario*, y **«gaya ciencia»
no aparece en ese diccionario**: el razonamiento se importó de una fuente y se firmó con el
localizador de otra. Dos verificadores distintos lo detectaron por su cuenta, cada uno en su lote,
sin saber que había más casos.

De ahí una comprobación para esta fase, que es mecánica y barata: **buscar las expresiones
características de cada fuente en las afirmaciones de las demás**. No se trata de penalizar que dos
fichas se parezcan —si una fuente explica dos formas juntas, deben parecerse—, sino de encontrar
vocabulario que una fuente no usa puesto en su boca.

### Lo que las dos pasadas no pueden ver

**Los lotes se construyeron desde las afirmaciones que existen**, así que una forma sin ninguna
queda fuera de A y de B y ningún verificador la mira nunca. Hay dos así, y las dos son de la serie
alirada: **Décima-lira y Novena-lira, con cero afirmaciones de las seis monografías**. Se crearon
el 24 de agosto de 2026 al sistematizar la serie entera, por coherencia del sistema, y a estas dos
no se les buscó fuente.

Y al menos una la tiene, localizada ya: el **§ 161 de Navarro Tomás** documenta las estrofas
aliradas de siete, ocho y nueve versos como desarrollos del sexteto, con sus esquemas y sus
autores —`abCabCcdD` de Figueroa y `AbCAbCcdD` de Góngora para la de nueve—. El mismo pasaje que
sostiene el septeto-lira sostiene la novena-lira, y de él solo se extrajo lo primero.

Salió cotejando: al septeto-lira el cotejo le señaló dieciséis esquemas sin registrar, y al
comprobar si estaban en las fichas vecinas resultó que **diez no están en ninguna afirmación
alirada de Navarro**. Los esquemas huérfanos no eran ruido: eran pasajes que el catálogo no recoge
en ninguna parte.

**Ninguna de las dos debería publicarse sin fuente**, con su sección «Lo que dicen las fuentes»
vacía, teniendo el pasaje localizado.

### Y un pasaje que nos toca de lleno y no recoge nadie

La entrada «soneto» del *Diccionario* (pp. 409-410) cierra así: **«El soneto es una forma propia de
la poesía lírica, y difícilmente se encontrará en las partes dialogadas del teatro.»** Es una
afirmación sobre el soneto **en el teatro**, en una base de datos de verso dramático, y ninguna de
las dos afirmaciones que cuelgan de esa entrada la recoge.

Salió al releer a ciegas la del soneto —la única de las 267 cuya transcripción no era una
transcripción, sino una nota que remitía a otra ficha—. La relectura confirmó que lo que sí
recogíamos era exacto, palabra por palabra, y de paso enseñó lo que se había quedado fuera. **Es
el argumento de la fase 4 en una línea: comprobar que una afirmación dice la verdad no comprueba
que diga todo lo que la fuente dice de nosotros.**

### Las tres comprobaciones que miran la columna, no el texto

`npm run senales:mecanicas`, sobre las **267**. Salieron de los tres huecos que dejó la muestra
humana de la segunda ronda, y las tres buscan defectos que **no se ven leyendo una ficha sola**,
que es lo único que se le pidió a A y a B.

| | Qué busca | Señaladas |
| --- | --- | --- |
| 1 · Anclaje | Afirmación colgada de la forma que habla de una arquitectura | **29** de 267, 4 con las dos señales |
| 2 · Esquemas huérfanos | Esquema que la fuente da, la ficha no registra y el catálogo no tiene en ninguna parte | **25** fichas con alguno sin rastro |
| 3a · Nombra otra fuente | Autor o libro ajeno dentro de la voz de una fuente | **14** de 267 |
| 3b · Tirada compartida | Siete palabras seguidas o más en afirmaciones de fuentes distintas | **29** pares |
| 4 · Endurecimiento | La fuente matiza en la frase que la ficha resume y la ficha no | **21** de 267 |

**La cuarta se añadió el 18 de septiembre de 2026**, `npm run senal:endurecimiento`, y nació de un
hueco: la señal de endurecimiento venía hasta entonces de la pasada B, de modo que solo existía si
el lector ciego se fijaba —y no distinguía «la fuente no matiza» de «B no lo anotó»—. Empareja el
resumen con las oraciones del pasaje que comparten con él una tirada de seis palabras, y mira si
matizan donde el resumen no matiza. **Cubre 153 de las 267**; las otras 114 parafrasean sin reutilizar
el léxico de la fuente y quedan fuera de alcance, lo que también es un dato: son las que solo puede
comprobar una lectura.

**El anclaje se mira por dos caminos y lo que vale es el cruce.** Uno: el texto nombra, con una
denominación de dos palabras o más, una sola arquitectura de su forma —se exigen dos palabras
porque «octosílaba» sale en cualquier página de métrica—. Otro: la misma fuente ancló otras
afirmaciones de esa misma forma en arquitecturas y esta no. Las cuatro que dan las dos señales
incluyen la silva arromanzada, que es el caso conocido: el comprobador encuentra lo que ya se
sabía que estaba mal.

**Los esquemas huérfanos se ordenan por dónde está el esquema**, no por si está. De los 203 que la
fuente da y la ficha no registra, 40 están modelados en `esquemas_rima` de esa forma, 21 los
registra una afirmación hermana y 67 aparecen colgando de otra forma: **nada de eso es trabajo**.
Solo los 75 restantes, repartidos en 25 fichas, no están en ninguna parte del catálogo, y solo
esos pueden ser una laguna. Es la clasificación que destapó la novena-lira.

**La lectura de esquemas es el punto frágil de todo esto.** El alfabeto de rima usa `a`–`h`, y con
esas ocho letras se escriben palabras españolas: la primera versión leía `decada` veinticinco
veces, que era «de cada» unida por encima del espacio. `scripts/lib/esquemas.mjs` exige ahora tres
letras a cada lado del espacio y descarta las palabras conocidas. **El cotejo de las dos pasadas
se quedó con su lectura antigua a propósito**, porque de su salida se sorteó la muestra humana y
cambiarla ahora movería los estratos de una muestra ya cerrada.

Las cifras son las del 13 de septiembre de 2026, con la pasada B ya completa sobre las 267.

## 5. La otra mitad: lo que falta

La regla de exhaustividad dice que toda fuente que trate una forma tiene su afirmación, y que el
silencio de una fuente también se registra. Eso no se audita por afirmación —una afirmación que no
existe no se puede leer— sino **por forma**: 43 unidades × 6 fuentes = 258 celdas.

Lo dibuja `npm run matriz:exhaustividad`, que cuenta para cada celda vacía cuántas veces nombra esa
fuente a esa forma bajo cualquiera de sus denominaciones. **Ese recuento ordena el trabajo y no
decide nada**, y conviene saber por qué, porque falló dos veces en la propia fase 4:

- **«cuarteto lira» sin guion no contaba como «Cuarteto-lira»**, y la celda de Caparrós 2014 salía a
  cero teniendo el epígrafe delante. Arreglado tratando el guion como espacio.
- **«Novena-lira» no aparece en ningún libro**, porque es nombre nuestro para algo que Navarro
  describe sin bautizar. Eso no tiene arreglo mecánico.
- **«Octeto-lira» era un sinónimo que el catálogo no tenía.** Jauralde llama así a la octava-lira, y
  como el contador busca las denominaciones registradas, dio cero y la celda pasó por silencio. Se
  arregló registrando la denominación, pero el fallo vuelve cada vez que una fuente use un nombre
  que no esté: **el contador mide lo que el catálogo sabe llamar, no lo que el libro dice.**

De ahí que cada celda vacía se abra una a una, y que el resultado de cada una sea una de tres cosas:
laguna, falso positivo del contador, o silencio justificado que hay que **dejar escrito** —la ficha
pública enseña seis fuentes y el lector no puede distinguir entre «no lo dice» y «no lo hemos
mirado»—.

## 6. Las fases

| Fase | Qué | Criterio de salida |
| --- | --- | --- |
| 0 | Inventario y niveles 0 y 1. Script `npm run audit:fuentes` | 267 extractos generados; lista de localizadores que no resuelven; desfase de página fijado en los cinco PDF |
| 1 | **Piloto** sobre el Diccionario 2016 —59, la más mecanizable— con los errores sembrados | ≥ 90 % de sembrados cazados y coste real por afirmación medido. **Aquí se decide si se sigue** |
| 2 | Navarro 1972 (51) y Morley y Bruerton (36) | dictamen de las 87 |
| 3 | Jauralde (43), Quilis (37), Caparrós 2014 (41) | dictamen de las 121 |
| 4 | Exhaustividad, 43 formas | matriz forma × fuente completa, con cada hueco justificado |
| 5 | Informe, correcciones propuestas y muestra humana | informe firmado y repetible por un tercero |

**La auditoría terminó el 16 de septiembre de 2026.** Qué se hizo y qué enseñó, en el
[registro](./historico/auditoria-de-fuentes-2026-09.md); lo que dejó abierto, en
[PENDIENTES](../PENDIENTES.md), bloque E.

La fase 1 existía para decidir si merecía la pena seguir. Se siguió.

Se empezó por el Diccionario y no por lo más sospechoso porque es donde la máquina puede decir quién
tiene razón, y eso es lo que calibra el método antes de gastarlo.

## 7. Modelos y coste

Sonnet en A, B y C; Opus solo adjudicando y redactando. Agrupando unas diez afirmaciones por agente
y trabajando **siempre sobre extractos, nunca sobre el libro entero en contexto**, salen del orden
de 60–90 ejecuciones de Sonnet para las tres pasadas y unas 20 más para la exhaustividad.

Es tarea de `Workflow`, que hace el reparto determinista con esquema de salida y permite reanudar
sin repetir lo ya hecho. Levanta muchos agentes de golpe, así que hay que pedirlo explícitamente en
cada fase.

## 8. Los entregables

`docs/dominio-metrico/auditoria-fuentes/` con el método, los dictámenes en JSON con su evidencia
—para que cualquiera repita la comprobación— y el informe ordenado por gravedad. Y el script que
regenera los niveles 0 y 1, como los demás informes del proyecto, **para que no envejezca**.

Si al final quiere dejarse constancia en la base de qué se verificó y cuándo, eso es una migración
y se decide aparte, cuando haya resultados que registrar.

## 9. Qué dolió de verdad

Las cuatro sospechas con que se escribió el plan —las seis páginas de Navarro, las tres de Jauralde,
los pliegos dobles de Quilis y el endurecimiento invisible— resultaron ciertas las cuatro y se
resolvieron. Lo que no se había previsto es esto, que es lo que hay que recordar:

**Ninguna pasada es fiable sola.** La B se equivocó en tres de las cuatro veces que disintió de la
A; la C dio tres páginas erróneas de Quilis seguidas; y la A llegó a **inventarse una cita de la
fuente** para acusar a una ficha de inventársela. Solo abrir el libro decide. De ahí que la tercera
lectura sea política fija y no recurso excepcional.

**Las guardas encuentran lo que nadie pensó en buscar.** Una guarda que solo iba a comprobar que una
cláusula falsa desaparecía del catálogo encontró una cuarta ficha con ella, sentada en el cubo de
las conformes. De ahí que las guardas cuenten antes de tocar y afirmen el invariante, en vez de
comparar con totales contados a mano —que también fallaron—.

**Los defectos vienen en familia.** Una cláusula se escribe una vez y se copia a las fichas
hermanas: «pp. 205 y ss.» ×5, «Octavillas y octavas» ×4, «Índice de estrofas» ×4 —un epígrafe de
Navarro dentro de fichas de Caparrós—. Y el catálogo parte a veces un solo pasaje de una fuente
entre dos de sus formas, de modo que cada ficha describe el contenido de la otra: pasó con la
octavilla de Quilis y con la séptima y la septilla de Navarro.

**El original manda, y el epub también es original.** Durante semanas las instrucciones dijeron que
el de Jauralde «no hacía falta». Sí hacía: conserva la jerarquía de encabezados que el `.txt` aplana
—vuelca las versalitas como «E STROFAS DE OCHO VERSOS»— y sin ella no se distingue un rótulo del
cuerpo de un epígrafe real, ni dos epígrafes que el libro repite.

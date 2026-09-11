# Plan de auditoría de las afirmaciones de las fuentes

Estado: **escrito el 11 de septiembre de 2026, sin iniciar.** Se ejecuta por fases y cada una
tiene criterio de salida: se puede parar entre dos sin dejar nada a medias.

La sección «Lo que dicen las fuentes» de cada forma se construyó buscando en los volcados `.txt`
de las seis monografías y consultando después el PDF para dar con la página o el epígrafe. **Nadie
ha comprobado después que el pasaje esté donde se dice, que diga lo que se le atribuye y que no se
haya quedado fuera lo que importaba.** Este plan lo comprueba de manera que el resultado pueda
enseñarse: cada veredicto lleva su fragmento literal y su posición en el fichero, y quien dude
puede repetir la comprobación sin fiarse de nosotros.

## Lo que hay hoy

Contado contra la base el 11 de septiembre de 2026, no copiado de ningún documento.

| Fuente | Afirmaciones | Con página | Con § | Con epígrafe o entrada |
| --- | --- | --- | --- | --- |
| Morley y Bruerton 1968 | 36 | 0 | 0 | 35 |
| Quilis 1969 | 37 | 15 | 25 | 0 |
| Navarro Tomás 1972 | 51 | **6** | 49 | 8 |
| Domínguez Caparrós 2014 | 41 | 35 | 0 | 1 |
| Diccionario 2016 | 59 | 26 | — | 59 |
| Jauralde Pou 2020 | 43 | 0 | 3 | 41 |
| | **267** | **82** | | |

Cuelgan de una forma 238, de una arquitectura 23 y de un esquema de rima 6. La `confianza` dice
`alta` en 264 y `media` en 3, así que hoy ese campo no distingue nada.

**43 formas activas y 223 pares forma-fuente cubiertos de los 258 posibles**: quedan 35 celdas
vacías, y dos formas —**Décima-lira** y **Novena-lira**— sin ninguna fuente.

Todo esto se publica hoy en `/formas`, en la sección `#fuentes` de cada ficha. Una invención
confirmada no es una deuda interna: está en la web.

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

**Si hay que recortar, se recorta B** y se deja solo en las fuentes de riesgo. A y C son el suelo.

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

  "por_que_ahi": "La entrada «octava real» abre en la línea 10384 del volcado. La hoja 259 del PDF lleva impreso el número 246 y contiene esa entrada.",
  "confirmacion_pdf": { "hoja": 259, "numero_impreso": 246, "coincide": true },

  "texto_original": "octava real. Estrofa de ocho versos endecasílabos, de los que riman en consonante… Es posible, aunque no frecuente, encontrar otra disposición de la rima de los seis primeros versos.",
  "texto_registrado": "Advierte que «es posible, aunque no frecuente, encontrar otra disposición de la rima de los seis primeros versos»…",

  "veredicto": "conforme | defecto | duda_filologica",
  "defectos": [ { "tipo": "endurecimiento", "gravedad": "grave",
                  "cita_literal": "es posible, aunque no frecuente…", "linea": 12351 } ]
}
```

**`texto_original` se transcribe, no se resume**, y un script comprueba después que esa
transcripción aparece de verdad en el fichero. Es lo que permite cotejar original y registro uno
al lado del otro, que es como se ve el endurecimiento y la omisión: leyendo los dos.

## 5. La otra mitad: lo que falta

La regla de exhaustividad dice que toda fuente que trate una forma tiene su afirmación, y que el
silencio de una fuente también se registra. Eso no se audita por afirmación sino **por forma**: 43
unidades. Para cada una se toman sus denominaciones del catálogo, se buscan en las seis y se listan
todos los pasajes que la mencionan; cada pasaje ha de estar cubierto por una afirmación o quedar
justificado por escrito. **Las 35 celdas vacías son el punto de partida y las dos formas sin
ninguna fuente, lo primero.**

## 6. Las fases

| Fase | Qué | Criterio de salida |
| --- | --- | --- |
| 0 | Inventario y niveles 0 y 1. Script `npm run audit:fuentes` | 267 extractos generados; lista de localizadores que no resuelven; desfase de página fijado en los cinco PDF |
| 1 | **Piloto** sobre el Diccionario 2016 —59, la más mecanizable— con los errores sembrados | ≥ 90 % de sembrados cazados y coste real por afirmación medido. **Aquí se decide si se sigue** |
| 2 | Navarro 1972 (51) y Morley y Bruerton (36) | dictamen de las 87 |
| 3 | Jauralde (43), Quilis (37), Caparrós 2014 (41) | dictamen de las 121 |
| 4 | Exhaustividad, 43 formas | matriz forma × fuente completa, con cada hueco justificado |
| 5 | Informe, correcciones propuestas y muestra humana | informe firmado y repetible por un tercero |

La fase 1 existe para decidir si merece la pena seguir: **si el piloto devuelve cero defectos
graves en la fuente más fácil de comprobar**, quizá baste con auditar entera la de más riesgo y
muestrear las demás.

Se empieza por el Diccionario y no por lo más sospechoso porque es donde la máquina puede decir
quién tiene razón, y eso es lo que calibra el método antes de gastarlo.

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

## 9. Lo que ya se sabe que va a doler

**Las seis páginas de Navarro Tomás.** [Las fuentes del catálogo](./fuentes-del-catalogo.md)
documenta que ese libro no se cita por página porque el volcado no las conserva. Que seis
afirmaciones la lleven significa que salieron de otro sitio. Puede que del PDF, correctamente;
puede que no. **Es la primera prueba que hay que hacer y es barata.**

**Las tres páginas de Jauralde.** Mismo caso y peor: el epub no tiene paginación ninguna.

**Los pliegos dobles de Quilis.** `localizar` devuelve pares de números y el PDF escaneó dos
páginas por hoja. Hay 15 afirmaciones con página ahí, y el riesgo de estar una fuera no es
desdeñable.

**El endurecimiento no se ve leyendo.** Es el defecto que la pasada A puede pasar por alto
tranquilamente, porque el resumen sigue siendo verdad *a medias*. Si en el piloto los sembrados de
ese tipo no se cazan, hay que aceptar que la pasada B es obligatoria en las seis fuentes y que el
coste sube.

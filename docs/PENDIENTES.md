# Pendientes

**La única lista de pendientes del proyecto.** Lo que se hace se borra de aquí: no se tacha ni se
archiva «por si acaso», porque para mirar atrás está `git` y está el
[histórico](./dominio-metrico/historico/).

Cada asunto ocupa pocas líneas: **qué falta, qué bloquea y dónde está el detalle**. Cuando un asunto
necesita un plan largo, vive en su propio documento y aquí solo se le nombra.

Lo que **no** va en esta lista: las decisiones filológicas, que son del IP y están en
[cuestiones para el IP](./dominio-metrico/cuestiones-para-el-ip.md); y los informes generados, que
no son estado porque se rehacen con un comando.

---

## Los dos hitos

**1 · Avanzar el laboratorio comparativo.** `corpus_comparativas` V2 ofrece la matriz por obra y los
agregados. Debe sustituir la carga relacional del laboratorio y servir para ensayar qué medidas son
interpretables, antes de proyectar una selección pequeña a las fichas. Las 11 obras visibles son de
prueba: valen para comprobar cálculo y presentación, no para sostener resultados.
→ [plan de comparativas](./plan-comparativas-corpus.md)

**2 · Migrar las secuencias ya anotadas.** 263, en 11 obras de 8 editores. Los informes y los
Excel que cada editor rellena **están enviados** y el aplicador que lee las respuestas está
escrito; falta que vuelvan los Excel y migrar obra por obra. **Hasta que se haga, esas obras no
tienen perfil.**
→ [plan de migración](./dominio-metrico/plan-migracion-anotaciones.md) ·
[informes y cuestionarios](./dominio-metrico/migracion/) ·
estado con `npm run equivalencias:informe`

---

## A · Bloquean la migración de las secuencias

**A1 · Migrar obra por obra.** El aplicador está escrito —`npm run migracion:aplicar -- --obra
<slug>`, con `--simular` y con `--simular --ensayar`, que ejecuta la transacción entera y la
deshace— y las once obras la pasan con respuestas de prueba. Falta: **aplicar la migración que crea
`migracion_secuencias`**, que está escrita y sin aplicar, y migrar cada obra cuando vuelva su Excel.
→ [plan, §5](./dominio-metrico/plan-migracion-anotaciones.md)

**A2 · Recoger las respuestas.** Los Excel de
[migracion/cuestionarios/](./dominio-metrico/migracion/cuestionarios/) **ya se mandaron** a los 8
editores; a 25 de septiembre de 2026 no ha vuelto ninguno. Cada uno lee el informe de su obra en
`/dashboard/migracion/<obra>` y no debe tocarla desde que devuelve el Excel hasta que se le confirma
la migración. Las respuestas van a `migracion/respuestas/`, versionadas, según llegan.

**A4 · Las preguntas que la serie alirada no tiene.** La novena-lira no tiene dónde registrar la
disposición que se vea, ni la décima cuando no sea la documentada. (La canción ya no está aquí: la
estancia se reparte verso a verso y el remate pregunta medida y rima desde el 18 de septiembre.) Es el mismo hueco de la sextilla y el sexteto, y se resuelve de una vez para todo el
catálogo.

**A5 · Las rimas compartidas entre partes de una forma compuesta no tienen destino.** El editor
guarda un esquema local por sección y al reunirlas renumera la segunda con letras nuevas; si el
enlace existe, lo borra. **Un caso así no se debe migrar ni guardar: hay que detener la anotación.**
Hace falta declarar equivalencias de clase entre secciones, o una disposición global de la unidad.

---

## B · El catálogo y su modelo

**B1 · Registrar una disposición que el catálogo no tiene.** El hueco que A4 nombra desde la serie
alirada y que alcanza también a la sextilla y al sexteto.

**B2 · El reparto de los rasgos, revisado entero.** Con él, la modalidad aguda: Jauralde dice que se
extendió «a otras muchas variedades estróficas, como la sextilla y la décima», y hoy solo la declaran
la octava aguda, el septeto y el sexteto. Y hay que decidir cómo se cruza con las vocales de la
asonancia, porque los cuatro valores simples —`a`, `e`, `i`, `o`— **son** las asonancias agudas y los
quince pares las llanas, relación que no está declarada: hoy se puede responder «final agudo» y una
asonancia en par, que se contradicen.

**B3 · La modalidad y los rasgos heredados por reutilización no son los de la posición que ocupan.**
`aabba` sale «admitida» en la segunda quintilla de la copla real, donde M&B dicen que en Lope es
siempre esa; y en la sextilla enlazada el pie quebrado es definitorio y en la quintilla que reutiliza,
admitido. Afecta a las 18 reutilizaciones. *El IP decidió el 20 de agosto decirlo en prosa y no tocar
el modelo por ahora.*

**B4 · `numero_clases` admite un solo valor**, así que no puede expresar «dos o tres». Con él, las dos
cosas del soneto: si sus cuartetos pueden heredar la disposición del cuarteto, y la restricción
`max_consecutivos: 2` de sus tercetos, que la fuente enuncia y el catálogo no declara —**esta segunda
ya se puede declarar**, el auditor la comprobaría.

**B5 · Los esquemas abiertos sin restricciones**: los tres del sexteto y el de la octava real. La
pregunta a cada fuente es la que respondió la quintilla —cuántas clases, cuántas alternancias, si
admite sueltos—, pero **solo tiene respuesta cuando la fuente enuncia una regla**: de una enumeración
no se saca un mínimo.

**B6 · Un esquema de rima solo puede señalar una sección**, y los tres de la mudanza del villancico
sirven a dos. Hoy no señalan ninguna y funciona; si aparece uno que deba señalar sección y servir a
varias, habrá que emparejar por `tipo_seccion`.

**B7 · No hay dónde guardar un ejemplo de verso.** El IP quiere un botón de ejemplos en cada ficha.
Hay que modelarlo —de qué cuelga, cómo se guarda la anotación de clases— y luego poblarlo. Con él se
resuelve dibujar la permutación de la sextina, que hoy solo se lee.

**B8 · La `suelta` de la endecha real es un ciclo con notación y cero posiciones.** O se expanden las
posiciones o se admite que la notación baste. *Puede retirarlo una decisión del IP sobre qué es una
endecha real.*

**B9 · Dos cosas de la seguidilla, anotadas y sin tocar.** El «Estribillo final» de la compuesta
duplica una arquitectura en vez de referenciarla, y `tipo_seccion` vale distinto en dos secciones
idénticas. *Ninguna es un defecto.*

**B10 · Las desviaciones no se han probado nunca.** Se puede abrir una desde el editor y no hay
ninguna anotada, ni en pruebas. Hay que recorrerlas antes de pedirle a nadie que las use. Y decidir
si es límite aceptable que **una desviación no pueda registrar algo que el catálogo no tenga**.

**B11 · El separador de las notaciones no es uniforme.** Once esquemas llevan `:` —`abCabC:cdeeDfF`,
`abba:accddc`, `ABBA:CDDC`— y quince llevan `|` —`abab|cddc`, `abcabc|defdef`—; el editor pinta
siempre `|` y la restricción de la base acepta los dos. Decidir cuál gana y unificar. Aplazado el 17
de septiembre de 2026 al partir la canción, que era donde se veía.

**B12 · Una canción cuyas estancias midan distinto no se puede anotar como una secuencia.**
`primera_realizacion_define_patron` obliga a que todas midan lo mismo, y Morley y Bruerton dan un
pasaje «mezclado» de 13, 13, 13, 14 y 15 versos en *El verdadero amante*. Cuando aparezca uno se
decide si se admite o se parte en secuencias.

**B13 · Nada impide anotar combinaciones de rasgos imposibles.** Una secuencia puede llevar
«densidad de rima: ninguna» y «organización en pareados: ocasionales» a la vez, y sin rima no hay
pareados. Salió en una obra de prueba (*El padrino burlado*, vv. 1761-1791), así que falla también
el generador de `guion:pruebas`. Falta la restricción en el catálogo o en el editor V2, y que el
generador la respete. El perfil agrupa ya los rasgos por combinación, y ahí se ven.

---

## C · Rendimiento y arquitectura

**C1 · El catálogo se deriva en cada lectura.** Cuatro «tablas» del gestor son vistas sobre funciones
que recorren el catálogo entero. La caché por revisión resolvió la mitad grande; queda materializar
lo derivado —880 filas entre tres vistas— y medirlo con la caché puesta. *Cuando el editor V2 relaje
la RLS de `catalogo_metrico_estado`, la llave de la caché dejará de bastar: habrá que añadirle la
visibilidad.* Y **mientras lo derivado se cachee por revisión, un informe puede estar leyendo un
catálogo que ya no existe**: seis respuestas del pareado estuvieron fuera del repertorio y ocultas
hasta que, el 17 de septiembre de 2026, una migración subió la revisión e invalidó la caché. Hasta
entonces `audit:anotaciones` firmaba «todo lo anotado encaja».

**C3 · Nadie proyecta una anotación a notación verso a verso**, y es lo que pide la estilometría. El
editor ya la escribe, pero **vive en la pantalla**: no es un módulo puro, no recorre las desviaciones
ni la arquitectura intercalada. Hace falta una **proyección precomputada y regenerable**, con el
nombre y la notación exacta a la vez. *No puede construirse sobre `rejilla.ts`, que es un recurso
visual.* No bloquea anotar, pero es previo a comparar y cuantificar.

**C4 · Separar y renombrar `loadMetricCatalog`.** Conserva el nombre y parte del contrato de la
pantalla retirada. Debe devolver solo `MetricCatalogForEditor` y el estado de migración.

**C5 · El disparador de posiciones toma la caja por clase de rima.**
`sincronizar_posiciones_esquema_rima_fijo` deriva las posiciones letra a letra, y de `-a-A` saca las
clases `a` y `A` como si fueran dos rimas distintas. Pero **la caja dice el arte del verso**, no con
quién rima: la lira escribe `aBabB` y son dos rimas, no cuatro. En la endecha real hubo que
corregir la clase a mano, y **cualquier rima futura entre un verso de arte menor y otro de arte
mayor caerá en lo mismo**. *Se arregla comparando en minúsculas dentro del disparador, pero antes
hay que comprobar si alguna forma poblada depende de la conducta actual.*

**C6 · Lo que la obra declara que no hay solo lo responde el editor.** Arreglado ahí y solo ahí,
porque hoy es la única vía por la que nace una secuencia. **Si vuelven a crearse obras por otra vía**
—un seeder, una importación—, hay que añadir el disparador `before insert`.

**C7 · La pestaña de secuencias se quedó sin borrador local**, y falta decidir si vuelve.

**C7bis · Dos rasgos quedan fuera del demarcador y quizá deban entrar los últimos.** `final_acentual`
y `encadenamiento_interior` están marcados `demarcable = false`. El encadenamiento es
`observabilidad: especializada` —ver que la rima final enlaza con una posición interior del
siguiente verso es lectura atenta—; desde el 18 de septiembre de 2026 es **definitorio** del
endecasílabo encadenado, forma propia, y ya no está en el suelto: si entrara en el demarcador,
separaría las dos series de endecasílabos. `final_acentual`, en cambio, es el único rasgo `directa` excluido: o la exclusión
sobra o lo que está mal es su observabilidad. *Idea a explorar, no decisión tomada*: ofrecerlos **al
final del recorrido**, cuando ya no quede ninguna pregunta fácil que separe, avisando de que son
difíciles de responder. Hoy el motor no tiene ese escalón.

**C8 · El demarcador manda 821 kB de catálogo en cada carga.** La caché de un minuto y la prosa
deduplicada —17 de septiembre de 2026— quitaron la recompilación y unos 165 kB de preguntas
repetidas. Queda el bloque gordo: **la presentación de las 90 arquitecturas viaja entera por
adelantado** —rejilla verso a verso, esquemas visuales y rasgos— y solo hace falta al abrir «Ver
detalles» de una tarjeta. *Decidido dejarlo mientras la base no se sature: traerlo todo de golpe
evita viajes durante el recorrido.* Antes de moverlo hay que medir cuánto pesa exactamente.

**C9 · La puntuación del demarcador premia coincidir sin medir cuánto se juega cada forma.** Suma
acuerdos, y cada acierto vale lo mismo para quien admite una sola realización que para quien admite
infinitas: «catorce versos» es casi una prueba para el soneto —su única extensión— y no dice nada
del septeto, al que le valen 7, 14, 21… Las dos se llevan el mismo punto, y por eso un contraste
puede acumular siete respuestas sin que ninguna separe nada. Su corolario: **«no declara» nunca
penaliza**, así que una forma vaga no se equivoca nunca. Hace falta **ponderar cada coincidencia por
la especificidad de la norma**. Es lo único que puede separar dos formas que encajan las dos, y sin
ello lo demás es maquillaje.

**C10 · La pantalla de comprobación sigue hablando el idioma de la identificación.** Durante el
recorrido dice «candidatas según tus respuestas» y lista «coincide / difiere», cuando la pregunta es
si el pasaje es o no esa forma. Con `discrepanciasEntre` ya calculado se puede marcar cada acierto
como **lo que la sostiene** o **lo que no la distingue de X** —que es la explicación de por qué el
recorrido no avanza— y presentar las dos lecturas de una misma extensión como lo que son: «un soneto
de 14» frente a «dos septetos de 7», que no compiten por lo mismo. *El veredicto de tres salidas ya
está en el motor y solo se pinta al detenerse el recorrido.*

**C8 · El desglose del autor se queda en dos niveles**, y **filtrar por rasgo o por esquema pide otro
selector**: hoy es «formas + subtipos anidados» en un control único que no aguanta lo que viene.

---

## D · La ficha pública

Lo que quedó abierto al cerrar el inventario de la ficha. Su relato punto por punto, con lo que se
descartó y por qué, está en el [histórico](./dominio-metrico/historico/ficha-publica-2026-09.md).

**D1 · Los gráficos de análisis no llevan a ninguna parte.** Un tramo del código de barras o una
barra de la evolución debería abrir o filtrar las secuencias que cuenta. Hoy solo se miran.

**D2 · La lectura de la evolución a lo largo de la obra.** No es dibujar otro gráfico: es decidir
antes qué significan `numero_efectivo_formas` y `densidad_transiciones` **dentro de una sola obra**
—hoy sirven para comparar obras entre sí en `/obras`— y si «se concentra» o «se diversifica» es
afirmable con lo que se mide.

**D3 · Los comentarios que no cuelgan de una secuencia no se pintan.** La ficha solo muestra los
que llevan `secuencia_id`; quedan fuera los generales y los ligados a una jornada o un cuadro.

**D4 · Los slugs de las arquitecturas.** Los nombres se corrigieron el 10 de septiembre; los slugs
no, porque viajan en el JSON de la ficha y en las URLs del catálogo y renombrarlos pide recompute y
repaso de enlaces. Dos desajustes esperan ese día: `terceto/endecasilabica_consonante` se llama
«Endecasílabo», y los slugs dicen `octosilabica` donde el nombre dice «Octosílabo». Y falta decidir
cómo nombrar la única arquitectura del endecasílabo suelto, que ya lo dice todo en el nombre de su
forma.

**D5 · Blanco y negro para el código de barras y el perfil.** Las franjas, las pendientes y las
tradiciones ya se descargan en grises, porque llevan el nombre escrito junto a lo que nombran. En
estos dos lo único que distingue una forma es su color: doce formas en papel piden trama —rayado,
punteado— y los nombres fuera, en diagonal, unidos a su tramo por una línea de guía. El modal ya
tiene la opción; basta con que el gráfico declare `admiteGrises`.

**D9 · La cita no invierte el nombre del editor.** `/como-citarnos` escribe «González Mesas,
Emma», pero `editores` solo guarda `nombre_completo`, y adivinar dónde acaba el nombre falla con
«José María» o «de la Fuente». La cita de la ficha y la de cada gráfico van en orden natural hasta
que haya apellidos en la base.

**D10 · El laboratorio sigue en ECharts.** La ficha pintaba el perfil con ECharts y ya no: todos
sus gráficos son SVG con d3 y se descargan por `$lib/figuras`. El laboratorio y la miniatura del
perfil en `/autores` (`MiniMetricDonut`) siguen con ECharts, y sus gráficos no se pueden
descargar. Pasarlos al mismo sistema es rehacerlos con `MetricDonut` y los tokens de
`$lib/figuras/tema`.

**D6 · Estados vacíos y cobertura parcial**, en métrica, jornadas, sinopsis y anotaciones: qué
enseña la ficha de una obra a medio anotar.

**D7 · El modal de secuencia, lo que le falta de accesibilidad**: comprobación visual en móvil y
decidir si se confina el foco del todo.

**D8 · Los patrones repetidos.** *Aplazado a propósito*: no se detecta ninguno hasta acordar qué
es un patrón y con qué umbral, y hasta tener corpus publicado suficiente para contrastarlo. Con una
obra delante, cualquier lista sería arbitraria.

---

## E · Lo que dejó la auditoría de fuentes

La auditoría está terminada: 267 afirmaciones resueltas y 57 migraciones. Qué se hizo y qué enseñó
está en el [registro](./dominio-metrico/historico/auditoria-de-fuentes-2026-09.md); el método, por
si hay que repetirlo, en [el plan](./dominio-metrico/plan-auditoria-fuentes.md).

**E1 · Fase 5: informe y muestra humana.** El cierre: que un tercero pueda repetir la auditoría sin
fiarse de nosotros.

**E2 · Los 66 esquemas que las fuentes dan y el catálogo no tiene**, en 22 fichas. Forma por forma y con el libro abierto: el volcado de Navarro lee la `c` como
`e` y algunas cadenas son varias estrofas seguidas. **La lista mecánica no es una lista de
trabajo.** *Cuando se aborde, entran como esquemas de la arquitectura con modalidad `admitida`,
nunca `definitoria`* —decidido el 17 de septiembre—: la distribución sigue siendo variable y lo que
se documenta es solo lo ya encontrado. Si entran, **la canción petrarquista dejará de tener una
sola arquitectura regular**. Y uno tiene ya destino dicho por el IP: `ABCABCDD`, la «canción toda
en endecasílabos» de *Barlaán y Josafat* (Morley y Bruerton, p. 176), es un esquema de **octava
real**, no una canción; el término legado `cancion_endecasilaba` apunta ahí.

**E3 · Las 23 afirmaciones que matizan sobre formas con esquema definitorio.** Lo único del inventario
de divergencias que apunta a desacuerdo real, no a silencio.
→ [divergencias con las fuentes](./dominio-metrico/divergencias-con-las-fuentes.md)

**E4 · Las 19 denominaciones** sin eco en su fuente o sin fuente declarada.

**E5 · Once candidatas a endurecimiento**, que `npm run senal:endurecimiento` señala sobre las 306
afirmaciones: resumen una oración con cautela —«podía», «pueden», «generalmente», «frecuente»— sin
recogerla. Son candidatas, no veredictos: lo decide abrir el libro.

**E6 · Tres comprobaciones mecánicas escritas a medias.** Las entradas del *Diccionario* con sentidos
numerados —acertó seis de seis sin existir—, la señal de endurecimiento invertida para detectar
cuándo la ficha ablanda a la fuente, y el cotejo de los epígrafes de Jauralde contra el epub.

**E7 · Dos propuestas sin redactar:** `cfb377cd` (septeto-lira de Navarro) y la afirmación del cubo
limpio que quedó sin decidir.

**E8 · Tres comprobaciones que salieron de cuestiones para el IP.** Los datos de las tres coplas
reales de *El caballero de Olmedo* —qué disposición tiene cada quintilla y dónde caen los
quiebros—, que es el único sitio donde el corpus puede contrastar lo que las fuentes dicen del
emparejamiento: **ya se piden en el Excel de la obra**; cuando vuelva, contrastarlos. Comprobar contra lo anotado que **ningún pasaje con quebrado esté
registrado como versificación irregular**, que es el error fácil al anotar y que la definición ya
excluye. *Esa secuencia de* Lo fingido y lo cierto (prueba) *quedó anotada como **silva**, y el guion la
vuelve a construir como villancico: al regenerar las pruebas volverá a serlo, que es lo que
interesa, porque es la única secuencia que ejercita secciones dentro de secciones.*

**E9 · Cuatro cabos de consistencia**, ninguno de auditoría. `40c2c354` habla de Morley y Bruerton
en singular —«La caracteriza»—, y sus dos hermanas ya se arreglaron. El *Diccionario* se cita de dos
maneras: ocho fichas con «s. v.» frente a 53 con «Entrada», y quince sin página. `22c63f36` enumera
«series arromanzadas» entre los tipos con nombre de la seguidilla, y en el § 498 aparece como
ejemplo suelto de García Lorca, no como categoría. Y queda la idea de **un párrafo de cabecera en
«Lo que dicen las fuentes» para cuando las seis disientan mucho**: no hace falta todavía, porque el
caso que la sugirió se resolvió documentando cada voz por separado.

**E10 · La prosa de las fichas no se ha releído con las fuentes ya firmes.** Se escribió en agosto
apoyándose en unas afirmaciones que la auditoría corrigió después en más de cien puntos.

---

## F · Fuera del dominio métrico

**F1 · Los sesenta enums en `CHECK`** y los tres sitios donde viven los vocabularios.
→ [revisión de vocabularios](./revision-de-vocabularios.md)

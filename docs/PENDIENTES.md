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

**2 · Migrar las secuencias ya anotadas.** Continuar obra por obra al recibir sus Excel.
El aplicador y los cuestionarios están escritos; las obras pendientes figuran en los informes
generados. **Hasta que se migren, esas obras no tienen perfil.**
→ [plan de migración](./dominio-metrico/plan-migracion-anotaciones.md) ·
[informes y cuestionarios](./dominio-metrico/migracion/) ·
estado con `npm run equivalencias:informe`

---

## Medidas analíticas y precomputación

**Cerrar definiciones generales y corregir sus productores.** El
[inventario de medidas](./inventario-medidas-analiticas.md) revisa obra, autor, comparativas y
laboratorio para fichas detalladas y básicas; no es una auditoría de toda la lógica de la DB.
Se incluyen verso aislado e irregularidad identificados en la diversidad y transiciones entre
jornadas en el total. Se abandona «fiabilidad» basada solo en volumen; marco aceptado de volumen,
cobertura por medida y estabilidad, con su desarrollo estadístico aún por validar. Aclarar extensión corregida y reformular los datos parciales
como parte confirmada y pendiente, sin repartir lo desconocido entre formas conocidas.
Aceptados extremos identificados aunque haya interior pendiente y exclusión de básicas sin
cuadros de sus medidas; cero analizado en detalladas publicadas frente a desconocido por silencio
de básicas. Mantener en el perfil las posiciones perdidas cuantificadas y atribuidas según la
práctica indicada, con reconstrucción explícita y sin duplicarlas en el total. No inventar
desgloses de 7/11 en silvas: una forma identificada no exige ese recuento interno. Revisar el
índice principal por clases y limitar consultas por medida a evidencia suficiente. La prosa
solo se localiza entre versos. Corrección implementada en ficha, laboratorio y productores V3,
probada en copia con 16 comprobaciones PostgreSQL: desplegar lectores compatibles y después
aplicar `20261029120000_la_prosa_se_localiza_entre_versos.sql`, que regenera los precomputados.
Se conserva la anotación válida del editor. Sustituir «peso» ambiguo
por porcentajes y poblaciones explícitos.
Aceptados perfil de autor ponderado por extensión y distribución por obras aparte, exclusión de
la obra contrastada y sus jornadas, y cronología por solapamiento sin año medio del rango.
Concretar diversidad por formas y revisar mediana/cuartiles como resumen principal entre obras,
con media accesible y presencia explícita; no construir un perfil compuesto de medianas.
Revisar los demás puntos D01–D10 antes de cambiar cálculos. La auditoría contiene ejemplos
sintéticos comprobados, sin recálculos ni cambios en la base compartida. Esta revisión general
es una dependencia de la incorporación analítica del importador.
Tras reunir el corpus de Lope, ejecutar el experimento de sensibilidad para el artículo científico
de presentación de Versología. Preparar antes su protocolo reproducible; distinguir descripción
confirmada, incertidumbre de identificación e inferencia. La parte pendiente no es una clase
métrica ni autoriza comparaciones concluyentes tratándola como dato exacto.

## Proyecto de importador métrico

**Concretar la persistencia mínima y ampliar el piloto.** Cuatro transcripciones aceptadas,
validador y normalizador locales con pruebas. Se reutilizan obras/jornadas/secuencias y se separa
la métrica mínima de v2. El diseño contrasta el esquema vivo y contempla agregados del corpus mínimo
para comparar fichas completas sin publicar las mínimas individuales. Campos revisados: género
obligatorio, fuente de datación y fundamentos de autoría opcionales; registro de quién importa.
El editor podrá corregir o vaciar la estructura; verá la propuesta importada sin aprobación en v2.
Se conserva una copia mínima fija hasta publicar la completa y entonces se sustituye su aporte.
Mínima es un tipo, sin nuevo estado ni segundo validador. Admin/IP y editores autorizados importan
y consultan todas las mínimas, viendo quién importó cada una; el laboratorio sigue para admin/IP.
Ya hay contrato local, vistas previas de las cuatro obras y pruebas de copia fija y permisos con
identidades sintéticas. El borrador SQL ya guarda transaccionalmente las cuatro obras en PostgreSQL
aislado y prueba permisos, copia fija e idempotencia concurrente contra el esquema real exportado.
Falta cerrar el reconocimiento de identidades y duplicados, reimportaciones, verificar entradas en
servidor, auditar consumidores y funciones con acceso privilegiado; integrar la migración definitiva,
permiso individual, RLS, vista Fichas mínimas y sustitución en el corpus. La vista previa de ensayo
del dashboard ya prepara entradas, metadatos y secuencias por jornadas para admin/IP, sin guardar.
El contrato 0.2 y el borrador SQL ya conservan original, copia confirmada, versión de reglas y decisiones
particulares breves, sin estados ni fundamentos generales repetidos por secuencia. La vista previa
ya permite editar formas y arquitecturas, dividir y reunir partes de una fila original, comprobar
en servidor y restablecer. El modal compartido con v2 mantiene la edición general; la división
muestra los rangos antes de crear la parte nueva y el remate permite añadir, corregir o quitar
su dato. Los datos incorporados se muestran fuera de «Añadir datos», que sirve solo para añadir.
El pareado final se registra como Dístico final / Presente y las asonancias explícitas del romance
como valores del rasgo Vocales de asonancia, conservando la notación original.
La tabla comparte la presentación de forma y arquitectura con las fichas y separa los datos
métricos estructurados del texto de notas, para revisar qué se guardará sin abrir cada secuencia.
Antes de conectar confirmación y guardado, cerrar el [plan de consultas y precomputación](./importador-metrico/consultas-y-precomputacion.md):
selección de una aportación por obra, lectores editoriales frente a productores del corpus mixto,
versiones, invalidación y permisos de artefactos. El análisis seguirá usando datos precomputados;
no se ampliarán indiscriminadamente los lectores públicos ni se filtrarán todas las mínimas fuera de los cálculos.
Revisión acordada: renombrar términos ambiguos (propuesta Básica/Detallada), exigir la integridad
editorial del 100 % para publicar una detallada y decidir ceros/datos ausentes medida por medida.
La revisión general de medidas y denominadores figura en el apartado anterior; se aplica también
al corpus existente, no solo a la importación.
El recálculo combinado procesa ambas fuentes; se preparan documentos por consumidor y un manifiesto
coherente para su almacenamiento actual en Supabase y futura distribución en R2, manteniendo permisos
y autoría por obra/jornada. No se integra R2 todavía.
Después conectar la confirmación desde la vista previa y el guardado definitivo;
ampliar el piloto y ensayar
sensibilidad. No se exige resolver todas las denominaciones: Canción con remate y encadenados
con «serventesio final» como cierre 3+1 están aceptados; «tercetos» sin calificativo y «letrilla»
conservan su ambigüedad sin cotejo obligatorio del texto. Trabajo en `main`,
con archivos locales y sin importaciones ni migraciones en Supabase.
→ [diseño de integración](./importador-metrico/diseno-integracion.md)
→ [campos mínimos y conexiones](./importador-metrico/campos-minimos.md)
→ [contrato local e informe del ensayo](./importador-metrico/contrato-local.md)
→ [borrador SQL y pruebas PostgreSQL](./importador-metrico/persistencia-local.md)
→ [vista previa del dashboard](./importador-metrico/vista-previa-dashboard.md)
→ [proyecto y hoja de ruta](./importador-metrico/README.md)

---

## A · Bloquean la migración de las secuencias

**A1 · Migrar obra por obra.** El aplicador está escrito —`npm run migracion:aplicar -- --obra
<slug>`, con `--simular` y con `--simular --ensayar`, que ejecuta la transacción entera y la
deshace—. Falta migrar cada obra cuando vuelva su Excel, con las resoluciones particulares de sus
notas y correcciones. La tabla `migracion_secuencias` ya está aplicada.
→ [plan, §5](./dominio-metrico/plan-migracion-anotaciones.md)

**A2 · Enviar los cuestionarios y recoger las respuestas.** El informe de cada obra se lee en
`/dashboard/migracion/<obra>`, que solo ven admin, el IP y el editor asignado; falta **mandar por
correo el Excel** de [migracion/cuestionarios/](./dominio-metrico/migracion/cuestionarios/) a cada
uno de los 8 editores, avisando de que no toque la obra desde que lo devuelve hasta que se le
confirma la migración. Las respuestas van a `migracion/respuestas/`, versionadas. Lo que un editor
no tenga claro lo pregunta antes de contestar.

**A4 · Las preguntas que la serie alirada no tiene.** La novena-lira no tiene dónde registrar la
disposición que se vea, ni la décima cuando no sea la documentada. (La canción ya no está aquí: la
estancia se reparte verso a verso y el remate pregunta medida y rima desde el 18 de septiembre.) Es el mismo hueco de la sextilla y el sexteto, y se resuelve de una vez para todo el
catálogo.

**A5 · Las rimas compartidas entre partes de una forma compuesta no tienen destino.** El editor
guarda un esquema local por sección y al reunirlas renumera la segunda con letras nuevas; si el
enlace existe, lo borra. **Un caso así no se debe migrar ni guardar: hay que detener la anotación.**
Hace falta declarar equivalencias de clase entre secciones, o una disposición global de la unidad.

**A6 · Revisar la organización en pareados de *Adonis y Venus*, vv. 2021–2094.** La silva consonante
de orden libre deja de dar «Predominantes» por hecho y pregunta «Predominantes» o «Regulares».
La densidad ya está anotada como total; falta confirmar cuánto organizan los pareados la serie.
El IP avisará al editor. No se asigna una respuesta automáticamente.

**A7 · Corregir las medidas del villancico de *Adonis y Venus*, vv. 852–871.** El editor ya está
avisado de la ampliación a los metros de arte menor catalogados (3–8 sílabas), una medida por
parte. Las respuestas anteriores se conservan hasta que él revise el pasaje; no son confirmación
de que las medidas anotadas sean correctas.

**A8 · Revisar los géneros de quienes intervienen.** Tras convertir las respuestas antiguas,
los editores deben comprobar los pasajes con canto, personajes sobrenaturales y coros. La lista
incluye las ocho obras reales, sus responsables y los versos donde empezar. El IP les avisará
cuando esté desplegado el nuevo formulario; la conversión no confirma el género de esas voces.
→ [lista y criterios de revisión](./revision-generos-intervinientes.md)

**A9 · Trasladar las notas al migrar cada obra.** Quedan 56 observaciones de caracterizaciones en
cinco obras reales, con destinos revisados por el IP. Aplicar cada decisión al procesar su Excel,
respetando correcciones y renumeraciones. La columna se conserva y los originales de lo ya
migrado quedan en el rastro; el formulario no admite nuevas notas en ella.
→ [dictamen y procedimiento](./revision-notas-caracterizaciones.md)

**A10 · Revisar los pareados de *El amor al uso*.** Las silvas de vv. 1348–1407, 2545–2612 y
2621–2644 se migraron como «Predominantes» por indicación del IP. Este preguntará a Ana Vicente
para que confirme o cambie la respuesta en el editor. No proceden de una respuesta del Excel.

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

**C11 · Unificar los modales en un componente común donde compartan estructura y comportamiento.**
Centralizar el fondo, el portal, el cierre, la gestión del foco y el scroll interior, manteniendo
las variantes que necesite cada contenido. Revisar tanto la web pública como el editor y el
dashboard; partir de `src/lib/actions/portal.ts` y de los componentes actuales de modal.

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

**F2 · Crear cuadros sin exigir una jornada creada previamente.** El responsable quiere permitir
registrarlos por rangos de obra, como las secuencias, para reducir fricción editorial. Revisar cómo
derivar su pertenencia a jornada y adaptar validación y consumidores. Mejora futura independiente
del importador; no se modifica ahora el registrador ni la DB.

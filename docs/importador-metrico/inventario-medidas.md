# Auditoría de medidas: ceros, ausencias y denominadores

28 de octubre de 2026. **Propuestas pendientes de revisión por el responsable.**
Este documento no cambia las medidas vigentes ni da por aceptadas nuevas reglas. Tras decidirlas,
sus definiciones se incorporarán a la [metodología canónica](../metodologia-perfil-metrico.md).

## Qué se ha comprobado

Se han leído las definiciones vigentes de doce funciones de Supabase y seguido sus salidas hasta
los contratos JSON, el laboratorio y el perfil de autor. El
[registro de firmas y hashes](./piloto/auditoria-medidas-2026-10-28.json) identifica la versión
auditada. La consulta se conserva en [auditar-medidas.sql](../../scripts/importador-metrico/auditar-medidas.sql).
No se ejecutaron productores ni se inspeccionaron fichas individuales para buscar errores.

Además se ejecutó un SELECT con constantes para comprobar ejemplos de las fórmulas y predicados:
[consulta](../../scripts/importador-metrico/casos-medidas.sql) y
[resultados](./piloto/casos-medidas-2026-10-28.json). Son casos sintéticos; no prueban el recorrido
completo de recomputación ni cuantifican cuántas obras actuales están afectadas.

El análisis seguirá usando precomputados. Actualmente el laboratorio también resume grupos en
el navegador a partir de los valores por obra descargados; esa operación no consulta anotaciones
en vivo. Hay que mantener coherentes ambas definiciones, sin añadir cálculos sobre tablas en las
visitas a las páginas. El futuro productor combinado recalculará ambas fuentes, con una sola
aportación seleccionada por obra y generación, según el [plan](./consultas-y-precomputacion.md).

Una detallada solo se publica con el 100 % de sus campos cumplimentados. Una discrepancia técnica
con esa regla requiere revisión; no autoriza a tratar como cero el dato ausente. En una básica,
la cobertura depende de la información disponible para cada medida, no de una supuesta ficha
detallada incompleta.

## Convenciones propuestas

- **Cero:** se estudió el ámbito necesario y se puede afirmar que no hay casos.
- **Desconocido:** no se recogió el dato o queda una parte que podría cambiar el resultado.
- **No aplicable:** la pregunta no tiene casos sobre los que calcularse; por ejemplo, la
  proporción de coincidencias entre límites cuando no hay ningún límite de cuadro.
- **No calculado o inválido:** falta el precomputado, el origen incumple su contrato o la
  generación falló. No es una propiedad de la obra.

No hacen falta cuatro números especiales. La propuesta técnica es un valor nullable y un motivo
breve cuando no hay valor, más numerador, denominador y cobertura cuando procedan. Un dato parcial
puede tener recuento confirmado o intervalo sin tener un valor exacto. Estos metadatos pertenecen
al precomputado; la interfaz solo explicará los que ayuden a interpretar el resultado.

Para las tablas siguientes: `T` = extensión numerada de la fuente elegida; `U` = posiciones cuya
forma no está resuelta; `N` = secuencias con delimitación confirmada de toda la obra; `F` = posiciones
confirmadas de una forma. Los rangos han de cubrir el ámbito declarado sin solapes ni huecos
inadvertidos. Un fallo de cobertura no convierte una obra en una obra de extensión cero.

## Inventario por obra

### Extensión, repertorio y segmentación

Productores actuales: `recompute_obra_resumen_metricas`, `formas_de_la_obra` y
`analisis_obra_publico_json`. Lectores: índices, ficha, comparativas, laboratorio y autor.

| Medida actual | Cálculo o comportamiento observado | Propuesta: cero, ausencia y denominador |
| --- | --- | --- |
| `total_versos` | Suma de `n_versos`; una suma ausente acaba en 0 | Extensión numerada de la fuente seleccionada. Fuente ausente o rangos inválidos: sin valor, no 0. Sin denominador. D01 |
| `n_jornadas` | Recuento de jornadas | Recuento exacto si la estructura está registrada por completo; estructura no recogida: desconocida. No inferir una jornada ni cero. D01 |
| `total_secuencias` / `n_secuencias` | Número de filas de secuencia | Exacto con segmentación confirmada. Las filas extraídas son una propuesta de segmentación: no certifican por sí solas `N`. D04 |
| `n_formas_distintas` | Distintos slugs no nulos; no separa registros del catálogo sin forma | Recuento observado si hay pendientes; exacto si la clasificación es completa. No añadir «sin identificar» como forma. Separar los registros declarados sin forma. D02–D03 |
| `perfil_formas[*].versos` | Suma de posiciones por slug; los nulos se agrupan como `sin-forma-anotada` en el análisis | Recuento confirmado por forma; puede ser un mínimo cuando hay `U`. Ausencia de clave no significa 0 salvo ausencia demostrable. Mantener lo pendiente fuera del catálogo. D02 |
| `perfil_formas[*].proporcion_versos` | `F/T` | Mantener `T`, sin renormalizar lo conocido. Exacta si no hay incertidumbre relevante para esa forma; en otro caso intervalo conservador `[F/T, (F+U)/T]`. D02 |
| `perfil_formas[*].secuencias` | Recuento de filas de esa forma | Requiere límites confirmados; si no, conservar como recuento provisional de origen y excluirlo de resúmenes exactos. D04 |
| `perfil_formas[*].longitud_media_secuencia` | Posiciones de la forma / sus secuencias | Requiere ambas cantidades completas. Forma ausente: no aplicable, no media 0. D04 |
| `numero_efectivo_formas` | `exp(-Σ p ln p)`, con `p=F/T`, omitiendo slugs nulos | No publicar un valor exacto de toda la obra con reparto parcialmente desconocido. Resolver también el dominio de los registros sin forma. D03 |
| `p_max` | Mayor proporción de un grupo, incluido el grupo nulo | Lo desconocido no puede ser la forma dominante. Valor exacto solo con información suficiente; extensión pendiente por separado. D03 |
| `densidad_transiciones` | `100 × número de secuencias / T`; con `T=0`, devuelve 0 | Renombrar como densidad de secuencias y mantener la fórmula. Sin `T` válido o segmentación confirmada: sin valor. D04 |
| `longitud_media_secuencia` | `T / número de secuencias` | `T/N` con segmentación completa. Sin secuencias observables: no aplicable; sin segmentación estudiada: desconocida. D04 |
| `proporcion_italiana` | Posiciones de tradición italiana / `T`; la ayuda del laboratorio dice «versos con tradición identificada» | Mantener el denominador de toda la obra y corregir la ayuda. Si quedan posiciones de tradición posible no resuelta, dar intervalo. Tradición conocida puede ser elegible aunque la forma exacta siga pendiente. D02 |
| `proporcion_sin_forma` | Posiciones con slug vacío o nulo / `T` | Renombrar como proporción pendiente de identificar. No confundirla con verso aislado o versificación irregular declarados. 0 si toda la extensión está clasificada. D02–D03 |
| Arquitecturas / `perfil_formas_hijos` | Perfil separado; autor y gráficos pueden normalizar solo lo presente | Cobertura propia dentro de la forma. Canción conocida y arquitectura desconocida sigue contando como Canción. D02 |
| Rasgos, rima, remates y desviaciones | Datos de anotación; no hay una medida global uniforme para todo el repertorio | Una declaración positiva permite contar esa presencia. Ausencia de mención en una básica no permite negarla. Definir el ámbito aplicable de cada rasgo antes de crear su agregado. D02 |
| Facetas de presencia: formas, tradición, metros, variaciones y esquemas de rima | Arrays de slugs derivados de anotaciones y catálogo | Sirven para encontrar presencias documentadas; una lista vacía no demuestra ausencia en una básica. Los filtros negativos y sus denominadores necesitan cobertura. D02 |
| Diagrama métrico y cortes de jornadas/cuadros | Rangos para dibujar; el resumen fusiona formas contiguas | Proyecciones de estructura, sin denominador propio. Conservar posiciones pendientes y distinguir las declaradas sin forma. Una fusión visual no recalcula `N` ni demuestra una transición. D02, D04 |

En arquitectura hay tres casos: desconocida, no aplicable según el catálogo, o conocida. No se
introduce una arquitectura ficticia «sin determinar». Para un rasgo, una respuesta explícita
«ausente» sí puede dar cero dentro del ámbito revisado; omitir el campo no lo sustituye.

### Transiciones, cuadros y extremos de jornada

Productor: `analisis_obra_publico_json`; agregación: `corpus_comparativas_artefacto_json`.
Lectores: laboratorio y comparativas; no todas las columnas tienen hoy un indicador visible.

| Medida | Comportamiento observado | Propuesta |
| --- | --- | --- |
| `total_transiciones` | `max(número de secuencias - 1, 0)` | Contar pares realmente elegibles; decidir frontera entre jornadas. Una sola secuencia completa puede tener 0; falta de segmentación no. D04 |
| `transiciones[de,a].veces` | `lag` sobre todas las secuencias, sin partición por jornada; incluye `sin-forma-anotada` | No crear categorías de forma pendiente ni saltar A–desconocido–B. Separar límites con formas desconocidas. Cero de una pareja exige descartar su presencia en todos los límites relevantes. D04 |
| `cambios_cuadro_total` | Inicios posteriores al primer cuadro de cada jornada | Con estructura completa, 0 es válido si no hay límites internos. En una básica sin cuadros, desconocido. D05 |
| `cambios_cuadro_sin_cobertura` | Límites sin secuencia que cubra ambos lados | Indicador de cobertura, no ausencia de coincidencias. Mantener recuento separado. D05 |
| `cambios_cuadro_que_parten_secuencia` | Ambos lados pertenecen a la misma secuencia | Recuento sobre límites cubiertos; no deducir cambio de forma. D05 |
| `cambios_cuadro_con_cambio_secuencia` | Cambia el identificador de secuencia en el límite | Recuento sobre límites cubiertos; puede mantenerse la forma. D05 |
| `cambios_secuencia_misma_forma` | Secuencias distintas con igual forma en un límite de cuadro | Solo con ambas formas conocidas; dos pendientes no constituyen igualdad métrica. D05 |
| `proporcion_cambios_cuadro_con_cambio_secuencia` | Coincidencias / (límites totales − sin cobertura) | Mantener denominador cubierto y mostrar cobertura. Sin límites: no aplicable; límites existentes sin cobertura: desconocida. D05 |
| Aperturas y cierres | Primera/última secuencia cuyo inicio cae en la jornada | Exigir que cubra el primer/último verso de la jornada. Un interior conocido no sustituye un extremo desconocido. D05 |
| Pares apertura–cierre | Agregados por forma, jornadas y obras | Cada extremo tiene su cobertura; el par requiere ambos. Denominadores de jornadas y obras explícitos y distintos. D05 |

El recuento de límites entre secuencias no es automáticamente un recuento de cambios de forma.
La densidad actual tampoco mide exactamente esos límites: con una secuencia de 100 versos vale 1,
mientras que los límites entre secuencias son 0.

### Enunciación y fenómenos por secuencia

Productores: `analisis_obra_publico_json`, resúmenes de obra y corpus. Lectores: ficha, laboratorio,
filtros y comparativas. La medida de canto del resumen anterior y la del análisis no son idénticas.

| Medida | Comportamiento observado | Propuesta |
| --- | --- | --- |
| Canto, prosa, evocación métrica: extensión y proporción | Análisis: unión de rangos por tipo, dividida por `T`. Corpus y lector del laboratorio convierten la clave ausente en 0 | Mantener unión, sin duplicar solapes. 0 con revisión exhaustiva que establece ausencia; en básica sin dato: desconocido. Una presencia sin extensión delimitada no da una proporción exacta. D06 |
| `obras_resumen.pct_cantado` | Suma de longitudes, sin unión, multiplicada por 100 | Una definición compartida basada en unión; almacenar proporción 0–1 y convertir a porcentaje al presentar. Revisar compatibilidad de consumidores. D06 |
| Versos partidos | Secuencias con sí / secuencias respondidas | Mantener denominador de secuencias respondidas, no versos ni casos individuales. Sin respuestas: desconocido. Con respuestas negativas y ningún sí: 0. D06 |
| Cambios de espacio | Inicios con sí / inicios respondidos | Mismo tratamiento; mide inicios, no número total de cambios dentro de una secuencia. D06 |
| Eventos sobrenaturales | Secuencias con sí / respondidas | Mismo tratamiento; ausencia declarada a nivel de obra puede fundamentar respuestas negativas. D06 |
| Intervención masculina, femenina e indeterminada | Cada categoría seleccionada / secuencias con array respondido | Mantener categorías solapadas; pueden sumar más del 100 %. Indeterminado es respuesta, no pendiente. No convertir `null` en array vacío. D06 |
| Intervención de donaire y de personajes sobrenaturales | Exclusiva + compartida / respondidas; conserva ambos recuentos | Mantener proporción por secuencia. Exclusiva y compartida no miden cantidad de parlamento. D06 |
| Intervención femenina heredada | También figura en la agregación de compatibilidad | Mantener solo como compatibilidad durante transición; la medida actual usa selección múltiple de géneros. No mezclar las dos fuentes. D06 |
| Flags globales de presencia e intervención | El ayudante métrico usa algunos ceros por defecto, pero el wrapper los sustituye con lógica que conserva pendientes | No concluir que el resultado final siempre es cero. Propuesta: presencia verdadera con algún positivo; ausencia solo con ámbito completamente negativo; pendiente en los demás casos. Separar presencia de clasificación exclusiva/compartida. D06 |

El wrapper actual puede dejar una presencia global en `null` si alguna secuencia está pendiente,
incluso habiendo un positivo. Afirmar la existencia de un caso y conocer la distribución completa
son preguntas distintas. Las fichas detalladas publicadas deben cumplir su integridad editorial;
los pendientes aquí importan para básicas y para detectar incidencias del recorrido técnico.

La unidad actual de «prosa» procede de posiciones numeradas de rangos. Antes de rotularla como
cantidad de versos hay que precisar esa convención; una extensión no medida no es cero ni una
estimación libre. La fuente métrica por sí sola tampoco declara exhaustivamente todos los cantos.

## Agregación, autoría y filtros

| Resultado | Comportamiento observado | Propuesta |
| --- | --- | --- |
| Media, mediana, cuartiles, mínimo y máximo | `resumen_estadistico_json` ignora nulos y conserva ceros; sin valores, `n=0` y estadísticos nulos | Conservar esa regla, pero solo pasar ceros demostrados. Acompañar `n`, excluidos y cobertura; no convertir muestra vacía en mediana 0. D07 |
| Peso de forma / secuencias por obra en el corpus | SQL cruza formas y obras; una clave ausente aporta 0 | Incluir ausencia real, mantener desconocidos fuera de la estadística exacta y declarar cuánto queda sin evaluar. Añadir límites del resultado cuando sea útil, sin imputación. D02, D07 |
| Peso típico en grupos del laboratorio | Mediana de proporciones solo donde la forma aparece; sus pruebas lo exigen | Conservarla como «peso donde aparece», distinta de la mediana sobre todas las obras evaluables. No corregir una para hacerla coincidir artificialmente con la otra. D07 |
| Difusión de una forma o transición | Obras con presencia / todas las obras del grupo | Separar positivos, negativos confirmados y desconocidos. Cociente entre evaluables con su cobertura; para todo el grupo, intervalo entre positivos/total y (positivos + desconocidos)/total. Grupo vacío: sin proporción. D07 |
| Transiciones por obra | Corpus incluye 0 ausente; grupos calculan frecuencia típica en las que aparece | Mismas dos preguntas, con elegibilidad de límites y segmentación. Una lista vacía no certificada no prueba ausencia. D04, D07 |
| Extremos del corpus | Recuentos por jornadas y por obras | Cada jornada cuenta una vez en su denominador; obras distintas se cuentan aparte. Publicar cobertura de aperturas, cierres y pares. D05 |
| Perfil agregado de autor | Suma perfiles de unidades atribuidas; `total_versos_autor` suma lo identificado, y gráficos normalizan lo disponible | Conservar extensión atribuida total, identificada y pendiente. Perfil ponderado por posiciones, sin hacer desaparecer lo desconocido. D08 |
| Diversidad del autor | Helper normaliza las formas conocidas por su suma; media de diversidad considera unidades de obra | No equiparar diversidad del perfil agregado y media de diversidades por obra. Aplicar dominio y cobertura de D03 y nombrar cada resultado. D08 |
| Banda de «fiabilidad» de autor | `fiabilidadDeVersos`: baja con menos de 1500 posiciones, media desde 1500, alta desde 6000; `null` pasa a 0 | Es una banda de volumen, no una estimación de incertidumbre. Renombrarla o retirarla al integrar el corpus ampliado; volumen desconocido no es volumen bajo. D10 |
| Autoría por obra/jornada | `perfil_metrico_unidades` selecciona atribuciones por obra o jornada; perfiles por rango toman secuencias contenidas | Mantener esas unidades e identidades. Para jornadas, intersecar rangos cuando proceda; no trasladar una jornada atribuida al autor como si fuera toda la obra. D08 |
| Cronología | Laboratorio usa solapamiento del intervalo tradicional; un extremo final ausente se sustituye por el inicial; sin fecha no pasa un filtro activo | Conservar fechas de la fuente seleccionada. No inventar año central ni probabilidades por año. D09 |
| Distancias composicional y secuencial | Módulo `distancias.ts` y pruebas, sin importación desde rutas/componentes actuales; normaliza lo conocido y devuelve 0 entre perfiles vacíos | No activarlo así para parciales: desconocido no significa identidad ni diferencia máxima. Requiere contrato propio de elegibilidad y tratamiento de huecos. D10 |

No todos los `?? 0` son imputaciones: hay ceros de presentación, ordenación o geometría de
gráficos que no cambian el valor analítico. La revisión de implementación debe distinguirlos.
En transiciones, la exploración del laboratorio muestra la **media** de apariciones donde existe
la pareja; la comparación de grupos muestra la **mediana** en esa población. Conservar la
distinción al etiquetar y precomputar; no llamar a ambas simplemente «frecuencia típica».

### Dos problemas técnicos adicionales

1. `perfil_formas_rango` compara directamente con límites nullable. Para una llamada con ambos
   límites nulos, el predicado no admite ninguna fila. El fallback de `perfil_artefacto_obra_rango`
   puede llegar a esa llamada desde el resumen del autor. El ayudante de arquitecturas sí admite
   límites opcionales. Propuesta: unificar el significado «obra entera» de límites nulos y no
   presentar un fallback vacío como ausencia de formas. El caso sintético prueba el predicado,
   no la incidencia sobre autores concretos.
2. Hay significados distintos en SQL, ayudas y visualización: tradición italiana usa `T` aunque
   su ayuda dice solo tradición identificada; la documentación describe densidad como cambios;
   el perfil de autor y la obra no resuelven igual la diversidad parcial. Se deben alinear
   contratos y documentación tras aprobar las definiciones, con pruebas del recorrido real.

## Decisiones para revisión

Las etiquetas D01–D10 permiten resolver los puntos sin aprobar todo en bloque.

### D01 · Extensión

**Propongo** usar la numeración de la edición como base común. Una adición ya numerada cuenta;
una laguna con posiciones incluidas en la numeración se cuenta una sola vez. Las correcciones
estructurales de la norma no cambian ese denominador. En Los locos, 133 posiciones y 132 de
extensión normativa responden a preguntas distintas. Conservar ambas cuando estén disponibles.
No reconstruir posiciones perdidas que la fuente no cuantifica. Un fallo de importación no da `T=0`.

### D02 · Perfiles y datos parciales

**Propongo** reparto sobre el total, con parte pendiente visible e intervalos conservadores,
sin convertir todo lo conocido en 100 %. Con 600 redondillas, 200 romances y 200 posiciones
sin identificar, el peso de redondillas es 60–80 %, no 75 % ni un 60 % exacto. Las candidatas no
son probabilidades ni garantizan una lista exhaustiva. Solo estrechar un intervalo con evidencia
que descarte alternativas. Arquitectura, tradición y rasgos tienen coberturas independientes.

Una ausencia puede demostrarse sin resolver absolutamente todo si la evidencia restante descarta
esa forma; en otro caso permanece desconocida. No penalizar por sistema una básica completamente
identificada: para esa medida puede aportar un valor exacto igual que una detallada.

### D03 · Diversidad y registros sin forma

**Propongo** distinguir forma pendiente de clasificación explícita sin forma —verso aislado,
versificación irregular—. Estos últimos conservan su extensión en el reparto, pero no suman una
forma al recuento ni a la diversidad de formas. Para esa diversidad, el dominio serían los versos
clasificados como formas, con denominador propio y cobertura visible respecto de `T`; si no hay
ninguno, no aplicable. Lo pendiente que pueda alterar ese dominio impide un valor exacto global.
La dominancia se definiría en ese mismo dominio para acompañar al índice; el peso de la forma
más frecuente sobre `T` seguiría disponible en el perfil. Esto cambia deliberadamente la fórmula
vigente cuando hay registros sin forma y necesita aprobación expresa.

No propongo un umbral arbitrario de cobertura para dar por buena la diversidad. Hoy, una sola
forma conocida en la mitad de la obra produce 1,414 en el cálculo de obra: no es la diversidad
exacta de la obra ni la diversidad de esa parte conocida, que sería 1. El piloto deberá estudiar
la utilidad de resultados parciales; mientras tanto, recuento observado y cobertura, sin índice
exacto inventado. Una diversidad condicionada a lo identificado solo se añadiría con nombre propio.

### D04 · Secuencias, densidad y fronteras de jornada

**Propongo** mantener `100N/T` como densidad de secuencias y renombrar la clave. Confirmar la
segmentación antes de usar recuentos y longitudes como exactos; un remate no crea otra secuencia.
Esa confirmación puede resultar de revisar la tabla y aplicar las equivalencias según nuestros
criterios; no exige cotejar obligatoriamente el texto de cada obra ni auditar la edición.
En transiciones, propongo analizar por defecto las contiguas **dentro de cada jornada**, y guardar
las conexiones entre jornadas aparte. Esto sí cambia el cálculo actual: falta decidir si esa
separación responde a vuestro criterio. A–desconocido–B nunca se transforma en A→B.

### D05 · Articulación y extremos

**Propongo** permitir aperturas y cierres conocidos aunque el interior sea parcial, verificando
la cobertura del verso extremo. Básicas sin cuadros no entran en medidas de cuadros. Cero límites
es un recuento válido cuando se estudió la estructura; su proporción de coincidencias no es 0 %,
sino no aplicable. Donde haya límites parcialmente cubiertos, mostrar el denominador cubierto.

### D06 · Enunciación y fenómenos

**Propongo** conservar los ceros de ausencia comprobada en detalladas y en cualquier básica que
aporte evidencia exhaustiva de ese ámbito. Si una básica calla sobre canto, el dato es desconocido.
Una mención positiva sirve para presencia; solo rangos y cobertura suficientes permiten proporción
exacta. Canto y demás extensiones: unión de rangos, proporción 0–1. Fenómenos por secuencia:
sí/respondidas, con cobertura; sin respuestas no se calcula. Presencia global: sí con algún
positivo, no solo con todos los casos negativos.

Sobre prosa, **propongo** conservar de momento el recuento de posiciones numeradas que usa el
sistema y rotularlo así cuando proceda; no afirmar que cuantifica extensión textual en prosa.
Una medida distinta de extensión en prosa requeriría unidad propia antes de combinarla con versos.

### D07 · Población y ceros de las estadísticas

**Propongo** conservar dos resultados con nombres distintos: «peso en las obras evaluables»
incluye ceros reales; «peso donde aparece» solo incluye presencias. Añadir difusión con cobertura
e intervalo para el grupo entero cuando haya obras no resueltas. Nunca dividir por todas las obras
como si todas fueran negativas conocidas.

Con dos obras, una con 60 % de romance y otra con ausencia confirmada, la mediana global es 30 %,
el peso típico donde aparece es 60 % y la difusión es 50 %. Los tres son correctos. Si la segunda
obra es desconocida, la difusión del grupo está entre 50 % y 100 %; no es un 50 % exacto.

### D08 · Referente de autor y autoría por jornada

**Propongo** mantener como perfil de autor el reparto agregado ponderado por posiciones. Añadir
por separado la distribución por obras: una obra larga pesa más en el primero; cada obra cuenta
una vez en la segunda. Mantener las jornadas atribuidas como unidades propias con sus rangos,
sin llamarlas obras completas. Mostrar número de obras, jornadas y posiciones aportadas.

Para contrastar una obra con su autor, **propongo excluir esa misma obra y todas sus jornadas
del referente**, evitando que contribuya a la base con la que se la juzga. Si no queda referente,
no hay comparación. Este resultado también se prepararía en la precomputación.

### D09 · Fechas

**Propongo** conservar el filtro por solapamiento y llamarlo «obras compatibles con el periodo».
Un intervalo 1590–1600 es compatible con 1595–1596, pero no permite fechar la obra en 1595.
No repartirla uniformemente por años. Una fecha única expresamente registrada puede representarse
como intervalo puntual; un dato incompleto no se convierte automáticamente en fecha cierta.
La ausencia indebida de datación impide incorporar una básica, conforme al requisito ya acordado.

### D10 · Alcance de las correcciones

**Propongo** corregir los problemas técnicos descritos y sus lectores al implementar las reglas
aprobadas, con una generación nueva de precomputados y pruebas sobre fuentes detalladas y básicas.
No activar ahora distancias ni fijar un único índice de «confianza» para todas las medidas. La
incertidumbre se explica con la cobertura y los límites pertinentes; el experimento de sensibilidad
servirá para decidir después qué resultados parciales son útiles.

La etiqueta de fiabilidad actual depende solo del volumen: desde 6000 posiciones pasa a «alta».
**Propongo llamarla volumen de muestra**, si se conserva la banda, y mostrar los recuentos y la
cobertura por separado. No permite afirmar fiabilidad alta por reunir dos obras largas ni sustituye
la incertidumbre del corpus básico. Los umbrales actuales tampoco quedan validados por esta auditoría.

## Comprobaciones exigidas después de decidir

Los ejemplos anteriores serán casos de aceptación del productor combinado y sus lectores:
ausencia real frente a silencio de fuente; 600/200/200; diversidad con media obra pendiente;
forma conocida sin arquitectura; registros sin forma frente a pendientes; una secuencia y cero
transiciones; frontera entre jornadas; cuadros no recogidos frente a cero límites; extremos sin
cobertura; rangos enunciativos solapados; respuestas negativas frente a ninguna respuesta;
mediana global frente a condicional; atribución por jornada y referente sin la propia obra.

Habrá que ejecutar los productores modificados, no solo validar sus tipos o crear funciones.
También comprobar su persistencia, permisos y lectura bajo una misma generación. Nada de eso se
da por probado por los SELECT sintéticos de esta auditoría.

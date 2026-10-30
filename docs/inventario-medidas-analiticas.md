# Inventario general de medidas analíticas: ceros, ausencias y denominadores

Auditoría del 28 de octubre de 2026; decisiones y propuestas actualizadas el 29 de octubre.
**Criterios del inventario aprobados por el responsable el 29 de octubre de 2026.** La aprobación
incluye diversidad por formas, mediana y Q1–Q3 como resumen principal entre obras con media
accesible, poblaciones explícitas y las restantes precisiones D01–D10. Cierra su revisión de
criterios; no afirma que los cambios estén desplegados ni valida todavía un método de afinidad.
**Ámbito: medidas de obra, autor, comparativas y laboratorio de toda la plataforma**, para fichas
detalladas y básicas. No es una auditoría de todas las tablas ni de toda la lógica de la base.
La incorporación de las básicas motivó la revisión, pero sus reglas analíticas son generales.

Se han confirmado dos correcciones de criterio: incluir los registros declarados sin forma en la
diversidad y mantener las transiciones entre jornadas en el cálculo general. Se ha aceptado
abandonar la etiqueta de fiabilidad por volumen y separar volumen, cobertura y estabilidad.
El experimento de sensibilidad se realizará con el corpus de Lope reunido y formará parte del
artículo científico de presentación de Versología. Están aceptados el aprovechamiento de extremos
identificados y la exclusión de básicas sin cuadros de las medidas de cuadros, así como el cero
de ausencia analizada en detalladas publicadas frente al desconocido por silencio de la básica.
D01–D02 incluyen las aclaraciones incorporadas durante la revisión. La aceptación final sustituye
los rótulos de propuesta de esa discusión; el protocolo inferencial sigue en desarrollo.
Este documento no aplica cambios de cálculo por sí mismo. Las definiciones aprobadas se incorporarán a la
[metodología canónica](./metodologia-perfil-metrico.md) al implementar y verificar los cambios.

Últimas precisiones del 29 de octubre: se retira la propuesta de excluir por defecto las lagunas
atribuidas del perfil principal; se propone mantenerlas contabilizadas con reconstrucción
explícita. Las silvas no proporcionan un recuento de versos por medida por el mero hecho de
admitir 7 y 11. La prosa se localiza entre versos, sin medir su longitud ni calcular porcentaje.
También están aceptados el perfil agregado del autor ponderado por extensión, la distribución
por obras como lectura separada, la exclusión de la propia obra y sus jornadas del referente,
y el filtro cronológico por solapamiento, sin convertir un intervalo en su año medio.

## Qué se ha comprobado

Se han leído las definiciones vigentes de doce funciones de Supabase y seguido sus salidas hasta
los contratos JSON, el laboratorio y el perfil de autor. El
[registro de firmas y hashes](./importador-metrico/piloto/auditoria-medidas-2026-10-28.json) identifica la versión
auditada. La consulta se conserva en [auditar-medidas.sql](../scripts/importador-metrico/auditar-medidas.sql).
No se ejecutaron productores ni se inspeccionaron fichas individuales para buscar errores.

Además se ejecutó un SELECT con constantes para comprobar ejemplos de las fórmulas y predicados:
[consulta](../scripts/importador-metrico/casos-medidas.sql) y
[resultados](./importador-metrico/piloto/casos-medidas-2026-10-28.json). Son casos sintéticos; no prueban el recorrido
completo de recomputación ni cuantifican cuántas obras actuales están afectadas.

El análisis seguirá usando precomputados. Actualmente el laboratorio también resume grupos en
el navegador a partir de los valores por obra descargados; esa operación no consulta anotaciones
en vivo. Hay que mantener coherentes ambas definiciones, sin añadir cálculos sobre tablas en las
visitas a las páginas. El futuro productor combinado recalculará ambas fuentes, con una sola
aportación seleccionada por obra y generación, según el [plan](./importador-metrico/consultas-y-precomputacion.md).

Una detallada solo se publica con el 100 % de sus campos cumplimentados. Una discrepancia técnica
con esa regla requiere revisión; no autoriza a tratar como cero el dato ausente. En una básica,
la cobertura depende de la información disponible para cada medida, no de una supuesta ficha
detallada incompleta.

## Convenciones acordadas

- **Cero:** se estudió el ámbito necesario y se puede afirmar que no hay casos.
- **Desconocido:** no se recogió el dato o queda una parte que podría cambiar el resultado.
- **No aplicable:** la pregunta no tiene casos sobre los que calcularse; por ejemplo, la
  proporción de coincidencias entre límites cuando no hay ningún límite de cuadro.
- **No calculado o inválido:** falta el precomputado, el origen incumple su contrato o la
  generación falló. No es una propiedad de la obra.

No hacen falta cuatro números especiales. La propuesta técnica es un valor nullable y un motivo
breve cuando no hay valor, más numerador, denominador y cobertura cuando procedan. Un dato parcial
puede tener recuento confirmado sin tener un valor exacto de toda la obra. Los límites de escenarios
no son probabilidades ni se mostrarán por defecto como si lo fueran. Estos metadatos pertenecen
al precomputado; la interfaz solo explicará los que ayuden a interpretar el resultado.

Para las tablas siguientes: `T` = extensión registrada de la fuente elegida, con las correcciones
aceptadas; `U` = posiciones cuya
forma no está resuelta; `N` = secuencias con delimitación confirmada de toda la obra; `F` = posiciones
confirmadas de una forma. Los rangos han de cubrir el ámbito declarado sin solapes ni huecos
inadvertidos. Un fallo de cobertura no convierte una obra en una obra de extensión cero.

## Inventario por obra

### Extensión, repertorio y segmentación

Productores actuales: `recompute_obra_resumen_metricas`, `formas_de_la_obra` y
`analisis_obra_publico_json`. Lectores: índices, ficha, comparativas, laboratorio y autor.

| Medida actual | Cálculo o comportamiento observado | Propuesta: cero, ausencia y denominador |
| --- | --- | --- |
| `total_versos` | Suma de `n_versos`; una suma ausente acaba en 0 | Extensión de la fuente seleccionada con correcciones aceptadas. Corregir un dato erróneo sí cambia el total; ajustar el comprobador normativo no borra un verso existente. Fuente ausente o rangos inválidos: sin valor, no 0. D01 |
| `n_jornadas` | Recuento de jornadas | Recuento exacto si la estructura está registrada por completo; estructura no recogida: desconocida. No inferir una jornada ni cero. D01 |
| `total_secuencias` / `n_secuencias` | Número de filas de secuencia | Exacto con segmentación confirmada. Las filas extraídas son una propuesta de segmentación: no certifican por sí solas `N`. D04 |
| `n_formas_distintas` | Distintos slugs no nulos; no separa registros del catálogo sin forma | Contar las clases métricas identificadas, incluidos verso aislado y versificación irregular. Recuento observado si hay pendientes; exacto si la clasificación es completa. «Sin identificar» no añade una clase métrica. D02–D03 |
| `perfil_formas[*].versos` | Suma de posiciones por slug; los nulos se agrupan como `sin-forma-anotada` en el análisis | Recuento confirmado por forma; puede ser un mínimo cuando hay `U`. Ausencia de clave no significa 0 salvo ausencia demostrable. Mantener lo pendiente fuera del catálogo. D02 |
| `perfil_formas[*].proporcion_versos` | `F/T` | Mantener `T`, sin renormalizar lo conocido. Mostrar peso confirmado y pendiente por separado, sin repartir `U` entre formas. Si puede cambiar la identificación, no presentar el peso confirmado como reparto final exacto. D02 |
| `perfil_formas[*].secuencias` | Recuento de filas de esa forma | Requiere límites confirmados; si no, conservar como recuento provisional de origen y excluirlo de resúmenes exactos. D04 |
| `perfil_formas[*].longitud_media_secuencia` | Posiciones de la forma / sus secuencias | Requiere ambas cantidades completas. Forma ausente: no aplicable, no media 0. D04 |
| `numero_efectivo_formas` | `exp(-Σ p ln p)`, con `p=F/T`, omitiendo slugs nulos | Incluir clases métricas identificadas, también registros declarados sin forma. No publicar diversidad exacta de toda la obra con reparto parcialmente desconocido. D03 |
| `p_max` | Mayor proporción de un grupo, incluido el grupo nulo | Lo desconocido no puede ser la forma dominante. Valor exacto solo con información suficiente; extensión pendiente por separado. D03 |
| `densidad_transiciones` | `100 × número de secuencias / T`; con `T=0`, devuelve 0 | Renombrar como densidad de secuencias y mantener la fórmula. Sin `T` válido o segmentación confirmada: sin valor. D04 |
| `longitud_media_secuencia` | `T / número de secuencias` | `T/N` con segmentación completa. Sin secuencias observables: no aplicable; sin segmentación estudiada: desconocida. D04 |
| `proporcion_italiana` | Posiciones de tradición italiana / `T`; la ayuda del laboratorio dice «versos con tradición identificada» | Mantener el denominador de toda la obra y corregir la ayuda. Si queda tradición pendiente, mostrar peso confirmado y cobertura. Tradición conocida puede ser elegible aunque la forma exacta siga pendiente. D02 |
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
| `total_transiciones` | `max(número de secuencias - 1, 0)` | Mantener todos los pares contiguos, incluidos los de cambio de jornada. Separar conocimiento del límite y conocimiento de sus formas. Una sola secuencia completa puede tener 0; falta de segmentación no. D04 |
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
Acuerdo del 30 de octubre: guardar una básica acepta la segmentación mostrada, sin una casilla
adicional. La forma desconocida no invalida esa segmentación. Los límites con algún extremo
sin identificar se mantienen fuera de los pares evaluables, sin computar como presencia ni
ausencia de un par. Se conserva su cobertura separada.
La densidad actual tampoco mide exactamente esos límites: con una secuencia de 100 versos vale 1,
mientras que los límites entre secuencias son 0.

### Enunciación y fenómenos por secuencia

Productores: `analisis_obra_publico_json`, resúmenes de obra y corpus. Lectores: ficha, laboratorio,
filtros y comparativas. La medida de canto del resumen anterior y la del análisis no son idénticas.

| Medida | Comportamiento observado | Propuesta |
| --- | --- | --- |
| Canto y evocación métrica: extensión y proporción | Análisis: unión de rangos por tipo, dividida por `T`. Corpus y lector del laboratorio convierten la clave ausente en 0 | Mantener unión, sin duplicar solapes. 0 con revisión exhaustiva que establece ausencia; en básica sin dato: desconocido. Una presencia sin extensión delimitada no da una proporción exacta. D06 |
| Prosa: presencia y localización | El editor registra versos anterior/posterior, pero la agregación genérica auditada aplica longitud de rango y proporción también a prosa | Corregir ese desacuerdo: conservar presencia y localización entre versos. Ningún número de versos de prosa ni porcentaje de extensión. D06 |
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

Los extremos de una anotación de prosa son referencias de localización, no posiciones cuya
distancia mida el pasaje. La conversión genérica del productor a extensión es una discrepancia
con el criterio editorial, no una unidad pendiente de elegir. La fuente métrica por sí sola
tampoco declara exhaustivamente todos los cantos.

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

## Decisiones y aclaraciones

Las etiquetas D01–D10 permiten resolver los puntos sin aprobar todo en bloque.

### D01 · Extensión

**Aclaración aceptada:** el dato corregido es el que se utiliza. Si la extracción o
un rango era erróneo y se corrige, el total se recalcula con la corrección aceptada; el valor
original se conserva solo como procedencia. No se impone la numeración errónea de la edición.

Ejemplo concreto: una redondilla tiene cuatro versos. Si el texto tiene cinco porque contiene
un verso añadido, se registran los cinco y se declara la adición. El comprobador puede aceptar
«cuatro versos regulares más uno añadido». No se propone borrar ese quinto verso. En cambio,
si el OCR produjo cinco donde la foto tiene cuatro, se corrige la extracción y se registran cuatro.
El ajuste del comprobador y la corrección de la extracción son operaciones distintas. Si la
corrección editorial cambia realmente la extensión del texto base elegido, se usa esa extensión.
El responsable precisa la práctica vigente: los versos perdidos cuantificados y atribuidos a
una forma, por ejemplo dentro de un romance, se cuentan en ella. **Se retira la propuesta de
excluirlos por defecto del perfil principal.** Se propone mantener la práctica y hacer explícita
la reconstrucción, sin confundirla con observación de versos conservados ni inventar su texto.

Ejemplo: 98 versos conservados de romance y dos perdidos cuantificados y atribuidos al mismo
romance aportan 100 posiciones de romance al perfil editorial adoptado, dos de ellas reconstruidas.
Esas dos entran una sola vez tanto en la extensión total como en la de romance. Si la numeración
ya las incluye, no se vuelven a sumar. No se calcula `100/98` ni se mezcla un numerador reconstruido
con un denominador solo de conservados.

El resultado debe conservar cuántas posiciones son perdidas y cómo se atribuyeron. Los porcentajes
describen el análisis editorial con esa reconstrucción; no se rotulan todas esas posiciones como
directamente observadas. Un ensayo de sensibilidad podrá comprobar qué cambia al excluirlas o
variar las atribuciones dudosas, sin convertir esa variante en el perfil principal por defecto.
Si no se conoce cuántos versos faltan o no se puede atribuir su forma, se conserva esa limitación:
no se completa automáticamente una redondilla ni se inventa una cantidad para cerrar el cálculo.

### D02 · Perfiles y datos parciales

**Propuesta reformulada:** reparto confirmado sobre el total y parte pendiente por separado.
Con 600 redondillas, 200 romances y 200 posiciones sin identificar, se muestran 60 % confirmado
de redondillas, 20 % confirmado de romance y 20 % pendiente. No se reparte ese 20 % entre las
formas presentes ni se presupone que pertenezca a ellas: puede corresponder íntegramente a otras
clases. Tampoco se renormalizan 600/800 como si el 75 % describiera toda la obra.

El 60–80 % de la propuesta anterior era solo el límite matemático más amplio si nada descarta
que parte de lo pendiente sea redondilla. No expresa probabilidad, no dice que sea una resolución
verosímil y puede no aportar utilidad filológica. Se retira como presentación por defecto;
solo tendría sentido como escenario explícito de sensibilidad. Las candidatas no son
probabilidades ni garantizan una lista exhaustiva. Arquitectura, tradición y rasgos tienen
coberturas independientes.

Una ausencia puede demostrarse sin resolver absolutamente todo si la evidencia restante descarta
esa forma; en otro caso permanece desconocida. No penalizar por sistema una básica completamente
identificada: para esa medida puede aportar un valor exacto igual que una detallada.

### Alcance estadístico de esta presentación

`600/1000 = 60 % confirmado` es una descripción exacta de lo identificado bajo la fuente y reglas
elegidas. No identifica por sí solo la proporción final de redondillas ni es la probabilidad de
que una secuencia pendiente sea redondilla. Tampoco el 20 % pendiente es una categoría métrica
que deba entrar en la diversidad o crear semejanza artificial entre dos perfiles incompletos.

Para comparar autores o una obra con un corpus mixto se necesita un protocolo adicional:

- Definir el resultado que se compara: perfil agregado por extensión o distribución por obras.
  Las fichas básicas pueden aportar valores exactos para unas dimensiones y parciales para otras.
- No introducir el 60 % confirmado como si fuera el 60 % total exacto en un test, una distancia
  o una clasificación. Analizar las resoluciones compatibles con la evidencia, incluidas clases
  no observadas en la parte conocida, o declarar las suposiciones de cualquier modelo de imputación.
- Los límites de resoluciones posibles, los intervalos de confianza bajo un modelo y las
  probabilidades predictivas son objetos distintos. No usar una etiqueta común de «confianza».
  No se adopta ahora ningún modelo probabilístico para las formas pendientes.
- No asumir que los datos sin identificar se distribuyen como los conocidos: la ambigüedad de
  los términos puede concentrarse en determinadas clases o ediciones. La cobertura no basta
  para justificar esa hipótesis. Tampoco seleccionar solo obras identificadas garantiza que
  representen al corpus entero; se debe describir y evaluar esa selección.
- Una diferencia puede ser robusta si se mantiene bajo todas las resoluciones admisibles; si
  puede desaparecer o invertirse, el resultado es indeterminado bajo esos datos. Que dos perfiles
  puedan coincidir no demuestra afinidad ni autoría. Las conclusiones se limitarán a las medidas
  estudiadas y al referente declarado, con comparaciones múltiples controladas si se hacen tests.
- La descripción del corpus reunido no requiere inventar error muestral. Si se quiere inferir
  sobre otras obras o modelar una obra nueva, habrá que definir población y supuestos. Para
  estabilidad por obras no se tratarán sus miles de versos como observaciones independientes.

Esta es una propuesta de protocolo, no un método inferencial ya validado. Sigue el principio de
identificación parcial de [Horowitz y Manski (2006)](https://www.sciencedirect.com/science/article/pii/S030440760500062X):
los datos incompletos pueden acotar resultados sin identificar un único valor. Para el plan previo,
la descripción de ausencias, las hipótesis y la sensibilidad se toma como referencia metodológica
[TARMOS (2021)](https://pmc.ncbi.nlm.nih.gov/articles/PMC8168830/), adaptando sus principios generales
de estudios observacionales al corpus literario; no se trasladan modelos clínicos ni se prescribe
imputación múltiple para este proyecto.

### D03 · Diversidad y registros sin forma

**Corregido por el responsable:** verso aislado y versificación irregular identificados sí
contribuyen a la diversidad. Su clasificación como registros «sin forma» en el catálogo no
autoriza a excluirlos del análisis. Se retira la propuesta de eliminarlos del recuento y del índice.

Se calcula sobre clases métricas identificadas, incluidas esas categorías, con sus extensiones.
Un verso aislado conserva su medida conocida; no es un verso pendiente de identificar. El nivel
de agrupación del índice debe ser común a básicas y detalladas: incluir la categoría no implica
crear automáticamente otra categoría por cada rasgo o medida. Cualquier desglose analítico por
medidas deberá definirse expresamente; no se da por aprobado ni cambia la taxonomía del catálogo.
La dominancia incluye las clases identificadas, nunca un grupo artificial de pendientes.

**Criterio aprobado:** el índice principal compara la
distribución de clases generales del catálogo, con una categoría de verso aislado y otra de
versificación irregular. Mantener las medidas conocidas para consultas adicionales cuando su
evidencia permita responderlas, sin prometer un reparto completo de versos por medida;
no subdividir solo el verso aislado por heptasílabo/octosílabo/endecasílabo en el índice principal.
En términos del dominio de Versología, se propone **diversidad por formas**, incluyendo los
registros identificados de aislados e irregularidad. No se cruzan formas con arquitecturas,
esquemas de rima, metros ni rasgos para multiplicar las categorías del índice principal.
Esta aclaración de vocabulario no transforma esos registros del catálogo en formas normativas.
Razones:

1. La pregunta principal es variedad de clases métricas. Medida, arquitectura y rasgos son
   dimensiones adicionales; si se cruzan solo en algunas clases, el índice cambia de pregunta.
2. La misma regla de agrupación debe aplicarse a todas las obras, sin que una ficha detallada
   se vuelva más diversa que una básica únicamente por responder más campos.
3. En la fórmula exponencial de Shannon, dividir una clase en varias subclases con presencia
   aumenta el índice cuando se mantiene la misma extensión total. No es un error matemático:
   se ha cambiado el nivel de clasificación. La elección debe fijarse antes de interpretar
   diferencias entre autores y mantenerse versionada.
4. No se pierde la diferencia entre medidas: se conserva la información disponible y su alcance.
   «Verso aislado sin medida informada» conserva clase conocida y medida desconocida; no se
   transforma todo el verso en dato sin identificar ni se crea una medida artificial «desconocida».

Por ejemplo, dos versos aislados de medidas distintas constituyen una clase en el perfil general
y conservan dos medidas concretas conocidas. **Corrección a la propuesta anterior:** una silva
que admite heptasílabos y endecasílabos no informa cuántos versos de cada medida contiene. Saber
que su repertorio admite 7 y 11 tampoco demuestra que ambas aparezcan en ese pasaje. No se
reparte a medias ni se atribuye toda su extensión a las dos medidas.

No se exige anotar verso a verso ni se propone un porcentaje global de 7 y 11 con esos datos.
Una consulta sobre medidas conocidas se limita a ámbitos con información suficiente y declara
lo que excluye; no se presenta automáticamente como distribución de medidas de toda la obra
o del autor. La forma Silva puede estar completamente identificada sin ese desglose. Su falta
de recuento interno no reduce la cobertura de identificación de formas ni impide por sí sola
calcular la diversidad por clases. El índice principal por formas está aprobado y no depende
de crear un nuevo perfil universal de medidas.
Se recomienda documentar separadamente recuento de clases y diversidad efectiva, que pondera su
extensión: un verso aislado cuenta, pero no tiene el mismo peso que mil versos de romance.
La interpretación del índice efectivo se apoya en
[Jost (2006)](https://nsojournals.onlinelibrary.wiley.com/doi/abs/10.1111/j.2006.0030-1299.14714.x);
la agrupación métrica propuesta aquí es una decisión de este proyecto, no una conclusión de ese artículo.

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
**Confirmado por el responsable:** la transición entre jornadas es importante y entra en el
cálculo general, junto con las transiciones interiores. Se conserva ese criterio actual. Puede
marcarse el cambio de jornada para un desglose opcional, sin quitarlo del total ni rebajar su peso.
A–desconocido–B nunca se transforma en A→B.

### D05 · Articulación y extremos

**Aceptado:** permitir aperturas y cierres conocidos aunque el interior sea parcial, verificando
la cobertura del verso extremo. Básicas sin cuadros no entran en medidas de cuadros. Cero límites
es un recuento válido cuando se estudió la estructura; su proporción de coincidencias no es 0 %,
sino no aplicable. Donde haya límites parcialmente cubiertos, mostrar el denominador cubierto.

### D06 · Enunciación y fenómenos

**Confirmado por el responsable:** en una detallada publicada, el cero declara una ausencia
analizada. En una básica —la nueva denominación propuesta para mínima—, el silencio de la fuente
suele ser lo esperable y significa desconocido. Una básica sí puede aportar una presencia u otro
dato explícito si su fuente lo declara. No aplicar la garantía de integridad de una detallada
publicada a una detallada en elaboración. Una básica que excepcionalmente declare una ausencia
exhaustiva de ese ámbito puede aportar un cero documentado. Si calla sobre canto, es desconocido.
Una mención positiva sirve para presencia; solo rangos y cobertura suficientes permiten proporción
exacta. Canto y demás extensiones: unión de rangos, proporción 0–1. Fenómenos por secuencia:
sí/respondidas, con cobertura; sin respuestas no se calcula. Presencia global: sí con algún
positivo, no solo con todos los casos negativos.

El [rastreo preliminar del lote](./importador-metrico/piloto/rastreo-canto-2026-10-29.md) no localizó
declaraciones explícitas de canto en las cuatro extracciones ni mediante OCR de las 38 fotos.
No demuestra ausencia en las veinte obras. Se comprobaron visualmente las menciones de letrilla
en El molino y Las ferias de Madrid; no permiten marcar canto. Si falta un caso positivo de fuente,
la comprobación técnica deberá usar otro ejemplo documental o un caso sintético explícito.

**Precisado por el responsable:** la prosa siempre se localiza entre versos; su longitud no se
mide en este proyecto. El editor v2 registra el verso anterior y el posterior. Se retira la
propuesta de conservar un recuento de posiciones o buscar otra unidad de extensión para prosa.
No se calcularán «versos de prosa» ni porcentaje de extensión en prosa. Se conservan presencia
y localización; cualquier agregado de número de pasajes u obras con prosa se definirá aparte,
sin confundirlo con longitud ni presumir un recuento exhaustivo en una básica.

Auditoría inicial de código del 29 de octubre, antes de corregirlo: `CaracterizacionesPorRango.svelte` ya explica «prosa
(no numerada)» y pide entre qué versos aparece. En cambio, `caracterizacionesDeLaObra` en
`analisis-ficha.ts` sumaba `v_fin - v_ini + 1` para todos los tipos, y el laboratorio definía prosa
como proporción de versos. La auditoría SQL del 28 también encontró esa agrupación genérica.
La corrección de productores, contratos y lectores ya está implementada en el repositorio y
probada en copia aislada: contrato V3 y compatibilidad temporal con V2. No se modifica el editor
para medir prosa ni se cambia la anotación válida de sus extremos. Código y migración ya se
desplegaron en ese orden el 29 de octubre; los precomputados de Supabase están en V3 y se verificó
la ficha en la web real. [Registro del despliegue](./despliegues/2026-10-29-prosa.md).
El rastreo del lote ha permitido comprobar visualmente un caso concreto: «carta en prosa» sin
rango numerado en Nacimiento de Ursón y Valentín, p. 996. La fuente aporta presencia, pero no
una extensión en versos: no se puede completar automáticamente una proporción a partir de ella.
El casamiento en la muerte también declara un pasaje en prosa entre los vv. 524–525: ese intervalo
localiza una inserción entre versos, no cuantifica dos versos de prosa. Debe conservarse esa
diferencia al diseñar su representación, sin forzarla como rango de versos cantados/prosa.

### D07 · Población y ceros de las estadísticas

«Peso» se había usado de forma ambigua. Aquí significa la proporción de versos de una clase
dentro de una obra, no un coeficiente de confianza ni un peso asignado a una ficha básica.
Se recomienda sustituirlo en los rótulos por «porcentaje de versos» y nombrar el resumen:

- **Mediana del porcentaje por obra, incluyendo ausencias comprobadas:** usa todas las obras
  evaluables para esa pregunta, cada una una vez. Una ausencia comprobada aporta 0 %.
- **Mediana del porcentaje en obras donde aparece:** solo usa obras con presencia conocida y
  porcentaje evaluable. Responde a cuánto ocupa esa clase cuando se utiliza.
- **Presencia en el corpus:** obras donde aparece / obras cuya presencia o ausencia es evaluable.
  Es otra medida; la cobertura de obras desconocidas acompaña al resultado.

Ejemplo con dos obras completamente identificadas: una tiene 60 % de romance y otra 0 %. La
mediana por obra es 30 %, la mediana donde aparece es 60 % y la presencia es una de dos obras.
Ninguno de esos tres resultados es necesariamente el porcentaje agregado de versos de romance
del autor: este último divide los versos de romance sumados entre la extensión sumada y depende
también de la longitud de cada obra. Esa ponderación por extensión se discute en D08.

**Propongo** conservar dos resultados con nombres distintos: «peso en las obras evaluables»
incluye ceros reales; «peso donde aparece» solo incluye presencias. Añadir difusión con cobertura
e intervalo para el grupo entero cuando haya obras no resueltas. Nunca dividir por todas las obras
como si todas fueran negativas conocidas.

Con dos obras, una con 60 % de romance y otra con ausencia confirmada, la mediana global es 30 %,
el peso típico donde aparece es 60 % y la difusión es 50 %. Los tres son correctos. Si la segunda
obra es desconocida, la difusión del grupo está entre 50 % y 100 %; no es un 50 % exacto.

#### Media y mediana: presentación acordada

«Típico» no identifica una operación estadística. Se propone evitarlo como rótulo aislado y
usar «media», «mediana» y la población correspondiente. La media aritmética del porcentaje por
obra da el mismo peso a cada obra; la mediana es el punto central de esos porcentajes ordenados.
La proporción agregada del autor de D08 responde a otra pregunta: suma posiciones de la forma
y divide entre la extensión sumada, equivalente a ponderar los porcentajes por extensión.

La mediana resiste mejor valores extremos que la media; eso no la convierte en universalmente
mejor ni convierte una obra excepcional en un dato erróneo. La elección depende de la pregunta
y la distribución. [NIST, medidas de localización](https://itl.nist.gov/div898/handbook/eda/section3/eda351.htm)
explica esa diferencia; su [guía sobre asimetría](https://www.itl.nist.gov/div898/handbook/eda/section3/eda33d6.htm)
aconseja describirla con más de una medida de centralidad. Aún no se ha caracterizado la distribución
del corpus real de Lope para cada variable; no se afirma que todas sean asimétricas.

Recomendación para Versología:

1. Para resumir variación entre obras, mostrar **mediana y cuartiles Q1–Q3** como lectura principal,
   acompañados de número de obras y cobertura; conservar la **media** accesible en la tabla o
   exportación y en la metodología. Los cuartiles son descriptivos, no un intervalo de confianza.
2. Para clases poco frecuentes, acompañar siempre la centralidad de la proporción de obras donde
   aparecen. La mediana de todas puede ser 0 aunque sí se utilicen. Ofrecer el resumen donde
   aparecen responde a una pregunta adicional, no autoriza a ocultar las ausencias del corpus.
3. Conservar las obras excepcionales válidas y los valores individuales. No recortar ni excluir
   extremos por defecto. La media conserva información sobre su magnitud; la mediana refleja
   otra propiedad del reparto. No elegir la que produzca la diferencia más llamativa entre autores.
4. El perfil agregado del autor mantiene su ponderación por extensión, ya aceptada. **No se
   construye una composición a partir de medianas por forma**: aunque todas las obras tengan
   perfiles completos, esas medianas no tienen por qué sumar 100 %. Renormalizarlas cambiaría
   su significado. Medias y medianas de cada indicador se conservan como resúmenes separados.
5. Ni media ni mediana resuelven identificación pendiente o sesgos de selección. Se aplican las
   condiciones de D02 antes de presentar valores exactos y se declaran las obras que aportan
   información a cada resultado. Una respuesta no recogida no entra como cero.

Ejemplos sintéticos, no resultados del corpus:

- Porcentajes de una forma en cinco obras: `0, 0, 0, 10, 40`. Media: 10 %; mediana: 0 %;
  presencia: dos de cinco obras. Entre las dos presencias, media y mediana son 25 %. La media
  global no dice que una obra concreta tenga un 10 %; la mediana 0 no dice que la forma no exista.
- Tres perfiles completos sobre tres clases: `(80,20,0)`, `(0,80,20)`, `(20,0,80)`. Las medianas
  por componente son `(20,20,20)`, que suman 60 %. Su media componente a componente es
  `(100/3, 100/3, 100/3)`, que sí suma 100 % en esta población común y completamente clasificada.

La recomendación conserva comparabilidad con estudios que usan media. El artículo debe declarar
qué se compara, qué población entra y qué resumen es principal antes de interpretar las diferencias;
la validación de afinidad no se sustituye por escoger media o mediana.

### D08 · Referente de autor y autoría por jornada

**Aceptado por el responsable el 29 de octubre:** mantener como perfil de autor el reparto agregado ponderado por posiciones. Añadir
por separado la distribución por obras: una obra larga pesa más en el primero; cada obra cuenta
una vez en la segunda. Mantener las jornadas atribuidas como unidades propias con sus rangos,
sin llamarlas obras completas. Mostrar número de obras, jornadas y posiciones aportadas.

Para contrastar una obra con su autor, **se excluyen esa misma obra y todas sus jornadas
del referente**, evitando que contribuya a la base con la que se la juzga. Si no queda referente,
no hay comparación. Este resultado también se prepararía en la precomputación.

### D09 · Fechas

**Aceptado por el responsable el 29 de octubre:** conservar el filtro por solapamiento y llamarlo «obras compatibles con el periodo».
Un intervalo 1590–1600 es compatible con 1595–1596, pero no permite fechar la obra en 1595.
No sustituir el intervalo por su media ni repartirlo uniformemente por años. Una fecha única expresamente registrada puede representarse
como intervalo puntual; un dato incompleto no se convierte automáticamente en fecha cierta.
La ausencia indebida de datación impide incorporar una básica, conforme al requisito ya acordado.

### D10 · Volumen, cobertura y estabilidad

**Propongo** corregir los problemas técnicos descritos y sus lectores al implementar las reglas
aprobadas, con una generación nueva de precomputados y pruebas sobre fuentes detalladas y básicas.
No activar ahora distancias ni fijar un único índice de «confianza» para todas las medidas. La
incertidumbre se explica con la cobertura y los límites pertinentes; el experimento de sensibilidad
servirá para decidir después qué resultados parciales son útiles.

**Aceptado:** retirar la idea de «fiabilidad» deducida solo del volumen. La etiqueta actual depende
solo de la extensión: desde 6000 posiciones pasa a «alta», sin medir incertidumbre. No se trasladan
esas bandas al nuevo diseño bajo otro nombre.

**Marco aceptado:** volumen, cobertura y estabilidad por separado. Las fórmulas de cobertura y
el diseño de las comprobaciones siguientes son su desarrollo propuesto, todavía por validar:

1. **Volumen de muestra:** número de obras distintas, jornadas aportadas como unidades propias y
   posiciones totales de las fuentes seleccionadas. Se informa también cuántas fichas son básicas
   y detalladas, sin convertir su tipo en una penalización de peso. Son recuentos, sin bandas.
2. **Cobertura de cada medida:** cantidad conocida dividida por la cantidad aplicable. Para
   clasificación métrica, posiciones identificadas / posiciones totales; aislados e irregularidad
   identificados cuentan como conocidos. Para arquitectura, posiciones con arquitectura conocida
   / posiciones en las que es aplicable. Para transiciones clasificadas, límites con ambos lados
   identificados / límites existentes, incluidos los de cambio de jornada. Un límite existente
   puede estar contado aunque no se conozcan sus formas. Para fenómenos por secuencia,
   respondidas / secuencias a las que se aplica la pregunta. Sin denominador aplicable no hay 0 %.
3. **Composición de la cobertura:** conservar tanto posiciones como obras evaluables; una obra
   larga no debe ocultar que muchas otras están pendientes. Los ámbitos no recogidos de una
   básica son desconocidos; los no aplicables quedan fuera del denominador correspondiente.
4. **Estabilidad del referente:** recalcular dejando fuera una obra cada vez, incluidas todas
   sus jornadas, y medir cuánto cambian los pesos de clases y otros indicadores aprobados. Se
   informa el rango de cambios observado, no una supuesta probabilidad de que la atribución sea
   correcta. La variación entre obras es una propiedad del repertorio, distinta de datos ausentes.
5. **Sensibilidad a lo desconocido:** partir de fuentes suficientemente identificadas para la
   medida ensayada y ocultar sucesivamente parte de sus datos, manteniendo un resultado de
   referencia. Probar pérdidas repartidas, concentradas en ciertas obras y concentradas en
   categorías poco frecuentes; estas últimas pueden alterar mucho la diversidad con pocos versos.
   Comparar desviación del resultado y pérdida de cobertura. No corregir ni puntuar la edición:
   se estudia la pérdida de información respecto de la declaración de la fuente.

Ejemplo: 20 obras y 60000 posiciones, de las que 54000 tienen clase métrica identificada, dan un
volumen de 20 obras y una cobertura métrica del 90 %. No implican «90 % de fiabilidad», cobertura
del 90 % para canto ni estabilidad de una comparación de autoría. El experimento determinará
qué resultados siguen siendo útiles bajo cada patrón de pérdida, sin fijar un umbral universal.
Estos resultados se generarán y guardarán en la precomputación; no se calcularán sobre anotaciones
durante las visitas a la web.

**Experimento y artículo acordados:** el responsable sitúa el experimento tras reunir el corpus
de Lope; será parte del artículo científico de presentación de Versología. Conviene fijar el
protocolo antes de examinar los resultados: corpus y versiones de fuentes, medidas objetivo,
patrones de pérdida, repeticiones y semillas, criterios de evaluación y registro de resultados.
El corpus importado no será automáticamente una referencia sin incertidumbre. Para medir error
por ocultación se necesitan ámbitos suficientemente resueltos de partida para la medida ensayada;
la incertidumbre original que permanezca se documentará por separado. No se pretende medir la
verdad filológica ni el error de los editores de las fuentes.

## Cierre de criterios y trabajo restante

La aprobación final cierra las decisiones de esta tabla; no se pedirán de nuevo para implementar
lo acordado. Permanecen las comprobaciones técnicas y el protocolo científico de comparación.

| Punto | Criterio adoptado y estado |
| --- | --- |
| D01: lagunas | Contar las posiciones perdidas cuantificadas y atribuidas en su forma y en el total, sin duplicarlas, conservando su carácter reconstruido. No inventar cantidad ni forma desconocidas. |
| D03: nivel de agrupación | Diversidad por formas, incluidos aislados e irregularidad, sin cruzarlas con arquitecturas/esquemas/metros. No se promete un reparto universal por medidas. |
| D05: detalle de denominador | Extremos conocidos y exclusión de básicas sin cuadros están aceptados. Un recuento cero de límites puede ser válido; dividir por cero no da 0 %, por lo que esa proporción es no aplicable. Es una regla técnica derivada, no otra aprobación necesaria. |
| D06: fenómenos | Cero analizado de detalladas publicadas y desconocido por silencio de básicas están aceptados. Prosa definida como presencia/localización; corrección implementada y probada en copia, pendiente de despliegue. Los otros fenómenos conservan la unidad que se anota y declaran sus respuestas conocidas; no se exige aprobar cada caso aritmético. |
| D07: centralidad y población | Mediana y Q1–Q3 como resumen principal entre obras, media accesible y presencia en el corpus; distinguir todas las obras evaluables de las presencias. No sustituye resolver la incertidumbre de identificación. |
| D08: referente | Aceptado: perfil agregado ponderado por extensión y distribución por obras aparte; excluir la obra contrastada y sus jornadas. Autoría por obra/jornada se mantiene. Pendiente de implementación en la comparación mixta, no de otra aprobación. |
| D09: fechas | Aceptado: solapamiento como «compatible con el periodo», sin usar la media del intervalo como fecha. No interpretar ventanas que se solapan como periodos disjuntos al sumar recuentos. |

D02 permite una presentación descriptiva sencilla, pero no cierra todavía el procedimiento para
declarar semejanza o diferencia en el artículo. Es una tarea de diseño y validación estadística,
no algo que el responsable deba resolver aprobando una fórmula aislada ni leyendo todo el SQL.

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

# Metodología del corpus mínimo

Este documento recoge los acuerdos del diseño del importador. Distingue lo aceptado como fuente,
lo comprobado en la extracción y lo identificado mediante el catálogo. Las propuestas que aún
requieren decisión figuran en la [hoja de ruta](./hoja-de-ruta.md).

## La edición es la fuente de referencia

Se acepta la declaración métrica de la edición base. El proyecto no estima sus posibles errores
filológicos ni necesita una anotación exhaustiva contra el texto de las veinte obras para comenzar.
La edición, su localizador y su denominación literal deben acompañar a los datos derivados.

Una persona revisa la extracción contra las fotografías y corrige rangos, filas, términos, notas y
totales hasta que la reproducción sea fiel. Ese resultado constituye el **gold de transcripción**.
Un desacuerdo aritmético visible en la propia fuente se conserva como incidencia documentada; no
se corrige atribuyendo a la fuente un dato que no declara.

La **referencia de normalización** registra las correspondencias revisadas con nuestro catálogo.
Puede contener identificaciones exactas, conjuntos de candidatas y términos pendientes. Una
transcripción validada no convierte automáticamente en cierta una equivalencia propuesta por la IA.

## Profundidad y segmentación

La estructura de obras, jornadas y secuencias es común. La métrica mínima tendrá una tabla propia,
separada de las anotaciones detalladas v2: no se completan por defecto sus preguntas obligatorias
ni se interpreta su ausencia de respuestas con las reglas de una anotación completa. Una proyección
analítica común permitirá comparar dimensiones equivalentes, con su evidencia y cobertura.

El nivel de detalle puede variar entre secuencias de una misma obra. Se conserva forma,
arquitectura, medida, rima o rasgos únicamente hasta donde los documente la fuente y permita la
correspondencia revisada. La ausencia de detalle no significa ausencia del fenómeno ni conformidad
comprobada con todas las exigencias de una arquitectura.

El criterio interno es cambio de forma → cambio de secuencia. Una inserción B entre dos tramos A
se representa como A → B → A, con tres secuencias y sin solapamientos. La transformación de filas
editoriales a secuencias analíticas conserva su trazabilidad. Si la fuente no permite localizar
una inserción o decidir su identificación, se registra la limitación sin inventar límites.

Las fechas son obligatorias para la ficha mínima destinada al corpus cronológico; su fuente es
opcional, aunque puede ser la propia edición base. El género es obligatorio, con Comedia como
valor inicial para este lote. Se registra el autor sin exigir fundamentos de autoría: se priorizan
obras no discutidas y la fundamentación queda para la ficha completa. No se revisan ahora las
atribuciones existentes. Los intervalos y las dataciones alternativas se conservan; no se
sustituyen silenciosamente por un año central.

Al pasar al trabajo completo, el editor elige entre conservar jornadas y secuencias para corregirlas
o vaciar esa estructura. Al abrir una secuencia consulta la propuesta del importador, que no es una
respuesta aceptada en v2. Puede escoger otra edición. La confianza en la edición como fuente del
corpus mínimo no obliga a confiar en ella para el análisis detallado.

Para que el trabajo en curso no altere el referente, se mantiene la copia fija de la
importación confirmada, incluidos sus metadatos y rangos, hasta publicar la completa. Entonces el
análisis completo sustituye su aporte, sin contar la obra dos veces. La mínima puede conservarse
como referencia después de dejar de contribuir; su permanencia documental no implica elegibilidad.

## Equivalencias y candidatas

La denominación de la edición y la identificación normalizada son datos distintos. El catálogo y
las equivalencias aprobadas ayudarán a la IA y al importador; el resultado original siempre se
conserva. Una correspondencia puede depender de la edición, su contexto o la información adicional
de la propia declaración, no solo de una coincidencia de palabras.

El procedimiento se apoya en la sinopsis de la edición y en correspondencias reutilizables.
No exige consultar el texto dramático para resolver cada etiqueta ambigua. Identificar la forma
de un pasaje concreto no autoriza a trasladar esa equivalencia a otros usos de la misma palabra;
cuando la terminología no discrimina, se mantiene la ambigüedad en el corpus mínimo.

Decisión del responsable del 22 de octubre de 2026: «estancias con pareado final» se normaliza
como **Canción al nivel de forma**, con remate en pareado declarado. El modelo ya contempla
el remate o envío como sección de la canción. No se exige identificar arquitectura, patrón de
estancias ni esquema concreto para conservar esos datos parciales en el piloto. La correspondencia
se aplica por la declaración terminológica; no depende de cotejar el texto de esa obra.

| Resultado | Qué permite afirmar |
| --- | --- |
| Identificación exacta revisada | La declaración corresponde a una entidad del catálogo en el nivel indicado |
| Conjunto acotado de candidatas | La identificación pertenece a ese conjunto, si su exhaustividad está justificada |
| Candidatas orientativas | Son posibilidades a examinar; otras identificaciones siguen abiertas |
| Sin resolver | No hay correspondencia suficiente; se conserva la declaración original |

Se contempla registrar usos como «este término suele designar estas tres formas». **Está pendiente
definir su representación y validación.** No se interpreta esa frase como exclusividad ni como una
distribución equiprobable. Para utilizar una lista como restricción de un cálculo hay que justificar
que las alternativas externas quedan descartadas. Las sugerencias de IA no adquieren ese carácter
sin revisión.

Cada correspondencia debería indicar su ámbito, fundamento, responsable de revisión y versión.
Esta es una orientación para el contrato de datos; los nombres de campos y tablas no están cerrados.
El MD que acompañe al prompt y las reglas del importador se producirán desde la misma referencia
versionada, evitando dos repertorios manuales divergentes.

«Forma sin resolver» expresa un estado de identificación, no una forma adicional del catálogo.
Tampoco equivale a versificación irregular. «Letrilla» se conserva como denominación de fuente:
no permite asignar por sí sola una forma concreta ni una caracterización de canto.

## Incertidumbre y medidas

Se distinguen la falta de profundidad, la identificación pendiente, los errores de extracción o
normalización y la incertidumbre de la muestra y sus fechas. El piloto estudia las dos operaciones
del importador, no la corrección filológica de la fuente aceptada. Cobertura no equivale a confianza:
un 95 % de versos identificados no constituye un intervalo de confianza del 95 %.

Las secuencias pendientes permanecen en su posición y sus versos en el denominador de la obra.
No se suman como otra forma, no desaparecen al normalizar el perfil y no producen un cero de
ausencia. Una medida calculada solo sobre versos identificados se denomina y presenta como tal.
En transiciones no se salta un tramo desconocido creando una transición directa entre sus vecinos.

Una medida puede expresarse como valor identificado, cobertura y límites compatibles con lo
pendiente. Los conjuntos exhaustivos de candidatas pueden estrechar esos límites; las listas
orientativas no justifican cerrar el espacio de posibilidades. Cualquier asignación hipotética
usada en un escenario sigue siendo un escenario, no se guarda como identificación.

La cobertura se estudia por obra, versos, secuencias, dimensión y periodo según la pregunta. Se
examina también cuánto se concentra en determinadas denominaciones o fuentes. Una laguna pequeña
en versos puede abarcar todos los casos de una forma rara. No habrá un umbral universal de utilidad
antes de realizar los experimentos.

## Dos experimentos diferentes

**Degradación de identificaciones conocidas.** Se alteran datos revisados mediante pérdidas de
etiquetas, confusiones terminológicas, omisiones o cambios de límites. Se comparan los resultados
con la referencia previa, con escenarios documentados y semillas reproducibles cuando haya azar.
Las perturbaciones respetan lo que representan: quitar una etiqueta conserva el rango y sus versos.

**Sensibilidad a correspondencias sistemáticamente pendientes.** Primero se mide su extensión y
distribución, por ejemplo la de todas las filas denominadas «letrilla». Cuando no existe una
identificación de referencia, no se puede medir el error real de perderla. Se calculan límites y
escenarios; si se resuelve una muestra con información suficiente, podrá ensayarse su ocultación
sin extrapolar automáticamente esa correspondencia a todo el término.

Ambos experimentos evalúan cambios en medidas concretas y en interpretaciones cronológicas o
comparativas. La muestra inicial sirve para aprender el procedimiento, no para proclamar una
tolerancia universal de todo el corpus de Lope.

## Uso del corpus y publicación

Por definición editorial, una ficha del recorrido detallado solo se publica cuando todos sus
campos están completos al 100 %. El tipo de ficha y su estado editorial son dimensiones distintas.
La revisión de datos existentes puede identificar incidencias respecto a esa regla, sin rellenar
campos ni modificar estados automáticamente. No se debe deducir de un agregado con cero cuál fue
la respuesta del editor: cada caso se contrasta con sus datos y con la definición de la medida.

Una ficha mínima confirmada puede aportar datos al perfil del autor. No pesa menos por carecer de
campos que el análisis no necesita. La elegibilidad depende de la evidencia y cobertura de la
medida, no solo de la etiqueta mínima/completa. Los datos no estudiados de cuadros, personajes u
otros fenómenos permanecen desconocidos, no se convierten en ausencias.

La consulta individual de fichas y la difusión de resultados agregados tienen reglas diferentes.
Se podrán seleccionar comparaciones para fichas completas sin publicar las fichas mínimas que
contribuyeron al referente. Se debe declarar el universo utilizado, su cobertura y las limitaciones
relevantes. **El uso de resultados agregados del corpus mínimo en fichas completas forma parte del
alcance acordado**, además de su exploración en el laboratorio. Importan admin/IP y editores con
autorización individual; los importadores autorizados consultan todas las mínimas, viendo quién
importó cada una, sin acceder por ello al laboratorio. Quien importa comprueba y confirma el guardado;
no se añade un nuevo estado editorial de validación ni una segunda aprobación por otro usuario.
Quedan por concretar las condiciones para seleccionar cada resultado difundible.

Como propuesta para validar, al situar una obra respecto al autor se excluirá la propia obra y sus
versiones del referente. También deben fijarse la unidad de agregación, el tratamiento de fechas
amplias y las condiciones que permitan redactar una comparación pública.

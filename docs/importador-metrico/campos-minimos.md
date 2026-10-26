# Campos mínimos y conexión con Versología

Propuesta revisada el 26 de octubre de 2026 con las indicaciones del responsable. **No aplicada
a la DB.** Este documento describe el funcionamiento esperado; el [diseño de integración](./diseno-integracion.md)
explica qué partes de la plataforma habrá que adaptar.

## Datos de la obra

| Dato | Obligatorio | Cómo se obtiene |
| --- | --- | --- |
| Título | Sí | Del resultado pegado o del formulario |
| Autor | Sí | Se selecciona o reconoce en el catálogo de autores |
| Fundamentos de autoría | No | Se completarán al elaborar la ficha completa; no bloquean este importador |
| Género | Sí | Comedia preseleccionada para el lote actual; se conserva como dato de la obra |
| Edición base | Sí | Referencia de la edición fotografiada |
| Fecha inicial y final | Sí | Intervalo; si hay un año concreto, ambos extremos coinciden |
| Fuente de datación | No | Puede ofrecerse la edición base como valor inicial, editable y eliminable |
| Jornadas | Sí | Número y límites de cada una |
| Secuencias | Sí | Rangos y declaración métrica, hasta el nivel identificable |
| Editor asignado | No | Se asignará cuando alguien vaya a realizar la ficha completa |
| Persona que importa | Sí, automático | Usuario autenticado que confirma la importación, junto con fecha y hora |

El lote se centrará preferentemente en obras de autoría no discutida. Se registra el autor sin
exigir una argumentación nueva ni presentar la importación como investigación de autoría.
No se revisarán ahora los fundamentos de las obras que ya están en la plataforma.

Las fechas procedentes de las ediciones se guardan en los campos de datación bibliográfica
`fecha_inicio_trad` y `fecha_fin_trad`. No se copian a la propuesta propia de Versología.
Si la fuente de datación se deja vacía, continúa vacía: no se atribuye silenciosamente a la edición.
Las hipótesis alternativas del material se conservan como notas, sin inventar un año medio.

La persona que importa se registra en `importaciones_metricas.importado_por` y `importado_en`:
no ocupa `editor_asignado` ni se convierte por eso en autor de la futura ficha pública.
El servidor toma su identidad de la sesión; no hay que escribirla en el prompt.

## Estados: guardar y dejar lista una mínima

Propongo añadir **Mínima validada** (`minima_validada`) al vocabulario de estados. Es una propuesta
pendiente de confirmar e implementar, no un término disponible hoy.

| Tipo de ficha y estado | Uso |
| --- | --- |
| Mínima / Borrador | Importación pendiente de comprobación; todavía fuera del corpus |
| Mínima / Mínima validada | Datos utilizables por admin/IP en los análisis que su cobertura permita; sin ficha individual pública |
| Completa / En elaboración | Trabajo v2 con sus exigencias habituales; el corpus puede seguir usando la copia mínima validada, sin leer los cambios del borrador |
| Completa / Publicada | El corpus usa el análisis completo; la mínima queda solo como referencia si se conserva |

Así distinguimos **estar lista para el corpus mínimo** de **estar publicada como ficha completa**.
Usar Publicado también sería técnicamente planteable, pero obligaría a revisar todos los lugares
que hoy lo interpretan como ficha detallada publicable. Recomiendo el término específico.
Las mínimas podrán contribuir igualmente a los agregados seleccionados para fichas completas.

Se añade `obras.tipo_ficha` con valores `minima` y `completa`; las existentes conservarían el
recorrido completo. Se mantienen `obras.estado` y `visible_publico`, este último falso en mínimas.
Validar una mínima comprueba sus datos, rangos y correspondencias aceptadas; no exige responder
el checklist de personajes, cuadros, sinopsis o anotación detallada.

## Qué se comparte y qué se guarda aparte

Se reutilizan las tablas **obras, jornadas y secuencias**. La métrica mínima tiene una tabla aparte
de las anotaciones v2, con una fila por secuencia mientras se trabaja en la mínima. Para preparar
la completa, el editor podrá conservar y corregir esa estructura o vaciarla para empezar de nuevo.
En ambos casos revisará la métrica; las identificaciones importadas no pasan a v2 como respuestas.

| Dato por secuencia mínima | Significado |
| --- | --- |
| Vínculo a la secuencia | Identifica la obra y su rango en la tabla común |
| Forma | Identificación revisada; puede quedar vacía si no se resuelve |
| Arquitectura | Solo cuando se conoce; puede quedar vacía aunque la forma esté identificada |
| Denominación original y fuente | Acceso a la fila de la edición y sus notas, conservadas en la importación |
| Segmentación confirmada o provisional | Indica si ese bloque puede tratarse ya como secuencia según nuestro criterio |
| Alternativas y detalles | Información opcional explicada en la sección siguiente |

Los rangos son inclusivos y el sistema calcula su extensión, en lugar de exigir otra cifra manual.
Los totales impresos se conservan aparte para comprobar discrepancias. No se crean rangos si son
ilegibles: la entrada puede seguir en borrador hasta resolver su representación.
Las lagunas y los versos añadidos se declaran; no se esconden para cuadrar totales.

Las secuencias siguen sin `jornada_id`: su pertenencia se determina por los límites. El deseo de
hacer lo mismo con los cuadros queda anotado como mejora futura independiente; no se cambia ahora.
Las caracterizaciones no estudiadas permanecen desconocidas y no se crean cuadros ficticios.

## Alternativas, origen y detalles, con ejemplos

Son tres cosas sencillas que el sistema conserva, no tres formularios nuevos que la persona deba
rellenar en todas las secuencias:

- **Alternativas:** si la edición dice «tercetos» y no sabemos qué tipo son, guardamos el nombre y
  las posibilidades pertinentes. Ninguna se cuenta como identificación confirmada. Una lista de
  posibilidades no es necesariamente exhaustiva ni tiene porcentajes de probabilidad.
- **Origen:** permite volver a la fila, foto o nota de donde salió el dato. Si una fila se convierte
  en A → B → A, las tres secuencias siguen enlazadas con esa misma declaración original.
- **Detalles:** si la edición aporta algo más, se conserva sin completar lo que no dice. Por ejemplo,
  Canción sin arquitectura conocida, con un remate en pareado declarado. No se inventa el patrón
  de las estancias ni se genera por ello una anotación v2.

En Los locos se mantienen las desviaciones acordadas: el heptasílabo de v. 2172 y el verso añadido
de v. 2666. Este último permanece dentro de la secuencia de redondillas: 133 versos de pasaje,
132 para comprobar su extensión normativa. No se declara laguna ni se parte la secuencia por él.
Las faltas ya incluidas en la numeración no se vuelven a sumar al comprobar la norma.

Los detalles con uso analítico tendrán referencias y validaciones, no solo texto libre.
La distribución concreta en tablas auxiliares se resolverá en el contrato técnico. No necesitamos
reproducir todas las preguntas y relaciones de v2 para el piloto. Tampoco se pide a la persona
redactar una justificación distinta para cada coincidencia sencilla: las reglas revisadas aportan
su fundamento; los casos especiales conservan su decisión y la nota que la sostiene.

## Cómo utiliza los datos el laboratorio

Cuando hablábamos de «contrato común», nos referíamos a **una misma manera de entregar los datos
a los cálculos**, no a heredar secuencias ni a convertir una mínima en anotación completa.

Mientras la obra solo tenga una mínima validada, el corpus usa esos datos aceptados. Durante la
elaboración de la completa mantiene una copia fija de esa importación, no las jornadas y secuencias
que el editor esté modificando. Al publicar la completa, pasa a usar v2 y deja de contar la mínima.
Con una sola definición se calcula el peso de cada forma, conservando qué versos siguen sin resolver.
La obra se cuenta una sola vez y cada medida declara su universo, procedencia y cobertura.
Al declarar cuántas fichas mínimas y completas sostienen un resultado, se cuenta la fuente usada:
una obra en elaboración todavía aporta como mínima mientras se use su importación validada.

Saber la forma no implica saber la arquitectura, la rima concreta o los personajes. No conocer
un dato no se convierte en cero ni en ausencia. Tampoco se elimina un tramo desconocido para crear
una transición directa entre sus vecinos. La incertidumbre se estudia por medida, no con un único
porcentaje de confianza para toda la ficha.

Los datos individuales mínimos quedan bajo sus permisos internos. Los resultados globales sí
pueden servir para situar una ficha completa frente al corpus del autor, con tamaño, cobertura y
limitaciones explícitos. Esto no requiere publicar las fichas mínimas de origen.

## Cuando un editor hace la ficha completa

El editor elige entre **conservar jornadas y secuencias para revisarlas** o **vaciar esa estructura
y comenzar de nuevo**. La elección se refiere a la estructura de trabajo, no al borrado de la obra
ni a aceptar automáticamente su métrica. Puede cambiar de edición y corregir los metadatos.

Al abrir una secuencia se muestra un apartado **Propuesta del importador**, separado de lo anotado
en v2. Incluye denominación editorial, forma propuesta o identificada en la mínima y notas de fuente.
Una identificación aceptada para el corpus mínimo sigue siendo una propuesta para el análisis
detallado: no rellena respuestas aprobadas ni satisface por sí sola el checklist completo.

Si cambia el rango, se muestra el tramo original al que correspondía la propuesta. No se extiende
su identificación a los versos nuevos. Si el nuevo tramo reúne varias filas, se presentan las
referencias pertinentes sin elegir una silenciosamente. Si cambia la edición y su numeración,
el original sigue consultable pero no se da por establecida una correspondencia entre versos.

### Mantener el referente mínimo hasta publicar la completa

La propuesta es conservar en la importación una **copia fija de los datos mínimos validados**:
edición, autoría usada, fechas, género, jornadas, rangos, identificaciones, candidatas y detalles.
Es necesaria porque las tablas comunes estarán cambiando, o sus filas pueden borrarse al reiniciar.
Conservar únicamente la tabla métrica enlazada a secuencias editables no protegería el referente.

Esta copia se guardaría como `importaciones_metricas.datos_validados`, con quién la valida y cuándo.
La referencia mínima vigente de cada obra se marca en `usada_en_corpus`: solo una importación
validada puede tener esa marca por obra. Una corrección se revisa antes de sustituir la copia vigente.
No se exige una tabla general de versiones métricas ni el campo `obras.base_metrica_analitica_id`.

Asignar la obra o comenzar a editar no retira esa contribución mínima. El código del corpus lee
la copia fija; el registrador lee la estructura de trabajo. Los cambios de edición, fechas o
autoría del borrador tampoco se mezclan con la métrica de la importación anterior.

Al publicar la ficha completa, su análisis v2 sustituye el aporte mínimo para esa obra y se
actualizan los agregados. La importación puede conservarse como referencia histórica sin seguir
contando. No se depende de borrar esa documentación para evitar el doble cómputo. La publicación
y el recálculo deben coordinarse para no sumar ambas fuentes ni servir una mezcla parcial.

Esta conservación se limita al tránsito de mínima a completa; no introduce un historial general
de versiones del registrador v2. Ningún borrado ni cambio de estado se ejecuta en este paso de diseño.

## Qué está comprobado y qué falta implementar

La [consulta del 26 de octubre](../../scripts/importador-metrico/auditar-flujo-minimo.sql) y su
[evidencia](./piloto/auditoria-flujo-2026-10-26.json) confirman que fuente de datación, fuente de
autoría y editor asignado admiten valores vacíos en la DB. El importador sí exigirá género, aunque
la columna actual sea nullable. Para Comedia se utilizará el término existente del catálogo,
`comedia_o_tragicomedia`; no se añade otro género por este lote.

El estado propuesto no existe todavía. Las reglas actuales de publicación y el endpoint de estado
presuponen el circuito completo, por lo que habrá que añadir el recorrido mínimo de forma explícita.
El guardado mínimo utilizará el modelo de autoría existente sin exigir fundamentos textuales;
se conservarán sus vínculos y categorías, sin inventar argumentos ni revisar las obras existentes.

Esta revisión cambia documentación. No crea tablas, no cambia atribuciones existentes, no aplica
migraciones ni modifica el registrador, el dashboard o los cuadros.

# Campos mínimos y conexión con Versología

Propuesta revisada el 26 de octubre de 2026 con las indicaciones del responsable. **No aplicada
a la DB.** Este documento describe el funcionamiento esperado; el [diseño de integración](./diseno-integracion.md)
explica qué partes de la plataforma habrá que adaptar.
El [contrato local ejecutable](./contrato-local.md) ya permite comprobar estos campos y ensayar
la independencia de la copia fija; todavía no escribe en la DB ni confirma las obras del piloto.

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

## Tipo de ficha y confirmación de la importación

**Mínima es un tipo de ficha, no un estado nuevo del circuito editorial.** Se retira la propuesta
de añadir Mínima validada a Borrador, Vista previa y Publicado. En la pantalla se distingue
Ficha mínima de Ficha completa mediante el nuevo `obras.tipo_ficha`.

El recorrido del importador es **preparar → comprobar la vista previa → confirmar la importación**.
La persona autorizada que importa revisa la transcripción y confirma los datos; no se añade una
segunda aprobación por admin/IP ni una figura nueva de validador. El sistema verifica formato,
metadatos, rangos y referencias. Las ambigüedades métricas pueden seguir declaradas como tales.
Nada de esto satisface el checklist de una ficha completa.

| Situación | Uso |
| --- | --- |
| Importación en preparación | Resultado todavía no confirmado; fuera del corpus |
| Ficha mínima guardada | Importación confirmada; aporta a los análisis que su cobertura permita, sin publicación individual |
| Ficha completa en elaboración | Circuito editorial habitual; el corpus conserva el aporte mínimo confirmado |
| Ficha completa publicada | v2 sustituye el aporte mínimo; la importación queda como referencia histórica |

`tipo_ficha` tendrá los valores `minima` y `completa`; las obras existentes conservarían el recorrido
completo. La columna actual `obras.estado` se mantiene para las completas. Como actualmente es
obligatoria, una mínima puede conservar Borrador como valor técnico de compatibilidad, sin mostrarlo
como un paso pendiente de revisión ni usarlo para decidir su entrada al corpus. Las consultas y
listas deberán distinguir los tipos explícitamente. `visible_publico` permanece falso en mínimas.

## Quién accede y dónde se muestran

La sección **Importar** estará disponible para admin/IP y para editores a quienes admin/IP conceda
ese permiso específico. No es una capacidad de todos los editores. El permiso no cambia su rol
ni les abre el laboratorio. Técnicamente puede ser una capacidad individual, por ejemplo
`editores.puede_importar_metrica`, desactivada por defecto; el nombre se concretará al implementar.

En Obras se propone una pestaña **Fichas mínimas**, diferenciada de las fichas completas.
Admin/IP y los importadores autorizados podrán consultar **todas** las mínimas, propias y ajenas.
Cada fila mostrará título, autor, fechas, edición, quién importó y cuándo. Un filtro Mis importaciones
puede facilitar el trabajo, pero no limitará el permiso de consulta. La importación original seguirá
consultable como historial si la obra pasa al recorrido completo.

El nombre Fichas mínimas explica su profundidad; Importar es la acción que las crea. No se confunden
con las obras asignadas para análisis completo. Poder consultar las importaciones de otro usuario
no otorga por sí solo edición o borrado de su trabajo ni acceso a sus anotaciones completas.
El editor asignado a la completa podrá consultar la propuesta de origen aunque no tenga permiso
para crear nuevas importaciones.

Estos accesos se comprobarán en servidor y RLS, no solo ocultando botones. La matriz del laboratorio
permanece reservada a admin/IP; los resultados agregados autorizados para fichas completas mantienen
su salida separada.

## Qué se comparte y qué se guarda aparte

Se reutilizan las tablas **obras, jornadas y secuencias**. La métrica mínima tiene una tabla aparte
de las anotaciones v2, con una fila por secuencia mientras se trabaja en la mínima. Para preparar
la completa, el editor podrá conservar y corregir esa estructura o vaciarla para empezar de nuevo.
En ambos casos revisará la métrica; las identificaciones importadas no pasan a v2 como respuestas.

| Dato por secuencia mínima | Significado |
| --- | --- |
| Vínculo a la secuencia | Identifica la obra y su rango en la tabla común |
| Forma | Forma identificada en la importación; puede quedar vacía si no se resuelve |
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

## Qué se conserva de las decisiones y dónde

La vista previa muestra **denominación de la edición → forma en Versología**. No presenta estados
«propuesta» y «revisada» para cada equivalencia, ni pide a quien importa aprobar nuestro catálogo.
La revisión general de equivalencias pertenece al mantenimiento de las reglas. Quien importa
comprueba el resultado de su obra y confirma sus datos, incluidas las ambigüedades que permanezcan.

| Dónde | Qué se conserva |
| --- | --- |
| Archivo de equivalencias versionado | Denominaciones, correspondencia de forma y arquitectura si se conoce, o posibilidades si no hay una correspondencia única. Una explicación breve y referencia cuando hacen falta para entender la regla |
| `importaciones_metricas.entrada_original` | Transcripción recibida, denominaciones originales, referencias de fotos o páginas y notas de la edición. Conservar una referencia no equivale a subir la fotografía |
| `importaciones_metricas.datos_confirmados` | Copia fija de los metadatos, jornadas y secuencias que acepta quien importa, con la versión de las reglas y la referencia de catálogo utilizadas |
| Registro de la importación | Quién importó y cuándo, tomados de la sesión y del servidor. Una sola atribución para toda la operación; confirmar no supone otro revisor |
| Métrica mínima de cada secuencia y su copia fija | Forma y arquitectura opcional, referencia a la fila original, posibilidades si sigue sin resolver, remates y desviaciones declarados. Una nota breve solo si hay una decisión particular que explicar |

Por ejemplo, la interpretación general de «tercetos encadenados con serventesio final» como
Terceto encadenado con remate de un verso se explica una vez en la regla. La secuencia conserva
su denominación original y su remate; no copia la discusión ni una aprobación de esa regla.
Si una fila A → B → A se divide, las tres secuencias apuntan a la misma fila y se explica brevemente
esa división. El heptasílabo y el verso añadido de Los locos se conservan como desviaciones concretas.

No se incorporan al contrato definitivo estados de revisión de equivalencias por secuencia,
justificaciones generales repetidas, citas del chat, categorías de «exhaustividad» del ensayo
ni porcentajes de confianza inventados. Las posibilidades no se consideran exhaustivas: una lista
orienta, pero no permite repartir entre sus miembros los versos pendientes. La falta de forma,
arquitectura o segmentación segura sigue siendo información necesaria para limitar los análisis.

**Contrato 0.2:** el módulo ejecutable y el borrador SQL ya conservan una sola `identificacion`,
las candidatas y una `nota` opcional. Los remates y desviaciones no llevan estados de revisión.
Los estados y fundamentos del estudio siguen en sus archivos de investigación y reglas generales,
sin copiarse al resultado mínimo. La extracción original se conserva tal como se recibe.
El resumen de una vista previa describe el resultado que se ofrece para confirmar; no certifica
su aceptación ni lo incorpora al corpus. Los informes de investigación mantienen su cómputo de
revisión de reglas, distinto de la cobertura del resultado preparado.

## Cómo utiliza los datos el laboratorio

Cuando hablábamos de «contrato común», nos referíamos a **una misma manera de entregar los datos
a los cálculos**, no a heredar secuencias ni a convertir una mínima en anotación completa.

Mientras la obra solo tenga una mínima confirmada, el corpus usa esos datos aceptados. Durante la
elaboración de la completa mantiene una copia fija de esa importación, no las jornadas y secuencias
que el editor esté modificando. Al publicar la completa, pasa a usar v2 y deja de contar la mínima.
Con una sola definición se calcula el peso de cada forma, conservando qué versos siguen sin resolver.
La obra se cuenta una sola vez y cada medida declara su universo, procedencia y cobertura.
Al declarar cuántas fichas mínimas y completas sostienen un resultado, se cuenta la fuente usada:
una obra en elaboración todavía aporta como mínima mientras se use su importación confirmada.

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

Se conserva en la importación una **copia fija de los datos mínimos confirmados**:
edición, autoría usada, fechas, género, jornadas, rangos, identificaciones, candidatas y detalles.
Es necesaria porque las tablas comunes estarán cambiando, o sus filas pueden borrarse al reiniciar.
Conservar únicamente la tabla métrica enlazada a secuencias editables no protegería el referente.

Esta copia se guardaría como `importaciones_metricas.datos_confirmados` (JSONB). `importado_por`
y `importado_en` registran su confirmación: una sola persona y fecha, sin otra instancia de validación.
La referencia mínima vigente de cada obra se marca en `usada_en_corpus`: solo una importación
confirmada puede tener esa marca por obra. Una corrección se comprueba antes de sustituir la copia vigente.
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

### Prioridad de la detallada ante una nueva importación

Regla acordada el 29 de octubre: si una obra ya existe como detallada, no se le puede importar
una básica, cualquiera que sea su estado editorial o visibilidad. Se rechaza esa nueva importación;
no se sobrescribe la detallada, no se le adjunta otra base mínima y no se crea una segunda obra
por cambiar de edición. Resolver identidad va más allá de comparar el título literal; los casos
dudosos se detienen para revisión. La regla se comprobará en servidor y al guardar.

La coincidencia nominal no acredita esa identidad. Según la precisión posterior del responsable,
el importador debe avisar mostrando título, autoría y tipo de ficha y permitir confirmar que es
otra obra para crearla, o descartar si es la misma. El título sirve para localizar candidatas y
el autor para contextualizarlas; no se impone unicidad por título ni por título/autor. Confirmar
«otra obra» no modifica la existente ni elude la prioridad de su detallada: registra otra identidad.
El servidor revalida las coincidencias al guardar y conserva la decisión con la importación.

No cambia el tránsito ya acordado de básica a detallada: se conserva su copia confirmada previa
hasta publicar la detallada. Esa conservación no es permiso para importar otra básica durante
la elaboración. La primera entrega crea obras nuevas; reimportar o corregir una básica existente
requiere un recorrido posterior explícito.

La [consulta del 26 de octubre](../../scripts/importador-metrico/auditar-flujo-minimo.sql) y su
[evidencia](./piloto/auditoria-flujo-2026-10-26.json) confirman que fuente de datación, fuente de
autoría y editor asignado admiten valores vacíos en la DB. El importador sí exigirá género, aunque
la columna actual sea nullable. Para Comedia se utilizará el término existente del catálogo,
`comedia_o_tragicomedia`; no se añade otro género por este lote.

No se añadirá un término al vocabulario de estados por este recorrido. Las reglas actuales de
publicación, el endpoint de estado y las listas editoriales deberán distinguir el nuevo tipo mínimo
y sus permisos de acceso. Importar y confirmar no utilizará el cambio de estado como atajo.
El guardado mínimo utilizará el modelo de autoría existente sin exigir fundamentos textuales;
se conservarán sus vínculos y categorías, sin inventar argumentos ni revisar las obras existentes.

Esta revisión cambia documentación. No crea tablas, no cambia atribuciones existentes, no aplica
migraciones ni modifica el registrador, el dashboard o los cuadros.

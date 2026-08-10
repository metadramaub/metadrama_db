# Contexto para continuar el trabajo métrico

Actualizado: 10 de agosto de 2026

Este es el documento que debe leer primero un nuevo chat. Resume el estado operativo y
enlaza la documentación detallada; no sustituye las revisiones filológicas de cada forma.

> **La revisión del catálogo contra las fuentes está terminada** desde el 8 de agosto de 2026:
> las 27 formas y los dos tramos sin forma. Lo que dejó hecho, lo que corrigió y lo que dejó
> abierto vive en **[revision-del-catalogo-estado.md](./revision-del-catalogo-estado.md)**. Lo
> pendiente está inventariado en [qué queda pendiente](#qué-queda-pendiente): las seis lecturas
> transversales se cerraron el 10 de agosto.

## Estado actual

- Rama de trabajo: `develop`. `main` corresponde a la versión desplegada y debe
  permanecer estable hasta decidir la integración.
- `develop` y producción comparten Supabase. No se ha creado ni hace falta otro proyecto.
- El catálogo nuevo usa tablas aditivas y está separado del vocabulario métrico legado.
- La versión del modelo y la última migración **no se anotan aquí**: quedan viejas en cuanto se
  aplica una migración más. Se consultan en la base —`select modelo_version from
  catalogo_metrico_estado`— y en `supabase/migrations/`, ordenadas por nombre.
- La base habla ya el vocabulario de la ontología: arquitectura, esquema métrico, esquema
  de rima, variedad, tramo sin forma. La arquitectura declara
  además la extensión de su unidad —`unidad_versos_min` y `unidad_versos_max`—, y ninguna
  sección existe ya para decir que la unidad se repite: cuántas unidades contiene el pasaje
  se deriva del rango. La unidad es la realización que no cuelga de ninguna otra y no
  realiza ninguna sección; las secciones describen su interior. No existen familias, la
  pertenencia a una tradición no se tipifica y las denominaciones pueden nombrar una
  variedad y declararse posteriores. Arquitecturas y esquemas siguen una misma convención de
  nombre y slug, registrada en
   [la revisión de nomenclatura](./historico/revision-nomenclatura.md). El catálogo tiene **27 formas y
  2 tramos sin forma**: la medida de toda forma isosilábica es arquitectura y ya no se
  pregunta, y lo que era una forma para decir «N unidades de esta otra» —doble sextilla,
  sexta rima, tercetos sin encadenar, pareados endecasílabos, copla manriqueña— vive en el
  nivel que le corresponde. Las formas con clasificación previa tienen ya su tradición; las
  restantes no la tienen porque no hay de dónde tomarla.
- `/dashboard/metrica` es el gestor permanente del catálogo y contiene también el editor
  V2 de prueba y la compilación del demarcador. **Las respuestas del editor ya no se editan
  ahí**: se derivan del catálogo y el gestor solo las muestra. Está anotado simplificar el resto
  del gestor en la misma dirección.
- **La respuesta guardada no depende del catálogo que la ofreció.** `elecciones_editor_metrico`
  apunta al dato elegido —el esquema, el metro, el valor de rasgo, la repetición, la variedad—,
  no a una opción, y el catálogo se niega a borrar algo que una anotación use. Para leerla con
  la opción que hoy la ofrece está `elecciones_editor_metrico_resueltas`.
- **El catálogo de formas se publica en `/formas`** desde el 4 de agosto de 2026, generado
  del dato: cada forma con sus arquitecturas, esquemas, secciones, rasgos, denominaciones y
  lo que dicen las fuentes. Nace en `admin_ip` y se abre desde `/dashboard/publicacion`
  cambiando el `scope_minimo` de la sección `formas`. No lleva texto redactado: si algo se
  lee mal, está mal en el catálogo. El listado carga los 29 registros activos en una sola
  consulta y los conserva para el filtrado en ejecución; cada ficha usa otra consulta agregada
  que mantiene los identificadores y la jerarquía padre-hijo de sus secciones.
- El editor V2 escribe únicamente en tablas `*_editor_metrico`. No crea obras, no modifica
  las secuencias reales y no alimenta fichas, buscadores ni resúmenes públicos.
- **La anotación en sombra funciona** desde el 4 de agosto de 2026, en la pestaña
  «Anotación en sombra» de `/dashboard/metrica`. Una prueba puede señalar una secuencia real
  con `secuencias_editor_metrico.secuencia_id`, sin que la secuencia cambie nada:
  `obras_editor_metrico_v2` dice qué obras están abiertas, la vista
  `propuesta_metrica_secuencia` traduce cada `estrofa_tipo_id` a su forma y arquitectura
  —94,9 % de cobertura medida— y el formulario llega propuesto desde ahí, de modo que el
  editor revisa en vez de reanotar. El recuento de acuerdo entre modelos está en la misma
  pestaña; para ver una obra en los dos modelos se abre el editor de siempre en otra
  pestaña, no hay pantalla doble. Es la fase 0 de
  [el plan de migración](./plan-migracion-anotaciones.md).
  **Nada de esto se ha visto todavía en pantalla con datos reales.**
- Las declaraciones métricas existentes en las obras siguen usando el vocabulario legado.
  Su migración se hará más adelante, cuando el IP haya validado el catálogo y el
  demarcador. Hay editores trabajando y esta frontera no debe adelantarse.

## Decisiones que gobiernan el modelo

Son dieciocho y viven en [el modelo aplicado](./implementacion-metrica.md#las-decisiones-que-gobiernan-el-modelo),
en un solo sitio desde el 10 de agosto de 2026. **Léelas antes de tocar el catálogo**: la mitad
de los errores de estos días venían de no saber que una de ellas existía.

## Cómo se registra una secuencia

```text
forma
+ arquitectura
+ elecciones entre alternativas admitidas
+ realizaciones de la unidad y de sus secciones, cuando proceda
+ desviaciones localizadas
```

Cuántas unidades contiene la secuencia no se declara: se deriva del rango y de la extensión
que la arquitectura declara para su unidad.

Si no existe una forma reconocible:

```text
tramo sin forma
+ rango
+ observación opcional
```

Los detalles de cada forma ya revisada están resumidos en
[Contratos del registrador](./contratos-registrador-formas-revisadas.md). El editor debe
adaptarse a esos contratos y no contener reglas filológicas escritas únicamente en el
componente: las preguntas y posibilidades deben proceder del catálogo.

## Demarcador

- El contrato vigente, la matemática de compatibilidad y el criterio de parada están en
  [Demarcador métrico](./demarcador-metrico.md).
- Se compila desde el catálogo nuevo, no desde el JSON legado.
- Las preguntas se ordenan por su capacidad de separar las candidatas restantes.
- Solo pregunta rasgos observables y razonables para el editor.
- `No sé` conserva candidatas; no afirma ni niega.
- Los tramos sin forma no compiten en el recorrido ordinario y aparecen únicamente
  cuando no queda una identificación más precisa.
- Si cambia el catálogo, la interfaz marca la prueba compilada como desactualizada y debe
  regenerarse.

## Trazabilidad y migración futura

El plan completo, con sus condiciones previas, fases y criterios de aceptación, está en
[plan-migracion-anotaciones.md](./plan-migracion-anotaciones.md). No se ejecutará hasta
que la ontología esté revisada, el editor V2 funcione como se espera y el demarcador
resulte útil.

## Documentos que debe consultar un nuevo chat

Leer solo lo necesario para la tarea:

1. [Ontología del verso español](./ontologia-verso-espanol.md): qué es el verso español y
   de qué está hecho. Describe posibilidades, no este corpus. Lectura previa a todo lo demás.
1bis. [El modelo métrico aplicado](./implementacion-metrica.md): qué parte se realiza, qué se
   restringe por el corpus, cómo se recoge el dato y **las dieciocho decisiones que lo gobiernan**.
1ter. [README del dominio](./README.md): índice de los diecinueve documentos.
2. [Criterios de nivel](./criterios-de-nivel.md): en qué nivel se registra cada hecho
   métrico. De lectura obligada antes de formalizar o corregir una forma.
3. [Editor V2](./editor-secuencias-v2.md): aislamiento, persistencia y comportamiento.
4. [Contratos del registrador](./contratos-registrador-formas-revisadas.md): comportamiento
   mínimo de las formas revisadas.
5. [Cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md): única lista
   vigente de dudas filológicas.
5bis. [Equivalencias pendientes](./equivalencias-pendientes.md): **por qué** algunos términos
   legados no declaran todavía su destino y qué decidió el IP sobre cada uno. Es lo que hay que
   cerrar antes del backfill. **El estado —cuántos faltan, cuáles y cuánto se usan— no se
   escribe: lo genera `npm run equivalencias:informe`** en
   [informe-equivalencias.md](./informe-equivalencias.md).
5bis-1. [Estado de la revisión del catálogo](./revision-del-catalogo-estado.md): la revisión
   filológica, **ya terminada**, y las lecturas transversales que dejó abiertas. Se mantiene al
   día: es el único sitio donde se lleva esa cuenta.
5bis-2. [Dónde vive la prosa del catálogo](./donde-vive-la-prosa.md): los ocho criterios de
   redacción que rigen todo lo que se escribe en el catálogo, y dónde va cada cosa —definición,
   descripción, nota—.
5ter. [Cómo se migra una obra](./como-se-migra-una-obra.md): el procedimiento, escrito para
   poder explicárselo a quien anotó cada obra. Los informes por obra se generan con
   `npm run migracion:informe` y viven en [migracion/](./migracion/).
6. La revisión específica de una forma, solo si la nueva tarea afecta a esa forma.

[El vocabulario heredado](./historico/vocabulario-heredado.md) conserva los 119 términos
anteriores con sus definiciones, rasgos, subtipos y destino actual. Es la referencia para
comprobar si se perdió información al migrar o si algo quedó en un nivel que no le toca. La
matriz de importación que lo revisaba en el panel se retiró: desde la importación las
decisiones han cambiado tanto que sus pendientes ya no describían nada actual.

La [matriz de reclasificación](./historico/matriz-reclasificacion-formas-metricas.md) y el
[informe de auditoría](./historico/informe-auditoria-vocabulario-metrico.md) explican la
procedencia, pero no deben releerse para una tarea ordinaria.

## Revisión del catálogo

El criterio de nivel está escrito en [criterios-de-nivel.md](./criterios-de-nivel.md) y
su cumplimiento se comprueba con `npm run audit:metrica`, que vuelca la base enlazada y
contrasta los datos poblados. El resultado vigente está en
[informe-conformidad-catalogo.md](./informe-conformidad-catalogo.md). El informe separa
los incumplimientos objetivos de las matrices que describen dónde vive cada dimensión;
estas últimas son el material de las decisiones pendientes del IP, no errores.

## Qué queda pendiente

Inventario hecho el 10 de agosto de 2026, al cerrar las seis lecturas transversales. Incluye lo
registrado y lo que fue apareciendo por el camino. **El orden lo fija el IP: primero terminar el
modelo, y las superficies —editor, gestor, demarcador— al final**, porque se derivan de él y
hacerlas antes obliga a hacerlas dos veces.

### Modelo

1. ~~**Un rasgo puede estar midiendo dos magnitudes.**~~ **Hecho el 10 de agosto de 2026.** Se
   separó en `densidad_de_rima` —cuántos versos riman— y `organizacion_en_pareados` —qué figura
   dibujan los que riman—. La silva y el endecasílabo suelto quedan en rangos disjuntos, que es
   el umbral del 50 % de Morley y Bruerton, y una guarda impide que se solapen. Contado en
   [el estado de la revisión](./revision-del-catalogo-estado.md#defectos-del-modelo-aplazados).
2. ~~**`definitoria` no pertenece a la escala de la modalidad.**~~ **Cerrado el 10 de agosto.** No
   eran dos ejes: la escala es de frecuencia y `definitoria` es su tope —lo que se da siempre—,
   porque la norma métrica es resultado de la práctica y no al revés. De ahí salió un invariante
   que ahora sostiene una guarda: **ninguna pregunta ofrece una definitoria junto a otra
   modalidad**. Falló en un sitio, la endecha real, y se corrigió con las fuentes en la mano. El
   razonamiento entero, en
   [la revisión de vocabularios](../revision-de-vocabularios.md#un-cabo-que-result%C3%B3-no-serlo).
3. ~~**Una restricción solo puede colgar de un esquema, no de una arquitectura.**~~ **Cerrado el
   10 de agosto, y en contra de lo que decía este punto.** Con las once delante, **dos serían
   falsas a nivel de arquitectura** —la exclusión de la sextilla se excluiría a sí misma, y el
   «todos los versos sueltos» de la canción alcanzaría al pareado final, que rima— y ocho viven en
   arquitecturas de un solo esquema, donde los dos niveles son indistinguibles. Lo que faltaba no
   era una columna sino **una comprobación**: los concretos de una arquitectura cumplen el criterio
   de su abierto, y ahora lo verifica `D13` de `npm run audit:metrica`. Las tres relaciones
   posibles entre un abierto y sus hermanos, en
   [el modelo aplicado](./implementacion-metrica.md#un-esquema-abierto-junto-a-otros-concretos).
4. **La `suelta` de la endecha real es un ciclo con notación y cero posiciones.** `[----]…` dice
   cuatro versos sueltos y nadie los expandió. O se expanden o se admite que la notación baste
   —pero entonces deja de ser cierto que un esquema con posiciones sea lo cerrado—. *Espera además
   una decisión del IP que puede retirarlo: Navarro Tomás y el Diccionario llaman endecha real a la
   que no rima, y Jauralde dice que el nombre llegó cuando recibió rimas. Ver
   [Endecha real](./revisiones-formas/cuestiones-para-el-ip.md#endecha-real) 4.*
5. ~~**`tipo` y `ambito` de las repeticiones están perfectamente correlacionados.**~~ **Cerrado el
   10 de agosto, y el hueco era mayor.** Al mirarlo salió que `ambito` no era una columna de las
   repeticiones sino **el antepasado grueso de `seccion_id`**: nació con cinco valores, se estrechó
   a dos y quedó respondiendo «¿de una sección?» donde `seccion_id` responde «¿de cuál?». Donde
   convivían se contradecían, y la ficha pública tenía que **adivinar** la parte. Se dio su sección
   a los seis esquemas del villancico y a los cuatro métricos —`esquemas_metricos` ganó la columna—,
   y `ambito` se retiró de las tres tablas: ahora se deriva.
6. ~~**Seis columnas no distinguen nada.**~~ **Rehecho el inventario en vivo el 10 de agosto: no
   eran seis del mismo problema, sino tres grupos.** Se retiraron las cuatro que duplicaban una
   distinción ya codificada —`seleccionable` decía lo que dice `tipo_registro`, y `obligatorio`,
   `obligatoria` y `tipo_enlace` decían lo que dice `modalidad`—. **`activo`, en las ocho tablas,
   se queda**: no es una columna vacía sino un mecanismo de retirada sin estrenar, lo leen 17
   objetos SQL, y el IP decidió resolverlo al fusionar con `main`. Anotado en
   [la revisión de vocabularios](../revision-de-vocabularios.md#lo-que-se-hace-ahora-y-lo-que-espera).
7. ~~**El aviso `patron_rima_sin_regla` se ha vuelto ruido.**~~ **Afinado el 10 de agosto.** Dejar
   la disposición abierta no es un defecto —es lo que hace una forma general—; lo es que la
   arquitectura no diga nada más de su rima, y tiene tres maneras de decirlo: las restricciones del
   esquema, la densidad declarada o unos esquemas concretos de los que se calcula. El aviso miraba
   solo la primera. Los ocho dejan de saltar, y al callar el ruido **queda a la vista el único
   acierto que tenía**: la `suelta` de la endecha real, un ciclo sin posiciones —punto 4—.
8. **La sección de seis versos del soneto**, en
   [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md#soneto).
9. **Las 27 equivalencias del vocabulario legado sin destino**, en
   [equivalencias-pendientes.md](./equivalencias-pendientes.md).

### Superficies, después del modelo

10. **El maquetado del editor V2.** Aprobado el diseño —estructura pintada a la izquierda,
    elecciones alineadas a la derecha, sin clics para navegar— y aplazado a propósito: el
    formulario se deriva del catálogo, así que cada cambio del modelo lo cambia gratis. El
    interruptor es «la arquitectura declara secciones», que es dato y no una lista de formas.
11. **Simplificar el gestor del catálogo** para que solo edite prosa y lo estructural pase por
    migración. Es lo que acabaría con los vocabularios y campos fantasma: en una semana
    aparecieron cuatro, y `npm run audit:campos` solo cubre los nombres de campo, no sus valores.
12. **Recompilar el demarcador** sobre la ontología en vez de su vector fijo de rasgos.
13. **Repaso visual del catálogo público**: el nombre de la copla manriqueña se pierde entre su
    notación, y un esquema sin nombre ni denominación muestra un guion de relleno.

## Siguiente fase prevista

La ontología quedó revisada desde la base el 30 de julio de 2026 y la migración estructural
se completó el 31. Lo que sigue:

1. Migración estructural y de datos: **completas**. Sus cuatro bloques y la unidad
   envolvente están aplicados; el registro de qué se cambió y por qué está en
   [histórico](./historico/).
2. Vocabulario unificado: **completo**. Una escala de modalidad, un tipo de secuencia, el
   ámbito reducido a unidad y sección.
3. Contraste del catálogo por rasgos y no por nombres: **hecho**, y actuado. Lo que salió de
   ahí está aplicado; el razonamiento, en la
   [auditoría archivada](./historico/auditoria-catalogo.md).
4. **Revisión del catálogo contra las fuentes: completa.** Las 27 formas activas y los dos
   tramos sin forma están contrastados con las seis monografías, y las fichas `.md` de
   `revisiones-formas/` se han retirado todas. El resultado y lo que dejó abierto están en
   [revision-del-catalogo-estado.md](./revision-del-catalogo-estado.md). Destapó por el camino
   defectos del modelo: los corregidos están aplicados y los aplazados eran **lecturas
   transversales** sobre el catálogo entero.
5. **Las seis lecturas transversales: completas** el 10 de agosto de 2026. El concepto de
   variedad, la automatización de las preguntas del editor, la reutilización de secciones, la
   modalidad y la primacía, las reglas de repetición y el modelo de esquemas abiertos. Lo que
   dejaron abierto está arriba, en [qué queda pendiente](#qué-queda-pendiente).
6. Crear la capa de desviaciones sobre las secuencias reales.
7. Recompilar el demarcador para que consuma la ontología en lugar de su vector fijo de
   rasgos.
8. Solo entonces, la [migración de las anotaciones](./plan-migracion-anotaciones.md).

**Sobre los defectos del informe de conformidad**: el
[informe](./informe-conformidad-catalogo.md) no señala ninguno de los tipificados como D1–D12
salvo cuatro incidencias de D5 que son **falsos positivos conocidos** —las opciones de tercetos
del soneto, cuya notación lleva un espacio (`CDE DCE`) que la regla cuenta como posición—. Al
revisar una forma conviene regenerarlo: introducir un defecto nuevo es fácil.

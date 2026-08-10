# Contexto para continuar el trabajo métrico

Actualizado: 9 de agosto de 2026

Este es el documento que debe leer primero un nuevo chat. Resume el estado operativo y
enlaza la documentación detallada; no sustituye las revisiones filológicas de cada forma.

> **La revisión del catálogo contra las fuentes está terminada** desde el 8 de agosto de 2026:
> las 27 formas y los dos tramos sin forma. Lo que dejó hecho, lo que corrigió y lo que dejó
> abierto vive en **[revision-del-catalogo-estado.md](./revision-del-catalogo-estado.md)**. Lo
> pendiente ya no es forma por forma, sino lecturas transversales sobre el catálogo entero.

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

1. La base de datos es la fuente de verdad. El artefacto del demarcador, las fichas y las
   redes son proyecciones regenerables.
2. Forma, arquitectura, esquema, variedad, sección, repetición, rasgo, elección,
   denominación, tradición y relación son conceptos distintos. La antigua jerarquía
   padre/hijo no se reproduce automáticamente y no existe el concepto de familia.
3. El criterio especializado incorporado por el IP para el corpus se conserva. La
   bibliografía académica documenta contrastes, pero no lo sustituye silenciosamente.
4. Las fuentes declaradas deben ser publicaciones bibliográficas autorizadas; una página
   web o un vídeo no constituyen por sí solos una fuente del catálogo.
5. El nivel de cada hecho se decide preguntando si puede variar dentro de una misma
   secuencia. Una arquitectura prototípica es opcional.
6. El editor debe responder lo mínimo. Los resultados únicos se derivan; solo se muestran
   alternativas con valor analítico y desviaciones reales.
7. Rige una convención de mundo cerrado: una secuencia guardada sin desviaciones cumple
   la norma y las elecciones realizadas. No se piden certeza, revisión ni pendiente.
8. Las alternativas admitidas no son desviaciones. Las desviaciones reutilizan metros,
   rimas, estructuras, repeticiones y rasgos normalizados.
9. Las formas reconocibles conservan su identidad aunque tengan excepciones localizadas.
   `Versificación irregular` y `Verso aislado` son tramos sin forma, sin arquitectura,
   no formas comparables.
10. Una forma general no ha llegado a especializarse, pero es forma plena. La copla de pie
    quebrado y el sexteto son generales; eso no las equipara a los dos tramos sin
    forma.
11. Las restricciones de longitud obligan a revisar rangos incompatibles: múltiplos de la
    unidad fija, ciclos repetibles, composiciones cerradas y estructuras calculadas.
12. **El catálogo no guarda lo que puede calcular.** El formulario del editor no se escribe: las
    respuestas salen de `opciones_eleccion_metrica`, que es una vista, y el enunciado de
    `grupos_eleccion_metrica_resueltos`, que lo compone con la dimensión y la sección. Lo que se
    quede sin poder derivarse no es una excepción que justifique escribirlo a mano: es una
    carencia del catálogo, y la solución es declararla.
13. **Una función SQL no está probada hasta que se ejecuta.** Un cuerpo entrecomillado no se
    revalida al borrar una columna y PL/pgSQL resuelve los campos de un `record` en ejecución, de
    modo que `db push`, `check` y las pruebas pasan sobre código roto. Ha mordido tres veces en
    dos días, una de ellas dejando el demarcador cinco días sin funcionar. Las guardas de las
    migraciones **ejecutan** lo que tocan.

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
1bis. [La implementación de METADRAMA](./implementacion-metrica.md): qué parte se realiza,
   qué se restringe por el corpus y cómo se recoge el dato.
1ter. [README del dominio](./README.md): índice y decisiones consolidadas.
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

1. **Un rasgo puede estar midiendo dos magnitudes.** `organizacion_en_pareados` gradúa *ninguna ·
   ocasionales · habituales · predominantes · regulares* y `versos_sueltos` *ninguno · admitidos ·
   predominantes · todos*. Las dos dicen «cuánto» sin decir «cuánto de qué», y en la silva libre
   `ninguna` significa «ningún pareado» aunque sí haya rima. Es el problema que más veces ha
   estorbado —silva, endecasílabo suelto y esquemas abiertos— y el IP pidió verlo caso por caso.
2. **`definitoria` no pertenece a la escala de la modalidad.** `habitual · admitida · excepcional`
   gradúan frecuencia y `definitoria` afirma necesidad; no siempre son excluyentes. Afecta a cinco
   tablas y está anotado en [la revisión de vocabularios](../revision-de-vocabularios.md), que es
   donde debe resolverse junto a los otros 60 enums.
3. **Una restricción solo puede colgar de un esquema, no de una arquitectura.** Las de la silva y
   las de la quintilla son norma de su arquitectura; hoy se apoyan en su esquema abierto, que
   funciona pero no es lo que son. Se descartó abrir la columna por un caso.
4. **La `suelta` de la endecha real es un ciclo con notación y cero posiciones.** `[----]…` dice
   cuatro versos sueltos y nadie los expandió. O se expanden o se admite que la notación baste
   —pero entonces deja de ser cierto que un esquema con posiciones sea lo cerrado—.
5. **`tipo` y `ambito` de las repeticiones están perfectamente correlacionados**: `estribillo` con
   sección y `palabra_final` con unidad, sin excepción en las once filas. Con dos clases puede ser
   casualidad; conviene mirarlo cuando haya una tercera.
6. **Seis columnas no distinguen nada.** `activo` es `true` en las ocho tablas donde existe,
   `seleccionable` en las 29 formas, `esquema_rima_enlaces.obligatorio` en sus trece filas,
   `tipo_enlace` vale siempre `misma_rima` y `esquema_rima_restricciones.obligatoria` siempre
   `true`. Algunas son borrado suave y defendibles; otras declaran una distinción que no se ha
   hecho nunca, como `grado_especificacion`, que se retiró por eso.
7. **El aviso `patron_rima_sin_regla` se ha vuelto ruido.** Salta en los ocho esquemas abiertos sin
   restricciones, y la revisión del 10 de agosto comprobó que **los ocho están bien**: la norma no
   fija más que el tipo de rima. O se afina o se baja a informativo.
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

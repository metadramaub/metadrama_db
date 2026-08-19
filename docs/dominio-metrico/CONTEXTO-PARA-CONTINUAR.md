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
- `/dashboard/metrica` es la superficie de trabajo del dominio: contiene la guía, el Editor V2 de
  prueba, la anotación en sombra y la validación del demarcador. El gestor mutable se retiró el 11
  de agosto: el catálogo se consulta en `/formas` y todos sus cambios se hacen por migración.
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

## El editor V2 ya tiene su pantalla nueva

**Hecho el 11 de agosto de 2026.** Los seis interruptores de plegado que hacían que la misma
pregunta pudiera aparecer en tres sitios se han retirado, y la estructura es ahora una **rejilla**:
la secuencia dibujada verso a verso a la izquierda, lo que hay que responder de cada parte a la
derecha, y nada oculto. Arriba, una línea por cada pregunta que apunte a dos o más realizaciones
para responderlas de una vez, que es un atajo y no un segundo domicilio. El atajo admite también
series posicionales —los dos metros del pareado— y las filas que coinciden recogen el control en
un resumen; «Cambiar» abre únicamente la excepción. En estructuras cíclicas, una pregunta que
materializa una sección se coloca donde aparece esa sección aunque siga guardándose en el
contenedor: la repetición del estribillo queda después de la copla, no en la cabecera del ciclo.
Las composiciones variables con ciclos —villancico, zéjel, canción— no muestran esa zona común:
se contestan por partes, cada ciclo abre un bloque visual y la única unidad raíz crece añadiendo
ciclos, no sumando composiciones.

- Cómo se genera hoy: `src/lib/components/metrica/editor-v2/grid-rows.ts` decide las filas y
  `MetricStructureEditor.svelte` las presenta. La [especificación que sirvió para construir la
  primera versión](./historico/editor-secuencias-v2-2026-08-11.md) queda archivada y no es una
  descripción vigente.
- Por qué: [propuesta-editor-v2.md](./propuesta-editor-v2.md), con el diagnóstico medido y lo que
  cambió respecto de lo que se propuso.

**No toca el modelo ni lo que se guarda**: cada realización conserva su propia respuesta, y
`npm run audit:editor` da la misma salida que antes. Qué filas se pintan vive en
`grid-rows.ts`, aparte del componente, y las cuatro formas de referencia —quintilla, villancico,
soneto y romance— están cubiertas en `grid-rows.test.ts`. **Falta que el IP la pruebe en pantalla
con datos reales.**

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
3. Editor V2: el comportamiento vigente está en `src/lib/components/metrica/editor-v2/` y en
   sus pruebas; la persistencia, en [el modelo aplicado](./implementacion-metrica.md). La
   [especificación inicial](./historico/editor-secuencias-v2-2026-08-11.md) es histórica.
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

**Un volcado no trae vistas, y hay una que el informe necesita.** `opciones_eleccion_metrica` es
una vista derivada desde el 11 de agosto de 2026, así que durante un día el informe leyó cero
opciones y firmó «0 defectos» sin haber mirado las reglas que dependen de ellas. Ahora esa
relación se pide por consulta y el informe **se planta** si el modelo se queda sin opciones. Si
otra tabla del catálogo se convierte en vista, hay que hacer lo mismo: `--dump` sobre una copia
local no puede verla.

### La revisión de la prosa va forma por forma

Distinta de la revisión filológica y posterior a ella. Se audita una forma entera contra la base
—definición, arquitecturas, esquemas, notas, denominaciones, relaciones y afirmaciones—, se
contrasta con la ficha real de `/formas`, y se aplica **una sola migración por forma** para poder
comprobar esa ficha antes de pasar a la siguiente. La norma de redacción es
[dónde vive la prosa](./donde-vive-la-prosa.md).

Se intentó primero como barrido global —hubo un informe de «segunda poda» con su generador— y no
funcionó: un inventario de frases sueltas no deja ver la forma entera, y sus recuentos envejecían
en cuanto se tocaba algo. Los tres documentos se retiraron el 18 de agosto de 2026; sus decisiones
ya aplicadas están en las migraciones y en el historial de `git`.

Llevan la prosa revisada, con su migración:

| Forma | Migración |
| --- | --- |
| Villancico | `20260814090000_el_villancico_explica_sin_repetir_sus_partes` |
| Zéjel | `20260814100000_el_zejel_deja_hablar_a_su_figura` |
| Seguidilla | `20260815090000_la_seguidilla_dice_lo_que_su_figura_no_dibuja` (+ `20260815091000`) |
| Romance | `20260818090000_el_romance_deja_de_repetir_su_rejilla` |
| Canción petrarquista | `20260818100000_la_cancion_ensena_por_dentro_la_estancia` |
| Sextilla | `20260818130000_la_sextilla_declara_lo_que_su_norma_acota` (+ `20260818140000`) |
| Quintilla | `20260819090000_la_quintilla_se_define_por_lo_que_evita` (+ `20260819100000`) |
| Silva | `20260819110000_la_silva_dice_donde_acaba_y_que_la_separa_del_pareado` (+ `20260819120000`, `20260819130000`) |
| Soneto | `20260819140000_el_soneto_dice_la_regla_de_sus_tercetos` |
| Décima | `20260819150000_la_decima_explica_sus_nombres_y_su_pausa` |
| Redondilla | `20260819160000_la_redondilla_dice_por_que_su_doble_es_una` |
| Cuarteto | `20260819170000_el_cuarteto_dice_de_donde_le_vienen_sus_nombres` |
| Terceto y terceto encadenado | `20260819180000_el_serventesio_final_no_es_obligatorio` |
| Sextina (composición y estrofa) | `20260819190000_la_sextina_dice_que_lo_que_vuelve_es_la_palabra` |
| Lira y sexteto-lira | `20260819200000_la_lira_dice_de_donde_viene_su_nombre` (+ `20260819210000`) |

**Definiciones y descripciones no se podan: se mejoran, y a menudo alargándolas.** Pueden repetir
en prosa lo que la figura dibuja, porque su función es que una forma se lea de corrido; las de la
seguidilla son el modelo. La regla de no escribir lo derivado se aplica con severidad a las
**notas** —de posición, de sección, de rasgo, y las descripciones de esquema—, no a ellas. Y su
prosa no usa lenguaje de base de datos ni da por supuesto el Siglo de Oro: el catálogo aspira a
ser más general que el corpus.

**Tras cada migración, `npm run audit:metrica` debe dar 0 defectos** —necesita Docker levantado,
porque vuelca la base—. Y conviene mirar la ficha servida, no solo el dato: en esta fase, leerlas
una a una ha descubierto defectos de presentación que no se veían ni en el catálogo ni en el
código.

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
   —pero entonces deja de ser cierto que un esquema con posiciones sea lo cerrado—. _Espera además
   una decisión del IP que puede retirarlo: Navarro Tomás y el Diccionario llaman endecha real a la
   que no rima, y Jauralde dice que el nombre llegó cuando recibió rimas. Ver
   [Endecha real](./revisiones-formas/cuestiones-para-el-ip.md#endecha-real) 4._
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
7. ~~**El aviso `patron_rima_sin_regla` se ha vuelto ruido.**~~ **Afinado el 10 de agosto** en el
   auditor, y **llevado a la ficha el 18 de agosto de 2026**, que era donde seguía vivo el criterio
   viejo: pintaba en rojo cualquier esquema abierto sin restricciones, sin mirar si la arquitectura
   lo decía por otra vía. Al llevarlo apareció una cuarta manera que el apunte no recogía —**el
   régimen `sin_rima`**, con el que no hay disposición que fijar—, y salió porque la sextina era la
   única ficha que quedaba en rojo. Ahora el aviso es de la arquitectura, no del esquema, y un
   esquema abierto sin restricciones dice «La disposición no está fijada», que informa en vez de
   acusar. Dejar
   la disposición abierta no es un defecto —es lo que hace una forma general—; lo es que la
   arquitectura no diga nada más de su rima, y tiene tres maneras de decirlo: las restricciones del
   esquema, la densidad declarada o unos esquemas concretos de los que se calcula. El aviso miraba
   solo la primera. Los ocho dejan de saltar, y al callar el ruido **queda a la vista el único
   acierto que tenía**: la `suelta` de la endecha real, un ciclo sin posiciones —punto 4—.
8bis. **Cinco formas piden medidas que el catálogo no tiene**, una pide además un régimen y otra
   trae nombre propio: romance (penta y tetrasílabos), sextilla (tetra y pentasílabas), quintilla
   (hexa y heptasílabas), décima (tetra, hexa y endecasílabas, **y asonante**) y terceto (**arte
   menor, que la tradición llama tercetillo, tercerilla o tercerillo**). Salió una por una al
   revisar su prosa y ya son cuatro seguidas: *conviene decidirlo de una vez.* Cada caso está
   detallado en la sección de su forma en
   [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md).

8quinquies. **Los ejemplos de verso no se han traído, y no hay dónde ponerlos.** El vocabulario
   legado guarda un ejemplo real en `vocabularios.ejemplo`, y de los 119 términos de
   `estrofa_tipo` **solo seis lo tienen**: copla de arte mayor, copla manriqueña, endecasílabo
   suelto encadenado, novena, sextina y villancico. El de la sextina trae la permutación anotada
   verso a verso —`(A) Al bello resplandor…`—, que es justo lo que ninguna figura puede dibujar.
   **El catálogo nuevo no tiene ninguna columna ni tabla para ejemplos**: `ejemplo` existe solo en
   `vocabularios`.

   *Lo previsto por el IP es un botón de ejemplos en cada ficha, con ejemplos para todas las
   formas y arquitecturas, no solo para esas seis.* Es decir: hay que **modelarlo** —dónde cuelga
   un ejemplo, si de la forma, de la arquitectura o del esquema; cómo se guarda la anotación de
   clases, que la sextina necesita— y luego poblarlo. Migrar los seis legados es lo de menos.

8sexies. **La permutación de la sextina no se puede dibujar y hoy solo se lee.** La rejilla pinta
   una estrofa y la colapsa con «×6», así que enseña `A B C D E F` en orden y no puede mostrar ni
   que la estrofa siguiente las trae en otro orden ni que el remate las reúne dos por verso. Se
   palió el 19 de agosto de 2026 sacando la descripción de la repetición de detrás de su icono,
   que es donde vive esa explicación. *Dibujarlo de verdad —las seis estrofas con su permutación—
   es una función aparte, y va con el punto anterior: el ejemplo anotado la enseña mejor que
   cualquier figura.*

8quater. **El cierre del terceto encadenado dejó de ser obligatorio y hay que revisar dos
   superficies.** Sus dos arquitecturas declaraban la sección de cierre con `repeticiones_min = 1`,
   de modo que el catálogo exigía un serventesio —o una redondilla cruzada— al final de toda
   cadena, y no lo es: la serie puede terminar sin él. Corregido el 19 de agosto de 2026
   (`20260819180000`). **Quedan por revisar el demarcador y el Editor V2**, que daban el cierre
   por hecho. *No se tocaron a la vez para no salirse de la revisión del catálogo.*

8ter. **El editor no sabe anotar una décima aumentada entre décimas normales.** El catálogo
   sostiene que no es un error —lo dicen su descripción y Morley y Bruerton—, pero
   `secuencias_editor_metrico` lleva una sola arquitectura por secuencia, así que solo cabe
   partir el pasaje o registrarla como desviación `estructura` / `mayor_que_norma`, que es
   anotarla como el error que no es. **⇒ Editor V2.**

8. **Dos cosas del soneto**, en
   [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md#soneto): si sus cuartetos
   podrían heredar la disposición del cuarteto y declarar la identidad con un enlace, y **la
   restricción `max_consecutivos: 2` de sus tercetos**, que la fuente enuncia y el catálogo no
   declara. Lo segundo cuesta dos piezas contadas allí: un esquema abierto de la sección
   `terceto` y **la evaluación de ese tipo en el auditor**, que hoy no existe —`incumple` devuelve
   `false` para `max_consecutivos`—. Es la misma pieza que echó en falta la sextilla, así que
   arreglarla sirve a las dos.
9. **Las 27 equivalencias del vocabulario legado sin destino**, en
   [equivalencias-pendientes.md](./equivalencias-pendientes.md).
10. ~~**El editor V2 aún no pregunta por realización.**~~ **Resuelto el 11 de agosto.** `alcance`
    admite una respuesta por cada aparición de su sección y el editor construye esas filas. En el
    villancico con estribillo posterior, la primera aparición declara el estribillo y la pregunta de
    repetición empieza en el ciclo siguiente; el criterio se deriva de la relación entre la sección
    materializada y la sección de la que toma su extensión.
11. **¿Son una sola arquitectura las dos del villancico?** Tras quitar la duplicación del ciclo, lo
    único que las separa es dónde aparece el estribillo por primera vez, y eso podría ser una
    pregunta. Queda abierto por decisión del IP: el demarcador distingue por arquitectura. Ver
    [Villancico](./revisiones-formas/cuestiones-para-el-ip.md#villancico) 6 y 7, donde va también la
    norma que se perdió al simplificar.
12bis. ~~**Ocho esquemas guardan la clase de rima en una caja y la notación en otra.**~~ **Cerrado
    el 12 de agosto de 2026**, y salió al dibujar la rejilla. `clase_rima` decía `abba` donde
    `notacion` dice `abbA`, y al revés: el zéjel guardaba `AABBBA` y publica `a(a) | [bbba]…`. La
    notación acertaba en los ocho, comprobado contra su esquema métrico, y se corrigieron 23
    posiciones. De ahí quedó escrito el criterio que faltaba —**la caja marca el arte del verso, no
    una clase distinta**, [criterios de nivel § 3.3](./criterios-de-nivel.md)—, su comprobación
    permanente `D14`, y el corolario de que `D13` no puede contar clases distinguiendo caja.

12ter. **Cinco esquemas abiertos no declaran ninguna restricción: pendientes de revisión contra las
    fuentes.** Eran nueve; **los cuatro de la sextilla se cerraron el 18 de agosto de 2026**
    (`20260818130000_la_sextilla_declara_lo_que_su_norma_acota`), y de paso dejaron escrito que
    **la pregunta de este punto no siempre tiene respuesta en las fuentes**: a diferencia de la
    quintilla, ninguna de las seis enuncia una regla para la sextilla —«varias combinaciones de
    rima», «variadas disposiciones», «la disposición varía de una a otra composición»—, así que lo
    declarable hubo que **derivarlo del repertorio documentado — y eso resultó ser un error**: se
    declararon `versos_sueltos` y `min_alternancias`, y las ocho restricciones se retiraron el
    mismo día (`20260818140000`). Quilis cierra su lista con un «etc.», de modo que **la
    enumeración de una fuente no es una norma**, y sacar de ella un mínimo convierte una muestra
    en ley. **Este apunte, tal como estaba escrito, empujaba a ese error**: la pregunta que propone
    solo tiene respuesta cuando la fuente enuncia una regla, como en la quintilla. Cuando solo
    enumera, el esquema abierto no declara nada y eso no es un hueco. Los detalles, en
    [Sextilla](./revisiones-formas/cuestiones-para-el-ip.md#sextilla) 6. Quedan el sexteto
    alejandrino, dodecasílabo y endecasílabo; la copla de pie quebrado; y la `suelta` de la endecha
    real, que además es el punto 4. Texto original del apunte: Dicen «distribución variable» y nada más, así que la ficha no puede enseñar de ellos
    ni un dibujo ni una norma —su fila de rima queda vacía, y ahí se ve—. Son el sexteto
    alejandrino, dodecasílabo y endecasílabo; la sextilla octosilábica, heptasilábica, hexasilábica
    y de pie quebrado; la copla de pie quebrado; y la `suelta` de la endecha real, que además es el
    punto 4. La pregunta que hay que hacerle a cada fuente es la misma que respondió la quintilla:
    **cuántas clases de rima, cuántas alternancias como mínimo y si admite versos sueltos**. Con eso
    el esquema abierto pasa a declarar norma y `D13` puede contrastar contra él las disposiciones
    concretas. Sale del barrido del 12 de agosto de 2026.

12quater. **La rejilla no sabe dibujar una unidad acotada: la convierte en ciclo.** Cuando
    `unidad_versos_min` y `unidad_versos_max` existen pero difieren, `construirRejilla` cae en la
    rama que toma las columnas del esquema de rima y **pone `cicla = true`**
    (`src/lib/metrica/rejilla.ts`), de modo que la ficha imprimiría «⟳ Se repite hasta el final de
    la serie» sobre una estrofa que no es una serie, y `perfilDeArquitectura` la clasificaría como
    `serie_ciclica`. Salió el 15 de agosto de 2026 al querer abrir la seguidilla gitana a 3–4
    versos, porque el Diccionario dice que «a veces puede presentarse sin su primer verso»: se
    dejó en 4/4 y el dato quedó solo como afirmación. **El radio es hoy nulo** —la única otra
    arquitectura con unidad acotada no fija, `copla_de_pie_quebrado/octosilabica_con_quebrados`,
    tiene cero posiciones de rima y nunca llega a esa rama—, y por eso no urge: el IP decidió
    aplazarlo porque esa gitana no aparece en el teatro que se analiza. El arreglo es una rama para
    unidad acotada antes de la del ciclo, con su prueba en `rejilla.test.ts`.

12quinquies. **Dos cosas de la seguidilla que quedaron anotadas y sin tocar** el 15 de agosto de
    2026. La primera: el «Estribillo final» de la compuesta **duplica** la arquitectura «De tres
    versos» —mismo 5-7-5, misma rima— en vez de referenciarla con
    `arquitectura_referenciada_id`, como sí hace su «Cuerpo» con la simple; Navarro Tomás lo dice
    literalmente, que la compuesta «suma la variedad de cuatro versos y la de tres». No se hizo
    porque la reutilización añadiría bajo la parte una fila de rima `a-a` junto a la unitaria
    `-a-ab-b`, con letras que chocan. La segunda: `tipo_seccion` vale `seguidilla_simple` en el
    cuerpo de la compuesta y `cuerpo` en el de la chamberga, siendo dos secciones idénticas
    —«Cuerpo», 4 versos, reutilizando la simple—. Ninguna de las dos es un defecto: `tipo_seccion`
    solo se lee como etiqueta de reserva cuando `nombre` viene vacío, y aquí nunca llega a
    dispararse. Se revisan y se unifican más adelante.

12. **Un esquema de rima solo puede señalar una sección, y a veces sirve a varias.** Los tres de la
    mudanza del villancico valen para `mudanza` y para `mudanza_inicial`, que son dos secciones de la
    misma clase. Hoy se resuelve no señalando ninguna —la ficha llega a ellos por su pregunta—, lo
    cual funciona pero deja el caso sin decir. Si aparece un esquema que deba señalar sección **y**
    servir a varias, habrá que emparejar por `tipo_seccion` en vez de por identidad.

14. ~~**La prosa de los niveles bajos repetía lo que la nueva ficha ya derivaba.**~~ **Cerrado el 13
    de agosto de 2026.** El barrido iniciado el día 12 se revisó entrada a entrada con la base viva
    y terminó en las migraciones `20260812270000`–`20260812330000`. No se podaron
    `formas_metricas.definicion` ni `arquitecturas_forma.descripcion`, porque sitúan la forma; las
    notas de enlaces, repeticiones, rasgos y relaciones se mejoraron sin vaciarlas. Las
    atribuciones que podían perderse se trasladaron antes a `afirmaciones_fuentes_metricas` y se
    contrastaron con los TXT originales cuando fue necesario. Una revisión retrospectiva añadió
    dos que la poda había dejado solo en glosas: Jauralde sobre `ababa` como fórmula más simple y
    antigua de la quintilla, y Navarro Tomás sobre `CDE CDE` como disposición preferida por
    Garcilaso y Herrera (`20260812340000`).

    El [informe regenerable](./historico/poda-de-la-prosa.md) queda en **0 frases pendientes de 191**. Las
    prosas que se conservaron por decisión expresa —por ejemplo, la renovación de la clase de rima
    en la silva consonante regular— están registradas en `scripts/informe-poda-prosa.mjs`; regenerar
    el informe no vuelve a abrirlas. Sigue vigente la regla 1 de
    [dónde vive la prosa](./donde-vive-la-prosa.md#las-tres-reglas): no escribir lo que la ficha
    deriva.

### Superficies, después del modelo

10. ~~**El maquetado del editor V2.**~~ **Hecho el 11 de agosto de 2026**, y con el diseño que
    estaba aprobado: estructura pintada a la izquierda, elecciones alineadas a la derecha, sin
    clics para navegar. Se adelantó al resto de las superficies porque el formulario había dejado
    de ser usable, no porque el modelo lo pidiera. Sigue derivándose del catálogo, así que cada
    cambio del modelo lo cambia gratis. Ver [arriba](#el-editor-v2-ya-tiene-su-pantalla-nueva).
11. ~~**Simplificar el gestor del catálogo.**~~ **Resuelto el 11 de agosto.** Se retiraron del
    dashboard las pantallas mutables de forma, organización y referencia. `/formas` es la consulta
    legible y los cambios, incluida la prosa, pasan por migración revisable.
12. **Recompilar el demarcador** sobre la ontología en vez de su vector fijo de rasgos.
13. ~~**Repaso visual del catálogo público**.~~ **Hecho el 12 de agosto de 2026, en dos tramos.**
    Primero, la arquitectura dibujada **verso a verso** con una rejilla que comparten la ficha, el
    demarcador y el recuadro de la norma del editor V2 —`src/lib/metrica/rejilla.ts`, con sus
    pruebas—. Después, al verla en pantalla, **la ficha entera rehecha**: la figura se estaba
    sumando a la prosa que ya la decía, y ahora la arquitectura se lee **dimensión a dimensión**
    —extensión, medida, rima, partes, repetición, rasgos—, cada una marcada según la fije la norma,
    la elija la realización o se observe al anotar
    (`src/lib/components/metrica/PublicArchitectureCard.svelte`). La rima lleva sus partes dentro,
    con su cuenta —«Cuartetos, se elige una de 2»—, el reparto dejó de ser una dimensión aparte
    porque es de la rima, y la glosa de una disposición se abre como una columna de la rejilla en
    vez de flotar, que se recortaba contra el contenedor con scroll. El razonamiento del día en que se hizo
    quedó [archivado](./historico/catalogo-publico-2026-08-12.md); lo vigente vive donde se
    comprueba: los moldes y los perfiles en `rejilla.ts` y sus pruebas, y por qué la pantalla es
    así en el propio componente. De paso
    cayeron los tres defectos que sangraban: el `undefined` del bloque «Repetición» —`regla` no es
    una columna de `repeticiones_metricas`—, las alternativas que el demarcador contaba como
    posiciones y las partes de un esquema con dos bloques iguales, que se fundían en una.

13bis. ~~**El régimen de rima no se enseñaba en ninguna ficha y ocho arquitecturas no lo
    declaraban.**~~ **Cerrado el 12 de agosto de 2026.** No eran ocho huecos: `esquemas_rima`
    también lo declara y lo tenía en 81 de 87, así que el dato vivía abajo. De ahí salió el
    criterio —**se declara siempre, arriba si el régimen es uno y en cada disposición si dentro de
    la arquitectura varía**, [§ 3.3](./criterios-de-nivel.md)—, su comprobación permanente `D15` y
    la corrección de los seis que sí faltaban, con Navarro Tomás § 207, Jauralde y Morley y
    Bruerton delante. El villancico y la canción sin rima **siguen sin declararlo arriba, y es lo
    correcto**: mezclan regímenes.

13ter. ~~**Revisar en conjunto las etiquetas que explican cómo se conoce cada dimensión en la
    ficha pública.**~~ **Cerrado el 14 de agosto de 2026.** No era un eje de procedencia ni de
    prescripción, sino de **grado de determinación**: qué permanece estable en una arquitectura y
    qué concreta cada poema. La ficha deriva `Fijo`, `Acotado`, `Variable`, `Opcional`, `Permitido`,
    `Abierto`, `No fijado` y `Fijado por la primera unidad` desde rangos, posiciones, restricciones
    y grupos de elección; `modalidad` sigue diciendo por separado la frecuencia reconocida por la
    teoría. La derivación vive en `src/lib/metrica/determinacion.ts`, sin columnas ni listas de
    formas, y sus reglas estables están en
    [el modelo aplicado](./implementacion-metrica.md#grado-de-determinaci%C3%B3n-qu%C3%A9-permanece-estable-en-la-arquitectura).
    Al hacerla se corrigió además la clasificación de rasgos: las opciones obligatorias se leen del
    grupo real, no del número de filas de `arquitectura_rasgos`.

13quater. **Revisar juntos el terceto y el terceto encadenado.** La poda conservó la distinción
    vigente —el segundo enlaza la rima central de cada unidad con la siguiente y no se divide en
    tercetos independientes—, pero el IP quiere volver sobre algún aspecto de ambas fichas. No se
    abre ni se concreta durante la poda: queda anotado para una revisión específica posterior.

13quinquies. ~~**La reutilización de arquitecturas no siempre tenía su relación entre formas.**~~
    **Cerrado el 13 de agosto de 2026.** Son dos niveles complementarios: `forma_relaciones`
    declara el vínculo ontológico una sola vez y la ficha lo lee desde ambos extremos;
    `estructuras_secciones.arquitectura_referenciada_id` señala qué realización concreta reutiliza
    la sección. Se añadieron las relaciones del soneto con cuarteto y terceto, y las que faltaban
    para novena, décima, terceto encadenado, cuarteto y redondilla (`20260812350000`–`360000`). La
    comprobación permanente **D16** impide que una reutilización entre formas vuelva a quedar sin
    relación ontológica. No hace falta una tabla de relaciones entre arquitecturas para la
    composición: la propia sección ya ocupa ese nivel preciso.

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

**Sobre los defectos del informe de conformidad**: el auditor tipifica ya **D1–D16** y termina en
**0 defectos** contra la base viva. Incluye la correspondencia entre notación y clases de rima
(D14), la declaración del régimen de rima (D15) y la correspondencia entre reutilización
estructural y relación ontológica (D16). Al revisar una forma conviene regenerarlo: introducir un
defecto nuevo es fácil.

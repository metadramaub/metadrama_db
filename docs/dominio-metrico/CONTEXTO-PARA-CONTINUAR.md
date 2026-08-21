# Contexto para continuar el trabajo métrico

Actualizado: 22 de agosto de 2026

Este es el documento que debe leer primero un nuevo chat. Resume el estado operativo, dice qué
queda por hacer y enlaza la documentación detallada.

> **La revisión del catálogo está terminada, y con ella la de su prosa.** Las formas activas de
> entonces —26— y los dos tramos sin forma se contrastaron con las seis monografías hasta el 8 de
> agosto de 2026; las seis lecturas transversales se cerraron el 10; y la prosa de esas 28 fichas
> quedó revisada forma por forma el **21 de agosto**. Ese mismo día entraron seis formas nuevas,
> escritas ya con el criterio de la revisión. El diario de ese proceso está
> [archivado](./historico/revision-del-catalogo-2026-07-a-08.md). Lo que sigue **sin decidir**, forma
> por forma, está en [cuestiones para el IP](./cuestiones-para-el-ip.md), podado el 22 de agosto.
>
> **Lo que queda por hacer está en [qué queda pendiente](#qué-queda-pendiente)**, reordenado el 21
> de agosto por lo que bloquea los dos hitos siguientes: migrar las secuencias ya anotadas y pasar
> el editor V2 a producción.

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
  [la revisión de nomenclatura](./historico/revision-nomenclatura.md). El catálogo tiene **37 formas
  y 2 tramos sin forma**: eran 27, la copla de pie quebrado se retiró el 20 de agosto de 2026 por
  nombrar un rasgo y no una estructura, el 21 entraron seis al llenar el hueco de las estrofas de
  siete, ocho, once y doce versos —copla de arte menor, copla castellana, octava aguda, septilla,
  oncena y copla manriqueña— y entre el 21 y el 22 otras cinco al cerrar las de siete y las
  enlazadas —septeto, septeto-lira, redondilla enlazada, sextilla enlazada y septilla enlazada—. **La medida de toda forma isosilábica es arquitectura** y ya
  no se pregunta, y lo que era una forma para decir «N unidades de esta otra» —sexta rima, tercetos
  sin encadenar, pareados endecasílabos— vive en el nivel que le corresponde. *La doble sextilla y
  la redondilla doble volvieron a ser formas el 21 de agosto, y no por su nombre: cuando dos
  semiestrofas no comparten rima la articulación es otra, y eso es lo que decide —ver
  [criterios de nivel § 3.1](./criterios-de-nivel.md).* Las formas con clasificación previa tienen
  ya su tradición; las restantes no la tienen porque no hay de dónde tomarla.
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
  lee mal, está mal en el catálogo. El listado carga en una sola consulta todos los registros
  activos —39 desde el 22 de agosto de 2026— y los conserva para el filtrado en ejecución; cada
  ficha usa otra consulta agregada que mantiene los identificadores y la jerarquía padre-hijo de
  sus secciones.
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
- Por qué: [propuesta-editor-v2.md](./historico/propuesta-editor-v2-2026-08-11.md), con el diagnóstico medido y lo que
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
5. [Las fuentes del catálogo](./fuentes-del-catalogo.md): las seis monografías, por qué solo seis,
   dónde están los ficheros y cómo se cita cada una. **De lectura obligada antes de añadir o
   corregir una afirmación.**
6. [Dónde vive la prosa del catálogo](./donde-vive-la-prosa.md): los ocho criterios de redacción
   y dónde va cada cosa —definición, descripción, nota, afirmación—.
7. Para la migración de las secuencias, en este orden:
   [el plan](./plan-migracion-anotaciones.md) → [cómo se migra una obra](./como-se-migra-una-obra.md)
   → [equivalencias pendientes](./equivalencias-pendientes.md), que dice **por qué** algunos
   términos legados no declaran todavía su destino. **El estado —cuántos faltan, cuáles y cuánto se
   usan— no se escribe: lo genera `npm run equivalencias:informe`** en
   [informe-equivalencias.md](./informe-equivalencias.md). Los informes por obra, con
   `npm run migracion:informe`, en [migracion/](./migracion/).
8. La razón filológica de una forma concreta, solo si la tarea la toca: primero `/formas`, que se
   genera del dato, y si hace falta el porqué,
   [cuestiones para el IP](./cuestiones-para-el-ip.md), que reúne lo que sigue sin decidir con el
   pasaje de la fuente de cada caso.

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

### Cómo se revisa y se cambia el catálogo

**El método, que sigue en vigor para cualquier cambio futuro.** Se audita una forma entera contra
la base —definición, arquitecturas, esquemas, notas, denominaciones, relaciones y afirmaciones—,
se contrasta con la ficha real de `/formas`, se presentan **todas las decisiones juntas** para que
el IP las apruebe una a una, y se aplica **una sola migración por forma**, con guardas que
comprueben los valores vivos exactos y ejecuten lo que tocan, para poder verificar esa ficha antes
de pasar a la siguiente. La norma de redacción es
[dónde vive la prosa](./donde-vive-la-prosa.md); las fuentes y cómo se citan, en
[las fuentes del catálogo](./fuentes-del-catalogo.md).

Se intentó primero como barrido global —hubo un informe de «segunda poda» con su generador— y no
funcionó: un inventario de frases sueltas no deja ver la forma entera, y sus recuentos envejecían
en cuanto se tocaba algo. Los tres documentos se retiraron el 18 de agosto de 2026; sus decisiones
ya aplicadas están en las migraciones y en el historial de `git`.

**Terminada el 21 de agosto de 2026.** Las 28 fichas que existían llevan la prosa revisada; las
seis formas creadas ese mismo día nacieron ya con ella. Su rastro:

| Forma | Migración |
| --- | --- |
| Villancico | `20260814090000_el_villancico_explica_sin_repetir_sus_partes` (+ `20260821090000_el_villancico_separa_el_enlace_de_la_vuelta`, `20260821110000`) |
| Zéjel | `20260814100000_el_zejel_deja_hablar_a_su_figura` (+ `20260821100000_el_zejel_dice_de_donde_viene_y_donde_pervive`) |
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
| Lira y sexteto-lira | `20260819200000_la_lira_dice_de_donde_viene_su_nombre` (+ `20260819210000`, `20260819220000`) |
| Sexteto | `20260819230000_el_sexteto_declara_lo_que_su_norma_deja_libre` |
| Sextilla (segunda vuelta) | `20260820090000_la_sextilla_manriquena_dice_como_rima` |
| Copla real | `20260820150000_cada_fuente_habla_de_la_forma_que_describe` |
| Octava real | `20260820160000_la_octava_real_acota_lo_que_deja_variar` (+ `20260820170000`, `20260820180000`) |
| Copla de arte mayor | `20260820190000_la_copla_de_arte_mayor_llega_al_teatro_como_arcaismo` (+ `20260820200000`) |
| Endecasílabo suelto | `20260820210000_el_endecasilabo_suelto_distingue_el_blanco_del_suelto` |
| Endecha real | `20260820220000_la_endecha_real_ensena_sus_cuatro_disposiciones` (+ `20260820230000`) |
| Pareado | `20260820240000_el_pareado_dice_para_que_sirve` (+ `20260820250000`) |
| Novena | `20260820260000_la_novena_dice_como_se_llama_y_quien_la_escribio` (+ `20260820270000`) |
| Tramos sin forma | `20260820280000_los_dos_tramos_sin_forma_se_reconocen_entre_si` |
| Pie quebrado, en cinco formas | `20260820100000_el_pie_quebrado_es_un_rasgo_de_cada_estrofa` (+ `20260820110000`, `20260820120000`, `20260820130000`) |

**Definiciones y descripciones no se podan: se mejoran, y a menudo alargándolas.** Pueden repetir
en prosa lo que la figura dibuja, porque su función es que una forma se lea de corrido; las de la
seguidilla son el modelo. La regla de no escribir lo derivado se aplica con severidad a las
**notas** —de posición, de sección, de rasgo, y las descripciones de esquema—, no a ellas. Y su
prosa no usa lenguaje de base de datos ni da por supuesto el Siglo de Oro: el catálogo aspira a
ser más general que el corpus.

**Cómo se retira algo del catálogo.** Fijado el 20 de agosto de 2026, al retirar la primera
forma. Una **forma** o una **arquitectura** se retiran con `activo = false`: es el interruptor
real —lo filtran nueve funciones SQL y el cargador del editor—, y saca la fila de la ficha, del
catálogo público y del demarcador de una vez, sin borrarla. Lo que **cuelga de una arquitectura**
—esquemas, secciones, rasgos, grupos— se retira con ella y no lleva flag propio. Y un **esquema,
una sección o una variedad sueltos se borran**: todas las claves ajenas de
`elecciones_editor_metrico` son `on delete restrict`, así que la base impide sola borrar lo que
una anotación use, que es una garantía más fuerte que un estado.

`estado_revision` **ya no existe** en el dominio métrico. Se retiró de sus doce tablas ese mismo
día: la escribían solo las pantallas del gestor mutable —retirado el 11 de agosto—, la leía un
único filtro que nunca excluyó nada, y lo que guardaba era el rastro de la última pantalla que
tocó cada fila, no un estado. **La revisión es la migración**, y queda en `git`. Cuidado al
buscarla: `permissions.ts` y `/dashboard/vocabularios` mencionan un `estado_revision` que es otra
cosa, una categoría del vocabulario legado.

**Una afirmación no se reutiliza entre formas.** Cada fuente dice lo que dice **de cada forma**, y
una misma afirmación servida a varias acaba hablando de otra estrofa en tres de ellas: pasó el 20
de agosto de 2026 al mover al rasgo `pie_quebrado` la bibliografía de la copla de pie quebrado, y
la ficha de la copla real amaneció con dos notas de fuente sobre la sextilla. Cuando una fuente
documenta algo que toca a varias formas, **se integra en la afirmación que cada una ya tiene**, con
lo que esa fuente dice de ella; si no dice nada de una forma, esa forma no lleva nota.

**Las seis monografías, dónde están y cómo se citan:**
[las fuentes del catálogo](./fuentes-del-catalogo.md). Ahí va también el aviso que costó dos
descuidos: el texto de Morley y Bruerton es `definiciones_Morley&Bruerton.md`, en `.md` y sin sus
apellidos al principio, así que una búsqueda filtrada por `.txt` lo deja fuera y hace creer que su
libro no está.

**Que el auditor calle no prueba que la norma esté declarada.** El aviso `patron_rima_sin_regla`
se apaga en cuanto la arquitectura tiene *o* una restricción, *o* una densidad, *o* un esquema
concreto — y un esquema concreto no dice nada de la disposición abierta, que es la que la norma
declara. Así se le pasó al sexteto la densidad de rima de su arquitectura principal, y así la
tiene todavía la sextilla en dos de las suyas. Al revisar una forma con disposición abierta,
comprobar la densidad **arquitectura por arquitectura**, no fiarse del recuento.

**Tras cada migración, `npm run audit:metrica` debe dar 0 defectos** —necesita Docker levantado,
porque vuelca la base—. Y conviene mirar la ficha servida, no solo el dato: en esta fase, leerlas
una a una ha descubierto defectos de presentación que no se veían ni en el catálogo ni en el
código.

## Qué queda pendiente

Inventario rehecho el **21 de agosto de 2026**, al terminar la revisión de la prosa. Lo cerrado ya
no se lista: está en las migraciones, en `git` y en el
[histórico](./historico/). Quedan **veinticuatro asuntos**, ordenados por lo que bloquea el
próximo hito y no por el orden en que aparecieron.

**Los dos hitos que vienen, en este orden:**

1. **Migrar las secuencias ya anotadas** del vocabulario legado al catálogo nuevo, por
   equivalencias más revisión manual obra por obra. Marco:
   [el plan de migración](./plan-migracion-anotaciones.md); procedimiento:
   [cómo se migra una obra](./como-se-migra-una-obra.md); estado de las equivalencias:
   [informe-equivalencias.md](./informe-equivalencias.md), que regenera
   `npm run equivalencias:informe`.
2. **Pasar el editor V2 a producción** para todo el equipo, sustituyendo al selector que hoy
   escribe en `secuencias_metricas`.

**Nada de lo que sigue impide anotar hoy** con el editor actual, y el catálogo está limpio:
`npm run audit:metrica` y `npm run audit:editor` dan cero defectos, y las pruebas y `npm run check`
pasan. Lo que sigue son deudas del modelo y huecos de cobertura.

*Puesto al día el **22 de agosto de 2026**. Del bloque A se cerraron los cuatro apuntes de
cobertura —A2, A2bis, A2ter y A3—, que dejaron **once formas nuevas**, doce medidas y tres
criterios escritos: una arquitectura no cambia la extensión de la unidad de su forma, un rasgo
admitido no cambia lo que la forma declara, y la medida no compromete la norma mientras que lo que
la fija se acota. **Quedan dos asuntos en A, cinco en B y dieciséis en C.***

### A · Bloquean la migración de las secuencias

Son los casos en que una secuencia real **no tendría dónde caer**. Conviene resolverlos antes de
empezar, porque cada uno obliga a parar la migración de una obra a la mitad.

**A1. Las 27 equivalencias del vocabulario legado sin destino.** El razonamiento de por qué faltan
y lo que ya decidió el IP están en
[equivalencias-pendientes.md](./equivalencias-pendientes.md); las cifras, en el informe
regenerable. *Es el primer paso: sin destino declarado, la secuencia no se puede convertir.*

**A2. ~~Faltan formas de ocho, once y doce versos donde caer.~~ Hecho el 21 de agosto de 2026**,
en seis migraciones —`20260821120000` a `20260821170000`—. El apunte estaba mal planteado: pedía
«octavilla, oncena y copla mixta», y al contrastar las seis fuentes resultó que **«octavilla» es un
nombre y no una forma**, que la estrofa que nombra **ya estaba en el catálogo escondida** dentro de
la redondilla, y que faltaba además la de siete versos, que nadie había echado en falta. El
catálogo pasa de 26 formas a 32:

- **Copla de arte menor** (8, dos semiestrofas que comparten una rima) — salió de
  `redondilla · doble_enlazada`, que se retiró. Sus otros nombres: octavilla, octava de arte menor,
  octava redondilla, redondilla de ocho versos.
- **Copla castellana** (8, cuatro rimas y semiestrofas independientes) — la que de verdad faltaba:
  Jauralde la llama «forma popularísima a lo largo de los siglos XVI y XVII».
- **Octava aguda** (8, riman en agudo los versos que cierran cada semiestrofa) — con seis
  arquitecturas por medida y «octavilla aguda» colgando de las de arte menor.
- **Septilla** (7 = redondilla + terceto enlazado), también llamada copla mixta.
- **Oncena** (11 = quintilla + sextilla, y la inversa), también llamada undécima.
- **Doble sextilla** (12) — salió de `sextilla · doble_pie_quebrado`.

**El criterio que ordenó todo esto**, y que quedó escrito en
[criterios de nivel § 3.1](./criterios-de-nivel.md): lo que hace forma aparte es la articulación
—cuántos miembros, de qué tamaño y si comparten rima—; la medida y la disposición son
arquitectura; el nombre no decide nada. Con un indicio duro: **una arquitectura no cambia la
extensión de la unidad de su forma**, con tres excepciones documentadas —décima, sextina y
seguidilla— que la comprobación enumera.

*No se creó una «copla mixta» general de siete a doce versos: en Navarro es el rótulo de un grupo
—septilla, novena, oncena y doble sextilla—, y una forma de rango repetiría el error de la copla de
pie quebrado, que tapaba las estrofas reales mientras cubría el intervalo.*

**A2bis. ~~Dos estructuras que salieron leyendo y no se crearon.~~ Hecho el 21 y 22 de agosto de
2026**, en cinco migraciones —`20260821200000` a `20260822000000`—. Al leer las fuentes para
resolverlo resultaron ser cinco y no dos, y **dos de ellas son del corpus**. El catálogo pasa de 32
formas a 37:

- **Septeto** (7, arte mayor). La hermana mayor de la septilla, separada por la medida como el
  sexteto de la sextilla: Jauralde dice que en las estrofas de siete «cabe también la distinción
  según el tipo de verso que acojan». Dos arquitecturas: la endecasilábica de rima libre que
  describen Quilis y el *Diccionario* —«con la única condición de que no rimen tres versos
  seguidos»— y la compuesta, cuarteto más terceto. El **septeto agudo** va como rasgo.
- **Septeto-lira** (7, heterométrico). Cierra la serie lira → sexteto-lira → septeto-lira, que el
  catálogo tenía coja. Es la estrofa de la canción alirada, y el ejemplo que la documenta es de
  **fray Luis de León**: `7a 11B 7a 11B 7b 7c 11C`.
- **Las tres estrofas enlazadas** de Navarro Tomás § 131 —**redondilla enlazada**, **sextilla
  enlazada** y **septilla enlazada**—, series en que la rima pasa de una estrofa a la siguiente.

**Las enlazadas eran el hueco de verdad.** Navarro no las trata como curiosidad: «se hizo de varios
modos el enlace de las estrofas, **no como mera gala métrica** […] **sino como recurso para dar a la
versificación movimiento flexible y corrido**», y al recorrer el período concluye que **«el teatro
dio preferencia a las estrofas octosílabas enlazadas de seis y siete versos»**. Las documenta en
**la mayor parte de los pasos y entremeses de la *Turiana* de Timoneda**, en la *Propalladia* de
Torres Naharro, en **los entremeses de Sebastián de Horozco** y en cuatro piezas de la colección
Rouanet. Es material del corpus, y hasta hoy un paso entero anotado así no tenía dónde caer.

*Las tres se apoyan en una sola fuente —las otras cinco no las tratan, y así consta en sus fichas—.
Es la primera vez que el catálogo crea formas con un solo respaldo, y se hace por el criterio de
exhaustividad: una fuente queda fuera de una forma solo cuando no la trata.*

**A2ter. ~~Dos preguntas abiertas sobre el pie quebrado.~~ Resueltas el 22 de agosto de 2026**
(`20260822040000`). Al preguntar el IP si el quiebro se declararía en la quintilla «sin transformar
la medida en combinación de tal y quebrados», se comprobó que el catálogo tenía **tres aparatos
distintos para el mismo rasgo**, y que cuatro de ellos los habían introducido las formas creadas
esos dos días: copla castellana, copla de arte menor, septilla y oncena anunciaban «8 de base, con
quebrados de 4» donde el quiebro es solo admitido, mientras la redondilla, con el mismo rasgo y la
misma modalidad, decía «8».

La regla quedó escrita en [criterios de nivel § 3.6](./criterios-de-nivel.md) y vale para cualquier
rasgo: **lo definitorio se declara donde se fija —el quiebro de la sextilla quebrada, la copla
manriqueña y las tres enlazadas va en las posiciones del esquema métrico— y lo admitido o habitual
va solo como rasgo**, sin tocar lo que la forma declara. Una guarda lo sostiene sobre el catálogo
entero.

**Y la quintilla admite ya el pie quebrado**, con el dato que lo pedía y que **no estaba recogido en
ninguna ficha**: Navarro Tomás, al resumir el período renacentista, escribe que «la quintilla con
verso inicial quebrado fue la estrofa más usada por Castillejo». El catálogo sostenía lo contrario
—que la tradición no la describe suelta y quebrada, sino como mitad de la copla real— y esa nota se
corrigió.

*Lo que quedaba de la segunda pregunta —dónde vive un rasgo que solo vale dentro de una
reutilización— **no era del quiebro sino del modelo**, y se funde en
[C1](#c--deudas-del-modelo-sin-urgencia): en la sextilla enlazada el quiebro es definitorio y
siempre en el mismo verso, y en la quintilla suelta es admitido, pero la reutilización no sabe
decir «aquí es obligatorio». Es la modalidad heredada, vista desde los rasgos.*

*Resueltas también por el camino, y anotadas porque valen para la próxima serie que se cree: **una
serie no declara la extensión de su unidad** —`rejilla.ts` descarta el esqueleto de secciones cuando
el esquema es cíclico, y entonces una unidad fija manda sobre el ciclo y lo apaga
(`20260822010000`)—; y **el enlace entre vueltas se declara en positivo**, con
`esquema_rima_enlaces`, o la ficha afirma lo contrario (`20260822020000`).*

**A3. ~~Cinco formas piden medidas que el catálogo no tiene.~~ Hecho el 22 de agosto de 2026**, en
cinco migraciones —`20260822050000` a `20260822100000`—. Las cinco tenían la medida documentada por
las fuentes y no declarada, y con ellas entró el **tercetillo**, que es el único caso de los cinco
con respaldo en el corpus áureo: Jauralde lo documenta en los diálogos teatrales de Lope, y **la
septilla lo estaba esperando** desde el día anterior con la única sección del catálogo sin la forma
que la realiza.

| Forma | Qué gana |
| --- | --- |
| **Terceto** | Octosilábica y hexasilábica, con el monorrimo `aaa` que la forma no tenía y la asonancia que el *Diccionario* le admite: **tercetillo**, tercerilla, tercerillo |
| **Quintilla** | Heptasilábica y hexasilábica, con las nueve disposiciones y las tres restricciones que son la norma de la forma, no de una medida |
| **Sextilla** | Pentasilábica y tetrasilábica, que el IP había dejado fuera el 18 de agosto y reabrió con el criterio nuevo |
| **Romance** | Pentasilábica y tetrasilábica, con sus nombres de romancillo; el *Diccionario* define romancillo por extensión abierta, «menos de ocho sílabas» |
| **Décima** | Penta, hexa, hepta y endecasilábica. **La hexasílaba la firma Góngora**, de modo que no es una prueba tardía |
| **Silva** | La **arromanzada**, que no es medida sino régimen, y entra por tener entrada y definición propias en el *Diccionario* |

**Lo que ordenó todo esto es un criterio nuevo**, escrito en
[criterios de nivel § 3.6](./criterios-de-nivel.md), que responde a la pregunta que volvía en cada
forma: **la medida no compromete la norma** y se declara cuando una fuente la documenta, sin
criterio de fecha; **lo que fija la norma** —disposición, restricción, régimen, rasgo definitorio,
forma nueva— exige que una fuente lo enuncie como regla o le dé nombre. La prueba es una sola
pregunta: *¿la fuente lo define o lo ensaya?*

*Por esa prueba quedó fuera la **décima asonante** —ninguna fuente la registra y Jauralde la
presenta como ensayo de Jorge Guillén «en vez de en consonante, que era lo tradicional»— y entró la
silva arromanzada, cuyo ejemplo es también del siglo XX pero tiene entrada y definición.*

**A4. Las equivalencias de los tres tramos irregulares hay que mirarlas una a una.** Es posible que
alguna sea que quien anotó no encontró la forma precisa, y que con el catálogo nuevo y el
demarcador sí la encuentre. Las que no, tendrán que **registrar exactamente lo que se ve** —medida,
rima y rasgos de todo el pasaje o verso—, que es lo que el editor V2 tendrá que pedir para estas
no formas. *No se modela nada para ellas porque todo vale: cualquier medida, cualquier rima,
cualquier rasgo, sin restricción.*

### B · Bloquean el editor V2 en producción

Son los casos en que un editor **no puede registrar lo que ve**, o en que la pantalla se apoya en
algo que ya no es cierto.

**B1. Qué pregunta el editor cuando la disposición de rima no es fija — y cómo declarar una que el
catálogo no tenga.** Salió al revisar la sextilla el 20 de agosto de 2026 y no es un caso suelto:
el sexteto da al editor un grupo `esquema_rima_observado` en sus tres arquitecturas, y la sextilla
—el mismo caso, seis versos consonantes de disposición abierta— **no tiene ninguno** en cuatro de
sus cinco, la principal incluida; solo la doble de pie quebrado pregunta, y con una casilla. Donde
la norma deja abierta la disposición, el editor no puede registrar la que vio. Hay dos salidas y no
son equivalentes: **campo libre**, como el sexteto, o **lista cerrada** con las disposiciones
documentadas más «otra». La revisión debe recorrer el catálogo entero y decidir una sola vez,
porque hoy conviven las dos sin criterio.

*Y con una tercera exigencia, decidida el 20 de agosto al revisar la octava real:* donde la norma
deja la disposición **abierta o acotada**, el editor tiene que poder **declarar un esquema que el
catálogo no tenga**. La octava real acota tres clases de rima y deja variar el orden de los seis
primeros versos; si un pasaje trae una de esas variantes, hoy no hay dónde escribirla. No es lo
mismo que elegir entre las catalogadas: es poder añadir la que se observa.

**B2. Qué se pregunta y qué no en los rasgos.** Va con B1: es la misma pregunta sobre otra
dimensión. Hoy conviven cuatro repartos sin criterio —el dístico final de la octava real no se
pregunta y el del endecasílabo suelto sí; el pie quebrado se pregunta en la copla real y no en la
redondilla; el final acentual se pregunta en cinco arquitecturas y no en la alejandrina del
sexteto—. Cada caso se decidió por separado y con razón local, pero nadie los ha mirado juntos. El
servidor distingue `permitidos` —rasgos sin pregunta—, `opcionales` —con pregunta que admite no
contestar— y `excluyentes` —varios valores y una sola respuesta—; **la distinción es del editor, no
del lector**, y por eso la ficha pública funde los dos primeros en un bloque desde el 20 de agosto.

**B3. El formulario del villancico, después del desdoblamiento.** El 21 de agosto de 2026 la
sección «Enlace o vuelta» se partió en dos partes planas dentro de la copla, «Enlace» y «Vuelta»,
con su grupo de medida cada una: `medida_enlace_vuelta` pasó a `medida_enlace` y nació
`medida_vuelta`. **Casi seguro que algo falla en la pantalla**: cambia el árbol de partes, el
número de preguntas y los slugs de dos grupos, y el formulario no se ha vuelto a abrir. Se
comprobó que ninguna elección anotada dependía de esas secciones —cero filas en
`elecciones_editor_metrico`—, así que no hay trabajo de editor en riesgo.

**B4. El cierre del terceto encadenado dejó de ser obligatorio y dos superficies lo dan por
hecho.** Sus dos arquitecturas declaraban la sección de cierre con `repeticiones_min = 1`, de modo
que el catálogo exigía un serventesio —o una redondilla cruzada— al final de toda cadena, y no lo
es: la serie puede terminar sin él. Corregido en el dato el 19 de agosto de 2026 (`20260819180000`).
**Quedan por revisar el demarcador y el editor V2.**

**B5. El editor no sabe anotar una décima aumentada entre décimas normales.** El catálogo sostiene
que no es un error —lo dicen su descripción y Morley y Bruerton—, pero `secuencias_editor_metrico`
lleva **una sola arquitectura por secuencia**, así que solo cabe partir el pasaje o registrarla
como desviación `estructura` / `mayor_que_norma`, que es anotarla como el error que no es.

### C · Deudas del modelo, sin urgencia

Ninguna impide migrar ni publicar. Se listan para que no se vuelvan a descubrir.

**C1. La modalidad heredada por reutilización no es la de la posición que ocupa.** Las dos
quintillas de la copla real reutilizan la arquitectura de la quintilla, así que traen sus esquemas
**con la frecuencia que tienen como quintilla suelta**: `aabba` sale «admitida» en la segunda
mitad, donde Morley y Bruerton dicen que en Lope es *siempre* esa. La novena tiene el mismo
desajuste. `modalidad` vive en `esquemas_rima`, que pertenece a **una** arquitectura, y no existe
una modalidad por *(sección, esquema)*. Afecta en principio a las **dieciocho reutilizaciones** del
catálogo —copla real, décima, novena, seguidilla, sextina, soneto y terceto encadenado— y muerde
donde la forma que reutiliza tiene frecuencias propias documentadas. *El IP decidió el 20 de agosto
decirlo en prosa y no tocar el modelo por ahora.* **Y tiene una segunda cara, la de los rasgos**,
que se le sumó el 22 de agosto: en la sextilla enlazada el pie quebrado es definitorio y siempre en
el mismo verso, mientras que en la quintilla que reutiliza es admitido, y `arquitectura_rasgos`
cuelga de una arquitectura y no de *(sección, rasgo)*, así que la reutilización no sabe decir «aquí
es obligatorio». Las dos caras se arreglan con la misma pieza. Las salidas barajadas: una tabla pequeña de
modalidad por sección, o dejar de reutilizar y duplicar los esquemas —que desharía la decisión de
reutilización cerrada el 13 de agosto y no se recomienda—.

**C2. La `suelta` de la endecha real es un ciclo con notación y cero posiciones.** `[----]…` dice
cuatro versos sueltos y nadie los expandió. O se expanden o se admite que la notación baste —pero
entonces deja de ser cierto que un esquema con posiciones sea lo cerrado—. *Espera además una
decisión que puede retirarlo: Navarro Tomás y el Diccionario llaman endecha real a la que no rima,
y Jauralde dice que el nombre llegó cuando recibió rimas.*

**C3. Dos huecos del auditor, y dos cosas del soneto que dependen de ellos.**
`max_consecutivos` está en el `CHECK` de `esquema_rima_restricciones.tipo` pero `incumple`, en
`scripts/audit-catalogo-metrico.mjs`, **no lo evalúa**: devuelve `false`. Y `numero_clases` admite
un solo valor, así que no puede expresar «dos o tres»: necesitaría un rango o un tipo nuevo.
*Arreglar lo primero es calcular la racha máxima en `resumir` y añadir una rama a `incumple`.* De
ahí cuelgan las dos preguntas del soneto: si sus cuartetos podrían heredar la disposición del
cuarteto declarando la identidad con un enlace, y la restricción `max_consecutivos: 2` de sus
tercetos, que la fuente enuncia y el catálogo no declara. Es la misma pieza que echó en falta la
sextilla.

**C4. Un esquema de rima solo puede señalar una sección, y a veces sirve a varias.** Los tres de la
mudanza del villancico valen para `mudanza` y para `mudanza_inicial`, que son dos secciones de la
misma clase. Hoy se resuelve no señalando ninguna —la ficha llega a ellos por su pregunta—, lo cual
funciona pero deja el caso sin decir. Si aparece un esquema que deba señalar sección **y** servir a
varias, habrá que emparejar por `tipo_seccion` en vez de por identidad.

**C5. Los tres esquemas abiertos del sexteto no declaran ninguna restricción.** Dicen «distribución
variable» y nada más, así que su fila de rima queda vacía en la ficha. La pregunta que hay que
hacerle a cada fuente es la que respondió la quintilla: cuántas clases de rima, cuántas
alternancias como mínimo y si admite versos sueltos. *Ojo con el precedente de la sextilla:* sus
cuatro esquemas se dejaron a propósito sin restricciones el 18 de agosto de 2026, porque las seis
fuentes solo **enumeran** disposiciones —Quilis cierra su lista con un «etc.»— y sacar un mínimo de
una enumeración convierte una muestra en ley. **La pregunta solo tiene respuesta cuando la fuente
enuncia una regla.** Lo mismo vale para el esquema abierto de la octava real, que se dejó sin
acotar el 20 de agosto por la misma razón.

**C6. La rejilla no sabe dibujar una unidad acotada: la convierte en ciclo.** Cuando
`unidad_versos_min` y `unidad_versos_max` existen pero difieren, `construirRejilla` cae en la rama
que toma las columnas del esquema de rima y **pone `cicla = true`** (`src/lib/metrica/rejilla.ts`),
de modo que la ficha imprimiría «⟳ Se repite hasta el final de la serie» sobre una estrofa que no
es una serie. **El radio es hoy nulo** y por eso no urge. El arreglo es una rama para unidad
acotada antes de la del ciclo, con su prueba en `rejilla.test.ts`.

**C7. No hay dónde guardar un ejemplo de verso.** El vocabulario legado guarda uno real en
`vocabularios.ejemplo`, y de los 119 términos de `estrofa_tipo` **solo seis lo tienen**: copla de
arte mayor, copla manriqueña, endecasílabo suelto encadenado, novena, sextina y villancico. El de
la sextina trae la permutación anotada verso a verso, que es justo lo que ninguna figura puede
dibujar. **El catálogo nuevo no tiene ninguna columna ni tabla para ejemplos.** Lo previsto por el
IP es un botón de ejemplos en cada ficha, para todas las formas: hay que **modelarlo** —de qué
cuelga un ejemplo, y cómo se guarda la anotación de clases— y luego poblarlo. Migrar los seis
legados es lo de menos.

**C8. La permutación de la sextina no se puede dibujar y hoy solo se lee.** La rejilla pinta una
estrofa y la colapsa con «×6», así que enseña `A B C D E F` en orden y no puede mostrar ni que la
estrofa siguiente las trae en otro orden ni que el remate las reúne dos por verso. Se palió el 19
de agosto sacando la descripción de la repetición de detrás de su icono. *Dibujarlo de verdad es
una función aparte, y va con C7: el ejemplo anotado la enseña mejor que cualquier figura.*

**C9. Dos cosas de la seguidilla, anotadas y sin tocar.** El «Estribillo final» de la compuesta
**duplica** la arquitectura «De tres versos» —mismo 5-7-5, misma rima— en vez de referenciarla con
`arquitectura_referenciada_id`, como sí hace su «Cuerpo» con la simple; no se hizo porque la
reutilización añadiría bajo la parte una fila de rima `a-a` junto a la unitaria `-a-ab-b`, con
letras que chocan. Y `tipo_seccion` vale `seguidilla_simple` en el cuerpo de la compuesta y
`cuerpo` en el de la chamberga, siendo dos secciones idénticas. *Ninguna de las dos es un defecto.*

**C10. ¿Son una sola arquitectura las dos del villancico?** Lo único que las separa es dónde
aparece el estribillo por primera vez, y eso podría ser una pregunta. Queda abierto por decisión
del IP: el demarcador distingue por arquitectura.

**C11. Modelar lo que las fuentes describen aunque el corpus no lo traiga.** Es un solo criterio
que asoma en cuatro sitios y se decide junto: el repertorio del **sexteto**, que las fuentes
definen más ancho que el corpus; las **cuatro disposiciones históricas de la doble sextilla** que
Navarro Tomás § 68 enumera con ejemplo y localizador y de las que el catálogo declara solo la
última; la **copla real de cuatro y seis versos**, que Jauralde advierte que «precede a la 5-5, que
solo se hace mayoritaria a finales del siglo XV» y el catálogo no tiene. *La cuarta pregunta de este apunte —si la doble sextilla merecía
nivel propio— se cerró el 21 de agosto: es la **copla manriqueña**, forma, porque la articulación
la separa de la sextilla aunque el enlace entre sus mitades sea de sentido y no de rima.*

**C12. Revisar juntos el terceto y el terceto encadenado.** La poda conservó la distinción vigente
—el segundo enlaza la rima central de cada unidad con la siguiente y no se divide en tercetos
independientes—, pero el IP quiere volver sobre algún aspecto de ambas fichas.

**C13. Revisar las tradiciones de todas las formas.** **Cinco están sin tradición** —cuarteto,
endecha real, pareado y los dos tramos sin forma—, y en algunos casos con razón: Jauralde sitúa el
pareado «entre las formas originarias y primitivas de la poesía», que no es ni italiana ni
española. Pero eso no se ha comprobado forma por forma, y las tres tradiciones del catálogo nunca
se han mirado juntas: ni de dónde sale cada asignación, ni si el reparto responde a un criterio, ni
si «italiana» y «española» bastan. *La revisión debe decidir si la ausencia es un dato o un hueco.*

**C14. Retirar `formas_metricas.orden`.** **No lo lee nadie**: las dos consultas públicas lo
seleccionan y ordenan por nombre, la página de `/formas` ordena por nombre, y el tipo público de
una forma ni siquiera lo lleva. Sus valores tampoco responden a ningún criterio: décima, romance y
terceto encadenado comparten el 10, la redondilla está en el 40, y hay huecos en 20, 30, 60, 80,
100, 160, 170, 270 y 300. **Cuidado al retirarla**: `arquitecturas_forma.orden` sí trabaja —`order
by orden nulls last, nombre` es lo que pone la principal delante— y `estructuras_secciones.orden`
también. Solo sobra la de las formas.

**C15. La esquina de las *Nise*: heptasílabos mezclados y sin rima.** No es silva, porque la silva
exige rima, y no es endecasílabo suelto, porque este es solo de once. Navarro Tomás lo documenta en
el teatro: Jerónimo Bermúdez compuso *Nise lastimosa* y *Nise laureada*, de 1577, en endecasílabos
sueltos, «donde además mezcló endecasílabos y heptasílabos sueltos». *Se anota por si alguna de las
dos entra en el corpus: entonces habrá que decidir si el endecasílabo suelto gana una arquitectura
heterométrica o si la frontera con la silva se redibuja.*

**C16. La modalidad aguda alcanza a más formas de las que la declaran.** Salió el 21 de agosto de
2026 al crear la octava aguda. Jauralde: «la modalidad aguda se extendió a otras muchas variedades
estróficas, **como la sextilla y la décima**», y también a estrofas de arte mayor. El catálogo tiene
la pieza —el rasgo `final_acentual` con valor `agudo` y `posiciones_max`, que el sexteto alejandrino
ya usa así: «riman en agudo los versos tercero y sexto, que son los que cierran cada
semiestrofa»—, pero solo lo declaran dos arquitecturas. *Falta una pasada que decida en qué formas
se admite y con qué modalidad; va con B2, que revisa el reparto entero de los rasgos.*

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
4. **Revisión del catálogo contra las fuentes: completa.** Las formas activas y los dos tramos sin
   forma están contrastados con las seis monografías. El diario está
   [archivado](./historico/revision-del-catalogo-2026-07-a-08.md). Destapó por el camino defectos
   del modelo: los corregidos están aplicados y los aplazados eran **lecturas transversales** sobre
   el catálogo entero.
5. **Las seis lecturas transversales: completas** el 10 de agosto de 2026. El concepto de
   variedad, la automatización de las preguntas del editor, la reutilización de secciones, la
   modalidad y la primacía, las reglas de repetición y el modelo de esquemas abiertos.
6. **Revisión de la prosa, forma por forma: completa** el 21 de agosto de 2026, en las 28 fichas
   que existían. Las seis formas creadas ese día nacieron con la prosa ya escrita a ese criterio.
7. **El demarcador ya consume la ontología**, no su vector fijo de rasgos: se recompila desde
   `/dashboard/metrica` y `obtener_catalogo_demarcador()` lo sirve de `formas_metricas`. Queda
   revisarlo tras dos cambios recientes —el cierre no obligatorio del terceto encadenado y la
   retirada de la copla de pie quebrado—, en [B4](#b--bloquean-el-editor-v2-en-producción).
8. **Lo que viene**, y en este orden: la
   [migración de las anotaciones](./plan-migracion-anotaciones.md) por equivalencias más revisión
   manual, y el paso del editor V2 a producción. Lo que hay que despejar antes está en
   [qué queda pendiente](#qué-queda-pendiente), bloques A y B.
9. Crear la capa de desviaciones sobre las secuencias reales:
   [plan de desviaciones](./plan-desviaciones-y-caracterizaciones.md), decidido y no ejecutado.

**Sobre los defectos del informe de conformidad**: el auditor tipifica ya **D1–D16** y termina en
**0 defectos** contra la base viva. Incluye la correspondencia entre notación y clases de rima
(D14), la declaración del régimen de rima (D15) y la correspondencia entre reutilización
estructural y relación ontológica (D16). Al revisar una forma conviene regenerarlo: introducir un
defecto nuevo es fácil.

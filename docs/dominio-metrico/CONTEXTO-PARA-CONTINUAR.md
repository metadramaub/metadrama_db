# Contexto para continuar el trabajo métrico

Actualizado: 25 de agosto de 2026

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
- `/dashboard/metrica` se retiró el 28 de agosto: ya no editaba ni auditaba el catálogo y su
  validación paralela producía avisos desactualizados. La ruta redirige al catálogo público; el
  catálogo se consulta en `/recursos/catalogo-metrico`, el demarcador en
  `/recursos/demarcador` y todos los cambios del dato se hacen por migración.
- **La respuesta guardada no depende del catálogo que la ofreció.** `anotacion_elecciones`
  apunta al dato elegido —el esquema, el metro, el valor de rasgo, la repetición, la variedad—,
  no a una opción, y el catálogo se niega a borrar algo que una anotación use. Para leerla con
  la opción que hoy la ofrece está `anotacion_elecciones_resueltas`.
- **El catálogo de formas se publica en `/recursos/catalogo-metrico`**, generado
  del dato: cada forma con sus arquitecturas, esquemas, secciones, rasgos, denominaciones y
  lo que dicen las fuentes. Nace en `admin_ip` y se abre desde `/dashboard/publicacion`
  cambiando el `scope_minimo` de la sección `formas`. No lleva texto redactado: si algo se
  lee mal, está mal en el catálogo. El listado carga en una sola consulta todos los registros
  activos —39 desde el 22 de agosto de 2026— y los conserva para el filtrado en ejecución; cada
  ficha usa otra consulta agregada que mantiene los identificadores y la jerarquía padre-hijo de
  sus secciones.
- El editor V2 escribe únicamente en tablas `*_editor_metrico`. No crea obras, no modifica
  las secuencias reales y no alimenta fichas, buscadores ni resúmenes públicos.
- La anotación en sombra se retiró. El editor métrico nuevo vive ya en las secuencias de cada obra;
  el catálogo se carga allí y las propuestas del vocabulario legado se piden bajo demanda.
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
soneto y romance— están cubiertas en `grid-rows.test.ts`. **Falta probarla en pantalla
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
`anotacion_elecciones` son `on delete restrict`, así que la base impide sola borrar lo que
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

## El camino a develop lista para la ola de editores

**Recorrido entre el 26 y el 28 de agosto de 2026.** El editor V2 es ya el que ven los editores al
abrir cualquier obra: sustituyó al panel lateral, las tablas de la anotación se renombraron, el
catálogo se abrió a todos los roles y el guardado pide permiso sobre la obra. **Los doce pasos están
en `git`**; lo que quedó vivo de aquel plan es esto:

- **Todas las obras se anotan con el catálogo nuevo.** No hay interruptor por obra: el que había
  —`obras_anotacion_nueva`— dejó de gobernar nada y solo sobrevive hasta que se migre lo anotado.
- **El editor V2 escribe únicamente en tablas `anotacion_*`.** No toca `secuencias_metricas.estrofa_tipo_id`,
  ni fichas, ni buscadores, ni resúmenes. Esa frontera no se adelanta.
- **Crear una secuencia la guarda ya**, con el rango y `estrofa_tipo_id` en nulo; a partir de ahí cada
  parte guarda por su lado.
- **Lo que falta antes de fusionar** está abajo, en [lo que va a `main`](#lo-que-va-a-main-no-aquí) y
  en [lo que queda para después](#lo-que-queda-para-después-de-fusionar).

### El replanteo de la migración, 27 de agosto de 2026

La anotación en sombra se retiró. El instrumento es **el informe por obra**
—`npm run migracion:informe`—, que vuelca cada secuencia con todos sus datos, y la migración se hace
**a mano con los editores**, obra por obra. Todas las obras abren ya con el editor nuevo, y al abrir
una secuencia heredada se ve en una línea de dónde viene: *sistema antiguo: tal · propuesta nueva:
tal*, que no rellena nada.


### Lo que sale de recorrer el formulario

*Se abre el 26 de agosto de 2026.* Cada entrada dice a cuántas formas alcanza y en qué capa está el
arreglo, comprobado contra la base antes de proponer nada.

**Cómo se recorre, acordado el 27 de agosto.** El editor pinta desde reglas genéricas, así que casi
nada de lo que se vea es «de esta forma»: lo que parece que a una le sobra suele ser que la regla
está mal planteada, y eso **solo se distingue después de tres o cuatro formas**. Así que:

- **Los fallos se arreglan según aparecen** —un número mal, algo que no guarda—, porque dejarlos
  ensucia el resto del recorrido.
- **Lo demás se recoge y no se toca**, y se decide cuando el mismo asunto aparezca por segunda o
  tercera vez. Arreglarlo con una sola forma delante acierta para esa y desajusta las otras cuarenta.
- Y se separa aparte **lo que es hueco del modelo**, que necesita decisión del IP.

**El registro va en tabla**, no en prosa, para poder cruzarlo: lo que interesa al final no es la queja
de una forma, sino **qué formas se comportan igual de cara al editor**. `Capa` dice dónde está el
arreglo; `alcance` está contado contra la base, no estimado.

| # | forma · arquitectura | síntoma | capa | causa | alcance | estado |
|---|---|---|---|---|---|---|
| F1 | todas | el rango admitía final anterior al inicial, y la pantalla razonaba sobre él | UI | sin `min` ni acotado | 41 formas | **arreglado** |
| F2 | canción · regular y variables | el remate no declara metro ni rima, y no pregunta nada | catálogo | sección opcional sin esquemas ni grupo de elección | 3 secciones (las 3 de la canción, de 11 opcionales del catálogo) | **IP** |
| F3 | canción · regular | «39 de 2 versos» se lee como número al revés | UI · redacción | la fórmula «X de Y» | 41 formas | **arreglado** |
| F4 | canción · regular | el recuadro debería llamarse «características esperadas» y ser desplegable | UI | — | 41 formas | recogido |
| F5 | canción · regular **y quintilla** | la norma dice en prosa lo que ya está dibujado o se ofrece debajo: sobran «partes fijas», «medida fija» y «rima fija», y en la quintilla **el párrafo de rima entero**, porque las ocho tipologías se eligen en la pregunta y lo que no esté se escribe con la salida abierta | UI | — | 41 formas | recogido, **2.ª vez** |
| F6 | canción · regular **y** variables | demasiada letra por parte en la rejilla; «patrón fijo» a secas; sobra «rango calculado desde sus partes»; la unidad modelo debería pintarse una vez y las demás decir solo vv. | UI · rejilla | — | 41 formas | **2.ª vez → maduro** |
| F7 | canción · variables | cinco renglones «Estructura» seguidos y «1 Primeros pies» | UI | `variableSectionFacts` recorría las hijas en plano | 9 arquitecturas de 5 formas; 14 secciones hijas; plural roto en 8 casos | **arreglado** |
| F8 | canción · sin rima | el pareado final no pinta su `aa` | UI · rejilla | `metricNormGrid` toma solo secciones madre; aquí los esquemas cuelgan de las hijas y la estancia no lleva ninguno | **1 caso en todo el catálogo**: es la única sección hija con posiciones de rima | pendiente |
| F9 | canción · sin rima | el `aa` del pareado no se guarda en la anotación | modelo | no hay grupo de elección de rima: el `aa` es norma del catálogo, no respuesta | 5 arquitecturas activas sin grupo de rima | con **B8** |
| F10 | canción · sin rima | la medida verso a verso y el nº de versos del cuerpo son el mismo control, y los versos se van sumando | catálogo | grupo `medida_estancia`, `alcance: unidad`, 5–20 selecciones; la estancia tiene extensión abierta y no hay pregunta de longitud | 1 arquitectura | recogido |
| F11 | copla castellana · octosilábica | «Medida: base de 8, quebrados 4 y 5» y debajo «Medida fija: 8» | UI | **un solo esquema leído dos veces**: `roleBasedMetreSummary` por roles y `fixedMetreSummary` por posiciones | 10 arquitecturas de 8 formas, todas iguales: base 8, quebrados 4 y 5, 1 posición | **arreglado** |
| F12 | copla castellana | con 2 coplas, responder «en conjunto» deja las dos abiertas y editables a la vez | UI | **era una copia, no un modo**: el panel escribía la misma respuesta en cada unidad y se cerraba | 77 preguntas en 51 arquitecturas, **28 de 41 formas** | **arreglado** |
| F13 | copla castellana, novena-lira **y octava-lira** | al elegir la rima no se ve desplegada verso a verso, en vertical, junto a cada verso, y queda lejos de donde se resume cada parte | UI | — | toda forma con grupo de rima | **4.ª vez → maduro**, va con **F6** |
| F21 | copla manriqueña · de pie quebrado | hay que poder decir si los quebrados son de 4 o de 5, y no se pregunta | **catálogo** | el esquema **ya declaraba la alternativa** —posiciones 3, 6, 9 y 12— pero la arquitectura no tenía grupo de metro | 2 arquitecturas: copla manriqueña (4 posiciones) y sextilla de pie quebrado (2) | **arreglado** |
| F22 | copla manriqueña · de pie quebrado | pregunta el esquema de rima, que estaba marcado **definitorio** | **catálogo** | la marca era la equivocada, no la pregunta | 1 arquitectura | **arreglado** |
| F26 | endecha real · heptasilábica de cinco versos | pregunta las **vocales de la asonancia** en una arquitectura cuya rima es **solo consonante**, y además es obligatoria | **catálogo** | el grupo `vocales_asonancia` está puesto donde no hay asonancia que describir | 1 arquitectura (de 10 que lo preguntan; las otras 9 son correctas) | **migración, sin aprobar** |
| F27 | endecha real · heptasilábica con endecasílabo final | pregunta la asonancia **elijas la rima que elijas**, incluidas «cruzada consonante» y «versos sueltos» | **modelo** | **no hay preguntas condicionales**: `grupos_eleccion_metrica` no tiene ninguna columna que haga depender una pregunta de otra respuesta | 1 arquitectura lo sufre hoy, pero **12 mezclan disposiciones asonantes y no asonantes**, y son las mismas que impiden dar la pregunta a las 18 arquitecturas con rima asonante que hoy no anotan en qué vocales asuena | **IP** |
| F23 | endecasílabo suelto | los seleccionables se presentan como cinco preguntas seguidas, cada una con su caja, sus radios y una descripción larga | UI | ninguna jerarquía entre ellas; en esta forma **son la única manera de caracterizar la realización** y merecen otro tratamiento | toda forma cuya caracterización va por rasgos | recogido |
| F24 | endecasílabo suelto | los textos de ayuda son de fuente, no de uso: «Morley y Bruerton cuentan un pasaje como suelto por debajo de ese umbral» | catálogo · prosa | las descripciones dicen de dónde sale el criterio, no qué mirar en el pasaje | los grupos con `ayuda_editor` y las opciones con `descripcion` | recogido, **2.ª vez** (octava real) |
| F25 | endecasílabo suelto | la norma decía «Densidad de rima: Ninguna; obligatorio» y la pregunta ofrecía **Ninguna y Esporádica** | catálogo | el valor «Ninguna» estaba marcado `definitoria`, y lo obligatorio es **el rasgo**, no el valor | 1 arquitectura, y la garantía se extiende a todos los rasgos | **arreglado** |
| F20 | copla castellana | la estructura de dos redondillas debería verse **donde se declara la medida**, más visualmente | UI · rejilla | — | toda forma con partes dentro de la unidad | recogido, va con **F6** |
| F14 | copla castellana | marcar quebrado pinta lo que ocupa el pie antes de saber cuánto mide | UI | se dibuja la extensión sin esperar a la medida elegida | las 10 de F11 | recogido |
| F15 | copla castellana | el resumen de «aplicar a todas» —«coincide con las demás unidades»— se entiende fatal | UI | consecuencia de F12: lo que coincidía seguía pintando campo, con esa nota repetida por unidad | los mismos 77 grupos | **arreglado con F12** |
| — | copla castellana | «rango calculado desde sus partes» | — | *es F6, segunda repetición del mismo mensaje* | — | ya en F6 |
| F16 | copla castellana, copla real, novena, oncena, quintilla, redondilla **y septilla** | el quebrado es **rasgo opcional**, no medida esperada: ponerlo bajo «Medida» hace creer que hay que encontrarlo; la definición de la copla real lo dice, «el quiebro, cuando lo hay» | **catálogo** | el rasgo `pie_quebrado` **ya está declarado** en las 10 arquitecturas —`admitida` en 8, `habitual` en las dos oncenas— pero **no tiene ningún valor** en `rasgo_valores`, así que no puede preguntarse ni salir en la norma; lo que se pregunta es `posiciones_pie_quebrado`, de dimensión `metro` | 10 arquitecturas de 8 formas (las mismas de F11) | **7.ª vez → maduro**; migración sin aprobar |
| F17 | todas las de rima | «¿Rima de otra manera?» se muestra siempre. Debe ser **una opción más del desplegable**; y donde el repertorio esté cerrado, **no salir en absoluto** | UI · y catálogo para lo segundo | `tipo_control: opciones_y_esquema` pinta las opciones **y** el campo libre a la vez. Qué repertorios están cerrados no lo decide la interfaz: es la cuestión que ya está planteada al IP | 41 grupos en 37 arquitecturas | **11.ª vez**, la más repetida del recorrido; en el villancico se ve en su peor versión: bajo un desplegable de tres disposiciones van dos renglones de instrucciones, un campo libre y el selector de régimen |
| F19 | copla de arte mayor | no hay «añadir otra copla»: las unidades aparecen al alargar el rango | — | **no es fallo**: `countFromRange` se activa cuando la unidad tiene extensión fija, y eso es la mayoría del catálogo | **65 arquitecturas de 30 formas** derivan del rango; solo 3 formas se añaden a mano (canción, villancico, zéjel) | **cerrado** |
| F18 | todas las de rima | esquema predefinido **con desviación** y esquema escrito a mano se ofrecen como si fueran lo mismo | modelo · UI | no hay nada que distinga los dos caminos ni que avise de que lo escrito se parece a un esquema ya existente | los mismos 37 | recogido, va con **F17** |
| F36 | las cuatro liras abiertas | **preguntan su rima de tres maneras distintas**, habiéndose creado el mismo día como una sola serie | **catálogo** | cuarteto-lira y octava-lira: repertorio de 2 y salida abierta, **obligatoria**. Décima-lira: repertorio de 1 y salida abierta, **opcional**. Novena-lira: **sin repertorio**, solo campo escrito —y esa sí está justificada, porque su único esquema es «Distribución variable», de secuencia `abierta`, y la función de opciones no ofrece las abiertas— | 4 arquitecturas de 4 formas | **arreglado**: las cuatro con repertorio —el que haya—, salida abierta y respuesta obligatoria |
| F67 | canción petrarquista · las 2 con `define_norma` | **guardar reventaba** con «column eleccion.opcion_eleccion_id does not exist» | **SQL** | `guardar_anotacion_metrica` construye la firma de las preguntas que declaran la norma con una columna que **no existe** en `anotacion_elecciones`: la añade la vista `anotacion_elecciones_resueltas`. El cuerpo entrecomillado no se revalida, así que compilaba, `db push` pasaba y las pruebas también; solo falla al ejecutarse, y solo donde hay `define_norma` | 3 preguntas en 2 arquitecturas de 1 forma | **arreglado** |
| F66 | villancico · estribillo inicial | la medida se pregunta **parte por parte** —cabeza, mudanza, y enlace y vuelta si se añaden—, todas con el mismo hexasílabo/octosílabo, y en un villancico de cuatro ciclos son muchas veces la misma pregunta | UI | la zona común de medida excluye a propósito las composiciones que crecen por ciclos: «mezclar composición, sección y ciclo confundía más de lo que ahorraba». *La decisión se quedó corta* | villancico ×2 y zéjel | recogido, va con **F46** |
| F65 | villancico y zéjel | **se abren en error**: una secuencia nueva de 2 versos monta ya una estructura de 6 y avisa «estructura 6 · rango 2 — sobran 4», antes de tocar nada | UI | la arquitectura materializa su ciclo mínimo al elegirla, y el rango recién creado no le llega | las 3 que crecen por ciclos | recogido |
| F64 | villancico · estribillo inicial | la repetición del estribillo se declaraba **opcional** y la pregunta que la materializa es **obligatoria y sin respuesta negativa** —«se repite entero» o «solo en parte»—: un ciclo sin repetición no se podía ni declarar ni guardar | **catálogo** | **las dos arquitecturas de la forma se contradecían**: en «Estribillo tras la primera copla» la sección homóloga ya era `1-1`. El estribillo no puede faltar —es lo que define un villancico— y lo que varía es cuánto vuelve | 1 arquitectura; el zéjel declara lo mismo y queda aparte | **arreglado** |
| F63 | versificación irregular y verso aislado | **no se les puede preguntar nada**, y lo único que se registra de ellas es una observación en texto libre | **modelo** | `grupos_eleccion_metrica.arquitectura_id` es **NOT NULL** y las dos son `sin_forma`: no tienen arquitectura, así que no hay dónde colgar una pregunta. No es que falten, es que el modelo no las sostiene | 2 tramos sin forma, y **9 secuencias ya anotadas con 197 versos** que pierden lo suyo al migrar | pendiente de decidir, abajo |
| F62 | terceto encadenado · las dos | **no se puede decir si lleva serventesio final**, que el catálogo declara opcional —`repeticiones 0-1`, 4 versos— | UI · modelo | `metricUnitPlan` devuelve `null` cuando el nivel es `serie`, así que `hasStructuredEditor` es falso y **el editor de estructura no se pinta**, aunque la arquitectura declare secciones. La regla de longitud sí lo sabe —`desplazamientos [0, 4]`, «bloques completos de 3 versos, con un cierre opcional de 4»— de modo que el rango valida con o sin él y nada registra cuál | **2 arquitecturas** con sección opcional sin respuesta; y **4 series** declaran secciones que no se ven: las dos del terceto encadenado, la septilla y la sextilla enlazadas y la silva consonante regular | **arreglado sin preguntarlo**: el rango ya lo decide, así que se le pone nombre. Lo de ver la estructura de una serie sigue abierto, con **F46** |
| F61 | todas | **la descripción de la arquitectura no se lee en ninguna parte**: elegir arquitectura es elegir un nombre. En la silva son cinco nombres, y dos se distinguen por un rasgo que la norma fija y por tanto no se pregunta | UI | el selector solo pinta `nombre`. Se le puso el texto en el `title` de cada opción, que no ocupa sitio, pero **dónde debe leerse de verdad se decide con la norma**: David apuntó que su sitio parece la zona de norma y no el selector. *Y son dos necesidades distintas: para **elegir** hace falta antes de escoger; para **entender lo escogido**, después* | 41 formas; solo la silva lo necesita de verdad | recogido, va con **F46** |
| F60 | silva · las tres abiertas | «Medida: **versos de 7 y 11 sílabas**» se lee como si fuera una pauta —7-11, o quizá 11-7— cuando lo que declara es un **repertorio sin orden** | UI · redacción | la frase no dice que las medidas se mezclen libremente, y la rejilla dibuja el ciclo de rima de dos versos al lado, que refuerza la lectura de pareja. La prosa del catálogo sí lo dice: la arromanzada rima «sobre la **mezcla libre** de siete y once» | las 3 silvas abiertas, y toda arquitectura con repertorio métrico sin posiciones | recogido, va con **F46** |
| F59 | silva · endecasilábica | **la única pregunta de pareados del catálogo obliga a elegir entre dos grados que su prosa no separa**: «Habituales — los pareados son frecuentes, aunque no obligatorios» y «Predominantes — los pareados organizan predominantemente la serie» | catálogo · prosa | *no es una duda abierta*: el 28 de agosto de 2026 se decidió **no cuantificar los grados**, y la cuestión se retiró del documento del IP. Lo que queda es que la descripción es el único criterio que el editor tiene, y con estas dos no basta | 1 arquitectura, y la pregunta es obligatoria | pendiente, va con **F24** |
| F58 | sextina · las tres composiciones | «la secuencia, unidad por unidad» dice **solo «Sextina vv. 1-39»**, que es lo que ya pone la cabecera: ni es verso a verso ni pinta la estructura | UI | son composiciones que la norma fija enteras y que no preguntan nada, así que el listado no tiene nada que añadir. *Y quizá no haga falta que lo tenga: la estructura ya está en la norma de la arquitectura* | las composiciones de extensión fija | recogido, va con **F46** |
| F57 | sextina · estrofa | **se puede elegir suelta**, y su definición dice que no se usa así: «fuera de ella la estrofa no se usa sola» | catálogo · modelo | nada impide elegir en el selector una forma que solo existe dentro de otra. Es **la única** del catálogo cuya definición lo dice, pero el modelo no sabe expresarlo | 1 forma hoy | **pendiente de decidir** |
| F56 | sextilla · de pie quebrado | **la disposición en columnas queda rara** cuando una unidad lleva varias preguntas: se lee «Sextilla | Esquema de rima | Medida de los quebrados» en fila, como si fueran columnas de una tabla y no la pregunta de una estrofa | UI | — | toda unidad con más de una pregunta | recogido, va con **F46** |
| F55 | sextilla · de pie quebrado | ofrecía **una sola disposición de rima**, `abcabc`, y las fuentes nombran tres | **catálogo** | el *Diccionario* la describe «con disposiciones `aabaab`, `aabccb` o `abcabc`», y Navarro Tomás llama a `abc:abc` «la más usual» y advierte que «el orden de las rimas varía de una composición a otra». No entra `ababab`, que las fuentes dan para la sextilla de octosílabos plenos | 1 arquitectura | **arreglado**: `abcabc` sigue habitual y entran las otras dos como admitidas |
| F53 | sexteto-lira · heterométrica consonante | la rejilla dibuja **las tres disposiciones de rima y un solo esquema métrico**, teniendo seis, cuando las variedades son combinaciones de ambos | UI · rejilla | `construirRejilla` toma el métrico con `find(esquema => !esquema.seccion)`: **el primero que encuentre**, en silencio. Es la única arquitectura del catálogo con más de un esquema métrico de unidad, así que hasta ahora no se notaba | 1 arquitectura | recogido, va con **F46** |
| F52 | sexteto-lira · heterométrica consonante | elegir una variedad **no cambiaba nada** en la anotación de la unidad | UI | el resumen solo leía preguntas de `metro` y de `rima`, y esta es de `combinacion`. Una variedad **reúne un esquema de rima y uno métrico**, así que responderla dice las dos cosas | 1 arquitectura hoy; toda pregunta de variedad | **arreglado** |
| F51 | septeto-lira · heterométrica consonante | declara `ababbcc` como **habitual** y **no lo preguntaba**: se daba por hecho que el pasaje rima así, sin confirmarlo ni poder decir otra cosa | **catálogo** | de las arquitecturas activas sin pregunta de rima era la única en ese caso: el endecasílabo suelto y las dos silvas declaran esquemas `abierta` sin posiciones —no hay disposición que ofrecer— y el sexteto-lira elige su rima por la variedad | 1 arquitectura | **arreglado**: repertorio y salida abierta, como la décima-lira |
| F50 | septeto · endecasilábica, y los 8 grupos de esquema abierto | **lo escrito se guarda tal cual**, y la convención de caja solo se aplica al pintar el resumen: escribir `abab` en una forma de endecasílabos guarda `abab` y enseña `ABAB` | modelo · UI | `compactRhymeNotation` solo quita espacios, y su comentario lo dice a propósito —«la caja de las letras también codifica la medida»—. Donde hay repertorio no importa, porque `canonizar` compara **sin distinguir caja** y lo guarda como la disposición catalogada; donde no lo hay, dos anotaciones de lo mismo quedan escritas distinto | los 8 grupos sin repertorio, en 5 formas | **arreglado**: se normaliza al guardar con la medida de cada verso, la misma que usa el resumen |
| F49 | septeto · endecasilábica y compuesta, **y soneto** | el marcador del campo abierto dice `aBaBcC` en una forma **de endecasílabos**, donde la convención pide todo mayúsculas; y en la redondilla, de cuatro versos, dice `abcabc`, que son seis | UI | es un literal fijo del componente, igual para todas las formas; la medida de la unidad ya se conoce y podría escribirlo bien | los 8 grupos de esquema abierto y los 39 mixtos | recogido |
| F48 | seguidilla · compuesta, chamberga y gitana | la anotación verso a verso **se saltaba los versos sueltos**: la compuesta salía «a a b b» en vez de «- a - a b - b» | UI | el resumen solo escribía las posiciones con clase de rima, y las sueltas —que el catálogo marca con `suelto` y escribe con raya en `-a-ab-b`— se caían | toda forma con versos sueltos en su esquema | **arreglado** |
| F47 | seguidilla · gitana, y las 6 de F44 | dos rótulos que decían lo que no es: «Medida de cada verso» cuando **solo se pregunta uno**, y «Medida de cada verso» donde antes decía «Medida de los quebrados» | catálogo · SQL | la vista decidía el rótulo con `bool_and(rol = 'quebrado')`, que dejó de cumplirse al declarar las posiciones —ahora ofrecen también el octosílabo, que es la respuesta de que ahí no hay quiebro—; y no distinguía una pregunta de una sola posición | 12 preguntas de quiebro y 1 de verso único | **arreglado** |
| F54 | todas | **el plegado unidad por unidad no funciona bien**; se revisa con el recorrido terminado | UI | — | 41 formas | recogido, va con **F46** |
| F46 | todas | **la «Norma de la arquitectura» hay que rehacerla entera**: más sencilla y mejor organizada. No es una queja de una forma, es el recuadro | UI | se ha ido llenando renglón a renglón —extensión, partes, medida, rima, rasgos, restricciones— sin que nadie decida qué merece estar arriba, qué se lee mejor dibujado y qué sobra porque se responde debajo | 41 formas | **pendiente**, se decide de una vez con **F4, F5, F6, F13, F20, F23 y F32** |
| F45 | redondilla, y las 15 que declaran el rasgo | el quiebro se afirmaba **bajo «Medida»** —«base de 8; los pies quebrados pueden medir 4 y 5»—, y ahí se lee como parte de cómo mide la estrofa. En una redondilla es raro: teóricamente es base de 8 con admitidos de menos, y en la práctica es de 8 y ya | UI | la medida decía cuánto miden y callaba el grado; y el rasgo no subía a la norma, porque uno `admitida` sin límite de posiciones se considera dato de la realización. Ahora la medida dice la base, y el quiebro va a su renglón con su grado y sus medidas | las 15 arquitecturas que declaran `pie_quebrado`, en sus tres grados | **arreglado** |
| F44 | quintilla, septilla, las dos novenas y las dos oncenas | la nota **nombra el verso del quiebro** y el editor lo pregunta en todos | **catálogo** | hay dos mecanismos y estas están en el que no restringe: con `medida_uniforme = false` la derivación enumera `generate_series(1, unidad_versos_max)` y ofrece el quebrado en cada verso; con `medida_uniforme = null` y posiciones declaradas —manriqueña, sextilla de pie quebrado y las tres enlazadas— solo se ofrece donde se declara | **6 arquitecturas declaran ahora dónde cae el quiebro** —quintilla, septilla, novena 4+5, las dos oncenas y la copla castellana— y **1 dejó de admitirlo**, la novena 5+4, cuyo quiebro no lo documenta ninguna fuente. Quedan 3 preguntando en todos los versos, y su fuente lo justifica: copla real, redondilla y copla de arte menor | **arreglado** |
| F43 | quintilla · octosilábica consonante | las ocho tipologías salían en el desplegable **desordenadas**: 4, 5, 3, 1, 7, 6, 2, 8 | catálogo · SQL | `opciones_eleccion_derivadas()` las ordenaba por notación —`aabab`, `aabba`, `abaab`…— y el número de la tipología, que es como se nombran y como las cita la bibliografía, no contaba | toda forma cuyas disposiciones llevan nombre; las que no lo llevan no se mueven | **arreglado** |
| F42 | pareado · alirado | **más de dos versos lo convierte en serie**, y una tirada de pareados alirados es en realidad una silva. Habría que avisarlo o impedirlo | **modelo** | la regla de longitud dice `unidades completas de 2 versos` y nada limita **cuántas** unidades caben en una secuencia; el modelo no sabe decir «esta arquitectura no se repite» | 1 arquitectura hoy; la pregunta —qué formas no admiten repetirse— alcanza a las 41 | **IP** |
| F41 | pareado · de cualquier medida | la elección de medida **se salía de pantalla** | UI | ofrece **nueve alternativas por verso**, 18 opciones en 2 posiciones, y la fila de botones no envolvía. Las formas vistas hasta aquí ofrecían dos | toda pregunta de medida posicional con repertorio ancho | **arreglado** |
| F40 | las 12 que admiten más de un régimen de rima | **el régimen no se podía preguntar nunca**, y la norma tampoco lo decía: el alirado solo enseñaba «Rima fija: aa», y el de cualquier medida, dos disposiciones llamadas «aa» sin distinguir la asonante | UI | dos huecos con la misma raíz: `rhymeRegimes` leía `domain.vocabularies`, **que no existe** —ni está entre los recursos del dominio ni lo rellena nadie—, y `metricNormGrid` no rellenaba el campo `tipoRima` que `MetricPositionGrid` **ya sabe pintar** y que la ficha pública sí rellena | 12 arquitecturas para el selector; el rótulo, todas las que declaran régimen | **arreglado** |
| F39 | oncena · las dos, y septeto compuesto | **la rima heredada no se puede guardar**: el servidor la rechaza | **modelo** | la herencia por reutilización vive **solo en el cliente**. El grupo que inventa conserva el `grupo_eleccion_id` del prestamista, y `validar_anotacion_eleccion` lo busca con `and arquitectura_id = <la de la secuencia>`: no lo encuentra y da «El grupo de elección no pertenece a la arquitectura seleccionada». `guardar_anotacion_metrica` no lo remapea —no menciona la reutilización en ninguna línea— | **3 arquitecturas de 2 formas**, las mismas de F38 | **arreglado con C20**: la respuesta dejó de apuntar a la pregunta, y las heredadas pasaron a ser filas del catálogo |
| F38 | oncena · las dos, **y septeto compuesto** | **solo preguntaba la rima de la primera parte**: la quintilla si la arquitectura es quintilla + sextilla, y la sextilla si es al revés | UI | las preguntas que una parte hereda de la arquitectura que reutiliza se traían **con el nombre pelado del prestamista**, «Esquema de rima», así que las dos partes se llamaban igual y todo lo que agrupa por nombre las tomaba por una sola. Las copiadas a mano de la copla real y la novena no lo sufrían porque alguien las llamó «Primera quintilla · Esquema de rima» | **3 arquitecturas de 2 formas** —las 2 oncenas y el septeto compuesto—, que son las que heredan en más de una parte, de 9 secciones que heredan en total | **arreglado** |
| F37 | las 21 formas de rima con repertorio y salida | escribir el esquema a mano **no marcaba la pregunta como respondida**: la rejilla la seguía enseñando pendiente | UI | `preguntaRespondida` miraba el texto solo en el control abierto puro | los 39 grupos de `opciones_y_esquema`, en 36 arquitecturas de 21 formas | **arreglado** |
| F35 | octava real · endecasilábica consonante | con más de una unidad, en conjunto **solo dejaba elegir del repertorio**, mientras la ayuda decía «si no, escribe el que veas» | UI | F31 abrió el camino escrito solo al esquema abierto puro; el de repertorio con salida seguía pintándose únicamente con sus opciones | **39 grupos en 36 arquitecturas de 21 formas**, que son todas las de `opciones_y_esquema` | **arreglado** |
| F34 | octava real · endecasilábica consonante | preguntaba el **dístico final** siempre, y no aportaba por ninguno de los dos caminos: el esquema `ABABABCC` ya lo lleva, y si se escribe el esquema a mano la notación lo enseña | **catálogo** | se retira **la pregunta, no la declaración**: `arquitectura_rasgos` conserva «Presente · habitual», que es de donde salen la norma y la ficha pública. El endecasílabo suelto conserva la suya, porque allí no hay notación de la que deducirlo | 1 arquitectura | **arreglado** |
| F33 | octava aguda, seguidilla, terceto, pareado, villancico | tienen disposición asonante y **no preguntan en qué vocales asuena** | catálogo | **9 de 27 arquitecturas con esquema asonante** lo preguntan; las 18 restantes, no. El final agudo, que sí es obligatorio, va marcado y no se pregunta: eso está bien | 18 arquitecturas de 5 formas | **decidido el 29 de agosto: se anota en todas.** Migración pendiente, abajo |
| F32 | novena-lira **y octava-lira** | la primera columna de la rejilla de medidas lleva solo «Verso 3» y ocupa una banda entera; quizá el verso deba ir dentro de la barra | UI · rejilla | — | toda pregunta de medida verso a verso | recogido, **2.ª vez**, va con **F6** |
| F31 | novena-lira · heterométrica consonante | con más de una unidad, el esquema de rima se preguntaba **por novena** y no en conjunto | UI | `preguntasCompartidas` excluía `tipo_control = 'esquema_rima'` sin decir por qué: el control común hablaba en slugs y el esquema abierto es texto | **8 arquitecturas de 5 formas**: novena-lira, septeto, sexteto dodecasilábico, las 4 sextillas y las estancias variables de la canción | **arreglado** |
| F30 | novena-lira · heterométrica consonante | con más de una unidad, la medida se preguntaba con **un desplegable por verso** en vez de con las barras | UI | `MetricFamilyControl` y `MetricChoiceField` habían divergido justo en lo que el primero existe para evitar: la misma pregunta, dos dibujos | las 34 preguntas de metro que admiten respuesta común, en 26 arquitecturas de 21 formas | **arreglado** |
| F29 | novena, seguidilla gitana, septilla y las 6 de F44 | la medida se pedía con un **desplegable con una unidad** y con las barras con dos, **la misma pregunta con dos controles** | UI | `MetricChoiceField` miraba `maximum === 1` **antes** que las ramas posicionales, y el control común no: con una unidad la pregunta no entra en el atajo y caía en el desplegable. Es la divergencia que estos dos componentes existen para evitar | 7 arquitecturas | **arreglado**: las ramas posicionales van primero, y el campo recibe además **lo que la norma fija en cada verso**, que antes solo sabía deducir del rol `dominante` —la gitana no lo tiene y sus tres versos fijos decían «sin medidas disponibles»— |
| F28 | lira · heptasilábica y endecasilábica | la cabecera decía «2 unidades de 5 versos» y el cuerpo, «2 ciclos de 5 versos» | UI · redacción | la caja del pasaje escribía «ciclos» a secas, cuando `arquitecturas_reglas_longitud.origen` distingue cinco casos y su propia `explicacion` los nombra distinto —«unidades», «ciclos de rima», «ciclos métricos», «estructuras», «bloques»— | **81 reglas de 37 formas**: 65 cuentan unidades, 10 ciclos de rima, 3 bloques, 2 estructuras y 1 ciclo métrico. La palabra estaba mal en las **71 que no son ciclos de rima** | **arreglado** |

**Lo arreglado no se cuenta aquí.** La tabla dice qué era y a cuánto alcanzaba; el porqué de cada
arreglo está en su commit, que es donde no se queda viejo. Lo que sigue es **solo lo que aún no se ha
tocado** y necesita algo más que una fila.

**F33 · La asonancia se anota siempre que la haya.** Decidido el 29 de agosto de 2026, y **no se
migra suelto**: se hace de una vez cuando se resuelva el bloque de la rima, porque la mitad de los
casos depende de que una pregunta pueda condicionarse a otra (**C1 · F27**).

*Lo que ya está comprobado y no hay que volver a averiguar:*

- **No hay que duplicar nada.** `vocales_asonancia` es **un solo rasgo** con sus 19 valores, y las 10
  arquitecturas que hoy preguntan apuntan todas al mismo `rasgo_id`. Añadirlo en otra son dos filas:
  una en `grupos_eleccion_metrica` y otra en `arquitectura_rasgos`.
- **El modelo ya sabe ofrecer un subconjunto.** La rama de rasgo de `opciones_eleccion_derivadas()`
  filtra `and (ar.valor_id is null or ar.valor_id = rv.valor_id)`: con `valor_id` en nulo ofrece los
  19 —así lo declara el romance, modalidad `admitida`—, y con una fila por valor admitido, solo esos.
- **Las nuevas filas van `admitida`**, nunca `definitoria`: el disparador
  `definitoria_no_se_ofrece()` rechaza una definitoria que se ofrezca como opción.

*Y lo que hay que hacer, en dos bloques:*

| bloque | arquitecturas | qué |
|---|---|---|
| **se puede sin nada más** | **7**: las siete seguidillas —simple, compuesta, real, gitana, chamberga, de tres versos y simple arromanzada— | todos sus esquemas son asonantes, como el romance: pregunta obligatoria y los 19 valores |
| **espera a C1** | **11**: octava aguda (6), villancico (2), terceto (2), pareado (1) | admiten asonante **y** consonante, así que la pregunta saldría también a quien eligió la consonante. Es el fallo de la endecha real |

*Dos precisiones del contenido:*

- **En la octava aguda solo van cuatro valores.** Es la única forma del catálogo que fija
  `final_acentual = Agudo`, y **definitorio** en sus seis arquitecturas. Una asonancia aguda es de
  **una sola vocal**, así que de los 19 solo aplican `a`, `e`, `i` y `o`; los otros quince son pares
  y describen asonancias llanas.
- **Falta el valor `u`.** *Virtud*, *salud*, *alud* asuenan en **ú** y no hay dónde decirlo. En el
  romance casi no se nota porque su asonancia suele ser llana; en la octava aguda, donde toda
  asonancia es aguda, falta una de las cinco vocales posibles. **Decidido añadirlo**, en la misma
  migración.

**F39 · La herencia por reutilización no llega al servidor.** Salió el 29 de agosto de 2026 al
preguntarse por qué la copla real y la novena **copian a mano** una pregunta que podrían heredar.

*La respuesta a eso es histórica y está bien:* el 31 de julio, el defecto D8 retiró los dieciséis
esquemas duplicados y ancló las preguntas a su sección, porque **entonces ese anclaje era el
mecanismo** —«es lo que autoriza a la opción a señalar un esquema de otra arquitectura»—. La
herencia automática, que se inventa el grupo sin que exista fila, llegó el **25 de agosto**, casi un
mes después, cuando la oncena y el septeto compuesto la necesitaron por no tener ninguna.

*Y al comprobar si las seis copias se podían borrar apareció lo otro:* **nadie enseñó al servidor
qué es heredar.** Ejecutada contra la base la primera comprobación del disparador —buscar el grupo
en la arquitectura de la secuencia— **las seis preguntas heredadas dan cero**. Así que la oncena y
el septeto compuesto no pueden guardar su rima, y **borrar las seis copias las dejaría igual**.

*Lo comprobado, para no repetirlo:*

- Las copias son idénticas a lo que se heredaría —repertorio, control y selecciones—, y **el
  repertorio no puede separarse**: la rama de rima de `opciones_eleccion_derivadas()` resuelve los
  esquemas con `coalesce(s.arquitectura_referenciada_id, a.arquitectura_id)`, así que un grupo
  anclado a una parte que reutiliza la quintilla ya deriva los esquemas de la quintilla. Lo que sí
  puede separarse es lo que vive en la fila: control, selecciones y ayuda.
- **La ficha pública no lee esas filas.** `formas-publicas.ts` tiene su propia `rimaHeredada`, que
  solo mira esquemas; como la copla real y la novena no declaran ninguno, **la ficha ya las trata
  como heredadas**. Las dos superficies llevan tiempo diciendo cosas distintas, y la regla que
  `reutilizacion.ts` dice guardar «una sola vez» está en realidad escrita dos veces, con condiciones
  que no coinciden: la del editor mira además las preguntas, la de la ficha no.
- Cero respuestas guardadas y cero equivalencias legadas en las seis.

*Los dos caminos:* enseñar al servidor a resolver la herencia —`validar_anotacion_eleccion` acepta
el grupo de la arquitectura que la parte reutiliza, y `seccion_id` se resuelve a la parte que lo
toma prestado—, o **darle filas propias a la oncena y al septeto**, seis en total, como las tiene la
copla real. Lo segundo funciona hoy y no toca ninguna función; lo primero es el mecanismo único.

**F46 · La norma de la arquitectura, entera.** Pedido por David el 29 de agosto de 2026, después de
mover el pie quebrado de «Medida» a su rasgo: *«quiero hacerlo más sencillo después, organizarlo un
poco mejor»*. No se decide forma a forma, y lo que ya está recogido apunta todo al mismo sitio.

**Y ese día quedó dicha la forma que debe tener**, que es lo que le faltaba a todo lo de abajo:

> «Yo lo que quiero es que haya una zona de **qué se va a registrar**. Eso es para mí el resumen:
> tenemos la norma, luego las elecciones, y al final qué se va a registrar sumando la norma más las
> elecciones.»

*Con eso el listado de abajo deja de ser «la secuencia, unidad por unidad» —que en una composición
fija no tiene nada que añadir, **F58**— y pasa a ser la tercera zona: lo que va a quedar guardado.*
La anotación en notación corriente que ya se escribe —`8a 8b 8a 4b | 8c 8d 8c 8d`— es justamente
eso, la suma de las dos primeras, y hoy vive dentro del listado en vez de ser la zona.

Lo que ya está recogido:

| | qué se dijo | dónde salió |
|---|---|---|
| **F4** | debería llamarse «características esperadas» y ser desplegable | canción · regular |
| **F5** | dice en prosa lo que ya está dibujado o se ofrece debajo | canción, quintilla |
| **F6** | demasiada letra por parte; la unidad modelo una vez y las demás solo su rango | canción · regular y variables |
| **F13** | la rima, desplegada verso a verso y en vertical | copla castellana, novena-lira, octava-lira |
| **F20** | la estructura de las partes, donde se declara la medida | copla castellana |
| **F23** | los rasgos, no como cinco preguntas seguidas con su caja y su descripción | endecasílabo suelto |
| **F32** | la primera columna de la rejilla lleva solo el número de verso | novena-lira, octava-lira |
| **F54** | el plegado unidad por unidad no funciona bien | todas |
| **F56** | la disposición en columnas de una unidad con varias preguntas | sextilla de pie quebrado |
| **F58** | qué dice el listado unidad por unidad cuando no hay nada que responder | las tres sextinas |
| **F60** | «versos de 7 y 11 sílabas» se lee como pauta y es repertorio | las tres silvas abiertas |
| **F61** | dónde se lee la descripción de la arquitectura | todas, y la silva la necesita |

**Y lo que se ha ido arreglando por el camino ya dice por dónde va**: la medida se cuenta una sola
vez (**F11**), el régimen de rima se dice una vez arriba o en cada disposición (**F40**), y el pie
quebrado se afirma donde es un rasgo y no donde se mide (**F45**). *Son tres decisiones del mismo
tipo —qué se dice, dónde y una sola vez— tomadas de una en una; el recuadro pide que se tomen
juntas.*

**F63 · Qué habría que preguntar en los dos tramos sin forma.** Revisado el 29 de agosto de 2026 a
petición de David. Hoy no se pregunta nada, y no por descuido: **toda pregunta cuelga de una
arquitectura** —`arquitectura_id` es `NOT NULL`— y estos dos no tienen ninguna, por definición. Lo
único que queda de un pasaje irregular es una observación en texto libre, que no se puede contar.

**Y hay una pérdida medida, no hipotética.** El vocabulario legado distinguía cuatro clases de
irregular, y el corpus las usa:

| término legado | secuencias | versos | ¿tiene equivalencia? |
|---|---|---|---|
| `irregular_mixto` | 6 | 147 | **no** |
| `irregular_arte_menor` | 1 | 37 | **no** |
| `irregular_arte_mayor` | 1 | 2 | **no** |
| `irregular` | 1 | 11 | **no** |
| `verso suelto` | 0 | 0 | **no** |

De las 26 filas de `equivalencias_respuestas_legadas`, **ninguna es de estas**: todas son del
endecasílabo suelto y una de la silva. Así que migrar esas nueve secuencias hoy **aplanaría las
cuatro clases en una** y la distinción se perdería sin que nadie lo notara.

**Lo que habría que preguntar, y de dónde sale:**

- **Versificación irregular — de qué arte son sus versos**: menor, mayor o mixto. No es una taxonomía
  inventada: es la que el corpus ya tiene anotada, y es el criterio que usa la propia definición
  —«ni el número de sílabas obedece a igualdad o proporción»—. Una sola respuesta, y hace contable
  una categoría cuyo valor es precisamente **poder volver a ella**: es la lista de lo que no se supo
  clasificar.
- **Verso aislado — cuánto mide**, que su definición da por observable —«con medida reconocible»— y
  sin lo cual el dato no sirve para nada; y **de qué clase es**, que la definición enumera: el mote
  con su glosa, y los proverbios, refranes y sentencias que el diálogo intercala.

*Lo que no propongo:* una pregunta de «por qué no se reconoce la forma». Esa taxonomía no está en
ninguna fuente ni en el vocabulario legado, y habría que inventarla.

**Lo que costaría.** Es la decisión de fondo: o `arquitectura_id` deja de ser obligatorio en las
preguntas, o los dos tramos sin forma reciben una arquitectura, que contradice su nombre. *La segunda
es más pequeña y menos honesta; la primera toca la tabla de la que cuelga todo.* Va con **C20**, que
replantea a qué apunta una respuesta.

**F2 · El remate, y las secciones opcionales que no declaran nada.** Contado contra la base, de las
**once secciones opcionales** del catálogo:

| forma | secciones | declaran | preguntan |
|---|---|---|---|
| Terceto encadenado | serventesio y redondilla finales | metro **y** rima | ~~no hace falta~~ **sí hace falta** ⇒ **F62** |
| Villancico y zéjel | enlace, vuelta y repetición (6) | metro sí, rima no | 4 de 6 |
| **Canción petrarquista** | **remate ×2 y eslabón** | **ninguno** | **no** |

El remate de la regular admite **de 1 a 13 versos** y no dice nada de cómo son, así que anotarlo no
registra más que su extensión. *Decisión del IP: si debe declarar lo que las fuentes documenten, o
preguntar como las demás.*

**Corregido el 29 de agosto de 2026, y resuelto el mismo día.** La fila del terceto encadenado decía
«no hace falta» porque sus dos secciones opcionales **declaran metro y rima**, que es lo que esta
tabla mide; eso responde a *cómo son* y no a **si están**. Al ir a preguntarlo apareció que **no hace
falta preguntarlo, pero por otra razón**: `3n ≡ 0` y `3n+4 ≡ 1` en módulo 3 son **excluyentes**, así
que ninguna longitud admite las dos lecturas y **el rango decide solo** —cuarenta versos llevan
serventesio, treinta y nueve no—. Lo que faltaba era decirlo: la caja del pasaje decía «y 4 versos
más» y ahora dice «y el serventesio final». ⇒ **F62**

**F6 · La rejilla, madura para decidirse entera.** Va por la tercera aparición y acumula **F5, F8,
F13, F14, F20 y F23**. Lo pedido, junto: que el recuadro se llame «características
esperadas» y sea desplegable; que no repita lo que la figura ya dibuja, porque lo que hay que saber
es **que** algo es fijo, no cuál es —de eso depende elegir entre la regular y la de estancias
variables—; que sobre la letra de al lado de cada parte; que la unidad modelo se pinte una vez y las
demás digan solo sus versos; y que la estructura se vea donde se declara la medida. **Alcanza a las
41 formas y se decide entera, no forma a forma.**

**F8 y F9 · Lo comprobado, para no repetirlo.** El catálogo **sí** declara el pareado de la canción
sin rima —esquema «Pareado consonante final», posiciones 1 y 2, ambas clase `a`—, y «Cuerpo sin rima»
es un esquema con cero posiciones, que es como se dice «no rima». Ninguna de las dos se pinta, y
ninguna se guarda: no hay grupo de rima, así que el `aa` es norma y no respuesta. Toda esa
arquitectura va **sin esquema métrico**, y por eso la medida se pregunta verso a verso.

**F16 · El quebrado es un rasgo, y el rasgo está vacío.** Las diez arquitecturas con quebrados **ya
declaran** `pie_quebrado` —`admitida` en ocho, `habitual` en las dos oncenas—, pero el rasgo **no
tiene ningún valor** en `rasgo_valores`, así que no puede preguntarse ni salir en la norma; lo único
visible es `posiciones_pie_quebrado`, de dimensión `metro`, y de ahí que todo acabe bajo «Medida».
Preguntar primero «¿hay quebrados?» es lo que el rasgo permitiría en cuanto tenga sus dos valores.
*Migración, sin aprobar.*

**F17 y F18 · La misma pantalla.** Escribir un esquema a mano y elegir uno predefinido marcando una
desviación son cosas distintas, y hoy se ofrecen juntas y sin jerarquía. El IP añade que la frontera
la decide el editor, que no pasa nada porque luego se revisen, y que **el comprobador en vivo podría
avisar de que lo escrito se parece mucho a un esquema existente**. Va con **B8** cerrado y con **F9**.

**F26 y F27 · Los dos huecos de la endecha real.** El primero es de dato: la **heptasilábica de cinco
versos** rima solo en consonante y pregunta obligatoriamente las vocales de la asonancia; de las diez
arquitecturas que hacen esa pregunta, las otras nueve son correctas. El segundo es de modelo: la
**heptasilábica con endecasílabo final** admite **tres regímenes** y pregunta la asonancia se elija lo
que se elija. Para callarla haría falta que **una pregunta dependiera de otra respuesta**, y eso no
está en el modelo —`grupos_eleccion_metrica` no declara ninguna dependencia—. Hoy muerde ahí, pero
**12 arquitecturas admiten más de un régimen**. *Es la cara técnica de una pregunta ya abierta en
cuestiones para el IP: «qué elecciones dependen de otras» ⇒ **C1**.*


### Lo que va a `main`, no aquí

La base es **la misma para las dos ramas**, así que un cambio de esquema hecho en `develop` aparece
en producción al instante. Por eso van directamente a `main`, y antes de fusionar:

- Los cambios en los **campos propios de `secuencias_metricas`** —los que no son métricos:
  caracterizaciones, personajes, sinopsis—.
- La **revisión de los vocabularios generales** pendiente, inventariada en
  [revisión de vocabularios](../revision-de-vocabularios.md).

*El IP se plantea cerrar la web una semana para que nadie trabaje mientras se hace todo esto.* Es la
manera limpia de evitar que un editor guarde a mitad de un renombrado o de una apertura de RLS.

### Lo que queda para después de fusionar

Que el perfil métrico, la ficha pública y la precomputación lean el catálogo nuevo. Hoy leen
`estrofa_tipo_id`, así que una obra anotada solo en V2 tendrá **perfil métrico vacío**. No bloquea
anotar; sí bloquea publicar esas obras. Los recomputes usan `left join` y `filter (… is not null)`,
así que **degradan, no rompen**.

## Qué queda pendiente

Inventario rehecho el **21 de agosto de 2026**, al terminar la revisión de la prosa. Lo cerrado ya
no se lista: está en las migraciones, en `git` y en el
[histórico](./historico/). Quedan **veintiún asuntos**, ordenados por lo que bloquea el
próximo hito y no por el orden en que aparecieron.

**Los dos hitos que vienen, en este orden.** *Se invirtió el 26 de agosto de 2026:* lo urgente
dejó de ser migrar lo anotado y pasó a ser que **nadie anote nada más con el vocabulario legado**.

1. **Que el editor V2 sea el que ven los editores** al abrir una obra nueva. El plan está aquí
   abajo, en [El camino a develop](#el-camino-a-develop-lista-para-la-ola-de-editores).
2. **Migrar las secuencias ya anotadas**, por equivalencias más revisión manual obra por obra.
   Marco: [el plan de migración](./plan-migracion-anotaciones.md); procedimiento:
   [cómo se migra una obra](./como-se-migra-una-obra.md); estado de las equivalencias:
   [informe-equivalencias.md](./informe-equivalencias.md), que regenera
   `npm run equivalencias:informe`.

**Nada de lo que sigue impide anotar hoy**, y el catálogo está limpio: `npm run audit:metrica` y
`npm run audit:editor` dan cero defectos, y las pruebas, `npm run check` y `npm run lint` pasan.

**Lo cerrado no se cuenta dos veces.** Estos asuntos están resueltos y su detalle vive en los
commits, en las migraciones y en el [histórico](./historico/); se listan solo para que quien busque
por su número sepa que no siguen abiertos.

| | qué era | cerrado |
|---|---|---|
| **A2, A2bis, A2ter, A3** | los cuatro huecos de cobertura: faltaban formas de siete, ocho, once y doce versos, dos estructuras que salieron leyendo, las dos preguntas del pie quebrado y cinco medidas | 21–22 ago |
| **B1 y B2** | qué pregunta el editor cuando la norma no fija la disposición de rima o la medida. Dejaron **cinco reglas y dos corolarios** en [criterios de nivel](./criterios-de-nivel.md) §§ 3.3 y 3.6, un tercer `tipo_control`, un normalizador de esquemas escritos y un defecto nuevo en cada auditor | 25 ago |
| **B3** | el villancico tras el desdoblamiento de «Enlace o vuelta»: comprobado en pantalla, no estaba roto | 25 ago |
| **B4** | el cierre del terceto encadenado dejó de ser obligatorio y dos superficies lo daban por hecho | 25 ago |
| **B5** | la décima aumentada entre décimas normales, resuelta en la realización | 26 ago |
| **B6** | el control abierto no preguntaba el régimen de rima | 25 ago |
| **B7** | la vuelta del villancico no declaraba su esquema métrico | 25 ago |
| **C6** | la rejilla convertía en ciclo una unidad acotada | 25 ago |
| **C14** | retirada de `formas_metricas.orden`, y el orden del buscador | 25 ago |
| **B8** | las aliradas abiertas no podían registrar el metro que se ve; se les creó la pregunta, y con ella la de los quebrados de la manriqueña y la sextilla | 27 ago |

Quedan **tres asuntos en A**, **ninguno en B** y **dieciséis en C**.

### A · Bloquean la migración de las secuencias

Son los casos en que una secuencia real **no tendría dónde caer**. Conviene resolverlos antes de
empezar, porque cada uno obliga a parar la migración de una obra a la mitad.

**A1. Las equivalencias del vocabulario legado. Cerrada la implementación; queda anotar.** El razonamiento de por qué faltaban y
lo que ya decidió el IP están en
[equivalencias-pendientes.md](./equivalencias-pendientes.md); las cifras, en el informe
regenerable.

**El 24 de agosto de 2026 se revisó el vocabulario legado entero** —los 123 términos, su árbol y
sus campos— y resultó que sabía bastante más de lo que declaraba:
[revision-vocabulario-legado.md](./revision-vocabulario-legado.md). La migración
`20260824090000` declaró diecinueve equivalencias nuevas por `equivalencias_respuestas_legadas`,
sin tocar ninguna reclamación existente, y **las secuencias con propuesta completa pasaron de 128 a
167 de 263**.

**La propuesta habla ya estrofa a estrofa.** La migración `20260824100000` quitó la cláusula que
solo proponía las preguntas de alcance `unidad` cuando la secuencia medía exactamente una estrofa
—y 42 de las preguntas activas son de ese alcance—. La vista da ahora **una fila por estrofa con su
rango de versos**, que es el lenguaje del editor, y trae las **336 tipologías** de
`secuencias_subtipos_estrofa`. La columna `origen` separa lo `anotado` —mirado verso a verso, se
traslada— de lo `derivado`, que hay que revisar. **Las completas pasaron de 167 a 204 de 263.**

*Dos cosas que se aprendieron ahí y conviene no volver a descubrir:* `posicion_unidad` es **el verso
dentro de la estrofa**, no la estrofa —las estrofas son las unidades de
`anotacion_realizaciones`—; y **los rangos de estrofa los pone la anotación, no una división**:
al dividir se perdían 38 tipologías y se borraban una estrofa de cuatro versos y otra de tres que
alguien anotó como tales.

**El informe por obra dice ya qué falta.** `npm run migracion:informe` abre cada obra con «Lo que
hay que completar» y da, secuencia a secuencia, su estado y cuántas respuestas trae anotadas y
cuántas derivadas.

*Lo que queda de A1:*

1. **~~La precarga en el editor V2.~~ Estaba construida, y este inventario lo daba por pendiente.**
   Comprobado en el código el 25 de agosto de 2026: `MetricShadowAnnotation.svelte` ya abre una
   secuencia real sin empezar en blanco. Si la secuencia **se anotó antes**, recupera lo guardado y
   no propone nada; si no, **construye el borrador desde la propuesta** —forma, arquitectura y rango,
   las respuestas de alcance secuencia ya contestadas, y las de alcance unidad guardadas para cuando
   el formulario materialice sus unidades, que en ese momento todavía no existen—. Lo dice el
   comentario de su propia función: *«Abrir una secuencia real no empieza en blanco… El editor revisa,
   no reanota»*. Llegó en tres commits —«La anotación en sombra usa ya el sistema de equivalencias
   entero», «La propuesta llega también con las respuestas, no solo con la forma» y «Si se calcula,
   se rellena: también las respuestas por unidad»— y este apunte no se puso al día.

   **Dónde se revisa ahora:** desde `/dashboard/obras`, al abrir una obra y entrar en su editor
   métrico. La antigua pestaña **«Anotación en sombra»** de `/dashboard/metrica` se retiró junto
   con ese panel.

   *Lo único cierto que quedaba de la nota vieja es que `anotaciones_metricas.secuencia_id`
   **sigue a cero**, y eso no es código que falte: es que nadie ha anotado todavía una secuencia
   real.* **Falta verlo funcionar en pantalla con una obra de verdad**, que es trabajo de editor y no
   de implementación.

*Huecos que ninguna equivalencia arregla*, y que son trabajo de editor con el texto delante: las
**37 secuencias de `redondilla` genérica** —el término no dice la disposición—, las **7 quintillas
sin tipología anotada**, los dos esquemas de las **3 coplas reales** y las vocales de un
romancillo.

*Y un hueco del catálogo nuevo, no de la equivalencia:* el endecasílabo suelto no pregunta por el
final acentual, de modo que `endecasilabo_suelto_de_esdrujulos` no tiene dónde caer. Es el único de
los seis términos de esdrújulos que se quedó sin declarar.

**A4. Las equivalencias de los tres tramos irregulares hay que mirarlas una a una.** Es posible que
alguna sea que quien anotó no encontró la forma precisa, y que con el catálogo nuevo y el
demarcador sí la encuentre. Las que no, tendrán que **registrar exactamente lo que se ve** —medida,
rima y rasgos de todo el pasaje o verso—, que es lo que el editor V2 tendrá que pedir para estas
no formas. *No se modela nada para ellas porque todo vale: cualquier medida, cualquier rima,
cualquier rasgo, sin restricción.*

**A5. La serie alirada, lo que quedó fuera el 24 de agosto de 2026.** Ese día entraron el
cuarteto-lira y la octava-lira —las dos que documenta el *Diccionario*—, la octava variedad del
sexteto-lira y el pareado alirado. Quedan dos cosas, y las dos por la misma razón: **ninguna fuente
las sostiene**.

1. ~~**Novena-lira y décima-lira.**~~ **Hechas el mismo día.** No hacía falta esperar a B1: creí que
   una forma sin disposición documentada tenía que elegir entre una pregunta vacía —defecto— o
   ningún esquema de rima —también defecto, D2b—, y las dos salidas eran falsas. El catálogo ya
   tenía el mecanismo: un **esquema de tipo `abierta`**, sin notación ni posiciones, que declara el
   régimen y deja libre la disposición. Lo usan la quintilla, la silva libre y la sextilla. La
   novena-lira entra así, sin pregunta; la décima-lira con la única disposición de la que hay
   testimonio —`aBaBcDcDeE`, la «décima-estancia» de la edición de *Elisa Dido*— y la pregunta
   **opcional**, para no obligar a elegirla a quien encuentre otra.
2. ~~**La ordenación de la canción de estancias variables.**~~ **Hecha el mismo día.** Declara ya
   fronte en dos piedi, eslabón y sirima, **con horquillas** en vez de medidas fijas, que es lo que
   significa su nombre: lo que se repite sin cambio no son unas medidas sino la articulación. El
   eslabón queda **opcional** ahí, y obligatorio en la regular de trece versos, donde forma parte de
   su esquema fijo.

*Lo que sigue esperando a B1* son las **preguntas**, no las formas: la novena-lira no tiene dónde
registrar la disposición que se vea, ni la décima cuando no sea la documentada, ni la canción
variable las medidas de sus partes. Es el mismo hueco de la sextilla y el sexteto, y se resuelve de
una vez para todo el catálogo.

*Y una pregunta filológica que ninguna de las dos cosas resuelve*, anotada en
[cuestiones para el IP § Lira](./cuestiones-para-el-ip.md): **cuando la cabeza se repite pero no hay
eslabón, ¿es canción o es alirada?** El eslabón no sirve de prueba —el IP escribe que la sirima
«suele» empezar con chiave, luego es habitual, no constitutivo— y la prueba de los dos piedi sola
declara canción al `aBaBcDcDeE` que la edición de *Elisa Dido* llama «décima-estancia». No hay
tercer rasgo formal que rompa el empate.

### B · Bloquean el editor V2 en producción

**B1 a B7 están resueltos**; el resumen de cada uno está en la tabla de arriba y el detalle, en los
commits y en [criterios de nivel](./criterios-de-nivel.md). El resto de lo que hace falta para que
el V2 llegue a los editores no son deudas del modelo sino integración, y vive en
[El camino a develop](#el-camino-a-develop-lista-para-la-ola-de-editores).

**B8 se cerró el 27 de agosto de 2026.** El cuarteto, la octava, la novena y la décima liras
declaraban su repertorio `7/11` y **ninguna posición** —la norma no fija cuál va dónde— pero no tenían
pregunta de metro, así que la medida que el editor leía no se registraba. Ya la tienen: la función que
deriva las opciones ofrece dos por verso. *El septeto-lira quedó fuera a propósito —su esquema sí fija
la medida verso a verso— y si admite otras proporciones lo decide el IP.*

**No queda nada abierto en B.**


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

**C3. ~~Dos huecos del auditor~~ Uno cerrado el 25 de agosto de 2026; el otro sigue. Y dos cosas
del soneto que dependían de ellos.**

**`max_consecutivos` ya se evalúa.** Estaba en el `CHECK` de `esquema_rima_restricciones.tipo` desde
el principio y `incumple` devolvía `false`, de modo que el catálogo podía declarar la restricción y
nadie la leía. Ahora se cuenta la racha más larga de versos seguidos con la misma rima.

*Y la cuenta no se escribió dos veces.* La misma medida —clases, sueltos, alternancias y racha— la
necesitaban el auditor, sobre las filas de `esquema_rima_posiciones`, y el validador de lo que el
editor escribe, sobre una notación. Vive una sola vez en
**`src/lib/metrica/esquema-rima-escrito.ts`** (`medirDisposicion`), con sus pruebas, y el auditor la
**importa**: con dos implementaciones, un día dirían cosas distintas del mismo verso. *El auditor
cuenta los sueltos con más manga, y está comentado por qué: un esquema catalogado puede dar clase a
un verso que no rima con ninguno, y para contrastar `versos_sueltos: ninguno` hay que verlo.*

*Comprobado de punta a punta*, y no solo con pruebas unitarias: se declaró la restricción sobre el
patrón abierto de la quintilla, se corrió el auditor —señaló `abbba` con «3 seguidos», que es
exactamente el caso que su ficha llevaba anotado como no comprobable— y se retiró.

**Y esa prueba destapó un segundo fallo, que el primero tapaba.** D13 exceptuaba dos cosas —el
esquema que el criterio excluye y el que ocupa otra sección— y **no la modalidad**. Pero `abbba`
está declarado `excepcional`: está en el catálogo *precisamente porque se aparta*, y su ficha lo
dice —«no lo numera nadie: lo registran como aparición suelta, que M&B atribuyen a errata o a
adaptación expresiva»—. Medirlo contra la norma y llamarlo defecto empujaba a una de dos cosas, y
las dos peores: borrar el esquema, o no declarar la restricción para que no protestara. **Declarar
algo excepcional es decir que no cumple la norma**, así que D13 lo salta.

La excepción protege hoy a las **tres quintillas**, que son las únicas con esquemas excepcionales y
patrón abierto con restricciones a la vez. Repetida la prueba con ella puesta, la restricción se
declara y el informe sigue en cero.

**Lo que eso desbloquea, y es una decisión filológica:** la ficha de la quintilla dice que
`min_alternancias: 2` **no es la regla de las fuentes** —la regla es «no más de dos versos seguidos
con la misma rima»— y que se expresaría con `max_consecutivos: 2`. Se dejó como estaba porque el
auditor no evaluaba el tipo correcto. **Los dos motivos han desaparecido.** ⇒ decisión del IP.

**Lo que sigue abierto:** `numero_clases` admite un solo valor, así que no puede expresar «dos o
tres»; necesitaría un rango o un tipo nuevo. Y con él las dos cosas del soneto: si sus cuartetos
podrían heredar la disposición del cuarteto declarando la identidad con un enlace, y la restricción
`max_consecutivos: 2` de sus tercetos, que la fuente enuncia y el catálogo no declara. **Esta
segunda ya se puede declarar**: el auditor la comprobaría.

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

**C13. Revisar las tradiciones de todas las formas.** **Nueve están sin tradición**, contadas el 28 de
agosto de 2026: cuarteto, endecha real, pareado, los dos tramos sin forma y **las cuatro liras nuevas**
—cuarteto, novena, octava y décima—, que entraron el 24 de agosto sin asignarla. Eran cinco cuando se
escribió esto, y la diferencia dice algo: **una forma nueva no recibe tradición si nadie se acuerda**.
En algunos casos la ausencia es correcta: Jauralde sitúa el
pareado «entre las formas originarias y primitivas de la poesía», que no es ni italiana ni
española. Pero eso no se ha comprobado forma por forma, y las tres tradiciones del catálogo nunca
se han mirado juntas: ni de dónde sale cada asignación, ni si el reparto responde a un criterio, ni
si «italiana» y «española» bastan. *La revisión debe decidir si la ausencia es un dato o un hueco.*

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
semiestrofa»—, pero contado el 28 de agosto de 2026 **la modalidad aguda solo la declaran tres
formas**: la octava aguda —seis arquitecturas, definitoria—, el septeto —dos, admitida— y el sexteto
—una, habitual—. Ni la sextilla ni la décima, que son las dos que Jauralde nombra. *Falta una pasada que decida en qué formas
se admite y con qué modalidad; va con B2, que revisa el reparto entero de los rasgos.*

**Y al hacerla habrá que ver cómo se cruza con las vocales de la asonancia**, que lo apuntó David el
29 de agosto de 2026 revisando el romance: **algunas asonancias son ya agudas por sí mismas**. De
los 19 valores de `vocales_asonancia`, los **cuatro simples** —`a`, `e`, `i`, `o`— son las asonancias
**agudas**, porque una rima aguda asuena en su única vocal tónica final; los **quince pares**
—`o-e`, `a-a`, `u-o`…— son las **llanas y esdrújulas**, que asuenan en la tónica y la final. Esa
relación no está declarada en ninguna parte, así que hoy se podría responder «final agudo» y a la
vez una asonancia en par, que se contradicen.

*Es la misma observación que ya obliga a la octava aguda a ofrecer solo cuatro valores* —ver
**F33**—: allí el final agudo es definitorio y las quince asonancias llanas no aplican. Si los
valores se clasificaran por su terminación, las dos cosas se sostendrían solas: la pregunta ofrecería
lo que cabe y el rasgo no habría que responderlo dos veces.

**C17. El catálogo se deriva en cada lectura, y eso no escala.** Cuatro de las «tablas» que lee el
gestor no son tablas: son vistas sobre funciones SQL que recorren el catálogo entero cada vez que
alguien las mira. Medidas por PostgREST el 26 de agosto de 2026, con **680 opciones y 107 grupos**:

| vista derivada | contra la base | por PostgREST |
|---|---|---|
| `opciones_eleccion_metrica` | 62 ms | 1.221 ms |
| `grupos_eleccion_metrica_resueltos` | 22 ms | 1.465 ms |
| `arquitecturas_reglas_longitud` | 41 ms | 768 ms |
| `anotacion_elecciones_resueltas` | 21 ms | 751 ms |
| `propuesta_elecciones_secuencia` | 750 ms | 2.041 ms |

El multiplicador de veinte no es la consulta: es que la pantalla dispara **unas treinta consultas en
paralelo** contra una instancia compartida y compiten por su CPU. `/dashboard/metrica` llegó a
tardar seis segundos y a dar un 500 por `statement timeout`.

**Hecho ese mismo día, y resuelve la mitad grande:** el catálogo son 2.422 filas que solo cambian
por migración, así que ya **no se reconstruye si su revisión no ha cambiado**
(`catalogo_metrico_estado`). Medido sobre cinco cargas: la revisión se pregunta cinco veces y el
catálogo, **cero**. Antes hizo falta que las veinticinco tablas subieran la revisión: dos no lo
hacían —`fuentes_metricas` y `afirmaciones_fuentes_metricas`— y lo arregló `20260826100000`.

*Que la caché pueda compartirse entre peticiones descansa en que quien pregunta ve el catálogo
entero, y eso hoy está probado por la propia base:* `catalogo_metrico_estado` tiene RLS
`auth_is_admin_or_ip()`, así que haber leído la revisión ya demuestra el permiso. **Cuando el editor
V2 pase a `/dashboard/obras` habrá que relajar esa RLS** —un editor también necesitará el catálogo—,
y ese día la llave de la caché deja de bastar: habrá que añadirle la visibilidad.

**Cerrado el 27 de agosto de 2026.** La propuesta de la anotación en sombra costaba dos segundos y
no la cubría la caché, porque depende de las secuencias. Al retirarse la anotación en sombra —dejó de
ser el camino de la migración ese mismo día— se fue con ella. No hubo que arreglar nada. Lo que sigue
valiendo es el aviso de abajo. Dos salidas, y no son excluyentes: es una herramienta de
migración que **desaparece cuando la migración termine**, y mientras tanto puede materializarse lo
derivado —`opciones_eleccion_metrica`, `grupos_eleccion_metrica_resueltos` y
`arquitecturas_reglas_longitud`, entre las tres 880 filas— refrescándolo cuando cambie la revisión.
*Materializar es seguro en cuanto al acceso: la RLS de esas tablas no filtra filas, es una puerta de
todo o nada —`auth_is_admin_or_ip() or catalogo_metrico_publico()`—, así que la vista conserva su
nombre y su regla y solo cambia de dónde lee.* Conviene medirlo con la caché ya puesta, para saber
cuánto añade de verdad.

*Un apunte que salió del plan de ejecución, por si vuelve a morder:*
`regla_longitud_arquitectura_metrica` está en **plpgsql**, que Postgres no puede integrar en la
consulta, así que la ejecuta fila a fila: **670 veces** en una sola carga de la propuesta. Reescrita
en SQL sería inlineable.

**C18. Nadie proyecta una anotación a notación verso a verso, y es lo que pide la estilometría.**
Salió el 26 de agosto de 2026 al revisar qué guarda una respuesta: la de una unidad guarda
`variedad_id` —«A2 · AbaBcC»— y no `11 7 7 11 7 11 / AbaBcC`.

**Que no esté guardado es correcto y no se toca.** La variedad apunta a un esquema métrico y a uno
de rima, y cada esquema tiene una fila por posición: la notación exacta se deriva, comprobado contra
la base. Guardarla además en la elección crearía una segunda fuente de verdad, y el día que se
corrija un esquema del catálogo —la revisión va por la 4413— los pasajes anotados antes conservarían
la vieja, sin manera de distinguir «esto se corrigió» de «este pasaje era realmente distinto». Esa
segunda distinción es justo para lo que existe `desviaciones`.

**Avanzó el 28 de agosto de 2026, a medias.** El editor ya cruza la norma con las respuestas y
escribe la anotación de cada unidad en notación corriente —`8a 8b 8a 4b 8c 8d 8c 8d`—, juntando medida
y rima, repartiendo las letras cuando cada parte trae las suyas y rellenando con la norma lo que no se
pregunta. **Pero vive en la pantalla**, en `MetricStructureEditor`: no está en un módulo puro, no
recorre las desviaciones ni la arquitectura intercalada, y nadie puede pedirla desde fuera. Para la
estilometría hace falta lo que sigue.

**Lo que falta es la proyección.** [`rejilla.ts`](../../src/lib/metrica/rejilla.ts) ya produce el
verso a verso —es pura, 678 líneas con 525 de pruebas—, pero **dibuja la norma de una arquitectura,
nunca un pasaje anotado**: sus tres consumidores son la ficha de `/formas`, el demarcador y el
recuadro de la norma del editor. Nada cruza la norma con **las respuestas, las desviaciones y la
arquitectura intercalada** de una secuencia concreta.

Debe ser una **proyección precomputada y regenerable**, como los resúmenes públicos. **Con las dos
caras a la vez**, que es como se consulta y como se compara: el **nombre** por un lado —forma,
arquitectura, variedad— y la **notación exacta** por otro, verso a verso, venga de un esquema del
catálogo o de uno escrito a mano.

*Y no puede construirse sobre `rejilla.ts`, aunque lo parezca.* Esa es **solo un recurso visual**:
sus tipos son de dibujo —bandas, enlaces, celdas— y su campo `verso` está documentado como «orden de
lectura dentro de lo dibujado», no el verso de la obra. Comparten la lectura del catálogo; la
proyección necesita su propia derivación. Tres casos que el ejemplo fácil no enseña y que tendrá que resolver: cuando el
editor **escribe un esquema que el catálogo no tiene** (`valor_texto`, lo que abrió B1), cuando el
esquema es **abierto** y solo declara el régimen —quintilla, silva, sextilla—, y cuando la respuesta
es **posicional**, como los versos quebrados.

*No corre prisa para anotar —nada de esto bloquea a un editor—, pero sí es previo a poder comparar y
cuantificar, que es para lo que se hace el catálogo nuevo.*

**C19. Separar y renombrar el cargador del catálogo que usa el editor.** Al retirarse
`/dashboard/metrica`, `loadMetricCatalog` conserva el nombre y parte del contrato de la antigua
pantalla, aunque sigue siendo imprescindible para el editor de secuencias de las obras. No es
urgente: más adelante debe convertirse en un cargador explícito para el editor, devolver solo
`MetricCatalogForEditor` y el estado de migración, y dejar de consultar los datos residuales de la
antigua página.

**C20. La respuesta se describe a sí misma. Hecho el 2 de septiembre de 2026.** Propuesto por
David el 30 de agosto. La respuesta guardaba **a qué pregunta contesta**, y con eso el catálogo no se
podía corregir sin arrastrar lo anotado. Ahora guarda **qué afirma** —la entidad—, **de qué habla**
—la dimensión— y **de qué parte**, y la pregunta se deriva al leerla. El plan, con todo lo que se
midió antes de empezar, está en [su documento](./plan-c20-la-respuesta-se-describe.md).

Lo que trajo de paso, y que era el motivo de fondo: **las preguntas heredadas dejaron de inventarse
en el cliente** —`reutilizacion.ts` desapareció— y pasaron al catálogo, en `preguntas_metricas`, con
identidad derivada como ya la tenían las opciones. Con eso la oncena y el septeto compuesto pueden
guardar su rima, que es **F39**. Y **el puente con el vocabulario legado** dice también a qué
respuesta equivale, en vez de a qué pregunta, así que alcanza a las heredadas.

Comprobado anotando en «Prueba» una forma de cada clase —sin preguntas, de rima simple, con partes,
con ciclos, de variedad, de cinco rasgos sobre una misma realización y de esquema escrito a mano—:
9 anotaciones y 21 respuestas, todas resolviendo a su pregunta. Desde ahora
`npm run audit:anotaciones` vigila que un cambio del catálogo no deje ninguna sin ella, y dice en
qué obra y quién la anotó.

**Sigue pendiente** lo que el plan contaba como arreglo de paso: **F63**, dar sus preguntas a la
versificación irregular y al verso aislado, que ahora ya se pueden hacer.


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
7. **El demarcador ya consume la ontología**, no su vector fijo de rasgos: se compila al cargar
   `/recursos/demarcador` y `obtener_catalogo_demarcador()` lo sirve de `formas_metricas`. El cierre
   no obligatorio del terceto encadenado se resolvió el 25 de agosto de 2026 —ver
   [B4](#b--bloquean-el-editor-v2-en-producción)—; **queda por revisar la retirada de la copla de
   pie quebrado**. Y los artefactos guardados están viejos: los cinco son del 2 de agosto,
   revisión 2351 contra la 4318 viva, así que hay que recompilar.
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

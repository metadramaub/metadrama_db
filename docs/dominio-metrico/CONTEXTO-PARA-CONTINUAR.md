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
- `/dashboard/metrica` es la superficie de trabajo del dominio: contiene la guía, el Editor V2 de
  prueba, la anotación en sombra y la validación del demarcador. El gestor mutable se retiró el 11
  de agosto: el catálogo se consulta en `/formas` y todos sus cambios se hacen por migración.
- **La respuesta guardada no depende del catálogo que la ofreció.** `anotacion_elecciones`
  apunta al dato elegido —el esquema, el metro, el valor de rasgo, la repetición, la variedad—,
  no a una opción, y el catálogo se niega a borrar algo que una anotación use. Para leerla con
  la opción que hoy la ofrece está `anotacion_elecciones_resueltas`.
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
  con `anotaciones_metricas.secuencia_id`, sin que la secuencia cambie nada:
  `obras_anotacion_nueva` dice qué obras están abiertas, la vista
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

*Escrito el 26 de agosto de 2026.* En una frase: **que un editor que entre a crear una obra nueva
vea en su pestaña de secuencias el editor V2**, bebiendo del catálogo nuevo, y que la fusión de la
semana siguiente no obligue a nadie a seguir anotando con el vocabulario legado.

### Lo que ya está decidido

- **Las obras nuevas dejan `secuencias_metricas.estrofa_tipo_id` vacío.** La identidad métrica vive
  solo en el catálogo nuevo. Cuando se migren las anotadas con el sistema viejo y se compruebe que
  lo viejo ya no aporta nada, **la columna se retira**. *No se escribe el término legado por
  equivalencia inversa: sería fabricar la deuda que se quiere dejar de fabricar.*
- **`secuencias_metricas` no necesita ninguna columna nueva.** El vínculo ya existe y va en el
  sentido correcto: lo lleva `anotaciones_metricas.secuencia_id`, con `on delete cascade`, y la
  tabla ya declara `CHECK (num_nonnulls(escenario_id, secuencia_id) = 1)` —o pertenece a un
  escenario de prueba, o a una secuencia real—. Se hizo pensando en esta mudanza. Añadir una columna
  del lado viejo duplicaría la relación y crearía dos sitios que mantener de acuerdo.
- **El catálogo y el demarcador son zona pública.** No solo para que los editores trabajen: cuando
  caiga el muro de «web en construcción», cualquiera podrá leerlos. El interruptor de
  `/dashboard/publicacion` se conserva, pero **el dashboard no puede depender de él**.
- **La publicación de obras, la vista previa y la precomputación se quedan como están.** Son legado
  y se rehacen cuando todo esto esté terminado. Una obra recién empezada no se publica el primer
  día, así que su perfil métrico vacío no bloquea a nadie.
- **Lo que toca `secuencias_metricas` por dentro no se hace aquí.** Ver *Lo que va a `main`*.
- **Se prueba en la pestaña de secuencias de una obra, no en el laboratorio.** Decidido el 26 de
  agosto de 2026, y cambia el orden de todo lo que sigue. Probar en el sitio definitivo prueba **la
  integración de verdad** —las caracterizaciones, la sinopsis, la checklist, el API real—, que es
  justo lo que el editor de prueba no toca; y lo que se arregle ahí se queda. El IP probará con una
  obra de pruebas en el editor normal.
- **El laboratorio se retira el último**, no al mover. Mientras el camino nuevo no esté probado es
  la red donde comparar; quitarlo el mismo día que se mueve es quedarse sin las dos cosas a la vez.
- **El renombrado va antes de mover.** Hoy las tablas tienen **cero filas** sobre secuencias reales;
  en cuanto se monte el V2 en una obra y se guarde, ya no. Sin datos es una migración y un `sed`.
- **La web se cierra unos días** cambiando la contraseña de «web en construcción», para que nadie
  guarde a mitad de un renombrado o de una apertura de RLS. *Pero eso protege a las personas, no al
  esquema:* la base la comparten `develop` y `main`, y una columna retirada sigue retirada aunque no
  entre nadie. Lo que protege a `main` estos días es que **cada migración sea reversible** y que **no
  se retire ninguna columna** mientras dure. `estrofa_tipo_id` se queda hasta que lo viejo sobre.

### Los pasos, en orden

*Reordenados el 26 de agosto de 2026.* Antes empezaban por abrir la RLS; ahora empiezan por mover el
editor, porque **para que el IP pruebe no hace falta abrir nada**: `loadMetricCatalog` solo exige
poder leer la revisión del catálogo, y eso ya lo puede un admin. Abrir a los editores espera a que
el formulario convenza.

| | paso | por qué ahí |
|---|---|---|
| 1 | **Los nombres y `UNIQUE (secuencia_id)`** | mientras no haya datos |
| 2 | **Montar el V2 en la pestaña de secuencias**, para admin/IP | para probar en el sitio bueno |
| 3 | **Las quejas del formulario, una a una** | ya en su sitio, y lo que se arregle se queda |
| 4 | **La RLS y el catálogo público** | cuando el formulario esté como debe |
| 5 | **La checklist acepta la forma nueva** | sin esto los editores no cierran nada |
| 6 | **Retirar el editor de prueba** | cuando lo de obras esté probado |

Lo que sigue detalla cada uno.

**1 · Los nombres, ahora que no hay datos.** Ver la tabla de nombres más abajo.

**2 · Montar el V2 en la pestaña de secuencias.** Ver *La pestaña de secuencias monta el V2*.

**3 · Las quejas del formulario.** Se recorre forma por forma en el editor real y, de cada cosa que
no convence, se decide **si es la UI, si es el catálogo, si es cómo se registra la elección, o si el
catálogo ya lo resuelve de otra manera y lo que falta es usarla** —esta cuarta salió de dos casos el
mismo día en que se acordó el método—. Lo que va saliendo se apunta abajo, en
[Lo que sale de recorrer el formulario](#lo-que-sale-de-recorrer-el-formulario).

**4 · El catálogo, público de verdad.** Contado contra la base: de las **veintiséis** tablas del
catálogo, **veintidós ya son públicas** —tienen `SELECT = catalogo_metrico_publico()`— y **tres no**:
`catalogo_metrico_estado`, `metro_segmentos` y `repeticion_posiciones`. Las dos últimas son tablas de
detalle de `metros` y `repeticiones_metricas`, que sí lo son: es un descuido, no una decisión.

`catalogo_metrico_estado` es la que muerde hoy, porque `loadMetricCatalog` **se rinde si no puede
leer la revisión**: un editor recibiría el catálogo vacío. Es solo un número de revisión y una
versión de modelo.

*Y una cosa más, que es de diseño y no de descuido:* que el dashboard funcione **no puede depender
del interruptor público**. Hoy `catalogo_metrico_publico()` mira si la sección `formas` está activa
para anónimos; si un admin la apaga, los editores se quedarían sin catálogo. La política debe ser
«lo ve quien lo publica, quien lo edita, o cualquiera si está publicado», y para eso hace falta un
`auth_is_editor()` que hoy no existe —solo hay `auth_is_admin_or_ip()`—.

*Esto además rompe la llave de la caché del catálogo*, que hoy se apoya en que haber leído la
revisión demuestra ser admin o IP. Al abrir esa RLS hay que añadirle la visibilidad a la llave. Va
en este mismo paso, no después. ⇒ **C17**

**Los nombres, en detalle.** Las tablas se llaman `*_editor_metrico` de cuando todo
era un laboratorio, y `obras_anotacion_nueva` lleva un «v2» que envejecerá mal. Cuando el sistema
viejo muera, `anotaciones_metricas` será *la* tabla de la identidad métrica de una secuencia
con un nombre que ya no dirá nada.

**Hoy tienen cero filas sobre secuencias reales** —solo dos secuencias de escenario—, así que este
es el momento más barato que va a haber. El coste medido: **31 objetos** en la base y **82
ocurrencias** en 6 archivos de código. *Las 64 migraciones que las nombran no se tocan: una migración
aplicada no se edita, y el renombrado es una migración nueva.*

Propuesta, pendiente del visto bueno del IP:

| hoy | propuesta | qué guarda |
|---|---|---|
| `anotaciones_metricas` | `anotaciones_metricas` | la identidad métrica de un pasaje: qué forma y qué arquitectura |
| `anotacion_realizaciones` | `anotacion_realizaciones` | el árbol de lo que hay verso a verso: cada unidad y sus partes |
| `anotacion_elecciones` | `anotacion_elecciones` | las respuestas a las preguntas que hace la arquitectura |
| `anotacion_elecciones_resueltas` | `anotacion_elecciones_resueltas` | *(vista)* esas respuestas más la opción que las ofrecía |
| `anotacion_desviaciones` | `anotacion_desviaciones` | lo que el pasaje hace y la norma no admite |
| `anotacion_escenarios_prueba` | `anotacion_escenarios_prueba` | el laboratorio: cajones de pruebas que no son obras |
| `obras_anotacion_nueva` | `obras_anotacion_nueva` | qué obras usan el editor nuevo |

**Las claves primarias van en el mismo viaje.** No son solo los nombres de tabla los que huelen a
laboratorio: `anotacion_id`, `realizacion_id`, `eleccion_id` y
`desviacion_id` están a punto de guardar anotaciones de verdad, y dejarlas obligaría a
convivir con una tabla llamada `anotaciones_metricas` cuya clave se llama «id de prueba». Pasan a
`anotacion_id`, `realizacion_id`, `eleccion_id` y `desviacion_id`, y con ellas las claves foráneas
que las nombran.

*`obras_anotacion_nueva` es la única que nace con fecha de caducidad:* mientras conviven los dos
sistemas dice qué obras usan el nuevo, y **cuando se migre lo anotado deja de hacer falta** —lo
usarán todas—. Se retira entonces, con la columna `estrofa_tipo_id`.

**5 · Una anotación por secuencia.** Falta un `UNIQUE (secuencia_id)`: hoy nada impide que una
secuencia real tenga dos anotaciones métricas.

**6 · La anotación, abierta a los editores.** Las seis tablas tienen política `auth_is_admin_or_ip()`
y ninguna otra: un editor no puede escribir ni una fila. Hay que abrirlas **con el alcance por obra
asignada**, que es la regla que ya gobierna el resto del dashboard. Con guardas que ejecuten: probar
que un editor escribe lo suyo y **no** lo ajeno.

**La pestaña de secuencias monta el V2, en detalle.** `MetricSequenceEditor` es portátil por diseño —recibe
lo no métrico como `bodyExtra` y su contenedor ya dice que «se moverá tal cual al editor de obras»—.
La secuencia real se sigue creando como hoy: rango y caracterizaciones en `secuencias_metricas`;
solo la identidad métrica va a las tablas nuevas. **El interruptor es por obra**, con la tabla que
hoy es `obras_anotacion_nueva`: una obra apuntada ahí usa el V2, y las demás siguen con el editor
viejo hasta que se migren. Así nadie empieza una obra nueva con el vocabulario legado y no se
interrumpe a quien está a mitad de una.

**7 · La checklist acepta la forma nueva.** `hasPendingSequenceFields` declara pendiente toda
secuencia con `estrofa_tipo_id` nulo, así que una obra anotada en V2 **no podría marcarse
revisable**. Tiene que dar por satisfecho ese campo cuando la secuencia tiene forma en el catálogo
nuevo. Sin esto los editores trabajan pero no cierran nada.

### Lo que sale de recorrer el formulario

*Se abre el 26 de agosto de 2026.* Cada entrada dice a cuántas formas alcanza y en qué capa está el
arreglo, comprobado contra la base antes de proponer nada.

**F1. El rango de versos admite un final anterior al inicial, y toda la pantalla razona sobre él.**
Con 116–112 en una forma de trece versos, la cobertura dice «la estructura rebasa el rango en 39
versos». **Alcanza a todas las formas**: no es del catálogo, es el campo. Tres capas:

1. **La UI deja llegar al estado imposible.** Los dos campos llevan `min="1"` y nada más:
   `updateSequenceEnd` hace `Math.max(1, value)` sin mirar `v_ini`, y `updateSequenceStart` al
   revés. `validateDraft` **sí** lo rechaza —«El verso final no puede ser anterior al inicial»—,
   pero solo al pulsar Guardar, cuando la pantalla lleva un rato mintiendo.
2. **Los rangos de las desviaciones están peor.** Son `bind:value` **sin `min` siquiera**, así que
   admiten cero y negativos, y `validateDraft` **no las menciona en ninguna línea**: ni su rango ni
   que caigan dentro de la secuencia. Lo para la base, con un error crudo en vez de un aviso.
3. **A `secuencias_metricas` le falta la restricción.** `anotacion_realizaciones`,
   `anotacion_desviaciones`, `anotaciones_metricas`, `secuencias_caracterizaciones_rango`
   y `secuencias_subtipos_estrofa` **todas** tienen `v_fin >= v_ini`; la de producción **no**. Hoy la
   sostiene solo el `refine` de zod del API. *Datos limpios: 0 invertidas de 263, ningún `n_versos`
   descuadrado.* Esa migración **va a `main`**, que es donde van los cambios de esa tabla.

*Queda una decisión del IP:* qué hace subir el verso inicial por encima del final. Hoy, cuando la
forma deriva las unidades del rango, **arrastra el final conservando la longitud**; cuando no las
deriva, el final se queda quieto y puede quedar detrás. La propuesta es hacerlo **igual siempre**,
para que el editor se comporte de una sola manera.

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

Quedan **tres asuntos en A**, **uno en B** y **dieciséis en C**.

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

   **Dónde está, porque no es obvio:** en la pestaña **«Anotación en sombra»** de
   `/dashboard/metrica`. No hay una zona de migrar aparte; es esa.

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

**B8. Las aliradas abiertas no pueden registrar el esquema de metro que se ve.** *Escrito el 26 de
agosto de 2026 y **rehecho dos veces el mismo día**, las dos por leer mal el catálogo antes de
preguntar. Queda anotado el recorrido porque el error es instructivo: ninguna de las dos lecturas
falsas se sostuvo al contrastarla con la intención del IP.*

**La decisión de diseño, dicha por el IP:** el cuarteto, el septeto, la octava, la novena y la
décima-lira son formas nuevas de las que **todavía no se sabe qué hay en el corpus**, así que se
dejan **abiertas de metro y de rima** —salvo el esquema de rima de la décima-lira, que ya se
conoce—, y **se quiere que registren exactamente el esquema de metro y exactamente el de rima**. La
base es donde se van a documentar.

Estado real, contado contra la base:

| forma | rima | metro | preguntas |
|---|---|---|---|
| Cuarteto-lira | `abab`, `abba` *(admitidas)* | abierto, `11/7` | 1 de rima, **0 de metro** |
| Octava-lira | `ababccdd`, `abcabcdd` *(admitidas)* | abierto, `11/7` | 1 de rima, **0 de metro** |
| Novena-lira | **abierta**, sin notación | abierto, `11/7` | 1 de rima, **0 de metro** |
| Décima-lira | `ababcdcdee` *(admitida)* | abierto, `11/7` | 1 de rima, **0 de metro** |
| Septeto-lira | `ababbcc` *(habitual)* | **fijo** `7 11 7 11 7 7 11` | **0 y 0** |

**La mitad de rima está hecha y la de metro no existe.** Escribir el esquema de rima lo resolvió B1
—`opciones_y_esquema`, 41 grupos—. Para el metro no hay nada: los **27 grupos de metro del catálogo
entero son `opciones` cerradas**, y no existe ningún `tipo_control` que admita escribir un esquema
métrico. Un editor que vea `11 7 7 11` en un cuarteto-lira no tiene dónde ponerlo.

**Y la salida de rebote no vale.** En la tradición alirada la caja de la notación es la medida
—`aBaB`—, y como el normalizador la conserva verso a verso, el dato *quedaría* registrado. Pero
mezcla dos dimensiones en una respuesta, solo se sostiene en esta tradición —en una octava real las
mayúsculas solo dicen arte mayor— y **no se puede contar ni comparar como metro**, que es
justamente para lo que se registra. El IP pide el esquema de metro exacto, como dato propio.

Lo que hace falta, con B1 de plantilla:

1. Un **`tipo_control` para escribir un esquema métrico** y su híbrido, espejo de `esquema_rima` y
   `opciones_y_esquema`.
2. Las **preguntas de metro** de estas formas.
3. Un **normalizador de esquemas métricos escritos**, hermano de
   [`esquema-rima-escrito.ts`](../../src/lib/metrica/esquema-rima-escrito.ts): validar `11 7 7 11`,
   comprobar que el número de medidas cuadra con la extensión de la unidad, y **casar con los
   esquemas métricos del catálogo**, para que uno que ya existe se guarde como elección y no como
   texto —igual que hace hoy `MetricChoiceField` con la rima—.
4. **Guardar lo escrito descompuesto**, no como cadena: sin eso, el recuento de «cuántos han escrito
   el mismo esquema» —la señal para incorporarlo al catálogo y migrar las secuencias que lo usaban—
   obliga a partir cadenas. Vale para las dos dimensiones a la vez.

*El septeto-lira está fuera de línea con sus hermanas:* tiene el metro fijo y un único esquema de
rima marcado `habitual` —«suele ser este», luego hay otros— y **no pregunta nada**, así que quien
encuentre uno distinto no puede decirlo. El auditor no lo ve porque **D17 da por fijada la rima
cuando hay un solo esquema concreto**, sin mirar la modalidad. Si va a quedar abierta como las
demás, se le añaden las dos preguntas; y conviene decidir si D17 debe mirar también la modalidad.

*Lo que sí está bien y no hay que tocar:* las **ocho variedades del sexteto-lira** no son otra
manera de declarar la medida, sino el mecanismo para emparejar esquema métrico y de rima **sin
generar el producto cartesiano** de variedades. Es propio de esa forma. No hay ninguna
inconsistencia de modelo que resolver, como llegué a escribir aquí.

*Y la **canción de estancias variables**, que puse como segundo caso, sí tiene pregunta de metro:
está cubierta.*

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

**C13. Revisar las tradiciones de todas las formas.** **Cinco están sin tradición** —cuarteto,
endecha real, pareado y los dos tramos sin forma—, y en algunos casos con razón: Jauralde sitúa el
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
semiestrofa»—, pero solo lo declaran dos arquitecturas. *Falta una pasada que decida en qué formas
se admite y con qué modalidad; va con B2, que revisa el reparto entero de los rasgos.*

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

**Lo que queda.** La propuesta de la anotación en sombra sigue costando dos segundos, y no la cubre
la caché porque depende de las secuencias. Dos salidas, y no son excluyentes: es una herramienta de
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
Salió el 26 de agosto de 2026 de una pregunta del IP: la respuesta de una unidad guarda
`variedad_id` —«A2 · AbaBcC»— y no `11 7 7 11 7 11 / AbaBcC`.

**Que no esté guardado es correcto y no se toca.** La variedad apunta a un esquema métrico y a uno
de rima, y cada esquema tiene una fila por posición: la notación exacta se deriva, comprobado contra
la base. Guardarla además en la elección crearía una segunda fuente de verdad, y el día que se
corrija un esquema del catálogo —la revisión va por la 4413— los pasajes anotados antes conservarían
la vieja, sin manera de distinguir «esto se corrigió» de «este pasaje era realmente distinto». Esa
segunda distinción es justo para lo que existe `desviaciones`.

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
   `/dashboard/metrica` y `obtener_catalogo_demarcador()` lo sirve de `formas_metricas`. El cierre
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

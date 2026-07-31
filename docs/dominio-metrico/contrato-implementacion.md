# Contrato de implementación del dominio métrico

Estado: **migración estructural completa** · bloques A, B y C aplicados el 30 de julio de 2026; la unidad envolvente y el bloque D, el 31

Contrasta [la ontología](./ontologia-metrica.md) con lo que la base y el código expresan
hoy, concepto a concepto, y fija qué hay que cambiar antes de corregir ningún dato. El
orden importa: nueve de los defectos del [informe de conformidad](./informe-conformidad-catalogo.md)
no se pueden arreglar sin cambiar antes el esquema, así que corregir datos primero
obligaría a migrarlos dos veces.

## 1 · Condiciones de seguridad

Comprobado antes de planificar nada:

- **Producción no toca el catálogo.** `main` no contiene ninguna referencia a
  `formas_metricas`, `configuraciones_forma`, `patrones_metricos`, `patrones_rima`,
  `estructuras_secciones` ni `familias_metricas`. Su métrica es la heredada: componentes
  de visualización y el demarcador legado basado en JSON. Renombrar tablas del catálogo no
  puede romper la versión desplegada.
- **Existe una barrera de versión.** `catalogo_metrico_estado.modelo_version` valía `42`
  antes de empezar y vale `47` al terminar, y
  [catalogo-metrico.ts](../../src/lib/server/catalogo-metrico.ts) muestra «falta aplicar
  migraciones» si es menor. Protege la dirección «base sin migrar, código nuevo», pero
  **no la contraria**: código antiguo contra base migrada pasaría la comprobación y
  fallaría al consultar tablas renombradas. Migración y código deben entrar juntos.
- **Ninguna secuencia real depende del catálogo.** `secuencias_metricas` sigue apuntando a
  `vocabularios`. Las únicas filas que se verían afectadas son las de prueba del editor V2,
  hoy un escenario y cero secuencias.

## 2 · Concepto a concepto

Fotografía del estado **antes** de empezar, que es lo que justifica el plan del apartado 5.
Los renombrados de la columna «Veredicto» están ya aplicados; para el estado vigente de
cada concepto, la tabla de correspondencia de [la ontología](./ontologia-metrica.md).

| Concepto de la ontología | Antes | Veredicto |
| --- | --- | --- |
| Forma | `formas_metricas` | Renombrar valores de `tipo_registro`; `residual` pasa a grado de especificación |
| Tramo sin forma | `tipo_registro = 'salida_editorial'` | Renombrar a `sin_forma`. Le falta la capa de observación descriptiva |
| Arquitectura | `configuraciones_forma` | Renombrar tabla. **Le falta declarar la extensión de la unidad** |
| Unidad | implícita, en las secciones | **No existe como declaración.** Es el hueco principal |
| Metro | `vocabularios` + `modelos_verso` | **Dos mecanismos para lo mismo.** Unificar en una tabla del dominio |
| Esquema métrico | `patrones_metricos` | Renombrar |
| Esquema de rima | `patrones_rima` | Renombrar; la columna `esquema` pasa a `notacion` |
| Sección | `estructuras_secciones` | Correcta. Retirar las nueve que solo repiten la unidad |
| Repetición | `patrones_repeticion` | Correcta |
| Variedad | `combinaciones_patrones_configuracion` | Renombrar |
| Rasgo | `rasgos_metricos` · `configuracion_rasgos` | Estructura correcta; falta poblarla (es corrección de datos) |
| Elección | `grupos_eleccion_metrica` · `opciones_eleccion_metrica` | Correcta salvo un caso: la respuesta que define la norma |
| Denominación | `denominaciones_metricas` | Falta el tipo `posterior` y el destino a variedad |
| Tradición | `tradiciones_metricas` · `formas_tradiciones` | Retirar `tipo_relacion` y `es_principal` |
| Relación | `forma_relaciones` | Correcta; los ocho tipos están en el check |
| Familia | `familias_metricas` · `familias_formas` | Eliminar |
| Realización de sección | `unidades_editor_metrico` | Renombrar: «unidad» pasa a significar lo que la forma define |
| Niveles estructurales | `nivel_estructural` | Fundir `composicion` y `compuesta` |

## 3 · Los cinco huecos reales

Lo demás son renombrados. Estos exigen decisiones de esquema.

### 3.1 · La unidad no se declara en ninguna parte · resuelto en el bloque C

Es el hueco que arrastra a los demás. Antes del bloque C la extensión de la unidad vivía en tres sitios
distintos según la forma: en `numero_versos` cuando era fija y la forma era estrofa o
composición; en una sección raíz cuando alguien la creó; y en ninguna parte para lira,
octava real, terceto, sexta rima y pareado, que por eso **no podían materializar sus
unidades** aunque la regla de longitud funcionara.

`numero_versos` no bastaba: la unidad puede tener rango. La copla de pie quebrado va de 5 a
12 versos y ese intervalo lo llevaba una sección fantasma. La migración
[20260728159000](../../supabase/migrations/20260728159000_numero_versos_configuracion.sql)
sustituyó `versos_min`/`versos_max` por `numero_versos` porque entonces ninguna
configuración tenía extremos distintos; con la unidad explícita vuelve a hacer falta el
intervalo, ahora por una razón documentada.

**Cambio aplicado:** la arquitectura declara `unidad_versos_min` y `unidad_versos_max`;
fija cuando coinciden. `numero_versos` desapareció absorbida, y con ella el disparador que
anulaba la extensión según el nivel, que existía solo para proteger un campo mal ubicado.
Veintinueve arquitecturas declaran hoy su unidad: las veintiocho que tenían `numero_versos`
y la copla de pie quebrado, que recibe por fin su intervalo de 5 a 12.

**La sección fantasma no era una fila muerta.** Comprobado el 30 de julio de 2026:
**ocho grupos de elección de alcance `unidad` colgaban de ella** —los de quintilla,
redondilla ×2, sexteto ×2, sexteto-lira y copla de pie quebrado ×2—, y el editor la usaba
para materializar las unidades del pasaje. Hacía dos trabajos a la vez: declarar la
extensión de la unidad y servir de ancla a lo que se pregunta por unidad.

Retirarla exigió, por tanto, más que borrar nueve filas:

1. Que una pregunta por unidad pueda no apuntar a ninguna sección: `seccion_id` a nulo
   cuando la pregunta se refiere a la unidad entera y no a una parte suya. Los ocho grupos
   lo tienen ya a nulo.
2. Que `realizaciones_editor_metrico.seccion_id` admita nulo: la realización de la unidad
   no es la realización de una sección. Una restricción impide que una realización sin
   sección cuelgue de otra.
3. Ajustar `validar_eleccion_editor_metrico` y `validar_unidad_editor_metrico`, que
   emparejaban la sección del grupo con la de la unidad. Una pregunta sin sección se aplica
   ahora a la realización que no cuelga de ninguna otra.
4. Sustituir en [editor-model.ts](../../src/lib/components/metrica/editor-v2/editor-model.ts)
   las tres funciones que detectaban la repetición del pasaje a partir de las secciones raíz
   —`flatRepeatedMetricSection`, `flatVariableRepeatedMetricSection` y
   `hierarchicalRepeatedMetricSection`— por una sola, hoy `metricUnitPlan`, que la deriva
   del rango y de la extensión declarada de la unidad.

Hicieron falta dos ajustes más, que el inventario previo no había anticipado:

- `validar_estructura_secuencia_editor_metrico` comprobaba la repetición de las secciones
  raíz contra la secuencia entera, cuando lo que esa repetición declara es cuántas veces
  aparece la sección dentro de cada unidad. Sin corregirlo, las formas cuya sección raíz
  declaraba `1–1` —copla de arte mayor, doble sextilla, copla manriqueña, sextina— no
  habrían podido registrar más de una unidad por secuencia. La unidad envolvente lo dejó en
  su forma definitiva: cada sección se cuenta dentro de la realización que la contiene.
- `guardar_secuencia_editor_metrico_prueba` emparejaba las preguntas por unidad con
  `grupo.seccion_id is null or grupo.seccion_id = unidad.seccion_id`, que con la sección
  nula habría aplicado la pregunta a cualquier realización, incluidas las partes internas.

Es el primer bloque que cambia comportamiento del editor y no solo representación. Su
efecto visible: las formas sin secciones —lira, octava real, terceto, sexta rima, pareado y
las nueve que perdieron su sección fantasma— materializan por fin sus unidades, y la
repetición del pasaje se deriva del rango en toda arquitectura que declare su unidad.

**La unidad envolvente cerró lo que quedaba abierto.** El bloque C dejó dos maneras de
expresar lo mismo: en unas arquitecturas la unidad era una sección raíz que contenía a las
demás, y en otras no era ninguna sección. Las que tienen varias secciones raíz —soneto,
villancico, zéjel, seguidilla compuesta— no podían por eso registrar más de una unidad por
secuencia, y un pasaje de tres sonetos seguidos seguía sin poder delimitarse.

Catorce secciones eran en realidad la unidad. Comprobado el 31 de julio de 2026: ninguna
declaraba esquema métrico, esquema de rima ni arquitectura referenciada —solo una nota que
explicaba de qué se compone la unidad, que es lo que la extensión declarada y las partes ya
dicen—, y solo cinco grupos de elección colgaban de ellas, los de las dos coplas reales.
Se disolvieron: sus partes son ahora las partes de la unidad, y esos cinco grupos preguntan
por la unidad entera, que es lo que preguntaban.

Queda una sola regla, sin excepciones: **la unidad es la realización que no cuelga de
ninguna otra, y toda sección se realiza dentro de una unidad.** La restricción
`(seccion_id is null) = (realizacion_padre_id is null)` la enuncia en la base, y
`validar_estructura_secuencia_editor_metrico` cuenta cada sección dentro de la realización
que la contiene, no dentro de la secuencia.

### 3.2 · El metro tiene dos representaciones

`patron_metrico_posiciones` obliga por `check` a elegir entre `metro_id` —hacia el
vocabulario genérico— y `modelo_verso_id` —hacia el dominio—. 200 posiciones usan la
primera y 8 la segunda, y el criterio para elegir no está escrito: es «si necesita
hemistiquios, cámbiate de tabla».

**Cambio:** una tabla `metros` en el dominio, con sílabas, tipo simple o compuesto,
segmentos y cesura. Absorbe `modelos_verso` y `modelo_verso_segmentos`. El arte se deriva
y no se almacena. Hay que repuntar 348 referencias: 200 posiciones, 8 modelos, 34 opciones
de esquema y 106 opciones de elección. El desdoblamiento de `dodecasilabo` en simple y
compuesto es la única fila que no es traslación directa, y `alejandrino` gana por fin su
estructura `7 + 7`.

`vocabularios` conserva su categoría `metro` mientras las secuencias reales sigan
apuntando ahí; los dos catálogos coexisten hasta la migración de anotaciones.

### 3.3 · La respuesta que define la norma no se distingue de una elección · resuelto

La canción petrarquista y el sexteto usan `tipo_control = 'esquema_rima'` con
`alcance = 'unidad'` y `permite_aplicar_global`. Funciona, pero dice otra cosa de la que
ocurre: no es una respuesta por unidad que casualmente se repite, es **una declaración que
rige toda la secuencia**. Con el modelo actual nada impide guardar estancias con esquemas
distintos en una canción, que es justo lo que su norma prohíbe.

**Cambio:** un `alcance = 'norma_de_secuencia'`, o un booleano `define_norma`, que obligue
a una sola respuesta por secuencia y la aplique a todas las unidades. Es pequeño y evita
que el editor pueda guardar algo que la forma no admite.

**Resuelto con el booleano.** `alcance` sigue diciendo dónde se pregunta y `define_norma`
dice cuántas veces puede responderse distinto: son cosas ortogonales, y separarlas evita que
cada sitio que hoy distingue `secuencia` de `unidad` tenga que aprender un tercer valor. La
respuesta se sigue guardando en cada realización —lo que permitirá registrar mañana una
desviación localizada— y lo que se añade es la comprobación de que todas coinciden dentro
del ámbito que las contiene.

Dos precisiones que el análisis anterior no tenía. El ámbito es **la unidad, no la
secuencia**: lo que debe coincidir son las estancias de una misma canción, no dos canciones
distintas del mismo pasaje, así que el nombre `norma_de_secuencia` describía mal el único
caso real. Y **el sexteto no es uno de ellos**: su ficha dice que su patrón de rima es
«variable y registrado en cada unidad», y que dos sextetos de una tirada difieran está
previsto. Queda activado solo en la canción petrarquista, en sus dos preguntas por estancia:
el esquema de rima y la medida por posición.

### 3.4 · Los tramos sin forma no tienen dónde describirse

No es un hueco del catálogo sino de la capa de anotación: solo existe
`desviaciones_editor_metrico`, que es comparativa por construcción —tiene
`relacion_norma` obligatorio—. Sin norma no hay nada con lo que comparar, así que hoy un
tramo irregular no puede registrar ni sus metros.

**Cambio:** la capa de observación necesita dos modos, descriptivo y comparativo. **Queda
fuera de esta migración**: pertenece a la capa de anotación, que se diseña junto con la de
las secuencias reales. Se registra aquí para que no se pierda.

### 3.5 · Detalles menores del mismo bloque · resueltos en el bloque D

- `denominaciones_metricas` no admitía apuntar a una variedad, y sus restricciones
  conservaban el nombre `forma_aliases_*` de antes del renombrado. Ya tiene `variedad_id`
  entre sus destinos posibles.
- El tipo `posterior` no existía: «Cuarteta» estaba registrada como `equivalente`, lo que
  afirma que así se las llamaba en el Siglo de Oro. Ya está reclasificada.
- `formas_tradiciones` obligaba a un `tipo_relacion` que el dato de origen no tiene, y su
  `es_principal` protegía una invariante vacía cuando la pertenencia es única. Ambas
  columnas desaparecieron y la clave primaria es ya `(forma_id, tradicion_id)`.

## 4 · Superficie de impacto

Un renombrado de tabla en PostgreSQL arrastra solo, sin tocarlas, las claves ajenas, los
índices, las restricciones, los disparadores y las vistas. **No arrastra el cuerpo de las
funciones plpgsql**, que es texto y sigue nombrando lo viejo hasta que falla en ejecución.
Por eso el inventario importa:

| Qué | Cuánto | Consecuencia |
| --- | ---: | --- |
| Funciones que nombran tablas del catálogo | 17 | Recrear todas en la misma migración |
| Vistas | 1 · `configuraciones_forma_reglas_longitud` | Recrear |
| Disparadores sobre tablas renombradas | 45 | Se arrastran solos; solo se renombran por higiene |
| Módulos de servidor | 3 · `catalogo-metrico.ts`, `demarcador-catalogo.ts`, `catalogo.ts` | Actualizar con la migración |
| Rutas de API | 4 · configuraciones, entidades, formas, editor-pruebas | Actualizar |
| Tipos generados | `database.types.ts` | Regenerar con `npm run db:types` |
| Script de auditoría | `audit-catalogo-metrico.mjs` | Lee nombres de columna: se rompe si no entra a la vez |

Las diecisiete funciones son: `guardar_secuencia_editor_metrico_prueba`,
`marcar_configuracion_metrica_principal`, `normalizar_extension_configuracion_metrica`,
`normalizar_extensiones_al_cambiar_nivel_metrico`, `regla_longitud_configuracion_metrica`,
`sincronizar_posiciones_patron_rima_fijo`, `validar_combinacion_patrones_configuracion`,
`validar_configuracion_forma_no_editorial`, `validar_desviacion_editor_metrico`,
`validar_eleccion_editor_metrico`, `validar_estructura_secuencia_editor_metrico`,
`validar_forma_salida_editorial`, `validar_grupo_eleccion_metrica`,
`validar_opcion_eleccion_metrica`, `validar_posicion_opcion_eleccion_metrica`,
`validar_secuencia_editor_metrico` y `validar_unidad_editor_metrico`.

Dos de ellas se simplificaron en el bloque C: `regla_longitud_configuracion_metrica` deriva
el múltiplo de la unidad declarada y solo recorre secciones cuando no hay unidad —es decir,
en las series, donde la sección repetible describe el ritmo interno de la propia serie—; y
`normalizar_extension_configuracion_metrica` desapareció con el campo que protegía, junto
con `normalizar_extensiones_al_cambiar_nivel_metrico`.

En el código, [editor-model.ts](../../src/lib/components/metrica/editor-v2/editor-model.ts)
derivaba la repetición del pasaje de las secciones raíz
—`flatRepeatedMetricSection`, `flatVariableRepeatedMetricSection`,
`hierarchicalRepeatedMetricSection`—. Con la unidad declarada, esas tres funciones son ya
una sola: `metricUnitAnchor`, que dice dónde se materializa la unidad —en la única sección
raíz, si la arquitectura la tiene; en ninguna, si no— y cuánto mide.

## 5 · Orden de la migración

Cuatro bloques, en este orden y con el código de cada uno en el mismo commit.

Antes de aplicar el bloque A se hizo una copia de seguridad completa de la base enlazada
en `backups/supabase/20260730-180007/` —esquema y datos—. Esa carpeta está en
`.gitignore`, así que no viaja en el repositorio: si hiciera falta revertir, es el punto de
partida. Conviene repetir la copia antes de cada bloque.

**A · Renombrados. Aplicado.** Tablas, columnas y valores controlados; recreación de las
quince funciones que los nombraban y de la vista; `modelo_version` a 43. El informe de
conformidad dio exactamente los mismos 53 defectos antes y después, que era el criterio de
aceptación.

Dos cosas que conviene recordar de su ejecución. Los disparadores de `formas_metricas`
tuvieron que recrearse **antes** de tocar los datos: el primer intento falló al actualizar
`tipo_registro` porque un disparador aún nombraba `configuraciones_forma`. Y renombrar una
vista no renombra sus columnas de salida, así que hubo que eliminarla y recrearla.

**B · Metro unificado. Aplicado.** Tabla `metros` con sus segmentos, absorción de los
modelos de verso, retirada de `patron_acentual` y del `check` de exclusividad.

Las 348 referencias no hubo que reescribirlas: los metros conservan el UUID del término de
origen y el compuesto conserva el del modelo de verso, así que solo cambió la tabla a la
que apuntan las claves ajenas. `esquema_metrico_posiciones.metro_id` es ahora `not null` y
`modelo_verso_id` desapareció. El arte mayor o menor es una columna generada a partir de
las sílabas: no se declara ni puede divergir. El catálogo pasa de ocho metros a nueve,
porque el dodecasílabo simple y el compuesto `6 + 6` dejan de ser el mismo, y el
alejandrino recibe sus dos hemistiquios heptasílabos.

**C · Unidad explícita. Aplicado.** Intervalo en la arquitectura, retirada de las nueve
secciones fantasma, simplificación de la regla de longitud y del modelo del editor;
`modelo_version` a 45.

Es el único bloque que debía mover el informe, y lo movió como estaba previsto: de 53
defectos a 44, con los nueve D11 desaparecidos y ninguna otra regla alterada. De paso se
corrigió en `audit-catalogo-metrico.mjs` una columna que el renombrado del bloque A había
dejado muda: la tabla 2.6 imprimía `notacion` sobre filas que traen `esquema`, así que
mostraba diez esquemas coincidentes sin decir cuáles.

Dos advertencias para quien continúe. Las secciones raíz que envuelven la unidad
—`copla_real`, `novena`, `decima_espinela`, `decima_aumentada`— conservan su repetición
`1–null`, que ya no significa nada: la comprobación de estructura la ignora cuando hay
unidad declarada. Y las arquitecturas con varias secciones raíz —soneto, villancico, zéjel,
seguidilla compuesta— siguen registrando una sola unidad por secuencia, porque la unidad no
se materializa en una sola realización y no hay nada que la agrupe. Un pasaje de tres
sonetos sigue sin poder registrarse; hacerlo posible pide una realización de la unidad que
envuelva a las secciones raíz, y eso no entraba aquí.

**D · Limpieza. Aplicado.** Familias fuera; `tipo_relacion` y `es_principal` fuera; tipo
`posterior` y destino a variedad en las denominaciones; restricciones renombradas.

Las tres familias pobladas no aportaban ningún vínculo que `forma_relaciones` no exprese ya
—`terceto_encadenado relacionada_con terceto`, `pareados_endecasilabos relacionada_con
pareado`, `decima_espinela sucede_historicamente_a copla_real`, `decima_aumentada
derivada_de decima_espinela`—, así que retirarlas no pierde información. Lo que colgaba de
una familia —una afirmación bibliográfica y una traza de migración— pasa a colgar de la
forma que la representaba.

Ciento ochenta identificadores —restricciones, índices, políticas y disparadores— dejaron
de nombrar configuraciones, patrones, combinaciones y unidades. Los nombres de las
funciones entraron después, en una migración aparte, porque renombrarlas obliga a recrear
la vista de reglas de longitud y a cambiar el nombre de un parámetro que la ruta de API
pasa por su nombre.

Al releer esos cuerpos apareció un resto del bloque A que nadie había ejecutado:
`sincronizar_posiciones_patron_rima_fijo` seguía leyendo `new.esquema`, la columna que
aquel bloque renombró a `notacion`. El disparador salta al insertar o actualizar un esquema
de rima, así que cualquier alta de un esquema `secuencia_fija` habría fallado con «record
"new" has no field "esquema"». Desde el bloque A no se dio de alta ninguno, y por eso no se
notó.

El bloque A fue el más ruidoso y el que menos riesgo tenía, porque no cambiaba significado.
B y C sí lo cambian y cada uno debía dejar el informe de conformidad en un estado
explicable: A y B no lo movieron, y C hizo desaparecer los nueve defectos D11 sin tocar
ninguna otra regla. La unidad envolvente y el bloque D tampoco lo movieron: 44 defectos
antes y después, regla por regla.

## 6 · Lo que no entra

- La capa de observación con sus dos modos, y con ella la posibilidad de describir un tramo
  sin forma.
- La corrección de los defectos de datos del informe, que necesita al IP: el triaje está en
  [cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md).
- El sellado de la revisión del catálogo en cada anotación.
- La reescritura del demarcador para que consuma rasgos y elecciones en lugar de su vector
  fijo de nueve.

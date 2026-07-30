# Contrato de implementación del dominio métrico

Estado: vigente · bloque A aplicado el 30 de julio de 2026

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
- **Existe una barrera de versión.** `catalogo_metrico_estado.modelo_version` vale hoy
  `42`, y [catalogo-metrico.ts:293](../../src/lib/server/catalogo-metrico.ts#L293) muestra
  «falta aplicar migraciones» si es menor. Protege la dirección «base sin migrar, código
  nuevo», pero **no la contraria**: código antiguo contra base migrada pasaría la
  comprobación y fallaría al consultar tablas renombradas. Migración y código deben
  entrar juntos.
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

### 3.1 · La unidad no se declara en ninguna parte

Es el hueco que arrastra a los demás. Hoy la extensión de la unidad vive en tres sitios
distintos según la forma: en `numero_versos` cuando es fija y la forma es estrofa o
composición; en una sección raíz cuando alguien la creó; y en ninguna parte para lira,
octava real, terceto, sexta rima y pareado, que por eso **no pueden materializar sus
unidades** aunque la regla de longitud funcione.

`numero_versos` no basta: la unidad puede tener rango. La copla de pie quebrado va de 5 a
12 versos y hoy ese intervalo lo lleva una sección fantasma. La migración
[20260728159000](../../supabase/migrations/20260728159000_numero_versos_configuracion.sql)
sustituyó `versos_min`/`versos_max` por `numero_versos` porque entonces ninguna
configuración tenía extremos distintos; con la unidad explícita vuelve a hacer falta el
intervalo, ahora por una razón documentada.

**Cambio:** la arquitectura declara `unidad_versos_min` y `unidad_versos_max`; fija cuando
coinciden. `numero_versos` desaparece absorbida. Las nueve secciones fantasma se retiran, y
con ellas el trigger que anula la extensión según el nivel, que existía solo para
proteger un campo mal ubicado.

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

### 3.3 · La respuesta que define la norma no se distingue de una elección

La canción petrarquista y el sexteto usan `tipo_control = 'esquema_rima'` con
`alcance = 'unidad'` y `permite_aplicar_global`. Funciona, pero dice otra cosa de la que
ocurre: no es una respuesta por unidad que casualmente se repite, es **una declaración que
rige toda la secuencia**. Con el modelo actual nada impide guardar estancias con esquemas
distintos en una canción, que es justo lo que su norma prohíbe.

**Cambio:** un `alcance = 'norma_de_secuencia'`, o un booleano `define_norma`, que obligue
a una sola respuesta por secuencia y la aplique a todas las unidades. Es pequeño y evita
que el editor pueda guardar algo que la forma no admite.

### 3.4 · Los tramos sin forma no tienen dónde describirse

No es un hueco del catálogo sino de la capa de anotación: solo existe
`desviaciones_editor_metrico`, que es comparativa por construcción —tiene
`relacion_norma` obligatorio—. Sin norma no hay nada con lo que comparar, así que hoy un
tramo irregular no puede registrar ni sus metros.

**Cambio:** la capa de observación necesita dos modos, descriptivo y comparativo. **Queda
fuera de esta migración**: pertenece a la capa de anotación, que se diseña junto con la de
las secuencias reales. Se registra aquí para que no se pierda.

### 3.5 · Detalles menores del mismo bloque

- `denominaciones_metricas` no admite apuntar a una variedad, y sus restricciones
  conservan el nombre `forma_aliases_*` de antes del renombrado.
- El tipo `posterior` no existe: «Cuarteta» está registrada como `equivalente`, lo que
  afirma que así se las llamaba en el Siglo de Oro.
- `formas_tradiciones` obliga a un `tipo_relacion` que el dato de origen no tiene, y su
  `es_principal` protege una invariante vacía cuando la pertenencia es única.

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

Dos de ellas se simplifican con el cambio: `regla_longitud_configuracion_metrica` deja de
recorrer secciones para derivar el múltiplo, porque la unidad lo declara; y
`normalizar_extension_configuracion_metrica` desaparece con el campo que protegía.

En el código, [editor-model.ts](../../src/lib/components/metrica/editor-v2/editor-model.ts)
deriva hoy la repetición del pasaje de las secciones raíz
—`flatRepeatedMetricSection`, `flatVariableRepeatedMetricSection`,
`hierarchicalRepeatedMetricSection`—. Con la unidad declarada, esas tres funciones se
sustituyen por una sola.

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

**B · Metro unificado.** Tabla nueva, absorción de los modelos de verso, repunte de las 348
referencias, retirada de `patron_acentual` y del `check` de exclusividad.

**C · Unidad explícita.** Intervalo en la arquitectura, retirada de las nueve secciones
fantasma, simplificación de la regla de longitud y del modelo del editor.

**D · Limpieza.** Familias fuera; `tipo_relacion` y `es_principal` fuera; tipo `posterior`
y destino a variedad en las denominaciones; restricciones renombradas.

El bloque A es el más ruidoso y el que menos riesgo tiene, porque no cambia significado. B
y C sí lo cambian y cada uno debe dejar el informe de conformidad en un estado explicable:
C, en particular, debe hacer desaparecer los nueve defectos D11.

## 6 · Lo que no entra

- La capa de observación con sus dos modos, y con ella la posibilidad de describir un tramo
  sin forma.
- La población de tradiciones desde `tipo_forma`.
- La corrección de los defectos de datos del informe.
- El sellado de la revisión del catálogo en cada anotación.
- La reescritura del demarcador para que consuma rasgos y elecciones en lugar de su vector
  fijo de nueve.

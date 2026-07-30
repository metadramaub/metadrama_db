# Especificación de tablas del catálogo métrico (histórico)

Fecha: 28 de julio de 2026 · **Documento superado**

Esta era la especificación tabla por tabla con la que se implementó la primera fase del
catálogo. Ya no describe el esquema vigente: faltan `tipo_registro`,
`combinaciones_patrones_configuracion`, `denominaciones_metricas`, `numero_versos`,
`configuracion_referenciada_id`, `tipo_control` y los disparadores de validación, y
describe campos retirados como `naturaleza_estrofica_id` o la longitud declarada en
`patrones_metricos`.

La fuente de verdad del esquema es la base de datos:
`npx supabase db dump --linked -f esquema.sql`. El estado de los datos poblados se
comprueba con `npm run audit:metrica`.

Se conserva por el razonamiento de diseño que contiene, no como referencia técnica.

---

## 8. Catálogo formal

### 8.1. `formas_metricas`

Representa una identidad métrica seleccionable o una salida editorial residual.

| Campo | Tipo orientativo | Regla |
| --- | --- | --- |
| `forma_id` | `uuid` | Clave estable. Cuando sea posible se reutilizará el UUID legado. |
| `slug` | `text` | Único, normalizado y estable. |
| `nombre` | `text` | Nombre preferido visible. |
| `definicion` | `text` | Definición editorial. |
| `nivel_estructural_id` | FK | Verso, estrofa, serie, composición o forma compuesta. |
| `tipo_registro` | valor controlado | `forma` o `salida_editorial`. La segunda no admite configuración normativa. |
| `seleccionable` | `boolean` | Puede asignarse a una secuencia. |
| `residual` | `boolean` | Solo se ofrece cuando no encaja una forma más precisa; puede marcar una forma estructurada residual o una salida editorial. |
| `estado_revision` | FK o valor controlado | Borrador, revisada, aprobada o retirada. |
| `activo` | `boolean` | Disponible para nuevos usos. |
| `orden` | `integer` | Orden técnico opcional. No se muestra en la edición ordinaria ni expresa jerarquía semántica. |
| `created_at` / `updated_at` | `timestamptz` | Auditoría técnica. |

`arte_metrico` no se almacenará como verdad primaria: se derivará de las configuraciones métricas. El origen español o italiano tampoco actuará como rasgo demarcador; si se conserva, será una relación documentada con una tradición.

### 8.2. `familias_metricas`

Representa agrupaciones estructurales, comparativas o de navegación. Las tradiciones históricas se modelan por separado para evitar que «española» o «italiana» funcionen como padres que transmiten rasgos métricos.

Campos mínimos:

- `familia_id`;
- `slug`;
- `nombre`;
- `descripcion`;
- `familia_padre_id`, solo si se necesita una navegación anidada;
- `estado_revision`;
- `orden`, únicamente si en el futuro se necesita una presentación manual;
- `activo`.

Una familia no será asignable a `secuencias_metricas`.

### 8.3. `familias_formas`

Relación potencialmente muchos-a-muchos:

- `familia_id`;
- `forma_id`;
- `es_principal`;
- `orden`, únicamente como preferencia técnica de presentación;
- `nota`.

`es_principal` permitirá ofrecer un árbol sencillo en las interfaces sin negar otras pertenencias válidas.

### 8.4. `tradiciones_metricas` y `formas_tradiciones`

`tradiciones_metricas` representa ámbitos históricos o culturales respaldados por fuentes. Nombres como tradición española, italiana o provenzal son categorías posibles, no pertenencias que deban inferirse ni precargarse como hechos:

- `tradicion_id`;
- `slug`;
- `nombre`;
- `descripcion`;
- ámbito cronológico y geográfico opcional;
- `estado_revision`;
- `activo`.

`formas_tradiciones` expresa una relación muchos-a-muchos:

- `forma_id`;
- `tradicion_id`;
- `tipo_relacion`: origen, adaptación, difusión o uso;
- `es_principal`;
- `fuente_id`;
- cronología y nota, cuando procedan.

Una forma podrá proceder de una tradición, adaptarse en otra y pertenecer simultáneamente a familias estructurales. La tradición podrá utilizarse como faceta o nodo de una red histórica, pero no como pregunta ordinaria del demarcador ni como propiedad heredable.

### 8.5. `denominaciones_metricas`

- `alias_id`;
- exactamente un destino: forma, configuración, patrón métrico, patrón de rima,
  sección o patrón de repetición;
- `nombre`;
- `slug_normalizado`;
- `tipo_alias`: equivalente, variante gráfica, nombre histórico o abreviatura;
- `idioma`;
- `preferente`;
- `fuente_id`, si procede.

Las denominaciones no crean configuraciones ni pueden asignarse como formas
independientes. Deben apuntar al nivel exacto que nombran: «Cuarteta», por ejemplo,
puede denominar el patrón cruzado `abab` de redondilla sin extenderse a sus demás
realizaciones.

### 8.6. `forma_relaciones`

Relaciones entre dos formas reales:

- `forma_origen_id`;
- `forma_destino_id`;
- `tipo_relacion`;
- `cantidad_min` y `cantidad_max`, solo para relaciones compositivas;
- `orden_composicion`, cuando intervienen varios tipos de componente;
- `nota`;
- `estado_revision`;
- `fuente_id`.

Tipos iniciales posibles:

- `subtipo_de`;
- `variante_historica_de`;
- `derivada_de`;
- `compuesta_por`;
- `relacionada_con`;
- `contrasta_con`.

`equivalente_de` se reservará para equivalencias conceptuales reales. Los nombres
alternativos irán en `denominaciones_metricas`.

`subtipo_de` expresa taxonomía; `compuesta_por`, arquitectura. Por ejemplo, la copla
manriqueña es subtipo de doble sextilla y está compuesta por dos sextillas. Ninguna de
esas relaciones convierte automáticamente `sextilla` en padre taxonómico.

## 9. Configuraciones formales

### 9.1. `configuraciones_forma`

Una configuración es una realización estructural admitida por una forma.

| Campo | Función |
| --- | --- |
| `configuracion_id` | Clave estable. |
| `forma_id` | Forma a la que pertenece. |
| `slug` / `nombre` | Identificación editorial de la alternativa. |
| `descripcion` | Explicación de la configuración. |
| `principal` | Configuración prototípica opcional. Puede no existir ninguna y solo puede existir una por forma. |
| `demarcable` | Puede intervenir en la compilación del demarcador. |
| `grado` | Fija, canónica, admitida, rara o irregular documentada. |
| `numero_versos` | Número fijo total; solo se declara directamente en estrofas y composiciones simples. |
| `estado_revision` | Flujo de aprobación. |
| `activo` | Disponible para nuevos usos. |

Una configuración puede existir sin recibir un nombre público. Un cambio que solo afecta a
la distribución de la rima no crea por sí mismo otra configuración: `ababa` y `abbab`, por
ejemplo, son patrones alternativos de la misma configuración de quintilla.

### 9.2. `patrones_metricos`

Describe el comportamiento de las medidas dentro de una configuración:

- `patron_metrico_id`;
- `configuracion_id`;
- `nombre`, breve y necesario para distinguir varios patrones en una misma configuración;
- `ambito`: estrofa, serie, sección o composición;
- `tipo`: secuencia fija, conjunto permitido, secuencia repetible o abierta;
- `descripcion`;
- `estado_revision`.

El valor técnico legado `unidad` se conserva temporalmente para poder revisar la importación, pero no se ofrecerá para crear patrones nuevos. Toda aparición debe precisarse como estrofa, serie, sección o composición.

`numero_versos` describe la extensión fija de una estrofa o composición simple. No se
almacena para versos, series ni formas compuestas: en estas últimas, la extensión se obtiene
de las secciones y sus repeticiones. La antigua `naturaleza_estrofica_id` no se conserva en
la configuración, porque duplicaba el nivel estructural y mezclaba en un mismo eje estrofa,
serie, composición, composición interna e irregularidad. En patrones posicionales, la
longitud se calcula a partir de las posiciones: las obligatorias determinan el mínimo y el
total de obligatorias y opcionales determina el máximo. No se almacena una segunda
extensión en `patrones_metricos`.

### 9.3. `patron_metrico_posiciones`

Conserva el orden cuando existe:

- `patron_metrico_id`;
- `posicion`;
- `metro_id` o `modelo_verso_id`, con una restricción de exclusividad;
- `opcional`;
- `grupo_repeticion`;
- `alternativa`;
- `nota`.

Para una sextilla manriqueña se podrán declarar posiciones ordenadas como `8, 8, 4, 8, 8, 4`. Las alternativas no se reducirán al conjunto `{4, 8}`.

Los metros podrán mantenerse inicialmente como catálogo controlado existente, pero deberán quedar tras una FK de dominio validada. En una fase posterior podrá valorarse extraer también `metro` de `vocabularios`.

### 9.4. `modelos_verso` y `modelo_verso_segmentos`

El número total de sílabas no basta para representar versos compuestos. `modelos_verso` describirá la estructura interna esperada:

- `modelo_verso_id`;
- `metro_id`, si existe un metro total normalizado;
- `tipo`: simple o compuesto;
- `silabas_totales`;
- presencia y tipo de cesura;
- patrón acentual, solo cuando sea necesario y observable;
- descripción y estado de revisión.

`modelo_verso_segmentos` conservará:

- `modelo_verso_id`;
- `posicion`;
- `silabas`;
- función, como primer o segundo hemistiquio;
- pausa posterior;
- alternativa y nota.

Así puede distinguirse un dodecasílabo compuesto `6 + 6` de cualquier verso de doce sílabas sin convertir esa diferencia en texto libre. Este nivel es necesario, entre otros casos, para la copla de arte mayor.

### 9.5. `patrones_rima`

- `patron_rima_id`;
- `configuracion_id`;
- `esquema`;
- `regimen_rima_id`;
- `ambito`;
- `comportamiento`: secuencia fija, secuencia repetible, restricciones combinatorias o distribución libre;
- `fijeza`: fijo, admitido, preferente, libre o no aplicable;
- `descripcion`;
- `estado_revision`.

Convenciones mínimas:

- letras iguales representan correspondencia de rima;
- mayúsculas y minúsculas podrán codificar arte métrico solo si se conserva expresamente esa convención;
- `-` o `X` representarán verso no rimado con una única política documentada;
- las vocales concretas de una asonancia no se incrustarán en la identidad de la forma.

`comportamiento` aporta la lógica computable y `fijeza` expresa el grado de obligatoriedad de esa lógica. El esquema textual queda como representación humana. Por ejemplo, el romance se almacena como ciclo repetible de dos posiciones —impar suelto y par en la clase `a`—, aunque se muestre como `-a-a-a…`.

### 9.6. `patron_rima_posiciones`, `patron_rima_enlaces` y restricciones

Un esquema de letras aislado no expresa todos los casos. `patron_rima_posiciones` permitirá declarar:

- bloque, sección y posición;
- ubicación de la rima: final o interior del verso;
- clase funcional de rima;
- verso suelto esperado;
- opcionalidad y nota.

`patron_rima_enlaces` expresará correspondencias entre posiciones:

- posición de origen;
- posición de destino o desplazamiento al bloque siguiente;
- tipo de enlace;
- obligatoriedad.

Esto permite formalizar:

- `ABA | BCB | CDC`, donde la rima central de un terceto pasa a las posiciones exteriores del siguiente;
- la relación entre vuelta y estribillo en villancico o zéjel;
- la rima del final de un verso con un grupo interior del siguiente en el endecasílabo suelto encadenado.

`patron_rima_restricciones` conservará reglas combinatorias cerradas cuando la identidad no dependa de un único esquema, por ejemplo:

- número de clases de rima;
- máximo de versos consecutivos con la misma rima;
- prohibición de pareado final;
- admisión o exclusión de versos sueltos.

No se introducirán porcentajes exactos para traducir expresiones como «mayoría». Esas expresiones se conservarán como modalidades cualitativas —definitoria, habitual, admitida o destacable— salvo que una fuente y un objetivo analítico justifiquen expresamente otra cosa.

### 9.6.1. `combinaciones_patrones_configuracion`

Se utiliza cuando una configuración admite varios patrones métricos y varios patrones
de rima, pero no todas sus parejas son válidas. Cada fila enlaza:

- una configuración;
- un patrón métrico de esa configuración;
- un patrón de rima de esa configuración;
- un nombre y un `slug` estables;
- su condición preferente o admitida;
- estado de revisión, orden y término de origen.

La combinación no es una forma ni una configuración adicional. Es una tipología
elegible de la misma norma. El sexteto-lira, por ejemplo, contiene cinco patrones
métricos y tres de rima, pero solo siete combinaciones reconocidas por el proyecto.
Sin esta entidad, dos desplegables independientes producirían quince parejas posibles
o se necesitarían siete configuraciones artificiales.

### 9.7. `estructuras_secciones`

Necesaria para villancico, zéjel, sextina, canción y otras formas compuestas:

- `seccion_id`;
- `configuracion_id`;
- `seccion_padre_id`;
- `tipo_seccion_id`;
- `orden`;
- `repeticiones_min`;
- `repeticiones_max`;
- `versos_min`;
- `versos_max`;
- `configuracion_referenciada_id`, si la sección realiza una configuración ya
  formalizada de otra forma;
- `patron_metrico_id`, si la sección tiene uno;
- `patron_rima_id`, si la sección tiene uno.

Cuando una sección tiene extensión o repetición fija, se almacena el mismo valor en el
extremo mínimo y máximo. Esto mantiene una única representación capaz de expresar también
intervalos reales: `3–3` significa tres versos; `2–4`, una extensión variable; y un máximo
nulo, ausencia de límite superior. La interfaz solicita un solo número para el caso fijo.

La relación recursiva se limitará a la estructura interna de una configuración y no sustituirá las familias.

La configuración referenciada permite composición sin duplicación. Una novena puede
declarar secciones que realizan una redondilla y una quintilla, y sus preguntas
editoriales reutilizan los patrones normalizados de esas configuraciones. La sección
sigue perteneciendo a la novena; la referencia solo aporta la norma del componente.

### 9.8. `patrones_repeticion`

Representa repeticiones que no son reducibles al esquema de rima:

- `patron_repeticion_id`;
- `configuracion_id`;
- `tipo`: palabra final, verso, estribillo, sección u otro valor controlado;
- `ambito`;
- `regla`;
- `fijeza`;
- `descripcion`;
- `estado_revision`.

Cuando el orden sea relevante, `patron_repeticion_posiciones` declarará:

- bloque o iteración;
- posición;
- posición de origen o referencia;
- etiqueta funcional;
- condición opcional.

Esta dimensión permite formalizar, por ejemplo, la permutación de palabras finales de la sextina o la repetición del estribillo de una forma compuesta sin confundirlas con rima convencional.

### 9.9. `grupos_eleccion_metrica` y `opciones_eleccion_metrica`

El catálogo debe distinguir entre una posibilidad formalizada y una posibilidad que interesa
preguntar al editor. Un dato con un único resultado se deriva de la configuración; no genera
un control redundante. Cuando existen alternativas admitidas con valor para el corpus, un
grupo de elección declara:

- configuración;
- pregunta y ayuda editorial;
- dimensión: medida, rima, estructura, repetición o rasgo;
- alcance: una vez por secuencia o en cada unidad interna aplicable;
- sección a la que se aplica, cuando corresponda;
- cardinalidad mínima y máxima;
- posibilidad de aplicar una respuesta a todas las unidades equivalentes;
- orden, actividad y estado de revisión.

Cada opción referencia mediante FK una entidad ya normalizada: metro, patrón métrico,
patrón de rima, sección, patrón de repetición, rasgo o valor de rasgo. Esta capa no es un EAV
abierto ni duplica la ontología. Define qué parte de la ontología se presenta como elección
editorial.

Una opción puede declarar efectos de interfaz separados de su valor semántico:

- `materializa_seccion_id`: la respuesta implica una sección material cuyo rango debe
  conservarse;
- `extension_desde_seccion_id`: la longitud de esa sección se deriva de otra realización.
- `posicion_unidad`: el valor normalizado se aplica a una posición concreta dentro de la
  unidad, como un tetrasílabo en una copla real.

Así, «repetición total» sigue siendo un patrón de repetición, pero puede materializar un
represa con la extensión de la primera aparición del estribillo, sea una cabeza inicial o
un estribillo posterior a la primera copla. Una respuesta implícita no crea versos ficticios.

Ejemplos:

- la quintilla puede ofrecer sus esquemas admitidos como opciones de rima;
- el villancico puede preguntar `abba` o `abab` en cada mudanza;
- un conjunto permitido de hexasílabos y octosílabos puede admitir una o ambas respuestas;
- la presencia de una sección opcional se registra mediante su unidad, sin duplicarla con
  una respuesta booleana;
- los modos total, parcial e implícito de un estribillo deben ser patrones de repetición
  diferenciados si interesa analizarlos por separado.
- una configuración con pies quebrados puede ofrecer posiciones numeradas que apuntan
  todas al metro corto, sin crear un rasgo distinto para cada verso.

## 10. Rasgos métricos

### 10.1. `rasgos_metricos`

Catálogo de propiedades transversales:

- `rasgo_id`;
- `slug`;
- `nombre`;
- `definicion`;
- `tipo_valor`: booleano, categoría, número o texto controlado;
- `observable_por_editor`;
- `util_demarcador`;
- `activo`.

Ejemplos:

- pie quebrado;
- mayoría de finales esdrújulos;
- dístico final;
- pareados intercalados;
- rima interna encadenada;
- vocales de la asonancia, si se decide tratarlas como rasgo consultable.

`Hipométrico`, `hipermétrico`, ruptura de rima o alteración de una sección no se modelarán automáticamente como rasgos. Son relaciones entre una realización y su configuración normativa y pertenecen a la capa de observaciones por rango.

### 10.2. `rasgo_valores`

Para rasgos categóricos:

- `rasgo_valor_id`;
- `rasgo_id`;
- `slug`;
- `nombre`;
- `orden`.

### 10.3. `configuracion_rasgos`

Declara cómo interviene un rasgo en una configuración:

- `configuracion_id`;
- `rasgo_id` o `rasgo_valor_id`;
- `modalidad`: definitorio, requerido, habitual, admitido, preferente o excluido;
- valor normalizado, cuando corresponda;
- fuente y nota.

No se utilizará esta tabla como EAV general para tamaño, metros o rima: esas dimensiones conservan tablas específicas.

## 11. Procedencia y revisión

### 11.1. `fuentes_metricas`

- `fuente_id`;
- tipo bibliográfico;
- autoría;
- título;
- año;
- datos de publicación;
- DOI o URL;
- cita normalizada;
- nota.

### 11.2. Enlaces de procedencia

Las afirmaciones podrán vincular fuentes con:

- formas;
- configuraciones;
- patrones;
- relaciones;
- rasgos.

La implementación deberá conservar integridad referencial. Se prefieren tablas de enlace específicas o una tabla con FKs opcionales y una restricción que exija exactamente un destino, frente a un par polimórfico sin FK.

Cada enlace podrá declarar:

- localizador o página;
- fragmento resumido;
- responsable de la interpretación;
- nivel de confianza;
- estado de revisión.


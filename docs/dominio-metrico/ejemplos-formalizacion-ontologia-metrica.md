# Ejemplos de formalización con la ontología métrica

Fecha: 28 de julio de 2026

Estado: documento explicativo del modelo propuesto

Documentos relacionados:

- [Propuesta conceptual](./propuesta-dominio-metrica.md)
- [Arquitectura del dominio métrico](./arquitectura-dominio-metrica.md)
- [Matriz de reclasificación](./matriz-reclasificacion-formas-metricas.md)

## 1. Propósito

Este documento muestra cómo se caracterizarán diferentes formas métricas mediante las tablas del dominio. Los ejemplos separan:

1. la definición estable mantenida por el IP;
2. la caracterización de una secuencia realizada por el editor;
3. los datos derivados para demarcación, búsqueda y análisis.

La riqueza del catálogo no implica que el editor tenga que rellenar todas sus tablas. El editor selecciona una forma, una configuración solo cuando sea necesario y las diferencias que observe. En una secuencia guardada, todo lo no señalado como diferencia se considera conforme con la configuración.

## 2. Tablas y responsabilidades

### Catálogo formal

Estas tablas definen la ontología y son mantenidas por el IP o por responsables autorizados:

| Tabla | Función |
| --- | --- |
| `formas_metricas` | Identidades métricas asignables. |
| `familias_metricas` | Agrupaciones organizativas no asignables. |
| `familias_formas` | Pertenencia de formas a familias. |
| `tradiciones_metricas` | Tradiciones históricas o culturales no heredables. |
| `formas_tradiciones` | Origen, adaptación, difusión o uso de una forma en una tradición. |
| `forma_aliases` | Nombres alternativos. |
| `forma_relaciones` | Relaciones tipadas entre formas. |
| `configuraciones_forma` | Realizaciones estructurales admitidas por una forma. |
| `patrones_metricos` | Tipo, alcance y longitud de los patrones de medida. |
| `patron_metrico_posiciones` | Medida ordenada de cada posición. |
| `modelos_verso` | Estructura simple o compuesta de un verso. |
| `modelo_verso_segmentos` | Hemistiquios, cesura y segmentos internos. |
| `patrones_rima` | Régimen, esquema, alcance y fijeza de la rima. |
| `patron_rima_posiciones` | Posiciones finales o internas de rima. |
| `patron_rima_enlaces` | Correspondencias entre versos, unidades o secciones. |
| `patron_rima_restricciones` | Reglas combinatorias como las de la quintilla. |
| `estructuras_secciones` | Partes internas y repeticiones de una forma compuesta. |
| `patrones_repeticion` | Repetición de palabras, versos, estribillos o secciones. |
| `patron_repeticion_posiciones` | Orden y correspondencias de una repetición. |
| `rasgos_metricos` | Propiedades transversales. |
| `rasgo_valores` | Valores controlados de un rasgo. |
| `configuracion_rasgos` | Rasgos requeridos, admitidos, preferentes o excluidos. |
| `fuentes_metricas` | Fuentes bibliográficas normalizadas. |

### Anotación editorial

Estas tablas describen una obra concreta:

| Tabla | Función |
| --- | --- |
| `secuencias_metricas` | Rango de la secuencia y forma identificada. |
| `secuencia_configuraciones` | Configuración reconocida en la secuencia. |
| `unidades_metricas` | Unidades internas y sus rangos. |
| `secuencia_observaciones_metricas` | Rango, dimensión y relación con la norma. |
| `secuencia_metros_observados` | Medida exacta o relación menor/mayor que la esperada. |
| `secuencia_rima_observada` | Diferencia de rima y detalle opcional. |
| `secuencia_rasgos_observados` | Rasgos normalizados adicionales. |
| `secuencia_estructura_observada` | Alteraciones de estructura o secciones. |
| `secuencia_repeticion_observada` | Alteraciones de repeticiones y enlaces. |

### Datos derivados

El sistema combina catálogo y anotación para generar:

- candidatas y preguntas del demarcador;
- facetas de forma, metro, rima, configuración y rasgo;
- perfiles métricos de obras y autores;
- representaciones estructuradas para fichas;
- advertencias de coherencia para los editores.

## 3. Esquema general

```mermaid
flowchart LR
    subgraph CAT["Catálogo formal · mantenido por el IP"]
        F["formas_metricas"]
        CF["configuraciones_forma"]
        PM["patrones_metricos"]
        PMP["patron_metrico_posiciones"]
        PV["modelos_verso"]
        PVS["modelo_verso_segmentos"]
        PR["patrones_rima"]
        PRP["patron_rima_posiciones"]
        PREN["patron_rima_enlaces"]
        ES["estructuras_secciones"]
        PRE["patrones_repeticion"]
        RM["rasgos_metricos"]
        CR["configuracion_rasgos"]
        FU["fuentes_metricas"]

        F --> CF
        CF --> PM
        PM --> PMP
        PMP --> PV
        PV --> PVS
        CF --> PR
        PR --> PRP
        PRP --> PREN
        CF --> ES
        CF --> PRE
        CF --> CR
        RM --> CR
        FU -. documenta .-> F
        FU -. documenta .-> CF
        FU -. documenta .-> PM
        FU -. documenta .-> PR
        FU -. documenta .-> RM
    end

    subgraph AN["Anotación · realizada por el editor"]
        SM["secuencias_metricas"]
        SC["secuencia_configuraciones"]
        UM["unidades_metricas"]
        OM["secuencia_observaciones_metricas"]
        MO["secuencia_metros_observados"]
        RO["secuencia_rima_observada"]
        RSO["secuencia_rasgos_observados"]

        SM --> SC
        SM --> UM
        SM --> OM
        OM --> MO
        OM --> RO
        OM --> RSO
    end

    SM --> F
    SC --> CF
    UM --> CF

    CAT --> DER["Proyecciones derivadas"]
    AN --> DER
    DER --> DEM["Demarcador"]
    DER --> BUS["Búsqueda y filtros"]
    DER --> LAB["Laboratorio"]
```

## 4. Copla real

### Definición ontológica

```mermaid
flowchart TB
    F["formas_metricas<br/>copla_real"]
    FA["familias_metricas<br/>coplas_de_diez_versos"]
    FF["familias_formas<br/>copla_real pertenece a la familia"]

    C1["configuraciones_forma<br/>sin_pie_quebrado · principal"]
    C2["configuraciones_forma<br/>con_pie_quebrado"]

    PM1["patrones_metricos<br/>secuencia fija · 10 versos"]
    PP1["patron_metrico_posiciones<br/>10 posiciones de 8 sílabas"]

    PM2["patrones_metricos<br/>secuencia fija · 10 versos"]
    PP2["patron_metrico_posiciones<br/>8 y 4 sílabas en posiciones declaradas"]

    PR1["patrones_rima<br/>sin_pie_quebrado<br/>consonante · esquema no fijo"]
    PR2["patrones_rima<br/>con_pie_quebrado<br/>consonante · esquema no fijo"]
    RG["rasgos_metricos<br/>pie_quebrado"]
    CR["configuracion_rasgos<br/>con_pie_quebrado requiere pie_quebrado"]

    ES["estructuras_secciones<br/>quintilla 1 + quintilla 2<br/>pausa después del verso 5"]

    FA --> FF
    F --> FF
    F --> C1
    F --> C2
    C1 --> PM1
    PM1 --> PP1
    C2 --> PM2
    PM2 --> PP2
    C1 --> PR1
    C2 --> PR2
    C1 --> ES
    C2 --> ES
    C2 --> CR
    RG --> CR
```

### Ejemplo de secuencia

Supongamos una secuencia de diez versos con el patrón observado:

`8, 8, 4, 8, 8 | 8, 8, 4, 8, 8`

| Tabla | Registro conceptual |
| --- | --- |
| `secuencias_metricas` | Rango de diez versos y `forma_metrica_id = copla_real`. |
| `secuencia_configuraciones` | `configuracion_id = con_pie_quebrado`. |

El patrón 8/4 y el rasgo pie quebrado ya se infieren de la configuración. No se duplican como observaciones. Solo se crearía una observación si alguno de los versos difiriera del patrón.

### Interacción del editor

| Nivel | Acción |
| --- | --- |
| Mínimo | Seleccionar “Copla real”. |
| Recomendado | Indicar “Con pie quebrado”. |
| Avanzado | Registrar la secuencia exacta de medidas. |

### Utilidad

- El demarcador compara dos configuraciones completas sin descartar la forma por aparecer tetrasílabos.
- La búsqueda puede combinar forma `copla_real`, metro 4 y rasgo pie quebrado.
- El perfil general sigue contando una sola forma: copla real.

## 5. Romance

### Definición ontológica

```mermaid
flowchart TB
    F["formas_metricas<br/>romance"]
    FA["familias_metricas<br/>series_asonantadas"]
    FF["familias_formas"]
    C["configuraciones_forma<br/>octosilabico_asonante · principal"]

    PM["patrones_metricos<br/>secuencia abierta y repetible"]
    PMP["patron_metrico_posiciones<br/>cada verso: 8 sílabas"]

    PR["patrones_rima<br/>pares: asonantes<br/>impares: sueltos"]

    RT["rasgos_metricos<br/>vocales_asonancia"]
    RV1["rasgo_valores<br/>a-a"]
    RV2["rasgo_valores<br/>e-o"]
    RV3["rasgo_valores<br/>o-a"]

    FA --> FF
    F --> FF
    F --> C
    C --> PM
    PM --> PMP
    C --> PR
    RT --> RV1
    RT --> RV2
    RT --> RV3
```

### Ejemplo de secuencia

Una serie octosilábica presenta asonancia `e-o` en los versos pares.

| Tabla | Registro conceptual |
| --- | --- |
| `secuencias_metricas` | Rango de la serie y `forma_metrica_id = romance`. |
| `secuencia_configuraciones` | Puede omitirse si solo existe una configuración principal inequívoca. |
| `secuencia_rasgos_observados` | Opcional: `vocales_asonancia = e-o` como valor destacable. |

### Interacción del editor

| Nivel | Acción |
| --- | --- |
| Mínimo | Seleccionar “Romance”. |
| Recomendado | Ninguna acción adicional. |
| Avanzado | Registrar las vocales de la asonancia, si se conocen y resultan útiles. |

### Utilidad

- El demarcador usa metro, extensión y régimen de rima, pero no exige las vocales concretas.
- El buscador puede ofrecer `e-o` como faceta avanzada.
- Todos los valores pertenecen a la misma forma y pueden estudiarse como una dimensión independiente.

## 6. Villancico

### Definición ontológica

```mermaid
flowchart TB
    F["formas_metricas<br/>villancico"]
    C["configuraciones_forma<br/>estructura_habitual"]

    H["estructuras_secciones<br/>cabeza · 0–1 · 2–4 versos"]
    CO["estructuras_secciones<br/>copla · 1–n"]
    MU["estructuras_secciones<br/>mudanza · 4 versos"]
    EN["estructuras_secciones<br/>enlace · opcional"]
    VU["estructuras_secciones<br/>vuelta · opcional"]
    ES["estructuras_secciones<br/>estribillo repetido"]

    PM["patrones_metricos<br/>arte menor · normalmente 6 u 8"]
    PR["patrones_rima<br/>relaciones locales entre secciones"]
    PRE["patrones_repeticion<br/>repetición total o parcial del estribillo"]

    PR1["patrones_rima<br/>ámbito: mudanza<br/>abba"]
    PR2["patrones_rima<br/>ámbito: mudanza<br/>abab"]

    F --> C
    C --> H
    C --> CO
    CO --> MU
    CO --> EN
    CO --> VU
    CO --> ES
    C --> PM
    C --> PR
    C --> PRE
    C --> PR1
    C --> PR2
    MU -. ámbito .-> PR1
    MU -. ámbito .-> PR2

```

### Ejemplo de secuencia

Un villancico presenta cabeza de tres versos, mudanza octosilábica `abba`, vuelta y repetición del estribillo.

| Tabla | Registro conceptual |
| --- | --- |
| `secuencias_metricas` | Rango completo y `forma_metrica_id = villancico`. |
| `secuencia_configuraciones` | `configuracion_id = estructura_habitual`. |
| `unidades_metricas` | Rangos de cabeza, mudanza, vuelta y estribillo. |

La medida, el esquema de la mudanza y los enlaces con vuelta y estribillo proceden de la configuración. Solo se anotan si difieren.

### Interacción del editor

| Nivel | Acción |
| --- | --- |
| Mínimo | Seleccionar “Villancico”. |
| Recomendado | Ninguna acción adicional. |
| Avanzado | Abrir “Describir estructura interna” y delimitar sus secciones. |

### Utilidad

- La ficha puede representar la arquitectura real de la composición.
- El buscador puede localizar villancicos con mudanza en redondilla o con determinada medida.
- El demarcador pregunta por estribillo, mudanza y vuelta solo cuando esas preguntas ayudan.

## 7. Soneto

### Definición ontológica

```mermaid
flowchart TB
    F["formas_metricas<br/>soneto"]
    FA["familias_metricas<br/>formas_fijas"]
    FF["familias_formas"]
    TI["tradiciones_metricas<br/>italiana"]
    TE["tradiciones_metricas<br/>española"]
    FTI["formas_tradiciones<br/>origen"]
    FTE["formas_tradiciones<br/>adaptación y uso"]
    C["configuraciones_forma<br/>endecasilabo_consonante · principal"]

    ES1["estructuras_secciones<br/>cuarteto · 2 × 4 versos"]
    ES2["estructuras_secciones<br/>terceto · 2 × 3 versos"]

    PM["patrones_metricos<br/>endecasílabo repetido"]
    PMP["patron_metrico_posiciones<br/>1 posición de 11 sílabas"]

    PR1["patrones_rima<br/>ABBAABBACDCDCD"]
    PR2["patrones_rima<br/>ABBAABBACDCEDE"]
    PR3["patrones_rima<br/>ABBAABBACDECDE"]
    PR4["patrones_rima<br/>ABBAABBACDEDCE"]

    RG["rasgos_metricos<br/>mayoria_finales_esdrujulos"]
    CR["configuracion_rasgos<br/>rasgo admitido, no requerido"]

    FA --> FF
    F --> FF
    TI --> FTI
    F --> FTI
    TE --> FTE
    F --> FTE
    F --> C
    C --> ES1
    C --> ES2
    C --> PM
    PM --> PMP
    C --> PR1
    C --> PR2
    C --> PR3
    C --> PR4
    C --> CR
    RG --> CR
```

### Ejemplo de secuencia

Un soneto endecasílabo presenta el esquema `ABBAABBACDCEDE` y mayoría de finales esdrújulos.

| Tabla | Registro conceptual |
| --- | --- |
| `secuencias_metricas` | Rango de 14 versos y `forma_metrica_id = soneto`. |
| `secuencia_configuraciones` | Configuración endecasílaba con patrón `ABBAABBACDCEDE`. |
| `secuencia_rasgos_observados` | Mayoría de finales esdrújulos. |
| `unidades_metricas` | Opcional: dos cuartetos y dos tercetos con sus rangos. |

### Interacción del editor

| Nivel | Acción |
| --- | --- |
| Mínimo | Seleccionar “Soneto”. |
| Recomendado | Ninguna acción adicional para el soneto prototípico. |
| Avanzado | Elegir esquema de tercetos y registrar rasgos prosódicos. |

### Utilidad

- Los esquemas de tercetos se comparan sin multiplicar el número de formas.
- El rasgo esdrújulo puede cruzarse con otras formas métricas.
- El demarcador identifica el soneto por su estructura básica antes de preguntar por el esquema exacto.

## 8. Sextina

### Definición ontológica

```mermaid
flowchart TB
    F["formas_metricas<br/>sextina"]
    C["configuraciones_forma<br/>sextina_clasica · principal"]

    E1["estructuras_secciones<br/>6 estrofas"]
    E2["estructuras_secciones<br/>cada estrofa: 6 versos"]
    E3["estructuras_secciones<br/>remate: 3 versos"]

    PM["patrones_metricos<br/>secuencia fija · 39 versos"]
    PMP["patron_metrico_posiciones<br/>39 posiciones de 11 sílabas"]

    PR["patrones_rima<br/>rima convencional: no aplica"]

    PRE["patrones_repeticion<br/>6 palabras finales"]
    PREP["patron_repeticion_posiciones<br/>orden de permutación por estrofa<br/>y presencia en el remate"]

    F --> C
    C --> E1
    E1 --> E2
    C --> E3
    C --> PM
    PM --> PMP
    C --> PR
    C --> PRE
    PRE --> PREP
```

### Ejemplo de secuencia

Una sextina conserva seis palabras finales, las permuta a lo largo de seis estrofas y las recupera en el remate.

| Tabla | Registro conceptual |
| --- | --- |
| `secuencias_metricas` | Rango completo y `forma_metrica_id = sextina`. |
| `secuencia_configuraciones` | `configuracion_id = sextina_clasica`. |
| `unidades_metricas` | Seis estrofas y un remate con sus rangos. |

El metro y la ausencia de rima convencional se infieren de la configuración. Las palabras concretas pertenecen a la realización de la obra y solo se almacenarían si el proyecto incorpora ese nivel de edición; no son necesarias para caracterizar la secuencia.

### Interacción del editor

| Nivel | Acción |
| --- | --- |
| Mínimo | Seleccionar “Sextina”. |
| Recomendado | Ninguna acción adicional. |
| Avanzado | Delimitar estrofas y remate o registrar las palabras finales. |

### Utilidad

- La forma se describe sin forzarla dentro de un patrón de rima convencional.
- La ficha puede mostrar 6 × 6 + 3.
- El demarcador puede preguntar por la permutación de palabras finales cuando las demás respuestas todavía dejan varias candidatas.

## 9. Copla de arte mayor

### Definición ontológica

```mermaid
flowchart TB
    F["formas_metricas<br/>copla_de_arte_mayor"]
    C["configuraciones_forma<br/>canonica"]
    PM["patrones_metricos<br/>8 posiciones"]
    PMP["patron_metrico_posiciones<br/>cada posición usa el modelo compuesto"]
    PV["modelos_verso<br/>dodecasilabo_compuesto"]
    S1["modelo_verso_segmentos<br/>hemistiquio 1 · 6 sílabas"]
    S2["modelo_verso_segmentos<br/>hemistiquio 2 · 6 sílabas"]
    CE["cesura<br/>entre ambos hemistiquios"]

    F --> C
    C --> PM
    PM --> PMP
    PMP --> PV
    PV --> S1
    PV --> S2
    S1 --> CE
    CE --> S2
```

El catálogo no reduce la forma al conjunto `{12}`: conserva que cada verso está compuesto por dos hemistiquios de seis sílabas separados por cesura.

### Interacción del editor

| Nivel | Acción |
| --- | --- |
| Mínimo | Seleccionar “Copla de arte mayor”. |
| Recomendado | Ninguna acción adicional. |
| Diferencia | Indicar el verso y una medida o segmentación diferente, si la hay. |

## 10. Terceto encadenado

### Definición ontológica

```mermaid
flowchart TB
    F["formas_metricas<br/>terceto_encadenado"]
    C["configuraciones_forma<br/>serie_canonica"]
    ES["estructuras_secciones<br/>tercetos repetibles + cierre"]
    PR["patrones_rima<br/>ABA por unidad"]
    P1["patron_rima_posiciones<br/>1:A · 2:B · 3:A"]
    EN["patron_rima_enlaces<br/>unidad n, posición 2<br/>→ unidad n+1, posiciones 1 y 3"]
    CI["regla de cierre<br/>recupera la rima abierta"]

    F --> C
    C --> ES
    C --> PR
    PR --> P1
    P1 --> EN
    EN --> CI
```

La secuencia resultante es `ABA | BCB | CDC | …`. El enlace pertenece al catálogo; no se pide al editor que conecte manualmente los versos.

### Interacción del editor

| Nivel | Acción |
| --- | --- |
| Mínimo | Seleccionar “Terceto encadenado”. |
| Recomendado | Ninguna acción adicional. |
| Diferencia | Marcar el rango donde se rompe el encadenamiento o cambia el cierre. |

## 11. Norma más diferencias

### Medida exacta conocida

Una redondilla octosilábica presenta siete sílabas en el tercer verso:

| Tabla | Registro conceptual |
| --- | --- |
| `secuencias_metricas` | Forma `redondilla`. |
| `secuencia_configuraciones` | Configuración octosilábica `abba`. |
| `secuencia_observaciones_metricas` | Rango del tercer verso, dimensión `medida`. |
| `secuencia_metros_observados` | `metro_observado = 7`; el sistema deriva `menor_que_norma` e hipometría. |

### Solo se conoce la relación

Para una caracterización legada que únicamente dice `hipometrico`:

| Tabla | Registro conceptual |
| --- | --- |
| `secuencia_observaciones_metricas` | Rango de un verso, dimensión `medida`. |
| `secuencia_metros_observados` | `relacion_norma = menor_que_norma`; medida exacta ausente. |

No se inventan seis o siete sílabas.

### Rima diferente sin texto anotado

Un romance rompe la correspondencia esperada en un tramo, pero la base no contiene los finales de verso:

| Tabla | Registro conceptual |
| --- | --- |
| `secuencias_metricas` | Forma `romance`. |
| `secuencia_configuraciones` | Configuración octosilábica asonante. |
| `secuencia_observaciones_metricas` | Rango afectado, dimensión `rima`. |
| `secuencia_rima_observada` | `relacion_norma = ruptura_de_correspondencia`; sin terminación inventada. |

### Ausencia de diferencias

Si el editor guarda una secuencia sin observaciones métricas, el sistema interpreta que cumple completamente la configuración. No existe un estado adicional «revisada» ni una casilla de certeza.

## 12. Qué escribe cada persona

```mermaid
flowchart LR
    IP["IP o responsable del catálogo"]
    ED["Editor de una obra"]
    SYS["Sistema"]

    IP --> CAT["formas_metricas<br/>configuraciones_forma<br/>patrones y rasgos<br/>fuentes_metricas"]

    ED --> SEC["secuencias_metricas<br/>secuencia_configuraciones"]
    ED -. "solo cuando difiere o destaca" .-> DET["unidades_metricas<br/>observaciones métricas por rango"]

    CAT --> SYS
    SEC --> SYS
    DET --> SYS

    SYS --> OUT["Demarcador<br/>fichas<br/>filtros<br/>laboratorio"]
```

El IP formaliza una vez las propiedades generales. El editor identifica la forma y añade únicamente diferencias o rasgos destacables. Lo no anotado se considera conforme con la configuración.

## 13. Regla de diseño de la interfaz

Para cualquier forma:

1. **Siempre visible:** rango y forma.
2. **Pregunta contextual:** configuración, solo cuando diferencia alternativas relevantes.
3. **Diferencias desplegables:** medida, rima, estructura, repetición o rasgo, filtradas por la configuración.
4. **Precisión opcional:** medida exacta o detalle de rima solo cuando se conoce.
5. **Datos derivados:** no se vuelven a pedir al editor.

La ontología aumenta la precisión y la reutilización de los datos, pero la interfaz aplica divulgación progresiva para mantener una edición breve. El editor no declara certeza ni estado de revisión: guardar la secuencia cierra su caracterización bajo la convención de mundo cerrado.

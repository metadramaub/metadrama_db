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

La riqueza del catálogo no implica que el editor tenga que rellenar todas sus tablas. El editor selecciona una forma y, cuando lo sabe, una configuración o una observación adicional. La definición estructurada de la forma ya está disponible en el catálogo.

## 2. Tablas y responsabilidades

### Catálogo formal

Estas tablas definen la ontología y son mantenidas por el IP o por responsables autorizados:

| Tabla | Función |
| --- | --- |
| `formas_metricas` | Identidades métricas asignables. |
| `familias_metricas` | Agrupaciones organizativas no asignables. |
| `familias_formas` | Pertenencia de formas a familias. |
| `forma_aliases` | Nombres alternativos. |
| `forma_relaciones` | Relaciones tipadas entre formas. |
| `configuraciones_forma` | Realizaciones estructurales admitidas por una forma. |
| `patrones_metricos` | Tipo, alcance y longitud de los patrones de medida. |
| `patron_metrico_posiciones` | Medida ordenada de cada posición. |
| `patrones_rima` | Régimen, esquema, alcance y fijeza de la rima. |
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
| `secuencia_metros_observados` | Medidas constatadas en la obra. |
| `secuencia_rima_observada` | Régimen, patrón o timbre constatado. |
| `secuencia_rasgos_observados` | Rasgos adicionales constatados. |

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
        PR["patrones_rima"]
        ES["estructuras_secciones"]
        PRE["patrones_repeticion"]
        RM["rasgos_metricos"]
        CR["configuracion_rasgos"]
        FU["fuentes_metricas"]

        F --> CF
        CF --> PM
        PM --> PMP
        CF --> PR
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
        MO["secuencia_metros_observados"]
        RO["secuencia_rima_observada"]
        RSO["secuencia_rasgos_observados"]

        SM --> SC
        SM --> UM
        SM --> MO
        SM --> RO
        SM --> RSO
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
| `secuencia_metros_observados` | Patrón observado con medidas 8 y 4. |
| `secuencia_rasgos_observados` | Opcional: pie quebrado constatado expresamente. |

El rasgo pie quebrado ya puede inferirse de la configuración. Solo se registra también como observación si interesa conservar que fue comprobado directamente.

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

    RT["rasgos_metricos<br/>timbre_asonancia"]
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
| `secuencia_rima_observada` | Régimen asonante, pares rimados y `timbre_asonancia = e-o`. |
| `secuencia_metros_observados` | Opcional: octosílabos comprobados. |

### Interacción del editor

| Nivel | Acción |
| --- | --- |
| Mínimo | Seleccionar “Romance”. |
| Recomendado | Ninguna acción adicional. |
| Avanzado | Registrar el timbre de asonancia, si se conoce. |

### Utilidad

- El demarcador usa metro, extensión y régimen de rima, pero no exige el timbre.
- El buscador puede ofrecer `e-o` como faceta avanzada.
- Todos los timbres pertenecen a la misma forma y pueden estudiarse como una dimensión independiente.

## 6. Villancico

### Definición ontológica

```mermaid
flowchart TB
    F["formas_metricas<br/>villancico"]
    C["configuraciones_forma<br/>estructura_tipica"]

    H["estructuras_secciones<br/>cabeza · 0–1 · 2–4 versos"]
    MU["estructuras_secciones<br/>mudanza"]
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
    C --> MU
    C --> EN
    C --> VU
    C --> ES
    C --> PM
    C --> PR
    C --> PRE
    C --> PR1
    C --> PR2
    MU -. ámbito .-> PR1
    MU -. ámbito .-> PR2

    H --> MU
    MU --> EN
    MU --> VU
    EN --> VU
    VU --> ES
```

### Ejemplo de secuencia

Un villancico presenta cabeza de tres versos, mudanza octosilábica `abba`, vuelta y repetición del estribillo.

| Tabla | Registro conceptual |
| --- | --- |
| `secuencias_metricas` | Rango completo y `forma_metrica_id = villancico`. |
| `secuencia_configuraciones` | `configuracion_id = estructura_tipica`. |
| `unidades_metricas` | Rangos de cabeza, mudanza, vuelta y estribillo. |
| `secuencia_metros_observados` | Octosílabos en la mudanza. |
| `secuencia_rima_observada` | Esquema `abba` en el rango de la mudanza. |

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
    C["configuraciones_forma<br/>soneto_endecasilabo · principal"]

    ES1["estructuras_secciones<br/>cuarteto 1 · 4 versos"]
    ES2["estructuras_secciones<br/>cuarteto 2 · 4 versos"]
    ES3["estructuras_secciones<br/>terceto 1 · 3 versos"]
    ES4["estructuras_secciones<br/>terceto 2 · 3 versos"]

    PM["patrones_metricos<br/>secuencia fija · 14 versos"]
    PMP["patron_metrico_posiciones<br/>14 posiciones de 11 sílabas"]

    PR1["patrones_rima<br/>ABBAABBACDCDCD"]
    PR2["patrones_rima<br/>ABBAABBACDCEDE"]
    PR3["patrones_rima<br/>ABBAABBACDECDE"]

    RG["rasgos_metricos<br/>mayoria_finales_esdrujulos"]
    CR["configuracion_rasgos<br/>rasgo admitido, no requerido"]

    FA --> FF
    F --> FF
    F --> C
    C --> ES1
    C --> ES2
    C --> ES3
    C --> ES4
    C --> PM
    PM --> PMP
    C --> PR1
    C --> PR2
    C --> PR3
    C --> CR
    RG --> CR
```

### Ejemplo de secuencia

Un soneto endecasílabo presenta el esquema `ABBAABBACDCEDE` y mayoría de finales esdrújulos.

| Tabla | Registro conceptual |
| --- | --- |
| `secuencias_metricas` | Rango de 14 versos y `forma_metrica_id = soneto`. |
| `secuencia_configuraciones` | Configuración endecasílaba principal. |
| `secuencia_rima_observada` | Referencia al patrón `ABBAABBACDCEDE`. |
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
| `secuencia_metros_observados` | Endecasílabos, si se desea registrar su comprobación. |
| `secuencia_rima_observada` | No se crea una falsa rima; el régimen es no aplicable. |

Las palabras concretas pertenecen a la realización de la obra. Podrán almacenarse como valores observados del patrón de repetición cuando se defina ese nivel de edición.

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

## 9. Qué escribe cada persona

```mermaid
flowchart LR
    IP["IP o responsable del catálogo"]
    ED["Editor de una obra"]
    SYS["Sistema"]

    IP --> CAT["formas_metricas<br/>configuraciones_forma<br/>patrones y rasgos<br/>fuentes_metricas"]

    ED --> SEC["secuencias_metricas<br/>secuencia_configuraciones"]
    ED -. "solo si lo conoce" .-> DET["unidades_metricas<br/>metros, rima y rasgos observados"]

    CAT --> SYS
    SEC --> SYS
    DET --> SYS

    SYS --> OUT["Demarcador<br/>fichas<br/>filtros<br/>laboratorio"]
```

El IP formaliza una vez las propiedades generales. El editor identifica la forma de una secuencia y añade únicamente la información específica de esa obra que conoce y considera útil.

## 10. Regla de diseño de la interfaz

Para cualquier forma:

1. **Siempre visible:** rango y forma.
2. **Pregunta contextual:** configuración, solo cuando diferencia alternativas relevantes.
3. **Detalle desplegable:** unidades, patrón exacto y rasgos observados.
4. **No determinado:** disponible siempre que el dato no sea imprescindible.
5. **Datos derivados:** no se vuelven a pedir al editor.

La ontología aumenta la precisión y la reutilización de los datos, pero la interfaz aplica divulgación progresiva para mantener una edición breve.

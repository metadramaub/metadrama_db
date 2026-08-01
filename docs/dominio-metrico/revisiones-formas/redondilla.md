# Redondilla

Estado: revisado con decisiones del proyecto · 1 de agosto de 2026

## Decisión

Una sola forma, `redondilla`, con cuatro arquitecturas.

| Arquitectura | Metro | Rima | Unidad |
| --- | --- | --- | ---: |
| `octosilabica` · principal | 4 × 8 | `abba` o `abab` | 4 |
| `heptasilabica` | 4 × 7 | `abba` o `abab` | 4 |
| `hexasilabica` | 4 × 6 | `abba` o `abab` | 4 |
| `doble_enlazada` | 8 × 8 | `abbaacca` | 8 |

La redondilla es isosilábica, así que la medida no puede cambiar entre estrofas de una
misma tirada: **es arquitectura, no pregunta**, en paralelo exacto con las cuatro medidas
del romance. Si una tirada cambia de medida, o empieza otra secuencia o hay un
anisosilabismo que se registra como desviación.

La distribución `abba` / `abab` sí se elige por unidad, mientras no se confirme si puede
alternar dentro de una misma tirada. Es la opción reversible: corregirlo después es
reclasificar filas, mientras que haberlo tratado como arquitectura habría partido
secuencias que no debían partirse. Es la primera de las
[cuestiones pendientes](./cuestiones-para-el-ip.md).

Ninguna de estas arquitecturas declara secciones: la unidad es la estrofa y cuántas
contiene el pasaje se deriva del rango.

## Del vocabulario anterior al catálogo

| Entrada anterior | Destino actual |
| --- | --- |
| `redondilla` | Forma `redondilla` |
| `redondilla_regular` | Arquitectura `octosilabica` |
| `redondilla_cruzada` | Esquema de rima `abab` |
| `redondilla_heptasilaba` | Arquitectura `heptasilabica` |
| `redondilla_hexasilaba` | Arquitectura `hexasilabica` |
| `redondilla_doble_abbaacca` | Arquitectura `doble_enlazada` |

La asociación errónea de `redondilla_hexasilaba` con el metro heptasílabo queda corregida:
la hexasílaba mide seis.

No se crea una familia `redondillas`: cuatro versos es una propiedad estructural
consultable, no una agrupación ontológica, y todas estas realizaciones pertenecen a la
misma forma.

## La doble enlazada

Cambia la unidad, y por eso no es un tercer esquema de rima de las simples:

```text
unidad de 8 versos
├── primera redondilla:  a b b a
└── segunda redondilla:  a c c a
```

Las dos mitades comparten la clase exterior `a`. La división interna se deriva de esas
posiciones; no se materializan subunidades cuando el editor no necesita caracterizarlas por
separado.

## «Cuarteta»

`denominaciones_metricas` sustituye el alcance limitado de `forma_aliases`: cada nombre
apunta exactamente a una entidad —forma, arquitectura, esquema, sección o variedad—.

```text
Cuarteta  ·  denominación posterior
└── esquema de rima abab
    └── arquitectura octosilabica
        └── forma Redondilla
```

Es **posterior**, no equivalente: en el Siglo de Oro ambas disposiciones eran redondillas, y
la reserva de «cuarteta» para la cruzada es una distinción que la preceptiva impone después.
Buscar «Cuarteta» conduce a esa realización concreta sin crear una forma falsa ni aplicar el
nombre a las abrazadas.

## Cómo se registra una tirada

```text
SECUENCIA
forma: Redondilla · arquitectura: Octosilábica · rango 1–48
→ 12 unidades derivadas de cuatro versos

SECUENCIA
forma: Redondilla · arquitectura: Doble enlazada · rango 1–48
→ 6 unidades derivadas de ocho versos
```

Cada unidad guarda su disposición de rima; si todas coinciden, la interfaz permite aplicar
la respuesta a la tirada completa. Las simples exigen múltiplos de 4 y la doble, de 8. Un
rango incompatible se rechaza para que el editor revise la delimitación, la fuente o una
posible laguna.

## Demarcador

Obtiene cuatro candidatos: tres redondillas simples que se distinguen por la medida —6, 7 y
8—, con rima `abba` o `abab`, y la doble enlazada de ocho octosílabos con `abbaacca`. Dentro
de cada simple puede preguntar la distribución, que en el registrador se guarda como
elección normalizada por unidad.

## Fuentes

- José Domínguez Caparrós, *Diccionario de métrica española*, 3.ª ed., Madrid, Alianza
  Editorial, 2016, voces «redondilla» y «cuarteta».
- Rudolf Baehr, *Manual de versificación española*, Madrid, Gredos, 1970.
- Daniel Devoto, «De la redondilla y su familia», *Boletín de la Real Academia Española*,
  63 (1983), pp. 475-482.

La bibliografía documenta usos terminológicos distintos. La organización del catálogo
expresa el criterio adoptado por el proyecto y conserva las fuentes en las entidades
concretas que las sustentan.

## Dudas para el IP

1. **¿Puede alternar `abba` y `abab` dentro de una misma tirada?** Si no puede, son dos
   arquitecturas más por medida y la redondilla se registra sin ninguna pregunta.
2. ¿Debe incorporarse «octavilla» como denominación relacionada de la doble enlazada o
   resultaría demasiado amplia?

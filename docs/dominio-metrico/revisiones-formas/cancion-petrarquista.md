# Canción petrarquista

Estado: revisada con los datos del proyecto y bibliografía · 1 de agosto de 2026

## Decisión

Una forma de nivel composición con tres configuraciones:

| Configuración | Estancia | Rima |
| --- | --- | --- |
| `estancias_consonantes_variables` | 5–20 versos; 7 y 11 sílabas por posición | esquema consonante observado y repetido |
| `regular_13_abCabC_cdeeDfF` | 13 versos: `7-7-11-7-7-11-7-7-7-7-11-7-11` | `ABCABCCDEEDFF` |
| `sin_rima_con_pareado_final` | cuerpo variable + 2 versos finales; 7 y 11 sílabas | cuerpo suelto + pareado consonante |

La configuración general es la principal. Las estancias de 8, 9 y 15 versos no son
configuraciones: son extensiones observadas del mismo componente. La antigua canción
endecasílaba tampoco crea una configuración; se registra eligiendo 11 sílabas en todas
las posiciones.

La configuración regular conserva la notación histórica `abCabC:cdeeDfF`, pero separa
sus dos dimensiones:

- medida: las minúsculas son heptasílabos y las mayúsculas endecasílabos;
- rima: las clases son `ABCABCCDEEDFF`.

Así, `C`, `c` y `C` representan una misma clase de rima.

## Registrador

Los recorridos son:

```text
Canción petrarquista
├── Regular de 13 versos → añadir estancias → guardar
├── Estancias consonantes variables
│   └── extensión + medida de cada posición + esquema de la primera estancia
│       → aplicar a todas → corregir solo diferencias
└── Canción sin rima
    └── extensión del cuerpo + medida de cada posición
        → aplicar a todas → final esdrújulo solo si caracteriza
```

El editor materializa un mínimo de tres estancias. En las configuraciones variables,
cada posición ofrece únicamente 7 u 11 sílabas. La extensión, la distribución métrica
y el esquema de rima pueden copiarse a todas las estancias equivalentes.

**La distribución métrica y el esquema de rima declaran la norma de la canción, y la base
lo comprueba.** Ambas preguntas llevan `define_norma`: se responden en cada estancia, pero
todas las estancias de una misma canción deben coincidir. Antes esa regla vivía solo en el
texto de ayuda al editor y nada impedía guardar una canción con estancias de esquemas
distintos, que es justo lo que su norma prohíbe. Dos canciones distintas del mismo pasaje sí
pueden diferir entre sí: el ámbito de la comparación es la unidad, no la secuencia.

La extensión de la estancia no está cubierta por esa comprobación: no es una pregunta del
catálogo sino la longitud de cada realización. Si se quisiera exigir también su igualdad,
haría falta una comprobación aparte.

En la configuración sin rima no se pregunta por la rima: el cuerpo suelto y el pareado
final se derivan de la norma. El campo esdrújulo queda vacío por defecto.

El remate o envío se puede añadir como sección final. Por ahora es opcional, porque la
definición del proyecto no lo exige expresamente.

## Demarcador

La forma se reconoce por una composición de estancias que repiten su estructura. La
configuración concreta se distingue por:

1. extensión de la estancia;
2. distribución de heptasílabos y endecasílabos;
3. régimen y esquema de rima;
4. presencia normativa del pareado final en la modalidad sin rima.

Los valores 8, 9 y 15 y la realización solo endecasílaba se derivan de las unidades y
elecciones guardadas. No existen reglas manuales del demarcador para esos antiguos
subtipos.

## Estructura

```text
FORMA Canción petrarquista
├── CONFIGURACIÓN Estancias consonantes variables
│   └── 3…n ESTANCIAS de 5–20 versos [+ REMATE]
├── CONFIGURACIÓN Regular de 13 versos
│   └── 3…n ESTANCIAS de 13 versos [+ REMATE]
└── CONFIGURACIÓN Cuerpo sin rima y pareado final
    └── 3…n ESTANCIAS
        ├── CUERPO sin rima de 3–18 versos
        └── PAREADO FINAL consonante de 2 versos
```

En el patrón regular, los versos 1–6 forman la fronte en dos pies; el verso 7 es el
eslabón y abre sintácticamente la sirima. Esta estructura se conserva en las posiciones
normalizadas sin obligar al editor a rellenar sus nombres.

## Trazabilidad

```text
cancion_petrarquista                  → FORMA
cancion_regular_abCabCcdeeDfF         → CONFIGURACIÓN regular + patrones
cancion_sin_rima                      → CONFIGURACIÓN sin rima
cancion_sin_rima_de_esdrujulos        → configuración sin rima + RASGO esdrújulo
cancion_endecasilaba                  → elección de 11 sílabas en cada posición
cancion_de_8_versos                   → extensión observada 8
cancion_de_9_versos                   → extensión observada 9
cancion_de_15_versos                  → extensión observada 15
```

No se crea una familia ni se conservan hijos por tamaño.

## Fuente

José Domínguez Caparrós, *Métrica española*, Madrid, UNED, 2014, pp. 214-216:
define la canción petrarquista como composición de estancias consonantes de
heptasílabos y endecasílabos; describe fronte, pies, eslabón, sirima y remate.

La fuente sitúa la estancia entre 9 y 20 versos. El catálogo conserva el intervalo
5–20 fijado por el proyecto para su corpus y registra expresamente el contraste.
La canción sin rima procede del criterio incorporado por el IP; no se atribuye a esta
fuente.

## Dudas para el IP

1. ~~¿La canción sin rima debe ser arquitectura o forma?~~ **Resuelto: arquitectura.**
   Combina heptasílabos y endecasílabos como la regular y mantiene la estructura de estancias;
   lo que la distingue es que prescinde de la rima en el cuerpo y conserva solo el pareado
   consonante final, que cierra cada unidad y marca la transición. Eso es otra realización de
   la misma forma, no otra forma.
2. Confirmar si toda canción del corpus debe exigir remate o envío.
3. Confirmar el límite inferior de la estancia: 5 según el proyecto y 9 en la fuente.

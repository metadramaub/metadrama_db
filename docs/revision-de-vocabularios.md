# Revisión de los vocabularios

Estado: anotado, **no decidido** · 3 de agosto de 2026

**Cuándo mirarlo.** Cuando el dominio métrico haya pasado a `main` y se hagan las
migraciones de datos. Ahora no: `develop` tiene demasiadas cosas a medias como para decidir
dónde vive cada vocabulario, y mezclarlos un tiempo más no rompe nada.

Este documento solo deja constancia del inventario y de la pregunta, para no tener que
volver a levantarlos.

## La pregunta

En el proyecto conviven **tres sistemas** para guardar vocabularios, y no hay un criterio
escrito que diga cuál toca en cada caso:

| Sistema | Qué guarda | ¿Editable sin migración? |
| --- | --- | --- |
| `vocabularios` | `estrofa_tipo`, `caracterizacion_rango`, `tipo_comentario`, `estado`, roles… | Sí, desde `/dashboard/vocabularios` |
| Tablas propias del catálogo | `metros`, `formas_metricas`, `esquemas_rima`, `rasgos_metricos`… | Sí, desde `/dashboard/metrica` |
| Restricciones `CHECK` | 60 enums repartidos por el esquema | No |

El riesgo no es teórico. Renombrar un valor guardado como literal obliga a un `UPDATE` de
todas las filas: ha pasado dos veces —`medida` → `metro` en julio, y
`falta_elemento_esperado` → `falta` el 3 de agosto—. Con una clave ajena, renombrar una
etiqueta habría costado una fila.

## Lo que no es un problema

**`metro` en `vocabularios` frente a la tabla `metros` no es una duplicación.** El primero
es el vocabulario de formas que está hoy en producción; el segundo es el catálogo métrico
nuevo, que se mantiene aparte por su complejidad, igual que `estrofa_tipo` frente a
`formas_metricas`. Es la frontera legado/nuevo funcionando como debe.

**Las entidades con atributos propios no caben en `vocabularios`.** `metros` tiene sílabas,
tipo y cesura; `formas_metricas` tiene nivel estructural y tipo de registro. Su sitio es su
tabla, y eso no está en discusión.

## El inventario

60 enums en `CHECK`, repartidos así:

| Superficie | Enums | ¿Se puede tocar sin afectar a producción? |
| --- | ---: | --- |
| Catálogo métrico nuevo | 46 | Sí |
| Trazabilidad de la migración | 4 | Sí, pero no aportan nada |
| Editor V2 de pruebas | 2 | Sí — ya cerrados |
| **Producción** | **8** | **No** |

Los ocho de producción:

| Tabla | Columna |
| --- | --- |
| `secuencias_metricas` | `personaje_femenino`, `final_acentual`, `intervencion_personajes_femeninos` |
| `secciones_publicas` | `scope_minimo` |
| `autores_resumen` | `alcance` |
| `demarcador_versiones` | `estado`, `fuente_tipo` |
| `demarcador_familias_config` | `politica` |

De estos, solo `final_acentual` merece discusión, y ya tiene destino propio en el
[plan de desviaciones y caracterizaciones](./dominio-metrico/plan-desviaciones-y-caracterizaciones.md):
pasa a ser un rasgo. Los otros siete son interruptores internos que ningún editor lee.

## El criterio que se propuso

Para cuando toque decidir, la línea discutida el 3 de agosto fue:

> Un vocabulario vive en `vocabularios` cuando alguien del proyecto tiene que leerlo,
> nombrarlo o definirlo. Se queda en `CHECK` cuando solo lo lee el código. Una entidad con
> atributos propios vive en su tabla, nunca en `vocabularios`.

Con tres reglas que hacen seguro el cambio:

1. El código referencia el `termino`, nunca el UUID ni la etiqueta. Renombrar una etiqueta
   cuesta una fila; renombrar un slug sigue siendo un acto deliberado.
2. La integridad la da la clave ajena, que sustituye al `CHECK`.
3. Una categoría no se borra ni se renombra desde el panel si hay código que la lee; solo
   sus etiquetas y definiciones.

Aplicando ese criterio, los candidatos a `vocabularios` dentro del catálogo nuevo —los que
un humano lee y cuyas etiquetas están hoy incrustadas en TypeScript— serían:

`modalidad` · `fijeza` · `observabilidad` · `nivel_estructural` · `tipo_registro` ·
`grado_especificacion` · `ambito` · `tipo_secuencia` · `tipo_control` · `alcance`
(secuencia/unidad) · `tipo_valor` · `comportamiento` · `dimension` · `relacion_norma`

Se quedarían en `CHECK` incluso dentro del catálogo: `estado_revision`, que es flujo y no
vocabulario editorial, y `tipo` (`simple`/`compuesto` de los metros), que es estructura.

## Tres cabos sueltos

**`modalidad` mezcla dos ejes en una escala.** Lo señaló el IP el 10 de agosto de 2026 al revisar
esa columna: `habitual · admitida · excepcional` gradúan **cuán corriente** es algo, y
`definitoria` afirma **que es necesario**. Son preguntas distintas, y no siempre excluyentes: la
asonancia de la endecha real es constitutiva de la forma **y además** es lo corriente, y hoy solo
cabe declarar una de las dos cosas. Pide separarse en una columna de necesidad y otra de
frecuencia, en las cinco tablas que hoy comparten el enum: `esquemas_rima`, `arquitecturas_forma`,
`arquitectura_rasgos`, `repeticiones_metricas` y `variedades_arquitectura`.

*Dos datos para cuando se resuelva. `definitoria` no significa «la única»: 7 de los 38 esquemas
definitorios tienen hermanos, porque describen otra parte de la unidad —el pareado final de la
canción y su cuerpo sin rima son las dos definitorios— o porque son la restricción abierta junto
a las realizaciones enumeradas. Y `arquitectura_rasgos` usa solo dos de los cuatro valores,
`definitoria` y `admitida`, que es lo único que tiene sentido ahí: un rasgo caracteriza la
arquitectura o solo se admite en ella.*

## Dos cabos más

**`estado_revision` aparece en los dos sitios.** Hay una categoría con ese nombre en
`vocabularios`, declarada como protegida en `src/lib/utils/permissions.ts`, cuyos términos no
aparecen sembrados en ninguna migración; y un `CHECK` `estado_revision` en doce tablas del
catálogo. Falta comprobar contra la base si son la misma idea escrita dos veces o dos cosas
homónimas. Es lo primero que hay que resolver.

**El mapa dimensión × relación está duplicado.** Qué relaciones admite cada dimensión de una
desviación vive a la vez en un `CHECK` de `desviaciones_editor_metrico` y en
`DEVIATION_RELATIONS_BY_DIMENSION`, en `sequence-draft.ts`. Si esos dos enums pasan a
`vocabularios`, el `CHECK` no puede seguir comparando texto: haría falta una tabla de enlace
—que de paso quitaría la duplicación— o un trigger. Es el coste real de mover estos dos.

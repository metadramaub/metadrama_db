# Revisión de los vocabularios

Estado: **repartido** · inventario contrastado con la base el 10 de agosto de 2026

**Cuándo mirarlo.** Ya: hay una parte que se hace ahora y otra que espera a que el dominio
métrico pase a `main`. El reparto está en [qué se hace ahora y qué espera a la
fusión](#qué-se-hace-ahora-y-qué-espera-a-la-fusión), y la línea es la superficie que toca cada
cosa, no su importancia.

## La pregunta

En el proyecto conviven **tres sistemas** para guardar vocabularios, y no hay un criterio
escrito que diga cuál toca en cada caso:

| Sistema | Qué guarda | ¿Editable sin migración? |
| --- | --- | --- |
| `vocabularios` | `estrofa_tipo`, `caracterizacion_rango`, `tipo_comentario`, `estado`, roles… | Sí, desde `/dashboard/vocabularios` |
| Tablas propias del catálogo | `metros`, `formas_metricas`, `esquemas_rima`, `rasgos_metricos`… | Sí, desde `/dashboard/metrica` |
| Restricciones `CHECK` | 49 enums repartidos por el esquema | No |

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

*Contado contra la base el 10 de agosto de 2026. La cuenta anterior —60 enums, de agosto 3— se
había quedado vieja en cosas que cambian la decisión, y va anotado abajo en qué.*

**49 enums en `CHECK`**, repartidos así:

| Superficie | Enums | ¿Se puede tocar sin afectar a producción? |
| --- | ---: | --- |
| Catálogo métrico nuevo | 38 | Sí |
| Editor V2 de pruebas | 3 | Sí — ya cerrados |
| **Producción** | **8** | **No** |

Los ocho de producción, con lo que de verdad son:

| Tabla · columna | Qué es | ¿Lo lee alguien del proyecto? |
| --- | --- | --- |
| `secuencias_metricas.intervencion_figuras_donaire` | `sin_intervencion · exclusiva · compartida` | **Sí**, lo anota el editor |
| `secuencias_metricas.intervencion_personajes_femeninos` | El mismo vocabulario | **Sí** |
| `secuencias_metricas.intervencion_personajes_sobrenaturales` | El mismo vocabulario | **Sí** |
| `comentarios_internos.seccion` | Las pestañas del editor de obra | No: es la interfaz |
| `autores_resumen.alcance` | `publico · completo` | No |
| `secciones_publicas.scope_minimo` | `anon · authenticated · admin_ip` | No |
| `demarcador_versiones.estado` · `fuente_tipo` | Flujo de publicación del artefacto | No |
| `demarcador_familias_config.politica` | `familia · variantes` | No |
| `vocabularios.arte_metrico` · `tipo_forma` | Atributos del vocabulario legado | No |

**Los tres de intervención son el único vocabulario editorial de producción**, comparten los
mismos tres valores en tres columnas y están en uso: 212 secuencias anotadas. Si algún día se
mueve algo de producción a `vocabularios`, empieza por ahí —y por los tres a la vez, porque son
el mismo vocabulario escrito tres veces—.

**Cuatro correcciones a la cuenta anterior**, todas encontradas al contrastarla:

- Eran 60 y son **49**. Han caído enums por el camino: `grado_especificacion` se retiró el 5 de
  agosto, `tipo_secuencia` perdió un valor el 10 al fundirse `restricciones` en `abierta`.
- **Los cuatro de la trazabilidad de la migración no existen**: `migracion_terminos_metricos` y
  `migracion_termino_destinos` no están en la base.
- **`final_acentual` ya no está en producción.** El documento decía que era «el único que merece
  discusión» y que su destino era pasar a rasgo: ya pasó. Hoy es `rasgos_metricos.final_acentual`.
- La lista de producción nombraba `personaje_femenino`, que no existe, y **omitía cuatro que sí**:
  las tres de intervención con su nombre real, `comentarios_internos.seccion` y los dos de
  `vocabularios`. Que la propia tabla de vocabularios lleve dos enums en `CHECK` resume bien el
  problema.

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

`modalidad` · `observabilidad` · `nivel_estructural` · `tipo_registro` · `ambito` ·
`tipo_secuencia` · `tipo_control` · `alcance` (secuencia/unidad) · `tipo_valor` · `dimension` ·
`relacion_norma`

*La lista del 3 de agosto nombraba además `fijeza`, `comportamiento` y `grado_especificacion`, y
**ninguno de los tres existe como columna**: los dos primeros nunca existieron —eran nombres que
el gestor usaba y la base no aceptaba— y el tercero se retiró el 5 de agosto. Es el mismo fallo
que `npm run audit:campos` vigila ahora en el gestor, aquí en un documento.*

Se quedarían en `CHECK` incluso dentro del catálogo: `estado_revision`, que es flujo y no
vocabulario editorial, y `tipo` (`simple`/`compuesto` de los metros), que es estructura.

## Qué se hace ahora y qué espera a la fusión

Repartido el 10 de agosto de 2026, con la fusión de `develop` en `main` prevista para dentro de
un mes. **La línea no es la importancia sino la superficie**: lo que solo toca las tablas del
catálogo nuevo y del editor V2 no puede romperle nada a nadie, porque no hay editores
trabajando sobre ellas; lo que toca producción o el código compartido espera a la migración de
datos, que hay que hacer de todos modos.

### Ahora — solo toca lo nuevo

Los tres pendientes que dejaron las lecturas transversales, y **ninguno es en realidad una
pregunta de vocabularios**: no discuten *dónde vive* un enum sino que **dicen mal lo que dicen**.

| Qué | Dónde | Por qué no espera |
| --- | --- | --- |
| `definitoria` mezclada en la escala de la modalidad | 5 tablas del catálogo | Una escala que confunde necesidad con frecuencia da datos mal clasificados desde hoy |
| Las restricciones solo pueden colgar de un esquema | `esquema_rima_restricciones` | La norma de la silva y de la quintilla es de su arquitectura, y se apoya en un esquema abierto por no poder decirlo |
| Seis columnas que no distinguen nada | Catálogo y editor V2 | Cada una es una distinción que se declaró y nunca se hizo, como `grado_especificacion` |

**Y hacerlos ahora abarata la mudanza**, que es el argumento de fondo: cuando toque decidir dónde
vive cada vocabulario habrá menos enums, mejor definidos y sin los que sobran. Mover un
vocabulario mal definido a un sitio mejor no lo arregla; lo consagra.

### A la fusión — toca producción o el código compartido

| Qué | Por qué espera |
| --- | --- |
| La mudanza de `CHECK` a `vocabularios` | Sustituir un `CHECK` por una clave ajena obliga a poblar términos y a tocar el código que los lee. Se hace de una vez, con las migraciones de datos |
| Los tres `intervencion_*` | Es el único vocabulario editorial de producción y está en uso en 212 secuencias |
| `estado_revision` en los dos sitios | Hay que comprobar antes si son la misma idea o dos homónimas, y afecta a doce tablas del catálogo más una categoría de producción |
| El mapa dimensión × relación duplicado | Quitar la duplicación pide una tabla de enlace o un disparador; el editor V2 aún va a cambiar |
| Los dos enums de `vocabularios` | Que la tabla de vocabularios lleve enums en `CHECK` es el caso más claro, y el más fácil de hacer al final |

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

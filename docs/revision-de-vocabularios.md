# Revisión de los vocabularios

Estado: **histórico** · inventario contrastado con la base el 10 de agosto de 2026

Actualización del 28 de agosto de 2026: el demarcador versionado al que se alude más abajo fue
retirado junto con sus tablas de configuración y versiones. El demarcador vigente se genera
directamente desde el catálogo métrico.

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
| Tablas propias del catálogo | `metros`, `formas_metricas`, `esquemas_rima`, `rasgos_metricos`… | No; se modifican mediante migraciones |
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
el gestor usaba y la base no aceptaba— y el tercero se retiró el 5 de agosto. Era el mismo fallo
que vigilaba `npm run audit:campos`, retirado el 21 de agosto de 2026 con el gestor mutable que
auditaba: hoy todo cambio del catálogo pasa por migración, y una columna inventada revienta al
aplicarla.*

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
| ~~`definitoria` mezclada en la escala~~ | 5 tablas del catálogo | **Resuelto sin cambio el 10 de agosto**: no eran dos ejes. Ver [el cabo que resultó no serlo](#un-cabo-que-result%C3%B3-no-serlo) |
| ~~Las restricciones solo pueden colgar de un esquema~~ | `esquema_rima_restricciones` | **Resuelto sin cambio el 10 de agosto**: dos de las once serían falsas a nivel de arquitectura. Lo que faltaba era una comprobación, no una columna |
| ~~Seis columnas que no distinguen nada~~ | Catálogo y editor V2 | **Rehecho el 10 de agosto: eran tres grupos.** Cuatro retiradas, `activo` a la fusión. Ver abajo |

**Y hacerlos ahora abarata la mudanza**, que es el argumento de fondo: cuando toque decidir dónde
vive cada vocabulario habrá menos enums, mejor definidos y sin los que sobran. Mover un
vocabulario mal definido a un sitio mejor no lo arregla; lo consagra.

#### Las cuatro columnas que se fueron

Rehecho el inventario en vivo el 10 de agosto, «seis columnas que no distinguen nada» resultó ser
**tres problemas distintos**. Cuatro se retiraron ese día porque duplicaban una distinción ya
codificada:

| Columna | Lo que ya lo decía |
| --- | --- |
| `formas_metricas.seleccionable` | `tipo_registro`, con sus 27 `forma` y sus 2 `sin_forma`. El gestor incluso **forzaba** el flag a `true` cuando el registro era `sin_forma`: el único caso que podía ponerlo en falso estaba codificado para no hacerlo |
| `esquema_rima_enlaces.obligatorio` | `modalidad` |
| `esquema_rima_restricciones.obligatoria` | `modalidad` — y antes que el dato, el concepto: **una restricción que no obliga no es una restricción** |
| `esquema_rima_enlaces.tipo_enlace` | Nada: valía siempre `misma_rima`, y ningún objeto SQL la leía |

No cambió ninguna conducta. El demarcador ya filtraba además por `tipo_registro`, y el disparador
del editor V2 trata el caso `sin_forma` por su cuenta unas líneas más abajo.

**`activo` se queda, y por una razón distinta de las suyas**: no es una columna vacía sino un
mecanismo de retirada sin estrenar. La leen diecisiete objetos SQL, así que quitarla es reescribir
diecisiete cuerpos entrecomillados —el fallo que ya ha mordido cuatro veces—, y jubilar una forma
sin borrarla es plausible justo cuando se migren las secuencias del vocabulario legado. Por eso
baja a la tabla de la fusión.

### A la fusión — toca producción o el código compartido

| Qué | Por qué espera |
| --- | --- |
| La mudanza de `CHECK` a `vocabularios` | Sustituir un `CHECK` por una clave ajena obliga a poblar términos y a tocar el código que los lee. Se hace de una vez, con las migraciones de datos |
| Los tres `intervencion_*` | Es el único vocabulario editorial de producción y está en uso en 212 secuencias |
| `estado_revision` en los dos sitios | Hay que comprobar antes si son la misma idea o dos homónimas, y afecta a doce tablas del catálogo más una categoría de producción |
| El mapa dimensión × relación duplicado | Quitar la duplicación pide una tabla de enlace o un disparador; el editor V2 aún va a cambiar |
| Los dos enums de `vocabularios` | Que la tabla de vocabularios lleve enums en `CHECK` es el caso más claro, y el más fácil de hacer al final |
| `activo` en las ocho tablas del catálogo | No es una columna vacía sino un mecanismo de retirada sin estrenar. Lo leen 17 objetos SQL, y retirarlo es reescribir diecisiete cuerpos entrecomillados: solo compensa si al migrar las secuencias se decide que jubilar una forma sin borrarla no hará falta |

## Un cabo que resultó no serlo

~~**`modalidad` mezcla dos ejes en una escala.**~~ **Comprobado el 10 de agosto de 2026 y
descartado, pero el malestar del IP tenía razón y apuntaba a otro sitio.**

El IP preguntó qué añade `definitoria` frente a `habitual`, y la respuesta que di —que son dos
ejes, necesidad y frecuencia, y que hacía falta partir la columna en las cinco tablas— **era un
error de categoría**. Ningún esquema definitorio es descrito como raro por las fuentes, y no puede
serlo: si fueran ejes independientes tendría que existir algo constitutivo e infrecuente a la vez.

**El IP dio la lectura que faltaba.** La escala sí es de frecuencia, porque la norma métrica
española no es prescriptiva: lo que hace que algo esté `admitido` es que se dio suficientes veces
como para que la crítica dejara de verlo como una rareza. La normativa es resultado de la
práctica, y los dos conceptos se cruzan por eso. Con esa lectura `definitoria` deja de ser un
intruso y pasa a ser **el tope del mismo eje** —lo que se da siempre—: *necesidad es el límite de
frecuencia*.

### La versión comprobable

La escala solo se lee mal si una definitoria puede aparecer **como una opción al lado de otra
modalidad**, porque entonces se estaría pidiendo elegir entre la norma y algo que la cumple. Así
que el invariante es: **ninguna pregunta ofrece una definitoria junto a otra modalidad.**

Se comprobó sobre las preguntas derivadas del catálogo entero y **falló en una sola**: la
disposición de rima de la endecha real heptasílaba ofrecía «asonancia sostenida en los cuartos»
como definitoria junto a la abrazada, la cruzada y **la suelta** —la norma y su negación como
hermanas—.

Las fuentes no sostenían esa lectura. Navarro Tomás § 207 no define la asonancia: **narra** que
«hacia mediados del siglo XVII se generalizó», que es exactamente lo que dice `habitual`; su
glosario admite las cruzadas; el *Diccionario* de 2016 advierte que «puede encontrarse sin rima»;
Jauralde recuerda que el cuarteto se usó suelto. Solo Domínguez Caparrós 2014 la da como parte de
la definición, y el mismo autor la relaja en 2016. Lo definitorio de la endecha real, en las seis,
es **el metro**. Pasó a `habitual`, y esa arquitectura se quedó sin ningún esquema de rima
definitorio: hay formas a las que define el metro y no la rima.

Desde entonces el invariante va escrito como guarda, así que la escala no depende de que nadie
recuerde esto.

### Cómo queda el reparto

Los 38 esquemas definitorios caen en tres formas —31 son el único de su arquitectura, 5 son el
esquema abierto que declara la norma y 2 son una parte complementaria, como el pareado final de la
canción— y **las tres dicen lo mismo**: *se da siempre*. Lo mismo en las otras tablas: el rasgo que
la arquitectura exige, la permutación que hace sextina a la sextina. Cuando un definitorio convive
con hermanos graduados no hay una lista de alternativas: hay **una norma y sus realizaciones**.

*Sobre el nombre: se valoró renombrarlo a `exigida` para que los cuatro valores sonaran al mismo
registro, y se descartó. Choca con `obligatorio`/`obligatoria`, y lee mal en los rasgos —el pie
quebrado no está «exigido» en la copla de pie quebrado: la **caracteriza**—.*

*Queda una observación menor, que no pide cambio: `arquitectura_rasgos` usa solo dos de los cuatro
valores, `definitoria` y `admitida`, y es lo único que tiene sentido ahí —un rasgo caracteriza la
arquitectura o solo se admite en ella—. Un enum puede usar parte de su vocabulario sin estar mal.*

## Dos cabos más

**`estado_revision` aparece en los dos sitios.** Hay una categoría con ese nombre en
`vocabularios`, declarada como protegida en `src/lib/utils/permissions.ts`, cuyos términos no
aparecen sembrados en ninguna migración; y un `CHECK` `estado_revision` en doce tablas del
catálogo. Falta comprobar contra la base si son la misma idea escrita dos veces o dos cosas
homónimas. Es lo primero que hay que resolver.

**El mapa dimensión × relación está duplicado.** Qué relaciones admite cada dimensión de una
desviación vive a la vez en un `CHECK` de `anotacion_desviaciones` y en
`DEVIATION_RELATIONS_BY_DIMENSION`, en `sequence-draft.ts`. Si esos dos enums pasan a
`vocabularios`, el `CHECK` no puede seguir comparando texto: haría falta una tabla de enlace
—que de paso quitaría la duplicación— o un trigger. Es el coste real de mover estos dos.

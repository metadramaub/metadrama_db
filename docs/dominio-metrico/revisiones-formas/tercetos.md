# Terceto y terceto encadenado

Fecha de revisión: 28 de julio de 2026

## Decisión de organización

La familia `tercetos` agrupa tres formas métricas relacionadas. No se crea una forma
genérica adicional que duplique la función de la familia.

- `terceto` pertenece al nivel **estrofa**: su extensión es de tres versos.
- `terceto_encadenado` pertenece al nivel **serie**: repite unidades de tres versos y
  establece enlaces de rima entre ellas.
- `tercetos_sin_encadenar` pertenece al nivel **serie**: repite unidades de tres versos,
  pero renueva la clase de rima y no establece enlaces entre ellas.
- Las dos formas de serie mantienen una relación `relacionada_con` con `terceto`. La
  relación explica que se construyen con esas unidades, pero no transmite rasgos ni
  convierte una forma en subtipo de la otra.

La familia sirve para navegar, agrupar y presentar conjuntamente las formas. La relación
explícita permite representar su vínculo estructural en redes y consultas sin inventar una
jerarquía de herencia.

## Definiciones adoptadas

### Terceto

> Estrofa de tres versos endecasílabos con rima consonante en la que, al menos, el primero
> rima con el tercero. Puede emplearse como unidad autónoma. Las sucesiones de estas
> unidades se catalogan como terceto encadenado o tercetos sin encadenar según exista o no
> enlace de rima entre ellas.

### Terceto encadenado

> Serie métrica continua de versos endecasílabos con rima consonante, organizada en
> tercetos encadenados. La rima del segundo verso de cada terceto se retoma en el primero
> y el tercero del siguiente, de acuerdo con la sucesión ABA | BCB | CDC | … . La cadena
> se cierra con un serventesio YZYZ, que recupera la rima pendiente del último terceto.

### Tercetos sin encadenar

> Serie métrica abierta de versos endecasílabos con rima consonante, organizada en
> tercetos cuyas rimas no enlazan con las unidades siguientes. El catálogo reconoce
> tanto la disposición con verso central suelto como la disposición con primer verso
> suelto.

Las tres definiciones reelaboran la información escrita por el IP en el vocabulario
anterior. Se ha conservado su criterio descriptivo, pero se ha separado la unidad
estrófica de la serie completa y se han retirado de la norma las excepciones que todavía
requieren confirmación.

## Traducción al catálogo

### Configuración canónica de `terceto`

- slug: `endecasilabico_consonante`;
- extensión fija: tres versos;
- patrón métrico: tres posiciones endecasilábicas;
- rima: consonante entre el primero y el tercero;
- estado: revisada y demarcable.

Los patrones heredados de series de tercetos sin encadenar no se consideran parte de esta
unidad estrófica: se trasladan a la forma de serie correspondiente.

### Configuración canónica de `terceto_encadenado`

- slug: `endecasilabico_consonante`;
- extensión total: abierta, sin guardar un falso total de tres versos;
- patrón métrico: endecasílabo repetido durante toda la serie;
- unidad estructural: terceto de tres versos, repetible;
- enlace de rima: la posición 2 de cada unidad reaparece en las posiciones 1 y 3 de la
  siguiente;
- cierre: un verso añadido al último terceto `YZY` para formar el serventesio `YZYZ`;
- estado: revisada y demarcable.

El patrón de rima muestra tres posiciones porque formaliza la unidad que se repite. El
cuarto verso solo pertenece al cierre y se declara en `estructuras_secciones`; no
constituye una cuarta posición de todos los tercetos. El patrón métrico solo necesita una
posición endecasilábica repetible.

### Configuración de `tercetos_sin_encadenar`

- slug de forma: `tercetos_sin_encadenar`;
- slug de configuración: `endecasilabico_consonante`;
- patrón métrico: endecasílabo repetido durante toda la serie;
- unidad estructural: terceto de tres versos, repetido al menos dos veces;
- patrón «Verso central suelto»: `A-A | B-B | C-C | …`;
- patrón «Primer verso suelto»: `-AA | -BB | -CC | …`;
- enlaces entre unidades: ninguno.

La ausencia de enlaces significa que la clase `A` se renueva al repetir la unidad: se
convierte en `B`, después en `C`, etc. En patrones como el romance, donde una clase sí
debe conservarse durante toda la serie, esa continuidad se declara con un enlace
explícito entre bloques.

Las entradas heredadas `terceto_sin_encadenar_1_AXABYB` y
`terceto_sin_encadenar_2_XAAYBB` se conservan mediante `origen_termino_id` para migrar
los datos antiguos, pero dejan de utilizarse como nombres o slugs editoriales.

### Configuración octosilábica

La entrada heredada `terceto_octosilabo` se incorpora provisionalmente como configuración
de `terceto_encadenado`, con el metro octosílabo ya normalizado. Permanece en borrador y no
es demarcable hasta confirmar con el IP si conserva siempre el encadenamiento y si posee
o no identidad histórica autónoma.

## Límites de esta revisión

No se han incorporado a la norma:

- el cierre alternativo `VYVYZZ`;
- la presencia excepcional de un verso sin rima;
- la repetición de un mismo sonido de rima cuatro veces;
- un mínimo supuesto de tercetos para reconocer la serie encadenada.

Los antiguos esquemas `AXABYB` y `XAAYBB` sí quedan resueltos en esta revisión: sus
etiquetas se traducen a
los dos patrones normalizados de `tercetos_sin_encadenar`. Sigue pendiente precisar si
los cierres en pareado o cuarteto descritos por el vocabulario anterior son alternativas
estructurales canónicas o realizaciones documentadas.

Estos puntos permanecen explícitamente abiertos para evitar convertir una inferencia
técnica en criterio del proyecto.

## Contraste bibliográfico

José Domínguez Caparrós, *Métrica española*, nueva edición corregida y aumentada
(Madrid: UNED, 2014), p. 185, describe el terceto como una combinación de tres versos de
arte mayor, normalmente endecasílabos, con rima consonante, y documenta la serie
encadenada. La fuente registra más de un cierre posible; METADRAMA adopta por ahora
`YZYZ`, de acuerdo con el criterio específico del proyecto.

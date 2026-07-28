# Revisión de la quintilla

## Estado de la revisión

La quintilla se formaliza como **una forma métrica con una sola configuración** y ocho
patrones de rima alternativos. Los ocho patrones proceden del criterio especializado del IP
para el corpus aurisecular y se conservan íntegramente. La bibliografía general se utiliza
para contrastar y documentar ese criterio, no para sustituirlo.

Esta revisión deja la forma y su configuración en estado `revisada`, no `aprobada`.

## Criterio del catálogo

### Forma: `formas_metricas`

- `slug`: `quintilla`
- `nombre`: `Quintilla`
- `nivel_estructural`: `estrofa`
- `seleccionable`: sí
- `residual`: no

La definición de trabajo es: estrofa de cinco versos octosílabos con rima consonante
distribuida en dos clases. El catálogo aurisecular reconoce ocho tipologías de rima fijadas
por el IP: siete ordinarias y la excepción documentada `abbba`.

### Configuración: `configuraciones_forma`

- `slug`: `octosilabica_consonante`
- `nombre`: `Quintilla octosilábica consonante`
- `grado`: `canonica`
- `numero_versos`: `5`
- `tipo_rima`: consonante
- `demarcable`: sí

No se crea una configuración por cada esquema. Cambiar la distribución de las dos rimas
no cambia la medida, el tamaño ni la arquitectura de la quintilla y, según el criterio del
IP, tampoco crea una forma nueva.

### Patrón métrico: `patrones_metricos`

La configuración tiene un único patrón, `Cinco octosílabos`, de ámbito `estrofa` y tipo
`secuencia_fija`. Sus cinco posiciones se guardan en `patron_metrico_posiciones`, todas
enlazadas con el metro octosílabo.

El manual general de Domínguez Caparrós admite versos octosílabos «o menores». El catálogo
mantiene, sin embargo, el octosílabo como medida exclusiva porque esa es la delimitación
del IP para el corpus del proyecto. La diferencia queda documentada en una afirmación de
fuente y no se resuelve ampliando automáticamente el patrón métrico.

## Patrones de rima

Los términos que antes eran hijos de quintilla pasan a ser registros de
`patrones_rima`, todos dentro de la misma configuración:

| Número | Esquema | Clasificación en el catálogo | Observación |
| ---: | --- | --- | --- |
| 1 | `ababa` | Ordinario | Compatible también con la preceptiva general consultada |
| 2 | `abbab` | Ordinario | Compatible también con la preceptiva general consultada |
| 3 | `abaab` | Ordinario | Compatible también con la preceptiva general consultada |
| 4 | `aabab` | Ordinario | Compatible con las restricciones generales |
| 5 | `aabba` | Ordinario | Compatible también con la preceptiva general consultada |
| 6 | `abbaa` | Ordinario | Termina en pareado; documentado en estudios de poesía áurea |
| 7 | `ababb` | Ordinario | Termina en pareado; documentado en estudios de poesía áurea |
| 8 | `abbba` | Excepción documentada | Acumula tres versos consecutivos con la misma rima |

Cada esquema se formaliza como `secuencia_fija` mediante cinco registros de
`patron_rima_posiciones`. De esta manera el demarcador puede comparar estructuras y no
depende de interpretar una cadena escrita por el editor.

No se conserva un noveno patrón general de `restricciones`: duplicaría el mismo espacio de
posibilidades ya expresado por la lista cerrada de ocho esquemas. Las reglas generales se
emplean para interpretar y documentar el conjunto, mientras que las ocho alternativas
explícitas constituyen la fuente computable para el demarcador.

En el dashboard, los patrones se muestran primero como alternativas legibles. Sus
posiciones normalizadas quedan agrupadas bajo cada patrón en un bloque avanzado. Cuando
se guarda un esquema fijo simple, como `ababa`, las cinco posiciones se regeneran
automáticamente para evitar discrepancias entre la etiqueta visible y la estructura
computable.

## Contraste bibliográfico

José Domínguez Caparrós define la quintilla general como una combinación de cinco versos
octosílabos o menores con dos rimas consonantes. Formula tres restricciones: no más de dos
versos consecutivos con la misma rima, ningún verso suelto y ausencia de pareado final.
También recuerda que entre los tratadistas y autores del Siglo de Oro `redondilla` podía
designar estrofas de cinco versos y otras combinaciones de arte menor. Estas observaciones
se registran como contraste en `afirmaciones_fuentes_metricas`, con localizador
`pp. 188 y 195`.

Un estudio académico sobre la métrica de Sor Juana enumera `abbab`, `ababa`, `abaab`,
`aabba`, `abbaa` y `ababb`, y muestra la alternancia de esquemas dentro de una misma
composición. Resulta especialmente relevante porque documenta `abbaa` y `ababb`, ambos
con pareado final, en un contexto áureo. Esto confirma que una prescripción general
moderna no debe borrar las categorías empleadas por el IP para el corpus.

La excepción `abbba` no queda respaldada por las dos fuentes revisadas. Se conserva porque
forma parte explícita del criterio del IP, pero se etiqueta como excepción documentada y
no se convierte en regla general.

## Correcciones editoriales detectadas

La definición importada decía «Hay siete modalidades» y enumeraba ocho. La redacción nueva
distingue **siete tipologías ordinarias y una excepción documentada**.

Los esquemas no deben aparecer:

- como formas hijas;
- como ocho configuraciones;
- ni como simples cadenas sin estructura.

Deben aparecer en el editor del catálogo dentro de la configuración de quintilla, bajo
`Patrones de rima`, con sus cinco posiciones visibles.

## Consecuencias para el demarcador

El demarcador debe llegar a `Quintilla` mediante rasgos simples: cinco versos,
octosílabos y rima consonante. Solo si necesita diferenciar o registrar la tipología interna
debe preguntar por la distribución de la rima.

Los ocho esquemas son alternativas de una misma candidata, no ocho resultados finales.
Por tanto, seleccionar `ababa` o `abbaa` debe conducir a `Quintilla` en ambos casos. La
excepción `abbba` también conduce a quintilla, pero su etiqueta permite advertir que no
cumple la tendencia de máximo dos consonancias consecutivas.

## Fuentes consultadas

- Domínguez Caparrós, José. *Métrica española*. Nueva edición corregida y aumentada.
  Madrid: Universidad Nacional de Educación a Distancia, 2014, pp. 188 y 195.
- Tena Morillo, Lucía. *Estudios de métrica. Aplicaciones a autores de la literatura
  hispánica: Sor Juana Inés de la Cruz*. Trabajo de Fin de Máster, Universidad de
  Extremadura, 2018, pp. 45-46.

La primera se declara en `fuentes_metricas`. La segunda se utiliza en esta revisión como
contraste específico del uso áureo, pero no se incorpora todavía como fuente declarada del
catálogo.

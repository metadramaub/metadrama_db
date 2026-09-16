# Auditoría profunda del catálogo contra sus fuentes

Estos catorce comandos comprueban **lo que el catálogo dice que dicen las seis monografías**. No
miran si el catálogo es coherente consigo mismo —eso es `npm run audit:metrica`, que vive fuera de
esta carpeta— sino si cada afirmación de «Lo que dicen las fuentes» dice lo que su libro dice y está
donde declara estar.

Se usaron a fondo en septiembre de 2026, sobre 267 afirmaciones. **No son de un solo uso**: cada
afirmación nueva vuelve a necesitarlos, y conviene pasarlos de vez en cuando aunque no se haya
tocado nada, porque un cambio en el catálogo mueve lo que señalan. Ajústalos según haga falta: lo
que aquí se comprueba se fue aprendiendo a base de fallar.

**Necesitan la bibliografía local**, que no está en el repositorio: ver
[las fuentes del catálogo](../../docs/dominio-metrico/fuentes-del-catalogo.md).

## Los que se pasan de vez en cuando

Leen el catálogo vivo y los libros. No dependen de ningún trabajo anterior.

| Comando | Qué mira |
| --- | --- |
| `npm run audit:fuentes` | Que el localizador de cada afirmación resuelva en su fichero. **Genera los extractos** de los que vive todo lo demás |
| `npm run matriz:exhaustividad` | El tablero forma × fuente: qué forma no tiene nada dicho por qué libro. Una forma nueva abre seis celdas |
| `npm run senales:mecanicas` | Cuatro señales: anclaje, esquemas huérfanos, una ficha que nombra otra fuente, y tiradas de seis palabras compartidas entre fichas —el copiar-pegar— |
| `npm run senal:endurecimiento` | Fichas que resumen una oración con cautela sin recoger la cautela. `--cubos` recorta a los de la auditoría de septiembre |
| `npm run divergencias` | Dónde los **datos** del catálogo se apartan de lo que las fuentes dan: esquemas sin notación citada, denominaciones sin eco |

**Los extractos caducan sin avisar.** Guardan el texto del día en que se generaron, y durante cinco
días de septiembre las señales estuvieron juzgando pasajes que el catálogo ya no declaraba. Pasa
`audit:fuentes` antes que nada.

## Los que hacen falta para una pasada de lectura

Reparten el trabajo entre verificadores, comprueban lo que devuelven y lo enfrentan con la ficha.
**Solo sirven dentro de una pasada**: sin dictámenes no tienen nada que leer.

| Comando | Qué hace |
| --- | --- |
| `npm run lotes:b` · `lotes:c` · `lotes:d` | Reparten las afirmaciones en lotes, uno por verificador |
| `npm run valida:dictamenes` · `valida:d` | Comprueban que un dictamen sea utilizable antes de creerle |
| `npm run cotejo:pasadas` | Enfrenta la lectura ciega con lo que el catálogo registra |
| `npm run correcciones:hoja` | De ahí saca la hoja de correcciones y el registro de decisiones |
| `npm run estado:fuentes` | Dice, en consola, qué lote falta y qué cubre cada pasada |
| `npm run muestra:humana` | La muestra para que un tercero pueda repetir la auditoría sin fiarse de nosotros |

**Las cuatro pasadas y qué busca cada una** están en
[el plan](../../docs/dominio-metrico/plan-auditoria-fuentes.md), y las instrucciones que se les dan
a los verificadores, palabra por palabra, en
[auditoria-fuentes/](../../docs/dominio-metrico/auditoria-fuentes/). Lo que la de septiembre enseñó
—y conviene leer antes de montar otra— está en
[su registro](../../docs/dominio-metrico/historico/auditoria-de-fuentes-2026-09.md).

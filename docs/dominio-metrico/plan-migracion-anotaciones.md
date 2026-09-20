# Plan de migración de las anotaciones métricas

Estado: **en curso** desde el 19 de septiembre de 2026 · escrito el 30 de julio

Cómo se llevan las secuencias métricas anotadas con el vocabulario legado al catálogo nuevo. Es
la única parte del dominio métrico que quedaba por hacer: el catálogo está revisado, el editor V2
es el único que escribe y la zona pública lee solo de las tablas `anotacion_*`. **Hasta que una
obra se migra, no tiene perfil.**

Cuántas secuencias quedan, en qué obras y qué le falta a cada una **no se escribe aquí**: lo dicen
`npm run equivalencias:informe` y `npm run migracion:informe`, que leen la base.

## 1 · Lo primero: qué NO va a pasar

- **Nadie reanota su obra.** Casi todo se traduce solo, y lo que el término viejo no decía se pide
  una vez, en un Excel, y se escribe por script.
- **Nada se toca sin las respuestas.** Las secuencias reales no cambian hasta que el Excel de esa
  obra vuelve; el editor de siempre sigue enseñando lo de siempre mientras tanto.
- **No se inventa precisión.** Un verso anotado como hipométrico sin más se registra como menor que
  la norma, sin cifra, salvo que el editor la dé ahora.
- **Lo que se corrige por el camino se corrige en el dato**, no alrededor: una laguna que no se
  contó renumera la obra desde ahí; cuatro sextetos-lira partidos por el vocabulario viejo pasan a
  ser una secuencia.

## 2 · Datos que se preservan

- las filas de `secuencias_metricas`, con su obra, su rango y su `n_versos`; el `estrofa_tipo_id`
  se queda como evidencia de la clasificación hecha y el editor V2 no lo toca;
- los subtipos (`secuencias_subtipos_estrofa`): son las estrofas, con su esquema, y se trasladan
  tal cual;
- las caracterizaciones por rango, según §3;
- sinopsis, indicadores de escena, comentarios internos, fechas y responsables.

Antes de migrar una obra: `npm run snapshot:obras` y la copia completa que describe `README.md`.

## 3 · Las caracterizaciones por rango

Se usaron para dos cosas y cada fila va a un sitio. El 7 de septiembre de 2026 se retiraron del
selector las que no eran enunciativas; sus filas siguen escritas y se trasladan obra por obra. La
tabla vive en código, en `scripts/lib/migracion/modelo.mjs` (`DESTINO_CARACTERIZACION`), y la usan
el informe y el aplicador; esto es su lectura, con lo contado sobre las 11 obras el 19 de septiembre:

| Término | Filas | Destino | Se le pregunta al editor |
| --- | ---: | --- | --- |
| `hipermetrico` · `hipometrico` | 129 · 56 | desviación `metro` · mayor / menor que la norma, con el metro observado si lo da | las sílabas, opcionales |
| `rima_defectuosa` | 16 | desviación `rima` · `otra`, con la nota | nada |
| `laguna` | 2 | desviación `estructura` · `falta` | nada; pero ver §4 |
| `patron_alternativo` | 8 | desviación `rima` · `otra`, con la nota | que le valga |
| `mayoria_agudas` | 1 | en un romance en «a» lo dice ya la asonancia | que le valga |
| `mayoria_esdrujulas` | 0 | rasgo `final_acentual` = esdrújulo | — |
| `cantado` · `prosa` · `evocacion_metrica` | 11 · 5 · 6 | **se quedan**: siguen activas como caracterizaciones enunciativas | nada |

Las relaciones son las que la base admite: `metro` acepta `menor_que_norma`, `mayor_que_norma` y
`otra`; `rima`, solo `otra`; `estructura`, `falta`, `sobra`, `menor_que_norma`, `mayor_que_norma` y
`otra`.

## 4 · Reglas que salieron de mirar los datos

- **Las unidades salen de los subtipos** cuando los hay, no de dividir la secuencia. Sus rangos
  dicen dónde una estrofa mide menos de lo que debe y dónde quedan versos sin cubrir, y eso se
  pregunta localizado —«el subtipo 762–765 mide 4»— y no como «150 no cuadra».
- **Una laguna se registra contando sus versos.** La quintilla a la que le faltan dos sigue
  ocupando cinco números. Si un rango solo cuadra sumando la laguna, no se contó: la respuesta
  «laguna sin contar» renumera la obra desde ahí, en las tablas legadas y antes de anotar.
- **Un romance impar es un verso perdido.** No se admite otra explicación: el editor lo localiza y
  dice si es laguna o rango.
- **Lo derivado se confirma, lo anotado no se pregunta.** Una respuesta que sale del término
  —la asonancia de `romance_a-o`, el ABABABCC de `octava_real_regular`— se enseña rellena para que
  el editor diga si alguna estrofa no era así.
- **Un cierre que explica el rango se confirma.** Sesenta y un versos de terceto encadenado son
  veinte tercetos y un verso de cierre; la vista lo admite desde el 19 de septiembre, y el Excel
  pide confirmar que el cierre existe.
- **Los tramos fundibles se funden.** Secuencias contiguas de la misma arquitectura con unidad de
  extensión fija, sin cruzar jornada ni cuadro, pasan a una sola con varias estrofas. Los booleanos
  de escena se suman, las intervenciones coinciden o quedan `compartida`, y la sinopsis la escribe
  el editor.
- **Sin arquitectura propuesta se pregunta cuál**, y lo que todas las de la forma preguntan por
  igual: el `irregular` escueto.

## 5 · El procedimiento, obra por obra

1. **Generar.** `npm run migracion:informe` escribe, por obra, el informe en Markdown
   ([migracion/](./migracion/)), el mismo informe en HTML y el Excel
   ([migracion/cuestionarios/](./migracion/cuestionarios/)). El informe está redactado para quien
   anotó: qué se ha encontrado, qué se le pide, cómo contestar. El Excel tiene tres pestañas que
   rellenar —*Responder*, *Confirmar*, *Desviaciones*— y cada fila lleva una clave que el
   aplicador lee sin mirar el texto.
2. **Enviar.** El HTML y el Excel, al editor asignado. Lo que no tenga claro lo pregunta; no deja
   respuestas a medias.
3. **Recibir.** El Excel devuelto se guarda en [migracion/respuestas/](./migracion/respuestas/) y
   se versiona: es el rastro de lo que se decidió.
4. **Aplicar.** `npm run migracion:aplicar -- --obra <slug>` *(por escribir)* lee la vista y el
   Excel, y con `--simular` escribe un guion legible sin tocar la base. Sin él: snapshot, las
   correcciones de las tablas legadas —renumeraciones, fusiones, rangos—, y una transacción por
   obra que llama a `guardar_anotacion_metrica` con la identidad del editor asignado, igual que
   `aplicar:guiones`. Deja constancia en `migracion_secuencias` (secuencia, anotación, término
   legado, fecha) e informa de lo que rechazó y de lo que sigue sin respuesta.
5. **Cerrar.** Recuento (secuencias legadas con anotación nueva = total), `npm run
   audit:anotaciones`, recompute. El editor revisa cada secuencia en el dashboard y comprueba que
   la migración no dejó ningún hueco.

Las reglas de equivalencia viven en **un solo sitio**, la vista `propuesta_metrica_secuencia`, y
las respuestas que el término ya contenía en `propuesta_elecciones_secuencia`. Las consultan por
igual el dashboard, `npm run equivalencias:informe`, el informe por obra y el aplicador.

## 6 · Trazabilidad

El mapa vigente es `origen_termino_id`, una columna en cada entidad del catálogo, más
`equivalencias_respuestas_legadas` para lo que un término afirma y la columna única no expresa.
Las tablas `migracion_terminos_metricos` y `migracion_termino_destinos` **no existen**: se
retiraron en julio de 2026. Lo que falta, y añade el aplicador, es el rastro por secuencia:
`migracion_secuencias`.

## 7 · Después

- **Retirada.** `estrofa_tipo` de solo lectura; retirar las FK y los servicios legados sin
  consumidores; conservar el rastro; eliminar las columnas métricas de `vocabularios` solo si
  ninguna otra categoría las usa.

## 8 · Criterios de aceptación

1. Igual número de secuencias antes y después, salvo las fusiones decididas.
2. Igualdad exacta de obra, `v_ini`, `v_fin` y `n_versos`, salvo las correcciones decididas.
3. Toda asignación legada puede trazarse hasta su anotación nueva.
4. Todo subtipo conserva su rango como estrofa.
5. Un verso legado marcado solo como hipométrico no recibe un número de sílabas inventado.
6. Una secuencia sin desviaciones se interpreta como conforme con su norma.
7. Ninguna proyección pública consulta ya la jerarquía de `estrofa_tipo` —ya es así desde el 7 de
   septiembre de 2026—.
8. Una restauración de la copia de seguridad ha quedado ensayada.

## 9 · Riesgos

| Riesgo | Mitigación |
| --- | --- |
| Reclasificar mal una entrada usada | La equivalencia vive en la vista y el informe la enseña; lo derivado se confirma |
| Perder lo anotado estrofa a estrofa | Las unidades salen de los subtipos; copia y snapshot antes de cada obra |
| Inventar precisión | Sílabas solo si el editor las da; relaciones cualitativas si no |
| Renumerar mal una obra | La renumeración sale de una respuesta explícita, se simula antes y se comprueba contra jornadas y cuadros |
| Migrar mientras alguien edita | No hay pausa de edición (comprobado el 19 de septiembre de 2026): se avisa al editor de que no toque la obra desde que devuelve el Excel hasta que se le confirma la migración, y la obra se escribe en una sola transacción |

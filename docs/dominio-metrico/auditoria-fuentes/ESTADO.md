# Estado de la auditoría de fuentes

**Este documento manda sobre el orden de trabajo.** El
[plan](../plan-auditoria-fuentes.md) dice qué es cada fase y cómo se comprueba; aquí está qué queda
por hacer y en qué orden. Se actualiza al cerrar cada cosa: lo terminado se borra, no se tacha.

Actualizado el 17 de septiembre de 2026.

## Dónde estamos

| Fase | Qué | Estado |
| --- | --- | --- |
| 0 | Inventario y niveles 0 y 1 | **cerrada** |
| 1 | Piloto sobre el *Diccionario* con errores sembrados | **cerrada** — se decidió seguir |
| 2 | Navarro 1972 y Morley y Bruerton | **cerrada** |
| 3 | Jauralde, Quilis, Caparrós 2014 | **cerrada** |
| 4 | Exhaustividad, 44 formas | **cerrada** |
| 5 | Informe y muestra humana | pendiente |

Las tres pasadas están completas sobre las **267** afirmaciones: A y B sobre el catálogo entero, C
sobre las 58 que se le repartieron. **42 migraciones aplicadas.**

## Lo que queda, en orden

### 1 · Los tres asuntos de catálogo que destapó la fase 4

No son afirmaciones: son decisiones sobre el propio catálogo, y condicionan cómo se redacta parte
de lo demás. Por eso van primero.

- [x] **Dos fichas tituladas «Sextina».** Resuelto sin tocar la base: el nombre lleva el nivel
      detrás solo cuando otra forma se llama igual, y solo donde el nombre viaja sin la página
      —título de pestaña y miga de pan—.
- [x] **La novena-lira deja de decir que ninguna fuente la describe.** Migración `20260917210000`:
      gana su primera afirmación, la del § 161 de Navarro, con los dos esquemas **en la voz de la
      fuente y no como esquemas de la arquitectura**, porque a qué forma pertenecen lo decide el IP.
      La frontera alirada/canción queda documentada con lo que dice cada una de las seis en
      [cuestiones para el IP](../cuestiones-para-el-ip.md), «Canción petrarquista» 6 a 8.
- [x] **La décima-lira gana sus dos fuentes.** Migración `20260917230000`: la entrada
      «décima-estancia» del *Diccionario* y la nota del § 285 de Navarro. **Con ella el catálogo se
      queda sin formas mudas**, y la guarda lo exige. Sus esquemas tampoco entran como esquemas de
      rima, por la misma razón que los de la novena.

### 2 · Las lagunas de la fase 4 — **once, cerradas**

Todas escritas, con el pasaje abierto y el localizador comprobado en el original. El recorrido está
en [fase-4-exhaustividad.md](./fase-4-exhaustividad.md) y las migraciones van de `20260917210000` a
`20260918230000`.

Empezaron siendo nueve. **Dos aparecieron al clasificar los silencios**, y la segunda enseña algo
del método: Jauralde llama «octetos-lira» a la octava-lira, y «octeto» no era ninguna de las
denominaciones del catálogo, de modo que el contador de menciones dio cero y la celda pasó por
silencio. Es el tercer fallo por la misma causa, tras el guion de «cuarteto lira» y el nombre propio
de «Novena-lira», que es nuestro y de nadie más. La denominación ya está registrada.

Lo que dejaron, además de las afirmaciones:

- **Una forma nueva.** La [estrofa sáfica](../cuestiones-para-el-ip.md#cuarteto-lira) no existía en
  el catálogo y cinco de las seis fuentes la documentan; Navarro le da sección propia en los seis
  períodos que recorre. Entró con dos arquitecturas —la sáfica y la de Francisco de la Torre— y sus
  cinco afirmaciones. El catálogo pasa de 43 unidades a 44.
- **Dos formas que estaban mudas dejan de estarlo**: novena-lira y décima-lira. **Ninguna forma
  activa del catálogo se queda hoy sin fuente**, y una guarda lo exige.
- **Una relación nueva**, endecha real ↔ cuarteto-lira.
- **Tres frases falsas retiradas** de la prosa publicada: las dos que afirmaban que ninguna fuente
  describía a las liras de nueve y diez versos, y la que daba su esquema por único.
- **Un hallazgo para el IP**: cada fuente deja de enumerar aliradas donde empieza a llamarlas
  canción, y dos de ellas ponen la juntura en el mismo sitio, el 8/9.

### 3 · Los silencios — **escritos, y con ellos cierra la fase 4**

**264 celdas y ninguna vacía.** Ninguna forma del catálogo tiene ya un hueco sin explicar frente a
ninguna de sus seis fuentes, y la migración `20260919120000` lo exige en una guarda.

Veintidós silencios, en siete razones, y **seis de las siete son citables**: lo que parecía ausencia
resultó ser una frontera que cada libro declara. **Ninguna fuente calla por olvido sobre la serie
alirada: cada una deja de enumerarla en el punto en que empieza a llamarla canción.** La primera
redacción decía de las trece lo mismo —«no la registra»— y era falsa por omisión.

La única razón puramente negativa son las cuatro celdas de Morley y Bruerton en formas que le son
ajenas, y ahí el motivo también es suyo: su repertorio no es el de la métrica española sino el de
las formas que Lope usa.

### 4 · Los cubos que quedan abiertos

| cubo | pendientes | qué son |
| --- | --- | --- |
| confirmación | 57 | **en curso**, ver abajo |
| observación | 50 | notas que hay que decidir si entran |
| limpio | 1 | |
| filológico | 1 | decisión del IP |

Y **dos propuestas sin redactar**: `9c4dd052` (lira de Morley y Bruerton) y `cfb377cd`
(septeto-lira de Navarro).

#### El cubo de confirmación no estaba comprobado

La hoja lo describe como «conformes sin ninguna divergencia señalada, **no piden decisión**». Al
abrirlo el 18 de septiembre de 2026 resultó que **41 de las 57 llevan alguna señal mecánica**: los
dos lectores coincidieron y lo que mira la columna vio otra cosa.

| señal | fichas |
| --- | --- |
| matices —la fuente matiza y la ficha puede no hacerlo— | 27 |
| esquemas que la fuente da y la ficha no registra | 21 |
| tiradas compartidas con otra fuente | 13 |
| esquemas sin rastro en el catálogo | 7 |
| anclaje | 4 |
| nombra otra fuente | 1 |

Y las pasadas que han tenido son **A y B las 57, C ninguna**.

**Lo que se ha hecho con eso:**

- **Una cuarta comprobación mecánica**, `npm run senal:endurecimiento`. La señal de «matices» venía
  de la pasada B —solo existía si el lector ciego se fijaba—, así que no distinguía «la fuente no
  matiza» de «B no lo anotó». La comprobación nueva no pregunta a nadie: empareja el resumen con las
  oraciones del pasaje que comparten con él una tirada de seis palabras, y mira si matizan donde el
  resumen no matiza. **Cubre 153 de las 267 y señala 21.** De tres comprobadas a mano, dos eran
  endurecimientos reales —el sexteto-lira de Navarro y la novena de Caparrós—.
- **La pasada C sobre las 57**, que es donde está a cero.

**Lo que queda fuera del alcance mecánico y necesita una lectura dirigida: 114 de las 267** —39 de
este cubo— que no comparten con su pasaje ninguna tirada de seis palabras, porque parafrasean en vez
de reutilizar el léxico de la fuente. Ahí la comprobación no puede decir nada.

*Y una decisión de método, tomada el 18 de septiembre: **no se repite la pasada B sobre las 57**. Ya
la pasaron, y una lectura más no añade verdad por sí sola —B se equivocó en tres de las cuatro veces
que disintió—. Lo que añade alcance es preguntar algo distinto, que es lo que hacen la comprobación
nueva y la pasada C.*

### 5 · Fase 5: informe y muestra humana

Lo último. El informe ha de poder repetirlo un tercero sin fiarse de nosotros.

## Apartado aparte · Los esquemas de rima que las fuentes dan y el catálogo no tiene

**No es esta auditoría y no se hace ahora.** Se anota aquí para que no se pierda.

La comprobación mecánica nº 2 señala **75 esquemas sin rastro en 23 fichas**, 60 de ellos de
Navarro Tomás. La regla que se seguirá cuando se aborde, decidida por David el 17 de septiembre: se
registran como esquemas de la arquitectura con modalidad **`admitida`**, nunca `definitoria`. La
distribución sigue siendo variable y lo que se documenta es solo lo ya encontrado. Es el patrón que
ya usa la octava-lira, con sus dos esquemas `admitida` sobre una `definitoria` de notación nula.

**Pero la lista mecánica no es una lista de trabajo**, y esto es lo que hay que recordar el día que
se retome:

- **El escáner de Navarro lee la `c` como `e` en las cadenas de esquema.** En la p. 133 imprime «las
  Coplas de Jorge Manrique, cuyo modelo, *abe:abe*», que es `abc:abc`. De ahí salen `abeabeddedde`
  (= `abcabcddcddc`), `abeabedefdef` o `abaabedeed`. Migrar la lista metería en la web esquemas que
  no existen.
- **Algunas cadenas son varias estrofas seguidas.** `AAABBBCCC` y `ABACDCEFE` en el terceto son tres
  tercetos leídos de corrido, no esquemas de nueve versos.

De modo que se va **forma por forma**, abriendo la fuente, y cada candidato pasa dos filtros: que la
cadena esté bien leída en el original, y que el esquema sea de esa forma y no de otra. El segundo
filtro no es teórico: es el que evitó meter dos canciones en la novena-lira.

## Apartado aparte · Decisiones filológicas, para el IP

Van a [cuestiones para el IP](../cuestiones-para-el-ip.md) y no las toma el equipo técnico.

**La frontera entre estrofa alirada y canción.** El catálogo la pone en el **eslabón**, y lo modela
como una sección propia: la estancia regular de trece versos es `abCabC:cdeeDfF`, repartida en
**fronte (6) + eslabón (1) + sirima (6)**, donde el eslabón es el verso suelto que repite la rima
con que se cerró la fronte. Se eligió ese criterio porque el proyecto necesita uno que no admita
ambigüedad.

Navarro Tomás no la pone ahí. Su **§ 161 se titula «Estrofas aliradas»**, recorre el tipo métrico
del sexteto en adelante, y dentro de ese epígrafe —no fuera— llega a nueve versos:

| versos | esquema | quién | cómo lo presenta |
| --- | --- | --- | --- |
| 8 | `abCabCdD` | Jáuregui, *Sic te, dive* | ya es nuestra octava-lira |
| 8 | `ABcABcDD` | Cervantes, *La entretenida* | ya es nuestra octava-lira |
| 9 | `abCabCcdD` | Figueroa, *Oh, navis* | «**una nueva reelaboración de este modelo**» |
| 9 | `AbCAbCcdD` | Góngora, poesía 120 | la misma bajo otra forma |

**El mismo string admite dos lecturas y por eso está abierto:**

- *canción*: fronte `abCabC` + eslabón `c` + sirima `dD`;
- *alirada*: la octava-lira con **un verso más** antes de su pareado final, y ese verso repite una
  rima de la cabeza.

La segunda es la de Navarro, y la dice él mismo al llamarlo «reelaboración de este modelo», siendo
«este modelo» las dos estrofas aliradas de ocho versos que acaba de describir. La primera es la que
sale de aplicar nuestra regla al pie de la letra.

**Aplicarla al pie de la letra es lo que no se sostiene**, por dos razones:

1. **Que una rima se repita no dice nada.** Ni la canción ni la alirada lo prohíben: la fronte
   repite `abC` por definición y la sirima `cdeeDfF` repite la `e`. Lo único que informaría es el
   eslabón **como sección**, y eso exige que haya sirima.
2. **Aquí no hay sirima que valga el nombre.** Lo que sigue al verso 7 es `dD`: un pareado final de
   dos versos, que es justamente la marca de las aliradas —la octava-lira lo declara como «una
   condición que no falla»— y no una sirima de seis.

**Lo que hay que decidir**, y es del IP:

1. Si la regla del eslabón necesita además una **extensión mínima de sirima** para separar canción
   de alirada, o si basta el verso que repite.
2. Si la frase de la canción petrarquista «**la tradición** y este catálogo la llaman alirada» puede
   sostenerse, cuando la tradición que se invoca clasifica al revés el caso de nueve versos.
3. Si «petrarquista» nombra propiamente la estancia de trece versos, y entonces la forma debería
   llamarse «Canción» a secas, dejando el apellido en esa arquitectura, para que la variable no
   cargue con un nombre que no le corresponde.

**Se decida como se decida, hay algo que cambia igual**: la definición de la novena-lira dice hoy
«ninguna de las fuentes del catálogo la describe **ni le da nombre**», y Navarro describe una
estrofa alirada de nueve versos bajo ese epígrafe. Esa frase no puede quedarse como está.

## Apartado aparte · Para la revisión del catálogo, no para esta

- **Un comentario de cabecera en la sección de fuentes, cuando las seis disientan.** Idea de David
  del 17 de septiembre: si en alguna forma la disparidad entre fuentes fuera grande, la ficha
  pública podría llevar bajo el epígrafe «Lo que dicen las fuentes» un párrafo que la resuma, antes
  de las seis voces. No hace falta todavía; el caso que lo sugirió —alirada frente a canción— se
  resuelve documentando cada voz por separado.
- **La canción petrarquista registra una sola arquitectura regular.** Si los esquemas de Navarro
  entran, habrá más.
- **El informe de la fase 4 cita pasajes de los seis libros.** Está en la historia del repositorio,
  como ya lo están `propuestas.json` y las migraciones. Si eso no debe ser así, se saca y se deja
  local.

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
| 4 | Exhaustividad, 43 formas | **auditada, sin escribir** |
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
- [ ] **La novena-lira y la frontera alirada/canción.** Abierto: los dos esquemas de nueve versos
      de Navarro admiten lectura como canción y como alirada, y él los pone entre las aliradas. →
      decisión filológica, abajo. Una parte no espera a esa decisión: la frase «ni le da nombre» de
      su definición es falsa en cualquier caso.
- [ ] **La décima-lira y su esquema fijo.** Sin examinar todavía. Hay que aplicarle la misma prueba
      que a la novena antes de dar nada por laguna.

### 2 · Las nueve lagunas de la fase 4

Localizadas y con el pasaje abierto en
[fase-4-exhaustividad.md](./fase-4-exhaustividad.md). **Ninguna escrita.** Se redactan por fuente y
se aprueban en tandas, como el cubo material.

| | forma · fuente |
| --- | --- |
| 1 | Octava aguda · Navarro 1972 — doce secciones y una frase sobre el teatro |
| 2 | Verso aislado · Quilis 1969 |
| 3 | Verso aislado · Caparrós 2014 |
| 4 | Verso aislado · Jauralde 2020 |
| 5 | Cuarteto-lira · Jauralde 2020 |
| 6 | Cuarteto-lira · Caparrós 2014 |
| 7 | Sextina (composición) · Jauralde 2020 — bajo el epígrafe «Sexta rima» |
| 8 | Décima-lira · *Diccionario* 2016 — **sin examinar**: aplicarle antes la prueba de la novena |
| 9 | Versificación irregular · Quilis 1969 |

Y una **décima**, la novena-lira · Navarro 1972, que **no es laguna hasta que el IP cierre la
frontera** entre alirada y canción.

Y **los veinte silencios justificados**, que hay que dejar escritos para que la ficha pública
distinga entre «no lo dice» y «no lo hemos mirado».

### 3 · Los dos cubos que quedan abiertos

De las 267, ya no cambia texto ninguna de **fondo** (33) ni de **material** (56 corregidas,
17 desmentidas por la verificación). Quedan:

| cubo | pendientes | qué son |
| --- | --- | --- |
| confirmación | 57 | comprobaciones, no correcciones de texto |
| observación | 50 | notas |
| limpio | 1 | |
| filológico | 1 | decisión del IP |

Y **dos propuestas sin redactar**: `9c4dd052` (lira de Morley y Bruerton) y `cfb377cd`
(septeto-lira de Navarro).

### 4 · Fase 5: informe y muestra humana

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

- **La canción petrarquista registra una sola arquitectura regular.** Si los esquemas de Navarro
  entran, habrá más.
- **El informe de la fase 4 cita pasajes de los seis libros.** Está en la historia del repositorio,
  como ya lo están `propuestas.json` y las migraciones. Si eso no debe ser así, se saca y se deja
  local.

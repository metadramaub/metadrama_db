# Estado de la auditoría de fuentes

**Este documento manda sobre el orden de trabajo.** El
[plan](../plan-auditoria-fuentes.md) dice qué es cada fase y cómo se comprueba; aquí está qué queda
por hacer y en qué orden. Se actualiza al cerrar cada cosa: lo terminado se borra, no se tacha.

Actualizado el 20 de septiembre de 2026.

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
sobre las 108 que se le han repartido —las 58 de la primera tanda, las 50 del cubo de observación—.
**48 migraciones aplicadas** desde el 11 de septiembre.

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

Los dos que estaban abiertos, confirmación y observación, **están cerrados y ninguno estaba
limpio**. Lo que queda son dos afirmaciones sueltas y una propuesta:

| cubo | pendientes | qué son |
| --- | --- | --- |
| limpio | 1 | |
| filológico | 1 | decisión del IP |

Y **una propuesta sin redactar**: `cfb377cd` (septeto-lira de Navarro). La otra, `9c4dd052`, se
redactó al cerrar el cubo de observación.

#### El cubo de confirmación · **cerrado, y no estaba limpio**

La hoja lo describía como «conformes sin ninguna divergencia señalada, **no piden decisión**». No lo
eran: **41 de las 57 llevaban alguna señal mecánica**, y de las tres pasadas habían tenido A y B las
cincuenta y siete, **C ninguna**.

Pasada la C sobre las 57, salen **ocho defectos**, migrados en tres tandas separadas:

| | |
| --- | --- |
| `20260919160000` | seis invenciones y dos epígrafes que no existen |
| `20260919170000` | 22 localizadores ganan la página impresa |
| `20260919180000` | 7 dicen ya que la afirmación está repartida |

**Lo que se retiró** fueron cosas puestas en la voz de una fuente: la glosa «X es el verso sin rima»
que Morley y Bruerton no enuncian, la sigla `AB-DE-CF` que no aparece ni una vez en Caparrós, y dos
fichas que explicaban el catálogo desde dentro de una fuente.

**Y dos hallazgos de método:**

- **La guarda del `AB-DE-CF` identificó al donante.** Escrita para exigir que la sigla no quedara en
  ninguna ficha, falló señalando una segunda: la sextina de Quilis. Pero ahí es correcta, porque es
  notación suya. La sigla no se inventó, **se copió de una ficha a otra** — y es la primera vez que
  el copiar-pegar aparece con origen identificado.
- **Un epígrafe inventado que ninguna pasada vio.** «Formas mixtas en cuartetos y septetos» no existe
  en Jauralde; salió de cotejar sus cincuenta localizadores contra los 214 encabezados reales del
  epub. Esa comprobación no está escrita como script y convendría que lo estuviera.

**Lo que la C confirma**, que es la mayor parte: 44 de las 57 bien localizadas, dos silencios
confirmados por agotamiento y **siete páginas de Navarro Tomás**, cuya paginación el plan marcaba
como «lo primero que hay que probar».

*Y cuatro falsos positivos suyos, que sostienen la regla: la C tampoco decide sola.*

#### El cubo de observación · **cerrado, y tampoco estaba limpio**

Cincuenta afirmaciones descritas por la hoja como «conformes, pero con algo anotado». De las tres
pasadas habían tenido A y B las cincuenta y **C ninguna**: el mismo agujero que el cubo anterior.
Pasada la C y leídas las cincuenta notas una a una, **39 pedían algo** y once estaban limpias.

| | |
| --- | --- |
| `20260920100000` | nueve glosas salen de la voz de la fuente, y una singular se hace plural |
| `20260920120000` | once fichas recobran lo que la fuente decía y ellas callaban |
| `20260920140000` | treinta y un localizadores, cuatro de ellos equivocados |

**La familia mayor vuelve a ser la misma**: una frase del catálogo puesta en boca del libro —«su
corpus es Lope, posterior al de los entremeses», «la silva dramática nace, por tanto, de…», «Es la
única fuente que la describe»—. No es casualidad: la heurística que reparte los cubos busca las
palabras con que un verificador señala una divergencia, y son las mismas que usa cuando ve que la
ficha ha añadido algo suyo.

**Y cuatro cosas que enseñó:**

- **Las entradas del *Diccionario* con sentidos numerados.** Tres fichas perdían lo mismo, y siempre
  lo que llevaba número: «serventesio 2 → cuarteta», «sextilla 2 → sexteto», «verso libre, 2». Con
  la sextina de dos días antes son cuatro. **Es una regla, no una casualidad**, y está apuntada como
  quinta comprobación mecánica.
- **Una glosa que no lo era.** «Las estrofas enlazadas llevan esa misma quintilla dentro» parecía
  inferencia del catalogador; el § 131 lo dice con esas palabras. Cortarla habría perdido fuente.
- **Lo que la ficha ya tenía.** La escansión que el septeto-lira atribuía al *Diccionario* es su
  propia arquitectura —`7-11-7-11-7-7-11` y `ababbcc`— repetida con firma ajena debajo.
- **Una excepción borrada que toca lo abierto.** Navarro dice que la quinta canción de Garcilaso
  está «compuesta en liras», dentro del epígrafe de la estancia. La ficha se la había comido, y cae
  justo en la frontera alirada/canción que espera al IP.

#### Lo que queda de los cubos

| cubo | pendientes | qué son |
| --- | --- | --- |
| limpio | 1 | |
| filológico | 1 | decisión del IP |

Y **una propuesta sin redactar**: `cfb377cd` (septeto-lira de Navarro).

**Lo que sigue fuera del alcance mecánico: 114 de las 267** no comparten con su pasaje ninguna tirada
de seis palabras, porque parafrasean en vez de reutilizar el léxico de la fuente. Son las que solo
puede ver una lectura, y la tanda dirigida sigue pendiente.

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

- **La quinta comprobación mecánica, y ya sabe qué buscar.** Recorrer las entradas del *Diccionario*
  con sentidos numerados y cotejar cuáles recoge la ficha. En el cubo de observación acertó tres de
  tres; con la sextina, cuatro.
- **«Es la única fuente que la describe» sigue en dos fichas más.** Al comprobar que la frase había
  salido de `c5992665` apareció idéntica en `eccebfab` (septilla enlazada) y `412ad16e` (sextilla
  enlazada), las dos de Navarro Tomás y las dos **fuera de este cubo**: están en el de material y
  dadas por corregidas. Es la misma familia de copiar-pegar, con tres hermanas esta vez. Pendiente
  de decidir si se retiran igual.
- **Una ficha de Morley y Bruerton habla todavía en singular**, `40c2c354` («La caracteriza»), fuera
  de este cubo. Las otras dos se arreglaron el 20 de septiembre.
- **El *Diccionario* cita de dos maneras.** Quedan ocho fichas con «s. v.» frente a las 53 que usan
  «Entrada», y quince sin página. Es trabajo de consistencia, no de auditoría.
- **`22c63f36` enumera «series arromanzadas» entre los tipos con nombre.** La pasada C avisa de que
  en el § 498 aparece como ejemplo suelto de García Lorca, no como categoría de la seguidilla. El
  texto se cerró sin tocar eso; queda por mirar.

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

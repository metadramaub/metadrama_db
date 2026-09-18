# Canción, liras, romance y endecasílabo · lo que se partió el 17 y el 18 de septiembre de 2026

**Documento histórico: nada de esto describe el estado actual.** Es el plan con el que se partió la
canción petrarquista en tres formas y se fijó la frontera con las estrofas aliradas, con el
razonamiento y la fuente de cada decisión. Se aplicó en la migración
`20260922160000_la_cancion_empieza_en_nueve.sql`; lo vigente se lee en `/formas`. Se conserva porque
las definiciones se discutieron frase a frase y aquí está por qué dicen lo que dicen.

Contrastado contra la base viva (revisión 4808, modelo 59), el código y la bibliografía local.

---

## 0 · Lo que el plan anterior decía y la base no confirma

Todo lo demás del plan anterior **sí** está como decía: arquitecturas, secciones, grupos, relaciones,
denominaciones, afirmaciones, las ocho anotaciones, los términos legados y su uso cero. Esto es lo
que no cuadraba o faltaba:

1. **Dos de las ocho anotaciones caen por debajo del suelo nuevo.** *El marqués desdichado (prueba)*,
   vv. 1–15, son tres estancias de **cinco**; *El remedio en la fortuna (prueba)*, vv. 2461–2484,
   tres de **ocho**. La base no valida `versos_min`/`versos_max` de una sección sobre lo anotado
   —solo repeticiones y que el patrón de la primera se mantenga—, así que la migración no fallará,
   pero deja dos anotaciones fuera de norma. Son obras de prueba: se resuelve **regenerando los
   guiones** después de la migración (paso 6), no a mano.
2. **El techo de quince está en Morley y Bruerton, pero no donde se citaba.** Resuelto el 17 de
   septiembre leyendo `M&B_completo.pdf`, *Estudio de las estrofas*, pp. 175–178 (pdf 177–180). La
   canción rimada de Lope va de **7 a 15** versos —«trece tipos»; la más larga es la «mezclada» de
   13, 13, 13, 14 y 15 de *El verdadero amante*— y la regular de trece va **«sin envío»**. La sin rima
   va de **7 a 20** —*La pastoral de Jacinto*, «13 × 6 más 14 más 20»— con remates de 2 a 16. El «de 5
   a 20» de la definición no coincide con su propia lista por abajo: ninguna de las dos baja de 7.
   Además llaman a la sin rima «Canción **Libre** o Sin Rima», y *La fábula de Perseo* va «13, 14,
   esdrújulos». Ese tramo del libro **no está volcado a texto**: se cita por página del libro.
3. **El identificador es el `slug`**, no un `forma_id` legible (`forma_id` es uuid). Y la columna es
   `nivel_estructural`, no `nivel`. Cambia cómo se escribe la migración, no lo decidido.
4. **`origen_termino_id` es único en `formas_metricas`.** Mover el término legado
   `cancion_petrarquista` a la forma nueva exige vaciarlo antes en la vieja, en ese orden.
5. **`metric-colors.ts` no conoce `cancion` ni `cancion_sin_rima`.** Sin entrada, esas formas
   salen sin color en el código de barras de la ficha. Hay que añadirlas.
6. **Las migraciones ya aplicadas llegan a `20260922140000`.** La nueva tiene que ordenarse
   después, aunque la fecha real sea anterior.
7. **`primer_pie` está del revés, confirmado en el libro.** Caparrós 2014, p. 214: la fronte está
   «formada por dos pies, normalmente de tres versos, **unidos por la rima**», y su ejemplo de la
   *Égloga I* permuta la figura. La nota dice hoy «riman igual; cambian los sonidos, no la figura».
8. **Las siete aliradas tienen cero secciones**: comprobado. La prohibición de declarar estructura
   ya es física.
9. **El separador**: 11 notaciones con `:` y 15 con `|`; el editor pinta `|`. Sigue sin decidir,
   no bloquea nada.

---

## 1 · Decisiones

### Cerradas

| | decisión |
| --- | --- |
| Reparto | tres formas donde hoy hay una: **Canción** (`cancion`, nueva), **Canción petrarquista** (`cancion_petrarquista`, conserva slug y URL), **Canción sin rima** (`cancion_sin_rima`, nueva) |
| Suelo | la estancia de la canción empieza en **nueve** versos: hasta ocho, alirada sin discusión |
| Techo | **quince** para la canción rimada; la sin rima, **7–20** (D7) |
| Frontera en 9 y 10 | no la decide el eslabón ni un pareado final: la decide **si la estrofa se considera una estancia con partes** (fronte y sirima) o no. **En la prosa pública no se habla de editores ni de anotar**, y el registro es el de una definición: se declara la coincidencia de materia y extensión, el criterio que distingue, y el límite con sus fuentes. Un pareado final no es una sirima —todos los sextetos-lira lo tienen—. La misma estrofa de nueve puede anotarse como novena-lira o como canción, y después se comparan por el esquema de rima |
| Partición | `fronte` y `sirima` pasan a **opcionales** (`0–1`); el eslabón ya lo es. Sí = existe; sin respuesta = no se ve, y no por eso deja de ser canción, sobre todo de once para arriba |
| Estancias que discrepan en la partición | no es una respuesta, es una **desviación de estructura** en esa unidad; el aviso «Aparece en 2 de 3» se queda |
| Petrarquista | el apellido nombra **solo la estancia de trece**, contra el uso de las fuentes, y la ficha lo dice |
| Sin rima | **forma propia**, no arquitectura |
| Remate | **no es obligatorio** en ninguna de las tres canciones (`0–1`, como hoy). Morley y Bruerton dan la regular de Lope «sin envío» |
| Pasajes de estancias de distinta extensión («mezcladas») | se decide cuando aparezca uno: si se admite o se parte en secuencias |
| `cancion_endecasilaba` (legado) | según el IP es un esquema de **octava real** (`ABCABCDD`); no es canción. Queda apuntado en E2 |

### Cerradas el 17 de septiembre, tras revisar el plan

| | decisión |
| --- | --- |
| D2 | la petrarquista lleva la denominación «Canción regular» (Morley y Bruerton, p. 175) |
| D3 | la descripción de «Regular de 13 versos» **no se vacía**: como en las demás formas de una sola arquitectura, dice lo técnico y la definición lo histórico (§ 2.3) |
| D4 | la frase sobre el nombre «petrarquista» va al final de la definición **y** en la relación `subtipo_de` |
| D5 | el separador `:` / `\|` se aplaza: **entra en PENDIENTES.md** |
| D6 | se crea `Canción --contrasta_con--> Septeto-lira` |
| D7 | la estancia de la sin rima mide **7–20**, siguiendo la lista de Morley y Bruerton |
| D8 | la sin rima recibe sección `remate`, `0–1`, de 1 a 20 versos |
| § 2.5 | los esquemas de nueve de Navarro admiten ambas lecturas, **con estructura —incluso con eslabón— o sin ella**, porque un pareado de sirima es débil; no se declaran como patrón en ninguna forma |
| § 2.1 | novena y décima dicen «cuando se considera una estrofa sin partes / cuando una fronte de dos *piedi* y una sirima la articulan como estancia» |

### Abiertas (siguen en cuestiones para el IP)

Si las estancias de la sin rima repiten la distribución posicional (4). La rima del eslabón y del
remate (5).

---

## 2 · La prosa

Reglas que gobiernan lo de abajo, de [dónde vive la prosa](./donde-vive-la-prosa.md): la
**definición** dice qué **es** la forma, no qué decidió el proyecto ni cómo se anota, ni de dónde
venía; **no cita**; acaba donde acaba lo que define. Lo que separa una forma de otra vive en la
**relación**. Lo que una fuente añade vive en su **afirmación**. Nada menciona el estado anterior
del catálogo.

### 2.1 · Definiciones

**Canción** (`cancion`)

> Composición en estancias: una estrofa larga de heptasílabos y endecasílabos con rima consonante
> que el poeta dispone a su gusto en la primera y repite sin cambio en todas las demás, tres por lo
> menos. La estancia mide de nueve a quince versos y suele ordenarse en dos partes: una **fronte**,
> hecha de dos *piedi* unidos por la rima, que suelen medir lo mismo, y una **sirima** de rimas nuevas, que
> a menudo se abre con un verso —el **eslabón**, *volta* o *chiave*— que retoma la rima con que se
> cerró la fronte. Esa ordenación es frecuente, no obligatoria: una estancia sin eslabón, o sin
> partición reconocible, sigue siendo estancia. La composición suele cerrarse con un fragmento de
> estancia más breve, el **remate**, envío o *commiato*, en el que el poeta se dirige a menudo a la
> propia canción; tampoco él es obligatorio. «Canción» a secas designa esta forma de tradición
> italiana, no la canción medieval del siglo XV.

Sale de aquí, respecto del plan anterior: todo lo de las aliradas (va a las relaciones con
octava-lira y novena-lira), la frase sobre el criterio antiguo, y la mención a la petrarquista (va
a la relación `subtipo_de`).

**Canción petrarquista** (`cancion_petrarquista`)

> Canción cuya estancia es la regular de trece versos, `abCabC:cdeeDfF` sobre la medida
> `7 7 11 7 7 11 7 7 7 7 11 7 11`, repetida tres veces por lo menos, con remate o sin él. Es la
> estancia que Garcilaso tomó de la canción undécima de Petrarca para su segunda égloga, la que
> Herrera empleó en su canción quinta y la más frecuente en la comedia del Siglo de Oro. Su fronte
> son dos *piedi* de tres versos unidos por la rima, `abC` y `abC`; el séptimo verso, heptasílabo,
> rima con el último de la fronte y abre ya la sirima, y por eso es el eslabón; la sirima cierra con
> dos pareados y un endecasílabo suelto de remate de estancia. El nombre, que los tratados aplican a
> la canción italiana en general, designa aquí solo esta estancia, la que viene literalmente de
> Petrarca.

**Canción sin rima** (`cancion_sin_rima`)

> Composición en estancias de heptasílabos y endecasílabos sin rima, salvo el pareado consonante con
> que cada estancia termina. La estancia mide de siete a veinte versos y repite en todas las demás
> la distribución de medidas que fijó la primera; el pareado final es lo que hace estancia a cada
> estrofa y composición al conjunto. Es forma del teatro: los tratados de métrica no la registran,
> porque describen la canción como forma siempre rimada, y se conoce por el recuento de las
> estrofas sin rima de las comedias.

Las dos razones de registrarla como forma —entrada propia en su única fuente, y que no es una silva
aunque tampoco rime— van a las relaciones con Canción y con Silva.

**Novena-lira** (`novena_lira`)

> Estrofa de nueve versos que mezcla endecasílabos y heptasílabos en proporción variable y rima en
> consonante, sin que la norma fije cómo se reparten las rimas. Pertenece a la serie de las estrofas
> aliradas: la misma materia de la canción, siete y once consonantes repetidos sin cambio de una
> estrofa a otra, sin la ordenación de la estancia. Es la primera extensión en la que la duda con la
> canción se plantea, porque a los nueve versos una estancia ya es posible: es novena-lira cuando
> se considera una estrofa sin partes, y canción cuando una fronte de dos *piedi* y una sirima la
> articulan como estancia.

**Décima-lira** (`decima_lira`)

> Estrofa de diez versos que mezcla endecasílabos y heptasílabos y rima en consonante. Pertenece a
> la serie de las estrofas aliradas —la materia de la canción, siete y once consonantes repetidos
> sin cambio, sin la ordenación de la estancia— y, como la novena, cae en la franja en la que una
> estancia es posible: es décima-lira cuando se considera una estrofa sin partes, y canción cuando
> una fronte de dos *piedi* y una sirima la articulan como estancia. La tradición crítica la llama también «décima-estancia», por lo cerca que queda de una
> estancia de diez versos.

El análisis de `aBaBcDcDeE` —repite la figura, no las rimas, y por eso no hace fronte— va a la
descripción de ese esquema, que es donde está hoy y donde hoy dice lo contrario.

**Octava-lira** (`octava_lira`) · solo cambia el último tramo

> […] Es la mayor de las estrofas aliradas: tiene la materia de la canción, siete y once
> consonantes repetidos sin cambio de una estrofa a otra, y le falta su ordenación. Que cierre en
> pareado no la acerca a la estancia —el sexteto-lira también cierra así—, y hasta los ocho versos
> no cabe canción: la estancia empieza en nueve.

Se va: «la que más fácilmente se confunde con una estancia de canción», «algunas de sus
disposiciones repiten la cabeza como lo haría una fronte» y todo lo del eslabón. Que las fuentes
duden a veces —Navarro, «con aspecto de estancias», «pueden más bien considerarse»— ya lo dicen
sus afirmaciones; el corte en ocho es nuestro y va en la relación con Canción.

**Cuarteto-lira**: se **quita** la frase «En una estrofa tan breve la diferencia no llega a
plantearse, porque no hay sitio para una fronte partida en dos piedi y una sirima con eslabón»: ni
la lira ni el sexteto lo dicen, y la comparación con la estancia no es cosa del cuarteto. Queda:
«…Es la menor de las estrofas aliradas: tiene la materia de la canción italiana, siete y once
consonantes repetidos sin cambio de una estrofa a otra, y le falta su ordenación. La tradición
registra también realizaciones con rima asonante o con algún verso suelto.»

### 2.1b · El origen común, dicho una vez

Las seis fuentes cuentan la misma historia y ninguna definición la cuenta: la lira es una estancia
recortada —el *Diccionario* la llama también «media estancia»—, y la serie alirada creció desde
ella hasta el tamaño en que empieza la estancia. Eso es lo que explica el solape en nueve y diez,
y por qué el *Diccionario* llama «canción alirada» a la composición hecha con ellas y Morley y
Bruerton dicen que «todas las liras no son más que formas especializadas de la *canzone*». Se
cuenta **dos veces, desde cada lado**, y las otras cinco aliradas se quedan con su cláusula de
«tiene la materia de la canción y le falta su ordenación», que ya remite a esto.

**Lira** (`lira`), definición nueva entera:

> Estrofa de cinco versos —7 11 7 7 11— con rima consonante repartida en dos clases y cierre en
> pareado, aBabB. Es una estancia de canción reducida a su mínimo, y por eso se la ha llamado
> también «media estancia»: la misma materia, heptasílabos y endecasílabos consonantes, fijada en
> una estrofa breve que se repite sin cambio. Bernardo Tasso la había usado en italiano, y Garcilaso
> la introdujo en castellano en la canción «A la flor de Gnido», de cuyo primer verso —«Si de mi
> baja lira»— toma el nombre. Fray Luis de León la consagró como molde de la oda horaciana, donde
> la estancia larga sobraba, hasta darle otro nombre. De ella salen el sexteto-lira, que la amplía
> a seis versos, y la serie entera de estrofas aliradas, que fue creciendo estrofa a estrofa hasta
> el tamaño en que empieza la estancia y que en el Barroco la desplazó.

**Canción** (`cancion`): se añade una frase antes de la última:

> …tampoco él es obligatorio. De su estancia salió, recortada a cinco versos, la lira, y de la lira
> la serie de estrofas aliradas, que tienen su misma materia sin su ordenación y que crecieron
> hasta rozar su tamaño: por eso los tratados llaman «canción alirada» a la composición hecha con
> ellas. «Canción» a secas designa…

**Denominación nueva** de la lira: «Media estancia», *Diccionario*, entrada «lira», p. 224.

**Afirmaciones de la lira que se completan** (comprobado el 17 de septiembre):

- **Navarro Tomás**: hoy cita solo el § 462 (la lira en el siglo XX). Se reescribe con el § 111
  —Garcilaso la introdujo con la *Canción de Gnido*; la idea «pudo recogerla» de Bernardo Tasso, que
  usó esa estrofa en sus *Amori*, 1534; «apenas practicada en Italia, fue acogida con especial
  predilección por los poetas españoles»— y el § 190, del Barroco: «Disminuyó notoriamente la lira
  de Garcilaso. Se dio preferencia a las estrofas aliradas de seis o más versos en combinaciones
  diferentes», conservando lo del § 462 al final. Localizador: «§§ 111, 190 y 462».
- ***Diccionario***: ya trae a Dámaso Alonso. Se añade que la entrada recoge «media estancia»
  entre sus otros nombres, y que su segunda acepción —«estrofa formada por cuatro, cinco, seis o
  siete versos, endecasílabos y heptasílabos, con dos o tres rimas consonantes», que «suelen
  terminar en un pareado»— es la que «constituye la estrofa de la canción alirada».

**No entra en las definiciones**: el `abC:abC` de san Juan como seis primeros versos de la
estancia de Garcilaso (Navarro § 110 n. 9). Es cuestión abierta de la serie alirada (la 2) y ahí
se queda, con la nota añadida.

### 2.2 · Notas de sección (arquitectura «Estancias consonantes variables»)

| sección | hoy | pasa a |
| --- | --- | --- |
| `fronte` | «…partida en dos piedi de igual medida y disposición. Cuánto miden lo fija cada canción.» | «Primera parte de la estancia, partida en dos piedi unidos por la rima, que suelen medir lo mismo. Cuánto miden lo fija cada canción.» *(corregido el 18: ninguna fuente exige que midan igual)* |
| `primer_pie` | «Los dos piedi miden lo mismo y riman igual; cambian los sonidos, no la figura.» | «Los dos piedi van unidos por la rima —comparten sus clases, no necesariamente en el mismo orden— y suelen medir lo mismo.» |
| `segundo_pie` | «Repite la medida y la disposición del primero. Es lo que hace estancia a la estancia.» | «Comparte las rimas del primero, en el mismo orden o permutadas, y suele medir lo que él.» |
| `eslabon` | «…Es lo que separa una estancia de una estrofa alirada, y en la tradición italiana es habitual pero no obligatorio: una canción sin él no deja de serlo, aunque este catálogo llame alirado por defecto a lo que no lo trae.» | «Verso que abre la sirima retomando la rima con que se cerró la fronte —la *chiave* o *volta*—. Habitual, no obligatorio: una estancia sin él no deja de serlo.» |
| `sirima` | «Segunda parte de la estancia, con rimas nuevas y sin la simetría de la fronte.» | igual |
| `remate` | (larga, correcta) | igual |

Las de «Regular de 13 versos» están vacías y así se quedan: la definición ya lo dice todo.

### 2.3 · Descripciones de arquitectura

| arquitectura | pasa a |
| --- | --- |
| Estancias consonantes variables (→ Canción, principal) | «El caso general: la estancia se inventa para cada canción y no hay dos iguales. Mide de nueve a quince versos: el suelo la separa de las estrofas aliradas, y el techo es el de la canción dramática. Fuera del teatro las hay más largas —la canción cuarta de Garcilaso tiene ocho estancias de veinte versos—, y quedan en las fuentes de esta ficha aunque el catálogo no las admita.» |
| Regular de 13 versos (Canción petrarquista, única) | «Trece versos, `7 7 11 7 7 11 7 7 7 7 11 7 11`, con la rima `abCabC:cdeeDfF`: fronte de dos *piedi* de tres versos, eslabón heptasílabo y sirima de seis versos con dos pareados y endecasílabo final. Medida y rima están fijas en todas las posiciones, de modo que la norma no deja nada por elegir; solo el remate, cuando lo hay, varía en extensión.» |
| Sin rima, con pareado final (→ Canción sin rima, única, `habitual`) | «Estancia de siete a veinte versos de siete y once sílabas, sin rima salvo el pareado consonante con que termina; la distribución de medidas la fija la primera estancia y la repiten las demás. Lo único variable es la medida de cada verso y, cuando se sostiene, la terminación esdrújula.» |

### 2.4 · Descripción del esquema `aBaBcDcDeE` de la décima-lira

Hoy: «…Repite la cabeza como lo haría una fronte y no trae eslabón, que es lo que la deja del lado
alirado.»

> Dos parejas de rima cruzada y un pareado final. En el testimonio que la documenta los
> heptasílabos y los endecasílabos alternan uno a uno —aBaBcDcDeE—, pero es un solo testimonio y no
> basta para fijar esa alternancia como norma. Sus versos quinto a octavo repiten la figura de los
> cuatro primeros con rimas nuevas: es un parecido con la fronte, no una fronte, porque los dos
> *piedi* comparten las rimas y estos bloques no.

### 2.5 · Descripción del esquema abierto de la novena-lira

Hoy: «…de esta forma no hay ninguna disposición documentada, y declarar una sería inventarla.» Es
falso —Navarro documenta dos— y con la frontera nueva lo sigue siendo, porque esas dos **pueden**
leerse de los dos lados.

> La norma exige que los nueve versos rimen en consonante y no fija cómo se reparten las rimas. Las
> dos disposiciones de nueve versos que Navarro Tomás describe entre las aliradas, `abCabCcdD` y
> `AbCAbCcdD`, admiten las dos lecturas: como estrofa sin partes, o como estancia con fronte
> `abC|abC`, eslabón y una sirima reducida a un pareado, que es un cierre débil para sostener por
> sí solo la articulación. Por eso no se declaran como patrón de esta forma ni de la canción.



### 2.6 · Relaciones

**Se repuntan** (hoy con origen o destino en `cancion_petrarquista`; pasan a `cancion`):

| relación | nota |
| --- | --- |
| `Canción --contrasta_con--> Lira` | «Hasta ocho versos no hay duda posible: una estrofa de siete y once consonantes repetida sin cambio es alirada, y la canción empieza en nueve. Es el suelo en el que coinciden cuatro de las seis fuentes, y el único que Jauralde razona: sitúa la estancia “normalmente por encima de los ocho versos, para diferenciarla de las liras”.» |
| `Canción --contrasta_con--> Silva` | igual que hoy |
| `Décima-lira --relacionada_con--> Canción` | «Desde los nueve versos las dos formas son posibles sobre la misma materia, y lo que decide es la ordenación: la canción parte la estancia en una fronte de dos *piedi* unidos por la rima y una sirima de rimas nuevas; la décima-lira repite diez versos iguales sin esa partición. Un pareado final no basta para hacer sirima. El patrón `aBaBcDcDeE` que el catálogo recoge repite la figura de sus cuatro primeros versos con rimas nuevas, y por eso no hace fronte.» |

**Se crean:**

| relación | nota |
| --- | --- |
| `Canción petrarquista --subtipo_de--> Canción` | «La estancia regular de trece versos, `abCabC:cdeeDfF`, es la realización más frecuente de la canción y se registra aparte porque su extensión es fija donde la de la canción varía; una arquitectura no cambia la extensión de la unidad de su forma. Las fuentes usan “petrarquista” como sinónimo de “canción a la italiana”: aquí el apellido se reserva para la estancia que viene literalmente de Petrarca, y los nombres generales se registran en la canción.» |
| `Canción sin rima --contrasta_con--> Canción` | «Misma materia, misma repetición del patrón que fijó la primera estancia y mismo cierre en pareado; lo que las separa es el régimen. La canción es siempre consonante y esta no rima salvo en el pareado final. Solo Morley y Bruerton la registran, y la registran con epígrafe propio.» |
| `Canción sin rima --contrasta_con--> Silva` | «Las dos combinan heptasílabos y endecasílabos y las dos pueden no rimar. La diferencia es que aquí hay estancia: una estrofa de medida fijada por la primera, repetida sin cambio y cerrada cada vez por un pareado, con lo que el conjunto es una composición; la silva es una serie sin unidad que se repita, y su pareado, cuando lo hay, cierra la serie y no una estrofa.» |
| `Canción --contrasta_con--> Novena-lira` | «A partir de los nueve versos las dos formas coinciden en materia y en extensión —heptasílabos y endecasílabos consonantes, repetidos sin cambio de una estrofa a otra— y solo se distinguen por la articulación interna: la estancia se compone de una fronte de dos *piedi* unidos por la rima y una sirima de rimas nuevas, con eslabón o sin él; la novena-lira es una estrofa sin partes. El pareado final no constituye por sí solo una sirima, puesto que cierra también las estrofas aliradas menores. Las dos disposiciones de nueve versos que Navarro Tomás describe entre las aliradas, `abCabCcdD` y `AbCAbCcdD`, admiten ambas lecturas.» |
| `Canción --contrasta_con--> Octava-lira` | «Las dos formas comparten la materia, y la extensión es el criterio que las separa: el catálogo sitúa el límite inferior de la estancia en nueve versos, de acuerdo con cuatro de sus seis fuentes, de modo que una estrofa de ocho de heptasílabos y endecasílabos consonantes, repetida sin cambio, se registra como octava-lira con independencia de su disposición de rimas. La delimitación no es unánime en la bibliografía: Morley y Bruerton cuentan como canción dos estrofas de ocho de Lope de Vega, `abbaCcDD` en *El castigo sin venganza*, que aquí corresponde a la octava-lira, y `ABCABCDD` en *Barlaán y Josafat*, que por ser toda de endecasílabos queda fuera de la serie alirada.» |
| `Canción --contrasta_con--> Septeto-lira` *(D6)* | «Por debajo de los nueve versos una estrofa de heptasílabos y endecasílabos consonantes, repetida sin cambio, pertenece a la serie alirada. Morley y Bruerton cuentan como canción dos estrofas de siete de Lope de Vega: `aBabBcC` en *Vida y muerte del rey Bamba*, que es la disposición documentada del septeto-lira, y `AabBCdC` en *La condesa Matilde*, siete versos cerrados en endecasílabo que su norma admite.» |

**Se corrigen sin moverse:**

| relación | hoy | pasa a |
| --- | --- | --- |
| `Décima-lira --relacionada_con--> Novena-lira` | «…ninguna de las dos la documentan las fuentes del catálogo… de esta hay testimonio en el corpus y de aquella no.» | «Las dos cierran la serie alirada por arriba y las dos caen ya en la franja en la que la canción es posible. Solo las separa la extensión, diez versos frente a nueve. Navarro Tomás documenta dos disposiciones de nueve y una de diez, `AaBBCCddEE`, y el *Diccionario* da entrada propia a la de diez con el nombre “décima-estancia”.» |
| `Novena-lira --relacionada_con--> Octava-lira` | «…de la novena no se conoce ninguna.» | «Las dos son estrofas aliradas y solo las separa la extensión, nueve versos frente a ocho; pero a los nueve la canción ya es posible y a los ocho no. La octava tiene disposiciones documentadas y una invariante —cierra en pareado—; de la novena, Navarro Tomás documenta dos, y las dos se dejan leer también como estancias.» |

`subtipo_de` es lo único que vigila el auditor (D8: esquemas copiados entre formas emparentadas).
No salta: la canción no declara notación y la petrarquista declara `abCabC:cdeeDfF`, que no comparte
con nadie. Comprobado en el código de D8.

### 2.7 · Denominaciones

| nombre | hoy en | pasa a |
| --- | --- | --- |
| Canción (M&B) · Canción a la italiana (Dicc.) · Canción extensa (Dicc.) | petrarquista | **Canción** |
| Canción regular (M&B, p. 175) | — | petrarquista, si D2 = sí |
| Canción libre (M&B, p. 177) | — | **Canción sin rima**, nueva |
| Décima-estancia | décima-lira, sin fuente | igual, **con fuente**: Diccionario, p. 110 (hoy le falta) |

### 2.8 · Afirmaciones

Una afirmación no se reutiliza entre formas: se **escriben de nuevo** para cada forma, con lo que la
fuente dice de **esa** forma.

| fuente | Canción | Canción petrarquista | Canción sin rima |
| --- | --- | --- | --- |
| Quilis | la actual, entera | — | — |
| Caparrós 2014 | la actual, entera | — | — |
| Diccionario | la actual, entera | — | — |
| Jauralde | la actual, entera | — | — |
| Navarro § 108 | la actual, entera | nueva: la estancia `abCabC:cdeeDfF` de la segunda égloga, «tenía por modelo la de la canción undécima del Petrarca», usada por Herrera e imitada después; las canciones de Garcilaso son en su mayor parte de cuatro o cinco estancias de trece | — |
| Morley y Bruerton | Cap. V «Canción (Canzone)», p. 40, **y Estudio de las estrofas «Canción», pp. 175–176**: definen la canción como versos de 7 y 11 en estrofas «de 5 a 20 versos» con rima fija e idéntica en cada estrofa, «rara vez» mezclada; pero su relación de los trece tipos que Lope empleó va de **siete a quince** versos —de 7, `aBabBcC` y `AabBCdC`; de 8, `ABCABCDD` y `abbaCcDD`; de 9, `aBaBbcddC`; de 10, `aBaBcdcCd`; de 11, `aXa:bbcddCeE` y `ABCABCcdDEE`; y una «mezclada» de 13, 13, 13, 14 y 15 en *El verdadero amante*—, ninguno aparece en más de una comedia y todos son anteriores a 1620 | Cap. V, p. 40, y pp. 175–177: «la más frecuente, con mucho, es la estrofa de 13 versos de la *Canzone XI* de Petrarca (“Chiare, fresche e dolci acque”): abCabC:cdeeDfF, **sin envío**. Usamos la palabra “regular” para referirnos a ella»; en 16 comedias de la Tabla I y otras 16 de la Tabla II, normalmente para monólogo | Cap. V, p. 41, y pp. 177–178: «la estrofa sin rima, que llamamos aquí Canción Libre o Sin Rima», versos italianos de 7 y 11 sin rima «menos en el pareado final», usada en Italia por Martelli, por Bermúdez en *Nise laureada* (1577) y por Lope, «y por ningún otro poeta español que sepamos»; sus estancias van de siete a **veinte** versos —*La pastoral de Jacinto*, «13 × 6 más 14 más 20»— y ningún caso es posterior a 1611; *La fábula de Perseo* va «13, 14, esdrújulos» |

Las afirmaciones de las aliradas que citan el «5 a 20» no se tocan: dicen lo que su fuente dice.

**Lo que esas páginas añaden a lo abierto:** la regular de Lope va «sin envío» —cuenta para la
cuestión 2, el remate—; «Canción libre» es denominación de la sin rima con fuente (el vocabulario
legado ya la traía como equivalencia); y la «mezclada» de 13, 13, 13, 14 y 15 es un pasaje que
nuestra base obliga a partir en secuencias, porque `primera_realizacion_define_patron` exige la
misma extensión: queda como aviso en la relación, no como norma.

---

## 3 · Los datos

### 3.1 · Formas

| slug | nombre | nivel | tradición | origen_termino_id |
| --- | --- | --- | --- | --- |
| `cancion` *(nueva)* | Canción | composicion | Italiana | término legado `cancion_petrarquista` (antes vaciarlo en la vieja) |
| `cancion_petrarquista` | Canción petrarquista | composicion | Italiana | null |
| `cancion_sin_rima` *(nueva)* | Canción sin rima | composicion | Italiana | null (`cancion_sin_rima` legado ya cuelga de la arquitectura) |

### 3.2 · Arquitecturas

| arquitectura | forma | principal | modalidad |
| --- | --- | --- | --- |
| Estancias consonantes variables | `cancion_petrarquista` → **`cancion`** | false → **true** | habitual |
| Regular de 13 versos | `cancion_petrarquista` | true | habitual |
| Sin rima, con pareado final | `cancion_petrarquista` → **`cancion_sin_rima`** | false → **true** | admitida → **habitual** |

Con la arquitectura viajan solas: secciones, esquemas (`consonante-repetido`, `aa`,
`cuerpo-sin-rima`), rasgos (`densidad_de_rima = total`; `final_acentual = esdrujulo`), grupos,
`origen_termino_id` de cada una y la equivalencia legada de `cancion_sin_rima_de_esdrujulos`, que
apunta a la arquitectura.

### 3.3 · Secciones y grupos de «Estancias consonantes variables»

| qué | hoy | pasa a |
| --- | --- | --- |
| `estancia` versos | 5–20 | **9–15** |
| `fronte` repeticiones | 1–1 | **0–1** |
| `fronte` versos | 4–18 | **4–14** |
| `sirima` repeticiones | 1–1 | **0–1** |
| `sirima` versos | 1–16 | **1–11** |
| `eslabon` | 0–1, 1 verso | igual |
| `primer_pie` / `segundo_pie` | 1–1, 2–9 versos, hijas de `fronte` | igual (existen solo si existe la fronte) |
| `remate` versos | 1–20 | **1–15** |
| grupo `medida_estancia` selecciones | 5 / 20 | **9 / 15** |

Y en «Sin rima, con pareado final»: `estancia` versos `null–null` → **7–20**; `cuerpo` versos 3–18 →
**5–18**; grupo `medida_estancia` selecciones 5/20 → **7/20**; y **sección nueva `remate`** (D8):
raíz, `tipo_seccion = 'remate'`, `0–1`, 1–20 versos, orden 2, con la misma nota que el remate de
las otras dos.

### 3.4 · Anotaciones

Las **8** anotaciones de «Estancias consonantes variables» cambian `forma_id` a `cancion`. Todas de
obras de prueba, todas en secuencia, sin desviaciones. Orden en la migración: primero la
arquitectura, después las anotaciones (el disparador `validar_anotacion_metrica` exige que la
arquitectura pertenezca a la forma). Las dos que caen por debajo de nueve versos (§ 0.1) se
regeneran en el paso 6.

---

## 4 · Fuera del catálogo

| dónde | qué |
| --- | --- |
| `scripts/guion-obras-de-prueba.mjs` | `MINIMO.cancion_petrarquista = 15` → `cancion: 27` (3 × 9) y `cancion_petrarquista: 39`. `estanciasDeCancion()` tiene 5 y 20 escritos (líneas 279–283): 9 y 15. Las líneas 155–156 mapean `cancion` y `cancion_canzone` de ARTELOPE a `['cancion_petrarquista','estancias_consonantes_variables']` → `['cancion', …]`. Las 220, 491 y 620 ramifican por `forma === 'cancion_petrarquista'`: pasan a cubrir `cancion` y `cancion_petrarquista`. Y el comentario de la 153 («tres estancias de cinco es el mínimo») |
| `src/lib/utils/metric-colors.ts` | `cancion` y `cancion_sin_rima` con el **mismo color** que `cancion_petrarquista`, `#8fc4e0` |
| `src/lib/demarcador/index.test.ts:600` | espera `cancion_petrarquista` en el demarcador legado; **sigue valiendo**, el slug no cambia |
| `docs/dominio-metrico/cuestiones-para-el-ip.md` | § 5 |
| `docs/dominio-metrico/equivalencias-pendientes.md` | `cancion_de_8_versos`: destino octava-lira por extensión, sin uso. `cancion_de_9_versos` y `_15_`: extensión de la estancia de Canción. `cancion_endecasilaba`: octava real, pendiente de E2 |
| `docs/PENDIENTES.md` E2 | anotar que `ABCABCDD` (M&B, *Barlaán y Josafat*) es el candidato de octava real que dijo el IP |
| `docs/PENDIENTES.md` (B) | nuevo: el separador de las notaciones, `:` en 11 y `\|` en 15, el editor pinta `\|`; decidir cuál gana (D5) |
| `docs/dominio-metrico/implementacion-metrica.md` | si nombra la canción como ejemplo de forma con tres arquitecturas, corregirlo (comprobar al ejecutar) |

**Cabo suelto conocido, fuera de alcance:** el demarcador propondrá Canción y Canción petrarquista a
la vez para un pasaje de trece regulares, porque todas las hipótesis puntúan igual desde que se
retiró `grado_especificacion`. Es la cuestión de la prioridad residual del sexteto y la septilla.

---

## 5 · Qué cierra en cuestiones para el IP

| | pregunta | queda |
| --- | --- | --- |
| 1 | ¿La sin rima es arquitectura o forma? | **forma**, se borra |
| 3 | El suelo en cinco | **nueve**, se borra |
| 6 | La frontera alirada / canción | **extensión más lectura de la partición; no el eslabón ni el pareado**, se borra |
| 7 | ¿«Petrarquista» nombra la forma o la estancia? | **la estancia**, dicho en la ficha, se borra |
| 2 | ¿Se exige el remate? | **no**: Morley y Bruerton dan la regular de Lope «sin envío» (p. 175), se borra |
| 4, 5 | distribución posicional de la sin rima; rima del eslabón y remate | siguen, con el epígrafe renombrado a «Canción, canción petrarquista y canción sin rima» |

La serie alirada no cierra ninguna de sus cuatro.

---

## 6 · Orden de ejecución

1. **Cerrar D1–D5** aquí, contigo.
2. **Copia**: `npm run snapshot:obras` (toca anotaciones, aunque sean de prueba).
3. **Una migración**, `202609221600xx_la_cancion_empieza_en_nueve.sql` o similar, con guardas que
   comprueben los valores vivos exactos (8 anotaciones, `5–20`, `1–1`, las tres notas literales) y
   que ejecuten lo que tocan. Contenido en este orden: formas nuevas y tradición → arquitecturas
   (`forma_id`, `principal`, `modalidad`) → anotaciones (`forma_id`) → secciones y grupos →
   definiciones, notas, descripciones → relaciones → denominaciones → afirmaciones →
   `origen_termino_id`.
4. `npm run db:push` · `npm run audit:metrica` (0 defectos; D4, D17 y D18 son los que pueden
   reaccionar) · `npm run audit:anotaciones`.
5. Código: guion, colores. `npm run check`, y las pruebas de los ficheros tocados.
6. `npm run guion:pruebas` y `npm run aplicar:guiones`: regenera las obras de prueba con canciones
   que cumplan el suelo. Después, otra vez `audit:anotaciones`.
7. Leer las **ocho fichas** en `/formas`: `cancion`, `cancion_petrarquista`, `cancion_sin_rima`,
   `lira`, `cuarteto_lira`, `novena_lira`, `decima_lira`, `octava_lira`. Probar en el editor V2 una canción de nueve sin
   fronte: la pregunta «¿Aparece “Fronte”?» tiene que salir y guardar sin partición.
8. Documentación: cuestiones para el IP, equivalencias pendientes, PENDIENTES, y borrar este plan.
9. `npm run equivalencias:informe`, `npm run audit:editor` y «Actualizar datos públicos».
10. Commit.

---

## Lo que salió al anotar la primera canción, el 18 de septiembre

Aplicada la migración, David rellenó una canción en una obra de prueba y salieron tres cosas que el
plan no veía, resueltas ese mismo día:

- **El formulario de árbol no le servía a la estancia.** Una unidad con partes medía la suma de sus
  partes, así que al decir «sí» a la fronte una estancia de quince se encogía a los cuatro versos
  del mínimo de dos pies; y la partición se repartía en campos de «N.º de versos» lejos de la fila
  en que se leen medida y rima. Se hizo un control propio para las unidades que fijan el patrón y
  tienen partes opcionales: la estancia manda sobre su extensión, y la partición se declara con
  **cortes entre versos**, cuyo nombre lo pone el orden del catálogo —un corte, fronte y sirima;
  dos, fronte, eslabón y sirima si el tramo del medio es un verso, y si no los dos pies y la
  sirima; tres, pies, eslabón y sirima—. Con atajo escrito, `abC.abC:c.dD`, en el que el punto y no
  la barra separa las partes porque el separador de las notaciones sigue sin decidirse (B11). Se
  descartaron un desplegable por verso —quince controles— y uno por tramo —híbrido—.
  `src/lib/components/metrica/editor-v2/reparto-estancia.ts` y `estancia-escrita.ts`.
- **La fronte podía verse clara y sus pies no.** Los dos pies pasaron a opcionales (migración
  `20260922180000`): ninguna fuente exige que estén, y las dos que los describen dicen
  «normalmente». Y los piedi «suelen medir lo mismo», no «miden lo mismo» (`20260922170000`).
- **El remate no tenía dónde decir su medida ni su rima.** Ninguna de las tres canciones le
  preguntaba nada. Entraron dos preguntas por arquitectura, sin `define_norma`; la regular de trece
  recibió un esquema conjunto 7·11 atado a la sección del remate, porque su estancia está fijada
  verso a verso y no tenía de dónde derivar las medidas.

---

## El romance, el mismo día: tres formas por la medida

Con el criterio de la canción —una forma por lo que las fuentes tratan como forma— el romance se
partió el 18 de septiembre de 2026 en **Romance** (octosílabo), **Romance heroico** (endecasílabo)
y **Romancillo** (heptasílabo, hexasílabo, pentasílabo y tetrasílabo), migración `20260922200000`.
Las seis fuentes los distinguen por su nombre y su historia, y el vocabulario legado también
(`romance`, `romance_heroico`, `romancillo`, este último sin destino hasta hoy).

Decisiones: el tetrasílabo entra en el romancillo, porque el *Diccionario* dice «menos de ocho» y
Jauralde lo nombra; el **hexasílabo** es la arquitectura principal del romancillo —Navarro Tomás,
«mucho más corriente fue el uso del hexasílabo… desempeñó papel importante en el teatro»; Jauralde,
«la primera y más importante» variante— y el heptasílabo deja de ser «el romancillo por
antonomasia». Las tres se emparentan con `derivada_de` y no con `subtipo_de`: comparten el esquema
`[-a]…`, y el auditor (D8) habría tomado por copia la misma figura en tres medidas. Seis anotaciones
reales cambiaron de forma con su arquitectura sin tocar nada más: cuatro octosílabas se quedaron y
dos heptasílabas (*Adonis y Venus*, *El burlador de Sevilla*) pasaron al romancillo. Las
afirmaciones se escribieron de nuevo para cada forma con lo que cada fuente dice de ella; la de
Jauralde que estaba en el romance hablaba del romancillo y se fue con él. El romancillo lleva color
propio en el código de barras; el heroico, el del romance.

---

## El endecasílabo encadenado deja de ser un rasgo del suelto

Migración `20260922210000`, el 18 de septiembre. El suelto llevaba un rasgo opcional,
`encadenamiento_interior`, para el endecasílabo en que la rima final de cada verso vuelve en el
interior del siguiente. No es un suelto con algo más: es una serie en la que todo rima, aunque no
entre finales de verso. Se leyeron en su página las cuatro fuentes que lo registran —Navarro §§ 114
y 166 (pp. 209 y 258), Morley y Bruerton «Rima interna en sueltos» (pp. 173-174), Caparrós 2014
(p. 120), *Diccionario* «rima interna» y «encadenamiento» (pp. 336-337 y 137)— y se comprobó que
Quilis y Jauralde no lo registran (la «rima encadenada» de Quilis es la cruzada `abab`). Navarro
habla de endecasílabos, no de cualquier encadenamiento, y separa este procedimiento del
*leixa-prende*; Morley y Bruerton lo cuentan dentro de los sueltos, pero en varias comedias el
pasaje entero va encadenado, que es lo que aquí hace forma.

La forma nueva lleva el rasgo como **definitorio** —y por tanto sin pregunta—, el esquema de rima
abierto con una restricción que dice dónde cae la rima, y solo las preguntas de dístico final y
esdrújulo: sin densidad de rima, que se lee como rima de finales. Las seis anotaciones que marcaban
el encadenamiento —dos fuera de las obras de prueba, *Adonis y Venus* y *Prueba*— pasaron a la
forma nueva perdiendo las respuestas que ya no se preguntan. El suelto perdió el rasgo, su pregunta
y la frase de la definición que lo mencionaba.

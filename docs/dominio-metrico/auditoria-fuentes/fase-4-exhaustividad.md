# Fase 4 · Exhaustividad

Las tres pasadas anteriores comprobaron que cada afirmación dice la verdad. **Comprobar que una
afirmación dice la verdad no comprueba que diga todo lo que la fuente dice de nosotros**, ni que
existan las afirmaciones que faltan. Esta fase audita lo que el catálogo no dice.

No se audita por afirmación —una afirmación que no existe no se puede leer— sino **por forma**:
43 unidades × 6 fuentes = **258 celdas**, de las que **33 están vacías**.

El punto de partida es `npm run matriz:exhaustividad`, que dibuja el tablero y cuenta, para cada
celda vacía, cuántas veces nombra esa fuente a esa forma bajo cualquiera de sus denominaciones. Ese
recuento **no decide nada**: dice dónde mirar. Lo que decide es abrir el libro, y eso se hizo con
las 33.

## El resultado

| | celdas |
| --- | --- |
| **Lagunas confirmadas** — la fuente trata la forma y no hay afirmación | **10** |
| Falsos positivos del contador — la mención es de otra forma | 3 |
| Silencios justificados — la fuente no trata la forma | 20 |

---

## Las diez lagunas

Cada una con el pasaje localizado. **Ninguna se ha escrito todavía en el catálogo.**

### 1 · Octava aguda · Navarro Tomás 1972 — la mayor de todas

29 menciones y ninguna afirmación. No es un descuido de una línea: Navarro la trata en **doce
secciones** —§§ 227, 245, 261, 265, 269, 270, 272, 288, 309, 342, 381 y 434— y le da entrada doble
en el «Índice de estrofas», una para la de arte mayor y otra para la de arte menor, que es
exactamente el reparto de nuestras seis arquitecturas.

Da el esquema de las dos, `ABBÉ:CDDÉ` y `abbé:cddé`, y el nombre alternativo **bermudina** para la
endecasílaba, por Salvador Bermúdez de Castro.

**Y dice algo que nos toca de lleno** (§ 309, pp. 363-364):

> El teatro no solía emplear la octavilla aguda sino en números cantables como el himno del drama
> *Baltasar*, II, 4, de la Avellaneda, y el coro de *Saúl*, III, 1, de la misma autora, o en pasajes
> líricos, como la carta de don Juan a doña Inés en *Don Juan Tenorio*, III, 3, de Zorrilla.

Una afirmación sobre esta forma **en el teatro**, en una base de datos de verso dramático, de la
única de las seis fuentes que no tiene voz en esa ficha.

**Y contradice a la fuente que sí la tiene.** Nuestra afirmación de Quilis recoge que la llama
«octava italiana u octava aguda». Navarro objeta al nombre en su propio índice: «El calificativo de
italianas que suele darse a la octava y octavilla agudas no las distingue de la octava real, también
de origen italiano».

### 2, 3 y 4 · Verso aislado · Quilis 1969, Caparrós 2014 y Jauralde 2020

El verso aislado es uno de los dos **tramos sin forma**, y tiene hoy **una sola** afirmación, la de
Navarro. Las otras tres fuentes lo tratan, y dos de ellas **con nuestro mismo término**.

**Quilis, § 5.0**, abre con él el capítulo de la estrofa:

> Un verso aislado no es realmente nada, ni siquiera un verso: es una sentencia o un enunciado de
> cualquier tipo. Para que un verso pueda ser considerado como tal, tiene que estar con otro u otros
> versos, en función de una unidad superior a ellos mismos que llamamos estrofa.

Es la respuesta directa a la duda que nuestra propia definición plantea —«que un verso solo sea
verso es discutible, porque le falta la repetición en que descansa el ritmo»— y viene de quien no
tiene voz en esa ficha.

**Caparrós 2014** lo trata como problema declarado, con nota bibliográfica propia (n. 17, remite a
D. Devoto) y recoge la fórmula de Navarro: «el verso único es para Navarro Tomás "como un embrión
de…"».

**Jauralde 2020** es el más cercano a lo que el catálogo hace:

> el verso único puede funcionar como estrofa y como poema, en cada caso, porque se relaciona *in
> absentia* con versos semejantes. La mayoría de las veces, con todo, el verso único pertenece al
> género prepoético de los motes, emblemas, refranes, sentencias, pie de glosa, estribillo, etc.

**Esto cierra por su cuenta la discusión del 16 de septiembre.** Se sacó el mote de la definición
del verso aislado porque el trabajo de modelo lo hace la definición o lo hace una forma, y se dejó
el caso funcional —«los proverbios, refranes y sentencias que el diálogo intercala»—. La frase de
Jauralde enumera ese mismo conjunto, el mote incluido, y lo hace desde una fuente: que es
justamente donde se dijo que el mote debía vivir.

### 5 y 6 · Cuarteto-lira · Jauralde 2020 y Caparrós 2014

**Jauralde** lo trata en cuatro sitios, y uno habla de nuestro corpus: «Particularmente efectivos
fueron sus quiebros para amoldarse a **los diálogos teatrales**…; hasta Campoamor los empleó».
Documenta además su ascendencia —fray Luis, Medrano, la estrofa sáfica, la alcaica— y su uso en
Juan Ramón, Gerardo Diego, Guillén y Lorca.

**Caparrós 2014** le da una frase de definición encuadrándolo: «El cuarteto lira, una de las
estrofas de la canción alirada, combina heptasílabos y…».

### 7 · Sextina (la composición) · Jauralde 2020 — y los dos epígrafes cambiados

Jauralde anuncia que dará «espacio aparte a las variedades históricamente más importantes, como son
**la sextina**, la endecha real, la copla de pie quebrado». Y lo hace. Pero **bajo el epígrafe
equivocado**, comprobado en el epub, donde los niveles de encabezado se conservan:

- `h3` **«Sextina real»** define el sexteto endecasilábico `ABABCC` con pareado final, que es lo que
  todo el mundo llama *sexta rima*.
- `h3` **«Sexta rima»** define, citando a Domínguez Caparrós, el «poema de treinta y nueve
  endecasílabos, dividido en seis estrofas de seis versos y un remate de tres versos», que es la
  sextina.

Los dos nombres están intercambiados respecto del uso corriente. **Quien consulte a Jauralde sobre
la sextina desde nuestra ficha aterrizará en la estrofa que no es**, y eso es exactamente lo que una
afirmación de fuente tiene que avisar. Nuestra otra ficha —la sextina como estrofa— ya registra la
mitad del enredo: dice que su «sextina real» es la sexta rima. Falta la otra mitad.

### 8 · Novena-lira · Navarro Tomás 1972 — la forma sin ninguna fuente

De las 43 unidades, **dos no tienen ni una sola afirmación**, y esta es la que no debía estar ahí.
El contador da cero menciones porque «Novena-lira» es nuestro nombre y no el de nadie: Navarro
describe la estrofa sin bautizarla. En el **§ 161, «Estrofas aliradas»**, al enumerar los
desarrollos del tipo métrico más allá del sexteto, llega a nueve versos y da dos esquemas con autor
y obra:

- `abCabCcdD`, de Francisco de Figueroa, en su imitación de la oda horaciana *Oh, navis*;
- `AbCAbCcdD`, la misma bajo otra forma, en la poesía 120 de Góngora.

**Es la prueba de que el cero del contador no significa silencio**, sino que el catálogo y el libro
no usan el mismo nombre. Y deja a la vista un segundo asunto: nuestra novena-lira no registra
ningún esquema de rima —su arquitectura dice «distribución variable»— teniendo dos documentados.

### 9 · Décima-lira · *Diccionario* 2016 — la otra forma sin ninguna fuente

Entrada propia: **«décima-estancia (Navarro Tomás). Combinación estrófica de diez versos,
heptasílabos y endecasílabos, rimados en consonante»**, con ejemplo.

Pero la entrada continúa: **«Ni el número de endecasílabos y heptasílabos, ni el orden de las rimas
están preestablecidos»**, y nuestra décima-lira registra un esquema fijo, `ababcdcdee`, con el
nombre «Décima-estancia · aBaBcDcDeE». La fuente de la que tomamos el nombre dice que no hay esquema
fijo. **Eso no es una laguna sino una cuestión de catálogo**, y va abajo.

### 10 · Versificación irregular · Quilis 1969

De los dos tramos sin forma, este tiene afirmación de las otras cinco fuentes. Quilis, que es quien
la define con más limpieza, no tiene ninguna. **§ 3.0**:

> A la versificación regular o silábica se contrapone la versificación irregular o libre, en la que
> el número de sílabas es totalmente indeterminado, pero que puede manifestarse bajo un cierto ritmo
> acentual (versificación rítmica) o bajo agrupaciones periódicas de ciertos grupos fónicos
> (versificación periódica).

---

## Los tres falsos positivos

Las tres celdas vacías de **Sextina (`sextina_estrofa`)** en Navarro, Caparrós 2014 y el
*Diccionario*, con 14, 23 y 25 menciones. El contador suma «sextina» sin poder saber de cuál de las
dos habla, y en esos tres libros habla de la composición, que **sí** tiene su afirmación. Los tres
tratan la sextina como composición y no aíslan la estrofa de seis: el único que lo hace es Quilis,
§ 5.4.5.1, y por eso es la única afirmación que esa ficha tiene junto a la de Jauralde.

## Los veinte silencios justificados

**Morley y Bruerton, 1968, explica seis de ellos.** No es un manual de métrica sino el repertorio de
las formas que Lope usa, y lo que tenemos es una copia del capítulo V. No trata la serie alirada
—cuarteto-lira, octava-lira, novena-lira, décima-lira—, ni la octava aguda, que es posterior a Lope,
ni la endecha real, ni el verso aislado, ni la sextina como estrofa suelta.

**La serie alirada explica los catorce restantes**, y por una razón de fondo: es una
**sistematización nuestra**. El catálogo la completó el 24 de agosto de 2026 al ver que faltaban
cuatro eslabones de una serie que las fuentes tratan por casos sueltos y no como serie. Que Quilis
no tenga una entrada de «octava-lira» no es un olvido suyo: es que solo Navarro recorre el tipo
métrico entero. **Ese silencio hay que registrarlo como tal**, no dejar la celda en blanco, porque
la ficha pública enseña hoy seis fuentes y el lector no puede distinguir entre «no lo dice» y «no lo
hemos mirado».

---

## Lo que sale de aquí y no es una afirmación

Tres cosas que la fase destapa y que no se arreglan escribiendo una fuente.

**1 · Dos formas del catálogo se llaman igual.** `sextina` —la composición de 39 endecasílabos— y
`sextina_estrofa` —la estrofa de seis—. Se distinguen por su slug, no por su nombre, así que en el
catálogo público hay **dos fichas tituladas «Sextina»** y nada en el título las separa. Es la misma
ambigüedad que en Jauralde nos costó un epígrafe.

**2 · La novena-lira no registra los esquemas que su fuente le da.** Navarro documenta `abCabCcdD` y
`AbCAbCcdD`; la arquitectura dice «distribución variable».

**3 · La décima-lira registra un esquema fijo que su fuente niega.** Nuestro `ababcdcdee` frente al
«ni el número… ni el orden de las rimas están preestablecidos» del *Diccionario*. Además, el
*Diccionario* atribuye el término «décima-estancia» a Navarro Tomás y **ese término no aparece en el
libro de Navarro**: ni en su texto ni en su «Índice de estrofas», donde la única entrada «Décima» es
la de los diez octosílabos.

## El límite del método, dicho por sus dos fallos

El contador de menciones falló dos veces en esta misma fase, y las dos hacia el mismo lado:

- **«cuarteto lira» sin guion no contaba como «Cuarteto-lira»**, y la celda de Caparrós 2014 salía a
  cero teniendo el epígrafe delante. Arreglado: el guion se trata como espacio.
- **«Novena-lira» no aparece en ningún libro** porque es nuestro nombre para algo que Navarro
  describe sin bautizar. Eso no tiene arreglo mecánico.

De ahí que el recuento sea una pista para ordenar el trabajo y **nunca un veredicto**: las 33 celdas
vacías se abrieron una a una.

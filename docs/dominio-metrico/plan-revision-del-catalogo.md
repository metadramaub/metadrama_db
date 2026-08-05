# Plan de revisión del catálogo

Estado: **preparado, no empezado** · 5 de agosto de 2026

Qué queda por hacer sobre el catálogo métrico, en qué orden y por qué ese orden. Se escribe
antes de empezar para que la sesión que lo retome no tenga que reconstruir el razonamiento.

## El orden importa, y es este

**A · Normalizar nombres. B/C · Definiciones y fuentes. D · Auditar lo que falta.**

La normalización va **primero** por una razón concreta: las definiciones mencionan nombres de
arquitecturas. Si se reescriben las definiciones y luego se renombra, quedan mencionando
nombres que ya no existen. Al revés no pasa nada.

D va al final porque, si se revisan las definiciones forma por forma, las anomalías de
secciones, repeticiones y rasgos aparecen solas por el camino. Hacerlo antes sería recorrer
el catálogo dos veces.

---

## A · Normalizar nombres — **hecho el 5 de agosto de 2026**

Auditadas las 110 entidades con nombre y slug: arquitecturas, esquemas métricos y variedades.
Salieron cuatro cosas y las cuatro están aplicadas.

| Qué | Cuántas |
| --- | ---: |
| Slugs de variedad con mayúsculas (sexteto-lira) | 7 |
| Nombres con el adjetivo en masculino | 4 |
| Slugs con el adjetivo en masculino | 8 |
| Nombres que repetían el de su forma | 1 |
| Arquitecturas del romance nombradas en sustantivo | 4 |

**El criterio del género**: el adjetivo concuerda con «arquitectura», que es lo que el nombre
califica, no con la forma. Lo prueba que el cuarteto y el sexteto, formas masculinas, ya se
nombraban «Endecasilábica». Eran dieciocho en femenino contra cuatro en masculino.

**Lo del romance admite discusión y se aplicó igualmente**: «romance octosílabo» es como lo
dice la tradición, pero su slug ya usaba el adjetivo y las otras cuarenta y cinco
arquitecturas también. Si se prefiere el sustantivo, revertir esas cuatro filas no afecta a
nada más.

### La caja de la notación de rima

Mayúscula arte mayor, minúscula arte menor. No es decoración: `aA` son un heptasílabo y un
endecasílabo que riman, y escribirlo `AA` pierde la mitad. Comprobado contra la medida de
cada posición, había **once posiciones con la caja contraria a su verso**:

- **Canción petrarquista**, `ABCABC:CDEEDFF` sobre 7-7-11-7-7-11-7-7-7-7-11-7-13. Nueve
  posiciones heptasílabas en mayúscula. Lo correcto es `abCabC:cdeeDfF`, que es exactamente
  lo que decía el término legado, `cancion_regular_abCabC_cdeeDfF`: la caja se perdió al
  normalizar en algún momento.
- **Endecha real**, `-a-a` sobre 7-7-7-11 → `-a-A`.
- **Romance endecasílabo**, el heroico, `[-a]…` → `[-A]…`. Sus tres hermanos son arte menor.

**Y por eso los slugs pueden llevar mayúsculas.** Bajar a minúsculas los de las variedades
del sexteto-lira dejó `a1_ababcc`, `a2_ababcc` y `a3_ababcc` **idénticos**: la caja era lo
único que separaba `aBaBcC` de `AbaBcC` y de `abaBcC`. La regla de minúsculas vale para el
texto descriptivo; una notación de rima conserva su caja.

**Dónde se comprueba y dónde no.** Solo puede comprobarse si la arquitectura tiene un único
esquema métrico. El sexteto-lira tiene cinco —M1 a M5— y tres de rima, y la rima es
independiente del metro: la caja no se decide hasta combinarlos en una variedad. Ahí sí se
comprueba, y sus siete variedades cuadran.

**Lo que enseñó hacerlo**: la auditoría del día anterior dio un resultado falso porque el
acento de `sílabo` cae en la *i* y el de `silábica` en la *a*, y una expresión regular escrita
para uno no encuentra el otro. Las tuberías de consola corrompen los acentos: hay que volcar
a fichero y leerlo con codificación explícita. Y una comprobación mal acotada da falsos
positivos: la primera versión de la guarda encontró 39 errores cruzando los cinco metros del
sexteto-lira contra sus tres rimas.

### Y la caja cuando la medida no se fija verso a verso

La primera comprobación solo alcanzaba a las arquitecturas que declaran una medida por
posición. Las que declaran un **conjunto** de medidas admisibles quedaban fuera, y ahí había
dos notaciones que afirmaban un arte que la medida no sostiene.

La regla que faltaba: **si todas las medidas admisibles comparten arte, se usa el suyo; si lo
cruzan, el arte no está determinado y se escribe en minúscula**, que es la forma no marcada.
No es una invención: el pareado ya lo hacía así, con medidas de cuatro a catorce sílabas y
notación `aa`.

- **Zéjel**, hexasílabo u octosílabo, o sea arte menor, escribía `A(A) | [BBBA]…`. Su hermano
  el villancico, con las mismas medidas, ya escribía `abba` y `abab`.
- **Canción sin rima**, pareado final. Escribía `AA` sobre una arquitectura de siete y once
  sílabas, afirmando dos endecasílabos sin que nada lo sostuviera. Ni la definición del
  proyecto ni Morley y Bruerton fijan esa medida, y el pareado final de la canción regular es
  `fF` —siete más once—, así que el `AA` venía de llamarlos «pareados consonantes» y no de la
  medida. Queda `aa`.

Con eso el catálogo no afirma en ninguna notación un arte que su medida no sostenga, y la
comprobación queda en la migración para que no vuelva a colarse.

### El estado anterior, para referencia

La convención ya está fijada en
[la revisión de nomenclatura](./historico/revision-nomenclatura.md): **adjetivo en `-ico`**
para las arquitecturas, slug en minúsculas sin tildes, y el nombre no repite el de la forma
—«Octosilábica», no «Redondilla octosilábica»—.

Lo que hace falta es comprobar que se cumple. Auditado por encima el 5 de agosto sobre el
catálogo en vivo, salen al menos dos cosas:

### A.1 · El romance nombra en sustantivo

| slug | nombre actual | debería ser |
| --- | --- | --- |
| `octosilabico` | Octosílabo | Octosilábica |
| `hexasilabico` | Hexasílabo | Hexasilábica |
| `heptasilabico` | Heptasílabo | Heptasilábica |
| `endecasilabico` | Endecasílabo | Endecasilábica |

El slug ya usa el adjetivo; el nombre se quedó en el sustantivo. Las cuatro.

**Antes de cambiarlo, decidir**: en una serie el sustantivo se lee bien —«romance
octosílabo» es lo que dice la tradición—, así que puede que la excepción esté justificada. Si
lo está, se escribe como excepción; si no, se normaliza.

### A.2 · Una arquitectura repite el nombre de su forma

`terceto_encadenado` · «Terceto encadenado octosilábico consonante» → «Octosilábico
consonante». Es justo lo que la convención prohíbe, y su hermana endecasilábica ya lo hace
bien.

### A.3 · Concordancia de género

Conviven «Octosilábica» y «Endecasilábico». El femenino concuerda con «arquitectura» y es
mayoría; el masculino, con «verso». Hay que elegir uno y aplicarlo.

### A.4 · Lo que falta auditar

La auditoría del 5 de agosto fue parcial: el filtro por acentos en la consulta no se comportó
como esperaba y no cubrió todas las arquitecturas. **Rehacerla entera**, y extenderla a
esquemas métricos, esquemas de rima y variedades, que la revisión de nomenclatura también
cubría.

Cómo hacerla bien: consultar el catálogo en vivo y volcar a fichero antes de procesar, porque
las tuberías de la consola corrompen los acentos y llevan a conclusiones falsas.

---

## B/C · Definiciones y fuentes, forma por forma

B y C se hacen **juntos**: auditar dónde vive cada prosa por separado obligaría a recorrer el
catálogo dos veces, y las dos preguntas se responden mirando la misma forma.

### La política, ya acordada

> La **definición** es la apuesta del proyecto. Se afirma lo que la forma es, en tercera
> persona, **sin «nuestro catálogo» ni «el proyecto reconoce»**, y sin mencionar el
> registrador ni el demarcador: son herramientas y aquí dan igual.
>
> Las **fuentes** entran cuando un especialista dice algo distinto, o afina un punto que la
> definición no puede llevar sin volverse farragosa.

Evitar el «nosotros» tiene una consecuencia buena: obliga a que la frase diga algo del verso
y no del catálogo. La definición de la quintilla, hoy, dice «las ocho distribuciones
reconocidas se registran como patrones alternativos de esta configuración» — eso habla del
registro, no de la quintilla.

### Dónde va cada cosa

| | |
| --- | --- |
| `formas_metricas.definicion` | Qué **es** la forma |
| `arquitecturas_forma.descripcion` | Cómo se realiza **esa** arquitectura |
| `estructuras_secciones.nota`, `arquitectura_rasgos.nota` | Precisión sobre una parte o un rasgo |
| `afirmaciones_fuentes_metricas` | Lo que **una fuente** dice, con localizador y confianza |

Lo que hay que cazar está en [dónde vive la prosa](./donde-vive-la-prosa.md): definiciones que
son decisiones, descripciones que repiten la definición, y el porqué que hoy solo vive en
`revisiones-formas/`.

### Las fuentes, ya convertidas a texto

En `bibliografía/txt/`, fuera de git porque el directorio está ignorado:

| Fuente | Tamaño |
| --- | --- |
| Navarro Tomás 1972 · *Métrica española* | 1,4 MB |
| Domínguez Caparrós 1999 · *Diccionario de métrica española* | 892 KB |
| Jauralde Pou 2020 · *Métrica española* | 860 KB |
| Domínguez Caparrós 2014 · *Métrica española* | 648 KB |
| Quilis 1969 · *Métrica española* | 320 KB |
| Morley y Bruerton · definiciones (ya en `.md`) | — |

Si faltan, se regeneran con `pdftotext -layout -enc UTF-8`. El epub de Jauralde se extrajo
descomprimiéndolo y limpiando etiquetas.

**Aviso**: `metrica-clasificacion.pdf` no es un manual de definiciones sino un artículo sobre
repertorios métricos. No sirve para esto.

**Y una advertencia de método**: Morley y Bruerton describen **a Lope**, no el Siglo de Oro
entero. El catálogo es deliberadamente más amplio en varios puntos —la redondilla cruzada, la
copla real—. Esa diferencia es información que merece registrarse como tal, no un desacuerdo
que haya que ocultar ni una corrección que haya que aplicar.

### Por dónde empezar

Por lo que más pesa en el corpus, que es donde un error costaría más caro:

| Forma | Secuencias |
| --- | ---: |
| Romance | 71 |
| Redondilla | 63 |
| Décima | 18 |
| Silva | 12 |
| Soneto | 7 |

---

## D · Auditar lo que queda

Con el método que el 5 de agosto encontró cinco errores en medidas y rimas: **consultar el
catálogo en vivo, comparar cómo se codifica el mismo fenómeno en formas distintas, y
sospechar de todo lo que aparezca a medias.**

Sin auditar todavía:

- **secciones** (`estructuras_secciones`): extensiones, repeticiones, qué reutiliza cada una
- **repeticiones** (`repeticiones_metricas`, `repeticion_posiciones`)
- **rasgos** (`arquitectura_rasgos`, `rasgos_metricos`, `rasgo_valores`)
- **variedades** (`variedades_arquitectura`)

Lo que la experiencia de hoy enseña sobre dónde mirar:

1. **Lo que declaran unas formas y otras no.** Es el patrón que destapó los tres errores del
   día: `grupo_repeticion` en 5 de 31, el enlace de asonancia en 1 de 4 romances, la copla
   real sin esquema métrico. Casi siempre el origen es que migraciones escritas en sesiones
   distintas decidieron por separado.
2. **El mismo fenómeno codificado de dos maneras.** El quebrado de la sextilla declaraba
   cuatro y cinco sílabas; el de la copla real, solo cuatro.
3. **Lo que se escribe a mano y podría derivarse.** Las etiquetas de las opciones de rima
   divergieron porque se escribían; ahora se derivan del esquema.

**Y una regla que vale para todo:** no fiarse de las migraciones para saber qué hay. Consultar
siempre el catálogo en vivo y leer el esquema de las tablas antes de sacar conclusiones: se
codifican muchos datos y las migraciones solo cuentan lo que pasó aquel día.

---

## Lo que cada cambio puede romper

Cualquier cosa que toque el catálogo alcanza a cinco sitios. Comprobarlos antes de dar nada
por bueno:

| | Cómo se comprueba |
| --- | --- |
| **Catálogo público** `/formas` | Se genera del dato: cambia solo |
| **Demarcador** | Se compila del catálogo; subir `catalogo_metrico_estado.revision` lo marca desactualizado |
| **Editor V2** | Lee nombres de opciones y esquemas: un renombrado se ve ahí |
| **Equivalencias** | `select via, count(*) from propuesta_metrica_secuencia group by via` — deben seguir siendo 212 |
| **Respuestas propuestas** | `select count(*) from propuesta_elecciones_secuencia` — deben seguir siendo 91 |

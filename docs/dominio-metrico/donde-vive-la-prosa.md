# Dónde vive la prosa del catálogo

Estado: **abierto, a auditar** · 4 de agosto de 2026

El catálogo de formas de la web se genera del dato, así que todo lo que se lee ahí sale de
algún campo de texto del catálogo. Al construirlo aparece que **el mismo tipo de información
puede vivir hoy en tres sitios distintos**, y eso adelanta que habrá duplicaciones y cosas
en el sitio que no les toca.

Se anota aquí para auditarlo con calma. No se toca nada todavía: faltan fuentes por sumar y
conviene mirar el catálogo entero de una vez, no campo a campo.

## Los tres sitios

| Campo | Dónde | Qué debería decir |
| --- | --- | --- |
| `definicion` | `formas_metricas` | Qué **es** la forma. La frase que define, no lo que el proyecto decidió sobre ella |
| `descripcion` | `arquitecturas_forma`, `variedades_arquitectura`, `esquemas_*` | Cómo se realiza **esa** arquitectura o variedad en concreto |
| `nota` | `estructuras_secciones`, `arquitectura_rasgos` | Precisión sobre una parte o un rasgo: por qué está, qué la limita |

Y un cuarto, que no es prosa libre sino afirmación con respaldo:

| `afirmaciones_fuentes_metricas` | Lo que **una fuente concreta** dice, con su localizador y su grado de confianza |

## Lo que hay hoy

Medido el 4 de agosto: 28 formas, todas con definición; 49 arquitecturas, todas con
descripción; 23 denominaciones; 39 afirmaciones sobre 11 fuentes.

Es decir, la cobertura es buena. Lo que falta comprobar es si cada cosa está en el sitio
que le toca.

## Lo que hay que mirar cuando se audite

1. **Definiciones que en realidad son decisiones del proyecto.** «El catálogo reconoce
   realizaciones de seis, siete y ocho sílabas» es una decisión, no una definición de la
   redondilla. Probablemente pertenezca a la descripción de cada arquitectura, o a una
   afirmación con fuente.
2. **Descripciones que repiten la definición** de su forma, palabra por palabra o casi.
3. **Razonamientos que hoy solo están en las fichas de `revisiones-formas/`** y no en el
   dato: por qué `aabaa` no está en el repertorio de la quintilla, por qué la hexasílaba se
   corrigió de siete a seis, por qué «Silva libre» sigue siendo arquitectura pese a
   compartir esquemas con la irregular. Si merecen sobrevivir, su sitio es el catálogo.
4. **Lo que dicen las fuentes frente a lo que decidió el proyecto.** Son cosas distintas y
   conviene que se lean como distintas. Morley y Bruerton describen a Lope; el catálogo
   cubre el Siglo de Oro y algo más, y en varios puntos es deliberadamente más amplio —la
   redondilla cruzada, la copla real—. Esa diferencia es información, no un desacuerdo que
   haya que ocultar.
5. **Fuentes que faltan por sumar.** Con once fuentes registradas, buena parte del criterio
   del proyecto todavía no tiene respaldo declarado.

## Por qué esperar

Auditar esto exige leer el catálogo entero con la web delante, que es justo para lo que se
ha hecho la página. Hacerlo antes sería adivinar; hacerlo campo a campo, perder el conjunto.

Cuando se haga, el destino natural de las fichas de `revisiones-formas/` es desaparecer: lo
descriptivo pasa al catálogo y se lee en la web, y lo que quede abierto vive en
[cuestiones para el IP](./revisiones-formas/cuestiones-para-el-ip.md). Hasta entonces las
fichas siguen siendo el único sitio donde está el porqué.

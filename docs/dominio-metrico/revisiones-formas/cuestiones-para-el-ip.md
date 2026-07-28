# Cuestiones para confirmar con el IP

Fecha de apertura: 28 de julio de 2026

Este documento reúne únicamente decisiones filológicas o de alcance del corpus que no
deben resolverse mediante inferencia técnica. Las cuestiones se incorporan durante la
revisión forma por forma. Cuando una respuesta quede acordada, se trasladará al documento
de revisión de la forma y se marcará aquí como resuelta.

## Quintilla

Estado de la definición: se conserva sin cambios hasta discutirla con el IP.

### Pendiente

1. ¿Los ocho esquemas enumerados constituyen un repertorio cerrado para el corpus o solo
   los casos reconocidos hasta ahora?
2. ¿Por qué no se incluye `aabaa`, que cumple la regla declarada de no presentar más de
   dos versos consecutivos con la misma rima?
3. ¿Deben `abbaa` y `ababb`, que terminan en pareado, considerarse tipologías ordinarias
   de la quintilla en METADRAMA?
4. ¿Debe la futura definición pública explicar expresamente que la clasificación del
   proyecto difiere de la definición normativa moderna y no pretende agotar todas las
   combinaciones teóricas?

### Contraste bibliográfico

José Domínguez Caparrós, *Métrica española* (UNED, 2014, p. 195), define la
quintilla normativa mediante cinco versos de arte menor, dos rimas consonantes, ausencia
de versos sueltos, un máximo de dos versos consecutivos con la misma rima y prohibición
del pareado final. Este contraste no sustituye el criterio especializado del proyecto.

## Terceto encadenado

### Resuelto en el proyecto

1. El cierre actualmente reconocido es `YZYZ`.
2. `YZYZ` se describe como un serventesio: los cuatro versos finales presentan rima
   consonante alterna. Dentro de la cadena también puede analizarse como el último terceto
   `YZY` más el verso `Z` que resuelve la rima pendiente.
3. El cierre alternativo `VYVYZZ` mencionado por Domínguez Caparrós no se incorporará
   mientras no aparezca en el corpus y el proyecto decida reconocerlo.
4. El catálogo debe permitir añadir otros cierres cuando estén documentados en el corpus.
5. La forma completa es una serie de extensión abierta; el valor `3` pertenece a la unidad
   repetida, no al total.
6. La rima canónica es consonante y sigue el encadenamiento
   `ABA | BCB | CDC | … | YZYZ`.
7. `terceto` y `terceto_encadenado` son formas distintas porque pertenecen a niveles
   estructurales diferentes. Se agrupan en la familia `tercetos` y se vinculan mediante
   una relación `relacionada_con`, no mediante una jerarquía de subtipos.

### Pendiente

1. ¿El `terceto_octosilabo` conserva siempre el encadenamiento entre unidades? Si es así,
   se modelará como configuración octosilábica de `terceto_encadenado`; si posee identidad
   histórica autónoma, deberá reconsiderarse como forma.
2. La definición heredada menciona excepcionalmente «un verso sin rima». ¿Es una
   realización admitida de la forma o una desviación que debe registrarse en la secuencia?
3. La definición heredada menciona la repetición de un mismo sonido de rima en cuatro
   ocasiones. ¿Es una variante admitida o una desviación?
4. ¿Qué número mínimo de unidades exige el proyecto para identificar una serie como
   terceto encadenado?
5. ¿Los cierres en pareado o cuarteto mencionados en las definiciones heredadas de las
   series sin encadenar son alternativas estructurales canónicas o realizaciones
   documentadas que deben registrarse como desviaciones?

### Organización adoptada

Crear la familia estructural `tercetos`:

- `terceto`: forma de nivel estrofa y tres versos;
- `terceto_encadenado`: forma de nivel serie compuesta por unidades de tres versos;
- `tercetos_sin_encadenar`: forma de nivel serie, con los patrones normalizados
  `A-A | B-B | C-C | …` y `-AA | -BB | -CC | …`;
- `terceto_octosilabo`: configuración de `terceto_encadenado`, mientras no se confirme
  que constituye una forma autónoma.

Las configuraciones no son miembros directos de una familia: la configuración octosilábica
queda incluida indirectamente a través de `terceto_encadenado`. `terceto_de_esdrujulos`
se modelará como aplicación de un rasgo normalizado y no como forma independiente.

### Contraste bibliográfico

José Domínguez Caparrós, *Métrica española* (UNED, 2014, p. 185), describe el
terceto como combinación de tres versos de arte mayor, normalmente endecasílabos, con
rima consonante, y presenta como disposición más frecuente el terceto encadenado.
Registra los cierres `…YZYZ` y `…VYVYZZ`; METADRAMA adopta por ahora únicamente el
primero.

## Silva

### Resuelto en el proyecto

1. `silva` se conserva como una única forma de nivel serie.
2. `silva_de_consonantes_regular`, `silva_de_consonantes_irregular`, `silva_libre` y
   `silva_de_endecasilabos` se convierten en configuraciones coordinadas.
3. Se conservan los nombres establecidos por el IP.
4. Los porcentajes 50-98 % y 99-100 % se eliminan y se sustituyen por descripciones
   cualitativas.
5. En la silva de consonantes regular, los versos sueltos se registran como desviaciones
   respecto de la norma de pareados `7 + 11`.

### Pendiente

1. Confirmar si `silva libre` se usa deliberadamente con el alcance específico del corpus
   —heptasílabos y endecasílabos, rima consonante libre y ausencia normativa de
   pareados— o si se pretendía hacerla coincidir con la categoría moderna, más amplia en
   metros y generalmente sin rima.

### Contraste bibliográfico

José Domínguez Caparrós, *Métrica española* (UNED, 2014, pp. 227-228), define la
silva general como serie no estrófica de endecasílabos, o endecasílabos y heptasílabos,
con rima consonante libremente dispuesta y posibles versos sueltos.

Isabel Paraíso, «Arcadio Pardo y la Teoría Métrica», *Rhythmica*, 20-21
(2023; publicado en 2024), pp. 137-150, documenta otro alcance de `silva libre`, propio
de la versificación moderna.

## Series endecasilábicas

### Resuelto en el proyecto

1. Los porcentajes 50 %, 98 % y 99-100 % no se usarán como fronteras ontológicas ni se
   pedirán al editor.
2. `endecasilabo_suelto` se reconoce cuando predominan los versos sin rima.
3. En la silva de endecasílabos predominan los versos rimados y los pareados pueden ser
   habituales, pero no organizan sistemáticamente toda la serie.
4. La antigua entrada `pareado_endecasilabo` describe una serie de dísticos y se convierte
   en la forma de nivel serie `pareados_endecasilabos`.
5. `pareado` permanece como forma de nivel estrofa. Ambas formas se reúnen en la familia
   `pareados`, sin relación de subtipo.
6. El demarcador expresa la frontera mediante dos preguntas cualitativas: predominio de
   versos rimados y organización sistemática en pareados.

### Pendiente

No quedan decisiones imprescindibles para construir esta parte del catálogo. El IP podrá
corregir las definiciones o el alcance de las cinco configuraciones de endecasílabo
suelto directamente en el dashboard.

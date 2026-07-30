# Hacia un dominio métrico propio en METADRAMA

El punto de partida de esta propuesta es un problema que se hizo visible al
intentar construir el demarcador de formas estróficas. El vocabulario actual
contiene mucha información valiosa, pero reúne bajo una misma jerarquía
realidades de naturaleza distinta. En ella conviven formas métricas propiamente
dichas, variantes de una forma, patrones de rima, denominaciones históricas,
tradiciones nacionales y rasgos que pueden aparecer en muchas formas. Esta
mezcla no solo dificulta decidir qué debe considerarse padre o hijo: también
obliga al demarcador a comparar elementos que no se encuentran en el mismo
nivel y complica los filtros y análisis posteriores.

Por eso, la propuesta no consiste simplemente en añadir más campos al
vocabulario existente, sino en reconocer que la métrica necesita un dominio
propio. En ese dominio, una forma —por ejemplo, el romance, el soneto o la
copla real— se describe mediante una arquitectura normativa: cuántos versos
tiene, qué medidas admite, cómo se organiza internamente, qué tipo de rima
emplea y qué relaciones se establecen entre sus versos o entre sus estrofas.
Junto a esa norma pueden registrarse arquitecturas alternativas, variantes
históricas, nombres equivalentes, tradiciones y fuentes bibliográficas. De este
modo, cada dato ocupa un lugar preciso y deja de ser necesario crear una nueva
«subforma» cada vez que cambia un único rasgo.

Esta separación permite distinguir mejor varios conceptos que hasta ahora
aparecían mezclados. Una tradición, como la italiana o la española, indica un
contexto histórico de procedencia, pero no convierte automáticamente una forma
en hija de otra. Un esquema de rima describe una organización, mientras que un
rasgo como el pie quebrado, el verso agudo o la asonancia en unas vocales
determinadas puede formar parte de distintas arquitecturas. Algunas formas,
además, exigen representar relaciones más complejas: versos compuestos con
hemistiquios, rimas que enlazan una estrofa con la siguiente o restricciones
que permiten varios esquemas válidos sin reducirlos a una única cadena fija.

El catálogo describe también qué decisiones debe tomar el editor en cada caso.
Algunas formas quedan resueltas con su sola selección; otras permiten escoger
una arquitectura, un esquema, una sección o una repetición entre posibilidades
previamente admitidas. Estas elecciones no son irregularidades: describen la
realización concreta y se guardan porque tienen valor para filtrar y analizar
el corpus. La interfaz solo muestra las preguntas aplicables a la forma elegida.

La riqueza del modelo no implica, sin embargo, que el editor tenga que rellenar
muchos más datos al describir una secuencia. La complejidad se concentra en el
catálogo de formas, que se prepara y revisa previamente. Cuando el editor
selecciona una forma, el sistema ya conoce su comportamiento normal. Su tarea
consiste ante todo en indicar dónde la secuencia concreta se aparta de esa
norma. Si una copla que debería tener versos octosílabos presenta uno de siete
sílabas, se registra esa diferencia y su extensión; si la rima se incumple en
un tramo, se señala la desviación sin obligar a inventar una nueva rima cuando
el texto no se transcribe. También pueden anotarse alteraciones estructurales o
rasgos especialmente relevantes. Si no se consigna ninguna diferencia, se
entiende que la secuencia cumple la arquitectura seleccionada. No se añaden
campos de certeza, revisión o pendiente: la secuencia se guarda completa y lo
no señalado se considera conforme a la norma.

Este planteamiento conserva lo útil del registro actual de irregularidades,
pero lo hace más preciso. Las desviaciones métricas dejan de depender de
descripciones aisladas y reutilizan los mismos conceptos normalizados con los
que se define la forma: medidas, rimas, posiciones, estructuras y rasgos. Las
caracterizaciones por rango que no son estrictamente métricas —por ejemplo,
prosa, canto o laguna— pueden seguir existiendo en su ámbito general. Así se
evita forzar todos los fenómenos dentro de una única tabla y, al mismo tiempo,
se mantiene una interfaz sencilla.

También se distingue entre una forma general, todavía describible, y un tramo del que no
puede afirmarse una forma. Una copla de pie quebrado puede ser general y conservar, no
obstante, una estructura formalizable. En cambio, «Versificación irregular» y
«Verso aislado» no son formas: se utilizan únicamente cuando no puede reconocerse
una identidad del catálogo. La primera abarca dos o más versos; la segunda, un
solo verso que no pertenece a los tramos contiguos. Ambas quedan fuera de las
comparaciones entre formas.

El demarcador se beneficia directamente de esta organización. En lugar de
recorrer una jerarquía rígida de padres e hijos, trabaja con las propiedades
efectivas de cada arquitectura y formula solo preguntas que el editor puede
responder con facilidad. Cada respuesta descarta incompatibilidades y conserva
como indeterminadas las formas sobre las que todavía faltan datos. «No sé»
sigue siendo una respuesta válida durante la búsqueda; no equivale a afirmar
ni a negar un rasgo. Las preguntas pueden ordenarse según su capacidad real
para separar las candidatas restantes, por lo que el recorrido se adapta a
cada caso. La inteligencia principal del sistema procede de datos bien
estructurados y de reglas transparentes. Un pequeño modelo de inteligencia
artificial podría ayudar más adelante a interpretar una descripción libre o
proponer preguntas, pero no debería sustituir ni ocultar este razonamiento.

La base de datos seguirá siendo la fuente de verdad. A partir de ella podrán
generarse automáticamente una versión optimizada para el demarcador, las
fichas públicas y las redes de relaciones entre formas. Estos productos serán
instantáneas regenerables, no copias que haya que mantener manualmente. Esto
permitirá corregir o ampliar el catálogo sin que el demarcador quede
desactualizado y hará posible mostrar gráficamente tradiciones, variantes y
semejanzas sin confundir unas relaciones con otras.

La transformación se está haciendo de forma gradual y reversible, porque las
anotaciones existentes en las obras son datos reales. Ya se ha construido el
nuevo catálogo y se ha establecido para cada término actual si
corresponde a una forma, una arquitectura, un rasgo, una denominación, una tradición
o un concepto que debe conservarse únicamente como histórico. La revisión del
IP y la validación mediante el editor y el demarcador precederán a la futura
migración de las secuencias, manteniendo la referencia de procedencia y
comprobando los casos ambiguos. El resultado será un sistema más fiel a la
teoría métrica, más fácil de usar para los editores y mucho más sólido para la
búsqueda, la comparación y futuros análisis computacionales.

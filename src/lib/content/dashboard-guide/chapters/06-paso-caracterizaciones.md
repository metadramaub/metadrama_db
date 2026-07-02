A veces una secuencia métrica contiene fenómenos internos que no requieren crear una nueva secuencia, pero sí conviene declarar por rango. Eso se hace con las **caracterizaciones por rango**, dentro de la pestaña Secuencias.

> [!IMPORTANT]
> Para poder añadir caracterizaciones por rango (tantas como necesites), debes guardar al menos una vez la secuencia en edición.

## Tipos que contemplamos

- versos cantados;
- versos de medida irregular (hipométricos o hipermétricos);
- rimas defectuosas o diferentes a lo esperado según la tipología estrófica;
- patrones alternativos a lo esperado según la tipología estrófica;
- lagunas textuales;
- prosa dentro de una secuencia métrica;
- tramos con mayoría de agudas o mayoría de esdrújulas.

## Qué incluye cada caracterización

- tipo de caracterización;
- verso inicial y verso final (que puede ser el mismo, si se trata de un solo verso);
- observaciones específicas de esa caracterización (cualquier dato extra que quieras añadir; será público).

Las observaciones de caracterización admiten [Markdown](/dashboard/guia/ref-markdown).

## Reglas importantes

- La caracterización debe quedar **dentro del rango de versos** de su secuencia.
- Los tipos padre (`fenomenos_enunciativos`, `irregularidades_metricas`, `final_acentual`) funcionan como agrupadores y **no se seleccionan directamente**.
- Si existe una secuencia cantada con versificación muy irregular, puedes combinar varias caracterizaciones por rango dentro de la misma secuencia.
- Si una secuencia cantada **parece** una estrofa concreta (por ejemplo, redondilla) pero tiene una versificación muy irregular, **no** elijas "redondilla" como tipo de estrofa: elige "irregular" y, dentro de las caracterizaciones, marca "cantado".
- En `prosa`, `v_ini` y `v_fin` indican el verso **anterior y posterior** a la prosa, pues esta, en realidad, no está numerada.
- En `hipométrico` e `hipermétrico`, `v_ini` y `v_fin` deben ser el **mismo verso**, declarando cada irregularidad de forma individual.
- En tipos como `cantado`, `rima defectuosa`, `laguna`, `mayoria_agudas` o `mayoria_esdrujulas`, puedes marcar un solo verso o un rango.

## Subtipos internos de quintilla

De momento, los subtipos extraordinarios solo se habilitan cuando la estrofa de la secuencia es `quintilla`, y también requieren que la secuencia esté guardada.

En cada subtipo registras:

- subtipo de quintilla (por ejemplo, ababa);
- verso inicial y verso final del subtipo dentro de la secuencia.

> [!IMPORTANT]
> El rango del subtipo debe quedar dentro del rango de su secuencia.

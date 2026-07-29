# Villancico

Estado: revisado, con dudas de alcance · 29 de julio de 2026

## Decisión

Una forma compuesta y una configuración habitual. Cabeza, mudanza, enlace o vuelta y
estribillo son secciones, no subformas. «Enlace» y «vuelta» designan en el proyecto una
misma función, no dos secciones acumulables. La repetición del estribillo se formaliza
aparte de la rima.

## Formalización

| Elemento | Valor |
| --- | --- |
| Forma | `villancico` · compuesta |
| Configuración | `estructura_habitual` |
| Metro | 6 u 8 sílabas, sin orden fijo |
| Cabeza | opcional · 2-4 versos |
| Copla | una o más |
| Mudanza | 4 versos · normalmente `abba` o `abab` |
| Enlace o vuelta | opcional · uno o más versos |
| Estribillo | repetición total, parcial o implícita |

La copla agrupa mudanza, enlace o vuelta y estribillo. Los esquemas `abba` y `abab` son
patrones locales alternativos de la mudanza. La relación de rima que articula el paso de
la mudanza a la cabeza se guarda como una restricción estructurada.

En el editor, la copla actúa como contenedor repetible y no como destino indiferenciado de
sus preguntas. El patrón se responde en la mudanza. La existencia de enlace o vuelta se
registra añadiendo esa única sección, sin un segundo campo booleano. La recuperación del
estribillo sí se responde en la copla: total y parcial materializan versos; implícita no
crea un rango.

## Demarcador

Debe reconocer la combinación de cabeza o estribillo y coplas con mudanza y vuelta. No
necesita pedir al editor que delimite todas las secciones para identificar la forma. La
diferencia con el zéjel se precisará al revisar este último.

## Trazabilidad

El término heredado conserva su identificador. No había secuencias editoriales asociadas
el 29 de julio de 2026. La definición del IP se conserva como criterio: admite casos sin
cabeza explícita y sin versos de enlace o vuelta.

## Fuente

Domínguez Caparrós, *Métrica española* (UNED, 2014), pp. 211-212: cabeza de dos a cuatro
versos, una o más estrofas o pies, dos mudanzas simétricas, vuelta y repetición del
estribillo; uso habitual de octosílabos o hexasílabos. El catálogo no sustituye con esta
terminología la definición del IP.

## Dudas para el IP

1. ¿La mudanza de cuatro versos debe mostrarse como una sola sección o como dos mudanzas
   simétricas de dos versos?
2. ¿La ausencia de cabeza explícita es una realización normativa o una omisión textual?
3. ¿El enlace o vuelta puede tener cualquier extensión igual o superior a un verso?
4. ¿La repetición implícita del estribillo debe contar como sección ausente o como
   repetición sobreentendida?
5. ¿`abba` y `abab` son los únicos esquemas reconocidos para la mudanza o solo los más
   habituales?

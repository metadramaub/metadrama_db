# Soneto

Estado: revisado, con dudas de alcance · 29 de julio de 2026

## Decisión

Una forma, una configuración endecasílaba y cuatro patrones de rima. Los patrones de los
tercetos no son subformas. El soneto de esdrújulos es un rasgo transversal.

## Formalización

| Elemento | Valor |
| --- | --- |
| Forma | `soneto` · composición fija |
| Configuración | `endecasilabo_consonante` |
| Extensión | 14 versos |
| Metro | 11 sílabas |
| Secciones | 2 cuartetos de 4 + 2 tercetos de 3 |
| Cuartetos | `ABBA ABBA` |
| Tercetos reconocidos | `CDCDCD`, `CDECDE`, `CDEDCE`, `CDCEDE` |
| Rasgo admitido | `final_acentual = esdrujulo` |

`CDCDCD` queda provisionalmente como patrón preferente porque el vocabulario heredado lo
llamaba «soneto regular». Los otros tres son alternativas admitidas. La lista no se
declara exhaustiva: la definición del IP dice «entre otras variantes».

## Registrador

La configuración se resuelve automáticamente porque solo hay una. El editor elige
únicamente qué esquema presentan los tercetos; la respuesta referencia el
`patron_rima` completo correspondiente. Los catorce versos, el endecasílabo, la
consonancia, `ABBA ABBA` y la división `4 + 4 + 3 + 3` se derivan de la norma y no se
vuelven a preguntar. El rango solo es válido si contiene un múltiplo de catorce versos.

## Demarcador

Debe identificar el soneto por catorce endecasílabos, rima consonante y arquitectura
`4 + 4 + 3 + 3`. No necesita preguntar por el esquema de los tercetos ni por los finales
esdrújulos para identificar la forma. Esta simplificación del demarcador no elimina la
elección de tercetos del registrador, porque el dato sí es necesario para el análisis.

## Trazabilidad

Los cuatro términos de esquema conservan `origen_termino_id` en `patrones_rima`.
`soneto_de_esdrújulos` conserva su destino en el valor del rasgo. Ninguna de las seis
entradas heredadas tenía usos en secuencias el 29 de julio de 2026.

## Fuente

Domínguez Caparrós, *Métrica española* (UNED, 2014), pp. 218-221: catorce versos de
arte mayor, endecasílabos en la forma clásica, consonancia, ocho versos iniciales
normalmente `ABBA ABBA` y seis finales de distribución variable. También documenta
cuartetos cruzados, estrambote, sonetillo y variantes modernas; no se incorporan sin
decisión del proyecto.

## Dudas para el IP

1. ¿`CDCDCD` debe seguir siendo el patrón preferente o «regular» solo era una etiqueta
   heredada?
2. ¿`ABBA ABBA` es una condición deliberadamente cerrada para el corpus o deben admitirse
   también cuartetos `ABAB ABAB`?
3. ¿Los cuatro esquemas de tercetos son los reconocidos hasta ahora o un repertorio
   cerrado?
4. ¿Soneto con estrambote y sonetillo se incorporarán solo si aparecen en el corpus?

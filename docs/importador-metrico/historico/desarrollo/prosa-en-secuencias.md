# Prosa entre tramos de la misma forma

Criterio acordado el 3 de noviembre de 2026: la prosa no numerada no rompe una secuencia.
Dos filas de la misma forma y jornada separadas por esa prosa generan una única secuencia
con una caracterización enunciativa localizada entre los dos versos contiguos. Su longitud
se calcula exclusivamente con los versos numerados; no se cuantifica la prosa.

## Preparación y procedencia

La IA conserva la fila de prosa con extremos y recuento nulos. El importador identifica
«prosa», «carta en prosa» y «pasaje en prosa» sin convertirlos en formas. Solo une si ambos
tramos tienen una misma forma identificada, pertenecen a la misma jornada y sus rangos son
consecutivos. No une dos filas solo porque sean contiguas, sin prosa intermedia. Admite una
cadena de varios tramos y varias inserciones.

El JSON original se conserva íntegro. En la copia confirmada, `origen.tramos_ref` identifica
todas las filas métricas unidas; `origen.tramo_ref` sigue siendo la referencia principal para
abrir y dividir la secuencia. Las notas enlazadas se conservan. `caracterizaciones` contiene
`termino: prosa`, `v_ini` (verso anterior), `v_fin` (verso posterior), `tramo_ref` y el literal
de la fila original de prosa. Es una caracterización; sus extremos no expresan extensión.
Los campos son opcionales para conservar compatibilidad con las importaciones existentes.

La arquitectura común se mantiene; si las arquitecturas no coinciden, queda sin determinar,
sin trasladar la precisión de un tramo al otro. Rasgos diferentes o un cierre intermedio
requieren revisión antes de unir: no se convierten automáticamente en rasgos globales.
Una fila de prosa con numeración, extremos ilegibles de los tramos o formas sin identificar
tampoco autorizan una unión por conjetura. La preparación muestra el problema para revisar.

## Interfaz y conservación

La tabla indica las filas unidas y muestra «Prosa · Entre vv. …» como dato registrado, fuera
de las notas y de «Añadir datos». El editor muestra la localización. Dividir la secuencia
conserva cada caracterización en la parte que la contiene; un corte que separa sus dos versos
de localización se rechaza con un aviso. La consulta de una copia guardada no reaplica reglas.

La métrica y caracterizaciones básicas se conservan en `metrica_minima_secuencias.datos_minimos`
y en la copia confirmada de `importaciones_metricas`, sin crear anotaciones v2 ni escribir en
las caracterizaciones de una ficha detallada. El ensayo analítico existente mantiene los
fenómenos enunciativos fuera de sus cálculos; no se añade longitud ni porcentaje de prosa.

## Guardado y pruebas

`comprobar_origen_minimo` contrasta cada referencia contra el original, el orden de las filas,
su continuidad, jornada, prosa sin rango y localización exacta. Rechaza referencias inventadas,
caracterizaciones sin origen, omitidas o duplicadas. No permite ampliar el rango por alegar una
procedencia compuesta. Los permisos de importación y de escritura directa siguen vigentes.

Pruebas sintéticas: unión, cadenas, no unión entre jornadas/formas o sin prosa, protección frente
a prosa numerada, conservación al reabrir y dividir, y guardado PostgreSQL de una sola secuencia
sin sumar versos de prosa. El caso de Ursón y Valentín sigue pendiente de una extracción fiel:
no se corrige automáticamente su respuesta defectuosa ni se usa como referencia aceptada.

Verificación del 03-11: 285 pruebas de aplicación, comprobación de tipos sin errores y compilación
correcta. La migración exacta pasó 116 comprobaciones PostgreSQL y se aplicó tras backup completo.
Las importaciones y anotaciones existentes mantienen sus huellas; no se importaron obras reales
de prueba. [Registro de despliegue](../../../despliegues/2026-11-03-prosa-importador.md).

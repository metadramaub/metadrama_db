# Contratos del registrador

**Qué tiene que cumplir el editor al anotar una secuencia**, sea cual sea la forma. Separa tres
cosas: lo que el catálogo **deriva sin preguntar**, lo que el editor **responde** y lo que se
registra como **desviación**.

**Lo que hace cada forma en concreto no se escribe aquí.** Se genera con `npm run audit:editor`, que
recorre el catálogo vivo y da, forma por forma, cuántas preguntas caen una vez, cuántas en cada
unidad y cuánto ahorra el atajo: [informe del editor V2](./informe-editor-v2.md). Hasta el 16 de
septiembre de 2026 esa tabla estaba aquí a mano, y llevaba desde julio sin las formas nuevas: le
faltaban dieciséis de cuarenta y dos.

## Las preguntas salen del catálogo, no del componente

Una forma no está lista para el registrador solo por tener el dato normalizado. El editor no puede
contener reglas filológicas escritas únicamente en el componente: **cada pregunta y cada
posibilidad procede del catálogo**, y si una forma se anota mal, lo que hay que corregir es el
catálogo.

De ahí que un cambio en el catálogo se verifique en la pantalla y no solo en el dato.

## El recorrido mínimo

Anotar una tirada de cuarenta redondillas no puede costar cuarenta respuestas iguales. El patrón,
que vale para toda forma que se repita:

1. El editor responde **la primera unidad**.
2. La aplica **a todas** las que coincidan.
3. **Corrige solo las excepciones.**

Lo que ese atajo no es: **un segundo domicilio de la pregunta**. La respuesta sigue viviendo en cada
realización, una por una; el atajo solo evita teclearla cuarenta veces. Cuando las filas coinciden,
la pantalla las recoge en un resumen y «Cambiar» abre únicamente la excepción.

Y todo lo que la norma fija **no se pregunta**: la décima espinela, la lira o la seguidilla se
anotan eligiendo la forma y guardando, porque no queda nada que decidir.

## Criterio de las desviaciones

Una opción admitida **nunca** se registra como desviación. Se usa una desviación cuando un tramo
incumple la arquitectura o la elección realizada: medida distinta, ruptura de rima, ausencia o
adición estructural, repetición anómala o rasgo observado no previsto. **La ausencia de desviaciones
significa conformidad con la norma seleccionada**, no que nadie haya mirado.

**La laguna de una fuente no autoriza un rango incompatible.** El cómputo incorpora la posición del
verso ausente y la laguna se localiza en el registro correspondiente.

**La adición estructural sí se descuenta al comprobar la norma.** Una desviación localizada
`estructura / sobra` identifica posiciones añadidas: siguen contando en la extensión real del
pasaje, pero no en su mínimo, módulo ni número de unidades normativas. El editor y la API usan
el mismo cálculo; los rangos solapados de adición cuentan una sola vez y deben quedar dentro
de la secuencia. Una desviación de metro o rima no cambia este recuento.

Por ejemplo, los vv. 2622–2754 de *Los locos de Valencia* abarcan 133 posiciones. Declarado el
v. 2666 como adición estructural, quedan 132 de norma: 33 redondillas. El reparto conserva
11 redondillas antes de ese verso y 22 después, dentro de una sola secuencia. Una adición
entre estrofas cubre su posición sin crear una unidad; una interna queda en el rango de la
unidad y se descuenta al comprobar su extensión.

Con `estructura / falta`, la posición ausente **ya está incluida en el rango**: ocho posiciones
con un verso perdido siguen formando dos redondillas. No se suma ni se descuenta otra vez.
Si la numeración de una edición no reserva posiciones para las lagunas, hay que resolver su
correspondencia con el rango interno al normalizar, conservando la numeración de la fuente.
El comprobador no deduce automáticamente posiciones perdidas ni reconstruye el texto.

## Los tramos sin forma no tienen norma que cumplir

Versificación irregular y verso aislado se delimitan y se guardan: no se pide arquitectura ni
desviaciones. Lo que sí se registra es **lo que se ve** —la medida verso a verso, el esquema de rima
que haya—, y se escribe, no se elige de una lista: no hay repertorio del que elegir porque no se
reconoce ninguna norma. El auditor lo comprueba en D19, y comprueba en D10 lo contrario, que no
declaren norma por descuido.

## Qué se comprueba, y con qué

| Pregunta | Comando |
| --- | --- |
| Qué le pide el editor a cada forma, y qué le hace trabajar de más | `npm run audit:editor` |
| Si el catálogo cumple los criterios de nivel | `npm run audit:metrica` |
| Si lo ya anotado sigue encajando con el catálogo | `npm run audit:anotaciones` |

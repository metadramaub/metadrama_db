# Decisiones de la segunda poda

Registro acumulativo de decisiones aprobadas. La revisión comenzó por bloques repetidos y continúa
forma a forma, con una migración por forma para poder comprobar cada ficha antes de pasar a la
siguiente. El inventario completo y regenerable vive en
[segunda-poda-de-la-prosa.md](./segunda-poda-de-la-prosa.md).

## Canción petrarquista · estancias consonantes variables

- Mejorar la definición de la forma para que abarque también la arquitectura sin rima.
- Reescribir la descripción de la arquitectura usando «composición», no «poema».
- Quitar `esquemas_metricos.descripcion`.
- Quitar `esquemas_rima.descripcion`.
- Conservar la restricción estructurada `identidad_entre_repeticiones`, retirar su descripción
  personalizada y no duplicarla en la ficha cuando ya la expresa el grado de determinación.
- Quitar la nota de la sección `estancia`.
- Quitar la nota de `densidad_de_rima` de esta arquitectura.
- Acortar la nota del `remate`, eliminando solo la repetición de las medidas 7 y 11.

## Bloques idénticos B1–B8

- **B1 · conservar bajo demanda.** Las seis notas sobre distribución consonante variable y
  densidad total se conservan, pero se abren mediante un icono en vez de quedar siempre visibles.
- **B2 · eliminar.** Las seis notas «Sirima.» de las posiciones 8–13 duplican la banda
  estructurada.
- **B3 · conservar bajo demanda.** Las cinco notas sobre terminación esdrújula se conservan bajo
  el mismo icono desplegable.
- **B4 · eliminar.** Las cuatro descripciones del ciclo asonantado de los romances repiten la
  rejilla.
- **B5 · eliminar.** Las cuatro notas «Verso impar suelto.» repiten el guion de la primera posición
  del ciclo.
- **B6 · eliminar.** Las tres notas «Primer hexasílabo.» de la seguidilla gitana repiten la celda.
- **B7 y B8 · estructurar y después eliminar.** Los dos pies de la fronte deben codificarse como
  subestructura métrica y dibujarse dentro de la banda `fronte`; solo entonces se borrarán las seis
  notas posicionales.
- **B9 · conservar.** `5-7-5` es el nombre legítimo de dos esquemas métricos, no una glosa.
- **B10 · eliminar.** Las dos notas del terceto encadenado repiten los enlaces de rima y, además,
  estaban colocadas en `estructuras_secciones` aunque su información pertenece a la rima.
- **B11 · conservar bajo demanda.** La explicación 7/11 permanece tras el icono tanto en `libre`
  como en `consonante_irregular`, publicada esta última como «Consonante de orden libre».
- **B12 · eliminar la explicación de la repetición total.** «Se repite entero» ya basta. La
  repetición parcial conservará bajo demanda «Se repiten solo algunos versos del estribillo
  completo, a menudo los dos últimos». Se revisarán en conjunto las notas de las partes del
  villancico.
- **B13 · acortar las dos apariciones.** En ambos remates se elimina solo la frase que vuelve a
  declarar las medidas admitidas por la arquitectura.
- **B14 · corregir y eliminar la glosa.** La mudanza asonantada del villancico pasa de `abcb` a
  `-a-a`: las posiciones primera y tercera quedan sueltas y la segunda y la cuarta comparten la
  asonancia. Una vez dibujado, se eliminan sus dos descripciones redundantes.
- **B15 · eliminar.** Las dos notas sobre la posición endecasilábica repetida en el remate de la
  sextina describen la antigua expansión del dato, no una propiedad que la figura deje sin decir.
- **B16 · mejorar sin recortar.** Las dos relaciones de la novena conservan notas extensas y
  específicas: una explica el papel de la redondilla y otra el de la quintilla, incluido el orden
  alternativo de los componentes y la independencia de sus rimas.

## Presentación de notas

Las notas de rasgo no quedan desplegadas permanentemente. Un componente general coloca un icono a
la derecha; el clic lo abre y otro clic, un clic exterior o Escape lo cierran.

Cuando termine la poda se abrirá una fase distinta de **glosas didácticas bajo demanda**. Podrán
explicar en prosa los dibujos o reglas estructuradas más difíciles de leer, aunque la información
sea redundante, pero se elegirán por su utilidad pedagógica y permanecerán ocultas tras el icono.
No se recuperan automáticamente las glosas antiguas ni se mezcla esta capa con la limpieza actual.

## Villancico

- **Definición de forma.** Se mejora sin recortarla: el enlace o vuelta deja de presentarse como
  obligatorio, se explicita que estribillo y coplas pueden emplear medidas distintas y la aparición
  del estribillo después de una copla deja de identificarse exclusivamente con una modalidad
  moderna.
- **Arquitectura `estribillo_inicial`.** La descripción hablará de uno o más ciclos de copla y
  estribillo y distinguirá la mudanza obligatoria del enlace o vuelta y la repetición opcionales.
- **Arquitectura `estribillo_tras_primera_copla`.** La descripción no atribuirá en línea la
  caracterización a Navarro Tomás: la atribución pertenece a las fuentes. Explicará la posición de
  la primera aparición, la posible diferencia de medida entre partes y presentará la combinación
  de cuarteta octosilábica y estribillo hexasílabo como una realización, no como definición de toda
  la arquitectura.
- **Medida.** `medida_uniforme = true` se conserva: expresa que cada sección es isométrica. Se
  corrige la inferencia pública «una medida para toda la composición» por «una medida por parte».
  Las dos descripciones genéricas se sustituyen por la glosa bajo demanda «El estribillo y las
  coplas suelen compartir medida, pero pueden emplear metros distintos».
- **Rima.** Se mantiene la decisión B14: `abcb` pasa a `-a-a` y se retiran las dos descripciones
  que la figura ya dibuja.
- **Partes comunes.** Se eliminan las notas de `copla` y `enlace_vuelta`. La de `mudanza` se acorta
  a «Suele organizar sus cuatro versos en dos miembros simétricos» y se muestra solo bajo demanda.
- **Partes de `estribillo_inicial`.** Se eliminan las notas de `cabeza`, `ciclo_copla` y `represa`.
- **Partes de `estribillo_tras_primera_copla`.** Se eliminan las notas de `ciclo_copla` y
  `estribillo`; la descripción de arquitectura ya explicará la diferencia entre primera aparición
  y repeticiones posteriores.
- **Repetición.** Se mantiene B12: sin glosa para la repetición total y glosa bajo demanda «Se
  repiten solo algunos versos del estribillo completo, a menudo los dos últimos» para la parcial.
- **Relación con el zéjel.** Se conserva extensa, pero concreta la oposición entre la mudanza
  monorrima de tres versos del zéjel y la mudanza villanciquil de cuatro versos, habitualmente
  consonante en `abba` o `abab`, con posibilidad asonantada y de enlace.

### Presentación del árbol de partes

- No se muestra `× 1`; la ausencia del signo significa una sola aparición.
- `0–1` se presenta como «opcional» y `0–∞` como «opcional · repetible».
- Las repeticiones se escriben `× 2`, `× 1–3` o `× 3 o más`, separadas del número de versos.
- Un único icono junto a «Partes» explica qué significa `×`.
- Las notas de sección que permanecen se abren bajo demanda con el componente general de ayuda.
- Una sección que reutiliza otra arquitectura dice «Se estructura como», porque la reutilización
  comprende la medida y la estructura, no solo la rima.
- Las cantidades respetan el singular: «1 verso».

La relación de rima entre mudanza, enlace o vuelta y estribillo no se intenta reducir a una regla
estructural única: varía demasiado entre realizaciones. La posible necesidad de registrar por
separado esas rimas en el Editor V2 queda en el documento de cuestiones pendientes.

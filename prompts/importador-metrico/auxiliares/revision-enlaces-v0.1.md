# Revisión de enlaces del JSON métrico

Revisa el último JSON de este chat. Esta segunda pasada comprueba únicamente sus
enlaces de notas: no vuelvas a transcribir las fotos. Conserva todos los valores
de todos los campos salvo `tramos[*].notas_ref`.

Usa `notas[*].tramos_ref` como única fuente para rehacer esas listas. Para cada
fila, busca su `id` en cada `tramos_ref` y escribe solo los `id` de las notas
que contienen esa fila. Si no hay ninguna, escribe `[]`. En particular, para cada
nota con `tramos_ref: []`, comprueba que ninguna fila mencione su id, ni siquiera
la última fila. No cambies las notas para hacerlas coincidir con las filas.

Devuelve el JSON íntegro con los enlaces corregidos en un solo bloque de código
`json`. No añadas citas, explicaciones ni resúmenes.

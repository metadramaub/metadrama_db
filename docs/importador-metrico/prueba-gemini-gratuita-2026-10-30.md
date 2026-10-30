# Prueba de extracción con Gemini · 30 de octubre de 2026

Primera ronda cerrada con cuatro obras de ajuste. Sesión gratuita facilitada por el responsable,
modo visible Automático («Modelos de Gemini 3» en el selector). Modelo exacto desconocido.
Una conversación nueva por obra, mismo prompt `extraccion-v0.1.md`, fotografías JPEG y metadatos.
No se proporcionó la tabla de referencia al modelo ni se modificó el prompt entre casos.

## Respuestas originales

| Obra | Filas conservadas | Diferencias de contenido frente a la referencia aceptada | Problemas de formato |
| --- | ---: | --- | --- |
| Los locos de Valencia | 20 de 20 | Marca de segunda nota vacía en vez de `**`; «quintillas» en vez de «quintilla» en una fila | La marca vacía incumple el esquema |
| El verdadero amante | 19 de 19 | Omite el recuento impreso de 220 versos en la primera fila | 19 páginas como cadenas en vez de números |
| Los donaires de Matico | 18 de 18 | Ninguna en los campos cotejados | 23 páginas como cadenas en vez de números (18 filas y 5 filas de resumen) |
| El molino | 21 de 21 | Ninguna en los campos cotejados | Ninguno; respuesta admitida sin corregir |

Todas las respuestas son JSON interpretable. El evaluador separa diferencias de tipo numérico
de diferencias de lectura, pero conserva la respuesta original y sigue rechazando el formato
incorrecto. Los textos de las dos notas de Los locos y sus vínculos se conservaron.

Los recuentos de diferencias son incidencias por campo, no observaciones estadísticas independientes.
No representan una tasa de error del modelo. Estas cuatro obras ya se usaban para desarrollar el
importador: sirven para ajustar el proceso, no como evaluación independiente del prompt final.
No se ha probado una cuenta gratuita de ChatGPT; no hay comparación ni modelo ganador.

Entradas, respuestas originales, registros de ejecución y evaluaciones quedan fuera de Git en
`backups/importador-modelos/gemini-automatico-20261030/`. No se registró latencia ni se dedujo el
modelo concreto de lo que la propia IA pudiera declarar.

## Recorrido local comprobado

Con un editor sintético autorizado, la respuesta original de Los locos se rechaza y ahora indica
«Nota 2 (marca): Debe contener texto», sin JSON técnico anidado. No se relaja la validación.

Para Matico se creó una copia de ensayo convirtiendo exclusivamente sus 23 páginas de cadena a
número. Se conservan el original y un registro por campo de esas correcciones. La copia se pegó,
se comprobó, se guardó y se volvió a abrir mediante recarga de la ficha en `localhost:5190`:

- 2.812 versos, 18 secuencias y 3 jornadas.
- Fechas originales 1589–1603 y edición base conservadas.
- Importación atribuida a Persona de prueba 2.
- Los dos pasajes llamados «tercetos» permanecen sin resolver; no se les adjudica una forma por conjetura.

La ficha se guardó únicamente en el Supabase sintético `versologia_importador_auth`. No se han
aplicado migraciones ni creado obras reales durante esta ronda. Evidencia de recarga y captura
en la misma carpeta de ensayos, archivos `matico-recorrido-local.json` y `matico-ficha-local.png`.

Validación del bloque: 144 pruebas del importador y de la vista previa pasan; `npm run check`
termina sin errores ni avisos.

## Próximo bloque

1. Preparar una versión nueva del prompt que explicite los tipos de cada campo, especialmente
   páginas y marcas, y refuerce la copia de recuentos impresos. Mantener intacta esta primera ronda.
2. Probar esa versión por separado y reservar obras nuevas del lote para su evaluación final.
3. Completar el recorrido de los casos con notas y desviaciones desde una respuesta de IA,
   sin heredar las decisiones reservadas al JSON exacto del piloto.
4. Cerrar las instrucciones breves para importadores antes de integrar la precomputación real.

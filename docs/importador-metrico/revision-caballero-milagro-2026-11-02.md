# El caballero del milagro: revisión de la respuesta v0.5

## Comprobación de la importación real

Tras el aviso de David, consulta de solo lectura al Supabase real el 02-11-2026. Importación
`4822994f-5836-44a1-8cce-d821df1af228`, obra `074310f3-76cf-47db-874c-dfd74116b3a8`.
La entrada original guardada coincide con la respuesta v0.6 aportada. La copia confirmada
y las 24 filas persistidas coinciden campo a campo con la preparación acordada: rangos,
longitudes, forma y arquitectura, referencias de origen, rasgos, notas, candidatas y desviaciones.
Las tres jornadas cubren 1–1028, 1029–2085 y 2086–3001, sin huecos ni solapamientos.

Perfil guardado: Redondilla 2324 versos, Octava real 184, Endecasílabo suelto 306,
Sexteto-lira 156, Soneto 28 y tres sin identificar (1679–1681). Las cinco tiradas de sueltos
conservan Dístico final presente. Redondilla sigue sin arquitectura. Se conserva la llamada 66
incompleta con su incidencia y la nota del estrambote termina en «criterio pendiente».
Todas las secuencias figuran con segmentación confirmada.

Metadatos guardados: Lope de Vega, comedia o tragicomedia, 1593–1593, edición de Santiago Restrepo
y Ramón Valdés Gázquez, Parte XV (2016). Se comprueba su persistencia; no se vuelve a fundamentar
la datación. No se modifica ningún dato remoto. Evidencia privada: `lectura-guardado-real.json`
y `auditoria-guardado-real.json` en la carpeta de este caso.

## Continuación con v0.6 y acuerdos del responsable

La segunda respuesta aportada corrige las tres jornadas y conserva la llamada 66 con texto
null e incidencia. Mantiene los 23 rangos y recuentos y los cinco totales del resumen; todavía
conserva saltos de línea en las cinco denominaciones de sueltos. Se archiva sin modificar como
`respuesta-v0.6-original.json` en la carpeta privada de este caso. Servicio y modelo no conocidos.

Acuerdos explícitos del responsable el 2 de noviembre, implementados en equivalencias v0.8:

- «Endecasílabos sueltos rematados en pareado» equivale a la variante «con pareado final»:
  Endecasílabo suelto, arquitectura endecasílaba y Dístico final presente, sin nueva secuencia.
- «Sextetos-liras» equivale a Sexteto-lira. Su única arquitectura activa es Heterométrico
  consonante, contrastada mediante consulta de solo lectura al Supabase enlazado. No se elige
  esquema de rima ni distribución de medidas.
- Provisionalmente, «soneto con estrambote» se divide en primeros 14 versos como Soneto y resto
  sin identificar. En esta obra: 1665–1678 y 1679–1681. No se presupone forma, metro ni esquema
  del resto. El IP decidirá si el catálogo debe admitir estrambote como remate de soneto.
  Si la extensión no supera 14 o no consta, no se inventa la división y queda sin identificar.

La comparación de literales tolera diferencias de espacios y saltos de línea, conservando
intacto el literal original. La división conserva la misma fila fuente en ambas partes y puede
editarse por el mecanismo existente. La nota sobre el estrambote se guarda en la parte pendiente.

La referencia de formas y arquitecturas se amplía mediante consulta de solo lectura a las 49
formas activas, con fecha propia de consulta. Rasgos y demás detalles mantienen su referencia
anterior: su ampliación se comprobará cuando aparezcan nuevas precisiones, sin afirmar cobertura
completa de todos los campos del catálogo. No se cambió el catálogo ni la DB.

Las veinte se revisarán conservando respuesta original, prompt utilizado y modelo cuando conste.
Al acabar se decidirá si repetir las ejecuciones con prompts antiguos o retirar las fichas de
prueba; no se elimina ni se reimporta nada automáticamente. La normalización tiene su propia
versión: cambiar una equivalencia no exige repetir la extracción si esta conserva la información.

Lo que sigue documenta el primer cotejo y las limitaciones detectadas entonces.

Respuesta aportada por David el 2 de noviembre de 2026. No consta aquí qué servicio o modelo
la produjo. Se coteja visualmente con las dos fotografías locales del lote, usando sus copias
JPG de lectura. No se declara gold ni revisión humana aprobada.

## Resultado del cotejo

- Las 23 filas conservan intervalos, denominaciones y recuentos de la tabla: 1–3001,
  sin huecos ni solapamientos. Los cinco totales y porcentajes del resumen también coinciden.
- Error de estructura: la cabecera corrida «Parte XV» de la segunda foto se convirtió en
  jornada 15. Esa foto continúa el acto tercero: las nueve filas t15–t23 pertenecen a la
  jornada 3. No corresponde renumerar automáticamente cualquier entrada con jornadas inválidas.
- Error de nota: el superíndice 66 está junto al total 31 de Sonetos en el resumen. No se ve
  el cuerpo de la nota. Debe conservarse la llamada, con texto null y una incidencia que
  identifique su ubicación en el resumen, sin atribuirla a tramos concretos.
- Incumplimiento menor del prompt: las cinco denominaciones de endecasílabos sueltos conservan
  un salto de línea; deben unirlo con espacio sin perder «rematados en pareado».
- Metadatos null y página null en la primera foto son correctos: no se debe inventar información
  a partir del nombre del archivo ni deducir la página de la foto contigua.

La validación técnica del intercambio acepta la estructura del original. Eso no certifica
su fidelidad: el comprobador posterior de ficha básica sí rechaza la jornada 15. La suma
correcta de 3001 versos no detecta por sí sola este error semántico.

## Cambio del prompt

Se conserva v0.5 y se activa `extraccion-v0.6.md` en el botón Copiar prompt. El formato sigue
siendo `versologia-extraccion/0.1`. Se precisa qué es un encabezamiento dramático, cómo continuar
una jornada entre fotos, cómo registrar llamadas sin cuerpo y cómo unir denominaciones partidas.
Son instrucciones generales con ejemplos; no se añade una corrección automática de estos datos.

Todavía no hay una nueva ejecución de IA con v0.6: el cambio no demuestra una mejora de acierto.
El siguiente ensayo debe usar las mismas dos fotos y comprobar esos puntos, además de todas
las filas y recuentos. Los casos anteriores siguen siendo controles de regresión.

La extracción literal y la equivalencia de catálogo son pasos distintos: no debe pedirse a la IA
que sustituya «rematados en pareado» por el nombre de un rasgo interno. La variante no figura
todavía entre los alias explícitos de «con pareado final»; su incorporación y la resolución de
«sextetos-liras» se revisarán en el vocabulario, sin alterar el literal ni inventar arquitectura.

## Archivos y comprobaciones

En `backups/importador-local/caballero-milagro-2026-11-02/`, fuera de Git:

- `respuesta-original.json`: copia exacta del archivo aportado.
- `extraccion-corregida.json`: corrección asistida de jornadas, saltos y llamada de nota;
  conserva procedencia v0.5 y revisión humana pendiente. No se ha importado ni guardado en DB.

La copia corregida pasa el validador técnico sin errores ni advertencias; conserva el pendiente
por nota incompleta. Las 22 pruebas de preparación del servidor pasan con el nuevo prompt.

# El caballero del milagro: revisión de la respuesta v0.5

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
